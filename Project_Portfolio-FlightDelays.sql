/*
2019-2021 US Flight Delays
Focused on cleaning the data prior to exploring more

*/
SELECT *
	FROM flight_info
-- NOTE: ct columns is the number & columns w/o ct are in minutes outside of cancelled and diverted

--Remove the Null rows as they did not have any info for any of the columns
DELETE FROM flight_info
	WHERE arr_flights IS NULL

--Divide up airport_name between City, State/Territory, Airport Full Name
SELECT
	SUBSTRING(airport_name,1,CHARINDEX(',',airport_name)-1) AS City,
	SUBSTRING(airport_name,CHARINDEX(',',airport_name) +2, 2) AS State,
	SUBSTRING(airport_name,CHARINDEX(':',airport_name) +2, LEN(airport_name)) AS 'Airport Name'
	FROM flight_info 

ALTER TABLE flight_info
	ADD airport_city NVARCHAR(255),
	airport_state_territory NVARCHAR(255),
	airport_name_revised NVARCHAR(255)

UPDATE flight_info
	SET airport_city = SUBSTRING(airport_name,1,CHARINDEX(',',airport_name)-1),
	airport_state_territory = SUBSTRING(airport_name,CHARINDEX(',',airport_name) +2, 2),
	airport_name_revised = SUBSTRING(airport_name,CHARINDEX(':',airport_name) +2, LEN(airport_name))

SELECT airport, airport_city, airport_state_territory, airport_name_revised
	FROM flight_info

--Rounding all values to whole number and add column to find the total on time arrival flights
UPDATE flight_info
	SET arr_flights = ROUND(arr_flights,0), 
	arr_cancelled = ROUND(arr_cancelled,0), 
	arr_diverted = ROUND(arr_diverted,0), 
	carrier_ct = ROUND(carrier_ct,0), 
	weather_ct = ROUND(weather_ct,0), 
	nas_ct = ROUND(nas_ct,0), 
	security_ct = ROUND(security_ct,0), 
	late_aircraft_ct = ROUND(late_aircraft_ct,0)

--Create OnTime Arrival Column
ALTER TABLE flight_info
	ADD ontime_flights INT

UPDATE flight_info
	SET ontime_flights = 
	(arr_flights - arr_cancelled - arr_diverted - carrier_ct - weather_ct - nas_ct - security_ct - late_aircraft_ct)

--Minutes Delayed - Turn columns that were in minutes into separate TEMP table for faster computing
SELECT year, month, carrier, airport, arr_del15, carrier_delay, weather_delay, nas_delay, 
	security_delay, late_aircraft_delay
	FROM flight_info

DROP TABLE IF EXISTS #MinutesDelayed
CREATE TABLE #MinutesDelayed
	(year NUMERIC,
	month NUMERIC,
	carrier NVARCHAR(255),
	airport NVARCHAR(255),
	arr_del15 NUMERIC,
	carrier_delay NUMERIC,
	weather_delay NUMERIC,
	nas_delay NUMERIC,
	security_delay NUMERIC,
	late_aircraft_delay NUMERIC)

INSERT INTO #MinutesDelayed
SELECT year, month, carrier, airport, arr_del15, carrier_delay, weather_delay, nas_delay, 
	security_delay, late_aircraft_delay
	FROM flight_info

SELECT * FROM #MinutesDelayed

--Number of Cases per Situation - Turn columns that were counts into separate TEMP table for faster computing
SELECT year, month, carrier, airport, ontime_flights, arr_flights , arr_cancelled, 
	arr_diverted, carrier_ct, weather_ct, nas_ct, security_ct, late_aircraft_ct
	FROM flight_info

DROP TABLE IF EXISTS #DelayScenarios
CREATE TABLE #DelayScenarios
	(year NUMERIC,
	month NUMERIC,
	carrier NVARCHAR(255),
	airport NVARCHAR(255),
	ontime_flights NUMERIC,
	arr_flights NUMERIC,
	arr_cancelled NUMERIC,
	arr_diverted NUMERIC,
	carrier_ct NUMERIC,
	weather_ct NUMERIC,
	nas_ct NUMERIC,
	security_ct NUMERIC,
	late_aircraft_ct NUMERIC
	)

INSERT INTO #DelayScenarios
SELECT year, month, carrier, airport, ontime_flights, arr_flights , arr_cancelled, 
	arr_diverted, carrier_ct, weather_ct, nas_ct, security_ct, late_aircraft_ct
	FROM flight_info

SELECT * FROM #DelayScenarios

--Created View for practice - will revise for better visualization
CREATE VIEW DelayScenarios AS
	SELECT year, month, carrier, airport, ontime_flights, arr_flights , arr_cancelled, 
	arr_diverted, carrier_ct, weather_ct, nas_ct, security_ct, late_aircraft_ct
	FROM flight_info

SELECT * FROM DelayScenarios

--Airports 
-- NOTE 376 airports it seems
SELECT DISTINCT airport_name, COUNT(airport_name) AS airport_count
	FROM flight_info
	GROUP BY airport_name
	ORDER BY airport_count DESC

SELECT DISTINCT carrier, carrier_name
	FROM flight_info

SELECT carrier, COUNT(carrier) AS carrier_count
	FROM flight_info
	GROUP BY carrier
	ORDER BY carrier_count DESC

--TOP 10 State/Territory with most Airports
SELECT TOP 10 airport_state_territory, COUNT(airport_state_territory)
	FROM flight_info
	GROUP BY airport_state_territory
	ORDER BY COUNT(airport_state_territory) DESC

SELECT airport, COUNT(airport)
	FROM flight_info
	GROUP BY airport
	ORDER BY COUNT(airport) DESC

SELECT ontime_flights FROM flight_info
	ORDER BY ontime_flights 

