/****** Script for SelectTopNRows command from SSMS  ******/
SELECT	Game_title
		,(Case 
		When steam_id_number = 3030 Then SUBSTRING(Game_title, 25, -2)
		Else game_title
		End)
  FROM [Test].[dbo].[rpg_steam_clean]
  Where steam_id_number =  3030

-------

Select *
From Test.dbo.rpg_steam_clean
Where Game_Title is null or developer is null or publisher is null