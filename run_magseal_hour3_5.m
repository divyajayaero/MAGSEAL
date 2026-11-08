% MAGSEAL HOUR 3.5 - LITERATURE-BASED ELECTROMAGNETIC FEASIBILITY
% No Simulink required. Run in MATLAB R2020b or newer.
% Distinguishes measured material properties, other researchers' actuator
% benchmarks, and OUR assumptions. Does not validate a particular coil.
clearvars; clc; close all;

%% 1. Literature-derived material property
% Cui et al., Micromachines 2026 17(8):927, doi:10.3390/mi17080927
% Reported remanence of 1.2:1 mass-ratio NdFeB/Ecoflex composite:
% 43.72 emu/g = 43.72 A*m^2/kg (SI mass-specific magnetic moment).
remanence_A_m2_per_kg = 43.72; % measured, OTHER author's composite

%% 2. Our illustrative module design (NOT measured)
moduleMass_kg = 0.003;        % 3-g complete module from Hour 3
compositeMassFraction = 0.20; % 20% proposed composite mass share (NOT measured)
alignmentFraction = 0.50;    % effective projection onto force direction
staticFriction_N = 0.002;    % assumed Hour 3 guided-track startup friction
hour3Moment_A_m2 = 1.25e-3; % assumed Hour 3 magnetic dipole moment
peakHour3Force_N = 0.025;    % illustrative peak, not needed for startup

% Mass-specific remanence -> effective magnetic moment.
% This assumes a pre-magnetized composite of the same composition and a
% dipole that stays approximately aligned; geometry/demagnetization matter.
magneticCompositeMass_kg = moduleMass_kg*compositeMassFraction;
momentLiterature_A_m2 = remanence_A_m2_per_kg* ...
    magneticCompositeMass_kg*alignmentFraction;

%% 3. Published field gradient benchmarks from DIFFERENT devices
% These are cross-study benchmarks, NOT measured at our 18-mm location.
% They must NOT be interpreted as a field map for our hypothetical coil.
benchmarkName = {'Modeled multi-coil 2026'; ...
                 'OctoMag reported maximum'; ...
                 'VORIACS reported maximum'};
G_T_per_m = [0.03; 0.20; 3.768];
benchmarkType = {'FEA result';'Published comparison';'Published comparison'};
benchmarkSource = { ...
    'https://doi.org/10.3390/act15010011'; ...
    'https://pmc.ncbi.nlm.nih.gov/articles/PMC11452550/'; ...
    'https://pmc.ncbi.nlm.nih.gov/articles/PMC11452550/'};

% F = m*G assumes dipole, aligned magnetization and local gradient.
F_hour3_N = hour3Moment_A_m2*G_T_per_m;
F_literature_N = momentLiterature_A_m2*G_T_per_m;
startsHour3 = F_hour3_N>staticFriction_N;
startsLiterature = F_literature_N>staticFriction_N;
requiredLocalG_hour3 = staticFriction_N/hour3Moment_A_m2;
requiredLocalG_literature = staticFriction_N/momentLiterature_A_m2;
requiredPeakG_literature = peakHour3Force_N/momentLiterature_A_m2;

results = table(benchmarkName, benchmarkType, G_T_per_m, ...
    1000*F_hour3_N, 1000*F_literature_N, startsHour3, ...
    startsLiterature, benchmarkSource, 'VariableNames', ...
    {'Reference','EvidenceType','FieldGradient_T_per_m', ...
     'Force_Hour3Moment_mN','Force_LiteratureMoment_mN', ...
     'Motion_Hour3Assumption','Motion_LiteratureAssumption','SourceURL'});
disp(results);
fprintf('\nMAGSEAL HOUR 3.5 - MIXED-SOURCE FEASIBILITY\n');
fprintf('Composite remanence (literature): %.2f A m^2/kg\n', ...
    remanence_A_m2_per_kg);
fprintf('Assumed composite share: %.0f%%; alignment: %.0f%%\n', ...
    100*compositeMassFraction,100*alignmentFraction);
