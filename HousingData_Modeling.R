#Part 2: Modeling
library(readxl)
library(dplyr)
library(MASS)

start_time<-Sys.time()
housing_data<-read.csv('housingdata_clean.csv',stringsAsFactors = FALSE)

train<-housing_data[!is.na(housing_data$SalePrice),]

#Think these plots may be problematic and need removing
plot(housing_data$LowQualFinSF,housing_data$SalePrice)
plot(housing_data$EnclosedPorch,housing_data$SalePrice)
plot(housing_data$PoolArea,housing_data$SalePrice)

cor(train$SalePrice,train$LowQualFinSF)
cor(train$SalePrice,train$EnclosedPorch)
cor(train$SalePrice,train$PoolArea)

#remove all bc all have very week correlation with SalePrice
housing_data<-housing_data[,-60]
housing_data<-housing_data[,-41]
housing_data<-housing_data[,-61]


#Collected all numeric columns to check for multicollinearity, need for
#standardization/transformation 
num_columns<-c("LotFrontage","LotArea","MasVnrArea","TotalBsmtSF","BsmtUnfSF",
               "FirstSF","SecondSF","GrLivArea","GarageArea","GarageYrBlt",
               "WoodDeckSF","OpenPorchSF","ThreeSsnPorch","ScreenPorch","Age",
               "YrSinceRemodel","BsmtPUnf","Bathrooms")

#Generate Correlation table and visual correlation matrix
cor<-cor(train[,num_columns])
library(corrplot)
corrplot(cor, method="circle")

#Collinearity between Lot Frontage and Lot area 0.62409014
#Despite high collinearity, keeping because both are strong predictors of SalePrice

#Collinearity between Age and GarageYrBuilt 0.84514067
cor(train$SalePrice,train$Age)
cor(train$SalePrice,train$GarageYrBlt)
#Removing GarageYrBuilt bc weaker correlation to SalePrice than Age
housing_data<-housing_data[-50]
num_columns<-num_columns[-10]

#Collinearity between BsmtPUnf and BsmtFinSF1 0.708626367
#BsmtPUnf and BsmtUnfSF 0.826271944
#Keeping BsmtPUnf because it represents proportion and not raw values, getting rid of
#BsmtUnfSF to prevent interference in OLS
housing_data<-housing_data[-33]
num_columns<-num_columns[-5]



#Model 1: OLS
#Split into train/test & collect RSMLE before transformations
train<-housing_data[!is.na(housing_data$SalePrice),]
test<-housing_data[is.na(housing_data$SalePrice),]
ols_model1 <- lm(SalePrice~.,data=train)
summary(ols_model1)

#Performing Transformations to see if they can improve the overall OLS model
plot(housing_data$LotArea,housing_data$SalePrice)
plot(sqrt(housing_data$LotArea),housing_data$SalePrice)
plot((1/(1+housing_data$LotArea)),housing_data$SalePrice)
plot(log(housing_data$LotArea),housing_data$SalePrice)
#going with the log
housing_data$LotArea<-log(housing_data$LotArea)
housing_data[housing_data$LotArea=="-Inf",'LotArea']<-0

plot(housing_data$YrSinceRemodel^(1/3),housing_data$SalePrice)
#Using cubed root to show negative linear relationship
housing_data$YrSinceRemodel<-housing_data$YrSinceRemodel^(1/3)

plot(housing_data$TotalBsmtSF,housing_data$SalePrice)
replace<-round(mean(housing_data$TotalBsmtSF))
housing_data[housing_data$TotalBsmtSF>5000,'TotalBsmtSF']<-mean(replace)
plot(log(housing_data$TotalBsmtSF),housing_data$SalePrice)
housing_data$TotalBsmtSF<-log(housing_data$TotalBsmtSF)
housing_data[housing_data$TotalBsmtSF=="-Inf",'TotalBsmtSF']<-0

