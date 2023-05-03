clear; close all; clc
warning('off')
%% global programm parameters
datasel = ["cpi", "m2", "er", "mb"];
dataunit = ["percent", "hezar miliard rial", "rial", "hezar miliard rial"];
forelen = 15;
maxlag = 20;
startingyear = 1384;
compareperiod = 24;  % forecast will compare with past 24 months because of monthly data
plotinterval = 90;

%% data aquision
numvar = size(datasel, 2);
fprintf('\n number of variable:')
fprintf('\t%0d\n', numvar)

datatable = readtable('testdata.xlsx', 'sheet', 'Sheet6');   % importing data from excel
datalen = size(datatable, 1);  % determining data length
data = nan(datalen, numvar);   % creating data as matrix
for i = 1:numvar
    data(:, i) = eval(strcat('datatable.', datasel(i)));
end
init = data(1, :);
data2 = data;

%% data preprocessing (scaling)
% [data, maxs] = scaling(data, cpinum); % scale data by cpi amplitude

%% stationaring data
data = makestation(data, datalen, numvar);
datalen = size(data, 1);  % determining data length

%% finding cpi in data
for i = 1:numvar
    if isequal(datasel(i), "cpi")
        cpinum = i;
    end
end

%% data pretests: colinearity test
% fprintf('\ncolinierity test for real data:\n')
% collintest(data)
% figure()
% corrplot(data)

%% datetable for differenced data
datelen = datenum(startingyear,1:datalen+forelen,1);
datetable = datetime(datelen,'Format','dd-MM-yyyy','convertFrom','datenum');

%% training with all data for forecasting
laglen = lagfind(maxlag, numvar, forelen, forelen, data, data); % finding optimal data length

fprintf('\n model estimation using all data length to forecast\n')

model = varm(numvar, laglen);   % model definition
[estmodel, SE, ~, error] = estimate(model, data, 'Y0', data(1:laglen, :));   % model estimation
modelinfer = infer(estmodel, data, 'Y0', data(1:laglen, :));   % model innovation inference, data as initial point
summerie = summarize(estmodel);  % identification summery

[outsample, outMSE] = forecast(estmodel, forelen, data);  % forecast data without training samples
[insample, inMSE] = forecast(estmodel, forelen, data(1:end-forelen, :));  % forecast data with training samples

MPEin = 100 * sum(abs(data(end-forelen+1:end, :) - insample) ./ abs(data(end-forelen+1:end, :))) / forelen;  % mean percentage error for insample forecast

cfun = @(x)(diag(x))'; % creating function to run on MSE matrix

MSEin = cellfun(cfun, inMSE, 'UniformOutput', false); % same as outsample procedure
SEin = sqrt(cell2mat(MSEin));
ciin195 = insample - 2*SEin;  % 95% confidence interval for insample
ciin295 = insample + 2*SEin;
ciin168 = insample - SEin;  % 68% confidence interval for insample
ciin268 = insample + SEin;

MSEout = cellfun(cfun, outMSE, 'UniformOutput', false);  % extracting mean squared error for outsample forecast
SEout = sqrt(cell2mat(MSEout));  % standard error (deviation) to find confidence interval
ciout195 = outsample - 2*SEout;  % 95% confidence interval for outsample
ciout295 = outsample + 2*SEout;
ciout168 = outsample - SEout;  % 68% confidence interval for outsample
ciout268 = outsample + SEout;


