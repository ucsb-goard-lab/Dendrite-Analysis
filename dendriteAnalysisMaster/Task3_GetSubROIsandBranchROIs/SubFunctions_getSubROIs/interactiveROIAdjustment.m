function roi = interactiveROIAdjustment(image_skeleton, meanImageEnh_2)
% interactiveROIAdustment - Interactive ROI parameter selector for dendrite skeleton.
%
% Usage:
%   roi = interactiveROIAdustment(image_skeleton, meanImageEnh_2)
%
% Parameters:
%   - image_skeleton: Skeletonized image.
%   - meanImageEnh_2: Mean enhanced image.
%
% This function allows the user to interactively edit the ROIs around the
% dendrite skeleton. Sliders for localRegionSize and percentile are
% provided to adjust the ROI visually. After defining the initial ROI,
% the user can adjust the sliders for smoothingSigma, holeFillRadius,
% and minObjectArea to see the effect on the ROI.
%

% Create a figure
fig = figure('Units', 'normalized', 'Position', [0, 0, 1, 1], 'Name', 'Interactive ROI Adjustment');

% Display images using imshowpair
subplot(2, 1, 1);
imshowpair(meanImageEnh_2, zeros(size(meanImageEnh_2)));
title('Overlayed ROI');

subplot(2, 1, 2);
imshow(meanImageEnh_2);
title('Original Image');

% Create text titles for sliders
uicontrol('Style', 'text', 'Units', 'normalized', 'Position', [0.80, 0.875, 0.15, 0.05], 'String', 'Width Adjustment');
uicontrol('Style', 'text', 'Units', 'normalized', 'Position', [0.80, 0.775, 0.15, 0.05], 'String', 'Contour Sensitivity Adjustment');
uicontrol('Style', 'text', 'Units', 'normalized', 'Position', [0.80, 0.675, 0.15, 0.05], 'String', 'Smoothing Sigma');
uicontrol('Style', 'text', 'Units', 'normalized', 'Position', [0.80, 0.575, 0.15, 0.05], 'String', 'Hole Fill Radius');
uicontrol('Style', 'text', 'Units', 'normalized', 'Position', [0.80, 0.474, 0.15, 0.05], 'String', 'Min Object Area');

% Create sliders for parameters
% Get the size of the image
[imageHeight, imageWidth] = size(image_skeleton);

% Initialize the shortest distance to a large value
shortestDistance = inf;

% Iterate over all non-zero pixels in the distance transform
for i = 1:imageHeight
    for j = 1:imageWidth
        if image_skeleton(i, j) == 1
            % Calculate the distance to the image boundary for the current pixel
            distanceToBoundary = min([i, j, imageHeight - i + 1, imageWidth - j + 1]);

            % Update the shortest distance if the current distance is smaller
            shortestDistance = min(shortestDistance, distanceToBoundary);
        end
    end
end

% localRegionSize
slider1 = uicontrol('Style', 'slider', 'Min', 0, 'Max', shortestDistance-1, 'Value', shortestDistance/2, ...
    'Units', 'normalized', 'Position', [0.80, 0.85, 0.2, 0.05], 'Callback', @(src, event) updateImages(src, event, fig), 'Tag', 'Slider1');
% percentile
slider2 = uicontrol('Style', 'slider', 'Min', 0, 'Max', 100, 'Value', 40, ...
    'Units', 'normalized', 'Position', [0.80, 0.75, 0.2, 0.05], 'Callback', @(src, event) updateImages(src, event, fig), 'Tag', 'Slider2');
% smoothingSigma
slider3 = uicontrol('Style', 'slider', 'Min', 0, 'Max', 10, 'Value', 0, ...
    'Units', 'normalized', 'Position', [0.80, 0.65, 0.2, 0.05], 'Callback', @(src, event) updateImages(src, event, fig), 'Tag', 'Slider3');
% holeFillRadius
slider4 = uicontrol('Style', 'slider', 'Min', 0, 'Max', 6, 'Value', 0, ...
    'Units', 'normalized', 'Position', [0.80, 0.55, 0.2, 0.05], 'Callback', @(src, event) updateImages(src, event, fig), 'Tag', 'Slider4');
% minObjectArea
slider5 = uicontrol('Style', 'slider', 'Min', 0, 'Max', 100, 'Value', 50, ...
    'Units', 'normalized', 'Position', [0.80, 0.45, 0.2, 0.05], 'Callback', @(src, event) updateImages(src, event, fig), 'Tag', 'Slider5');

% Save button
saveButton = uicontrol('Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.85, 0.375, 0.1, 0.05], 'String', 'Save ROI', 'Callback', @saveROI);

% Initialize stopFlag
stopFlag = 0;

% Initial display of images
updateImages(meanImageEnh_2, fig);


% While loop for interactive updates
while stopFlag == 0
    pause(0.5);

end

% Function to update images based on slider values
    function updateImages(~, ~, fig)
        % Get slider values
        localRegionSize = round(get(slider1, 'Value'));
        percentile = round(get(slider2, 'Value'));
        smoothingSigma = get(slider3, 'Value');
        holeFillRadius = round(get(slider4, 'Value'));
        minObjectArea = round(get(slider5, 'Value'));
        
        % disp(strcat(['localRegionSize = ', num2str(localRegionSize)]));
        % disp(strcat(['smoothingSigma = ', num2str(smoothingSigma)]));
        % disp(strcat(['holeFillRadius = ', num2str(holeFillRadius)]));
        % disp(strcat(['minObjectArea = ', num2str(minObjectArea)]));

        % Apply function to images based on slider values
        roi = extractROIAroundSkeleton(image_skeleton, meanImageEnh_2, localRegionSize, percentile);
        roi = smoothROI(roi, smoothingSigma, holeFillRadius, minObjectArea);

        % Display images using imshowpair
        subplot(2, 1, 1);
        imshowpair(meanImageEnh_2, roi);
        title('Overlayed ROI');

        subplot(2, 1, 2);
        imshow(meanImageEnh_2);
        title('Original Image');
    end

    function saveROI(~, ~)
        % Save the final ROI and close the interactive figure
        disp('Saving ROI...');
        stopFlag = 1;
        close(gcf);
    end
end
