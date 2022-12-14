clc; clear; close all;
dirName = fileparts(matlab.desktop.editor.getActiveFilename);
cd(dirName)

%  ------------- 
%  | LOAD INFO |
%  -------------

dirProject='C:\Septiembre-Octubre\Ripple-Properties';
% Location of the all_properties.mat to be analized
dirTest='Paper';
dirProperties=fullfile(dirProject,dirTest);
load(fullfile(dirProperties,'all_properties.mat'));

% What to plot
prop_names = {'frequency', 'power',  'entropy','SRI'};
n_props = length(prop_names);
n_detectors = length(detectors);
colors = makeColorMap([.2 .4 .7], [.7 .4 .8], [.8 .1 .4], 9);
if ~exist(fullfile(dirProperties, 'images'), 'dir')
        mkdir(fullfile(dirProperties, 'images'))
end
%% --- All detections ----
detectors = {'XGBOOST','SVM','LSTM','CNN2D','CNN1D'};
figure('pos', [100 100 1300 1100])
sgtitle('All detections')

for idet = 1:n_detectors
    detector = detectors{idet};
    for iprop = 1:n_props
        property = prop_names{iprop};
        
        % Plot
        subplot(n_props, n_detectors, ((iprop-1)*n_detectors + idet)), hold on
        dthresh = mean(diff(thresholds{idet}))/4;

        % Gather all properties
        n_thrs = length(thresholds{idet});
        prop_values = cell(1,n_thrs);
        median_prop = nan(1,n_thrs);
        ic95_prop = nan(2,n_thrs);
        for ithr = 1:n_thrs
            if isempty(pred_prop.(detector){ithr})
                continue
            end
            prop_values{ithr} = pred_prop.(detector){ithr}.(property);
            
            median_prop(ithr) = nanmedian(prop_values{ithr});
            ic95_prop(:,ithr) = [prctile(prop_values{ithr},25); prctile(prop_values{ithr},75)];
            %scatter(thresholds{idet}(ithr) + (rand(1,length(prop_values{ithr}))-0.5)*dthresh, prop_values{ithr}, 12, ...
            %    'markeredgecolor', 'none', 'markerfacecolor', [1 1 1]*0.8, 'markerfacealpha', 0.01)
            % Added 
            % plot(thresholds{idet}(ithr), prop_values{ithr}, '.', 'color', [.5 .5 .5])
        end
        plot(thresholds{idet}, median_prop, 'k')
        plot([thresholds{idet}; thresholds{idet}], [ic95_prop(1,:); ic95_prop(2,:)], 'k')
        
        %groupStats(prop_values, [], 'inAxis', true, 'color', colors(1:n_thrs,:))
        
        
        % Axis
        if idet==1, ylabel(property), end
        if iprop==1, title(detector), end
        if iprop==n_props, xlabel('Threshold'), end
        switch property
            case 'frequency'
                set(gca,'yscale','log', 'ylim', [80 300])
            case 'power'
                set(gca,'yscale','log', 'ylim', [0 2.5e6])
            case 'duration'
                set(gca, 'ylim', [0 0.1])
            case 'SRI'
                set(gca, 'ylim', [0 0.2])
            case 'entropy'
                set(gca, 'ylim', [0 4])
        end
    end    
end
saveas(gcf,fullfile(dirProperties, 'images','compare_properties_alldetections.png'))



%% --- True positives ----

figure('pos', [100 100 1300 1100])
sgtitle('True positives')
for idet = 1:n_detectors
    detector = detectors{idet};
    for iprop = 1:n_props
        property = prop_names{iprop};

        % Plot
        subplot(n_props, n_detectors, (iprop-1)*n_detectors + idet), hold on
        dthresh = mean(diff(thresholds{idet}))/4;
        
        % Gather all properties
        n_thrs = length(thresholds{idet});
        prop_values = cell(1,n_thrs);
        median_prop = nan(1,n_thrs);
        ic95_prop = nan(2,n_thrs);
        for ithr = 1:n_thrs
            if isempty(pred_prop.(detector){ithr})
                continue
            end
            idxs_TPs = pred_prop.(detector){ithr}.TP==1;
            prop_values{ithr} = pred_prop.(detector){ithr}.(property)(idxs_TPs);
            median_prop(ithr) = nanmedian(prop_values{ithr});
            ic95_prop(:,ithr) = [prctile(prop_values{ithr},25); prctile(prop_values{ithr},75)];
            %scatter(thresholds{idet}(ithr) + (rand(1,length(prop_values{ithr}))-0.5)*dthresh, prop_values{ithr}, 12, ...
            %    'markeredgecolor', 'none', 'markerfacecolor', [1 1 1]*0.8, 'markerfacealpha', 0.01)
        end
        plot(thresholds{idet}, median_prop, 'k')
        plot([thresholds{idet}; thresholds{idet}], [ic95_prop(1,:); ic95_prop(2,:)], 'k')
        
        %groupStats(prop_values, [], 'inAxis', true, 'color', colors(1:n_thrs,:))
        
        
        % Axis
        if idet==1, ylabel(property), end
        if iprop==1, title(detector), end
        if iprop==n_props, xlabel('Threshold'), end
        switch property
            case 'frequency'
                set(gca,'yscale','log', 'ylim', [80 300])
            case 'power'
                set(gca,'yscale','log', 'ylim', [0 2.5e6])
            case 'duration'
                set(gca, 'ylim', [0 0.1])
            case 'SRI'
                set(gca, 'ylim', [0 0.2])
            case 'entropy'
                set(gca, 'ylim', [0 4])
        end
    end    
