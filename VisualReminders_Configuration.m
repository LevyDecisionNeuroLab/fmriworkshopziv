%%%%%%%%%%%%%%%%%%%%%%% REQUIRED DEFINITIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.firstLevelDir = 'Z:\Lab_Projects\PTSD_Subtyping_fMRI_MEG\Initial_Analysis_Jan24\data\VisualReminders_First_Level';
config.secondLevelDir='Z:\Lab_Projects\PTSD_Subtyping_fMRI_MEG\Initial_Analysis_Jan24\data\VisualReminders_Second_Level';
config.dataDir = 'Z:\Lab_Projects\PTSD_Subtyping_fMRI_MEG\Initial_Analysis_Jan24\data\BIDS\derivatives';
config.isConstProtocol = false;% For createContrasts
config.protocolFolder = 'Z:\Lab_Projects\PTSD_Subtyping_fMRI_MEG\Initial_Analysis_Jan24\data\eventfiles\visualreminders';
config.timeUnits = 'secs';
config.TR = 1;
config.smoothFilePrefix = 's';
config.smoothFunctionalFileTemplate = 'ss*visualreminders*MNI152NLin2009cAsym_res-2_desc-preproc_bold';
config.originalFunctionalFileTemplate = '*visualreminders*MNI152NLin2009cAsym_res-2_desc-preproc_bold';
config.useToExtractRun = '_space';
config.numOfInitialTRsToRemove =0; %Dont Remove any TRs
config.fmri_t = 16;
config.fmri_t0 = 8;
config.sessions = {""};
config.subjectsToExclude = [1807, 1808];%1807 still not preprocessed, 1808 will do VR next month
config.subjectsToAnalyse = [1783, 1784, 1809, 1811, 1819, 1820, 1830];
config.noiseRegressors = {'trans_x',	'trans_y', 'trans_z',...
    'rot_x',	'rot_y',	'rot_z', 'std_dvars',...
    'a_comp_cor_00',	'a_comp_cor_01',	'a_comp_cor_02',...
    'a_comp_cor_03',	'a_comp_cor_04',	'a_comp_cor_05',...
    'framewise_displacement'};
config.useExtendedMotionRegressors = {'trans_x','trans_y', 'trans_z',...
    'rot_x',	'rot_y',	'rot_z'};
config.measuresForScrubbing = {'framewise_displacement'};
config.thresholdsForScrubbing = [0.9];
config.scrubbingStatFileName = 'fd_stats_visual reminders.CSV';

%% For First Level & Protcolos
%projectConfigFile='Z:\Lab_Projects\PTSD_Subtyping_fMRI_MEG\Initial_Analysis_Jan24\scripts\VisualReminders_Configuration.m'
% runParallel=false
%
% % For createContrasts
% contrasts={'Gohappyneutral-NoGohappyneutral', 'Goangryneutral-NoGoangryneutral', 'Gohappyangry-NoGohappyangry'...
%            'Goangryhappy-NoGoangryhappy', 'Goneutralhappy-NoGoneutralhappy', 'Goneutralangry-NoGoneutralangry'...
%            'Gohappyneutral+Goangryneutral+Gohappyangry+Goangryhappy+Goneutralhappy+Goneutralangry-NoGohappyneutral+NoGoangryneutral+NoGohappyangry+NoGoangryhappy+NoGoneutralhappy+NoGoneutralangry'}
% 
% contrastsNames={'HappyGo_NeutralNoGo', 'AngryGo_NeutralNoGo', 'HappyGo_AngryNoGo', 'AngryGo_HappyNoGo', 'NeutralGo_HappyNoGo', 'NeutralGo_AngryNoGo', 'AllGo_AllNoGo'}
% 
% projectConfigurationFile=''Z:\Lab_Projects\PTSD_Subtyping_fMRI_MEG\Initial_Analysis_Jan24\scripts\VisualReminders_Configuration.m'
% 
% isParametric=false
% 
% names = {'Gohappyneutral' 'NoGohappyneutral' 'Goangryneutral' 'NoGoangryneutral' 'Gohappyangry' 'NoGohappyangry',...
% 'Goangryhappy' 'NoGoangryhappy' 'Goneutralhappy' 'NoGoneutralhappy' 'Goneutralangry' 'NoGoneutralangry'}

%% For secondLevelAnalysis
% analysisType='oneSampleTTest'
% covariatesFiles={}
% resultsFolder='VisualReminders_Second_Level'
% maskFilePath={}

% analysisType='covariates'
% resultsFolder='T1CAPSCovariate_Baseline_Choose&False_Mar20'
% maskFilePath={}
%covariatesFiles={'51','75','51','71','80','61','43','95','68','59','44','80','42','83','77','30','60','48','58','63','45','83','56','62','48','72','53','52','88','87','48','64','40','88','46','58','87','54','78','30','73','21','102','14','8','30','41','26','51','4','33','82','43','33','38','47','32','30','12','51','42','72','34','71','32','7','48','6','13','30','55','41','17','16','81','76','46','52','46','22','55','55','72','20','19','90','69','84','55','44','45','77','53','58','100','58','9','11','57','32','16','78','46','58','56','36','24','60','62','66','30','52','43','53','57','52','98','84','65','73','61','36','47','32','64','93','37','59','58','75','32','40','32'}

