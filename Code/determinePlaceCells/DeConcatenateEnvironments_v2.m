function [data] = DeConcatenateEnvironments_v2(F, data, num_envs, frames, short_frames)
%-------------------------------------------------------------------------%
%   This function breaks down suite2p, and processed data into
%   the length of each environment, now that floating data is
%   deconcatenated in the Neurotar Extractor.
%
%   Written NSW 11/11/2022 // Last Updated by NSW 11/11/2022
%-------------------------------------------------------------------------%
if nargin < 1 || isempty(F)
    Fall = importdata('Fall.mat');
    F = Fall.F;
end

if nargin < 2 || isempty(data)
    disp('Select processed data file')
    data = uigetfile('*.mat');
    data = importdata(data);
end

if nargin < 3 || isempty(num_envs)
    num_envs = 3;
end

disp('Deconcatenating environments...')
% Preallocate filename arrays
dname_array = {'data_2_1.mat','data_2_2.mat','data_2_3.mat','data_2_4.mat'};
fname_array = {'Fall_2_1.mat','Fall_2_2.mat','Fall_2_3.mat','Fall_2_4.mat'};

% Define previously calculated variables
% Fall = importdata('suite2p/plane0/Fall.mat');
Fall = importdata('suite2p/Fall.mat');
% Fall = importdata('Fall.mat');
olddata = data;
oldF = F;
oldFneu = Fall.Fneu;
oldspks = Fall.spks;
stat = Fall.stat;
ops = Fall.ops;
iscell = Fall.iscell;
% redcell = Fall.redcell;

% Calculate where to split files 
if short_frames(1) > frames(1) % if the microscope time was shorter than the neurotar time
    short_frames = frames;
end
split_times = zeros(num_envs*2,1);
split_times(1) = 1;
split_times(2) = short_frames(1);
split_times(3) = frames(1) + 1;
split_times (4) = frames(1) + short_frames(2);
split_times (5) = frames(1) + frames(2) + 1;
split_times(6) = frames(1) + frames(2) + short_frames(3);

currdir = pwd;
trial_idx = strfind(currdir,'TRIAL_');
trialID = currdir(trial_idx:trial_idx+6);
data.trialID = trialID; % add trial tag 

%% Save data into split arrays where N = num_envs
for ii = 1:num_envs
    curr_starttime = split_times(ii*2-1,1); % first frame of cue change
    curr_endtime = split_times(ii*2,1); % last frame of cue change
    
    data.raw_F = olddata.raw_F(:,curr_starttime:curr_endtime); %% split data file
    data.neuropil_F = olddata.neuropil_F(:,curr_starttime:curr_endtime);
    data.DFF_raw = olddata.DFF_raw(:,curr_starttime:curr_endtime);
    data.DFF = olddata.DFF(:,curr_starttime:curr_endtime);
    data.spikes = olddata.spikes(:,curr_starttime:curr_endtime);
    data.r_neuropil = olddata.r_neuropil;
    
    dataname = cell2mat(dname_array(1,ii));
    save(dataname,'data') %% save new data file from ii environment
    
    F = oldF(:,curr_starttime:curr_endtime); %% split fall file
    Fneu = oldFneu(:,curr_starttime:curr_endtime);
    spks = oldspks(:,curr_starttime:curr_endtime);
    
    fallname = cell2mat(fname_array(1,ii));
    save(fallname,'stat','ops','F','Fneu','spks','iscell') %% save new Fall file from ii environment
end
end