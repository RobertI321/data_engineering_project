CREATE TABLE Dim_Date (
    DateKey INT PRIMARY KEY,
    Full_Date DATE NOT NULL,
    Year INT NOT NULL,
    Month INT NOT NULL,
    Month_Name VARCHAR(20) NOT NULL
);

CREATE TABLE Dim_Location (
    LocationKey INT PRIMARY KEY,
    LSOA_Code VARCHAR(20),
    LSOA_Name VARCHAR(255),
    Location_Description VARCHAR(500),
    Latitude DECIMAL(9,6),
    Longitude DECIMAL(9,6)
);

CREATE TABLE Dim_Police_Force (
    PoliceForceKey INT PRIMARY KEY,
    Force_Name VARCHAR(100) NOT NULL
);

CREATE TABLE Dim_Crime_Type (
    CrimeTypeKey INT PRIMARY KEY,
    Crime_Type_Name VARCHAR(255) NOT NULL
);

CREATE TABLE Dim_Crime_Outcome (
    CrimeOutcomeKey INT PRIMARY KEY,
    Outcome_Name VARCHAR(255),
    Is_Resolved BOOLEAN
);

CREATE TABLE Dim_Search_Outcome (
    SearchOutcomeKey INT PRIMARY KEY,
    Outcome_Name VARCHAR(255),
    Is_Successful BOOLEAN
);

CREATE TABLE Dim_Demographics (
    DemographicsKey INT PRIMARY KEY,
    Gender VARCHAR(20),
    Age_Range VARCHAR(20),
    Ethnicity_Self_Defined VARCHAR(100),
    Ethnicity_Officer_Defined VARCHAR(100)
);

CREATE TABLE Dim_Search_Detail (
    SearchDetailKey INT PRIMARY KEY,
    Search_Type VARCHAR(50),
    Legislation_Used VARCHAR(500),
    Object_of_Search VARCHAR(255)
);

-- ===============================
-- FACT TABLES
-- ===============================

CREATE TABLE Fact_Crime_Incident (
    Crime_ID VARCHAR(50) PRIMARY KEY,
    DateKey INT NOT NULL,
    LocationKey INT NOT NULL,
    PoliceForceKey INT NOT NULL,
    CrimeTypeKey INT NOT NULL,
    CrimeOutcomeKey INT NOT NULL,  
    Incident_Count INT DEFAULT 1,

    CONSTRAINT fk_crime_date
        FOREIGN KEY (DateKey) REFERENCES Dim_Date(DateKey),
    CONSTRAINT fk_crime_location
        FOREIGN KEY (LocationKey) REFERENCES Dim_Location(LocationKey),
    CONSTRAINT fk_crime_police
        FOREIGN KEY (PoliceForceKey) REFERENCES Dim_Police_Force(PoliceForceKey),
    CONSTRAINT fk_crime_type
        FOREIGN KEY (CrimeTypeKey) REFERENCES Dim_Crime_Type(CrimeTypeKey),
    CONSTRAINT fk_crime_outcome
        FOREIGN KEY (CrimeOutcomeKey) REFERENCES Dim_Crime_Outcome(CrimeOutcomeKey)
);

CREATE TABLE Fact_Stop_Search (
    Stop_ID VARCHAR(50) PRIMARY KEY,
    DateKey INT NOT NULL,
    LocationKey INT NOT NULL,
    PoliceForceKey INT NOT NULL,
    DemographicsKey INT NULL,     
    SearchOutcomeKey INT NOT NULL,    
    SearchDetailKey INT NOT NULL,
    Stop_Count INT DEFAULT 1,
    Is_Linked_To_Object BOOLEAN,

    CONSTRAINT fk_stop_date
        FOREIGN KEY (DateKey) REFERENCES Dim_Date(DateKey),
    CONSTRAINT fk_stop_location
        FOREIGN KEY (LocationKey) REFERENCES Dim_Location(LocationKey),
    CONSTRAINT fk_stop_police
        FOREIGN KEY (PoliceForceKey) REFERENCES Dim_Police_Force(PoliceForceKey),
    CONSTRAINT fk_stop_demo
        FOREIGN KEY (DemographicsKey) REFERENCES Dim_Demographics(DemographicsKey),
    CONSTRAINT fk_stop_outcome
        FOREIGN KEY (SearchOutcomeKey) REFERENCES Dim_Search_Outcome(SearchOutcomeKey),
    CONSTRAINT fk_stop_detail
        FOREIGN KEY (SearchDetailKey) REFERENCES Dim_Search_Detail(SearchDetailKey)
);