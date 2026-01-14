function [W_codebook, grid_coords] = codebook(Nt, pos, k, size_cb, max_x, max_z)
% Generates Near-Field beamsforming weights in a codebook.
%
% Inputs:
%   Nt      - Number of antennas
%   pos     - Antenna positions (3xN matrix)
%   k       - Wavenumber (2*pi/lambda)
%   size_cb - Total desired number of beams (e.g., 1024)
%   max_x   - Coverage limit in Lateral direction (+/- meters)
%   max_z   - Coverage limit in Depth direction (meters)
%
% Outputs:
%   W_codebook  - (Nt x size_cb) matrix of weights
%   grid_coords - (size_cb x 3) matrix of focal point locations [x,y,z]

    % 1. Define Grid Dimensions
    % We split the total size into (Angles x Ranges)
    % We take the square root to get an even split (e.g., 32x32 = 1024)
    N_angle = round(sqrt(size_cb));
    N_range = floor(size_cb / N_angle);
    
    % Adjust actual size to match product (in case of rounding)
    actual_size = N_angle * N_range;
    
    % 2. Define Angular Domain (Theta)
    % Calculate max angle based on the geometry (FOV)
    % tan(theta) = x / z. We use a safe FOV of +/- 60 degrees if x=z.
    max_angle_deg = atand(max_x / 5); % Avoid scanning too wide at close range
    if max_angle_deg > 75, max_angle_deg = 75; end % Cap at 75 deg
    
    theta_vec = linspace(-max_angle_deg, max_angle_deg, N_angle);
    
    % 3. Define Range Domain (R)
    % We scan from very close (Fresnel region) to the max_z
    min_r = 0.5 * (max_z / N_range); % Start slightly away from array
    r_vec = linspace(min_r, sqrt(max_x^2 + max_z^2), N_range);
    
    % 4. Initialize Output
    W_codebook = zeros(Nt, actual_size);
    grid_coords = zeros(actual_size, 3);
    
    col_idx = 1;
    
    % 5. Generate Weights
    for r_val = r_vec
        for th_val = theta_vec
            
            % Convert Polar (r, theta) to Cartesian (x, z)
            % x = r * sin(theta)
            % z = r * cos(theta)
            x_foc = r_val * sind(th_val);
            z_foc = r_val * cosd(th_val);
            y_foc = 0;
            
            foc_point = [x_foc; y_foc; z_foc];
            
            % Save coordinate
            grid_coords(col_idx, :) = foc_point';
            
            % --- USW Weight Calculation ---
            % 1. Distance from every antenna to this focal point
            dist_from_target_to_antennas = sqrt(sum((pos - foc_point).^2, 1));
            
            % 2. Distance from array center to focal point (Reference)
            % r_center = norm(foc_point);
            
            % 3. Calculate Phase (USW Model) [Cite: Eq 20]
            % We use (d_vec - r_center) to normalize phase at the array center
            response_vector = exp(-1j * k * dist_from_target_to_antennas);

            % 5. Normalize Power (Norm = 1)
            w_vec = response_vector'; 
            w_vec = w_vec / norm(w_vec);
            
            % Store in Codebook
            W_codebook(:, col_idx) = w_vec;
          
            col_idx = col_idx + 1;
        end
    end
    
    disp(['Codebook Generated: ' num2str(actual_size) ' beams (Polar Domain).']);
end