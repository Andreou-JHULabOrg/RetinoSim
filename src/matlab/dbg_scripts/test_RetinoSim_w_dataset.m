%% Debug script for RetinoSim
%%% Description: Top script to match to ETH dataset
%%% Author: Jonah P. Sengupta
%%% Date: 04-13-2022

clear;clc;

%% Add Requisite Paths

addpath(genpath('../modeling'));
addpath(genpath('../aux'));
addpath(genpath('../io'));

%% Choose to use pre-confiugred parameters or customize (1)

customize_params = false;
save_params = true;
write_video  = false;
params_file_name = 'params_log_dataset_match';

%%  Import video

base_dir = '../../../../AER_Data/eth_rpg_dataset/images/';

imagefiles = dir('../../../../AER_Data/eth_rpg_dataset/images/*.png');

input_vid = uint8(zeros(180,240,113));
for ff = 1:113 % first 5 seconds of data
	input_vid(:,:,ff) = uint8(imread([base_dir imagefiles(ff).name]));
% 	imshow(input_vid(:,:,ff));
	pause(1/60);
end

%% Parameterize model 

if customize_params == 1 
    
    params.enable_shot_noise                = 0;
    
    params.time_step                        = 44; % sets timestep in milliseconds (1/fps * 1e3)
    
    params.neuron_leak                      =  1.2; % neuron leakage (leak down) (min set to 0 for log/log-lowpass)
    params.ba_leak                          =  1.05; % configure background activity rate (leak-up) (min set to 0 for log/log-lowpass)
    
    params.percent_threshold_variance       = 5.0; %set variance of threshold FPN
    params.percent_leak_variance            = 2.0; %set variance of leakage FPN
    
    params.threshold(:,:,1)                 =   1.1 *ones(size(input_vid(:,:,1))); % ON thresholds
    params.threshold(:,:,2)                 =   1.1 *ones(size(input_vid(:,:,2))); % OFF thresholds
    
    params.spatial_fe_mode                  = "log"; % configure spatial FE mode (options = 'log', 'log-lowpass', 'linear', 'lowpass', 'bandpass')
    params.spatial_filter_variances         = [2 2.2];
    params.opl_time_constant                = 1.0; % set mean time constant for OPL

    params.bc_offset                        = 0; %create neuron deadzone
    params.bc_leak                          = 0; %configure bipolar cell leakage
    
    params.hpf_gc_tc                        = 1.0; % set integration TC for neuron
    params.gc_reset_value                   = 0;
    params.gc_refractory_period             = 20; % units of ms
    params.oms_reset_value                  = 3; % in-progress
    params.oms_refractory_period            = 0; % in-progress
    params.hpf_wac_tc                       = 0.4; % in-progress

    params.enable_sequentialOMS             = 0; % in-progress
    params.dbg_mode                         = 'on_neuron';

    params.resample_threshold               = 0;
    params.rng_settings                     = 0;
    
    params.debug_pixel                      = [90 140];
    
    if save_params
        save(params_file_name, 'params'); 
    end
else 
    load(params_file_name);
end

%% Run Model 

[TD_model, eventFrames, dbgFrames, ~, pixDbg] = RetinoSim(input_vid, params);
%% Plot Outputs

plotRetinoOutput(dbgFrames,eventFrames, params);

%%


[TD_real] = loadAEFile('../../../../AER_Data/eth_rpg_dataset/events_5s.txt');
eventFrames_real = makeFrames(TD_real, 'time', 44066, 1); %fs set to value in images.txt


%%

[ outVid ] = videoBlend( input_vid, eventFrames, 0, 1, 'kk.txt');

%%

fnum = 20;
figure();

imagesc(eventFrames_real(:,:,:,fnum));

figure();

imagesc(eventFrames(:,:,:,fnum));

err_frame = eventFrames(:,:,:,fnum)-eventFrames_real(:,:,:,fnum);
imagesc(err_frame)