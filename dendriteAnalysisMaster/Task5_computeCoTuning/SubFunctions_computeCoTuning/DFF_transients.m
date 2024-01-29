function [data] = DFF_transients(data, sd_thresh)
%-------------------------------------------------------------------------%
%   This function finds the transients in the DFF of each neuron and masks
%   all other points to zero. This was done in Hainmuller and Bartos 2018. 
%
%   Written by WTR 12/27/20 // Last updated by WTR 01/10/21
%-------------------------------------------------------------------------%
N = size(data.DFF, 1);  
DFF_transients = zeros(size(data.DFF)); 

for ii = 1:N
    sd = std(data.DFF(ii, :)); 
    baseline_times = find(data.DFF(ii, :) < (sd_thresh * sd)); 
    mean_baseline = mean(data.DFF(ii, baseline_times)); 
    sd_baseline = std(data.DFF(ii, baseline_times)); 
    transient_times = find(data.DFF(ii, :) > (sd_thresh * sd_baseline + mean_baseline)); 
    DFF_transients(ii, transient_times) = data.DFF(ii, transient_times);     
end

data.DFF_transients = DFF_transients; 
