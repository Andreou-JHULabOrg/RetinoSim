function [TD, eventFrames, rng_settings] = RetinaNvsModelBck(inVid, params)
%RETINANVSMODEL Model that converts video into events using Retina-inspired NVS model 
%AUTHOR : Jonah P. Sengupta
%DATE : 8-19-20
%INPUTS : 
% 'inVid' 
%       NxMx3xF RGB (NxMx3xF Grayscale) video
% 'params'
%       structure containing parameters needed for
%           on_threshold : scalar value ranging from 0 to ln(255) that determines triggering of on events
%           off_threshold : scalar value ranging from 0 to ln(255) that determines triggering of on events
%           percent_threshold_variance : 
%           enable_threshold_variance : 
%           enable_pixel_variance :
%           enable_diffusive_net :
%           frames_per_second : 
%           frame_show : show resultant frames
%           enable_temporal_low_pass : 
%           enable_leak_ba : 
%           enable_refractory_period :
%           refractory_period
%           inject_spike_jitter : 
%           inject_poiss_noise : 
%OUTPUTS : 
% 'TD'
%   Four member structure that includes x (x address), y (y address), p
% (polarity), ts (timestamp) of acquired events
%       TD.x : AE pixel x-address
%       TD.y : AE pixel y-address
%       TD.p : polarity, -1 for OFF events, 1 for ON events
%       TD.ts : timestamps in units of microseconds
% 'eventFrame'
%   NxMxF video containing the simulated events

%to-do
% 3. Amacrine : digital amacrine cells. 
% 4. split into functions to clean up code
% 5. live version

addpath(genpath('../aux'));

if length(size(inVid)) == 4
    grayFrames = 0.299*inVid(:,:,1,:) + 0.587*inVid(:,:,2,:)+0.114*inVid(:,:,3,:) + 1;
else
    grayFrames = inVid + 1;
end

logFrames = log(grayFrames);

nFrames = size(logFrames,3);

eventCt = 1;
cur.T = 0;

eventFrames = zeros(size(logFrames,1), size(logFrames,2), 3, nFrames);

%%%%% -------------------------------- Create fixed pattern threshold noise

threshold_variance_on = (params.percent_threshold_variance/100)*params.on_threshold;
threshold_variance_off = (params.percent_threshold_variance/100)*params.off_threshold;

if params.resample_threshold
    rng_settings = rng;
    on_threshold = params.on_threshold + normrnd(0,threshold_variance_on, size(logFrames(:,:,1)));
    off_threshold = params.off_threshold + normrnd(0,threshold_variance_off, size(logFrames(:,:,1)));
else
    rng_settings = rng(params.rng_settings); % use given settings to reproduce same mismatch distribution as prior iteration
    on_threshold = params.on_threshold + normrnd(0,threshold_variance_on, size(logFrames(:,:,1)));
    off_threshold = params.off_threshold + normrnd(0,threshold_variance_off, size(logFrames(:,:,1)));
end

%%%%% -------------------------------------------- Calculate Shot Noise RMS 
maxLog = max(max(logFrames(:,:,1)));

timescale           = 10e-6; % S
q                   = 1.62e-19; % C
average_current     = 1e-9; % A
num_devices         = 10;
pix_shot_rate        = (sqrt(2*num_devices*average_current*q*(1/timescale))/average_current) .* (maxLog-logFrames(:,:,1));
pixel_fe_noise_past = normrnd(0,pix_shot_rate,size(logFrames(:,:,1)));

sae = zeros(size(logFrames(:,:,1)));
lp_log_in = zeros(size(logFrames(:,:,1)));

I_mem = log(128)*ones(size(logFrames(:,:,1)));

% leak_rate = normrnd(params.leak_ba_rate, sqrt(params.leak_ba_rate/2), size(logFrames(:,:,1)));
leak_rate = params.leak_ba_rate;

fprintf("Generating spikes from RetinaNvs model...\n");

horiz_spatial_response = fspecial('gaussian', 15, 2.5);
pr_spatial_response = fspecial('gaussian',15, 2);

total_spatial_response = 1.1*(pr_spatial_response + horiz_spatial_response);


