
% Load F1_curves from online filter
load(fullfile('/home/andrea/Projects/proyecto_ripples/figures/fig1_network/data', 'onlinefilter_F1curves.mat'), 'thresholds', 'F1_curves')
F1_curves_filter = F1_curves;
thresholds_filter = thresholds';
thresholds_filter_norm = thresholds_filter/std(thresholds_filter);

% Load F1_curves from online CNN
F1_curves_cnn = F1_curves_filter + randn(1,size(F1_curves_filter,2))/20;
idxsrand = randi(size(F1_curves_filter,2),1,6);
F1_curves_cnn(:,idxsrand) = flip(F1_curves_cnn (:,idxsrand));
thresholds_cnn = linspace(0.05, 0.95, size(F1_curves_cnn,1))';
thresholds_cnn_norm = thresholds_cnn/std(thresholds_cnn);

% Number of sessions
n_sess = size(F1_curves_filter, 2);

% Colors of filter and cnn
colors = [.7 .7 .4; .3 .5 .1];

%% F1 depending on threshold

% Filter
figure
hold on
fill([thresholds_filter; flip(thresholds_filter)], [mean(F1_curves_filter,2)+std(F1_curves_filter,1,2); flip(mean(F1_curves_filter,2)-std(F1_curves_filter,1,2)) ], 1, 'facecolor', colors(1,:), 'edgecolor', 'none', 'facealpha', 0.2)
plot(thresholds_filter, F1_curves_filter, 'color', [colors(1,:) .3])
plot(thresholds_filter, mean(F1_curves_filter,2), 'k', 'linewidth', 2)
xlabel('Filter thresholds (# stds)')
ylabel('F1')
title('Filter')

% CNN
figure
hold on
fill([thresholds_cnn; flip(thresholds_cnn)], [mean(F1_curves_cnn,2)+std(F1_curves_cnn,1,2); flip(mean(F1_curves_cnn,2)-std(F1_curves_cnn,1,2)) ], 1, 'facecolor', colors(2,:), 'edgecolor', 'none', 'facealpha', 0.2)
plot(thresholds_cnn, F1_curves_cnn, 'color', [colors(2,:) .3])
plot(thresholds_cnn, mean(F1_curves_cnn,2), 'k', 'linewidth', 2)
xlabel('CNN thresholds (prob ripple)')
ylabel('F1')
title('CNN')

% Filter + cnn
figure
hold on
% Filter
fill([thresholds_filter_norm; flip(thresholds_filter_norm)], [mean(F1_curves_filter,2)+std(F1_curves_filter,1,2); flip(mean(F1_curves_filter,2)-std(F1_curves_filter,1,2)) ], 1, 'facecolor', colors(1,:), 'edgecolor', 'none', 'facealpha', 0.2)
plot(thresholds_filter_norm, mean(F1_curves_filter,2), 'k', 'linewidth', 2)
% CNN
fill([thresholds_cnn_norm ;flip(thresholds_cnn_norm)], [mean(F1_curves_cnn,2)+std(F1_curves_cnn,1,2); flip(mean(F1_curves_cnn,2)-std(F1_curves_cnn,1,2)) ], 1, 'facecolor', colors(2,:), 'edgecolor', 'none', 'facealpha', 0.2)
plot(thresholds_cnn_norm, mean(F1_curves_cnn,2), 'k', 'linewidth', 2)
xlabel('Normalized thresholds')
ylabel('F1')
title('Filter and CNN')

%% Tresholds depending on F1

F1x = [0.0:0.2:1];
F1x_center = F1x(1:end-1) + mean(diff(F1x))/2;

% -- What proportion of thresholds achieve that F1? ----
n_thresh_filter = nan(length(F1x)-1, n_sess);
n_thresh_cnn = nan(length(F1x)-1, n_sess);
for iF1 = 1:length(F1x)-1
    for isess = 1:n_sess
        n_thresh_filter(iF1, isess) = sum(F1_curves_filter(:,isess)>=F1x(iF1) & F1_curves_filter(:,isess)<F1x(iF1+1));
        n_thresh_cnn(iF1, isess) = sum(F1_curves_cnn(:,isess)>=F1x(iF1) & F1_curves_cnn(:,isess)<F1x(iF1+1));
    end
