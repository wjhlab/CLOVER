# WJH Lab and Wood Lab 
# Jessie Kanacharoen

#Turn dev off
while (!is.null(dev.list())) {
  dev.off()
}

# Download packages
library(ggplot2); library(ragg); library(dplyr); library(readxl)

#Set up levels - user needs to update these inputs ======
samplevels=c("Grp2ROI1", "Grp3ROI2", "Grp5ROI2", "Grp7ROI3")


###### Generate Cluster Plots for UNANNOTATED CLUSTERS - START HERE ##############
##Set up cluster levels
unannotatedclusterlevels <- 1:length(unique(data_full$cluster))

#load RDS (previously saved data_full)
global_data<-readRDS("global_data.RDS")
data_full <- data.frame(global_data[1])

#cleanpanel.xlsx should be comprised of project-specific IMC markers - user needs to update this
cleanpanel <- read_xlsx('cleanpanel.xlsx')
markerlist <- cleanpanel$clean_names[cleanpanel$subtype == 1]
data_xy <- data_full %>% select(sample_id, CellId, cluster, cluster1m, X_coord, Y_coord)

#Specifically for visualizing unannotated clusters
data_xy <- data_xy %>% rename(cluster_num = cluster)

#To store failed ROI names
error_list <- c()

#Rename unannotated cluster column to 'cluster_num'
cluster_num <- unannotatedclusterlevels


#Cluster Plot loop
for (targetROI in samplevels) {
  cat("Processing:", targetROI, "\n")
  
  for (cluster_name in cluster_num) {
    tryCatch({
      filtered_data <- data_xy %>%
        filter(sample_id == targetROI, cluster_num == cluster_name)
      
      if (nrow(filtered_data) == 0) next
      
      pointplot <- ggplot(filtered_data, aes(x = X_coord, y = -Y_coord)) +
        geom_point(color = "white", size = 0.2) +
        theme_void() +
        scale_x_continuous(limits = c(0, 1000)) +
        scale_y_continuous(limits = c(-1000, 0)) +
        theme(
          plot.margin = unit(c(-5, -5, -5, -5), "mm"),
          plot.background = element_blank(),
          panel.background = element_blank(),
          axis.title = element_blank(),
          axis.text = element_blank(),
          axis.ticks = element_blank()
        )
      
      # Create folder path
      folder_path <- file.path("CLOVER_ClusterPlots", targetROI)
      if (!dir.exists(folder_path)) dir.create(folder_path, recursive = TRUE)
      
      # Build filename
      cluster_suffix <- tolower(cluster_name)
      filename <- file.path(folder_path, paste0(cluster_suffix, ".tiff"))
      
      # Export TIFF
      # Save using ragg::agg_tiff (supports transparency) ###User - revise width and height settings to appropriate size of ROI
      ragg::agg_tiff(filename = filename, width = 1000, height = 1000, units = "px", bg = "transparent", compression = "none", res = 300)
      print(pointplot)
      dev.off()
      
    }, error = function(e) {
      warning(paste("Error with", targetROI, "-", cluster_name, ":", e$message))
      error_list <<- c(error_list, paste(targetROI, cluster_name, sep = "_"))
    })
  }
}

if (length(error_list) > 0) {
  cat("Errors occurred in the following ROIs/clusters:\n")
  print(error_list)
} else {
  cat("Yay! All plots generated successfully.\n")
}




###### Generate Cluster Plots for ANNOTATED CLUSTERS  - START HERE ##############

##Set up cluster levels - user needs to update input of project-unique clusters here
annotatedclusterlevels=c("Endoth",
                         "Gran",
                         "Mac",
                         "Myeloid",
                         "Stroma",
                         "Tc",
                         "Th",
                         "Tumor",
                         "UA")


#load RDS (previously saved data_full)
global_data<-readRDS("global_data.RDS")
data_full <- data.frame(global_data[1])

#cleanpanel.xlsx should be comprised of project-specific IMC markers - user needs to update this
cleanpanel <- read_xlsx('cleanpanel.xlsx')
markerlist <- cleanpanel$clean_names[cleanpanel$subtype == 1]
data_xy <- data_full %>% select(sample_id, CellId, cluster, cluster1m, X_coord, Y_coord)

