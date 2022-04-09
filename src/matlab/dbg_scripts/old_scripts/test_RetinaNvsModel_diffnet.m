%%%% Demo Retina-NVS model diffusive net 

clear;clc;


%%  CREATE FRAMES FROM VIDEO FILE

addpath(genpath('../modeling'));
addpath(genpath('../filters'));
addpath(genpath('../io'));

videoFile = '../../../../data/video/cat_jump.mp4';

nrows = 180;
ncols = 240;
numframes = 300;
brightness_ratio = 1;
frames = brightness_ratio * readVideo_rs( videoFile, nrows, ncols, numframes );

%% SET PARAMETERS

params.frames_per_second            = 240;
params.frame_show                   = 0;


params.resample_threshold           = 0;
params.rng_settings                 = 1;

if brightness_ratio == 1
    params.on_threshold             = 0.25*ones(size(frames(:,:,1)));
    params.off_threshold            = 0.25*ones(size(frames(:,:,1)));
else
    params.on_threshold             = 0.25* abs(1/log(brightness_ratio)) * ones(size(frames(:,:,1)));
    params.off_threshold            = 0.25* abs(1/log(brightness_ratio)) * ones(size(frames(:,:,1)));
end

params.percent_threshold_variance   = 2.5; % 2.5% variance in threshold - from DVS paper

params.enable_threshold_variance    = 1;
params.enable_pixel_variance        = 1;

params.enable_temporal_low_pass     = 1;

params.enable_leak_ba           = 1;

params.enable_refractory_period = 0;
params.refractory_period        = 1 * (1/params.frames_per_second);

params.inject_spike_jitter      = 1;

params.inject_poiss_noise       = 0;

params.write_frame = 0;
params.write_frame_tag = 'leakrate_45_diffnet_1';


%%

leak_rates = 0:5:55;

isplot = 0;

epochs = 10;
loss.on = [];
loss.off = [];

num_events_wo = []; num_events_w = [];

% terminate iterative correction if loss is less than tolerance 
tol.on = 0.1;
tol.off = 0.1;

for epoch = 1:numel(leak_rates)
    fprintf("|-------------------Leakage Rate: %d-------------------|\n", leak_rates(epoch));
    
    % ---------------------------------------------------------------------
    step = "......1. RUNNING MODEL WITHOUT DIFFUSIVE NET.....";
    fprintf("%s\n",step);
    
    if epoch == 1
        params.resample_threshold           = 1;
        params.rng_settings                 = 0;
    else
        params.rng_settings             = rng_settings;
        params.resample_threshold       = 0;
    end

    
    params.enable_diffusive_net         = 0;
    params.leak_ba_rate                 = leak_rates(epoch);
    [TD, ~, rng_settings] = RetinaNvsModel(double(frames), params);
    fprintf("%d events in simulated stream.\n", length(TD.x));
    num_events_wo = [num_events_wo length(TD.x)];
    
    % ---------------------------------------------------------------------
    step = "............2. RUNNING WITH DIFFUSIVE NET..........";
    fprintf("%s\n",step);
    
    params.rng_settings             = rng_settings;
    params.resample_threshold       = 0;
    params.enable_diffusive_net         = 1;
    
    [TD, ~, rng_settings] = RetinaNvsModel(double(frames), params);
    fprintf("%d events in simulated stream with diffusive net.\n", length(TD.x));
    num_events_w = [num_events_w length(TD.x)];
    
end

%%

diff_events = num_events_wo-num_events_w;
percentage_red = diff_events./num_events_wo;

plot(leak_rates, percentage_red, 'r-*');
xlabel('Leakage rate (1/s)','Interpreter', 'latex');
ylabel('Percent Data reduction','Interpreter', 'latex');