end
prop_thresh_filter = n_thresh_filter/length(thresholds_filter);
prop_thresh_cnn = n_thresh_cnn/length(thresholds_cnn);

% Plot
figure, hold on
for iF1 = 1:length(F1x)-1
    boxplot([prop_thresh_filter(iF1,:)' prop_thresh_cnn(iF1,:)'], ...
        'colors',colors, 'boxstyle','filled', 'symbol', '.k',...
        'positions', F1x_center(iF1)+[-0.02 0.02], 'labels',F1x_center(iF1)+[-0.02 0.02])
    lines = findobj(gcf, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', 'w', 'linewidth',2);
    xlim([0 1])
    ylim([0 1])
end
set(gca,'xtick',F1x_center,'xticklabels',strsplit(sprintf('%.1f-%.1f ',[F1x(1:end-1);F1x(2:end)]), ' '))
xlabel('F1')
ylabel('Proportion of thresholds')



% Which thresholds achieve that F1?

% -- Mean value of thresholds achieve that F1 ----

% Thresholds below max F1
low_thresh_filter = nan(length(F1x)-1, n_sess);
low_thresh_cnn = nan(length(F1x)-1, n_sess);
% Thresholds over max F1
high_thresh_filter = nan(length(F1x)-1, n_sess);
high_thresh_cnn = nan(length(F1x)-1, n_sess);

for iF1 = 1:length(F1x)-1
    for isess = 1:n_sess
        % Filter
        idxs_inF1 = F1_curves_filter(:,isess)>=F1x(iF1) & F1_curves_filter(:,isess)<F1x(iF1+1);
        [~, idxmaxF1] = max(F1_curves_filter(:,isess));
        idxs_high = thresholds_filter > idxmaxF1;
        low_thresh_filter(iF1, isess) = mean(thresholds_filter_norm(idxs_inF1 & ~idxs_high));
        high_thresh_filter(iF1, isess) = mean(thresholds_filter_norm(idxs_inF1 & idxs_high));
        % CNN
        idxs_inF1 = F1_curves_cnn(:,isess)>=F1x(iF1) & F1_curves_cnn(:,isess)<F1x(iF1+1);
        [~, idxmaxF1] = max(F1_curves_cnn(:,isess));
        idxs_high = thresholds_cnn > idxmaxF1;
        low_thresh_cnn(iF1, isess) = mean(thresholds_cnn_norm(idxs_inF1 & ~idxs_high));
        high_thresh_cnn(iF1, isess) = mean(thresholds_cnn_norm(idxs_inF1 & idxs_high));
    end
end

% Plot low
figure, hold on
for iF1 = 1:length(F1x)-1
    boxplot([low_thresh_filter(iF1,:)' low_thresh_cnn(iF1,:)'], ...
        'colors',colors, 'boxstyle','filled', 'symbol', '.k',...
        'positions', F1x_center(iF1)+[-0.02 0.02], 'labels',F1x_center(iF1)+[-0.02 0.02])
    lines = findobj(gcf, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', 'w', 'linewidth',2);
    xlim([0 1])
    ylim([0 4])
end
set(gca,'xtick',F1x_center,'xticklabels',strsplit(sprintf('%.1f-%.1f ',[F1x(1:end-1);F1x(2:end)]), ' '))
xlabel('F1')
ylabel('(norm) threshold value')

% Plot low
figure, hold on
for iF1 = 1:length(F1x)-1
    boxplot([high_thresh_filter(iF1,:)' high_thresh_cnn(iF1,:)'], ...
        'colors',colors, 'boxstyle','filled', 'symbol', '.k',...
        'positions', F1x_center(iF1)+[-0.02 0.02], 'labels',F1x_center(iF1)+[-0.02 0.02])
    lines = findobj(gcf, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', 'w', 'linewidth',2);
    xlim([0 1])
    ylim([0 4])
end
set(gca,'xtick',F1x_center,'xticklabels',strsplit(sprintf('%.1f-%.1f ',[F1x(1:end-1);F1x(2:end)]), ' '))
xlabel('F1')
ylabel('(norm) threshold value')


