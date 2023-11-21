function [valid_PCs, selected_PCs] = HPC_Analysis_Pipeline_SingleEnv(num_envs,data,floating,...
    plot_all, plot_oneD, plot_heatMap, plot_Location, save_flag, frames)
%% HPC Analysis Pipeline for non-remapping experiments
%
%   Written by NSW 05/31/2023 // Last updated by NSW 05/31/2023
%------------------------------------------------------------------------%
if nargin < 1 || isempty(num_envs)
    num_envs = 1;
end
if nargin < 2 || isempty(data)
    data = importdata('GOARD_method_processed_data.mat');
end
if nargin < 3 || isempty(floating)
    floating = importdata('floating.mat'); % for NewNeurotarExtractor class
end
if nargin < 4 || isempty(plot_all)
    plot_all = 0; % plot lap by lap activity for every cell (not just pc's)
end
if nargin < 5 || isempty(plot_oneD)
    plot_oneD = 0; % plot PC responses for each environment
end
if nargin < 6 || isempty(plot_heatMap)
    plot_heatMap = 1; % plot heatmaps for each environment
end
if nargin < 7 || isempty(plot_Location)
    plot_Location = 1; % plot anatomical location (suite2p)
end
if nargin < 8 || isempty(save_flag)
    save_flag = 1; % defaults to save data
end

% Display current iteration
disp('Calculating place cell responses...')
Fall_File = importdata('suite2p\plane0\Fall.mat');
data.DFF(Fall_File.iscell(:, 1) == 0, :) = []; % delete DFF traces and spikes from non-cells
data.spikes(Fall_File.iscell(:, 1) == 0, :) = [];

% Removing any artifacts in the data
artifacts = find(isnan(floating.X));
if sum(artifacts) > 0 % if there are artifacts
    floating.Y(artifacts) = [];
    floating.speed(artifacts) = [];
    floating.R(artifacts) = [];
    floating.alpha(artifacts) = [];
    data.DFF(:, artifacts) = [];
    data.spikes(:, artifacts) = [];
end

%% Functions
%   Here we'll have the different functions you can pass your data through.
%   Run whichever ones suite your data.
% ----------------------------------------------------------------------- %
% Parameters
degree_size = 5;
act_thresh = 0.03;
sd_thresh = 2; % 3

params = struct;
params.oneD_bin_size = degree_size;
params.act_thresh = act_thresh;
params.sd_thresh = sd_thresh;
% ----------------------------------------------------------------------- %

% Functions
[ data ] = Spike_Max(data);                                    % establishes maximum spike rate
[ data ] = Normalizer(data);                                   % normalizes your activity
[ data, floating ] = Moving_v3(1, data, floating, frames);     % removes timepoints when mouse is not moving; change to v2 for earlier data
[ active_cells ] = Active_Cells(data, act_thresh);
[ data ] = DFF_transients(data, sd_thresh);

% extract lap-by-lap activity and smooth traces
[ activity_binned_1D_sde_smoothed, activity_binned_1D_smoothed, angle_bin_ids, ...
    ~, lap_times,  lap_by_lap_activity ] = OneD_Track_Anaysis_v2(data,...
    floating, degree_size, []);

% remove binned activity artifacts
activity_binned_1D_sde_smoothed(isnan(activity_binned_1D_sde_smoothed)) = 0;
activity_binned_1D_smoothed(isnan(activity_binned_1D_smoothed)) = 0;

% finding place cells using cohen's d
[ place_cells, FWHM, params ] = PC_reliability_checker_WTR_v2(lap_by_lap_activity, 0, 0, 0, 0);

% compute spatial info
[ spatial_info, ~ ] = SpatialInfoComputer(activity_binned_1D_smoothed, angle_bin_ids, lap_times);

% compute spped cells
[ speed_cells, ~, ~, ~, ~, ~, ~] = Speed_Cells(data, floating, lap_times);

PC_array = place_cells; % cell array of pc indices
SC_array = speed_cells; % cell array of sc indices

%% Get vector of all cells with a place field in at least one environment
% just take unique active cells, without repitition
nonactive = find(~active_cells);
valid_PCs = PC_array;
valid_SCs = SC_array;
for n = 1:length(nonactive)
    curr_idx = nonactive(n);
    if ~isempty(find(valid_PCs == curr_idx)) % if the cell has been classified as a place cell
        valid_PCs(valid_PCs == curr_idx) = []; % remove non-active cells
    end
end

%% Plot according to input arguments
if plot_all
    plotAllLapByLap_SingleEnv(data,lap_by_lap_activity);
end
if plot_heatMap
    [valid_PCs,valid_SCs,~,~] = plotHeatMaps(PC_array,...
        SC_array,activity_binned_1D_smoothed,num_envs,valid_PCs,valid_SCs);
end
if plot_oneD
    plotOneD_SingleEnv(activity_binned_1D_smoothed);
end
if plot_Location
    if ~isempty(valid_PCs)
        % addpath('E:\Code\Social Coding')
        selected_PCs = plotSuite2pCellMasks([],[],valid_PCs,[],1); % plot cell masks of PCs on suite2p data
    else
        disp('Could not display place cell locations: no place cells found')
    end
end

%% Save data to current directory including date
if save_flag
    Save_Data(data,active_cells,spatial_info,activity_binned_1D_smoothed,...
        activity_binned_1D_sde_smoothed,lap_by_lap_activity,params,valid_PCs,...
        valid_SCs,FWHM,angle_bin_ids,'_pos_')
end
end