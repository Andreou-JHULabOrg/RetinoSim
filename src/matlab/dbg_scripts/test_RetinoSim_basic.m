%%%% Test various NVS models

clear;clc;

addpath(genpath('../modeling'));
addpath(genpath('../aux'));
addpath(genpath('../io'));

%%  read-in video

nrows = 512;
ncols = 512;
% videoFile = '/Volumes/Galatea/Users/jonahs/Dropbox/RetinaNVSModel_resources/videos/room_pan.mp4';
videoFile = '/Users/jonahs/Documents/research/projects/spike_proc/data/video/js_1_walk_NE_SW.mp4';

brightness_ratio = 1;
numframes = 100;
input_vid = brightness_ratio * readVideo_rs( videoFile, nrows, ncols, numframes, 1 );

%% Parameterize model 

params.frame_show                       = 1;

params.enable_shot_noise                = 0;

params.time_step                        = 10;

params.neuron_leak                      =  1.2; % 1.2 stable for low pass and bandpass
params.ba_leak                          =  1.0;

params.percent_threshold_variance       = 0;
params.percent_leak_variance            = 0;

params.threshold(:,:,1)                 =   12 *ones(size(input_vid(:,:,1))); % ON thresholds
params.threshold(:,:,2)                 =   12 *ones(size(input_vid(:,:,2))); % OFF thresholds

params.spatial_fe_mode                  = "bandpass";
params.spatial_filter_variances         = [2 2.5];
params.bc_offset                        = 0;
params.bc_leak                          = 0;
params.gc_reset_value                   = 0;
params.gc_refractory_period             = 0;
params.oms_reset_value                  = 3;
params.oms_refractory_period            = 0;
params.dbg_mode                         = 'opl_str';
params.opl_time_constant                = 0.9;
params.hpf_gc_tc                        = 1.0;
params.hpf_wac_tc                       = 0.4;
params.resample_threshold               = 0;
params.rng_settings                     = 0;
params.enable_sequentialOMS             = 0;


%% Run Model 
[TD, eventFrames, dbgFrames, OMSNeuron] = RetinoSim(input_vid, params);

%% Plot Outputs
if (params.frame_show == 1)
    fig = figure();
    
    fig.Units = 'normalize';
    fig.Position=[0.1 0.25 0.8 0.75];
    
    ax(1)=axes;
    ax(2)=axes;
    
    x0=0.15;
    y0=0.3;
    dx=0.25;
    dy=0.45;
    ax(1).Position=[x0 y0 dx dy];
    x0 = x0 + dx + 0.2;
    ax(2).Position=[x0 y0 dx dy];
    
    im(1) = imagesc(ax(1),dbgFrames(:,:,1));
    ax(1).Title.String = ['Debug: Frame ' num2str(1)];
    set(ax(1), 'xtick', [], 'ytick', []);
    colormap();
    
    im(2) = imagesc(ax(2),eventFrames(:,:,:,1));
    ax(2).Title.String = ['Accumulated Events: Frame ' num2str(1)];
    set(ax(2), 'xtick', [], 'ytick', []);
   
    for ii = 2:size(dbgFrames,3)
%         fprintf("Frame : %d\n", ii);
        ax(1).Title.String = ['Intensity: Frame ' num2str(ii)];
        ax(2).Title.String = ['Accumulated Events: Frame ' num2str(ii)];
        set(im(1),'cdata',dbgFrames(:,:,ii));
        set(im(2),'cdata',eventFrames(:,:,:,ii));
        frame = getframe();
        colorbar(ax(1));

        pause(1/60);
    end
end
