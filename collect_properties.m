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

dirAndrea = 'C:\ProyectoInicial\Datos';

% Sessions
dirSessions = {
    'Kilosort/Thy7/2020-11-11_16-05-00', ...
    'Kilosort/Thy1GCam1/2020-12-18_14-40-16', ...
    'Kilosort/Dlx1/2021-02-12_12-46-54', ...
    'Kilosort/Thy9/2021-03-16_12-10-32', ...
    'Kilosort/PV6/2021-04-19_14-02-31', ...
    'Kilosort/PV7xChR2/2021-05-18_13-24-33'    
};

% Filters to test
%detectors = {'butter', 'besselfir', 'cnn32'};
%Where to save the generated files inside Ripple-Properties
SavePath='2022-09-14';
%Detectors will contain the different models validated inside
%session\events\[Model]
detectors = {'CNN2D'};
%thresholds = {2:8, 2:8, 0.1:0.1:0.9};
% This section extracts the length of the threshold array
dirData = fullfile(dirAndrea, dirSessions{4});

% Properties of all ripples 
pred_prop = {};
true_prop = {};
% This for loop extracts the arrays used in the test of the different
% arquitectures, which dont have to be the same across models
 thresholds={} ;  % Working with cells
for idet = 1:length(detectors) 
    th_arr=[];
    dirTest=fullfile(dirData,'events',detectors{idet});
    filePattern = fullfile(dirTest, '*.txt')
    Results = dir(filePattern);
    for i=1:length(Results)
        %Extracts the threshold and appends it to an array 
        thStr=extractBetween(Results(i).name,'th','.txt');
        th_arr(end+1)=str2double(thStr{1,1});
    end
    thresholds(end+1)={th_arr};
end
% Cell inicialzation
for idet = 1:length(detectors)
    pred_prop.(detectors{idet}) = cell(1,length(thresholds{idet}));
    true_prop.(detectors{idet}) = cell(1,length(thresholds{idet}));
end
%% for loop iterating over the sessions
for isess = 1:length(dirSessions)
    dirSession = dirSessions{isess};
    
    fprintf('\n\n  > DATA: %s\n',dirSession);
    % for loop iterating over the arquitectures
    for idet = 1:length(detectors)        
        detector = detectors{idet};
        disp(detector);
        dirData = fullfile(dirAndrea, dirSession,'events',detector);
      
        filePattern = fullfile(dirTest, '*.txt'); 
        Results = dir(filePattern);              %Results contains a structure with the names of the folder      
        
        for ithr = 1:length(thresholds{idet})
            thr = thresholds{idet}(ithr);
            disp(fullfile(dirData, strcat(Results(ithr).name(1:end-4),'_metrics_win.mat')))
            load(fullfile(dirData, strcat(Results(ithr).name(1:end-4),'_metrics_win.mat')), 'properties') 
            % PRED: append to properties structure
            append_table = properties.detection(:,[1:6 8]);
            append_table = [append_table table(isess*ones(height(properties.detection),1), 'VariableNames', {'session'})];
            pred_prop.(detector){ithr} = [pred_prop.(detector){ithr}; append_table];
            % PRED: append to properties structure
            append_table = properties.true(:,[1:6 8]);
            append_table = [append_table table(isess*ones(height(properties.true),1), 'VariableNames', {'session'})];
            true_prop.(detector){ithr} = [true_prop.(detector){ithr}; append_table];
        end        
   end
end
% It is saved in the main directory
if ~exist(SavePath, 'dir')
       mkdir(SavePath);
end
save(fullfile(SavePath,'all_properties.mat'), 'pred_prop', 'true_prop', 'detectors', 'thresholds', 'dirSessions')

%%

% Load
load(fullfile(SavePath,'all_properties.mat'))
TPFN_names = {'TP', 'FP', 'FN', 'pred', 'true'};

prop_sess = {};
for iTPFN = 1:length(TPFN_names)
    TPFN = TPFN_names{iTPFN};

    % Pred
    prop_sess.(TPFN) = {};
    prop_sess.(TPFN).mean = {};
    prop_sess.(TPFN).median = {};
    prop_sess.(TPFN).std = {};

    % Mean by session in true properties
    for idet = 1:length(detectors)
        detector = detectors{idet};
        prop_sess.(TPFN).mean.(detector) = cell(1,length(thresholds{idet}));
        prop_sess.(TPFN).median.(detector) = cell(1,length(thresholds{idet}));
        prop_sess.(TPFN).std.(detector) = cell(1,length(thresholds{idet}));
        
        for ithr = 1:length(thresholds{idet})
            
            switch TPFN
                case 'FN'
                    tbl = true_prop.(detector){ithr};
                case 'true'
                    tbl = true_prop.(detector){ithr};
                otherwise
                    tbl = pred_prop.(detector){ithr};
            end
            prop_names = fieldnames(tbl);
            prop_sess.(TPFN).mean.(detector){ithr} = {};
            prop_sess.(TPFN).median.(detector){ithr} = {};
            prop_sess.(TPFN).std.(detector){ithr} = {};
                
            for iprop = 1:width(tbl)
                prop = prop_names{iprop};
                prop_sess.(TPFN).mean.(detector){ithr}.(prop) = [];
                prop_sess.(TPFN).median.(detector){ithr}.(prop) = [];
                prop_sess.(TPFN).std.(detector){ithr}.(prop) = [];
            
                for isess = 1:max(tbl.session)

                    switch TPFN
                        case 'pred'
                            prop_sess_TPFN = tbl{tbl.session==isess, iprop};
                        case 'TP'
                            prop_sess_TPFN = tbl{(tbl.session==isess) & (tbl.TP==1), iprop};
                        case 'FP'
                            prop_sess_TPFN = tbl{(tbl.session==isess) & (tbl.TP==0), iprop};
                        case 'true'
                            prop_sess_TPFN = tbl{tbl.session==isess, iprop};
                        case 'FN'
                            prop_sess_TPFN = tbl{(tbl.session==isess) & (tbl.FN==1), iprop};
                    end
                    
                    
                    % Mean
                    prop_sess.(TPFN).mean.(detector){ithr}.(prop) = [prop_sess.(TPFN).mean.(detector){ithr}.(prop); nanmean(prop_sess_TPFN)];
                    % Median
                    prop_sess.(TPFN).median.(detector){ithr}.(prop) = [prop_sess.(TPFN).median.(detector){ithr}.(prop); nanmedian(prop_sess_TPFN)];
                    % Std
                    prop_sess.(TPFN).std.(detector){ithr}.(prop) = [prop_sess.(TPFN).std.(detector){ithr}.(prop); nanstd(prop_sess_TPFN)];
                end
            end
            
            % To table
            prop_sess.(TPFN).mean.(detector){ithr} = struct2table(prop_sess.(TPFN).mean.(detector){ithr});
            prop_sess.(TPFN).median.(detector){ithr} = struct2table(prop_sess.(TPFN).median.(detector){ithr});
            prop_sess.(TPFN).std.(detector){ithr} = struct2table(prop_sess.(TPFN).std.(detector){ithr});
            
        end
    end
end

save(fullfile(SavePath,'all_properties_sess.mat'), 'prop_sess', 'TPFN_names', 'detectors', 'thresholds', 'dirSessions')

