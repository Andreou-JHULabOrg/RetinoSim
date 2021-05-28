function [isi, events_per_cycle] = CharacterizeRetina(TD, intensity_params, isplot)

% characterize spike timings: look at dts
% look at number of events per cycle

% 1. accumulate number spikes over recording
% 1a. accumulate isi 
% 2. average number of spikes over number of cycles
% 2a. average isi over number of total spikes
% 3. plot histograms

sae.on  = zeros(max(TD.y)+1,max(TD.x)+1);
sae.off = zeros(max(TD.y)+1,max(TD.x)+1);

isi.on  = zeros(max(TD.y)+1,max(TD.x)+1);
isi.off = zeros(max(TD.y)+1,max(TD.x)+1);

acc.on  = zeros(max(TD.y)+1,max(TD.x)+1);
acc.off = zeros(max(TD.y)+1,max(TD.x)+1);

fprintf("Gathering event statistics...\n");

for ee = 1:length(TD.x)
%     if mod(ee,100000) == 0
%         fprintf("Event: %d\n", ee);
%     end
    cur.x = TD.x(ee)+1; cur.y = TD.y(ee)+1; cur.p = TD.p(ee); cur.ts = TD.ts(ee);
    if cur.p == 1
        acc.on(cur.y, cur.x) = acc.on(cur.y, cur.x) + 1;
        if acc.on(cur.y, cur.x) > 1
            dt = cur.ts - sae.on(cur.y, cur.x);
            isi.on(cur.y, cur.x) = isi.on(cur.y, cur.x) + dt;
        end
        sae.on(cur.y, cur.x) = cur.ts;
    elseif cur.p == -1
        acc.off(cur.y, cur.x) = acc.off(cur.y, cur.x) + 1;
        if acc.off(cur.y, cur.x) > 1
            dt = cur.ts - sae.off(cur.y, cur.x);
            isi.off(cur.y, cur.x) = isi.off(cur.y, cur.x) + dt;
        end
        sae.off(cur.y, cur.x) = cur.ts;
    end
end

isi.on = isi.on ./ acc.on;
isi.off = isi.off ./ acc.off;

events_per_cycle.on = acc.on / intensity_params.iterations;
events_per_cycle.off = acc.off / intensity_params.iterations;

if isplot
    figure();
    histogram(events_per_cycle.on(:));
    % title('ON Events per Cycle', 'Interpreter', 'latex')
    % subplot(2,1,2);
    hold on;
    histogram(events_per_cycle.off(:));
    % title('OFF Events per Cycle', 'Interpreter', 'latex')
    hold off;
    legend({'ON Events','OFF Events'},  'Interpreter', 'latex');
    title('Events/Cycle',  'Interpreter', 'latex');
    
    figure();
    histogram(isi.on(:));
    % title('Average ISI for ON events', 'Interpreter', 'latex')
    % subplot(2,1,2);
    hold on;
    histogram(isi.off(:));
    legend({'ON Events','OFF Events'},  'Interpreter', 'latex');
    title('ISI',  'Interpreter', 'latex');
    hold off;
    % title('Average ISI for OFF events', 'Interpreter', 'latex')
end



end
