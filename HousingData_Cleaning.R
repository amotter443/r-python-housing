#Part 1: Cleaning
library(readxl)
library(dplyr)
library(MASS)

start_time<-Sys.time()

#Read in Data, remove 1st ID column
suppressWarnings(housing_data<-read_xlsx("HousePricesCompleteData.xlsx"))
housing_data<-housing_data[,-1]

#Create character vector to collect all columns that contain at least one NA
na_columns<-"0"

for (i in 1:ncol(housing_data)){
  if (sum(is.na(housing_data[[i]]))>0){
    na_columns<-c(na_columns,colnames(housing_data[i]))
  }
}

na_columns<-na_columns[-1]
#Ignore NAs in SalesPrice, the y, they represent the test set
na_columns<-na_columns[-9]
print(na_columns)


#1&2 Basement square footage for type 1 and type 2
#No basement, therefore square footage of basement is zero

replace<-housing_data[is.na(housing_data$BsmtFinSF1),]
housing_data[is.na(housing_data$BsmtFinSF1),"BsmtFinSF1"]<-0
replace<-housing_data[is.na(housing_data$BsmtFinSF2),]
housing_data[is.na(housing_data$BsmtFinSF2),"BsmtFinSF2"]<-0

#3 BsmtUnfSF Unfinished square footage of basement area
#Same Row as 1 &2, therefore doesn't have a basement

replace<-housing_data[is.na(housing_data$BsmtUnfSF),]
housing_data[is.na(housing_data$BsmtUnfSF),"BsmtUnfSF"]<-0

#4-6 TotalBsmtSF, BsmtFullBath, and BsmtHalfBath
#all don't have basement so all can be replaced with zeroes 

housing_data[is.na(housing_data$TotalBsmtSF),"TotalBsmtSF"]<-0
housing_data[is.na(housing_data$BsmtFullBath),"BsmtFullBath"]<-0
housing_data[is.na(housing_data$BsmtHalfBath),"BsmtHalfBath"]<-0

#7-8 GarageCars  Size of garage in car capacity
#No Garage and therefore all converted to zeroes

housing_data[is.na(housing_data$GarageCars),"GarageCars"]<-0
housing_data[is.na(housing_data$GarageArea),"GarageArea"]<-0


#Lot frontage has a square root relationship with lot area, use existing
#data to derive approximations
housing_data[which(housing_data$LotFrontage=="NA"),'LotFrontage']<-round(sqrt(housing_data[which(housing_data$LotFrontage=="NA"),'LotArea']))
#Convert Lot Frontage to numeric column
housing_data$LotFrontage<-as.numeric(housing_data$LotFrontage)

#If there is no masonry veneer, type is none and area is 0
housing_data[which(housing_data$MasVnrType=="NA"),'MasVnrType']<-"None"
housing_data[which(housing_data$MasVnrType=="None"),'MasVnrArea']<-0
housing_data$MasVnrArea<-as.numeric(housing_data$MasVnrArea)

replace<-housing_data[which(housing_data$GarageYrBlt=="NA"),'GarageType']
#this means that all the values with NA don't have a garage
housing_data$GarageYrBlt<-as.numeric(format(as.Date(housing_data$GarageYrBlt,format="%Y"),"%Y"))

#Just so the C's are cleaner
housing_data[housing_data$MSZoning=='C (all)','MSZoning']<-"C"

#Recoded BsmtQual to same scale used by other ordinal variables
housing_data[housing_data$BsmtQual=="Gd" & housing_data$BsmtExposure=="NA",'BsmtExposure']<-"No"
housing_data[housing_data$BsmtQual=="Gd" & housing_data$BsmtCond=="NA",'BsmtCond']<-"TA"
housing_data[housing_data$BsmtQual=="TA" & housing_data$BsmtFinType1=="BLQ",'BsmtCond']<-"Po"
housing_data[housing_data$BsmtQual=="TA" & housing_data$BsmtFinType1=="ALQ",'BsmtCond']<-"TA"
housing_data[housing_data$BsmtQual=="NA" & housing_data$BsmtCond!="NA",'BsmtQual']<-"Po"

#Because both have a 1 on overall condition or quality, recoding both to Moderate Deductions
housing_data[housing_data$Functional=="NA",'Functional']<-"Mod"

#Because there is an other category and these fit the criteria of other, accordingly recoded
housing_data[housing_data$Exterior1st=="NA",'Exterior1st']<-"Other"
housing_data[housing_data$SaleType %in% c("Oth","NA"),'SaleType']<-"Other"

#Filling in NAs here with year the house was built just to assume that garage age is
#that of the house age because the majority of values, 2125, are same year as house construction
housing_data[which(is.na(housing_data$GarageYrBlt)),'GarageYrBlt']<-housing_data[which(is.na(housing_data$GarageYrBlt)),'YearBuilt']
sum(is.na(housing_data$GarageYrBlt))
#Correcting data entry error
housing_data[housing_data$GarageYrBlt==2207,'GarageYrBlt']<-2007

