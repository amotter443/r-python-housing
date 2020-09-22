#Initialize packages
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import time
start_time = time.time()
pd.options.display.max_rows = 100

#Read in data
data=pd.read_excel(r'HousePricesCompleteData.xlsx')
df = pd.DataFrame(data)

#Remove exteraneous columns
df.drop(df.columns[0], axis=1,inplace = True)
df.head()


#Count NAs in Features
df.apply(lambda a: a.isnull().sum(),axis=0).sort_values()



#All values with an NA for BsmtFinSF1, BsmtFinSF2, and BsmtUnfSF have no basement, so set all to 0
for i in ['BsmtFinSF1','BsmtFinSF2','BsmtUnfSF']: 
    df[i] = np.where(df[i].isnull(),0,df[i])
#Same process for TotalBsmtSF,BsmtFullBath, BsmtHalfBath 
for i in ['BsmtUnfSF','TotalBsmtSF','BsmtFullBath','BsmtHalfBath']: 
    df[i] = np.where(df[i].isnull(),0,df[i])



#Garages also NA when missing, same process for GarageCars, GarageArea
df.loc[df.GarageCars.isnull(),['GarageCars','GarageArea']] = 0
#Fill garage year built NAs with year house was built
df.loc[df.GarageYrBlt.isnull(),'GarageYrBlt'] = df.loc[df.GarageYrBlt.isnull(),'YearBuilt'] 
#Correct data entry error in column
df.loc[df.GarageYrBlt==2207,'GarageYrBlt'] = 2007



#Remove exteraneous C (all) from MSZoning
df.MSZoning = df.MSZoning.str.replace(' \(all\)','')
#Consolidating all the Residential values together
df.loc[df.MSZoning.isin(["RH","RL","RP","RM","FV"]),'MSZoning'] = "R"
#For NANs, Recoding to R because 4 obs are all 1 family buildings from pre 1945
df.loc[df.MSZoning.isnull(),'MSZoning'] = "R"
#Convert MSZoning to categorical
df.MSZoning = df.MSZoning.astype('category')



#Lot frontage has a square root relationship with lot area, use existing data to derive approximations
df.loc[df.LotFrontage.isnull(),'LotFrontage'] = round(np.sqrt(df.loc[df.LotFrontage.isnull(),'LotArea']))

#If lot shape is regular 1, else 0 in standard boolean format
df['LotShape'] = [1 if x == "Reg" else 0 for x in df['LotShape']]




#If there is no masonry veneer, type is none and area is 0
df.loc[df['MasVnrType'].isnull(), 'MasVnrType'] = "None"
df.loc[df['MasVnrType']=="None", 'MasVnrArea'] = 0




#Reduced number of building materials to the following: Wood, Rock, Concrete, Brick, Metal, and Other
ind = ['RoofMatl', 'Exterior1st', 'Exterior2nd', 'MasVnrType', 'Foundation']

for i in ind: 
    df[i] = np.where(df[i].isin(["ClyTile","Tar&Grv","Stone","Stucco"]),'Rock',df[i])
    
for i in ind:
    df[i] = np.where(df[i].isin(["WdShake","WdShngl","Plywood","WdShing","Wd Sdng","Wd Shng",]),'Wood',df[i])

for i in ind: 
    df[i] = np.where(df[i].isin(["CmentBd","CemntBd","CBlock","PConc","Slab"]),'Concrete',df[i])

for i in ind: 
    df[i] = np.where(df[i].isin(["Brk Cmn","BrkComm","BrkFace","BrkCmn","BrkTil"]),'Brick',df[i])

for i in ind: 
    df[i] = np.where(df[i].isin(["CompShg","Membran","Roll","AsbShng","AsphShn","HdBoard","ImStucc","VinylSd","PreCast","None"]),'Other',df[i])

for i in ind: 
    df[i] = np.where(df[i]=="MetalSd",'Metal',df[i])

for i in ind: 
    df[i] = np.where(df[i].isin(["CompShg","Membran","Roll","AsbShng","AsphShn","HdBoard","ImStucc","VinylSd","PreCast","None"]),'Other',df[i])

for i in ind: 
    df[i] = np.where(df[i].isnull(),'Other',df[i])



