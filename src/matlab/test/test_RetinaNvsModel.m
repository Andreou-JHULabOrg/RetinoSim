%%%% Demo Retina-NVS model function

clear;clc;


%%  RUN DEMO 

addpath(genpath('../modeling'));
addpath(genpath('../aux'));
addpath(genpath('../io'));


%For AGA Lab - NAS1 usage

% filenamePrefix = 'dm_1_Jump_Fwd_Then_Bwd_NW_SE';
% videoFile = ['/DatasetsStaging/ONR-MURI-2009/JHUMMA-Shriver_Aug2014/make_rgb_videos/videos/' filenamePrefix '.avi'];

%For Galatea-Dropbox usage
% videoFile = '/Users/jonahs/Dropbox/RetinaNVSModel_resources/videos/gait/dm_1_Jump_Fwd_Then_Bwd_NW_SE.avi';

% videoFile = '/Users/susanliu/Documents/AndreouResearch/videos/livingroom_walk.mp4';


nrows = 512;
ncols = 512;
numframes = 300;

videoFile = '../../../../spike_proc/data/video/cat_jump.mp4';
%videoFile = '../../../../spike_proc/data/video/OCD1_029_statinary_800mm_1mile_frames.mp4';
% videoFile = '../../../../spike_proc/data/video/stationary_1mile_800mm.mp4';
% videoFile = '../../../../spike_proc/data/video/simp_ball/simp_ball_3.mp4';
%nrows = 260;
%ncols = 346;
%numframes = 60;

brightness_ratio = 1;
inVid = brightness_ratio * readVideo_rs( videoFile, nrows, ncols, numframes, 1 );

%%

params.frames_per_second            = 30;
params.frame_show                   = 0;


params.resample_threshold           = 0;
params.rng_settings                 = 1;

if brightness_ratio == 1
%     params.on_threshold             = 0.25*ones(size(inVid(:,:,1)));
%     params.off_threshold            = 0.25*ones(size(inVid(:,:,1)));
%     params.on_threshold             = 0.2*ones(size(inVid(:,:,1)));
    params.on_threshold             = 20 *ones(size(inVid(:,:,1)));
    params.off_threshold             =20 *ones(size(inVid(:,:,1)));

%     params.off_threshold            = 0.2*ones(size(inVid(:,:,1)));

    %params.on_threshold             = 0.1*ones(size(inVid(:,:,1)));
    %params.off_threshold            = 0.1*ones(size(inVid(:,:,1)));
else
%     params.on_threshold             = 0.25 * abs(1/log(brightness_ratio));
%     params.off_threshold            = 0.25 * abs(1/log(brightness_ratio)); % roughly from DVS paper
    params.on_threshold             = 0.25* abs(1/log(brightness_ratio)) * ones(size(inVid(:,:,1)));
    params.off_threshold            = 0.25* abs(1/log(brightness_ratio)) * ones(size(inVid(:,:,1)));
end

params.percent_threshold_variance   = 2.5; % 2.5% variance in threshold - from DVS paper

params.enable_threshold_variance    = 1;
params.enable_pixel_variance        = 0;
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

[TD, eventFrames, ~, grayFrames, curFrames] = RetinaNvsModel(double(inVid), params);


%%

% outframes = videoBlend(inVid, eventFrames, 0, 1, 'test.avi');

%% Write video

% run = '_run_04';
% 
% save(['../../../data/gait/mats/dm_1_Jump_Fwd_Then_Bwd_NW_SE_params_' run '.mat'],'params')
% save(['../../../data/gait/mats/dm_1_Jump_Fwd_Then_Bwd_NW_SE_events_' run '.mat'],'TD')
% v = VideoWriter(['../../../data/gait/vids/dm_1_Jump_Fwd_Then_Bwd_NW_SE_event_frames' run '.avi']);
% open(v);
% 
% for k = 1:size(eventFrames,4)
%    imagesc(eventFrames(:,:,:,k));
%    pause(1/10);
%    M = getframe(gcf);
%    writeVideo(v,M);
% end
%  
% close(v);
% 
% v = VideoWriter(['../../../data/gait/vids/dm_1_Jump_Fwd_Then_Bwd_NW_SE_gray_frames' run '.avi']);
% open(v);
% 
% for k = 1:size(inVid,3)
%    imagesc(inVid(:,:,k));
%    pause(1/10);
%    M = getframe(gcf);
%    writeVideo(v,M);
% end
%  
% close(v);
% 
% v = VideoWriter(['../../../data/gait/vids/dm_1_Jump_Fwd_Then_Bwd_NW_SE_blended_frames' run '.avi']);
% open(v);
% 
% for k = 1:size(outframes,4)
%    imagesc(outframes(:,:,:,k));
%    pause(1/10);
%    M = getframe(gcf);
%    writeVideo(v,M);
% end
%  
% close(v);
% 
% for f = 1:size(inVid,3)
%     image(outframes(:,:,:,f));
%     pause(1/10);
% end
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


