clear all; close all; clc

%% Get data
% Set folder
folder.root = '/Users/ilja/Dropbox/12_work/mr_informationSamplingVisualManual/';
folder.data = strcat(folder.root, '2_data/');
folder.fig = strcat(folder.root, "5_outreach/manuscript/figures/fig2");

data = load(strcat(folder.data, 'data_newPipeline.mat'));

%% Plot settings
% Assemble data for plot
plotDat = cat(3, ...
              [data.data.performance.proportionCorrect.easy(:,1), ...
               data.data.performance.proportionCorrect.difficult(:,1)], ...
              [data.data.time.planning.mean.easy(:,1), ...
               data.data.time.planning.mean.difficult(:,1)], ...
              [data.data.time.inspection.mean.easy(:,1), ...
               data.data.time.inspection.mean.difficult(:,1)], ...
              [data.data.time.response.mean.easy(:,1), ...
               data.data.time.response.mean.difficult(:,1)], ...
              [data.data.performance.proportionCorrect.easy(:,3), ...
               data.data.performance.proportionCorrect.difficult(:,3)], ...
              [data.data.time.planning.mean.easy(:,3), ...
               data.data.time.planning.mean.difficult(:,3)], ...
              [data.data.time.inspection.mean.easy(:,3), ...
               data.data.time.inspection.mean.difficult(:,3)], ...
              [data.data.time.response.mean.easy(:,3), ...
               data.data.time.response.mean.difficult(:,3)]);

% Define visuals
opt_visuals;
xLabels = repmat(["Proportion correct easy", "Planning time easy [s]", ...
                  "Inspection time easy [s]", "Response time easy [s]"], ...
                 1, 2);
yLabels = repmat(["Proportion correct difficult", "Planning time difficult [s]", ...
                  "Inspection time difficult [s]", "Response time difficult [s]"], ...
                 1, 2);
axLimits = [[0.70, 1]; [150, 750]; [250, 1000]; [400, 1300]; ...
            [0.70, 1]; [500, 1250]; [750, 1650]; [400, 1300]];
axTicks = [{axLimits(1,1):0.10:axLimits(1,2)}, ...
           {axLimits(2,1):200:axLimits(2,2)}, ...
           {axLimits(3,1):250:axLimits(3,2)}, ...
           {axLimits(4,1):300:axLimits(4,2)}, ...
           {axLimits(5,1):0.10:axLimits(5,2)}, ...
           {axLimits(6,1):250:axLimits(6,2)}, ...
           {axLimits(7,1):300:axLimits(7,2)}, ...
           {axLimits(8,1):300:axLimits(8,2)}];

plotDat(:,:,[2:4, 6:8]) = plotDat(:,:,[2:4, 6:8]) ./ 1000;
axLimits([2:4, 6:8],:) = round(axLimits([2:4, 6:8],:) ./ 1000, 2);
axTicks([2:4, 6:8]) = cellfun(@(x) x ./ 1000, axTicks([2:4, 6:8]), 'UniformOutput', false);

%% Plot
hFig = figure;
tiledlayout(2, 4);
for p = 1:size(plotDat, 3) % Panel
    if any(p == 1:4)
        plt.color.condition = plt.color.green;
    else
        plt.color.condition = plt.color.purple;
    end

    nexttile;
    line(axLimits(p,:), axLimits(p,:), ...
        'LineStyle', '--', ...
        'LineWidth', plt.line.widthThin, ...
        'Color', plt.color.gray(3,:), ...
        'HandleVisibility', 'off');
    hold on
    plot(plotDat(:,1,p), plotDat(:,2,p), ...
        'o', ...
        'MarkerSize', plt.marker.sizeSmall, ...
        'MarkerFaceColor', plt.color.condition(2,:), ...
        'MarkerEdgeColor', plt.color.white, ...
        'LineWidth', plt.line.widthThin, ...
        'Color', plt.color.condition(2,:))
    errorbar(mean(plotDat(:,1,p), 1, 'omitnan'), ...
             mean(plotDat(:,2,p), 1, 'omitnan'), ...
             ci_mean(plotDat(:,2,p)), ci_mean(plotDat(:,2,p)), ...
             ci_mean(plotDat(:,1,p)), ci_mean(plotDat(:,1,p)), ...
            'o', ...
            'MarkerSize', plt.marker.sizeLarge, ...
            'MarkerFaceColor', plt.color.condition(1,:), ...
            'MarkerEdgeColor', 'none', ...
            'LineWidth', plt.line.widthThin, ...
            'CapSize', 0, ...
            'Color', plt.color.condition(1,:), ...
            'HandleVisibility', 'off')
    [~, ~, h] = plotMean(plotDat(:,1,p), plotDat(:,2,p), plt.color.condition(1,:));
    set(h(4), 'LineWidth', plt.line.widthThin);
    hold off
    axis([axLimits(p,:), axLimits(p,:)], 'square');
    xlabel(xLabels(p));
    ylabel(yLabels(p));
    xticks(axTicks{p});
    yticks(axTicks{p});
    box off
end
sublabel([], -60, -45);
opt.size = [55, 25];
opt.imgname = folder.fig;
opt.save = true;
prepareFigure(hFig, opt);
close;