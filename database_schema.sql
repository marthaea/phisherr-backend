

CREATE DATABASE IF NOT EXISTS VHIMS;
USE VHIMS;



CREATE TABLE USER (
    User_ID INT AUTO_INCREMENT PRIMARY KEY,
    Username VARCHAR(50) NOT NULL UNIQUE,
    Password_Hash VARCHAR(255) NOT NULL,
    Role VARCHAR(20) NOT NULL CHECK (Role IN ('Administrator', 'Veterinarian', 'Staff')),
    Created_Date DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- TABLE 2: ADMINISTRATOR (Specialization of USER - Disjoint)
-- ----------------------------------------------------------------------------

CREATE TABLE ADMINISTRATOR (
    User_ID INT PRIMARY KEY,
    Access_Level VARCHAR(20) NOT NULL CHECK (Access_Level IN ('Level 1', 'Level 2', 'Level 3')),
    Admin_Rights VARCHAR(100),
    FOREIGN KEY (User_ID) REFERENCES USER(User_ID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ----------------------------------------------------------------------------
-- TABLE 3: VETERINARIAN (Specialization of USER - Disjoint)
-- ----------------------------------------------------------------------------

CREATE TABLE VETERINARIAN (
    User_ID INT PRIMARY KEY,
    Licence_Number VARCHAR(50) NOT NULL UNIQUE,
    Speciality VARCHAR(50),
    Qualifications VARCHAR(100),
    FOREIGN KEY (User_ID) REFERENCES USER(User_ID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ----------------------------------------------------------------------------
-- TABLE 4: STAFF (Specialization of USER - Disjoint)
-- ----------------------------------------------------------------------------

CREATE TABLE STAFF (
    User_ID INT PRIMARY KEY,
    Position VARCHAR(50) NOT NULL,
    Department VARCHAR(50),
    Salary DECIMAL(10,2) CHECK (Salary >= 0),
    FOREIGN KEY (User_ID) REFERENCES USER(User_ID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ----------------------------------------------------------------------------
-- TABLE 5: ANIMAL_OWNER (Independent table)
-- ----------------------------------------------------------------------------

CREATE TABLE ANIMAL_OWNER (
    Owner_ID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Contact VARCHAR(20) NOT NULL,
    Address VARCHAR(200),
    Email VARCHAR(100) UNIQUE
);

-- ----------------------------------------------------------------------------
-- TABLE 6: AUDITLOG (Tracks system activities)
-- ----------------------------------------------------------------------------

CREATE TABLE AUDITLOG (
    Log_ID INT AUTO_INCREMENT PRIMARY KEY,
    User_ID INT,
    Action VARCHAR(50) NOT NULL,
    Entity VARCHAR(50) NOT NULL,
    TimeStamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (User_ID) REFERENCES USER(User_ID) ON DELETE SET NULL ON UPDATE CASCADE
);

-- ----------------------------------------------------------------------------
-- TABLE 7: ANIMAL (Parent table with specializations)
-- ----------------------------------------------------------------------------

CREATE TABLE ANIMAL (
    Animal_ID INT AUTO_INCREMENT PRIMARY KEY,
    Owner_ID INT NOT NULL,
    Name VARCHAR(100),
    Species VARCHAR(50) NOT NULL,
    Breed VARCHAR(50),
    Sex VARCHAR(10) CHECK (Sex IN ('Male', 'Female', 'Unknown')),
    Age INT CHECK (Age >= 0),
    Category VARCHAR(50) NOT NULL CHECK (Category IN ('Livestock', 'Pet', 'Wildlife')),
    DOB DATE,
    FOREIGN KEY (Owner_ID) REFERENCES ANIMAL_OWNER(Owner_ID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ----------------------------------------------------------------------------
-- TABLE 8: LIVESTOCK (Specialization of ANIMAL - Disjoint)
-- ----------------------------------------------------------------------------

CREATE TABLE LIVESTOCK (
    Animal_ID INT PRIMARY KEY,
    Breed VARCHAR(50),
    Farm_Location VARCHAR(200),
    FOREIGN KEY (Animal_ID) REFERENCES ANIMAL(Animal_ID) ON DELETE CASCADE ON UPDATE CASCADE,
    CHECK ((SELECT Category FROM ANIMAL WHERE Animal_ID = LIVESTOCK.Animal_ID) = 'Livestock')
);

-- ----------------------------------------------------------------------------
-- TABLE 9: PET (Specialization of ANIMAL - Disjoint)
-- ----------------------------------------------------------------------------

CREATE TABLE PET (
    Animal_ID INT PRIMARY KEY,
    Color VARCHAR(50),
    Microchip_No VARCHAR(50) UNIQUE,
    FOREIGN KEY (Animal_ID) REFERENCES ANIMAL(Animal_ID) ON DELETE CASCADE ON UPDATE CASCADE,
    CHECK ((SELECT Category FROM ANIMAL WHERE Animal_ID = PET.Animal_ID) = 'Pet')
);

-- ----------------------------------------------------------------------------
-- TABLE 10: WILDLIFE (Specialization of ANIMAL - Disjoint)
-- ----------------------------------------------------------------------------

CREATE TABLE WILDLIFE (
    Animal_ID INT PRIMARY KEY,
    Permit_No VARCHAR(50) UNIQUE,
    Habitat VARCHAR(100),
    FOREIGN KEY (Animal_ID) REFERENCES ANIMAL(Animal_ID) ON DELETE CASCADE ON UPDATE CASCADE,
    CHECK ((SELECT Category FROM ANIMAL WHERE Animal_ID = WILDLIFE.Animal_ID) = 'Wildlife')
);

-- ----------------------------------------------------------------------------
-- TABLE 11: MEDICATION_MASTER (Reference table for medications)
-- ----------------------------------------------------------------------------

CREATE TABLE MEDICATION_MASTER (
    MedMaster_ID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Dosage_Form VARCHAR(50) NOT NULL CHECK (Dosage_Form IN ('Tablet', 'Injection', 'Topical', 'Liquid', 'Capsule'))
);

-- ----------------------------------------------------------------------------
-- TABLE 12: SERVICE (Reference table for clinic services)
-- ----------------------------------------------------------------------------

CREATE TABLE SERVICE (
    Service_ID INT AUTO_INCREMENT PRIMARY KEY,
    Service_Name VARCHAR(100) NOT NULL UNIQUE,
    Standard_Fee DECIMAL(10,2) NOT NULL CHECK (Standard_Fee >= 0)
);

-- ----------------------------------------------------------------------------
-- TABLE 13: INVENTORY (Stores medication stock information)
-- ----------------------------------------------------------------------------

CREATE TABLE INVENTORY (
    Item_ID INT AUTO_INCREMENT PRIMARY KEY,
    Item_Name VARCHAR(100) NOT NULL,
    Quality VARCHAR(50) CHECK (Quality IN ('Good', 'Expired', 'Damaged', 'Low Stock')),
    Reorder_Level INT CHECK (Reorder_Level >= 0),
    Expiry_Date DATE,
    Quantity INT DEFAULT 0 CHECK (Quantity >= 0)
);

-- ----------------------------------------------------------------------------
-- TABLE 14: APPOINTMENT (Links Animal and Veterinarian)
-- ----------------------------------------------------------------------------

CREATE TABLE APPOINTMENT (
    Appointment_ID INT AUTO_INCREMENT PRIMARY KEY,
    Animal_ID INT NOT NULL,
    Doctor_ID INT NOT NULL,
    Date DATE NOT NULL,
    Time TIME NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Scheduled' CHECK (Status IN ('Scheduled', 'Completed', 'Cancelled', 'Pending')),
    FOREIGN KEY (Animal_ID) REFERENCES ANIMAL(Animal_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (Doctor_ID) REFERENCES VETERINARIAN(User_ID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ----------------------------------------------------------------------------
-- TABLE 15: VACCINATION (Tracks animal vaccinations)
-- ----------------------------------------------------------------------------

CREATE TABLE VACCINATION (
    Vacc_ID INT AUTO_INCREMENT PRIMARY KEY,
    Animal_ID INT NOT NULL,
    Vaccine_Name VARCHAR(100) NOT NULL,
    Due_Date DATE NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (Status IN ('Pending', 'Completed', 'Overdue')),
    Administered_Date DATE,
    FOREIGN KEY (Animal_ID) REFERENCES ANIMAL(Animal_ID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ----------------------------------------------------------------------------
-- TABLE 16: LAB_TEST (Laboratory test results)
-- ----------------------------------------------------------------------------

CREATE TABLE LAB_TEST (
    Test_ID INT AUTO_INCREMENT PRIMARY KEY,
    Visit_ID INT NOT NULL,
    Test_Type VARCHAR(100) NOT NULL,
    Results VARCHAR(500),
    Test_Date DATE DEFAULT (CURRENT_DATE),
    FOREIGN KEY (Visit_ID) REFERENCES APPOINTMENT(Appointment_ID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ----------------------------------------------------------------------------
-- TABLE 17: DIAGNOSIS (Created from Appointment)
-- ----------------------------------------------------------------------------

CREATE TABLE DIAGNOSIS (
    Diagnosis_ID INT AUTO_INCREMENT PRIMARY KEY,
    Appointment_ID INT NOT NULL UNIQUE,
    Symptoms VARCHAR(500),
    Conditions VARCHAR(500),
    Recommendations VARCHAR(500),
    Diagnosis_Date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Appointment_ID) REFERENCES APPOINTMENT(Appointment_ID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ----------------------------------------------------------------------------
-- TABLE 18: PRESCRIPTION (Links Diagnosis and Medication)
-- ----------------------------------------------------------------------------

CREATE TABLE PRESCRIPTION (
    Prescription_ID INT AUTO_INCREMENT PRIMARY KEY,
    Diagnosis_ID INT NOT NULL,
    MedMaster_ID INT NOT NULL,
    Dosage VARCHAR(100) NOT NULL,
    FOREIGN KEY (Diagnosis_ID) REFERENCES DIAGNOSIS(Diagnosis_ID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (MedMaster_ID) REFERENCES MEDICATION_MASTER(MedMaster_ID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ----------------------------------------------------------------------------
-- TABLE 19: DIAGNOSIS_SERVICE (Junction table - Many-to-Many)
-- ----------------------------------------------------------------------------

CREATE TABLE DIAGNOSIS_SERVICE (
    Diagnosis_ID INT,
    Service_ID INT,
    PRIMARY KEY (Diagnosis_ID, Service_ID),
    FOREIGN KEY (Diagnosis_ID) REFERENCES DIAGNOSIS(Diagnosis_ID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (Service_ID) REFERENCES SERVICE(Service_ID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ----------------------------------------------------------------------------
-- TABLE 20: TREATMENT (Created from Diagnosis)
-- ----------------------------------------------------------------------------

CREATE TABLE TREATMENT (
    Treatment_ID INT AUTO_INCREMENT PRIMARY KEY,
    Diagnosis_ID INT NOT NULL,
    Procedure_Date DATE NOT NULL,
    Cost DECIMAL(10,2) NOT NULL CHECK (Cost >= 0),
    Description VARCHAR(500),
    FOREIGN KEY (Diagnosis_ID) REFERENCES DIAGNOSIS(Diagnosis_ID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ----------------------------------------------------------------------------
-- TABLE 21: BILL (Links Appointment and Treatment for billing)
-- ----------------------------------------------------------------------------

CREATE TABLE BILL (
    Bill_ID INT AUTO_INCREMENT PRIMARY KEY,
    Appointment_ID INT NOT NULL,
    Treatment_ID INT,
    Total_Amount DECIMAL(10,2) NOT NULL CHECK (Total_Amount >= 0),
    Status VARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (Status IN ('Paid', 'Pending', 'Overdue')),
    Bill_Date DATE DEFAULT (CURRENT_DATE),
    FOREIGN KEY (Appointment_ID) REFERENCES APPOINTMENT(Appointment_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (Treatment_ID) REFERENCES TREATMENT(Treatment_ID) ON DELETE SET NULL ON UPDATE CASCADE
);

-- ----------------------------------------------------------------------------
-- TABLE 22: PAYMENT (Records payments for bills)
-- ----------------------------------------------------------------------------

CREATE TABLE PAYMENT (
    Payment_ID INT AUTO_INCREMENT PRIMARY KEY,
    Bill_ID INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL CHECK (Amount > 0),
    Mode VARCHAR(50) NOT NULL CHECK (Mode IN ('Cash', 'Mobile Money', 'Bank Transfer', 'Card')),
    Date DATE DEFAULT (CURRENT_DATE),
    FOREIGN KEY (Bill_ID) REFERENCES BILL(Bill_ID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ----------------------------------------------------------------------------
-- TABLE 23: INVENTORY_TRANSACTION (Tracks inventory movements)
-- ----------------------------------------------------------------------------

CREATE TABLE INVENTORY_TRANSACTION (
    Transaction_ID INT AUTO_INCREMENT PRIMARY KEY,
    Item_ID INT NOT NULL,
    Animal_ID INT,
    Quantity INT NOT NULL,
    Type VARCHAR(50) NOT NULL CHECK (Type IN ('Issue', 'Receipt', 'Adjustment')),
    Transaction_Date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Item_ID) REFERENCES INVENTORY(Item_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (Animal_ID) REFERENCES ANIMAL(Animal_ID) ON DELETE SET NULL ON UPDATE CASCADE
);

-- ============================================================================
-- STEP 4: CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX idx_animal_owner ON ANIMAL(Owner_ID);
CREATE INDEX idx_appointment_animal ON APPOINTMENT(Animal_ID);
CREATE INDEX idx_appointment_doctor ON APPOINTMENT(Doctor_ID);
CREATE INDEX idx_appointment_date ON APPOINTMENT(Date);
CREATE INDEX idx_vaccination_animal ON VACCINATION(Animal_ID);
CREATE INDEX idx_vaccination_due_date ON VACCINATION(Due_Date);
CREATE INDEX idx_bill_appointment ON BILL(Appointment_ID);
CREATE INDEX idx_payment_bill ON PAYMENT(Bill_ID);
CREATE INDEX idx_auditlog_user ON AUDITLOG(User_ID);
CREATE INDEX idx_auditlog_timestamp ON AUDITLOG(TimeStamp);

-- ============================================================================
-- STEP 5: CREATE VIEWS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- VIEW 1: AnimalMedicalHistoryView
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW AnimalMedicalHistoryView AS
SELECT 
    a.Animal_ID,
    a.Name AS Animal_Name,
    a.Species,
    a.Breed,
    a.Category,
    ao.Name AS Owner_Name,
    ao.Contact AS Owner_Contact,
    app.Appointment_ID,
    app.Date AS Appointment_Date,
    app.Time AS Appointment_Time,
    app.Status AS Appointment_Status,
    v.Username AS Veterinarian_Name,
    d.Symptoms,
    d.Conditions,
    d.Recommendations,
    d.Diagnosis_Date,
    t.Treatment_ID,
    t.Procedure_Date,
    t.Cost AS Treatment_Cost,
    b.Bill_ID,
    b.Total_Amount,
    b.Status AS Bill_Status
FROM ANIMAL a
INNER JOIN ANIMAL_OWNER ao ON a.Owner_ID = ao.Owner_ID
LEFT JOIN APPOINTMENT app ON a.Animal_ID = app.Animal_ID
LEFT JOIN VETERINARIAN vet ON app.Doctor_ID = vet.User_ID
LEFT JOIN USER v ON vet.User_ID = v.User_ID
LEFT JOIN DIAGNOSIS d ON app.Appointment_ID = d.Appointment_ID
LEFT JOIN TREATMENT t ON d.Diagnosis_ID = t.Diagnosis_ID
LEFT JOIN BILL b ON app.Appointment_ID = b.Appointment_ID
ORDER BY a.Animal_ID, app.Date DESC;

-- ----------------------------------------------------------------------------
-- VIEW 2: VaccinationStatusView
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW VaccinationStatusView AS
SELECT 
    a.Animal_ID,
    a.Name AS Animal_Name,
    a.Species,
    a.Breed,
    a.Category,
    ao.Name AS Owner_Name,
    ao.Contact AS Owner_Contact,
    v.Vacc_ID,
    v.Vaccine_Name,
    v.Due_Date,
    v.Status AS Vaccination_Status,
    v.Administered_Date,
    CASE 
        WHEN v.Due_Date < CURRENT_DATE AND v.Status = 'Pending' THEN 'Overdue'
        WHEN v.Due_Date = CURRENT_DATE AND v.Status = 'Pending' THEN 'Due Today'
        WHEN v.Due_Date > CURRENT_DATE AND v.Status = 'Pending' THEN 'Upcoming'
        ELSE v.Status
    END AS Status_Description
FROM ANIMAL a
INNER JOIN ANIMAL_OWNER ao ON a.Owner_ID = ao.Owner_ID
LEFT JOIN VACCINATION v ON a.Animal_ID = v.Animal_ID
ORDER BY v.Due_Date ASC, a.Animal_ID;

-- ----------------------------------------------------------------------------
-- VIEW 3: AppointmentSummaryView
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW AppointmentSummaryView AS
SELECT 
    app.Appointment_ID,
    app.Date,
    app.Time,
    app.Status,
    a.Animal_ID,
    a.Name AS Animal_Name,
    a.Species,
    ao.Name AS Owner_Name,
    ao.Contact,
    v.Username AS Veterinarian_Name,
    vet.Speciality,
    d.Diagnosis_ID,
    d.Conditions,
    b.Bill_ID,
    b.Total_Amount,
    b.Status AS Bill_Status
FROM APPOINTMENT app
INNER JOIN ANIMAL a ON app.Animal_ID = a.Animal_ID
INNER JOIN ANIMAL_OWNER ao ON a.Owner_ID = ao.Owner_ID
INNER JOIN VETERINARIAN vet ON app.Doctor_ID = vet.User_ID
INNER JOIN USER v ON vet.User_ID = v.User_ID
LEFT JOIN DIAGNOSIS d ON app.Appointment_ID = d.Appointment_ID
LEFT JOIN BILL b ON app.Appointment_ID = b.Appointment_ID
ORDER BY app.Date DESC, app.Time DESC;

-- ============================================================================
-- STEP 6: CREATE STORED PROCEDURES
-- ============================================================================

DELIMITER //

-- ----------------------------------------------------------------------------
-- STORED PROCEDURE 1: sp_AddVisit (Add Appointment)
-- ----------------------------------------------------------------------------

CREATE PROCEDURE sp_AddVisit(
    IN p_Animal_ID INT,
    IN p_Doctor_ID INT,
    IN p_Date DATE,
    IN p_Time TIME,
    IN p_Status VARCHAR(20)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Validate that Doctor_ID is a veterinarian
    IF NOT EXISTS (SELECT 1 FROM VETERINARIAN WHERE User_ID = p_Doctor_ID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Doctor_ID: Must be a registered veterinarian';
    END IF;
    
    -- Validate that Animal_ID exists
    IF NOT EXISTS (SELECT 1 FROM ANIMAL WHERE Animal_ID = p_Animal_ID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Animal_ID: Animal does not exist';
    END IF;
    
    -- Insert appointment
    INSERT INTO APPOINTMENT (Animal_ID, Doctor_ID, Date, Time, Status)
    VALUES (p_Animal_ID, p_Doctor_ID, p_Date, p_Time, p_Status);
    
    COMMIT;
    
    SELECT 'Appointment added successfully' AS Message, LAST_INSERT_ID() AS Appointment_ID;
END //

-- ----------------------------------------------------------------------------
-- STORED PROCEDURE 2: sp_UpdateVaccination
-- ----------------------------------------------------------------------------

CREATE PROCEDURE sp_UpdateVaccination(
    IN p_Vacc_ID INT,
    IN p_Status VARCHAR(20),
    IN p_Administered_Date DATE
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Validate Vacc_ID exists
    IF NOT EXISTS (SELECT 1 FROM VACCINATION WHERE Vacc_ID = p_Vacc_ID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Vacc_ID: Vaccination record does not exist';
    END IF;
    
    -- Update vaccination
    UPDATE VACCINATION
    SET Status = p_Status,
        Administered_Date = p_Administered_Date
    WHERE Vacc_ID = p_Vacc_ID;
    
    COMMIT;
    
    SELECT 'Vaccination updated successfully' AS Message;
END //

-- ----------------------------------------------------------------------------
-- STORED PROCEDURE 3: sp_AddLabtest
-- ----------------------------------------------------------------------------

CREATE PROCEDURE sp_AddLabtest(
    IN p_Visit_ID INT,
    IN p_Test_Type VARCHAR(100),
    IN p_Results VARCHAR(500),
    IN p_Test_Date DATE
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Validate that Visit_ID (Appointment_ID) exists
    IF NOT EXISTS (SELECT 1 FROM APPOINTMENT WHERE Appointment_ID = p_Visit_ID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Visit_ID: Appointment does not exist';
    END IF;
    
    -- Insert lab test
    INSERT INTO LAB_TEST (Visit_ID, Test_Type, Results, Test_Date)
    VALUES (p_Visit_ID, p_Test_Type, p_Results, COALESCE(p_Test_Date, CURRENT_DATE));
    
    COMMIT;
    
    SELECT 'Lab test added successfully' AS Message, LAST_INSERT_ID() AS Test_ID;
END //

-- ----------------------------------------------------------------------------
-- STORED PROCEDURE 4: sp_GenerateBill
-- ----------------------------------------------------------------------------

CREATE PROCEDURE sp_GenerateBill(
    IN p_Appointment_ID INT,
    IN p_Treatment_ID INT,
    IN p_Total_Amount DECIMAL(10,2)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Validate Appointment_ID exists
    IF NOT EXISTS (SELECT 1 FROM APPOINTMENT WHERE Appointment_ID = p_Appointment_ID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Appointment_ID: Appointment does not exist';
    END IF;
    
    -- Insert bill
    INSERT INTO BILL (Appointment_ID, Treatment_ID, Total_Amount, Status)
    VALUES (p_Appointment_ID, p_Treatment_ID, p_Total_Amount, 'Pending');
    
    COMMIT;
    
    SELECT 'Bill generated successfully' AS Message, LAST_INSERT_ID() AS Bill_ID;
END //

DELIMITER ;

-- ============================================================================
-- STEP 7: CREATE TRIGGERS
-- ============================================================================

DELIMITER //

-- ----------------------------------------------------------------------------
-- TRIGGER 1: Auto-update vaccination status when Due_Date <= CURRENT_DATE
-- ----------------------------------------------------------------------------

CREATE TRIGGER trg_UpdateVaccinationStatus
BEFORE UPDATE ON VACCINATION
FOR EACH ROW
BEGIN
    IF NEW.Due_Date <= CURRENT_DATE AND NEW.Status = 'Pending' THEN
        SET NEW.Status = 'Overdue';
    END IF;
END //

-- ----------------------------------------------------------------------------
-- TRIGGER 2: Auto-update vaccination status on insert
-- ----------------------------------------------------------------------------

CREATE TRIGGER trg_CheckVaccinationDueDate
BEFORE INSERT ON VACCINATION
FOR EACH ROW
BEGIN
    IF NEW.Due_Date <= CURRENT_DATE AND NEW.Status = 'Pending' THEN
        SET NEW.Status = 'Overdue';
    END IF;
END //

-- ----------------------------------------------------------------------------
-- TRIGGER 3: Log every appointment insertion in Audit table
-- ----------------------------------------------------------------------------

CREATE TRIGGER trg_LogAppointmentInsert
AFTER INSERT ON APPOINTMENT
FOR EACH ROW
BEGIN
    INSERT INTO AUDITLOG (User_ID, Action, Entity, TimeStamp)
    VALUES (NEW.Doctor_ID, 'CREATE', 'APPOINTMENT', CURRENT_TIMESTAMP);
END //

-- ----------------------------------------------------------------------------
-- TRIGGER 4: Log appointment updates
-- ----------------------------------------------------------------------------

CREATE TRIGGER trg_LogAppointmentUpdate
AFTER UPDATE ON APPOINTMENT
FOR EACH ROW
BEGIN
    INSERT INTO AUDITLOG (User_ID, Action, Entity, TimeStamp)
    VALUES (NEW.Doctor_ID, 'UPDATE', 'APPOINTMENT', CURRENT_TIMESTAMP);
END //

-- ----------------------------------------------------------------------------
-- TRIGGER 5: Update inventory quantity on transaction
-- ----------------------------------------------------------------------------

CREATE TRIGGER trg_UpdateInventoryQuantity
AFTER INSERT ON INVENTORY_TRANSACTION
FOR EACH ROW
BEGIN
    IF NEW.Type = 'Receipt' THEN
        UPDATE INVENTORY 
        SET Quantity = Quantity + NEW.Quantity
        WHERE Item_ID = NEW.Item_ID;
    ELSEIF NEW.Type = 'Issue' THEN
        UPDATE INVENTORY 
        SET Quantity = Quantity - ABS(NEW.Quantity)
        WHERE Item_ID = NEW.Item_ID;
    END IF;
    
    -- Update quality status based on quantity
    UPDATE INVENTORY
    SET Quality = CASE
        WHEN Quantity <= Reorder_Level THEN 'Low Stock'
        WHEN Expiry_Date < CURRENT_DATE THEN 'Expired'
        ELSE 'Good'
    END
    WHERE Item_ID = NEW.Item_ID;
END //

-- ----------------------------------------------------------------------------
-- TRIGGER 6: Auto-update bill status when payment is made
-- ----------------------------------------------------------------------------

CREATE TRIGGER trg_UpdateBillStatus
AFTER INSERT ON PAYMENT
FOR EACH ROW
BEGIN
    DECLARE total_paid DECIMAL(10,2);
    DECLARE bill_total DECIMAL(10,2);
    
    SELECT SUM(Amount) INTO total_paid
    FROM PAYMENT
    WHERE Bill_ID = NEW.Bill_ID;
    
    SELECT Total_Amount INTO bill_total
    FROM BILL
    WHERE Bill_ID = NEW.Bill_ID;
    
    IF total_paid >= bill_total THEN
        UPDATE BILL
        SET Status = 'Paid'
        WHERE Bill_ID = NEW.Bill_ID;
    ELSEIF total_paid > 0 THEN
        UPDATE BILL
        SET Status = 'Pending'
        WHERE Bill_ID = NEW.Bill_ID;
    END IF;
END //

DELIMITER ;

-- ============================================================================
-- STEP 8: CREATE USERS AND GRANT PRIVILEGES
-- ============================================================================

-- Create user roles
CREATE USER IF NOT EXISTS 'vhims_admin'@'localhost' IDENTIFIED BY 'Admin@123';
CREATE USER IF NOT EXISTS 'vhims_vet'@'localhost' IDENTIFIED BY 'Vet@123';
CREATE USER IF NOT EXISTS 'vhims_tech'@'localhost' IDENTIFIED BY 'Tech@123';
CREATE USER IF NOT EXISTS 'vhims_recep'@'localhost' IDENTIFIED BY 'Recep@123';

-- Grant privileges to Administrator (Full access)
GRANT ALL PRIVILEGES ON VHIMS.* TO 'vhims_admin'@'localhost';

-- Grant privileges to Veterinarian
GRANT SELECT, INSERT, UPDATE ON VHIMS.ANIMAL TO 'vhims_vet'@'localhost';
GRANT SELECT, INSERT, UPDATE ON VHIMS.APPOINTMENT TO 'vhims_vet'@'localhost';
GRANT SELECT, INSERT, UPDATE ON VHIMS.DIAGNOSIS TO 'vhims_vet'@'localhost';
GRANT SELECT, INSERT, UPDATE ON VHIMS.PRESCRIPTION TO 'vhims_vet'@'localhost';
GRANT SELECT, INSERT, UPDATE ON VHIMS.VACCINATION TO 'vhims_vet'@'localhost';
GRANT SELECT, INSERT, UPDATE ON VHIMS.TREATMENT TO 'vhims_vet'@'localhost';
GRANT SELECT ON VHIMS.MEDICATION_MASTER TO 'vhims_vet'@'localhost';
GRANT SELECT ON VHIMS.SERVICE TO 'vhims_vet'@'localhost';
GRANT SELECT ON VHIMS.ANIMAL_OWNER TO 'vhims_vet'@'localhost';
GRANT SELECT ON VHIMS.AnimalMedicalHistoryView TO 'vhims_vet'@'localhost';
GRANT SELECT ON VHIMS.VaccinationStatusView TO 'vhims_vet'@'localhost';
GRANT EXECUTE ON PROCEDURE VHIMS.sp_AddVisit TO 'vhims_vet'@'localhost';
GRANT EXECUTE ON PROCEDURE VHIMS.sp_UpdateVaccination TO 'vhims_vet'@'localhost';

-- Grant privileges to Technician
GRANT SELECT, INSERT, UPDATE ON VHIMS.LAB_TEST TO 'vhims_tech'@'localhost';
GRANT SELECT ON VHIMS.APPOINTMENT TO 'vhims_tech'@'localhost';
GRANT SELECT ON VHIMS.ANIMAL TO 'vhims_tech'@'localhost';
GRANT EXECUTE ON PROCEDURE VHIMS.sp_AddLabtest TO 'vhims_tech'@'localhost';

-- Grant privileges to Receptionist
GRANT SELECT, INSERT, UPDATE ON VHIMS.ANIMAL_OWNER TO 'vhims_recep'@'localhost';
GRANT SELECT, INSERT, UPDATE ON VHIMS.ANIMAL TO 'vhims_recep'@'localhost';
GRANT SELECT, INSERT, UPDATE ON VHIMS.APPOINTMENT TO 'vhims_recep'@'localhost';
GRANT SELECT, INSERT, UPDATE ON VHIMS.BILL TO 'vhims_recep'@'localhost';
GRANT SELECT, INSERT, UPDATE ON VHIMS.PAYMENT TO 'vhims_recep'@'localhost';
GRANT SELECT ON VHIMS.SERVICE TO 'vhims_recep'@'localhost';
GRANT EXECUTE ON PROCEDURE VHIMS.sp_AddVisit TO 'vhims_recep'@'localhost';
GRANT EXECUTE ON PROCEDURE VHIMS.sp_GenerateBill TO 'vhims_recep'@'localhost';

-- Apply privileges
FLUSH PRIVILEGES;

-- ============================================================================
-- STEP 9: INSERT SAMPLE DATA
-- ============================================================================

-- Insert Users
INSERT INTO USER (Username, Password_Hash, Role) VALUES
('admin_mukasa', '$2y$10$examplehash1', 'Administrator'),
('vet_nakato', '$2y$10$examplehash2', 'Veterinarian'),
('vet_owino', '$2y$10$examplehash3', 'Veterinarian'),
('staff_kizza', '$2y$10$examplehash4', 'Staff'),
('recep_namukwaya', '$2y$10$examplehash5', 'Staff');

-- Insert Administrators
INSERT INTO ADMINISTRATOR VALUES
(1, 'Level 1', 'Full System Access');

-- Insert Veterinarians
INSERT INTO VETERINARIAN VALUES
(2, 'LIC-2024-001', 'Small Animals', 'BVSc, MRCVS'),
(3, 'LIC-2024-002', 'Livestock', 'BVSc, PhD');

-- Insert Staff
INSERT INTO STAFF VALUES
(4, 'Store Keeper', 'Inventory', 850000.00),
(5, 'Receptionist', 'Front Desk', 650000.00);

-- Insert Animal Owners
INSERT INTO ANIMAL_OWNER (Name, Contact, Address, Email) VALUES
('James Mukasa', '0772123456', 'Kampala Road, Kampala', 'james.mukasa@email.com'),
('Sarah Nakato', '0756789123', 'Ntinda, Kampala', 'sarah.nakato@email.com'),
('Peter Owino', '0702345678', 'Makindye, Kampala', 'peter.owino@email.com'),
('Grace Namukwaya', '0789456123', 'Najjera, Kampala', 'grace.namukwaya@email.com');

-- Insert Animals
INSERT INTO ANIMAL (Owner_ID, Name, Species, Breed, Sex, Age, Category, DOB) VALUES
(1, 'Max', 'Dog', 'German Shepherd', 'Male', 3, 'Pet', '2021-01-15'),
(1, 'Fluffy', 'Cat', 'Persian', 'Female', 2, 'Pet', '2022-03-20'),
(2, 'Bella', 'Cow', 'Ankole', 'Female', 5, 'Livestock', '2019-06-10'),
(3, 'Buddy', 'Dog', 'Labrador', 'Male', 4, 'Pet', '2020-02-14'),
(4, 'Billy', 'Goat', 'Boer', 'Male', 2, 'Livestock', '2022-08-05');

-- Insert Pet specializations
INSERT INTO PET (Animal_ID, Color, Microchip_No) VALUES
(1, 'Brown and Black', 'CHIP001'),
(2, 'White', 'CHIP002'),
(4, 'Golden', 'CHIP003');

-- Insert Livestock specializations
INSERT INTO LIVESTOCK (Animal_ID, Breed, Farm_Location) VALUES
(3, 'Ankole', 'Mbarara District'),
(5, 'Boer', 'Wakiso District');

-- Insert Medications
INSERT INTO MEDICATION_MASTER (Name, Dosage_Form) VALUES
('Amoxicillin 250mg', 'Tablet'),
('Paracetamol 500mg', 'Tablet'),
('Ivermectin 1%', 'Injection'),
('Antibiotic Ointment', 'Topical'),
('Vitamin B Complex', 'Injection');

-- Insert Services
INSERT INTO SERVICE (Service_Name, Standard_Fee) VALUES
('General Consultation', 50000.00),
('Vaccination', 75000.00),
('Surgery', 300000.00),
('Laboratory Test', 100000.00),
('X-Ray', 150000.00);

-- Insert Inventory
INSERT INTO INVENTORY (Item_Name, Quality, Reorder_Level, Expiry_Date, Quantity) VALUES
('Amoxicillin 250mg', 'Good', 50, '2025-12-31', 200),
('Paracetamol 500mg', 'Good', 100, '2026-06-30', 500),
('Ivermectin 1%', 'Good', 30, '2025-09-15', 150),
('Antibiotic Ointment', 'Good', 25, '2026-03-20', 80),
('Vitamin B Complex', 'Good', 40, '2025-11-10', 120);

-- Insert Appointments
INSERT INTO APPOINTMENT (Animal_ID, Doctor_ID, Date, Time, Status) VALUES
(1, 2, '2024-01-15', '09:00:00', 'Completed'),
(3, 3, '2024-01-16', '10:30:00', 'Completed'),
(4, 2, '2024-01-17', '14:00:00', 'Completed'),
(2, 2, '2024-01-18', '11:00:00', 'Pending'),
(5, 3, '2024-01-19', '08:30:00', 'Scheduled');

-- Insert Vaccinations
INSERT INTO VACCINATION (Animal_ID, Vaccine_Name, Due_Date, Status) VALUES
(1, 'Rabies Vaccine', '2024-02-15', 'Pending'),
(1, 'DHPP Vaccine', '2024-03-01', 'Pending'),
(2, 'FVRCP Vaccine', '2024-02-20', 'Pending'),
(3, 'Anthrax Vaccine', '2024-01-10', 'Overdue'),
(4, 'Rabies Vaccine', '2024-02-14', 'Pending');

-- Insert Lab Tests
INSERT INTO LAB_TEST (Visit_ID, Test_Type, Results, Test_Date) VALUES
(1, 'Blood Test', 'Normal', '2024-01-15'),
(1, 'Urine Analysis', 'No abnormalities', '2024-01-15'),
(2, 'Parasite Test', 'Positive for worms', '2024-01-16'),
(3, 'X-Ray', 'No fractures detected', '2024-01-17');

-- Insert Diagnoses
INSERT INTO DIAGNOSIS (Appointment_ID, Symptoms, Conditions, Recommendations) VALUES
(1, 'Fever, Loss of appetite', 'Bacterial Infection', 'Complete course of antibiotics'),
(2, 'Weight loss, Dull coat', 'Parasitic Infestation', 'Deworming treatment required'),
(3, 'Lethargy, Coughing', 'Respiratory Infection', 'Antibiotics and rest'),
(4, 'Vomiting, Diarrhea', 'Gastrointestinal Issue', 'Medication and dietary changes');

-- Insert Prescriptions
INSERT INTO PRESCRIPTION (Diagnosis_ID, MedMaster_ID, Dosage) VALUES
(1, 1, '250mg twice daily for 7 days'),
(2, 3, '1ml per 50kg body weight'),
(3, 1, '500mg three times daily for 5 days'),
(3, 5, '2ml once daily for 3 days'),
(4, 2, '500mg every 8 hours for 3 days');

-- Insert Diagnosis-Service links
INSERT INTO DIAGNOSIS_SERVICE VALUES
(1, 1), (1, 4),
(2, 1), (2, 2),
(3, 1), (3, 5),
(4, 1);

-- Insert Treatments
INSERT INTO TREATMENT (Diagnosis_ID, Procedure_Date, Cost, Description) VALUES
(1, '2024-01-15', 150000.00, 'Antibiotic treatment'),
(2, '2024-01-16', 175000.00, 'Deworming procedure'),
(3, '2024-01-17', 250000.00, 'Respiratory treatment with X-Ray'),
(4, '2024-01-18', 100000.00, 'Gastrointestinal treatment');

-- Insert Bills
INSERT INTO BILL (Appointment_ID, Treatment_ID, Total_Amount, Status) VALUES
(1, 1, 200000.00, 'Paid'),
(2, 2, 250000.00, 'Paid'),
(3, 3, 400000.00, 'Pending'),
(4, 4, 150000.00, 'Pending');

-- Insert Payments
INSERT INTO PAYMENT (Bill_ID, Amount, Mode, Date) VALUES
(1, 200000.00, 'Mobile Money', '2024-01-15'),
(2, 250000.00, 'Cash', '2024-01-16');

-- Insert Inventory Transactions
INSERT INTO INVENTORY_TRANSACTION (Item_ID, Animal_ID, Quantity, Type) VALUES
(1, 1, -10, 'Issue'),
(3, 2, -5, 'Issue'),
(1, 3, -5, 'Issue'),
(2, 4, -20, 'Issue'),
(1, NULL, 100, 'Receipt');

-- ============================================================================
-- STEP 10: VERIFICATION QUERIES
-- ============================================================================

-- Test Views
SELECT * FROM AnimalMedicalHistoryView LIMIT 5;
SELECT * FROM VaccinationStatusView WHERE Status_Description = 'Overdue';

-- Test Stored Procedures
CALL sp_AddVisit(1, 2, '2024-02-20', '10:00:00', 'Scheduled');
CALL sp_UpdateVaccination(1, 'Completed', '2024-01-20');
CALL sp_AddLabtest(1, 'Blood Test', 'Normal', '2024-01-20');

-- Check Triggers (Audit Log should have entries from appointment insertions)
SELECT * FROM AUDITLOG ORDER BY TimeStamp DESC LIMIT 10;

-