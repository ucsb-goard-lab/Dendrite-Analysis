function [] = extractDFF(branchROIs,subROIs)
% Use Goard Method to extract DFF from all ROI's, including soma, dendrite,
% branch, and subROI
% For this step you need the registered multipage TIF in the current directory

dname = dir('*registered_data.mat');
data_raw = importdata(dname.name);
C_ExtractDFF(dname.name) % get data from all PC's in main file

branchname = 'branch_ROIs.mat';
subname = 'subROIs.mat';

%% restructure branch ROIs and subROIs so each ROI is in it's own cell in,
% one long row, not divided by the cell they belong to
totalNumBranches = cellfun(@(x) numel(x),branchROIs); % restructure branch ROIs
branchMasks = cell(1,sum(totalNumBranches));
bcount = 0;
for ii = 1:length(branchROIs)
    curr_branch = branchROIs{ii};
    for i = 1:length(curr_branch)
        bcount = bcount+1;
        curr_branchROI = curr_branch{i};
        branchMasks{bcount} = curr_branchROI;
    end
end
branchSizes = cell2mat(cellfun(@length,branchMasks,'UniformOutput',false));
branches2delete = find(branchSizes<10);
branchMasks(branches2delete) = []; % delete too-small branches


totalNumSubROIs = cellfun(@(x) numel(x),subROIs); % restructure subROIs
subMasks = cell(1,sum(totalNumSubROIs));
scount = 0;
for ss = 1:length(subROIs)
    curr_sub = subROIs{ss};
    for s = 1:length(curr_sub)
        scount = scount+1;
        curr_subROI = curr_sub{s};
        subMasks{scount} = curr_subROI;
    end
end
emptycells = find(cellfun(@isempty,subMasks));
subMasks(emptycells) = []; % get rid of empty cells in array 

% Construct and save branch data
data = struct;
data.cellMasks = branchMasks;
data.avg_projection = data_raw.avg_projection;
data.numFrames = data_raw.numFrames;
data.xPixels = data_raw.xPixels;
data.yPixels = data_raw.yPixels;
data.filename = data_raw.filename;

save(branchname, 'data')

% Construct and save subROI data
data = struct;
data.cellMasks = subMasks;
data.subROIbyCell = subROIs;
data.emptycells = emptycells;
data.avg_projection = data_raw.avg_projection;
data.numFrames = data_raw.numFrames;
data.xPixels = data_raw.xPixels;
data.yPixels = data_raw.yPixels;
data.filename = data_raw.filename;
data.emptycells = emptycells;

save(subname, 'data')
if ~isempty(branchMasks)
    C_ExtractDFF(branchname)
end
C_ExtractDFF(subname)
disp('DFF processed and saved to respective data files')