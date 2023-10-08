function [ PCs, FWHM, params ] = PC_reliability_checker_WTR_v2(lap_activity, save_flag, plot_fits, plot_resp, shuffle_data)
%% PC_reliability_checker
%-------------------------------------------------------------------------%
%   This function finds cells that are significant under shuffling and have
%   a response curve that is well described by a Gaussian. 
%
%   Written by MJG 06/18/2021 // Last updated by NSW 06/01/2023
%-------------------------------------------------------------------------%
if nargin < 1 || isempty(lap_activity)
    lap_fname = uigetfile('*.mat');
    lap_activity = importdata(lap_fname);
end
if nargin < 2 || isempty(save_flag)
    save_flag = 1; % save data to current directory
end
if nargin < 3 || isempty(plot_fits)
    plot_fits = 0; % plot all reliable cells and fits
end
if nargin < 4 || isempty(plot_resp)
    plot_resp = 0; % plot responses of significant cells
end
if nargin < 5 || isempty(shuffle_data)
    shuffle_data = 0;  % shuffle actual data - only for testing!
end

%% User parameters
params = struct;
params.alpha_val = 0.001;            % alpha value for reliability testing (og 0.01)
params.iterations = 500;             % number of iterations for reliability testing
params.track_length = 19.5*pi;       % calculate form path radius
params.FWHM_max = params.track_length / 2;  % maximum place field width
params.FWHM_min = 2.50;              % minimum place field width 
params.gof_thresh = 0.375;           % minimum r^2 value on gaussian
params.amp_thresh = 0.50;            % minmum ratio of Gaussian amplitude to baseline
params.max_dist2center = 5;          % maximum distance a trial peak can be from the overall peak (og 5)
params.min_peak_ratio = 0.7;         % minimum percent of overall peak a lap peak has to have (og 0.5)
params.cohen_thresh = 1.2;           % Cohen's D threshold (og 0.5)
 
