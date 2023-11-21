function skeleton = skeletonizeBinarizedBranch(selected_dendrite_in_image, threshold, meanImageSub)
% SKELETONIZEBINARIZEDBRANCH Skeletonizes a binarized image.
%   SKELETON = SKELETONIZEBINARIZEDBRANCH(BINARIZEDIMAGE) takes a binarized image as input,
%   performs morphological operations to thin the image to its skeleton, dilates it,
%   closes it, and then thins it again to its final skeleton form.
%
%   Input:
%       BINARIZEDIMAGE - A binary image.
%
%   Output:
%       SKELETON - The skeleton of the binarized image.
%
%   Written by MEK on 10/23/2023, Last ran on MATLAB 2023a
binarizedImage = imbinarize(selected_dendrite_in_image,threshold);
skeleton    = bwmorph(binarizedImage,'thin',inf);
se = strel('disk',3);
di = imdilate(skeleton,se);
closed = imclose(di,se);
skeleton = bwmorph(closed,'thin',inf);

% skeleton = bwmorph(skeleton,'bridge');
% skeleton = bwmorph(skeleton,'clean');
% skeleton = bwmorph(skeleton,'diag');
% skeleton = bwmorph(skeleton,'fill');
% skeleton = bwmorph(skeleton,'spur',inf);
% skeleton = bwmorph(skeleton,'thin',inf);

end
