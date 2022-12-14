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
load(fullfile(dirProperties,'all_properties_sess.mat'));

% What to plot
prop_names = {'frequency', 'power', 'SRI', 'entropy'};
statistics = {'mean'};%, 'median'};
n_props = length(prop_names);
n_detectors = length(detectors);

%% Threshold curves, no stats (no call to group stats)


%for iTPFN = 1:length(TPFN_names)
    TPFN = 'TP';

    for istat = 1:length(statistics)
        stat = statistics{istat};

        figure('pos', [100 100 1600 1200])
        sgtitle([TPFN ' detections - ' stat ' per session'])
        for idet = 1:n_detectors
            detector = detectors{idet};
            n_thrs= length(thresholds{idet});
            colors = makeColorMap([.2 .4 .7], [.7 .4 .8], [.8 .1 .4], n_thrs);
            for iprop = 1:n_props
                property = prop_names{iprop};
                
                % Plot
                subplot(n_props, n_detectors, ((iprop-1)*n_detectors + idet)), hold on
                dthresh = mean(diff(thresholds{idet}))/n_thrs;
                
                % Gather all properties
                % n_thrs = length(thresholds{idet}); % This is moved to the
                % outer loop, al TP,FP etc are extracted with the same
                % thesholds
                
                prop_values = cell(1,n_thrs);
                median_prop = nan(1,n_thrs);
                ic95_prop = nan(2,n_thrs);
                for ithr = 1:n_thrs
                    if isempty(prop_sess.(TPFN).(stat).(detector){ithr})
                        continue
                    end
                    prop_values{ithr} = prop_sess.(TPFN).(stat).(detector){ithr}.(property);
                    median_prop(ithr) = nanmedian(prop_values{ithr});
                    ic95_prop(:,ithr) = [prctile(prop_values{ithr},25); prctile(prop_values{ithr},75)];
                    % Si comento los plots de los puntos individuales igual
                    % no hay problema con que se desplacen los ejes del
                    % boxplot, y salen mas bonitas las gr?ficas
                    % plot(thresholds{idet}(ithr), prop_values{ithr}, '.', 'color', [.5 .5 .5])
                    % Original: 
                    plot(thresholds{idet}(ithr) + (rand(1,length(prop_values{ithr}))-0.5)*dthresh, prop_values{ithr}, '.', 'color', [.5 .5 .5])

                end
                
                plot(thresholds{idet}, median_prop, 'k')
                plot([thresholds{idet}; thresholds{idet}], [ic95_prop(1,:); ic95_prop(2,:)], 'k')
                
                %groupStats(prop_values, [], 'inAxis', true, 'color', colors(1:n_thrs,:),'sigStar', false)
                % The points are moved with respect to the plot boxes. Ask
                % andrea
                
                
                % Axis
                if iprop==1, title(detector), end
                if idet==1, ylabel(property), end
                if iprop==n_props, xlabel('Threshold'), end
                switch property
                    case 'frequency'
                        set(gca, 'ylim', [80 200])
                    case 'power'
                        set(gca,'yscale','log', 'ylim', [0 2.5e6])
                    case 'duration'
                        set(gca, 'ylim', [0 0.1])
                    case 'SRI'
                        set(gca, 'ylim', [0.02 0.12])
                    case 'entropy'
                        set(gca, 'ylim', [0.5 4])
                end
            end    
        end
        saveas(gcf,fullfile(dirProperties, 'images',['compare_' stat '_properties_sess_' TPFN '.png']));
    end
%end

