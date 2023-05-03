function StationMat = makestation(data, datalen, numvar)

StationMat = zeros(datalen, numvar);
flag = 0;
for i = 1:numvar
    if adftest(data(:,i)) == 1
%         disp(1)
        StationMat(:,i) = data(:,i);
    elseif adftest(log(data(:,i))) == 1
%         disp(2)
        StationMat(:,i) = log(data(:,i));
    elseif adftest(diff(data(:,i))) == 1
%         disp(3)
        flag = 1;
        StationMat(2:end,i) = diff(data(:,i));
    elseif adftest(diff(log(data(:,i)))) == 1
%         disp(4)
        flag = 1;
        StationMat(2:end,i) = diff(log(data(:,i)));
    end
end

if flag == 1
    StationMat(1, :) = [];
end
