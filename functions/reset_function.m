function [initial_obs, logged_signals] = reset_function(config)
    % 1. Randomize Locations
    b_x = (rand-0.5)*2*config.max_x; 
    b_z = 20 + rand*(config.max_z - 20);
    logged_signals.bob_loc = [b_x; 0; b_z];
    
    e_x = b_x + (rand-0.5)*20; % Eve ±10m near Bob x and z
    e_z = b_z + (rand-0.5)*20; 
    logged_signals.eve_loc = [e_x; 0; e_z];
    
    % 2. Initialize agent randomly
    start_beam_idx = randi(config.size_cb); 
    start_psf_idx = randi(numel(config.psf_codebook));
    start_psf = config.psf_codebook(start_psf_idx);
    
    logged_signals.current_beam_idx = start_beam_idx;
    logged_signals.current_psf = start_psf;
    
    % 3. Set initial observations
    % Get distance of Bob and Eve from beam focal point
    current_focus_point = config.beam_focal_locs(start_beam_idx, :);
    delta_bob_x = (logged_signals.bob_loc(1) - current_focus_point(1)) / (2*config.max_x);
    delta_bob_z = (logged_signals.bob_loc(3) - current_focus_point(3)) / config.max_z;
    delta_eve_x = (logged_signals.eve_loc(1) - current_focus_point(1)) / (2*config.max_x);
    delta_eve_z = (logged_signals.eve_loc(3) - current_focus_point(3)) / config.max_z;
    initial_obs = [ ...
        start_beam_idx / config.size_cb; ...
        start_psf;
        delta_bob_x; delta_bob_z; ...
        delta_eve_x; delta_eve_z ...
    ];
end