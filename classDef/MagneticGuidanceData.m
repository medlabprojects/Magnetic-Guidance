%% MagneticGuidanceData Class
%
%   Imports, stores, and processes data from magnetic guidance experiments
%
%
%   How to Use:
%   -> create CSV files for smaract and force topics from ROS bag file
%     -> use bash script 'bag2csv.sh'
%       caos@control:~/MagSteering$ ./bag2csv.sh
%
%   -> create a struct with filepaths to the CSV files
%     -> MUST use these field names: smaract, forces, (optional) dac
%       >> filepaths.smaract = 'C:\path\to\data\smaract_data_from_bag.csv';
%       >> filepaths.force  = 'C:\path\to\data\force_data_from_bag.csv';
% 
%   -> construct instance of class
%       >> trial2_nomag = MagneticGuidanceData(filepaths);
% 
%   -> set smoothing span to use for force data
%       >> trial2_nomag.setSmoothSpan(0.05);
% 
%   -> plot force vs insertion depth
%       >> plot(trial2_nomag.depth_insertion, trial2_nomag.Fmag, '--b')
%       >> plot(trial2_nomag.depth_insertion, trial2_nomag.Fmag_smooth, 'b')
%
%   Trevor Bruns
%   July 2019

%%
classdef MagneticGuidanceData
    properties (SetAccess = private)
        depth_insertion % [mm] Nx1, interpolated depth at each force measurement during insertion        
        smaract % SmaractData object
        nano    % Nano17Data object
%         dac
        force_i_start
        force_i_end
    end
    properties (Dependent, SetAccess = private)
        time_insertion  % [ns] Nx1, times corresponding to each force measurement during insertion
        force_insertion % [mN] Nx3, force measurements taken during insertion
        Fmag % [mN] Nx1, ||force_insertion||
        Fx   % [mN] Nx1, force_insertion(:,1)
        Fy   % [mN] Nx1, force_insertion(:,2)
        Fz   % [mN] Nx1, force_insertion(:,3)
        force_insertion_smooth
        Fmag_smooth
        Fx_smooth
        Fy_smooth
        Fz_smooth
        force_i_insertion % indices of force measurements taken during insertion
    end
    properties (Access = private)
        smooth_span; % proportion of points to use for smoothing (default = 0.06)
        force_insertion_smooth_ % only recomputed if smooth_span has changed
    end

    methods
        function obj = MagneticGuidanceData(filepaths)
            % import forces CSV
            if isfield(filepaths, 'force')
               obj.nano = Nano17Data(filepaths.force);
            else
                error('''forces'' struct field not found')
            end
            
            % import smaract CSV
            if isfield(filepaths, 'smaract')
               obj.smaract = SmaractData(filepaths.smaract);
            else
                error('''smaract'' struct field not found')
            end
            
            % import dac voltages CSV
%             if isfield(filepaths, 'smaract')
%                obj.dac = importRosDacCSV(filepaths.dac);
%             else
%                 disp('''dac'' struct field not found')
%             end    

            % force indices corresponding to smaract start/stop (i.e. during insertion)
            obj.force_i_start = find(obj.nano.time >= obj.smaract.time_start, 1);
            obj.force_i_end   = find(obj.nano.time >= obj.smaract.time_end,   1);
            
            % interpolate to find ch0 position at each force measurement during insertion
            obj.depth_insertion = interp1(obj.smaract.time, obj.smaract.ch0, obj.time_insertion);
            
            % initialize default smoothing
            obj = obj.setSmoothSpan(0.06);
        end
        
        function obj = setSmoothSpan(obj, smooth_span)
            % recompute if smooth_span is changed
            if isempty(obj.smooth_span) || (smooth_span ~= obj.smooth_span)
                obj.smooth_span = smooth_span;
                
                obj.force_insertion_smooth_ = ...
                    [ smooth(obj.depth_insertion, obj.Fx, smooth_span, 'loess'), ...
                      smooth(obj.depth_insertion, obj.Fy, smooth_span, 'loess'), ...
                      smooth(obj.depth_insertion, obj.Fz, smooth_span, 'loess')];
            end
        end
               
        function time_insertion = get.time_insertion(obj)
            time_insertion = obj.nano.time(obj.force_i_insertion);
        end
        
        function force_insertion = get.force_insertion(obj)
            force_insertion = obj.nano.force(obj.force_i_insertion);
        end
        
        function Fx = get.Fx(obj)
            Fx = obj.nano.Fx(obj.force_i_insertion);
        end
       
        function Fy = get.Fy(obj)
            Fy = obj.nano.Fy(obj.force_i_insertion); 
        end
       
        function Fz = get.Fz(obj)
            Fz = obj.nano.Fz(obj.force_i_insertion); 
        end
       
        function Fmag = get.Fmag(obj)
            Fmag = obj.nano.Fmag(obj.force_i_insertion);
        end
        
        function force_insertion_smooth = get.force_insertion_smooth(obj)
            force_insertion_smooth = obj.force_insertion_smooth_;
        end
        
        function Fx_smooth = get.Fx_smooth(obj)
            Fx_smooth = obj.force_insertion_smooth(:,1);
        end
       
        function Fy_smooth = get.Fy_smooth(obj)
            Fy_smooth = obj.force_insertion_smooth(:,2); 
        end
       
        function Fz_smooth = get.Fz_smooth(obj)
            Fz_smooth = obj.force_insertion_smooth(:,3); 
        end
       
        function Fmag_smooth = get.Fmag_smooth(obj)
            Fmag_smooth = sqrt(sum(obj.force_insertion_smooth.^2, 2));
        end
        
        function force_i_insertion = get.force_i_insertion(obj)
            force_i_insertion = [obj.force_i_start:obj.force_i_end]';
        end
    end 
end