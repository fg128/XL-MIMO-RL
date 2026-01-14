function [initial_obs, logged_signals] = reset_function(config)
    % 1. Randomize Locations
    b_x = (rand-0.5)*40; 
    b_z = 20 + rand*30;
    logged_signals.bob_loc = [b_x; 0; b_z];
    
    e_x = b_x + (rand-0.5)*15; % Eve near Bob
    e_z = b_z + (rand-0.5)*15;
    logged_signals.eve_loc = [e_x; 0; e_z];
    
    % 2. Initialize Agent
    start_beam_idx = round(config.size_cb / 2);
    start_psf_idx = round(config.psf_N / 2);
    
    logged_signals.current_beam_idx = start_beam_idx;
    logged_signals.current_psf_idx = start_psf_idx;
    
    % 3. Set initial observations
    initial_obs = [ ...
        start_beam_idx / config.size_cb; ...
        start_psf_idx;
    ];
end