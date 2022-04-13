imagesc(eventFrames(:,:,:,63)); set(gca, 'xtick', [] , 'ytick', []); 

imwrite(eventFrames(:,:,:,63),'/Users/jonahs/Documents/research/docs/papers/ICONS2022/retinosim/figs/walk_loglowpass_events.png')

imagesc(uint8(dbgFrames(:,:,63)./max(dbgFrames(:,:,63), [], 'all')*255)); colormap(gray); set(gca, 'xtick', [] , 'ytick', []); 

imwrite(uint8(dbgFrames(:,:,63)./max(dbgFrames(:,:,63), [], 'all')*255),'/Users/jonahs/Documents/research/docs/papers/ICONS2022/retinosim/figs/walk_linear_bc.png')


figure();

iframe = input_vid(:,:,63);
Y = fft2(iframe);
Yabs = abs(fftshift(Y));
imagesc(Yabs)

figure();

eframe = eventFrames(:,:,1,63) + eventFrames(:,:,2,63);
Y = fft2(eframe);
Yabs = abs(fftshift(Y));
imagesc(Yabs)


459293
355493

177913 - with 500 us, refr. time
356245 - with 100 us, refr. time
1112547 - 2.2
1112839 - 2.2
1154946 - 2.5
1215220 - 3
1291495 - 4
1331201 - 5