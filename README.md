📊 Customer Segmentation using RFM Analysis (SQL)

📝 Project Overview

The primary objective of this project is to analyze and segment customers based on their historical purchasing behavior using RFM (Recency, Frequency, Monetary) Analysis. This segmentation model empowers marketing and sales teams to understand customer behavior and design highly targeted, data-driven campaigns.

💼 Business Impact

By effectively segmenting the customer base, this project provides the following business value:

Targeted Marketing: Identified "Champions" (VIP customers) to offer exclusive cross-sell and up-sell promotions, ultimately increasing the Average Order Value (AOV).

Churn Prevention: Discovered "At Risk" customers (formerly high-value buyers whose engagement has dropped) to launch immediate win-back campaigns before losing them to competitors.

Resource Optimization: Improved marketing budget allocation by focusing resources on key revenue-generating segments rather than utilizing a "spray and pray" approach.

🛠️ Tech Stack & SQL Skills Used

Database: MySQL (Update this if you used PostgreSQL, SQL Server, etc.)

Key SQL Techniques Demonstrated:

Data Cleaning & Preprocessing (REPLACE, STR_TO_DATE, ALTER TABLE)

Common Table Expressions (CTEs) & Views (CREATE OR REPLACE VIEW)

Window Functions (NTILE()) for dynamic scoring

Aggregations (COUNT, SUM, DATEDIFF)

Data Joins & Grouping

🚀 Key Business Questions Answered

This project utilizes SQL to extract actionable insights by answering 5 critical business questions:

Win-back Campaign: Who are the top 10 "At Risk" customers with the highest spending history? (Action: Forward list to the sales team for personalized follow-ups).

Loyalty Preference: Which product categories do our "Champions" purchase the most?

Regional Churn Analysis: In which geographical regions are our "Lost / Hibernating" customers mostly concentrated?

Average Order Value (AOV): How significantly does the AOV of "Champions" differ from that of "Regular Customers"?

Peak Season for Acquisition: During which months do we acquire the most "New Customers"?

Note: The specific SQL queries and their results can be found in the provided .sql file.

📁 Repository Structure

RFM Segmentation.sql: The complete SQL script encompassing everything from Database Creation and Data Cleaning to the final Business Analytics Queries.

[Your_Dataset_Name].csv: The dataset used for this analysis. (Optional: Include if you are allowed to share the data).

⚙️ How to Run

Import the raw Customer_DB data into your local database.

Open and run the RFM Segmentation.sql script sequentially (from Section 0 to 5).

The script will automatically handle data cleaning, build performance indexes, and generate the vw_customer_segmentation view.

Execute the queries in Section 5 to explore the business insights.

Created by [Your Name] - Let's connect on LinkedIn!
