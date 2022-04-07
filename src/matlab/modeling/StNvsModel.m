function [TD, eventFrames, dbgFrames, OMSNeuron] = StNvsModel(input_video, params)
%STNVSMODEL An isolated signal processing pipeline to model spatiotemporal pixel array
%AUTHOR : Jonah P. Sengupta
%DATE : 11-8-21
%INPUTS :
% 'input_video'
%       NxMx3xF RGB (NxMx3xF Grayscale) video
% 'params'
%       structure containing parameters needed for


fprintf("\n---------------------------------------------------------------\n\n");
fprintf("[SpatioTemporalVS-INFO] Generating spikes from StNvs model...\n");
fprintf("\n---------------------------------------------------------------\n");

tic;
fprintf("[STVS-INFO] Using parameters:\n");

param_names = fields(params);
for p = 1:length(param_names)
	if size(params.(param_names{p})) == 1
		try
			fprintf("[STVS-INFO] %s: %d\n", param_names{p}, params.(param_names{p}));
		catch
			fprintf("[STVS-INFO] %s: %s\n", param_names{p}, params.(param_names{p}));
		end
	end
end

addpath(genpath('../aux'));

%%% ------------------------------------------------ Convert to grayscale

if length(size(input_video)) == 4
	grayFrames = 0.299*input_video(:,:,1,:) + 0.587*input_video(:,:,2,:) ...
		+0.114*input_video(:,:,3,:) + 1;
else
	grayFrames = double(input_video + 1);
end

nFrames = size(grayFrames,3);

eventFrames = zeros(size(grayFrames,1), size(grayFrames,2), 3, nFrames);


%%% -------------------------------------------- Calculate Shot Noise RMS
maxLog = max(max(grayFrames(:,:,1)));

timescale           = 10e-6; % S
q                   = 1.62e-19; % C
average_current     = 1e-9; % A
num_devices         = 10;
pix_shot_rate        = (sqrt(2*num_devices*average_current*q*(1/timescale))/average_current) .* (maxLog-grayFrames(:,:,1));
pixel_fe_noise_past = normrnd(0,double(pix_shot_rate),size(grayFrames(:,:,1)));


%%% ----------------------------------------------- Set leakage currents

leak_rate = max(normrnd(params.leak_ba_rate, sqrt(params.leak_ba_rate/2), size(grayFrames(:,:,1))),0);

%%% ----------------------------------------------- Create threshold
%%% distributions

for threshold_idx = 1:3
	threshold_variance = (params.percent_threshold_variance/100)*params.threshold(:,:,threshold_idx);
	threshold_arrays(:,:,threshold_idx) = params.threshold(:,:,threshold_idx) + normrnd(0,threshold_variance, size(grayFrames(:,:,1)));
end

threshold_array.bc  = threshold_arrays(:,:,1);
threshold_array.on  = threshold_arrays(:,:,2);
threshold_array.off = threshold_arrays(:,:,3);

onNeuron.state                        = params.gc_reset_value*ones(size(grayFrames(:,:,1)));
onNeuron.sam            = zeros(size(grayFrames(:,:,1)));

offNeuron.state                       = params.gc_reset_value*ones(size(grayFrames(:,:,1)));
offNeuron.sam           = zeros(size(grayFrames(:,:,1)));

spikeGenParams.gc_reset_value       = params.gc_reset_value;
spikeGenParams.time_step            = params.time_step;
spikeGenParams.refractory_period    = params.gc_refractory_period;

OMSNeuron.params.gc_reset_value     = params.oms_reset_value;
OMSNeuron.params.time_step          = params.time_step;
OMSNeuron.params.refractory_period  = params.oms_refractory_period;

OMSNeuron.params.gc_threshold = threshold_array.on;
OMSNeuron.params.polarity = 1;

OMSNeuron.state                       = params.oms_reset_value*ones(size(grayFrames(:,:,1)));
OMSNeuron.sam           = zeros(size(grayFrames(:,:,1)));

OMSNeuron.events = struct();

% two low-pass fiter
WAC.inhib.RF = fspecial('gaussian', 31, 10);
WAC.excite.RF = fspecial('gaussian',9, 2);

eventIdx = 1;

OMSNeuron.Idx = 1;

frames.current_time  = 0;

%%% ----------------------------------------------- %%%
%
%               MAIN PROCESSING LOOP
%
%%% ----------------------------------------------- %%%

TD = struct();



