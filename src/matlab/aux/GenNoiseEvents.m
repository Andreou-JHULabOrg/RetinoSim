function [ TD ] = GenNoiseEvents(doplot, dist, numEvents, sensorSize, tsRange)
%GenNoiseEvents create noise events by sampling from given distribution
%   For the purpose of noise injection or noise filter characterization,
%   noise events need to be synthesized. They are sampled from a Gaussian,
%   Poisson that is parameterized by sensor size.
%   and temporal resolution. 
%AUTHOR : Jonah P. Sengupta
%DATE : 07-17-20
%INPUTS
% 'tsRange'
%   min and max of timestamps. If not provided, start time is offset from 0
%   and numEvents alone determines when last event is generated. Used when
%   injecting into target stream 
% 'sensorSize'
%   dimensions of image sensor. Spatial locations of events are sampled
%   uniformly parameterized by width and height of image sensor. 
%   Default - [128, 128]
% 'numEvents'
%   number of events desired to be generated
%   Default - [10k]
% 'dist'
%   distribution for time difference between noise events struct that hass three members
%       dist.name : 'Gaussian', 'Poisson'
%       dist.params : 'Gaussian' - two element vector that describes mean
%       and variance of dts, 'Poisson' - scalar that describes lambda or
%       average rate in terms of microseconds
%   Default - ['Poisson', '2e6']
% 'doplot'
%   show histograms of event stream
%OUTPUTS
% 'TD'
%   struct of arrays each of size numEvents, has elements
%       TD.x : AE pixel x-address
%       TD.y : AE pixel y-address
%       TD.p : polarity, -1 for OFF events, 1 for ON events
%       TD.ts : timestamps in units of microseconds
%Example:
%   %Generate 2000 events from gaussian with mean 500ms and variance of 1ms
%   with given timestamp range.
%   dist.name = 'Gaussian'
%   dist.params = [500e3 1e3];
%   timeRange = [15e6 200e6];
%   [TD] = GenNoiseEvents(0, dist, 2000, [240, 346], tsRange);


% argument check and default setting

if exist('tsRange', 'var')
    range_chk = true;
    tsOffst = tsRange(1);
    tsEnd = tsRange(2);
else
    range_chk = false;
end

if ~exist('sensorSize', 'var')
    uniform_param_y = 128;
    uniform_param_x = 128;
else
    if (length(sensorSize)~=2)
        error("sensorSize parameter needs to have two values.");
    else
        uniform_param_y = sensorSize(1);
        uniform_param_x = sensorSize(2);
    end
end

if ~exist('dist', 'var')
    dist.name = 'Poisson';
    dist.params = 2e6;
else
    if strcmp(dist.name,'Gaussian')
        if (length(dist.params) ~= 2)
            error("To generate spike timings using Gaussian distribution, need two parameters: mean and variance.");
        end
    elseif strcmp(dist.name,'Poisson')
        if (length(dist.params) ~= 1)
            error("To generate spike timings using Poisson distribution, need one parameter: mean rate.");
        end
    else
        error("Need to specify either Gaussian or Poisson for dist.name");
    end
end

if ~exist('sensorSize', 'var')
    numEvents = 10e3;
end

if strcmp(dist.name,'Gaussian')
    dts = normrnd(dist.params(1),dist.params(2),[numEvents,1]);
else 
    dts = poissrnd(dist.params(1),[numEvents,1]);
end

if range_chk
    ts = cumsum(dts) + double(tsOffst);
    ts(ts > double(tsEnd)) = [];
    numEvents = length(ts);
else
    ts = cumsum(dts);
end

TD.x = randi(uniform_param_x, [numEvents,1]);
TD.y = randi(uniform_param_y, [numEvents,1]);
TD.p = 2*(rand([numEvents,1]) > 0.5) - 1;
TD.ts = ts;

if ~exist('doplot', 'var')
    doplot = false;
end

if doplot
    figure();
    subplot(4,1,1);
    histogram(TD.x);
    title('Distribution of X-addresses');
    subplot(4,1,2);
    histogram(TD.y);
    title('Distribution of Y-addresses');
    subplot(4,1,3);
    histogram(diff(TD.ts));
    title('Distribution of Timestamps');
    subplot(4,1,4);
    histogram(TD.p);
    title('Distribution of Polarities');
end

end

