function [] = CreateStimulus(hsf, vsf, htf, vtf, hamp, vamp, write, videoPath)
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

hsf = hsf * 0.1;
vsf = vsf * 0.1;
width = 400;
height = 400;
num_frame = 300;
hamp = hamp * 0.25;
vamp = vamp * 0.25;

if write
    v = VideoWriter(videoPath, 'MPEG-4');
    open(v);
else
    figure
end
hbin = 0:1:width-1;
vbin = 0:1:height-1;
for k = 0:num_frame
    x = (hbin + k * htf) .* hsf;
    hy = 0.25 + sin(x) * hamp;
    hy = hy.';
    cha = repmat(hy, [1, height]);
    hstr = cat(3, cha, cha, cha);
    x = (vbin + k * vtf) .* vsf;
    vx = 0.25 + sin(x) * vamp;
    cha = repmat(vx, [width, 1]);
    vstr = cat(3, cha, cha, cha);
    im = hstr + vstr;
%     figure
%     image(im)
    if write
        writeVideo(v, im);
    else
        image(im);
        pause(1/60);
    end
end
if write
    close(v)
end
end
