%% Demo script for RetinoSim
%%% Description: Top script to load video and parameters, run model, show
%%% frames, and save to output
%%% Author: Jonah P. Sengupta
%%% Date: 04-11-2022

clear;clc;


%% Add Requisite Paths

addpath(genpath('../modeling'));
addpath(genpath('../aux'));
addpath(genpath('../io'));

%% Choose to use pre-configured parameters

customize_params = false;
write_video  = true;
params_file_name = '../dbg_scripts/params_bandpass_small_var.mat';

%%  Import video

nrows = 512; % configure input video dimensions
ncols = 512;

videoFile = '../../../data/room_pan.mp4';

numframes = 100;
input_vid = readVideo_rs( videoFile, nrows, ncols, numframes, 1 );

%% Parameterize model 

load(params_file_name);

%% Run Model 

[TD, eventFrames, dbgFrames, ~] = RetinoSim(input_vid, params);
%% Plot Outputs

plotRetinoOutput(dbgFrames,eventFrames, params);

%% Save Outputs

if write_video
    filepath = '../../../data/roompan_events.avi';
    writeOutputVideo(eventFrames,filepath);
    
    outframes = videoBlend(input_vid, eventFrames, 0, 0, 'test.avi');
    filepath = '../../../data/roompan_blended.avi';
    writeOutputVideo(outframes,filepath);
end