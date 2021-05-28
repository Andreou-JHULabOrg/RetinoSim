function [ outVid ] = readVideo_rs( videoFile, nrows, ncols, numframes )
v = VideoReader(videoFile);
for ii = 1:numframes
    frame = readFrame(v);
    outVid(:, : , ii) = imresize(rgb2gray(frame), [nrows ncols]);
end

end

