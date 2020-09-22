#Initialize packages
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import time
import warnings
start_time = time.time()
pd.options.display.max_rows = 100

#Read in data
data=pd.read_csv(r'housingdata_clean.csv')
df = pd.DataFrame(data)



#Plot correlation matrix
corrMatrix = df[['LotFrontage','LotArea','MasVnrArea','TotalBsmtSF','BsmtUnfSF','FirstSF','SecondSF','GrLivArea','GarageArea',
       'GarageYrBlt','WoodDeckSF','OpenPorchSF','ThreeSsnPorch','ScreenPorch','Age','YrSinceRemodel','BsmtPUnf','Bathrooms']].corr()
plt.subplots(figsize=(20,15))
sns_plot = sns.heatmap(corrMatrix,cmap="RdBu",annot=True)
#fig = sns_plot.get_figure()
#fig.savefig("jupyter_heatmap.png")



#Plot potenitally problematic features
fig, (ax1, ax2, ax3) = plt.subplots(ncols=3, sharey=True,figsize=(14,5))
sns.scatterplot(data=df,x="LowQualFinSF",y="SalePrice",ax=ax1)
sns.scatterplot(data=df,x="EnclosedPorch",y="SalePrice",ax=ax2)
sns.scatterplot(data=df,x="PoolArea",y="SalePrice",ax=ax3);



#Determine correlations of individual features vs. sale price
print(df['LowQualFinSF'].corr(df['SalePrice']))
print(df['EnclosedPorch'].corr(df['SalePrice']))
print(df['PoolArea'].corr(df['SalePrice']))
#Since so weak, deleting from data
df.drop(['LowQualFinSF','EnclosedPorch','PoolArea'], axis=1, inplace=True)


#Determine correlations of individual features vs. sale price
print(df['Age'].corr(df['GarageYrBlt']))
print(df['Age'].corr(df['SalePrice']))
print(df['GarageYrBlt'].corr(df['SalePrice']))
#Removing GarageYrBuilt bc weaker correlation to SalePrice than Age
df.drop('GarageYrBlt', axis=1, inplace=True)


print(df['BsmtPUnf'].corr(df['BsmtFinSF1']))
print(df['BsmtPUnf'].corr(df['BsmtUnfSF']))
#Keeping BsmtPUnf because it represents proportion and not raw values
df.drop('BsmtUnfSF', axis=1, inplace=True)



import sklearn.model_selection as model_selection
from sklearn import linear_model
import sklearn.metrics as metrics
from sklearn.ensemble import RandomForestRegressor
from sklearn.feature_selection import RFE

train = df[~df['SalePrice'].isnull()]
test = df[df['SalePrice'].isnull()]
X_test = test.drop('SalePrice', axis=1)

X=train.drop('SalePrice', axis=1)
y=train[['SalePrice']]
Xval_train, Xval_test, yval_train, yval_test = model_selection.train_test_split(X,y,test_size=0.3, random_state=75)

#Initial Model
lm = linear_model.LinearRegression()  
lm.fit(Xval_train, yval_train)
ols_fitted = lm.predict(Xval_test)

#Calculate R Squared, RMSLE
print(metrics.r2_score(yval_test, ols_fitted))
print(np.sqrt(metrics.mean_squared_log_error(yval_test, ols_fitted)))



#Transformations
tplot = sns.regplot(x="LotArea", y="SalePrice", 
                    data=df, fit_reg=False)
tplot.set(xscale="log")
df['LotArea'] = np.log(df['LotArea'])
np.isinf(df['LotArea']).sum()



warnings.simplefilter("ignore")
df['YrSinceRemodel'] = df['YrSinceRemodel']**(1./3.)
df.loc[df['TotalBsmtSF']>5000,'TotalBsmtSF'] = np.mean(df['TotalBsmtSF'])
df['TotalBsmtSF'] = np.log(df['TotalBsmtSF'])
df['TotalBsmtSF'] = np.where(np.isinf(df['TotalBsmtSF']),0,df['TotalBsmtSF'])

fig, (ax1, ax2) = plt.subplots(ncols=2, sharey=True,figsize=(10,5))
sns.scatterplot(data=df,x="YrSinceRemodel",y="SalePrice",ax=ax1)
sns.scatterplot(data=df,x="TotalBsmtSF",y="SalePrice",ax=ax2);



#Remove high leverage points in other features
df.loc[df['FirstSF']>4000,'FirstSF'] = np.mean(df['FirstSF'])
df.loc[df['BsmtFinSF1']>3000,'BsmtFinSF1'] = np.mean(df['BsmtFinSF1'])

