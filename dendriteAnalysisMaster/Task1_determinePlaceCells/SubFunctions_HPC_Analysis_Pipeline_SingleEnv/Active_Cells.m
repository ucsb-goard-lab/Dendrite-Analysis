function [ active_cells ] = Active_Cells(data, act_thresh)
%-------------------------------------------------------------------------%
%   This function computes the number of active cells like they do in
%   Hainmueller and Bartos 2018.
%
%   Written by WTR 08/14/2020 // Last updated by NSW 07/31/2023
%-------------------------------------------------------------------------%
%%
active_cells = zeros(1, size(data.DFF, 1)); 
sigma = 2;

%%
for ii = 1:size(data.DFF, 1)
    transient_thresh = mean(data.DFF(ii, :)) + sigma * std(data.DFF(ii, :)); 
    transients = find(data.DFF(ii, :) > transient_thresh); 
    
    if length(transients)  / 10 > act_thresh
        active_cells(ii) = 1;
    end
end