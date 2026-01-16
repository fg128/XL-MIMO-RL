function config = get_config()
% Gets the configuration setting so can be easily passed around
% 
% Output:
%   config   - Configuration struct

    %% --------------------------------------------------------------------
    % 1. GENERAL CONFIG
    % ---------------------------------------------------------------------
    config.c = physconst('LightSpeed');
    config.fc = 28e9; % Frequency (Hz)
    config.lambda = config.c / config.fc; % Wavelength (m)
    config.k = 2 * pi / config.lambda; % Wavenumber (m^-1)
    config.Nt = 1024; % Number of antennas
    config.max_x = 70; % Maximum +/- lateral distance in simulation
    config.max_z = 70; % Maximum depth in simulation
    config.resolution = 0.5; % Resolution of probing (i.e. Strength resolution)
    config.P_total_watts = 10; % Power of array

    config.show_plot_every_nth_steps = 2500;
    

    %% --------------------------------------------------------------------
    % 2. NOISE CONFIG
    % ---------------------------------------------------------------------
    config.k_B = physconst('Boltzmann');
    config.BW = 100e6; % Bandwidth (Hz)
    config.NF_dB = 10; % Noise Figure (i.e. Receiver Quality)
    config.T_temp = 290; % Noise temperature (Kelvin)
    % Noise Power Floor (Watts) [P_noise = k * T * B * 10^(NF/10)]
    config.noise_power_watts = config.k_B * config.T_temp * config.BW * 10^(config.NF_dB/10);


    %% --------------------------------------------------------------------
    % 3. CODEBOOK CONFIG
    % ---------------------------------------------------------------------
    % Power-splitting factor codebook formation
    config.psf_N = 10; % 1/N linear spacing of power-splitting factor codebook
    config.psf_codebook = linspace(0, 1, config.psf_N+1); % Power splitting codebook
    
    % Beamforming codebook formation
    config.size_cb = 1024; % Size of beam-forming codebook
    antenna_array = phased.ULA('NumElements', config.Nt, ...
                               'ElementSpacing', 0.5*config.lambda, ...
                               'ArrayAxis', 'x');
    
    % Get element 3D positions (3xN matrix)
    config.pos = getElementPosition(antenna_array); 
    
    % Generate beamforming codebook
    [w_beam_codebook, grid_coords] = codebook(config.Nt, ...
                                              config.pos, ...
                                              config.k, ...
                                              config.size_cb, ...
                                              config.max_x, ...
                                              config.max_z);
    config.w_beam_codebook = w_beam_codebook;
    config.beam_focal_locs = grid_coords;
end