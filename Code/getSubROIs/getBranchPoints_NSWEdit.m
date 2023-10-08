function [x_branch,y_branch] = getBranchPoints_NSWEdit(image_skeleton, x_end, y_end)
% GETBRANCHPOINTS takes in branchpoints taken from a skeleton with
% morphological operations, separates them into x and y components, and
% cleans the data

[x_branch, y_branch] = find((bwmorph(image_skeleton, 'branchpoints'))');
xy_branch = zeros(length(x_end),2);

for i = 1:length(x_end)
    
    distance_endpoints = bwdistgeodesic(image_skeleton, x_end(i), y_end(i), 'quasi-euclidean');
    vector_distance    = zeros(length(x_branch),1);
  
    for j = 1:length(x_branch) %for every branch point to this end point
        vector_distance(j) = distance_endpoints(y_branch(j),x_branch(j));
    end
    
    if isempty(vector_distance) || vector_distance(1,1) == Inf
        continue 
    else 
        % find which branch has the smallest distance to endpoint
        [~,val]            = min(vector_distance); 
        xy_branch(i,:) = [x_branch(val(1)),y_branch(val(1))];
    end
end

x_branch = xy_branch(:,1); y_branch = xy_branch(:,2);


end

