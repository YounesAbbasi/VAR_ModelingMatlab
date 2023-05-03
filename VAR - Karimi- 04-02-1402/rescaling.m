function unrealrescaled = rescaling(data, cpinum, maxs, datalen, numvar)

unrealrescaled = nan(datalen, numvar);
for i = 1:numvar
    if ne(i, cpinum)
        unrealrescaled(:, i) = (data(:, i) * maxs(1, i) / maxs(1, end)) / 100;
    else
        unrealrescaled(:, i) = data(:, cpinum);
    end
end
