clear all; close all; clc

%% Get data
% Set folder
folder.root = '/Users/ilja/Dropbox/12_work/mr_informationSamplingVisualManual/';
folder.data = strcat(folder.root, '2_data/');
folder.fig = strcat(folder.root, "5_outreach/manuscript/figures/fig3");

data = load(strcat(folder.data, 'data_newPipeline.mat'));

% Number of participants to use as representative participants
subjectOfInterest = [4, 4];
conditionsOfInterest = [2, 4]; % Only double-target

% Define visuals
opt_visuals;

%% Panel A&B: choice curves of representative participants
axisLimits = [[-1, 9]; [0, 1.15]];
titleLabels = {'Visual search', 'Manual search'};

hFig = figure;
tiledlayout(1, 3);
for c = 1:numel(conditionsOfInterest)
    intercept = data.data.choice.regressionFit(subjectOfInterest(c),1,conditionsOfInterest(c));
    slope = data.data.choice.regressionFit(subjectOfInterest(c),2,conditionsOfInterest(c));
    x = (0:1:8)';
    yPredicted = (intercept + slope .* (x-4)) + 0.50;
    yEmpirical = ...
        data.data.choice.target.proportionEasy(subjectOfInterest(c),:,conditionsOfInterest(c));
    regressionEquation = ...
        ['y = ', num2str(round(intercept, 2)), ' + x * ', ...
         num2str(round(slope, 2))];
    lineLimitsHorizontal = [axisLimits(1,:)', [4; 4]];
    lineLimitsVertical = [[0.50; 0.50], [0.20; axisLimits(2,2)]];
    if c == 1
        thisColor = plt.color.green(2,:);
    elseif c == 2
        thisColor = plt.color.purple(2,:);
    end

    nexttile;
    line(lineLimitsHorizontal, lineLimitsVertical, ...
        'LineStyle', '--', ...
        'LineWidth', plt.line.widthThin, ...
        'Color', plt.color.gray(3,:), ...
        'HandleVisibility', 'off');
    hold on
    plot(x, yEmpirical, ...
        'o-', ...
        'MarkerSize', plt.marker.sizeSmall, ...
        'MarkerFaceColor', thisColor, ...
        'MarkerEdgeColor', 'none', ...
        'LineWidth', plt.line.widthThick, ...
        'Color', thisColor)
    plot(x, yPredicted, ...
        '-', ...
        'LineWidth', plt.line.widthThick, ...
        'Color', plt.color.black);
    text(-0.25, 0.10, regressionEquation)
    hold off
    axis([axisLimits(1,:), axisLimits(2,:)], 'square')
    xticks((axisLimits(1,1)+1):2:(axisLimits(1,2)-1))
    yticks(axisLimits(2,1):0.25:axisLimits(2,2))
    xlabel('# easy distractors');
    ylabel('Prop. choices [easy target]');
    box off
    title(titleLabels(c));
end

%% Panel 2: regression parameter all participants
intercepts = squeeze(data.data.choice.regressionFit(:,1,conditionsOfInterest));
slopes = squeeze(data.data.choice.regressionFit(:,2,conditionsOfInterest));
regPar = cat(3, intercepts, slopes);

axisLimits = [min(regPar(:)), max(regPar(:))];
plotMarker = {'o', 'd'};
lineHorizontal = [[axisLimits'], [axisLimits'], [0; 0]];
lineVertical = [[axisLimits'], [0; 0], axisLimits'];

axisHandle = nexttile;
line(lineHorizontal, lineVertical, ...
     'LineStyle', '--', ...
     'LineWidth', plt.line.widthThin, ...
     'Color', plt.color.gray(3,:), ...
     'HandleVisibility', 'off');
hold on
for p = 1:size(regPar, 3) % Parameter
    plot(regPar(:,1,p), regPar(:,2,p), ...
         'Marker', plotMarker{p}, ...
         'MarkerSize', plt.marker.sizeSmall, ...
         'MarkerFaceColor', plt.color.gray(2,:), ...
         'MarkerEdgeColor', plt.color.white, ...
         'LineStyle', 'none', ...
         'LineWidth', plt.line.widthThin, ...
         'HandleVisibility', 'off');
    [~, ~, meanHandle] = plotMean(regPar(:,1,p), regPar(:,2,p), plt.color.black);
    set(meanHandle, ...
        'MarkerSize', plt.marker.sizeLarge, ...
        'MarkerFaceColor', plt.color.black, ...
        'MarkerEdgeColor', 'none', ...
        'LineWidth', plt.line.widthThin);
    set(meanHandle(1), ...
        'Marker', plotMarker{p});
    set(meanHandle(2:end), ...
        'HandleVisibility', 'off')
end
set(axisHandle, ...
    'XColor', plt.color.green(1,:), ...
    'YColor', plt.color.purple(1,:));
hold off
axis([axisLimits, axisLimits], 'square')
xticks(-0.10:0.10:0.50);
yticks(-0.10:0.10:0.50);
xlabel('Visual search')
ylabel('Manual search')
legend({'Intercept [difficulty]'; 'Slope [set size]'}, ...
        'Position', [0.60, 0.19, 0.50, 0.14]);
legend box off
box off

sublabel([], -130, -30);
opt.size = [50, 15];
opt.imgname = folder.fig;
opt.save = true;
prepareFigure(hFig, opt);
close