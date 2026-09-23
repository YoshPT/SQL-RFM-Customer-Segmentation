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
