function cmap = colormapMaker(colors, scaling)
    % takes colors (given as an N x 3 array) and creates a colormap that goes from each color in the order provided
    % ex. for white to green, colors = [255,255,255;0,255,0];
    if nargin < 2 || isempty(scaling)
        scaling = 'linear';
    end

    if size(colors, 2) ~= 3
        error('Make sure your input colors are N x 3, where N is the number of colors');
    end

    if any(colors > 1)
        colors = colors/255; % supplied 0-255 rather than 0-1, so we rescale
    end 

    n_colors = floor(255/(size(colors, 1)-1));

    colormap_matrix = zeros(3, n_colors);
    for n = 1:size(colors, 1) - 1
        switch scaling
        case 'linear'
            colormap_matrix(:, (n - 1) * n_colors + 1 : n * n_colors) = cat(1, linspace(colors(n, 1), colors(n+1, 1), n_colors), linspace(colors(n, 2), colors(n+1, 2), n_colors), linspace(colors(n, 3), colors(n+1, 3), n_colors));
        case 'log'
            colormap_matrix(:,  (n - 1) * n_colors + 1 : n * n_colors) = cat(1, logspace(colors(n, 1), colors(n+1, 1), n_colors), logspace(colors(n, 2), colors(n+1, 2), n_colors), logspace(colors(n, 3), colors(n+1, 3), n_colors));
        end
    end
    cmap = rescale(colormap_matrix)';
end