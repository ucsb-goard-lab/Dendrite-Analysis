classdef NewNeurotarExtractor < handle
    
    properties (Access = public)
        FILENAME
        CAGE_RADIUS = 125
        ANGLE_TYPE = 'Positive'
        RECORDING_RATE
        SPEED_THRESHOLD = 10;
        BOUT_THRESHOLD = 10;
        RECORDING_FRAMES
        data
    end

    properties
        isRecording 
        isMoving
        moving_times
    end

    properties (Dependent)
        X
        Y
        speed
        alpha
        R
        phi
    end

    methods
        % Constructor
        function obj = NewNeurotarExtractor(session, options)
            
            arguments
                session
                options.isRecording = true
                options.isMoving = false
                options.RECORDING_FRAMES = 12000
                options.RECORDING_RATE = 10
            end

            obj.isRecording= options.isRecording;
            obj.isMoving = options.isMoving;

            if ~isempty( options.RECORDING_FRAMES)
                obj.RECORDING_FRAMES = options.RECORDING_FRAMES;
            end

            if ~isempty( options.RECORDING_RATE)
                obj.RECORDING_RATE = options.RECORDING_RATE;
            end

            if nargin == 0 || isempty(session)
                obj.getFilename();
            else
                obj.FILENAME = strcat(session, '.tdms');
            end

            if obj.isRecording && isempty(obj.RECORDING_FRAMES)
                prompt = "How many recording frames ? ";
                obj.RECORDING_FRAMES = input(prompt);
            end

            obj.readTDMS();
            obj.moving_times = obj.detectMovement();

        end

    end

    % Reading methods
    methods

        function getFilename(obj)

%             folder = uigetdir([], 'Choose the folder containing the file:');
% 
%             tdms_files = strcat(folder, filesep, '*.tdms');
%             file_location = dir(tdms_files);
%             filename = strcat(file_location.folder, filesep, ...
%                 file_location.name);
%             obj.FILENAME = filename;

              % disp('Choose tdms file...')
              % [tdms_file,path] = uigetfile('*.tdms');
              tdms_file = dir('*.tdms');
              path = strcat(tdms_file.folder,'\');
              tdms_file = tdms_file.name;
              obj.FILENAME = strcat(path,tdms_file); % must be on path
        end

        function data = readTDMS(obj)

            data = tdmsread(obj.FILENAME);
            obj.data = data{1,3};
            
        end

    end
    
    
    % Extracting and microscope-matching methods
    methods

        function raw_variable = extractVariable(obj, variable_name)

            raw_variable = obj.data.(variable_name);

        end

        function behavior_variable = getVariable(obj, variable_name)

            raw_variable = obj.extractVariable(variable_name);

            switch variable_name

                case 'X'

                    behavior_variable = obj.CAGE_RADIUS/100 * raw_variable;

                case 'Y'

                    behavior_variable = - obj.CAGE_RADIUS/100 * raw_variable;

                case 'alpha'

                    switch obj.ANGLE_TYPE

                        case 'Positive'

                            behavior_variable = wrapTo360(90 - raw_variable);

                    end

                otherwise

                    behavior_variable = raw_variable;

            end

        end

        function behavior_variable = getRecordingVariable(obj, variable_name)

            variable = obj.getVariable(variable_name);
            cropped_variable = obj.cropToRecording(variable);
            behavior_variable = obj.downSample(cropped_variable);
            
        end

        function cropped_variable = cropToRecording(obj, variable)

            microscope_time = getVariable(obj, 'HW_timestamp') < ...
                (obj.RECORDING_FRAMES * (1/obj.RECORDING_RATE) * 1000);
            cropped_variable = variable(microscope_time);

        end

        function down_sampled = downSample(obj, variable)

            % step 2: downsample adjusted frames to match
            original_frames = 1:length(variable);
            desired_frames = linspace(1, length(variable), obj.RECORDING_FRAMES);
            down_sampled = interp1(original_frames, variable, desired_frames);

        end

    end

    % Get behavior variables
    methods 

        function speed = get.speed(obj)

            if obj.isRecording
                speed = getRecordingVariable(obj, 'Speed');
            else
                speed = getVariable(obj, 'Speed');
            end

        end

        function X = get.X(obj)

            if obj.isRecording
                X = getRecordingVariable(obj, 'X');
            else
                X = getVariable(obj, 'X');
            end

            if obj.isMoving
                X = X(obj.moving_times);
            end

        end

        function Y = get.Y(obj)

            if obj.isRecording
                Y = getRecordingVariable(obj, 'Y');
            else
                Y = getVariable(obj, 'Y');
            end

            if obj.isMoving
                Y = Y(obj.moving_times);
            end

        end

        function alpha = get.alpha(obj)

            if obj.isRecording
                alpha = getRecordingVariable(obj, 'alpha');
            else
                alpha = getVariable(obj, 'alpha');
            end

            if obj.isMoving
                alpha = alpha(obj.moving_times);
            end

        end

        function phi = get.phi(obj)

            if obj.isRecording
                phi = getRecordingVariable(obj, 'phi');
            else
                phi = getVariable(obj, 'phi');
            end

            if obj.isMoving
                phi = phi(obj.moving_times);
            end

        end

        function R = get.R(obj)

            if obj.isRecording
                R = getRecordingVariable(obj, 'R');
            else
                R = getVariable(obj, 'R');
            end

            if obj.isMoving
                R = R(obj.moving_times);
            end

        end

    end

    % Detect movement
    methods

        function is_moving= detectMovement(obj, options)

            arguments
                obj
                options.SpeedThreshold = 10;
                options.BoutThreshold = 5;
            end

            Speed = smooth(obj.speed, 10, 'moving')';

            Speed(Speed>200) = 200;
            speed_thresh = options.SpeedThreshold;
            bout_thresh = options.BoutThreshold;

            moving_time = Speed > speed_thresh;
            moving_time = [false, moving_time, false];
            bout_start = strfind(moving_time, [false true]) + 1;
            bout_end = strfind(moving_time, [true false]);

            for i = 1:length(bout_end)

                if bout_end(i)-bout_start(i) < bout_thresh
                    moving_time(bout_start(i):bout_end(i)) = false;
                elseif bout_start(i)>10
                    moving_time(bout_start(i)-10:bout_end(i)) = true;
                end

            end

            is_moving = moving_time(2:end-1);

        end

    end

end