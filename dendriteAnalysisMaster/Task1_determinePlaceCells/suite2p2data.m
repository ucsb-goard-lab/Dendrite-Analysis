function [data] = suite2p2data(F, Fneu, save_flag, deconcat_flag, num_envs, frames, short_frames)
%-------------------------------------------------------------------------%
%   This function converts the suite2p output to Goard Lab pipeline
%   variables, and performs the local neuropil subtraction. 
%
%   Written by WTR 06/15/2020 // Last updated by NSW 09/20/2021
%-------------------------------------------------------------------------%
if nargin < 2 || isempty(F)
    fall = importdata('suite2p/plane0/Fall.mat');
    % fall = importdata('Fall.mat');
    F = fall.F;
    Fneu = fall.Fneu;
end

if nargin < 3 || isempty(save_flag)
    save_flag = 1;
end

if nargin < 4 || isempty(deconcat_flag)
    deconcat_flag = 0; % seperate out environments if using for remapping
end

if nargin < 5 || isempty(num_envs)
    num_envs = 3; % only for deconcatenation 
end

data = struct; 
data.raw_F = F; 
data.neuropil_F = Fneu;

%% Local neuropil subtraction
disp('Converting suite2p to data...');
test_vec = 0:0.01:1;
r_neuropil = subroutine_test_r_HPC(test_vec, data, 0);
data.r_neuropil = r_neuropil;

DFF = zeros(size(data.raw_F, 1), size(data.raw_F, 2));
for ii = 1:size(data.raw_F, 1)
    raw_F = data.raw_F(ii,:);
        
    % Find F0 using mode of distribution estimate
    [KSD, Xi] = ksdensity(raw_F);
    [~, maxIdx]= max(KSD);
    F0 = Xi(maxIdx);
        
    % Raw DF/F calculation
    data.DFF_raw(ii,:) = (raw_F - F0) / F0 * 100;
        
    % Subtract neuropil response
    neuropil_F = data.neuropil_F(ii, :);
    norm_F = raw_F - r_neuropil(ii) * neuropil_F + r_neuropil(ii) * mean(neuropil_F);
            
    % Find F0 using mode of distribution estimate
    [KSD, Xi] = ksdensity(norm_F);
    [~, maxIdx]= max(KSD);
    F0 = Xi(maxIdx);
            
    % DF/F calculation
    DFF(ii,:) = (norm_F - F0) / F0 * 100;
end

data.DFF = DFF;

if save_flag
filename = 'GOARD_method_processed_data.mat';
save(filename, 'data'); 
% save('floating.mat','floating');

%% Running spike inference
[ data ] = spikeInference(filename,1); 

% Save new data
save(filename, 'data'); 
end

if deconcat_flag
    DeConcatenateEnvironments_v2(F,data,num_envs,frames,short_frames);
end

end