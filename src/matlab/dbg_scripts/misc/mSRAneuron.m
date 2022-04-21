%% Script to resolve behavior of SRA neuron with HPF current input


%% Script parameters
clear;clc;

vmem    = 10;
% imem    = [2*ones(1,100) 5*ones(1,100) 7*ones(1,100) 10*ones(1,100)];
% discrete time membrane input current
imem    = [1*ones(1,100) 4*ones(1,200) 5*ones(1,300) 8*ones(1,200) 10*ones(1,200)];

% imem    = [10*ones(1,100) 0*ones(1,200) 7*ones(1,300) 6*ones(1,200) 0*ones(1,200)];

% reset membrane voltage upon spike
vrst    = -70;
% threshold membrane voltage that generates spikes
vth     = 5;

% membrane (leakage) time constant
tleak = 8;

% membrane leak potential (steady state)
Eleak = -0;
Esra = 0;

% spike rate adaptation dynamic parameters

%incremental conductance addition (upon spike) :increase value to arrive at
%equilibrium condition with quicker
g0 = 0.0; 
%initial conductance state
gsra = 0;
%SRA time constant, increase value to lengthen decay time
tsra = 128;

gsra_states(1) = gsra;
vmem_states(1) = vmem;

tend = 1000;

t0 = 1;

% HPF params
iresp = 0;
% HPF time constant
thpf = 10;


%% ODE Numerical Solutions

for t=2:tend
    
    diresp = (imem(t)-imem(t-1)) - iresp/thpf;
    
    % Uncomment to use injection current as input
%     imem_cur = abs(imem(t));

    % Uncomment to use HPF response as input
    
    imem_cur = abs(iresp); % fullwave rectification of HPF response
    
    dgsra = -gsra/tsra;
    
    % Uncomment to use LIF model 
%     dvmem = Eleak/tleak - vmem/tleak + imem_cur;

    % Uncomment to use SRA model 
    dvmem = Eleak/tleak - vmem/tleak + imem_cur + gsra*(Esra-vmem);

    % Euler method DE update
    vmem = vmem + dvmem;
    gsra = gsra + dgsra;
    iresp = iresp + diresp;

    
    % Store system states
    gsra_states(t) = gsra;
    vmem_states(t) = vmem;
    iresp_states(t) = iresp;

    
    % Non-linear reset update
    if vmem>vth
        gsra = gsra + g0;
        vmem = vrst;
        fprintf("Spike frequency %0.2f Hz\n",(1/(t-t0))*1000);
        t0 = t;
    end

end


%% Plotting 

% figure();
% subplot(4,1,1)
% plot(1:tend, vmem_states);
% title('Vmem');
% subplot(4,1,2)
% plot(1:tend, gsra_states);
% title('Gsra');
% subplot(4,1,3)
% plot(1:tend, abs(iresp_states));
% title('Iresp');
% subplot(4,1,4)
% plot(1:tend, imem);
% title('Imem');


figure();
subplot(3,1,1)
plot(1:tend, imem);
title('Imem');
subplot(3,1,2)
plot(1:tend, abs(iresp_states));
title('Iresp');
subplot(3,1,3)
plot(1:tend, vmem_states);
title('Vmem');


