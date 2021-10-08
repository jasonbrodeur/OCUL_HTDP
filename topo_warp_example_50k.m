cd('/media/Stuff/Working/50k-topos/150K Sample')


epsg_code = 26717; % AD_1927_UTM_Zone_17N
filename_in = '030M11_1985ed7.jpg';
filename_out = '030M11_1985ed7-jay.tif';
gcp_path = '030M11_1985ed7.txt';

ppi_in = 300; %native resolution of the images;
ppi_out = 300; %output resolution for the transformed image;
gcp_fmt = '%f %f %f %f %f %f %f'; %input format for the GCP files

s_srs = num2str(epsg_code); % Source srs
t_srs = num2str(epsg_code); % Target srs

%%% Do we need the corners of the sheet?

##cmd = ['identify -quiet -format "%h" ' filename_in];
##cmd2 = ['identify -quiet -format "%y" ' filename_in];
%%% Note to self, need to add a query for resolution identify -quiet -format "%y"
##if ispc==1; [status,cmdout] = dos(cmd); 
##else [status,cmdout] = unix(cmd);
##end
##h = str2double(cmdout); %height of the tif in pixels
##if ispc==1; [status2,cmdout2] = dos(cmd2);
##else [status2,cmdout2] = unix(cmd2);
##end
##ppi_in = str2double(cmdout2); %resolution of the tif (in points per inch)
##ppi_out = ppi_in./2;
h = 8412; 
ppi_in = 300;
ppi_out = 300;
% From gdalinfo, Size is 12032, 8412

% Read the GCP file:
        fid = fopen([gcp_path],'r');
        tmp = fgetl(fid);
        C_tmp = textscan(fid,gcp_fmt,'delimiter','\t');
        C = cell2mat(C_tmp); %convert from cell array into a matrix
        fclose(fid)
        
        %%% Put something in here that will take a look at the number of points in the GCP file, and decide which transformation to use:
        if size(C,1)>6; trans_order = '2'; else trans_order = '1'; end
        
        % format of C:
        % x (inches right) | y (inches up) | x_map (lng) | y_map (lat)
        y = C(:,2);
        x = C(:,3);
        lng = C(:,5)/100; % Easting
        lat = C(:,4)/100; % Northing
        out_pct = 100;
C_GDAL = [x y lng lat];
gdal_str = '';
        for j = 1:1:size(C_GDAL,1)
            gdal_str = [gdal_str '-gcp ' num2str(C_GDAL(j,1),8) ' ' num2str(C_GDAL(j,2),8) ' ' num2str(C_GDAL(j,3),8) ' ' num2str(C_GDAL(j,4),8) ' '];
        end
        
gdal_trans_cmd = ['gdal_translate -q -of GTiff -outsize ' num2str(out_pct) '% ' num2str(out_pct) '% ' gdal_str '"' filename_in '" "' 'tmp.tif' '"'];
        disp(gdal_trans_cmd);
        disp(['Running gdal_translate on ' filename_in '.']);
        if ispc==1; 
        gdal_trans_cmd = ['C:\OSGeo4W64\bin\' gdal_trans_cmd];
        [status_trans] = dos(gdal_trans_cmd); 
        else [status_trans] = unix(gdal_trans_cmd);
      end        
      
%%% Try the gdalwarp command:

  gdalwarp_cmd = ['gdalwarp -overwrite -q -r cubicspline -s_srs EPSG:' s_srs ' -t_srs EPSG:' t_srs ' -order ' trans_order ' -co COMPRESS=NONE -dstalpha "tmp.tif" "' filename_out '"'];
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
    
