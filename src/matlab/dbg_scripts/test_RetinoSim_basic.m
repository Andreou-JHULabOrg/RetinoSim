%% Debug script for RetinoSim
%%% Description: Top script to parameterize model, import videos, and
%%% characterize reponse. 
%%% Author: Jonah P. Sengupta
%%% Date: 04-10-2022

clear;clc;

%% Add Requisite Paths

addpath(genpath('../modeling'));
addpath(genpath('../aux'));
addpath(genpath('../io'));

%% Choose to use pre-confiugred parameters or customize (1)

customize_params = true;
save_params = false;
write_video  = false;
params_file_name = 'params_bandpass_small_var';

%%  Import video

nrows = 512;
ncols = 512;

% videoFile = '/Volumes/Galatea/Users/jonahs/Dropbox/RetinaNVSModel_resources/videos/room_pan.mp4';
videoFile = '/Users/jonahs/Documents/research/projects/spike_proc/data/video/js_1_walk_NE_SW.mp4';

brightness_ratio = 1;
numframes = 100;
input_vid = brightness_ratio * readVideo_rs( videoFile, nrows, ncols, numframes, 1 );

%% Parameterize model 

if customize_params == 1 
    
    params.enable_shot_noise                = 0;
    
    params.time_step                        = 10; % sets timestep in milliseconds (1/fps * 1e3)
    
    params.neuron_leak                      =  1.5; % neuron leakage (leak down) (min set to 0 for log/log-lowpass)
    params.ba_leak                          =  0; % configure background activity rate (leak-up) (min set to 0 for log/log-lowpass)
    
    params.percent_threshold_variance       = 5.0; %set variance of threshold FPN
    params.percent_leak_variance            = 2.5; %set variance of leakage FPN
    
    params.threshold(:,:,1)                 =   15 *ones(size(input_vid(:,:,1))); % ON thresholds
    params.threshold(:,:,2)                 =   15 *ones(size(input_vid(:,:,2))); % OFF thresholds
    
    params.spatial_fe_mode                  = "bandpass"; % configure spatial FE mode (options = 'log', 'log-lowpass', 'linear', 'lowpass', 'bandpass')
    params.spatial_filter_variances         = [2 2.2];
    params.opl_time_constant                = 0.9; % set mean time constant for OPL

    params.bc_offset                        = 0; %create neuron deadzone
    params.bc_leak                          = 0; %configure bipolar cell leakage
    
    params.hpf_gc_tc                        = 0.9; % set integration TC for neuron
    params.gc_reset_value                   = 0;
    params.gc_refractory_period             = 500;
    params.oms_reset_value                  = 3; % in-progress
    params.oms_refractory_period            = 0; % in-progress
    params.hpf_wac_tc                       = 0.4; % in-progress

    params.enable_sequentialOMS             = 0; % in-progress
    params.dbg_mode                         = 'on_neuron';

    params.resample_threshold               = 0;
    params.rng_settings                     = 0;
    
    params.debug_pixel                      = [256 256];
    
    if save_params
        save(params_file_name, 'params'); 
    end
else 
    load(params_file_name);
end

%% Run Model 

[TD, eventFrames, dbgFrames, ~, pixDbg] = RetinoSim(input_vid, params);
%% Plot Outputs

plotRetinoOutput(dbgFrames,eventFrames, params);

%% Save Outputs

if write_video
    filepath = '../../../data/outvid_test.avi';
    writeOutputVideo(eventFrames,filepath);
    
    outframes = videoBlend(input_vid, eventFrames, 0, 1, 'test.avi');
    filepath = '../../../data/outvid_blend_test.avi';
    writeOutputVideo(outframes,filepath);
end