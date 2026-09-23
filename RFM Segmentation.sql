-- ==========================================
-- 0. SCHEMA DESIGN & TABLE CREATION
-- ==========================================
-- ⚠️ สิ่งที่ต้องทำ: คลุมดำและรันโค้ดส่วนนี้ก่อน เพื่อสร้างตารางเตรียมไว้สำหรับ Import ไฟล์ CSV
CREATE TABLE Customer_DB (
    `Transaction ID` VARCHAR(100) PRIMARY KEY,
    Date VARCHAR(20),
    `Product ID` VARCHAR(50),
    `Product Name` VARCHAR(255),
    `Product Category` VARCHAR(100),
    Quantity VARCHAR(50),
    PPU VARCHAR(50),
    Amount VARCHAR(50),
    `Customer ID` VARCHAR(100) NOT NULL,
    Region VARCHAR(50)
);

-- ==========================================
-- 1. DATA EXPLORATION & UNDERSTANDING (EDA)
-- ==========================================
-- (เช็กโครงสร้าง, ดูข้อมูลดิบเบื้องต้น, เช็กค่า Null หรือเช็กขนาดข้อมูล)

-- ตรวจสอบข้อมูลดิบเบื้องต้นหลัง Import
SELECT * 
FROM Customer_RFM.Customer_DB
LIMIT 10;

-- เช็กจำนวนค่าว่าง (NULL) ในคอลัมน์ที่สำคัญ
SELECT 
    SUM(CASE WHEN `Customer ID` IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN `Transaction ID` IS NULL THEN 1 ELSE 0 END) AS missing_transaction_id,
    SUM(CASE WHEN Date IS NULL THEN 1 ELSE 0 END) AS missing_date,
    SUM(CASE WHEN Amount IS NULL THEN 1 ELSE 0 END) AS missing_amount,
    SUM(CASE WHEN Region IS NULL THEN 1 ELSE 0 END) AS missing_region
FROM Customer_RFM.Customer_DB;

-- ==========================================
-- 2. DATA CLEANING & PREPROCESSING
-- ==========================================

-- ปิดโหมด Safe Updates ชั่วคราวเพื่อให้ Update ข้อมูลทั้งตารางได้
SET SQL_SAFE_UPDATES = 0;

-- อัปเดตข้อมูลในตารางเดิม
UPDATE Customer_RFM.Customer_DB
SET 
    -- ลบคอมมาออกออกจากคอลัมน์ยอดเงิน เพื่อให้แปลงเป็นตัวเลขได้
    PPU = REPLACE(PPU, ',', ''),
    Amount = REPLACE(Amount, ',', ''),
    
    -- แปลงวันที่จาก 01-01-2025 เป็นฟอร์แมตมาตรฐานของระบบ (YYYY-MM-DD)
    Date = STR_TO_DATE(Date, '%d-%m-%Y');

-- เปิดโหมด Safe Updates กลับคืน
SET SQL_SAFE_UPDATES = 1;

-- เปลี่ยน Data Type ให้ถูกต้อง
ALTER TABLE Customer_RFM.Customer_DB
MODIFY COLUMN `Transaction ID` VARCHAR(100),
MODIFY COLUMN `Customer ID` VARCHAR(100),
MODIFY COLUMN PPU INT,
MODIFY COLUMN Amount INT,
MODIFY COLUMN Quantity INT
MODIFY COLUMN Date DATE;

-- ตรวจสอบโครงสร้างตารางว่า Type เปลี่ยนเป็น INT และ DATE แล้วหรือยัง
DESCRIBE Customer_RFM.Customer_DB;

-- ดูผลลัพธ์ข้อมูลหลังจาก Cleaning
SELECT * 
FROM Customer_RFM.Customer_DB 
LIMIT 10;

-- ==========================================
-- INDEXING FOR PERFORMANCE OPTIMIZATION
-- ==========================================
-- สร้าง Index เพื่อเพิ่มความเร็วในการสืบค้นข้อมูลก่อนนำไปคำนวณ RFM
CREATE INDEX idx_customer_date ON Customer_RFM.Customer_DB (`Customer ID`, Date);
CREATE INDEX idx_transaction ON Customer_RFM.Customer_DB (`Transaction ID`);