#Consolidating number of dummies by putting all the Residential values together
housing_data[which(housing_data$MSZoning %in% c("RH","RL","RP","RM","FV")),'MSZoning']<-"R"
#For NAs, Recoding to R because 4 obs are all 1 family buildings from pre 1945
housing_data[housing_data$MSZoning=="NA",'MSZoning']<-"R"


#If lot shape is regular 1, else 0 in standard boolean format
housing_data[which(housing_data$LotShape %in% c("IR1","IR2","IR3")),'LotShape']<-"0"
housing_data[which(housing_data$LotShape=="Reg"),'LotShape']<-"1"

#1 regular, 0 irregular
housing_data$LotShape<-as.numeric(housing_data$LotShape)

#From here to line 142 reduced number of building materials to the following:
#Wood, Rock, Concrete, Brick, Metal, and Other
#Materials chosen based on frequency & research into common building materials
housing_data[which(housing_data$RoofMatl %in% c("ClyTile","Tar&Grv")),'RoofMatl']<-"Rock"
housing_data[which(housing_data$RoofMatl %in% c("CompShg","Membran","Roll")),'RoofMatl']<-"Other"
housing_data[which(housing_data$RoofMatl %in% c("WdShake","WdShngl")),'RoofMatl']<-"Wood"

housing_data[which(housing_data$Exterior1st %in% c("AsbShng","AsphShn","HdBoard","ImStucc","VinylSd","PreCast")),'Exterior1st']<-"Other"
housing_data[which(housing_data$Exterior1st %in% c("CemntBd","CBlock")),'Exterior1st']<-"Concrete"
housing_data[which(housing_data$Exterior1st %in% c("BrkComm","BrkFace")),'Exterior1st']<-"Brick"
housing_data[which(housing_data$Exterior1st %in% c("Stone","Stucco")),'Exterior1st']<-"Rock"
housing_data[which(housing_data$Exterior1st %in% c("Plywood","WdShing","Wd Sdng")),'Exterior1st']<-"Wood"
housing_data[which(housing_data$Exterior1st=="MetalSd"),'Exterior1st']<-"Metal"

housing_data[which(housing_data$Exterior2nd %in% c("AsbShng","AsphShn","HdBoard","ImStucc","VinylSd","PreCast")),'Exterior2nd']<-"Other"
housing_data[which(housing_data$Exterior2nd %in% c("CmentBd","CemntBd","CBlock")),'Exterior2nd']<-"Concrete"
housing_data[which(housing_data$Exterior2nd %in% c("Brk Cmn","BrkComm","BrkFace")),'Exterior2nd']<-"Brick"
housing_data[which(housing_data$Exterior2nd %in% c("Stone","Stucco")),'Exterior2nd']<-"Rock"
housing_data[which(housing_data$Exterior2nd %in% c("Plywood","WdShing","Wd Sdng","Wd Shng")),'Exterior2nd']<-"Wood"
housing_data[which(housing_data$Exterior2nd=="MetalSd"),'Exterior2nd']<-"Metal"
housing_data[which(housing_data$Exterior2nd=="NA"),'Exterior2nd']<-"Other"

housing_data[which(housing_data$MasVnrType=="Stone"),'MasVnrType']<-"Rock"
housing_data[which(housing_data$MasVnrType=="None"),'MasVnrType']<-"Other"
housing_data[which(housing_data$MasVnrType=="CBlock"),'MasVnrType']<-"Concrete"
housing_data[which(housing_data$MasVnrType %in% c("BrkCmn","BrkFace")),'MasVnrType']<-"Brick"

housing_data[which(housing_data$Foundation=="BrkTil"),'Foundation']<-"Brick"
housing_data[which(housing_data$Foundation %in% c("CBlock","PConc","Slab")),'Foundation']<-"Concrete"
housing_data[which(housing_data$Foundation=="Stone"),'Foundation']<-"Rock"

housing_data[which(housing_data$Functional=="Typ"),'Functional']<-"TA"
housing_data[which(housing_data$Functional %in% c("Min1", "Min2", "Mod")),'Functional']<-"Fa"
housing_data[which(housing_data$Functional %in% c("Maj1","Maj2","Sev","Sal")),'Functional']<-"Po"

#From 145-156 recoded all ordinal values to scale most commonly used in dataset
housing_data[which(housing_data$BsmtExposure %in% c("No","Mn")),'BsmtExposure']<-"EX"
housing_data[which(housing_data$BsmtExposure=="Av"),'BsmtExposure']<-"TA"

