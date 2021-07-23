function [imgOut] = NormalizeContrast(imgIn)
img_16 = uint16(imgIn);
alpha = 5;
horiz = fspecial('gaussian', 15, 2.5);
pr = fspecial('gaussian',15, 2);
%bg = (1/8)*ones(3,3); bg(2,2) = 0; 
img_bg = imfilter(img_16, horiz, 'replicate');
img_current = imfilter(img_16, pr, 'replicate');
img_c = double((alpha*img_current - img_bg))./double(img_bg) - (alpha-1); % bring to 0
img_c = img_c - min(min(img_c)); % bring to pos
imgOut = img_c/max(max(img_c))*255; % normalize and scale

% total_spatial_response = ((pr_spatial_response - horiz_spatial_response)./(horiz_spatial_response));
% img = imfilter(img, total_spatial_response);
% histogram(img(:));
% imgs = [img img_bg img_c];
% montage(imgs);
