%%%% Script to demo bandpass filtering in spatial domain

im_in  = double(imread('cameraman.tif'));

fpn = normrnd(0,50,size(im_in));

im_n = im_in + fpn;

image(im_n);


% Y = fft2(im_in);
% imagesc(abs(fftshift(Y)))
% 
horiz = fspecial('gaussian', 15, 2.5);
pr = fspecial('gaussian',15, 2);

opl_ = 1*pr - horiz;
surf(opl_)

img_p = imfilter(im_n, opl_, 'replicate');

% image(img_p);

imo = [im_n img_p];

% image(imo);



