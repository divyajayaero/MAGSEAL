function mdot = magseal_leak_rate(Pin, Pout, A, p)
% Gas mass flow through an orifice from high to low pressure [kg/s].
% Isentropic compressible orifice approximation; constant Cd.
% Pin and Pout must be absolute pressures [Pa].
if Pin <= Pout || Pin <= 0 || A <= 0
    mdot = 0;
    return;
end
r = max(Pout / Pin, 0);
rCritical = (2/(p.gamma+1))^(p.gamma/(p.gamma-1));
if r <= rCritical
    factor = sqrt(p.gamma/(p.R*p.T)) * ...
        (2/(p.gamma+1))^((p.gamma+1)/(2*(p.gamma-1)));
else
    factor = sqrt((2*p.gamma)/(p.R*p.T*(p.gamma-1)) * ...
        (r^(2/p.gamma) - r^((p.gamma+1)/p.gamma)));
end
mdot = p.Cd * A * Pin * factor;
end
