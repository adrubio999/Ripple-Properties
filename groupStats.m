
function [stats] = groupStats(y,group,varargin)
% Descriptive and mean/median difference analysis, with serveral plot
% options.
% 
% INPUTS
%    'y'            N x 1, sample data, specified as a numeric vector. If cell is provied, 
%                       (1 x M) it assumes that each element is a group.
%    'group'        N x M, grouping vector. If empty, or not provided, try to get groups
%                       from 'y' columns. If M is > 1, perform M ways
%                       analysis. Otherwise, 1 way.
% <optional>
%    'color'        M x 3, RGB code for groups.
%    'doPlot'       Default True.
%    'inAxis'       Plot in an arealdy open axis, without statistical summary (default false)
%    'orientation'  horizontal or vertical (default)
%    'style'        edge or face (default)
%    'showOutliers' true or false (default)
%    'labelSummary' true (default) or false
%    'sigStar'      Add significance stars, default true
%    'sigStarTest'  Stats test used for significance stars, by default 'KW'
%       (other option: 'anova')
%    'plotType'     Default 'boxplot', 'barSEM', 'barStd', 'BoxLinesSEM',
%                       'BoxLinesStd','dispersionStd' 
%    'plotData'     Plot data points, default false.
%    'repeatedMeasures' Default, false
% 
% OUTPUS
%    'stats'    Structure containing the statistical test results.
%    .
%    .
% Manu Valero - BuzsakiLab 2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parse options
p = inputParser;
addParameter(p,'color',[],@isnumeric);
addParameter(p,'doPlot',true,@islogical);
addParameter(p,'inAxis',false,@islogical);
addParameter(p,'orientation','vertical',@ischar);
addParameter(p,'style','face')
addParameter(p,'showOutliers',false,@islogical)
addParameter(p,'labelSummary',true,@islogical);
addParameter(p,'sigStar',true,@islogical);
addParameter(p,'sigStarTest','KW',@ischar);
addParameter(p,'plotType','boxplot',@ischar);
addParameter(p,'plotData',false,@islogical);
addParameter(p,'repeatedMeasures',false,@islogical);

parse(p,varargin{:});
color = p.Results.color;
doPlot = p.Results.doPlot;
inAxis = p.Results.inAxis;
orientation = p.Results.orientation;
style = p.Results.style;
showOutliers = p.Results.showOutliers;
labelSummary = p.Results.labelSummary;
addSigStar = p.Results.sigStar;
sigStarTest = p.Results.sigStarTest;
plotType = p.Results.plotType;
plotData = p.Results.plotData;
repeatedMeasures = p.Results.repeatedMeasures;

% Dealing with inputs
if size(y,1) < size(y,2)
    y = y';
end

if ~exist('group') || isempty(group)
    if iscell(y)
        dataC = y;
        y = []; group = [];
        for ii = 1:length(dataC)
            d = dataC{ii};
            if size(d,1) < size(d,2)
                d = d';
            end
            y = [y ; d];
            group = [group; ii * ones(size(d))];
        end
        clear dataC
    else
        error('Input format not recognized.')
    end
else
    if size(group,1) < size(group,2)
        group = group';
    end
end

if size(group,2) > 1
    if strcmpi(plotType,'BoxLinesSEM') || strcmpi(plotType,'BoxLinesStd')
        Disp('Plot type no supported. Unsing boxplot instead...');
    end
    sigStarTest = 'anova';
    groupAll = group;
    for ii = 1:size(groupAll,2)
        group(:,ii) = groupAll(:,ii) * 10^(size(groupAll,2)-ii);
    end
    group = sum(group,2);
    ind=sort(unique(group));  
    indAll = [];
    for ii = 1:size(groupAll,2)-1
        indAll = [indAll mod(ind,10^(size(groupAll,2)-ii))];        
    end
    if size(indAll,2)>1
        for ii = 1:size(indAll,2)-1
            indAll(:,ii) = indAll(:,ii) - indAll(:,ii+1:end);
        end
    end 
    indAll = [ind-sum(indAll,2) indAll];
else
    groupAll = group;
    ind=sort(unique(group));                                               % get group info
end

if isempty(color) && doPlot                                                % colors
    color=jet(length(ind));
end

if size(color,1) == 1
    color = repmat(color,length(ind),1);
end

for i=1:length(ind)                                                        % grouping data
    yC{i}=y(group==ind(i));
end

stats.groupsIndex = ind;

if showOutliers
    showOutliers = 'on';
else
    showOutliers = 'off';
end

if strcmpi(style, 'face')
    style = zeros(size(ind));
elseif strcmpi(style, 'edge')
    style = ones(size(ind));
end

