close all; clear all; clc;

%% Load settings
settings_exper;
settings_figure;
settings_analysis;
settings_screen;
settings_log;

addpath(exper.path.ANALYSIS);
cd(exper.path.ROOT);

%% Extract data from files
data.log = getLogFiles(exper, logCol);
data.gaze = getDatFiles(exper, screen, anal, data.log.nCompletedTrials);
data.badTrials = ...
    getBadTrials(exper, data.log.nCompletedTrials, exper.path.DATA);

%% Asses data quality
quality.excludedTrials = ...
    getExcludeTrials(exper, ...
                     anal, ...
                     data.log.error.fixation.online, ...
                     data.gaze.error.fixation.offline, ... 
                     data.gaze.error.dataLoss, ...
                     data.gaze.error.eventMissing, ...
                     data.badTrials);
[quality.proportionValidTrials, quality.nValidTrials] = ...
    getProportionValidTrials(exper, anal, data.log.nCompletedTrials, ...
                             quality.excludedTrials);

%% Drop excluded trials from variables
% Log files contain all trials, and thus, do not yet account for excluded
% trials. This step is not necessary for everything but the stuff from log
% files, because functions are designed to skip over excluded trials
data.log.hitOrMiss = ...
    dropTrials(exper, anal, data.log.hitOrMiss, quality.excludedTrials);
data.log.nDistractors.easy.trialwise = ...
    dropTrials(exper, anal, data.log.nDistractors.easy.trialwise, quality.excludedTrials);
data.log.nDistractors.difficult.trialwise = ...
    dropTrials(exper, anal, data.log.nDistractors.difficult.trialwise, quality.excludedTrials);

%% Get screen coordinates of stimuli
data.stimulusCoordinates = getStimCoord(exper, anal, logCol, data.log.files);

%% Get gaze shifts
data.gaze.gazeShifts = ...
    getGazeShifts(exper, anal, data.gaze, data.log.nCompletedTrials, ...
                  quality.excludedTrials);

% Map trialwise variables to detected gaze shifts
data.log.nDistractors.easy.gazeShiftWise = ...
    trialwise2gazeShiftWise(exper, anal, ...
                            data.log.nCompletedTrials, ...
                            data.gaze.gazeShifts.trialMap, ...
                            data.log.nDistractors.easy.trialwise);

%% Get fixated areas of interest
data.fixations = ...
    getFixatedAois(exper, screen, anal, data.gaze, ...
                   data.stimulusCoordinates, ...
                   data.log.nCompletedTrials, ...
                   quality.excludedTrials, ...
                   fig.toggle.debug.SHOW_FIXATIONS);
data.fixations.propTrialOneAoiFix = ...
    getProportions(exper, anal, data.fixations.atLeastOneFixatedAoi, ....
                   quality.nValidTrials, []);

%% Analyse choice behavior
% Get chosen target
data.choice = getChoices(exper, anal, logCol, data.log, data.gaze, ...
                         data.fixations, quality.excludedTrials);
[~, data.choice.target.proportionEasy] = ...
    getAvg(exper, anal, data.choice.target.easy, ...
           data.choice.target.id, ...
           [], ...
           data.log.nDistractors.easy.trialwise);

% Test influence of difficult and set size on choices
% Do this by fitting a linear regression, and inspecting slope (set size)
% and intercepts (difficult)
data.choice.regressionFit = ...
    fitRegression(exper, anal, data.choice.target.proportionEasy, ...
                  data.log.nDistractors.easy.trialwise);

%% Analyse fixated AOIs over the course of a trial
% Timelock (valid) fixations to trial start
data.fixations.timelock = ...
    timelockGazeShifts(exper, anal, data.log.nCompletedTrials, ...
                       quality.excludedTrials, ...
                       data.gaze.gazeShifts.trialMap, ...
                       data.fixations.fixatedAois.groupIds, ...
                       data.fixations.subset);

% Check if specific areas of interest where fixated
data.fixations.wentToChosen = ...
    onChosenSet(anal, exper, ...
                data.log.nCompletedTrials, ...
                data.gaze.gazeShifts.trialMap, ...
                quality.excludedTrials, ...
                data.fixations.fixatedAois.groupIds, ...
                data.choice.target.id);
data.fixations.wentToSmallerSet = ...
    onSmallerSet(anal, exper, ...
                 data.log.nCompletedTrials, ...
                 data.gaze.gazeShifts.trialMap, ...
                 quality.excludedTrials, ...
                 data.fixations.fixatedAois.groupIds, ...
                 data.log.nDistractors.easy.trialwise, ...
                 data.log.nDistractors.difficult.trialwise);
