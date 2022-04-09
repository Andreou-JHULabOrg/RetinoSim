clear;clc;

addpath(genpath('../modeling'));
addpath(genpath('../aux'));
addpath(genpath('../io'));


%%
videoFileRoot = '/home/jonahs/projects/ReImagine/AER_Data/gait/082521/';
outputDirectory =[videoFileRoot 'out/'];

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

params.nrows = 512;
params.ncols = 512;
params.numframes = 400;

params.method = 'time';
params.bin_length = 33e3;
run = 'run_00';

save([outputDirectory 'genframes_' run '_params.mat'],'params');


%%
for curTidx = 1:length(trials)
	for curMidx = 1:length(mvmts)
        
        clear TD
        
        filenamePrefix = [trials{curTidx} mvmts{curMidx}];
        filePath = [videoFileRoot filenamePrefix '_sensor_0.mat'];
		outputFilePath = [outputDirectory 'vids/' filenamePrefix '_event_frames_' run '.avi'];
		
		fprintf("Reading from %s and outputting to %s\n", filePath, outputFilePath);
        [TD] = loadAEFile(filePath);
        
        [eventFrames] = makeFrames(TD, params.method, params.bin_length);
        			
        v = VideoWriter(outputFilePath);
        open(v);
        for k = 1:params.numframes
            currentRGBFrame = imresize(eventFrames(:,:,:,k), [params.nrows params.ncols]);
            scaledFrame = uint8(rescale(currentRGBFrame,0,255));
            writeVideo(v,scaledFrame);
        end
        close(v);
        
    end
end