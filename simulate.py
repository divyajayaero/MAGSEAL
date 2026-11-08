"""Conditional MAGSEAL exterior-layer model. Run with Python 3 + numpy/scipy/matplotlib."""
from pathlib import Path
import csv
import json
import numpy as np
from scipy.special import ellipk, ellipe
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parent
COLUMNS = ['time_s', 'pressure_Pa', 'radius_m', 'current_A', 'coil_temperature_K',
           'exterior_open_area_fraction', 'retained_m3', 'used_m3', 'expelled_m3',
           'cure_fraction', 'leak_kg_s', 'bond_capacity_N', 'coil_energy_J']
SCENARIOS = [
    ('Untreated', False, False, {}),
    ('Exterior only', True, False, {}),
    ('Combined nominal assumptions', True, True, {}),
    ('Exterior does not heal', False, True, {}),
    ('Exterior heals slowly', True, True, {'healingTau': 60}),
    ('Exterior attachment fails', True, True, {'exteriorCapacityN': 1}),
]

def field(radius, z, p):
    a = p['coilRadius']
    ap = (a + radius)**2 + z*z
    bm = (a - radius)**2 + z*z
    k2 = 4*a*radius/ap
    k, e = ellipk(k2), ellipe(k2)
    coefficient = 4*np.pi*1e-7*p['coilTurns']/(2*np.pi*np.sqrt(ap))
    bz = coefficient*(k + (a*a-radius*radius-z*z)*e/bm)
    br = coefficient*z/radius*(-k + (a*a+radius*radius+z*z)*e/bm)
    return np.hypot(bz, br)

def force_table(p):
    radius = np.linspace(p['holeDiameter']/2, p['rStart'], 501)
    h, z = p['fieldStep'], p['coilStandoff']
    radial = -p['carrierMoment']*(field(radius+h,z,p)-field(radius-h,z,p))/(2*h)
    normal = abs(p['carrierMoment']*(field(radius,z+h,p)-field(radius,z-h,p))/(2*h))
    return np.column_stack([radius, np.maximum(0,radial), normal])

