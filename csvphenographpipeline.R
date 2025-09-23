# WJH Lab and Wood Lab 
# Sarah Shin

rm(list = ls())

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
work<-getwd()

metaDataFile = paste0(work,"/Config/metadata.xlsx")
dataDirectory = paste0(work,"/Data")

require(scales);require(readxl);require(plyr);require(dplyr);require(DataEditR); 
require(Rphenograph);require(Hmisc); require(ComplexHeatmap); require(pals); require(matrixStats);
require(reshape2); require(ggplot2); require(ggpubr)

#load RDS if previously saved, run code from line #67 to 79, then skip to line #96
global_data<-readRDS("global_data.RDS")
data_full <- data.frame(global_data[1])
data <- data.matrix(global_data[2])
data01 <- data.frame(global_data [3])
csv_full <- data.frame(global_data[4])


#Set up levels ======
samplevels=c("Grp2ROI1", "Grp3ROI2", "Grp5ROI2", "Grp7ROI3")

grouplevels=c("Group 2", "Group 3", "Group 5", "Group 7")

## Read-in metadata and clean, add in additional columns if needed =======
ifelse(grepl(metaDataFile,pattern='.xlsx'),md <- read_excel(metaDataFile),md <- read.csv(metaDataFile,header = TRUE))#must be in xl format or csv
md$file_name <- factor(md$file_name)
md$sample_id <- factor(md$sample_id, levels=samplevels)
md$Group <- factor(md$Group)

##input image id into metadata
image_id<-c()
for (i in 1:length(md$file_name)){
  tempfile <- read.csv(paste0(dataDirectory,"/",md$file_name[i]))
  df<- as.data.frame(cbind(paste0(md$file_name[i]), unique(tempfile$ImageId)))
  image_id<-rbind(image_id,df)
}
md$ImageId <- image_id$V2[match(image_id$V1,md$file_name)]


## QC Check - Make sure all files in metadata are present in datadirectory
if(!all(md$file_name %in% list.files(dataDirectory)[grep(list.files(dataDirectory),pattern = '.csv')])){
  print(paste('ERR: not all filenames in metadata present in data folder - missing',
              md$file_name[!which(data$file_name %in% list.files(dataDirectory)[grep(list.files(dataDirectory),
                                                                                   pattern = '.csv')])],'Subsetting...'))
  md <- md[-c(!which(md$file_name %in% list.files(dataDirectory)[grep(list.files(dataDirectory),pattern = '.csv')])),]
}


## Read csv into csv_raw =========
csv_raw <- lapply(paste0(dataDirectory,"/",md$file_name),read.csv)
csv_raw_full <- plyr::ldply(csv_raw, rbind)
csv_raw_full$ImageId <- md$sample_id[match(csv_raw_full$ImageId,md$ImageId)]

#export raw channel names to clean/rename panel + rename ImageId as sample_id
#Ignore 'Error in colSums(csv_raw_full): 'x' must be numeric
rawcolnames <- c()
rawcolnames$name <- colnames(csv_raw_full)
rawcolnames$sum <- colSums(csv_raw_full)
write.csv(rawcolnames, 'rawpanel.csv')

#clean panel by creating new 'cleanpanel.xlsx' file and adding new columns for cleaned up marker names + selecting which markers to use for clustering/subclustering
cleanpanel <- read_xlsx('cleanpanel.xlsx')
colnames(csv_raw_full) <- cleanpanel$clean_names
panel <- cleanpanel$clean_names[cleanpanel$analysis > 0]
csv_full <- csv_raw_full[,colnames(csv_raw_full) %in% panel]

#Once cleanpanel.xlsx is generated and cleaned, run this line
panelDataFile = paste0(work,"/cleanpanel.xlsx")

#sort panels into different categories
subtype_markers <- cleanpanel$clean_names[cleanpanel$subtype == 1]
functional_markers <- cleanpanel$clean_names[cleanpanel$functional == 1]
cluster_by <- cleanpanel$clean_names[cleanpanel$cluster_by == 1]
otherparameters <- cleanpanel$clean_names[cleanpanel$other ==1]


#Cluster heatmap for unannotated clusters======
data_full <- csv_full
data <- data.matrix(csv_full[,-1])
data <- asinh(data[, union(subtype_markers,functional_markers)] / 0.8)

#phenograph clustering of data
rng <- colQuantiles(data, probs = c(0.01, 0.99))
data01 <- t((t(data) - rng[, 1]) / (rng[, 2] - rng[, 1]))
data01[data01 < 0] <- 0; data01[data01 > 1] <- 1;data01 <-data01[,union(subtype_markers,functional_markers)]

set.seed(1234)
phenographout<-Rphenograph(data01)
data_full$cluster<-factor(membership(phenographout[[2]]))

cluster_mean <- data.frame(data01, cluster = data_full$cluster, check.names = FALSE) %>%
  group_by(cluster) %>% summarize_all(list(mean))

cluster_mean_mat<-as.matrix(cluster_mean[,union(subtype_markers,functional_markers)])

rownames(cluster_mean_mat)<-1:nrow(cluster_mean_mat)

cluster_scaled<-t(scale(t(cluster_mean_mat)))

rownames(cluster_scaled)<-1:nrow(cluster_scaled)

#save as RDS file
global_data <- list(data_full, data, data01, csv_full)
saveRDS(global_data, "global_data.RDS")

## Annotation for the original clusters
annotation_row <- data.frame(Cluster = factor(cluster_mean$cluster))
rownames(annotation_row) <- rownames(cluster_mean)
color_clusters1 <- kovesi.rainbow_bgyrm_35_85_c69(nlevels(annotation_row$Cluster))
names(color_clusters1) <- levels(annotation_row$Cluster)
annotation_colors <- list(Cluster = color_clusters1)

