function BW = binarizeMeanGausProjection_NSWEdit(mean_image,image_name,...
    binarized_branch_images,show_image_steps,numPixelsOfEachImage,...
    skip_manual_binarization, resize_imgs_if_needed, save_img_flag)
% Function binarizes mean Gaussian Projection converted from tif files of
% microscopy images and resizes them to be consistent sizing if necessary

% Written by MEK
% Last running on Matlab 2022b
% Last updated April 28, 2023

% Function includes code lines 4-28 from SuperResolution Function by WTR
% Function also uses part of procedure of "An open-source tool for analysis
% and automatic identification of dendritic spines using machine learning"
% by Smirnov and colleagues published in 2018.
% Also uses helper function natsortfiles published on mathworks by Stephen23

%%
if (nargin < 4)
    show_image_steps = 0;
    numPixelsOfEachImage = 760;
    skip_manual_binarization = 0;
    resize_imgs_if_needed = 1;
elseif (nargin < 5)
    numPixelsOfEachImage = 760;
    skip_manual_binarization = 0;
    resize_imgs_if_needed = 1;
elseif (nargin < 6)
    skip_manual_binarization = 0;
    resize_imgs_if_needed = 1;
elseif (nargin < 7)
    skip_manual_binarization = 0;
    resize_imgs_if_needed = 1;
end

% %% For testing purposes import data with this:
% [image_name,file_path] = uigetfile('Select data file');
% data = load(fullfile(file_path,image_name));
% mean_image = data.gaus_mean_projection;
% binarized_branch_images = 'C:\Users\Goard Lab\Dropbox\CodeInBeta_Marie\DendriticSpines\Data\binarizedBranches';
% show_image_steps = 1;
% numPixelsOfEachImage = 760;
% skip_manual_binarization = 0;
% resize_imgs_if_needed = 1;
%
% %set path for helper functions - gen path gets all subfolders too
% addpath(genpath('C:\Users\Goard Lab\Dropbox\CodeInBeta_Marie\DendriticSpines\Functions'));
%
% %add path for data
% addpath(file_path)


%% Resizing Image
if resize_imgs_if_needed == 1
    s4 = size(mean_image);

    % mean image is only resized to restore the image size to be consistent with
    % the rest of the dataset and to validly align with the recorded micrometer
    % dimension of each image

    if s4(1) < numPixelsOfEachImage
        mean_image = vertcat(mean_image,zeros(numPixelsOfEachImage-s4(1),s4(2)));
    end
    if s4(2) < numPixelsOfEachImage
        mean_image = horzcat(mean_image,zeros(numPixelsOfEachImage,numPixelsOfEachImage-s4(2)));
    end
    if (s4(1) > numPixelsOfEachImage || s4(2) > numPixelsOfEachImage)
        mean_image = imresize(mean_image,(numPixelsOfEachImage/(max(s4(1),s4(2)))));
        s4 = size(mean_image);
        if s4(1) < numPixelsOfEachImage
            mean_image = vertcat(mean_image,zeros(numPixelsOfEachImage-s4(1),s4(2)));
        end
        if s4(2) < numPixelsOfEachImage
            mean_image = horzcat(mean_image,zeros(numPixelsOfEachImage,numPixelsOfEachImage-s4(2)));
        end
        if s4(1) > numPixelsOfEachImage
            mean_image = mean_image(1:numPixelsOfEachImage,:);
        end
        if s4(2) > numPixelsOfEachImage
            mean_image = mean_image(:,1:numPixelsOfEachImage);
        end
        % For testing purposes uncomment these lines:
        % disp('size of dendrite after padding')
        % disp(num2str(size(dendrite)))
        % disp(num2str(numPixelsOfEachImage-s(1)))
        % disp(num2str(numPixelsOfEachImage-s(2)))

    end
end

%% checking if image has already been binarized
oldFolder = cd(binarized_branch_images);

file_list = struct2cell(dir('**/*.*'));
BW_images = natsortfiles(file_list(1,:));
cd(oldFolder)