for f = 2:nFrames
%     fprintf("Processing Frame : %d \n", f);
    maxLog = max(max(logFrames(:,:,f)));
    if params.enable_pixel_variance
        pix_shot_rate        = (sqrt(2*num_devices*average_current*q*(1/timescale))/average_current) .* (maxLog-logFrames(:,:,f));
        pixel_fe_noise = normrnd(0,pix_shot_rate,size(logFrames(:,:,1)));
        pastFrame = logFrames(:,:,f-1) + pixel_fe_noise_past;
        cur.Frame = logFrames(:,:,f) + pixel_fe_noise;
        pixel_fe_noise_past = pixel_fe_noise;
    else 
        pastFrame = logFrames(:,:,f-1);
        cur.Frame = logFrames(:,:,f);
    end
    
    % ---------------------------------------------------- horizontal cells 
    % ------------------ Diffusive net implements a spatial low pass filter 
    if params.enable_diffusive_net
        pastFrame = imgaussfilt(pastFrame, sqrt(exp(1)));
        cur.Frame = imgaussfilt(cur.Frame, sqrt(exp(1)));
    end

    I_mem_p = I_mem;
    
    if params.enable_leak_ba
        I_mem = I_mem - (1/params.frames_per_second)*(leak_rate);
    end
    % -------- Implements temporal low pass based on photoreceptor response 
    if params.enable_temporal_low_pass
        temporal_lp_response = max(cur.Frame/max(max(cur.Frame)),.05);
        cur.Frame = cur.Frame.*temporal_lp_response + (1-temporal_lp_response).*pastFrame;
        pastFrame = pastFrame.*temporal_lp_response + (1-temporal_lp_response).*lp_log_in;
        lp_log_in = pastFrame;
    end
   
    % ------------------------------------- bipolar cells/ change amplifier
    dI = cur.Frame - pastFrame;
    I_mem = I_mem + dI;
    
    cur.T = cur.T + (1/params.frames_per_second);
    
    % ---------------------------------------- optional plotting and output
    if params.write_frame
        if f == params.write_frame
            outputdir = '../../../../data/output/spike_model/';
            fprintf("Wrote images to input, pr, and bp images.\n");
            imwrite(grayFrames(:,:,f)/max(max(grayFrames(:,:,f))),[outputdir 'in_' params.write_frame_tag '_.jpg'], 'JPEG');
            imwrite(cur.Frame/max(max(cur.Frame)),[outputdir 'pr_' params.write_frame_tag '_.jpg'], 'JPEG');
            imwrite(I_mem/max(max(I_mem)),[outputdir 'bc_' params.write_frame_tag '_.jpg'],'JPEG');
%             plot_vars = {'on_threshold', 'off_threshold', 'leak_rate' ,'pixel_fe_noise'};
%             for fig =  1:numel(plot_vars)
%                 figure();
%                 imagesc(eval(plot_vars{fig}));
%                 title(plot_vars{fig});
%             end
            figure();
            histogram(on_threshold(:)); 
            hold on; histogram(off_threshold(:)); hold off; 
            threshold_var = [params.on_threshold(1,1)+threshold_variance_on(1,1) params.on_threshold(1,1)-threshold_variance_on(1,1)];
            line([threshold_var(1) threshold_var(1)], get(gca, 'ylim'), 'LineWidth', 2, 'Color', [0 0 1]); 
            line([threshold_var(2) threshold_var(2)], get(gca, 'ylim'), 'LineWidth', 2, 'Color', [1 0 0]);
            xlabel('$\theta$','Interpreter','latex'); legend({'ON','OFF', '$\theta_\mu + \sigma$', '$\theta_\mu - \sigma$'},'Interpreter','latex');
            
            figure();
            pixel_shot_r_db = 10*log10(abs(pix_shot_rate)/mean(abs(pix_shot_rate(:))));
            imagesc(pixel_shot_r_db); colormap(gray); colorbar
        end
    end
    
    % ----------------------------------- UPDATE Events with ganglion model
    
    for ii = 1:size(cur.Frame,1)
        for jj = 1:size(cur.Frame,2)  
            
            if params.enable_threshold_variance
                theta_on =  on_threshold(ii,jj);
                theta_off = off_threshold(ii,jj);
            else
                theta_on =  params.on_threshold(ii,jj);
                theta_off = params.off_threshold(ii,jj);
            end
                     
            % ganglion cells 
            if I_mem(ii,jj) > I_mem_p(ii,jj)
                p = 1;
                nevents = floor(abs(I_mem(ii,jj) -I_mem_p(ii,jj))/theta_on);
            else
                p = -1;
                nevents = floor(abs(I_mem(ii,jj) -I_mem_p(ii,jj))/theta_off);
            end
            
            if nevents > 1
                ts = cur.T:((1/params.frames_per_second)/nevents):cur.T+(1/params.frames_per_second);
                I_mem(ii,jj) = log(128);
            elseif nevents == 1
                ts = cur.T + (1/params.frames_per_second)/2;
            end
            
            if params.inject_spike_jitter && nevents > 0 
                ts = ts + normrnd(0,(1/params.frames_per_second)*(1/100), size(ts));
            end
                        
            if nevents >  0 
