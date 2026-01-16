function visualise(W, psf, bx, bz, ex, ez, config)
    %% 1. SIMULATE FIELD RESPONSE
    % Define Grid
    x_range = -config.max_x : config.resolution : config.max_x;
    Y_fixed = 0; 
    z_range = 1 : config.resolution : config.max_z;
    [X_grid, Z_grid] = meshgrid(x_range, z_range);
    
    SNR_Linear = zeros(size(X_grid));
    
    fprintf(['Computing SNR for ' psf '...\n']);
    
    % Loop through grid
    for i = 1:numel(X_grid)
        probe_loc = [X_grid(i); Y_fixed; Z_grid(i)];
        
        % Get channel (Ensure get_channel returns a column vector!)
        h = get_channel(config, probe_loc);
        
        % Calculate Signal (Projection model: h' * W)
        rx_signal = h' * W;
        
        sig_power = abs(rx_signal)^2;
        SNR_Linear(i) = sig_power / config.noise_power_watts;
    end
    
    SNR_dB = 10*log10(SNR_Linear);
    max_val = max(SNR_dB(:));

    %% 2. VISUALIZATION
    figure('Name', ['SNR Map: ' psf], 'Color', 'w');
    
    % Plot Heatmap
    surf(X_grid, Z_grid, SNR_dB, 'EdgeColor', 'none');
    view(0, 90); 
    colormap('jet');
    colorbar;
    title(['SNR Distribution - ' psf]);
    xlabel('Lateral (X) [m]'); ylabel('Depth (Z) [m]'); zlabel('SNR (dB)');
    axis equal; axis tight;
    
    % Adjust Color Scale
    caxis([-10, max_val]); 
    
    % --- CRITICAL FIX: ENABLE HOLD ON ---
    hold on; 
    
    % --- CRITICAL FIX: USE PLOT3 TO DRAW ON TOP ---
    % We plot Bob and Eve slightly higher (Z + 10) than the max SNR 
    % so they are not hidden behind the heatmap surface.
    z_offset = max_val + 10;
    
    % Plot BOB (Green Star)
    if ~isnan(bx) % Only plot if coordinates exist
        plot3(bx, bz, z_offset, 'p', ...
            'MarkerSize', 15, 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k');
        text(bx, bz, z_offset, '  BOB', 'Color', 'w', 'FontWeight', 'bold');
    end
    
    % Plot EVE (Red Cross)
    if ~isnan(ex)
        plot3(ex, ez, z_offset, 'x', ...
            'MarkerSize', 15, 'LineWidth', 3, 'Color', 'r');
        text(ex, ez, z_offset, '  EVE', 'Color', 'w', 'FontWeight', 'bold');
    end
    
    % Plot Antenna Array (Red Squares at bottom)
    plot3(config.pos(1,:), config.pos(3,:), ones(1,config.Nt)*z_offset, ...
        'rs', 'MarkerSize', 2, 'MarkerFaceColor', 'r');

    hold off;
end