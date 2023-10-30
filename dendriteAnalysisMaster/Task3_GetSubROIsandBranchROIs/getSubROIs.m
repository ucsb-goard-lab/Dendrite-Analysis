function [subROIs, branchROIs] = getSubROIs(selected_PCs,microns)
%   This function takes selected dendritic masks and breaks them down into
%   2-micron chunks and individual branches. It also performs various
%   operations to process the masks and extract sub-ROIs and branch ROIs.
%
%   Input:
%       - selected_PCs: An array of indices of selected dendritic masks.
%                       These can be obtained from the extractMainROIs function.
%       - microns: The size of the micron (e.g., 414 microns). This can be
%                  obtained from the getZoom function.
%
%   Output:
%       - subROIs: Cell array containing 2-micron ROIs.
%       - branchROIs: Cell array containing individual branch ROIs.
%
%   Example:
%       [subROIs, branchROIs] = getSubROIs([31, 217, 29], 414);
%
%   See also: binarizeMeanGausProjection_NSWEdit, getBranchPoints_NSWEdit,
%             bwtraceboundary, pgonCorners.


ROI_size = 6; % microns for subROI splitting !ASK why 6 again?
fname = dir('*registered_data.mat');
reg_data = importdata(fname.name);
cell_masks = reg_data.cellMasks;
image = reg_data.avg_projection;
pixels = round((ROI_size * microns)/size(image,1)); % how many pixels in X microns