housing_data[which(housing_data$BsmtFinType1 %in% c("ALQ","Rec")),'BsmtFinType1']<-"TA"
housing_data[which(housing_data$BsmtFinType1 %in% c("LwQ","Unf")),'BsmtFinType1']<-"Po"
housing_data[which(housing_data$BsmtFinType1=="GLQ"),'BsmtFinType1']<-"Gd"
housing_data[which(housing_data$BsmtFinType1=="BLQ"),'BsmtFinType1']<-"Fa"

housing_data[which(housing_data$BsmtFinType2 %in% c("ALQ","Rec")),'BsmtFinType2']<-"TA"
housing_data[which(housing_data$BsmtFinType2 %in% c("LwQ","Unf")),'BsmtFinType2']<-"Po"
housing_data[which(housing_data$BsmtFinType2=="GLQ"),'BsmtFinType2']<-"Gd"
housing_data[which(housing_data$BsmtFinType2=="BLQ"),'BsmtFinType2']<-"Fa"

#From 159-256 recoded all ordinal feataures to consistent numeric scale and subsequently
#converted feature to numeric
housing_data[which(housing_data$ExterCond=="Ex"),'ExterCond']<-9
housing_data[which(housing_data$ExterCond=="Gd"),'ExterCond']<-7
housing_data[which(housing_data$ExterCond=="TA"),'ExterCond']<-5
housing_data[which(housing_data$ExterCond=="Fa"),'ExterCond']<-3
housing_data[which(housing_data$ExterCond=="Po"),'ExterCond']<-1
housing_data$ExterCond<-as.numeric(housing_data$ExterCond)

housing_data[which(housing_data$ExterQual=="Ex"),'ExterQual']<-9
housing_data[which(housing_data$ExterQual=="Gd"),'ExterQual']<-7
housing_data[which(housing_data$ExterQual=="TA"),'ExterQual']<-5
housing_data[which(housing_data$ExterQual=="Fa"),'ExterQual']<-3
housing_data[which(housing_data$ExterQual=="Po"),'ExterQual']<-1
housing_data$ExterQual<-as.numeric(housing_data$ExterQual)

housing_data[which(housing_data$BsmtCond=="Ex"),'BsmtCond']<-9
housing_data[which(housing_data$BsmtCond=="Gd"),'BsmtCond']<-7
housing_data[which(housing_data$BsmtCond=="TA"),'BsmtCond']<-5
housing_data[which(housing_data$BsmtCond=="Fa"),'BsmtCond']<-3
housing_data[which(housing_data$BsmtCond=="Po"),'BsmtCond']<-1
housing_data$BsmtCond<-suppressWarnings(as.numeric(housing_data$BsmtCond))

housing_data[which(housing_data$BsmtQual=="Ex"),'BsmtQual']<-9
housing_data[which(housing_data$BsmtQual=="Gd"),'BsmtQual']<-7
housing_data[which(housing_data$BsmtQual=="TA"),'BsmtQual']<-5
housing_data[which(housing_data$BsmtQual=="Fa"),'BsmtQual']<-3
housing_data[which(housing_data$BsmtQual=="Po"),'BsmtQual']<-1
housing_data$BsmtQual<-suppressWarnings(as.numeric(housing_data$BsmtQual))

housing_data[which(housing_data$BsmtExposure=="Ex"|housing_data$BsmtExposure=="EX"),'BsmtExposure']<-9
housing_data[which(housing_data$BsmtExposure=="Gd"),'BsmtExposure']<-7
housing_data[which(housing_data$BsmtExposure=="TA"),'BsmtExposure']<-5
housing_data[which(housing_data$BsmtExposure=="Fa"),'BsmtExposure']<-3
housing_data[which(housing_data$BsmtExposure=="Po"),'BsmtExposure']<-1
housing_data$BsmtExposure<-suppressWarnings(as.numeric(housing_data$BsmtExposure))

housing_data[which(housing_data$BsmtFinType1=="Ex"),'BsmtFinType1']<-9
housing_data[which(housing_data$BsmtFinType1=="Gd"),'BsmtFinType1']<-7
housing_data[which(housing_data$BsmtFinType1=="TA"),'BsmtFinType1']<-5
housing_data[which(housing_data$BsmtFinType1=="Fa"),'BsmtFinType1']<-3
housing_data[which(housing_data$BsmtFinType1=="Po"),'BsmtFinType1']<-1
housing_data$BsmtFinType1<-suppressWarnings(as.numeric(housing_data$BsmtFinType1))

