%% MAGSEAL — Single coil assumed positioned over a known 6-mm puncture
% No coil-positioning robot is simulated. A future manipulator positions the
% coil concentrically with the puncture at a 4-mm cabin-side standoff.
% This script tests lateral force, wall-normal force, and guided motion.
% One coil, multiple magnetization scenarios, no extra toolboxes.
% IMPORTANT: CoFe2O4-BaTiO3 (MENP) and NdFeB carrier magnetic moments here
% are only screening estimates. None is a measured MAGSEAL actuator moment.
clearvars; close all; clc;

cfg.holeDiameter = 0.006;            % [m] 6-mm pressure-shell puncture
cfg.coilRadius = 0.004;             % [m] assumed coil radius
cfg.standoff = 0.004;               % [m] coil plane 4 mm cabin-side of lining
cfg.turns = 200;                    % assumed tightly packed, thin circular turns
cfg.initialRadius = 0.008;          % [m] local material starts 8 mm from hole
cfg.captureRadius = cfg.holeDiameter/2; % arrival at 3-mm hole radius
cfg.frictionStatic = 0.002;         % [N] assumed for guided carrier
cfg.frictionKinetic = 0.0015;       % [N] assumed for guided carrier
cfg.damping = 0.60;                 % [N s/m] assumed
cfg.speedLimit = 0.025;             % [m/s] imposed speed limit
cfg.rampTime = 0.25;                % [s] assumed actuator current response
cfg.tFinal = 12;                    % [s] after coil is in position
cfg.dt = 0.01;                      % [s]
cfg.step = 5e-5;                    % [m] field-gradient difference step
cfg.cabinPressure = 101325;        % [Pa]
cfg.outerPressure = 0;             % [Pa]
cfg.nTestPaths = 12;                % 12 angular starting positions

% Comparable 3-gram guided carriers, NOT individual nanoparticles.
scenarios(1) = struct('name','NdFeB composite carrier, 1 A', ...
    'moment',0.013116,'current',1.0);
scenarios(2) = struct('name','MENP composite carrier, 1 A', ...
    'moment',0.001794,'current',1.0);
scenarios(3) = struct('name','MENP composite carrier, 2 A (thermal risk)', ...
    'moment',0.001794,'current',2.0);

fprintf('\nMAGSEAL - IDEALLY CENTERED, ROBOT-POSITIONED SINGLE COIL\n');
fprintf('Robot positioning: ASSUMED instantaneous and exact, not solved.\n');
fprintf('Puncture: %.1f mm, coil standoff: %.1f mm cabin-side.\n', ...
    1e3*cfg.holeDiameter,1e3*cfg.standoff);
pressureLoad = (cfg.cabinPressure-cfg.outerPressure)*pi*cfg.captureRadius^2;
fprintf('Pressure load across hole: %.3f N (NOT carried by magnetic actuation).\n',pressureLoad);

rr = linspace(cfg.captureRadius,cfg.initialRadius,130)';
Fr=zeros(numel(rr),numel(scenarios));
Fz=Fr;
res=cell(numel(scenarios),1);
summary=cell(numel(scenarios),6);
for k=1:numel(scenarios)
    sc=scenarios(k);
    for i=1:numel(rr)
        [dBdr,dBdz]=coilMagnitudeGradient(rr(i),cfg.standoff,cfg,sc.current);
        Fr(i,k)=sc.moment*dBdr;
        Fz(i,k)=sc.moment*dBdz;
    end
    res{k}=simulateRadial(sc,cfg);
    [startGr,startGz]=coilMagnitudeGradient(cfg.initialRadius,cfg.standoff,cfg,sc.current);
    startInward=max(0,-sc.moment*startGr);
    startNormal=abs(sc.moment*startGz);
    fprintf('\n%s\n',sc.name);
    fprintf('  Start inward force: %.3f mN vs %.3f mN assumed static friction\n', ...
        1e3*startInward,1e3*cfg.frictionStatic);
    fprintf('  Cabin-side lifting force magnitude at start: %.3f mN\n',1e3*startNormal);
    if res{k}.arrived
        fprintf('  Guided carrier ARRIVES in %.2f s after coil activation.\n',res{k}.arrivalTime);
    else
        fprintf('  NO ARRIVAL within %.1f s.\n',cfg.tFinal);
    end
    summary(k,:)={sc.name,sc.current,sc.moment,1e3*startInward, ...
        res{k}.arrived,res{k}.arrivalTime};
end

% Figure 1: Can a single centered field move a guided composite carrier?
figure('Name','MAGSEAL - position assumed: lateral and normal forces', ...
    'Color','w','Position',[120 120 1080 490]);
