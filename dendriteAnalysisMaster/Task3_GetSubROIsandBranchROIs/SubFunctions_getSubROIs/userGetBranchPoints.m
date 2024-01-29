function [x_branch, y_branch] = userGetBranchPoints(image_skeleton, meanImgEnh_2)
%USERGETBRANCHPOINTS Allows the user to interactively select branch points in an image.
%
%   [x_branch, y_branch] = USERGETBRANCHPOINTS(image_skeleton, x_end, y_end, meanImgEnh_2) 
%   displays the image_skeleton overlayed with meanImgEnh_2 and allows the user to select 
%   branch points. The coordinates of the selected points are returned as x_branch and y_branch.
%
%   Inputs:
%   - image_skeleton: Binary image representing the skeleton.
%   - x_end, y_end: Coordinates of the endpoints in the skeleton.
%   - meanImgEnh_2: Background image for overlay.
%
%   Outputs:
%   - x_branch, y_branch: Coordinates of the selected branch points.

    % Display the overlay image
    imshowpair(meanImgEnh_2, image_skeleton, 'blend');
    hold on;

    % Initialize arrays to hold the selected branch points
    x_branch = [];
    y_branch = [];

    % Loop until the user is done selecting points
    done = false;
    while ~done
        % Let the user select a point
        [x, y] = ginput(1);

        % If the user didn't select a point, exit the loop
        if isempty(x) || isempty(y)
            done = true;
            continue;
        end

        % Round the coordinates to the nearest integer
        x = round(x);
        y = round(y);

        % Add the selected point to the branch points arrays
        x_branch = [x_branch; x];
        y_branch = [y_branch; y];

        % Plot the selected point
        plot(x, y, 'yo');
    end

    hold off;
end