end
saveas(gcf,fullfile(dirProperties, 'images','compare_properties_TPs.png'))



%% --- False positives ----

figure('pos', [100 100 1300 1100])
sgtitle('False positives')
for idet = 1:n_detectors
    detector = detectors{idet};
    for iprop = 1:n_props
        property = prop_names{iprop};
        
        % Plot
        subplot(n_props, n_detectors, (iprop-1)*n_detectors + idet), hold on
        dthresh = mean(diff(thresholds{idet}))/4;
        
        % Gather all properties
        n_thrs = length(thresholds{idet});
        prop_values = cell(1,n_thrs);
        median_prop = nan(1,n_thrs);
        ic95_prop = nan(2,n_thrs);
        for ithr = 1:n_thrs
            idxs_FPs = pred_prop.(detector){ithr}.TP==0;
            prop_values{ithr} = pred_prop.(detector){ithr}.(property)(idxs_FPs);
            median_prop(ithr) = nanmedian(prop_values{ithr});
            ic95_prop(:,ithr) = [prctile(prop_values{ithr},25); prctile(prop_values{ithr},75)];
            %scatter(thresholds{idet}(ithr) + (rand(1,length(prop_values{ithr}))-0.5)*dthresh, prop_values{ithr}, 12, ...
            %    'markeredgecolor', 'none', 'markerfacecolor', [1 1 1]*0.8, 'markerfacealpha', 0.01)
        end
        plot(thresholds{idet}, median_prop, 'k')
        plot([thresholds{idet}; thresholds{idet}], [ic95_prop(1,:); ic95_prop(2,:)], 'k')
        
        %groupStats(prop_values, [], 'inAxis', true, 'color', colors(1:n_thrs,:))
        
        
        % Axis
        if idet==1, ylabel(property), end
        if iprop==1, title(detector), end
        if iprop==n_props, xlabel('Threshold'), end
        switch property
            case 'frequency'
                set(gca,'yscale','log', 'ylim', [80 300])
            case 'power'
                set(gca,'yscale','log', 'ylim', [0 2.5e6])
            case 'duration'
                set(gca, 'ylim', [0 0.1])
            case 'SRI'
                set(gca, 'ylim', [0 0.2])
            case 'entropy'
                set(gca, 'ylim', [0 4])
        end
    end    
end
saveas(gcf,fullfile(dirProperties, 'images','compare_properties_FPs.png'))



%% --- False negatives ----

figure('pos', [100 100 1300 1100])
sgtitle('False negatives')
for idet = 1:n_detectors
    detector = detectors{idet};
    for iprop = 1:n_props
        property = prop_names{iprop};
        
        % Plot
        subplot(n_props, n_detectors, (iprop-1)*n_detectors + idet), hold on
        dthresh = mean(diff(thresholds{idet}))/4;
        
        % Gather all properties
        n_thrs = length(thresholds{idet});
        prop_values = cell(1,n_thrs);
        median_prop = nan(1,n_thrs);
        ic95_prop = nan(2,n_thrs);
        for ithr = 1:n_thrs
            idxs_FNs = true_prop.(detector){ithr}.FN==1;
            prop_values{ithr} = true_prop.(detector){ithr}.(property)(idxs_FNs);
            median_prop(ithr) = nanmedian(prop_values{ithr});
            ic95_prop(:,ithr) = [prctile(prop_values{ithr},25); prctile(prop_values{ithr},75)];
            %scatter(thresholds{idet}(ithr) + (rand(1,length(prop_values{ithr}))-0.5)*dthresh, prop_values{ithr}, 12, ...
            %    'markeredgecolor', 'none', 'markerfacecolor', [1 1 1]*0.8, 'markerfacealpha', 0.01)
        end
        plot(thresholds{idet}, median_prop, 'k')
        plot([thresholds{idet}; thresholds{idet}], [ic95_prop(1,:); ic95_prop(2,:)], 'k')
        
        %groupStats(prop_values, [], 'inAxis', true, 'color', colors(1:n_thrs,:))
        
        
        % Axis
        if idet==1, ylabel(property), end
        if iprop==1, title(detector), end
        if iprop==n_props, xlabel('Threshold'), end
        switch property
            case 'frequency'
                set(gca,'yscale','log', 'ylim', [80 200])
            case 'power'
                set(gca,'yscale','log', 'ylim', [0 8e6])
            case 'duration'
                set(gca, 'ylim', [0 0.1])
            case 'SRI'
                set(gca, 'ylim', [0 0.2])
            case 'entropy'
                set(gca, 'ylim', [0 4])
        end
    end    
end
saveas(gcf,fullfile(dirProperties, 'images','compare_properties_FNs.png'))