data.fixations.wentToClosestStimulus = ...
    onClosestStimulus(anal, exper, ...
                      data.log.nCompletedTrials, ...
                      data.gaze.gazeShifts.trialMap, ...
                      quality.excludedTrials, ...
                      data.fixations.fixatedAois.uniqueIds, ...
                      data.stimulusCoordinates, ...
                      data.gaze.gazeShifts.onsets);

% Get proportion gaze shifts on AOIs at different points in a trial
data.fixations.timecourse.onChosen = ...
    getFixationTimeCourse(exper, ...                                
                          anal, ...
                          data.fixations.timelock, ...
                          1:2, ...
                          data.fixations.wentToChosen, ...
                          data.log.nDistractors.easy.gazeShiftWise, ...
                          false);
data.fixations.timecourse.onSmaller = ...
    getFixationTimeCourse(exper, ...                                
                          anal, ...
                          data.fixations.timelock, ...
                          1:2, ...
                          data.fixations.wentToSmallerSet, ...
                          data.log.nDistractors.easy.gazeShiftWise, ...
                          true);
data.fixations.timecourse.onClosest = ...
    getFixationTimeCourse(exper, ...                                
                          anal, ...
                          data.fixations.timelock, ...
                          1:2, ...
                          data.fixations.wentToClosestStimulus, ...
                          data.log.nDistractors.easy.gazeShiftWise, ...
                          false);

%% Get time-related variables
data.time = getTimes(exper, anal, data.log.nCompletedTrials, ...
                     data.gaze, ...
                     data.fixations, ...
                     quality.excludedTrials);

% Planning time
data.time.planning.mean.easy = ...
    getAvg(exper, anal, data.time.planning.trialwise, ...
           data.choice.target.id, ...
           exper.stimulus.id.target.EASY, ...
           data.log.nDistractors.easy.trialwise);
data.time.planning.mean.difficult = ...
    getAvg(exper, anal, data.time.planning.trialwise, ...
           data.choice.target.id, ...
           exper.stimulus.id.target.DIFFICULT, ...
           data.log.nDistractors.difficult.trialwise);
data.time.planning.mean.overall = ...
    getAvg(exper, anal, data.time.planning.trialwise, ...
           data.choice.target.id, ...
           [], ...
           data.log.nDistractors.easy.trialwise);

% Inspection time
data.time.inspection.mean.easy = ...
    getAvg(exper, anal, data.time.inspection.trialwise, ...
           data.choice.target.id, ...
           exper.stimulus.id.target.EASY, ...
           data.log.nDistractors.easy.trialwise);
data.time.inspection.mean.difficult = ...
    getAvg(exper, anal, data.time.inspection.trialwise, ...
           data.choice.target.id, ...
           exper.stimulus.id.target.DIFFICULT, ...
           data.log.nDistractors.difficult.trialwise);
data.time.inspection.mean.overall = ...
    getAvg(exper, anal, data.time.inspection.trialwise, ...
           data.choice.target.id, ...
           [], ...
           data.log.nDistractors.difficult.trialwise);

% Response time
data.time.response.mean.easy = ...
    getAvg(exper, anal, data.time.response.trialwise, ...
           data.choice.target.id, ...
           exper.stimulus.id.target.EASY, ...
           data.log.nDistractors.easy.trialwise);
data.time.response.mean.difficult = ...
    getAvg(exper, anal, data.time.response.trialwise, ...
           data.choice.target.id, ...
           exper.stimulus.id.target.DIFFICULT, ...
           data.log.nDistractors.difficult.trialwise);
data.time.response.mean.overall = ...
    getAvg(exper, anal, data.time.response.trialwise, ...
           data.choice.target.id, ...
           [], ...
           data.log.nDistractors.difficult.trialwise);

% Trial durations
data.time.trialDurations = ...
    getTrialDurations(exper, anal, data.log.nCompletedTrials, data.gaze);

% Proportion trials for which response time could be calculated
% if the last gaze shift was located in the AOI around a distractor, no
% response time was calculated
data.time.propTrialsWithResp = ...
    getProportions(exper, anal, data.time.response.trialwise, ....
                   quality.nValidTrials, "numeric");

% Time lost due to exclusion of trials
% Calculate time lost due to excluded trials and store # excluded trials
data.time.lostTime = ...
    getLostTime(exper, anal, quality.excludedTrials, data.time.trialDurations);