#Convert ordinals to numeric
ind = ['ExterCond', 'ExterQual', 'BsmtCond', 'BsmtQual', 'BsmtExposure','BsmtFinType1','BsmtFinType2','HeatingQC','KitchenQual','Functional','PoolQC','GarageCond','GarageQual','FireplaceQu']

for i in ind: 
    df[i] = np.where(df[i].isin(["Ex","EX","No","Mn"]),9,df[i])
    
for i in ind: 
    df[i] = np.where(df[i].isin(["Gd","GLQ"]),7,df[i])
    
for i in ind: 
    df[i] = np.where(df[i].isin(["TA","Typ","ALQ","Rec","Av"]),5,df[i])

for i in ind: 
    df[i] = np.where(df[i].isin(["Fa","BLQ","Min1","Min2","Mod"]),3,df[i])

for i in ind: 
    df[i] = np.where(df[i].isin(["Po","Maj1","Maj2","Sev","Sal","LwQ","Unf"]),1,df[i])
    
for i in ind: 
    df[i] = np.where(df[i].isnull(),0,df[i])



#For PavedDrive & Central Air, recoded to 1,0 True False structure
#PavedDrive had a "Partial" option which was recoded to 0.5
df.loc[df.PavedDrive=="P",'PavedDrive'] = 0.5
for i in ['PavedDrive','CentralAir']: df[i] = np.where(df[i]=="N",0,df[i])
for i in ['PavedDrive','CentralAir']: df[i] = np.where(df[i]=="Y",1,df[i])   



#New feature for number of floors
df['NumFloors'] = [1 if x <=0 else 2 for x in df['2ndFlrSF']]
df.loc[df.HouseStyle.isin(["1.5Fin","2.5Fin","2.5Unf","1.5Unf"]),'NumFloors'] = df.loc[df.HouseStyle.isin(["1.5Fin","2.5Fin","2.5Unf","1.5Unf"]),'NumFloors']+0.5



#Create new HouseFinish feature
df.loc[(df['HouseStyle']=="2.5Unf") | (df['HouseStyle']=="1.5Unf") | (df['BsmtUnfSF']>0) | (df['GarageFinish']=="Unf"),'HouseFinish']=0
df.loc[df.HouseFinish.isnull(),'HouseFinish']=1
#Remove HouseStyle
df.drop("HouseStyle", axis=1, inplace = True)

#Determine what proportion of the basement is unfinished
df['BsmtPUnf'] = round((df['BsmtUnfSF']/df['TotalBsmtSF'])*100)
df.loc[df['BsmtPUnf'].isnull(),'BsmtPUnf'] = 0



#Consolidate bathrooms into singular feature
df['Bathrooms'] = df['FullBath'] + (df['HalfBath']*0.5) + df['BsmtFullBath'] + (df['BsmtHalfBath']* 0.5)
df.Bathrooms.value_counts()
#Drop previous columns
df.drop(["FullBath","HalfBath","BsmtFullBath","BsmtHalfBath"], axis = 1, inplace = True) 

#New Date features:
df['Age'] = 2020 - df['YearBuilt']
df['YrSinceRemodel'] = 2020 - df['YearRemodAdd']
df['New'] = np.where((df['YrSold']==df['YearBuilt']),1,0)
df.drop(["YearBuilt","YearRemodAdd"], axis = 1, inplace = True) 



#Create new features
df['Commercial'] = [1 if x =="C" else 0 for x in df['MSZoning']]
df.drop("MSZoning", axis = 1, inplace = True) 
df['Street'] = [1 if x =="Pave" else 0 for x in df['Street']]
df.loc[(df.Alley.isin(["Grvl","NA","None"]))|(df.Alley.isnull()),'Alley'] = 0
df.loc[df.Alley=="Pave",'Alley'] = 1

#Recode utilities
df.loc[df.Utilities=="AllPub",'Utilities'] = 4
df.loc[df.Utilities=="NoSewr",'Utilities'] = 3
df.loc[df.Utilities=="NoSeWa",'Utilities'] = 2
df.loc[df.Utilities=="ELO",'Utilities'] = 1
df.loc[df.Utilities.isnull(),'Utilities'] = 0

