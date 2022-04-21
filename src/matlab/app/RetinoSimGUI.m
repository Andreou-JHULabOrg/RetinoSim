classdef RetinoSimGUI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        PlotOutputButton                matlab.ui.control.StateButton
        RunModelButton                  matlab.ui.control.StateButton
        IOInterfaceLabel                matlab.ui.control.Label
        NumberColumnsEditField          matlab.ui.control.NumericEditField
        NumberColumnsEditFieldLabel     matlab.ui.control.Label
        NumberRowsEditField             matlab.ui.control.NumericEditField
        NumberRowsEditFieldLabel        matlab.ui.control.Label
        NumberFramesEditField           matlab.ui.control.NumericEditField
        NumberFramesEditFieldLabel      matlab.ui.control.Label
        LoadVideoButton                 matlab.ui.control.Button
        SaveVideoButton                 matlab.ui.control.Button
        OutputVideoFileEditField        matlab.ui.control.EditField
        OutputVideoFileEditFieldLabel   matlab.ui.control.Label
        InputVideoFileEditField         matlab.ui.control.EditField
        InputVideoFileEditFieldLabel    matlab.ui.control.Label
        RetinoSimLabel                  matlab.ui.control.Label
        RefractoryPeriodEditField       matlab.ui.control.NumericEditField
        RefractoryPeriodEditFieldLabel  matlab.ui.control.Label
        DebugModeDropDown               matlab.ui.control.DropDown
        DebugModeDropDownLabel          matlab.ui.control.Label
        NeuronVarianceSlider            matlab.ui.control.Slider
        NeuronVarianceLabel             matlab.ui.control.Label
        LeakVarianceSlider            matlab.ui.control.Slider
        LeakVarianceLabel             matlab.ui.control.Label
        NeuronTimeConstantSlider        matlab.ui.control.Slider
        NeuronTimeConstantSliderLabel   matlab.ui.control.Label
        OPLTimeConstantSlider           matlab.ui.control.Slider
        OPLTimeConstantSliderLabel      matlab.ui.control.Label
        BackendParametersLabel          matlab.ui.control.Label
        SpatialVariance2EditField       matlab.ui.control.NumericEditField
        SpatialVariance2EditFieldLabel  matlab.ui.control.Label
        SpatialVariance1EditField       matlab.ui.control.NumericEditField
        SpatialVariance1EditFieldLabel  matlab.ui.control.Label
        OFFThresholdEditField           matlab.ui.control.NumericEditField
        OFFThresholdEditFieldLabel      matlab.ui.control.Label
        ONThresholdEditField            matlab.ui.control.NumericEditField
        ONThresholdEditFieldLabel       matlab.ui.control.Label
        BALeakageEditField              matlab.ui.control.NumericEditField
        BALeakageEditFieldLabel         matlab.ui.control.Label
        NeuronLeakageEditField          matlab.ui.control.NumericEditField
        NeuronLeakageEditFieldLabel     matlab.ui.control.Label
        SpatialFEModeListBox            matlab.ui.control.ListBox
        SpatialFEModeListBoxLabel       matlab.ui.control.Label
        FrontendParametersLabel         matlab.ui.control.Label
        EnableShotNoiseCheckBox         matlab.ui.control.CheckBox
        UIAxes2_3                       matlab.ui.control.UIAxes
        UIAxes2_2                       matlab.ui.control.UIAxes
        UIAxes2                         matlab.ui.control.UIAxes
        UIAxes_2                        matlab.ui.control.UIAxes
        UIAxes                          matlab.ui.control.UIAxes
    end
    
    properties (Access = public)
        TD = struct();
    end
    properties (Access = private)
        model_params = struct('gc_reset_value', 0, ...
            'oms_reset_value', 0, ...
            'oms_refractory_period', 0,...
            'hpf_wac_tc', 0.3,...
            'enable_sequentialOMS', 0,...
            'resample_threshold', 0,...
            'rng_settings', 0,...
            'bc_offset', 0, ...
            'bc_leak', 0, ...
            'time_step', 10,...
            'debug_pixel', [128 128]);
        
        input_video = zeros(256,256,10);
        event_video = zeros(256,256,3,10);
        dbg_video = zeros(256,256,10);
        
        io_params = struct('rows', 0, 'cols', 0, 'frames', 0, 'in_path', 0,'out_path', 0);
    end
    
   

    % Callbacks that handle component events
    methods (Access = private)
        
        function startupFcn(app)
            UpdateThreshold(app);
            UpdateLeakage(app);
            UpdateSpatialFilter(app);
            UpdateIOConfig(app);
            UpdateFrontendAux(app);
            UpdateBackendAux(app);
        end

        
        function UpdateThreshold(app,event)
            