## Colors for the heatmap
legend_breaks = seq(from = 0, to = 1, by = 0.2)
colorassigned<-kovesi.rainbow_bgyrm_35_85_c69(length(unique(cluster_mean$cluster)))
names(colorassigned)<- sort(unique(cluster_mean$cluster))
color_list = list(clusters=colorassigned)
color_list_byoriginal = colorassigned[match((cluster_mean$cluster),names(colorassigned))]

rAbar<-rowAnnotation(clusters=cluster_mean$cluster,
                     col=color_list,
                     gp = gpar(col = "white", lwd = .5),
                     counts= anno_barplot(
                       as.vector(table(data_full$cluster)),
                       gp = gpar(fill=colorassigned),
                       border = F,
                       bar_width = 0.75, 
                       width = unit(2,"cm")))


pdf("clusterheatmap_unannotated.pdf",width=10,height=8)
Heatmap(cluster_scaled,
        column_title="Phenograph Clusters",
        name = "scaled",
        col=rev(brewer.rdbu(100)),
        cluster_columns = T,
        cluster_rows = T,
        border = NA,
        rect_gp = gpar(col = "white", lwd = .5),
        right_annotation = rAbar,
        show_row_names = T,
        row_names_gp = gpar(fontsize=7),
        column_names_gp = gpar(fontsize=10),
        heatmap_legend_param = list(at=seq(from = round(min(cluster_scaled)), to = round(max(cluster_scaled)))),
        width = ncol(cluster_scaled)*unit(4, "mm"), 
        height = nrow(cluster_scaled)*unit(4, "mm"))
dev.off() 



#######CLUSTER ANNOTATIONS
#annotate each cluster based on expression, add in annotated clusters + respective cluster number in merge.xlsx ===========
clusterMergeFile = paste0(work,"/Config/merge.xlsx") #create a column of clusters numbered + another column of respective annotation
cluster_merging <- read_excel(clusterMergeFile)


#Annotations based on cluster heatmap alone - iffy clusters were annotated accordingly and identified after unannotated image stack
clusterlevels=c("Endoth",
                "Gran",
                "Mac",
                "Myeloid",
                "Stroma",
                "Tc",
                "Th",
                "Tumor",
                "UA")
                           

colorassigned<-kovesi.rainbow_bgyrm_35_85_c69(length(unique(cluster_merging$new_cluster)))
clusternames<-clusterlevels
names(colorassigned)<-clusternames
mm1 <- match(data_full$cluster, cluster_merging$original_cluster)
data_full$cluster1m <- cluster_merging$new_cluster[mm1]

cluster_mean_merged <- data.frame(data01, cluster = data_full$cluster1m, check.names = FALSE) %>%
  group_by(cluster) %>% summarize_all(list(mean))

cluster_mean_merged_mat<-as.matrix(cluster_mean_merged[,union(subtype_markers,functional_markers)])

cluster_scaled_merged<-t(scale(t(cluster_mean_merged_mat)))

rownames(cluster_scaled_merged)<-1:nrow(cluster_scaled_merged)

## Annotation for merged clusters

if(!is.null(clusterMergeFile)){
  ifelse(grepl(clusterMergeFile,pattern='.xls'),cluster_merging <- read_excel(clusterMergeFile),cluster_merging <- read.csv(clusterMergeFile,header = TRUE))
  cluster_merging$new_cluster <- factor(cluster_merging$new_cluster)
  annotation_row$Merged <- cluster_merging$new_cluster
  color_clusters2 <- kovesi.rainbow_bgyrm_35_85_c69(nlevels(annotation_row$Merged))
  names(color_clusters2) <- levels(cluster_merging$new_cluster)
  annotation_colors$Merged <- color_clusters2
}

## Colors for the heatmap

legend_breaks = seq(from = 0, to = 1, by = 0.2)
clusternames<-clusterlevels
colorassigned<-kovesi.rainbow_bgyrm_35_85_c69(length(clusternames))
names(colorassigned)<-clusternames
rownames(cluster_scaled_merged)<-cluster_mean_merged$cluster
color_list = list(clusters=colorassigned)
color_list_byoriginal = colorassigned[match(unique(cluster_merging$new_cluster),names(colorassigned))]

cp<-rowAnnotation(col=color_list,
                  gp = gpar(col = "white", lwd = .5),
                  counts= anno_barplot(
                    as.vector(table(data_full$cluster1m)),
                    gp = gpar(fill=colorassigned),
                    border = F,
                    bar_width = 0.75, 
                    width = unit(2,"cm")))

pdf("clusterheatmap_merged.pdf",width=10,height=6)
Heatmap(cluster_scaled_merged,
        column_title="Phenograph Merged Clusters",
        name = "scaled",
        col=rev(brewer.rdbu(100)),
        cluster_columns = T,
        cluster_rows = F,
        border = NA,
        rect_gp = gpar(col = "white", lwd = .5),
        right_annotation = cp,
        show_row_names = T,
        row_names_gp = gpar(fontsize=7),
        column_names_gp = gpar(fontsize=10),
        heatmap_legend_param = list(at=seq(from = round(min(cluster_scaled)), to = round(max(cluster_scaled)))),
        width = ncol(cluster_scaled_merged)*unit(4, "mm"), 
        height = nrow(cluster_scaled_merged)*unit(4, "mm"))
dev.off()


#save as RDS file
global_data <- list(data_full, data, data01, csv_full)
saveRDS(global_data, "global_data.RDS")
