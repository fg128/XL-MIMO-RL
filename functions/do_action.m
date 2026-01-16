function [next_beam_idx, next_psf_idx] = do_action(action, curr_beam_idx, curr_psf_idx, size_cb, psf_N)
% Routes the DQN action decision to performing the action.
%
% Inputs:
%   action          - Action chosen by DQN to take (0=Stay, 1-8=Move, 9-10=Power)
%   curr_beam_idx   - Current index of the beamforming codebook
%   curr_psf_idx    - Current index of the power splitting codebook
%   size_cb         - Total size of the codebook (e.g., 1024)
%   psf_N           - N = psf_codebook_size-1
%
% Output:
%   next_beam_idx   - The new index of the beamforming codebook
%   next_psf_idx    - The new index of the power splitting codebook

    % Set next beam and psf to current values by default
    next_beam_idx = curr_beam_idx;
    next_psf_idx = curr_psf_idx;

    switch action
        case 0 % STAY
            % Do nothing
        
        case 1 % Angle +1
            next_beam_idx = move_beam(curr_beam_idx, 'angle', +1, size_cb);

        case 2 % Angle +5
            next_beam_idx = move_beam(curr_beam_idx, 'angle', +8, size_cb);
            
        case 3 % Angle -1
            next_beam_idx = move_beam(curr_beam_idx, 'angle', -1, size_cb);
        
        case 4 % Angle -5
            next_beam_idx = move_beam(curr_beam_idx, 'angle', -8, size_cb);
            
        case 5 % Range +1
            next_beam_idx = move_beam(curr_beam_idx, 'range', +1, size_cb);
        
        case 6 % Range +5
            next_beam_idx = move_beam(curr_beam_idx, 'range', +5, size_cb);
        
        case 7 % Range -1
            next_beam_idx = move_beam(curr_beam_idx, 'range', -1, size_cb);
        
        case 8 % Range -5
            next_beam_idx = move_beam(curr_beam_idx, 'range', -5, size_cb);
            
        case 9 % Move PSF book index by +1
            next_psf_idx = move_psf(curr_psf_idx, psf_N, false);
            
        case 10 % Move PSF book index by -1
            next_psf_idx = move_psf(curr_psf_idx, psf_N, true);
    end
end