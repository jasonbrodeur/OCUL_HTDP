## Technical reference
GDAL code to crop georeferenced map to extents of neatline:
```gdalwarp -t_srs EPSG:26717 -cutline cutline.csv -crop_to_cutline -dstalpha 030M12_1951ed2enad27.tif 030M12_1951ed2enad27_cropped_cutline_alpha.tif```

Where cutline.csv is a WKT-defined polygon (sample included in this folder), with contents of the form:
```
id,WKT
1,"POLYGON((601058.7200 4816884.6500,600640.7300 4844649.8100,620769.0700 4844983.9000,621270.7000 4817218.6100,601058.7200 4816884.6500))"
```



