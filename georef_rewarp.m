function [logfile] = georef_rewarp(series_label, georef_list, clipping_flag)
% georef_rewarp.m
% This function runs through a collection of maps sheets (whether 1:25000 or 1:63360, as specified by series_label),
% looks for corresponding gcp files--and where they exist, performs georeferencing and georectification.
%%% inputs:
% series_label: string input for series scale -- either '25000' or '63360'
% georef_list: file name of a single column list of filenames for sheets to be processed (optional); file must exist in the master_path directory 
% (i.e. /AutoGeoref/1_25000/ or /AutoGeoref/1_63360/ 
% where georef_list is not provided, the function works through the entire 
% clipping_flag indicates whether or not a clipped (to the neatline) version should be created with the unclipped one. The clipped image is saved to /geotiff_clipped
%%%clipping_flag = 0 indicates no clipped image to be created, while clippeing_flag=1 causes a clipped image to be produced.

if nargin == 0
    disp(['The variable ''series_label'' needs to be set to ''63360'' or ''25000''. Exiting.']);
    break
elseif nargin == 1
    dir_flag = 1 % if only one argument (series label) is provided, then run through the entire /tif directory
    clipping_flag = 0;
elseif nargin ==2
    dir_flag = 0; % if a list is provided, the function will run through all filenames provided in the list.
    clipping_flag = 0;
else
    dir_flag = 0;
end

if isempty(georef_list)==1
dir_flag = 1;
end

%% Variables
% variables -- these could be set in a function call (since s_srs and t_srs may not be constant).
h_loadflag = 0; % flag to load image heights from variable 'h.mat'. When set to 1 it loads variables; otherwise, the script will use the imagemagick 'identify' command to get the height
ppi_in = 600; %native resolution of the images;
%ppi_in = 456.933;%600; %native resolution of the images;
ppi_out = 300; %output resolution for the transformed image;
gcp_fmt = '%f %f %f %f'; %input format for the Arc GCP files
%series_label = '63360'; %'25000' %Change this value to change the series.
%series_label = '25000';

%% Paths
%master_path = '/media/brodeujj/KINGSTON/AutoGeorefTests/';
if ispc==1
if exist('E:\Users\brodeujj\GIS\OCUL Topo Project\AutoGeoRef\','folder')==7
top_path = ['E:\Users\brodeujj\GIS\OCUL Topo Project\AutoGeoRef\'];
else
top_path = ['F:\OCUL_HTDP\AutoGeoRef\'];
end

master_path = [top_path '1_' series_label '\'];
else
top_path = ['/media/Stuff/AutoGeoRef/'];
master_path = [top_path '1_' series_label '/'];
end

gcp_path = [master_path 'GCP-Upload/'];
tif_path = [master_path 'tif/'];
qgis_gcp_path = [master_path 'GCP-QGIS/'];
tiles_path = [master_path 'tiles/'];

%% Series-specific settings:
switch series_label
  case '63360'
%  SRS_find_flag = 1;
    s_srs = ''; %This may have to be incorporated into a loop:
%    t_srs = {'3857';'3162'};%'EPSG:3162';% can be a cell array (gdalwarp loops through these)
    t_srs = {''}; % 
    geotiff_path = [master_path 'geotiff'];
  case '25000'
%    SRS_find_flag = 1; % Means that we'll need to pull the SRS info from a separate lookup table.
    s_srs = ''; %
    t_srs = {''}; % 
    geotiff_path = [master_path 'geotiff'];
  case '50000'
    s_srs = ''; %
    t_srs = {''}; % 
    geotiff_path = [master_path 'geotiff']; 
  
  otherwise
    disp(['The variable ''series_label'' needs to be set to ''63360'' or ''25000''. Exiting.']);
    break
end
geotiff_clipped_path = [master_path 'geotiff_clipped'];
    t_srs_tag = t_srs;
    
%% Make the output folders (if necessary):
for k = 1:1:length(t_srs)
  if exist([geotiff_path t_srs{k}])~=7
    if ispc==1; [status,cmdout] = dos(['mkdir "' geotiff_path t_srs{k} '"']); else [status,cmdout] = unix(['mkdir "' geotiff_path t_srs{k} '"']);end
      if status==0
      disp(['Created directory: ' geotiff_path t_srs{k}]);
      end
  end
  if exist([geotiff_clipped_path t_srs{k}])~=7
    if ispc==1; [status,cmdout] = dos(['mkdir "' geotiff_clipped_path t_srs{k} '"']); else [status,cmdout] = unix(['mkdir "' geotiff_clipped_path t_srs{k} '"']);end
      if status==0
      disp(['Created directory: ' geotiff_clipped_path t_srs{k}]);
      end
  end
end

%% If SRS_find_flag==1, we need to load a lookup table to connect the sheet to the proper coordinate reference system. Need to load it as a cell
% column 1 is the file name (no extension); column 2 is the EPSG number (number only, e.g. 26717)
% edit 20170127: using EPSG_Lookup.csv for all purposes now. No need for SRS_find_flag anymore (assumed to always be =1)
%if SRS_find_flag==1
fid_srs = fopen([top_path 'EPSG_Lookup_1_' series_label '.csv'],'r');
tmp = textscan(fid_srs,'%s %s %s','Delimiter',',','headerlines',1);
epsg_lookup(:,1) = tmp{1,1}(:,1);
epsg_lookup(:,2) = tmp{1,2}(:,1);
epsg_lookup(:,3) = tmp{1,3}(:,1);
fclose(fid_srs);
%end
clear tmp;

%%% Load in the NTS lookup table (to get extents for the sheet, to be used in clipping).
% Sheet | East | West | South | North
fid_nts = fopen([top_path 'NTS_TopoCorners_1_' series_label '.csv'],'r');
tmp = textscan(fid_nts,'%s %s %s %s %s','Delimiter',',','headerlines',1);
nts_lookup(:,1) = tmp{1,1}(:,1); % sheet
nts_lookup(:,2) = tmp{1,2};%(:,1); % east
nts_lookup(:,3) = tmp{1,3}(:,1); % west
nts_lookup(:,4) = tmp{1,4}(:,1); % south
nts_lookup(:,5) = tmp{1,5}(:,1); % north
fclose(fid_nts);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% get the directory listing in /tif; pare down to a list of only tif files:
cd(tif_path);
d = struct; 

if dir_flag==1
tmp_dir = dir(tif_path);
else
% load the processing list:
fid_list = fopen([master_path georef_list]);
tmp_dir = struct;
tmp = textscan(fid_list, '%s','Delimiter',',');
  for i = 1:1:size(tmp{1,1},1)
  tmp_dir(i).name = tmp{1,1}{i,1};
  tmp_dir(i).isdir = 0;
  end
  fclose(fid_list);
end

ctr = 1;
for i = 1:1:length(tmp_dir)
    [fdir, fname, fext] = fileparts(tmp_dir(i).name); %file directory | filename | file extension
    if tmp_dir(i).isdir==0 && strcmp(fext,'.tif')==1 % If we're dealing with a tif file:
        d(ctr).name =  tmp_dir(i).name;
        ctr = ctr+1;
    else
    end
end
clear tmp_dir;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Load the variable 'h.mat' if it exists -- it contains the height
%%% information that we'll need (if 'identify' command isn't working):
% Column 1 of h is the .tif name; column 2 is the image height (in pixels)
if h_loadflag==1 && exist([master_path 'h.mat'],'file')==2
    load([master_path 'h.mat']);
    h_all = h;
else
    h_all = {};
    h_loadflag=0;
end
clear h;

logfile = cell(length(d),2);
%% Cycle through the tif files:
for i = 1:1:length(d)
    % get the filename of the tif file:
    filename_in = d(i).name;
    [fdir, fname, fext] = fileparts(filename_in); %file directory | filename | file extension
    logfile{i,1} = filename_in;
    
    % Attempt to pull out the year of publication from the filename (should be the first four characters after the first "_")
    uscores = strfind(fname,'_');
    pubyear_str = fname(uscores(1)+1:uscores(1)+4);
    disp(['Publication year is ' pubyear_str ]);
    pubyear = str2double(pubyear_str);
    sheetname = fname(1:uscores(1)-1);
    
    % look for the corresponding GCP file in the gcp directory (named the same but with .txt extension)
    if exist([gcp_path fname '.txt'],'file')==2
    disp(['Now working on file: ' filename_in]);
        
        %%%% Get image size (using imagemagick 'identify' command or from loaded 'h.mat' variable):
        if h_loadflag==1
            try
                h = h_all{strcmp(filename_in,h_all(:,1))==1,2};
            catch
                disp(['Could not find entry for ' filename_in ' in h_all.']);
                h = 0;
            end
        else
            cmd = ['identify -quiet -format "%h" ' filename_in];
            cmd2 = ['identify -quiet -format "%y" ' filename_in];
            %%% Note to self, need to add a query for resolution identify -quiet -format "%y"
            if ispc==1; [status,cmdout] = dos(cmd); else [status,cmdout] = unix(cmd);end
            h = str2double(cmdout); %height of the tif in pixels
            if ispc==1; [status2,cmdout2] = dos(cmd2); else [status2,cmdout2] = unix(cmd2);end
            ppi_in = str2double(cmdout2); %resolution of the tif (in points per inch)
            ppi_out = ppi_in./2;
        end
        
        if isempty(h)==1 || h==0
            disp(['Could not get the image height for: ' filename_in '. Skipping.']);
            logfile{i,2} = 'height';
            continue
        end
        
        %%%% if SRS_find_flag==1, retrieve the proper input (and output) reference systems
%        if SRS_find_flag==1
          try
            s_srs = epsg_lookup{strcmp(fname(1:4),epsg_lookup(:,1))==1,2};
            t_srs{1,1} = epsg_lookup{strcmp(fname(1:4),epsg_lookup(:,1))==1,3};
            t_srs_tag = {''};
          catch
          disp(['Could not find entry for ' fname(1:4) ' in epsg_lookup.']);
          end
%        else
%        end
        
        if isempty(s_srs)==1
            disp(['Could not get info from epsg_lookup for: ' fname(1:4) '. Skipping.']);
            logfile{i,2} = 'epsg_lookup';
            continue
        end
        
        %%%% For 1:50000 sheets only -- modify the s_srs to the NAD83 srs if the sheet pubyear is post-1984 AND we're using a UTM projection.
        switch series_label
          case '50000'
          if length(s_srs)==5 & strncmp(s_srs,'26',2)==1 & pubyear > 1984
          disp(['modifying source srs from ' s_srs ' to ' num2str(str2double(s_srs)+200)]);
          s_srs = num2str(str2double(s_srs)+200);
          end
        end
        
%        if exist([gcp_path fname '.txt'],'file')~=2
%            disp(['Could not find the gcp file for ' fname '. Skipping.']);
%            logfile{i,2} = 'gcp_file';
%            continue
%        end
        
        % Read the GCP file:
        fid = fopen([gcp_path fname '.txt'],'r');
        C_tmp = textscan(fid,gcp_fmt,'delimiter','\t');
        C = cell2mat(C_tmp); %convert from cell array into a matrix
        fclose(fid)
        
        %%% Put something in here that will take a look at the number of points in the GCP file, and decide which transformation to use:
        if size(C,1)>6; trans_order = '2'; else trans_order = '1'; end
        
        % format of C:
        % x (inches right) | y (inches up) | x_map (lng) | y_map (lat)
        x = C(:,1);
        y = C(:,2);
        lng = C(:,3);
        lat = C(:,4);
        
%        % Extract the four extents from the long and lat category (we'll use this for clipping the image to the neatline)
%        % We've also made an assumption here that at least one GCP exists on each of the margins.
%        lng_min = num2str(min(lng)); lng_max = num2str(max(lng));
%        lat_min = num2str(min(lat)); lat_max = num2str(max(lat));
%        
        
        %Create the qgis .points file:
        fid_qgis = fopen([qgis_gcp_path filename_in '.points'],'w');
        fprintf(fid_qgis,'%s\n','mapX,mapY,pixelX,pixelY,enable');
        fclose(fid_qgis);
        
        %%% Create format for qgis file:
        C_QGIS = [lng lat x.*ppi_in (y.*ppi_in)-h ones(length(x),1)];
        dlmwrite([qgis_gcp_path filename_in '.points'],C_QGIS,"-append");
        
       %% Extract the extents of the map in the four cardinal directions. We need this in lat/long, so we'll need to find it in the lookup table.
       right_row = find(strcmp(sheetname,nts_lookup(:,1))==1);
       lng_max = str2double(nts_lookup{right_row,2});
       lng_min = str2double(nts_lookup{right_row,3});
       lat_min = str2double(nts_lookup{right_row,4});
       lat_max = str2double(nts_lookup{right_row,5});
       
        switch fname(end)
          case 'E'
          lng_min = lng_min + (lng_max - lng_min)./2;
          case 'W'
          lng_max = lng_max - (lng_max - lng_min)./2;
          otherwise
        end
        
        % Set the coordinate system for clipping (according to publication year)
        if pubyear > 1984 
        te_srs = '4269';
        else
        te_srs = '4267';
        end
        
        %%% Generate gdal_translate string
        % ratio of ppi_out to ppi_in
        out_ratio = ppi_out./ppi_in;
        out_pct = round(out_ratio*10000)./100;
        disp(['out_ratio is: ' num2str(out_ratio) '. out_pct = ' num2str(out_pct)]);
%        C_GDAL = [x*ppi_out (h./2)-(y*ppi_out) lng lat];
        C_GDAL = [x*ppi_out (h.*out_ratio)-(y*ppi_out) lng lat];
        gdal_str = '';
        for j = 1:1:size(C_GDAL,1)
            gdal_str = [gdal_str '-gcp ' num2str(C_GDAL(j,1),8) ' ' num2str(C_GDAL(j,2),8) ' ' num2str(C_GDAL(j,3),8) ' ' num2str(C_GDAL(j,4),8) ' '];
        end
        %last line:
        %gdal_str = [gdal_str '-gcp ' num2str(C_GDAL(j,1)) ' ' num2str(C_GDAL(j,2)) ' ' num2str(C_GDAL(j,3)) ' ' num2str(C_GDAL(j,4))];
        
        %%% Try and execute GDAL translate command:
        gdal_trans_cmd = ['gdal_translate -q -of GTiff -outsize ' num2str(out_pct) '% ' num2str(out_pct) '% ' gdal_str '"' tif_path filename_in '" "' master_path 'tmp.tif"'];
        disp(gdal_trans_cmd);
        disp(['Running gdal_translate on ' filename_in '.']);
        if ispc==1; 
        gdal_trans_cmd = ['C:\OSGeo4W64\bin\' gdal_trans_cmd];
        [status_trans] = dos(gdal_trans_cmd); 
        else [status_trans] = unix(gdal_trans_cmd);
        end
        
        if status_trans~=0
            disp(['gdal_translate failed for: ' filename_in '. Skipping.']);
            logfile{i,2} = 'gdal_translate';
            continue
        end
        
        %%% Try the gdalwarp command:
        for k = 1:1:length(t_srs)
          gdalwarp_cmd = ['gdalwarp -overwrite -q -r cubicspline -s_srs EPSG:' s_srs ' -t_srs EPSG:' t_srs{k} ' -order ' trans_order ' -co COMPRESS=NONE -dstalpha "' master_path 'tmp.tif" "'...
              geotiff_path t_srs_tag{k} '/' filename_in '"'];
          disp(['Running gdalwarp on ' filename_in '.']);
          
          if ispc==1; 
          gdalwarp_cmd = ['C:\OSGeo4W64\bin\' gdalwarp_cmd];
          [status_warp, msg_warp] = dos(gdalwarp_cmd); 
          else [status_warp] = unix(gdalwarp_cmd);
          end
          
          if status_warp~=0
              disp(['gdalwarp failed for: ' filename_in '. Skipping.']);
              logfile{i,2} = 'gdalwarp';
              continue
          
          end
          disp(['Transformation of ' filename_in ' was successful.']);
          logfile{i,2} = 'clear!';
          
          %%% if clipping_flag==1, run gdalwarp command again, but clip to the neatline.
          if clipping_flag==1
          gdalwarp_cmd2 = ['gdalwarp -overwrite -q -r cubicspline -s_srs EPSG:' s_srs ' -t_srs EPSG:4269 -te ' num2str(lng_min) ' ' num2str(lat_min) ' ' num2str(lng_max) ' ' num2str(lat_max) ' -te_srs EPSG:' te_srs ' -order ' trans_order ' -co COMPRESS=NONE -dstalpha "' master_path 'tmp.tif" "' geotiff_clipped_path t_srs_tag{k} '/' filename_in '"'];
%          gdalwarp_cmd2 = ['gdalwarp -overwrite -q -r cubicspline -s_srs EPSG:' s_srs ' -t_srs EPSG:' t_srs{k} ' -te ' num2str(lng_min) ' ' num2str(lat_min) ' ' num2str(lng_max) ' ' num2str(lat_max) ' -te_srs EPSG:' te_srs ' -order ' trans_order ' -co COMPRESS=NONE -dstalpha "' master_path 'tmp.tif" "' geotiff_clipped_path t_srs_tag{k} '/' filename_in '"'];    
          
          disp(['Running gdalwarp (clipped) on ' filename_in '.']);
          
          if ispc==1; 
          gdalwarp_cmd2 = ['C:\OSGeo4W64\bin\' gdalwarp_cmd2];
          [status_warp2, msg_warp2] = dos(gdalwarp_cmd2); 
          else [status_warp] = unix(gdalwarp_cmd2);
          end
          
          if status_warp2~=0
              disp(['gdalwarp (clipped) failed for: ' filename_in '. Skipping.']);
              %logfile{i,2} = 'gdalwarp';
              continue
          end
          

          end
          
        end
        
    else
        disp(['Could not find the gcp file for: ' filename_in '. Breaking loop.']);
        logfile{i,2} = 'no_gcp';
        continue
    end
    
end

%%% Save the log file: 
fid = fopen([master_path 'logfile_' datestr(now,30) '.txt'],'w+');
for i = 1:1:size(logfile,1)
fprintf(fid,'%s\t %s\n',logfile{i,:});
end
fclose(fid)