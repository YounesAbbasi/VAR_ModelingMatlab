function [scaled, maxs] = scaling(numvar,data)
data2 = nan(size(data, 1),numvar);
maxs = nan(1, numvar);
minmaxdata = max(max(abs(data)));
counter = 1;
for i = 1:numvar
    maxs(1, i)= max(abs(data(:, i)));
    data2(:, i) = data(:, i)/maxs(1, i);
    if max(abs(data(:, i))) < minmaxdata
        minmaxdata = max(abs(data(:, i)));
    end
    counter = counter + 1;
end
scaled = data2 * minmaxdata;
