function out = magseal_test_layer_growth(p,seal,guidance,makePlots)
% TEST 1B: Optimistic LAYER ACCUMULATION kinetic proxy.
% This assumes all incoming MENPs stick and form a spatially uniform layer,
% even though magnetic transport does NOT itself prove adhesion, interparticle
% bonds, or an airtight film. Thus times shown are *best-case transport only*.
if nargin < 4,makePlots=true;end
vNP=max(0,guidance.configurations(1).startSpeedInward); % at 8 mm, centered coil
transferCrossSection=2*pi*(p.dPatch/2)*p.coatingThickness;
phi=p.mobileMENPVolumeFraction;
% Compact spherical agglomerates: v ~ (volume)/(Stokes diameter) ~ d^2.
% Clusters are not independent nanoparticles and can jam/become immobilized.
scale=[1 10 100];
labels={'100 nm MENP','1 um compact aggregate','10 um compact aggregate'};
t=(0:1:300)';
rate=zeros(1,numel(scale)); needTime=zeros(size(rate));
height=zeros(numel(t),numel(scale));
layerTime=zeros(size(rate));
Apatch=seal.patchArea;
for j=1:numel(scale)
    v=vNP*scale(j)^2;
    rate(j)=transferCrossSection*phi*p.rhoMENP*v; % kg/s, no losses
    needTime(j)=seal.neededMenpKg/max(rate(j),realmin);
    height(:,j)=min(seal.availableMenpKg,rate(j)*t)/ ...
        (Apatch*(1-p.layerPorosity)*p.rhoMENP);
    layerTime(j)=(p.particleDiameter*scale(j))* ...
        Apatch*(1-p.layerPorosity)*p.rhoMENP/max(rate(j),realmin);
end
fprintf('\n=== TEST 1B: OPTIMISTIC MATERIAL DEPOSITION RATE ===\n');
fprintf('Uses 8-mm coil gradient as CONSTANT donor-front velocity, 100%% sticking.\n');
for j=1:numel(scale)
    fprintf('%s: drift %.3g um/s; 1 nominal layer %.2g s; 100-um film %.3g h\n', ...
        labels{j},vNP*scale(j)^2*1e6,layerTime(j),needTime(j)/3600);
    fprintf('   Height after 300 s: %.4f um\n',height(end,j)*1e6);
end
fprintf('No deposition chemistry, nanolayer growth mechanism, or strength validated.\n');
if makePlots
    figure('Name','MAGSEAL test 1B - layer-by-layer timing','Color','w');
    tiledlayout(2,1);
    nexttile;
    plot(t,height*1e6,'LineWidth',1.8);
    yline(p.targetStackThickness*1e6,'k--','Target 100 um');
    ylabel('Uniform equivalent film thickness (um)');
    title('Optimistic no-loss accumulation from adjacent wall (300 s)');
    legend(labels,'Location','northwest');grid on;
    nexttile;
    bar(needTime/3600);set(gca,'XTickLabel',labels);
    ylabel('Optimistic time to accumulate 100-um layer (hours)');
    set(gca,'YScale','log');grid on;
    title('A 10-um aggregate is a microscale cluster, not a free MENP');
end
out=struct('particleSizesM',p.particleDiameter*scale,'fluxKgPerS',rate, ...
    'timeToTargetS',needTime,'timeOneLayerS',layerTime, ...
    'heightAfter300sM',height(end,:));
end
