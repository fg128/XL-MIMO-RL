function [next_beam_idx, next_psf] = action_step(action, curr_beam_idx, curr_psf, size_cb)
    % Set next beam and psf to current values by default
    next_beam_idx = curr_beam_idx;
    next_psf = curr_psf;

    switch action
        case 0 % STAY
            % Do nothing
        
        case 1 % Angle +1
            next_beam_idx = move_beam(curr_beam_idx, 'angle', +1, size_cb);

        case 2 % Angle +5
            next_beam_idx = move_beam(curr_beam_idx, 'angle', +5, size_cb);
            
        case 3 % Angle -1
            next_beam_idx = move_beam(curr_beam_idx, 'angle', -1, size_cb);
        
        case 4 % Angle -5
            next_beam_idx = move_beam(curr_beam_idx, 'angle', -5, size_cb);
            
        case 5 % Range +1
            next_beam_idx = move_beam(curr_beam_idx, 'range', +1, size_cb);
        
        case 6 % Range +5
            next_beam_idx = move_beam(curr_beam_idx, 'range', +5, size_cb);
        
        case 7 % Range -1
            next_beam_idx = move_beam(curr_beam_idx, 'range', -1, size_cb);
        
        case 8 % Range -5
            next_beam_idx = move_beam(curr_beam_idx, 'range', -5, size_cb);
            
        case 9 % Increment power-splitting factor by 0.1
            next_psf = increment_psf(curr_psf, 0.1);
            
        case 10 % Decrement power-splitting factor by 0.1
            next_psf = increment_psf(curr_psf, -0.1);
    end
end