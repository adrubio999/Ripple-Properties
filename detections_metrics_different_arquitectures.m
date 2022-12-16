clc; clear; close all;
dirName = fileparts(matlab.desktop.editor.getActiveFilename);
addpath(dirName)
% Copied from Andrea's folder
addpath(genpath('C:\Septiembre-Octubre\ScriptsAndrea\buzcode'))
addpath(genpath('C:\Septiembre-Octubre\ScriptsAndrea\scripts'))
addpath(fullfile('C:\Septiembre-Octubre\ScriptsAndrea\scripts proyecto ripples'))

%  -------------
%  | LOAD INFO |
%  -------------
% 
dirAndrea = 'C:\ProyectoInicial\Datos';

% Sessions
dirSessions = {
    'Kilosort/Dlx1/2021-02-12_12-46-54', ...
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
% Which model made de predictions
ModelTypes={'LSTM','XGBOOST','SVM','CNN2D','CNN1D'};
%% 
for isess = 1:length(dirSessions)
    fprintf('Computing properties of session %d',isess)
    dirSession = dirSessions{isess};
    fprintf('\n\n  > DATA: %s\n',dirSession);
    dirData = fullfile(dirAndrea, dirSession)
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
%    % An array with the th used in the test is created 
    
    dirTest=fullfile(dirData,'events','Best');
        for iModeltype=1:length(ModelTypes)
            thArray=[];
            
            ModelType=ModelTypes{iModeltype};
            filePattern = fullfile(dirTest, strcat(ModelType,'_','*.txt') ); 
            Results = dir(filePattern);
            for i=1:length(Results)
                %Extracts the threshold and appends it to an array 
                thStr=extractBetween(Results(i).name,'th_','.txt');
                thArray(end+1)=str2double(thStr{1,1});
            end

            % -- COMPUTE AUTOMATIC EVENTS WITH COMMON THRESHOLD ----
            % Ground truth?
            [true_events, true_shanks] = read_csv_events(dirData, fs);
            true_shank = unique(true_shanks);

            for i_th =1:length(thArray)  %thArray extracted from files results
                thr=thArray(i_th);
                disp(ModelType);
                fprintf('Threshold %.2f...', thr);
                % File name. Results contains the information of the file, not the
                % file itself
                file_name = fullfile(Results(i_th).folder,Results(i_th).name);
                % Read
                if exist(file_name, 'file')
                    fprintf(' loading...');
                    pred_events = read_all_events(file_name , 'exact_match', 1);

                    % Merge nearby detections
                    if (isempty(pred_events))
                        continue
                    end
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
                    warning('There is no file of detections with such name')
                    continue
                end

                fprintf('Computing metrics: \n');

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

                save([file_name(1:end-4) '_metrics_win.mat'], 'metrics', 'properties')

                clear properties metrics

            end


            %Reset del array de umbrales, por si es distinto en cada modelo
            thArray=[];
         end
end



