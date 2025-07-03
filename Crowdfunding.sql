
-- =========Group 2 - Crowdfunding ======= --

Create Database crowdfunding;           -- To create database
use crowdfunding;                       -- to use same database

########################################################################################################################
############## To cross check count of uploaded data from Excel files ##################################################

select count(*) as TotalRows
FROM Crowdfunding_location;             -- To cross check count of location table
SELECT COUNT(*) AS TotalRows 
FROM Crowdfunding_creator;              -- To cross check count of Creator table    
SELECT COUNT(*) AS TotalRows 
FROM Crowdfunding_category;             -- To cross check count of Category table 
SELECT COUNT(*) AS TotalRows 
FROM projects;                          -- To cross check count of Projects table   


########################################################################################################################
########################################################################################################################

 ##### Q1) Convert the Date fields to normal format (from Epoch To Normal)
 
 /* For convertion dates new column added to store new date format (Epoch to normal date format from project */

ALTER TABLE projects
ADD created_at_date DATETIME,
ADD deadline_date DATETIME,
ADD updated_at_date DATETIME,
ADD state_changed_at_date DATETIME,
ADD launched_at_date DATETIME;

/* convert EPOCH date in to normal date format and add into new created columns */


SET SQL_SAFE_UPDATES = 0;      /* Use to disables "Safe Update Mode" in MySQL for 
                                current session , Safe update mode is a safety feature that prevents 
                                accidental UPDATE or DELETE statements */
                               

UPDATE projects
SET created_at_date = FROM_UNIXTIME(created_at),                  --  Converts 'created_at' from Unix timestamp to readable date and stores it in 'created_at_date'
    deadline_date = FROM_UNIXTIME(deadline),                      -- Converts 'deadline' from Unix timestamp to readable date and stores it in 'deadline_date'
    updated_at_date = FROM_UNIXTIME(updated_at),                  -- Converts 'updated_at' from Unix timestamp to readable date and stores it in 'updated_at_date'      
    state_changed_at_date = FROM_UNIXTIME(state_changed_at),      -- Converts 'state_changed_at' from Unix timestamp to readable date and stores it in 'state_changed_at_date
    launched_at_date = FROM_UNIXTIME(launched_at);                -- Converts 'launched_at' from Unix timestamp to readable date and stores it in 'launched_at_date' 
    
######## To cross check converted dates
    
SELECT ProjectID, created_at, created_at_date, deadline, deadline_date
FROM projects  LIMIT 5;


########################################################################################################################
############ Create calender table ##################################################################################### 

	CREATE TABLE Calendar (
		Date DATE PRIMARY KEY,
		Year INT,
		MonthNo INT,
		MonthFullName VARCHAR(20),
		Quarter VARCHAR(3),
		YearMonth VARCHAR(10),
		WeekdayNo INT,
		WeekdayName VARCHAR(15),
		FinancialMonth VARCHAR(5),
		FinancialQuarter VARCHAR(5)
	);

-- MySQL limits the number of iterations in a recursive Common Table Expression (CTE) to 1000 by default.
-- You are generating dates using a recursive CTE.
-- The number of days between your minimum and maximum dates in the projects table exceeds 1000.
-- MySQL restricts recursion to 1000 levels to prevent infinite loops.

SET @@cte_max_recursion_depth = 30000;



-- Insert data using the minimum and maximum dates from projects table

INSERT INTO Calendar (Date, Year, MonthNo, MonthFullName, Quarter, 
YearMonth, WeekdayNo, WeekdayName, FinancialMonth, FinancialQuarter)
WITH RECURSIVE dates AS (                                                      -- Begins a recursive CTE to generate a list of dates
    SELECT MIN(created_at_date) AS Date                                        -- Gets the earliest project creation date as the starting point
    FROM projects
    UNION ALL                                                                  -- Combines the result of two SELECT statements.
    SELECT Date + INTERVAL 1 DAY                                               -- Adds 1 day in each recursive step 
    FROM dates
    WHERE Date < (SELECT MAX(created_at_date) FROM projects)                   -- Continues until the latest project creation date is reached
)
SELECT 
    Date,
    YEAR(Date) AS Year,
    MONTH(Date) AS MonthNo,
    DATE_FORMAT(Date, '%M') AS MonthFullName,
    CONCAT('Q', QUARTER(Date)) AS Quarter,
    DATE_FORMAT(Date, '%Y-%b') AS YearMonth,
    DAYOFWEEK(Date) AS WeekdayNo,
    DAYNAME(Date) AS WeekdayName,
    CONCAT('FM', (MONTH(Date) + 8) % 12 + 1) AS FinancialMonth,
    CONCAT('FQ-', CEIL(((MONTH(Date) + 8) % 12 + 1) / 3)) AS FinancialQuarter