df.loc[(df['GrLivArea']>4000) & (df['SalePrice'].isnull()),'GrLivArea'] = np.mean(df['GrLivArea'])
df.loc[((df['GrLivArea']>4000) & (df['SalePrice']<=700000)),'GrLivArea'] = np.mean(df['GrLivArea'])
sns.scatterplot(data=df,x="GrLivArea",y="SalePrice");



#Remainder of transformations
df['ScreenPorch'] = 3 * df['ScreenPorch']
df.loc[(df['OverallQual']<5) & (df['SalePrice']>200000),'OverallQual'] = 5

df['GarageArea'] = np.log(df['GarageArea'])
df['GarageArea'] = np.where(np.isinf(df['GarageArea']),0,df['GarageArea'])
sns.scatterplot(data=df,x="GarageArea",y="SalePrice");



#Re-cut train and test to determine results of transformations on RMSLE
train = df[~df['SalePrice'].isnull()]
test = df[df['SalePrice'].isnull()]
X_test = test.drop('SalePrice', axis=1)

X=train.drop('SalePrice', axis=1)
y=train[['SalePrice']]
Xval_train, Xval_test, yval_train, yval_test = model_selection.train_test_split(X,y,test_size=0.3, random_state=75)

#OLS Model # 2
lm = linear_model.LinearRegression()  
lm.fit(Xval_train, yval_train)
ols_fitted = lm.predict(Xval_test)

#Calculate R Squared, RMSLE
print(metrics.r2_score(yval_test, ols_fitted))
print(np.sqrt(metrics.mean_squared_log_error(yval_test, ols_fitted)))



#Code provided by Abhini Shetye
nof_list=np.arange(1,75)            
high_score=0
nof=0           
score_list =[]
Variable to store the optimum features
for n in range(len(nof_list)):
    Xval_train, Xval_test, yval_train, yval_test = model_selection.train_test_split(X,y,test_size=0.3, random_state=75)
    model = linear_model.LinearRegression()
    rfe = RFE(model,nof_list[n])
    X_train_rfe = rfe.fit_transform(Xval_train,yval_train)
    X_test_rfe = rfe.transform(Xval_test)
    model.fit(X_train_rfe,yval_train)
    score = model.score(X_test_rfe,yval_test)
    score_list.append(score)
    if(score>high_score):
        high_score = score
        nof = nof_list[n]
print("Optimum number of features: %d" %nof)
print("Score with %d features: %f" % (nof, high_score))
#Optimum number of features: 69
#Score with 69 features: 0.875737


cols = list(X.columns)
model = linear_model.LinearRegression()
#Initializing RFE model
rfe = RFE(model, 69)             
#Transforming data using RFE
X_rfe = rfe.fit_transform(X,y)  
#Fitting the data to model
model.fit(X_rfe,y)              
temp = pd.Series(rfe.support_,index = cols)
selected_features_rfe = temp[temp==True].index
print(selected_features_rfe)



#Apply feature selection
X_test = X_test.filter(selected_features_rfe)
Xval_train = Xval_train.filter(selected_features_rfe)
Xval_test = Xval_test.filter(selected_features_rfe)

#OLS Model # 3
lm = linear_model.LinearRegression()  
lm.fit(Xval_train, yval_train)
ols_fitted = lm.predict(Xval_test)

#Calculate R Squared, RMSLE
print(metrics.r2_score(yval_test, ols_fitted))
print(np.sqrt(metrics.mean_squared_log_error(yval_test, ols_fitted)))



#Elastic Net
search=model_selection.GridSearchCV(estimator=enet,param_grid={'alpha':np.logspace(-5,2,8),'l1_ratio':[.2,.4,.6,.8]},scoring='neg_mean_squared_error',n_jobs=1,refit=True,cv=10)
search.fit(Xval_train,yval_train)
print(search.best_params_)

enet=linear_model.ElasticNet(normalize=True,alpha=0.001,l1_ratio=0.2)
enet.fit(Xval_train, yval_train)
enet_fitted = enet.predict(Xval_test)

#Calculate R Squared, RMSLE
print(metrics.r2_score(yval_test, enet_fitted))
print(np.sqrt(metrics.mean_squared_log_error(yval_test, abs(enet_fitted))))



#Random Forest
search = model_selection.GridSearchCV(estimator=RandomForestRegressor(),param_grid={'max_depth': range(3,7),'n_estimators': (10, 50, 100, 1000),},cv=10, scoring='neg_mean_squared_error',n_jobs=1)
search.fit(Xval_train,yval_train)
print(search.best_params_)