#Update column names
df.rename(columns={'1stFlrSF':'FirstSF','2ndFlrSF':'SecondSF','3SsnPorch':'ThreeSsnPorch'}, inplace=True)



#Recode misc. columns to numeric
df.loc[df['Electrical'].isin(["Mix","FuseA","FuseF","FuseP"]),'Electrical'] = 0
df.loc[df['Electrical']=="SBrkr",'Electrical'] = 1
df['SaleCondition'] = [1 if x =="Normal" else 0 for x in df['SaleCondition']]
df['GarageType'] = np.where(df['GarageType'].isin(["2Types","CarPort","Detchd"]),0,1)
df['GarageFinish'] = np.where(df['GarageFinish'].isin(["RFn","Unf"]),0,1)
df['LandContour'] = np.where(df['LandContour'].isin(["Bnk","HLS","Low"]),0,1)

#Close out NAs
df.loc[df['LandSlope']=="Sev",'LandSlope'] = 3
df.loc[df['LandSlope']=="Mod",'LandSlope'] = 2
df.loc[df['LandSlope']=="Gtl",'LandSlope'] = 1

df.loc[df['Fence'].isin(["GdPrv","GdWo"]),'Fence'] = 7
df.loc[df['Fence'].isin(["MnPrv","MnWw"]),'Fence'] = 3

df.loc[df['SaleType'].isin(["WD","CWD","VWD"]),'SaleType'] = 4
df.loc[df['SaleType']=="New",'SaleType'] = 3
df.loc[df['SaleType'].isin(["ConLD","ConLI","ConLw","Con"]),'SaleType'] = 2
df.loc[df['SaleType'].isin(["COD","Oth","Other"]),'SaleType'] = 1

df.loc[df['MiscFeature'].isnull(),'MiscFeature'] = 5
df.loc[df['MiscFeature']=="TenC",'MiscFeature'] = 4
df.loc[df['MiscFeature']=="Gar2",'MiscFeature'] = 3
df.loc[df['MiscFeature']=="Shed",'MiscFeature'] = 2
df.loc[df['MiscFeature']=="Othr",'MiscFeature'] = 1

df.loc[df['Heating'].isin(["Floor","Grav","Wall"]),'Heating'] = 2
df.loc[df['Heating'].isin(["GasA","GasW"]),'Heating'] = 3
df.loc[df['Heating']=="OthW",'Heating'] = 1

for i in ['Electrical','Fence','SaleType']: 
    df[i] = np.where(df[i].isnull(),0,df[i])



#Condition 1 & 2
for i in ['Condition1','Condition2']: 
    df[i] = np.where(df[i].isin(["Artery","Feedr"]),"Street",df[i])
for i in ['Condition1','Condition2']: 
    df[i] = np.where(df[i].isin(["RRNn","RRAn","RRNe","RRAe"]),"RR",df[i])
for i in ['Condition1','Condition2']: 
    df[i] = np.where(df[i].isin(["PosN","PosA"]),"Pos",df[i])
fig, (ax1, ax2) = plt.subplots(ncols=2, sharey=True)
sns.boxplot(data=df,x="Condition1",y="SalePrice",palette="viridis",ax=ax1)
sns.boxplot(data=df,x="Condition2",y="SalePrice",palette="viridis",ax=ax2)

for i in ['Condition1','Condition2']: 
    df[i] = np.where(df[i]=="Street",1,df[i])
for i in ['Condition1','Condition2']: 
    df[i] = np.where(df[i]=="RR",2,df[i])
for i in ['Condition1','Condition2']: 
    df[i] = np.where(df[i]=="Pos",3,df[i])    
for i in ['Condition1','Condition2']: 
    df[i] = np.where(df[i]=="Norm",4,df[i])
    
#Convert string Neighborhood column to numeric categories
df['Neighborhood'] = df['Neighborhood'].astype('category')
df['Neighborhood'] = df['Neighborhood'].cat.codes + 1



#RoofStyle, BldgType, Lot Config
fig, (ax1, ax2, ax3) = plt.subplots(ncols=3, sharey=True,figsize=(14,5))
sns.boxplot(data=df,x="RoofStyle",y="SalePrice",palette="coolwarm",ax=ax1)
sns.boxplot(data=df,x="BldgType",y="SalePrice",palette="twilight",ax=ax2)
sns.boxplot(data=df,x="LotConfig",y="SalePrice",palette="Blues",ax=ax3)