housing_data[which(housing_data$BsmtFinType2=="Ex"),'BsmtFinType2']<-9
housing_data[which(housing_data$BsmtFinType2=="Gd"),'BsmtFinType2']<-7
housing_data[which(housing_data$BsmtFinType2=="TA"),'BsmtFinType2']<-5
housing_data[which(housing_data$BsmtFinType2=="Fa"),'BsmtFinType2']<-3
housing_data[which(housing_data$BsmtFinType2=="Po"),'BsmtFinType2']<-1
housing_data$BsmtFinType2<-suppressWarnings(as.numeric(housing_data$BsmtFinType2))

housing_data[which(housing_data$HeatingQC=="Ex"),'HeatingQC']<-9
housing_data[which(housing_data$HeatingQC=="Gd"),'HeatingQC']<-7
housing_data[which(housing_data$HeatingQC=="TA"),'HeatingQC']<-5
housing_data[which(housing_data$HeatingQC=="Fa"),'HeatingQC']<-3
housing_data[which(housing_data$HeatingQC=="Po"),'HeatingQC']<-1
housing_data$HeatingQC<-as.numeric(housing_data$HeatingQC)

housing_data[which(housing_data$KitchenQual=="Ex"),'KitchenQual']<-9
housing_data[which(housing_data$KitchenQual=="Gd"),'KitchenQual']<-7
housing_data[which(housing_data$KitchenQual=="TA"),'KitchenQual']<-5
housing_data[which(housing_data$KitchenQual=="Fa"),'KitchenQual']<-3
housing_data[which(housing_data$KitchenQual=="Po"),'KitchenQual']<-1
housing_data$KitchenQual<-suppressWarnings(as.numeric(housing_data$KitchenQual))

housing_data[which(housing_data$Functional=="Ex"),'Functional']<-9
housing_data[which(housing_data$Functional=="Gd"),'Functional']<-7
housing_data[which(housing_data$Functional=="TA"),'Functional']<-5
housing_data[which(housing_data$Functional=="Fa"),'Functional']<-3
housing_data[which(housing_data$Functional=="Po"),'Functional']<-1
housing_data$Functional<-as.numeric(housing_data$Functional)

housing_data[which(housing_data$PoolQC=="Ex"),'PoolQC']<-9
housing_data[which(housing_data$PoolQC=="Gd"),'PoolQC']<-7
housing_data[which(housing_data$PoolQC=="TA"),'PoolQC']<-5
housing_data[which(housing_data$PoolQC=="Fa"),'PoolQC']<-3
housing_data[which(housing_data$PoolQC=="Po"),'PoolQC']<-1
housing_data$PoolQC<-suppressWarnings(as.numeric(housing_data$PoolQC))

housing_data[which(housing_data$GarageCond=="Ex"),'GarageCond']<-9
housing_data[which(housing_data$GarageCond=="Gd"),'GarageCond']<-7
housing_data[which(housing_data$GarageCond=="TA"),'GarageCond']<-5
housing_data[which(housing_data$GarageCond=="Fa"),'GarageCond']<-3
housing_data[which(housing_data$GarageCond=="Po"),'GarageCond']<-1
housing_data$GarageCond<-suppressWarnings(as.numeric(housing_data$GarageCond))

housing_data[which(housing_data$GarageQual=="Ex"),'GarageQual']<-9
housing_data[which(housing_data$GarageQual=="Gd"),'GarageQual']<-7
housing_data[which(housing_data$GarageQual=="TA"),'GarageQual']<-5
housing_data[which(housing_data$GarageQual=="Fa"),'GarageQual']<-3
housing_data[which(housing_data$GarageQual=="Po"),'GarageQual']<-1
housing_data$GarageQual<-suppressWarnings(as.numeric(housing_data$GarageQual))

housing_data[which(housing_data$FireplaceQu=="Ex"),'FireplaceQu']<-9
housing_data[which(housing_data$FireplaceQu=="Gd"),'FireplaceQu']<-7
housing_data[which(housing_data$FireplaceQu=="TA"),'FireplaceQu']<-5
housing_data[which(housing_data$FireplaceQu=="Fa"),'FireplaceQu']<-3
housing_data[which(housing_data$FireplaceQu=="Po"),'FireplaceQu']<-1
housing_data$FireplaceQu<-suppressWarnings(as.numeric(housing_data$FireplaceQu))

#For PavedDrive & Central Air, recoded to 1,0 True False structure
#PavedDrive had a "Partial" option which was recoded to 0.5
housing_data[which(housing_data$PavedDrive=="N"),'PavedDrive']<-"0"
housing_data[which(housing_data$PavedDrive=="P"),'PavedDrive']<-"0.5"
housing_data[which(housing_data$PavedDrive=="Y"),'PavedDrive']<-"1"
housing_data$PavedDrive<-as.numeric(housing_data$PavedDrive)

housing_data[housing_data$CentralAir=="Y",'CentralAir']<-1
housing_data[housing_data$CentralAir=="N",'CentralAir']<-0
housing_data$CentralAir<-as.numeric(housing_data$CentralAir)

