/****** Script for SelectTopNRows command from SSMS  ******/
SELECT  [steam_id_number]
      ,[game_title]
      ,[release_month]
      ,[release_year]
      ,[release_price]
      ,[lowest_estimated_owners_number]
      ,[highest_estimated_owners_number]
      ,[average_estimated_owners_number]
      ,[developer]
      ,[publisher]
  FROM [Test].[dbo].[rpg_steam_clean]
    ORder by 2