%% 
nameforein = ["diffcpi ins", "diffm2 nomi ins", "diffef nomi ins", "diffmb nomi ins"];
nameciin195 = ["diffcpi ins CI1 95", "diffm2 nomi ins CI1 95", "diffef nomi ins CI1 95", "diffmb nomi ins CI1 95"];
nameciin295 = ["diffcpi ins CI2 95", "diffm2 nomi ins CI2 95", "diffef nomi ins CI2 95", "diffmb nomi ins CI2 95"];
nameciin168 = ["diffcpi ins CI1 68", "diffm2 nomi ins CI1 68", "diffef nomi ins CI1 68", "diffmb nomi ins CI1 68"];
nameciin268 = ["diffcpi ins CI2 68", "diffm2 nomi ins CI2 68", "diffef nomi ins CI2 68", "diffmb nomi ins CI2 68"];
nameforeout = ["diffcpi outs", "diffm2 nomi outs", "diffef nomi outs", "diffmb nomi outs"];
nameciout195 = ["diffcpi outs CI1 95", "diffm2 nomi outs CI1 95", "diffef nomi outs CI1 95", "diffmb nomi outs CI1 95"];
nameciout295 = ["diffcpi outs CI2 95", "diffm2 nomi outs CI2 95", "diffef nomi outs CI2 95", "diffmb nomi outs CI2 95"];
nameciout168 = ["diffcpi outs CI1 68", "diffm2 nomi outs CI1 68", "diffef nomi outs CI1 68", "diffmb nomi outs CI1 68"];
nemaciout268 = ["diffcpi outs CI2 68", "diffm2 nomi outs CI2 68", "diffef nomi outs CI2 68", "diffmb nomi outs CI2 68"];

%% ploting for differened data
x0 = datetable(1:datalen);
x1 = datetable(datalen-forelen+1:datalen)';
x2 = datetable(datalen:forelen-1+datalen)';
for i = 1:numvar
    % plotting insample
    y1 = ciin168(:, i);
    y2 = ciin268(:, i);
    y3 = ciin195(:, i);
    y4 = ciin295(:, i);

    figure()
    plot(x0, data(:, i), 'black')
    hold on
    plot(x1, insample(:, i), 'blue')
    plot(x1, y1, 'g--')
    plot(x1, y2, 'g--')
    plot(x1, y3, 'r--')
    plot(x1, y4, 'r--')
    
    shade(x1, y1, x1, y2, 'FillColor', {'cyan'}, 'FillType', [2 1])
    shade(x1, y3, x1, y4, 'FillColor', {'yellow'}, 'FillType', [2 1])
    
    title('insample forecast with differenced data')
    xlabel('time'); ylabel(convertStringsToChars(dataunit(i)))
    xlim([datetable(end-plotinterval) datetable(datalen)]); ylim([-inf inf])
    xtickformat("yyyy-MM")
    legend1 = sprintf(['differenced ' convertStringsToChars(datasel(i))]);
    legend2 = sprintf('insample forcast');
    legend3 = sprintf('');
    legend4 = sprintf('68%% confidence area');
    legend5 = sprintf('95%% confidence area');
    legend({legend1, legend2, legend3, legend3, legend3, legend3, legend3, legend3, legend4, legend3, legend3, legend5}, 'Location', 'northwest');
    
        % creating data equivalence table
    data4table = [consistnan(data(:, i), datalen, forelen, "data"), consistnan(insample(:, i), datalen, forelen, "insample"), ...
        consistnan(y3, datalen, forelen, "insample"), consistnan(y4, datalen, forelen, "insample"), ...
        consistnan(y1, datalen, forelen, "insample"), consistnan(y2, datalen, forelen, "insample")];
    name4table = [datasel(i), nameforein(i), nameciin195(i), ...
        nameciin295(i), nameciin168(i), nameciin268(i)];
    
    creattable(datetable, data4table, name4table, ['fillchart differenced insample', num2str(i)])
    
    % ploting outsample
    y1 = ciout168(:, i);
    y2 = ciout268(:, i);
    y3 = ciout195(:, i);
    y4 = ciout295(:, i);

    figure()  
    plot(datetable(1:datalen), data(:, i), 'black')
    hold on
    plot(x2, outsample(:, i), 'blue')
    plot(x2, y1, 'g--')
    plot(x2, y2, 'g--')
    plot(x2, y3, 'r--')
    plot(x2, y4, 'r--')
    
    shade(x1, y1, x1, y2, 'FillColor', {'cyan'}, 'FillType', [2 1])
    shade(x1, y3, x1, y4, 'FillColor', {'yellow'}, 'FillType', [2 1])

    title('outsample forecast with differenced data')
    xlabel('time'); ylabel(convertStringsToChars(dataunit(i)))
    xlim([datetable(end-plotinterval) datetable(datalen+forelen)]); ylim([-inf inf])
    xtickformat("yyyy-MM")
    legend1 = sprintf(['differenced ' convertStringsToChars(datasel(i))]);
    legend2 = sprintf('outsample forcast');
    legend3 = sprintf('');
    legend4 = sprintf('68%% confidence area');
    legend5 = sprintf('95%% confidence area');
    legend({legend1, legend2, legend3, legend3, legend3, legend3, legend3, legend3, legend4, legend3, legend3, legend5}, 'Location', 'northwest');
    
    % creating data equivalence table
    
    data4table = [consistnan(data(:, i), datalen, forelen, "data"), consistnan(outsample(:, i), datalen, forelen, "outsample"), ...
        consistnan(y3, datalen, forelen, "outsample"), consistnan(y4, datalen, forelen, "outsample"), ...
        consistnan(y1, datalen, forelen, "outsample"), consistnan(y2, datalen, forelen, "outsample")];
    name4table = [datasel(i), nameforeout(i), nameciout195(i), ....
        nameciout295(i), nameciout168(i), nemaciout268(i)];
    creattable(datetable, data4table, name4table, ['fillchart differenced outsample', num2str(i)])
