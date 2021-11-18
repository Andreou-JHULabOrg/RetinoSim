function [GC] = ObjectMotionSensitiveGC(TD,SAM,params)
%OBJECTMOTIONSENSITIVEGC Detects local temporal changes and suppresses
%activity of output unless local exceeds global
% Inputs
% TD: four member address-event structure
%   TD.x: x-address 
%   TD.y: y-address
%   TD.p:   polarity
%   TD.ts:  timestamp
% SAM: Spike activation memory containing most recent spike timings
%   SAM.on: spike timings for on cells
%   SAM.off: spike timings for off cells
% params:
%   rf_dim: OMS receptive field dimension including center and surround
%   center_dim: center excitation dimensions
%   excite_syn: parameter to dictate synaptic strength 
%   gc_threshold: membrane potential that dictates when to pass spike
% Outputs
%   GC: five member address-event structure that also includes pass param
%   SAM_: output SAM to update global structure

ae.x = TD.x+params.rf_dim + 1;
ae.y = TD.y+params.rf_dim + 1;
ae.ts = TD.ts;

%grab receptive field
if TD.p == 1
    rf=SAM.on(ae.y + (-params.rf_dim:params.rf_dim), ae.x+  (-params.rf_dim:params.rf_dim));
else
    rf=SAM.on(ae.y + (-params.rf_dim:params.rf_dim), ae.x+  (-params.rf_dim:params.rf_dim));
end

centerCoord = ceil(size(rf)/2);

% Inhibition response
surroundRf = rf; surroundRf(centerCoord(1)+ -params.center_dim:params.center_dim) = 0;
surroundDts = surroundRf; surroundDts = surroundDts(surroundDts>0) - ae.ts;
surroundResp = sum(surroundDts)/length(surroundDts);

% Excitation center
centerRf = rf(centerCoord(1)+ -params.center_dim:params.center_dim);
centerDts = centerRf - ae.ts; centerDts = reshape(centerDts, [],1);
centerResp = params.excite_syn* sum(centerDts,'all')/(length(centerDts));

% Firing filter
if(centerResp - surroundResp) > params.gc_threshold
    filt = 1;
else
    filt = 0;
end

%Output update
GC.x = ae.x - params.rf_dim - 1;
GC.y = ae.y - params.rf_dim - 1;
GC.ts = ae.ts;
GC.p = ae.p;

GC.pass = filt;


end

