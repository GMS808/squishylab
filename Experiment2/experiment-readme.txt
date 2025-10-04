# Rheology Experiment: Linear Viscoelastic Response

In this experiment we will use bulk rheology methods to probe linear viscoelastic response of materials that exhibit both elastic energy storage and viscous loss over timescales that are observable in the lab. To do this, you will make dynamic oscillatory shear, creep, and steady shear measurements using a TA Instruments Discovery Hybrid Series rheometer (DHR-2). The materials we look at will be glycerol (a Newtonian fluid), agarose (a polysaccharide polymer with solid-like response), and mayonnaise, which exhibits both liquid-like and solid-like response over accessible time scales.

---

## The Experiment

For the following rheology tests, the TA Instruments DHR2 and Trios software manuals are good sources for help on both theory of measurements and details of instrument operation. There are also some important details pertaining to instrument calibration, sample loading and setting an appropriate gap height that we will discuss in the laboratory. Be sure to keep a notebook with you and record measurement procedures and parameters during all experiments.

### 1. Sample preparation and loading

As with the first experiment, there will be an introduction to the details of sample prep in the laboratory. You will be shown how to prepare glycerol solutions and agarose hydrogels. Agarose will be placed on the rheometer in solution phase at elevated temperature and allowed to cool/gel after the geometry is brought in contact. Optimal loading conditions for student-provided samples may require some experimentation. In all cases, it is crucial to set the gap height appropriately. Watch carefully as the geometry is lowered and look for the slight bulge of material past the edge of the plates.

### 2. Rheometry measurements

For each material you measure, you will run oscillatory shear, creep, and flow tests. Be sure that you conduct all necessary instrument calibration steps, including zeroing the gap.

**Oscillatory shear measurements.**  
First, you will need to make sure you are in the linear regime, by running an amplitude sweep at fixed frequency. For this test, you will increase stress at a constant angular frequency (10 rad/s is fine) and examine plots of \(G′\) and \(G″\) vs strain % to confirm that over some range, the real and imaginary components of \(G^*(\omega)\) are independent of strain. Note that if strain is increased to a value outside the linear regime, the material may fail and be altered permanently. In this case you will need to re-load your sample. However, this is not a problem as this is part of the characterization you will eventually do anyway (see below). Also note however, that depending on what material you are working with (e.g. glycerol), this may not be a concern.

Once you have selected a strain for which you are well within the linear regime and you have robust measurement (look at raw phase and waveforms in the rheometer software), you can conduct a frequency sweep. In this test you hold strain constant and obtain \(G^*(\omega)\) at several frequencies per decade. The main constraint is time, which determining the lower bound as each measurement is averaged over multiple iterations, low frequency measurements can get very time consuming.

After other non-destructive linear viscoelasticity measurements are complete (see below) you can go back and run a final amplitude sweep, this time going to high stresses beyond the linear regime to identify a yield stress, if applicable.

**Creep and recovery measurements.**  
Assuming no destructive deformations have been performed, you can proceed with a creep test without reloading the sample. Use the same stress, \(\sigma_0\), as in your oscillatory shear measurements, perform a creep (\(\sigma = \sigma_0\)) and recovery (\(\sigma=0\)) test over a period of a few minutes. Here you will be generating plots of compliance,  
\[
J(t) = \frac{\gamma(t)}{\sigma_0}
\]  
versus \(t\).

**Flow test.**  
Finally, you should run a flow test to measure effective viscosity over a wide range of shear rates if applicable for the material. This is not applicable for the agarose gel.

### 3. Analysis

Once you have run rheology tests on your samples you should save all your experiment data (all parameters and calculated values are stored in tables in the software) for offline analysis. For each material tested:

1. Prepare plots of \(G′\) and \(G″\) vs strain for all materials and identify a value of applied strain within the linear regime, used in your subsequent frequency sweep. Also, if applicable, identify a yield stress.
  
2. Prepare plots \(G′\) and \(G″\) vs \(\omega\), and plot the phase angle, \(\delta\). Identify solid-like and/or liquid-like response. Can you identify a relaxation time from a crossover (if applicable)? For materials with liquid-like response, do you see viscous scaling \((G″ \sim \omega \eta_0)\), and if so, what is the measured value of zero shear viscosity, \(\eta_0\)? If you can identify a relaxation time in your data, discuss the time of observation and Deborah number.
  
3. In your plots of creep compliance, do you see evidence of elasticity and/or viscous flow? Identify regions of flow and obtain viscosity where possible. Is the behavior consistent with your analysis of \(G^*(\omega)\)?  

4. Where applicable, generate plots of effective viscosity, \(\eta_{\rm eff}\), versus shear rate. Identify Newtonian/non-Newtonian behavior (shear thinning, shear thickening, etc).

