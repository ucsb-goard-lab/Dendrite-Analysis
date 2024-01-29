function [ activity_binned_1D, activity_binned_1D_sde_smoothed, activity_binned_1D_smoothed, binned_angles, consistency, lap_times, lap_by_lap_activity ] = ...
    OneD_Track_Analysis_v2(data, floating, degree_size)
%-------------------------------------------------------------------------%
%   This script bins the linear track data by angle (the size of the bins
%   being given by degree_size). This can be used for any of the HPC data
%   where the mouse ran on the track. 
%   
%   Here we update some of the code to be a little more careful with how we
%   do the analysis (as compared to v1). In particular, the first thing we
%   do is find the laps. We then disregard any activity that doesn't fall
%   in one of the laps. 
%
%   Written by WTR 09/16/2020 // Last updated by WTR 01/22/2021
%-------------------------------------------------------------------------%
%% Globals 
N = size(data.DFF, 1); 
T = size(data.DFF, 2);
activity = data.DFF; 'DFF'
angles = floating.phi; 
n_bins = round(360 / degree_size); 
angle_bins = linspace(-180, 180, n_bins); 

num_shuffles = 500; 
min_lap_length = 10; 
max_avg_lap_speed = 100; %180

%% Binning the angular position of the mouse
binned_angles = zeros(1, T); 
for tt = 1:T
    [~, binned_angles(tt)] = min(abs(angle_bins - angles(tt)));
end

%% Finding the laps 
%   Here we have two processing steps. First, we find all the times where
%   the mouse passes through the position it started the session at after
%   not being at that position for a while. Second, we make sure that the
%   average speed during that lap was not too fast. 
pos1 = binned_angles(1); 
lap_start_times = find(binned_angles == pos1); 
lap_end_times = [lap_start_times(2:end) - 1, T]; 

to_delete = [];  
for ll = 1:length(lap_start_times)
    lap_length = lap_end_times(ll) - lap_start_times(ll); 
    
    if lap_length < min_lap_length || abs(max(binned_angles(lap_start_times(ll):lap_end_times(ll)) - min(binned_angles(lap_start_times(ll):lap_end_times(ll))))) < (n_bins / 2)
        to_delete = [to_delete, ll];
        if ll < length(lap_start_times)
            lap_start_times(ll + 1) = lap_start_times(ll); 
        end
    end
    
end
lap_start_times(to_delete) = []; 
lap_end_times(to_delete) = []; 

avg_speed = zeros(1, length(lap_start_times)); 
for ll = 1:length(lap_start_times)
    avg_speed(ll)= mean(floating.speed(lap_start_times(ll):lap_end_times(ll))); 
end

lap_start_times(avg_speed > max_avg_lap_speed) = []; 
lap_end_times(avg_speed > max_avg_lap_speed) = []; 

n_laps = length(lap_start_times); 
lap_times = [lap_start_times', lap_end_times'];

%% Computing the activity of each neuron lap-by-lap
lap_by_lap_activity = zeros(n_laps, n_bins, N); 

for ii = 1:n_laps 
    bin_counts_lap_ii = zeros(1, n_bins); 
    for jj = lap_start_times(ii):lap_end_times(ii)
        bin_counts_lap_ii(binned_angles(jj)) = bin_counts_lap_ii(binned_angles(jj)) + 1;
        lap_by_lap_activity(ii, binned_angles(jj), :) = lap_by_lap_activity(ii, binned_angles(jj), :) + reshape(activity(:, jj), [1, 1, N]); 
    end

    bin_counts_lap_ii(bin_counts_lap_ii == 0) = NaN; 
    lap_by_lap_activity(ii, :, :) = lap_by_lap_activity(ii, :, :) ./ bin_counts_lap_ii; 
    
end
    
%% Computing average 1D activity
% For smoothing the SEM, see Taylor "Introduction to Error Analysis"
activity_binned_1D = squeeze(nanmean(lap_by_lap_activity, 1))'; 
activity_binned_1D_sde = squeeze(nanstd(lap_by_lap_activity, 1))'; 
activity_binned_1D_smoothed = zeros(N, n_bins); 