# Define mapping of subclusters to main clusters for ease of viewing - user needs to update these inputs
cluster_mapping <- list(
  "Gran" = startsWith(annotatedclusterlevels, "Gran"),
  "Mac" = startsWith(annotatedclusterlevels, "Mac"),
  "Myeloid" = startsWith(annotatedclusterlevels, "Myeloid"),
  "Tc" = startsWith(annotatedclusterlevels, "Tc"),
  "Th" = startsWith(annotatedclusterlevels, "Th"),
  "Treg" = startsWith(annotatedclusterlevels, "Treg"),
  "Str" = startsWith(annotatedclusterlevels, "Stroma"),
  "Tumor" = startsWith(annotatedclusterlevels, "Tumor"),
  "Endoth" = startsWith(annotatedclusterlevels, "Endoth")
)

# Assign each cluster to its main group
main_clusters <- sapply(annotatedclusterlevels, function(x) {
  matched_cluster <- names(cluster_mapping)[unlist(lapply(cluster_mapping, function(y) x %in% annotatedclusterlevels[y]))]
  if (length(matched_cluster) == 1) {
    return(matched_cluster)
  } else {
    return(x)  # If no match, keep original cluster name
  }
})

#Specifically for visualizing annotated clusters
data_xy <- data_xy %>% rename(main_cluster = cluster1m)


# Ensure main_clusters is named correctly and matches the data frame's cluster column - user needs to update these inputs
main_clusters <- c("Gran",
                   "Mac",
                   "Myeloid",
                   "Tc",
                   "Th",
                   "Stroma",
                   "Tumor",
                   "Endoth",
                   "UA")

# To store failed ROI names
error_list <- c()

# Define clusters and corresponding colors - user needs to update these inputs
cluster_colors <- list("Gran" = "magenta",
                       "Mac" = "yellow",
                       "Myeloid" = "yellow",
                       "Tc" = "green",
                       "Th" = "green",
                       "Stroma" = "cyan",
                       "Tumor" = "blue",
                       "Endoth" = "red",
                       "UA" = "white")

#Cluster Plot loop
for (targetROI in samplevels) {
  cat("Processing:", targetROI, "\n")
  
  for (cluster_name in main_clusters) {
    tryCatch({
      filtered_data <- data_xy %>%
        filter(sample_id == targetROI, main_cluster == cluster_name)
      
      if (nrow(filtered_data) == 0) next
      
      pointplot <- ggplot(filtered_data, aes(x = X_coord, y = -Y_coord)) +
        geom_point(color = cluster_colors[[cluster_name]], size = 0.2) +
        theme_void() +
        scale_x_continuous(limits = c(0, 1000)) +
        scale_y_continuous(limits = c(-1000, 0)) +
        theme(
          plot.margin = unit(c(-5, -5, -5, -5), "mm"),
          plot.background = element_blank(),
          panel.background = element_blank(),
          axis.title = element_blank(),
          axis.text = element_blank(),
          axis.ticks = element_blank()
        )
      
      # Create folder path
      folder_path <- file.path("CLOVER_ClusterPlots", targetROI)
      if (!dir.exists(folder_path)) dir.create(folder_path, recursive = TRUE)
      
      # Build filename
      cluster_suffix <- tolower(cluster_name)
      filename <- file.path(folder_path, paste0(cluster_suffix, ".tiff"))
      
      # Export TIFF
      # Save using ragg::agg_tiff (supports transparency) ###User - revise width and height settings to appropriate size of ROI
      ragg::agg_tiff(filename = filename, width = 1000, height = 1000, units = "px", bg = "transparent", compression = "none", res = 300)
      print(pointplot)
      dev.off()
      
    }, error = function(e) {
      warning(paste("Error with", targetROI, "-", cluster_name, ":", e$message))
      error_list <<- c(error_list, paste(targetROI, cluster_name, sep = "_"))
    })
  }
}

if (length(error_list) > 0) {
  cat("Errors occurred in the following ROIs/clusters:\n")
  print(error_list)
} else {
  cat("Yay! All plots generated successfully.\n")
}
