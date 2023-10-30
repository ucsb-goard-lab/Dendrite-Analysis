function [ activity_binned_1D_sde_smoothed, activity_binned_1D_smoothed, binned_angles, consistency,...
    lap_times, lap_by_lap_activity ] = ...
    OneD_Track_Anaysis_v2(data, floating, degree_size, trialID)
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
activity = data.DFF_transients;
angles = floating.phi;
n_bins = floor(360 / degree_size);
angle_bins = linspace(-180, 180, n_bins);

num_shuffles = 500;
min_lap_length = 20; % 10
max_avg_lap_speed = 200; % 180

%% Binning the angular position of the mouse
binned_angles = zeros(1, T);
for tt = 1:T
    [~, binned_angles(tt)] = min(abs(angle_bins - angles(tt)));
end

%% Finding the laps
[lap_start_times, lap_end_times, n_laps] = getLaps(binned_angles, trialID,...
    min_lap_length, max_avg_lap_speed, T, n_bins, floating, 0);
lap_times = [lap_start_times', lap_end_times'];

%% Computing the activity of each neuron lap-by-lap
lap_by_lap_activity = zeros(n_laps, n_bins, N);

for i = 1:n_laps
    bin_counts = zeros(1, n_bins); % how many times the mouse was in each bin
    for jj = lap_start_times(i):lap_end_times(i) % for whole duration of a given lap
        bin_counts(binned_angles(jj)) = bin_counts(binned_angles(jj)) + 1; % adds one to whichever bin the animal is currently in
        % prev version: lap_by_lap_activity(i, binned_angles(jj), :) = lap_by_lap_activity(i, binned_angles(jj)) + reshape(activity(:, jj),[1,1,N]);
        lap_by_lap_activity(i, binned_angles(jj), :) = lap_by_lap_activity(i, binned_angles(jj), :) + reshape(activity(:, jj),[1,1,N]);
    end
    bin_counts(bin_counts == 0) = NaN;
    lap_by_lap_activity(i, :, :) = lap_by_lap_activity(i, :, :) ./ bin_counts;

    % Linearly interpolate spots that get skipped (bins they didn't spend enough
    % time in), except for the beginning of each lap
    % ADDED 06/15/22
    curr_row = lap_by_lap_activity(i,:);
    coordinates = isnan(curr_row);
    range = 1:numel(curr_row);
    lap_by_lap_activity(i,coordinates) = interp1(range(~coordinates), curr_row(~coordinates), range(coordinates));
end

lap_by_lap_activity2 = lap_by_lap_activity;
gauss_n = 7; % should be odd
gauss_weights = gausswin(gauss_n)' / sum(gausswin(gauss_n));

for ii = 1:N
    for jj = 1:n_laps
        for kk = (floor(gauss_n / 2) + 1):(n_bins - floor(gauss_n / 2) - 1)
            a = squeeze(lap_by_lap_activity(jj, (kk - floor(gauss_n / 2)):(kk + floor(gauss_n / 2)), ii));
            lap_by_lap_activity2(jj, kk, ii) = sum(a .* gauss_weights) ./ sum((1 - isnan(a)) .* gauss_weights,'omitnan');
        end

        for kk = 1:floor(gauss_n / 2)
            a = squeeze(cat(2, lap_by_lap_activity(jj, 1:(kk + floor(gauss_n / 2)), ii), lap_by_lap_activity(jj, (end - floor(gauss_n / 2) + kk):end, ii)));
            lap_by_lap_activity2(jj, kk, ii) = sum(a .* gauss_weights) ./ sum((1 - isnan(a)) .* gauss_weights,'omitnan');
        end

        for kk = (n_bins - floor(gauss_n / 2)):n_bins
            s = n_bins - kk;
            a = squeeze(cat(2, lap_by_lap_activity(jj, (kk - floor(gauss_n / 2)):end, ii), lap_by_lap_activity(jj, 1:(floor(gauss_n / 2) - s), ii)));
            lap_by_lap_activity2(jj, kk, ii) = sum(a .* gauss_weights) ./ sum((1 - isnan(a)) .* gauss_weights,'omitnan');
        end
    end
end
lap_by_lap_activity = lap_by_lap_activity2;

%% Computing average 1D activity
% For smoothing the SEM, see Taylor "Introduction to Error Analysis"
if size(lap_by_lap_activity,3) > 1 % if there's more than one cell
    activity_binned_1D = squeeze(mean(lap_by_lap_activity, 1,'omitnan'))';
    activity_binned_1D_sde = squeeze(std(lap_by_lap_activity, 1,'omitnan'))';
else
    activity_binned_1D = mean(lap_by_lap_activity, 1,'omitnan');
    activity_binned_1D_sde = std(lap_by_lap_activity, 1,'omitnan');
end
activity_binned_1D_smoothed = zeros(N, n_bins);

