function choice = getChoices(exper, logCol, logFiles, gaze, fixations)

    % Wrapper function
    % Extracts target choices
    %
    % The following analysis steps are performed:
    % - Extract chosen target in trial, using the keypress a participant
    %   provided
    % - Check response congruency, i.e., whether the provided key
    %   corresponds to the last stimulus, a participant fixated
    % - Extract number of distractors in the set of the chosen target
    %
    % Input
    % exper:
    % structure; general experiment settings, as returned by the
    % "settings_exper" script
    % 
    % logCol:
    % structure; column indices for log files, as returned by the
    % "settings_log" script
    % 
    % logFiles:
    % structure; log files across participants and conditions, as returned
    % by the "getLogFiles" function
    %
    % gaze:
    % structure; gaze data of participants in conditions, as returned by
    % the "getGazeData" function
    % 
    % fixations:
    % structure; fixated AOIs across participants and conditions, as
    % returned by the "getFixatedAois" function
    %
    % Output
    % choice:
    % structure; choice-related data of participants

    %% Get choices
    targetIds = [exper.stimulus.id.target.EASY, ...
                 exper.stimulus.id.target.DIFFICULT];

    choice.target = cell(exper.n.SUBJECTS, exper.n.CONDITIONS);
    choice.congruency = cell(exper.n.SUBJECTS, exper.n.CONDITIONS);
    choice.nDistractorsChosenSet = cell(exper.n.SUBJECTS, exper.n.CONDITIONS);
    for c = 1:exper.n.CONDITIONS % Condition
        for s = 1:exper.n.SUBJECTS % Subject
            thisSubject.number = exper.num.SUBJECTS(s);
            thisSubject.nTrials = logFiles.nCompletedTrials(thisSubject.number,c);
            thisSubject.logFile = logFiles.files{thisSubject.number,c};
            if isnan(thisSubject.nTrials)
                continue
            end

            thisSubject.chosenTarget = NaN(thisSubject.nTrials, 1);
            thisSubject.responseCongruency = NaN(thisSubject.nTrials, 1);
            thisSubject.nDistractorsChosenSet = NaN(thisSubject.nTrials, 1);
            for t = 1:thisSubject.nTrials % Trial
                % Unpack trial data
                thisTrial.idx = ...
                    gaze.gazeShifts.trialMap{thisSubject.number,c} == t;
                thisTrial.gazeShifts.idx = ...
                    gaze.gazeShifts.idx{thisSubject.number,c}(thisTrial.idx,:);
                thisTrial.fixations.subset = ...
                    logical(fixations.subset{thisSubject.number,c}(thisTrial.idx,:));
                thisTrial.fixations.uniqueIds = ...
                    fixations.fixatedAois.uniqueIds{thisSubject.number,c}(thisTrial.idx,:);
                thisTrial.gapPositions = [thisSubject.logFile(t,logCol.GAP_POSITION_EASY), ...
                                          thisSubject.logFile(t,logCol.GAP_POSITION_DIFFICULT)];
                thisTrial.nDistractors = [thisSubject.logFile(t,logCol.N_DISTRACTOR_EASY), ...
                                          thisSubject.logFile(t,logCol.N_DISTRACTOR_DIFFICULT)];
                thisTrial.gapReported = thisSubject.logFile(t,logCol.GAP_POSITION_REPORTED);

                % Get chosen target in trial
                thisTrial.responseCongruency = NaN;
                [thisTrial.chosenTarget.response, thisTrial.chosenTarget.fixation] = ...
                    getChosenTarget(thisTrial.gapPositions, ...
                                    thisTrial.gapReported, ...
                                    thisTrial.fixations.uniqueIds(thisTrial.fixations.subset), ...
                                    targetIds, ...
                                    exper.stimulus.id.BACKGROUND);
                if ~isnan(thisTrial.chosenTarget.fixation)
                    thisTrial.responseCongruency = ...
                        thisTrial.chosenTarget.response == thisTrial.chosenTarget.fixation;
                end
                
                % Get number of distractors in set of chosen target
                thisTrial.nDistractorsChosenSet = ...
                    getDistractorsChosenSet(thisTrial.nDistractors, ...
                                            thisTrial.chosenTarget.response, ...
                                            targetIds);

                % Store data
                thisSubject.chosenTarget(t) = thisTrial.chosenTarget.response;
                thisSubject.responseCongruency(t) = thisTrial.responseCongruency;
                thisSubject.nDistractorsChosenSet(t) = thisTrial.nDistractorsChosenSet;
                clear thisTrial
            end

            % Store data
            choice.target{thisSubject.number,c} = thisSubject.chosenTarget;
            choice.congruency{thisSubject.number,c} = thisSubject.responseCongruency;
            choice.nDistractorsChosenSet{thisSubject.number,c} = thisSubject.nDistractorsChosenSet;
            clear thisSubject
        end
    end
end