%                 fprintf("potential: %0.4f, %d events at %d, %d\n", I_mem(ii,jj), nevents, ii,jj);
                for ee = 1:nevents
                    if params.enable_refractory_period
                        if ts(ee) - sae(ii,jj) > params.refractory_period
                            TD.x(eventCt) = jj;
                            TD.y(eventCt) = ii;
                            TD.p(eventCt) = p;
                            TD.ts(eventCt) = ts(ee);
                            
                            eventCt = eventCt + 1;
                            
                            sae(ii,jj) = ts(ee);
                        end
                    else
                        TD.x(eventCt) = jj;
                        TD.y(eventCt) = ii;
                        TD.p(eventCt) = p;
                        
                        TD.ts(eventCt) = ts(ee);
                        
                        eventCt = eventCt + 1;
                    end
                end
                
                if p == 1
                    eventFrames(ii,jj,3,f) = eventFrames(ii,jj,3,f) + nevents;
                else
                    eventFrames(ii,jj,2,f) = eventFrames(ii,jj,2,f) + nevents;
                end
            end
        end
    end
    if params.write_frame
        if f == params.write_frame
            fprintf("Wrote gc image to file.\n");
            outputdir = '../../../../data/output/spike_model/';
            imwrite(eventFrames(:,:,:,f),[outputdir 'gc_' params.write_frame_tag '_.jpg'],'JPEG');
        end
    end
end

if (params.frame_show == 1)
    fig = figure();
    
    fig.Units = 'normalize';
    fig.Position=[0.1 0.25 0.8 0.75];
    
    ax(1)=axes;
    ax(2)=axes;
    
    x0=0.15;
    y0=0.3;
    dx=0.25;
    dy=0.45;
    ax(1).Position=[x0 y0 dx dy];
    x0 = x0 + dx + 0.2;
    ax(2).Position=[x0 y0 dx dy];
    
    im(1) = imagesc(ax(1),logFrames(:,:,1));
    ax(1).Title.String = ['Log Intensity: Frame ' num2str(1)];
    set(ax(1), 'xtick', [], 'ytick', []);
    colormap(gray);
    
    im(2) = imagesc(ax(2),eventFrames(:,:,:,1));
    ax(2).Title.String = ['Accumulated Events: Frame ' num2str(1)];
    set(ax(2), 'xtick', [], 'ytick', []);
    
    
    for ii = 2:nFrames
%         fprintf("Frame : %d\n", ii);
        ax(1).Title.String = ['Log Intensity: Frame ' num2str(ii)];
        ax(2).Title.String = ['Accumulated Events: Frame ' num2str(ii)];
        set(im(1),'cdata',logFrames(:,:,ii));
        set(im(2),'cdata',eventFrames(:,:,:,ii));
        drawnow;
        pause(1/params.frames_per_second);
    end
    
end

[TD.ts, idx] = sort(TD.ts);
TD.ts = TD.ts';
TD.ts = uint32((TD.ts - TD.ts(1))*1e6); % zero and bring to microsecond resolution
TD.x = uint16(TD.x(idx)' - 1); % bring to 0 to sensor width
TD.y = uint16(TD.y(idx)' - 1); % bring to 0 to sensor height
TD.p = int8(TD.p(idx)');

if params.inject_poiss_noise
    dist.name = 'Gaussian'; dist.params = [1000 250]; % in units of microseconds
    TDnoise = GenNoiseEvents(1, dist, 20e3, [max(TD.y), max(TD.x)], [min(TD.ts) max(TD.ts)]);
    TD = CombineStreams(TD, TDnoise, 'isnoise', 0, 1);
end


end

