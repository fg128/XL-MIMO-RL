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

beam_indexes = [left, current_idx, right];
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


%% ------------------------------------------------------------------------
% 3. SIMULATE FIELD RESPONSE WITH NOISE (SNR)
% -------------------------------------------------------------------------
% Noise signma
sigma = sqrt(config.noise_power_watts / 2);

% We scan the XZ plane (Top-Down view)
x_range = -config.max_x : config.resolution : config.max_x;  % Meters (Lateral)
Y_fixed = 0; % Fixed slice Y=0
z_range = 1 : config.resolution : config.max_z;   % Meters (Depth)
[X_grid, Z_grid] = meshgrid(x_range, z_range);

% Initiate array to hold SNR
SNR_Linear = zeros(size(X_grid));

fprintf('Computing Near-Field SNR using LSFC Model...\n');
for i = 1:numel(X_grid)
    % 1. Current Probe Location (User u)
    probe_loc = [X_grid(i); Y_fixed; Z_grid(i)];
    
    % 2. Get channel h
    h = get_channel(config, probe_loc);
    
    % 3. Received Signal (y = h*W + n_u)
    % n_u = sigma * (randn(1) + 1j * randn(1));
    % rx_signal = h*W + n_u;
    rx_signal = h*W;
    
    % Save results
    sig_power = abs(rx_signal)^2;
    SNR_Linear(i) = sig_power / config.noise_power_watts;
end

% Convert SNR to dB (Absolute dB, not normalized)
SNR_dB = 10*log10(SNR_Linear);


%% ------------------------------------------------------------------------
% 4. VISUALIZATION
% -------------------------------------------------------------------------
figure('Name', 'SNR Probing Map', 'Color', 'w');;

% Heatmap of SNR
surf(X_grid, Z_grid, SNR_dB, 'EdgeColor', 'none');
view(0, 90); % Top-down view
colormap('jet');
colorbar;

% Adjust Color Axis (Dynamic Range)
% We clip the bottom at 0 dB (Noise Floor) to make the beam pop
caxis([-10, max(SNR_dB(:))]); 

hold on;
% Draw the Antenna Array
plot3(config.pos(1,:), ...
      config.pos(3,:), ...
      ones(1,config.Nt)*100, ...
      'rs', ...
      'MarkerSize', 2, ...
      'MarkerFaceColor', 'r');

title('XL-MIMO Near-Field SNR Distribution');
xlabel('Lateral Position (X) [m]');
ylabel('Depth (Z) [m]'); 
zlabel('SNR (dB)');
axis equal; axis tight;

disp(['Max SNR achieved: ' num2str(max(SNR_dB(:))) ' dB']);