branchROIs = cell(1,length(selected_PCs)); % where each cell contains as many cells as there are branches
subROIs = cell(1,length(selected_PCs)); % where each cell contains a 3D array of 2-micron ROIs
for ii = 1:length(selected_PCs)
    curr_mask = cell2mat(cell_masks(ii*2)); % every 2nd ROI is the dendrite
    xmin = min(curr_mask(:,1));
    xmax = max(curr_mask(:,1));
    ymin = min(curr_mask(:,2));
    ymax = max(curr_mask(:,2));
    ROI_box = image(ymin:ymax,xmin:xmax); % part of image containing ROI

    % User skeletonizes image to find branch points
    image_skeleton = skeletonizeMeanGausProjection(ROI_box,0);

    % User connects any branch points if the skeleton is disconnected
    CC = bwconncomp(image_skeleton);
    if CC.NumObjects == 1
        % The image skeleton object is fully connected
    else
        % The image skeleton object is not fully connected
        answer = "Yes";
        while answer ~= "No" % if user does want to connect branch points
            answer = questdlg('Would you like to connect branch points?', ...
            'Options', 'Yes','No','No');
            if strcmp(answer,'Yes')
            image_skeleton = connectBranchPoints(image_skeleton,ROI_box);
            end
        end
    end

    [x_end   , y_end]    = find((bwmorph(image_skeleton, 'endpoints'))');
    [x_branch, y_branch] = getBranchPoints_NSWEdit(image_skeleton,x_end, y_end);
    objs = [];

    if any(x_branch) || any(y_branch) % if either vector isn't all zeros
        min_x = find(x_branch);
        x_branch = x_branch(min_x(1)); % to get rid of random zeros and whatnot
        y_branch = y_branch(min_x(1));
        image_skeleton_branches = image_skeleton;
        image_skeleton_branches(round(y_branch(1))-3:round(y_branch(1))+3,round(x_branch(1))-3:round(x_branch(1))+3) = 0; % split up branches
        objs = regionprops(image_skeleton_branches,'boundingbox','filledimage'); % get properties of each branch
        if length(objs) > 2
            objs(3) = []; % if the dendritss
            %if contains a branch, remove the farthest right segment, which should be the main process
        end
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
        RGB_masks = cat(3, all_masks * 1, all_masks * 0, all_masks * 0); % pseudocolor masks red
        all_masks(find(all_masks)) = 0.5; % scale for AlphaData

        % plot results
        figure
        subplot(1,3,1)
        imagesc(ROI_box)
        title('Image segment')
        subplot(1,3,2)
        imshow(image_skeleton)
        axis square
        title('Skeletonized dendrite')
        subplot(1,3,3)
        imagesc(image);
        hold on
        im = imshow(RGB_masks);
        set(im, 'AlphaData', all_masks);
        axis square
        title('Dendritic branch masks')
        sgtitle('Dendritic Branch ROI Isolation')

        branchROIs{ii} = branch_masks; % save branches of bigger cell to the
    else
        se = strel('disk',10);
        di = imdilate(image_skeleton,se);
        closed = imclose(di,se);
        image_skeleton =  bwmorph(closed,'thin',inf);
        se = strel('disk',10);
        di = imdilate(image_skeleton,se); % do one more time to get dilated whole skeleton
        disp('No branches found: continuing to subROI detection')
        figure
        imshow(image_skeleton)
        title('Image Skeleton (no branches)')
    end

    skeleton_parts = regionprops(image_skeleton);
    if length(skeleton_parts) > 1 % if part of the dendrite was missed
        image_skeleton = connectBranchPoints(image_skeleton,ROI_box);
        figure
        imshow(image_skeleton)
        title('Corrected image skeleton')
    end

    %% Skeleton Positioning: positioning the skeleton on the whole image based on its coordinates.
    skeleton_im = zeros(size(image));
    skeleton_im(ymin:ymax,xmin:xmax) = image_skeleton; % put skeleton in position on whole image

    [y,x] = find(skeleton_im);
    skeleton_coords = [x,y];

    %% Branch Handling & breaking the image into chunks at angles perpendicular to the dendrite
    if ~isempty(objs) % if there are branches, re-order skeleton coordinates so that it doesn't switch between branches
        blank_boundary_im = zeros(size(image));
        blank_boundary_im(ymin:ymax, xmin:xmax) = image_skeleton_branches;
        boundaries = bwboundaries(blank_boundary_im);
        b1 = boundaries{1};
        b1(floor(length(b1)/2):end,:) = []; % get rid of repeated coords
        % b1 = unique(b1,'rows');
        other_branches = skeleton_im;
        for b = 1:size(b1,1)
            curr_b = b1(b,:);
            other_branches(curr_b(1),curr_b(2)) = 0; % get rid of first branch coords
         end
        [yo,xo] = find(other_branches);
        skeleton_coords = [[b1(:,2);xo],[b1(:,1);yo]];
        first_other = [xo(1),yo(1)];
    end

    mask_im = zeros(size(image)); % create whole dendrite mask as binary image
    mask_im(ymin:ymax,xmin:xmax) = di;
    [ym,xm] = find(mask_im); % get coordinates of mask
    mask_boundary = bwtraceboundary(mask_im,[ym(1),xm(1)],'N'); % output = y,x

    new_cellMask = [mask_boundary(:,2),mask_boundary(:,1)];
    reg_data.cellMasks{ii*2} = new_cellMask; % replace hand-drawn mask with 10-pixel wide mask

    % calculate results and plot as you go
    blank_plotting_im = zeros(size(image));
    figure
    title('subROIs')
    curr_subROIs = cell(ceil(length(skeleton_coords)/pixels),1);
    last_top = [ym(1),xm(1)]; % presets for first pixel
    last_bottom = [ym(1),xm(1)];
    last_curr = [xm(1),ym(1)];
    cmap = jet(floor(length(skeleton_coords)/pixels));

    for ss = 1:floor(length(skeleton_coords)/pixels) % for each sub-ROI
        % find the two closest boundary points to the center pixel point
        % and draw a line between them
        blank_im = zeros(size(image));
        if ss > 1
            last_curr = curr_pixel; % previous current pixel
            % last_curr(1) = last_curr(1) + 1; % move over one column
            last_top = top_vertex;
            % last_top(2) = last_top(2) + 1;
            last_bottom = bottom_vertex;
            % last_bottom(2) = last_bottom(2) + 1;
        end
        curr_pixel = skeleton_coords(ss*pixels,:); % in x,y format
        above_idx = find(mask_boundary(:,1)>curr_pixel(2));
        mask_top = mask_boundary(above_idx,:);
        k = dsearchn([mask_top(:,2),mask_top(:,1)],curr_pixel); % find index of closest coordinate above current pixel
        top_vertex = mask_top(k,:); %y,x: closest coordinate above current pixel
        below_idx = find(mask_boundary(:,1)<curr_pixel(2));
        mask_bottom = mask_boundary(below_idx,:);
        k2 = dsearchn([mask_bottom(:,2),mask_bottom(:,1)],curr_pixel); % find index of closest coordinate below current pixel
        bottom_vertex = mask_bottom(k2,:); %y,x: closest coordinate below current pixel
        if abs(top_vertex(1) - bottom_vertex(1)) < 5 % if bottom vertex gets switched to top, or vice versa
            if top_vertex(2) < curr_pixel(1) % if top coord got translated to the left
                % get rid of pixels to the left of current pixel
                mask_top(find(mask_top(:,2)>curr_pixel(1)),:) = [];
                % re-calculate top vertex
                k_edit = dsearchn([mask_top(:,2),mask_top(:,1)],curr_pixel);
                top_vertex = mask_top(k_edit,:);
            end
            if bottom_vertex(2) > curr_pixel(1) % if bottom coord got translated to the left
                % get rid of pixels to the right of current pixel
                mask_bottom(find(mask_bottom(:,2)<curr_pixel(1)),:) = [];
                % re-calculate bottom vertex
                k2_edit = dsearchn([mask_bottom(:,2),mask_bottom(:,1)],curr_pixel);
                bottom_vertex = mask_bottom(k2_edit,:);
            end
        end
        if abs(top_vertex(1) - last_top(1)) > 20 || abs(top_vertex(2) - last_top(2)) > 20 % if difference is too high (i.e. with branches) calculate from image
            % find closest boundary point in blank_plotting_im
            plotting_im_bw = imbinarize(blank_plotting_im);
            if size(plotting_im_bw,3) > 1
                plotting_im_bw = plotting_im_bw(:,:,3); % make 2D if not already
            end
            plotting_im_bw = bwareaopen(plotting_im_bw,20); % to remove random pixels
            bw_props = regionprops(plotting_im_bw);
            if length(bw_props) > 1  % if there's more than one region (i.e. two branches), and not the first pixel of the second branch
                top_corners = zeros(length(bw_props),2);
                for b = 1:length(bw_props)
                    curr_corner = bw_props(b).BoundingBox(1:2); % translate to top right corner
                    top_corners(b,1:2) = [curr_corner(1)+bw_props(b).BoundingBox(3),curr_corner(2)];
                end
                k_branch = dsearchn(top_corners,curr_pixel);
                box2keep = bw_props(k_branch).BoundingBox;
                im2keep = plotting_im_bw(floor(box2keep(2)):floor(box2keep(2))+ceil(box2keep(4)),...
                    floor(box2keep(1)):floor(box2keep(1))+ceil(box2keep(3))); % remove other region
                plotting_im_bw = zeros(size(plotting_im_bw));
                plotting_im_bw(floor(box2keep(2)):floor(box2keep(2))+ceil(box2keep(4)),...
                    floor(box2keep(1)):floor(box2keep(1))+ceil(box2keep(3))) = im2keep;
                bw_props = bw_props(k_branch); % just take current branch
            end
            if ~isempty(bw_props)
                if abs(curr_pixel(1) - first_other(1)) > 4 && abs(curr_pixel(2) - first_other(2)) > 4  % if not first pixel of second branch
                    if ss > 100 % because first iterations should have smaller dendritic chunks
                        plotting_im_bw = bwareaopen(plotting_im_bw,20); % get rid of extraneous objects
                    end
                    bw_props2 = regionprops(plotting_im_bw);
                    if length(bw_props2) > 1 % if some other weird object was included
                        bw_lengths = zeros(length(bw_props2),2);
                        for b = 1:length(bw_props2)
                            bw_lengths(b,1:2) = bw_props2(b).BoundingBox(3:4);
                        end
                        bw_sum = bw_lengths(:,1) + bw_lengths(:,2);
                        [~,max_obj_idx] = max(bw_sum);
                        bw_props2(max_obj_idx) = []; % take out main object, leave rest to delete
                        for bb = 1:length(bw_props2) % delete all smaller objects, leaving only one
                            curr_region = bw_props2(bb).BoundingBox; % (otherwise messes up bwtraceboundary)
                            plotting_im_bw(floor(curr_region(2)):floor(curr_region(2))+ceil(curr_region(4)),...
                                floor(curr_region(1)):floor(curr_region(1))+ceil(curr_region(3))) = 0;
                        end
                    end
                    [yp,xp] = find(plotting_im_bw); % get coordinates of mask
                    plotting_boundary = bwtraceboundary(plotting_im_bw,[yp(1),xp(1)],'N');

                    corners = pgonCorners(plotting_im_bw,5); % assumes 5 edges
                    corner_sum = corners(:,1) + corners(:,2);
                    last_top = [round(corners(find(corner_sum == max(corner_sum)),1)),...
                        round(corners(find(corner_sum == max(corner_sum)),2))]; % upper right corner
                    if size(last_top,1) > 1
                        last_top = last_top(2,:);
                    end

                    k_curr = dsearchn([plotting_boundary(:,2),plotting_boundary(:,1)],curr_pixel);
                    last_curr = [round(plotting_boundary(k_curr,2)),round(plotting_boundary(k_curr,1))]; % closest point to curr on previous shape boundary
                    % find farthest right point of the points below last_curr
                    below_curr = corners(find(corners(:,1)<last_curr(2)),:);
                    [~,lrow_idx] = max(below_curr(:,2)); % farthest right of the low points
                    last_bottom = round(below_curr(lrow_idx,:)); % bottom right corner
                    if isempty(last_bottom)
                        top_curr_diff = round(abs(last_top(1) - last_curr(2)));
                        last_bottom = [last_curr(2)-top_curr_diff,last_curr(1)-1];
                    end
                else % if this is the first pixel on the other branch
                    last_top = top_vertex;
                    last_top(2) = top_vertex(2) - 2;
                    last_bottom = bottom_vertex;
                    last_bottom(2) = bottom_vertex(2) - 2;
                    last_curr = curr_pixel;
                    last_curr(1) = curr_pixel(1) - 2;
                end
            else
                last_top = top_vertex;
                last_top(2) = top_vertex(2) - 2;
                last_bottom = bottom_vertex;
                last_bottom(2) = bottom_vertex(2) - 2;
                last_curr = curr_pixel;
                last_curr(1) = curr_pixel(1) - 2;
            end
        end
        if ss == floor(length(skeleton_coords)/pixels) % last pixel exception
            [max_mask_x,max_idx] = max(xm);
            max_mask_y = ym(max_idx); % get coordinates of rightmost pixel
            curr_pixel = [max_mask_x,max_mask_y];
        end
        region_im = insertShape(blank_im,"filled-polygon",[last_top(2),last_top(1),top_vertex(2),top_vertex(1),...
            curr_pixel(1),curr_pixel(2),bottom_vertex(2),bottom_vertex(1),...
            last_bottom(2),last_bottom(1),last_curr(1),last_curr(2)]); % polygon filling region of interest
        % region_im = region_im - blank_plotting_im; % delete any overlapping regions

        [yl,xl] = find(region_im);
        curr_subROIs{ss} = [xl,yl];

        region_RGB = cat(3, region_im(:,:,1) * cmap(ss,1), region_im(:,:,1) * cmap(ss,2), region_im(:,:,1) * cmap(ss,3));
        blank_plotting_im = blank_plotting_im+region_RGB;
        imshow(blank_plotting_im)
    end
    flipped_subROIs = flipud(curr_subROIs); % flip array upside down so closest to soma is first
    subROIs{ii} = flipped_subROIs;
end
close all

% Replace old registered data with file with new masks
data = reg_data;
save(fname.name,'data')