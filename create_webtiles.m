function [logfle] = create_webtiles(series_label, process_list, zipflag)
%%% INPUTS
% series_label: string input for series scale -- either '25000' or '63360'
% process_list: file name of a single column list of filenames for sheets to be processed (optional); file must exist in the master_path directory 
% (i.e. /AutoGeoref/1_25000/ or /AutoGeoref/1_63360/. When georef_list is not provided, the function works through the entire directory.
% zipflag: flag for zipping top-level folders when created for each sheet (1 = zip; 0 = do not zip);

if nargin == 0
    disp(['The variable ''series_label'' needs to be set to ''63360'' or ''25000''. Exiting.']);
    break
elseif nargin == 1
    dir_flag = 1 % if only one argument (series label) is provided, then run through the entire /tif directory
    zipflag = 0; % zip the tile folders by default
    process_list = '';
elseif nargin == 2
    dir_flag = 0; % if a list is provided, the function will run through all filenames provided in the list.
    zipflag = 1; % zip the tile folders by default
else
    dir_flag = 0;
end


clear all;
close all;

%% Variables
%h_loadflag = 0; % flag to load image heights from variable 'h.mat'. When set to 1 it loads variables; otherwise, the script will use the imagemagick 'identify' command to get the height
%series = '63360'; %'25000' %Change this value to change the series.
%series_label = '63360';
%series_label = '25000';

OSGeo_install_path = 'C:\OSGeo4W64\bin\'; %The location of the gdal libraries 
%% Paths
%master_path = '/media/brodeujj/KINGSTON/AutoGeorefTests/';
if ispc==1
%master_path = ['E:\Users\brodeujj\GIS\OCUL Topo Project\AutoGeoRef\1_' series_label '\'];
top_path = pwd;
master_path = [top_path '\1_' series_label '\'];
%zipflag = 1;
else
top_path = ['/media/Stuff/AutoGeoRef/'];
master_path = [top_path '1_' series_label '/'];
%zipflag = 1;
end

%gcp_path = [master_path 'GCP-Upload/'];
%geotif_path = [master_path 'tif/'];
%qgis_gcp_path = [master_path 'GCP-QGIS\'];
tiles_path = [master_path 'tiles/'];
geotiff_path = [master_path 'geotiff/'];
t_srs='3857';
%SRS_find_flag = 1;
%% Series-specific settings:
%switch series
%  case '63360'
%  SRS_find_flag = 1;
%    s_srs = ''; %This may have to be incorporated into a loop:
%%    t_srs = {'3857';'3162'};%'EPSG:3162';% can be a cell array (gdalwarp loops through these)
%    t_srs = {''}; % 
%    geotiff_path = [master_path 'geotiff'];
%  case '25000'
%    SRS_find_flag = 1; % Means that we'll need to pull the SRS info from a separate lookup table.
%    s_srs = ''; %
%    t_srs = {''}; % 
%    geotiff_path = [master_path 'geotiff'];
%  otherwise
%    disp(['The variable ''series'' needs to be set to ''63360'' or ''25000''. Exiting.']);
%    break
%end
t_srs_tag = t_srs;

%% Make the output folders (if necessary):

%% If SRS_find_flag==1, we need to load a lookup table to connect the sheet to the proper coordinate reference system. Need to load it as a cell
% column 1 is the file name (no extension); column 2 is the EPSG number (number only, e.g. 26717)
%if SRS_find_flag==1
%fid_srs = fopen([master_path 'EPSG_Lookup_1_' series_label '.csv']);
%tmp = textscan(fid_srs,'%s %s %s','Delimiter',',');
%epsg_lookup(:,1) = tmp{1,1}(:,1);
%epsg_lookup(:,2) = tmp{1,2}(:,1);
%epsg_lookup(:,3) = tmp{1,3}(:,1);
%fclose(fid_srs);
%end
fid_srs = fopen([top_path 'EPSG_Lookup_1_' series_label '.csv'],'r');
tmp = textscan(fid_srs,'%s %s %s','Delimiter',',','headerlines',1);
epsg_lookup(:,1) = tmp{1,1}(:,1);
epsg_lookup(:,2) = tmp{1,2}(:,1);
epsg_lookup(:,3) = tmp{1,3}(:,1);
fclose(fid_srs);

%%% get the directory listing in /geotif; pare down to a list of only tif files:
cd(geotiff_path);

d = struct;

if dir_flag==1
tmp_dir = dir(geotiff_path);
else
% load the processing list:
fid_list = fopen([master_path process_list]);
tmp_dir = struct;
tmp = textscan(fid_list, '%s','Delimiter',',');
  for i = 1:1:size(tmp{1,1},1)
  tmp_dir(i).name = tmp{1,1}{i,1};
  tmp_dir(i).isdir = 0;
  end
  fclose(fid_list);
end

ctr = 1;
for i = 3:1:length(tmp_dir)
    [fdir, fname, fext] = fileparts(tmp_dir(i).name); %file directory | filename | file extension
    if tmp_dir(i).isdir==0 && strcmp(fext,'.tif')==1 % If we're dealing with a tif file:
        d(ctr).name =  tmp_dir(i).name;
        ctr = ctr+1;
    else
    end
end
clear tmp_dir;

cd(tiles_path);
logfile = cell(length(d),2);
%% Cycle through the tif files:
for i = 1:1:length(d)
    % get the filename of the tif file:
    filename_in = d(i).name;
    [fdir, fname, fext] = fileparts(filename_in); %file directory | filename | file extension
    logfile{i,1} = filename_in;
    %See if a directory exists already in /tiles. If not, create it:
    if exist([tiles_path fname],'folder')==7
    disp(['folder /tiles/' fname ' already exists. Writing into it']);
   else
   mkdir([tiles_path fname]);
   end
   
   %%%% retrieve the proper input (and output) reference systems
        try
            s_srs = epsg_lookup{strcmp(fname(1:4),epsg_lookup(:,1))==1,3};
%            t_srs{1,1} = epsg_lookup{strcmp(fname(1:4),epsg_lookup(:,1))==1,3};
%            t_srs_tag = {''};
        catch
          disp(['Could not find entry for ' fname(1:4) ' in epsg_lookup.']);
        end
        
        if isempty(s_srs)==1
            disp(['Could not get info from epsg_lookup for: ' fname '. Skipping.']);
            logfile{i,2} = 'epsg_lookup';
            continue
        end
   
    %run the gdal2tiles command:
    cmd = [' -s EPSG:' s_srs ' -z 6-16 ' geotiff_path filename_in ' "' tiles_path fname '"'];
    if ispc==1; 
        cmd = ['"' OSGeo_install_path 'gdal2tiles.py"' cmd];
        [status] = dos(cmd); 
        else [status] = unix(['gdal2tiles.py' cmd]);
    end
%    if ispc==1; [status,cmdout] = dos(cmd); else [status,cmdout] = unix(cmd);end
    
    if status~=0
            disp(['gdal2tiles failed for: ' filename_in '. Skipping.']);
            logfile{i,2} = 'gdal2tiles';
            continue
    end
    
    if zipflag==1
        [status_zip] = unix(['zip -r ' fname '.zip ' fname ' &']);  
%        [status_zip] = unix(['pushd "' tiles_path '" && zip -r ' fname '.zip ' fname ' && popd &']); 
%        [status_zip] = unix(['zip -r "' tiles_path fname '.zip" "' tiles_path fname '" &']); 
    end 
    
    if status_zip~=0
        disp(['zipping failed for: ' fname '. Skipping.']);
        logfile{i,2} = 'zip';
        continue
        
    end
         logfile{i,2} = 'ok';  
       
end

%%% Save the log file: 
fid = fopen([master_path 'tiles_logfile_' datestr(now,30) '.txt'],'w+');
for i = 1:1:size(logfile,1)
fprintf(fid,'%s\t %s\n',logfile{i,:});
end
fclose(fid)

%% If in Linux (and we'll need to transport these back on a hard drive), zip these folders up
%if zipflag==1
%cd(tiles_path)
%tmp_dir = dir(tiles_path);
%ctr = 1;
%  for i = 3:1:length(tmp_dir)
%    if tmp_dir(i).isdir == 1
%    [status] = unix(['zip -r ' tmp_dir(i).name '.zip ' tmp_dir(i).name]);
%    end
%  end
%end