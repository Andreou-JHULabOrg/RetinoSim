sensor_size = [128 128];
intensity_params.starting_level  = 10;
intensity_params.end_level = 255;
intensity_params.number_levels = 10;
intensity_params.iterations = 3;
intensity_params.pattern = 'triangle';
shape_params.type = 'uniform';
show_frame = 1;

[frames] = GenerateCharacterization(sensor_size, intensity_params, shape_params, show_frame);
