% MAGSEAL Step 1: mass conservation, pressure sensor, seal comparison.
% Run from the folder containing these three .m files.
clear; clc; close all;
p = magseal_parameters();
t = (0:p.dt:p.tEnd)';
n = numel(t);
Popen = zeros(n,1);
Psealed = zeros(n,1);
mdotOpen = zeros(n,1);
mdotSealed = zeros(n,1);
Popen(1) = p.P0;
Psealed(1) = p.P0;
for k = 1:n-1
    if t(k) < p.tPuncture
        effectiveAreaOpen = 0;
        effectiveAreaSealed = 0;
    else
        effectiveAreaOpen = p.area;
        if t(k) < p.tSeal
            effectiveAreaSealed = p.area;
        else
            effectiveAreaSealed = p.area*p.residualAreaFraction;
        end
    end
    mdotOpen(k) = magseal_leak_rate(Popen(k),p.Pext,effectiveAreaOpen,p);
    mdotSealed(k) = magseal_leak_rate(Psealed(k),p.Pext,effectiveAreaSealed,p);
    % Ideal-gas pressure dynamics: P = mRT/V (T and V held constant).
    Popen(k+1) = max(p.Pext, Popen(k) - p.R*p.T/p.V*mdotOpen(k)*p.dt);
    Psealed(k+1) = max(p.Pext, Psealed(k) - p.R*p.T/p.V*mdotSealed(k)*p.dt);
end
% First sampled sensor crossing (without noise/filtering; added later).
detectIndex = find((Psealed <= p.P0 - p.sensorDropPa) & ...
                   (t >= p.tPuncture),1,'first');
if isempty(detectIndex)
    detectionTime = NaN;
else
    detectionTime = t(detectIndex);
end

figure('Color','w','Name','MAGSEAL | Pressure and Leak Flow');
tiledlayout(2,1,'TileSpacing','compact');
nexttile;
plot(t,Popen/1000,'r--','LineWidth',1.8); hold on;
plot(t,Psealed/1000,'b-','LineWidth',1.8);
xline(p.tPuncture,':k','Puncture');
xline(p.tSeal,':b','Assumed seal');
if ~isnan(detectionTime)
    xline(detectionTime,':m','Sensor detection');
end
ylabel('Absolute cabin pressure (kPa)');
legend('No repair','Assumed repair','Location','southwest');
grid on;
title('Pressure response — preliminary assumed-seal scenario');
nexttile;
plot(t,mdotOpen*1000,'r--','LineWidth',1.8); hold on;
plot(t,mdotSealed*1000,'b-','LineWidth',1.8);
xline(p.tPuncture,':k');
xline(p.tSeal,':b');
xlabel('Time (s)'); ylabel('Air mass leakage (g/s)');
legend('No repair','Assumed repair','Location','northeast'); grid on;

fprintf('Hole diameter: %.1f mm\n',p.holeDiameter*1000);
fprintf('Opening area: %.2f mm^2\n',p.area*1e6);
fprintf('Initial outward force on cover: %.2f N\n', ...
    (p.P0-p.Pext)*p.area);
fprintf('Initial leakage: %.2f g/s\n', ...
    magseal_leak_rate(p.P0,p.Pext,p.area,p)*1000);
fprintf('Sensor detection at t = %.2f s (threshold %.0f Pa)\n', ...
    detectionTime,p.sensorDropPa);
fprintf('Pressure at t = %.0f s: open %.2f kPa; assumed repair %.2f kPa\n', ...
    p.tEnd,Popen(end)/1000,Psealed(end)/1000);
fprintf('NOTE: Seal timing and residual area are ASSUMED, not validated.\n');
