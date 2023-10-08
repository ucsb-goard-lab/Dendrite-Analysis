function [ data, floating] = Moving_v3(move_flag,data,floating,frames)
%-------------------------------------------------------------------------%
%   This script was updated from its previous form to include both the
%   extractor data from the newer and older versions of the Neurotar
%   software. Times where the mouse is not moving are subtracted from both
%   the behavior data and the suite2p activity data.
%
%   Written by NSW 11/16/2022 // Based on code from WTR Sept. 2020
%-------------------------------------------------------------------------%
if nargin < 1 || isempty(move_flag)
    move_flag = 1;
end

if length(data.DFF) > frames % if the data is longer than the neurotar recording
    data.DFF = data.DFF(:,1:frames); % chop off end after neurotar was turned off
    data.DFF_raw = data.DFF_raw(:,1:frames);
    data.raw_F = data.raw_F(:,1:frames);
    data.neuropil_F = data.neuropil_F(:,1:frames);
end

if move_flag
    not_moving_time = ~floating.moving_times;
    
    % remove not moving time from activity data
    data.DFF(:, not_moving_time) = [];
    data.DFF_raw(:, not_moving_time) = [];
    % data.spikes(:, not_moving_time) = [];
    data.raw_F(:, not_moving_time) = [];
    data.neuropil_F(:, not_moving_time) = [];
end

if length(data.DFF) > length(floating.X)

end