function [ outVid ] = readVideo_rs( videoFile, nrows, ncols, numframes, sampRate )
v = VideoReader(videoFile);

framect = 1;

for ii = 1:numframes
	try 
		frame = readFrame(v);
		
		
		if mod(ii,sampRate) == 0
			outVid(:, : , framect) = imresize(rgb2gray(frame), [nrows ncols]);
			framect = framect + 1;
		end
	catch
		break
	end

end


end