end

%% reversing difference
revdata = revdiff(data, init);
revforein = revdiff(insample, revdata(end-forelen, :));  % insample forecast data before processing if there were any
revciin195 = revdiff(ciin195, revdata(end-forelen, :));  % 95% confidence intreval forecast data before processing if they existed
revciin295 = revdiff(ciin295, revdata(end-forelen, :));
revciin168 = revdiff(ciin168, revdata(end-forelen, :));  % 68% confidence intreval forecast data before processing if they existed
revciin268 = revdiff(ciin268, revdata(end-forelen, :));

revforeout = revdiff(outsample, revdata(end, :));  % insample forecast data before processing if there were any
revciout195 = revdiff(ciout195, revdata(end, :));  % 95% confidence intreval forecast data before processing if they existed
revciout295 = revdiff(ciout295, revdata(end, :));
revciout168 = revdiff(ciout168, revdata(end, :));  % 68% confidence intreval forecast data before processing if they existed
revciout268 = revdiff(ciout268, revdata(end, :));

%% naming reversed data
namerevforein = ["cpi ins", "m2 nomi ins", "er nomi ins", "mb nomi ins"];
namerevciin195 = ["cpi ins CI1 95", "m2 nomi ins CI1 95", "er nomi ins CI1 95", "mb nomi ins CI1 95"];
namerevciin295 = ["cpi ins CI2 95", "m2 nomi ins CI2 95", "er nomi ins CI2 95", "mb nomi ins CI2 95"];
namerevciin168 = ["cpi ins CI1 68", "m2 nomi ins CI1 68", "er nomi ins CI1 68", "mb nomi ins CI1 68"];
namerevciin268 = ["cpi ins CI2 68", "m2 nomi ins CI2 68", "er nomi ins CI2 68", "mb nomi ins CI2 68"];
namerevforeout = ["cpi outs", "m2 nomi outs", "er nomi outs", "mb nomi outs"];
namerevciout195 = ["cpi outs CI1 95", "m2 nomi outs CI1 95", "er nomi outs CI1 95", "mb nomi outs CI1 95"];
namerevciout295 = ["cpi outs CI2 95", "m2 nomi outs CI2 95", "er nomi outs CI2 95", "mb nomi outs CI2 95"];
namerevciout168 = ["cpi outs CI1 68", "m2 nomi outs CI1 68", "er nomi outs CI1 68", "mb nomi outs CI1 68"];
nemarevciout268 = ["cpi outs CI2 68", "m2 nomi outs CI2 68", "er nomi outs CI2 68", "mb nomi outs CI2 68"];

