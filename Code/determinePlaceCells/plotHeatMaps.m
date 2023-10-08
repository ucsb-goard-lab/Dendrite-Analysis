function [valid_PCs,valid_SCs,sorted_PCs,PC_activity] = plotHeatMaps(PC_array,...
    SC_array,activity_binned_1D_smoothed,num_envs,valid_PCs,valid_SCs)
%% Sort place cell responses
if num_envs > 1

    %% USE IF USING PCS FOUND IN > 1 ENV
    %     int_1 = intersect(PC_array{1},PC_array{2});
    %     int_2 = intersect(PC_array{1},PC_array{3});
    %     int_3 = intersect(PC_array{2},PC_array{3});
    %     all_int = [int_1,int_2,int_3];
    %     valid_PCs = unique(all_int);

    % find order of PCs
    PC_activity1 = activity_binned_1D_smoothed{1,:}(valid_PCs, :);
    [ ~, b ] = max(PC_activity1, [], 2);
    [~, master_sorted_ids] = sort(b);
    sorted_PCs = valid_PCs(master_sorted_ids); % prev: (:,master_sorted_ids);
else
    % Sort pcs by max response along the track
    PC_activity = activity_binned_1D_smoothed(PC_array, :);
    [ ~, m ] = max(PC_activity, [], 2);
    [~, sorted_ids] = sort(m);
    sorted_PCs = sorted_ids;
    valid_PCs = PC_array;
    valid_SCs = SC_array;
end

if num_envs > 1
PC_activity = cell(num_envs,1);
    for j = 1:num_envs
        % Plotting
        %Plot spatial information
        %         figure
        %         curr_spatial_info = spatial_info{j,:};
        %         plot(1:length(curr_spatial_info), curr_spatial_info, 'ko'); hold on
        %         plot(valid_PCs, curr_spatial_info(valid_PCs), 'ro');
        %         format = 'Spatial Information Plot %d';
        %         idx1 = j;
        %         title_1 = sprintf(format,idx1);
        %         title(title_1)

        % Plot uncentered PCs
        %         figure;
        %         for ii = 1:length(valid_PCs)
        %             subplot(ceil(sqrt(length(valid_PCs))), ceil(sqrt(length(valid_PCs))), ii)     % all place cell 1D smoothed maps uncentered
        %             plot(1:size(activity_binned_1D_smoothed{j,:}, 2), ...
        %                 activity_binned_1D_smoothed{j,:}(valid_PCs(ii), :), 'k-', 'LineWidth', 1.5);
        %             title(strcat({num2str(valid_PCs(ii))}, {' '}, {'corr = '}, {num2str(consistency{j,:}(valid_PCs(ii)))}));
        %         end
        %         format2 = 'Uncentered Place Cells %d';
        %         title_2 = sprintf(format2,idx1);
        %         sgtitle(title_2)

        % Plot PC heatmap
        % based on predetermined master sorted indices
        maxpt = length(activity_binned_1D_smoothed{j,:});
        sorted_PCs(:,sorted_PCs>maxpt) = []; % make sure sorted PCs don't exceed existing PCs
        figure;
        PC_activity{j,:} = activity_binned_1D_smoothed{j,:}(valid_PCs, :);
        sorted_PC_activity = activity_binned_1D_smoothed{j,:}(sorted_PCs, :);
        imagesc(sorted_PC_activity);
        if j == 1 % different colors for different cues
            cmap = colormapMaker([255,255,255;117,119,205]);
            colormap(cmap);
        elseif j == 2
            cmap = colormapMaker([255,255,255;255,109,2]);
            colormap(cmap);
        else
            cmap = colormapMaker([255,255,255;8,9,87]);
            colormap(cmap);
        end
        format5 = 'Place Cell heat map %d';
        title_5 = sprintf(format5,j);
        title(title_5)
    end
else
    % Plot PC heatmap
    % based on predetermined master sorted indices
    maxpt = length(activity_binned_1D_smoothed);
    sorted_PCs(:,sorted_PCs>maxpt) = []; % make sure sorted PCs don't exceed existing PCs
    figure;
    PC_activity = activity_binned_1D_smoothed(valid_PCs, :);
    sorted_PC_activity = activity_binned_1D_smoothed(sorted_PCs, :);
    imagesc(sorted_PC_activity);
    cmap = colormapMaker([255,255,255;117,119,205]);
    colormap(cmap);
    title('Place Cell heat map')
end