clear;clc;

vmem    = 10;
imem    = [2*ones(1,100) 5*ones(1,100) 7*ones(1,100) 10*ones(1,100)];
vrst    = -70;
vth     = 15;

tleak = 10;
Esra = 0;

g0 = 0.05;
gsra = 0;
tsra = 2;

gsra_states(1) = gsra;
vmem_states(1) = vmem;

tend = 400;

t0 = 1;

for t=2:tend
    imem_cur = imem(t);
    
    dgsra = -gsra/tsra;
    
    dvmem = imem_cur- vmem/tleak + gsra*(Esra-vmem);
    
    vmem = vmem + dvmem;
    gsra = gsra + dgsra;
    
    gsra_states(t) = gsra;
    vmem_states(t) = vmem;

    if vmem>vth
        gsra = gsra + g0;
        vmem = vrst;
        fprintf("Spike frequency %0.2f Hz\n",(1/(t-t0))*1000);
        t0 = t;
    end

end

figure();
subplot(2,1,1)
plot(1:tend, vmem_states);
subplot(2,1,2)
plot(1:tend, gsra_states);