function [hJ,hL,hH] = diagtest(ResidualP)
% Normality test
% h=1 means <h0=data is normal> rejected
fprintf(['Normality test\n h=1 means <h0=data is normal> rejected\n' ...
    '+___________+\n'])
hJ = zeros(1,size(ResidualP,2));
for nn = 1:size(ResidualP,2)
    if jbtest(ResidualP(:,nn))==1
        hJ(1,nn)=jbtest(ResidualP(:,nn));
    end
end

% Serial correlation
% h=1 means <h0=no autocorrelation> rejected
fprintf(['Ljung box test for serial correlation\n h=1 means <h0=no autocorrelation> rejected\n' ...
    '+___________+\n'])
hL = zeros(1,size(ResidualP,2));
for n = 1:size(ResidualP,2)
    if jbtest(ResidualP(:,n))==1
        hL(1,n)=lbqtest(ResidualP(:,n));
    end
end
% Heteroscedasticity
% h=1 means <h0=no conditional heteroscedasticity> rejected
fprintf(['Engel"s test for conditional heteroscedasticity\n h=1 means <h0=no conditional heteroscedasticity> rejected\n' ...
    '+___________+\n'])
hH = zeros(1,size(ResidualP,2));
for z = 1:size(ResidualP,2)
    if jbtest(ResidualP(:,z))==1
        hH(1,z)=lbqtest(ResidualP(:,z));
    end
end