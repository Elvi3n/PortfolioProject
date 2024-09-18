Select *
From PortfolioProject..CovidDeaths
Where continent is not NULL
order by 3,4



-- Select Data that we are going to use

-- Ordered by location and date
Select location, date, total_cases, new_cases, total_deaths, population 
From PortfolioProject..CovidDeaths
order by 1, 2


-- Looking at total cases vs total deaths
-- Shows the likelihood of dying from COVID in each countries
SELECT location, date, total_cases, total_deaths, 
	CASE
		WHEN total_cases =0 THEN NULL    -- if total_cases is 0, return NULL
		ELSE (total_deaths / total_cases)*100  -- Otherwise, calculate the deathrate
	END as death_percentage
From PortfolioProject..CovidDeaths
WHERE location like '%States'
order by 2,5



-- Inspect the Total cases vs population
SELECT location, date, total_cases, population, (total_cases/population)*100 as infection_rate
From PortfolioProject..CovidDeaths
WHERE location like '%States'
order by 2,5



-- Looking at countries with highest infection rate vs population
-- Make sure the selected columns are grouped, otherwise remove them from the selections
SELECT location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population)*100) as infection_rate
From PortfolioProject..CovidDeaths
group by location, population
order by 4 desc  -- Descending order

-- Breaking things down by continent
-- Showing continents with the highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) as total_death_count  -- using case just in case some values are not int
From PortfolioProject..CovidDeaths
Where continent is not NULL
group by continent
order by 1 desc  -- Descending order



-- Showing countries with highest death count vs population
SELECT location, population, MAX(cast(total_deaths as int)) as total_death_count  -- using case just in case some values are not int
From PortfolioProject..CovidDeaths
Where continent is not NULL
group by location, population
order by 3 desc  -- Descending order



-- GLOBAL NUMBERS
SELECT date, 
	   SUM(new_cases) as global_total_cases, 
	   SUM(cast(new_deaths as int)) as global_new_deaths,
	   CASE
			WHEN SUM(new_cases) = 0 THEN NULL
			ELSE SUM(cast(new_deaths as int)) / SUM(new_cases)
			END as Death_percentage
	   -- using case just in case some values are not int
From PortfolioProject..CovidDeaths
Where continent is not NULL
group by date
order by 1, 2  -- Descending order

----------------------------------------------------------------------

-- JOING THE TWO TABLES
Select *
From PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..CovidVaccine vac
	on deaths.location = vac.location
	and deaths.date = vac.date


-- Total Population vs Vaccinations

-- USE CTE
WITH  Pop_vs_Vac (Continent, location, date, population, New_Vaccinations, Rolling_People_Vaccinated) as
(
Select deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations
,	   SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by deaths.location Order by deaths.location, deaths.date) as Rolling_People_vaccinated
From PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..CovidVaccine vac
	on deaths.location = vac.location
	and deaths.date = vac.date
WHERE deaths.continent is not null
)
SELECT *, (Rolling_People_Vaccinated/Population)*100
FROM Pop_vs_Vac


-- Use temp table

IF OBJECT_ID('tempdb..#PercentPopulationVaccinated') IS NOT NULL
    DROP TABLE #PercentPopulationVaccinated;

Create Table #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_Vaccinations numeric,
    Rolling_People_Vaccinated numeric
);

INSERT INTO #PercentPopulationVaccinated
Select deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations
,	   SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by deaths.location Order by deaths.location, deaths.date) as Rolling_People_Vaccinated
From PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..CovidVaccine vac
	on deaths.location = vac.location
	and deaths.date = vac.date
WHERE deaths.continent is not null
-- ORDER BY 2,3

SELECT *, (Rolling_People_Vaccinated/Population)*100
FROM #PercentPopulationVaccinated


-- Creating View to store data for visualization later
CREATE View PercentPopulationVaccinated
as
Select deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations
,	   SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by deaths.location Order by deaths.location, deaths.date) as Rolling_People_Vaccinated
From PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..CovidVaccine vac
	on deaths.location = vac.location
	and deaths.date = vac.date
WHERE deaths.continent is not null
ORDER BY 2,3