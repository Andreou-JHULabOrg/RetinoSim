% plotting for information processing

% Point-to-point connectivity between neuromorphic chips using address events

gamma = 10;
psi = 2;

a = 0.10;

N = 32*32;

fNyq = 100;

Z = gamma;

%%

a = 0.0:.01:1.0;



fbit_adapt = fNyq*(a+(1-a)/Z)*log2(N);


plot(a,fbit_adapt); hold on; plot(a,ones(1,length(a))*fNyq); hold off;
%%
Fch = 1e6;
fch = Fch/N;


fNyq = fch./(a+(1-a)/Z);

plot(a,fNyq);
%%

Tch = 1/Fch;

fnu = 1e3;

G = N*fnu/Fch;

pcolest = 1-poisspdf(0,2*G);

Pcol = 0:0.001:1.0;
S = ((1-Pcol)/2).*log(1./(1-Pcol));

plot(Pcol, S);

%%

mean_wait = G/(2*(1-G));
var_wait = mean_wait^2 + 2/3*(mean_wait);

neuronal_latency = 1e-3;

timing_error = G./(a.*N)*((2-G)/(1-G));

plot(a,timing_error);
a = 0.01;
S_arb = N*(timing_error./2 + 1/(N*a)-sqrt((timing_error./2).^2 + 1./(N*a).^2));

