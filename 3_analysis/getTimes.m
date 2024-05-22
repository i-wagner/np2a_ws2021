function time = getTimes(exper, anal, nTrials, gaze, fixations, excludedTrials)

    % Wrapper function
    % Extracts trialwise planning, dwell, inspection, response, and
    % non-search time for each subject in conditions
    %
    % NOTE 1:
    % This wrapper function uses the SUBSET of fixation, as determined in
    % the "getFixatedAois" function, to calculate all output variables
    %
    % NOTE 2:
    % Dwell times are saved in a vector with it's length corresponding to
    % the overall number of fixations that were made in the trial (i.e.,
    % not only the subset). This is done to later simplify indexing into
    % the dwell-time array (i.e., we don't need a specific trial map to do
    % this). We chose this approach instead of calculating the dwell time
    % for all fixations that were made, because dwell-times are calculated
    % using the leaving times of AOIs. Leaving times, however, differ,
    % depending on whether all or only a subset of fixations is used to
    % calculate them (since leaving times are calculated based on the
    % specific sequence of inspected AOIs, which naturally diffres
    % depending on which fixations are used to calculate them)
    %
    % NOTE 3:
    % non-search time is defined as the trialwise sum of the respective
    % response and planning time. It is used to quantify the overall time
    % in a trial that participants did not spend searching for a target
    % (i.e., fixating stimuli)
    %
    % Input
    % exper:
    % structure; general experiment settings, as returned by the
    % "settings_exper" script
    %
    % anal:
    % structure; various analysis settings, as returned by the
    % "settings_analysis" script
    %
    % nTrials:
    % matrix; number of completed trials per participant and condition
    %
    % gaze:
    % structure; gaze data of participants in conditions
    %
    % fixations:
    % structure; fixated AOIs across participants and conditions
    %
    % Output
    % time:
    % structure; time-variables across participants and conditions

    %% Analyse fixations
    time.inspection.trialwise = cell(exper.n.SUBJECTS, exper.n.CONDITIONS);
    time.dwell.trialwise = cell(exper.n.SUBJECTS, exper.n.CONDITIONS);
    time.planning.trialwise = cell(exper.n.SUBJECTS, exper.n.CONDITIONS);
    time.response.trialwise = cell(exper.n.SUBJECTS, exper.n.CONDITIONS);
    time.nonSearch.trialwise = cell(exper.n.SUBJECTS, exper.n.CONDITIONS);
    for c = 1:exper.n.CONDITIONS % Condition
        for s = 1:exper.n.SUBJECTS % Subject
            thisSubject.number = exper.num.SUBJECTS(s);
            if ismember(thisSubject.number, anal.excludedSubjects)
                continue
            end

            thisSubject.nTrials = nTrials(thisSubject.number,c);
            thisSubject.excludedTrials = excludedTrials{thisSubject.number,c};
            thisSubject.nGazeShifts = numel(gaze.gazeShifts.trialMap{thisSubject.number,c});
            if isnan(thisSubject.nTrials)
                continue
            end

            thisSubject.inspectionTime = NaN(thisSubject.nTrials, 1);
            thisSubject.dwellTimes = NaN(thisSubject.nGazeShifts,1);
            thisSubject.planningTime = NaN(thisSubject.nTrials, 1);
            thisSubject.responseTime = NaN(thisSubject.nTrials, 1);
            thisSubject.nonSearchTime = NaN(thisSubject.nTrials, 1);
            thisSubject.gazeShiftCounter = 0;
            for t = 1:thisSubject.nTrials % Trial
                % Check whether to skip excluded trial
                if ismember(t, thisSubject.excludedTrials)
                    continue
                end

                % Unpack trial data
                thisTrial.idx = ...
                    gaze.gazeShifts.trialMap{thisSubject.number,c} == t;
                thisTrial.gazeShifts.idx = ...
                    gaze.gazeShifts.idx{thisSubject.number,c}(thisTrial.idx,:);
                thisTrial.gazeShifts.onsets = ...
                    gaze.gazeShifts.onsets{thisSubject.number,c}(thisTrial.idx,:);
                thisTrial.gazeShifts.offsets = ...
                    gaze.gazeShifts.offsets{thisSubject.number,c}(thisTrial.idx,:);
                thisTrial.timestamp.stimOn = ...
                    gaze.timestamps.stimOn{thisSubject.number,c}(t,:);
                thisTrial.timestamp.stimOff = ...
                    gaze.timestamps.stimOff{thisSubject.number,c}(t,:);
                thisTrial.fixations.subset = ...
                    logical(fixations.subset{thisSubject.number,c}(thisTrial.idx,:));
                thisTrial.fixations.groupIds = ...
                    fixations.fixatedAois.groupIds{thisSubject.number,c}(thisTrial.idx,:);
                thisTrial.fixations.uniqueIds = ...
                    fixations.fixatedAois.uniqueIds{thisSubject.number,c}(thisTrial.idx,:);
                thisTrial.gazeShifts.informationLoss = ...
                    fixations.informationLoss{thisSubject.number,c}(thisTrial.idx,:);
                thisTrial.nGazeShifts = size(thisTrial.gazeShifts.idx, 1);

                % Get leaving times of AOIs
                thisTrial.leavingTimes = ...
                    getLeavingTimes(logical(thisTrial.gazeShifts.idx(thisTrial.fixations.subset,3)), ...
                                    thisTrial.gazeShifts.offsets(thisTrial.fixations.subset,1), ...
                                    thisTrial.gazeShifts.onsets(thisTrial.fixations.subset,1), ...
                                    thisTrial.timestamp.stimOff);

                % Get inspection and dwell times
                [thisTrial.inspectionTime, temp] = ...
                    getInspectionTime(thisTrial.fixations.groupIds(thisTrial.fixations.subset), ...
                                      [exper.stimulus.id.target.EASY, exper.stimulus.id.target.DIFFICULT], ...
                                      exper.stimulus.id.BACKGROUND, ...
                                      thisTrial.gazeShifts.offsets(thisTrial.fixations.subset,1), ...
                                      thisTrial.gazeShifts.informationLoss(thisTrial.fixations.subset), ...
                                      thisTrial.leavingTimes, ...
                                      anal.dwellTimes.useTargets(c));
                thisTrial.dwellTimes = NaN(size(thisTrial.fixations.groupIds));
                thisTrial.dwellTimes(thisTrial.fixations.subset) = temp;

                % Get planning time
                thisTrial.planningTime = ...
                    getPlanningTime(thisTrial.gazeShifts.offsets(thisTrial.fixations.subset,1), ...
                                    thisTrial.timestamp.stimOn);
                
                % Get response time
                thisTrial.responseTime = ...
                    getResponseTime(thisTrial.fixations.uniqueIds(thisTrial.fixations.subset), ...
                                    thisTrial.gazeShifts.offsets(thisTrial.fixations.subset,1), ...
                                    thisTrial.timestamp.stimOff, ...
                                    [exper.stimulus.id.target.EASY, exper.stimulus.id.target.DIFFICULT], ...
                                    exper.stimulus.id.BACKGROUND);

                % Get non-search time
                thisTrial.nonSearchTime = ...
                    thisTrial.planningTime + thisTrial.responseTime;

                % Store data
                thisTrial.storeIdx = ...
                    (thisSubject.gazeShiftCounter + 1):(thisSubject.gazeShiftCounter + thisTrial.nGazeShifts);
                thisSubject.gazeShiftCounter = ...
                    thisSubject.gazeShiftCounter + thisTrial.nGazeShifts;

                thisSubject.inspectionTime(t) = thisTrial.inspectionTime;
                thisSubject.dwellTimes(thisTrial.storeIdx) = thisTrial.dwellTimes;
                thisSubject.planningTime(t) = thisTrial.planningTime;
                thisSubject.responseTime(t) = thisTrial.responseTime;
                thisSubject.nonSearchTime(t) = thisTrial.nonSearchTime;
                clear thisTrial
            end

            % Store data
            time.inspection.trialwise{thisSubject.number,c} = thisSubject.inspectionTime;
            time.dwell.trialwise{thisSubject.number,c} = thisSubject.dwellTimes;
            time.planning.trialwise{thisSubject.number,c} = thisSubject.planningTime;
            time.response.trialwise{thisSubject.number,c} = thisSubject.responseTime;
            time.nonSearch.trialwise{thisSubject.number,c} = thisSubject.nonSearchTime;
            clear thisSubject
        end
    end
end
