# RetinoSim
Video to AER data synthesis model using retinomorphic chip architectures with physiological improvements.

## Directory Hierarchy

**src/python/***: in-works - Python version of RetinoSim, not updated to current version
**src/cpp/**: in-works - C++ version of RetinoSim, not updated to current version
**src/matlab/modeling**: contains the source code for RetinoSim in RetinoSim.m, other functions are sub-routines called from this top file or used for characterization
**src/matlab/dbg_scripts**: contains a debug script template to save parameters and experiment with function parameterization
**src/matlab/demo**: contains a script to load input video, load saved parameters, run model, display video, and optionally save video to local disk.

## Software Notes

All code is compatible with Matlab 2017-2021.1a. The model has also been verified on a Intel-based Macbook running Mojave (10.14.6) and AMD Ryzen-based PC running CentOS 7.7.1908.

## RetinoSim Parameters

**params.time_step** (double, nom. = 10): timestamp resolution (in ms) of model, this can be modified by the used to match the inverse of the input video FPS. Note: output timestamps are multiplied by 1000 to convert to units of microseconds which matches the format of AER data.

**params.enable_shot_noise** (boolean, nom = False): enables the injection of photoreceptor shotnoise into the model. This is inversely proportional to the pixel intensity to model the mechanisms effect on signal quality.

**params.neuron_leak**: 