#Split HouseStyle into 2 fields (NumFloors and HouseFinish)

#Create new feature for number of floors
housing_data$NumFloors<-NA

#If 2ndfloorsqft>0 then +2 else +1
#If GarageQual or BsmtQual are not = "NA" then +0.5 because they are considered partial floors
housing_data[housing_data$`2ndFlrSF`>0,'NumFloors']<-2
housing_data[housing_data$`2ndFlrSF`<=0,'NumFloors']<-1
housing_data[which(housing_data$GarageQual!="NA"|housing_data$BsmtQual!="NA"),'NumFloors']<-housing_data[which(housing_data$GarageQual!="NA"|housing_data$BsmtQual!="NA"),'NumFloors']+0.5

#Create new feature for type of finish of the house
housing_data$HouseFinish<-NA

#Finished coded as 1, Unfinished 0

#If HouseStyle ends with "Unf", BsmtUnfSF>0, or GarageFinish= "Unf" then 0
#If none of these conditions satisifed then it is finished and coded as 1
housing_data[which(endsWith(housing_data$HouseStyle,"Unf")==TRUE | housing_data$BsmtUnfSF>0 | housing_data$GarageFinish=="Unf"),'HouseFinish']<-0
housing_data[which(is.na(housing_data$HouseFinish)),'HouseFinish']<-1

#Get rid of old House Stytle feature
housing_data<-housing_data[,-16]

#Created three new Date features: The age of the house and the years since the last remodel
housing_data$Age<-2019-housing_data$YearBuilt
housing_data$YrSinceRemodel<-2019-housing_data$YearRemodAdd
housing_data$New <-NA
housing_data[which(housing_data$YrSold==housing_data$YearBuilt),'New']<-1
housing_data[which(housing_data$YrSold!=housing_data$YearBuilt),'New']<-0


#Remove old features YearBuild and yearRemodAdd
housing_data<-housing_data[,-18]
housing_data<-housing_data[,-18]

#Create new value that is proportion of basement that is unfinished
housing_data$BsmtPUnf<-NA
housing_data$BsmtPUnf<-round((housing_data$BsmtUnfSF/housing_data$TotalBsmtSF)*100)
#If no basement creates NA because of 0/0, recoding as 0s to prevent errors
housing_data[is.na(housing_data$BsmtPUnf),'BsmtPUnf']<-0

#Created new feature that consolidates bathrooms into one variable
housing_data$Bathrooms<-housing_data$FullBath + (housing_data$HalfBath*0.5) + housing_data$BsmtFullBath + (housing_data$BsmtHalfBath*0.5)
housing_data<-housing_data[,-44]
housing_data<-housing_data[,-44]
housing_data<-housing_data[,-44]
housing_data<-housing_data[,-44]

#Supressing warnings before coerced NAs, need to be recoeded into 0s

#Use loop to collect columns with NAs
ord_columns<-"0"

for (i in 1:ncol(housing_data)){
  if (sum(is.na(housing_data[[i]]))>0){
    ord_columns<-c(ord_columns,colnames(housing_data[i]))
  }
}  

ord_columns<-ord_columns[-1]  

#Confirmed that the only NAs are in Features that are ordinal and test set values for SalePrice
ord_columns


#Recoded NAs as 0s
ord_columns<-ord_columns[-11]  
housing_data[which(is.na(housing_data$BsmtQual)),"BsmtQual"]<-0
housing_data[which(is.na(housing_data$BsmtCond)),"BsmtCond"]<-0
housing_data[which(is.na(housing_data$BsmtExposure)),"BsmtExposure"]<-0
housing_data[which(is.na(housing_data$BsmtFinType1)),"BsmtFinType1"]<-0
housing_data[which(is.na(housing_data$BsmtFinType2)),"BsmtFinType2"]<-0
housing_data[which(is.na(housing_data$KitchenQual)),"KitchenQual"]<-0
housing_data[which(is.na(housing_data$FireplaceQu)),"FireplaceQu"]<-0
housing_data[which(is.na(housing_data$GarageQual)),"GarageQual"]<-0
housing_data[which(is.na(housing_data$GarageCond)),"GarageCond"]<-0
housing_data[which(is.na(housing_data$PoolQC)),"PoolQC"]<-0

housing_data$Commercial<-NA

housing_data[housing_data$MSZoning=="C",'Commercial']<-1
housing_data[housing_data$MSZoning=="R",'Commercial']<-0

housing_data<-housing_data[-2]

housing_data[housing_data$Street=="Grvl",'Street']<-0
housing_data[housing_data$Street=="Pave",'Street']<-1
housing_data$Street<-as.numeric(housing_data$Street)

