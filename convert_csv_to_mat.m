% Transform Behavioral 'csv' files into Eventfile '.mat' for fMRI Analysis
% Created by Ziv Ben-Zion, January 2024
%
% Base path where the CSV files are located
basePath = 'Z:\Lab_Projects\PTSD_Subtyping_fMRI_MEG\Initial_Analysis_Jan24\data\eventfiles\emotionalgonogo'; % Update this to your CSV files directory
% Define constants
firstFolderIndex = 3;
fileType = '*.csv';
% Extract subjects list
subjectsDir=dir(basePath);
subjects=subjectsDir(firstFolderIndex:length(subjectsDir));
subjectsList = extractfield(subjects,'name');

% Loop over each subject
for subjNum = 1:length (subjectsList)
    % Extract the actual subject number from the filename
    subjectStr = subjectsList{subjNum};
    subjectNumber = str2double(regexp(subjectStr, '\d+', 'match'));
    % Construct the file names, depending on the task (PSUB_GNG or PSUB_VR)
    csvFileName = sprintf('PSUB_GNG_%d.csv', subjectNumber);
    % Choose output file names, depending on the task (emotionalgonogo or visualreminders)
    matFileName = sprintf('sub-%d_ses-1_task-emotionalgonogo.mat', subjectNumber);
    
    % Full paths for the CSV and MAT files
    csvFilePath = fullfile(basePath, csvFileName);
    matFilePath = fullfile(basePath, matFileName);

    % Read the CSV file
    dataTable = readtable(csvFilePath);

    % Extract unique conditions
    conditions = unique(dataTable.condition);

    % Initialize cell arrays for onsets, names, and durations
    onsets = cell(1, numel(conditions));
    names = cell(numel(conditions), 1);
    durations = cell(1, numel(conditions));

    % Populate cell arrays with data from the CSV file
    for i = 1:numel(conditions)
        % Logical indexing for rows with the current condition
        conditionIndices = strcmp(dataTable.condition, conditions{i});
        
        % Assign names
        names{i} = conditions{i};
        
        % Assign onsets and durations, ensuring they are column vectors
        onsets{i} = dataTable.onset(conditionIndices);
        durations{i} = dataTable.duration(conditionIndices);
    end

    % Convert onsets and durations to type double
    onsets = cellfun(@double, onsets, 'UniformOutput', false);
    durations = cellfun(@double, durations, 'UniformOutput', false);

    % Save the data to a .mat file with the same structure
    save(matFilePath, 'names', 'onsets', 'durations');
    
    % Display progress
    fprintf('Finished processing %s\n', csvFileName);
end
