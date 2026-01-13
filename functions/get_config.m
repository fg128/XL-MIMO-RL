function config = get_config()
        config.c = physconst('LightSpeed');
        config.fc = 28e9; % Frequency (Hz)
        config.lambda = config.c / config.fc; % Wavelength (m)
        config.k = 2 * pi / config.lambda; % Wavenumber (m^-1)
        config.Nt = 1024; % Number of antennas
        config.max_x = 70; % Maximum +/- lateral distance in simulation
        config.max_z = 70; % Maximum depth in simulation
        config.resolution = 0.5; % Resolution of probing (i.e. Strenght resolution)
        config.size_cb = 1024; % Size of codebook
        
        % Noise related constants
        config.k_B = physconst('Boltzmann');
        config.BW = 100e6; % Bandwidth (Hz)
        config.NF_dB = 10; % Noise Figure (i.e. Receiver Quality)
        config.T_temp = 290; % Noise temperature (Kelvin)
        % Noise Power Floor (Watts) [P_noise = k * T * B * 10^(NF/10)]
        config.noise_power_watts = config.k_B * config.T_temp * config.BW * 10^(config.NF_dB/10);
end