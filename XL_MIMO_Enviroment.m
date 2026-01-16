clear; clc; close all;
addpath('functions');
config = get_config();
%% ------------------------------------------------------------------------
% 1. CREATE ULA ANTENNA ARRAY
% -------------------------------------------------------------------------
% Create ULA Objects
antenna_array = phased.ULA('NumElements', config.Nt, ...
                           'ElementSpacing', 0.5*config.lambda, ...
                           'ArrayAxis', 'x');

% Get element 3D positions (3xN matrix)
config.pos = getElementPosition(antenna_array); 

% 'viewArray' plots the physical elements for us to see
figure('Name', 'Antenna Geometry', 'Color', 'w');
viewArray(antenna_array, ...
          'ShowNormals', true, ...
          'ShowIndex', [1 64], ...
          'Title', 'XL-MIMO ULA Geometry (1024 Elements)');
view(45, 45);


%% ------------------------------------------------------------------------
% 2. FORM CODEBOOK & CALCULATE MULTI-BEAM PRECODING WEIGHTS
% -------------------------------------------------------------------------
[w_beam_codebook, beam_locs] = codebook(config.Nt, ...
                                   config.pos, ...
                                   config.k, ...
                                   config.size_cb, ...
                                   config.max_x, ...
                                   config.max_z);

% Form beamforming weights W
W = zeros(config.Nt, 1);
display_string = "Targets selected from Codebook:" + newline;

% Test focal point adjustments
current_idx = 300;
right = move_beam(current_idx, 'angle', +1, config.size_cb);
left = move_beam(current_idx, 'angle', -1, config.size_cb);
left = move_beam(left, 'range', 5, config.size_cb);

beam_indexes = [left, current_idx];
for i = beam_indexes
    W = W + w_beam_codebook(:, i);
    coords = beam_locs(i, :);
    
    % Create a readable string for this target
    target_info = "Index " + i + ": X=" + num2str(coords(1), '%.1f') + ...
                  " m, Z=" + num2str(coords(3), '%.1f') + " m";
              
    display_string = display_string + target_info + newline;
end

% Normalise weights
W = W / norm(W);
disp(display_string); % Print beam focus location coordinates

visualise(W, 0.5, 10, 10, 13, 13, config)