%% Threshold curves + stats
% Provisional, mientras busco una solucion a lo de los th de la 
thresholds={linspace(0.1,0.9,9),linspace(0.1,0.9,9),linspace(0.1,0.8,8),linspace(0.1,0.9,9),linspace(0.1,0.9,9) }
% colors = makeColorMap([.2 .4 .7], [.7 .4 .8], [.8 .1 .4], 9);
% for iTPFN = 1:length(TPFN_names)
colors=[25/255 146/255 81/255;
          174/255 2/255 128/255;
          255/255 91/255 34/255;
          255/255 190/255 13/255;
          47/255,182/255,206/255];
    TPFN = 'TP';

    for istat = 1:length(statistics)
        stat = statistics{istat};

        figure('pos', [100 100 1600 1200])
        sgtitle([TPFN ' detections - ' stat ' per session'])
        for idet = 1:n_detectors
            detector = detectors{idet};
            n_thrs= length(thresholds{idet});
            for iprop = 1:n_props
                property = prop_names{iprop};
                
                % Plot
                subplot(n_props, n_detectors, (iprop-1)*n_detectors + idet), hold on
                % OG: subplot(n_detectors, n_props, (idet-1)*n_props + iprop), hold on
                dthresh = mean(diff(thresholds{idet}))/3;
                
                % Gather all properties
                n_thrs = length(thresholds{idet});
                prop_values = cell(1,n_thrs+1);
                median_prop = nan(1,n_thrs+1);
                ic95_prop = nan(2,n_thrs+1);
                % Para colores
                color_ind=zeros(n_thrs+1,3);
                
                for ithr = 1:n_thrs
                    if isempty(prop_sess.(TPFN).(stat).(detector){ithr})
                        continue
                    end
                    prop_values{ithr} = prop_sess.(TPFN).(stat).(detector){ithr}.(property);
                    median_prop(ithr) = nanmedian(prop_values{ithr});
                    ic95_prop(:,ithr) = [prctile(prop_values{ithr},25); prctile(prop_values{ithr},75)];
                    color_ind(ithr,:)=colors(idet,:)*(ithr+10)/(n_thrs+10);
                    plot(ithr + (rand(1,length(prop_values{ithr}))-0.5)*0.3, prop_values{ithr}, '.k')
                end
                % Extra column for ground truth
                prop_values{end}=prop_sess.true.(stat).(detector){1}.(property);
                median_prop(end)=nanmedian(prop_values{end});
                ic95_prop(:,end)=[prctile(prop_values{end},25); prctile(prop_values{end},75)];
                color_ind(end,:)=[192/255, 192/255, 192/255];
                plot(ithr+1 + (rand(1,length(prop_values{end}))-0.5)*0.3, prop_values{end}, '.k')

                groupStats(prop_values, [], 'inAxis', true, 'color', color_ind,'sigStar',false,'labelSummary',false)
                
                
                % Axis
                if iprop==1 ,title(detector), end
                if idet==1, ylabel(property), end
                if iprop==n_props, xlabel('Threshold'), end
                switch property
                    case 'frequency'
                        set(gca, 'ylim', [120 180])
                    case 'power'
                        set(gca,'yscale','log', 'ylim', [0 1e3])
                    case 'duration'
                        set(gca, 'ylim', [0 0.2])
                    case 'SRI'
                        set(gca, 'ylim', [0 0.1])
                    case 'entropy'
                        set(gca, 'ylim', [0.5 4])
                end
            end    
        end
        saveas(gcf,fullfile(dirProperties, 'images',['groupstats_' stat '_properties_sess_' TPFN '.svg']))
    end
% end

%% All thresholds together + stats

colors = makeColorMap([.2 .4 .7], [.7 .4 .8], [.8 .1 .4], 3);
for iTPFN = 1:length(TPFN_names)
    TPFN = TPFN_names{iTPFN};

    for istat = 1:length(statistics)
        stat = statistics{istat};

        figure('pos', [100 100 1600 400])
        sgtitle([TPFN ' detections - ' stat ' per session'])
        for iprop = 1:n_props
            property = prop_names{iprop};

            % Plot
            subplot(1, n_props, iprop), hold on
            dthresh = mean(diff(thresholds{idet}))/3;
                
            prop_values = cell(1, n_detectors);
            for idet = 1:n_detectors
                detector = detectors{idet};
                
                % Gather all properties
                n_thrs = length(thresholds{idet});
                for ithr = 1:n_thrs
                    prop_values{idet} = [prop_values{idet}; prop_sess.(TPFN).(stat).(detector){ithr}.(property)];
                end
                plot(idet + (rand(1,length(prop_values{idet}))-0.5)*0.3, prop_values{idet}, '.k')
            end 
            groupStats(prop_values, [], 'inAxis', true, 'color', colors(1:3,:), 'plotData', true,'sigStar',false)


            % Axis
            title(property)
            %set(gca,'xtick',[1:3], 'xticklabels', detectors)
            switch property
                case 'frequency'
                    set(gca, 'ylim', [80 200])
                case 'power'
                    set(gca,'yscale','log', 'ylim', [0 6e6])
                case 'duration'
                    set(gca, 'ylim', [0 0.15])
                case 'SRI'
                    set(gca, 'ylim', [0 0.15])
                case 'entropy'
                    set(gca, 'ylim', [0.5 4])
            end
        end
        saveas(gcf,fullfile(dirProperties, 'images',['groupstats_allthresh_' stat '_properties_sess_' TPFN '.png']))
    end
end



%% From this point onwards is a specific for a filter or something

%% Good thresholds together + stats

good_threshs = {[3 4 5], [3 4 5], [6 7 8]};

colors = makeColorMap([.2 .4 .7], [.7 .4 .8], [.8 .1 .4], 3);
for iTPFN = 1:length(TPFN_names)-1
    TPFN = TPFN_names{iTPFN};

    for istat = 1:length(statistics)
        stat = statistics{istat};

        figure('pos', [100 100 1600 400])
        sgtitle([TPFN ' detections - ' stat ' per session'])
        for iprop = 1:n_props
            property = prop_names{iprop};

            % Plot
            subplot(1, n_props, iprop), hold on
            dthresh = mean(diff(thresholds{idet}))/3;
                
            prop_values = cell(1, n_detectors);
            for idet = 1:n_detectors
                detector = detectors{idet};
                
                % Gather all properties
                n_thrs = length(thresholds{idet});
                for ithr = good_threshs{idet}
                    prop_values{idet} = [prop_values{idet}; prop_sess.(TPFN).(stat).(detector){ithr}.(property)];
                end
                plot(idet + (rand(1,length(prop_values{idet}))-0.5)*0.3, prop_values{idet}, '.k')
            end 
            groupStats(prop_values, [], 'inAxis', true, 'color', colors(1:n_detectors,:), 'plotData', true)


            % Axis
            title(property)
            %set(gca,'xtick',[1:3], 'xticklabels', detectors)
            switch property
                case 'frequency'
                    set(gca, 'ylim', [80 200])
                case 'power'
                    set(gca,'yscale','log', 'ylim', [0 6e6])
                case 'duration'
                    set(gca, 'ylim', [0 0.15])
                case 'SRI'
                    set(gca, 'ylim', [0 0.15])
                case 'entropy'
                    set(gca, 'ylim', [0.5 4])
            end
        end
        saveas(gcf, ['images/groupstats_goodthresh_' stat '_properties_sess_' TPFN '.png'])
    end
