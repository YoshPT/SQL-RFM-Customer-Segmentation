# 📊 Customer Segmentation using RFM Analysis (SQL)

> **An advanced SQL project demonstrating data extraction, transformation, and customer behavior analysis using the RFM (Recency, Frequency, Monetary) model.**

---

## 🎯 Project Objective
To segment customers based on their purchasing behavior. This allows the marketing and sales teams to tailor targeted campaigns, optimize retention strategies, and maximize overall revenue.

---

## 📊 Data Source
The dataset used in this project is publicly available on Kaggle. It contains transactional records including customer IDs, purchase dates, product categories, regions, and transaction amounts.
* **Source:** [raw_rfm_sales_transactions_(V2).csv](https://www.kaggle.com/datasets/charmmyaeaung/raw-sales-dataset-for-rfm-customer-segmentation?select=raw_rfm_sales_transactions_%28V2%29.csv)
* **Size:** 2,000 transactions from 812 customers, covering Jan–Dec 2025.

---

## 🛠️ Technical Skills Demonstrated
* **Database Management:** Schema Design, Raw-to-Clean Staging Layer, Indexing, Views
* **Data Wrangling:** Type Casting, String Manipulation, Date Standardization, Data Validation
* **Advanced SQL:** Window Functions (`CUME_DIST`, `SUM() OVER`), Common Table Expressions (CTEs), Subqueries
* **Business Intelligence:** Data Aggregation, Customer Cohort Segmentation


---

## 📂 Project Structure & Workflow

### 📄 `01_schema_and_setup.sql` (Data Cleaning & Preprocessing)
* Kept `Customer_DB` as the raw layer (loaded as-is from CSV) and built a separate `Customer_Clean` staging table, so raw data is never modified.
* Converted string columns to proper types (`Quantity` → `INT`, `PPU`/`Amount` → `DECIMAL(12,2)`) and standardized `DD-MM-YYYY` strings into native `DATE`.
* Validated the output: row counts match the raw table (2,000), no invalid quantities or amounts, and `Amount = Quantity × PPU` on every row.
* Created a covering index on `(customer_id, order_date, amount)` to support the RFM aggregation query (verified with `EXPLAIN`: `Using index`).

### 📄 `02_rfm_analysis_and_insights.sql` (RFM Modeling & Insights)
Calculated RFM metrics using **CTEs** inside a view (`vw_customer_segmentation`) and assigned scores from 1 to 5:
* **Recency (R):** Days since the last purchase, scored with `CUME_DIST()` (reversed scoring: 5 is best).
* **Frequency (F):** Number of distinct transactions, scored with **fixed thresholds** (1, 2, 3, 4, 5+ purchases) instead of percentiles, because many customers bought only once.
* **Monetary (M):** Total amount spent, scored with `CUME_DIST()` (5 is the highest spend).


Customers were categorized into strategic groups based on their RFM scores:

| Segment | Description | Actionable Strategy |
| :--- | :--- | :--- |
| 🏆 **Champions** | Bought very recently, buy often, and spend a lot (R = 5, F ≥ 4, M ≥ 4). | Reward them, offer early access to new products. |
| 🤝 **Loyal Customers** | Bought fairly recently, purchase regularly, and spend good money (R = 3–4, F ≥ 4, M ≥ 4). | Upsell higher-value products, ask for reviews. |
| 👋 **New Customers** | Bought recently but only once so far (R ≥ 4, F = 1). | Provide onboarding support, offer 2nd-purchase discounts. |
| ⚠️ **At Risk** | Purchased several times with decent spend but haven't returned lately (R ≤ 2, F ≥ 3, M ≥ 3). | Send personalized "We miss you" win-back offers. |
| 💤 **Lost / Hibernating** | Haven't purchased recently and bought rarely (R ≤ 2, F ≤ 2). | Do not spend high marketing budget here. |
| 📦 **Regular Customers** | All remaining customers not matched above (e.g., mid-recency R = 3, repeat buyers with F = 2–3 and R ≥ 4, or frequent buyers with lower spend). | Nurture with standard promotions to move them up. |

---

## 💡 Key Business Insights

Using the segmented data, this project answers 5 critical business questions:
1. **Win-back Campaign:** Identified the top 10 highest-spending "At Risk" customers for the sales team to contact directly.
2. **Product Preference:** Discovered which product categories our "Champions" buy the most to create bundle promotions.
3. **Regional Churn Analysis:** Pinpointed geographic regions with the highest share of "Lost" customers to investigate operational issues.
4. **Average Order Value (AOV):** Compared the AOV of Champions vs. Regular Customers to adjust pricing and discount strategies.
5. **Customer Acquisition by Month:** Counted first-time buyers per month to guide ad spend and stock planning (see the caveats below).

---

### 📈 Results Snapshot
*(Amounts are in the dataset's currency units; the currency is not specified.)*

* **Revenue concentration:** Champions and Loyal customers (122 customers, 15.0%) generate 69.8% of revenue.
* **Win-back (insight 1):** 60 customers are "At Risk". The top three accounts (Customer-180: 1.08B over 9 orders, Customer-074: 1.03B over 3 orders, Customer-663: 0.40B over 5 orders) make up about 54% of this segment's revenue, so they warrant personal outreach.
* **Product preference (insight 2):** Champions' revenue comes from Electronics (68.2%), Furniture (29.7%), and Office Supplies (2.1%). Office Supplies is 20.1% of their orders but only 2.1% of revenue, which makes it a natural add-on for bundles.
* **Regional churn (insight 3):** Taunggyi (40.3%), Naypyitaw (39.7%), and Bago (37.4%) have a higher share of "Lost" customers than Mandalay (26.8%) and Yangon (25.5%).
* **AOV (insight 4):** Champions' average order value is about 4.1x that of Regular customers (51.1M vs 12.4M).
* **Acquisition (insight 5):** 167 customers (20.6%) first purchased in January, then 96–107 per month in February–April, falling to 25–29 in November–December. 57.8% had made their first purchase by the end of April.

---
## ⚠️ Limitations & Future Improvements

* **Small, single-year dataset:** 2,000 transactions from 812 customers (Jan–Dec 2025). Segment sizes are modest, seasonality can't be separated from trend, and the covering index shows no measurable speedup at this size. It is designed to support RFM aggregation as the data grows.
* **Tied values affect scoring:** R and M use `CUME_DIST()`, so customers with identical values always share the same score. Recency is measured in whole days, so ties are common and score groups are not exactly 20% each. Frequency uses fixed thresholds for the same reason (292 of 812 customers bought only once, and 207 bought twice), which makes F = 1 and F = 2 very large groups.
* **Rule-based segments, not validated:** The segment rules are heuristic and haven't been tested against real outcomes. A natural next step is an A/B test of the win-back campaign on "At Risk" customers.
* **"Regular Customers"** is a catch-all for everyone not matched by the other rules and is the largest segment (about 38% of customers). It mixes mid-recency customers (R = 3) and recent repeat buyers (F = 2–3), so it should be split into finer segments.
* **Recency is relative to the dataset:** It is measured from the latest transaction date in the data, not today's date.
* **"Lost" is a proxy for churn:** Low recency and frequency suggest, but do not confirm, that a customer has churned. Regional patterns (insight 3) are hypotheses to investigate, not proven causes.
* **Acquisition-by-month caveats:** January may look inflated because customers who bought before 2025 are counted as "first-time" buyers. With a finite customer base, first-time buyers also tend to decline over time naturally, so monthly differences are not proof of seasonality.
* **Revenue, not profit:** The data has no cost or margin, so segment value is based on sales amount only.
* **Large orders dominate revenue:** Order values are highly skewed (median 7.75M vs. max 600M), so a few large accounts drive revenue shares and the win-back ranking. Rank-based scoring (`CUME_DIST`) limits their effect on segment assignment, but revenue figures should be read with this in mind.
* * **Future improvements:** Split "Regular Customers" into finer segments (e.g., Potential Loyalists, Need Attention), a Power BI/Tableau dashboard for the segments, and customer lifetime value using profit data.


---

## 🚀 How to Run the Code
1. Clone this repository to your local machine. Requires **MySQL 8.0+** (CTEs and window functions).
2. Open `01_schema_and_setup.sql` and run section 0 (`CREATE DATABASE` and `CREATE TABLE Customer_DB`) first (one-time setup).
3. Import `raw_rfm_sales_transactions_(V2).csv` into `Customer_DB` and confirm 2,000 rows.
4. Run the rest of `01_schema_and_setup.sql` to build `Customer_Clean`, validate it, and create the index. The raw table is never modified. To re-run this step, first run `DROP TABLE Customer_RFM.Customer_Clean;` (this also drops its index).
5. Run `02_rfm_analysis_and_insights.sql` to build the RFM view and view business insights. The view uses `CREATE OR REPLACE`, so this file can be re-run safely.

---
*Created by Poomrat Thanapasee | Connect with me on [LinkedIn](https://www.linkedin.com/in/poomrat-thanapasee-6a99443b3/)*
