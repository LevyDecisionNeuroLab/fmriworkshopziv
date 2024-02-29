
% This function runs the first level analysis for all subjects

% Inputs %

% projectConfigFile: path to the project's configuration file
%   
% runParallel: True if you wish the code to run in a parallel manner
% (recommended if running on a computer with multiple cores)
% 
% projectConfigFile='Z:\Lab_Projects\PTSD_Subtyping_fMRI_MEG\Initial_Analysis_Jan24\scripts\GoNoGo_Configuration.m'; runParallel=false;
% projectConfigFile='Z:\Lab_Projects\PTSD_Subtyping_fMRI_MEG\Initial_Analysis_Jan24\scripts\VisualReminders_Configuration.m'; runParallel=false;
% firstLevelAnalysis(projectConfigFile, runParallel)
% For T1 analysis, Change back to ses-1 at lines 92 & 94


function firstLevelAnalysis(projectConfigFile, runParallel)
addpath ('utils');
spm('defaults','fmri');
spm_jobman('initcfg');

% Extract config definitions
run(projectConfigFile);
dataDir = config.dataDir;
firstLevelDir = config.firstLevelDir;
secondLevelDir = config.secondLevelDir;
protocolFolder = config.protocolFolder;
fileTemplate = config.smoothFunctionalFileTemplate;
firstRelevantscan= config.numOfInitialTRsToRemove + 1;

% Define constants
firstFolderIndex = 3;
fileType = '*.nii';

% Extract subjects list
subjectsDir=dir(dataDir);
subjects=subjectsDir(firstFolderIndex:length(subjectsDir));
subjects=subjects([subjects.isdir]);
subjectsList = extractfield(subjects,'name');

% Create folders to contain the results
if ~exist (firstLevelDir)
    mkdir (firstLevelDir);
end
if ~exist (secondLevelDir)
    mkdir (secondLevelDir);
end


batches={}; % we save the batch created for each subject so we can
% execute these batches in a parallel manner later

statTitlesForMeasure = {}; % A cell array that holds the conditions
% names to be used as titles in the
% statistics file that will be created for
% the bad TRs. Will be used only if measuresForScrubbing was
% defined in the config file.

statDataForMeasure = {};    % A cell array that holds the amount of bad TRs
% in each condition in each run,
% to be reported in the
% statistics file that will be created for
% the bad TRs. Will be used only if measuresForbing was
% defined in the config file.

