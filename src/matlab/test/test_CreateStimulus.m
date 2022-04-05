
%%% The testing function for 2D-grid stimulus generation
%%% Author: Susan Liu

% hsf: horizontal spatial frequency, range [2, 5]; 0 for no horizontal bars
% vsf: vertical spatial frequency, range [2, 5]; 0 for no vertical bars
% htf: horizontal temporal frequency, range [0, 10]
% vtf: vertical temporal frequency, range [0, 10]
% hamp: horizontal amplitude, range [0, 1]
% vamp: vertical amplitude, range [0, 1]
% write: whether write to a file
% vPath: the file to write to

hsf = 4;
vsf = 4;
htf = 5;
vtf = 5;
hamp = 1;
vamp = 1;
write = false;
vPath = '/Users/susanliu/Documents/AndreouResearch/videos/h451v451.mp4';

CreateStimulus(hsf, vsf, htf, vtf, hamp, vamp, write, vPath);