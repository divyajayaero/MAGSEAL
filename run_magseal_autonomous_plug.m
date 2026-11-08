% MAGSEAL: autonomously guided magnetic-elastomer head + curable hole-filling gel.
% Run from THIS directory: run_magseal_autonomous_plug
% No Simulink or specialized toolboxes needed. Numerical screening only.
clearvars; clc;
p=magseal_plug_parameters();

names={ ...
    'HYBRID: magnet + retained polymer plug', ...
    'Dry MENP powder only', ...
    'Magnetic microcapsules, no backing', ...
    'Magneto-elastomer cover only', ...
    'Hybrid: weak coil (12% current)', ...
    'Hybrid: insufficient reservoir', ...
    'Hybrid: weak mechanical retention', ...
    'Hybrid: very viscous gel', ...
    'Hybrid: leaky post-cure edge', ...
    'Hybrid: one coil 18-mm travel', ...
    'Hybrid: puncture not located', ...
    'Hybrid: 10-mm puncture', ...
    'Hybrid: MENP-only carrier moment' ...
    };
cases=cell(1,numel(names));
cases{1}=p;
cases{2}=p;cases{2}.enableElastomerHead=false;cases{2}.enableFillingGel=false;cases{2}.enableCuring=false;
cases{3}=p;cases{3}.enableElastomerHead=false;cases{3}.latchCapacity=0;
cases{4}=p;cases{4}.enableFillingGel=false;
cases{5}=p;cases{5}.coilCurrent=0.12;
cases{6}=p;cases{6}.reservoirThickness=0.00005;cases{6}.recoverableFraction=0.25;
cases{7}=p;cases{7}.latchCapacity=4;
cases{8}=p;cases{8}.gelViscosity=30;
cases{9}=p;cases{9}.residualOpenAfterCure=0.02;
cases{10}=p;cases{10}.petalStartRadius=0.018;
cases{11}=p;cases{11}.localizationSuccessful=false;
cases{12}=p;cases{12}.dHole=0.010;
cases{13}=p;cases{13}.effectiveMoment=0.001794; % CoFe2O4-BaTiO3 remanence estimate

z=cell(size(cases));
for i=1:numel(cases)
    z{i}=magseal_screen_case(cases{i});
end
base=z{1};
fprintf('\nMAGSEAL AUTONOMOUS PLUG - MODEL-BASED DESIGN SCREEN\n');
fprintf('No experimental validation is implied. Unmeasured bonding, cure and permeability are assumptions.\n\n');
fprintf('Hole %.1f mm | pressure force %.3f N | required retention %.3f N\n', ...
  base.dHole_mm,base.pressureForce_N,base.requiredRetention_N);
fprintf('Fill required %.1f uL; usable local reservoir %.1f uL; dispensed %.1f uL\n', ...
  base.fillVolume_uL,base.availableVolume_uL,base.dispensedRequired_uL);
fprintf('Coil gradients: 8-mm = %.3f T/m, 18-mm = %.4f T/m\n', ...
  base.gradientNear_Tpm,base.gradientFar_Tpm);
fprintf('Carrier force: 8-mm = %.2f mN; 18-mm = %.3f mN; static friction = %.2f mN\n', ...
  base.forceNear_mN,base.forceFar_mN,p.staticFriction*1e3);
fprintf('Computed head travel time = %.2f s; model gel flow = %.2f uL/s\n', ...
  base.headMotionTime_s,base.gelFlow_uLps);
fprintf('Baseline times: detection %.2f; head %.2f; fill %.2f; cure %.2f seconds\n', ...
  base.detectionTime,base.headTime,base.filledTime,base.curedTime);
fprintf('Single coil estimated R=%.2f ohm? Power=%.2f W, ideal no-cooling rise=%.1f K\n', ...
  base.coilPower_W/max(p.coilCurrent^2,eps),base.coilPower_W,base.coilAdiabaticRise_K);
