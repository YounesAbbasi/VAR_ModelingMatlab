function [StationMat]=stationData(Mdata)

[n,c]=size(Mdata);
StationMat = zeros(n-1,c);
for z=1:c
    if 1 == adftest(Mdata(:,z))
        disp("It's Station")
        disp(z)
        StationMat(:,z)=Mdata(2:end,z);
    else
        if  1 == adftest(diff(Mdata(:,z)))
            disp('Diff station')
            StationMat(:,z)=Mdata(2:end,z);
        else
            if 1 == adftest(log(Mdata(:,z)))
            disp('log station')
            disp(z)
            StationMat(:,z)=log(Mdata(:,z));
            else 
                if 1 == adftest(diff(log(Mdata(:,z))))
                disp('percent change station')
                disp(z)
                StationMat(:,z)=diff(log(Mdata(:,z)));
                end
            end
        end
    end
end