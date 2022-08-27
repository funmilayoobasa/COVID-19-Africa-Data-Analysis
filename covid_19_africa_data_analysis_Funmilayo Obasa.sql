/*
PROJECT: Covid 19 Africa Analysis Data
Data begins from 20th Feb., 2020 and ends on 24th June, 2022
*/


/*
QUESTION 1: 
How's Africa doing in comparison to other continents in terms of cases, deaths, tests, vaccinations, GDP and median age.
*/


-- QUERY 1: CREATING VIEW FOR COVID VACCINATIONS PER COUNTRY

CREATE OR ALTER VIEW covid_vaccinations AS
SELECT location, 
	continent, 
	MAX(CAST(people_fully_vaccinated AS bigint)) AS fully_vaccinated,
	MAX(CAST(total_vaccinations AS bigint)) AS total_vaccine_doses, 
	MAX(CAST(people_vaccinated AS bigint)) AS people_vaccinated_at_least_once
FROM covid_data
WHERE continent IS NOT NULL AND people_vaccinated IS NOT NULL
GROUP BY location, 
	continent;


-- QUERY 2: Using a CTE to join vaccination view to continental stats
-- Also storing as a view for easy visualisation

CREATE OR ALTER VIEW continental_stats AS
WITH vac_numbers AS( -- get sum of vaccinations per country and group by continent
	SELECT continent, 
		SUM(fully_vaccinated) AS fully_vaccinated,
		SUM(total_vaccine_doses) AS total_vaccine_doses,
		SUM(people_vaccinated_at_least_once) AS people_vaccinated_at_least_once
	FROM covid_vaccinations
	GROUP BY continent
)
SELECT ca.continent,
	SUM(COALESCE(new_cases, 0)) AS Total_cases, 
	SUM(COALESCE(CAST(new_tests AS bigint), 0)) AS Total_tests,
	SUM(COALESCE(CAST(new_deaths AS bigint),0)) AS Total_deaths, 
	vac_numbers.total_vaccine_doses,
	vac_numbers.people_vaccinated_at_least_once,
	vac_numbers.fully_vaccinated,
	ROUND(AVG(COALESCE(CAST(gdp_per_capita AS decimal),0)),2) AS Average_gdp_per_capita, 
	ROUND(AVG(COALESCE(ca.median_age,0)),2) AS median_age,
	SUM(DISTINCT(population)) AS Continent_population
FROM covid_data AS ca
INNER JOIN vac_numbers
	ON ca.continent = vac_numbers.continent
WHERE ca.continent IS NOT NULL
GROUP BY ca.continent, 
	vac_numbers.fully_vaccinated, 
	vac_numbers.total_vaccine_doses,
	vac_numbers.people_vaccinated_at_least_once;


/*
QUESTION 2:
Which African countries have the highest covid cases & deaths?
*/


-- QUERY 1: Create a view of African COVID data to narrow my focus
-- Each record contains the no. of cases, tests, vaccinations, deaths, etc per day

CREATE OR ALTER VIEW covid_africa_date AS
SELECT 
	iso_code,
	continent, 
	location, 
	date, 
	total_cases, 
	new_cases,
	total_deaths, 
	new_deaths,
	total_tests, 
	new_tests, 
	people_vaccinated, 
	people_fully_vaccinated,
	new_vaccinations,
	total_vaccinations,
	population, 
	median_age, 
	gdp_per_capita,
	life_expectancy
FROM covid_data
WHERE continent = 'Africa';


-- QUERY 2: From the COVID AFRICA view, create another view for African covid data
-- This one is grouped by African country

CREATE OR ALTER VIEW covid_africa_country AS
SELECT ca.location, 
	SUM(CAST(new_cases AS bigint)) AS total_cases_africa,
	SUM(CAST(new_deaths AS bigint)) AS total_deaths_africa,
	SUM(DISTINCT(population)) AS Population,
	COALESCE(cv.fully_vaccinated,0) AS people_fully_vaccinated,
	SUM(CAST(new_tests AS bigint)) AS Total_tests,
	gdp_per_capita,
	life_expectancy,
	median_age
FROM covid_africa_date AS ca
INNER JOIN covid_vaccinations AS cv
	ON ca.location = cv.location
GROUP BY ca.location, 
	gdp_per_capita,
	life_expectancy,
	median_age, 
	cv.fully_vaccinated;
