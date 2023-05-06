%%-------------------------------------------%%
%              VECM model estimation
%%-------------------------------------------%%
%              Inflation Forecasting
%%-------------------------------------------%%

clear; clc;close all;
warning('off')
%%-------------------Load Data----------------%%
%% specify file and sheet
TlData = readtable('testdata.xlsx', 'ReadRowNames', true);
Mdata = table2array(TlData);
ColName = TlData.Properties.VariableNames;
%%
% Select time series for modeling and maxlag
SelectedCol = [1,2,5,6];
maxlag = 15;
%%
% ADF test and station time series
StationMat = stationData(Mdata);
EstY = StationMat(:,SelectedCol);
Mdata = Mdata(:,SelectedCol);
[n,c]=size(Mdata);
%%
% In smaple Forecasting
TrainPercent = 0.98;
numperiods = n-round(n*TrainPercent);
ColNameModel = ColName(SelectedCol);
TargetVariables = 4;
%%
% h = jcitest(Mdata(:,[1,3]), Lags=0);
% hcol = 1;
% while table2array(h(1,hcol))>=1
% hcol=hcol+1;
% end
%%
% h = jcitest(Mdata(:,[1,3]), Lags=0);
% hcol = 1;
% while table2array(h(1,hcol))>=1
% hcol=hcol+1;
% if hcol>size(Mdata(:,[1,3]),2)
%     hcol=1;
%     break
% end
% end
%%
[MAPE, RevForData,ForData, ForMSE, NumSeries, resultSumm, selecteddata] = OptVECM(c,10,Mdata,TrainPercent,TargetVariables);
%%
extractMSE = @(x)diag(x)';
MSE = cellfun(extractMSE,ForMSE,'UniformOutput',false);
SE = sqrt(cell2mat(MSE));
%%
% 95 percent confidence interval 
ForecastFI = zeros(numperiods,NumSeries,2);
ForecastFI(:,:,1) = exp((ForData - 2*SE)/100);
ForecastFI(:,:,2) = exp((ForData + 2*SE)/100);
% 68 percent confidence interval
ForecastFI68 = zeros(numperiods,NumSeries,2);
ForecastFI68(:,:,1) = exp((ForData - SE)/100);
ForecastFI68(:,:,2) = exp((ForData + SE)/100);

%%
ShowNum =50;
FShowNum =ShowNum-numperiods+2:ShowNum+1;
for s=1:c
    figure
    h1 = plot(selecteddata(end-ShowNum:end,s));
    hold on
    h2 = plot(FShowNum,RevForData(:,s),'k');
    h3 = plot(FShowNum, ForecastFI(:,s,1), 'g--');
    plot(FShowNum, ForecastFI(:,s,2), 'g--');
    h4 = plot(FShowNum, ForecastFI68(:,s,1), 'r--');
    plot(FShowNum, ForecastFI68(:,s,2), 'r--');
    title(ColNameModel(s))
    ylabel("Growth Rate")
    xlabel("Date")
    legend([h1 h2 h3 h4],"Data","Forecast",'95% Forecast interval','68% Forecast interval','Location','northwest')
    hold off
end