FROM dates;

SELECT * FROM Calendar ORDER BY Date LIMIT 10;
 

########################################################################################################################
######################################### To Check the Data ############################################################

select * from projects;
select * from Crowdfunding_category;
select * from Crowdfunding_creator;
select * from Crowdfunding_location;
Select * from calendar;

########################################################################################################################
########################################################################################################################

##### Q3 - Convert the Goal amount into USD using the Static USD Rate.

	ALTER TABLE projects                            -- Alter the Table to Add a New Column:
ADD goal_usd FLOAT;


UPDATE projects                                     -- Update the New Column with the Converted Value:
SET goal_usd = goal * static_usd_rate;


SELECT ProjectID, goal, static_usd_rate, goal_usd   -- Verify the Conversion
FROM projects
where static_usd_rate >1
LIMIT 100;

########################################################################################################################
########################################################################################################################

#####     Total Number of Projects based on outcome 

SELECT state AS Outcome, COUNT(*) AS TotalProjects    -- Selects the 'state' column and renames it as 'Outcome'; counts total projects per state
FROM projects                                         -- From the 'projects' table  
GROUP BY state;                                       -- Groups the data by 'state' to get count per unique state   

########################################################################################################################
########################################################################################################################
#####  Total Number of Projects based on Locations

/* To calculate the Total Number of Projects based on Locations, we will use the projects and Crowdfunding_Location tables.*/

SELECT l.displayable_name AS Location, COUNT(p.ProjectID) AS TotalProjects -- Selects location name as 'Location' and counts total projects per location
FROM projects p                                                            -- From the 'projects' table with alias 'p'
JOIN Crowdfunding_Location l ON p.location_id = l.id                       -- Join with 'Crowdfunding_Location' table to get location names 
GROUP BY l.displayable_name                                                -- Group by location name to count projects per location  
ORDER BY TotalProjects DESC                                                -- Sort the result by total projects in descending order 
limit 10;                                                                  -- Limit the output to top 10 locations  


########################################################################################################################
########################################################################################################################
#####  Total Number of Projects based on  Category

/* To calculate the Total Number of Projects based on Category, we will use the projects and Crowdfunding_Category tables.*/

SELECT c.name AS Category, COUNT(p.ProjectID) AS TotalProjects  -- Select category name as 'Category' and count total projects per category
FROM projects p                                                 -- From the 'projects' table with alias 'p' 
JOIN Crowdfunding_Category c ON p.category_id = c.id            -- Performs an INNER JOIN with 'Crowdfunding_Category' using 'category_id' to match category names
GROUP BY c.name                                                 -- Groups the result set by each unique category name
ORDER BY TotalProjects DESC;                                    -- Orders the results by total number of projects in descending order


########################################################################################################################
########################################################################################################################
##### Total Number of Projects created by Year , Quarter , Month

#### By Year
SELECT c.Year, COUNT(p.ProjectID) AS TotalProjects             -- Selects the year from the calendar and counts the number of projects created in that year 
FROM projects p                                                -- From the 'projects' table, using alias 'p' 
JOIN Calendar c ON p.created_date_only = c.date_only           -- Joins with the 'Calendar' table on the date to match project creation dates with calendar dates
GROUP BY c.Year                                                -- Groups the result set by each unique year
ORDER BY c.Year;                                               -- Orders the results by year in ascending order

#### By Qurter

SELECT c.Quarter, COUNT(p.ProjectID) AS TotalProjects          -- Selects the quarter from the calendar and counts the number of projects created in that quarter     
FROM projects p                                                -- From the 'projects' table, using alias 'p'
JOIN Calendar c ON DATE(p.created_at_date) = DATE(c.Date)      -- Performs an INNER JOIN with 'Calendar' to match each project's creation date with the calendar date (using DATE to ignore time)
GROUP BY c.Quarter                                             -- Groups the result set by each unique quarter
ORDER BY c.Quarter;                                            -- Orders the results by quarter in ascending order 

#### By Month

SELECT c.MonthFullName, COUNT(p.ProjectID) AS TotalProjects    -- Selects the full month name and counts the number of projects created in each month   
FROM projects p                                                -- From the 'projects' table, using alias 'p'
JOIN Calendar c ON DATE(p.created_at_date) = DATE(c.Date)      -- Performs an INNER JOIN with 'Calendar' to match each project's creation date with the calendar date
GROUP BY  c.MonthNo, c.MonthFullName                           -- Groups the result set by month number and full month name to ensure correct sorting and labeling  
ORDER BY  c.MonthNo;                                           -- Orders the results by month number (1 for Jan, 2 for Feb, etc.)


########################################################################################################################
########################################################################################################################
##### Successful Projects- Amount Raised 

