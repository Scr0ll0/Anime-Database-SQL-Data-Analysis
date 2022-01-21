SELECT * 
FROM mal.anime
ORDER BY 1;

-- Members vs. Watching
SELECT DISTINCT(MAL_ID), Name, Members, Watching, (Watching/Members * 100) AS WatchingPercentage
FROM mal.members
WHERE Members > 10000
ORDER BY WatchingPercentage DESC;

-- Members vs. Completed
SELECT DISTINCT(MAL_ID), Name, Members, Completed, (Completed/Members * 100) AS CompletedPercentage
FROM mal.members
WHERE Type = 'TV'
ORDER BY CompletedPercentage DESC;

-- Members vs. On Hold
SELECT DISTINCT(MAL_ID), Name, Members, OnHold, (OnHold/Members * 100) AS OnHoldPercentage
FROM mal.members
WHERE Type = 'TV'
ORDER BY OnHoldPercentage DESC;

-- Members vs. Dropped
SELECT DISTINCT(MAL_ID), Name, Members, Dropped, (Dropped/Members * 100) AS DroppedPercentage
FROM mal.members
WHERE Type = 'TV'
ORDER BY DroppedPercentage DESC;

-- Members vs. Plan To Watch
SELECT DISTINCT(MAL_ID), Name, Members, Plan_to_Watch AS PlanToWatch, (Plan_to_Watch/Members * 100) AS PlanToWatchPercentage
FROM mal.members
WHERE Type = 'TV'
ORDER BY PlanToWatchPercentage DESC;

-- Average Genre Completed/Drop Rates, With and Without Weighting by Members
SELECT anime.Genres, COUNT(DISTINCT anime.MAL_ID) AS Num_Genre, SUM(DISTINCT members.Completed/members.Members)/COUNT(DISTINCT members.MAL_ID) * 100 AS Average_Completed, SUM(DISTINCT members.Completed)/SUM(DISTINCT members.Members) * 100 AS Weighted_Average_Completed, SUM(DISTINCT members.Dropped/members.Members)/COUNT(DISTINCT members.MAL_ID) * 100 AS Average_Drop, SUM(DISTINCT members.Dropped)/SUM(DISTINCT members.Members) * 100 AS Weighted_Average_Drop
FROM mal.anime AS anime
JOIN mal.members AS members
	ON anime.MAL_ID = members.MAL_ID
WHERE Genres NOT LIKE "N/A"
GROUP BY Genres
ORDER BY Weighted_Average_Completed DESC;

-- Average Score by Genres
SELECT Genres, COUNT(DISTINCT MAL_ID) AS Num_Genre, AVG(DISTINCT Score) AS Average_Score
FROM mal.anime
WHERE Genres NOT LIKE "N/A"
AND Score NOT LIKE 0
GROUP BY Genres
ORDER BY Average_Score DESC;

-- Average Score by Studios
SELECT Studios, COUNT(DISTINCT MAL_ID) AS Num_Series_Produced, AVG(DISTINCT Score) AS Average_Score
FROM mal.anime
WHERE Studios NOT LIKE "Unknown"
AND Score NOT LIKE 0
GROUP BY Studios
HAVING Num_Series_Produced > 10
ORDER BY Average_Score DESC;

-- Average Score and Total Anime by Season
SELECT Season, COUNT(DISTINCT MAL_ID) AS Num_Anime, SUM(COUNT(DISTINCT MAL_ID)) OVER (ORDER BY RIGHT(Season, 4), Month) AS Total_Anime, AVG(DISTINCT Score) AS Average_Score
FROM mal.anime
WHERE Season NOT LIKE "Unknown"
AND Score NOT LIKE 0
-- AND Type LIKE "TV"
-- AND Season LIKE "%20%"
GROUP BY Season
ORDER BY RIGHT(Season, 4), Month;
-- ORDER BY Average_Score DESC;

-- Average Score and Total Anime by Year
SELECT RIGHT(Season, 4) AS Year, COUNT(DISTINCT MAL_ID) AS Num_Anime, SUM(COUNT(DISTINCT MAL_ID)) OVER (ORDER BY RIGHT(Season, 4)) AS Total_Anime, AVG(DISTINCT Score) AS Average_Score
FROM mal.anime
WHERE Season NOT LIKE "Unknown"
AND Score NOT LIKE 0
-- AND Type LIKE "TV"
-- AND Season LIKE "%20%"
GROUP BY Year
ORDER BY Year;
-- ORDER BY Average_Score DESC;

-- Total Runtime By Season
WITH Rolling AS (
	WITH Singular AS (
		SELECT DISTINCT(MAL_ID), Name, Season, TotalDuration, Month
		FROM mal.anime
)
	SELECT DISTINCT(MAL_ID), Name, Season, TotalDuration, SUM(TotalDuration) OVER (PARTITION BY Season ORDER BY MAL_ID, RIGHT(Season, 4), Month) AS RollingDuration
	FROM Singular
	WHERE TotalDuration NOT LIKE 0
	ORDER BY RIGHT(Season, 4), Month
)
SELECT Season, COUNT(DISTINCT MAL_ID) AS NumAnime, MAX(RollingDuration) AS SeasonDuration
FROM Rolling
WHERE Season NOT LIKE "Unknown"
GROUP BY Season
ORDER BY SeasonDuration DESC;

-- Create View For Season Runtime
CREATE VIEW SeasonRuntime AS (
WITH Singular AS (
		SELECT DISTINCT(MAL_ID), Name, Season, TotalDuration, Month
		FROM mal.anime
)
	SELECT DISTINCT(MAL_ID), Name, Season, TotalDuration, SUM(TotalDuration) OVER (PARTITION BY Season ORDER BY MAL_ID, RIGHT(Season, 4), Month) AS RollingDuration
	FROM Singular
	WHERE TotalDuration NOT LIKE 0
	ORDER BY RIGHT(Season, 4), Month
);

-- Total Runtime By Year
DROP TABLE IF EXISTS Rolling;
CREATE TABLE Rolling
(
MAL_ID DOUBLE,
Name VARCHAR(100),
Season VARCHAR(100),
Year VARCHAR(100),
TotalDuration DOUBLE,
RollingDuration DOUBLE
);
INSERT INTO Rolling
WITH Singular AS (
	SELECT DISTINCT(MAL_ID), Name, Season, RIGHT(Season, 4) AS Year, TotalDuration, Month
	FROM mal.anime
)
SELECT DISTINCT(MAL_ID), Name, Season, Year, TotalDuration, SUM(TotalDuration) OVER (PARTITION BY Year ORDER BY MAL_ID, Year) AS RollingDuration
FROM Singular;

SELECT Year, MAX(RollingDuration) AS YearlyDuration
FROM Rolling
WHERE Season NOT LIKE "Unknown"
GROUP BY Year
ORDER BY YearlyDuration DESC;

-- Create View for Year Runtime
CREATE VIEW YearRuntime AS (
WITH Singular AS (
		SELECT DISTINCT(MAL_ID), Name, Season, RIGHT(Season, 4) AS Year, TotalDuration, Month
		FROM mal.anime
)
	SELECT DISTINCT(MAL_ID), Name, Season, Year, TotalDuration, SUM(TotalDuration) OVER (PARTITION BY Year ORDER BY MAL_ID, Year) AS RollingDuration
	FROM Singular
	WHERE TotalDuration NOT LIKE 0
	ORDER BY Year
);

