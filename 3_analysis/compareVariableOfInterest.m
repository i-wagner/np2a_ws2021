function compareVariableOfInterest(newPipeline, variableOfInterest, suffix)

    % Compares content of a variable, generated using the new analysis 
    % pipeline, to it's counterpart, generated using the old pipeline
    %
    % Input
    % newPipeline:
    % varying type; data from new pipeleine, which to compare to the same
    % data from the old pipeline
    %
    % variableOfInterest:
    % string; dependent variable of interest:
    % "proportionValid"
    % "proportionTrialsWithResponse"
    %
    % suffix:
    % string; use results of old pipeline where only trials
    % ("_withExclusion") or where trials and subjects where excluded 
    % ("_allExclusions"). Use "" for no exclusions
    %
    % Output
    % --

    %% Get variable of interest from old pipeline
    conditionLabels = ["oldGs_visual", "oldGs_manual"];
    oldPipeline = [];
    for c = 1:2 % Condition
        pathToData = strcat("/Users/ilja/Dropbox/12_work/", ...
                            "mr_informationSamplingVisualManual/2_data/", ...
                            conditionLabels{c}, suffix, ".mat");
        thisData = load(pathToData);
        if strcmp(variableOfInterest, "proportionValid")
            thisVariable = thisData.exper.prop.val_trials;
        elseif strcmp(variableOfInterest, "proportionTrialsWithResponse")
            thisVariable = thisData.exper.prop.resp_trials;
        elseif strcmp(variableOfInterest, "timeLostExcldTrials")
            thisVariable = thisData.exper.timeLostExcldTrials;
        end
        oldPipeline = [oldPipeline, thisVariable];
    end
    
    %% Compare pipelines
    pipelineResultyMatch = isequaln(newPipeline, oldPipeline);
    if ~pipelineResultyMatch
        warning("Results from old and new pipeleine do not match!");
        keyboard
    end

end