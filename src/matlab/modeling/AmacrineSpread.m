function [onOut,offOut] = AmacrineSpread(onIn,offIn, size, std)
%Apply Gaussian filter over sojme input
%   Detailed explanation goes here
gfilter = fspecial('gaussian', size, std);
onOut = imfilter(onIn, gfilter);
offOut = imfilter(offIn, gfilter);
end

