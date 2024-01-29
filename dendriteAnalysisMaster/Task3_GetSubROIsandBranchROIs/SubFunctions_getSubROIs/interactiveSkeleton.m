function [skeleton, threshold] = interactiveSkeleton(selected_dendrite_in_image, meanImageEnh_2)
% interactiveSkeleton - Interactive skeletonization with a threshold slider.
%
% Usage:
%   skeleton = interactiveSkeleton(binarized_image, meanImageEnh_2)
%
% Parameters:
%   - binarized_image: Binarized image of the selected dendrite.
%   - meanImageEnh_2: Mean enhanced image.
%   - meanImageSub: Intermediary form for binarized image.
%
% This function allows the user to interactively adjust the skeletonization
% of the selected dendrite using a threshold slider. The resulting skeleton
% is overlayed with the mean enhanced image.
%

threshold = 0;

% Create a figure
fig = figure('Units', 'normalized', 'Position', [0, 0, 1, 1], 'Name', 'Interactive Skeletonization');

% Display images using imshowpair
subplot(2, 1, 1);
imshowpair(meanImageEnh_2, zeros(size(meanImageEnh_2)));
title('Overlayed Skeleton');

subplot(2, 1, 2);
imshow(meanImageEnh_2);
title('Original Image');

% Create a text title for the threshold slider
uicontrol('Style', 'text', 'Units', 'normalized', 'Position', [0.80, 0.6, 0.15, 0.25], 'String', 'Please use the slider to adjust skeleton sensitivity. You will have an opportunity to add and remove objects from the skeleton shortly.');

% Create a slider for the threshold
thresholdSlider = uicontrol('Style', 'slider', 'Min', 0, 'Max', 1, 'Value', 0.5, ...
    'Units', 'normalized', 'Position', [0.80, 0.65, 0.2, 0.05], 'Callback', @(src, event) updateSkeleton(src, event, fig), 'Tag', 'ThresholdSlider');

% Save button
saveButton = uicontrol('Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.85, 0.375, 0.1, 0.05], 'String', 'Save Skeleton', 'Callback', @saveSkel);

% Initialize stopFlag
stopFlag = 0;

% Initial display of images
updateSkeleton([], [], fig);

% While loop for interactive updates
while stopFlag == 0
    pause(0.5);

    % % Check if the figure is still open and the slider value is below 3
    % if ~isempty(get(0,'CurrentFigure')) && get(thresholdSlider, 'Value') < 3
    %     updateSkeleton([], [], fig);
    % end
end

% Function to update images based on threshold slider value
    function updateSkeleton(~, ~, fig)
        % Get the threshold value
        threshold = get(thresholdSlider, 'Value');

        % disp(strcat(['Threshold = ', num2str(threshold)]));

        % Apply skeletonization based on the threshold
        skeleton = skeletonizeBinarizedBranch(selected_dendrite_in_image,threshold);

        % Display images using imshowpair
        subplot(2, 1, 1);
        imshowpair(meanImageEnh_2, skeleton);
        title('Overlayed Skeleton');

        subplot(2, 1, 2);
        imshow(meanImageEnh_2);
        title('Original Image');
    end

    function saveSkel(~, ~)
        % Save the final skeleton and close the interactive figure
        disp('Saving Skeleton...');
        stopFlag = 1;
        close(gcf);
    end
end
