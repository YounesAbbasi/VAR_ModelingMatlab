function revdata = revdiff(data, initial)

[a, b] = size(data);
revdata = nan(a+1, b);
for i = 1:size(data, 2)
    revdata(:, i) = cumsum([initial(i); data(:, i)]);
end
revdata(1, :) = [];