%% Get performance measures
% Target discrimination performance
data.performance.proportionCorrect.easy = ...
    getAvg(exper, anal, ...
           data.log.hitOrMiss, ...
           data.choice.target.id, ...
           exper.stimulus.id.target.EASY, ...
           data.log.nDistractors.easy.trialwise);
data.performance.proportionCorrect.difficult = ...
    getAvg(exper, anal, ...
           data.log.hitOrMiss, ...
           data.choice.target.id, ...
           exper.stimulus.id.target.DIFFICULT, ...
           data.log.nDistractors.difficult.trialwise);

% Final score at the end of conditions
data.performance.finalScores = getFinalScore(exper, anal, data.log.scores);

%% Store data
save(strcat(exper.path.DATA, "data_newPipeline.mat"));

%% DEBUG: check whether results from new match old pipeline
% Check which version of old pipeline data to load
oldDataVersion = "_allExclusions";

% For check of gaze data matrix: can run with bad trials excluded, because
% those are taken care of within the checkPipelines function
% 
% For check of individual variables: needs to run without bad trials
% exclusion, because this was not taken into account in the old pipeline,
% and thus, the data from there does not match
checkPipelines(exper, anal, logCol, data.log, data.gaze, ...
               data.fixations, data.time, data.choice, ...
               data.badTrials, quality.excludedTrials, oldDataVersion);
compareVariableOfInterest(quality.proportionValidTrials, ...
                          "proportionValid", oldDataVersion);
compareVariableOfInterest(data.time.propTrialsWithResp, ...
                          "proportionTrialsWithResponse", oldDataVersion);
compareVariableOfInterest(data.time.lostTime, ...
                          "timeLostExcldTrials", oldDataVersion);
compareVariableOfInterest(data.fixations.propTrialOneAoiFix, ...
                          "aoiFix", oldDataVersion);
compareVariableOfInterest(data.performance.proportionCorrect.easy, ...
                          "propCorrectEasy", oldDataVersion);
compareVariableOfInterest(data.performance.proportionCorrect.difficult, ...
                          "propCorrectDifficult", oldDataVersion);
compareVariableOfInterest(data.time.planning.mean.easy, ...
                          "planningTimeEasy", oldDataVersion);
compareVariableOfInterest(data.time.planning.mean.difficult, ...
                          "planningTimeDifficult", oldDataVersion);
compareVariableOfInterest(data.time.inspection.mean.easy, ...
                          "inspectionTimeEasy", oldDataVersion);
compareVariableOfInterest(data.time.inspection.mean.difficult, ...
                          "inspectionTimeDifficult", oldDataVersion);
compareVariableOfInterest(data.time.response.mean.easy, ...
                          "responseTimeEasy", oldDataVersion);
compareVariableOfInterest(data.time.response.mean.difficult, ...
                          "responseTimeDifficult", oldDataVersion);
compareVariableOfInterest(data.choice.target.proportionEasy(:,:,[2,4]), ...
                          "proportionEasyChoices", oldDataVersion);
compareVariableOfInterest(data.choice.regressionFit(:,:,[2,4]), ...
                          "regression", oldDataVersion);
compareVariableOfInterest(data.fixations.timecourse.onChosen(:,:,[2,4]), ...
                          "propGsOnChosen", oldDataVersion);
compareVariableOfInterest(data.fixations.timecourse.onSmaller(:,:,[2,4]), ...
                          "propGsOnSmaller", oldDataVersion);

compareVariableOfInterest(data.fixations.timecourse.onClosest, ...
                          "propGsOnClosest", oldDataVersion);

%% How much time participants spent searching for targets
sacc.time.search_reg_coeff = NaN(exper.num.subNo, 2, exper.num.condNo);
sacc.time.search_confInt   = NaN(2, 2, exper.num.subNo, exper.num.condNo);
sacc.time.search_ss        = NaN(exper.num.subNo, 9, exper.num.condNo);
for c = 1:exper.num.condNo % Condition

    for s = 1:exper.num.subNo % Subject

        thisSubject   = exper.num.subs(s);
        searchTime = sacc.time.search{thisSubject, c};
        if ~isempty(searchTime)

            searchTime = sacc.time.search{thisSubject, c}(:, 4);
            noDis_sub  = [stim.no_easyDis{thisSubject, c} stim.no_hardDis{thisSubject, c}];
            no_ss      = unique(noDis_sub(~isnan(noDis_sub(:, 1)), 1));
            for ss = 1:numel(no_ss) % Set size

                switch c

                    case 1
                        li_trials = any(noDis_sub == no_ss(ss), 2);

                    case 2
                        li_trials = noDis_sub(:, 1) == no_ss(ss);

                end

                sacc.time.search_ss(thisSubject, ss, c) = mean(searchTime(li_trials), 'omitnan');
                clear li_trials

            end
            clear no_ss ss noDis_sub

            % Regression over mean inspection time for different set sizes
            reg_predictor = (0:8)';
            reg_criterion = sacc.time.search_ss(thisSubject, :, c)';

            [sacc.time.search_reg_coeff(thisSubject, :, c), sacc.time.search_confInt(:, :, thisSubject, c)] = ...
                regress(reg_criterion, [ones(numel(reg_predictor), 1) reg_predictor]);
            clear reg_predictor reg_criterion

        end
        clear thisSubject searchTime

    end
    clear s

