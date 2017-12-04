%% count_gcps
% A silly little script to count the total # of gcps that were added.

cd('D:\Local\OCUL_HTDP\gcp-arc')
start_path = 'D:\Local\OCUL_HTDP\gcp-arc\';

d = dir([start_path '1_25000\']);
total_gcps = 0;
for i = 3:1:size(d,1)
    fid = fopen([start_path '1_25000\' d(i).name],'r');
   C = textscan(fid,'%s%s%s%s');
   
   fclose(fid);
   num_lines = size(C{1,1},1);
   total_gcps = total_gcps + num_lines;
   clear C num_lines
end

d2 = dir([start_path '1_63360\']);
total_gcps_63360 = 0;
for i = 3:1:size(d2,1)
    fid = fopen([start_path '1_63360\' d2(i).name],'r');
   C = textscan(fid,'%s%s%s%s');
   
   fclose(fid);
   num_lines = size(C{1,1},1);
   total_gcps_63360 = total_gcps_63360 + num_lines;
   clear C num_lines
end

total_gcps+total_gcps_63360;