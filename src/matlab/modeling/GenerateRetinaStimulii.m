function [frames, intensity_levels, log_out] = GenerateRetinaStimulii(sensor_size, intensity_params, shape_params, show_frame, show_plot)
% GenerateRetinaStimulii Creates video used to characterize spiking NVS
% model
% INPUTS:
%  'sensor_size'
%       two dimensional vector
%  'intensity_params'
%       structure that contains variables used to construct frame
%       intensities
%           starting_level : 0-255 level that intensity waveform begins
%           end_level : 0-255 level that intensity waveform ends
%           number_levels : 
%           iterations : determines number of frames in conjuction with
%           number_levels
%           pattern : 'triangle', 'sawtooth'
%  'shape_params'
%       structure that contains variables used to construct frame pattern
%           type : 'uniform', 'circles', 'squares'
%           pattern : 'grid', 'center'
%           size : 'size'
% 'show_frame'
%       show resultant frames

if intensity_params.end_level > intensity_params.starting_level
    intensity_levels = intensity_params.starting_level:((intensity_params.end_level-intensity_params.starting_level)/intensity_params.number_levels):intensity_params.end_level;
elseif intensity_params.end_level < intensity_params.starting_level
    intensity_levels = intensity_params.starting_level:((intensity_params.end_level-intensity_params.starting_level)/intensity_params.number_levels):intensity_params.end_level;
%     intensity_levels = fliplr(intensity_levels);
end

if strcmp(intensity_params.pattern, 'triangle')
    intensity_levels = [intensity_levels fliplr(intensity_levels)];
end

frames_one_it = zeros(sensor_size(1), sensor_size(2), length(intensity_levels));

if strcmp(shape_params.type, 'uniform')
    for f = 1:length(intensity_levels)
        frames_one_it(:,:,f) = intensity_levels(f)*ones(sensor_size(1),sensor_size(2));
    end
end

frames = frames_one_it;
for it = 1:intensity_params.iterations-1
    frames = cat(3, frames, frames_one_it); 
end

if show_frame
    figure(1);
    for f = 1:size(frames, 3)
        image(frames(:,:,f));
        colormap(gray);
        title(['Frame: ' num2str(f)]);
        pause(1/10);
    end
end

for f = 1:size(frames, 3)
    mean_frame(f) = mean(mean(frames(:,:,f)));
end


if show_plot
    figure();
    subplot(2,1,1);
    plot(1:size(frames,3), mean_frame, 'r-o');
    xlabel('Frames','Interpreter','latex');
    xlim([1 size(frames, 3)+1]);
    ylabel('Mean Value','Interpreter','latex');
    subplot(2,1,2);
    plot(1:size(frames,3), log(mean_frame), 'b-x');
    xlabel('Frames','Interpreter','latex');
    xlim([1 size(frames, 3)+1]);
    ylabel('Log Mean Value','Interpreter','latex');
end

log_out = log(mean_frame);

end