housing_data[which(housing_data$Alley %in% c("Grvl","NA","None")),'Alley']<-0
housing_data[housing_data$Alley=="Pave",'Alley']<-1
housing_data$Alley<-as.numeric(housing_data$Alley)

housing_data[housing_data$Utilities=="AllPub",'Utilities']<-4
housing_data[housing_data$Utilities=="NoSewr",'Utilities']<-3
housing_data[housing_data$Utilities=="NoSeWa",'Utilities']<-2
housing_data[housing_data$Utilities=="ELO",'Utilities']<-1
housing_data[housing_data$Utilities=="NA",'Utilities']<-0
housing_data$Utilities<-as.numeric(housing_data$Utilities)

colnames(housing_data)[38]<-"FirstSF"
colnames(housing_data)[39]<-"SecondSF"
colnames(housing_data)[57]<-"ThreeSsnPorch"

#Recoding all fields to numeric
housing_data[which(housing_data$Electrical %in% c("NA","Mix","FuseA","FuseF","FuseP")),'Electrical']<-0
housing_data[housing_data$Electrical=="SBrkr",'Electrical']<-1
housing_data$Electrical<-as.numeric(housing_data$Electrical)

housing_data[which(housing_data$GarageType %in% c("NA","2Types","CarPort","Detchd")),'GarageType']<-0
housing_data[which(housing_data$GarageType %in% c("Attchd","Basment","BuiltIn")),'GarageType']<-1
housing_data$GarageType<-as.numeric(housing_data$GarageType)

housing_data[which(housing_data$GarageFinish %in% c("NA","RFn","Unf")),'GarageFinish']<-0
housing_data[which(housing_data$GarageFinish %in% c("RFn","Fin")),'GarageFinish']<-1
housing_data$GarageFinish<-as.numeric(housing_data$GarageFinish)

housing_data[which(housing_data$LandContour %in% c("Bnk","HLS","Low")),'LandContour']<-0
housing_data[housing_data$LandContour=="Lvl",'LandContour']<-1
housing_data$LandContour<-as.numeric(housing_data$LandContour)

housing_data[housing_data$LandSlope=="Sev",'LandSlope']<-3
housing_data[housing_data$LandSlope=="Mod",'LandSlope']<-2
housing_data[housing_data$LandSlope=="Gtl",'LandSlope']<-1
housing_data$LandSlope<-as.numeric(housing_data$LandSlope)

housing_data[which(housing_data$Condition1 %in% c("Artery","Feedr")),'Condition1']<-"Street"
housing_data[which(housing_data$Condition1 %in% c("RRNn","RRAn","RRNe","RRAe")),'Condition1']<-"RR"
housing_data[which(housing_data$Condition1 %in% c("PosN","PosA")),'Condition1']<-"Pos"
plot(as.factor(housing_data$Condition1),housing_data$SalePrice,horizontal=T)
housing_data[housing_data$Condition1=="Norm",'Condition1']<-4
housing_data[housing_data$Condition1=="Pos",'Condition1']<-3
housing_data[housing_data$Condition1=="RR",'Condition1']<-2
housing_data[housing_data$Condition1=="Street",'Condition1']<-1
housing_data$Condition1<-as.numeric(housing_data$Condition1)

housing_data[which(housing_data$Condition2 %in% c("Artery","Feedr")),'Condition2']<-"Street"
housing_data[which(housing_data$Condition2 %in% c("RRNn","RRAn","RRNe","RRAe")),'Condition2']<-"RR"
housing_data[which(housing_data$Condition2 %in% c("PosN","PosA")),'Condition2']<-"Pos"
plot(as.factor(housing_data$Condition2),housing_data$SalePrice,horizontal=T)
housing_data[housing_data$Condition2=="Norm",'Condition2']<-4
housing_data[housing_data$Condition2=="Pos",'Condition2']<-3
housing_data[housing_data$Condition2=="RR",'Condition2']<-2
housing_data[housing_data$Condition2=="Street",'Condition2']<-1
housing_data$Condition2<-as.numeric(housing_data$Condition2)

housing_data[which(housing_data$Heating %in% c("Floor","Grav","Wall")),'Heating']<-2
housing_data[which(housing_data$Heating %in% c("GasA","GasW")),'Heating']<-3
housing_data[housing_data$Heating=="OthW",'Heating']<-1
housing_data$Heating<-as.numeric(housing_data$Heating)

housing_data[which(housing_data$Fence %in% c("GdPrv","GdWo")),'Fence']<-7
housing_data[which(housing_data$Fence %in% c("MnPrv","MnWw")),'Fence']<-3
housing_data[housing_data$Fence=="NA",'Fence']<-0
housing_data$Fence<-as.numeric(housing_data$Fence)