for fidx = 2:size(grayFrames,3)
	
	fprintf("[SpatioTemporalVS-INFO] processing frame: %d\n", fidx);
	
	onNeuron.numSpikes      = zeros(size(grayFrames(:,:,1)));
	onNeuron.spikeLocs      = [];
	offNeuron.numSpikes     = zeros(size(grayFrames(:,:,1)));
	offNeuron.spikeLocs      = [];
	
	
	frames.current_time = frames.current_time + params.time_step;
	
	maxIph = max(grayFrames, [], 'all');
	
	%%% ----------------------------------------------- Additive shot noise to photocurrent
	
	if params.enable_shot_noise
		pix_shot_rate       = (sqrt(2*num_devices*average_current*q*(1/timescale))/average_current) .* (maxIph-grayFrames(:,:,fidx));
		pixel_fe_noise      = normrnd(0,double(pix_shot_rate),size(grayFrames(:,:,1)));
		
		frame.cur   = grayFrames(:,:,fidx) + pixel_fe_noise;
		frame.past  = grayFrames(:,:,fidx-1) +  pixel_fe_noise_past;
	else
		frame.cur   = grayFrames(:,:,fidx);
		frame.past  = grayFrames(:,:,fidx-1);
	end
	
	frame.photo = frame.cur;
	frame.idx   = fidx;
	
	
	%%% ----------------------------------------------- OPL: Spatial FE
	%%% configuration
	
	if strcmp(params.spatial_fe_mode,"bandpass")
		frame.opl_sr = NormalizeContrast(frame.cur);
	elseif strcmp(params.spatial_fe_mode,"log-lowpass")
		horiz = fspecial('gaussian', 15, 2.5);
		sr = imfilter(frame.cur, horiz, 'replicate');
		frame.opl_sr = log(sr);
	elseif strcmp(params.spatial_fe_mode,"low-pass")
		horiz = fspecial('gaussian', 15, 2.5);
		sr = imfilter(frame.cur, horiz, 'replicate');
		frame.opl_sr = sr;
	elseif strcmp(params.spatial_fe_mode,"log")
		frame.opl_sr = log(frame.cur);
	end
	
	%%% ----------------------------------------------- OPL: 1st order Temporal lowpass
	
	if (fidx == 2)
		if strcmp(params.spatial_fe_mode,"bandpass")
			frame.opl_str_ = NormalizeContrast(frame.past);
		elseif strcmp(params.spatial_fe_mode,"log-lowpass")
			horiz = fspecial('gaussian', 15, 2.5);
			sr = imfilter(frame.past, horiz, 'replicate');
			frame.opl_str_ = log(sr);
		elseif strcmp(params.spatial_fe_mode,"low-pass")
			horiz = fspecial('gaussian', 15, 2.5);
			sr = imfilter(frame.past, horiz, 'replicate');
			frame.opl_str_ = sr;
		elseif strcmp(params.spatial_fe_mode,"log")
			frame.opl_str_ = log(frame.past);
		end
	else
		frame.opl_str_   = frame.opl_str;
	end
	
	frame.opl_str = (params.opl_time_constant)*frame.opl_str_ + (1-params.opl_time_constant)*frame.opl_sr;
	
	%%% ----------------------------------------------- Channel rectification
	%%% ----------------------------------------------- 1st order High pass
	%%% temporal filtering and integration
	
	%Difference in OPL
	diffOPL = frame.opl_str-frame.opl_str_;
	
	%Rectify signals
	onIdx = (diffOPL) > (params.bc_offset);
	offIdx = (diffOPL) < (params.bc_offset);
	
	% Dead zone leakage integration
	deadZIdx = ~(onIdx |offIdx);
	
	onNeuron.state(deadZIdx) = onNeuron.state(deadZIdx) + params.bc_leak;
	offNeuron.state(deadZIdx) = offNeuron.state(deadZIdx) + params.bc_leak;
	
	%Create high pass response
	
	onNeuron.state_   = onNeuron.state;
	offNeuron.state_  = offNeuron.state;
	
	%     high_pass_response.on = ((params.hpf_gc_tc)*onNeuron.state_(onIdx) + (params.hpf_gc_tc)*(diffOPL(onIdx)));
	%     high_pass_response.off = ((params.hpf_gc_tc)*offNeuron.state_(offIdx) + (params.hpf_gc_tc)*(diffOPL(offIdx)));
	% JS - remove
	high_pass_response.on = zeros(size(grayFrames(:,:,1)));
	high_pass_response.on(onIdx) = (params.hpf_gc_tc)*(abs(diffOPL(onIdx)));
	high_pass_response.off = zeros(size(grayFrames(:,:,1)));
	high_pass_response.off(offIdx) = (params.hpf_gc_tc)*(abs(diffOPL(offIdx)));
	
	%Integrate on Neurons
	