def simulate(p, exterior=True, menp=True, table=None):
    table = force_table(p) if table is None else table
    time = np.arange(round(p['tEnd']/p['dt'])+1)*p['dt']
    out = np.zeros((len(time), len(COLUMNS)))
    area = np.pi*(p['holeDiameter']/2)**2
    target = area*p['hullThickness']
    coefficient = p['Cd']*np.sqrt(p['gamma']/(p['Rgas']*p['Tgas']))*(2/(p['gamma']+1))**((p['gamma']+1)/(2*(p['gamma']-1)))
    wire_length = p['coilTurns']*2*np.pi*p['coilRadius']
    wire_area = np.pi*(p['wireDiameter']/2)**2
    resistance = p['copperResistivity']*wire_length/wire_area
    heat_capacity = p['copperDensity']*wire_length*wire_area*p['copperSpecificHeat']
    pressure, radius, temperature = p['P0'], p['rStart'], p['ambientTemp']
    retained = used = expelled = cure = energy = 0.0
    detected = arrival = None
    thermal_fault = False
    # A capacity input is required. It includes film and attachment; no strength is inferred from thickness.
    exterior_supported = exterior and p['exteriorCapacityN'] >= p['safetyFactor']*p['P0']*area
    for i, t in enumerate(time):
        if t >= p['punctureTime'] and detected is None and p['P0']-pressure >= p['sensorDropPa']:
            detected = t
        current = 0.0
        if menp and detected is not None and arrival is None and not thermal_fault and t-detected < p['maxCoilOnTime']:
            current = p['coilCurrent']*(1-np.exp(-(t-detected)/p['coilRampTau']))
        elapsed = max(0, t-p['punctureTime']-p['healingDelay'])
        opening = 1.0
        if exterior_supported:
            opening = p['residualAreaFraction']+(1-p['residualAreaFraction'])*np.exp(-elapsed/p['healingTau'])
        if arrival is not None:
            cure = 1-np.exp(-(t-arrival)/p['cureTau'])
        fill = min(1, retained/target)
        # Empirical gas-area closure law. Void topology, bypass gaps and gas permeation are unresolved.
        effective_area = area*min(1, opening*(1-fill*cure)+p['leakFloorAreaFraction']*fill*cure)
        leak = coefficient*pressure*effective_area if t >= p['punctureTime'] else 0.0
        bond = p['finalBondShearStrength']*np.pi*p['holeDiameter']*p['hullThickness']*fill*cure*cure
        out[i] = [t,pressure,radius,current,temperature,opening,retained,used,expelled,cure,leak,bond,energy]
        if i == len(time)-1:
            break
        dt = p['dt']
        pressure *= np.exp(-p['Rgas']*p['Tgas']/p['Vcabin']*coefficient*effective_area*dt) if t >= p['punctureTime'] else 1
        power = current*current*resistance
        equilibrium = p['ambientTemp']+power*p['thermalResistance']
        temperature = equilibrium+(temperature-equilibrium)*np.exp(-dt/(heat_capacity*p['thermalResistance']))
        thermal_fault |= temperature >= p['coilMaxTemp']
        energy += power*dt
        if current > 0:
            inward = np.interp(radius,table[:,0],table[:,1])*current
            normal = np.interp(radius,table[:,0],table[:,2])*current
            if inward > p['staticFriction']+p['guideFrictionCoefficient']*normal:
                speed = min(p['speedLimit'], (inward-p['kineticFriction']-p['guideFrictionCoefficient']*normal)/p['motionDamping'])
                radius = max(p['holeDiameter']/2,radius-speed*dt)
                if radius <= p['holeDiameter']/2:
                    arrival = t+dt
        # Deposition begins the step AFTER arrival. Feed rate is an explicit assumption, not a magnetic-flow prediction.
        if arrival is not None and t >= arrival:
            feed = 0.0
            if t-arrival < p['workingLife']:
                feed = min(p['feedRate']*dt,max(0,p['inventory']-used),max(0,target-retained))
            used += feed
            # Newtonian capillary extrusion estimate through the surviving exterior aperture.
            # Cure suppresses mobility phenomenologically; cap at mobile inventory to conserve volume.
            aperture_radius = p['holeDiameter']/2*np.sqrt(opening)
            path = p['hullThickness']+(p['exteriorThickness'] if exterior_supported else 0)
            q_loss = np.pi*aperture_radius**4*out[i,1]/(8*p['gelViscosity']*path)*(1-cure)**3
            loss = min(retained+feed,q_loss*dt)
            expelled += loss
            retained += feed-loss
    return out, {'detected':detected,'arrival':arrival,'target_m3':target,'supported':bool(exterior_supported)}

