function [MAPE, RevForData,ForData, ForMSE, NumSeries, resultSumm, selecteddata] = OptVECM(Numseries,maxlag,Mdata,TrainPercent,targetSeries)
n=size(Mdata,1);
cols = 1:Numseries;
numperiods = n-round(n*TrainPercent);
sumMAPE = 100;

for i=targetSeries
cols=cols(cols~=i);
end
otherseriesnumber = size(cols,2);

for j=1:otherseriesnumber
v = nchoosek(cols,j);
    for row=1:size(v,1)
        selectedcol = [targetSeries, v(row,:)];
        data = Mdata(:,selectedcol);
        for lag=0:maxlag
            for rank=0:size(data,2)
            model = vecm(size(data,2),rank,lag);
            MdataTrain =log(data(1:round(n*TrainPercent),:))*100;
            EstModel = estimate(model,MdataTrain);
            [ForData, ForMSE] = forecast(EstModel,n-round(n*TrainPercent),MdataTrain);
            RevForData =exp(ForData/100);
            MAPE = 100*sum(abs(data(round(n*TrainPercent)+1:end,:)-RevForData)./data(round(n*TrainPercent)+1:end,:))/(numperiods);
            if MAPE(1,1:size(targetSeries,2))<sumMAPE
                sumMAPE =MAPE(1,1:size(targetSeries,2));
            end
            end
        end
    end
end

NumSeries = model.NumSeries;
resultSumm = summarize(model);
selecteddata = Mdata(:,selectedcol);
end

