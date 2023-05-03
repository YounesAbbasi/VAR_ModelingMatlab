function [simumean, simustd] = simulationrun(bestmodel, boutsample, forelen, data, NumPaths)
simu = simulate(bestmodel,forelen,'Y0',data(end-25:end,:),'NumPaths',NumPaths);
simumean = mean(simu, 3);
simustd = std(simu, 0, 3);
for i = 1:4
    figure()
    plot(simumean(:, i)-2*simustd(:, i))
    hold on
    plot(simumean(:, i))
    plot(boutsample(:, i))
    plot(simumean(:, i)+2*simustd(:, i))
end
