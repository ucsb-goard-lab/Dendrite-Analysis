function [selected_PCs] = plotSuite2pCellMasks(image,Fall,cellIDs,header,select_flag)

if nargin < 1 || isempty(image)
%     disp('Select registered data')
%     dname = uigetfile('*_registered_data.mat');
    dname = dir('*_registered_data.mat');
%     data = importdata(dname);
    data = importdata(dname.name);
    image = data.avg_projection;
end
if nargin < 2 || isempty(Fall)
    Fall = importdata('suite2p\plane0\Fall.mat');
end
if nargin < 3 || isempty(cellIDs)
    cellIDs = 1:length(Fall.iscell); % defaults to all cells
end
if nargin < 4 || isempty(header)
    header = 'Cell Locations';
end

% Convert cell numbers to suite2p cell numbers
cell_idx = 1:size(Fall.F,1);
iscell = Fall.iscell(:,1);
cell_idx(find(~iscell)) = []; % removes not cells
cellIDs =cell_idx(1,cellIDs);

% Plot avg projection with cell masks on top
figure
imagesc(image)
axis square
colormap(gray)
hold on 
for i = 1:length(cellIDs)
    stat = Fall.stat{1,cellIDs(i)};
    curr_mask = double([stat.xpix',stat.ypix']);
    pgon_mask = alphaShape(curr_mask(:,1),curr_mask(:,2));
    p = plot(pgon_mask);
    p.EdgeColor = [0,1,1];
    text(curr_mask(1,1),curr_mask(1,2),num2str(cellIDs(i)),'Color','r') % mark with #
    title(header);
    xlim([0 length(image)])
    hold on
end

% Manually identify which PCs have visible dendrites
selected_PCs = []; % set in case flag is false
if select_flag
    prompt = 'Enter place cells of interest separated by a single space:';
    dlgtitle = 'Input';
    dims = [1 35];
    definput = {'20','hsv'};
    select = inputdlg(prompt,dlgtitle,dims,definput);
    sp_select = split(select);
    selected_PCs = cell2mat(cellfun(@str2num,sp_select,'un',0).');
end