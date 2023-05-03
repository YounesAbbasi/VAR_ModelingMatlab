function completemat = consistnan(mat, datalen, forelen, flag)
% forelen: how many data you want to add
% datalen: how many length of data should be
[matlen, varnum] = size(mat);
if flag == "data"
    if length(mat) == datalen
        completemat = [mat; nan(forelen, varnum)];
    elseif length(mat) < datalen
        completemat = [mat; nan((datalen-length(mat))+forelen, varnum)];
    end
    
elseif flag == "outsample"
    completemat = [nan(datalen+forelen-matlen, varnum); mat];
    
elseif flag == "insample"
    completemat = [nan(datalen-forelen, varnum); mat; nan(forelen, varnum)];
end
