function [ spatial_info, mean_act ]  = Spatial_Information_v2(activity, counts) 
%-------------------------------------------------------------------------%
%   This script computes the spatial information of each cell. This is
%   saved and can be used for future analysis. 
%
%   Note: We calculate the average activity of each cell (ii_mean_DFF)
%   using the binned activity and the number of times the mouse was at each
%   location because, when/if we smooth the DFF activity, we're smoothing
%   over bins, not the actual trace itself. So to calculate the "mean
%   smoothed activity" of each cell, we need to go backwards and use the
%   smoothed binned activity. 
%
%   Written by WTR 10/25/2020 // Last updated by WTR 10/25/2020 
%-------------------------------------------------------------------------%
%% 
p = counts / nansum(counts);
mean_act = nansum(activity .* counts) / nansum(counts); 
spatial_info = nansum(activity .* p .* log2(activity / mean_act));
spatial_info = spatial_info / mean_act; % dividing by mean activity