%             if or(event.Value > 255, event.Value < 0)
%                 event.Value = 10;
%                 fprintf("here\n")
%             end
            
            app.ONThresholdEditField.Value
            app.OFFThresholdEditField.Value
            app.NeuronVarianceSlider.Value 

            app.model_params.threshold(:,:,1) = app.ONThresholdEditField.Value.*ones(256,256);
            app.model_params.threshold(:,:,2) = app.OFFThresholdEditField.Value.*ones(256,256);
            app.model_params.percent_threshold_variance = app.NeuronVarianceSlider.Value;
            
            threshold_variance = (app.NeuronVarianceSlider.Value /100)*app.model_params.threshold(:,:,1);
            threshold_arrays(:,:,1) = app.model_params.threshold(:,:,1) + normrnd(0,threshold_variance, size(app.model_params.threshold(:,:,1)));
            threshold_variance = (app.NeuronVarianceSlider.Value /100)*app.model_params.threshold(:,:,2);
            threshold_arrays(:,:,2) = app.model_params.threshold(:,:,2) + normrnd(0,threshold_variance, size(app.model_params.threshold(:,:,2)));

            tMat0 = threshold_arrays(:,:,1);
            tMat1 = threshold_arrays(:,:,2);
            histogram(app.UIAxes2, tMat0(:));
            hold on
            histogram(app.UIAxes2, tMat1(:));
            hold off
        end
        
        function UpdateLeakage(app,event)
            
            app.model_params.neuron_leak = app.NeuronLeakageEditField.Value;
            app.model_params.ba_leak_rate = app.BALeakageEditField.Value;
            app.model_params.percent_leak_variance = app.LeakVarianceSlider.Value;

            neuron_leak_rate = max(normrnd(app.model_params.neuron_leak,  (app.model_params.percent_leak_variance/100)*app.model_params.neuron_leak, size(app.input_video(:,:,1))),0);
            ba_leak_rate    = max(normrnd(app.model_params.ba_leak_rate,  (app.model_params.percent_leak_variance/100)*app.model_params.ba_leak_rate, size(app.input_video(:,:,1))),0);
            
            lMat0 = neuron_leak_rate;
            lMat1 = ba_leak_rate;
            histogram(app.UIAxes2_2, lMat0(:));
            hold on
            histogram(app.UIAxes2_2, lMat1(:));
            hold off
        end
        
        function UpdateSpatialFilter(app,event)
          
            
            app.model_params.spatial_filter_variances = [app.SpatialVariance1EditField.Value app.SpatialVariance2EditField.Value];
            
            switch app.SpatialFEModeListBox.Value
                case 'Log'
                    spat_filt = zeros(15,15); spat_filt(8,8) = 1;
                    app.model_params.spatial_fe_mode = 'log';
                case 'Log-lowpass'
                    spat_filt = fspecial('gaussian', 15, app.model_params.spatial_filter_variances(1));
                    app.model_params.spatial_fe_mode = 'log-lowpass';
                case 'Linear'
                    spat_filt = zeros(15,15); spat_filt(8,8) = 1;
                case 'Lowpass'
                    spat_filt = fspecial('gaussian', 15, app.model_params.spatial_filter_variances(1));
                    app.model_params.spatial_fe_mode = 'lowpass';
                case 'Bandpass'
                    horiz = fspecial('gaussian', 15, app.model_params.spatial_filter_variances(2));
                    pr = fspecial('gaussian',15, app.model_params.spatial_filter_variances(1));
                    spat_filt = pr - horiz;
                    app.model_params.spatial_fe_mode = 'bandpass';
            end
            
            surf(app.UIAxes2_3, spat_filt);
        end
        
        function UpdateFrontendAux(app,event)
            app.model_params.enable_shot_noise = app.EnableShotNoiseCheckBox.Value;
            app.model_params.opl_time_constant = app.OPLTimeConstantSlider.Value;
            app.model_params
        end
        
        function UpdateBackendAux(app,event)
            app.model_params.hpf_gc_tc   = app.NeuronTimeConstantSlider.Value;
            app.model_params.gc_refractory_period = app.RefractoryPeriodEditField.Value;
            switch app.DebugModeDropDown.Value
                case 'Photo'
                    app.model_params.dbg_mode                         = 'photo';
                case 'OPL S. Resp.'
                    app.model_params.dbg_mode                         = 'opl_sr';
                case 'OPL ST Resp.'
                    app.model_params.dbg_mode                         = 'opl_str';
                case 'ON Neuron'
                    app.model_params.dbg_mode                         = 'on_neuron';
                case 'OFF Neuron'
                    app.model_params.dbg_mode                         = 'off_neuron';
            end
            
            app.model_params

        end
        
        function UpdateIOConfig(app,event)
            app.io_params.in_path = app.InputVideoFileEditField.Value;
            app.io_params.out_path = app.OutputVideoFileEditField.Value;
            app.io_params.rows = app.NumberRowsEditField.Value;
            app.io_params.cols = app.NumberColumnsEditField.Value;
            app.io_params.frames = app.NumberFramesEditField.Value;
            
            app.io_params
        end
        
        function ReadInputVideo(app,event)
            
            [file,path] = uigetfile('*.mp4;*.avi', 'Pick a input video file');
            app.InputVideoFileEditField.Value = [path file];
            app.io_params.in_path = app.InputVideoFileEditField.Value;
            
            app.input_video = readVideo_rs( app.io_params.in_path, app.io_params.rows, app.io_params.cols, app.io_params.frames, 1 );
            fprintf('[RetinoGUI-INFO] Loaded input video from %s\n', app.io_params.in_path);
            app.UIAxes.XLim = [0 app.io_params.cols];
            app.UIAxes.YLim = [0 app.io_params.rows];
            
            im(1) = imagesc(app.UIAxes,app.input_video(:,:,1));
            for fidx=1:size(app.input_video,3)
                set(im(1),'cdata',app.input_video(:,:,fidx));
                colormap(gray);
                pause(1/60);
            end
        end
        
        
        function RunModel(app,event)
            fprintf('[RetinoGUI-INFO] Running Model\n');
            
            app.RunModelButton.Text = 'Running Model...';

            [app.TD, app.event_video, app.dbg_video, ~, ~] = RetinoSim(app.input_video, app.model_params);
            
            app.RunModelButton.Value = 0;
            
            app.RunModelButton.Text = 'Run Model';

        end
        
        function PlotModel(app,event)
            fprintf('[RetinoGUI-INFO] Plotting Model\n');
            
            app.PlotOutputButton.Text = 'Plotting...';
            
            app.UIAxes.XLim = [0 app.io_params.cols];
            app.UIAxes.YLim = [0 app.io_params.rows];
            
            app.UIAxes_2.XLim = [0 app.io_params.cols];
            app.UIAxes_2.YLim = [0 app.io_params.rows];
            
            im(1) = imagesc(app.UIAxes,app.dbg_video(:,:,1));
            im(2) = imagesc(app.UIAxes_2,app.event_video(:,:,:,1));
            
            for fidx  = 1:size(app.dbg_video,3)
                set(im(1),'cdata',app.dbg_video(:,:,fidx));
                set(im(2),'cdata',app.event_video(:,:,:,fidx));
                pause(1/60);
            end

            
            app.PlotOutputButton.Value = 0;
            app.PlotOutputButton.Text = 'Plot Model';


        end
        
        function SaveOutputs(app,event)
            
            [file,path] = uiputfile('*', 'Pick an output file header and location');
            app.OutputVideoFileEditField.Value = [path file];
            app.io_params.out_path = app.OutputVideoFileEditField.Value;
            
            fprintf('[RetinoGUI-INFO] Saving Outputs to %s\n',app.OutputVideoFileEditField.Value);

            
            filepath = [app.OutputVideoFileEditField.Value '.avi'];
            writeOutputVideo(app.event_video,filepath);
            
            outframes = videoBlend(app.input_video, app.event_video, 0, 1, 'test.avi');
            filepath = [app.OutputVideoFileEditField.Value '_blended.avi'];
            writeOutputVideo(outframes,filepath);
            
            filepath = [app.OutputVideoFileEditField.Value '_events.mat'];
            TD = app.TD;
            save(filepath, 'TD');

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)
            
            set(0, 'DefaultFigureVisible', 'off');

            
            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1386 862];
            app.UIFigure.Name = 'RetinoSim v0.0';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Debug Frames')
