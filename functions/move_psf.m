function next_psf_idx = move_psf(current_psf_idx, psf_N, is_decrement)
% Changes the index of power splitting code book by ±1.
%
% Inputs:
%   current_psf_idx - Current index of power splitting code book
%   psf_N           - N = psf_codebook_size-1
%   is_decrement    - If true decrease idx by -1 else +1 index
% 
% Outputs:
%   next_psf_idx    - New power splitting factor index in the psf codebook

    if is_decrement
        next_psf_idx = current_psf_idx - 1;
    else
        next_psf_idx = current_psf_idx + 1;
    end
    
    if next_psf_idx >= psf_N + 1
        next_psf_idx = psf_N + 1;
    elseif next_psf_idx < 1
        next_psf_idx = 1;
    end
end