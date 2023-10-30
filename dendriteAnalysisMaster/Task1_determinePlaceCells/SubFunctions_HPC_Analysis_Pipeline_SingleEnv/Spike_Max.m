function [ data ] = Spike_Max(data)
%% Spike_Max
%-------------------------------------------------------------------------%
%   This code implements a maximum spike rate cut-off as suggested to me by
%   Kevin Sit. 
%
%   Written by WTR 12/12/2019 // Last updated by WTR 12/19/2020
%-------------------------------------------------------------------------%
%% Globals
max_std = 3; 
N = size(data.spikes, 1); 

%% Capping the spikes
for ii = 1:N
    spikes_ii = data.spikes(ii, :); 
    std_ii = std(spikes_ii);
    mean_ii = mean(spikes_ii);
    spikes_ii(spikes_ii > (mean_ii + std_ii * max_std)) = mean_ii + std_ii * max_std;
    data.spikes(ii, :) = spikes_ii; 
end

