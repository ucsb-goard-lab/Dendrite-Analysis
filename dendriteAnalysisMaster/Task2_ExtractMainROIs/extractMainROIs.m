function [] = extractMainROIs(selected_PCs,Fall)
% Extract main soma and dendrite ROI's using Goard Method's B_DefineROI
% extracted ROIs are saved in the registered data file 
% addpath(genpath('E:\Code\Postprocessing'))
addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'Postprocessing')));

for cc = 1:length(selected_PCs)
    curr_cell = selected_PCs(cc);
    im_file = dir('*registered_data.mat');
    im_data = importdata(im_file.name);

    % Plot cell masks for current cell
    figure
    imagesc(im_data.avg_projection)
    axis square
    colormap(gray)
    hold on
    stat = Fall.stat{1,curr_cell};
    curr_mask = double([stat.xpix',stat.ypix']);
    pgon_mask = alphaShape(curr_mask(:,1),curr_mask(:,2));
    p = plot(pgon_mask);
    p.EdgeColor = [0,1,1];
    text(curr_mask(1,1),curr_mask(1,2),num2str(curr_cell),'Color','r') % mark with #
    title('Current place cell mask');
    xlim([0 length(im_data.avg_projection)])
    
    figure
    disp('Manually select soma first, then ROI')
    B_DefineROI(im_file.name); % manually draw current ROI (dendrite + soma)
    close all
end