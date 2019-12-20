#LCI Screening
#Alene Onion
#March 2019


#capture current working directory so I can return to it
current_wd<-getwd()
#set working directory to raw data folder
setwd("L:/DOW/BWAM/LMAS/Lakes Stuff/LCI/2019 LCI/screening/LENS/raw.data")

files<-list.files()
nfiles<-length(files)

#read the first file
library(xlsx)
lens<-read.xlsx(files[1],9,header=TRUE)
#add the NHD identifyier
files[1]<-gsub("_LENS.*","",files[1])
files[1]<-gsub(".*_","",files[1])
lens$NHD<-files[1]
lens<-unique(lens[c('NHD','Loading_Total_Category','Load_lbs_yr')])
#spread the table
library(tidyr)
lens<-lens %>%
  spread(Loading_Total_Category,Load_lbs_yr)

for(i in 2:nfiles){
  temp<-read.xlsx(files[i],9,header=TRUE)
  #add the NHD identifier
  files[i]<-gsub("_LENS.*","",files[i])
  files[i]<-gsub(".*_","",files[i])
  temp$NHD<-files[i]
  temp<-unique(temp[c('NHD','Loading_Total_Category','Load_lbs_yr')])
  #spread the table
  library(tidyr)
  temp<-temp %>%
    spread(Loading_Total_Category,Load_lbs_yr)
  #merge with lens file
  lens<-merge(lens,temp,all=TRUE)
  rm(temp)
}
rm(list=c('files','nfiles','i'))

#reset working directory to parent
setwd(current_wd)
rm(current_wd)

#add a total column:
lens$Total<-rowSums(lens[c('Point Source Load','Septic Load','Forest','Developed','Agriculture')],na.rm=TRUE)

#write the file
write.csv(lens,file="L:/DOW/BWAM/LMAS/Lakes Stuff/LCI/2019 LCI/screening/LENS/concatinated.lens.csv",row.names=FALSE)


####################################################################################################################
#pulling previously sampled lakes from the past 10 yrs
####################################################################################################################
############################################################################################################
#pull historic data, insert 2018 data, and clean up data file
source('L:/DOW/StreamDatabase/Lakes/data/2018.cleanup.R')

#simplifying and merging the tables
source('L:/DOW/StreamDatabase/Lakes/data/2018/Lakes.R')
rm(list=c('bprofiles','bresults','bsample','habs','results1','results2'))

#Fixing the data set
data$Result.Sample.Fraction[data$Result.Sample.Fraction==""]<-NA

#correct erroneous info_types
infos<-read.csv("L:/DOW/StreamDatabase/Lakes/data/2018/fix.info.types.csv",na.strings=c("","NA"), stringsAsFactors=FALSE)
#set working directory
setwd("C:/Rscripts/TP.Variance")
infos<-unique(infos[c('LAKE_ID','SAMPLE_ID','SAMPLE_NAME','INFO_TYPE','new_INFO_TYPE')])
sites<-unique(data[c('LAKE_ID','SAMPLE_ID','SAMPLE_NAME','INFO_TYPE')])
sites<-merge(sites,infos,by=c('LAKE_ID','SAMPLE_ID','SAMPLE_NAME','INFO_TYPE'),all=TRUE)
sites$INFO_TYPE<-ifelse(!is.na(sites$new_INFO_TYPE),sites$new_INFO_TYPE,sites$INFO_TYPE)
sites$new_INFO_TYPE<-NULL
data$INFO_TYPE<-NULL
data<-merge(data,sites,by=c('LAKE_ID','SAMPLE_ID','SAMPLE_NAME'),all=TRUE)
rm(list=c('infos','sites'))

#restrict to phosphorus to ensure non HAB sampling
data<-data[data$Characteristic.Name=="PHOSPHORUS",]
data<-data[!is.na(data$Characteristic.Name),]

#write
write.csv(data,file="backup.data.files.csv",row.names = FALSE)
write.csv(blocation,file="backup.location.file.csv",row.names = FALSE)
#readin
data<-read.csv("backup.data.files.csv", stringsAsFactors=FALSE)
data$SAMPLE_DATE<-as.Date(data$SAMPLE_DATE,format="%Y-%m-%d")
blocation<-read.csv("backup.location.file.csv",stringsAsFactors = FALSE)

#restrict to the past 10 yrs
data<-data[data$SAMPLE_DATE>'2001-01-01',]
data<-data[data$SAMPLE_DATE<'2011-01-01',]
data<-data[!is.na(data$SAMPLE_DATE),]
data<-data[!is.na(data$Characteristic.Name),]

#merge with location table
blocation<-unique(blocation[c('LakeID','Y_Coordinate','X_Coordinate')])
blocation<-blocation[!duplicated(blocation$LakeID),]
names(blocation)[names(blocation)=="LakeID"]<-"LAKE_ID"
data<-merge(data,blocation,by=c('LAKE_ID'),all.x=TRUE)

#spread date
data<-unique(data[c('LAKE_ID','Y_Coordinate','X_Coordinate','SAMPLE_DATE')])
data<-data[!is.na(data$LAKE_ID),]

lakes<-unique(data$LAKE_ID)
nlakes<-length(lakes)

temp<-data[data$LAKE_ID==lakes[1],]
temp<-temp[!is.na(temp$LAKE_ID),]
temp$maxdate<-max(temp$SAMPLE_DATE)
temp<-unique(temp[c('LAKE_ID','Y_Coordinate','X_Coordinate','maxdate')])
for(i in 1:nlakes){
  temp1<-data[data$LAKE_ID==lakes[i],]
  temp1<-temp1[!is.na(temp1$LAKE_ID),]
  temp1$maxdate<-max(temp1$SAMPLE_DATE)
  temp1<-unique(temp1[c('LAKE_ID','Y_Coordinate','X_Coordinate','maxdate')])
  temp<-merge(temp,temp1,all=TRUE)
}
data<-temp
rm(list=c('temp','temp1','i','lakes','nlakes','blocation'))

#write the file
write.csv(data,file="data.from.10before.csv",row.names=FALSE)
