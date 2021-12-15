/*
COVID Deaths, Infections, & Vaccinations
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Exploring the Data
SELECT * FROM Portfolio_Project..CovidDeaths$
	ORDER BY 3,4  
SELECT * FROM Portfolio_Project..CovidVaccinations$
	ORDER BY 3,4

SELECT * FROM Portfolio_Project..CovidDeaths$
	WHERE continent IS NOT NULL
	ORDER BY 3,4  

SELECT location, date, total_cases, new_cases, total_deaths, population 
	FROM Portfolio_Project..CovidDeaths$
	ORDER BY 1,2 

-- Total Cases Vs. Total Deaths
-- Shows likeihood of dying per day in the States
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage 
	FROM Portfolio_Project..CovidDeaths$
	WHERE location LIKE '%states%'
	ORDER BY 1,2 

--Total Cases Vs. Population
--Shows what is the percenatage of the population was infected with covid

SELECT location, date, total_cases, population, (total_cases/population)*100 AS Case_Percentage 
	FROM Portfolio_Project..CovidDeaths$
	WHERE location LIKE '%states%'
	ORDER BY 1,2 

--Countries with Highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS Highest_Infection_Count, 
	MAX((total_cases/population))*100 AS Infected_Pop_Percent 
		FROM Portfolio_Project..CovidDeaths$
	GROUP BY location, population
	ORDER BY Infected_Pop_Percent DESC

--Countries with Highest death rate compared to population
SELECT location, MAX(CAST(total_deaths AS INT)) AS Total_Death_Count 
	FROM Portfolio_Project..CovidDeaths$
	WHERE continent IS NOT NULL
	GROUP BY location
	ORDER BY Total_Death_Count DESC

--Contintents with the highest death count per population
SELECT location, MAX(CAST(total_deaths AS INT)) AS Total_Death_Count 
	FROM Portfolio_Project..CovidDeaths$
	WHERE continent IS NULL 
		AND location NOT IN ('World','Upper middle income','High income',
		'Lower middle income','European Union', 'Low income', 'International')
	GROUP BY location
	ORDER BY Total_Death_Count DESC

--Global Numbers
SELECT SUM(new_cases) AS Total_Cases, SUM(CAST(new_deaths AS INT)) AS Total_Deaths, 
	SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS Death_Percent
		FROM Portfolio_Project..CovidDeaths$
	WHERE continent is not null
	ORDER BY 1,2 

SELECT * FROM Portfolio_Project..CovidDeaths$ AS dea
	JOIN Portfolio_Project..CovidVaccinations$ AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date

--Total Population vs Vaccinations
--Will show Percentage of Population that has received at least one dose of COVID vaccine in the CTE and Temp Table
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
	AS Rolling_People_Vaccinated
		FROM Portfolio_Project..CovidDeaths$ AS dea
	JOIN Portfolio_Project..CovidVaccinations$ AS vac
		ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	ORDER BY 2,3

--Using CTE to calculate Partition by from above (Total Population vs Vaccinations)
With PopvsVac (continent, location, date, population, new_vaccinations, Rolling_People_Vaccinated) 
	AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
	AS Rolling_People_Vaccinated
		FROM Portfolio_Project..CovidDeaths$ AS dea
	JOIN Portfolio_Project..CovidVaccinations$ AS vac
		ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
)
SELECT *, (Rolling_People_Vaccinated/population)*100 
		FROM PopvsVac

--Using Temp table to calculate Partition by from above (Total Population vs Vaccinations)
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
	(continent NVARCHAR(255),
	location NVARCHAR(255),
	date DATETIME,
	population NUMERIC,
	new_vaccinations NUMERIC,
	RollingPeopleVaccinated NUMERIC)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
	AS RollingPeopleVaccinated
		FROM Portfolio_Project..CovidDeaths$ AS dea
	JOIN Portfolio_Project..CovidVaccinations$ AS vac
		ON dea.location = vac.location 
		AND dea.date = vac.date

SELECT *, (RollingPeopleVaccinated/population)*100 
		FROM #PercentPopulationVaccinated

-- Creating View to store data for visualization
CREATE VIEW PercentPopulationVaccinated AS
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
	AS Rolling_People_Vaccinated
		FROM Portfolio_Project..CovidDeaths$ AS dea
	JOIN Portfolio_Project..CovidVaccinations$ AS vac
		ON dea.location = vac.location 
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL

SELECT * FROM PercentPopulationVaccinated

--Tableau Code

--1
SELECT SUM(new_cases) AS Total_Cases, SUM(CAST(new_deaths AS INT)) AS Total_Deaths, 
	SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS Death_Percent
		FROM Portfolio_Project..CovidDeaths$
	WHERE continent IS NOT NULL
	ORDER BY 1,2

--2
SELECT location, SUM(CAST(new_deaths AS INT)) AS Total_Death_Count
		FROM Portfolio_Project..CovidDeaths$
	WHERE continent IS NULL
		AND location NOT IN ('World','European Union','International')
	GROUP BY location
	ORDER BY Total_Death_Count DESC

--3
SELECT location, population, MAX(total_cases) AS Highest_Infection_Count, 
	MAX((total_cases/population))*100 AS Percent_Population_Infected
		FROM Portfolio_Project..CovidDeaths$
	GROUP BY location, population
	ORDER BY Percent_Population_Infected DESC

--4
SELECT location, population, date, MAX(total_cases) AS Highest_Infection_Count,
	MAX((total_cases/population))*100 AS Percent_Population_Infected
		FROM Portfolio_Project..CovidDeaths$
	GROUP BY location, population, date
	ORDER BY Percent_Population_Infected DESC