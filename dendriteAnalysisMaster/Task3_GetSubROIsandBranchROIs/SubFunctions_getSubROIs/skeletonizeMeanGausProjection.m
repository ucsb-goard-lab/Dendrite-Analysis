function [skeleton, meanImageEnh_2] = skeletonizeMeanGausProjection(mean_image,show_image_steps)
% Function binarizes mean Gaussian Projection converted from tif files of
% microscopy images and resizes them to be consistent sizing if necessary

% Inputs:
% - mean_image: The mean image to be binarized.
% - image_name: The name of the image.
% - save_dir_location: The path to save the binarized branch images.
% - show_image_steps: A flag to indicate whether to show image steps. Default is 0 (false).
% - save_img_flag: A flag to indicate whether to save the image. Default is 0 (false).

% Outputs:
% - binarizedImage: The binarized output image.

% Written by MEK, Edited by NSW
% Last running on Matlab 2023a
% Last updated Otctober 22, 2023

% Function includes code lines 4-28 from SuperResolution Function by WTR
% Function also uses part of procedure of "An open-source tool for analysis
% and automatic identification of dendritic spines using machine learning"
% by Smirnov and colleagues published in 2018.
% Also uses helper function natsortfiles published on mathworks by Stephen23

if (nargin < 2)
    show_image_steps = 0;
end

if isempty(mean_image)
    error('Input mean_image is empty. Ensure you are drawing a boundary around the dendrite in step 2: extract main ROIs');
end

% Define constants
diameter   = [12 12];
parameter  = [6 -6];
brightness_factor = 1.5;

%normalize grayscale to a range of [0, 1]
mean_image = mat2gray(mean_image);

% Apply a 2D median filter to the mean image. The filter size is determined by the diameter.
meanImageFiltered = medfilt2(mean_image,(diameter)*4+1);

% Subtract the filtered image from the original mean image to remove noise.
meanImageSub = mean_image - meanImageFiltered;

% Apply a 2D median filter to the absolute value of the subtracted image.
meanImageFiltered_2 = medfilt2(abs(meanImageSub),(diameter)*4+1);

% Divide the subtracted image by the filtered subtracted image. A small constant is added to the denominator to avoid division by zero.
meanImageDiv = meanImageSub ./ (1e-10 + meanImageFiltered_2);

% Repeat the division operation with a larger constant in the denominator.
meanImageDiv_2 = meanImageSub ./ (1e+10 + meanImageFiltered_2);

% Normalize and scale the second divided image based on a parameter.
meanImageEnh_2 = (meanImageDiv_2 - parameter(2)) / (parameter(1) - parameter(2));
meanImageEnh_2 = mat2gray(max(0,min(1,meanImageEnh_2)));

% Adjust the contrast of the enhanced image and apply a 2D median filter.
meanImageEnh_2 = imadjust(meanImageEnh_2);
meanImageEnh_2 = medfilt2(meanImageEnh_2,[6 6]);

% Normalize and scale the first divided image based on a parameter.
meanImageEnh = (meanImageDiv - parameter(2)) / (parameter(1) - parameter(2));
meanImageEnh = max(0,min(1,meanImageEnh));

% Combine both enhanced images to get the final enhanced image.
enhancedImage = meanImageEnh + meanImageEnh_2;

if show_image_steps == 1
    figure
    montage({mean_image,meanImageFiltered,meanImageSub,meanImageFiltered_2,meanImageDiv,meanImageDiv_2,meanImageEnh, meanImageEnh_2,enhancedImage});
end

% Otsu's threshold fr initial binarization threshold
[counts,~] = imhist(enhancedImage);
threshold  = otsuthresh(counts);

% Binarized image
binarizedImage = mat2gray(zeros(size(meanImageEnh_2)));

fig = figure;

% Have the user draw an ROI around the binarized dendrite for editing
imshowpair(meanImageEnh_2,binarizedImage)
title('Please select the dendrite by drawing a polygon. Your last point should connect to your first point.','Color', 'b');
set(gcf,'units','normalized','outerposition',[0 0 1 1])
roi = drawpolygon();
selected_dendrite = createMask(roi);
selected_dendrite_in_image = im2double(meanImageEnh_2);
selected_dendrite_in_image(~selected_dendrite) = 0;
close(gcf);  % Close the figure

%%
[skeleton, threshold] = interactiveSkeleton(selected_dendrite_in_image, meanImageEnh_2);

%%
fig = figure;
clf(fig);
imshowpair(meanImageEnh_2,skeleton)
set(gcf,'units','normalized','outerposition',[0 0 1 1])

answer2 = ' ';
% Prompt the user if they would like to remove parts of the skeleton
while ~strcmp(answer2,'Neither')
    clf(fig);
    imshowpair(meanImageEnh_2,skeleton)
    set(gcf,'units','normalized','outerposition',[0 0 1 1])
    answer2 = questdlg('Would you like to remove or add objects? If two points will not connect even when adding the section between them, you will have the oppportunity to connect these points in the next dialog.', 'Options','Remove Objects', 'Add Objects', 'Neither', 'Neither');

    if or(strcmp(answer2, 'Add Objects'), strcmp(answer2, 'Remove Objects'))
        % Draw polygon and create mask
        clf(fig);
        imshowpair(meanImageEnh_2,skeleton)
        set(gcf,'units','normalized','outerposition',[0 0 1 1])
        title('Please select the parts you wish to add or remove by drawing a polygon. Your last point should connect to your first point.','Color', 'b');
        waitfor(roi)
        roi = drawpolygon();
        mask = createMask(roi);

        if strcmp(answer2, 'Add Objects')
            selected_dendrite_in_image = im2double(meanImageEnh_2);
            selected_dendrite = logical(selected_dendrite);
            selected_dendrite = imadd(selected_dendrite,mask);
            selected_dendrite_in_image(~selected_dendrite) = 0;
            selected_dendrite_in_image(mask) = selected_dendrite_in_image(mask) .* brightness_factor ;

            % Skeletonize Binarized Branch
            added_skeleton = skeletonizeBinarizedBranch(selected_dendrite_in_image,threshold);
            added_skeleton(~mask) = 0;
            added_skeleton = logical(added_skeleton);
            skeleton = logical(skeleton);
            skeleton = imadd(skeleton,added_skeleton);
            skeleton = bwmorph(skeleton,'bridge');
            skeleton = bwmorph(skeleton,'clean');
            skeleton = bwmorph(skeleton,'diag');
            skeleton = bwmorph(skeleton,'fill');
            skeleton = bwmorph(skeleton,'spur',inf);
            skeleton = bwmorph(skeleton,'thin');

            clf(fig);
            imshowpair(meanImageEnh_2,skeleton)
            set(gcf,'units','normalized','outerposition',[0 0 1 1])

        elseif strcmp(answer2, 'Remove Objects')
            skeleton(mask) = 0;
        end

    end
end

close(fig);

%% User connects any points if the skeleton is disconnected
CC = bwconncomp(skeleton);
if CC.NumObjects == 1
    % The image skeleton object is fully connected
else
    % The image skeleton object is not fully connected
    answer = "Yes";
    while answer ~= "No" % if user does want to connect branch points
        % insert branch handling, make sure the output variables are available outside of this else statement scope though
        skeleton = connectBranchPoints(skeleton,mean_image);
        answer = questdlg('Do you want to connect more branch points?', 'Connect Branch Points', 'Yes', 'No', 'No');
    end
end

end