-- ==========================================
-- 3. FEATURE ENGINEERING & RFM MODELING
-- ==========================================
-- (คำนวณค่าตัวแปรใหม่, ให้คะแนน NTILE, และจัดกลุ่ม Segment)
CREATE OR REPLACE VIEW Customer_RFM.vw_customer_segmentation AS
WITH rfm_raw AS (
    -- ดึงค่าดิบและคำนวณวันล่าสุด, จำนวนครั้ง, และยอดใช้จ่ายของลูกค้าแต่ละคน
    SELECT 
        `Customer ID`,
        DATEDIFF((SELECT MAX(Date) FROM Customer_RFM.Customer_DB), MAX(Date)) AS Recency,
        COUNT(DISTINCT `Transaction ID`) AS Frequency,
        SUM(Amount) AS Monetary
    FROM Customer_RFM.Customer_DB
    GROUP BY `Customer ID`
),
rfm_scoring AS (
    -- แปลงค่าดิบให้เป็นคะแนน 1-5 ด้วย Window Function (NTILE)
    SELECT 
        `Customer ID`,
        Recency,
        Frequency,
        Monetary,
        -- Recency: เรียงวันจากน้อยไปมาก แล้วลบด้วย 6 เพื่อกลับค่า (ซื้อล่าสุดได้คะแนน 5)
        6 - NTILE(5) OVER (ORDER BY Recency ASC) AS R_Score,
        
        -- Frequency & Monetary: ยิ่งเยอะ คะแนนยิ่งสูง (เรียงจากน้อยไปมาก)
        NTILE(5) OVER (ORDER BY Frequency ASC) AS F_Score,
        NTILE(5) OVER (ORDER BY Monetary ASC) AS M_Score
    FROM rfm_raw
)
-- ประกอบร่างคะแนนรวม และกำหนดเงื่อนไขแบ่งกลุ่มลูกค้า (Customer Segmentation)
SELECT 
    `Customer ID`,
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
    COUNT(`Customer ID`) AS Total_Customers,
    SUM(Monetary) AS Total_Revenue
FROM Customer_RFM.vw_customer_segmentation
GROUP BY Customer_Segment
ORDER BY Total_Revenue DESC;

-- ==========================================
-- 5. BUSINESS INSIGHTS & ANALYTICAL QUERIES
-- ==========================================
-- 5.1) แคมเปญดึงลูกค้าเก่ากลับมา (Win-back Campaign)
-- คำถาม: ลูกค้ากลุ่ม "At Risk" (เคยซื้อบ่อย ยอดสูง แต่ช่วงหลังหายไป) ที่มียอดใช้จ่ายสูงสุด 10 อันดับแรกคือใคร?
-- การนำไปใช้: ส่งรายชื่อให้ทีมเซลส์เพื่อโทรเสนอโปรโมชันพิเศษ หรือส่ง Email Marketing ดึงตัวกลับมาด่วน
SELECT 
    `Customer ID`, 
    Recency, 
    Frequency, 
    Monetary
FROM Customer_RFM.vw_customer_segmentation
WHERE Customer_Segment = 'At Risk'
ORDER BY Monetary DESC
LIMIT 10;

-- 5.2) วิเคราะห์สินค้าที่โดนใจแฟนพันธุ์แท้ (Loyalty & Product Preference)
-- คำถาม: ลูกค้ากลุ่ม "Champions" มักจะซื้อสินค้าในหมวดหมู่ไหน (Product Category) มากที่สุด?
-- การนำไปใช้: นำไปออกแบบโปรโมชันแบบ Bundle หรือ Cross-sell เพื่อทำกำไรสูงสุดจากกลุ่มลูกค้าชั้นดี
SELECT 
    db.`Product Category`,
    COUNT(db.`Transaction ID`) AS Total_Orders, -- นับจำนวนครั้งที่สั่งซื้อทั้งหมด
    SUM(db.Amount) AS Revenue_From_Champions    -- รวมยอดขายที่ได้จากลูกค้ากลุ่มนี้