#Removed high leverage point in 1stFlrSf
housing_data[housing_data$FirstSF>4000,'FirstSF']<-mean(housing_data$FirstSF)

#Removed high leverage point in BsmtFinSF1
housing_data[housing_data$BsmtFinSF1>3000,'BsmtFinSF1']<-mean(housing_data$BsmtFinSF1)

plot(housing_data$GrLivArea,housing_data$SalePrice)
replace<-mean(train$GrLivArea)
housing_data[which(housing_data$GrLivArea>4000 & housing_data$SalePrice<=700000|housing_data$GrLivArea>4000 & is.na(housing_data$SalePrice)),'GrLivArea']<-replace

plot(log(housing_data$GarageArea),housing_data$SalePrice)
housing_data$GarageArea<-log(housing_data$GarageArea)
housing_data[housing_data$GarageArea=="-Inf",'GarageArea']<-0

#Improved from 0.000423 -> 0.000395
housing_data$ScreenPorch<-3*housing_data$ScreenPorch

#Re-run the OLS to see how R Squared affected by transformations
train<-housing_data[!is.na(housing_data$SalePrice),]
test<-housing_data[is.na(housing_data$SalePrice),]

ols_model2 <- lm(SalePrice~.,data=train)
summary(ols_model2)



#Model 2: Stepwise OLS
#step <- stepAIC(ols_model2, direction="both")
#step$anova
step_both<-lm(SalePrice ~ MSSubClass + LotFrontage + LotArea + Utilities + 
                LotConfig + LandSlope + Condition1 + OverallQual + OverallCond + 
                RoofStyle + RoofMatl + Exterior1st + MasVnrArea + ExterQual + 
                ExterCond + BsmtQual + BsmtExposure + BsmtFinSF1 + BsmtFinType2 + 
                BsmtFinSF2 + TotalBsmtSF + Heating + Electrical + FirstSF + 
                SecondSF + GrLivArea + BedroomAbvGr + KitchenAbvGr + KitchenQual + 
                Functional + GarageType + GarageFinish + GarageCars + GarageArea + 
                GarageQual + WoodDeckSF + ScreenPorch + PoolQC + NumFloors + 
                BsmtPUnf + Age + New + Commercial + FireplaceQu,data=train)
summary(step_both)

#step_forward <- stepAIC(ols_model2, direction="forward")
#step_forward$anova
step_forward<-lm(SalePrice ~ MSSubClass + LotFrontage + LotArea + Street + Alley + 
                   LotShape + LandContour + Utilities + LotConfig + LandSlope + 
                   Neighborhood + Condition1 + Condition2 + BldgType + OverallQual + 
                   OverallCond + RoofStyle + RoofMatl + Exterior1st + Exterior2nd + 
                   MasVnrType + MasVnrArea + ExterQual + ExterCond + Foundation + 
                   BsmtQual + BsmtCond + BsmtExposure + BsmtFinType1 + BsmtFinSF1 + 
                   BsmtFinType2 + BsmtFinSF2 + TotalBsmtSF + Heating + HeatingQC + 
                   CentralAir + Electrical + FirstSF + SecondSF + GrLivArea + 
                   BedroomAbvGr + KitchenAbvGr + KitchenQual + TotRmsAbvGrd + 
                   Functional + Fireplaces + FireplaceQu + GarageType + GarageFinish + 
                   GarageCars + GarageArea + GarageQual + GarageCond + PavedDrive + 
                   WoodDeckSF + OpenPorchSF + ThreeSsnPorch + ScreenPorch + 
                   PoolQC + Fence + MiscFeature + MiscVal + MoSold + YrSold + 
                   SaleType + SaleCondition + NumFloors + HouseFinish + BsmtPUnf + 
                   Bathrooms + Age + YrSinceRemodel + New + Commercial,data=train)
summary(step_forward)

