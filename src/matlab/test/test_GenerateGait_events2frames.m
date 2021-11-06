clear;clc;

addpath(genpath('../modeling'));
addpath(genpath('../aux'));
addpath(genpath('../io'));


%%
videoFileRoot = '/Users/jonahs/Documents/research/projects/RetinaNVSmodel/data/mat/gait/082521/';

trials = {
    'ss_1', ...
    'js_1', ...
    'mt_1'
    };

mvmts = {
    '_walk_N_S', ...
    '_walk_W_E', ...
    '_walk_in_place', ...
    '_walk_NE_SW', ...
    '_walk_NW_SE'
};

nrows = 512;
ncols = 512;
numframes = 400;

bin_params.method = 'time';
bin_params.bin_length = 33e3;


%%
for curTidx = 1:length(trials)
	for curMidx = 1:length(mvmts)
        
        clear TD
        
        filenamePrefix = [trials{curTidx} mvmts{curMidx}];
        filePath = [videoFileRoot filenamePrefix '_sensor0.mat'];
        [TD] = loadAEFile(filePath);
        
        [eventFrames] = makeFrames(TD, bin_params.method, bin_params.bin_length);
        			
        v = VideoWriter([outputDirectory '/vids/' filenamePrefix '_event_frames_' run '.avi']);
        open(v);
        for k = 1:size(eventFrames,4)
            currentRGBFrame = (eventFrames(:,:,:,k));
            scaledFrame = uint8(rescale(currentRGBFrame,0,255));
            writeVideo(v,scaledFrame);
        end
        close(v);
        
    end
end