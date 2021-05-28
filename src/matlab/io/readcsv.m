clear; clc;

file.path = ['/home/jonahs/projects/ReImagine/AER_Data' '/tennis_ball'];
file.name = '/tb_1.aedat';

frame_params.filepath = [file.path file.name];
frame_params.bin_time = 1e3; %us
frame_params.first_frame = 1;
frame_params.last_frame = 200;
frame_params.show_frames = 0;
frame_params.sensor_size = [128 128];
% 
% m = csvread('/home/jonahs/projects/ReImagine/AER_Data/csv/tb_1.csv',1,0);

% TD1.x = m(:,1);
% TD1.y = m(:,2);
% TD1.p = m(:,3);
% TD1.ts = m(:,4);
% 
% startEvent = 1;
% num_events = 40e3;
% TD1.x = TD1.x(startEvent:(startEvent+num_events-1));
% TD1.y= TD1.y(startEvent:(startEvent+num_events-1));
% TD1.p = TD1.p(startEvent:(startEvent+num_events-1));
% TD1.ts = TD1.ts(startEvent:(startEvent+num_events-1));

[TD2.x, TD2.y, TD2.p, TD2.ts] = loadAERfull(frame_params.filepath);

csv_mat = zeros(length(TD2.x)+1,4);
csv_mat(1,:) = [length(TD2.x) length(TD2.x) length(TD2.x) length(TD2.x)];
csv_mat(2:end,1) = TD2.x;
csv_mat(2:end,2) = TD2.y;
csv_mat(2:end,3) = TD2.p;
csv_mat(2:end,4) = TD2.ts;

csvwrite('/home/jonahs/projects/ReImagine/AER_Data/csv/tb_1.csv', csv_mat, 0, 0);

% TD2.x = TD2.x(startEvent:(startEvent+num_events-1));
% TD2.y= TD2.y(startEvent:(startEvent+num_events-1));
% TD2.p = TD2.p(startEvent:(startEvent+num_events-1));
% TD2.ts = TD2.ts(startEvent:(startEvent+num_events-1));


% out = makeFrames(TD1,frame_params.bin_time,frame_params.show_frames, frame_params.sensor_size);
