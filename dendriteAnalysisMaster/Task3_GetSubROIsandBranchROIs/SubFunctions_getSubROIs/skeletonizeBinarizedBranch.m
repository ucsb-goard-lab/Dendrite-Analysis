function skeleton = skeletonizeBinarizedBranch(binarizedImage)
% SKELETONIZEBINARIZEDBRANCH Skeletonizes a binarized image.
%   SKELETON = SKELETONIZEBINARIZEDBRANCH(BINARIZEDIMAGE) takes a binarized image as input,
%   performs morphological operations to thin the image to its skeleton, dilates it,
%   closes it, and then thins it again to its final skeleton form.
%
%   Written by MEK on 10/23/2024, Last ran on MATLAB 2023a
%
%   Input:
%       BINARIZEDIMAGE - A binary image.
%
%   Output:
%       SKELETON - The skeleton of the binarized image.

    % Perform initial thinning to get the skeleton
    skeleton    = bwmorph(binarizedImage,'thin',inf);
    se = strel('disk',3);
    di = imdilate(skeleton,se);
    closed = imclose(di,se);
    skeleton = bwmorph(closed,'thin',inf);
end