fname = (strcat(erase(image_name,'.mat'),'.png'));
ind=find(ismember(BW_images(1,:),fname), 1);
%%
if isempty(ind) %if it hasn't then binarize it

    %mean_image = mat2gray(mean_image); %normalizes grayscale to a range of [0, 1]
    mean_image = mat2gray(mean_image);
    
    diameter   = [12 12];
    parameter  = [6 -6];

    % from superResolution function:
    meanImageFiltered = medfilt2(mean_image,(diameter)*4+1);
    % [counts,~]        = imhist(meanImageFiltered);
    % threshold         = otsuthresh(counts)*0.9;
    % I                 = imbinarize(meanImageFiltered,threshold);
    % value        = 10;
    % I(1:value,:) = 0; I(end-value:end,:) = 0; % top  & bottom part
    % I(:,1:value) = 0; I(:,end-value:end) = 0; % left & right  part
    %
    % se = strel('disk',35);
    % BW = imbinarize(imgaussfilt(double(I),3),0.55);
    %montage({im,mean_image,I,BW})

    %%
    %remove noise with 2d median filter
    meanImageSub        = mean_image - meanImageFiltered;
    meanImageFiltered_2 = medfilt2(abs(meanImageSub),(diameter)*4+1); %empty?

    meanImageDiv   = meanImageSub ./ (1e-10 + meanImageFiltered_2); %r
    meanImageDiv_2 = meanImageSub ./ (1e+10 + meanImageFiltered_2);%empty?

    meanImageEnh = (meanImageDiv - parameter(2)) / (parameter(1) - parameter(2)); %r
    meanImageEnh = max(0,min(1,meanImageEnh)); %r

    meanImageEnh_2 = (meanImageDiv_2 - parameter(2)) / (parameter(1) - parameter(2));
    meanImageEnh_2 = mat2gray(max(0,min(1,meanImageEnh_2)));

    meanImageEnh_2 = imadjust(meanImageEnh_2);
    meanImageEnh_2 = medfilt2(meanImageEnh_2,[6 6]);

    II = meanImageEnh + meanImageEnh_2; %r

    % from dendriticSpineImg Pro :
    %imhist(I)
    [counts,~] = imhist(II);
    threshold    = otsuthresh(counts);

    % UPDATED: Automatic Threshold Selection from Histogram of image
    % inspired by:
    % https://onlinelibrary.wiley.com/doi/full/10.1002/cyto.a.20431

    I            = imbinarize(II,threshold);
    value        = 10;
    I(1:value,:) = 0; I(end-value:end,:) = 0; % top  & bottom part
    I(:,1:value) = 0; I(:,end-value:end) = 0; % left & right  part
    se1          = strel('disk',3);
    I            = imopen(I,se1);

    se = strel('disk',35);
    BW = (imbinarize(imdilate((imbinarize(double(meanImageSub), 0.15)),se).*I));
    BW = imbinarize(imgaussfilt(double(BW),3),0.55);
    perimeter = sum(sum(bwperim(BW)));

    if show_image_steps == 1
        figure
        montage({mean_image,meanImageFiltered,meanImageSub,meanImageFiltered_2,meanImageDiv,I,meanImageEnh,meanImageDiv_2,meanImageEnh_2,BW});
    end


    if skip_manual_binarization == 0
        % Show the image

        answer = ' ';

        while ~strcmp(answer,'No Change Needed')
            imshowpair(meanImageEnh_2,BW)
            % Prompt the user if they want to binarize it further
            answer = questdlg('Would you like to edit the image further?', 'Options','Re-binarize (new threshold)', 'Add or Remove Objects', 'No Change Needed','No Change Needed');

            if strcmp(answer, 'Re-binarize (new threshold)')
                % Binarize the image with different thresholds
                threshold1 = threshold * 0.75;
                threshold2 = threshold;
                threshold3 = threshold * 1.25;
                BW1 = imbinarize(II, threshold1);
                BW2 = imbinarize(II, threshold2);
                BW3 = imbinarize(II, threshold3);

                % Show the montage of binarized images at different thresholds
                montage({BW1, BW2, BW3}, 'Size', [1 3], 'BorderSize', 10, 'BackgroundColor', 'w');
                title(sprintf('threshold = %.2f, %.2f, %.2f', threshold1, threshold2, threshold3));

                % Prompt the user to select a threshold
                prompt = {'Enter the threshold value:'};
                dlgtitle = 'Threshold Selection';
                dims = [1 35];
                definput = {num2str(threshold)};
                answerT = inputdlg(prompt, dlgtitle, dims, definput);

                % Binarize the image according to the user selected threshold
                userSelectedThreshold = str2double(answerT{1});
                BW = imbinarize(II,userSelectedThreshold);
                value = 10;
                BW(1:value,:) = 0; BW(end-value:end,:) = 0; % top  & bottom part
                BW(:,1:value) = 0; BW(:,end-value:end) = 0; % left & right  part
                se1 = strel('disk',3);
                BW = imopen(BW,se1);
                se = strel('disk',35);
                BW = (imbinarize(imdilate((imbinarize(double(meanImageSub), 0.15)),se).*BW));
                BW = imbinarize(imgaussfilt(double(BW),3),0.55);

                continue;
            end

            if strcmp(answer, 'Add or Remove Objects')

                answer2 = ' ';
                % Prompt the user if they would like to remove or add spines
                while ~strcmp(answer2,'Neither')
                    imshowpair(meanImageEnh_2,BW)
                    answer2 = questdlg('Would you like to remove or add objects?', 'Options','Remove Objects', 'Add Objects', 'Neither', 'Neither');

                    if or(strcmp(answer2, 'Add Objects'), strcmp(answer2, 'Remove Objects'))
                        % Draw polygon and create mask
                        imshowpair(meanImageEnh_2,BW)
                        roi = msgbox('Please draw a polygon by selecting points that eventually connect together to select the parts of the image you wish to add or remove from the binarized image.','Instructions');
                        waitfor(roi)
                        roi = drawpolygon();
                        mask = createMask(roi);

                        if strcmp(answer2, 'Add Objects')
                            % Add spines or dendrite
                            addBack = imbinarize(II, threshold*0.8);
                            addBack(~mask) = 0;
                            BW = imbinarize(imadd(BW,addBack,0.9));
                            % Object will be smoothed at the end!
                        elseif strcmp(answer2, 'Remove Objects')
                            BW(mask) = 0;
                        end
                        % Prompt the user again if they added or removed spines
                    end
                    continue;
                end
            end

        end

    end

else
    %image already binarized
    oldFolder = cd(binarized_branch_images);
    BW = load(image_name);
    BW = BW.gaus_mean_projection;
    % an error may appear and you may have to add the image to the path if it's not in the given binarized folder
    cd(oldFolder);
end


% Show final image;
BW = imbinarize(imgaussfilt(double(BW),3),0.75);
imshow(BW);
title('Binarized Image')

if save_img_flag
    oldFolder = cd(binarized_branch_images);
    imwrite(BW,strcat([image_name(1:end-4),'.png']))
    cd(oldFolder)
end


end
