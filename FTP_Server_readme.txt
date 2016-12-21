README FILE FOR OCUL Historical Topo Digitization Project (HTDP) FTP Server Directory

Created: 18-July, 2016
Last modified: 20-Dec, 2016

As of 18-July, 2016, there is a new structure to the directories in the OCUL HTDP FTP Server, to reflect the results of QA procedures.
A description of each top-level directory is included below: 

*Note: Processing scripts can be found here: https://github.com/jasonbrodeur/OCUL_HTDP

/tifs --> Contains the quality-assured 600 ppi uncompressed "archival quality" tif format images for the 1:63360 and 1:25000 series. All files in this directory have had GCP files created, and have been warped (with products files in /geotifs). The contents are subdivided into subdirectories for each of these series. 

/backup_tifs --> The pre-QA 600 ppi uncompressed "archival quality" tif format images, kept purely for backup purposes. All of this material is redundant and/or superseded by information in /tifs

/docs --> Documentation files, such as use agreements from LAC

/geotifs --> Location for georeferenced and transformed (projected) tif files. These are derivative, 300 ppi tif images created through GIS software using the original 600 ppi archival quality tifs and collaborator-created ground control point (GCP) files. 

/gcp --> Location for the ground control point (GCP) files that have been created for each map by project contributors. These GCP files correspond to 600 ppi tif files found in /tif. The contents are divided into subdirectories for 1:25000 and 1:63360 series. Within each series, separate folders exist for GCPs in ArcMap (/gcp-arc)and QGIS (/gcp-qgis) formats.

/backup_gcp/ --> Backups (old) versions of files found in /gcp. 

/IndexFiles --> Contains index shapefiles for 1:25000 and 1:63360 series.

/1_25000-Post1967 --> An upload directory for newly-scanned material, which is not currently incorporated into /tifs. Items in this folder are ready for georeferencing. 
Items are separated into two directories:
	The /Pre-QA directory is where newly-scanned, non-QA-passing tif files should be uploaded. GCPs should NOT be created for files in this folder. Once they are checked and pass QA, the files will be moved to the '/Post-QA' directory.
	The /Post-QA directory is where QA-passing tifs are moved after checking. GCP files should be created for all items within this directory. Following georeferencing and creation of geotiffs, items in this directory will be moved to /tifs.

/jpg --> Derivatives created from original 600 ppi images. Organized within by series (/1_25000, /1_63360). Within subfolders, the following folders exist, representing each derivative product:
	/small 	--> thumbnail JPG (204 pixel height) [thumbnail]
	/medium	--> medium JPG (2000 pixel height) [Could be useful for an Omeka-like item display page]
	/large 	--> 300 ppi JPG (20-30MB) [manageable-sized copy for general reference use]