%% ploting nominal data
for i = 1:numvar
    % plotting insample
    figure()  
    plot(x0, revdata(:, i), 'black')
    hold on
    plot(x1, revforein(:, i), 'b')
    plot(x1, revciin195(:, i), 'r')
    plot(x1, revciin295(:, i), 'r')
    plot(x1, revciin168(:, i), 'r')
    plot(x1, revciin268(:, i), 'r')
    
    y1 = revciin168(:, i);
    y2 =  revciin268(:, i);
    shade(x1, y1, x1, y2, 'FillColor', {'cyan'}, 'FillType', [2 1])
    y1 = revciin195(:, i);
    y2 =  revciin295(:, i);
    shade(x1, y1, x1, y2, 'FillColor', {'yellow'}, 'FillType', [2 1])
    
    title('insample forecast with nominal data')
    xlabel('time'); ylabel(convertStringsToChars(dataunit(i)))
    xlim([datetable(end-plotinterval) datetable(datalen)]); ylim([0 inf])
    xtickformat("yyyy-MM")
    legend1 = sprintf(['nominal ' convertStringsToChars(datasel(i))]);
    legend4 = sprintf('insample forcast');
    legend5 = sprintf('');
    legend6 = sprintf('68%% confidence area');
    legend7 = sprintf('95%% confidence area');
    legend({legend1, legend4, legend5, legend5, legend5, legend5, legend5, legend5, legend6, legend5, legend5, legend7}, 'Location', 'northwest');
    
    % creating data equivalence table
    data4table = [consistnan(revdata(:, i), datalen, forelen, "data"), consistnan(revforein(:, i), datalen, forelen, "insample"), ...
        consistnan(revciin195(:, i), datalen, forelen, "insample"), consistnan(revciin295(:, i), datalen, forelen, "insample"), ...
        consistnan(revciin168(:, i), datalen, forelen, "insample"), consistnan(revciin268(:, i), datalen, forelen, "insample")];
    name4table = [datasel(i), namerevforein(i), namerevciin195(i), ...
        namerevciin295(i), namerevciin168(i), namerevciin268(i)];
    
    creattable(datetable, data4table, name4table, ['fillchart rev unscaled in', num2str(i)])
    
    figure()  % plotting outsample
    plot(datetable(1:datalen), revdata(:, i), 'black')
    hold on
    plot(x2, revforeout(:, i), 'blue')
    plot(x2, revciout195(:, i), 'r--')
    plot(x2, revciout295(:, i), 'r--')
    plot(x2, revciout168(:, i), 'r--')
    plot(x2, revciout268(:, i), 'r--')
    
    y1 = revciout168(:, i);
    y2 = revciout268(:, i);
    shade(x2, y1, x2, y2, 'FillColor', {'cyan'}, 'FillType', [2 1])
    
    y1 = revciout195(:, i);
    y2 =  revciout295(:, i);
    shade(x2, y1, x2, y2, 'FillColor', {'yellow'}, 'FillType', [2 1])
    
    title('outsample forecast')
    xlabel('time'); ylabel(convertStringsToChars(dataunit(i)))
    xlim([datetable(end-plotinterval) datetable(datalen+forelen)]); ylim([-inf inf])
    xtickformat("yyyy-MM")
    legend1 = sprintf(['nominal ' convertStringsToChars(datasel(i))]);
    legend4 = sprintf('outsample forcast');
    legend5 = sprintf('');
    legend6 = sprintf('68%% confidence area');
    legend7 = sprintf('95%% confidence area');
    legend({legend1, legend4, legend5, legend5, legend5, legend5, legend5, legend5, legend6, legend5, legend5, legend7}, 'Location', 'northwest');
    
    data4table = [consistnan(revdata(:, i), datalen, forelen, "data"), consistnan(revforeout(:, i), datalen, forelen, "outsample"), ...
        consistnan(revciout195(:, i), datalen, forelen, "outsample"), consistnan(revciout295(:, i), datalen, forelen, "outsample"), ...
        consistnan(revciout168(:, i), datalen, forelen, "outsample"), consistnan(revciout268(:, i), datalen, forelen, "outsample")];
    name4table = [datasel(i), namerevforeout(i), namerevciout195(i), ....
        namerevciout295(i), namerevciout168(i), nemarevciout268(i)];
    creattable(datetable, data4table, name4table, ['fillchart rev unscaled out', num2str(i)])
end

%% moving average data
movdatafore = movmean([revdata; revforeout], 20);  % moving average of merge data and outsample
%% naming moving average data
namerevdatamean = ["cpi last " + string(compareperiod) + " sample mean", "m2 last " + string(compareperiod) + " sample mean", ...
    "er last " + string(compareperiod) + " sample mean", "mb last " + string(compareperiod) + " sample mean"];
