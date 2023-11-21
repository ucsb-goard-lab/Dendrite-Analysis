function [subROIs, branchROIs] = getSubROIs(selected_PCs,microns)
% GETSUBROIS Extracts 2-micron ROIs from selected dendritic masks.
%
%   subROIs = getSubROIs(selected_PCs, microns)
%
%   Inputs:
%       - selected_PCs: An array of indices of selected dendritic masks.
%                       These can be obtained from the extractMainROIs function.
%       - microns: The size of the micron (e.g., 414 microns).
%                  This can be obtained from the getZoom function.
%
%   Output:
%       - subROIs: Structure array where each element corresponds to a dendritic mask.
%                  Each element contains a cell array of 2-micron ROIs.
%
%   Example:
%       subROIs = getSubROIs([31, 217, 29], 414);
%
%   See also: skeletonizeMeanGausProjection, connectBranchPoints,
%             extractROIAroundSkeleton, smoothROI.

fname = dir('*registered_data.mat');
reg_data = importdata(fname.name);
cell_masks = reg_data.cellMasks;
image = reg_data.avg_projection;

branchROIs = cell(1,length(selected_PCs)); % where each cell contains as many cells as there are branches
subROIs = cell(1,length(selected_PCs)); % where each cell contains a 3D array of 2-micron ROIs
for ii = 1:length(selected_PCs)
    curr_mask = cell2mat(cell_masks(ii*2)); % every 2nd ROI is the dendrite
    xmin = min(curr_mask(:,1));
    xmax = max(curr_mask(:,1));
    ymin = min(curr_mask(:,2));
    ymax = max(curr_mask(:,2));
    ROI_box = image(ymin:ymax,xmin:xmax); % part of image containing ROI

    %% User skeletonizes image to find branch points
    [image_skeleton, meanImageEnh_2] = skeletonizeMeanGausProjection(ROI_box,0);

    %% User selects the base of each branch
    answer = questdlg('Are there any branches in this dendrite?', 'Select Branch Bases', 'Yes', 'No', 'No');

    switch answer
        case 'Yes'
            % User selects the base of each branch
            branchBases = selectBranchBases(image_skeleton, ROI_box);

            % Separating branches based on selected bases
            separatedBranches = separateSkeletonIntoBranches(image_skeleton, branchBases);

            % for each of the separated image_skeletons, define an ROI
            separateROIs = cell(1, length(separatedBranches));
            for j = 1:length(separatedBranches)
                separateROIs{j} = interactiveROIAdjustment(separatedBranches{j}, meanImageEnh_2);
            end

            branchROIs{ii} = separateROIs;

        case 'No'
            % No branches, proceed with standard ROI adjustment
            subROIs{ii} = interactiveROIAdjustment(image_skeleton, meanImageEnh_2);

        otherwise
            % Handle unexpected answer
            error('Unexpected answer from user.');
    end

end

%%
subROIs = cellfun(@double, subROIs, 'UniformOutput', false);
branchROIs = cellfun(@(x) cellfun(@double, x, 'UniformOutput', false), branchROIs, 'UniformOutput', false);

end
