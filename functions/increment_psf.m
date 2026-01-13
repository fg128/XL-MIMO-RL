function next_psf = increment_psf(current_psf, step_size)
% MOVE_POWER Adjusts the power splitting factor safely.
% Clips the result between 0.0 and 1.0.
    next_psf = current_psf + step_size;
    
    if next_psf > 1.0
        next_psf = 1.0;
    elseif next_psf < 0.0
        next_psf = 0.0;
    end
end