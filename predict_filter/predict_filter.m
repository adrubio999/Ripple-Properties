clc; clear; close all;
dirName = fileparts(matlab.desktop.editor.getActiveFilename);
addpath(dirName)
addpath(genpath('C:\Septiembre-Octubre\ScriptsAndrea\buzcode'));
addpath(genpath('C:\Septiembre-Octubre\ScriptsAndrea\scripts'));
addpath(fullfile('C:\Septiembre-Octubre\ScriptsAndrea\scripts proyecto ripples'));
addpath(fullfile('C:\Septiembre-Octubre\ScriptsAndrea\MANUEL_VALERO'));
% Directory of data 
dirProject = '/home/andrea/Projects/proyecto_ripples';
dirDatabase = 'C:\ProyectoInicial\Datos';

% Sessions

sessions = {'Kilosort/Dlx1/2021-02-12_12-46-54', ...
    'Kilosort/Thy7/2020-11-11_16-05-00', ...
    'Kilosort/PV6/2021-04-19_14-02-31', ...
    'Kilosort/PV7xChR2/2021-05-18_13-24-33',...
    'Kilosort/Thy9/2021-03-16_12-10-32', ...
    'Kilosort/Thy1GCam1/2020-12-18_14-40-16', ...
    'Kilosort/Thy7/2020-11-11_16-21-15', ...        % 6 
    'Kilosort/Thy7/2020-11-11_16-35-43', ...        % 7
    'Kilosort/Thy1GCam1/2020-12-18_13-16-03', ...   % 8
    'Kilosort/Thy1GCam1/2020-12-18_13-32-27', ...   % 9
    'Kilosort/Thy1GCam1/2020-12-18_14-56-54', ...   % 10
    'Kilosort/Thy1GCam1/2020-12-21_14-58-51', ...   % 11
    'Kilosort/Thy1GCam1/2020-12-21_15-11-32', ...   % 12
    'Kilosort/Thy1GCam1/2020-12-21_15-26-01', ...   % 13
    'Kilosort/Calb20/2021-01-22_13-08-20', ...      % 14
    'Kilosort/Dlx1/2021-02-12_12-24-56', ...        % 15
    'Kilosort/Thy9/2021-03-16_14-31-51', ...     % 16
    'Kilosort/PV7xChR2/2021-05-18_13-08-23', ... % 17
    'Kilosort/PV7xChR2/2021-05-18_13-48-31', ... % 18
    'Kilosort/Thy10/2021-06-01_13-28-27', ...    % 19
    'Kilosort/Thy10/2021-06-15_15-28-56', ...    % 20
    };

% Filters to test
filters = {'butter', 'besselfir'};

for isess = 1:length(sessions)
    
    % -- LOAD DATA -----

    dirData = fullfile(dirDatabase, sessions{isess});
    
    fprintf('\n\n    ---------------------\n    |  Ripple Analysis  |\n    ---------------------\n');
    fprintf('%s\n', dirData)

    % Load pyramidal channel of shank
    load(fullfile(dirData,'info.mat'), 'pyr', 'slm', 'so', 'rad', 'fs');
    ch.pyr = pyr; %pyr_chs.(strrep(strrep(sessions{isess},'/','_'),'-','_'));
    ch.rad = rad;
    ch.slm = slm;
    ch.so = so;

    % Load LFP
    [LFP, shMap] = load_lfp(dirData, 'fs', fs);
    LFP = double(LFP);
    
    if ~exist(fullfile(dirData, 'images'), 'dir')
        mkdir(fullfile(dirData, 'images'))
    end
    
    for ifilter = 1:length(filters)
        
        filter_type = filters{ifilter};
        fprintf('%s filter ', filter_type);
    
        % -- COMPUTE AUTOMATIC EVENTS WITH BEST THRESHOLD ----

        % True events   
        [true_events, true_shanks] = read_csv_events(dirData, fs);
        true_shank = unique(true_shanks);

        % Find ripples
        [auto_events, F1s, thrs1, thrs2] = find_automatic_ripples(LFP, true_shank, ch, fs, 'true_events', true_events, ...
                                                 'filter_type', filter_type,...
                                                 'verbose', 1, 'save_plot', fullfile(dirData, 'images', ['F1_events_automatic_' filter_type '_tuned.png']));

        % Performance
        [precision, recall, F1] = compute_precision_recall_events({auto_events}, true_events);
        fprintf('        precision %.2f , recall %.2f\n', precision, recall)
    
        % Save
        write_file = fullfile(dirData, 'events', ['events_automatic_' filter_type '_tuned']);
        write_events_format(write_file, auto_events, true_shank);
        
        % Save F1s
        save(fullfile(dirData, 'events', ['events_automatic_' filter_type '_tuned_F1s.mat']), 'F1s', 'thrs1', 'thrs2')
        
    end
    
end


