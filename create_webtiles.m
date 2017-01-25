clear all;
close all;

%% Variables
%h_loadflag = 0; % flag to load image heights from variable 'h.mat'. When set to 1 it loads variables; otherwise, the script will use the imagemagick 'identify' command to get the height
%series = '63360'; %'25000' %Change this value to change the series.
series = '63360';
%series = '25000';

OSGeo_install_path = 'C:\Program Files\QGIS 2.18\bin\'; %The location of the gdal libraries 
%% Paths
%master_path = '/media/brodeujj/KINGSTON/AutoGeorefTests/';
if ispc==1
%master_path = ['E:\Users\brodeujj\GIS\OCUL Topo Project\AutoGeoRef\1_' series '\'];
tmp = pwd;
master_path = [tmp '\1_' series '\'];
zipflag = 1;
else
master_path = ['/media/Stuff/AutoGeoRef/1_' series '/'];
zipflag = 1;
end

%gcp_path = [master_path 'GCP-Upload/'];
%geotif_path = [master_path 'tif/'];
%qgis_gcp_path = [master_path 'GCP-QGIS\'];
tiles_path = [master_path 'tiles/'];
geotiff_path = [master_path 'geotiff/'];
t_srs='3857';
SRS_find_flag = 1;
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
if SRS_find_flag==1
fid_srs = fopen([master_path 'EPSG_Lookup_1_' series '.csv']);
tmp = textscan(fid_srs,'%s %s %s','Delimiter',',');
epsg_lookup(:,1) = tmp{1,1}(:,1);
epsg_lookup(:,2) = tmp{1,2}(:,1);
epsg_lookup(:,3) = tmp{1,3}(:,1);
fclose(fid_srs);
end

%%% get the directory listing in /geotif; pare down to a list of only tif files:
cd(geotiff_path);
tmp_dir = dir(geotiff_path);
d = struct;
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

%%% Load the variable 'h.mat' if it exists -- it contains the height
%%% information that we'll need (if 'identify' command isn't working):
% Column 1 of h is the .tif name; column 2 is the image height (in pixels)
%if h_loadflag==1 && exist([master_path 'h.mat'],'file')==2
%    load([master_path 'h.mat']);
%    h_all = h;
%else
%    h_all = {};
%    h_loadflag=0;
%end
%clear h;
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
   
   %%%% if SRS_find_flag==1, retrieve the proper input (and output) reference systems
        if SRS_find_flag==1
          try
            s_srs = epsg_lookup{strcmp(fname,epsg_lookup(:,1))==1,3};
          catch
          disp(['Could not find entry for ' fname ' in epsg_lookup.']);
          end
        else
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