namemovingaverage = ["cpi moving average", "m2 moving average", "er moving average", "mb moving average"];
nameoutsample = ["cpi outsample", "m2 outsample", "er outsample", "mb outsample"];
%% ploting moving average and outsample data
for i = 1:numvar
    figure()
    plot(datetable(1:datalen), revdata(:, i), 'black')
    hold on
    y = mean(revdata(end-compareperiod:end, i));  % mean of part of recent data selected by compareperiod
    yline(y, 'r')
    plot(datetable(1:forelen+datalen), movdatafore(:, i), 'c')
    plot(datetable(datalen:forelen-1+datalen), revforeout(:, i), 'blue')
    
    title('comparing outsample and moving average of revdata')
    
    legend1 = sprintf(['nominal ' convertStringsToChars(datasel(i))]);
    legend2 = sprintf(['mean of ', num2str(compareperiod), ' last turns= %.2f'], mean(revdata(end-compareperiod:end, i)));
    legend3 = sprintf('data and outsample moving average');
    legend4 = sprintf('outsample forcast');
    legend({legend1, legend2, legend3, legend4}, 'Location', 'northwest');
    
    xlabel('time'); ylabel('unit')
    xlim([datetable(end-plotinterval) datetable(datalen+forelen)]); ylim([-inf inf])
    xtickformat("yyyy-MM")
    
    % creating data equivalence table
    data4table = [consistnan(revdata(:, i), datalen, forelen, "data"), y*ones(forelen+datalen, 1), ...
        movdatafore(:, i), consistnan(revforeout(:, i), datalen, forelen, "outsample")];
    name4table = [datasel(i), namerevdatamean(i), namemovingaverage(i), nameoutsample(i)];
    
    creattable(datetable, data4table, name4table, ['moving average', num2str(i)])
end

%% extract inflation from data and estimated cpi for senario
infldata = 100*(revdata(2:end, cpinum) - revdata(1:end-1, cpinum)) ./ revdata(1:end-1, cpinum);
cpiestim = [revforein(:, cpinum); revforeout(:, cpinum)];
inflfore = 100 * (cpiestim(2:end, 1) - cpiestim(1:end-1, 1)) ./ cpiestim(1:end-1, 1);

%% ploting heppend inflation and forecast inflation
figure()
x1 = datetable(datalen-forelen+1:datalen-1);
x2 = datetable(datalen-forelen+1:datalen+forelen-1);
y1 = infldata(end-forelen+2:end);
plot(x1, y1)
hold on
plot(x2, inflfore, 'r--')
title('heppend inflation and it''s forecast')

legend1 = sprintf('happend inflation');
legend2 = sprintf('inflation by forecasted data');
legend({legend1,  legend2}, 'Location','northeast')

xlabel('time'); ylabel('percent')
xlim([datetable(datalen-forelen+1) datetable(datalen+forelen-1)]); ylim([-inf inf])
xtickformat("yyyy-MM")

% creating data equivalence table
data4table = [consistnan(y1, length(y1), forelen, "data"), inflfore];
name4table = ["happend inflation", "forecast inflation"];
creattable(x2, data4table, name4table, 'comparing inflation')

%% histogram ploting
% happend inflation and forecasted inflation relative frequency histogram
figure()
h1 = histogram(infldata);
hold on
h2 = histogram(inflfore);
h1.Normalization = 'probability';
h1.BinWidth = 0.5;
h2.Normalization = 'probability';
h2.BinWidth = 0.5;

xline(mean(infldata), 'b', 'LineWidth', 2)
xline(median(infldata), 'k', 'LineWidth', 2)
xline(mean(inflfore), 'g', 'LineWidth', 2)
xline(median(inflfore), 'r', 'LineWidth', 2)
title('Past & Forecasted Inflation Relative Frequency')
xlabel('inflation'); ylabel('relative frequency')
legend1 = sprintf('past inflation');
legend2 = sprintf('forecasted inflation');
legend3 = sprintf('past mu = %.2f', mean(infldata));
legend4 = sprintf('past mode = %.2f', median(infldata));
legend5 = sprintf('forecasted mu = %.2f', mean(inflfore));
legend6 = sprintf('forecasted mode = %.2f', median(inflfore));
legend({legend1, legend2, legend3, legend4, legend5, legend6});
xlim([-2 inf]); ylim([0 inf])

