%% Chronic dendrite analysis master pipeline
dfols = dir('*DendritesDAY*');
addpath(genpath('E:\Code\HPC_pipeline'))

for ii = 1:length(dfols)
    curr_dfol = dfols(ii).name;
    disp(strcat('Current folder: ',curr_dfol))
    cd(curr_dfol)
    rfols = dir('TSeries*');
    for rr = 1:length(rfols)
        curr_rfol = rfols(rr).name;
        cd(curr_rfol) % move into current recording directory

        %% Step 1: determine which cells are place cells
        [frames, rrate, fname]  = getExtractorInptDendrites();
        Neurotar = NewNeurotarExtractor([], isMoving = true, RECORDING_FRAMES = frames,...
            RECORDING_RATE = rrate); % extract neurotar data from tdms file, inpt 1 = rec name
        save(fname,'Neurotar')

        % extract from suite2p; inpts = (F, Fneu, save_flag, deconcat_flag, num_envs, frames, short_frames)
        Fall = importdata("suite2p\plane0\Fall.mat");
        data = suite2p2data(Fall.F,Fall.Fneu,1,0,1,frames,frames);
        [valid_PCs, selected_PCs] = HPC_Analysis_Pipeline_SingleEnv(1,[],[],...
            0, 0, 1, 1, 1, frames);

        %% Step 2: extract main ROIs
        % For each selected place cell, display avg projection and ask the
        % user to manually select the ROI of the dendrite and the ROI of the soma
        extractMainROIs(selected_PCs,Fall); % automatically saves to registered data

        %% Step 3: get sub-ROIs and branch ROIs
        % For the selected dendrite ROI's, break the ROI into two-micron chunks
        % Detect any branch points and break ROI into selected branches
        [zoom, microns] = getZoom();
        [subROIs, branchROIs] = getSubROIs(selected_PCs,microns); % also save to registered data file

        %% Step 3: extract DFF
        % Use goard method to get DFF from soma, dendrites, branches, and sub-ROIs
        % Output saves to data structures in current directory
        extractDFF(branchROIs,subROIs);

        %% Step 4: compute co-tuning
        % 1. Get co-tuning between dendrite and soma
        % 2. Get co-tuning between dendritic branches
        % 3. Get co-tuning between 2um sub-ROIs
        [cell_corr, branch_corr, sub_corr, subcell_corr] = calculateCoTuning(frames);
        cd ..
    end
    close all
    cd ..
end