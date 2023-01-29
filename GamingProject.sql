USE GamingProject;
GO
/*
ViewMart-Gaming project
	Create schema stg
	GO
	Create schema vw
	GO
	Create schema dim
	GO
*/

/*
	1)Idenitfy the business process of the data recorded
	2)Identify the gain
	4)Facts
	5)Dimensions

https://www.kaggle.com/datasets/ericngui/rpg-steam-clean

Select *
From Test.dbo.rpg_steam_clean

Obersvation on Estimated Owner number
https://steamspy.com/genre/RPG

*/
							/******* Begin ******/

-- Import staging tables needed to create fact table
/*
		 - Cheat alittle on the way in HANDLING NULLS - 12 rows

Select *
From Test.dbo.rpg_steam_clean
Where Game_Title is null or developer is null or publisher is null

https://steamdb.info/graph/

Select *
From stg.RpgSteam
Where game_title is null or developer is null or publisher is null

		
*/


DROP TABLE if exists stg.RpgSteam

SELECT [steam_id_number] as 'GameID'
      ,(Case
			When [steam_id_number]= 6624 Then 'Unknown'
			When [steam_id_number]= 8892 Then 'Arcane Raise'
			When [steam_id_number]= 7345 Then 'LABrpgUP'
			When [steam_id_number]= 725  Then 'We Are The Dwarves'
			When [steam_id_number]= 1518 Then 'Chinese PaladinSword and Fairy 4'
			When [steam_id_number]= 1852 Then 'Chinese PaladinSword and Fairy 4'
			When [steam_id_number]= 9419 Then 'Azur Ring virgin and slave phylacteries'
			When [steam_id_number]= 9827 Then 'Be a maid in the Demon World-The Secret Café of the Demon Angel Hero'
			When [steam_id_number]= 7785 Then 'LIVE IN DUNGEON'
			When [steam_id_number]= 3792 Then 'Fallalypse Disconnect'
			When [steam_id_number]= 6740 Then 'Fallalypse'
			When [steam_id_number]= 6129 Then 'Fallalypse Death or Cress'
			When [steam_id_number]= 6396 Then 'Hexaluga Weapon and Shield'
			When [steam_id_number]= 5327 Then 'Hexaluga Dungeons and Hunting'
			When [steam_id_number]= 5330 Then 'Hexaluga Witch Hunters Travelling Castle'
			When [steam_id_number]= 6126 Then 'Heroes of Hexaluga'
			When [steam_id_number]= 7226 Then 'Johnny Rocket'
			When [steam_id_number]= 4585 Then 'Curse of disaster spirit : Anecdotes of mansion'
			When [steam_id_number]= 9962 Then 'Necromancy Emily Escape'
			When steam_id_number =  1557 Then SUBSTRING(Game_title, 2, 12 -2)
			When steam_id_number =  4585 Then SUBSTRING(Game_title, 2, 49-2)
			When steam_id_number =  6713 Then SUBSTRING(Game_title, 2, 35-2)
			When steam_id_number = 3202 Then SUBSTRING(Game_title, 15, 26-2)
			When steam_id_number = 7557 Then SUBSTRING(Game_title, 2, 17-2)
			When steam_id_number = 8930 Then SUBSTRING(Game_title, 2, 17-2)
			When steam_id_number = 3029 Then SUBSTRING(Game_title, 8, 16-2)
			When steam_id_number = 3030 Then SUBSTRING(Game_title, 8, 35-2)
		Else game_title
		End) as 'game_title'
      ,[release_month]
      ,(case
			When [steam_id_number]= 197 Then 2019
		Else [release_year]
	    End) as 'release_year'
	  ,Cast((CONCAT_WS (' ', release_month, Release_year )) as date) as 'ReleaseDate'
	  ,(case
			When [steam_id_number]= 811   Then 'POLYGON GAMES'
			When [steam_id_number]= 1780  Then 'UPLAY Online'
			When [steam_id_number]= 2310  Then 'RLR Training Inc'
			When [steam_id_number]= 2332  Then 'RLR Training Inc, Fair Play Labs'
			When [steam_id_number]= 2904  Then 'Yintento'
			When [steam_id_number]= 2263  Then 'Fantasy Flight Games'
			When [steam_id_number]= 10258 Then 'OpenRealms'
			When [steam_id_number]= 5476  Then 'Sylvestre Studio'
			When [steam_id_number]= 10198 Then 'Senpai Studios'
			When [steam_id_number]= 697   Then 'Rebelmind'
			When [steam_id_number]= 3557  Then 'Unknown'
			When [steam_id_number]= 6624  Then 'Unknown'
			Else developer
	    End) as 'Developer'
      ,(case
			When [steam_id_number]= 811   Then 'Move Games. Co., LTD'
			When [steam_id_number]= 1780  Then 'Raiser Games'
			When [steam_id_number]= 2310  Then 'RLR Training Inc/Red Dahlia Interactive'
			When [steam_id_number]= 2332  Then 'RLR Training Inc, PUA Training Limited'
			When [steam_id_number]= 2904  Then 'LHD000'
			When [steam_id_number]= 6624  Then 'Unknown'
			When [steam_id_number]= 10258 Then 'OpenRealms'
			When [steam_id_number]= 5476  Then 'Renan Sylvestre Games'
			When [steam_id_number]= 3557  Then 'Unknown'
			Else publisher
	    End) as 'Publisher'
	  ,average_estimated_owners_number as 'EstimatedOwners'
	  ,[release_price]