df.loc[df['RoofStyle']=="Hip",'RoofStyle'] = 6
df.loc[df['RoofStyle']=="Shed",'RoofStyle'] = 5
df.loc[df['RoofStyle']=="Gable",'RoofStyle'] = 4
df.loc[df['RoofStyle']=="Flat",'RoofStyle'] = 3
df.loc[df['RoofStyle']=="Mansard",'RoofStyle'] = 2
df.loc[df['RoofStyle']=="Gambrel",'RoofStyle'] = 1

df.loc[df['BldgType']=="1Fam",'BldgType'] = 5
df.loc[df['BldgType']=="TwnhsE",'BldgType'] = 4
df.loc[df['BldgType']=="Twnhs",'BldgType'] = 3
df.loc[df['BldgType']=="2fmCon",'BldgType'] = 2
df.loc[df['BldgType']=="Duplex",'BldgType'] = 1

df.loc[df['LotConfig']=="CulDSac",'LotConfig'] = 5
df.loc[df['LotConfig']=="FR3",'LotConfig'] = 4
df.loc[df['LotConfig']=="Corner",'LotConfig'] = 3
df.loc[df['LotConfig']=="Inside",'LotConfig'] = 2
df.loc[df['LotConfig']=="FR2",'LotConfig'] = 1



#RoofMatl, MasVnrType
fig, (ax1, ax2) = plt.subplots(ncols=2, sharey=True)
sns.boxplot(data=df,x="RoofMatl",y="SalePrice",palette="terrain",ax=ax1)
sns.boxplot(data=df,x="MasVnrType",y="SalePrice",palette="terrain",ax=ax2)

df.loc[df['RoofMatl']=="Other",'RoofMatl'] = 4
df.loc[df['RoofMatl']=="Wood",'RoofMatl'] = 3
df.loc[df['RoofMatl']=="Metal",'RoofMatl'] = 2
df.loc[df['RoofMatl']=="Rock",'RoofMatl'] = 1

df.loc[df['MasVnrType']=="Rock",'MasVnrType'] = 3
df.loc[df['MasVnrType']=="Brick",'MasVnrType'] = 2
df.loc[df['MasVnrType']=="Other",'MasVnrType'] = 1



#Exterior 1st and 2nd (same recoding), Foundation
fig, (ax1, ax2, ax3) = plt.subplots(ncols=3, sharey=True,figsize=(14,5))
sns.boxplot(data=df,x="Exterior1st",y="SalePrice",palette="terrain",ax=ax1)
sns.boxplot(data=df,x="Exterior2nd",y="SalePrice",palette="terrain",ax=ax2)
sns.boxplot(data=df,x="Foundation",y="SalePrice",palette="terrain",ax=ax3)

df.loc[df['Foundation']=="Concrete",'Foundation'] = 4
df.loc[df['Foundation']=="Wood",'Foundation'] = 3
df.loc[df['Foundation']=="Rock",'Foundation'] = 2
df.loc[df['Foundation']=="Brick",'Foundation'] = 1

for i in ['Exterior1st','Exterior2nd']: 
    df[i] = np.where(df[i]=="Rock",1,df[i])
for i in ['Exterior1st','Exterior2nd']: 
    df[i] = np.where(df[i]=="Metal",2,df[i])
for i in ['Exterior1st','Exterior2nd']: 
    df[i] = np.where(df[i]=="Wood",3,df[i])    
for i in ['Exterior1st','Exterior2nd']: 
    df[i] = np.where(df[i]=="Brick",4,df[i])
for i in ['Exterior1st','Exterior2nd']: 
    df[i] = np.where(df[i]=="Other",5,df[i])
for i in ['Exterior1st','Exterior2nd']: 
    df[i] = np.where(df[i]=="Concrete",6,df[i])



#Print cleaned data
df.to_csv(r'housingdata_clean.csv',header=True, index = False)

#Print Runtime
print("--- %s seconds ---" % round(time.time() - start_time, 2))