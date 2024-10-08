clear all; close all; clc

%% Init
initFig;
folder.fig = [strcat(folder.root, "5_outreach/manuscript/figures/figSupp5"), ...
              strcat(folder.root, "5_outreach/manuscript/figures/figSupp6")];

%% Plot proportion fixations on easy set
idx.doubleVisual = 2;
idx.doubleManual = 4;
axScalingFactor = 0.10;
textLocOffset = [0.25, 0.08];

xLabels = ["Emp. prop. mov. chosen [visual]", ...
           "Emp. prop. mov. chosen [manual]"];
yLabels = ["Pred. prop. mov. chosen [visual]", ...
           "Pred. prop. mov. chosen [manual]"];
plotDataEmp = cat(3, ...
                  data.fixations.propFixOnChosenModelEval(:,:,idx.doubleVisual), ...
                  data.fixations.propFixOnChosenModelEval(:,:,idx.doubleManual));
plotDataPred = cat(3, ...
                   probabilisticModel.pred.visual.propFixChosen, ...
                   probabilisticModel.pred.manual.propFixChosen);
axLim = [0, 1, 0, 1];
locText = [(axLim(2) - textLocOffset(1)), ...
           (axLim(3) + textLocOffset(2))];
nSetSizes = size(plotDataEmp, 2);
nFigures = size(plotDataEmp, 3);

for f = 1:nFigures % Figure
    hFig = figure;
    hTile = tiledlayout(3, 3);
    for p = 1:nSetSizes % Panel
        r = corrcoef(plotDataEmp(:,p,f), plotDataPred(:,p,f), ...
                     "Rows", "Complete");
        rSquared = round(r(1,2)^2, 2);
    
        nexttile;
        line([0, 5], [0, 5], ...
             'LineStyle', '-', ...
             'LineWidth', plt.line.widthThin, ...
             'Color', plt.color.black, ...
             'HandleVisibility', 'off');
        hold on
        plot(plotDataEmp(:,p,f), plotDataPred(:,p,f), ...
             'o', ...
             'MarkerSize', plt.marker.sizeSmall, ...
             'MarkerFaceColor', plt.color.gray(2,:), ...
             'MarkerEdgeColor', plt.color.white, ...
             'LineWidth', plt.line.widthThin, ...
             'Color', plt.color.black)
        errorbar(mean(plotDataEmp(:,p,f), 1, 'omitnan'), ...
                 mean(plotDataPred(:,p,f), 1, 'omitnan'), ...
                 ci_mean(plotDataPred(:,p,f)), ...
                 ci_mean(plotDataPred(:,p,f)), ...
                 ci_mean(plotDataEmp(:,p,f)), ...
                 ci_mean(plotDataEmp(:,p,f)), ...
                 'o', ...
                 'MarkerSize', plt.marker.sizeLarge, ...
                 'MarkerFaceColor', plt.color.black, ...
                 'MarkerEdgeColor', 'none', ...
                 'LineWidth', plt.line.widthThin, ...
                 'CapSize', 0, ...
                 'Color', plt.color.black, ...
                 'HandleVisibility', 'off')
        [~, ~, h] = plotMean(plotDataEmp(:,p,f), plotDataPred(:,p,f), plt.color.black);
        set(h(4), 'LineWidth', plt.line.widthThin);
        hold off
        axis(axLim, 'square');
        % Weird workaround: cannot use xticks/yticks, because Matlab, for
        % some reason, re-orders axis labels during saving of the figure
        set(gca, 'xtick', 0:0.50:1, 'xticklabel', 0:0.50:1); 
        set(gca, 'ytick', 0:0.50:1, 'yticklabel', 0:0.50:1);
        text(locText(1), locText(2), ...
             ['{\itr^{2}}', ' = ', num2str(rSquared)]);
        title(strcat(num2str(p-1), " easy distractors"));
        box off

        if checkAxLim(axLim, ...
                      [plotDataEmp(:,p,f), plotDataPred(:,p,f)])
            error("Current axis limits result in values being cut-off!");
        end
    end
    xlabel(hTile, xLabels(f), "FontSize", opt.fontSize);
    ylabel(hTile, yLabels(f), "FontSize", opt.fontSize);

    sublabel([], -10, -50);
    opt.size = [35, 35];
    opt.imgname = folder.fig(f);
    opt.save = true;
    prepareFigure(hFig, opt);
    close;
end