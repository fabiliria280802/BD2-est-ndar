# LabX Database Project

## Overview

This project is a SQL script developed by ITIZ-2201 - DATABASE II students for various class exercises. The script automates the creation and configuration of a database named **LabX**, including the definition of custom data types, validation rules, tables, triggers, and a stored procedure to manage exam result entries.

## Features

- **Database Creation**  
  - Checks if the **LabX** database already exists and deletes it if necessary, then creates a fresh instance.

- **Custom Data Types & Validation Rules**  
  - **`correo`**: A custom data type for storing email addresses.  
  - **`cedulaIdentidad`**: A custom data type for storing Ecuadorian identity card numbers.  
  - **Validation Rules**:  
    - **`cedulaIdentidad_rule`**: Ensures that the identity card number adheres to the Ecuadorian format and verification algorithm.
    - **`correo_rule`**: Validates that email addresses conform to required standards (e.g., proper format, valid length for both username and domain).

- **Table Creation & Triggers**  
  - **Tables**:  
    - **Paciente**: Stores patient information such as identity card, name, email, phone, date of birth, and blood type.  
    - **Examen**: Contains details of medical exams, including exam name, normal value ranges, fasting indicator, and days to deliver the result.  
    - **Resultado**: Records exam results, linking patients and exams via foreign keys. It also validates the sequence of dates (order, exam, and delivery dates).
  - **Triggers**:  
    - Ensure data integrity by preventing unauthorized or direct changes to critical fields like `usuarioRegistro` (system user) and `fechaRegistro` (record timestamp).

- **Stored Procedure**  
  - **`ingresoResultado`**:  
    - Facilitates the insertion of exam results into the **Resultado** table by accepting the exam name, patient's identity card, and relevant date values.
    - Verifies the existence of both the exam and the patient before performing the insertion.

- **Sample Data Insertion**  
  - Provides example insertions into the **Paciente** and **Examen** tables.
  - Demonstrates the use of the stored procedure to insert an exam result.

## How to Use

1. **Execute the Script**:  
   Run the SQL script on your SQL Server. The script will:
   - Create the **LabX** database.
   - Define custom data types and validation rules.
   - Create the required tables and triggers.
   - Set up the stored procedure for inserting exam results.
   - Insert sample data to help you get started.

2. **Customize**:  
   Modify the sample data, validation rules, or table definitions as needed to fit your project's requirements.

## Authors

- ITIZ-2201 Students
- University of the Americas
