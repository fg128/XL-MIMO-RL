function [next_obs, reward, is_done, logged_signals] = step_function(action, logged_signals, config)
    % 1. Unpack current state
    curr_beam_idx = logged_signals.current_beam_idx;
    curr_psf = logged_signals.current_psf;
    curr_psf_idx = find(config.psf_codebook == curr_psf);

    % 2. Execute action
    [next_beam_idx, next_psf_idx] = do_action(action, curr_beam_idx, curr_psf_idx, config.size_cb, config.psf_N);
    next_psf = config.psf_codebook(next_psf_idx);

    % 3. Update beam & power splitting factor from codebooks 
    W = config.w_beam_codebook(:, next_beam_idx);
    psf = config.psf_codebook(next_psf_idx);

    % 4. Power allocation between signal and noise
    P_s = config.P_total_watts * psf;
    P_an = config.P_total_watts * (1 - psf);

    % 5. Get channels for Bob and Eve
    h_bob = get_channel(config, logged_signals.bob_loc);
    h_eve = get_channel(config, logged_signals.eve_loc);

    if isrow(h_bob), h_bob = h_bob.'; end
    if isrow(h_eve), h_eve = h_eve.'; end

    % 6. Transmitted signal sent
    s = (randn(1, 1) + 1j*randn(1, 1)) / sqrt(2); % Transmitted symbol
    z = (randn(config.Nt, 1) + 1j*randn(config.Nt, 1)) / sqrt(2); % Random noise vector
    V = eye(config.Nt) - (h_bob * h_bob') / (norm(h_bob)^2); % Null space of Bob
    x = sqrt(P_s)*W*s + sqrt(P_an)*(V*z); % Transmitted signal

    % 7. Recieved signals
    sigma_bob = sqrt(config.noise_power_watts / 2);
    n_bob = sigma_bob * (randn(1, 1) + 1j*randn(1, 1));
    y_bob = h_bob'*x + n_bob;

    sigma_eve = sqrt(config.noise_power_watts / 2);
    n_eve = sigma_eve * (randn(1, 1) + 1j*randn(1, 1));
    y_eve = h_eve'*x + n_eve;

    % 8. Received powers
    rx_pwr_bob = abs(y_bob)^2;
    rx_pwr_eve = abs(y_eve)^2;

    % Analytical signal power
    sig_pwr_bob = P_s * abs(h_bob' * W)^2;
    sig_pwr_eve = P_s * abs(h_eve' * W)^2;

    % Analytical interference power (AN leakage)
    % (Bob interference should be 0 due to projection V)
    an_leakage_bob = P_an * norm(h_bob' * V)^2; 
    an_leakage_eve = P_an * norm(h_eve' * V)^2;

    % 9. SINR (Signal to Interference plus Noise Ratio)
    SINR_bob = sig_pwr_bob / (config.noise_power_watts + an_leakage_bob);
    SINR_eve = sig_pwr_eve / (config.noise_power_watts + an_leakage_eve);

    % 10. Secrecy rate
    rate_bob = log2(1 + SINR_bob);
    rate_eve = log2(1 + SINR_eve);
    secrecy_rate = max(0, rate_bob - rate_eve);

    % 11. Give reward 
    reward = secrecy_rate;
    is_done = false; 
    
    % 12. Update logged signals
    logged_signals.current_beam_idx = next_beam_idx;
    logged_signals.current_psf = next_psf;

    % 13. Next observation
    next_obs = [next_beam_idx / config.size_cb; next_psf];
end