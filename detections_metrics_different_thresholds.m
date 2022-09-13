clc; clear; close all;
dirName = fileparts(matlab.desktop.editor.getActiveFilename);
addpath(dirName)
addpath(fullfile('/home/andrea/Projects/proyecto_ripples/analysis/scripts'))
addpath(genpath('/home/andrea/Projects/Analyset/scripts'));
addpath(genpath('/home/andrea/Toolboxes/buzcode/'))

%  -------------
%  | LOAD INFO |
%  -------------

dirAndrea = '/home/andrea/DATA/';

% Sessions
dirSessions = {
    'Kilosort/Thy7/2020-11-11_16-05-00', ...
    'Kilosort/Thy7/2020-11-11_16-21-15', ...
    'Kilosort/Thy7/2020-11-11_16-35-43', ...
    'Kilosort/Thy1GCam1/2020-12-18_13-16-03', ...
    'Kilosort/Thy1GCam1/2020-12-18_13-32-27', ...
    'Kilosort/Thy1GCam1/2020-12-18_14-40-16', ...
    'Kilosort/Thy1GCam1/2020-12-18_14-56-54', ...
    'Kilosort/Thy1GCam1/2020-12-21_14-58-51', ...
    'Kilosort/Thy1GCam1/2020-12-21_15-11-32', ...
    'Kilosort/Thy1GCam1/2020-12-21_15-26-01', ...
    'Kilosort/Calb20/2021-01-22_13-08-20', ...
    'Kilosort/Dlx1/2021-02-12_12-24-56', ...
    'Kilosort/Dlx1/2021-02-12_12-46-54', ...
    'Kilosort/Thy9/2021-03-16_12-10-32', ...
    'Kilosort/Thy9/2021-03-16_14-31-51', ...
    'Kilosort/PV6/2021-04-19_14-02-31', ...
    'Kilosort/PV7xChR2/2021-05-18_13-08-23', ...
    'Kilosort/PV7xChR2/2021-05-18_13-24-33', ...
    'Kilosort/PV7xChR2/2021-05-18_13-48-31', ...
    'Kilosort/Thy10/2021-06-01_13-28-27', ...
    'Kilosort/Thy10/2021-06-15_15-28-56', ...    
};

for isess = 1:length(dirSessions)
    dirSession = dirSessions{isess};
    
    fprintf('\n\n  > DATA: %s\n',dirSession);
    dirData = fullfile(dirAndrea, dirSession);
    
    % Make image and events directory
    if ~exist(fullfile(dirData, 'images'), 'dir')
        mkdir(fullfile(dirData, 'images'))
    end
    if ~exist(fullfile(dirData, 'events'), 'dir')
        mkdir(fullfile(dirData, 'events'))
    end
    
    
    % Load pyramidal channel of shank
    load(fullfile(dirData,'info.mat'), 'pyr', 'slm', 'so', 'rad', 'fs');
    ch.pyr = pyr;
    ch.rad = rad;
    ch.slm = slm;
    ch.so = so;

    % Load LFP
    [LFPraw, shMap] = load_lfp(dirData, 'fs', fs);
    LFP = double(LFPraw);
    % zscore LFP
    LFP = (LFP-mean(LFP,1)) ./ std(LFP);
    

    % -- COMPUTE AUTOMATIC EVENTS WITH COMMON THRESHOLD ----

    [true_events, true_shanks] = read_csv_events(dirData, fs);
    true_shank = unique(true_shanks);

    for thr = 0.1:0.1:0.9
        fprintf('thresh %.1f...', thr);

        % File name
        file_name = fullfile(dirData, 'events', ['events_cnn32_thr', num2str(thr)]);

        % Read
        if exist([file_name '.txt'], 'file')
            fprintf(' loading...');
            pred_events = read_all_events([file_name '.txt'], 'exact_match', 1);
            
            % Merge nearby detections
            auto_events = pred_events(1,:);
            for ii = 2:size(pred_events,1)
                if all(pred_events(ii,:) < auto_events(end,2)+0.032)
                    auto_events(end, 2) = pred_events(ii,2);
                else
                    auto_events = [auto_events; pred_events(ii,:)];
                end
            end
            

        % Compute and save
        else
            warning('There is no file of detections')
            continue
        end

        fprintf(' compute metrics...\n');

        % Check which ones are TP or FP
        [precision, recall, F1, TP, FN, IOU] = compute_precision_recall_events({auto_events}, true_events);

        % Compute properties
        properties.detection = compute_ripple_properties(LFP, auto_events, ch.pyr(true_shank), fs);
        properties.detection.TP = TP{1};
        properties.true = compute_ripple_properties(LFP, true_events, ch.pyr(true_shank), fs);
        properties.true.FN = FN;

        % Save
        metrics.precision = precision;
        metrics.recall = recall;
        metrics.F1 = F1;
        metrics.TP = TP{1};
        metrics.FN = FN;
        metrics.properties = properties;
        save([file_name '_metrics_win.mat'], 'metrics', 'properties')

        clear properties metrics

    end

end





