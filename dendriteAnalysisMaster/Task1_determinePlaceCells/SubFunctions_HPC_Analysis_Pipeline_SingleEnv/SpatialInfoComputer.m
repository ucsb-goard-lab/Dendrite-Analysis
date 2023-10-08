function [ spatial_info, mean_rate ] = SpatialInfoComputer(activity, angles, lap_times)
%-------------------------------------------------------------------------%
%   This script computes the spatial information.
%
%   Written by WTR 02/06/2021 // Last updated by WTR 02/06/2021
%-------------------------------------------------------------------------%
%% Normalizing activity 
activity = activity ./ max(activity, [], 2); 

%%
angles2 = [];
for nn = 1:size(lap_times, 1)
    angles2 = [angles2, angles(lap_times(nn, 1):lap_times(nn, 2))];
end 

counts = zeros(1, size(activity, 2)); 
for ii = 1:size(activity, 2)
    counts(ii) = sum(angles2 == ii); 
end

spatial_info = zeros(1, size(activity, 1)); 
mean_rate = zeros(1, size(activity, 1)); 

for ii = 1:size(activity, 1)
    [spatial_info(ii), mean_rate(ii)] = Spatial_Information_v2(activity(ii, :), counts);
end



