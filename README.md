# CLOVER

# Overview
This repository includes all relevant custom R scripts, IJM scripts, and associated configuration files (R) for the CLOVER pipeline.
In addition, this repository includes all revelant custom R scripts for clustering IMC data from .mcd files.

# Input data
All raw MCD files, fully annotated data frame ("global_data.rds"), and example CLOVER plots ("ClusterPlot") are available at 10.5281/zenodo.16907810. 
"global_data.rds" contains a fully annotated data frame (data_full) that can be inputted into the R script "csvphenograph.R" or the R script "ClusterPlot.R".
In the 'Config' folder, there is a metadata, area, and merge (annotation) file necessary to generate clusters and plots.


# R scripts
The R script "csvphenograph.R" contains custom code to cluster out a dataset, visualize clusters via heatmaps, and save a dataframe containing associated clusters for each cell.
The R script "ClusterPlot.R" generates the minimal dataframe required to generate annotated or unannotated spatial cluster dot plots to be used further downstream as CLOVER plots.

# IJM scripts
The IJM scripts "Overlayer_AnnotatedClusters.ijm" and "Overlayer_UnannotatedClusters.ijm" contains custom code to overlay cluster plots on source images, generated CLOVER plots. 
"Overlayer_AnnotatedClusters.ijm" is better adapted for use with annotated cluster plots, while "Overlayer_UnannotatedClusters.ijm" is better adapted for use with unannotated cluster plots.