for ii = 1:n_bins 
    n_ii = n_laps - sum(isnan(lap_by_lap_activity(:, ii, 1))); 
    activity_binned_1D_sde(:, ii) = activity_binned_1D_sde(:, ii) / sqrt(n_ii); 
    
    if ii > 1 && ii < n_bins 
        activity_binned_1D_smoothed(:, ii) = mean(activity_binned_1D(:, (ii - 1):(ii + 1)), 2); 
    elseif ii == 1
        activity_binned_1D_smoothed(:, ii) = 1/3 * (activity_binned_1D(:, ii) + ...
            activity_binned_1D(:, ii + 1) + activity_binned_1D(:, end)); 
    else
        activity_binned_1D_smoothed(:, ii) = 1/3 * (activity_binned_1D(:, ii) + ...
             activity_binned_1D(:, ii - 1) + activity_binned_1D(:, 1)); 
    end
end

activity_binned_1D_sde_smoothed = activity_binned_1D_sde;
for ii = 2:(n_bins - 1)
    activity_binned_1D_sde_smoothed(:, ii) = nanmean(activity_binned_1D_sde(:, (ii - 1):(ii + 1)), 2); 
end

activity_binned_1D_sde_smoothed(:, 1) = nanmean(cat(2, activity_binned_1D_sde(:, 1:2), activity_binned_1D_sde(:, end)), 2); 
activity_binned_1D_sde_smoothed(:, end) = nanmean(cat(2, activity_binned_1D_sde(:, (end - 1):end), activity_binned_1D_sde(:, 1)), 2); 

%% Shuffling 
corr_vec = zeros(N, num_shuffles); 

for ss = 1:num_shuffles
     shuffled_laps = randperm(n_laps); 
     shuffled_activity = lap_by_lap_activity(shuffled_laps, :, :); 
     first_half = squeeze(nanmean(shuffled_activity(1:ceil(n_laps / 2), :, :), 1))'; 
     second_half = squeeze(nanmean(shuffled_activity((ceil(n_laps / 2) + 1):end, :, :), 1))'; 

     first_half_smoothed = zeros(N, n_bins); 
     second_half_smoothed = zeros(N, n_bins); 
     for ii = 1:n_bins
         if ii > 1 && ii < n_bins
             first_half_smoothed(:, ii) = nanmean(first_half(:, (ii - 1):(ii + 1)), 2);
             second_half_smoothed(:, ii) = nanmean(second_half(:, (ii - 1):(ii + 1)), 2);
         elseif ii == 1
             first_half_smoothed(:, ii) = nanmean([first_half(:, ii), first_half(:, ii + 1), first_half(:, end)], 2); 
             second_half_smoothed(:, ii) = nanmean([second_half(:, ii), second_half(:, ii + 1), second_half(:, end)], 2); 
         else
             first_half_smoothed(:, ii) = nanmean([first_half(:, ii), first_half(:, ii - 1), first_half(:, 1)], 2); 
             second_half_smoothed(:, ii) = nanmean([second_half(:, ii), second_half(:, ii - 1), second_half(:, 1)], 2); 
         end
     end
     
     corr_vec(:, ss) = diag(corr(first_half_smoothed', second_half_smoothed')); 
     
end

consistency = nanmean(corr_vec, 2); 

%% Smoothing the lap by lap activity 
smooth_lap_by_lap_activity = zeros(size(lap_by_lap_activity)); 

for ii = 1:n_bins
     if ii > 1 && ii < n_bins 
        smooth_lap_by_lap_activity(:, ii, :) = nanmean(lap_by_lap_activity(:, (ii - 1):(ii + 1), :, :), 2); 
    elseif ii == 1
        smooth_lap_by_lap_activity(:, ii, :) = nanmean(cat(2, lap_by_lap_activity(:, ii, :),...
            lap_by_lap_activity(:, ii + 1, :), lap_by_lap_activity(:, end, :)), 2); 
    else
        smooth_lap_by_lap_activity(:, ii, :) = nanmean(cat(2, lap_by_lap_activity(:, ii, :),...
            lap_by_lap_activity(:, ii - 1, :), lap_by_lap_activity(:, 1, :)), 2); 
     end
end

lap_by_lap_activity = smooth_lap_by_lap_activity; 


        
        
        
        
        
        
        
        
        
        
        
        
        










