function par = fitSigmoid(exper, proportionChoicesEasy)

    % Fit sigmoid (Gaussian CDF) to choice data of participants
    %
    % Input
    % exper:
    % structure; general experiment settings, as returned by the
    % "settings_exper" script
    %
    % proportionChoicesEasy:
    % matrix; proportion choices for easy target for different set sizes of
    % easy distractors
    %
    % Output
    % par:
    % matrix; model parameters

    %% Init
    DO_PLOT = false; % Debuging setting

    opt = optimset('MaxFunEvals', 100000, ...
                   'MaxIter', 100000, ...
                   'TolFun', 1e-12, ...
                   'TolX', 1e-12);
    x = (0:8)';
    parMin = [-2, -inf]; % [Mean, SD]
    parMax = [10, inf];
    parStart = [mean(x), std(x)];
    fixedMean = 0;
    
    %% Fit
    par = NaN(exper.n.SUBJECTS, 3, exper.n.CONDITIONS);
    for c = 1:exper.n.CONDITIONS % Condition
        if DO_PLOT
            close all;
            figure;
            hTiles = tiledlayout(4,5);
        end
    
        for s = 1:exper.n.SUBJECTS % Subject
            thisSubject.number = exper.num.SUBJECTS(s);
            thisSubject.proportionChoicesEasy = ...
                proportionChoicesEasy(thisSubject.number,:,c)';
            if all(isnan(thisSubject.proportionChoicesEasy))
                continue
            end
    
            thisPar = ...
                fminsearchbnd(@lossCdf, ...
                              parStart, ...
                              parMin , ...
                              parMax, ...
                              opt, ...
                              x, ...
                              thisSubject.proportionChoicesEasy);
            par(thisSubject.number,1,c) = thisPar(1); % Mean
            par(thisSubject.number,2,c) = thisPar(2); % Std

            % Get slopes
            % With unconstrained SDs we might get parameter values that
            % are extremely large. Those will be outliers and make the 
            % parameters hard to analyse. To get around this, we use the
            % fitted SDs and a fixed mean to estimate the Gaussian PDF, 
            % and then get the PDF value at 0; this is then used as the 
            % slope of the CDF, and a substitute for the SD.
            %
            % Explanation:
            % the first derivative of the sigmoid yields the slope, and
            % corresponds to the PDF of the sigmoid
            thisSubject.pdf = pdf("Normal", x, fixedMean, thisPar(2)) .* -1;
            thisSubject.idxSlope = (x == fixedMean);
            par(thisSubject.number,3,c) = ...
                thisSubject.pdf(thisSubject.idxSlope);
    
            if DO_PLOT
                parRaw = strcat("Mean: ", num2str(round(thisPar(1), 2)), ...
                                "; Std: ", num2str(round(thisPar(2), 2)));
    
                nexttile;
                if sign(thisPar(2)) == -1
                    % If SD is negative, plot a regular sigmoids that
                    % increases towards right
                    pred = cdf('Normal', x, thisPar(1), abs(thisPar(2)));
                else
                    % Plot sigmoids starting from left and decreasing
                    % towards right. Need to "flip" regular CDF to achieve
                    % this
                    pred = 1 - cdf('Normal', x, thisPar(1), thisPar(2));
                end
                plot(x, pred, '-b');
                hold on;
                plot(x, thisSubject.proportionChoicesEasy, '-r');
                hold off;
                axis([min(x)-1, max(x)+1, 0, 1]);
                xticks(x);
                title(parRaw);
                box off;
            end
        end
        if DO_PLOT
            hLegend = legend(["Predicted", "Empirical"], "Location", "NorthEast");
            legend box off;
            nTiles = size(hTiles.Children, 1);
            hLegend.Layout.Tile = nTiles;
        end
    end

end