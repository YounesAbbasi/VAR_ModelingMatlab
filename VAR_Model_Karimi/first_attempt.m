clear; close all; clc;
%% global programm parameters
datasel = {'cpi', 'm2', 'er', 'mb'};
testlen = 10;
forelen = 20;
maxlag = 25;
%% data aquision
% fprintf('\ncolinierity test for real data:\n')
% data = xlsread('testdata.xlsx', 'Sheet5');

numvar = size(datasel, 2);
datatable = readtable('testdata.xlsx', 'sheet', 'Sheet5');
datalen = size(datatable, 1);
data = nan(datalen, numvar);
for i = 1:numvar
    data(:, i) = eval(strcat('datatable.', datasel{i}));
end

%% data pretests: colinearity test
% collintest(data)
% figure()
% corrplot(data)

%% data preprocessing (scaling)
[data, maxs] = scaling(numvar,data);
%%
% Cointegration test
% h0 = no cointegration
% hC =1 means rejection of h0
hC = egcitest(data);
%%
data = stationData(data);
datalen=size(data,1);
%% datetable
datelen = datenum(1384,1:datalen,30);
datetable = datetime(datelen,'Format','dd-MM-yyyy','convertFrom','datenum');
%% lag detection
traindata = data(1:end-testlen, :);
laglen = lagfind(maxlag,numvar,forelen,testlen,traindata,data);
%% var model defenition and forecasting
fprintf('\nmodel training with training data (part of data)')

model = varm(numvar, laglen);   % model definition
traindata = data(1:end-testlen, :);
lentraind = size(traindata, 1);
[estmodel, SE, ~, Error] = estimate(model, traindata, 'Y0', traindata(1:laglen, :));   % model estimation

% innovation inference
modelinfer = infer(estmodel, traindata, 'Y0', data(1:laglen, :));   % model innovation inference
% modelinfer = infer(estmodel, data);   % model innovation inference when laglen initial values are zeros

%summarize(estmodel)

[outsample, outMSE] = forecast(estmodel, forelen, traindata);
[insample, inMSE] = forecast(estmodel, forelen, traindata(1:end-forelen, :));
MPEin = 100 * sum(abs(traindata(end-forelen+1:end, :) - insample) ./ traindata(end-forelen+1:end, :)) / forelen;
MPEout = 100 * sum(abs(data(end-testlen+1:end, :) - outsample(1:end-testlen, :)) ./ outsample(1:end-testlen, :)) / testlen;

cfun = @(x)(diag(x))';
MSEout = cellfun(cfun, outMSE, 'UniformOutput', false);
SEout = sqrt(cell2mat(MSEout));

YFIout = zeros(forelen,numvar,2);
YFIout(:,:,1) = outsample - 2*SEout;
YFIout(:,:,2) = outsample + 2*SEout;
YFIout65(:,:,1) = outsample - SEout;
YFIout65(:,:,2) = outsample + SEout;

MSEin = cellfun(cfun, inMSE, 'UniformOutput', false);
SEin = sqrt(cell2mat(MSEin));

YFIin = zeros(forelen, numvar, 2);
YFIin(:,:,1) = insample - 2*SEin;
YFIin(:,:,2) = insample + 2*SEin;
YFIin65(:,:,1) = insample - SEin;
YFIin65(:,:,2) = insample + SEin;

%% extract inflation from data and estimated cpi
infldata = 100*(traindata(2:end, 1) - traindata(1:end-1, 1)) ./ traindata(1:end-1, 1);
cpiestim = [insample(:, 1); outsample(:, 1)];
inflprediction = 100*(cpiestim(2:end, 1) - cpiestim(1:end-1, 1)) ./ cpiestim(1:end-1, 1);

