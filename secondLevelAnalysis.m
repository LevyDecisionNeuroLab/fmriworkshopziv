% This function runs second level analysis

% Inputs %

% projectConfigFile: path to the project's configuration file

% contrastsNames: A cell array of contrasts name to calculate the second
% level for

% analysisType: analysis to perform. Should be one of the followings 
% ("oneSampleTTest" / "covariates")
% oneSampleTTest is used if we just want to do the standrat analysis -
% check for each voxel if a specific beta value that represents a contrast
% between multiple conditions in significantly different than zero (thus -
% one sample t test)
% covariates - we use this analysis type if we want to control for one or
% more variables that my contribute to the variaility between subjects
% (like age, depression score, etc.)

% covariatesFiles: A cell array of MAT files names where each contains data
% for one covariate - two variables:
%   1. name: covariate name in characters (e.g., cov='name')
%   2. values: values for the covariate - a (vertical) vector with the length of
%   subjects number
% if the required analsis is no "covariates" then this variable shpuld be
% an empty cell array.
% Please notice that the resulting contrast image represents the mean effect
% while controlling for variability explained by the covariate. 
% If you are interested in directly testing the variability explained by the covariate,
% this currently should be done via the "results" tab in SPMs GUI,
% were you should mark the regresseor of the covariate by "1" and all other regressors by "0". 


% resultsFolder: name of the results folder (will be created inside each contrast
% folder in the secondLevelAnlysis folder) 

