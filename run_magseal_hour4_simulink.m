% OPTIONAL: Simulink validation/replay of the Hour 4 MATLAB solution.
% Requires installed Simulink, runs independently of MAGSEAL_Hour2.slx.
% Close and delete MAGSEAL_Hour4.slx only if you want to regenerate blocks.
p=magseal_parameters();q=magseal_hour3_parameters();s=magseal_hour4_parameters();
r=magseal_run_hour4_case(p,q,s);
assignin('base','p',p);
flowCoefficient=r.flowCoefficient;
assignin('base','flowCoefficient',flowCoefficient);
% Replay cover engagement from the coupled MATLAB calculation as a signal.
% This is not a stand-alone Simulink simulation of magnetic tile dynamics.
magsealSealProfile=timeseries(r.blockedFraction,r.t);
assignin('base','magsealSealProfile',magsealSealProfile);
model=build_magseal_hour4_simulink();
out=sim(model);
P=out.get('magsealH4Pressure');
A=out.get('magsealH4Area');
cmd=out.get('magsealH4Sensor');
ref=interp1(r.t,r.pressurePa,P.Time(:),'linear');
maxError=max(abs(double(P.Data(:))-ref));
fprintf('\nHour 4 Simulink pressure comparison: max error vs MATLAB = %.3f Pa\n',maxError);
% A few Pa difference possible because of different solver discretizations.
if maxError>5
    warning('Pressure disagreement >5 Pa: inspect solver time step and imported cover profile.');
end
figure('Name','MAGSEAL Hour 4 | MATLAB vs Simulink replay','Color','w');
tiledlayout(2,1);
nexttile;
plot(r.t,r.pressurePa/1000,'LineWidth',1.8);hold on;
plot(P.Time,double(P.Data(:))/1000,'--','LineWidth',1.5);
xlabel('Time (s)');ylabel('Pressure (kPa)');
legend('Coupled MATLAB solver','Simulink pressure replay','Location','best');grid on;
nexttile;
plot(A.Time,double(A.Data(:))/p.area,'LineWidth',1.7);hold on;
stairs(cmd.Time,double(cmd.Data(:)),'--','LineWidth',1.3);
ylabel('Normalized area / sensor');xlabel('Time (s)');
legend('Effective opening / original opening','Sensor output','Location','best');
grid on;