%% ploting
for i = 1:numvar
    figure()
    plot(1:datalen, data(:, i), 'black')
    hold on
    plot(lentraind-forelen+1:lentraind, insample(:, i), 'blue')
    plot(lentraind-forelen+1:lentraind, reshape(YFIin(:, i, 1), forelen, 1), 'r--')
    plot(lentraind-forelen+1:lentraind, reshape(YFIin(:, i, 2), forelen, 1), 'r--')
    plot(lentraind-forelen+1:lentraind, reshape(YFIin65(:, i, 1), forelen, 1), 'r--')
    plot(lentraind-forelen+1:lentraind, reshape(YFIin65(:, i, 2), forelen, 1), 'r--')
    title('insample of train model')
    legend(['real ' datasel{i}],'in sample forcast','95% & 65% percision','','','','Location','northwest')
    xlabel('time'); ylabel('unit')
    xlim([(datalen+forelen)/2 datalen])
    
    figure()
    plot(1:datalen, data(:, i), 'black')
    hold on
    plot(lentraind:forelen-1+lentraind, outsample(:, i), 'blue')
    plot(lentraind:forelen-1+lentraind, reshape(YFIout(:, i, 1), forelen, 1), 'r--')
    plot(lentraind:forelen-1+lentraind, reshape(YFIout(:, i, 2), forelen, 1), 'r--')
    plot(lentraind:forelen-1+lentraind, reshape(YFIout65(:, i, 1), forelen, 1), 'r--')
    plot(lentraind:forelen-1+lentraind, reshape(YFIout65(:, i, 2), forelen, 1), 'r--')
    title('outsample of train model')
    legend(['real ' datasel{i}],'forcast','95% & 65% percision','','','','Location','northwest')
    xlabel('time'); ylabel('unit')
    xlim([(datalen+forelen)/2 datalen+forelen])
    %     figure()
    %     plot(modelinfer(:, i))
    %     hold on
    %     plot(zeros(1, size(modelinfer, 1)), 'r--')
end

figure()
plot(lentraind-forelen-testlen+1:lentraind-1, infldata(end-forelen-testlen+2:end))
hold on
plot(lentraind-forelen+1:forelen-1+lentraind, inflprediction, 'r--')

title('inflation forecast by best senario')
legend('real inflation','inflation by forecast data', 'Location','northeast')
xlabel('time'); ylabel('percent')
xlim([lentraind-forelen+1 lentraind+forelen-1])

%% best senario training with all data
laglen = lagfind(maxlag,numvar,forelen,forelen,data,data);

fprintf('\nbest model simulation part')
bmodel = varm(numvar, laglen);   % model definition
[bestmodel, bSE, ~, bError] = estimate(bmodel, data, 'Y0', data(1:laglen, :));   % best model estimation
bmodelinfer = infer(bestmodel, data, 'Y0', data(1:laglen, :));   % best model innovation inference
summarize(bestmodel)
[boutsample, boutMSE] = forecast(bestmodel, forelen, data);
[binsample, binMSE] = forecast(bestmodel, forelen, data(1:end-forelen, :));
bMPEin = 100 * sum(abs(data(end-forelen+1:end, :) - binsample) ./ data(end-forelen+1:end, :)) / forelen;
bMSEout = cellfun(cfun, boutMSE, 'UniformOutput', false);
bSEout = sqrt(cell2mat(MSEout));
bYFIout = zeros(forelen, numvar, 2);
bYFIout(:,:,1) = boutsample - 2*bSEout;
bYFIout(:,:,2) = boutsample + 2*bSEout;
bYFIout65(:,:,1) = boutsample - bSEout;
bYFIout65(:,:,2) = boutsample + bSEout;

bMSEin = cellfun(cfun, binMSE, 'UniformOutput', false);
bSEin = sqrt(cell2mat(bMSEin));

bYFIin = zeros(forelen,numvar,2);
bYFIin(:,:,1) = binsample - 2*bSEin;
bYFIin(:,:,2) = binsample + 2*bSEin;
bYFIin65(:,:,1) = binsample - bSEin;
bYFIin65(:,:,2) = binsample + bSEin;

