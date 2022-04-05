function [out] = makeFrames(varargin)
%function to create video from binned events
%modified from previos versions to accept only TD struct instead of file
%I/O
%Jonah P. Sengupta - 1/6/20
%startEvent =  specfies which event to use to start creating frames
%stopEvent =  specfies which is the last event to use to create frames
%bt =  bin time - the amount of time in microseconds to bin events together for frames
%TD = four member structure that includes x, y, p, ts
%
%out = 3 dimensional output array which is 128x128xlength(vid)/dt

switch nargin
    case 0
        error("Need at least one argument.");
    case 1
        TD = varargin{1};
        method = 'time';
        bin_param = 10e3;
        showFrame = 0;
        writeVid = 0;
        fps = 10;
        filepath = './test.mp4';
        IsFrames = 0;
        Frames = 0;
    case 2
        TD = varargin{1};
        method = varargin{2};
        bin_param = 10e3;
        showFrame = 0;
        writeVid = 0;
        fps = 10;
        filepath = './test.mp4';
        IsFrames = 0;
        Frames = 0;
    case 3
        TD = varargin{1};
        method = varargin{2};
        bin_param = varargin{3};
        showFrame = 0;
        writeVid = 0;
        fps = 10;
        filepath = './test.mp4';
        IsFrames = 0;
        Frames = 0;
    case 4
        TD = varargin{1};
        method = varargin{2};
        bin_param = varargin{3};
        showFrame = varargin{4};
        writeVid = 0;
        fps = 10;
        filepath = './test.mp4';
        IsFrames = 0;
        Frames = 0;
    case 5
        TD = varargin{1};
        method = varargin{2};
        bin_param = varargin{3};
        showFrame = varargin{4};
        writeVid = varargin{5};
        fps = 10;
        filepath = './test.mp4';
        IsFrames = 0;
        Frames = 0;
    case 6
        TD = varargin{1};
        method = varargin{2};
        bin_param = varargin{3};
        showFrame = varargin{4};
        writeVid = varargin{5};
        fps = varargin{6};
        filepath = './test.mp4';
        IsFrames = 0;
        Frames = 0;
    case 7
        TD = varargin{1};
        method = varargin{2};
        bin_param = varargin{3};
        showFrame = varargin{4};
        writeVid = varargin{5};
        fps = varargin{6};
        filepath = varargin{7};
        IsFrames = 0;
        Frames = 0;
    case 8:9
        TD = varargin{1};
        method = varargin{2};
        bin_param = varargin{3};
        showFrame = varargin{4};
        writeVid = varargin{5};
        fps = varargin{6};
        filepath = varargin{7};
        IsFrames = varargin{8};
        Frames = varargin{9};
    otherwise 
        error("Need at most 7 arguments.")
end

fprintf("[makeFrames-INFO] Parameters for frame binning: \n\t Method: %s\n\t Bin Parameter: %d \n\t showFrame: %d \n\t writeVid: %d \n\t FramesPerSecond %d\n\t Filepath: %s\n", ...
    method, bin_param, showFrame, writeVid, fps, filepath);

TD_new.x = double(TD.x + 1); %adjust for matlab
TD_new.y = double(TD.y + 1);
% x_new = double(TD.x);
% y_new = double(TD.y);
TD_new.p = double(TD.p);
TD_new.ts = double(TD.ts);

startEvent = 1;
stopEvent = length(TD_new.p);

min_ts = double(TD_new.ts(1));

r_t = TD_new.ts(end)-TD_new.ts(1); %run time

nevents = length(TD_new.x);

if strcmp(method, "time")
   nFrames = ceil(r_t/bin_param)+1; 
elseif strcmp(method, "events")
    nFrames = ceil(nevents/bin_param)+1;
else
    error("makeFrames-ERROR] Method needs to be either time or events.\n");
end


fprintf("[makeFrames-INFO] Number of frames: %d\n", nFrames);

% out = zeros(max(TD.y)+1, max(TD.x)+1,nFrames);
% out = 128*ones(max(TD.y)+1, max(TD.x)+1,nFrames);
out  = zeros(max(TD.y)+1, max(TD.x)+1,3,nFrames);

FrameCt = 1;
EventCt = 1;


for f = 1:nFrames
    if strcmp(method, "time")
        startT = bin_param * (f - 1) + min_ts;
        endT = bin_param * f + min_ts;
        [~, ixStart] = min(abs(startT - TD_new.ts(:)));
        [~, ixEnd] = min(abs(endT - TD_new.ts(:)));
    elseif strcmp(method, "events")
        ixStart = bin_param * (f - 1) + 1;
        ixEnd = min(bin_param * f, nevents);
    end
    
    for iT = ixStart:ixEnd
        if (TD_new.p(iT) == 1)
            out(TD_new.y(iT), TD_new.x(iT), 3, f) = out(TD_new.y(iT), TD_new.x(iT), 3, f) + TD_new.p(iT);
        else
            out(TD_new.y(iT), TD_new.x(iT), 2, f) = out(TD_new.y(iT), TD_new.x(iT), 2, f) + abs(TD_new.p(iT));
        end
    end    
end

FrameCt = nFrames;

if IsFrames
    out=Frames;
end

if showFrame == 1
    figure();
    if writeVid
		v = VideoWriter(filepath, 'MPEG-4');
		v.FrameRate = 10;
		open(v);
	end
    for ii = 1:FrameCt
        curFrame = out(:,:,:,ii);
        imshow(curFrame);
        title(['Frame: ' num2str(ii) ', Time: ' num2str(ii*bin_param + TD.ts(1))]);
        colormap(gray);
        pause(1/fps);
        frame = getframe(gcf);
		if writeVid
			writeVideo(v,frame);
		end
    end
end

if writeVid
	close(v);
end

end