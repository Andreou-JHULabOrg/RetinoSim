
%%% The testing function for 2D-grid stimulus generation
%%% Author: Susan Liu

% hsf: horizontal spatial frequency, range [2, 5]; 0 for no horizontal bars
% vsf: vertical spatial frequency, range [2, 5]; 0 for no vertical bars
% htf: horizontal temporal frequency, range [0, 10]
% vtf: vertical temporal frequency, range [0, 10]
% hamp: horizontal amplitude, range [0, 1]
% vamp: vertical amplitude, range [0, 1]
% write: whether write to a file
% vPath: the file to write to

clear; clc;

addpath(genpath('../modeling'))

hsf = 0.1; % 1/512 fundamental frequencies to allow for full resolvement of the frequency
vsf = 0.1;
htf = 0.05;
vtf = 0;
hamp = 1;
vamp = 1;
write = false;

vPath = '/home/jonahs/projects/ReImagine/AER_Data/model_stim/hsf_0_vsf_4_htf_2_vtf_0_hamp_255_vamp_255.avi';

dims = [512 512];

frames = CreateStimulus(hsf, vsf, htf, vtf, hamp, vamp, write, vPath, 99, dims);

% 2D DFT of input
x_ = frames(:,:,1);

X = fft2(x_);
Xabs = abs(fftshift(X));
figure();
imagesc(Xabs)

%2D DFT of Bandpass filter

figure();

farr=zeros(10,512,512);

for ii = 2:11
	
	gamma_h = ii;
	horiz = fspecial('gaussian', 512, gamma_h);
	pr = fspecial('gaussian',512, 2);
	hc = (pr - horiz);

	subplot(2,5,ii-1);
	F = fft2(hc);
	Fabs = abs(fftshift(F));
	fg = imagesc(Fabs);
	
	farr(ii-1,:,:) = Fabs;
	
	xt = get(gca, 'XTick'); xt = (xt - 256)/512;
	yt = get(gca, 'YTick'); yt = (yt - 256)/512;

% 	set(gca, 'YTickLabels', yt);
% 	set(gca, 'XTickLabels', xt, 'XTickLabelRotation', 90);
    set(gca, 'YTick', []);
	set(gca, 'XTick', []);
	title(['FFT of OPL Spatial Filter with $\gamma_{h}$ =' num2str(ii)], 'interpreter', 'latex')
end

%Plot Spectral response of spatial filter

figure();
legend_cells = {};
for ii = 1:10
fSlice = squeeze(farr(ii,256,256:end));
hold on
plot((0:256)/512, fSlice);
legend_cells{ii} = ['\gamma_{h} =' num2str(ii+1)];
end
legend(legend_cells);

hold off
grid on
xlabel('Cyc./pix.', 'interpreter','latex');

% figure();
% surf(hc)





%Filter Output

hf = imfilter(x_, hc, 'replicate');

hf = hf - min(min(hf)); % bring to pos
hf0 = hf/max(max(hf))*255; % normalize and scale

% imagesc([f_ hf0])
figure();
Y = fft2(hf);
Yabs = abs(fftshift(Y));
imagesc(Yabs)

%1D DFT of Spatial Wave
figure();
f_  = frames(1,:,1);
plot(f_)
res = 2*abs((fft(f_)/400));
figure();
plot((0:256)/512,res(1:257), '-*');

%1D DFT of Temporal Wave

ft_ = squeeze(frames(1,1,:));
figure();
plot(ft_)

fs = 60;
ts = 1/fs;
nf = size(frames,3);
tres = 2*abs(fft(ft_)/nf); % divide by nf to normalize to single point (sums N points), mult by two to relate double sided spectra to single

figure();
plot(fs/nf*(0:nf/2), tres(1:nf/2+1))
