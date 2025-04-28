# Collaborative Filtering Recommendation System

This project implements a **Collaborative Filtering (CF)** recommendation system for books using the **Amazon Books dataset** and **Amazon Reviews**.  
The system was developed in **R**, leveraging user-based (UBCF) and item-based (IBCF) collaborative filtering models.

## Project Overview

- **Database Connection**: Connected to an Oracle database to retrieve large-scale book and rating datasets.
- **Data Preprocessing**:
  - Removed sparse users (≤11 ratings) and books (≤6 ratings) to improve model robustness.
  - Filtered out zero ratings to focus on meaningful user preferences.
- **Modeling**:
  - Built User-Based Collaborative Filtering (UBCF) and Item-Based Collaborative Filtering (IBCF) models using **cosine similarity**.
  - Applied 80/20 train-test split with k=5 folds and 8 known ratings per user.
- **Evaluation**:
  - Calculated **RMSE (Root Mean Square Error)** for both individual users and overall performance.
  - Visualized RMSE distributions for UBCF and IBCF models using histograms.
- **Results**:
  - Saved trained models and evaluation sets.
  - Generated sample rating predictions for 500 users.

## Technologies Used

- **R**
- **recommenderlab**
- **dplyr**
- **ggplot2**
- **odbc** / **DBI**