c = [127/255 63/255 152/255]; % colors for the place cells lap-by-lap activity        
cmap = cat(1, ones(10, 3), ...
    [linspace(1, c(1), 100); ...
    linspace(1, c(2), 100); linspace(1, c(3), 100)]');

%% Calculated parameters
numSamp = size(lap_activity,2);
numCell = size(lap_activity,3);
cm_per_bin = params.track_length/72;
COM_std = nan(1, numCell); 
spatial_precision = nan(1, numCell); 

%% Initialize vectors
reliable_cell_vec = zeros(1,numCell);
nan_cell_vec = zeros(1,numCell);
baseline_vec = zeros(1, numCell); 
amp_vec = zeros(1,numCell);
FWHM_vec = zeros(1,numCell);
lap_FWHM_vec = nan(1, numCell); 
gof_vec = zeros(1,numCell);
place_cell_vec = zeros(1,numCell);
preferred_pos = zeros(1,numCell);
cross_validated_resp = zeros(numCell,numSamp); 

fit_func = fittype('a0+a1*exp(-((x-b1)/c1)^2)'); % define function: gaussian w/ baseline
initial_param = [0 0 36 20];                     % initial parameters: [a0 a1 b1 c1]

%% Test lap-wise reliability of each cell
disp('Testing reliability of each cell...')
for i = 1:numCell
    % initialize vectors
    bt_CC_data = zeros(1,params.iterations);
    bt_CC_rand = zeros(1,params.iterations);
    
    for j = 1:params.iterations
        % Remove empty trials (and keep track of trials with NaN values)
        full_trials = mean(lap_activity(:,:,i),2,'omitnan');
        numLaps = sum(isfinite(full_trials));
        halfLaps = round(numLaps/2);
        finite_trials = mean(lap_activity(:,:,i),2);
        
        % Extract neuron data and initialize random matrix
        activity_data = lap_activity(1:numLaps,:,i);
        activity_rand = zeros(size(activity_data));

        if j == 1
            [peak, max_idx] = max(mean(activity_data,'omitnan'));
            centered_resp = circshift(activity_data,round(numSamp/2)-max_idx, 2);
            centered_resp = centered_resp - min(centered_resp(~isnan(centered_resp)));
            x = repmat(1:72, [numLaps, 1]);
            COM_n = sum(centered_resp .* x, 2,'omitnan') ./ sum(centered_resp, 2, 'omitnan');
            COM_std(i) = std(COM_n,'omitnan');
            A_n = max(centered_resp, [], 2);
            COM_w = (COM_n' * A_n) / sum(A_n);
            spatial_precision(i) = 1/sqrt((sum(A_n .* (COM_n - COM_w).^2))/(sum(A_n)));
        end
        lap_width = [];

        for k = 1:numLaps
            % interpolate any NaN values
            if isnan(finite_trials(k))
                trial_interp = activity_data(k,:);
                nanx = isnan(trial_interp);
                %                 if length(find(nanx)) == length(trial_interp)
                %                     trial_interp_nan = zeros(size(trial_interp)); % if all are nan change to all 0's
                %                     activity_data(k,:) = trial_interp_nan;
                %                 else % if the lap isn't all nans
                t = 1:numel(trial_interp);
                trial_interp(nanx) = interp1(t(~nanx), trial_interp(~nanx), t(nanx));
                if ~isempty(intersect(find(nanx == 1), 1))
                    trial_interp(1) = (trial_interp(2) + trial_interp(end))/2;
                elseif ~isempty(intersect(find(nanx == 1), numSamp))
                    trial_interp(end) = (trial_interp(1) + trial_interp(end - 1))/2;
                end

                activity_data(k,:) = trial_interp;
                %                 end
            end

            if j == 1
                [lap_peak, lap_max_idx] = max(activity_data(k, :));
                if abs(lap_max_idx - max_idx) < params.max_dist2center
                    if (lap_peak/peak) > params.min_peak_ratio
                        trial_centered_resp = circshift(activity_data(k, :),round(numSamp/2)-lap_max_idx, 2);
                        nanx = isnan(trial_centered_resp);
                        x = [1:numSamp]';
                        %                         if length(x(~nanx)) > 3 % min data points to get gof
                        [fitobj,gof] = fit(x(~nanx),trial_centered_resp(~nanx)',fit_func,'StartPoint',initial_param);
                        if gof.rsquare > params.gof_thresh
                            w = 2*sqrt(log(2)) * fitobj.c1 * cm_per_bin;
                            if w > params.FWHM_min && w < params.FWHM_max
                                lap_width = [lap_width, w];
                            end
                        end
                        %                         end
                    end
                end
            end
       
            % circularly shuffle random matrices
            activity_rand(k,:) = circshift(activity_data(k,:),randi(numSamp));
            if shuffle_data==1 % shuffle actual data if desired (only for testing)
                activity_data(k,:) = circshift(activity_data(k,:),randi(numSamp));
            end
            
        end
        
        if ~isempty(lap_width)
            lap_FWHM_vec(i) = median(lap_width);
        end
        
        % Randomly split laps into two halves
        randvec = randperm(numLaps);
        half1_idx = randvec(1:halfLaps);
        half2_idx = randvec(halfLaps+1:end);
        
        % Calculate CC from two halves of data
        lap_half1 = activity_data(half1_idx,:);
        lap_half2 = activity_data(half2_idx,:);
%         if numel(lap_half1) ~= numel(lap_half2) %make sure halves are of equal length
%             shortest_length = min(numel(lap_half1),numel(lap_half2));
%             lap_half1 = lap_half1(shortest_length,:);
%             lap_half2 = lap_half2(shortest_length,:);
%         end
        CC = corrcoef(mean(lap_half1,'omitnan'),mean(lap_half2,'omitnan'));
        bt_CC_data(j) = CC(2);
    
        % Calculate CC from two halves of randomized data
        lap_half1 = activity_rand(half1_idx,:);
        lap_half2 = activity_rand(half2_idx,:);
        CC = corrcoef(mean(lap_half1,'omitnan'),mean(lap_half2,'omitnan'));
        bt_CC_rand(j) = CC(2);
        
    end

    % test actual CC distribution against shuffled distribution
    try
        P = ranksum(bt_CC_data,bt_CC_rand,'tail','right');
        nan_cell_vec(i) = 0;
        
        x1 = bt_CC_data; 
        x2 = bt_CC_rand; 
        n1 = numel(x1);
        n2 = numel(x2);
        mean_x1 = mean(x1,'omitnan');
        mean_x2 = mean(x2,'omitnan');
        var_x1  = var(x1,'omitnan');
        var_x2  = var(x2,'omitnan');
        meanDiff = (mean_x1 - mean_x2);
        sv1 = ((n1-1)*var_x1);
        sv2 = ((n2-1)*var_x2);
        numer =  sv1 + sv2;
        denom = (n1 + n2 - 2);
        pooledSD =  sqrt(numer / denom); % pooled Standard Deviation
        s = pooledSD;             % re-name
        d =  meanDiff / s;        % Cohen's d (for independent samples)
        
    catch
%         disp(['Error: Unable to calculate reliability for neuron #' num2str(i)])
        nan_cell_vec(i) = 1;
        P = 1;
    end
    
    if P < params.alpha_val && d > params.cohen_thresh
        reliable_cell_vec(i) = 1;
    end
    
    %% Test Gaussian fit for each cell

    % extract mean response
    mean_resp = mean(activity_data,'omitnan')*100;
    
    % shift max response to center
    [~,max_idx] = max(smooth(mean_resp));
    centered_resp = circshift(mean_resp,round(numSamp/2)-max_idx);
    
    % fit gaussian and save full widith at half-maximum and goodness-of-fit
    if nan_cell_vec(i) ~= 1 % if nan cell flag is false
        fit_func = fittype('a0+a1*exp(-((x-b1)/c1)^2)'); % define function: gaussian w/ baseline
        initial_param = [0 0 36 20];                     % initial parameters: [a0 a1 b1 c1]
        [fitobj,gof] = fit([1:numSamp]',centered_resp',fit_func,'StartPoint',initial_param);
        baseline_vec(i) = fitobj.a0;
        amp_vec(i) = fitobj.a1;
        FWHM_vec(i) = 2*sqrt(log(2)) * fitobj.c1 * cm_per_bin;
        gof_vec(i) = gof.rsquare;
    end
    
    % plot fit if desired
    if plot_fits==1 && reliable_cell_vec(i)==1
        figure(1)
        plot(fitobj,[1:numSamp],centered_resp);
        title(['Neuron #' num2str(i) ', FWHM = ' num2str(FWHM_vec(i),'%.1f')...
            ' cm, r^2 = ' num2str(gof_vec(i),'%.2f')])
        figure(2)
        imagesc(circshift(activity_data, [1, round(numSamp/2)-max_idx]))
        colormap(cmap)
        pause
    end
    % determine if current cell is place cell (then plot response if desired)
    if reliable_cell_vec(i)==1 && amp_vec(i)>0 && FWHM_vec(i)<params.FWHM_max && FWHM_vec(i)>params.FWHM_min && gof_vec(i)>params.gof_thresh && (amp_vec(i)/abs(baseline_vec(i)))>params.amp_thresh
        
        % indicate whether a place cell
        place_cell_vec(i) = 1;
        
        % calculate cross_validated response
        [~,preferred_pos(i)] = max(mean(activity_data(half1_idx,:),'omitnan'));
        cross_validated_resp(i,:) = mean(activity_data(half2_idx,:),'omitnan');
        
        % plot place cell response if desired
        if plot_resp==1
            
            % calculate sem (fix NaNs at end if necessary)
            sem_resp = std(activity_data)/sqrt(size(activity_data,1))*100;
            
            if isnan(sem_resp(1))
                counter = 2; 
                while isnan(sem_resp(counter))
                    counter = counter + 1;
                end
                sem_resp(1) = sem_resp(counter); 
            end
            
            for kk = 2:length(sem_resp)
                if isnan(sem_resp(kk))
                    sem_resp(kk) = sem_resp(kk - 1);
                end
            end
%             if isnan(sem_resp(1))
%                 sem_resp(1) = sem_resp(2);
%             elseif isnan(sem_resp(end))
%                 sem_resp(end) = sem_resp(end-1);
%             end
%             
            % plot mean +/- sem
            x_vec = [1:numSamp fliplr(1:numSamp)]*cm_per_bin;
            y_vec = [mean_resp+sem_resp fliplr(mean_resp-sem_resp)];
            hold off
            fill(x_vec,y_vec,[0 0.75 1],'edgecolor',[0 0.75 1])
            hold on
            plot((1:numSamp)*cm_per_bin,mean_resp,'k','linewidth',3)
            xlabel('Position (cm)')
            ylabel('DF/F')
            title(['Neuron #' num2str(i) ' place field'])
            set(gcf,'color',[1 1 1])
            hold off
            pause
            
        end
    end
    
end

% Narrow down FWHM to only valid pc's
FWHM = FWHM_vec(find(place_cell_vec));

% Place cells
PCs = find(place_cell_vec == 1); 

%% Plot cross-validated place cell response
if plot_resp
    pref_positions = preferred_pos(PCs);
    cross_val_resp_mat = cross_validated_resp(PCs,:);
    [~,sort_idx] = sort(pref_positions,'ascend');
    sorted_cross_val_resp = cross_val_resp_mat(sort_idx,:);
    for i = 1:size(sorted_cross_val_resp,1)
        sorted_cross_val_resp(i,:) = smooth(sorted_cross_val_resp(i,:));
        sorted_cross_val_resp(i,:) = sorted_cross_val_resp(i,:)-min(sorted_cross_val_resp(i,:));
        sorted_cross_val_resp(i,:) = sorted_cross_val_resp(i,:)/max(sorted_cross_val_resp(i,:));
    end
    imagesc((1:numSamp)*cm_per_bin,1:sum(place_cell_vec),sorted_cross_val_resp)
    xlabel('Position (cm)')
    ylabel('Neuron (sorted)')
    title('Place cells plotted by position')
    set(gcf,'color',[1 1 1])
end

place_cell_pctl = sum(place_cell_vec)/numCell*100;
disp(['Percentage of place cells = ' num2str(place_cell_pctl,'%.1f') '%'])

%% Computing spatial information of all cells
% load lap_by_lap_activity_spikes.mat
numCell = size(lap_activity,3);
spatial_info = zeros(1, numCell); 
mean_activity = zeros(1, numCell); 

for ii = 1:numCell
    A_ii = mean(lap_activity(:, :, ii),'omitnan'); 
    C_ii = sum(~isnan(lap_activity(:, :,ii))); 
    [spatial_info(ii), mean_activity(ii)] = Spatial_Information_v2(A_ii, C_ii);
end

%% Saving 
if save_flag==1
    save_file_name = 'DFF_place_cells_cohens_d';
    save(save_file_name,'reliable_cell_vec','FWHM_vec','gof_vec','place_cell_vec', 'spatial_info', 'spatial_precision');
    saveas(gcf,save_file_name)
end
end