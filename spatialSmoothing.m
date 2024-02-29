
% this function does smoothing to the pre-processed functional files.
% Note that it usually takes a long time to run.

% Inputs %
% projectConfigFile: The path to the project configuration file
% projectConfigFile='Z:\Lab_Projects\PTSD_Subtyping_fMRI_MEG\Initial_Analysis_Jan24\scripts\VisualReminders_Configuration.m'
%change to the relevant session - lines 32 and 34
function spatialSmoothing(projectConfigFile)
    spm('defaults','fmri');
    spm_jobman('initcfg');
    run (projectConfigFile);
    
    dataDir = config.dataDir;
    fileTemplate = config.originalFunctionalFileTemplate;  
    fileType = '.nii';
    subjectsDir=dir(dataDir);
    subjectsDir=subjectsDir([subjectsDir.isdir]);
    subjects=subjectsDir(3:length(subjectsDir));
    subjectsList = {};
    for i=1:length(subjects)
       subjectsList{i}= subjects(i).name; 
    end

     for subjectNum=1:length(subjectsList)
        if subjectsList{subjectNum} == "logs"
            continue
        end
        for sessionNum = 1: length(config.sessions)
            session = config.sessions(sessionNum);
            subjectPath = [dataDir, filesep, subjectsList{subjectNum}, filesep];
            if  session{1} == ""
                funcFilesDir = [subjectPath, 'ses-1\func\'];%change to the relevant session
            else
                funcFilesDir = [subjectPath, session{1}, filesep, 'ses-1\func\'];%change to the relevant session
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
                   continue
               end
            end
            for niiFileNum = 1:length(niiFiles)
                    % Specify scans for each run
                    runID=extractBefore(niiFiles(niiFileNum).name,'_bold');
                    scans{niiFileNum}=cellstr(spm_select('expand', fullfile(funcFilesDir,niiFiles(niiFileNum).name)));
                    matlabbatch{1}.spm.spatial.smooth.data = scans{niiFileNum};
                    matlabbatch{1}.spm.spatial.smooth.fwhm = [6 6 6];
                    matlabbatch{1}.spm.spatial.smooth.dtype = 0;
                    matlabbatch{1}.spm.spatial.smooth.im = 0;
                    matlabbatch{1}.spm.spatial.smooth.prefix = config.smoothFilePrefix;
                    spm_jobman('run',matlabbatch);
            end
        end
    end
end

