# OCUL_HTDP_AutomatedTools
This repository contains functions and scripts used for automated processing digitized 1:25000 and 1:63360 scale map sheets, as part of the OCUL-funded Historical Topographic Map Digitization Project, carried out by the Ontario Council of University Libraries (OCUL) Geo Community. 

Currently all functions/scripts have been written in the Octave/Matlab language.

##Function list
The included functions/scripts:
1. georef_rewarp: function to georeference original 600 ppi tifs and produce georectified 300 ppi geotifs 
2. create_webtiles: script to generate webtiles from georectified images 
3. create_derivatives: function to create derivative files (thumbs, medium, large) from original 600 ppi tif files 


##Dependencies: 
The functions require installation on one/all of the following libraries:
* Python version 2.7+
* gdal version 2+
* imagemagick version 7+ 