def main():
    p = json.loads((ROOT/'parameters.json').read_text())
    results = ROOT/'results'
    results.mkdir(exist_ok=True)
    table = force_table(p)
    np.savetxt(ROOT/'coil_force_per_amp.csv',table,delimiter=',',header='radius_m,inward_N_per_A,normal_N_per_A',comments='')
    runs, summaries = [], []
    for index,(name,ext,menp,changes) in enumerate(SCENARIOS):
        settings = {**p,**changes}
        data, events = simulate(settings,ext,menp,table)
        np.savetxt(results/f'case_{index+1}.csv',data,delimiter=',',header=','.join(COLUMNS),comments='')
        loss_g = (p['P0']-data[-1,1])*p['Vcabin']/(p['Rgas']*p['Tgas'])*1000
        summary = dict(case=name,arrival_s=events['arrival'],air_lost_g=loss_g,
                       final_pressure_kPa=data[-1,1]/1000,final_leak_mg_s=data[-1,10]*1e6,
                       retained_uL=data[-1,6]*1e9,expelled_uL=data[-1,8]*1e9,
                       peak_coil_C=max(data[:,4])-273.15,coil_energy_J=data[-1,12],
                       final_bond_N=data[-1,11],exterior_support_assumed=events['supported'])
        summaries.append(summary)
        runs.append(data)
    with (results/'summary.csv').open('w',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=summaries[0].keys());writer.writeheader();writer.writerows(summaries)
    # Meaningful regression checks: inventories, monotonic pressure, analytical no-repair gas loss, timestep sensitivity.
    for data in runs:
        assert np.allclose(data[:,7],data[:,6]+data[:,8],atol=1e-18)
        assert np.all(np.diff(data[:,1])<=1e-8)
        assert data[:,7].max() <= p['inventory']+1e-16
        assert data[:,6].min() >= -1e-16
    coefficient=p['Cd']*np.sqrt(p['gamma']/(p['Rgas']*p['Tgas']))*(2/(p['gamma']+1))**((p['gamma']+1)/(2*(p['gamma']-1)))
    analytical=p['P0']*np.exp(-p['Rgas']*p['Tgas']/p['Vcabin']*coefficient*np.pi*(p['holeDiameter']/2)**2*(p['tEnd']-p['punctureTime']))
    assert abs(runs[0][-1,1]-analytical)<1e-5
    refined,_=simulate({**p,'dt':p['dt']/2},True,True,table)
    relative=abs(refined[-1,6]-runs[2][-1,6])/max(refined[-1,6],1e-15)
    assert relative<0.01
    zero,_=simulate({**p,'coilCurrent':0},True,True,table)
    assert zero[-1,7]==0
    (results/'verification.txt').write_text(f'PASS inventory conservation, monotonic pressure, supply bounds, analytical untreated leakage, zero-current no delivery.\nNominal retained-volume change at half timestep = {relative:.6%}.\nPython executed. MATLAB runner supplied but not executed in this environment.\n')
    plt.rcParams.update({'font.size':10,'axes.spines.top':False,'axes.spines.right':False})
    fig,axes=plt.subplots(2,2,figsize=(13,8))
    colors=['#64748b','#f59e0b','#0891b2','#e11d48','#7c3aed','#a16207']
    for (name,*_),data,color in zip(SCENARIOS,runs,colors):
        axes[0,0].plot(data[:,0],data[:,10]*1e6,label=name,color=color)
        axes[0,1].plot(data[:,0],(p['P0']-data[:,1])/1000,color=color)
        axes[1,0].plot(data[:,0],data[:,6]*1e9,color=color)
    axes[0,0].set(yscale='log',ylabel='Air leakage (mg/s)',xlabel='Time (s)')
    axes[0,0].axhline(p['leakAcceptance']*1e6,color='black',ls=':',lw=1)
    axes[0,1].set(ylabel='Cabin pressure lost (kPa)',xlabel='Time (s)')
    axes[1,0].axhline(np.pi*(p['holeDiameter']/2)**2*p['hullThickness']*1e9,color='black',ls=':',label='Bore volume')
    axes[1,0].set(ylabel='Retained repair polymer (µL)',xlabel='Time (s)')
    nominal=runs[2]
    axes[1,1].plot(nominal[:,0],nominal[:,5]*100,label='Exterior open area (%)',color='#0891b2')
    axes[1,1].plot(nominal[:,0],nominal[:,9]*100,label='Assumed cure (%)',color='#f59e0b')
    axes[1,1].set(xlabel='Time (s)',ylabel='Nominal model state (%)',ylim=(-2,102))
    axes[1,1].legend(fontsize=9)
    for ax in axes.flat: ax.grid(alpha=.2)
    fig.suptitle('MAGSEAL • Exterior polymer + MENP repair\n6 mm puncture | Conditional reduced-order simulation',fontsize=17)
    handles,labels=axes[0,0].get_legend_handles_labels()
    fig.legend(handles,labels,loc='lower center',ncol=3,fontsize=9)
    fig.tight_layout(rect=(0,.09,1,.91))
    fig.savefig(results/'simulation_results.png',dpi=170)
    print(json.dumps(summaries,indent=2))

if __name__=='__main__':
    main()
