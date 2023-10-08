function [] = plotOneD_SingleEnv(activity_binned_1D_smoothed)

n_cells = size(activity_binned_1D_smoothed,1);
% Plot PC responses 5 at a time by environment
figure;
sgtitle('1D Smoothed Responses')
for i = 1:n_cells
    cell_resp = activity_binned_1D_smoothed(i, :);
    [~,max_idx] = max(cell_resp(1,:)); % location of max peak in env A
    subplot(n_cells,1,i)
    curr_resp = rescale(cell_resp); % normalize
    p = plot(1:size(activity_binned_1D_smoothed, 2), curr_resp, 'LineWidth', 1.5);
    p.Color = '#7577CD';
    xline(max_idx) % plot a vertical line in the middle of the plot, for centered: line at 36
    title(strcat('Cell #',num2str(i))); % plot cell # as subtitle
    xlabel('bins')
    ylabel('DFF')
    hold on
    hold off
end