subjectsList = subjectsList(~ismember(subjectsList, 'logs'));
%% Loop for all subjects and define the first level model for each
for subjectNum = 1:length (subjectsList)
    subjectPath = [dataDir, '\', subjectsList{subjectNum}, filesep];
    subNum = str2num(extractAfter(subjectsList{subjectNum},'sub-'));
    
    % If we defined specific subjectsToAnalyse - we check here if this
    % subjecy should be analysed
    if ~isempty(config.subjectsToAnalyse) && ~ismember(subNum, config.subjectsToAnalyse)
        continue
    end
    if ismember(subNum,config.subjectsToExclude)
        continue
    end
    %% Specifying and creating individual SPM folder
    outDir =  [firstLevelDir, filesep, subjectsList{subjectNum}, filesep];
    if ~exist (outDir)
        mkdir (outDir);
    end
    
    matlabbatch{1}.spm.stats.fmri_spec.dir = {outDir};
    
    for sessionNum = 1: length(config.sessions)
        session = config.sessions(sessionNum);
        subjectPath = [dataDir, filesep, subjectsList{subjectNum}, filesep];
        if  session{1} == "" % There are no sessions in the BIDS format so the functional data
            % is located right under the subjects
            % folder
            funcFilesDir = [subjectPath, 'ses-1\func\'];%Change back to ses-1
        else
            funcFilesDir = [subjectPath, session{1}, filesep, 'ses-1\func\'];%Change back to ses-1
        end
        if ~exist (funcFilesDir)
            continue;
        end
        
        niiFiles = dir([funcFilesDir, fileTemplate, fileType]);
        
        if isempty(niiFiles)
            cd(funcFilesDir);
            extract = gunzip('*.gz', funcFilesDir);
            niiFiles = dir([funcFilesDir, fileTemplate, fileType]);
            if isempty(niiFiles)
                matlabbatch{1}.spm.stats.fmri_spec.sess(sessionNum,1).scans= {};
                continue
            end
        end
        
        for niiFileNum = 1:length(niiFiles)
            % Specify scans for each run
            runID=extractBefore(niiFiles(niiFileNum).name,...
                config.useToExtractRun);
            % reshape the 4 dimensional nifti file to multiple files
            % with 3 dimensions (each file corresponds to one scan)
            scans{niiFileNum}=cellstr(spm_select('expand', fullfile(funcFilesDir,niiFiles(niiFileNum).name)));
            allScans=scans{niiFileNum};
            relevantScans=allScans(firstRelevantscan:end); % skip the first TRs
            matlabbatch{1}.spm.stats.fmri_spec.sess(sessionNum,niiFileNum).scans=relevantScans;
            
            % Specify protocol for each run
            startIndexNoPrefix = 1 + length(config.smoothFilePrefix);
            %Use this on smooth files
            runID_noPrefix = runID(startIndexNoPrefix:length(runID));
            if config.isConstProtocol == true
                protocolMat = dir(config.protocolFolder)
                protocolMat = protocolMat(firstFolderIndex) %first file in folder
                protocolMat = fullfile(protocolMat.folder ,protocolMat.name)
            else
                protocolMat=dir([protocolFolder, '\', runID_noPrefix, '.mat']);
                protocolMat=fullfile(protocolMat.folder ,protocolMat.name);
            end
            
            matlabbatch{1}.spm.stats.fmri_spec.sess(sessionNum,niiFileNum).multi = {protocolMat};
            % hpf - default - didn't tauch
            matlabbatch{1}.spm.stats.fmri_spec.sess(sessionNum,niiFileNum).hpf = 128;
            
            % Create movement regressors for each run
            confoundFiles=dir([funcFilesDir runID_noPrefix '*confounds*.tsv']);
            Rfile=tdfread([funcFilesDir confoundFiles.name],'\t');
            
            noiseRegressors = config.noiseRegressors;
            R = [];
            for regressor = 1:length(noiseRegressors)
                currentR = extractfield(Rfile, noiseRegressors{regressor});
                if iscell(currentR)
                    currentR = convertCharArrayToNumVector(currentR{1})
                end
                R = [R, currentR'];
            end
            
            extendedMotion = motionRegExtended(Rfile, config.useExtendedMotionRegressors);
            R = [R, extendedMotion];
           
            scrubbingMeasures = config.measuresForScrubbing;
            temporalMask = [];
            for measure = 1:length(scrubbingMeasures)
                scrubbingMeasure = extractfield(Rfile, scrubbingMeasures{measure});
                display(runID_noPrefix)          
                [statTitlesForMeasure, statDataForMeasure_run,...
                    temporalMaskForMeasure_run] = ...
                    createTemporalMask(scrubbingMeasure{1},...
                    config.thresholdsForScrubbing(measure), protocolMat,...
                    projectConfigFile);           
                    statDataForMeasure_run{1} = runID_noPrefix;
                   fostatDataForMeasure = [statDataForMeasure ; statDataForMeasure_run];
                    temporalMask = [temporalMask, temporalMaskForMeasure_run];
            end
            
            R = [R, temporalMask];
            R=R(firstRelevantscan:end,:); % skip first TRs for reressors
            
            % Save regressors in a .mat file
            outRegFileName=[firstLevelDir,'\' 'MovReg_' runID_noPrefix '.mat'];
            save(outRegFileName, 'R');
            
            % Specify movement regressors for each run
            matlabbatch{1}.spm.stats.fmri_spec.sess(sessionNum,niiFileNum).multi_reg = {outRegFileName};
        end
        
        %% all parameters that are not individually specific
        matlabbatch{1}.spm.stats.fmri_spec.timing.units = config.timeUnits;
        matlabbatch{1}.spm.stats.fmri_spec.timing.RT = config.TR;
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = config.fmri_t;
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = config.fmri_t0;
        matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
        matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
        matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
        matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.8;
        matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
        matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
        matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
        
        %Model Estimation
        matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
        matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
        matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
    end
    
    batches{subjectNum} = matlabbatch;
    clear matlabbatch;
end

% % Write bad TRs statistics to file
% table=cell2table(statDataForMeasure);
% writetable(table, config.scrubbingStatFileName);

subjectsToAnalyse = config.subjectsToAnalyse;
subjectsToExclude = config.subjectsToExclude;
% Actually run the batches now
if runParallel
    parfor subjectNum = 1:length (subjectsList)
        subNum = str2num(extractAfter(subjectsList{subjectNum},'sub-'));
        if ~isempty(subjectsToAnalyse) && ~ismember(subNum, subjectsToAnalyse)
            continue
        end
        if ismember(subNum,subjectsToExclude)
            continue
        end
        matlabbatch = batches(subjectNum);
        spm_jobman('run',matlabbatch);
    end
else
    for subjectNum = 1:length (subjectsList)
        subNum = str2num(extractAfter(subjectsList{subjectNum},'sub-'));
        if ~isempty(subjectsToAnalyse) && ~ismember(subNum, subjectsToAnalyse)
            continue
        end
        if ismember(subNum,subjectsToExclude)
            continue
        end
        matlabbatch = batches(subjectNum);
        disp(subjectNum);
        spm_jobman('run',matlabbatch);
    end
end

end

