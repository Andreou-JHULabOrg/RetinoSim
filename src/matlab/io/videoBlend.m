function [ outVid ] = videoBlend( vid1, vid2, writeVid, showVid, filepath)
%VIDEOBLEND overlays two video data structures and writes to file.
% Note videoBlend always overlays the second video over the first
% Inputs
%       vid1:
%           MxNx(3)xD input array
%       vid2:
%           MxNx(3)xD input array

if length(size(vid1)) > 4 || length(size(vid2)) > 4
    error('Input videos exceed 4 dimensions'); 
end

if length(size(vid1)) < 3 || length(size(vid2)) < 3
    error('Input videos are less than 2 dimensions'); 
end

if length(size(vid1)) == 3
    numFrames_vid1 = size(vid1,3);
else
    numFrames_vid1 = size(vid1,4);
end

if length(size(vid2)) == 3
    numFrames_vid2 = size(vid2,3);
else
    numFrames_vid2 = size(vid2,4);
end

numFrames = min(numFrames_vid1,numFrames_vid2);

if numFrames_vid2 > numFrames_vid1
    outVid = uint8(zeros(size(vid1,1),size(vid1,2),3,numFrames));
else
    outVid = uint8(zeros(size(vid1,1),size(vid1,2),3,numFrames));
end

colors = ['r'; 'g'; 'b'];

if length(size(vid2)) == 4
    for f = 1:numFrames
        C = vid1(:,:,f);
        for d = 1:size(vid2,3)
            C = imoverlay(C,vid2(:,:,d,f), colors(d));
        end
%         imagesc(C);
%         pause(1/10);
        outVid(:,:,:,f) = C;
    end
else
    for f = 1:numFrames
        outVid(:,:,:,f) = imoverlay(vid1(:,:,f),vid2(:,:,f), colors(1));        
    end
end


if showVid
    for f = 1:numFrames
        imagesc(outVid(:,:,:,f));
        pause(1/10);
    end
end

end

