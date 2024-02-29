% This function creates contrasts and saves them to the SPM.mat of each
% subject

% Inputs %

% contrasts: cell array of the contrasts to create. The structure of each
% contrast should be:
%   <plusRegressor1>:S1+<plusRegressor2>+<plusRegressor3>-<minusRegressor1>:S2
%   +<minusRegressor2>+<minusRegressor3>
% Note: you should add ":S#session" if the regressor should be
% entered to the contrast only from specific sesisons. Otherwise, if session
% number is't mentioned, the resgressor will be entered from all sessions.
% Note: if you want to contrast a condition against baseiline, write
% "-None" as the negative side of your contrast
% Note: the name of the regressors in the contrast should be exactly the
% same as the names you defined in your protocol files
% Note: for parameteric modulation the structure of the regressors name
% should be as follows: names{i}xpmod.name{i}^1 for linear,
% names{i}xpmod.name{i}^2 for quadratic etc. Where names and pmod are
% structures that are defined in your protocol files. For example:
% allLoadsxload^1-None, where names{i} = allLoads, pmod.name{i} = load.

% contrastsNames: cell array of the desired names for each contrast
% projectConfigurationFile: path to configuration file of the project (look
% at Elbit\elbitBatConfiguration for a template)

% For createContrasts
% contrasts={'Gohappyneutral-NoGohappyneutral', 'Goangryneutral-NoGoangryneutral', 'Gohappyangry-NoGohappyangry'...
%            'Goangryhappy-NoGoangryhappy', 'Goneutralhappy-NoGoneutralhappy', 'Goneutralangry-NoGoneutralangry'...
%            'Gohappyneutral+Goangryneutral+Gohappyangry+Goangryhappy+Goneutralhappy+Goneutralangry-NoGohappyneutral+NoGoangryneutral+NoGohappyangry+NoGoangryhappy+NoGoneutralhappy+NoGoneutralangry'}
% 
% contrastsNames={'HappyGo_NeutralNoGo', 'AngryGo_NeutralNoGo', 'HappyGo_AngryNoGo', 'AngryGo_HappyNoGo', 'NeutralGo_HappyNoGo', 'NeutralGo_AngryNoGo', 'AllGo_AllNoGo'}
% 
% projectConfigurationFile='Z:\Lab_Projects\PTSD_Subtyping_fMRI_MEG\Initial_Analysis_Jan24\scripts\GoNoGo_Configuration.m'
% 
% isParametric=false

% names = {'Gohappyneutral' 'NoGohappyneutral' 'Goangryneutral' 'NoGoangryneutral' 'Gohappyangry' 'NoGohappyangry',...
% 'Goangryhappy' 'NoGoangryhappy' 'Goneutralhappy' 'NoGoneutralhappy' 'Goneutralangry' 'NoGoneutralangry'}


% For createContrasts
% contrasts={'positive-', 'trauma-', 'neutral-', 'positive-neutral', 'trauma-neutral', 'trauma-positive'}
% 
% contrastsNames={'Positive', 'Trauma', 'Neutral', 'PositiveVsNeutral', 'TraumaVsNeutral', 'TraumaVsPositive'}
% 
% projectConfigurationFile='Z:\Lab_Projects\PTSD_Subtyping_fMRI_MEG\Initial_Analysis_Jan24\scripts\VisualReminders_Configuration.m'
% 
% isParametric=false
% 
% names = {'positive' 'trauma' 'neutral'}


function createContrasts(contrasts, contrastsNames, projectConfigurationFile, isParametric)
spm('defaults','fmri');
spm_jobman('initcfg');
firstIndexOfFolder = 3;
run(projectConfigurationFile);
estimatedModelFile = 'SPM.mat';
firstLevelDir = config.firstLevelDir;

firstLevelData = dir(firstLevelDir);
subsDir = firstLevelData(vertcat(firstLevelData.isdir));
subsDir = subsDir(firstIndexOfFolder:end);
%% Loop for all subjects
 for subjectNum = 1:length(subsDir)
    subNum = str2num(extractAfter(subsDir(subjectNum).name,'sub-'));
    if ~isempty(config.subjectsToAnalyse) && ~ismember(subNum, config.subjectsToAnalyse)
        continue
    end
    if ismember(subNum,config.subjectsToExclude)
        continue
    end
    %% Specifying and creating individual SPM folder
    outDir =  [firstLevelDir, filesep, subsDir(subjectNum).name, filesep];
    matlabbatch{1}.spm.stats.con.dir = {outDir};
    %Results
    matlabbatch{1}.spm.stats.con.spmmat{1} = [outDir, estimatedModelFile];
    load (matlabbatch{1}.spm.stats.con.spmmat{1})

    [allRegressors amountOfRegPerSess] = getAllRegresors(SPM, config, isParametric);
    
    for conNum = 1:length(contrasts)
        contrast = contrasts{conNum};
        weights = getWeightsVectorForContrast(contrast, allRegressors, amountOfRegPerSess);
        matlabbatch{1}.spm.stats.con.consess{conNum}.tcon.name = contrastsNames{conNum};
        matlabbatch{1}.spm.stats.con.consess{conNum}.tcon.weights = weights;
        matlabbatch{1}.spm.stats.con.consess{conNum}.tcon.sessrep = 'none';
        matlabbatch{1}.spm.stats.con.delete = 0;
    end
    %% RUN the batch
    spm_jobman('run',matlabbatch);
 end
 copyContrasts(contrastsNames, projectConfigurationFile);
end

function [allRegressors, amountOfRegPerSess] = getAllRegresors(SPM, config, isParametric)
    allRegressors = {};
    noiseRegressors = config.noiseRegressors;

    amountOfRegPerSess = [];
    for session = 1:length(SPM.Sess)
        noiseRegressors = {};
        
        conditionsRegressors = {};
        % Extract the names of the conditions' regressors
        
            nameIndex = 1;
            for cond = 1:length(SPM.Sess(session).U)
                names = SPM.Sess(session).U(cond).name;
                if isParametric
                    for name = 1:length(names)
                        conditionsRegressors{nameIndex} = names{name};
                        nameIndex = nameIndex + 1;
                    end
                else
                    conditionsRegressors{cond} = names{1};
                end
            end
        
        conditionRegressorsAmount = length(conditionsRegressors);
        allRegressorsAmount = length(SPM.Sess(session).col);
        noiseRegressorsAmount = allRegressorsAmount - conditionRegressorsAmount;
        noiseRegressors(1:noiseRegressorsAmount) = {'noiseRegressor'};
        amountOfRegPerSess(session) = allRegressorsAmount;
        allRegressors = [allRegressors, conditionsRegressors, noiseRegressors];
        
    end
    runAverageReg(1:length(SPM.Sess))={'runConstant'};
    allRegressors = [allRegressors, runAverageReg];
end
