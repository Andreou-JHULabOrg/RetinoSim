function writeOutputVideo(inputFrames, filepath)
%writeOutputVideo Summary of this function goes here

v = VideoWriter(filepath);
numDims = length(size(inputFrames));
open(v);
for k = 1:size(inputFrames,numDims)
    if numDims == 4
        currentRGBFrame = (inputFrames(:,:,:,k));
    elseif numDims == 3
        currentRGBFrame = (inputFrames(:,:,k));
    end
    scaledFrame = uint8(rescale(currentRGBFrame,0,255));
    writeVideo(v,scaledFrame);
end
close(v);

end