#step <- stepAIC(ols_model2, direction="backward")
#step$anova
step_backward<-lm(SalePrice ~ MSSubClass + LotFrontage + LotArea + Utilities + 
                    LotConfig + LandSlope + Condition1 + OverallQual + OverallCond + 
                    RoofStyle + RoofMatl + Exterior1st + MasVnrArea + ExterQual + 
                    ExterCond + BsmtQual + BsmtExposure + BsmtFinSF1 + BsmtFinType2 + 
                    BsmtFinSF2 + TotalBsmtSF + Heating + Electrical + FirstSF + 
                    SecondSF + GrLivArea + BedroomAbvGr + KitchenAbvGr + KitchenQual + 
                    Functional + GarageType + GarageFinish + GarageCars + GarageArea + 
                    GarageQual + WoodDeckSF + ScreenPorch + PoolQC + NumFloors + 
                    BsmtPUnf + Age + New + Commercial,data=train)
summary(step_backward)


#Split into validate train and test randomly
set.seed(75)
train_ind <- sample(seq_len(nrow(train)), size = floor(0.7 * nrow(train)))
validate_train <- train[train_ind, ]
validate_test <- train[-train_ind, ]

library(Metrics)
ols.fitted <- predict(ols_model1,newdata=validate_test)
ols.fitted[which(ols.fitted<0)]<-abs(ols.fitted[which(ols.fitted<0)])
error<-rmsle(validate_test$SalePrice,ols.fitted)
error #0.2421673

ols.fitted <- predict(ols_model2,newdata=validate_test)
ols.fitted[which(ols.fitted<0)]<-abs(ols.fitted[which(ols.fitted<0)])
error<-rmsle(validate_test$SalePrice,ols.fitted)
error #0.1498343

both.fitted <- predict(step_both,newdata=validate_test)
error<-rmsle(validate_test$SalePrice,both.fitted)
error #0.1469933

forward.fitted <- predict(step_forward,newdata=validate_test)
forward.fitted[which(forward.fitted<0)]<-abs(forward.fitted[which(forward.fitted<0)])
error<-rmsle(validate_test$SalePrice,forward.fitted)
error #0.1498343

back.fitted <- predict(step_backward,newdata=validate_test)
error<-rmsle(validate_test$SalePrice,back.fitted)
error #0.1469933

#Going with Both as it has the lowest RMSLE
ols_model<-step_both



#Model 3: Polynomial Regression
#For poly put all the features in and put 2nd degree polynomial for each of the ones that
#have an apparently quadratic relationship
poly_model<-lm(SalePrice ~ MSSubClass + LotFrontage + LotArea + Street + Alley + 
                 LotShape + LandContour + Utilities + LotConfig + LandSlope + 
                 Neighborhood + Condition1 + Condition2 + BldgType + OverallQual + 
                 OverallCond + RoofStyle + RoofMatl + Exterior1st + Exterior2nd + 
                 MasVnrType + MasVnrArea + ExterQual + ExterCond + Foundation + 
                 BsmtQual + BsmtCond + BsmtExposure + BsmtFinType1 + BsmtFinSF1 + 
                 BsmtFinType2 + BsmtFinSF2 + TotalBsmtSF + Heating + HeatingQC + 
                 CentralAir + Electrical + poly(FirstSF,2,raw=T) + SecondSF + GrLivArea + 
                 BedroomAbvGr + KitchenAbvGr + KitchenQual + TotRmsAbvGrd + 
                 Functional + Fireplaces + FireplaceQu + GarageType + GarageFinish + 
                 GarageCars + GarageArea + GarageQual + GarageCond + PavedDrive + 
                 WoodDeckSF + OpenPorchSF + ThreeSsnPorch + ScreenPorch + 
                 PoolQC + Fence + MiscFeature + MiscVal + MoSold + YrSold + 
                 SaleType + SaleCondition + NumFloors + HouseFinish + BsmtPUnf + 
                 Bathrooms + poly(Age,2,raw=T) + YrSinceRemodel + New + Commercial,
                data=train)
#Also tried Poly on TotalBsmtSF, GrLivArea,and  but they decreased model RMSLE
summary(poly_model)

