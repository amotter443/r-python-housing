# r-python-housing
>Modeling housing data using both R and Python

The [House Prices Kaggle competiton](https://www.kaggle.com/c/house-prices-advanced-regression-techniques) is a common project for budding data scientists to familiarize themselves with regression methods and how to apply them to predicting price data. Whether you are learning R or Python, whether you are an experienced programmer or just starting your first language, this repo has something for you. The R scripts were originally written during my undergrad and re-written a year later more efficiently and effectively using Python. For more detailed report on this project and its methodology, please check out my [LinkedIn article](https://www.linkedin.com/pulse/how-i-upskilled-my-data-science-expertise-python-alex-motter/)


Who is this project for?
------------------------
- Intermediate data scientists looking to apply several models to a regression problem
- R or Python proficient developers looking to transfer skills into the other language
- Data scientists proficient in both languages looking to benchmark their skillset
- Early analytics/data science students looking to challenge themselves with more difficult methods


Usage
--------
- Read `HousePricesCompleteData.xlsx` into your environment
- Familiarize yourself with the data using `Data Dictionary.txt`
- If modeling the data in R, start with `HousingData_Cleaning.R` and use its output to run `HousingData_Modeling.R`, adjusting the file paths as needed
- If modeling in Python, likewise start with `HousingData_Cleaning.py` and use its output to run `HousingData_Modeling.py`
- Submit predictions to [Kaggle](https://www.kaggle.com/c/house-prices-advanced-regression-techniques) (the script is formatted to produce the output in the style needed for Kaggle's scoring algorithm, but a sample submission is also available on the competition page for reference)


Simplifications Options 
------------------
- For those not interested in the more challenging Bayesian optimization process in `HousingData_Modeling.py`, this can be omitted for a still rather successful model
- A significant focus of this script is data cleaning and pre-processing. A less scrupulous cleaning process that relies more on automated methods like one-hot encoding can decrease the overall project time. However, doing so has been shown to decrease success of the models in the Kaggle competition
- One process that occupies a significant amount of runtime and computational power is the optimization of the various algorithm's hyperparameters for performance with the training set. While not advisable, omitting or only deploying on a subset of models can decrease time to insight and overall project time


Extension Options 
-----------------
- This project, while still able to reach the top 15% out of almost 5000 teams, was conducted only using the provided dataset. Other entrants had fortune integrating external data and augmenting the dataset with more information including information seasonality, geographic data, and other related information. Integrating related data could help boost the model's performance beyond that of the Bayesian optimized model
- While extensive time was spent determining the optimal ensemble combinations, hyperparameter weights, etc. further energy could be invested in extending this research. Some entrants had success ensembling 5+ algorithm's predictions and scaling their net output to game a better RMSLE, and similar efforts could likely propel the final model's output into the top 10%
- Despite the integration of Bayesian optimization and more complicated models like gradient boosting, deep learning integration could finally improve the model's output. A well-diversified neural network architecture, potentially ensembled with other successful models like the gradient boosting one, would more perfectly capture the nuances of the training data without overfitting. The decision to do so would need to be weighed against the time and resource-related costs of doing so
