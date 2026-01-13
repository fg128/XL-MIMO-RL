clear; clc; close all;
addpath('functions');
%% ------------------------------------------------------------------------
% 0. DEFINE CONSTANTS
% -------------------------------------------------------------------------
c = physconst('LightSpeed');
fc = 28e9; % Frequency (Hz)
lambda = c / fc; % Wavelength (m)
k = 2 * pi / lambda; % Wavenumber (m^-1)
Nt = 1024; % Number of antennas
max_x = 70; % Maximum +/- lateral distance in simulation
max_z = 70; % Maximum depth in simulation
resolution = 0.5; % Resolution of probing (i.e. Strenght resolution)
size_cb = 1024; % Size of codebook

% Noise related constants
k_B = physconst('Boltzmann');
BW = 100e6; % Bandwidth (Hz)
NF_dB = 10; % Noise Figure (i.e. Receiver Quality)
T_temp = 290; % Noise temperature (Kelvin)
% Noise Power Floor (Watts) [P_noise = k * T * B * 10^(NF/10)]
noise_power_watts = k_B * T_temp * BW * 10^(NF_dB/10);


%% ------------------------------------------------------------------------
% 1. CREATE ULA ANTENNA ARRAY
% -------------------------------------------------------------------------
% Create ULA Objects
antenna_array = phased.ULA('NumElements', Nt, ...
                   'ElementSpacing', 0.5*lambda, ...
                   'ArrayAxis', 'x');

% Get element 3D positions (3xN matrix)
pos = getElementPosition(antenna_array); 

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
[W_Codebook, beam_locs] = codebook(Nt, pos, k, size_cb, max_x, max_z);

% Form beamforming weights W
W = zeros(Nt, 1);
display_string = "Targets selected from Codebook:" + newline;

% Test focal point adjustments
current_idx = 300;
right = move_beam(current_idx, 'angle', +1, size_cb);
left = move_beam(current_idx, 'angle', -1, size_cb);
left = move_beam(left, 'range', 5, size_cb);

beam_indexes = [left, current_idx, right];
for i = beam_indexes
    W = W + W_Codebook(:, i);
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
sigma = sqrt(noise_power_watts / 2);

% We scan the XZ plane (Top-Down view)
x_range = -max_x : resolution : max_x;  % Meters (Lateral)
Y_fixed = 0; % Fixed slice Y=0
z_range = 1 : resolution : max_z;   % Meters (Depth)
[X_grid, Z_grid] = meshgrid(x_range, z_range);

% Initiate array to hold SNR
SNR_Linear = zeros(size(X_grid));

fprintf('Computing Near-Field SNR using LSFC Model...\n');
for i = 1:numel(X_grid)
    % 1. Current Probe Location (User u)
    probe_loc = [X_grid(i); Y_fixed; Z_grid(i)];
    
    % 2. Calculate Center Distance (d_ub)
    array_center = [0;0;0];
    d_ub = norm(probe_loc - array_center);
    
    % 3. Calculate Large Scale Fading Coefficient (beta_ub) [Friis Path Loss: (lambda / 4*pi*d)^2]
    beta_ub = (lambda / (4 * pi * d_ub))^2;
    
    % 4. Calculate Array Response Vector (a)
    d_vec = sqrt(sum((pos - probe_loc).^2, 1)); 
    a_probe = exp(-1j * k * d_vec);
    
    % 5. Construct Channel Vector h 
    h = sqrt(beta_ub) * exp(-1j * k * d_ub) * a_probe;
    
    % 6. Received Signal (y = h*W + n_u)
    % n_u = sigma * (randn(1) + 1j * randn(1));
    % rx_signal = h*W + n_u;
    rx_signal = h*W;
    
    % Save results
    sig_power = abs(rx_signal)^2;
    SNR_Linear(i) = sig_power / noise_power_watts;
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
plot3(pos(1,:), pos(3,:), ones(1,Nt)*100, 'rs', 'MarkerSize', 2, 'MarkerFaceColor', 'r');

title('XL-MIMO Near-Field SNR Distribution');
xlabel('Lateral Position (X) [m]');
ylabel('Depth (Z) [m]'); 
zlabel('SNR (dB)');
axis equal; axis tight;

disp(['Max SNR achieved: ' num2str(max(SNR_dB(:))) ' dB']);