SELECT SUM(pledged) AS TotalAmountRaised,                      -- Sums the 'pledged' amounts of all successful projects and renames the result as 'TotalAmountRaised'
CASE
    WHEN SUM(pledged) >= 1000000000 THEN CONCAT(ROUND(SUM(pledged)/1000000000, 2), ' B')  
    WHEN SUM(pledged) >= 1000000    THEN CONCAT(ROUND(SUM(pledged)/1000000,    2), ' M')  
    WHEN SUM(pledged) >= 1000       THEN CONCAT(ROUND(SUM(pledged)/1000,       2), ' K') 
    ELSE ROUND(SUM(pledged), 2)                                                     
  END AS TotalAmountRaised
FROM projects                                                  -- From the 'projects' table
WHERE state = 'successful';                                    -- Filters the records to include only projects with 'successful' state



########################################################################################################################
########################################################################################################################
##### Successful Projects- number of backers

SELECT SUM(backers_count) AS backerwise_AmountRaised           -- Sums the number of backers for all successful projects and renames it as 'TotalBackers'
FROM projects                                                  -- From the 'projects' table	 
WHERE state = 'successful';                                    -- Filters the records to include only projects with 'successful' state      

 
########################################################################################################################
########################################################################################################################
##### Avg NUmber of Days for successful projects
 
SELECT ROUND(AVG(DATEDIFF(deadline_date, launched_at_date)), 2) AS AvgProjectDurationDays  -- Calculates the average duration (in days) between launch and deadline for successful projects, rounded to 2 decimal places
FROM projects                                                                              -- From the 'projects' table
WHERE state = 'successful';                                                                -- Filters the records to include only projects with 'successful' state


########################################################################################################################
########################################################################################################################
##### Top  5 Successful Projects 

select name, sum(usd_pledged) as Top_Successful_Projects    -- Selects project name and calculates total USD pledged per project, renaming it as 'Top_Successful_Projects
from projects                                               -- From the 'projects' table
where state = 'successful'                                  -- Filters the records to include only projects with 'successful' state 
group by name                                               -- Groups the result by project name to get total per project
order by Top_Successful_Projects desc                       -- Sorts the result in descending order of total pledged amount  
limit 5;                                                    -- Limits the output to top 5 projects



########################################################################################################################
########################################################################################################################
##### Top 5 Successful Projects - Based on Number of Backers
 
select name , sum(backers_count) as Backerwise_successful_projects   -- Selects project name and sums the number of backers for each successful project
from projects                                                        -- From the 'projects' table 
where state = 'successful'                                           -- Filters the records to include only projects with 'successful' state
group by name                                                        -- Groups the result by project name to calculate total backers per project   
order by Backerwise_successful_projects desc                         -- Sorts the result in descending order of total backers
limit 5;	                                                         -- Limits the output to top 5 projects


########################################################################################################################
########################################################################################################################
##### Percentage of Successful Projects overall

SELECT 
  ROUND((SUM(CASE WHEN state = 'successful' THEN 1 ELSE 0 END) * 100.0)   -- Counts successful projects (1 for each), multiplies by 100 to convert to percentage
  / COUNT(*),2                                                            -- Divides by total number of projects to get the success rate , Rounds the result to 2 decimal places
  ) AS SuccessPercentage                                                  -- Renames the final result as 'SuccessPercentage'
FROM projects;                                                            -- From the 'projects' table

 
#################################################################################################################################################
#################################################################################################################################################
##### Percentage of Successful Projects  by Category

SELECT 
  c.name AS Category,                                                                         -- Selects the category name from the 'Crowdfunding_Category' table
  COUNT(p.ProjectID) AS TotalProjects,                                                        -- Counts the total number of projects in each category  
  SUM(CASE WHEN p.state = 'successful' THEN 1 ELSE 0 END) AS SuccessfulProjects,              -- Counts the number of successful projects per category
  ROUND(                                                                                   
    (SUM(CASE WHEN p.state = 'successful' THEN 1 ELSE 0 END) * 100.0)                         -- Multiplies successful project count by 100 to convert to percentage  
    / COUNT(p.ProjectID),2                                                                    -- Divides by total projects in the category to get success rate
  ) AS SuccessPercentage                                                                      -- Renames the final result as 'SuccessPercentage'   
FROM projects p                                                                               -- From the 'projects' table (alias 'p')
JOIN Crowdfunding_Category c ON p.category_id = c.id                                          -- Joins with 'Crowdfunding_Category' table to get category names  
GROUP BY c.name                                                                               -- Groups the result by category name
ORDER BY SuccessPercentage asc	                                                              -- Sorts the result by success percentage in ascending order
limit 5;                                                                                      -- Limits the output to the 5 categories with the lowest success rate	


#################################################################################################################################################
#################################################################### == END == ##################################################################




























