% MAGSEAL HOUR 4 — closed-loop pressure + magnetic motion + assumed sealing.
% Save all files in one folder. Run: run_magseal_hour4
% Works with MATLAB alone; additional Simulink pressure replay is optional.
clearvars; clc;
p=magseal_parameters();
q=magseal_hour3_parameters();
s=magseal_hour4_parameters();

% Do not silently allow old 8-mm values when user runs from a different folder.
assert(abs(p.holeDiameter-0.006)<1e-10, ...
    'Expected 6-mm updated magseal_parameters.m; check Current Folder.');

baseline=magseal_run_hour4_case(p,q,s);
qOff=q; qOff.fieldScale=0;
noRepair=magseal_run_hour4_case(p,qOff,s);
qWeak=q; qWeak.fieldScale=0.05;
weakField=magseal_run_hour4_case(p,qWeak,s);
sBadLatch=s; sBadLatch.latchCapacity=4;
badLatch=magseal_run_hour4_case(p,q,sBadLatch);
sPartial=s; sPartial.contactQuality=0.60;
partial=magseal_run_hour4_case(p,q,sPartial);

cases={baseline,noRepair,weakField,badLatch,partial};
caseNames={'Full assumed contact','No actuation','Weak field (5%)', ...
           'Latch too weak (4 N)','Partial contact (60%)'};

fprintf('\nMAGSEAL HOUR 4 | Sensor -> motion -> membrane/latch -> pressure\n');
fprintf('WARNING: Contact quality and latch capacity are assumed, not measured.\n');
fprintf('Puncture: %.1f mm | membrane: %.1f mm | radial overlap: %.1f mm\n', ...
    p.holeDiameter*1e3,s.membraneDiameter*1e3,baseline.radialOverlap*1e3);
fprintf('Pressure load: %.3f N; target with SF %.1f: %.3f N; assumed latch: %.2f N\n', ...
    p.P0*p.area,s.retentionSafetyFactor,p.P0*p.area*s.retentionSafetyFactor,s.latchCapacity);
fprintf('Baseline detection: %.2f s; arrivals: %d/%d; last arrival: %.2f s; seat: %.2f s\n', ...
    baseline.detectionTime,baseline.nArrived,q.nTiles, ...
    baseline.lastArrivalTime,baseline.sealEngagementTime);
fprintf('\n%-26s  %-9s %-11s %-12s %-12s\n','CASE','Arrived', 'Seal at s','P(40s) kPa','A_eff / A0');
for i=1:numel(cases)
    z=cases{i};
    fprintf('%-26s  %2d/%-6d %-11.2f %-12.3f %-12.3f\n', ...
        caseNames{i},z.nArrived,q.nTiles,z.sealEngagementTime, ...
        z.pressurePa(end)/1000,z.effectiveArea(end)/p.area);
end

figure('Name','MAGSEAL HOUR 4 | pressure comparison','Color','w');
hold on;
for i=1:numel(cases)
    plot(cases{i}.t,cases{i}.pressurePa/1000,'LineWidth',1.6);
end
xline(p.tPuncture,':','Puncture');
if isfinite(baseline.detectionTime),xline(baseline.detectionTime,'--','Sensor');end
if isfinite(baseline.sealEngagementTime),xline(baseline.sealEngagementTime,':','Contact');end
xlabel('Time (s)'); ylabel('Cabin pressure (kPa)');
title('MAGSEAL | Pressure response under explicit design assumptions');
legend(caseNames,'Location','southwest'); grid on;

figure('Name','MAGSEAL HOUR 4 | seal state and leakage','Color','w');
tiledlayout(3,1,'TileSpacing','compact');
nexttile;
plot(baseline.t,baseline.blockedFraction*100,'LineWidth',1.6); hold on;
plot(partial.t,partial.blockedFraction*100,'--','LineWidth',1.4);
ylabel('Area blocked (%)'); ylim([-5 105]);
legend('Full assumed contact','Partial contact','Location','best'); grid on;
nexttile;
plot(baseline.t,baseline.leakMassFlow*1e3,'LineWidth',1.7);hold on;
plot(noRepair.t,noRepair.leakMassFlow*1e3,'--','LineWidth',1.4);
ylabel('Mass leak (g/s)'); legend('Assumed seal','No repair','Location','best'); grid on;
nexttile;
plot(baseline.t,1e3*baseline.gap,'LineWidth',0.9);
ylabel('Remaining travel (mm)');xlabel('Time (s)'); grid on;
sgtitle('Arrival, coverage and leakage are connected; true gasket contact mechanics omitted');

% Save comparison arrays + reproducible data for pitch charts.
save('MAGSEAL_Hour4_Results.mat','p','q','s','baseline','noRepair','weakField','badLatch','partial');
summary=table(string(caseNames(:)),cellfun(@(z)z.nArrived,cases)', ...
    cellfun(@(z)z.sealEngagementTime,cases)', ...
    cellfun(@(z)z.pressurePa(end)/1000,cases)', ...
    cellfun(@(z)z.effectiveArea(end)/p.area,cases)', ...
    'VariableNames',{'Scenario','ModulesArrived','SealTime_s','Pressure40s_kPa','FinalAreaRatio'});
writetable(summary,'MAGSEAL_Hour4_Scenarios.csv');
assignin('base','magsealHour4Baseline',baseline);
assignin('base','magsealHour4Cases',cases);
fprintf('\nSaved MAGSEAL_Hour4_Results.mat and MAGSEAL_Hour4_Scenarios.csv\n');
fprintf('OPTIONAL Simulink pressure replay: run_magseal_hour4_simulink\n');