poly.fitted <- predict(poly_model,newdata=validate_test)
error<-rmsle(validate_test$SalePrice,poly.fitted)
error #0.1425319



#Model 4: Ridge, Lasso, Elastic Net Regression
library(glmnet)
train<-housing_data[!is.na(housing_data$SalePrice),]
test<-housing_data[is.na(housing_data$SalePrice),]
validate_train <- train[train_ind, ]
validate_test <- train[-train_ind, ]

y<-validate_train$SalePrice
x<-data.matrix(validate_train[,-67])
xnew<-data.matrix(validate_test[,-67])

cv.out <- cv.glmnet(x, y, alpha=0, nlambda=100, lambda.min.ratio=0.0001)
plot(cv.out)
best.lambda <- cv.out$lambda.min
best.lambda #was 24821.9, now 6876.934

rmsles<-0
# alpha 0 ridge, alpha 1 LASSO
for (i in 0:10) {
  model<-glmnet(x,y,alpha=i/10,nlambda = 100, lambda.min.ratio=0,standardize = TRUE)
  fitted.results <- predict(model,s=best.lambda,newx=xnew)
  fitted.results<-abs(fitted.results)
  rmsles[i]<-rmsle(validate_test$SalePrice,fitted.results)
}

rmsles
min(rmsles)
rmsles[7]

#Elastic net chosen, alpha=0.2 on 50% validation set and 0.7 on 70% validation train
enet_model<-glmnet(x,y,alpha=0.7,nlambda = 100, lambda.min.ratio=0,standardize = TRUE)
enet.fitted<-predict(enet_model,s=best.lambda,newx=xnew)
error<-rmsle(validate_test$SalePrice,enet.fitted)
error #0.1648151


#Random Forest
library(randomForest)

#error.bag<-0
#for (i in 1:74){
#  bag.house=randomForest(SalePrice~.,mtry=i,validate_train,importance=TRUE)
#  yhat.house = predict(bag.house,mtry=i,newdata=validate_test)
#  error.bag[i]<-rmsle(validate_test$SalePrice,yhat.house)
#}

error.bag<-c(0.2274555,0.1718773,0.1611817,0.1566194,0.1551772,0.1525404,
             0.1510553,0.1520002,0.1517172,0.1507572,0.1503473,0.1505908,
             0.1507651,0.1503753,0.1512496,0.1500346,0.1495613,0.1511179,
             0.1499379,0.1504011,0.1504805,0.1509515,0.1505135,0.1507352,
             0.1509615,0.1500946,0.1500345,0.1506053,0.1510781,0.1506822,
             0.1519326,0.1510075,0.1501223,0.1508313,0.1509766,0.1519841,
             0.1507625,0.1504607,0.1505907,0.1501098,0.1505320,0.1503323,
             0.1510927,0.1504840,0.1505804,0.1512766,0.1509918,0.1515258,
             0.1512600,0.1517276,0.1508588,0.1514667,0.1521470,0.1509810,
             0.1510652,0.1514559,0.1513501,0.1521374,0.1512269,0.1524595,
             0.1519946,0.1517997,0.1520564,0.1525723,0.1523241,0.1519591,
             0.1518582,0.1528970,0.1533325,0.1524626,0.1523205,0.1532770,
             0.1527862,0.1539374)

min(error.bag)
#Minimum at 29
error.bag[29]

bag.house=randomForest(SalePrice~.,mtry=29,validate_train,importance=TRUE)
yhat.house = predict(bag.house,mtry=29,newdata=validate_test)
error.bag<-rmsle(validate_test$SalePrice,yhat.house)
error.bag # 0.1355805

random_model<-randomForest(SalePrice~.,mtry=29,train,importance=TRUE)

#Gradient Boosting model
library(xgboost)
library(caret)

trainvalidatex<-data.matrix(train[,-67])
trainvalidatey<-train$SalePrice