fprintf('Thermal screening flag (uncooled coil): %d [1 means further heat-sink design required]\n',base.needsThermalDesign);
fprintf('WARNING: adiabatic rise is an upper bound; electrical/thermal feasibility NOT validated.\n\n');

fprintf('%-43s | %-8s | %-8s | %-9s | %-11s\n', ...
  'SCENARIO','Head s','Cure s','P(900)kPa','Leak mg/s');
for i=1:numel(z)
 fprintf('%-43s | %8.2f | %8.2f | %9.3f | %11.3f\n', ...
     names{i},z{i}.headTime,z{i}.curedTime, ...
     z{i}.pressure(end)/1e3,z{i}.massLeak(end)*1e6);
end

figure('Name','MAGSEAL: first-minute response','Color','w');
subplot(2,1,1);
hold on;
subset=[1 2 4 5 7 9];
for j=subset
  plot(z{j}.time,z{j}.pressure/1e3,'LineWidth',1.5);
end
xlim([0 60]);ylabel('Cabin pressure (kPa)');grid on;
legend(names(subset),'Interpreter','none','Location','southwest');
title('First 60 seconds: temporary pressure reduction vs. no seal');
subplot(2,1,2);
semilogy(base.time,max(base.massLeak*1e6,1e-5),'LineWidth',1.8);hold on;
semilogy(z{2}.time,max(z{2}.massLeak*1e6,1e-5),'--','LineWidth',1.4);
xlim([0 900]);ylim([1e-3 1e5]);
legend('Hybrid (assumed cured leakage)','No repair','Location','northeast');
xlabel('Time (s)');ylabel('Air leakage (mg/s)');grid on;
title('Cure-dependent, ASSUMED leakage - NOT measured airtightness');

figure('Name','MAGSEAL: physical design limits','Color','w');
subplot(2,2,1);
bar([base.forceNear_mN base.forceFar_mN p.staticFriction*1e3]);
set(gca,'XTickLabel',{'8-mm coil','18-mm coil','Friction'});
ylabel('Magnetic or friction force (mN)');title('Single coil: near vs. far');grid on;
subplot(2,2,2);
bar([base.fillVolume_uL base.availableVolume_uL base.dispensedRequired_uL]);
set(gca,'XTickLabel',{'Plug volume','Usable inventory','Required dispense'});
ylabel('Volume (uL)');title('Mass conservation / inventory');grid on;
subplot(2,2,3);
bar([base.pressureForce_N base.requiredRetention_N p.latchCapacity]);
set(gca,'XTickLabel',{'Pressure','3x target','Latch ASSUMED'});
ylabel('Force (N)');title('Retention is NOT the same as magnetic actuation');grid on;
subplot(2,2,4);
bar([z{1}.massLeak(end),z{9}.massLeak(end),z{2}.massLeak(end)]*1e6);
set(gca,'XTickLabel',{'Hybrid','Bad edge','No repair'});
ylabel('Final leak (mg/s)');title('Cured leakage assumptions determine outcome');grid on;

Scenario=string(names(:));
Head_s=cellfun(@(v)v.headTime,z)';
Cure_s=cellfun(@(v)v.curedTime,z)';
Pressure900_kPa=cellfun(@(v)v.pressure(end)/1e3,z)';
Leak900_mg_s=cellfun(@(v)v.massLeak(end)*1e6,z)';
InventoryOK=cellfun(@(v)v.inventoryOK,z)';
RetentionOK=cellfun(@(v)v.latchOK,z)';
Passes_ASSUMED_Leak_Target=cellfun(@(v)v.lowLeakFinal,z)';
summary=table(Scenario,Head_s,Cure_s,Pressure900_kPa,Leak900_mg_s, ...
  InventoryOK,RetentionOK,Passes_ASSUMED_Leak_Target);
writetable(summary,'MAGSEAL_Plug_ScenarioScreen.csv');
save('MAGSEAL_Plug_Results.mat','p','z','names','summary');
fprintf('\nSaved: MAGSEAL_Plug_ScenarioScreen.csv / MAGSEAL_Plug_Results.mat\n');
