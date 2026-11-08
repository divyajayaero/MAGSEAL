% MAGSEAL HOUR 3 — sensor command (Hour 2) -> 12 magnetic tile dynamics.
% Keep all Hour 2 files in this same folder; Hour 2 model is not modified.
clearvars; clc;
p = magseal_parameters();
q = magseal_hour3_parameters();
assignin('base','p',p);
flowCoefficient=p.Cd*sqrt(p.gamma/(p.R*p.T))* ...
    (2/(p.gamma+1))^((p.gamma+1)/(2*(p.gamma-1)));
assignin('base','flowCoefficient',flowCoefficient);

if ~exist('MAGSEAL_Hour2.slx','file')
    fprintf('Hour 2 Simulink model not found; generating it now...\n');
    build_magseal_hour2;
end
out=sim('MAGSEAL_Hour2');
P=out.get('magsealPressure');
cmd=out.get('magsealCoilCommand');
t=(0:p.dt:p.tEnd)';
% Zero-order hold: avoids erroneous interpolation through the 0->1 command.
command=interp1(cmd.Time,double(cmd.Data(:)),t,'previous','extrap');
command=max(0,min(1,command));

base=magseal_simulate_tiles(t,command,q);
qWeak=q; qWeak.fieldScale=0.05; % intentionally weak, may stall
weak=magseal_simulate_tiles(t,command,qWeak);
noMag=magseal_simulate_tiles(t,zeros(size(command)),q);

idx=find(command>=0.5,1,'first');
if isempty(idx), tDetect=NaN; else,tDetect=t(idx);end
fprintf('\nMAGSEAL HOUR 3 - 1D guided tile dynamics (illustrative inputs)\n');
fprintf('Sensor activation: %.3f s\n',tDetect);
fprintf('Baseline arrivals: %d/%d\n',base.numArrived,q.nTiles);
fprintf('Weak field (5%%): %d/%d arrived\n',weak.numArrived,q.nTiles);
fprintf('Field disabled: %d/%d arrived\n',noMag.numArrived,q.nTiles);
for i=1:q.nTiles
    fprintf('Tile %2d | initial travel %5.1f mm | arrival %8.3f s\n',...
        i,1000*q.initialGap(i),base.arrivalTime(i));
end
if all(base.reached)
    fprintf('Last tile reached target at %.3f s. Not a sealed-patch claim.\n',max(base.arrivalTime));
end

figure('Name','MAGSEAL Hour 3 | magnetic module dynamics','Color','w');
tiledlayout(4,1,'TileSpacing','compact');

nexttile;
plot(P.Time,double(P.Data(:))/1000,'LineWidth',1.5); hold on;
xline(p.tPuncture,':','Puncture');
if isfinite(tDetect), xline(tDetect,'--','Sensor detects'); end
ylabel('Pressure (kPa)');
title('Hour 2 pressure model (sealing feedback not yet implemented)'); grid on;

nexttile;
plot(t,1000*base.gap,'LineWidth',1.0); hold on;
plot(t,1000*weak.gap(:,end),'k--','LineWidth',1.5);
ylabel('Remaining travel (mm)');
title('12 baseline modules (solid); farthest module with weak field (dashed)'); grid on;

nexttile;
plot(t,1000*base.magneticForce(:,1),'LineWidth',1.4); hold on;
plot(t,1000*base.magneticForce(:,end),'LineWidth',1.4);
ylabel('Magnetic force (mN)');
title('Actual simulated magnetic force — no artificial rescaling');
legend('Nearest module','Farthest module','Location','best'); grid on;

nexttile;
stairs(t,command,'LineWidth',1.4); hold on;
plot(t,base.fieldFraction,'LineWidth',1.4);
ylabel('Normalized activation'); xlabel('Time (s)'); ylim([-0.05 1.05]);
legend('Sensor coil command','Coil field response','Location','best');grid on;

sgtitle('MAGSEAL Hour 3 | Module arrival is NOT seal verification');

% Store for exploration and possible Hour 4 extension.
assignin('base','magsealHour3',base);
assignin('base','magsealHour3Weak',weak);
assignin('base','magsealHour3Params',q);
