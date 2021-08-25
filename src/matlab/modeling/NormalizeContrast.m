function [imgOut] = NormalizeContrast(imgIn)
img_16 = uint16(imgIn);
alpha = 1;
horiz = fspecial('gaussian', 15, 2.5);
pr = fspecial('gaussian',15, 2);
img_bg = imfilter(img_16, horiz, 'replicate');
img_current = imfilter(img_16, pr, 'replicate');
img_c = double((alpha*img_current - img_bg)); % find the contrast
img_c = img_c - min(min(img_c)); % bring to pos
imgOut = img_c/max(max(img_c))*255; % normalize and scale

