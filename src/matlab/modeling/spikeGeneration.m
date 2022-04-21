function [events_, neuronObj_, eventIdx_] = spikeGeneration(neuronObj,params, eventIdx, events, time_in)
%SPIKEGENERATION Summary of this function goes here
 neuronObj.spikeLocs = [];
[neuronObj.spikeLocs(:,1), neuronObj.spikeLocs(:,2)]   = find(floor(neuronObj.state./params.gc_threshold) > 0);
neuronObj.numSpikeLocs = length(neuronObj.spikeLocs(:,1));

%%%% Shuffle spikes locs for each
rand_Ix   = randperm(length(neuronObj.spikeLocs(:,1)));

neuronObj.spikeLocs  = neuronObj.spikeLocs(rand_Ix,:);
rix = 0; cix = 0;
for sidx = 1:neuronObj.numSpikeLocs
    addr = neuronObj.spikeLocs(sidx, :);
    rix = addr(1); cix  = addr(2);
    
    neuronObj.numSpikes(rix,cix) = floor(neuronObj.state(rix,cix)/params.gc_threshold(rix,cix));
    neuronObj.state(rix,cix) = params.gc_reset_value;
    
    if neuronObj.numSpikes(rix,cix) > 1
        ts = time_in:(params.time_step/neuronObj.numSpikes(rix,cix)):time_in+params.time_step;
    else
        ts = time_in + (params.time_step)/2;
    end
    
    ts = ts + normrnd(0,(params.time_step)*(1/100), size(ts));
    
    for ee = 1:neuronObj.numSpikes(rix,cix)
        if params.refractory_period > 0
            if ts(ee) - neuronObj.sam(rix,cix) > params.refractory_period
                events.x(eventIdx) = cix;
                events.y(eventIdx) = rix;
                events.p(eventIdx) = params.polarity;
                events.ts(eventIdx) = ts(ee);
                
                eventIdx = eventIdx + 1;
                
                neuronObj.sam(rix,cix) = ts(ee);
            end
        else
            events.x(eventIdx) = cix;
            events.y(eventIdx) = rix;
            events.p(eventIdx) = params.polarity;
            
            events.ts(eventIdx) = ts(ee);
            
            eventIdx = eventIdx + 1;
        end
    end    
end

% assign to outputs
neuronObj_ = neuronObj;
eventIdx_ = eventIdx;
events_ = events;

end

