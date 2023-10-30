function [] = plotAllLapByLap_SingleEnv(data,lap_by_lap_activity)

n_cells = length(data.DFF(:,1));
laps = lap_by_lap_activity;

figure
for ii = 1:n_cells
    imagesc(laps(:,:,ii))
    c = colormapMaker([0,0,0;0,255,255]); % black to cyan
    colormap(c)
    title(strcat('Lap by Lap Activity: Cell #', num2str(ii)))

    minColorLimit = min((min(laps(:,:,ii))));
    maxColorLimit = max((max(laps(:,:,ii))));
    c = colorbar;
    set(c,'Position',[0.93 0.168 0.022 0.7])  % attach colorbar to axis
    clim([minColorLimit,maxColorLimit]);        % set colorbar limits
    disp('Press any button to advance')
    pause
end