% DESCRIPTIVE 
for ii = 1 : size(yC,2)
    fprintf('%i %8.2f +/- %1.2f \n', ind(ii),nanmean(yC{ii}), nanstd(yC{ii}));
    stats.descriptive.groupsIndex(ii) = ind(ii);
    stats.descriptive.mean(ii) =  nanmean(yC{ii});
    stats.descriptive.median(ii) = nanmedian(yC{ii});
    stats.descriptive.std(ii) = nanstd(yC{ii});
    stats.descriptive.SEM(ii) = nanstd(yC{ii})/sqrt(length(yC{ii}));
    stats.descriptive.q25(ii) = prctile(yC{ii},25);
    stats.descriptive.q75(ii) = prctile(yC{ii},75);
end

% normality
for ii=1:length(ind)
    [HN(ii),pN(ii),SN(ii)]=kstest(yC{ii});
    stats.normality.kstest.p(ii) = pN(ii);
    stats.normality.kstest.h(ii) = HN(ii);
    stats.normality.kstest.kstats(ii) = SN(ii);
    stats.normality.groupsIndex{ii} = num2str(ind(ii));
end
ii = ii + 1;
[HN(ii),pN(ii),SN(ii)]=kstest(y);
stats.normality.groupsIndex{ii} = 'all';
stats.normality.kstest.p(ii) = pN(ii);
stats.normality.kstest.kstats(ii) = SN(ii);
stats.normality.isNormal = ~HN;
stats.normality.test = 'One-sample Kolmogorov-Smirnov test';
isNorm=~HN(1:ii-1);

% homocedasticity
[pvar,hvar]=vartestn(y,group,'off');
stats.homoscedasticity.p = pvar;
stats.homoscedasticity.df = hvar.df;
stats.homoscedasticity.chisq = hvar.chisqstat;
stats.homoscedasticity.isHomosce = (pvar>.05);