Into stg.RpgSteam
FROM test.[dbo].[rpg_steam_clean]

--Select * From stg.RpgSteam
Go

--Create Surrogate keys for Fields without Keys placing them in their own staging tables to be reference later

Drop table if exists stg.Developer
;

With developerCte
as
(
Select Distinct Developer as 'Developer'
From stg.RpgSteam
)
Select Row_number () Over(Order by Developer) + 1000 as 'kDeveloperID'
	  ,Developer
Into stg.Developer
From developerCte

--7722

GO

Drop Table if exists stg.Publisher
;
With PublisherCte
as
(
Select Distinct Publisher as 'Publisher'
From stg.RpgSteam
)
Select Row_number () Over(Order by Publisher) + 10000 as 'kPublisherID'
	  ,Publisher
Into stg.Publisher
From PublisherCte

--6847

GO


------- Fact Table View -------

Create or Alter view vw.fRpgGames
as
Select rs.GameID
	  ,Cast(Replace(Convert(varchar(10), ReleaseDate), '-','') as INT) as 'DateKey'
	  ,dev.kDeveloperID
	  ,pub.kPublisherID 
	  ,rs.EstimatedOwners
	  ,Round(release_price, 2) as 'release_price'
	  ,Round((rs.release_price*rs.EstimatedOwners), 2) as 'LineTotal'
FROM stg.RpgSteam rs
	Inner join stg.Publisher pub
		on rs.Publisher = pub.Publisher
	Inner join stg.Developer dev
		on rs.Developer = dev.Developer

GO

-------Create Dimensions Views -----

Create or Alter View Vw.dDeveloper
as
Select *
From stg.Developer

GO

Create or Alter View Vw.dPublisher
as
Select *
From stg.Publisher

GO

Create or Alter view Vw.dGames
as
SELECT GameID
      ,Game_Title
FROM [stg].[RpgSteam]

GO

Create or alter view vw.dEstimatedOwners
as
SELECT EstimatedOwners
	  ,Dense_Rank() over(Order by EstimatedOwners desc) as 'RankingByEstimatedOwners'
      ,Count(*) as 'CountofGamePerRanking'
FROM vw.fRpgGames
Group by EstimatedOwners

Go


------- Create Calander Dimension -------

Drop table if exists dim.Calendar;

DECLARE @StartDate  date;
Set @StartDate = '19830101';

DECLARE @CutoffDate date; 
Set @CutoffDate = DATEADD(DAY, -1, DATEADD(YEAR, 41, @StartDate));

--Change nothing below this line --
;WITH seq(n) AS 
(
  SELECT 0 UNION ALL SELECT n + 1 FROM seq
  WHERE n < DATEDIFF(DAY, @StartDate, @CutoffDate)
),
d(d) AS 
(
  SELECT DATEADD(DAY, n, @StartDate) FROM seq
),
src AS
(
  SELECT
  	bkDateKey	 = CAST(REPLACE(CONVERT(varchar(10), d),'-','') as INT),
    Date         = CONVERT(date, d),
    DayofMonth   = DATEPART(DAY,       d),
    DayName      = DATENAME(WEEKDAY,   d),
    WeekOfYear   = DATEPART(WEEK,      d),
    ISOWeek      = DATEPART(ISO_WEEK,  d),
    DayOfWeek    = DATEPART(WEEKDAY,   d),
    Month        = DATEPART(MONTH,     d),
    MonthName    = DATENAME(MONTH,     d),
	MonthAbbrev  = LEFT(DATENAME(MONTH, d),3),
    Quarter      = DATEPART(Quarter,   d),
	Qtr          =(Case
						When DATEPART(QUARTER,    d) = 1 THEN 'Q1'
						When DATEPART(QUARTER,    d) = 2 THEN 'Q2'
						When DATEPART(QUARTER,    d) = 3 THEN 'Q3'
						When DATEPART(QUARTER,    d) = 4 THEN 'Q4'
					  ELSE 'Err'
				    End),

    Year         = DATEPART(YEAR,      d),
    FirstOfMonth = DATEFROMPARTS(YEAR(d), MONTH(d), 1),
    LastOfYear   = DATEFROMPARTS(YEAR(d), 12, 31),
    DayOfYear    = DATEPART(DAYOFYEAR, d)
  FROM d
)
SELECT * 
INTO dim.Calendar
FROM src
  ORDER BY Date
  OPTION (MAXRECURSION 0);
GO

--- Create Calendar View

Create or Alter View Vw.dCalendar 
as
SELECT  bkDateKey
	   ,[Month]
       ,[MonthName]
	   ,Qtr
	   ,[Year]
FROM dim.Calendar

GO 
