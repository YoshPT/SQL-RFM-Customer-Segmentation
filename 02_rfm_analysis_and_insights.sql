-- ==========================================
-- 5. FEATURE ENGINEERING & RFM MODELING
-- ==========================================
-- (คำนวณค่าตัวแปรใหม่, ให้คะแนน R/F/M, และจัดกลุ่ม Segment)
CREATE OR REPLACE VIEW Customer_RFM.vw_customer_segmentation AS
WITH rfm_raw AS (
    -- ดึงค่าดิบและคำนวณวันล่าสุด, จำนวนครั้ง, และยอดใช้จ่ายของลูกค้าแต่ละคน
    SELECT 
        customer_id,
        DATEDIFF((SELECT MAX(order_date) FROM Customer_RFM.Customer_Clean), MAX(order_date)) AS Recency,
        COUNT(DISTINCT transaction_id) AS Frequency,
        SUM(amount) AS Monetary
    FROM Customer_RFM.Customer_Clean
    GROUP BY customer_id
),
rfm_scoring AS (
    -- แปลงค่าดิบให้เป็นคะแนน 1-5 (R, M ใช้ NTILE / F ใช้เกณฑ์ตายตัวตามจำนวนครั้งที่ซื้อ)
    SELECT 
        customer_id,
        Recency,
        Frequency,
        Monetary,
        -- Recency: เรียงวันจากน้อยไปมาก แล้วลบด้วย 6 เพื่อกลับค่า (ซื้อล่าสุดได้คะแนน 5)
        6 - NTILE(5) OVER (ORDER BY Recency ASC) AS R_Score,
        
        -- Frequency: ใช้เกณฑ์ตายตัว เพราะลูกค้าซื้อครั้งเดียวมีจำนวนมาก (NTILE จะแบ่งคนที่ซื้อเท่ากันไปคนละกลุ่ม)
        CASE
            WHEN Frequency >= 5 THEN 5
            WHEN Frequency = 4  THEN 4
            WHEN Frequency = 3  THEN 3
            WHEN Frequency = 2  THEN 2
            ELSE 1
        END AS F_Score,
        
        -- Monetary: ยิ่งเยอะ คะแนนยิ่งสูง (เรียงจากน้อยไปมาก)
        NTILE(5) OVER (ORDER BY Monetary ASC) AS M_Score
    FROM rfm_raw
)
-- ประกอบร่างคะแนนรวม และกำหนดเงื่อนไขแบ่งกลุ่มลูกค้า (Customer Segmentation)
SELECT 
    customer_id,
    Recency, Frequency, Monetary,
    R_Score, F_Score, M_Score,
    -- นำคะแนนมารวมกันเป็นรหัส เช่น 555, 142
    CONCAT(R_Score, F_Score, M_Score) AS RFM_Score,
    
    -- จัด Segment ตามหลักเศรษฐศาสตร์พฤติกรรมลูกค้า
    CASE 
        WHEN R_Score = 5 AND F_Score IN (4, 5) AND M_Score IN (4, 5) THEN 'Champions'
        WHEN R_Score IN (3, 4) AND F_Score IN (4, 5) AND M_Score IN (4, 5) THEN 'Loyal Customers'
        WHEN R_Score IN (4, 5) AND F_Score IN (1, 2) THEN 'New Customers'
        WHEN R_Score IN (1, 2) AND F_Score IN (4, 5) THEN 'At Risk'
        WHEN R_Score IN (1, 2) AND F_Score IN (1, 2) THEN 'Lost / Hibernating'
        ELSE 'Regular Customers'
    END AS Customer_Segment
FROM rfm_scoring;

-- ==========================================
-- MODEL VALIDATION & SEGMENT OVERVIEW
-- ==========================================
-- (ตรวจสอบความถูกต้องของผลลัพธ์ และสรุปภาพรวมของกลุ่มลูกค้าทั้งหมด)

-- เรียกดูข้อมูลและคะแนนของลูกค้าแต่ละราย (Validation)
SELECT * 
FROM Customer_RFM.vw_customer_segmentation
LIMIT 100;

-- สรุปจำนวนลูกค้าในแต่ละกลุ่ม (Segment Distribution)
SELECT 
    Customer_Segment,
    COUNT(customer_id) AS Total_Customers,
    SUM(Monetary) AS Total_Revenue
FROM Customer_RFM.vw_customer_segmentation
GROUP BY Customer_Segment
ORDER BY Total_Revenue DESC;

-- ==========================================
-- 6. BUSINESS INSIGHTS & ANALYTICAL QUERIES
-- ==========================================
-- 6.1) แคมเปญดึงลูกค้าเก่ากลับมา (Win-back Campaign)
-- คำถาม: ลูกค้ากลุ่ม "At Risk" (เคยซื้อบ่อย แต่ช่วงหลังหายไป) ที่มียอดใช้จ่ายสูงสุด 10 อันดับแรกคือใคร?
-- การนำไปใช้: ส่งรายชื่อให้ทีมเซลส์เพื่อโทรเสนอโปรโมชันพิเศษ หรือส่ง Email Marketing ดึงตัวกลับมาด่วน
SELECT 
    customer_id, 
    Recency, 
    Frequency, 
    Monetary