FROM Customer_RFM.Customer_DB db
JOIN Customer_RFM.vw_customer_segmentation v 
  ON db.`Customer ID` = v.`Customer ID`
WHERE v.Customer_Segment = 'Champions'          -- กรองเอาเฉพาะลูกค้าเกรดดีที่สุด
GROUP BY db.`Product Category`                  -- จัดกลุ่มยอดขายตามหมวดหมู่สินค้า
ORDER BY Revenue_From_Champions DESC;           -- เรียงลำดับจากหมวดหมู่ที่ทำรายได้สูงสุดไปต่ำสุด

-- 5.3) วิเคราะห์ปัญหาเชิงพื้นที่ (Regional Churn Analysis)
-- คำถาม: ลูกค้าที่อยู่ในกลุ่ม "Lost / Hibernating" ส่วนใหญ่กระจุกตัวอยู่ในภูมิภาคไหน? (อาจบ่งบอกถึงปัญหาด้านการขนส่ง หรือคู่แข่งในพื้นที่นั้น)
-- การนำไปใช้: แจ้งทีม Operation ให้ตรวจสอบปัญหาในพื้นที่นั้น (เช่น ขนส่งล่าช้า) หรือจัดโปรโมชันสู้คู่แข่งในพื้นที่
SELECT 
    db.Region,
    COUNT(DISTINCT v.`Customer ID`) AS Total_Churned_Customers -- นับจำนวนลูกค้าที่หายไปแบบไม่ซ้ำคน
FROM Customer_RFM.Customer_DB db
JOIN Customer_RFM.vw_customer_segmentation v 
  ON db.`Customer ID` = v.`Customer ID`
WHERE v.Customer_Segment = 'Lost / Hibernating'
GROUP BY db.Region                                      -- จัดกลุ่มตามภูมิภาค
ORDER BY Total_Churned_Customers DESC;                     -- เรียงจากพื้นที่ที่มีลูกค้าหายไปมากที่สุด

-- 5.4) เปรียบเทียบพฤติกรรมการใช้จ่าย (Average Order Value - AOV)
-- คำถาม: ลูกค้ากลุ่ม "Champions" มียอดใช้จ่ายต่อบิล (AOV) แตกต่างจากกลุ่ม "Regular Customers" มากแค่ไหน? 
-- การนำไปใช้: เพื่อประเมินกลยุทธ์ราคา เช่น เสนอส่วนลดให้กลุ่ม Regular และเสนอการอัปเกรดสินค้าให้กลุ่ม Champions
SELECT 
    v.Customer_Segment,
    COUNT(DISTINCT db.`Transaction ID`) AS Total_Orders,
    SUM(db.Amount) AS Total_Revenue,
    ROUND(SUM(db.Amount) / COUNT(DISTINCT db.`Transaction ID`), 2) AS Average_Order_Value
FROM Customer_RFM.Customer_DB db
JOIN Customer_RFM.vw_customer_segmentation v 
  ON db.`Customer ID` = v.`Customer ID`
WHERE v.Customer_Segment IN ('Champions', 'Regular Customers')
GROUP BY v.Customer_Segment;


-- 5.5) วิเคราะห์ช่วงเวลาทองในการหาลูกค้าใหม่ (Peak Season for Acquisition)
-- คำถาม: ลูกค้ากลุ่ม "New Customers" ส่วนใหญ่เข้ามาซื้อสินค้าในเดือนไหนมากที่สุด? 
-- การนำไปใช้: วางแผนจัดสรรงบประมาณการตลาด (ยิงแอด) หรือเตรียมสต็อกสินค้าให้สอดคล้องกับเดือนที่เป็น Peak Season
SELECT 
    MONTH(db.Date) AS Order_Month,
    COUNT(DISTINCT v.`Customer ID`) AS Total_New_Customers,
    SUM(db.Amount) AS Revenue_From_New
FROM Customer_RFM.Customer_DB db
JOIN Customer_RFM.vw_customer_segmentation v 
  ON db.`Customer ID` = v.`Customer ID`
WHERE v.Customer_Segment = 'New Customers'
GROUP BY MONTH(db.Date)
ORDER BY Total_New_Customers DESC;
