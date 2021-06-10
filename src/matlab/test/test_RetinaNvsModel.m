%%%% Demo Retina-NVS model function

clear;clc;


%%  RUN DEMO WITH CAT VIDEO 

addpath(genpath('../modeling'));
addpath(genpath('../aux'));
addpath(genpath('../io'));

% videoFile = '../../../../spike_proc/data/video/cat_jump.mp4';
videoFile = '../../../../spike_proc/data/video/simp_ball/simp_ball_3.mp4';
nrows = 512;
ncols = 512;
numframes = 100;
brightness_ratio = 1;
inVid = brightness_ratio * readVideo_rs( videoFile, nrows, ncols, numframes );

%%

params.frames_per_second            = 60;
params.frame_show                   = 0;


params.resample_threshold           = 0;
params.rng_settings                 = 1;

if brightness_ratio == 1
%     params.on_threshold             = 0.25*ones(size(inVid(:,:,1)));
%     params.off_threshold            = 0.25*ones(size(inVid(:,:,1)));
    params.on_threshold             = 0.1*ones(size(inVid(:,:,1)));
    params.off_threshold            = 0.1*ones(size(inVid(:,:,1)));
else
%     params.on_threshold             = 0.25 * abs(1/log(brightness_ratio));
%     params.off_threshold            = 0.25 * abs(1/log(brightness_ratio)); % roughly from DVS paper
    params.on_threshold             = 0.25* abs(1/log(brightness_ratio)) * ones(size(inVid(:,:,1)));
    params.off_threshold            = 0.25* abs(1/log(brightness_ratio)) * ones(size(inVid(:,:,1)));
end

params.percent_threshold_variance   = 2.5; % 2.5% variance in threshold - from DVS paper

params.enable_threshold_variance    = 1;
params.enable_pixel_variance        = 1;
params.enable_diffusive_net         = 1;
params.enable_temporal_low_pass     = 0;

params.enable_leak_ba           = 1;
params.leak_ba_rate             = 5;

params.enable_refractory_period = 0;
params.refractory_period        = 1 * (1/params.frames_per_second);

params.inject_spike_jitter      = 1;

params.inject_poiss_noise       = 0;

params.write_frame = 0;
params.write_frame_tag = 'leakrate_5_diffnet_1';

[TD, eventFrames, ~] = RetinaNvsModel(double(inVid), params);

%%


outframes = videoBlend(inVid, eventFrames, 0, 1, 'test.avi');