tiledlayout(1,2,'TileSpacing','compact');
nexttile; hold on;
for k=1:numel(scenarios)
    plot(1e3*rr,1e3*(-Fr(:,k)),'LineWidth',1.8);
end
yline(1e3*cfg.frictionStatic,'k--','Assumed static friction');
xlabel('Distance from puncture center (mm)');
ylabel('Inward radial magnetic force (mN)');
title('Does the field initiate inward guided motion?');grid on;
legend({scenarios.name},'Location','northwest');
nexttile; hold on;
for k=1:numel(scenarios)
    plot(1e3*rr,1e3*abs(Fz(:,k)),'LineWidth',1.8);
end
xlabel('Distance from puncture center (mm)');
ylabel('Wall-normal attraction toward cabin-side coil (mN)');
title('Guides / captive layer must resist lift-off');grid on;
exportgraphics(gcf,'MAGSEAL_PositionAssumed_Forces.png','Resolution',150);

% Figure 2: Actuation time once the robotic arm is already positioned.
figure('Name','MAGSEAL - radial trajectories from an 8-mm start', ...
    'Color','w','Position',[140 140 900 470]); hold on;
for k=1:numel(scenarios)
    plot(res{k}.t,1e3*res{k}.radius,'LineWidth',2);
end
yline(1e3*cfg.captureRadius,'k--','Puncture edge / arrival');
xlabel('Time since coil activation (s)');
ylabel('Remaining distance to puncture center (mm)');
title('Motion of 3-g guided carriers; robot positioning omitted');
legend({scenarios.name},'Location','best');grid on;
exportgraphics(gcf,'MAGSEAL_PositionAssumed_Arrival.png','Resolution',150);

% Pressure retention and polymer curing are intentionally NOT inferred
% from the carrier reaching the puncture edge.
T=cell2table(summary,'VariableNames',{'Scenario','Current_A', ...
    'Moment_A_m2','InwardStartForce_mN','Arrived','ArrivalAfterActuation_s'});
writetable(T,'MAGSEAL_PositionAssumed_Results.csv');
save('MAGSEAL_PositionAssumed_Results.mat','cfg','scenarios','res','T','Fr','Fz','rr');

fprintf('\nIMPORTANT: Arrival is NOT a pressure seal; no 3-D contact, curing,\n');
fprintf('actual coil heat dissipation, or robot deployment is predicted here.\n');
fprintf('Results saved to two PNGs, a CSV, and a MAT file.\n');

function out=simulateRadial(sc,cfg)
    n=round(cfg.tFinal/cfg.dt);
    ts=(0:n)'*cfg.dt;
    rad=zeros(n+1,1);rad(1)=cfg.initialRadius;
    arrived=false;arrival=NaN;
    for j=2:n+1
        t=ts(j-1);
        ramp=1-exp(-t/cfg.rampTime);
        [gradR,~]=coilMagnitudeGradient(rad(j-1),cfg.standoff,cfg,sc.current);
        inward=max(0,-sc.moment*gradR*ramp);
        if inward<=cfg.frictionStatic
            v=0;
        else
            v=min(cfg.speedLimit,max(0,(inward-cfg.frictionKinetic)/cfg.damping));
        end
        rad(j)=max(cfg.captureRadius,rad(j-1)-cfg.dt*v);
        if rad(j)<=cfg.captureRadius
            arrived=true;arrival=ts(j);
            rad(j:end)=cfg.captureRadius;
            break
        end
    end
    if ~arrived
        j=n+1;
    end
    out.t=ts;out.radius=rad;out.arrived=arrived;out.arrivalTime=arrival;
end

function [dBdr,dBdz]=coilMagnitudeGradient(r,z,cfg,I)
    h=cfg.step;
    dBdr=(coilBmag(r+h,z,cfg,I)-coilBmag(r-h,z,cfg,I))/(2*h);
    dBdz=(coilBmag(r,z+h,cfg,I)-coilBmag(r,z-h,cfg,I))/(2*h);
end

function mag=coilBmag(r,z,cfg,I)
    % Finite-radius circular thin-loop Biot-Savart field, times turns.
    % r is cylindrical radius; z is absolute normal offset from coil plane.
    mu0=4*pi*1e-7; a=cfg.coilRadius;
    ap=(a+r)^2+z^2;bm=(a-r)^2+z^2;
    m=min(4*a*r/ap,1-1e-12);
    [K,E]=ellipke(m);
    fac=mu0*cfg.turns*I/(2*pi*sqrt(ap));
    bz=fac*(K+(a*a-r*r-z*z)*E/bm);
    if r>1e-12
        br=fac*z/r*(-K+(a*a+r*r+z*z)*E/bm);
    else
        br=0;
    end
    mag=hypot(br,bz);
end