% 	onNeuron.state(onIdx) = onNeuron.state(onIdx) + diffOPL(onIdx);
% 	offNeuron.state(offIdx) = offNeuron.state(offIdx) + diffOPL(offIdx);
	
	onNeuron.state(onIdx) = onNeuron.state(onIdx) + abs(high_pass_response.on(onIdx));
	offNeuron.state(offIdx) = offNeuron.state(offIdx) + abs(high_pass_response.off(offIdx));
	
	%%% ----------------------------------------------- Apply leak to two l-IAF neurons
	
	onNeuron.state      = onNeuron.state    -     leak_rate;
	onNeuron.state      = max(onNeuron.state, 0);
	offNeuron.state     = offNeuron.state   -     leak_rate;
	offNeuron.state      = max(offNeuron.state, 0);
	
	frame.on_neuron     = onNeuron.state;
	frame.off_neuron    = offNeuron.state;
	
	%%% ----------------------------------------------- Spike generation
	
	%%%% OFF neuron spike generation
	spikeGenParams.gc_threshold = threshold_array.off;
	spikeGenParams.polarity = 0;
	
	[TD, offNeuron, eventIdx] = spikeGeneration(offNeuron,spikeGenParams, eventIdx, TD, frames.current_time);
	eventFrames(:,:,2,fidx) = offNeuron.numSpikes;
	
	%%%% ON neuron spike generation
	spikeGenParams.gc_threshold = threshold_array.on;
	spikeGenParams.polarity = 1;
	[TD, onNeuron, eventIdx] = spikeGeneration(onNeuron,spikeGenParams, eventIdx, TD, frames.current_time);
	eventFrames(:,:,1,fidx) = onNeuron.numSpikes;
	
	%%% ----------------------------------------------- Parallelized OMS Ganglion Cell
	%%%% high-pass filter of large surround spatially filtered (averaged)
	%%%% inhibits excitation
	%%%% Subsample image space
	
	if (fidx == 2)
		WAC.hpr_ = onNeuron.state;
	else
		WAC.hpr_ =  WAC.hpr;
	end
	
	diffOn = onNeuron.state-onNeuron.state_;
	
	WAC.hpr = ((params.hpf_wac_tc)*WAC.hpr_ + (params.hpf_wac_tc)*(diffOn));
	
	WAC.inhib.response   = imfilter(WAC.hpr, WAC.inhib.RF, 'replicate');
	WAC.excite.response  = imfilter(WAC.hpr, WAC.excite.RF, 'replicate');
	
	OMSNeuron.state = WAC.excite.response-WAC.inhib.response;
	
	[OMSNeuron.events, OMSNeuron, OMSNeuron.Idx] = spikeGeneration(OMSNeuron,OMSNeuron.params, OMSNeuron.Idx, OMSNeuron.events, frames.current_time);
	
	
	% ---- Debug Plug-in
	
	dbgFrames(:,:,fidx) = frame.(params.dbg_mode);
	
end

[TD.ts, idx] = sort(TD.ts);
TD.ts = TD.ts' * 1e6;
TD.x = uint16(TD.x(idx)' - 1); % bring to 0 to sensor width
TD.y = uint16(TD.y(idx)' - 1); % bring to 0 to sensor height
TD.p = int8(TD.p(idx)');

% Sequential OMS computation based on spike timings

if params.enable_sequentialOMS
	OMS_params.rf_dim = 15;
	OMS_params.center_dim = 3;
	OMS_params.excite_syn = 2;
	OMS_params.gc_threshold = 10;
	filt_count = 1;
	
	SAM.on = zeros(size(grayFrames,1)+2*rf_dim, size(grayFrames,2)+2*rf_dim);
	SAM.off = zeros(size(grayFrames,1)+2*rf_dim, size(grayFrames,2)+2*rf_dim);
	
	for eidx = 1:length(TD.x)
		ae.x = TD.x(eidx);
		ae.y = TD.x(eidx);
		ae.p = TD.x(eidx);
		ae.ts = TD.x(eidx);
		
		if ae.p == 1
			SAM.on(ae.y, ae.x) = ae.ts;
		else
			SAM.off(ae.y, ae.x) = ae.ts;
		end
		
		[GC] = ObjectMotionSensitiveGC(TD,SAM,params);
		
		if GC.pass == 1
			events.x(filt_count) = GC.x;
			events.y(filt_count) = GC.y;
			events.p(filt_count) = GC.p;
			events.ts(filt_count) = GC.ts;
			filt_count=filt_count+1;
		end
		
	end
end


end
