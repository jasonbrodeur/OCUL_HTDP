function [logfile] = create_derivatives(series_label, process_list, pc_path_flag)

% create_derivatives.m
% This function runs through a collection of maps sheets (whether 1:25000 or 1:63360, as specified by series_label),
% and creates the following derivative images.
%--> thumbnail (204 x 204) [thumbnail]
%--> medium JPG (~2000x2000) [Could be useful for an Omeka-like item display page]
%--> 300 ppi JPG (20-30MB) [manageable-sized copy for general reference use]

%%% inputs:
% series_label: string input for series scale -- either '25000' or '63360'
% georef_list: file name of a single column list of filenames for sheets to be processed (optional); file must exist in the master_path directory 
% (i.e. /AutoGeoref/1_25000/ or /AutoGeoref/1_63360/ 
% where process_list is not provided, the function works through the entire /tif directory
% pc_path_flag: Flag allowing Jay to specify different read/write directories on the processing PC
%%% pc_path_flag = 0 is default --> work from the 'E:\Users\brodeujj\GIS\OCUL Topo Project\AutoGeoRef directory
%%% pc_path_flag = 1 --> work from the 'I:\AutoGeoRef directory

if nargin == 0
    disp(['The variable ''series_label'' needs to be set to ''63360'' or ''25000''. Exiting.']);
    break
elseif nargin == 1
    dir_flag = 1 % if only one argument (series label) is provided, then run through the entire /tif directory
    pc_path_flag = 0; % work from the default directory 
    process_list = '';
elseif nargin == 2
    dir_flag = 0; % if a list is provided, the function will run through all filenames provided in the list.
    pc_path_flag = 0; % work from the default directory 
else
    dir_flag = 0;
end

%%% If process_list has been provided as an empty matrix ('[]'), then change dir_flag to 1
if isempty(process_list)==1
  dir_flag = 1;
else 
  dir_flag = 0; 
end

%%% If pc_path_flag is 1, then set the home directory to I:\AutoGeoRef. Otherwise, use the default.
if pc_path_flag==1
home_dir = 'I:\AutoGeoRef';
else
home_dir = 'E:\Users\brodeujj\GIS\OCUL Topo Project\AutoGeoRef';
end    
%% Variables

%% Paths
%master_path = '/media/brodeujj/KINGSTON/AutoGeorefTests/';
if ispc==1
master_path = [home_dir '\1_' series_label '\'];
else
master_path = ['/media/Stuff/AutoGeoRef/1_' series_label '/'];
end

jpg_path = [master_path 'jpg/'];
tif_path = [master_path 'tif/'];

jpg_folders = {'small';'medium';'large'};
%% Make the output folders (if necessary):

for k = 1:1:length(jpg_folders)
  if exist([jpg_path jpg_folders{k}])~=7
    if ispc==1; [status,cmdout] = dos(['mkdir "' jpg_path jpg_folders{k} '"']); else [status,cmdout] = unix(['mkdir "' jpg_path jpg_folders{k} '"']);end
      if status==0
      disp(['Created directory: ' jpg_path jpg_folders{k}]);
      end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% get the directory listing in /tif; pare down to a list of only tif files:
cd(tif_path);

if dir_flag==1
%for k = 1:1:length(jpg_folders)
cmds = {['mogrify -path "' jpg_path jpg_folders{1} '/" -geometry x204 -format jpg *.tif'];...
        ['mogrify -path "' jpg_path jpg_folders{2} '/" -geometry x2000 -format jpg *.tif'];...
        ['mogrify -path "' jpg_path jpg_folders{3} '/" -resize 50% -format jpg *.tif']};
  for i = 1:1:length(cmds)
     if ispc==1;  [status,cmdout] = dos(cmds{i,1}); 
     else         [status,cmdout] = unix(cmds{i,1});
     end
  end

else 
% load the processing list:
  fid_list = fopen([master_path process_list]);
  tmp_dir = struct;
  tmp = textscan(fid_list, '%s','Delimiter',',');
  fclose(fid_list);

  for j = 1:1:size(tmp{1,1},1)
  tmp_name = tmp{1,1}{j,1};
  [fdir, fname, fext] = fileparts(tmp_name);
  cmds = {['convert ' tmp_name ' -geometry x204 "' jpg_path 'small/' fname '.jpg"'];...
        ['convert ' tmp_name ' -geometry x2000 "' jpg_path 'medium/' fname '.jpg"'];...
        ['convert ' tmp_name ' -resize 50% "' jpg_path 'large/' fname '.jpg"']};
     for i = 1:1:length(cmds)
        if ispc==1;  [status,cmdout] = dos(cmds{i,1}); 
        else         [status,cmdout] = unix(cmds{i,1});
        end
     end
  end
end