%% extract inflation from data and estimated cpi for best senario
binfldata = 100*(data(2:end, 1) - data(1:end-1, 1)) ./ data(1:end-1, 1);
bcpiestim = [binsample(:, 1); boutsample(:, 1)];
binflprediction = 100 *(bcpiestim(2:end, 1) - bcpiestim(1:end-1, 1)) ./ bcpiestim(1:end-1, 1);

%% ploting best senario
for i = 1:numvar
    
    figure()
    plot(1:datalen, data(:, i), 'black')
    hold on
    plot(datalen-forelen+1:datalen, binsample(:, i), 'blue')
    plot(datalen-forelen+1:datalen, reshape(bYFIin(:, i, 1), forelen, 1), 'r--')
    plot(datalen-forelen+1:datalen, reshape(bYFIin(:, i, 2), forelen, 1), 'r--')
    plot(datalen-forelen+1:datalen, reshape(bYFIin65(:, i, 1), forelen, 1), 'r--')
    plot(datalen-forelen+1:datalen, reshape(bYFIin65(:, i, 2), forelen, 1), 'r--')
    title('insample of best senario')
    legend(['real ' datasel{i}],'in sample forcast','95% & 65% percision','','','','Location','northwest')
    xlabel('time'); ylabel('unit')
    xlim([(datalen+forelen)/2 datalen])
    
    figure()
    plot(1:datalen, data(:, i), 'black')
    hold on
    plot(datalen:forelen-1+datalen, boutsample(:, i), 'blue')
    plot(datalen:forelen-1+datalen, reshape(bYFIout(:, i, 1), forelen, 1), 'r--')
    plot(datalen:forelen-1+datalen, reshape(bYFIout(:, i, 2), forelen, 1), 'r--')
    plot(datalen:forelen-1+datalen, reshape(bYFIout65(:, i, 1), forelen, 1), 'r--')
    plot(datalen:forelen-1+datalen, reshape(bYFIout65(:, i, 2), forelen, 1), 'r--')
    title('outsample of best senario')
    legend(['real ' datasel{i}],'forcast','95% & 65% percision','','','','Location','northwest')
    xlabel('time'); ylabel('unit')
    xlim([(datalen+forelen)/2 datalen+forelen])
    
    %     figure()
    %     plot(bmodelinfer(:, i))
    %     hold on
    %     plot(zeros(1, size(bmodelinfer, 1)), 'r--')
end

figure()
plot(datalen-forelen+1:datalen-1, binfldata(end-forelen+2:end))
hold on
plot(datalen-forelen+1:forelen-1+datalen, binflprediction, 'r--')
title('inflation forecast by best senario')
legend('real inflation','inflation by forecast data', 'Location','northeast')
xlabel('time'); ylabel('percent')
xlim([datalen-forelen+1 datalen+forelen-1])


%% drawing table
fprintf('%10s %16s %16s %16s\n', 'index', 'MPEout', 'MPEin', 'bMPEin')
fprintf('  -----------------------------------------------------------------\n')
for i = 1:numvar
    fprintf('%8s %16.2f %17.2f %16.2f\n', datasel{i}, [MPEout(i) MPEin(i) bMPEin(i)])
end

%% simulation
% [simumean, simustd] = simulationrun(bestmodel, boutsample, forelen, data, 2000);
% close all

%% impulse response
% [Response,Lower,Upper] = irf(bestmodel);
% for i = 1:numvar
%     Resp(:, :) = Response(:, i, :);
%     lo(:, :) = Lower(:, i, :);
%     upp(:, :) = Upper(:, i, :);
%     for j = 1:numvar
%         subplot(numvar, numvar, (i-1)*numvar+j)
%         plot(Resp(:, j), 'b')
%         hold on
%         plot(lo(:, j), 'r')
%         plot(upp(:, j), 'r')
%         title([datasel{j} ' resp ' 'to ' datasel{i}])
%     end
%     clear Resp lo upp
% end
% 
%% granger causality
h = gctest(bestmodel, 'Type', "exclude-all");
h = gctest(estmodel, 'Type', "exclude-all");
%%
h = gctest(bestmodel);
h = gctest(estmodel);
%%