end



%% Best global threshold + stats
%                6    6   0.8
best_threshs = {[5], [5], [8]};

iTPFN = 4;
TPFN = TPFN_names{iTPFN};
colors = makeColorMap([.2 .4 .7], [.7 .4 .8], [.8 .1 .4], 4);

for istat = 1:length(statistics)
    stat = statistics{istat};

    figure('pos', [100 100 1600 400])
    sgtitle(['All detections - ' stat ' per session'])
    for iprop = 1:n_props
        property = prop_names{iprop};

        % Plot
        subplot(1, n_props, iprop), hold on

        prop_values = cell(1, n_detectors+1);
        for idet = 1:n_detectors
            % Detectors
            detector = detectors{idet};
            ithr = best_threshs{idet};
            prop_values{idet} = [prop_values{idet}; prop_sess.(TPFN).(stat).(detector){ithr}.(property)];
            plot(idet + (rand(1,length(prop_values{idet}))-0.5)*0.3, prop_values{idet}, '.k')
        end 
        % True predictions
        idet = idet+1;
        prop_values{idet} = [prop_values{idet}; prop_sess.('true').(stat).(detector){ithr}.(property)];
        plot(idet + (rand(1,length(prop_values{idet}))-0.5)*0.3, prop_values{idet}, '.k')
        
        groupStats(prop_values, [], 'inAxis', true, 'color', colors(1:n_detectors+1,:), 'plotData', true)


        % Axis
        title(property)
        %set(gca,'xtick',[1:3], 'xticklabels', detectors)
        switch property
            case 'frequency'
                set(gca, 'ylim', [80 200])
            case 'power'
                set(gca,'yscale','log', 'ylim', [0 6e6])
            case 'duration'
                set(gca, 'ylim', [0 0.15])
            case 'SRI'
                set(gca, 'ylim', [0 0.15])
            case 'entropy'
                set(gca, 'ylim', [0.5 4])
        end
    end
    saveas(gcf, ['images/groupstats_bestthresh_' stat '_properties_sess_' TPFN '.png'])
end



%% Best global threshold + stats (no bessel)
%                6    6   0.8
best_threshs = {[5], [5], [8]};

iTPFN = 4;
TPFN = TPFN_names{iTPFN};
colors = makeColorMap([.2 .4 .7], [.7 .4 .8], [.8 .1 .4], 3);

for istat = 1:length(statistics)
    stat = statistics{istat};

    figure('pos', [100 100 1600 400])
    sgtitle(['All detections - ' stat ' per session'])
    for iprop = 1:n_props
        property = prop_names{iprop};

        % Plot
        subplot(1, n_props, iprop), hold on

        prop_values = cell(1, n_detectors);
        idets = [1 3];
        for idet = 1:n_detectors-1
            % Detectors
            detector = detectors{idets(idet)};
            ithr = best_threshs{idets(idet)};
            prop_values{idet} = [prop_values{idet}; prop_sess.(TPFN).(stat).(detector){ithr}.(property)];
            plot(idet + (rand(1,length(prop_values{idet}))-0.5)*0.3, prop_values{idet}, '.k')
        end 
        % True predictions
        idet = idet+1;
        prop_values{idet} = [prop_values{idet}; prop_sess.('true').(stat).(detector){ithr}.(property)];
        plot(idet + (rand(1,length(prop_values{idet}))-0.5)*0.3, prop_values{idet}, '.k')
        
        groupStats(prop_values, [], 'inAxis', true, 'color', colors(1:n_detectors,:), 'repeatedMeasures', true)


        % Axis
        title(property)
        %set(gca,'xtick',[1:3], 'xticklabels', detectors)
        switch property
            case 'frequency'
                set(gca, 'ylim', [100 180])
            case 'power'
                set(gca,'yscale','log', 'ylim', [2e5 16e5])
            case 'duration'
                set(gca, 'ylim', [0.02 0.08])
            case 'SRI'
                set(gca, 'ylim', [0.02 0.12])
            case 'entropy'
                set(gca, 'ylim', [0.5 4])
        end
    end
    saveas(gcf, ['images/groupstats_bestthresh_' stat '_properties_sess_' TPFN '.png'])
end