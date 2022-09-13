clc; clear; close all;
dirName = fileparts(matlab.desktop.editor.getActiveFilename);
cd(dirName)

%  ------------- 
%  | LOAD INFO |
%  -------------

load('all_properties_sess.mat')

% What to plot
prop_names = {'frequency', 'power', 'duration', 'SRI', 'entropy'};
statistics = {'mean', 'median'};
n_detectors = length(detectors);

%% Threshold curves

iTPFN = 1; % True positives
istat = 1; % Mean

TPFN = TPFN_names{iTPFN};
stat = statistics{istat};
props2plot = [1 2 4 5];
n_props = length(props2plot);

for idet = 1:2 %[1 3]
    detector = detectors{idet};
    
    
    figure('pos', [100 100 1300 250])
    sgtitle([ detector ' - ' TPFN ' detections - ' stat ' per session'])

    for iprop = 1:length(props2plot)
        property = prop_names{props2plot(iprop)};

        % Plot
        subplot(1, n_props, iprop), hold on
        dthresh = mean(diff(thresholds{idet}))/3;
        iprop = props2plot(iprop);

        % Gather all properties
        n_thrs = length(thresholds{idet});
        prop_values = cell(1,n_thrs);
        median_prop = nan(1,n_thrs);
        ic95_prop = nan(2,n_thrs);
        for ithr = 1:n_thrs
            prop_values{ithr} = prop_sess.(TPFN).(stat).(detector){ithr}.(property);
            if strcmp(property, 'duration')
                prop_values{ithr} = prop_values{ithr}*1000;
            end
            median_prop(ithr) = nanmedian(prop_values{ithr});
            ic95_prop(:,ithr) = [prctile(prop_values{ithr},25); prctile(prop_values{ithr},75)];
            plot(ithr + (rand(1,length(prop_values{ithr}))-0.5)*0.3, prop_values{ithr}, '.k')
        end
        
        % True predictions
        ithr = ithr+1;
        prop_values{ithr} = prop_sess.('true').(stat).(detector){1}.(property);
        if strcmp(property, 'duration')
            prop_values{ithr} = prop_values{ithr}*1000;
        end
        plot(ithr + (rand(1,length(prop_values{ithr}))-0.5)*0.3, prop_values{ithr}, '.k')
    
        % Colors
        if idet < 2
            colors = makeColorMap([251 194 89]/255, [254 127 12]/255, [222 74 9]/255, n_thrs);
        else
            colors = makeColorMap([143 198 89]/255, [65 124 60]/255, [26 78 20]/255, n_thrs);
        end
        colors = [colors; 0.5*[1 1 1]];
    
        % Add Ground truth
        groupStats(prop_values, [], 'inAxis', true, 'color', colors)
        


        % Axis
        title(property)
        if iprop==1, ylabel(detector), end
        switch property
            case 'frequency'
                set(gca, 'ylim', [100 170])
            case 'power'
                set(gca,'yscale','log', 'ylim', [0.5e1 2e3])
            case 'duration'
                set(gca, 'ylim', [0 100])
            case 'SRI'
                set(gca, 'ylim', [0.00 0.08])
            case 'entropy'
                set(gca, 'ylim', [0 3.5])
        end
    end    
    
    saveas(gcf, ['images/svg' detector '_groupstats_' stat '_properties_sess_' TPFN '.svg'])
end

