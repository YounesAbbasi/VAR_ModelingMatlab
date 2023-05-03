function bestlag = lagfind(maxlag, numvar, forelen, testlen, traindata, data)
maxforlag = 1e10;
% fprintf('mean of MPE is: \n')
for i = 1:maxlag
    model = varm(numvar, i);   % model definition
    estmodel = estimate(model, traindata, 'Y0', data(1:i, :));   % model estimation
    aic = summarize(estmodel).AIC;
    bic = summarize(estmodel).BIC;
    
    if isequal(traindata, data)
        binsample = forecast(estmodel, forelen, data(1:end-forelen, :));
        MPE = 100 * sum(abs(data(end-forelen+1:end, :) - binsample) ./ abs(data(end-forelen+1:end, :))) / forelen;
    else
        outsample = forecast(estmodel, forelen, traindata);
        MPE = 100 * sum(abs(data(end-testlen+1:end, :) - outsample(1:testlen, :)) ./ abs(outsample(1:testlen, :))) / testlen;
    end
%     fprintf('\t%0d', i)
%     fprintf(':\t%0.2f\n', mean(MPE))
    if maxforlag > mean(MPE)
        lagleni = i;
        maxforlag = mean(MPE);
    end
end
bestlag = lagleni;
fprintf(' \noptimal lag length subject to prediction:')
fprintf('\t%0d\n', bestlag)
end
% insample = forecast(estmodel, forelen, tdata(1:end-forelen, :));
% MPEin = 100 * sum(abs(data(end-forelen+1:end, :) - insample) ./ data(end-forelen+1:end, :)) / forelen;
