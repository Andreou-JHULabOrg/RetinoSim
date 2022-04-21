%%%% Demo Retina-NVS model function

clear;clc;


addpath(genpath('../modeling'));
addpath(genpath('../aux'));
addpath(genpath('../io'));

%%


trials = {
    'ss_1', ...
    'js_1', ...
    'mt_1'
    };

% mvmts = {
%     '_walk_N_S', ...
%     '_walk_W_E', ...
%     '_walk_in_place', ...
%     '_walk_NE_SW', ...
%     '_walk_NW_SE'
% };

mvmts = {
    '_walk_in_place'
};


%%

params.frames_per_second            = 30;
params.frame_show                   = 0;

params.nrows = 512;
params.ncols = 512;
params.numFrames = 400;

params.resample_threshold           = 0;
params.rng_settings                 = 1;


params.on_threshold             = 10 *ones(params.nrows, params.ncols);
params.off_threshold             =10 *ones(params.nrows, params.ncols);


params.percent_threshold_variance   = 2.5; % 2.5% variance in threshold - from DVS paper

params.enable_threshold_variance    = 1;
params.enable_pixel_variance        = 0;
params.enable_diffusive_net         = 0;
params.enable_temporal_low_pass     = 1;

params.isGPU                        = 1;

params.enable_leak_ba           = 1;

params.leak_ba_rate             = 60;


params.enable_refractory_period = 0;
params.refractory_period        = 1 * (1/params.frames_per_second);


params.inject_spike_jitter      = 0;

params.inject_poiss_noise       = 0;

params.write_frame = 0;
params.write_frame_tag = 'leakrate_5_diffnet_1';

videoFileRoot = '/home/jonahs/projects/ReImagine/AER_Data/gait/082521/avi/';
run = 'run_05';
outputDirectory =['/home/jonahs/projects/ReImagine/AER_Data/model_output/gait/' run];

save([outputDirectory '/mats/genscript1_' run '_params.mat'],'params');

%%


% HAD TO INSTALL GSTREAMER1.0 and ALL PLUGINS TO GET AVI and MP4 to work on
% LINUX

for curTidx = 1:length(trials)
	for curMidx = 1:length(mvmts)
		
		% --------------------------------------------------- 1. LOAD VIDEO
		
		filenamePrefix = [trials{curTidx} mvmts{curMidx}];
		videoFile = [videoFileRoot filenamePrefix '.avi'];
		outFilePath = [outputDirectory '/vids/' filenamePrefix '_event_frames_' run '.avi'];
		
		fprintf("[genscript-INFO] Reading from %s and outputting to %s\n", videoFile, outFilePath);
		
% 		try
			inVid = readVideo_rs( videoFile, params.nrows, params.ncols, params.numFrames, 1 );
			
			fprintf('[genscript-INFO] Generating events from video file: %s.avi\n', filenamePrefix);
			
			% ------------------------------------------------ 2. PROCESS VIDEO
			
			[TD, eventFrames, ~, grayFrames, curFrames] = RetinaNvsModel(double(inVid), params);
			
			% ------------------------------------------------- 3. SAVE OUTPUTS
			
			outframes = videoBlend(inVid, eventFrames, 0, 0, 'test.avi');
			
			save([outputDirectory '/mats/' filenamePrefix '_events_' run '.mat'],'TD');
			
			v = VideoWriter([outputDirectory '/vids/' filenamePrefix '_event_frames_' run '.avi']);
			open(v);
			for k = 1:size(eventFrames,4)
				currentRGBFrame = (eventFrames(:,:,:,k));
				scaledFrame = uint8(rescale(currentRGBFrame,0,255));
				writeVideo(v,scaledFrame);
			end
			close(v);
% 		catch ME
% 			warning('Video file not found');
% 		end

		
	end
end

