function [image_skeleton_branches, objs, branch_masks] = handleBranches(image_skeleton, meanImageEnh_2, ymin, xmin, image)
% This function handles the branches in the skeletonized image.
%
% Inputs:
%   image_skeleton: The skeletonized image of the dendrite.
%   meanImageEnh_2: The enhanced image used for display purposes.
%   ymin, xmin: The minimum y and x coordinates of the ROI in the original image.
%   image: The original image.
%
% Outputs:
%   image_skeleton_branches: An array of the skeletonized branches.
%   objs: The properties of each branch.
%   branch_masks: The masks for each branch.

[x_branch, y_branch] = userGetBranchPoints(image_skeleton, meanImageEnh_2);
objs = [];

if any(x_branch) || any(y_branch) % if either vector isn't all zeros
    image_skeleton_branches = image_skeleton;

    % For each x branch, get the corresponding y_branch
    for i = 1:length(x_branch)
        curr_x_branch = x_branch(i);
        curr_y_branch = y_branch(i);

        % Remove a 7x7 box around that from the image_skeleton_branches
        image_skeleton_branches(round(curr_y_branch)-3:round(curr_y_branch)+3,round(curr_x_branch)-3:round(curr_x_branch)+3) = 0; % split up branches
    end

    % Now outside of the for loop removing a section for each branch
    % point, we're gonna make a zone for each section and ask the user
    % which ones they want to keep.
    objs = regionprops(image_skeleton_branches,'boundingbox','filledimage'); % get properties of each branch

    if length(objs) > 2
        % Assume meanImageEnh_2 is your background image
        figure, imshow(meanImageEnh_2, []);
        hold on;

        % Loop through each object and plot it on the image with its index
        for k = 1:length(objs)
            % Get the boundary of the k-th object
            boundary = bwboundaries(objs(k).FilledImage);

            % Plot the boundary and add the index as text
            plot(boundary{1}(:,2), boundary{1}(:,1), 'g', 'LineWidth', 2);
            text(mean(boundary{1}(:,2)), mean(boundary{1}(:,1)), num2str(k), 'Color', 'r');
        end

        % Ask the user which objects to keep
        prompt = 'Enter the indices of the objects to keep in brackets separated by spaces(e.g., [1 2]): ';
        indices = input(prompt);

        % Keep only the selected objects
        objs = objs(indices);
    end

    % I'm assuming this part is just for plotting it for the user,
    % correct me if I'm wrong

    branch_masks = cell(length(objs),1);
    all_masks = zeros(size(image));
    for bb = 1:length(objs)
        curr_branch = objs(bb).FilledImage;
        curr_boundingBox = objs(bb).BoundingBox;
        % upper left vertex translated to match where the ROI was in the original image
        curr_vertex = [curr_boundingBox(2)+ymin,curr_boundingBox(1)+xmin];
        se = strel('disk',10);
        di_branch = imdilate(curr_branch,se);
        branch_im = zeros(size(image));
        branch_im(round(curr_vertex(1)):round(curr_vertex(1))+size(di_branch,1)-1,...
            round(curr_vertex(2)):round(curr_vertex(2))+size(di_branch,2)-1) = di_branch;
        [y, x] = find(branch_im); % get coordinates
        curr_branch_mask = [x,y];
        branch_masks{bb} = curr_branch_mask;
        all_masks = all_masks + branch_im;
    end
else
    image_skeleton_branches = image_skeleton;
    branch_masks = {};
end
end