fprintf('Derived effective moment: %.6f A m^2\n',momentLiterature_A_m2);
fprintf('Reference Hour 3 moment: %.6f A m^2\n',hour3Moment_A_m2);
fprintf('Required LOCAL gradient to beat 2 mN friction, Hour 3 moment: %.3f T/m\n', ...
    requiredLocalG_hour3);
fprintf('Required LOCAL gradient with literature-derived moment: %.3f T/m\n', ...
    requiredLocalG_literature);
fprintf('Required LOCAL gradient for 25 mN with literature moment: %.3f T/m\n', ...
    requiredPeakG_literature);

%% 4. Consistency check of ORIGINAL Hour 3 surrogate (NOT a measured curve)
gap_m = linspace(0,0.018,181)';
Gref = 20; gapRef = 0.010; exponent = 2;
Gsurrogate = Gref*(gapRef./(gapRef+gap_m)).^exponent;
Fsurrogate_mN = 1e3*hour3Moment_A_m2*Gsurrogate;
initial18mmForce_mN = Fsurrogate_mN(end);
fprintf('Original Hour 3 model force at 18 mm: %.3f mN (ASSUMED spatial law)\n', ...
    initial18mmForce_mN);
fprintf('Original Hour 3 model peak at 0 mm: %.3f mN\n', ...
    Fsurrogate_mN(1));

%% 5. Visualization: measured/estimated/assumed evidence separated
figure('Name','MAGSEAL Hour 3.5 | literature-based feasibility', ...
    'Color','w','Position',[100 100 1000 740]);
tiledlayout(2,2,'TileSpacing','compact');
nexttile;
bar(categorical(benchmarkName),[1000*F_hour3_N,1000*F_literature_N]);
yline(1000*staticFriction_N,'k--','Assumed static friction');
ylabel('Conditional force (mN)');
title('Different published actuator gradients (NOT our hardware)');
legend('Hour 3 assumed moment','Literature-derived moment','Location','northwest');
grid on;

nexttile;
compositeShares=linspace(0.02,1,100);
alignment=0.50;
Grequired=staticFriction_N./(remanence_A_m2_per_kg*moduleMass_kg* ...
    compositeShares*alignment);
plot(100*compositeShares,Grequired,'LineWidth',1.7); hold on;
yline(0.2,'--','0.2 T/m reference');
yline(3.768,'--','3.768 T/m reference');
set(gca,'YScale','log');
xlabel('Composite mass as % of module');
ylabel('Required LOCAL gradient to start (T/m)');
title('Design sensitivity; 50% alignment ASSUMED'); grid on;

nexttile;
plot(1000*gap_m,Fsurrogate_mN,'LineWidth',1.8); hold on;
yline(1000*staticFriction_N,'k--','2 mN static friction');
xline(18,':','Farthest tile begins');
xlabel('Distance from destination (mm)');
ylabel('Assumed force (mN)');
title('Original Hour 3 hypothetical distance law'); grid on;

nexttile;
axis off;
text(0,0.90,'WHAT IS AND IS NOT VERIFIED','FontWeight','bold','FontSize',12);
text(0,0.76,'YES: Magnetic composites can be actuated experimentally.','FontSize',10);
text(0,0.63,'YES: Published electromagnetic devices deliver field gradients.','FontSize',10);
text(0,0.50,'CONDITIONAL: A suitable combination may beat 2 mN friction.','FontSize',10);
text(0,0.37,'NOT VERIFIED: Actual gradient at the patch location.','FontSize',10);
text(0,0.24,'NOT VERIFIED: Free tile force, path, gasket seal, or latch.','FontSize',10);
text(0,0.08,'Solenoid-plunger ratings do NOT describe free composite tiles.', ...
     'FontWeight','bold','FontSize',9);
sgtitle('MAGSEAL: Source-grounded actuation envelope, not experimental validation');

writetable(results,'MAGSEAL_Hour3_5_source_comparison.csv');
save('MAGSEAL_Hour3_5_results.mat','results','momentLiterature_A_m2', ...
    'requiredLocalG_hour3','requiredLocalG_literature', ...
    'initial18mmForce_mN','compositeMassFraction','alignmentFraction');
fprintf('\nSaved CSV and MAT results in current folder.\n');
