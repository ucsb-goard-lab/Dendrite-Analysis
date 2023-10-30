function [short_frames, rrate, fname]  = getExtractorInptDendrites()

fname= 'floating.mat'; % specify filenames

Fall = importdata(fullfile('suite2p', 'plane0', 'Fall.mat'));
frames = size(Fall.F,2);

% get the number of frames that correspond to the neurotar recording
f = NewNeurotarExtractor([], isMoving = true, RECORDING_FRAMES = frames,...
    RECORDING_RATE = 10);
ndata = f.data;
HW_timestamp = ndata.HW_timestamp; % extract relative timestamps
last_time = double(HW_timestamp(end))/1000; % get end time
if last_time == 0 % sometimes last frame gets rewritten to 0
    last_time = double(HW_timestamp(end-1))/1000; % take time right before end
end

% get exact frame number from xml file
xmlname = dir('*.xml'); % select xml file
xml = readstruct(xmlname.name);
relative_time = zeros(length(xml.Sequence.Frame),1);
for rr = 1:length(xml.Sequence.Frame)
    relative_time(rr,1) = xml.Sequence.Frame(rr).relativeTimeAttribute;
end
[~,cutoff]=min(abs(relative_time-last_time)); % get closest frame to cutoff point
if cutoff < 100 % if there is an error with the xml file
    cutoff = round(last_time*10);
    disp('Error in xml file: extracing cutoff time from tdms')
end
short_frames = cutoff;

% get exact frame rate from env file
envname = dir('*.env'); % select xml file
env_file = importdata(envname.name);
for j = 1:length(env_file)
    if strfind(env_file{j},'repetitionPeriod') > 0
        cfg_line = env_file{j};
        index = strfind(cfg_line,'repetitionPeriod');
        frameRate = 1/sscanf(cfg_line(index:end),'repetitionPeriod="%f"');
    end
end
rrate = frameRate;