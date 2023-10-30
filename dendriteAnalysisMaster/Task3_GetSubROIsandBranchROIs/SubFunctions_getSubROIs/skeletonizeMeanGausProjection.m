function skeleton = skeletonizeMeanGausProjection(mean_image,show_image_steps)
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
binarizedImage = imbinarize(selected_dendrite_in_image,threshold);

% Skeletonize Binarized Branch
skeleton = skeletonizeBinarizedBranch(binarizedImage);
clf(fig);
imshowpair(meanImageEnh_2,skeleton)
set(gcf,'units','normalized','outerposition',[0 0 1 1])

answer = ' ';

while ~strcmp(answer,'No Change Needed')
    % Prompt the user if they want to edit the skeleton
    answer = questdlg('Would you like to edit the image further?', 'Options','Adjust Skeleton Sensitivity', 'Add or Remove Parts of Skeleton', 'No Change Needed','No Change Needed');

    if strcmp(answer, 'Adjust Skeleton Sensitivity')
        % Binarize the image with different thresholds
        threshold1 = threshold * 0.5;
        threshold2 = threshold;
        threshold3 = threshold * 1.50;
        skel1 = skeletonizeBinarizedBranch(imbinarize(selected_dendrite_in_image,threshold1));
        skel2 = skeletonizeBinarizedBranch(imbinarize(selected_dendrite_in_image,threshold2));
        skel3 = skeletonizeBinarizedBranch(imbinarize(selected_dendrite_in_image,threshold3));

        % Create composite images
        figure; imshowpair(skel1, meanImageEnh_2, 'montage'); comp1 = getframe(gcf); comp1 = comp1.cdata; close(gcf);
        figure; imshowpair(skel2, meanImageEnh_2, 'montage'); comp2 = getframe(gcf); comp2 = comp2.cdata; close(gcf);
        figure; imshowpair(skel3, meanImageEnh_2, 'montage'); comp3 = getframe(gcf); comp3 = comp3.cdata; close(gcf);

        % Display the composite images using montage
        clf(fig);
        montage({comp1, comp2, comp3}, 'Size', [1 3], 'BorderSize', 10, 'BackgroundColor', 'w');
        title(sprintf('thresholds shown = %.2f, %.2f, %.2f', threshold1, threshold2, threshold3));
        set(gcf,'units','normalized','outerposition',[0 0 1 1])

        % Prompt the user to select a threshold
        prompt = {'Enter a new threshold value:'};
        dlgtitle = 'Threshold Selection';
        dims = [1 35];
        definput = {num2str(threshold)};
        answerT = inputdlg(prompt, dlgtitle, dims, definput);

        % Binarize the image according to the user selected threshold
        threshold = str2double(answerT{1});
        binarizedImage = imbinarize(selected_dendrite_in_image,threshold);

        % Skeletonize Binarized Branch
        skeleton = skeletonizeBinarizedBranch(binarizedImage);
        clf(fig);
        imshowpair(meanImageEnh_2,skeleton)
        set(gcf,'units','normalized','outerposition',[0 0 1 1])
        continue;
    end

    if strcmp(answer, 'Add or Remove Parts of Skeleton')

        answer2 = ' ';
        % Prompt the user if they would like to remove parts of the skeleton
        while ~strcmp(answer2,'Neither')
            clf(fig);
            imshowpair(meanImageEnh_2,skeleton)
            set(gcf,'units','normalized','outerposition',[0 0 1 1])
            answer2 = questdlg('Would you like to remove or add objects?', 'Options','Remove Objects', 'Add Objects', 'Neither', 'Neither');

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
                    selected_dendrite_in_image(mask) = brightness_factor * selected_dendrite_in_image(mask);
                    binarizedImage = imbinarize(selected_dendrite_in_image,threshold);

                    % Skeletonize Binarized Branch
                    added_skeleton = skeletonizeBinarizedBranch(binarizedImage);
                    added_skeleton(~mask) = 0;
                    added_skeleton = logical(added_skeleton);
                    skeleton = logical(skeleton);
                    skeleton = imadd(skeleton,added_skeleton);
                    skeleton = imbinarize(skeleton, threshold);
                    clf(fig);
                    imshowpair(meanImageEnh_2,skeleton)
                    set(gcf,'units','normalized','outerposition',[0 0 1 1])

                elseif strcmp(answer2, 'Remove Objects')
                    skeleton(mask) = 0;
                end
            end
            continue;
        end
    end

end

close(fig);

end