% mean/median differences
if repeatedMeasures
    repet = repmat((1:length(find(group == min(group))))',length(ind),1);
    [pA,tblA,statsA]=anovan(y,[group repet],'random',2,'display','off');
    pA = pA(1);
    % sigStarTest = 'anova';

    X = reshape(y,[length(find(group==ind(1))) length(ind)]);
    removeNaN = find(isnan(mean(X,2))); X(removeNaN,:) = [];
    [pK,tblK,statsK]=friedman(X,1,'off');
    
    stats.r_anova.p = pA;
    stats.r_anova.tbl = tblA;
    stats.r_anova.stats = statsA;

    stats.friedman.p = pK;
    stats.friedman.tbl = tblK;
    stats.friedman.stats = statsK;
else
    if size(groupAll,2) > 1                                                % more than 1 way only anovan
        code = mat2cell(groupAll, size(groupAll,1), ones(1,size(groupAll,2)));
        [pA,tblA,statsA]=anovan(y,code,'model','interaction','display','off');
        
        stats.anova.p = pA;
        stats.anova.tbl = tblA;
        stats.anova.stats = statsA;
    else        
        [pA,tblA,statsA]=anova1(y,group,'off');
        [pK,tblK,statsK]=kruskalwallis(y,group,'off');

        stats.anova.p = pA;
        stats.anova.tbl = tblA;
        stats.anova.stats = statsA;

        stats.kruskalWallis.p = pK;
        stats.kruskalWallis.tbl = tblK;
        stats.kruskalWallis.stats = statsK;
    end
end

% post-hocs
if size(groupAll,2) < 2    
    anph=multcompare(statsA,'CType','tukey-kramer','Display','off');
    kkph=multcompare(statsK,'Display','off');

    if repeatedMeasures
        stats.r_anova.posthoc.tbl = anph;
        stats.r_anova.posthoc.test = 'tukey-kramer';
        stats.friedman.posthoc.tbl = kkph;
        stats.friedman.posthoc.test = 'tukey-kramer';
    else
        stats.anova.posthoc.tbl = anph;
        stats.anova.posthoc.test = 'tukey-kramer';
        stats.kruskalWallis.posthoc.tbl = kkph;
        stats.kruskalWallis.posthoc.test = 'tukey-kramer';
    end
else
    anph=multcompare(statsA,'CType','tukey-kramer','Display','on','Dimension',[1:size(groupAll,2)]);
    % change numbers
    posLin = [1:length(ind)];                                              
    c=unique(indAll(:,end));
    postMult = [];
    for ii = 1:length(c)
        postMult = [postMult posLin(indAll(:,2)==c(ii))];
    end       

    % 1 2 3 4 5 6    to 1 3 5 2 4 6
    gs = anph(:,1:2);
    codeMult = anph(:,1:2);
    codeMultInd = anph(:,1:2);
    for ii = 1:length(posLin)
        codeMult(find(gs==posLin(ii))) = postMult(ii); %  postMult posLin
    end
    codeMultInd = codeMult;
    for ii = 1:length(posLin)
        codeMultInd(find(codeMult==posLin(ii))) = ind(ii); %  postMult posLin
    end
    anph(:,1:2) = codeMult;
    anphInd = [(codeMultInd) anph(:,3:end)];
    anph = sortrows(anph,[1 2]);
    anphInd = sortrows(anphInd,[1 2]);
    
    stats.anova.posthoc.tbl = anphInd;
    stats.anova.posthoc.test = 'tukey-kramer';
 end

if pvar>=0.05
    varDiff='homocedasticity';
else
    varDiff='heterocedasticity';
end

% plots
if doPlot
    if ~inAxis
        figure;
    end
    if strcmpi(plotType,'boxplot')
        color=flip(color,1);
        if size(groupAll,2) < 2
            pos = [1:length(ind)];
        else
            pos = [1:length(ind)];                                         % group by the first variable
            pos = (cumsum([0; diff(indAll(:,1))/(1*10^(size(groupAll,2)-1))])/2)' + pos;
        end
        
        boxplot(y,group,'colors',[0 0 0],'symbol','o','width',.8,'orientation',orientation,'positions',pos);
        h = findobj(gca,'Tag','Box');
        h1=findobj(gca,'Tag','Upper Whisker');
        h2=findobj(gca,'Tag','Lower Whisker');
        h3=findobj(gca,'Tag','Upper Adjacent Value');
        h4=findobj(gca,'Tag','Lower Adjacent Value');
        h5=findobj(gca,'Tag','Median');
        h6=findobj(gca,'Tag','Outliers');

        if any(ind==0)
            ind = ind + 1;
        end
        if size(ind,1) > size(ind,2)
            ind = ind';
        end
        el = [1:length(ind)];
        for j=flip(el)
            if style(j)
                patch(get(h(j),'XData'),get(h(j),'YData'),[1 1 1],'EdgeColor',color(j,:));
                set(h(j),'color','none');
                set(h1(j),'lineStyle','-','color',color(j,:));
                set(h2(j),'lineStyle','-','color',color(j,:));
                set(h3(j),'lineStyle','none'); set(h4(j),'lineStyle','none');
                set(h5(j),'color',color(j,:),'lineWidth',1);
                set(h6(j),'Visible',showOutliers,'MarkerEdgeColor','none','MarkerFaceColor',color(j,:)); % on to show outliers
            else
                patch(get(h(j),'XData'),get(h(j),'YData'),color(j,:),'EdgeColor','none');
                set(h(j),'color','none');
                set(h1(j),'lineStyle','-','color',color(j,:));
                set(h2(j),'lineStyle','-','color',color(j,:));
                set(h3(j),'lineStyle','none'); set(h4(j),'lineStyle','none');
                set(h5(j),'color',[1 1 1],'lineWidth',2);
                set(h6(j),'Visible',showOutliers,'MarkerEdgeColor','none','MarkerFaceColor',color(j,:),'MarkerSize',2); % on to show outliers
            end
        end 
        
        axis auto
        set(gca,'Children',flipud(get(gca,'Children'))); %Invert the order of the objects
        box off;
        if strcmpi(orientation, 'horizontal')
            ylim([0 max(pos)+1]);
            set(gca,'ytick',[]);
        else
            xlim([0 max(pos)+1]);
            set(gca,'xtick',[]);
        end 
        
    elseif strcmpi(plotType,'barSEM') || strcmpi(plotType,'barStd')
        if size(groupAll,2) < 2
            pos = [1:length(ind)];
        else
            pos = [1:length(ind)];                                         % group by the first variable
            pos = (cumsum([0; diff(indAll(:,1))/(1*10^(size(groupAll,2)-1))])/2)' + pos;
        end
        
        hold on
        for ii = 1:length(ind) 
            bar(pos(ii),stats.descriptive.mean(ii),'FaceColor',color(ii,:),'EdgeColor','none');
            if strcmpi(plotType,'barSEM')
                plot([pos(ii) pos(ii)], [stats.descriptive.mean(ii)-stats.descriptive.SEM(ii) stats.descriptive.mean(ii)+stats.descriptive.SEM(ii)],'color',color(ii,:),'LineWidth',2);
            elseif strcmpi(plotType,'barStd')
                plot([pos(ii) pos(ii)], [stats.descriptive.mean(ii)-stats.descriptive.std(ii) stats.descriptive.mean(ii)+stats.descriptive.std(ii)],'color',color(ii,:),'LineWidth',2);
            end
            
            if plotData
               plot(pos(ii)*ones(length(find(group==ind(ii))),1)+rand(length(find(group==ind(ii))),1)/2-.25, y(group==ind(ii)),'o',...
                   'MarkerSize',3,'MarkerEdgeColor','none','MarkerFaceColor','k');
            end
        end
        xlim([.5 max(pos)+.5]);
        set(gca,'xtick',[]);
        if strcmpi(orientation, 'horizontal')
            view([90 90]); 
        end
        
    elseif strcmpi(plotType,'BoxLinesStd') || strcmpi(plotType,'BoxLinesSEM')
        pos = [1:length(ind)];
        hold on
        for ii = 1:length(ind) 
            wing = .3;
            m = stats.descriptive.mean(ii);
            if strcmpi(plotType,'linesStd')
                s = stats.descriptive.std(ii);
            else
                s = stats.descriptive.SEM(ii);
            end
            
            fill([pos(ii)-wing pos(ii)+wing pos(ii)+wing pos(ii)-wing pos(ii)-wing],...
                [m-s m-s m+s m+s m-s],color(ii,:),'faceAlpha',.3,'lineStyle','none');
            plot([pos(ii)-wing pos(ii)+wing],ones(1,2)*m,'Color',color(ii,:)); % media
        end
        repet = repmat((1:length(find(group == min(group))))',length(ind),1);
        % c_rep = jet(length(unique(repet)));
        for ii = 1:length(unique(repet))
            plot(pos,y(repet==ii),'color',[.7 .7 .7]);
        end
        
    elseif strcmpi(plotType,'dispersionStd') 
        if size(groupAll,2) < 2
            pos = [1:length(ind)];
        else
            pos = [1:length(ind)];                                         % group by the first variable
            pos = (cumsum([0; diff(indAll(:,1))/(1*10^(size(groupAll,2)-1))])/2)' + pos;
        end
        
        hold on
        for ii = 1:length(ind) 
            wing = .3;
            m = stats.descriptive.mean(ii);
            s = stats.descriptive.std(ii);
            fill([pos(ii)-wing pos(ii)+wing pos(ii)+wing pos(ii)-wing pos(ii)-wing],...
                [m-s m-s m+s m+s m-s],color(ii,:),'faceAlpha',.3,'lineStyle','none');
            plot([pos(ii)-wing pos(ii)+wing],ones(1,2)*m,'Color',[1 1 1]); % mean
            
            plot(pos(ii)*ones(length(find(group==ind(ii))),1)+rand(length(find(group==ind(ii))),1)/2-.25, y(group==ind(ii)),'o',...
                   'MarkerSize',3,'MarkerEdgeColor','none','MarkerFaceColor','k');
        end
    end 

    if labelSummary
        if repeatedMeasures
            xlabel({...
                strcat('norm: ',num2str(isNorm),'; var(p)=',num2str(round(pvar,3)));
                strcat('rANOVA p=',sprintf('%0.3g',pA),', F(',num2str(tblA{4,3}),')=',num2str(round(tblA{2,5},3)));
                strcat('FM p=',sprintf('%0.3g',pK),', Chi-sq=',num2str(round(tblK{2,5},3)))});
        else
            if size(groupAll,2) < 2
                xlabel({...
                    strcat('norm: ',num2str(isNorm),'; var(p)=',num2str(round(pvar,3)));
                    strcat('ANOVA p=',sprintf('%0.3g',pA),', F(',num2str(tblA{4,3}),')=',num2str(round(tblA{2,5},3)));
                    strcat('KW p=',sprintf('%0.3g',pK),', Chi-sq=',num2str(round(tblK{2,5},3)))});
            else
                xlabel({...
                    strcat('norm: ',num2str(isNorm),'; var(p)=',num2str(round(pvar,3)));
                    strcat('ANOVA p=',sprintf('%0.3g ',pA),', F(',num2str(tblA{4,3}),')=',num2str(round(tblA{2,5},3)));});
            end
        end
    end
    hold off
    set(gca,'TickDir','out')
    if addSigStar
        if strcmpi(sigStarTest,'KW')
            phtest = kkph;
        elseif strcmpi(sigStarTest,'anova')
            phtest = anph;
        else
            error('significance star test not recognized!');
        end
        
        gs = phtest(:, [1 2]);
        ps = phtest(:, end);
        gs(ps>.05,:) = []; ps(ps>.05)=[];
        
        posLin = [1:length(ind)];                                          % exange positions
        gs2 = gs;
        for ii = 1:length(posLin)
            gs2(find(gs==posLin(ii))) = pos(ii);
        end
        
        sigstar(num2cell(gs2,2),ps);
    end
end

disp('Tukey ANOVA pairwise comparison ');
disp(anph);
disp('Tukey KK pairwise comparison ');
try disp(kkph); end

end