%             xlabel(app.UIAxes, 'X')
%             ylabel(app.UIAxes, 'Y')
            app.UIAxes.Position = [21 403 470 400];
            app.UIAxes.XTick = [];
            app.UIAxes.YTick = [];
            
            % Create UIAxes_2
            app.UIAxes_2 = uiaxes(app.UIFigure);
            title(app.UIAxes_2, 'Event Frames')
%             xlabel(app.UIAxes_2, 'X')
%             ylabel(app.UIAxes_2, 'Y')
            app.UIAxes_2.Position = [491 403 510 400];
            app.UIAxes_2.XTick = [];
            app.UIAxes_2.YTick = [];
            
            %% GC Threshold Figure and Params init

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.UIFigure);
            title(app.UIAxes2, 'GC Thresholds')
            xlabel(app.UIAxes2, 'Threshold Value')
            ylabel(app.UIAxes2, 'Counts')
            app.UIAxes2.Position = [1021 620 300 185];
            
            
            % Create ONThresholdEditFieldLabel
            app.ONThresholdEditFieldLabel = uilabel(app.UIFigure);
            app.ONThresholdEditFieldLabel.HorizontalAlignment = 'right';
            app.ONThresholdEditFieldLabel.Position = [1021 600 80 22];
            app.ONThresholdEditFieldLabel.Text = 'ON Threshold';

            % Create ONThresholdEditField
            app.ONThresholdEditField = uieditfield(app.UIFigure, 'numeric');
            app.ONThresholdEditField.Position = [1021 580 100 22];
            app.ONThresholdEditField.Value = 10;
            app.model_params.threshold(:,:,1)  = app.ONThresholdEditField.Value * ones(256,256);
            app.ONThresholdEditField.ValueChangedFcn = createCallbackFcn(app, @UpdateThreshold, true);


            % Create OFFThresholdEditFieldLabel
            app.OFFThresholdEditFieldLabel = uilabel(app.UIFigure);
            app.OFFThresholdEditFieldLabel.HorizontalAlignment = 'right';
            app.OFFThresholdEditFieldLabel.Position = [1021 560 86 22];
            app.OFFThresholdEditFieldLabel.Text = 'OFF Threshold';


            % Create OFFThresholdEditField
            app.OFFThresholdEditField = uieditfield(app.UIFigure, 'numeric');
            app.OFFThresholdEditField.Position = [1021 540 100 22];
            app.OFFThresholdEditField.Value = 10;
            app.model_params.threshold(:,:,2)  = app.OFFThresholdEditField.Value * ones(256,256);
            app.OFFThresholdEditField.ValueChangedFcn = createCallbackFcn(app, @UpdateThreshold, true);


            % Create NeuronVarianceLabel
            app.NeuronVarianceLabel = uilabel(app.UIFigure);
            app.NeuronVarianceLabel.HorizontalAlignment = 'center';
            app.NeuronVarianceLabel.Position = [1170 580 175 22];
            app.NeuronVarianceLabel.Text = 'ON/OFF Thresh. Variance (%)';

            % Create NeuronVarianceSlider
            app.NeuronVarianceSlider = uislider(app.UIFigure);
            app.NeuronVarianceSlider.Limits = [0 100];
            app.NeuronVarianceSlider.MajorTicks = [0 25 50 75 100];
            app.NeuronVarianceSlider.Position = [1170 575 150 3];
            app.NeuronVarianceSlider.ValueChangedFcn = createCallbackFcn(app, @UpdateThreshold, true);
            

            %% Neuron/BA Leakage Figure and params Init.

            % Create UIAxes2_2
            app.UIAxes2_2 = uiaxes(app.UIFigure);
            title(app.UIAxes2_2, 'Neuron/BA Leakage')
            xlabel(app.UIAxes2_2, 'Leakage Value')
            ylabel(app.UIAxes2_2, 'Counts')
            app.UIAxes2_2.Position = [1021 340 300 185];
            
            % Create NeuronLeakageEditFieldLabel
            app.NeuronLeakageEditFieldLabel = uilabel(app.UIFigure);
            app.NeuronLeakageEditFieldLabel.HorizontalAlignment = 'right';
            app.NeuronLeakageEditFieldLabel.Position = [1021 320 94 22];
            app.NeuronLeakageEditFieldLabel.Text = 'Neuron Leakage';

            % Create NeuronLeakageEditField
            app.NeuronLeakageEditField = uieditfield(app.UIFigure, 'numeric');
            app.NeuronLeakageEditField.Position = [1021 300 100 22];
            app.NeuronLeakageEditField.Value = 1.0;
            app.model_params.neuron_leak = app.NeuronLeakageEditField.Value;
            app.NeuronLeakageEditField.ValueChangedFcn = createCallbackFcn(app, @UpdateLeakage, true);
            
            % Create BALeakageEditFieldLabel
            app.BALeakageEditFieldLabel = uilabel(app.UIFigure);
            app.BALeakageEditFieldLabel.HorizontalAlignment = 'right';
            app.BALeakageEditFieldLabel.Position = [1021 280 71 22];
            app.BALeakageEditFieldLabel.Text = 'BA Leakage';

            % Create BALeakageEditField
            app.BALeakageEditField = uieditfield(app.UIFigure, 'numeric');
            app.BALeakageEditField.Position = [1021 260 100 22];
            app.BALeakageEditField.Value = 1.0;
            app.model_params.ba_leak = app.BALeakageEditField.Value;
            app.BALeakageEditField.ValueChangedFcn = createCallbackFcn(app, @UpdateLeakage, true);

             % Create LeakVarianceLabel
            app.LeakVarianceLabel = uilabel(app.UIFigure);
            app.LeakVarianceLabel.HorizontalAlignment = 'center';
            app.LeakVarianceLabel.Position = [1170 310 175 22];
            app.LeakVarianceLabel.Text = 'Leakage Variance (%)';

            % Create LeakVarianceSlider
            app.LeakVarianceSlider = uislider(app.UIFigure);
            app.LeakVarianceSlider.Limits = [0 100];
            app.LeakVarianceSlider.MajorTicks = [0 25 50 75 100];
            app.LeakVarianceSlider.Position = [1170 305 150 3];
            app.LeakVarianceSlider.ValueChangedFcn = createCallbackFcn(app, @UpdateLeakage, true);

            
            %% Spatial Variance Config.

            % Create UIAxes2_3
            app.UIAxes2_3 = uiaxes(app.UIFigure);
            title(app.UIAxes2_3, 'Spatial Filter')
            xlabel(app.UIAxes2_3, 'X')
            ylabel(app.UIAxes2_3, 'Y')
            app.UIAxes2_3.Position = [1021 60 300 185];
            
            % Create SpatialVariance1EditFieldLabel
            app.SpatialVariance1EditFieldLabel = uilabel(app.UIFigure);
            app.SpatialVariance1EditFieldLabel.HorizontalAlignment = 'right';
            app.SpatialVariance1EditFieldLabel.Position = [1060 40 102 22];
            app.SpatialVariance1EditFieldLabel.Text = 'Spatial Variance 1';

            % Create SpatialVariance1EditField
            app.SpatialVariance1EditField = uieditfield(app.UIFigure, 'numeric');
            app.SpatialVariance1EditField.Position = [1060 20 100 22];
            app.SpatialVariance1EditField.Value = 2;
            app.SpatialVariance1EditField.ValueChangedFcn = createCallbackFcn(app, @UpdateSpatialFilter, true);

            % Create SpatialVariance2EditFieldLabel
            app.SpatialVariance2EditFieldLabel = uilabel(app.UIFigure);
            app.SpatialVariance2EditFieldLabel.HorizontalAlignment = 'right';
            app.SpatialVariance2EditFieldLabel.Position = [1200 40 102 22];
            app.SpatialVariance2EditFieldLabel.Text = 'Spatial Variance 2';

            % Create SpatialVariance2EditField
            app.SpatialVariance2EditField = uieditfield(app.UIFigure, 'numeric');
            app.SpatialVariance2EditField.Position = [1200 20 102 22];
            app.SpatialVariance2EditField.Value = 2.3;
            app.SpatialVariance2EditField.ValueChangedFcn = createCallbackFcn(app, @UpdateSpatialFilter, true);
            
           %% Frontend
            
            % Create FrontendParametersLabel
            app.FrontendParametersLabel = uilabel(app.UIFigure);
            app.FrontendParametersLabel.FontWeight = 'bold';
            app.FrontendParametersLabel.Position = [210 290 126 25];
            app.FrontendParametersLabel.Text = 'Frontend Parameters';
            
            % Create EnableShotNoiseCheckBox
            app.EnableShotNoiseCheckBox = uicheckbox(app.UIFigure);
            app.EnableShotNoiseCheckBox.Text = 'Enable Shot Noise';
            app.EnableShotNoiseCheckBox.Position = [136 250 121 22];
            app.EnableShotNoiseCheckBox.ValueChangedFcn = createCallbackFcn(app, @UpdateFrontendAux, true);

            % Create SpatialFEModeListBoxLabel
            app.SpatialFEModeListBoxLabel = uilabel(app.UIFigure);
            app.SpatialFEModeListBoxLabel.HorizontalAlignment = 'right';
            app.SpatialFEModeListBoxLabel.Position = [303 260 94 22];
            app.SpatialFEModeListBoxLabel.Text = 'Spatial FE Mode';

            % Create SpatialFEModeListBox
            app.SpatialFEModeListBox = uilistbox(app.UIFigure);
            app.SpatialFEModeListBox.Items = {'Log', 'Log-lowpass', 'Linear', 'Lowpass', 'Bandpass'};
            app.SpatialFEModeListBox.Position = [290 165 119 94];
            app.SpatialFEModeListBox.Value = 'Log';
            app.model_params.spatial_fe_mode = app.SpatialFEModeListBox.Value;
            app.SpatialFEModeListBox.ValueChangedFcn = createCallbackFcn(app, @UpdateSpatialFilter, true);
            
            % Create OPLTimeConstantSliderLabel
            app.OPLTimeConstantSliderLabel = uilabel(app.UIFigure);
            app.OPLTimeConstantSliderLabel.HorizontalAlignment = 'right';
            app.OPLTimeConstantSliderLabel.Position = [136 215 110 22];
            app.OPLTimeConstantSliderLabel.Text = 'OPL Time Constant';

            % Create OPLTimeConstantSlider
            app.OPLTimeConstantSlider = uislider(app.UIFigure);
            app.OPLTimeConstantSlider.Limits = [0 1];
            app.OPLTimeConstantSlider.MajorTicks = [0 0.2 0.4 0.6 0.8 1];
            app.OPLTimeConstantSlider.Position = [116 205 150 3];
            app.OPLTimeConstantSlider.ValueChangedFcn = createCallbackFcn(app, @UpdateFrontendAux, true);
            
            %% Backend
            % Create BackendParametersLabel
            app.BackendParametersLabel = uilabel(app.UIFigure);
            app.BackendParametersLabel.FontWeight = 'bold';
            app.BackendParametersLabel.Position = [690 290 124 25];
            app.BackendParametersLabel.Text = 'Backend Parameters';

            % Create NeuronTimeConstantSliderLabel
            app.NeuronTimeConstantSliderLabel = uilabel(app.UIFigure);
            app.NeuronTimeConstantSliderLabel.HorizontalAlignment = 'right';
            app.NeuronTimeConstantSliderLabel.Position = [680 215 126 22];
            app.NeuronTimeConstantSliderLabel.Text = 'Neuron Time Constant';

            % Create NeuronTimeConstantSlider
            app.NeuronTimeConstantSlider = uislider(app.UIFigure);
            app.NeuronTimeConstantSlider.Limits = [0 1];
            app.NeuronTimeConstantSlider.MajorTicks = [0 0.2 0.4 0.6 0.8 1];
            app.NeuronTimeConstantSlider.Position = [665 205 150 3];
            app.NeuronTimeConstantSlider.ValueChangedFcn = createCallbackFcn(app, @UpdateBackendAux, true);

            % Create DebugModeDropDownLabel
            app.DebugModeDropDownLabel = uilabel(app.UIFigure);
            app.DebugModeDropDownLabel.HorizontalAlignment = 'right';
            app.DebugModeDropDownLabel.Position = [771 260 74 22];
            app.DebugModeDropDownLabel.Text = 'Debug Mode';

            % Create DebugModeDropDown
            app.DebugModeDropDown = uidropdown(app.UIFigure);
            app.DebugModeDropDown.Items = {'Photo', 'OPL S. Resp.', 'OPL ST Resp.', 'ON Neuron', 'OFF Neuron'};
            app.DebugModeDropDown.Position = [768 240 100 22];
            app.DebugModeDropDown.Value = 'Photo';
            app.DebugModeDropDown.ValueChangedFcn = createCallbackFcn(app, @UpdateBackendAux, true);

            % Create RefractoryPeriodEditFieldLabel
            app.RefractoryPeriodEditFieldLabel = uilabel(app.UIFigure);
            app.RefractoryPeriodEditFieldLabel.HorizontalAlignment = 'right';
            app.RefractoryPeriodEditFieldLabel.Position = [645 260 99 22];
            app.RefractoryPeriodEditFieldLabel.Text = 'Refractory Period';

            % Create RefractoryPeriodEditField
            app.RefractoryPeriodEditField = uieditfield(app.UIFigure, 'numeric');
            app.RefractoryPeriodEditField.Position = [645 240 100 22];
            app.RefractoryPeriodEditField.ValueChangedFcn = createCallbackFcn(app, @UpdateBackendAux, true);
            
            %% Aux
            % Create RetinoSimLabel
            app.RetinoSimLabel = uilabel(app.UIFigure);
            app.RetinoSimLabel.FontSize = 20;
            app.RetinoSimLabel.FontWeight = 'bold';
            app.RetinoSimLabel.Position = [641 829 104 24];
            app.RetinoSimLabel.Text = 'RetinoSim';
            
            % Create RunModelButton
            app.RunModelButton = uibutton(app.UIFigure, 'state');
            app.RunModelButton.Text = 'Run Model';
            app.RunModelButton.FontWeight = 'bold';
            app.RunModelButton.Position = [41 343 440 30];
            app.RunModelButton.ValueChangedFcn = createCallbackFcn(app, @RunModel, true);

            % Create PlotOutputButton
            app.PlotOutputButton = uibutton(app.UIFigure, 'state');
            app.PlotOutputButton.Text = 'Plot Output';
            app.PlotOutputButton.FontWeight = 'bold';
            app.PlotOutputButton.Position = [541 343 440 30];
            app.PlotOutputButton.ValueChangedFcn = createCallbackFcn(app, @PlotModel, true);

            
            %% IO
            % Create IOInterfaceLabel
            app.IOInterfaceLabel = uilabel(app.UIFigure);
            app.IOInterfaceLabel.FontWeight = 'bold';
            app.IOInterfaceLabel.Position = [490 135 75 22];
            app.IOInterfaceLabel.Text = 'I/O Interface';

            % Create InputVideoFileEditFieldLabel
            app.InputVideoFileEditFieldLabel = uilabel(app.UIFigure);
            app.InputVideoFileEditFieldLabel.HorizontalAlignment = 'right';
            app.InputVideoFileEditFieldLabel.Position = [240 110 89 22];
            app.InputVideoFileEditFieldLabel.Text = 'Input Video File';

            % Create InputVideoFileEditField
            app.InputVideoFileEditField = uieditfield(app.UIFigure, 'text');
            app.InputVideoFileEditField.ValueChangedFcn = createCallbackFcn(app, @UpdateIOConfig, true);
            app.InputVideoFileEditField.Position = [205 80 176 22];
            app.InputVideoFileEditField.Value = '../../../data/room_pan.mp4';

            % Create OutputVideoFileEditFieldLabel
            app.OutputVideoFileEditFieldLabel = uilabel(app.UIFigure);
            app.OutputVideoFileEditFieldLabel.HorizontalAlignment = 'right';
            app.OutputVideoFileEditFieldLabel.Position = [810 110 98 22];
            app.OutputVideoFileEditFieldLabel.Text = 'Output Video File';

            % Create OutputVideoFileEditField
            app.OutputVideoFileEditField = uieditfield(app.UIFigure, 'text');
            app.OutputVideoFileEditField.Position = [775 80 177 22];
            app.OutputVideoFileEditField.Value = '../../../data/gui_out';
            app.OutputVideoFileEditField.ValueChangedFcn = createCallbackFcn(app, @UpdateIOConfig, true);

            % Create SaveVideoButton
            app.SaveVideoButton = uibutton(app.UIFigure, 'push');
            app.SaveVideoButton.Position = [665 80 100 22];
            app.SaveVideoButton.Text = 'Save Video';
            app.SaveVideoButton.ButtonPushedFcn = createCallbackFcn(app, @SaveOutputs, true);

            % Create LoadVideoButton
            app.LoadVideoButton = uibutton(app.UIFigure, 'push');
            app.LoadVideoButton.Position = [101 80 100 22];
            app.LoadVideoButton.Text = 'Load Video';
            app.LoadVideoButton.ButtonPushedFcn = createCallbackFcn(app, @ReadInputVideo, true);

            % Create NumberRowsEditFieldLabel
            app.NumberRowsEditFieldLabel = uilabel(app.UIFigure);
            app.NumberRowsEditFieldLabel.HorizontalAlignment = 'right';
            app.NumberRowsEditFieldLabel.Position = [420 110 82 22];
            app.NumberRowsEditFieldLabel.Text = 'Number Rows';

            % Create NumberRowsEditField
            app.NumberRowsEditField = uieditfield(app.UIFigure, 'numeric');
            app.NumberRowsEditField.Position = [415 80 100 22];
            app.NumberRowsEditField.Value = 256;
            app.NumberRowsEditField.ValueChangedFcn = createCallbackFcn(app, @UpdateIOConfig, true);

            % Create NumberColumnsEditFieldLabel
            app.NumberColumnsEditFieldLabel = uilabel(app.UIFigure);
            app.NumberColumnsEditFieldLabel.HorizontalAlignment = 'right';
            app.NumberColumnsEditFieldLabel.Position = [540 110 99 22];
            app.NumberColumnsEditFieldLabel.Text = 'Number Columns';

            % Create NumberColumnsEditField
            app.NumberColumnsEditField = uieditfield(app.UIFigure, 'numeric');
            app.NumberColumnsEditField.Position = [535 80 100 22];
            app.NumberColumnsEditField.Value = 256;
            app.NumberColumnsEditField.ValueChangedFcn = createCallbackFcn(app, @UpdateIOConfig, true);
            
            
            % Create NumberFramesEditFieldLabel
            app.NumberFramesEditFieldLabel = uilabel(app.UIFigure);
            app.NumberFramesEditFieldLabel.HorizontalAlignment = 'right';
            app.NumberFramesEditFieldLabel.Position = [490 50 99 22];
            app.NumberFramesEditFieldLabel.Text = 'Number Frames';

            % Create NumberFramesEditField
            app.NumberFramesEditField = uieditfield(app.UIFigure, 'numeric');
            app.NumberFramesEditField.Position = [485 20 100 22];
            app.NumberFramesEditField.Value = 100;
            app.NumberFramesEditField.ValueChangedFcn = createCallbackFcn(app, @UpdateIOConfig, true);


            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = RetinoSimGUI
            
            addpath(genpath('../modeling'));
            addpath(genpath('../aux'));
            addpath(genpath('../io'));
            
            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure);
            
            
            runStartupFcn(app, @startupFcn);

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end