end
clear c


%% Proportion gaze shifts to chosen/not-chosen stimuli, as a function of set size
% Only gaze shifts to distractors as well as the last gaze shift to a
% target (if it was not followed by another gaze shift to a distractor) are
% counted; proportions are calculaed seperately for each set size and
% across alls gaze shifts, without separating for set sizes
sacc.propGs.onAOI_modelComparision_chosenNot    = NaN(exper.num.subNo, 2, exper.num.condNo); % Proportion fixations on chosen/not-chosen set
sacc.propGs.onAOI_modelComparision_chosenNot_ss = NaN(exper.num.subNo, 9, exper.num.condNo); % Proportion fixations on chosen/not-chosen set, seperate for set-sizes
sacc.propGs.onAOI_modelComparision_easyDiff     = NaN(exper.num.subNo, 2, exper.num.condNo); % Proportion fixations on easy/difficult set
sacc.propGs.onAOI_modelComparision_easyDiff_ss  = NaN(exper.num.subNo, 9, exper.num.condNo); % Proportion fixations on easy/difficult set, seperate for set-sizes
for c = 2:exper.num.condNo % Condition

    for s = 1:exper.num.subNo % Subject

        thisSubject = exper.num.subs(s);
        gs_sub   = sacc.gazeShifts{thisSubject, c};
        if ~isempty(gs_sub)

            % Extract unique fixations of elements
            % Removes multiple fixations of same element in trials as well
            % as fixations on targets, except for the last fixation in a
            % trial (if this one went to a target)
            gs_sub2 = [];
            for t = 1:exper.trialNo(s, c) % Trial

                dat_trial                        = gs_sub(gs_sub(:, 26) == t, :);
                li_targWhileSearch               = any(dat_trial(1:end-1, 18) == stim.identifier(1, :), 2); % Target fixation while searching
                dat_trial(li_targWhileSearch, :) = [];
                clear li_targWhileSearch

                [~, ia, ~] = unique(dat_trial(:, 17));

                gs_sub2 = [gs_sub2; sortrows(dat_trial(ia, :), 1)];
                clear dat_trial ia

            end
            gs_sub = gs_sub2;
            clear t gs_sub2

            % Calculate proportion fixations on chosen/not-chosen set
            fixatedStim                       = gs_sub(:, 18);
            id_chosenTarget                   = gs_sub(:, 23);
            li_easyChosen                     = id_chosenTarget == stim.identifier(1, 1);
            li_diffChosen                     = id_chosenTarget == stim.identifier(1, 2);
            id_nonChosenTarget                = NaN(numel(fixatedStim), 1);
            id_nonChosenTarget(li_easyChosen) = stim.identifier(1, 2);
            id_nonChosenTarget(li_diffChosen) = stim.identifier(1, 1);
            clear li_easyChosen li_diffChosen

            li_onDis           = any(fixatedStim == stim.identifier(:)', 2);
            li_onDis_easy      = any(fixatedStim(li_onDis) == stim.identifier(:, 1)', 2);
            li_onDis_diff      = any(fixatedStim(li_onDis) == stim.identifier(:, 2)', 2);
            li_onDis_chosen    = any(fixatedStim(li_onDis) == stim.identifier(:, id_chosenTarget(li_onDis))', 2);
            li_onDis_nonChosen = any(fixatedStim(li_onDis) == stim.identifier(:, id_nonChosenTarget(li_onDis))', 2);
            noValidGs          = sum(~isnan(id_chosenTarget(li_onDis)));

            sacc.propGs.onAOI_modelComparision_chosenNot(s, :, c) = [sum(li_onDis_chosen) / noValidGs ...
                                                                     sum(li_onDis_nonChosen) / noValidGs];
            sacc.propGs.onAOI_modelComparision_easyDiff(s, :, c)  = [sum(li_onDis_easy) / noValidGs ...
                                                                     sum(li_onDis_diff) / noValidGs];
            clear li_onDis li_onDis_easy li_onDis_diff li_onDis_chosen li_onDis_nonChosen noValidGs

            % Calculate proportion fixations on chosen/not-chosen set, as a function of set size
            setSizes = unique(gs_sub(:, 22));
            setSizes = setSizes(~isnan(setSizes));
            for ss = 1:numel(setSizes) % Set size

                li_ss                 = gs_sub(:, 22) == setSizes(ss);
                fixatedStim_ss        = fixatedStim(li_ss);
                id_chosenTarget_ss    = id_chosenTarget(li_ss);
                id_nonChosenTarget_ss = id_nonChosenTarget(li_ss);

                li_onDis           = any(fixatedStim_ss == stim.identifier(:)', 2);
                li_onDis_easy      = any(fixatedStim_ss(li_onDis) == stim.identifier(:, 1)', 2);
                li_onDis_diff      = any(fixatedStim_ss(li_onDis) == stim.identifier(:, 2)', 2);
                li_onDis_chosen    = any(fixatedStim_ss(li_onDis) == stim.identifier(:, id_chosenTarget_ss(li_onDis))', 2);
                li_onDis_nonChosen = any(fixatedStim_ss(li_onDis) == stim.identifier(:, id_nonChosenTarget_ss(li_onDis))', 2);
                noValidGs          = sum(~isnan(id_chosenTarget_ss(li_onDis)));

                sacc.propGs.onAOI_modelComparision_chosenNot_ss(s, ss, c) = sum(li_onDis_chosen) / noValidGs;
                sacc.propGs.onAOI_modelComparision_easyDiff_ss(s, ss, c)  = sum(li_onDis_easy) / noValidGs;
                clear li_ss fixatedStim_ss id_chosenTarget_ss id_nonChosenTarget_ss li_onDis li_onDis_easy li_onDis_diff li_onDis_chosen li_onDis_nonChosen noValidGs

            end
            clear fixatedStim id_chosenTarget id_nonChosenTarget setSizes ss

        end
        clear thisSubject gs_sub

    end
    clear s

end
clear c


%% Latencies of first movement in trial
sacc.latency.firstGs = NaN(exper.num.subNo, 3, exper.num.condNo);
for c = 1:exper.num.condNo % Condition
    for s = 1:exper.num.subNo % Subject
        thisSubject = exper.num.subs(s);
        subDat = sacc.gazeShifts{thisSubject,c};
        if ~isempty(subDat)
            % Unpack data
            latencies = subDat(:,11);
            saccNo = subDat(:,24);
            chosenTarget = subDat(:,23);
            nDisEasy = subDat(:,22);
            nDisDifficult = subDat(:,28);
            setSizes = unique(nDisEasy);
            setSizes = setSizes(~isnan(setSizes));
            nSs = numel(setSizes);

            % Find trials
            idxFirstSacc = saccNo == 1; % First saccades in trial
            idxChosenEasy = chosenTarget == stim.identifier(1,1); % Easy chosen
            idxChosenDifficult = chosenTarget == stim.identifier(1,2); % Difficult chosen

            temp = NaN(3, nSs);
            for ss = 1:numel(setSizes) % Set size
                % Single-target
                % - Select trials where either target was shown with a
                %   given number of distractor and where the easy or
                %   difficult target was shown with a given number of
                %   same-colored distractors
                % Double-target
                % - Use the number of easy distractors in a trial as
                %   reference, and find trials where a given number of easy
                %   distractors was shown and participants chose either,
                %   the easy, or the difficult target
                % - We take the number of easy distractors as reference,
                %   because nEasy == 1-nEasy or nDifficult = fliplr(nEasy)
                if c == 1 % Single-target
                    idxAnySet = any([nDisEasy, nDisDifficult] == setSizes(ss), 2);
                    idxEasySet = nDisEasy == setSizes(ss);
                    idxDifficultSet = nDisDifficult == setSizes(ss);
                elseif c == 2 % Double-target
                    idxAnySet = nDisEasy == setSizes(ss);
                    idxEasySet = idxAnySet;
                    idxDifficultSet = idxAnySet;
                end
                idxBoth = idxFirstSacc & idxAnySet;
                idxEasy = idxFirstSacc & idxEasySet & idxChosenEasy;
                idxDifficult = idxFirstSacc & idxDifficultSet & idxChosenDifficult;

                temp(:,ss) = ...
                    [median(latencies(idxBoth), 'omitnan'), ...
                     median(latencies(idxEasy), 'omitnan'), ...
                     median(latencies(idxDifficult), 'omitnan')];
                clear idxAnySet idxEasySet idxDifficultSet idxBoth idxEasy idxDifficult
            end
            clear latencies saccNo chosenTarget nDisEasy nDisDifficult
            clear setSizes nSs idxFirstSacc idxChosenEasy idxChosenDifficult ss

            sacc.latency.firstGs(s,:,c) = mean(temp, 2, 'omitnan');
            clear temp
        end
        clear thisSubject subDat
    end
    clear s
end
clear c

%% Export data for model
% Model scripts are build around getting data from exported .txt files and
% fitting the model to the imported data. To make things easier, I will
% keep this workflow, instead of "properly" implementing the model scripts
% into my framework
container_dat_mod   = NaN(exper.num.subNo, 100, 2);
container_dat_label = infSampling_colNames;
dat_filenames       = {[exper.name.export{exper.num.conds(1)-1, 1}, '.txt'],  [exper.name.export{exper.num.conds(1)-1, 2}, '.txt']; ...
                       [exper.name.export{exper.num.conds(1)-1, 1}, '.xlsx'], [exper.name.export{exper.num.conds(1)-1, 2}, '.xlsx']};
for c = 1:exper.num.condNo % Condition

    % Gather data to export
    container_dat = [exper.num.subs ...                                         1:     Subject numbers
                     reshape(perf.hitrates(:, c, :), exper.num.subNo, 3, 1) ...        Proportion correct (overall, easy, difficult)
                     NaN(exper.num.subNo, 60) ...                               5:64:  Placeholder for legacy columns
                     sacc.time.mean.inspection(:, c, 1) ...                     65:    Overall mean inspection time per item
                     sacc.time.mean.non_search(:, c, 1) ...                            Overall mean non-search time
                     sacc.time.mean.planning(:, c, 1) ...                              Overall mean planning time
                     sacc.time.mean.decision(:, c, 1) ...                              Overall mean decision time
                     sacc.time.mean.inspection(:, c, 2) ...                            Mean search time easy target chosen
                     sacc.time.mean.non_search(:, c, 2) ...                     70:    Mean non-search time easy target chosen
                     sacc.time.mean.decision(:, c, 2) ...                              Mean decision time easy target chosen
                     sacc.time.mean.planning(:, c, 2) ...                              Mean planning time easy target chosen
                     sacc.time.mean.inspection(:, c, 3) ...                            Mean inspection time per item difficult target chosen
                     sacc.time.mean.non_search(:, c, 3) ...                            Mean non-search time difficult target chosen
                     sacc.time.mean.decision(:, c, 3) ...                       75:    Mean response time difficult target chosen
                     sacc.time.mean.planning(:, c, 3) ...                              Mean fixation time difficult target chosen
                     NaN(exper.num.subNo, 2) ...                                77:78: Placeholder for legacy columns
                     stim.propChoice.easy(:, :, c)' ...                         79:87: Proportion choices easy target as a function of set-size
                     1-stim.propChoice.easy(:, :, c)' ...                       88:96: Proportion choices difficult target as a function of set-size
                     exper.trialNo(:, c) ...                                           # solved trials
                     exper.timeLostExcldTrials(:, c) ...                               time lost due to excluded trials
                     exper.noExcludedTrial(:, c) ...                                   # excluded trials
                     perf.score.final(:, c)];                                 % 100: accumulated reward
    container_dat_mod(:, :, c) = container_dat;

    % Export data
    if exper.flag.export == 1

        % Define paths
        savePath_txt = strcat(exper.name.analysis, '/_model/', dat_filenames{1, c});
        savePath_xls = strcat(exper.name.analysis, '/_model/', dat_filenames{2, c});

        % Delete old files to prevent weird bug that might occur due to
        % overwriting existing files
        delete(savePath_txt, savePath_xls);

        % Save data as .txt and .xls
        writematrix(container_dat, savePath_txt);
        container_dat_xls = num2cell(container_dat);
        container_dat_xls(isnan(container_dat)) = {'NaN'};
        dat_table = array2table(container_dat_xls, ...
                                'VariableNames', container_dat_label');
        writetable(dat_table, savePath_xls)
        clear savePath_txt savePath_xls

    end
    clear container_dat container_dat_xls dat_table

end
clear c container_dat_label dat_filenames


%% Fit model with perfect fixation distribution
cd(strcat(exper.name.analysis, '/_model'))
model_io = [];
model_io.containerDat = container_dat_mod; % Get data from .xls files
model_io = get_params(model_io);
model_io = read_data(model_io);
model_io = fit_model(model_io); % Fit model and plot results
clear container_dat_mod


%% Fit probabilistic model
cd('/Users/ilja/Dropbox/12_work/mr_informationSamplingVisualManual/3_analysis/_model/_recursiveModel_standalone');

% Generate lookup tablet
% infSampling_generateLUT([(1:9)' (9:-1:1)'], [0 2], 4, 1)

% Run model
if exper.num.conds(1) == 2
    if exper.flag.runModel.eye
        load('modelResults_eye_propChoices_fixChosen.mat');
    else
        model = infSampling_model_main(stim, sacc, model_io, perf, exper, plt);
    end
elseif exper.num.conds(1) == 4
    if exper.flag.runModel.tablet
        load('modelResults_tablet_propChoices_fixChosen.mat');
    else
        model = infSampling_model_main(stim, sacc, model_io, perf, exper, plt);
    end
end


%% Write data to drive
if exper.num.conds(1) == 2
    filename = 'dataEye';
elseif exper.num.conds(1) == 4
    filename = 'dataTablet';
end
save([exper.name.data, '/', filename], ...
     'exper', 'model', 'model_io', 'perf', 'plt', 'sacc', 'screen', 'stim');
clear filename


%% Statistics for paper 
% Figure 4
% Intercepts and slopes of regression fit
clc; matlab_oneSampleTtest(model_io.reg.fit(:, 1), 2); % Intercepts
clc; matlab_oneSampleTtest(model_io.reg.fit(:, 2), 2); % Slopes

% Figure 5
% Proportion gaze shifts on different stimuli over the course of trials
inp_minSub = exper.avg.minSub;
inp_dat    = [sacc.propGs.onChosen_trialBegin(:, 2) ...
              sacc.propGs.onEasy_trialBegin(:, 2) ...
              sacc.propGs.onSmaller_trialBegin(:, 2) ...
              sacc.propGs.onCloser_trialBegin(:, 2)];
% single_subjects = infSampling_avgPropSacc(inp_dat, inp_minSub);
single_subjects = squeeze(mean(infSampling_avgPropSacc(inp_dat, inp_minSub), 3, 'omitnan'));
clear inp_minSub

clc; matlab_pairedTtest(single_subjects(:, 1, 1), single_subjects(:, 2, 1), 2) % 5A: Proportions to chosen/not-chosen sets for first two gaze shifts
clc; matlab_pairedTtest(single_subjects(:, 1, 2), single_subjects(:, 2, 2), 2) % 5B: Proportions to easy/difficult sets for first two gaze shifts
clc; matlab_pairedTtest(single_subjects(:, 1, 3), single_subjects(:, 2, 3), 2) % 5C: Proportion to smaller/larger sets for first two gaze shifts
clc; matlab_pairedTtest(single_subjects(:, 1, 4), single_subjects(:, 2, 4), 2) % 5D: Proportions to closet/more distant sets for first two gaze shifts
clear single_subjects

% Figure 6
% Model results
clc; matlab_pairedTtest(model_io.data.double.perf, model_io.model.perf_perfect(:, 3), 2)              % 6A: Empirical vs. maximum gain
[r, p, rl, ru] = corrcoef(model_io.data.double.perf, ...
                          model_io.model.perf_perfect(:, 3), 'Rows', 'complete');
clc; disp(round([r(1, 2), rl(1, 2), ru(1, 2), p(1, 2)], 2));
clc; matlab_pairedTtest(model.freeParameter{2}(:, 1), model.freeParameter{2}(:, 2), 2)                % 6B: Free parameters distributions
clc; matlab_pairedTtest(model_io.data.double.perf, model.performance(:, 2), 2)                        % 6C: Empirical vs. stochastic model gain
[r, p, rl, ru] = corrcoef(model_io.data.double.perf, model.performance(:, 2), 'Rows', 'complete');
clc; disp(round([r(1, 2), rl(1, 2), ru(1, 2), p(1, 2)], 2));
clc; matlab_pairedTtest(mean(sacc.propGs.onAOI_modelComparision_chosenNot_ss(:, :, 2), 2), ...       6E: Empirical vs. predicted proportion gaze shifts on chosen set
                        mean(model.propFixChosen(:, :, 2), 2), 2)
[r, p, rl, ru] = corrcoef(mean(sacc.propGs.onAOI_modelComparision_chosenNot_ss(:, :, 2), 2), ...
                          mean(model.propFixChosen(:, :, 2), 2), 'Rows', 'complete');
clc; disp(round([r(1, 2), rl(1, 2), ru(1, 2), p(1, 2)], 2));

% % Figure S4
% % Latencies of first gaze shifts to different stimuli
% clc; matlab_pairedTtest(sacc.lat.firstGs_chosenSet(:, 1, 2),   sacc.lat.firstGs_chosenSet(:, 2, 2))   % S4A: Latencies to chosen/not-chosen set
% clc; matlab_pairedTtest(sacc.lat.firstGs_easySet(:, 1, 2),     sacc.lat.firstGs_easySet(:, 2, 2))     % S4A: Latencies to easy/difficult set
% clc; matlab_pairedTtest(sacc.lat.firstGs_smallerSet(:, 1, 2),  sacc.lat.firstGs_smallerSet(:, 2, 2))  % S4A: Latencies to smaller/larger set
% clc; matlab_pairedTtest(sacc.lat.firstGs_closestStim(:, 1, 2), sacc.lat.firstGs_closestStim(:, 2, 2)) % S4A: Latencies to closest/more distant stimulus


%% Create plots for paper
% Figure 6
% Results of model fitting
inp_emp_propChoicesEasy = stim.propChoice.easy(:, :, 2)';
inp_emp_propGsChosen    = sacc.propGs.onAOI_modelComparision_chosenNot_ss(:, :, 2);
inp_emp_perf            = model_io.data.double.perf;

infSampling_plt_fig6(inp_emp_propChoicesEasy, inp_emp_propGsChosen, inp_emp_perf, ...
                     model, model_io.model, plt)

% Supplementary figure 1
% Proportion gaze shifts on different AOIs, search time as a function of
% distractor number, perceptual performance and temporal aspects of search
% behavior (planning-, search- and decision-time) in single-target
% condition
inp_dat_perf = cat(3, ...
                   [perf.hitrates(:, 2, 2)             perf.hitrates(:, 2, 3)], ...
                   [sacc.time.mean.planning(:, 2, 2)   sacc.time.mean.planning(:, 2, 3)], ...
                   [sacc.time.mean.inspection(:, 2, 2) sacc.time.mean.inspection(:, 2, 3)], ...
                   [sacc.time.mean.decision(:, 2, 2)   sacc.time.mean.decision(:, 2, 3)]);
inp_dat_reg  = [(0:8)' sacc.time.search_ss(:, :, 2)'];
inp_dat_gs   = [(1:3)' squeeze(mean(sacc.propGs.onAOI_ss(:, :, :, 2), 2, 'omitnan'))'];
inp_pltName  = strcat(plt.name.aggr(1:end-14), 'figureSupp1');

infSampling_plt_fig3(inp_dat_reg, NaN, NaN, inp_dat_gs, inp_dat_perf, inp_pltName, plt)
clear inp_dat_var inp_dat_reg inp_dat_reg_long inp_mod_reg inp_dat_gs inp_pltName

% Supplementary figure 2
% Proportion choices easy target of individual subjects in double-target condition
prop_choices_easy      = stim.propChoice.easy(:, :, 2);
prop_choices_easy_fit  = cat(3, model_io.reg.xn-1, model_io.reg.yn);
prop_choices_easy_pred = model.propChoicesEasy(:, :, 2)';

infSampling_plt_figSupp2(prop_choices_easy, prop_choices_easy_fit, prop_choices_easy_pred, plt)
clear prop_choices_easy prop_choices_easy_fit prop_choices_easy_pred

% Supplementary figure 3
% Predicted proportions gaze shifts on chosen set
propFix_pred = model.propFixChosen(:, :, 2);
propFix_emp  = sacc.propGs.onAOI_modelComparision_chosenNot_ss(:, :, 2);

infSampling_plt_figSupp3(propFix_pred, propFix_emp, plt)
clear propFix_pred propFix_emp

% % Supplementary figure X
% % Latencies of first gaze shifts to different stimuli
% inp_dat = cat(3, ...
%               sacc.lat.firstGs_chosenSet(:, :, 2), ...
%               sacc.lat.firstGs_easySet(:, :, 2), ...
%               sacc.lat.firstGs_smallerSet(:, :, 2), ...
%               sacc.lat.firstGs_closestStim(:, :, 2));
% 
% infSampling_plt_figSuppThree(inp_dat, plt)
% clear inp_dat