dtrain <- xgb.DMatrix(data = trainvalidatex,label = trainvalidatey) 
dtest <- xgb.DMatrix(data = data.matrix(validate_test[,-67]),label=validate_test$SalePrice)

#cv <- train(SalePrice ~., data = train, method = "xgbTree",
#trControl = trainControl("cv", number = 5))

#cv$bestTune

boost_model <- xgboost(dtrain,nrounds=150,max_depth=3,eta=0.3,gamma=0,
                       colsample_bytree=0.8,min_child_weight=1,subsample=1)

boost.fitted<- predict(boost_model, newdata=dtest)
serror<-rmsle(validate_test$SalePrice,boost.fitted)
serror #0.05523038

#Apply final model to test set
boost.predict<-predict(boost_model,newdata=data.matrix(validate_test)[,-67]) 
poly.predict<-predict(poly_model,newdata=validate_test)

pred_rmsles<-0
for (i in 0:10){
  replace<-((1-(i/10))*boost.predict)+((i/10)*poly.predict)
  replace[which(replace<0)]<-abs(replace[which(replace<0)])
  pred_rmsles[i]<-rmsle(validate_test$SalePrice,replace)
}

pred_rmsles
min(pred_rmsles) #minmum 0.06294109 at alpha = 0 
#100% boosting 0% poly

boost.predict<-predict(boost_model,newdata=data.matrix(validate_test)[,-67]) 
rforrest.predict<-predict(random_model,newdata = validate_test)

pred_rmsles<-0
for (i in 0:10){
  replace<-((1-(i/10))*boost.predict)+((i/10)*rforrest.predict)
  pred_rmsles[i]<-rmsle(validate_test$SalePrice,replace)
  
}

pred_rmsles
min(pred_rmsles) #0.05155053
#Min Alpha = 5, 0.5 boost and 0.5 random forrest

train_ind <- sample(seq_len(nrow(train)), size = floor(0.5 * nrow(train)))
validate_train <- train[train_ind, ]
validate_test <- train[-train_ind, ]

boost.predict<-predict(boost_model,newdata=data.matrix(validate_test)[,-67]) 
poly.predict<-predict(poly_model,newdata=validate_test)

pred_rmsles<-0
for (i in 0:10){
  replace<-((1-(i/10))*boost.predict)+((i/10)*poly.predict)
  replace[which(replace<0)]<-abs(replace[which(replace<0)])
  pred_rmsles[i]<-rmsle(validate_test$SalePrice,replace)
}

pred_rmsles
min(pred_rmsles) #Min 0.05955391
#Alpha = 0, 100% boost and 0% poly

boost.predict<-predict(boost_model,newdata=data.matrix(validate_test)[,-67]) 
rforrest.predict<-predict(random_model,newdata = validate_test)

pred_rmsles<-0
for (i in 0:10){
  replace<-((1-(i/10))*boost.predict)+((i/10)*rforrest.predict)
  pred_rmsles[i]<-rmsle(validate_test$SalePrice,replace)
}

pred_rmsles
min(pred_rmsles) # 0.05242982
#Min is also Alpha = 4, 0.6 boost and 0.4 random forrest


#Going with alpha of 0.5 between boost and random forrest for lowest RMSLE
poly.predict<-predict(poly_model,newdata=test)
boost.predict<-predict(boost_model,newdata=data.matrix(test)[,-67]) 
rforrest.predict<-predict(random_model,newdata = test)

housing_data$ID<-seq(1:nrow(housing_data))
train<-housing_data[!is.na(housing_data$SalePrice),]
test<-housing_data[is.na(housing_data$SalePrice),]

test$SalePrice<-((1-(2/10))*boost.predict)+((2/10)*poly.predict)

test<-data.frame(test$ID,test$SalePrice)
colnames(test)<-c("ID","SalePrice")  

#Calculate runtime
end_time<-Sys.time()
print(end_time-start_time)

write.csv(test,file="best_model.csv",row.names = F)
