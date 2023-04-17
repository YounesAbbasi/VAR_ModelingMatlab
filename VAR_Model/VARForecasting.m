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
%%-------------------------%
%% 
% Plot raw Data 
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
StationMat = zeros(n-1,c);
for z=1:c
    if 1 == adftest(Mdata(:,z))
        disp("It's Station")
        disp(z)
        StationMat(:,z)=Mdata(2:end,z);
    else
        if 1 == adftest(log(Mdata(:,z)))
            disp('log station')
            disp(z)
            StationMat(:,z)=log(Mdata(:,z));
        else 
            if 1 == adftest(diff(log(Mdata(:,z))))
             disp('percent change station')
             disp(z)
             StationMat(:,z)=diff(log(Mdata(:,z)));
            end
        end
    end
end

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
EstMdlP = estimate(MdlP,EstY(1:Train,:));
numperiodsP = size(EstY,1)-Train;
[YfP, YMSEP] = forecast(EstMdlP,numperiodsP,EstY(1:Train,:));
Error = EstY(Train+1:end,:)-YfP;
MPE = sum(abs(Error./EstY(Train+1:end,:))*100)/size(YfP,1);

% Plot forecasting 
for sp=1:cc
    figure
    h1 = plot(EstY(Train+1:end,sp));
    hold on
    h2 = plot(1:numperiodsP,YfP(:,sp));
    title(ColNameModel(sp))
    ylabel("Growth Rate")
    xlabel("Date")
    legend([h1 h2],"Data","Forecast",'Location','northwest')
    hold off
end


%% 
%%% Out sample forecasting
% Estimation and forecasting model
EstMdl = estimate(Mdl,EstY);
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
    h2 = plot(51:50+numperiods,Yf(:,s));
    h3 = plot(51:50+numperiods, ForecastFI(:,s,1), 'k--');
    plot(51:50+numperiods, ForecastFI(:,s,2), 'k--');
    h4 = plot(51:50+numperiods, ForecastFI68(:,s,1), 'r--');
    plot(51:50+numperiods, ForecastFI68(:,s,2), 'r--');
    title(ColNameModel(s))
    ylabel("Growth Rate")
    xlabel("Date")
    legend([h1 h2 h3 h4],"Data","Forecast",'95% Forecast interval','68% Forecast interval','Location','northwest')
    hold off
end