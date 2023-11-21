function image_skeleton = connectBranchPoints(image_skeleton, ROI_box)

regions = regionprops(image_skeleton);
n_endpoints = length(regions)*2-2;

fig = figure;
title('Please click on points you would like to connect');
skeleton_small = image_skeleton(1:size(ROI_box,1),1:size(ROI_box,2));
overlay = imoverlay(mat2gray(ROI_box),skeleton_small,'yellow');
imshow(overlay)
set(gcf,'units','normalized','outerposition',[0 0 1 1])
hold on

% Get the first point
[x1, y1] = ginput(1);

% Draw a circle at the first point
radius = 2; % You can adjust the radius as needed
theta = linspace(0, 2*pi, 100);
x_circle = radius * cos(theta) + x1;
y_circle = radius * sin(theta) + y1;
plot(x_circle, y_circle, 'b-', 'LineWidth', 2);

% Get the second point
[x2, y2] = ginput(1);

% Draw a circle at the second point
x_circle2 = radius * cos(theta) + x2;
y_circle2 = radius * sin(theta) + y2;
plot(x_circle2, y_circle2, 'b-', 'LineWidth', 2);

% Draw a line between the two points
plot([x1, x2], [y1, y2], 'y-', 'LineWidth', 2);

% Update image_skeleton with the line
blank_skeleton = false(size(image_skeleton));
image_skeleton_repaired = insertShape(double(blank_skeleton), 'line', [x1, y1, x2, y2]);
se = strel('disk', 2);
di = imdilate(image_skeleton_repaired, se);
closed = imclose(di, se);
closed = closed(:,:,2);
image_skeleton_repaired = bwmorph(closed, 'thin', inf);

image_skeleton = image_skeleton_repaired | image_skeleton;


% Briefly display the updated image_skeleton
pause(1);

% Close the figure
close(fig);

end
