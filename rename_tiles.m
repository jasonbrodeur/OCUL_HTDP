% This function converts gdal tiles (in TMS format) to XYZ format.
clearvars;
top_path = 'D:\Local\Scratch\gdal_tests\'; % Top-level folder where directories exist for each sheet (e.g. this folder contains /030M05_1923, /030M11_1921, etc.)

% if exists([top_path 'tmp'],'dir')~=2
%     mkdir([top_path 'tmp']
d = dir(top_path); % create directory listing of top-level directory

for i = 3:1:size(d,1) % run through top-level directories; if it's a folder, then continue
    if d(i).isdir==1 && strcmp(d(i).name,'tmp')~=1 %only operate if this is a folder (and not the 'tmp' folder)
        d2 = dir([top_path d(i).name]); % directory listing for all items in the top-level directories (i.e. an individual map sheet)
        for j = 3:1:size(d2,1) %cycle through each {z}-level folder. 
            if d2(j).isdir==1 %%% Only proceed for {z}-level directories (avoid other files)
                z_level = str2double(d2(j).name); 
                d3 = dir([top_path d(i).name '\' d2(j).name]); % directory listing for all items in {z} level folder (i.e. {x}-level directories)
                for k = 3:1:size(d3,1) %cycle through each {x}-level folder
                    d4 = dir([top_path d(i).name '\' d2(j).name '\' d3(k).name]); % directory listing for all items in {x}-level folder (i.e {y}-level directories).
                    for m = 3:1:size(d4,1) %cycle through each {y}-level folder - rename files
                        [junk,fname,ext] = fileparts(d4(m).name);
                        old_y = str2double(fname); % original name
                        new_y = 2.^z_level - old_y - 1; % rename folder by flipping the zero-point on the y-axis
                        old_name = [top_path d(i).name '\' d2(j).name '\' d3(k).name '\' d4(m).name];
                        new_name = [top_path d(i).name '\' d2(j).name '\' d3(k).name '\' num2str(new_y) ext];
                        [SUCCESS,MESSAGE,MESSAGEID] = movefile(old_name,new_name); %rename the file.
                        if SUCCESS~=1
                            disp(['Issue renaming ' old_name '. Halting']);
                            break;
                        end
                    end
                end
            end
        end
    end
end