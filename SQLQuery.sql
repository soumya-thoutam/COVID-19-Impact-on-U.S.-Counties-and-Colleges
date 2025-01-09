-----------------------
-- Covid-19 Analysis --
-----------------------

-- Create Tables --

-- Create WorldRel Table
CREATE TABLE WorldRel
(
  iso_code VARCHAR(10) NOT NULL,
  country VARCHAR(100) NOT NULL,
  PRIMARY KEY (iso_code)
);

-- Create StateRel Table
CREATE TABLE StateRel
(
  state_code VARCHAR(10) NOT NULL,
  state VARCHAR(100) NOT NULL,
  PRIMARY KEY (state_code)
);

-- Create USCollegeRel Table
CREATE TABLE USCollegeRel
(
  clg_name VARCHAR(100) NOT NULL,
  city VARCHAR(100) NOT NULL,
  clg_ID INT NOT NULL,
  state_code VARCHAR(10) NOT NULL,
  PRIMARY KEY (clg_ID),
  FOREIGN KEY (state_code) REFERENCES StateRel(state_code)
);

-- Create Worldwide_Cases Table
CREATE TABLE Worldwide_Cases
(
  country VARCHAR(100) NOT NULL,
  date DATE NOT NULL,
  cases INT NOT NULL,
  deaths INT NOT NULL,
  iso_code VARCHAR(10) NOT NULL,
  PRIMARY KEY (country, iso_code),
  FOREIGN KEY (iso_code) REFERENCES WorldRel(iso_code)
);

-- Create US_States Table
CREATE TABLE US_States
(
  state VARCHAR(100) NOT NULL,
  city VARCHAR(100) NOT NULL,
  county VARCHAR(100) NOT NULL,
  state_code VARCHAR(10) NOT NULL,
  PRIMARY KEY (state, city, county),
  FOREIGN KEY (state_code) REFERENCES StateRel(state_code)
);

-- Create US_College_Cases Table
CREATE TABLE US_College_Cases
(
  clg_name VARCHAR(100) NOT NULL,
  cases2020 INT NOT NULL,
  cases2021 INT NOT NULL,
  clg_ID INT NOT NULL,
  FOREIGN KEY (clg_ID) REFERENCES USCollegeRel(clg_ID)
);

-- Create United_States_covid_record Table
CREATE TABLE United_States_covid_record
(
  iso_code VARCHAR(10) NOT NULL,
  country VARCHAR(100) NOT NULL,
  date DATE NOT NULL,
  cases INT NOT NULL,
  deaths INT NOT NULL,
  PRIMARY KEY (iso_code, country, date)
);

-- *********************
-- Data Extraction
-- *********************

-- 1. Extracting Cases and Deaths in United States with Dates
SELECT cases, deaths, date 
FROM worldwide_cases 
WHERE country = 'United States';

-- 2. Total Number of Cases and Deaths Worldwide (Excluding the United States)
SELECT COUNT(cases), COUNT(deaths) 
FROM Worldwide_Cases 
WHERE country NOT IN ('USA');

-- 3. Average Number of Cases and Deaths Worldwide (Excluding the United States)
SELECT AVG(cases) AS avg_cases, AVG(deaths) AS avg_deaths 
FROM Worldwide_Cases 
WHERE country != 'United States';

-- 4. Adding Records Fetched from Worldwide Cases into the United States COVID Records
INSERT INTO United_States_covid_record 
SELECT iso_code, country, date, cases, deaths
FROM Worldwide_Cases 
WHERE iso_code = 'USA';

-- 5. Total Cases and Deaths in the United States
SELECT iso_code, SUM(cases + deaths) AS total 
FROM Worldwide_Cases 
WHERE iso_code = 'USA' 
GROUP BY iso_code;

-- 6. Highest Cases and Deaths in the World
SELECT MAX(cases) AS max_cases, MAX(deaths) AS max_deaths 
FROM Worldwide_Cases;

-- *********************
-- Analysis by State & College
-- *********************

-- 7. Count of Cities in Each State of the United States
SELECT state, COUNT(city) 
FROM US_States 
GROUP BY state;

-- 8. Colleges Where Cases in 2020 are Greater than 100 and College Name Starts with 'U'
SELECT clg_name 
FROM US_College_Cases 
WHERE cases2020 > 100 
AND clg_name LIKE 'U%';

-- 9. College ID, Name, and Total Number of Cases in 2020 and 2021
SELECT clg_ID, clg_name, cases2020 + cases2021 AS total_cases 
FROM US_College_Cases;

-- 10. City and State Code of the College with the Highest Number of Cases in 2020
SELECT UR.city, UR.state_code 
FROM USCollegeRel AS UR 
JOIN US_College_Cases AS UC 
    ON UR.clg_ID = UC.clg_ID 
WHERE cases2020 = (SELECT MAX(cases2020) FROM US_College_Cases);

-- 11. Iso Code, Country, Cases, and Deaths Worldwide from May 2020 to January 2021
SELECT iso_code, cases, deaths 
FROM Worldwide_Cases 
WHERE date BETWEEN '2020-05-01' AND '2021-01-01';

-- 12. College ID and Name with More Than One Case in 2020, Including Colleges with Zero Cases
SELECT clg_ID, clg_name 
FROM US_College_Cases 
WHERE cases2020 > 1 OR cases2020 = 0;

-- *********************
-- Advanced SQL Queries
-- *********************

-- 13. Checking if College ID Exists in College Reference Table for 2021
SELECT clg_ID 
FROM US_College_Cases 
WHERE clg_ID IN (SELECT clg_ID FROM US_College_Cases);

-- 14. Creating a View for Colleges with Total Cases Greater Than 500
CREATE VIEW highCovid AS 
SELECT clg_ID, SUM(cases2020 + cases2021) AS total_cases 
FROM US_College_Cases 
WHERE cases2020 > 500 
GROUP BY clg_ID;

-- 15. Creating an Index on City Names in the US_States Table
CREATE INDEX city_names ON US_States (city);

-- 16. Creating a Function to Select County from a Particular City in the US_States Table
CREATE OR REPLACE FUNCTION SelectAllCounty() 
RETURNS TABLE(citi VARCHAR) AS $$
BEGIN
    RETURN QUERY 
    SELECT city FROM US_States;
END;
$$ LANGUAGE plpgsql;

-- Calling the function to select cities from the US_States table
SELECT citi FROM SelectAllCounty();

-- 17. Creating a Table for Colleges Affected by COVID in 2021
CREATE TABLE college_cases (
    clg_ID INT, 
    clg_name VARCHAR(30), 
    CHECK (cases2021 > 100)
);

-- 18. Matching City Names from the Same State
SELECT c1.city AS cityname1, c2.city AS cityname2, c1.state 
FROM US_States c1, US_States c2 
WHERE c1.state_code <> c2.state_code 
AND c1.state = c2.state 
ORDER BY c1.state;

-- 19. Inserting New Cases in 2020 or 2021 While Ensuring College ID Has Not Appeared Previously
CREATE OR REPLACE TRIGGER tri
AFTER UPDATE OF cases ON US_College_Cases
FOR EACH ROW
WHEN (OLD.cases != NEW.cases)
BEGIN
   -- Logic to handle update, e.g., insert into another table or log
   INSERT INTO some_log_table(clg_ID, old_cases, new_cases)
   VALUES (:OLD.clg_ID, :OLD.cases, :NEW.cases);
END;


-- *********************
-- Updates and Insertions
-- *********************

-- 20. Updating the First City with a New City and State
UPDATE US_States 
SET city = 'Anchorage', state = 'Alaska' 
WHERE state_code = 'AK';
