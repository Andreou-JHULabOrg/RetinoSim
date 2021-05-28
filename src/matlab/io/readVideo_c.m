function [ outVid ] = readVideo_c( videoFile )
v = VideoReader(videoFile);
ii = 1; 
while hasFrame(v)
    frame = readFrame(v);
    outVid(:, : , : ,ii) = frame;
     ii = ii + 1;
end

end

