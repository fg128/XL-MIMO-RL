function h = get_channel(config, loc)
    % 1. Calculate Center Distance (d)
    array_center = [0;0;0];
    d = norm(loc - array_center);
    
    % 2. Calculate Large Scale Fading Coefficient (beta_ub) [Friis Path Loss: (lambda / 4*pi*d)^2]
    beta = (config.lambda / (4 * pi * d))^2;
    
    % 3. Calculate Array Response Vector (a)
    d_vec = sqrt(sum((config.pos - loc).^2, 1)); 
    a_usw = exp(-1j * config.k * d_vec);
    
    % 4. Construct Channel Vector h 
    h = sqrt(beta) * exp(-1j * config.k * d) * a_usw;
end