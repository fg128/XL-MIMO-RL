function next_beam_idx = move_beam(current_beam_idx, move_type, step_size, size_cb)
% Calculates the new codebook index based on a desired move 
% (i.e move angle right 3, move range deeper 1).
%
% Inputs:
%   current_idx - Current linear index in the codebook (1 to size_cb).
%   move_type   - String: 'angle' or 'range'.
%   step_size   - Integer: Amount to move (e.g., +1, -1, +5, -5).
%   size_cb     - Total size of the codebook (e.g., 1024).
%
% Output:
%   next_idx    - The new valid linear index

    % 1. Recover Grid Dimensions (Must match your codebook function logic)
    % N_angle is the inner loop size
    N_angle = round(sqrt(size_cb)); 
    N_range = floor(size_cb / N_angle);
    
    % Cap total size to ensure valid math
    max_idx = N_angle * N_range;
    if current_beam_idx > max_idx, current_beam_idx = max_idx; end
    if current_beam_idx < 1, current_beam_idx = 1; end

    % 2. Convert Linear Index to Grid Coordinates (Row, Col)
    % Row = Range Index (1 to N_range)
    % Col = Angle Index (1 to N_angle)
    % Formula: index = (row - 1)*N_angle + col
    current_row = ceil(current_beam_idx / N_angle);
    current_col = mod(current_beam_idx - 1, N_angle) + 1;
    
    % 3. Apply the Move
    new_row = current_row;
    new_col = current_col;
    
    if strcmp(move_type, 'angle')
        % Apply step to Column (Angle)
        new_col = current_col + step_size;
        
        % CLAMPING (Don't wrap around to the next depth level)
        if new_col < 1, new_col = 1; end
        if new_col > N_angle, new_col = N_angle; end
        
    elseif strcmp(move_type, 'range')
        % Apply step to Row (Range/Depth)
        new_row = current_row + step_size;
        
        % CLAMPING (Don't go below min range or above max range)
        if new_row < 1, new_row = 1; end
        if new_row > N_range, new_row = N_range; end
    end
    
    % 4. Convert Grid Coordinates back to Linear Index
    next_beam_idx = (new_row - 1) * N_angle + new_col;
end