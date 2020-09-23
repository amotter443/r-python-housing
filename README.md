# r-python-housing
>Modeling housing data using both R and Python

The [House Prices Kaggle competiton](https://www.kaggle.com/c/house-prices-advanced-regression-techniques) is a common project for budding data scientists to familiarize themselves with regression methods and how to apply them to predicting price data. Whether you are learning R or Python, whether you are an experienced programmer or just starting your first language, this repo has something for you. The R scripts were originally written during my undergrad and re-written a year later more efficiently and effectively using Python. For more detail on this project's process, please check out my [LinkedIn article](https://www.linkedin.com/pulse/how-i-upskilled-my-data-science-expertise-python-alex-motter/)!

Who is this project for?
------------------------
- Example A
- Example B
- Example C


Usage
--------
- Read `HousePricesCompleteData.xlsx` into your environment
- Familiarize yourself with the data using `Data Dictionary.txt`
- If modeling the data in R, start with `HousingData_Cleaning.R` and use its output to run `HousingData_Modeling.R`, adjusting the file paths as needed
- If modeling in Python, likewise start with `HousingData_Cleaning.py` and use its output to run `HousingData_Modeling.py`
- Submit predictions to [Kaggle](https://www.kaggle.com/c/house-prices-advanced-regression-techniques) (the script is formatted to produce the output in the style needed for Kaggle's scoring algorithm, but a sample submission is also available on the competition page for reference)


Simplifications Options 
------------------
- Skip Baysean optimization (Python)
- Less scrupulous cleaning (both)
- Omit hyperparameter optimizing (both)


Extension Options 
-----------------
- Integrating external data
