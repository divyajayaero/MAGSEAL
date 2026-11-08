function out = magseal_test_seal(p, makePlots)
% TEST 1: Can deposited MENP layers (or a MENP/polymer composite) resist a
% 6-mm pressure difference? This is a BOUND/SCREEN, not a contact mechanics
% or molecular sealing simulation. Requires a proven binder for actual seal.
if nargin < 2, makePlots = true; end
r = p.dHole/2; rp = p.dPatch/2;
Ahole = pi*r^2; Apatch = pi*rp^2;
Pin = p.P0; Pout = p.Poutside; dP = Pin - Pout;
Fpressure = dP*Ahole;
Aadhesion = Apatch - Ahole; % full overlap annulus: optimistic uniform shear
bondShearRequired = p.designSafetyFactor*Fpressure/Aadhesion;
% Approx. idealized tensile stress in a curved hemispherical unsupported
% film; lower-order proxy, not bending/contact analysis of a flat film.
filmStrengthRequired = p.designSafetyFactor*dP*r/(2*p.targetStackThickness);
% Kozeny-Carman permeability for uniformly packed spheres, continuum gas.
% Gas-slip/Knudsen flow, cracks, seams, and outflow are NOT modeled.
eps = p.layerPorosity; dp = p.particleDiameter;
permeability = dp^2*eps^3/(180*(1-eps)^2);
L = p.targetStackThickness;
mdarcy = permeability*Ahole*(Pin^2-Pout^2)/(2*p.muAir*L*p.Rair*p.T);
chokedFactor = sqrt(p.gamma/(p.Rair*p.T))* ...
    (2/(p.gamma+1))^((p.gamma+1)/(2*(p.gamma-1)));
mdotHole = p.Cd*Ahole*Pin*chokedFactor;
% min is only a convenient screening cap; not a rigorous series network.
mdotScreen = min(mdarcy,mdotHole);
solidVolume = Apatch*L*(1-eps);
needKg = solidVolume*p.rhoMENP;
sourceArea = pi*(p.donorOuterRadius^2-rp^2);
availKg = sourceArea*p.coatingThickness* ...
    p.mobileMENPVolumeFraction*p.rhoMENP;
% A dry stack has no justified tensile strength or adhesion, regardless of
% optimistic gas permeation calculation.
gasPass = mdotScreen <= p.acceptableAirLeakKgPerS;
massPass = availKg >= needKg;
mechanicalConditionalPass = p.hasContinuousBinder && ...
    p.exampleFilmTensileStrength >= filmStrengthRequired && ...
    p.exampleBondShearStrength >= bondShearRequired;
pass = gasPass && massPass && mechanicalConditionalPass;
% Sensitivity across thickness and porosity; no pass claims for bare powder.
por = [0.20 0.25 0.30 0.36 0.45];
thick = logspace(-5,-3,100);
leak = zeros(numel(por),numel(thick));
mass = zeros(size(thick));
for j=1:numel(por)
    ej=por(j);
    k=dp^2*ej^3/(180*(1-ej)^2);
    leak(j,:) = min(k*Ahole*(Pin^2-Pout^2)./( ...
        2*p.muAir*thick*p.Rair*p.T), mdotHole);
end
mass = Apatch*thick*(1-eps)*p.rhoMENP;
fprintf('\n=== TEST 1: LAYERED PRESSURE SEAL SCREEN ===\n');
fprintf('MENP: CoFe2O4/BaTiO3 (material class), d=%.0f nm [ASSUMED]\n',dp*1e9);
fprintf('Puncture %.1f mm, patch %.1f mm, pressure load %.3f N\n',p.dHole*1e3,p.dPatch*1e3,Fpressure);
fprintf('Idealized overlap bond strength needed with SF=%.1f: %.1f kPa\n', ...
    p.designSafetyFactor,bondShearRequired/1e3);
fprintf('Optimistic film tensile strength needed: %.2f MPa\n',filmStrengthRequired/1e6);
fprintf('100-um layer at porosity %.2f: Darcy-only leakage %.2f ug/s\n',eps,mdarcy*1e9);
fprintf('Screen goal (NOT aerospace standard): %.2f ug/s -> gas %s\n', ...
    p.acceptableAirLeakKgPerS*1e9,word(gasPass));
fprintf('MENP required %.2f mg; available %.2f mg -> mass %s\n', ...
    needKg*1e6,availKg*1e6,word(massPass));
fprintf('Continuous binder modeled? %d; structural screen %s\n', ...
    p.hasContinuousBinder,word(mechanicalConditionalPass));
fprintf('FULL PASS? %s (NO = not proven, not necessarily impossible)\n',word(pass));
if makePlots
    figure('Name','MAGSEAL test 1 - layered seal limits','Color','w');
    tiledlayout(2,1);
    nexttile;
    hold on;
    for j=1:numel(por)
        loglog(thick*1e6,leak(j,:)*1e9,'LineWidth',1.4);
    end
    yline(p.acceptableAirLeakKgPerS*1e9,'k--','Screening leak goal');
    xline(L*1e6,':','Assumed film');
    xlabel('Packed-film thickness (um)');ylabel('Modeled leak (ug/s)');
    title('Optimistic continuum porous-film model (ignores bypass and cracking)');
    legend([compose('Porosity = %.2f',por),"Leak goal","Assumed film"],'Location','northeastoutside');
    grid on;
    nexttile;
    loglog(thick*1e6,mass*1e6,'LineWidth',1.6);hold on;
    yline(availKg*1e6,'--','Available local particle inventory');
    xline(L*1e6,':','Assumed film');
    xlabel('Packed-film thickness (um)');ylabel('MENP mass for 12-mm cover (mg)');
    title('Conservation of local repair material (no mass created)');grid on;
end
out=struct('holeArea',Ahole,'patchArea',Apatch,'pressureN',Fpressure, ...
    'bondShearNeededPa',bondShearRequired,'filmStrengthNeededPa',filmStrengthRequired, ...
    'permeabilityM2',permeability,'gasLeakKgPerS',mdotScreen, ...
    'bareHoleLeakKgPerS',mdotHole,'neededMenpKg',needKg, ...
    'availableMenpKg',availKg,'gasPass',gasPass,'massPass',massPass, ...
    'mechanicalPass',mechanicalConditionalPass,'fullPass',pass);
end
function s=word(b)
if b, s='PASS'; else, s='FAIL'; end
end
