# 📊 Customer Segmentation using RFM Analysis (SQL)

> **An advanced SQL project demonstrating data extraction, transformation, and customer behavior analysis using the RFM (Recency, Frequency, Monetary) model.**

---

## 🎯 Project Objective
To segment customers based on their purchasing behavior. This allows the marketing and sales teams to tailor targeted campaigns, optimize retention strategies, and maximize overall revenue.

---

## 📊 Data Source
The dataset used in this project is publicly available on Kaggle. It contains transactional records including customer IDs, purchase dates, product categories, and transaction amounts.
* **Source:** [raw_rfm_sales_transactions_(V2).csv](https://www.kaggle.com/datasets/charmmyaeaung/raw-sales-dataset-for-rfm-customer-segmentation?select=raw_rfm_sales_transactions_%28V2%29.csv)
* **Size:** 2,000 transactions from 812 customers, covering Jan–Dec 2025.
---

## 🛠️ Technical Skills Demonstrated
* **Database Management:** Schema Design, Raw-to-Clean Staging Layer, Indexing
* **Data Wrangling:** Type Casting, String Manipulation, Date Standardization, Data Validation
* **Advanced SQL:** Window Functions (`NTILE`), Common Table Expressions (CTEs), Subqueries
* **Business Intelligence:** Data Aggregation, Customer Cohort Segmentation

---

## 📂 Project Structure & Workflow

### 📄 `01_schema_and_setup.sql` (Data Cleaning & Preprocessing)
* Kept `Customer_DB` as the raw layer (loaded as-is from CSV) and built a separate `Customer_Clean` staging table, so raw data is never modified.
* Converted string columns to proper types (`Quantity` → `INT`, `PPU`/`Amount` → `DECIMAL(12,2)`) and standardized `DD-MM-YYYY` strings into native `DATE`.
* Validated the output: row counts match the raw table (2,000), no invalid quantities or amounts, and `Amount = Quantity × PPU` on every row.
* Created an index on `(customer_id, order_date, amount)` to support the RFM aggregation query.

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
| ⚠️ **At Risk** | Purchased often (F ≥ 4) but haven't returned lately (R ≤ 2). | Send personalized "We miss you" win-back offers. |
| 💤 **Lost / Hibernating**| Haven't purchased recently and bought rarely (R ≤ 2, F ≤ 2). | Do not spend high marketing budget here. |
| 📦 **Regular Customers** | All remaining customers who don't fit the segments above. | Nurture with standard promotions to move them up. |

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
1. Clone this repository to your local machine. Requires **MySQL 8.0+** (CTEs and window functions).
2. Open `01_schema_and_setup.sql` and run only the `CREATE TABLE Customer_DB` block first (one-time setup).
3. Import `raw_rfm_sales_transactions_(V2).csv` into `Customer_DB` and confirm 2,000 rows.
4. Run the rest of `01_schema_and_setup.sql` to build `Customer_Clean`, validate it, and create the index. The raw table is untouched, so this part is safe to re-run.
5. Run `02_rfm_analysis_and_insights.sql` to build the RFM view and view business insights.

---
*Created by Poomrat Thanapasee | Connect with me on [LinkedIn](https://www.linkedin.com/in/poomrat-thanapasee-6a99443b3/)*
