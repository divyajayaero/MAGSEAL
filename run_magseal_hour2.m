% Run AFTER build_magseal_hour2.m has built the model.
p = magseal_parameters();
assignin('base','p',p);
flowCoefficient = p.Cd * sqrt(p.gamma/(p.R*p.T)) * ...
   (2/(p.gamma+1))^((p.gamma+1)/(2*(p.gamma-1)));
assignin('base','flowCoefficient',flowCoefficient);

out = sim('MAGSEAL_Hour2');
P = out.get('magsealPressure');
cmd = out.get('magsealCoilCommand');
flow = out.get('magsealLeakFlow');
t = P.Time;
pPa = P.Data(:);
cmdAtP = interp1(cmd.Time,double(cmd.Data(:)),t,'previous','extrap');
trigger = find(double(cmd.Data(:))>=0.5,1,'first');
if isempty(trigger)
    tDetected = NaN;
else
    tDetected = cmd.Time(trigger);
end
fprintf('MAGSEAL Hour 2: first detection at t = %.3f s\n',tDetected);
fprintf('Expected approximately %.2f s; difference depends on solver.\n', ...
    p.tPuncture+log(p.P0/(p.P0-p.sensorDropPa))/(p.R*p.T/p.V*flowCoefficient*p.area));

figure('Name','MAGSEAL Hour 2 | Sensor verification','Color','w');
tiledlayout(3,1,'TileSpacing','compact');
nexttile;
plot(t,pPa/1000,'LineWidth',1.6); hold on;
yline((p.P0-p.sensorDropPa)/1000,'--','Sensor threshold');
xline(p.tPuncture,':','Puncture');
ylabel('Pressure (kPa)'); grid on;
nexttile;
stairs(cmd.Time,double(cmd.Data(:)),'LineWidth',1.5);
ylim([-0.1 1.1]); ylabel('Coil command'); grid on;
nexttile;
plot(flow.Time,flow.Data(:)*1000,'LineWidth',1.6);
ylabel('Leak (g/s)'); xlabel('Time (s)'); grid on;
sgtitle('Control logic only: no patch motion or seal yet');
