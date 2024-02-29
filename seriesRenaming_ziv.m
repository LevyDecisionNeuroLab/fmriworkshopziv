% seriesRenaming_ziv.m
% Created by Ziv Ben-Zion, Jan 2024

rootPath = 'Z:\Lab_Projects\PTSD_Subtyping_fMRI_MEG\Initial_Analysis_Jan24\data\raw_dicom';

dirNames = dir(rootPath);
dirList = {dirNames.name}';
dirList = dirList(3:end);

for curSub = 3:numel(dirList)
    curSubPath = fullfile(rootPath, dirList{curSub});
    fprintf('Applying series renaming on: %s...\n', curSubPath)

    seriesFolders = dir(fullfile(curSubPath, '*')); % List all items in curSubPath
    seriesFolders = seriesFolders([seriesFolders.isdir]); % Filter only directories

    for ii = 1:length(seriesFolders)
        curFolderName = seriesFolders(ii).name;

        % Skip '.' and '..' folders
        if strcmp(curFolderName, '.') || strcmp(curFolderName, '..')
            continue;
        end

    % Folder path for current series
    curFolderPath = fullfile(curSubPath, curFolderName);

    % Code to check DICOM files, extract series name, and rename folder will go here
    dicomFiles = dir(fullfile(curFolderPath, '*.dcm'));
    if isempty(dicomFiles)
    warning('No DICOM files found in %s', curFolderPath);
    continue;
    end

    % Try getting DICOM info from the first file and handle potential errors
    try
        dcmInfo = dicominfo(fullfile(curFolderPath, dicomFiles(1).name));
    catch
        warning('File is not a valid DICOM file: %s', fullfile(curFolderPath, dicomFiles(1).name));
        continue;
    end
    
    seriesName = dcmInfo.SeriesDescription;

    % Construct new folder name
    newFolderName = sprintf('Se%02d_%s', dcmInfo.SeriesNumber, seriesName);
    newFolderPath = fullfile(curSubPath, newFolderName);

    % Rename the folder
    if ~strcmp(curFolderPath, newFolderPath)
    movefile(curFolderPath, newFolderPath);
else
    disp(['Skipping: ', curFolderPath, ' as it is the same as ', newFolderPath]);
end
    end

              
            end
