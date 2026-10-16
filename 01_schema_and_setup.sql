-- ==========================================
-- 0. SCHEMA DESIGN & TABLE CREATION
-- ==========================================
-- ⚠️ สิ่งที่ต้องทำ: คลุมดำและรันโค้ดส่วนนี้ก่อน เพื่อสร้างตารางเตรียมไว้สำหรับ Import ไฟล์ CSV
CREATE DATABASE IF NOT EXISTS Customer_RFM;
USE Customer_RFM;
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

-- ตรวจสอบจำนวนรายการทั้งหมดก่อน Cleaning
SELECT COUNT(*) AS total_rows
FROM Customer_RFM.Customer_DB;

-- ==========================================
-- 2. DATA CLEANING & PREPROCESSING
-- ==========================================
-- Customer_DB คือตาราง Raw: คงไว้ตามไฟล์ CSV ไม่ UPDATE หรือ ALTER
-- สร้างตารางใหม่ Customer_Clean (Staging) เพื่อเก็บข้อมูลที่ทำความสะอาดแล้ว

-- สร้างตาราง Clean พร้อมกำหนด Data Type และ NOT NULL ให้ถูกต้อง
CREATE TABLE Customer_RFM.Customer_Clean (
    transaction_id   VARCHAR(100)  NOT NULL,
    order_date       DATE          NOT NULL,
    product_id       VARCHAR(50),
    product_name     VARCHAR(255),
    product_category VARCHAR(100),
    quantity         INT           NOT NULL,
    price_per_unit   DECIMAL(12,2) NOT NULL,
    amount           DECIMAL(12,2) NOT NULL,
    customer_id      VARCHAR(100)  NOT NULL,
    region           VARCHAR(50),
    PRIMARY KEY (transaction_id)
);

-- นำข้อมูลจากตาราง Raw เข้าตาราง Clean พร้อมแปลงข้อมูล
INSERT INTO Customer_RFM.Customer_Clean
SELECT
    `Transaction ID`,
    -- แปลงวันที่จาก 01-01-2025 เป็นฟอร์แมตมาตรฐานของระบบ (YYYY-MM-DD)
    STR_TO_DATE(Date, '%d-%m-%Y'),
    `Product ID`,
    `Product Name`,
    `Product Category`,
    -- ลบคอมมาออกจากคอลัมน์ตัวเลข เพื่อให้แปลงเป็นตัวเลขได้
    CAST(REPLACE(Quantity, ',', '') AS SIGNED),
    CAST(REPLACE(PPU, ',', '') AS DECIMAL(12,2)),
    CAST(REPLACE(Amount, ',', '') AS DECIMAL(12,2)),
    `Customer ID`,
    Region
FROM Customer_RFM.Customer_DB;

-- ตรวจสอบโครงสร้างตารางว่า Type เปลี่ยนเป็น INT, DECIMAL และ DATE แล้วหรือยัง
DESCRIBE Customer_RFM.Customer_Clean;

-- ดูผลลัพธ์ข้อมูลหลังจาก Cleaning
SELECT *
FROM Customer_RFM.Customer_Clean
LIMIT 10;

-- ==========================================
-- 3. DATA VALIDATION
-- ==========================================

-- ตรวจสอบจำนวนรายการหลัง Cleaning ต้องเท่ากับตาราง Raw (2,000 แถว)
SELECT
    (SELECT COUNT(*) FROM Customer_RFM.Customer_DB)    AS raw_rows,
    (SELECT COUNT(*) FROM Customer_RFM.Customer_Clean) AS clean_rows;

-- ตรวจสอบข้อมูลที่อาจผิดปกติหลัง Cleaning (ต้องได้ 0)
-- ค่า NULL ไม่ต้องเช็ก เพราะ NOT NULL จะ error ตั้งแต่ตอน INSERT
SELECT COUNT(*) AS bad_rows
FROM Customer_RFM.Customer_Clean
WHERE quantity <= 0
   OR amount < 0
   OR quantity * price_per_unit <> amount;

-- ==========================================
-- 4. INDEXING FOR RFM AGGREGATION
-- ==========================================
-- สร้าง Index เพื่อรองรับการคำนวณ RFM ซึ่งต้องใช้ MAX(order_date), COUNT(*) และ SUM(amount) ต่อลูกค้า
-- สร้างหลัง INSERT เพื่อไม่ต้องอัปเดต Index ทีละแถวตอนโหลดข้อมูล
CREATE INDEX idx_customer_date_amount
ON Customer_RFM.Customer_Clean (customer_id, order_date, amount);

-- ตรวจสอบ Index ที่มีอยู่ (ควรเหลือ PRIMARY กับ idx_customer_date_amount)
SHOW INDEX FROM Customer_RFM.Customer_Clean;

-- ตรวจสอบว่า Query RFM ใช้ Index นี้จริงหรือไม่
-- คอลัมน์ Extra ขึ้น "Using index" = Covering Index
EXPLAIN
SELECT customer_id,
       MAX(order_date) AS last_date,
       COUNT(*)        AS frequency,
       SUM(amount)     AS monetary
FROM Customer_RFM.Customer_Clean
GROUP BY customer_id;
