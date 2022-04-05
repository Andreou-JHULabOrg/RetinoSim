clear;

videoFile = '../../../../spike_proc/data/video/motion1.avi';


v = VideoReader(videoFile);
frameIdx = 1;
numFrames =300;


wv = VideoWriter('../../../../spike_proc/data/video/c_motion1.avi');
open(wv);

while hasFrame(v)
    if frameIdx == numFrames
        break;
    end
    frame = readFrame(v);
    
    cropFrame = rgb2gray(frame(50:350, 75:505,:));
    

    outVid(:, : , frameIdx) = cropFrame;

    imagesc(outVid(:,:,frameIdx)); colormap(gray);

    frameIdx = frameIdx + 1;
    
    frame = getframe();
    writeVideo(wv,cropFrame);
    
    pause(1/10);
end


close(wv);



