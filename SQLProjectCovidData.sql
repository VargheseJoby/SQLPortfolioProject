Select *
from PortfolioProject.dbo.CovidDeaths$
Where continent is Not Null
Order by 3,4

--Select *
--from PortfolioProject.dbo.CovidVaccinations$
--Order by 3,4

Select Location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject.dbo.CovidDeaths$
Order by 1,2

--Total Cases vs Total Deaths (Percentage)

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject.dbo.CovidDeaths$
Order by 1,2

--Total Cases vs Population (Percentage)

Select Location, date, population, total_cases,(total_cases/population)*100 as CovidPercentage
from PortfolioProject.dbo.CovidDeaths$
--Where location = 'India'
Order by 1,2

-- Countries with Highest Infection Rate compared to Population

Select Location, population, MAX(total_cases) as HighestInfectionCount,MAX((total_cases/population))*100 as PercentPopulationInfected
from PortfolioProject.dbo.CovidDeaths$
--Where location = 'India'
Group By location, population
Order by PercentPopulationInfected DESC

-- Countries with Highest Death Count Per Population

Select Location, Max(Cast(total_deaths as INT)) as TotalDeathCount
from PortfolioProject.dbo.CovidDeaths$
Where continent is Not Null
Group By location
Order by TotalDeathCount DESC


-- Let's break this down by Continent

--Showing the continents with highest death count per population

Select continent, Max(Cast(total_deaths as INT)) as TotalDeathCount
from PortfolioProject.dbo.CovidDeaths$
Where continent is Not Null and
Location <> 'World' and
Location <> 'High Income'and
Location <> 'Upper middle income' and
Location <> 'Lower middle income' and
Location <> 'Low income'
Group By continent
Order by TotalDeathCount DESC

-- Global Numbers by Date

Select Date, SUM(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, 
(SUM(cast(new_deaths as int))/SUM(new_cases)) *100 as DeathPercentage
From PortfolioProject.dbo.CovidDeaths$
Where continent is not null
Group by Date
Order by 1,2

-- Global Numbers so far by this Date

Select SUM(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, 
(SUM(cast(new_deaths as int))/SUM(new_cases)) *100 as DeathPercentage
From PortfolioProject.dbo.CovidDeaths$
Where continent is not null
Order by 1,2

-- Death Percentage over Population as at today

Select SUM(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, SUM(Population) as TotalPopulation,
(SUM(cast(new_deaths as int))/SUM(population)) *100 as DeathPercentage
From PortfolioProject.dbo.CovidDeaths$
Where continent is not null
Order by 1,2

--Joining Tables CovidDeaths & CovidVaccinations

Select * from PortfolioProject.dbo.CovidDeaths$ Deaths
Join PortfolioProject.dbo.CovidVaccinations$ Vaccinations
On Deaths.location = Vaccinations.location
And Deaths.date = Vaccinations.date
Order by Deaths.date, Deaths.Location ASC

-- Looking at Total Population vs Deaths vs Vaccinations

Select Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Deaths.new_cases, Deaths.new_deaths, Vaccinations.new_vaccinations
from PortfolioProject.dbo.CovidDeaths$ Deaths
Join PortfolioProject.dbo.CovidVaccinations$ Vaccinations
On Deaths.location = Vaccinations.location
And Deaths.date = Vaccinations.date
Where Deaths.continent is NOT NULL And
Deaths.Location = 'India'
Group by Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Deaths.new_cases, Deaths.new_deaths, Vaccinations.new_vaccinations
Order by 1,2,3

-- Looking at Total Population vs  Vaccinations

Select Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinations.new_vaccinations,
SUM(Cast(Vaccinations.new_vaccinations as bigint)) over (Partition by Deaths.location Order by Deaths.location, Deaths.Date)
from PortfolioProject.dbo.CovidDeaths$ Deaths
Join PortfolioProject.dbo.CovidVaccinations$ Vaccinations
On Deaths.location = Vaccinations.location
And Deaths.date = Vaccinations.date
Where Deaths.continent is NOT NULL
Order by 2,3


---Alternate method
Select Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinations.new_vaccinations,
SUM(CONVERT(BigInt, Vaccinations.new_vaccinations)) over (Partition by Deaths.location Order by Deaths.location, Deaths.Date) as RollingCount_Vaccinations
from PortfolioProject.dbo.CovidDeaths$ Deaths
Join PortfolioProject.dbo.CovidVaccinations$ Vaccinations
On Deaths.location = Vaccinations.location
And Deaths.date = Vaccinations.date
Where Deaths.continent is NOT NULL
Order by 2,3


--- Use CTE .....determine Rolling Count to Population by Percentage

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingCount_Vaccinations) as
(
Select Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinations.new_vaccinations,
SUM(CONVERT(BigInt, Vaccinations.new_vaccinations)) over (Partition by Deaths.location Order by Deaths.location, Deaths.Date) as RollingCount_Vaccinations
from PortfolioProject.dbo.CovidDeaths$ Deaths
Join PortfolioProject.dbo.CovidVaccinations$ Vaccinations
On Deaths.location = Vaccinations.location
And Deaths.date = Vaccinations.date
Where Deaths.continent is NOT NULL
--Order by 2,3
)

Select *, (RollingCount_Vaccinations/Population) * 100 as Percentage from PopvsVac


----TEMP Table----

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar (255),
Location nvarchar (255),
Date Datetime,
Population Numeric,
New_Vaccinations Numeric,
RollingCount_Vaccinations Numeric
)

Insert into #PercentPopulationVaccinated
Select Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinations.new_vaccinations,
SUM(CONVERT(BigInt, Vaccinations.new_vaccinations)) over (Partition by Deaths.location Order by Deaths.location, Deaths.Date) as RollingCount_Vaccinations
from PortfolioProject.dbo.CovidDeaths$ Deaths
Join PortfolioProject.dbo.CovidVaccinations$ Vaccinations
On Deaths.location = Vaccinations.location
And Deaths.date = Vaccinations.date
--Where Deaths.continent is NOT NULL
Order by 2,3

Select *, (RollingCount_Vaccinations/Population) * 100 as Percentage 
from #PercentPopulationVaccinated


--Creating view to store data for later visualizations

Create View PercentPopulationVaccinated as
Select Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinations.new_vaccinations,
SUM(CONVERT(BigInt, Vaccinations.new_vaccinations)) over (Partition by Deaths.location Order by Deaths.location, Deaths.Date) as RollingCount_Vaccinations
from PortfolioProject.dbo.CovidDeaths$ Deaths
Join PortfolioProject.dbo.CovidVaccinations$ Vaccinations
On Deaths.location = Vaccinations.location
And Deaths.date = Vaccinations.date
--Where Deaths.continent is NOT NULL
--Order by 2,3

Select * from PercentPopulationVaccinated