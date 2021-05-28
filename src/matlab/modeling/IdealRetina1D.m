function [ events, events_per_cycle, isi ] = IdealRetina1D(log_frames,fps, theta_on, theta_off, iterations)
%IdealRetina1D Find ideal spike count over time with given parameters and
%stimulii

I_t = log_frames(1);

times_on = [];
times_off = [];
nevents_on = [];
nevents_off = [];
cur_T = 0;

dt = 1/fps;
for f = 2:numel(log_frames)
    cur_T = cur_T + (1/fps);
    I_dt = log_frames(f);
    
%     fprintf("Frame: %d, Log difference: %3.4f\n",f, (I_dt-I_t));
    
    if I_dt > I_t
        nevents = floor((I_dt - I_t)/theta_on);
%         fprintf("Frame: %d, Number of ON events: %d\n",f, nevents);
        nevents_on = [nevents_on nevents];
        nevents_off = [nevents_off 0];
        p = 1;
    else
        nevents = floor(abs(I_dt - I_t)/theta_off);
%         fprintf("Frame: %d, Number of OFF events: %d\n",f, nevents);
        nevents_off = [nevents_off nevents];
        nevents_on = [nevents_on 0];
        p = -1;
    end
    
    if nevents > 1
        if p == 1
            times_on = [(cur_T:(dt/nevents):cur_T+dt) times_on];
        else
            times_off = [(cur_T:(dt/nevents):cur_T+dt) times_off];
        end
    elseif nevents == 1
        if p == 1
            times_on = [(cur_T + dt/2) times_on ];
        else
            times_off = [(cur_T + dt/2) times_off];
        end
    end
    I_t = I_dt;
end

events = [nevents_on; nevents_off];
events_per_cycle = [sum(nevents_on)/iterations; sum(nevents_off)/iterations];
isi = abs(1e6*[sum(diff(times_on))/iterations; sum(diff(times_off))/iterations]);

end

