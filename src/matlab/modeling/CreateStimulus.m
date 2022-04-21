function imgs = CreateStimulus(hsf, vsf, htf, vtf, hamp, vamp, write, videoPath, num_frames, dims)
%%% This is a function that creates 2D-grid stimulus for testing purposes
%%% Author: Susan Liu
% hsf: horizontal spatial frequency, range [2, 5]
% vsf: vertical spatial frequency, range [2, 5]
% htf: horizontal temporal frequency, range [0, 10]
% vtf: vertical temporal frequency, range [0, 10]
% hamp: horizontal amplitude, range [0, 1]
% vamp: vertical amplitude, range [0, 1]
% write: whether write to a file
% videoPath: the file to write to


width = dims(2);
height = dims(1);
num_frame = num_frames;


imgs = zeros(height,width,num_frame);

if write
    v = VideoWriter(videoPath);
    open(v);
else
    figure
end
hbin = 0:1:width-1;
vbin = 0:1:height-1;
for k = 0:num_frame
	
	% construct horizontal sinusoid component
	
    x = hbin.* 2*pi*hsf + k * 2*pi*htf;
    hx = sin(x) * hamp;
    hx = hx;
    cha = repmat(hx, [height, 1]);
	hstr = cha;

%     hstr = cat(3, cha, cha, cha);

    % construct vertical sinusoid component
    x = vbin.* 2*pi*vsf + k * 2*pi*vtf;
	vx = (sin(x) * vamp)';

%     vx = 0.25 + sin(x) * vamp;
    cha = repmat(vx, [1, width]);
	vstr = cha;
%     vstr = cat(3, cha, cha, cha);
	im = hstr + vstr;
	imgs(:,:,k+1) = im;
    if write
        writeVideo(v, im);
    else
        imagesc(im);
        pause(1/60);
    end
end
if write
    close(v)
end


end
