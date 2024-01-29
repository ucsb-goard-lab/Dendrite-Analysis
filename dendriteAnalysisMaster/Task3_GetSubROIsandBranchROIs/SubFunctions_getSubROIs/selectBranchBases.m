function branchBases = selectBranchBases(image_skeleton, ROI_box)
% SELECTBRANCHBASES Interactive branch base selection using GUI.
%
%   branchBases = selectBranchBases(image_skeleton, ROI_box)
%
%   Inputs:
%       - image_skeleton: Binary image representing the skeleton of the dendrite.
%       - ROI_box: The region of interest (ROI) containing the dendrite.
%
%   Output:
%       - branchBases: A matrix where each row represents the coordinates (x, y)
%                      of a selected branch base.
%

% Create a figure for user interaction
fig = figure;
skeleton_small = image_skeleton(1:size(ROI_box, 1), 1:size(ROI_box, 2));
overlay = imoverlay(mat2gray(ROI_box), skeleton_small, 'yellow');
imshow(overlay);
set(gcf, 'units', 'normalized', 'outerposition', [0 0 1 1]);
title('Select the base of each branch. Right-click to finish.');
hold on

branchBases = [];

while true
    % Get the next branch base
    [x, y, button] = ginput(1);

    if isempty(x) || isempty(y)
        % No more branch bases selected, exit the loop
        break;
    end

    if button == 1
        % Add the selected base to the list
        branchBases = [branchBases; x, y];

        % Draw a circle at the selected base
        radius = 2; % You can adjust the radius as needed
        theta = linspace(0, 2 * pi, 100);
        x_circle = radius * cos(theta) + x;
        y_circle = radius * sin(theta) + y;
        plot(x_circle, y_circle, 'r-', 'LineWidth', 2);
    elseif button == 3
        % Right-click detected, finish the selection
        break;
    end
end


% Close the figure if it's still valid
if ishandle(fig)
    close(fig);
end
end
