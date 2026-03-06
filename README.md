# CLOVER

# Overview
This repository includes all relevant custom R scripts, IJM scripts, and associated configuration files (R) for the CLOVER pipeline.
In addition, this repository includes all revelant custom R scripts for clustering IMC data from .mcd files.

# Input data
All raw MCD files, fully annotated data frame ("global_data.rds"), and example CLOVER plots ("CLOVERPlot") are available at 10.5281/zenodo.16907810. 
"global_data.rds" contains a fully annotated data frame (data_full) that can be inputted into the R script "csvphenograph.R" or the R script "CLOVERPlot.R".
In the 'Config' folder, there is a metadata, area, and merge (annotation) file necessary to generate clusters and plots.


# R scripts
The R script "csvphenograph.R" contains custom code to cluster out a dataset, visualize clusters via heatmaps, and save a dataframe containing associated clusters for each cell.
The R script "CLOVERPlot.R" generates the minimal dataframe required to generate annotated or unannotated spatial cluster dot plots to be used further downstream as CLOVER plots.

# IJM scripts
The IJM scripts "CLOVERLayer_AnnotatedClusters.ijm" and "CLOVERLayer_AnnotatedClusters.ijm" contains custom code to overlay cluster plots on source images, generating CLOVER plots. 
"CLOVERLayer_AnnotatedClusters.ijm" is better adapted for use with annotated cluster plots, while "CLOVERLayer_AnnotatedClusters.ijm" is better adapted for use with unannotated cluster plots.
