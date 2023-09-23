Select *
From [Portfolio Project]..[CovidDeaths]
order by 3,4

Select Location, date, total_cases, new_cases, total_deaths, population
From [Portfolio Project]..[CovidDeaths]
order by 1,2

--Total Cases vs Total Deaths in the UK

Select Location, date, total_cases, total_deaths,
    CASE 
        WHEN TRY_CONVERT(float, total_cases) IS NOT NULL AND TRY_CONVERT(float, total_deaths) IS NOT NULL THEN
            (CONVERT(float, total_deaths) / CONVERT(float, total_cases)) * 100
        ELSE
            NULL -- Handle cases where conversion is not possible or data is not numeric
    END AS DeathPercentage
FROM [Portfolio Project]..[CovidDeaths]
WHERE Location = 'United Kingdom' AND total_cases IS NOT NULL AND total_deaths IS NOT NULL
ORDER BY 1, 2;


--Total Cases vs Population
--Query shows the percentage of the UK population that contracted COVID over time during the pandemic
SELECT Location, date, total_cases, Population, (total_cases/population) * 100 as PercentPopulationInfected
FROM [Portfolio Project]..[CovidDeaths]
WHERE Location = 'United Kingdom' AND total_cases IS NOT NULL
ORDER BY Location, Date;


--Countries with highest infection rate compared to population
SELECT Location, MAX(cast(total_cases as bigint)) as HighestInfectionCount, population , MAX((total_cases/population)) * 100 as PercentPopulationInfected
FROM [Portfolio Project]..[CovidDeaths]
WHERE total_cases IS NOT NULL AND continent IS NOT NULL
Group by Location, Population
ORDER BY PercentPopulationInfected desc;


--Countries with highest death count per population
SELECT Location, MAX(cast(total_deaths as bigint)) as TotalDeaths
FROM [Portfolio Project]..[CovidDeaths]
WHERE total_deaths IS NOT NULL AND continent IS NOT NULL
Group by Location
ORDER BY TotalDeaths desc;


--Continents with highest death count per population
SELECT Location, MAX(cast(total_deaths as bigint)) as TotalDeaths
FROM [Portfolio Project]..[CovidDeaths]
WHERE  continent IS NULL AND Location NOT IN ('High income', 'Upper middle income', 'Lower middle income', 'Low income','World','European Union')
Group by Location
ORDER BY TotalDeaths desc;


-- Global numbers
SELECT 
       SUM(new_cases) as total_cases,
       SUM(cast(new_deaths as bigint)) as total_deaths,
       CASE
           WHEN SUM(new_cases) = 0 THEN NULL -- Handle divide by zero case
           ELSE (SUM(cast(new_deaths as bigint)) * 100.0) / SUM(new_cases)
       END as DeathPercentage
FROM [Portfolio Project]..[CovidDeaths]
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
Select CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations,
	SUM(cast(CovidVaccinations.new_vaccinations as bigint)) OVER (PARTITION BY CovidDeaths.location ORDER BY CovidDeaths.location, CovidDeaths.date) as RollingCount
	 FROM [Portfolio Project]..[CovidDeaths]
	 JOIN [Portfolio Project]..[CovidVaccinations]
		ON CovidDeaths.location = CovidVaccinations.location
		AND CovidDeaths.date = CovidVaccinations.date
WHERE CovidDeaths.continent IS NOT NULL AND CovidVaccinations.new_vaccinations IS NOT NULL
order by 2,3

--Total Population vs Vaccinations
--Using CTE to perform Calculation on Partition By in previous query
With PopulationVsVaccination(Continent, Location, Date, Population, New_Vaccination, RollingCount)
as
(
	Select CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations,
	SUM(cast(CovidVaccinations.new_vaccinations as bigint)) OVER (PARTITION BY CovidDeaths.location ORDER BY CovidDeaths.location, CovidDeaths.date) as RollingCount
	 FROM [Portfolio Project]..[CovidDeaths]
	 JOIN [Portfolio Project]..[CovidVaccinations]
		ON CovidDeaths.location = CovidVaccinations.location
		AND CovidDeaths.date = CovidVaccinations.date
	WHERE CovidDeaths.continent IS NOT NULL AND CovidVaccinations.new_vaccinations IS NOT NULL
)
SELECT *, (RollingCount/Population) *100 FROM PopulationVsVaccination


-- TEMP TABLE
--Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_Vaccination numeric,
RollingCount numeric
)

INSERT INTO #PercentPopulationVaccinated
	Select CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations,
	SUM(cast(CovidVaccinations.new_vaccinations as bigint)) OVER (PARTITION BY CovidDeaths.location ORDER BY CovidDeaths.location, CovidDeaths.date) as RollingCount
	 FROM [Portfolio Project]..[CovidDeaths]
	 JOIN [Portfolio Project]..[CovidVaccinations]
		ON CovidDeaths.location = CovidVaccinations.location
		AND CovidDeaths.date = CovidVaccinations.date
	WHERE CovidDeaths.continent IS NOT NULL AND CovidVaccinations.new_vaccinations IS NOT NULL
	--ORDER BY 2,3
SELECT *, (RollingCount/Population) *100 FROM #PercentPopulationVaccinated



-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated as 
Select CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations,
	SUM(cast(CovidVaccinations.new_vaccinations as bigint)) OVER (PARTITION BY CovidDeaths.location ORDER BY CovidDeaths.location, CovidDeaths.date) as RollingCount
	 FROM [Portfolio Project]..[CovidDeaths]
	 JOIN [Portfolio Project]..[CovidVaccinations]
		ON CovidDeaths.location = CovidVaccinations.location
		AND CovidDeaths.date = CovidVaccinations.date
	WHERE CovidDeaths.continent IS NOT NULL AND CovidVaccinations.new_vaccinations IS NOT NULL


SELECT * FROM PercentPopulationVaccinated