function secondLevelAnalysis(projectConfigFile, contrastsNames, analysisType, covariatesFiles, resultsFolder, maskFilePath)

    conFilePrefix_smallerThan10 = 'con_000';
    conFilePrefix_largerThan10 = 'con_00';
    run(projectConfigFile);
    secondLevelDir = config.secondLevelDir;
    firstLevelDir = config.firstLevelDir;
    firstLevelDirContent = dir(firstLevelDir);
    subs_folders = arrayfun(@(x) x.isdir==1,firstLevelDirContent);
    subs_folders = firstLevelDirContent(subs_folders);
    subs_folders=subs_folders(3:end);
    con_template = load([subs_folders(1).folder,'\',...
        subs_folders(1).name , '\', 'SPM.mat']);covariatesFiles
    contrasts = extractfield(con_template.SPM.xCon,'name');

    spm('defaults','fmri');
    spm_jobman('initcfg');

    %% Loop for all contrasts
    for con = 1:length(contrastsNames)
        file_dir = char(fullfile(secondLevelDir, contrastsNames{con}));
        file_dir = strrep(file_dir, '>', '_vs_');
        glm_dir = char(fullfile(file_dir,'\', resultsFolder));
        
        if ~exist (glm_dir)
            mkdir (glm_dir);
        else
            spm_mat=dir(fullfile(glm_dir,'SPM.mat'));
            if ~isempty(spm_mat)
                continue
            end            
        end
        matlabbatch{1}.spm.stats.factorial_design.dir = {glm_dir};

        matlabbatch{1}.spm.stats.factorial_design.masking.em = {maskFilePath};
        con_name = contrastsNames{con};
        con_num = find(strcmp(contrasts,con_name));
        
        if con_num < 10
            con_pref = conFilePrefix_smallerThan10;
        else
            con_pref =  conFilePrefix_largerThan10;
        end
        full_con = ['*' con_pref, num2str(con_num), '.nii'];
        subjectsCons = dir(fullfile(file_dir, full_con));


        if analysisType == "oneSampleTTest"
            matlabbatch = addOneSampleTTest(subjectsCons, matlabbatch, projectConfigFile);
        elseif analysisType == "covariates"
            matlabbatch = addCovariates(subjectsCons, matlabbatch, covariatesFiles, projectConfigFile);
        end

        matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('Factorial design specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    
        matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'All';
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
        matlabbatch{3}.spm.stats.con.delete = 0;

        %% RUN the batch
        spm_jobman('run',matlabbatch);

    end
end

function batch = addOneSampleTTest(subjectsCons, batchStruct, projectConfigFile)
    run(projectConfigFile);
    actualSub = 1;
    for sub=1:length(subjectsCons)
        subNum = str2num(extractBefore(extractAfter(subjectsCons(sub).name,'sub-'), 'con'));
        if ~isempty(config.subjectsToAnalyse) && ~ismember(subNum, config.subjectsToAnalyse)
            continue
        end
        if ismember(subNum, config.subjectsToExclude) 
            continue
        end
        conPath = [subjectsCons(sub).folder, filesep, subjectsCons(sub).name, ',1'];
        batchStruct{1}.spm.stats.factorial_design.des.t1.scans {actualSub, 1} = conPath;
        actualSub = actualSub + 1;
    end
    batch = batchStruct;
end

function batch = addCovariates(subjectsCons, batchStruct, covariatesFiles, projectConfigFile)
    run(projectConfigFile);
    actualSub = 1;
    for sub=1:length(subjectsCons)
        subNum = str2num(extractBefore(extractAfter(subjectsCons(sub).name,'sub-'), 'con'));
        if ~isempty(config.subjectsToAnalyse) && ~ismember(subNum, config.subjectsToAnalyse)
            continue
        end
        if ismember(subNum, config.subjectsToExclude) 
            continue
        end
        conPath = [subjectsCons(sub).folder, filesep, subjectsCons(sub).name, ',1'];
        batchStruct{1}.spm.stats.factorial_design.des.mreg.scans {actualSub, 1} = conPath;
        actualSub = actualSub + 1;
    end
    matlabbatch{1}.spm.stats.factorial_design.des.mreg.mcov.c = [51
                                                             75
                                                             51
                                                             71
                                                             80
                                                             61
                                                             43
                                                             95
                                                             68
                                                             59
                                                             44
                                                             80
                                                             42
                                                             83
                                                             77
                                                             30
                                                             60
                                                             48
                                                             58
                                                             63
                                                             45
                                                             83
                                                             56
                                                             62
                                                             48
                                                             72
                                                             53
                                                             52
                                                             88
                                                             87
                                                             48
                                                             64
                                                             40
                                                             88
                                                             46
                                                             58
                                                             87
                                                             54
                                                             78
                                                             30
                                                             73
                                                             21
                                                             102
                                                             14
                                                             8
                                                             30
                                                             41
                                                             26
                                                             51
                                                             4
                                                             33
                                                             83
                                                             43
                                                             33
                                                             38
                                                             47
                                                             32
                                                             30
                                                             12
                                                             51
                                                             42
                                                             72
                                                             34
                                                             71
                                                             32
                                                             7
                                                             48
                                                             6
                                                             13
                                                             30
                                                             55
                                                             41
                                                             17
                                                             16
                                                             81
                                                             76
                                                             46
                                                             52
                                                             46
                                                             22
                                                             55
                                                             55
                                                             72
                                                             20
                                                             19
                                                             90
                                                             69
                                                             84
                                                             55
                                                             44
                                                             45
                                                             77
                                                             53
                                                             58
                                                             100
                                                             58
                                                             9
                                                             11
                                                             57
                                                             32
                                                             16
                                                             78
                                                             46
                                                             58
                                                             56
                                                             36
                                                             24
                                                             60
                                                             62
                                                             66
                                                             30
                                                             52
                                                             43
                                                             53
                                                             57
                                                             52
                                                             98
                                                             84
                                                             65
                                                             73
                                                             61
                                                             36
                                                             47
                                                             32
                                                             67
                                                             93
                                                             37
                                                             59
                                                             58
                                                             75
                                                             32
                                                             40
                                                             32];
                                                         
matlabbatch{1}.spm.stats.factorial_design.des.mreg.mcov.cname = 'T1_CAPS4';
matlabbatch{1}.spm.stats.factorial_design.des.mreg.mcov.iCC = 1;
%     for covariateNum = 1: length(covariatesFiles) 
%         load (covariatesFiles{covariateNum});
%         batchStruct{1}.spm.stats.factorial_design.des.mreg.mcov(covariateNum).c = values;
%         batchStruct{1}.spm.stats.factorial_design.des.mreg.mcov(covariateNum).cname = name;
%         batchStruct{1}.spm.stats.factorial_design.des.mreg.mcov(covariateNum).iCC = 1;
%        batchStruct{1}.spm.stats.factorial_design.des.mreg.mcov(covariateNum).iCFI = 1;
%     end
    batch = batchStruct;
end