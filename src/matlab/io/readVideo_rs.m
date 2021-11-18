function [ outVid ] = readVideo_rs( videoFile, nrows, ncols, numframes, sampRate )
v = VideoReader(videoFile);

framect = 1;
frameIdx  = 1;
while hasFrame(v)
    if frameIdx == numframes
        break;
    end
    frame = readFrame(v);
    
    outVid(:, : , frameIdx) = imresize(rgb2gray(frame), [nrows ncols]);

%     if mod(frameIdx,sampRate) == 0
%         outVid(:, : , framect) = imresize(rgb2gray(frame), [nrows ncols]);
%         framect = framect + 1;
%     end    
    frameIdx = frameIdx + 1;
end


end

