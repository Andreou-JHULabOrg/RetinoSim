function [imgOut] = NormalizeContrast(imgIn, variances)
% img_16 = uint16(imgIn);
img_16 = (imgIn);

alpha = 1;
horiz = fspecial('gaussian', 15, variances(2));
pr = fspecial('gaussian',15, variances(1));
img_bg = imfilter(img_16, horiz, 'replicate');
img_current = imfilter(img_16, pr, 'replicate');
img_c = alpha*double(img_current)-double(img_bg); % find the contrast
img_c = img_c - min(min(img_c)); % bring to pos
imgOut = img_c/mean(mean(img_c))*255; % normalize and scale

end