housing_data[housing_data$SaleCondition!="Normal",'SaleCondition']<-0
housing_data[housing_data$SaleCondition=="Normal",'SaleCondition']<-1
housing_data$SaleCondition<-as.numeric(housing_data$SaleCondition)

housing_data[which(housing_data$SaleType %in% c("WD","CWD","VWD")),'SaleType']<-4
housing_data[housing_data$SaleType=="New",'SaleType']<-3
housing_data[which(housing_data$SaleType %in% c("ConLD","ConLI","ConLw","Con")),'SaleType']<-2
housing_data[which(housing_data$SaleType %in% c("COD","Oth","Other")),'SaleType']<-1
#Set SaleType NA to 0
housing_data$SaleType<-as.numeric(housing_data$SaleType)

#housing_data[which(housing_data$Neighborhood %in% c("Gilbert","IDOTRR","MeadowV","Mitchel","OldTown")),'Neighborhood']<-1
#housing_data[which(housing_data$Neighborhood %in% c("Blmngtn","BrDale","BrkSide","ClearCr","CollgCr","NAmes","NoRidge","NPkVill","NridgHt","Somerst","StoneBr")),'Neighborhood']<-2
#housing_data[which(housing_data$Neighborhood %in% c("Blueste","Edwards","SWISU","Timber")),'Neighborhood']<-3
#housing_data[which(housing_data$Neighborhood %in% c("Crawfor","NWAmes","Sawyer","SawyerW","Veenker")),'Neighborhood']<-4
#housing_data$Neighborhood<-as.numeric(housing_data$Neighborhood)
#colnames(housing_data)[11]<-"Ward"
#correlation is 0.05 with this method
plot(as.factor(housing_data$Neighborhood),housing_data$SalePrice,horizontal=T)
levels(as.factor(housing_data$Neighborhood)) #1 value is bottom tick, #25 is top tick
housing_data[housing_data$Neighborhood=="NridgHt",'Neighborhood']<-25
housing_data[housing_data$Neighborhood=="StoneBr",'Neighborhood']<-22
housing_data[housing_data$Neighborhood=="NoRidge",'Neighborhood']<-24
housing_data[housing_data$Neighborhood=="Edwards",'Neighborhood']<-17
housing_data[housing_data$Neighborhood=="NWAmes",'Neighborhood']<-3
housing_data[housing_data$Neighborhood=="Mitchel",'Neighborhood']<-11
housing_data[housing_data$Neighborhood=="Gilbert",'Neighborhood']<-1
housing_data[housing_data$Neighborhood=="OldTown",'Neighborhood']<-18
housing_data[housing_data$Neighborhood=="NAmes",'Neighborhood']<-14
housing_data[housing_data$Neighborhood=="Crawfor",'Neighborhood']<-5
housing_data[housing_data$Neighborhood=="Veenker",'Neighborhood']<-8
housing_data[housing_data$Neighborhood=="BrDale",'Neighborhood']<-19
housing_data[housing_data$Neighborhood=="ClearCr",'Neighborhood']<-6
housing_data[housing_data$Neighborhood=="SawyerW",'Neighborhood']<-4
housing_data[housing_data$Neighborhood=="CollgCr",'Neighborhood']<-2
housing_data[housing_data$Neighborhood=="IDOTRR",'Neighborhood']<-21
housing_data[housing_data$Neighborhood=="Somerst",'Neighborhood']<-9
housing_data[housing_data$Neighborhood=="SWISU",'Neighborhood']<-13
housing_data[housing_data$Neighborhood=="NPkVill",'Neighborhood']<-10
housing_data[housing_data$Neighborhood=="Sawyer",'Neighborhood']<-15
housing_data[housing_data$Neighborhood=="Timber",'Neighborhood']<-12
housing_data[housing_data$Neighborhood=="Blueste",'Neighborhood']<-7
housing_data[housing_data$Neighborhood=="Blmngtn",'Neighborhood']<-23
housing_data[housing_data$Neighborhood=="MeadowV",'Neighborhood']<-20
housing_data[housing_data$Neighborhood=="BrkSide",'Neighborhood']<-16
housing_data$Neighborhood<-as.numeric(housing_data$Neighborhood)

plot(as.factor(housing_data$LotConfig),housing_data$SalePrice,horizontal=T)
housing_data[housing_data$LotConfig=="CulDSac",'LotConfig']<-5
housing_data[housing_data$LotConfig=="FR3",'LotConfig']<-4
housing_data[housing_data$LotConfig=="Corner",'LotConfig']<-3
housing_data[housing_data$LotConfig=="Inside",'LotConfig']<-2
housing_data[housing_data$LotConfig=="FR2",'LotConfig']<-1
housing_data$LotConfig<-as.numeric(housing_data$LotConfig)