for ii = 1:n_bins
    n_ii = n_laps - sum(isnan(lap_by_lap_activity(:, ii, 1)));
    activity_binned_1D_sde(:, ii) = activity_binned_1D_sde(:, ii) / sqrt(n_ii);

    if ii > 1 && ii < n_bins
        activity_binned_1D_smoothed(:, ii) = mean(activity_binned_1D(:, (ii - 1):(ii + 1)), 2);
    elseif ii == 1 && size(activity_binned_1D,2) > 1
        activity_binned_1D_smoothed(:, ii) = 1/3 * (activity_binned_1D(:, ii) + ...
            activity_binned_1D(:, ii + 1) + activity_binned_1D(:, end));
    else
        activity_binned_1D_smoothed(:, ii) = 1/3 * (activity_binned_1D(:, ii) + ...
            activity_binned_1D(:, ii - 1) + activity_binned_1D(:, 1));
    end
end

activity_binned_1D_smoothed = activity_binned_1D; %%% ADDED

activity_binned_1D_sde_smoothed = activity_binned_1D_sde;
for ii = 2:(n_bins-1)
    activity_binned_1D_sde_smoothed(:, ii) = mean(activity_binned_1D_sde(:, (ii - 1):(ii + 1)), 2,'omitnan');
end

activity_binned_1D_sde_smoothed(:, 1) = mean(cat(2, activity_binned_1D_sde(:, 1:2), activity_binned_1D_sde(:, end)), 2,'omitnan');
activity_binned_1D_sde_smoothed(:, end) = mean(cat(2, activity_binned_1D_sde(:, (end - 1):end), activity_binned_1D_sde(:, 1)), 2,'omitnan');

%% Shuffling
corr_vec = zeros(N, num_shuffles);

for ss = 1:num_shuffles
    shuffled_laps = randperm(n_laps);
    shuffled_activity = lap_by_lap_activity(shuffled_laps, :, :);
    if size(shuffled_activity,3) > 1 % if there's more than 1 cell
        first_half = squeeze(mean(shuffled_activity(1:ceil(n_laps / 2), :, :), 1,'omitnan'))';
        second_half = squeeze(mean(shuffled_activity((ceil(n_laps / 2) + 1):end, :, :), 1,'omitnan'))';
    else
        first_half = mean(shuffled_activity(1:ceil(n_laps / 2), :, :), 1,'omitnan');
        second_half = mean(shuffled_activity((ceil(n_laps / 2) + 1):end, :, :), 1,'omitnan');
    end

    first_half_smoothed = zeros(N, n_bins);
    second_half_smoothed = zeros(N, n_bins);
    for ii = 1:n_bins
        if ii > 1 && ii < n_bins
            first_half_smoothed(:, ii) = mean(first_half(:, (ii - 1):(ii + 1)), 2,'omitnan');
            second_half_smoothed(:, ii) = mean(second_half(:, (ii - 1):(ii + 1)), 2,'omitnan');
        elseif ii == 1 
            first_half_smoothed(:, ii) = mean([first_half(:, ii), first_half(:, ii + 1), first_half(:, end)], 2,'omitnan');
            second_half_smoothed(:, ii) = mean([second_half(:, ii), second_half(:, ii + 1), second_half(:, end)], 2,'omitnan');
        else
            first_half_smoothed(:, ii) = mean([first_half(:, ii), first_half(:, ii - 1), first_half(:, 1)], 2,'omitnan');
            second_half_smoothed(:, ii) = mean([second_half(:, ii), second_half(:, ii - 1), second_half(:, 1)], 2,'omitnan');
        end
    end

    corr_vec(:, ss) = diag(corr(first_half_smoothed', second_half_smoothed'));

end

consistency = mean(corr_vec, 2,'omitnan');

%% Smoothing the lap by lap activity
smooth_lap_by_lap_activity = zeros(size(lap_by_lap_activity));

for ii = 1:n_bins
    if ii > 1 && ii < n_bins
        smooth_lap_by_lap_activity(:, ii, :) = mean(lap_by_lap_activity(:, (ii - 1):(ii + 1), :, :), 2,'omitnan');
    elseif ii == 1
        smooth_lap_by_lap_activity(:, ii, :) = mean(cat(2, lap_by_lap_activity(:, ii, :),...
            lap_by_lap_activity(:, ii + 1, :), lap_by_lap_activity(:, end, :)), 2,'omitnan');
    else
        smooth_lap_by_lap_activity(:, ii, :) = mean(cat(2, lap_by_lap_activity(:, ii, :),...
            lap_by_lap_activity(:, ii - 1, :), lap_by_lap_activity(:, 1, :)), 2,'omitnan');
    end
end

if length(lap_start_times) == 15
    x = 2;
end

lap_by_lap_activity = smooth_lap_by_lap_activity;