function [] = HPC_Analysis_Pipeline_Dendrites(num_envs,data,floating,...
    plot_all, plot_oneD, plot_Location, save_flag, fname, frames)
%% HPC Analysis Pipeline for non-remapping experiments
%
%   Written by NSW 05/31/2023 // Last updated by NSW 05/31/2023
%------------------------------------------------------------------------%
if nargin < 1 || isempty(num_envs)
    num_envs = 1;
end
if nargin < 2 || isempty(data)
    dname = dir('*registered_data.mat');
    data = importdata(dname.name);
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
if nargin < 6 || isempty(plot_Location)
    plot_Location = 1; % plot anatomical location (suite2p)
end
if nargin < 7 || isempty(save_flag)
    save_flag = 1; % defaults to save data
end

% Display current iteration
disp('Calculating tuning curves...')

% Removing any artifacts in the data
artifacts = find(isnan(floating.X));
if sum(artifacts) > 0 % if there are artifacts
    floating.Y(artifacts) = [];
    floating.speed(artifacts) = [];
    floating.R(artifacts) = [];
    floating.alpha(artifacts) = [];
    data.DFF(:, artifacts) = [];
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
[ data ] = Normalizer(data);                                   % normalizes your activity
[ data, floating ] = Moving_v3(1, data, floating, frames);     % removes timepoints when mouse is not moving
[ data ] = DFF_transients(data, sd_thresh);

% extract lap-by-lap activity and smooth traces
[ activity_binned_1D_sde_smoothed, activity_binned_1D_smoothed, angle_bin_ids, ...
    ~, ~,  lap_by_lap_activity ] = OneD_Track_Anaysis_v2(data,...
    floating, degree_size, []);

% remove binned activity artifacts
activity_binned_1D_sde_smoothed(isnan(activity_binned_1D_sde_smoothed)) = 0;
activity_binned_1D_smoothed(isnan(activity_binned_1D_smoothed)) = 0;

%% Plot according to input arguments
if plot_all
    plotAllLapByLap_SingleEnv(data,lap_by_lap_activity);
end
if plot_oneD
    plotOneD_SingleEnv(activity_binned_1D_smoothed);
end
if plot_Location
    if ~isempty(valid_PCs)
        addpath('C:\Data\Code\Social Coding')
        plotSuite2pCellMasks([],[],1:size(data.DFF,1),[],1); % plot cell masks of PCs on suite2p data
    else
        disp('Could not display place cell locations: no place cells found')
    end
end

%% Save data to current directory including date
if save_flag
    Save_DendriteData(data,activity_binned_1D_smoothed,activity_binned_1D_sde_smoothed,...
        lap_by_lap_activity,params,angle_bin_ids,fname)
end
end