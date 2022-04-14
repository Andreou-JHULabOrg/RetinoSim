function [TD] = loadAEFile(varargin)


filepath = varargin{1};

% find type of file and load it appropriately into TD struct
% supported types:
%   .aedat - V2 for DVS128 or DAVIS240 from jAER
%   .mat   - from aedat4 to .mat script for DV
%   .txt   - read text file for uzh-rpg dataset files
%   .bag - read from uzh-rpg dataset files

extension = filepath(max(strfind(filepath, '.')):end);
fprintf("Loading %s file from %s...\n", extension, filepath);

switch extension
	case '.aedat'
		try 
			[TD.x, TD.y, TD.p, TD.ts] = loadAERfull(filepath);
		catch
			try 
				[TD.x, TD.y, TD.p, TD.ts] = getDVSeventsDavis(filepath);
			catch 
				error('File is not compatible with DAVIS or DVS read scripts.');
			end
		end
	case '.mat'
		TD = load(filepath);
		TD.x = TD.x';
		TD.y = TD.y';
		TD.ts = TD.ts';
		TD.p = TD.p'*2 - 1;
	case '.txt'
		TD_mat = table2array(readtable(filepath));
		TD.ts = uint32(TD_mat(:,1)*1e6); 
		TD.x = uint16(TD_mat(:,2));
		TD.y = uint16(TD_mat(:,3)); 
		TD.p = 2*TD_mat(:,4)-1;
	case '.bag'
		bag = rosbag(filepath);
		bSel = select(bag,'Topic','/dvs/events');
		TD = readMessages(bSel,'DataFormat','struct');
    case '.bin'
        TD = readaerdat(filepath, 0, 61844);
	otherwise
		error('Incorrect file type. Please use .aedat, .mat, .txt, .bin s,or .bag.');
end

switch nargin
    case 1
        startEvent = 1;
        num_events = length(TD.x);
    case 2
        startEvent = varargin{2};
        num_events = length(TD.x)-startEvent;
    case 3
        startEvent = varargin{2};
        num_events = varargin{3};
end

field_names = fields(TD);
for field_it = 1:length(field_names)
    TD.(field_names{field_it}) = TD.(field_names{field_it})(startEvent:startEvent+num_events-1);
end

end