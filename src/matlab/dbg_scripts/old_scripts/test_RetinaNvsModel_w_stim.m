%%%% Demo Retina-NVS model function

clear;clc;


%%  RUN DEMO 

addpath(genpath('../modeling'));
addpath(genpath('../aux'));
addpath(genpath('../io'));

%%  Generate Stim

hsf = 0.01; % 1/512 fundamental frequencies to allow for full resolvement of the frequency
vsf = 0;
htf = 0.02;
vtf = 0;
hamp = 1;
vamp = 1;
write = false;
numFrames = 80-1;
dims = [1 1024];

vPath = '/home/jonahs/projects/ReImagine/AER_Data/model_stim/hsf_0_vsf_4_htf_2_vtf_0_hamp_255_vamp_255.avi';

frames = CreateStimulus(hsf, vsf, htf, vtf, hamp, vamp, write, vPath, numFrames, dims) + 1;

inVid = frames;

%%

params.frames_per_second            = 30;
params.frame_show                   = 1;


params.resample_threshold           = 0;
params.rng_settings                 = 1;

params.on_threshold             = 20 *ones(size(inVid(:,:,1)));
params.off_threshold             =20 *ones(size(inVid(:,:,1)));

params.percent_threshold_variance   = 2.5; % 2.5% variance in threshold - from DVS paper

params.enable_threshold_variance    = 1;
params.enable_pixel_variance        = 1;
params.enable_diffusive_net         = 1;
params.enable_temporal_low_pass     = 1;

params.isGPU                        = 0;

params.enable_leak_ba           = 1;

params.leak_ba_rate             = 40;
%params.enable_leak_ba           = 0;
%params.leak_ba_rate             = 5;

params.enable_refractory_period = 1;
params.refractory_period        = 1 * (1/params.frames_per_second);
% params.refractory_period        = 1;


params.inject_spike_jitter      = 1;

params.inject_poiss_noise       = 0;

params.write_frame = 170;
params.write_frame_tag = 'proposal_figure_w_diff';
params.h = 0;

params.enable_pixel_variance        = 0;

%%
[TD, eventFrames, rng_settings, grayFrames, curFrames] = RetinaNvsModel(double(inVid), params);


%% figures
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
    
    im(1) = imagesc(ax(1),grayFrames(:,:,1));
    ax(1).Title.String = ['Log Intensity: Frame ' num2str(1)];
    set(ax(1), 'xtick', [], 'ytick', []);
    colormap(gray);
    
    im(2) = imagesc(ax(2),eventFrames(:,:,:,1));
    ax(2).Title.String = ['Accumulated Events: Frame ' num2str(1)];
    set(ax(2), 'xtick', [], 'ytick', []);
    
%     v = VideoWriter('../../../../figures/livingroom_walk.avi');
%     open(v);
%     
    for ii = 2:size(grayFrames,3)
%         fprintf("Frame : %d\n", ii);
        ax(1).Title.String = ['Intensity: Frame ' num2str(ii)];
        ax(2).Title.String = ['Accumulated Events: Frame ' num2str(ii)];
        set(im(1),'cdata',grayFrames(:,:,ii));
        set(im(2),'cdata',eventFrames(:,:,:,ii));
%         drawnow;
        frame = getframe();
%         writeVideo(v,frame);
        pause(1/60);
    end
    close(v);
end


