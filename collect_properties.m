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

% Filters to test
%detectors = {'butter', 'besselfir', 'cnn32'};
detectors = {'butter', 'cnn32'};
%thresholds = {2:8, 2:8, 0.1:0.1:0.9};
thresholds = {2:8, 0.1:0.1:0.9};

% Properties of all ripples 
pred_prop = {};
true_prop = {};
for idet = 1:length(detectors) 
    pred_prop.(detectors{idet}) = cell(1,length(thresholds{idet}));
    true_prop.(detectors{idet}) = cell(1,length(thresholds{idet}));
end

for isess = 1:length(dirSessions)
    dirSession = dirSessions{isess};
    
    fprintf('\n\n  > DATA: %s\n',dirSession);
    dirData = fullfile(dirAndrea, dirSession);
    
    for idet = 1:length(detectors)        
        detector = detectors{idet};
        disp(detector);
        for ithr = 1:length(thresholds{idet})
            thr = thresholds{idet}(ithr);
            load(fullfile(dirData, 'events', ['events_' detector '_thr', num2str(thr) '_metrics_win.mat']), 'properties') 
            
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

save('all_properties.mat', 'pred_prop', 'true_prop', 'detectors', 'thresholds', 'dirSessions')

%%

% Load
load('all_properties.mat')
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

save('all_properties_sess.mat', 'prop_sess', 'TPFN_names', 'detectors', 'thresholds', 'dirSessions')

