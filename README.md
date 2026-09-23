# 📊 Customer Segmentation using RFM Analysis (SQL)

> **An advanced SQL project demonstrating data extraction, transformation, and customer behavior analysis using the RFM (Recency, Frequency, Monetary) model.**

---

## 🎯 Project Objective
To segment customers based on their purchasing behavior. This allows the marketing and sales teams to tailor targeted campaigns, optimize retention strategies, and maximize overall revenue.

---

## 📊 Data Source
The dataset used in this project is publicly available on Kaggle. It contains transactional records including customer IDs, purchase dates, product categories, and transaction amounts.
* **Source:** [raw_rfm_sales_transactions_(V2).csv](https://www.kaggle.com/datasets/charmmyaeaung/raw-sales-dataset-for-rfm-customer-segmentation?select=raw_rfm_sales_transactions_%28V2%29.csv)

---

## 🛠️ Technical Skills Demonstrated
* **Database Management:** Schema Design, Indexing for Performance Optimization
* **Data Wrangling:** Type Casting, String Manipulation, Handling Missing Values
* **Advanced SQL:** Window Functions (`NTILE`), Common Table Expressions (CTEs), Subqueries
* **Business Intelligence:** Data Aggregation, Customer Cohort Segmentation

---

## 📂 Project Structure & Workflow

### 📄 `01_schema_and_setup.sql` (Data Cleaning & Preprocessing)
* Created the database schema and applied `CREATE INDEX` on key columns to improve query execution time.
* Converted raw string data (e.g., `PPU`, `Amount`) to proper `INT` formats.
* Standardized date strings into native SQL `DATE` format.

### 📄 `02_rfm_analysis_and_insights.sql` (RFM Modeling & Insights)
Calculated RFM metrics using **CTEs** and assigned scores (1-5) using `NTILE()` window functions:
* **Recency (R):** Days since the last purchase (reversed scoring: 5 is best).
* **Frequency (F):** Total number of transactions.
* **Monetary (M):** Total amount spent.

Customers were categorized into strategic groups based on their RFM scores:

| Segment | Description | Actionable Strategy |
| :--- | :--- | :--- |
| 🏆 **Champions** | Bought recently, buy often, and spend the most. | Reward them, offer early access to new products. |
| 🤝 **Loyal Customers** | Spend good money and purchase regularly. | Upsell higher-value products, ask for reviews. |
| 👋 **New Customers** | Bought recently but not frequently yet. | Provide onboarding support, offer 2nd-purchase discounts. |
| ⚠️ **At Risk** | Spent big and often, but haven't returned lately. | Send personalized "We miss you" win-back offers. |
| 💤 **Lost / Hibernating**| Lowest recency, frequency, and monetary scores. | Do not spend high marketing budget here. |

---

## 💡 Key Business Insights

Using the segmented data, this project answers 5 critical business questions:
1. **Win-back Campaign:** Identified the top 10 highest-spending "At Risk" customers for the sales team to contact directly.
2. **Product Preference:** Discovered which product categories our "Champions" buy the most to create bundle promotions.
3. **Regional Churn Analysis:** Pinpointed geographic regions with the highest number of "Lost" customers to investigate operational issues.
4. **Average Order Value (AOV):** Compared the AOV of Champions vs. Regular Customers to adjust pricing and discount strategies.
5. **Peak Acquisition Season:** Analyzed the months that brought in the most "New Customers" to optimize future ad spend.

---

## 🚀 How to Run the Code
1. Clone this repository to your local machine.
2. Open `01_schema_and_setup.sql` and run only the `CREATE TABLE` block first to create an empty table.
3. Import the provided `raw_rfm_sales_transactions_(V2).csv` dataset into the `Customer_DB` table.
4. Run the rest of `01_schema_and_setup.sql` to clean the data and create indexes.
5. Run `02_rfm_analysis_and_insights.sql` to execute the RFM model and view business insights.

---
*Developed by [Poomrat Thanapasee]* | *[[LinkedIn Profile Link](https://www.linkedin.com/in/poomrat-thanapasee-6a99443b3/)]*
