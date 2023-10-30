function [ SCs, speed_binned, activity_binned, sde_activity_binned, speed_score, n_thresh, p_thresh ] = Speed_Cells(data, floating, lap_times)
%-------------------------------------------------------------------------%
%   This script determines which cells are speed cells. It uses the method
%   introduced in Kropff et al. 2015. We make a slight adjustment to
%   compare each cell to its own null idtribution instead of the total
%   distribution. 
%
%   Written by WTR 10/30/2020 // Last updated by WTR 01/22/2021
%-------------------------------------------------------------------------%
%% Globals 
N = size(data.DFF, 1); 
speed_prct_bin = 10; 
shuffle_prct = 0.01;
n_shuff = 100; 
min_shuff = 10;

%% Finding the activity and speed that correspond to actual laps 
speed = [];
activity = []; 

for ii = 1:size(lap_times, 1)
    speed = [speed, floating.speed(lap_times(ii, 1):lap_times(ii, 2))]; 
    activity = [activity, data.DFF_transients(:, lap_times(ii, 1):lap_times(ii, 2))]; 
end

speed_bins = prctile(speed, 0:speed_prct_bin:100); 
speed_binned = (speed_bins(1:(end - 1)) + speed_bins(2:end)) / 2;

%% Computing the mean and SEM of the activity for the binned speed
%   This is just for plotting purposes
activity_binned = zeros(N, length(speed_bins) - 1);
sde_activity_binned = zeros(N, length(speed_bins) - 1);  

for ii = 1:N
    if isempty(lap_times)
        continue
    end
     bin_counts = zeros(1, length(speed_binned)); 
     for ss = 2:length(speed_bins) 
        activity_binned(ii, ss - 1) = mean(activity(ii, find(speed < speed_bins(ss) & speed > speed_bins(ss - 1))));   
        bin_counts(ss - 1) = length(find(speed < speed_bins(ss) & speed > speed_bins(ss - 1))); 
        sde_activity_binned(ii, ss - 1) = std(activity(ii, find(speed < speed_bins(ss) & speed > speed_bins(ss - 1)))) / sqrt(bin_counts(ss - 1)); 
     end    
end

%% Finding the speed cells
%   This has three steps. 1) Computing each cell's speed score. 2)
%   Computing the null distribution for each cell. 3) Combining all the
%   null distributions and using that as the criteria for defining speed
%   cells. 
speed_cells = zeros(1, N); 
speed_score = zeros(1, N);
null_speed_score = zeros(1, N * n_shuff); 
T = size(activity, 2); 
n_thresh = zeros(1, N); 
p_thresh = zeros(1, N); 

for ii = 1:N
    if isempty(lap_times)
        continue
    end
    R = corrcoef(speed', activity(ii, :)');
    speed_score(ii) = R(1, 2); 

    ii_null_speed_score = zeros(1, n_shuff); 
    for ss = 1:n_shuff
        ii_activity = activity(ii, :); 
        shuff_amount = min_shuff + floor(rand() * (T - min_shuff - 1)); 
        shuff_activity = zeros(1, T); 
        shuff_activity(1:(T - shuff_amount + 1)) = ii_activity(shuff_amount:T); 
        shuff_activity((T - shuff_amount + 2):end) = ii_activity(1:(shuff_amount - 1)); 
        
        R_shuff = corrcoef(speed', shuff_activity');
        ii_null_speed_score(ss) = R_shuff(1,2); 
    end
    
    null_speed_score(((ii - 1) * n_shuff + 1):(ii * n_shuff)) = ii_null_speed_score; 
    
    sorted_ii_null_speed_score = sort(ii_null_speed_score); 
    
    n_thresh(ii) = sorted_ii_null_speed_score(round(shuffle_prct * n_shuff)); 
    p_thresh(ii) = sorted_ii_null_speed_score(round((1 - shuffle_prct) * n_shuff)); 
    
    if (speed_score(ii) < n_thresh(ii)) || (speed_score(ii) > p_thresh(ii))
        speed_cells(ii) = 1;
    end 
end
SCs = find(speed_cells);