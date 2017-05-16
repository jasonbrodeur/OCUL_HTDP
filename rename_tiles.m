% This function converts gdal tiles (in TMS format) to XYZ format.
clearvars;
top_path = 'D:\Local\Scratch\gdal_tests\'; % Top-level folder where directories exist for each sheet (e.g. this folder contains /030M05_1923, /030M11_1921, etc.)

% if exists([top_path 'tmp'],'dir')~=2
%     mkdir([top_path 'tmp']
d = dir(top_path); % create directory list

for i = 3:1:size(d,1)
    if d(i).isdir==1 && strcmp(d(i).name,'tmp')~=1 %only operate if this is a folder (and not the 'tmp' folder
        d2 = dir([top_path d(i).name]);
        for j = 3:1:size(d2,1) %cycle through each {z} level folder
            z_level = str2double(d2(j).name);
            d3 = dir([top_path d(i).name '\' d2(j).name]);
            for k = 3:1:size(d3,1)
                d4 = dir([top_path d(i).name '\' d2(j).name '\' d3(k).name]);
                for m = 3:1:size(d4,1)
                    [~,fname,ext] = fileparts(d4(m).name);
                    old_y = str2double(fname);
                    new_y = 2.^z_level - old_y - 1;
                    old_name = [top_path d(i).name '\' d2(j).name '\' d3(k).name '\' d4(m).name];
                    new_name = [top_path d(i).name '\' d2(j).name '\' d3(k).name '\' num2str(new_y) ext];
                    [SUCCESS,MESSAGE,MESSAGEID] = movefile(old_name,new_name);
                    if SUCCESS~=1
                        disp(['Issue renaming ' old_name '. Halting']);
                        break;
                    end
                end
            end
        end
        
    end
end