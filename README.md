# CLOVER

# Overview
This repository includes all relevant custom R scripts and associated configuration files for the CLOVER pipeline.
In addition, this repository includes all revelant custom R scripts for clustering IMC data from .mcd files.

# Input data
All raw MCD files and fully annotated data frame ("global_data.rds") are available at 10.5281/zenodo.16907810. 
"global_data.rds" contains a fully annotated data frame (data_full) that can be inputted into the R script "csvphenograph.R" or the R script "ClusterPlot.R".
In the 'Config' folder, there is a metadata, area, and merge (annotation) file necessary to generate clusters and plots.

# R scripts
The R script "csvphenograph.R" contains custom code to cluster out a dataset, visualize clusters via heatmaps, and save a dataframe containing associated clusters for each cell.
The R script "ClusterPlot.R" generates the minimal dataframe required to generate spatial cluster dot plots to be used further downstream as CLOVER plots based on the data_full dataframe.
