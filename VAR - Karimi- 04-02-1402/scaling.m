function [scaled, maxs] = scaling(data, cpinum)
maxs = max(data);
maxs(1, end+1) = max(data(:, cpinum));
scaled = (data ./ maxs(1, 1:end-1)) * maxs(1, end);
maxs(1, cpinum) = 1;




% data2 = nan(size(data, 1),numvar);
% maxs = nan(1, numvar);
% minmaxdata = max(max(abs(data)));
% counter = 1;
% for i = 1:numvar
%     maxs(1, i)= max(abs(data(:, i)));
%     data2(:, i) = data(:, i)/maxs(1, i);
%     if max(abs(data(:, i))) < minmaxdata
%         minmaxdata = max(abs(data(:, i)));
%     end
%     counter = counter + 1;
% end
% 
% for i = 1:numvar
%     if maxs(1, i) == minmaxdata
%         maxs(1, i) = 1;
%     end
% end
% scaled = data2 * minmaxdata;