rf = RandomForestRegressor(max_depth = 6,n_estimators = 100, random_state = 75)
rf.fit(Xval_train,yval_train)
rf_fitted = rf.predict(Xval_test)

#Calculate R Squared, RMSLE
print(metrics.r2_score(yval_test, rf_fitted))
print(np.sqrt(metrics.mean_squared_log_error(yval_test, rf_fitted)))



#Basic Gradient Boosting
import lightgbm as lgb
train_data=lgb.Dataset(Xval_train,label=yval_train)

par = {'num_leaves':120,'metric':'l1' ,'objective':'regression','max_depth':7,'learning_rate':.05,'max_bin':200}
num_round = 1000
gbm = lgb.train(par,train_data,num_round)
gb_fitted = gbm.predict(Xval_test)

#Calculate R Squared, RMSLE
print(metrics.r2_score(yval_test, gb_fitted))
print(np.sqrt(metrics.mean_squared_log_error(yval_test, gb_fitted)))



#Hyperparameter optimization
n_folds = 5
def rmsle_cv(model):
    kf = model_selection.KFold(n_folds, shuffle=True, random_state=75).get_n_splits(Xval_train)
    rmse= np.sqrt(-model_selection.cross_val_score(model, Xval_train, yval_train, scoring="neg_mean_squared_error", cv = kf))
    return(rmse)

o_gbm = lgb.LGBMRegressor(objective='regression',num_leaves=5,
                              learning_rate=0.05, n_estimators=720,
                              max_bin = 55, bagging_fraction = 0.8,
                              bagging_freq = 5, feature_fraction = 0.2319,
                              feature_fraction_seed=9, bagging_seed=9,
                              min_data_in_leaf =6, min_sum_hessian_in_leaf = 11)
score = rmsle_cv(o_gbm)
o_gbm.fit(Xval_train, yval_train)
ogb_fitted = o_gbm.predict(Xval_test)

#Calculate R Squared, RMSLE
print(metrics.r2_score(yval_test, ogb_fitted))
print(np.sqrt(metrics.mean_squared_log_error(yval_test, ogb_fitted)))



#Feature Importance
fimportance_df = pd.DataFrame()
fimportance_df["feature"] = Xval_train.columns
fimportance_df["importance"] = o_gbm.feature_importances_
#Filter out near-zero features
fimportance_df = fimportance_df.loc[fimportance_df['importance']>=10]

plt.figure(figsize=(8, 10))
sns.barplot(x="importance", y="feature", data=fimportance_df.sort_values(by="importance", ascending=False),palette="viridis")
plt.title('Optimized GB Feature Importance')
plt.tight_layout()
#plt.savefig('ogbm_importance.png')



#Ensembling
pred_rmsles = [10,10,10,10,10,10,10,10,10,10,10]
#enet_fitted vs. rf_fitted vs. (o)gb_fitted

for i in range(0,11):
    replace = ((1-(i/10))*ogb_fitted)+((i/10)*rf_fitted)
    replace = [abs(i) for i in replace]
    pred_rmsles[i] = np.sqrt(metrics.mean_squared_log_error(yval_test, replace))

print(pred_rmsles)
print("The maximum is at position", pred_rmsles.index(min(pred_rmsles))+1)



#Ensembling with multiple models
multiple_ensemble = ((0.75 * ogb_fitted) + (0.15 * enet_fitted) + (0.1 * gb_fitted))

#Calculate R Squared, RMSLE
print(metrics.r2_score(yval_test, multiple_ensemble))
print(np.sqrt(metrics.mean_squared_log_error(yval_test, multiple_ensemble)))



#Apply to test set

#Option1: Single Prediction
#ogb_predict = o_gbm.predict(X_test)
#output = pd.DataFrame({'Id':range(1461, 1461+len(X_test))})
#output['SalePrice'] = ogb_predict


#Option2: Ensemble Prediction
gb_predict = gbm.predict(X_test)
ogb_predict = o_gbm.predict(X_test)
enet_predict = enet.predict(X_test)
rf_predict = rf.predict(X_test)
ensemble = ((0.75 * ogb_predict) + (0.15 * enet_predict) + (0.1 * gb_predict))
output = pd.DataFrame({'Id':range(1461, 1461+len(X_test))})
output['SalePrice'] = ensemble

output.to_csv(r'output.csv',header=True, index = False)

#Print Runtime
print("--- %s seconds ---" % round(time.time() - start_time, 2))