plot(as.factor(housing_data$Foundation),housing_data$SalePrice,horizontal=T)
housing_data[housing_data$Foundation=="Concrete",'Foundation']<-4
housing_data[housing_data$Foundation=="Wood",'Foundation']<-3
housing_data[housing_data$Foundation=="Rock",'Foundation']<-2
housing_data[housing_data$Foundation=="Brick",'Foundation']<-1
housing_data$Foundation<-as.numeric(housing_data$Foundation)

plot(as.factor(housing_data$RoofMatl),housing_data$SalePrice,horizontal=T)
housing_data[housing_data$RoofMatl=="Other",'RoofMatl']<-4
housing_data[housing_data$RoofMatl=="Wood",'RoofMatl']<-3
housing_data[housing_data$RoofMatl=="Metal",'RoofMatl']<-2
housing_data[housing_data$RoofMatl=="Rock",'RoofMatl']<-1
housing_data$RoofMatl<-as.numeric(housing_data$RoofMatl)

plot(as.factor(housing_data$Exterior1st),housing_data$SalePrice,horizontal=T)
housing_data[housing_data$Exterior1st=="Concrete",'Exterior1st']<-6
housing_data[housing_data$Exterior1st=="Other",'Exterior1st']<-5
housing_data[housing_data$Exterior1st=="Brick",'Exterior1st']<-4
housing_data[housing_data$Exterior1st=="Wood",'Exterior1st']<-3
housing_data[housing_data$Exterior1st=="Metal",'Exterior1st']<-2
housing_data[housing_data$Exterior1st=="Rock",'Exterior1st']<-1
housing_data$Exterior1st<-as.numeric(housing_data$Exterior1st)

plot(as.factor(housing_data$Exterior2nd),housing_data$SalePrice,horizontal=T)
housing_data[housing_data$Exterior2nd=="Concrete",'Exterior2nd']<-6
housing_data[housing_data$Exterior2nd=="Other",'Exterior2nd']<-5
housing_data[housing_data$Exterior2nd=="Brick",'Exterior2nd']<-4
housing_data[housing_data$Exterior2nd=="Wood",'Exterior2nd']<-3
housing_data[housing_data$Exterior2nd=="Metal",'Exterior2nd']<-2
housing_data[housing_data$Exterior2nd=="Rock",'Exterior2nd']<-1
housing_data$Exterior2nd<-as.numeric(housing_data$Exterior2nd)

plot(as.factor(housing_data$MasVnrType),housing_data$SalePrice,horizontal=T)
housing_data[housing_data$MasVnrType=="Rock",'MasVnrType']<-3
housing_data[housing_data$MasVnrType=="Brick",'MasVnrType']<-2
housing_data[housing_data$MasVnrType=="Other",'MasVnrType']<-1
housing_data$MasVnrType<-as.numeric(housing_data$MasVnrType)

plot(as.factor(housing_data$RoofStyle),housing_data$SalePrice,horizontal=T)
housing_data[housing_data$RoofStyle=="Hip",'RoofStyle']<-6
housing_data[housing_data$RoofStyle=="Shed",'RoofStyle']<-5
housing_data[housing_data$RoofStyle=="Gable",'RoofStyle']<-4
housing_data[housing_data$RoofStyle=="Flat",'RoofStyle']<-3
housing_data[housing_data$RoofStyle=="Mansard",'RoofStyle']<-2
housing_data[housing_data$RoofStyle=="Gambrel",'RoofStyle']<-1
housing_data$RoofStyle<-as.numeric(housing_data$RoofStyle)

plot(as.factor(housing_data$BldgType),housing_data$SalePrice,horizontal=T)
housing_data[housing_data$BldgType=="1Fam",'BldgType']<-5
housing_data[housing_data$BldgType=="TwnhsE",'BldgType']<-4
housing_data[housing_data$BldgType=="Twnhs",'BldgType']<-3
housing_data[housing_data$BldgType=="2fmCon",'BldgType']<-2
housing_data[housing_data$BldgType=="Duplex",'BldgType']<-1
housing_data$BldgType<-as.numeric(housing_data$BldgType)

plot(as.factor(housing_data$MiscFeature),housing_data$SalePrice,horizontal=T)
housing_data[housing_data$MiscFeature=="NA",'MiscFeature']<-5
housing_data[housing_data$MiscFeature=="TenC",'MiscFeature']<-4
housing_data[housing_data$MiscFeature=="Gar2",'MiscFeature']<-3
housing_data[housing_data$MiscFeature=="Shed",'MiscFeature']<-2
housing_data[housing_data$MiscFeature=="Othr",'MiscFeature']<-1
housing_data$MiscFeature<-as.numeric(housing_data$MiscFeature)


#Write to CSV
write.csv(housing_data,file="housingdata_clean.csv",row.names = F)

#Calculate runtime
end_time<-Sys.time()
print(end_time-start_time)
