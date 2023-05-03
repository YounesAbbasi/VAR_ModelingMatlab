function creattable(datetable, data, datasel, excelname)
[datalen, numvar] = size(data);

sz = [datalen numvar+1];
varTypes = {'datetime'};
varNames = {'time'};
for i = 1:numvar
    varTypes{i+1} = 'double';
    varNames{i+1} = convertStringsToChars(datasel(i));
end
T2 = table('Size', sz, 'VariableTypes', varTypes, 'VariableNames', varNames);
T2.time = datetable(1, 1:datalen)';
for i = 1:numvar
    T2(:, i+1) = table(data(:, i));
end
writetable(T2, [excelname '.xlsx'], 'Sheet', 1);