% creating data equivalence table
data4table = [h1.Data, consistnan(y1, length(h1.Data), 0, "data")];
name4table = ["happend inflation", "forecast inflation"];
creattable(datetable(1, 1:length(h1.Data)), data4table, name4table, 'inflation historgram')

% happend inflation and forecasted inflation frequency histogram
figure()
h3 = histogram(infldata, 'FaceColor', 'b');
h3.BinWidth = 0.5;
hold on
h4 = histogram(inflfore, 'FaceColor', 'r');
h4.BinWidth = 0.5;
xline(mean(infldata), 'b', 'LineWidth', 2)
xline(median(infldata), 'k', 'LineWidth', 2)
xline(mean(inflfore), 'g', 'LineWidth', 2)
xline(median(inflfore), 'r', 'LineWidth', 2)
title('Past Inflation and Forecasted Inflation Frequency')
ylabel('frequency'); xlabel('inflation')
legend1 = sprintf('past inflation');
legend2 = sprintf('forecasted inflation');
legend3 = sprintf('past mu = %.2f', mean(infldata));
legend4 = sprintf('past mode = %.2f', median(infldata));
legend5 = sprintf('forecasted mu = %.2f', mean(inflfore));
legend6 = sprintf('forecasted mode = %.2f', median(inflfore));
legend({legend1, legend2, legend3, legend4, legend5, legend6});
xlim([-2 inf]); ylim([0 inf])

% recent happend inflation and forecasted inflation relative frequency histogram
figure()
y = infldata(end-compareperiod:end);
h5 = histogram(y, 'FaceColor', 'b');
hold on
h6 = histogram(inflfore, 'FaceColor', 'r');
h5.Normalization = 'probability';
h5.BinWidth = 0.5;
h6.Normalization = 'probability';
h6.BinWidth = 0.5;
xline(mean(y), 'b', 'LineWidth', 2)
xline(median(y), 'k', 'LineWidth', 2)
xline(mean(inflfore), 'g', 'LineWidth', 2)
xline(median(inflfore), 'r', 'LineWidth', 2)
title([num2str(compareperiod) ' Period of Past & forecasted Inflation Relative Frequency'])
xlabel('inflation'); ylabel('relative frequency')
legend1 = sprintf('past inflation');
legend2 = sprintf('forecasted inflation');
legend3 = sprintf([num2str(compareperiod), 'recent mu = %.2f'], mean(y));
legend4 = sprintf([num2str(compareperiod), 'recent mode = %.2f'], median(y));
legend5 = sprintf('forecasted mu = %.2f', mean(inflfore));
legend6 = sprintf('forecasted mode = %.2f', median(inflfore));
legend({legend1, legend2, legend3, legend4, legend5, legend6});

% creating data equivalence table
if length(h5.Data) > length(h6.Data)
    data4table = [h5.Data, consistnan(h6.Data, length(h5.Data), 0, "data")];
else
    data4table = [consistnan(h5.Data, length(h6.Data), 0, "data"), h6.Data];
end

name4table = ["recent happend inflation", "forecast inflation"];
creattable(datetable(1, end-length(data4table)-1:end), data4table, name4table, 'recent inflation historgram')

%% barchart data creating

%% plot barchart for comparing 3, 6, and 12 month inflation

%% drawing table
fprintf('\n%10s %16s\n', 'index', 'MPEin')
fprintf('  -----------------------------------------------------------------\n')
for i = 1:numvar
    fprintf('%8s %17.2f\n', convertStringsToChars(datasel(i)), MPEin(i))
end

%% granger causality
% h = gctest(bestmodel, 'Type', "exclude-all");
% h = gctest(estmodel, 'Type', "exclude-all");
% %%
% h = gctest(bestmodel);
% h = gctest(estmodel);
