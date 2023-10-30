function image_skeleton = connectBranchPoints(image_skeleton, ROI_box)

regions = regionprops(image_skeleton);
n_endpoints = length(regions)*2-2;
disp('Please click on points you would like to connect')
fig = figure;
skeleton_small = image_skeleton(1:size(ROI_box,1),1:size(ROI_box,2));
overlay = imoverlay(mat2gray(ROI_box),skeleton_small,'yellow');
imshow(overlay)
set(gcf,'units','normalized','outerposition',[0 0 1 1])
hold on
[x_endp,y_endp] = ginput(n_endpoints);
for ee = 1:length(x_endp)/2
    image_skeleton_repaired = insertShape(double(image_skeleton),'line',[[round(x_endp(ee*2-1)),round(y_endp(ee*2-1))],...
        [round(x_endp(ee*2)),round(y_endp(ee*2))]]);
    se = strel('disk',2);
    di = imdilate(image_skeleton_repaired,se);
    closed = imclose(di,se);
    closed = closed(:,:,2);
    image_skeleton = bwmorph(closed,'thin',inf);
end

close(fig);
end