FROM Customer_RFM.vw_customer_segmentation
WHERE Customer_Segment = 'At Risk'
ORDER BY Monetary DESC
LIMIT 10;

-- 6.2) วิเคราะห์สินค้าที่โดนใจแฟนพันธุ์แท้ (Loyalty & Product Preference)
-- คำถาม: ลูกค้ากลุ่ม "Champions" มักจะซื้อสินค้าในหมวดหมู่ไหน (Product Category) มากที่สุด?
-- การนำไปใช้: นำไปออกแบบโปรโมชันแบบ Bundle หรือ Cross-sell เพื่อทำกำไรสูงสุดจากกลุ่มลูกค้าชั้นดี
SELECT 
    c.product_category,
    COUNT(c.transaction_id) AS Total_Orders,  -- นับจำนวนครั้งที่สั่งซื้อทั้งหมด
    SUM(c.amount) AS Revenue_From_Champions   -- รวมยอดขายที่ได้จากลูกค้ากลุ่มนี้
FROM Customer_RFM.Customer_Clean c
JOIN Customer_RFM.vw_customer_segmentation v 
  ON c.customer_id = v.customer_id
WHERE v.Customer_Segment = 'Champions'        -- กรองเอาเฉพาะลูกค้าเกรดดีที่สุด
GROUP BY c.product_category                   -- จัดกลุ่มยอดขายตามหมวดหมู่สินค้า
ORDER BY Revenue_From_Champions DESC;         -- เรียงลำดับจากหมวดหมู่ที่ทำรายได้สูงสุดไปต่ำสุด

-- 6.3) วิเคราะห์ปัญหาเชิงพื้นที่ (Regional Churn Analysis)
-- คำถาม: ลูกค้าที่อยู่ในกลุ่ม "Lost / Hibernating" ส่วนใหญ่กระจุกตัวอยู่ในภูมิภาคไหน? (อาจบ่งบอกถึงปัญหาด้านการขนส่ง หรือคู่แข่งในพื้นที่นั้น)
-- การนำไปใช้: แจ้งทีม Operation ให้ตรวจสอบปัญหาในพื้นที่นั้น (เช่น ขนส่งล่าช้า) หรือจัดโปรโมชันสู้คู่แข่งในพื้นที่
SELECT 
    c.region,
    COUNT(DISTINCT v.customer_id) AS Total_Churned_Customers -- นับจำนวนลูกค้าที่หายไปแบบไม่ซ้ำคน
FROM Customer_RFM.Customer_Clean c
JOIN Customer_RFM.vw_customer_segmentation v 
  ON c.customer_id = v.customer_id
WHERE v.Customer_Segment = 'Lost / Hibernating'
GROUP BY c.region                                           -- จัดกลุ่มตามภูมิภาค
ORDER BY Total_Churned_Customers DESC;                      -- เรียงจากพื้นที่ที่มีลูกค้าหายไปมากที่สุด

-- 6.4) เปรียบเทียบพฤติกรรมการใช้จ่าย (Average Order Value - AOV)
-- คำถาม: ลูกค้ากลุ่ม "Champions" มียอดใช้จ่ายต่อบิล (AOV) แตกต่างจากกลุ่ม "Regular Customers" มากแค่ไหน? 
-- การนำไปใช้: เพื่อประเมินกลยุทธ์ราคา เช่น เสนอส่วนลดให้กลุ่ม Regular และเสนอการอัปเกรดสินค้าให้กลุ่ม Champions
SELECT 
    v.Customer_Segment,
    COUNT(DISTINCT c.transaction_id) AS Total_Orders,
    SUM(c.amount) AS Total_Revenue,
    ROUND(SUM(c.amount) / COUNT(DISTINCT c.transaction_id), 2) AS Average_Order_Value
FROM Customer_RFM.Customer_Clean c
JOIN Customer_RFM.vw_customer_segmentation v 
  ON c.customer_id = v.customer_id
WHERE v.Customer_Segment IN ('Champions', 'Regular Customers')
GROUP BY v.Customer_Segment;

-- 6.5) วิเคราะห์ช่วงเวลาทองในการหาลูกค้าใหม่ (Peak Season for Acquisition)
-- คำถาม: ลูกค้ากลุ่ม "New Customers" ส่วนใหญ่เข้ามาซื้อสินค้าในเดือนไหนมากที่สุด? 
-- การนำไปใช้: วางแผนจัดสรรงบประมาณการตลาด (ยิงแอด) หรือเตรียมสต็อกสินค้าให้สอดคล้องกับเดือนที่เป็น Peak Season
SELECT 
    MONTH(c.order_date) AS Order_Month,
    COUNT(DISTINCT v.customer_id) AS Total_New_Customers,
    SUM(c.amount) AS Revenue_From_New
FROM Customer_RFM.Customer_Clean c
JOIN Customer_RFM.vw_customer_segmentation v 
  ON c.customer_id = v.customer_id
WHERE v.Customer_Segment = 'New Customers'
GROUP BY MONTH(c.order_date)
ORDER BY Total_New_Customers DESC;
