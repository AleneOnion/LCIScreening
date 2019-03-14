#LCI Screening
#Alene Onion
#March 2019


#capture current working directory so I can return to it
current_wd<-getwd()
#set working directory to raw data folder
setwd("LENS/raw.data")

files<-list.files()
nfiles<-length(files)

#read the first file
library(xlsx)
lens<-read.xlsx(files[1],11,header=TRUE)
#add the NHD identifyier
files[1]<-gsub("_LENS.*","",files[1])
files[1]<-gsub(".*_","",files[1])
lens$NHD<-files[1]
lens<-unique(lens[c('NHD','Total_Load_Breakdown_Category','Load_lbs_yr')])
#spread the table
library(tidyr)
lens<-lens %>%
  spread(Total_Load_Breakdown_Category,Load_lbs_yr)

for(i in 2:nfiles){
  temp<-read.xlsx(files[i],11,header=TRUE)
  #add the NHD identifier
  files[i]<-gsub("_LENS.*","",files[i])
  files[i]<-gsub(".*_","",files[i])
  temp$NHD<-files[i]
  temp<-unique(temp[c('NHD','Total_Load_Breakdown_Category','Load_lbs_yr')])
  #spread the table
  library(tidyr)
  temp<-temp %>%
    spread(Total_Load_Breakdown_Category,Load_lbs_yr)
  #merge with lens file
  lens<-merge(lens,temp,all=TRUE)
  rm(temp)
}
rm(list=c('files','nfiles','i'))

#reset working directory to parent
setwd(current_wd)
rm(current_wd)

#add a total column:
lens$Total<-rowSums(lens[c('Point Source Load','Septic Load','Forest','Cultivated Crops','Pasture/Hay','Developed, Open Space','Developed, Low Intensity','Developed, Medium Intensity','Developed, High Intensity')],na.rm=TRUE)

#write the file
write.csv(lens,file="LENS/concatinated.lens.csv",row.names=FALSE)
