function verify_magseal_autonomous_plug()
% Six geometry/physics/failure-model sanity checks, NOT real-world validation.
p=magseal_plug_parameters();
a=magseal_screen_case(p);
assert(abs(a.pressureForce_N-2.8648969)<0.002,'6-mm pressure load incorrect');
assert(abs(a.fillVolume_uL-84.823)<0.05,'Bore/collar fill volume incorrect');
assert(a.inventoryOK && a.latchOK,'Baseline inventory or latch screen fails');
assert(a.forceNear_mN>2 && a.forceFar_mN<2, ...
    'Coil should move near carrier but not far one under current assumptions');
assert(a.canMoveHead && isfinite(a.filledTime) && isfinite(a.curedTime), ...
    'Baseline delivery or curing state sequence failed');
assert(a.lowLeakFinal,'Baseline low-leak assumption should pass its screening target');

b=p;b.coilCurrent=.12;r=magseal_screen_case(b);
assert(~r.canMoveHead && isnan(r.curedTime),'Weak field should fail');
b=p;b.latchCapacity=4;r=magseal_screen_case(b);
assert(~r.latchOK && isnan(r.curedTime),'Weak latch should fail');
b=p;b.reservoirThickness=0.00005;b.recoverableFraction=0.25;
r=magseal_screen_case(b);
assert(~r.inventoryOK && isnan(r.curedTime),'Insufficient material should fail');
b=p;b.enableElastomerHead=false;r=magseal_screen_case(b);
assert(isnan(r.curedTime),'No head means no protected plug placement');
b=p;b.effectiveMoment=.001794;r=magseal_screen_case(b);
assert(~r.canMoveHead,'MENP-only carrier should not overcome modeled friction');
b=p;b.residualOpenAfterCure=.02;r=magseal_screen_case(b);
assert(~r.lowLeakFinal,'Poor edge seal must fail leakage criterion');
fprintf('PASS: 6 baseline physics/sequence checks + 6 independent failure cases.\n');
fprintf('DISCLAIMER: tests verify model equations, not spacecraft hardware.\n');
end
