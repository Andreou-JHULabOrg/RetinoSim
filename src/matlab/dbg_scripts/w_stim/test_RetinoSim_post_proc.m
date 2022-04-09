
k = 1:100;


x =  k * 2*pi*htf;
hx = sin(x) * hamp;

figure();

xt = squeeze(frames(:,512,2:end).*128);
ft0 = squeeze(dbgFrames(:,512,2:end));
plot(ft0,'*-'); hold on; plot(xt, '*-'); hold off
av = max(ft0)/max(xt);

figure();

xs = squeeze(frames(:,:,2).*128);
fs0 = squeeze(dbgFrames(:,:,2));
plot(fs0,'*-'); hold on; plot(xs, '*-'); hold off

av = max(fs0)/max(xs);


figure(); 

vs = [0.01 0.02 0.04 0.06 0.08 0.1 0.15 0.2 0.25];
resp = [0.9912 0.9957 0.926 0.819 0.811 0.768 0.67 0.65 0.65];
plot(vs, resp, '*-')