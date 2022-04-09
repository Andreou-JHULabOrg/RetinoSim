%%

clear;clc;

addpath(genpath('../modeling'));
addpath(genpath('../aux'));
addpath(genpath('../io'));

%%

videoFileRoot = '/Users/jonahs/Documents/research/projects/RetinaNVSmodel/data/gait/ss_inputs/';
videoFilePrefix = 'ss_1_';
videoFileSuffix = {
                    'fwd_bwd_walk_E_W', ...
                    'fwd_bwd_walk_N_S', ...
                    'fwd_bwd_walk_NE_SW', ...
                    'fwd_bwd_walk_NW_SE', ...
                    'in_place_walk'...
                   };
%%
               
               
nrows = 512;
ncols = 512;
numframes = 500;

%% crop video 1

file = [videoFileRoot videoFilePrefix videoFileSuffix{1} '.mp4'];
inVid = brightness_ratio * readVideo_rs( file, nrows, ncols, numframes, 1 );

for f = 1:numframes
    image(inVid(:,:,f));
    title('Frame:', f);
    pause(1/30);
end

cropStart = 150; numframes_crop = 300;
inVid_crop = inVid(:,:,cropStart:numframes_crop+cropStart-1);
for f = 1:numframes_crop
    image(inVid_crop(:,:,f));
    title('Frame:', f);
    pause(1/30);
end

save([videoFileRoot 'mats/' videoFilePrefix videoFileSuffix{1} '_crop.mat'], 'inVid_crop');


%% crop video 2

file = [videoFileRoot videoFilePrefix videoFileSuffix{2} '.mp4'];
inVid = brightness_ratio * readVideo_rs( file, nrows, ncols, numframes, 1 );

for f = 1:numframes
    image(inVid(:,:,f));
    title('Frame:', f);
    pause(1/30);
end

cropStart = 100; numframes_crop = 300;
inVid_crop = inVid(:,:,cropStart:(numframes_crop+cropStart-1));
for f = 1:numframes_crop
    image(inVid_crop(:,:,f));
    title('Frame:', f);
    pause(1/30);
end

save([videoFileRoot 'mats/' videoFilePrefix videoFileSuffix{2} '_crop.mat'], 'inVid_crop');


%% crop video 3

file = [videoFileRoot videoFilePrefix videoFileSuffix{3} '.mp4'];
inVid = brightness_ratio * readVideo_rs( file, nrows, ncols, numframes, 1 );

for f = 1:numframes
    image(inVid(:,:,f));
    title('Frame:', f);
    pause(1/30);
end

cropStart = 100; numframes_crop = 300;
inVid_crop = inVid(:,:,cropStart:(numframes_crop+cropStart-1));
for f = 1:numframes_crop
    image(inVid_crop(:,:,f));
    title('Frame:', f);
    pause(1/30);
end

save([videoFileRoot 'mats/' videoFilePrefix videoFileSuffix{3} '_crop.mat'], 'inVid_crop');

%% crop video 4


numframes = 800;
file = [videoFileRoot videoFilePrefix videoFileSuffix{4} '.mp4'];
inVid = brightness_ratio * readVideo_rs( file, nrows, ncols, numframes, 1 );

for f = 200:numframes
    image(inVid(:,:,f));
    title('Frame:', f);
    pause(1/30);
end

cropStart = 300; numframes_crop = 300;
inVid_crop = inVid(:,:,cropStart:(numframes_crop+cropStart-1));
for f = 1:numframes_crop
    image(inVid_crop(:,:,f));
    title('Frame:', f);
    pause(1/30);
end

save([videoFileRoot 'mats/' videoFilePrefix videoFileSuffix{4} '_crop.mat'], 'inVid_crop');

%% crop video 5

numframes = 360;
file = [videoFileRoot videoFilePrefix videoFileSuffix{5} '.mp4'];
inVid = brightness_ratio * readVideo_rs( file, nrows, ncols, numframes, 1 );

for f = 1:numframes
    image(inVid(:,:,f));
    title('Frame:', f);
    pause(1/30);
end

cropStart = 60; numframes_crop = 300;
inVid_crop = inVid(:,:,cropStart:(numframes_crop+cropStart-1));
for f = 1:numframes_crop
    image(inVid_crop(:,:,f));
    title('Frame:', f);
    pause(1/30);
end

save([videoFileRoot 'mats/' videoFilePrefix videoFileSuffix{5} '_crop.mat'], 'inVid_crop');


%% parameterize model

params.frames_per_second            = 30;
params.frame_show                   = 0;

params.resample_threshold           = 0;
params.rng_settings                 = 1;

params.on_threshold             = 30 *ones(size(inVid(:,:,1)));
params.off_threshold             =30 *ones(size(inVid(:,:,1)));

params.percent_threshold_variance   = 2.5; % 2.5% variance in threshold - from DVS paper

params.enable_threshold_variance    = 1;
params.enable_pixel_variance        = 1;
params.enable_diffusive_net         = 1;
params.enable_temporal_low_pass     = 1;

params.enable_leak_ba           = 1;

params.leak_ba_rate             = 40;


params.enable_refractory_period = 0;
params.refractory_period        = 1 * (1/params.frames_per_second);


params.inject_spike_jitter      = 0;

params.inject_poiss_noise       = 0;

params.write_frame = 0;
params.write_frame_tag = 'leakrate_5_diffnet_1';

MatsFileRoot = '/Users/jonahs/Documents/research/projects/RetinaNVSmodel/data/gait/mats/ss_inputs/';
run = 'run_00';
file = [MatsFileRoot run '_' videoFilePrefix 'params.mat'];
save(file, 'params');

%% run model through cropped videos
clear inVid_crop

for v = 1:numel(videoFileSuffix)
    load([videoFileRoot 'mats/' videoFilePrefix videoFileSuffix{v} '_crop.mat']);
    [TD{v}, eventFrames{v}, ~, grayFrames, curFrames] = RetinaNvsModel(double(inVid_crop), params);
end

%% Save .mat and .avi files
for v = 1:numel(videoFileSuffix)
    file = [MatsFileRoot run '_' videoFilePrefix videoFileSuffix{v} 'eventsFrames.mat'];
    eventFrames_out = eventFrames{v};
    save(file, 'eventFrames_out');
    file = [MatsFileRoot run '_' videoFilePrefix videoFileSuffix{v} 'events.mat'];
    TD_out = TD{v};
    save(file, 'TD_out');
    
    VidsFileRoot = '/Users/jonahs/Documents/research/projects/RetinaNVSmodel/data/gait/vids/';
    vid = VideoWriter([VidsFileRoot run '_' videoFilePrefix videoFileSuffix{v} '_eventFrames.avi']);
    open(vid);
    for f = 1:size(eventFrames{v},4)
        imagesc(eventFrames_out(:,:,:,f));
        pause(1/10);
        M = getframe(gcf);
        writeVideo(vid,M);
    end
    close(vid);
end


%%

for f = 1:size(eventFrames{1},4)
    imagesc(eventFrames{5}(:,:,:,f));
    pause(1/10);
   
end
