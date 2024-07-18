function [propChoiceEasy, nFix, propFix] = getModelPred(setSizes, relativeGain, par, nNoiseSamples, lut, precision)

    % Generate predictions for proportion choices for the easy target,
    % proportion fixations on elements from the chosen set, and number of
    % fixations that need to be made before finding the target
    %
    % Input
    % setSizes:
    % matrix; number of easy (:,1) and difficult distractors (:,2) for
    % which to generate model predictions
    %
    % relativeGain:
    % matrix; relative gain of participants
    %
    % par:
    % vector; model parameter
    %
    % nNoiseSamples:
    % int; number of noise samples to apply on gain estimates
    %
    % lut:
    % matrix; look-up table with pre-calculated model predictions
    %
    % precision:
    % int; numerical precision of model parameters and predictions
    %
    % Output
    % propChoiceEasy:
    % matrix; predicted probability to choose easy target for different set 
    % sizes
    %
    % nFix:
    % matrix; predicted overall number of fixations required to find the
    % chosen target
    % 
    % propFix:
    % matrix; predicted probability to fixate an chosen element during
    % search for the chosen target

    %% Add decision noise to relative gain
    % Assumption:
    % participants don't act like an ideal observer, but deviate from it's
    % behavior. This deviation is quantified by some amount of additive
    % noise, added to the gain predictions
    noise = (randn(1, nNoiseSamples) .* par(2));
    noisyGain = repmat(relativeGain, 1, nNoiseSamples) + noise;

    %% Estimate fixation bias from gain and add fixation noise
    % Fixation biases are generated by converting the estimated (noisy)
    % gain values via a Gaussian cumulative density function. This has the
    % benefit that gain values will be normalised, and can add additional
    % fixation noise by varying the STD of the Gaussian CDF. When 
    % generating fixation biases, we multiply the result of the CDF
    % transformation by 2 so that the values are in a range that our
    % model can operate with. Additionally, we round fixationen biases to
    % make the fitting computationally tractable
    %
    % Assumption:
    % participants are NOT exclusively fixating elements from the set of
    % the higher gain target, but occasionally fixate other elements on the
    % screen. This preference for fixating other elements is quantified by
    % some of additive noise, added during conversion of gain to fixation
    % bias
    fixationBiases = cdf('Normal', noisyGain, 0, par(1)) .* 2;
    fixationBiases = round(fixationBiases, precision);

    %% Make predictions
    % Instead of actually generating model predictions by building a
    % decision tree, we extract pre-calculated predictions from a look-up
    % table. Multiple steps are performed for this:
    % - For each set size combination, determine the corresponding fixation
    %   bias. Do as often, as we have noise samples
    % - Calculate the indices in the look-up table, where we store the
    %   model predictions for a given combination of model parameters and
    %   set size
    % - Using the calculated indices, extract model predictions from the
    %   look-up table
    matOffset = setSizes(:,1) - 1;
    nBiases = numel(0:(10^-precision):2); % How many unique bias parameters will we have for a given numerical precision?

    parCombinations = [fixationBiases(:), ...
                       repmat(setSizes, nNoiseSamples, 1)];
    idxLut = round((parCombinations(:,1) * 10^precision) + 1) + ...
             (matOffset(parCombinations(:,2)) * nBiases);
    predictions = lut(idxLut,:);

    % Sanity check
    % If the extraction of model predictions from the look-up table worked
    % as intended, the "predictions" matrix should store the same fixation
    % bias parameter (:,1) and the same set size condition label (:,2) as 
    % the matrix ("parCombinations") that we used to calculate the look-up
    % table indices
    deltaMatrices = parCombinations(:,1:2) - predictions(:,1:2);
    if any(deltaMatrices(:) ~= 0)
        error("Extracted model predictions don't match expectation." + ...
              "Please check function!");
    end

    % Since all predictions for all biases where extracted from the lookup
    % table, here we only have to average over noise samples
    nSetSizes = size(setSizes, 1);
    nPredictions = nNoiseSamples * nSetSizes;

    nFix = NaN(nSetSizes, 3);
    propChoiceEasy = NaN(nSetSizes, 2);
    for ss = 1:nSetSizes % Set-size condition
        idx = ss:nSetSizes:nPredictions; % Faster than logical indexing

        propChoiceEasy(ss,:) = mean(predictions(idx,3:4), 1);
        nFix(ss,:) = mean(predictions(idx,5:7), 1);
    end
    propFix = nFix(:,1) ./ nFix(:, 3); % Fixations on chosen/not-chosen / over all fixations
    propChoiceEasy = propChoiceEasy(:,1); % Drop difficult
    nFix = nFix(:,3);

end