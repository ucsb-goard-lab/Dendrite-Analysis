function separatedBranches = separateSkeletonIntoBranches(image_skeleton, branchBases)
% REMOVEBRANCHAREAS Removes small areas around each branch base in image_skeleton.
%
%   separatedBranches = removeBranchAreas(image_skeleton, branchBases)
%
%   Inputs:
%       - image_skeleton: Binary image representing the skeleton of the dendrite.
%       - branchBases: A matrix where each row represents the coordinates (x, y)
%                      of a selected branch base.
%
%   Output:
%       - separatedBranches: A cell array where each cell contains a separate image_skeleton.
%

separatedBranches = cell(1, size(branchBases, 1));
pos_end = 0;
masked_image = false(size(image_skeleton));

for i = 1:size(branchBases, 1)
    % Extract a smaller area around each branch base
    x = round(branchBases(i, 1));
    y = round(branchBases(i, 2));
    radius = round(size(image_skeleton)/100); % Adjust the radius as needed
    [rows, cols] = size(image_skeleton);

    % Ensure indices are within the image bounds
    x_start = max(1, x - radius);
    x_end = min(cols, x + radius);
    y_start = max(1, y - radius);
    y_end = min(rows, y + radius);

    % Create a mask to remove the smaller area around the branch base
    mask = ones(size(image_skeleton));
    mask(y_start:y_end, x_start:x_end) = 0;
    masked_image = image_skeleton .* mask;
    imshow(masked_image);
end

% Use bwconncomp to get connected components
CC = bwconncomp(masked_image);
imshow(masked_image);
disp(strcat(['Found ',num2str(CC.NumObjects),' pieces of the dendrite']));

% Save each connected component as a separate image_skeleton
for j = 1:CC.NumObjects

    temp = zeros(size(image_skeleton));
    temp(CC.PixelIdxList{j}) = 1;

    % Check if the number of pixels in temp is above a threshold
    if nnz(temp) > 10  % Adjust the threshold as needed
        separatedBranches{pos_end+1} = temp;
        pos_end = pos_end +1;
    end
end
end
