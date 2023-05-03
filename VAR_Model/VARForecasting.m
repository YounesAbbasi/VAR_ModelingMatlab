%%-------------------------------------------%%
%              VAR model estimation
%%-------------------------------------------%%
%              Inflation Forecasting
%%-------------------------------------------%%

clear; clc;close all;
%%-------------------Load Data----------------%%
%% specify file and sheet
TlData = readtable('testdata.xlsx', 'ReadRowNames', true);
Mdata = table2array(TlData);
ColName = TlData.Properties.VariableNames;
[n,c]=size(Mdata);
%% 
%Plot raw Data 
for i=1:c
    figure
    plot(Mdata(:,i));
    % xticklabels(cell2mat(TlData.Properties.RowNames))
    xticklabels(TlData.Properties.RowNames)
    % datatip(p,xtickLabel(cell2mat(x.Properties.RowNames)))
    set(gca, 'XTick',1:n, 'XTickLabel',TlData.Properties.RowNames)
    title(ColName(i))
    ylabel("Index")
    xlabel("Date")
end
%%
% ADF test and station time series
StationMat = stationData(Mdata);
%%
% Select time series for modeling
SelectedCol = [1,2 ,5,6];
%%
%%% In smaple Forecasting
TrainPercent = 0.9; 
ColNameModel = ColName(SelectedCol);
[rr,cc] = size(ColNameModel);
NLag = 15;  % Lag selection
EstY = StationMat(:,SelectedCol);
Train = ceil(TrainPercent*size(EstY,1));
MdlP = varm(cc,NLag);
MdlP.SeriesNames = ColNameModel;

% Test and train data
[EstMdlP,~,~,ResidualP] = estimate(MdlP,EstY(1:Train,:));
EstMSE = sum((ResidualP.*100).^2)./size(EstY(1:Train,:),1);
numperiodsP = size(EstY,1)-Train;
[YfP, YMSEP] = forecast(EstMdlP,numperiodsP,EstY(1:Train,:));
Error = EstY(Train+1:end,:)-YfP;
MPEP = sum(abs(Error./abs(EstY(Train+1:end,:)))*100)/size(YfP,1);
%% 
[hJP,hLP,hHP] = diagtest(ResidualP);
%%
extractMSE = @(x)diag(x)';
MSEP = cellfun(extractMSE,YMSEP,'UniformOutput',false);
SEP = sqrt(cell2mat(MSEP));
%%
% 95 percent confidence interval 
ForecastFIP = zeros(numperiodsP,MdlP.NumSeries,2);
ForecastFIP(:,:,1) = YfP - 2*SEP;
ForecastFIP(:,:,2) = YfP + 2*SEP;
% 68 percent confidence interval 
ForecastFI68P = zeros(numperiodsP,MdlP.NumSeries,2);
ForecastFI68P(:,:,1) = YfP - SEP;
ForecastFI68P(:,:,2) = YfP + SEP;
%%
% Plot forecasting 
for sp=1:cc
    figure
    h1 = plot(EstY(:,sp));
    hold on
    h2 = plot(Train+1:Train+numperiodsP,YfP(:,sp),'k');
    h3 = plot(Train+1:Train+numperiodsP, ForecastFIP(:,sp,1), 'g--');
    plot(Train+1:Train+numperiodsP, ForecastFIP(:,sp,2), 'g--');
    h4 = plot(Train+1:Train+numperiodsP, ForecastFI68P(:,sp,1), 'r--');
    plot(Train+1:Train+numperiodsP, ForecastFI68P(:,sp,2), 'r--');
    title(ColNameModel(sp))
    ylabel("Growth Rate")
    xlabel("Date")
    legend([h1 h2],"Data","Forecast",'Location','northwest')
    hold off
end


%% 
%%% Out sample forecasting
% Estimation and forecasting model
Mdl = varm(cc,NLag);
[EstMdl,~,~,Residual] = estimate(Mdl,EstY);
%%
[hJ,hL,hH] = diagtest(Residual);
%%
numperiods = 12; % Number of period forecasting

Y0 = EstY;
[Yf, YMSE] = forecast(EstMdl,numperiods,Y0);
%%
extractMSE = @(x)diag(x)';
MSE = cellfun(extractMSE,YMSE,'UniformOutput',false);
SE = sqrt(cell2mat(MSE));
%%
% 95 percent confidence interval 
ForecastFI = zeros(numperiods,Mdl.NumSeries,2);
ForecastFI(:,:,1) = Yf - 2*SE;
ForecastFI(:,:,2) = Yf + 2*SE;
% 68 percent confidence interval 
ForecastFI68 = zeros(numperiods,Mdl.NumSeries,2);
ForecastFI68(:,:,1) = Yf - SE;
ForecastFI68(:,:,2) = Yf + SE;
%%
% Plot forecasting 
for s=1:cc
    figure
    h1 = plot(EstY((end-49):end,s));
    hold on
    h2 = plot(51:50+numperiods,Yf(:,s),'k');
    h3 = plot(51:50+numperiods, ForecastFI(:,s,1), 'g--');
    plot(51:50+numperiods, ForecastFI(:,s,2), 'g--');
    h4 = plot(51:50+numperiods, ForecastFI68(:,s,1), 'r--');
    plot(51:50+numperiods, ForecastFI68(:,s,2), 'r--');
    title(ColNameModel(s))
    ylabel("Growth Rate")
    xlabel("Date")
    legend([h1 h2 h3 h4],"Data","Forecast",'95% Forecast interval','68% Forecast interval','Location','northwest')
    hold off
end