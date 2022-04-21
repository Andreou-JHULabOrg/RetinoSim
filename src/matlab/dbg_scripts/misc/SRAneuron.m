%% Script to resolve behavior of SRA neuron

%% Script parameters

clear;clc;

vmem    = 10;
% imem    = [2*ones(1,100) 5*ones(1,100) 7*ones(1,100) 10*ones(1,100)];
% discrete time membrane input current
% imem    = [10*ones(1,100) 0*ones(1,200) 7*ones(1,300) 6*ones(1,200) 0*ones(1,200)];
imem    = [1*ones(1,100) 4*ones(1,200) 5*ones(1,300) 8*ones(1,200) 10*ones(1,200)];


% reset membrane voltage upon spike
vrst    = -70;
% threshold membrane voltage that generates spikes
vth     = 10;

% membrane (leakage) time constant
tleak = 10;

% membrane leak potential (steady state)
Eleak = -22;
Esra = 0;

% spike rate adaptation dynamic parameters

%incremental conductance addition (upon spike) :increase value to arrive at
%equilibrium condition with quicker
g0 = 0.2; 
%initial conductance state
gsra = 0;
%SRA time constant, increase value to lengthen decay time
tsra = 600;

gsra_states(1) = gsra;
vmem_states(1) = vmem;

tend = 1000;

t0 = 1;


%% ODE Numerical Solutions


for t=2:tend
    imem_cur = imem(t);
    
    dgsra = -gsra/tsra;
    
    % Uncomment to use LIF model 
%     dvmem = Eleak/tleak - vmem/tleak + imem_cur;

    % Uncomment to use SRA model 
    dvmem = Eleak/tleak - vmem/tleak + imem_cur + gsra*(Esra-vmem);

    % Euler method DE update
    vmem = vmem + dvmem;
    gsra = gsra + dgsra;
    
    % Store system states
    gsra_states(t) = gsra;
    vmem_states(t) = vmem;
    
    % Non-linear reset update
    if vmem>vth
        gsra = gsra + g0;
        vmem = vrst;
        fprintf("Spike frequency %0.2f Hz\n",(1/(t-t0))*1000);
        t0 = t;
    end

end

%% Plotting 


figure();
subplot(3,1,1)
plot(1:tend, imem);
title('Imem');
subplot(3,1,2)
plot(1:tend, gsra_states);
title('Gsra');
subplot(3,1,3)
plot(1:tend, vmem_states);
title('Vmem');


