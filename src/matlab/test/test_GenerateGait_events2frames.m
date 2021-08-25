clear;clc;

addpath(genpath('../modeling'));
addpath(genpath('../aux'));
addpath(genpath('../io'));


%%

videoFileRoot = '/Users/jonahs/Documents/research/projects/RetinaNVSmodel/data/gait/ss_inputs/';
videoFilePrefix = 'ss_1_';
videoFileSuffix = {
                    'fwd_bwd_walk_E_W', ...
                    'fwd_bwd_walk_N_S', ...
                    'fwd_bwd_walk_NE_SW', ...
                    'fwd_bwd_walk_NW_SE', ...
                    'in_place_walk'...
                   };