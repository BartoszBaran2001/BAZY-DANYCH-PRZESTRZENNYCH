 CREATE EXTENSION POSTGIS
 --zad4
 CREATE TABLE tableB AS
 SELECT DISTINCT popp.geom FROM popp, majrivers
 WHERE ST_DWITHIN(popp.geom, majrivers.geom, 3280) AND f_codedesc = 'Building';
 
 SELECT COUNT(*) FROM tableB
 
 --zad5
CREATE TABLE airportsNew AS 
SELECT name, geom, elev FROM airports;
--a
SELECT name, ST_X(geom) as coor FROM airportsNew
ORDER BY coor DESC LIMIT 1;--EAST
SELECT name, ST_X(geom) as coor FROM airportsNew 
ORDER BY coor LIMIT 1;--WEST
--b
INSERT INTO airportsNew VALUES (
    'airportB',
    (SELECT ST_CENTROID(
    ST_MAKELINE (
        (SELECT geom FROM airportsNew WHERE name = 'ANNETTE ISLAND'),
        (SELECT geom FROM airportsNew WHERE name = 'ATKA')
    ))));
	
SELECT * FROM airportsNew WHERE name = 'airportB'

--zad6
Select ST_AREA(ST_BUFFER(ST_SHORTESTLINE(airports.geom, lakes.geom), 1000))
FROM airports, lakes
WHERE lakes.names='Iliamna Lake' AND airports.name='AMBLER';

--zad7
SELECT vegdesc, SUM(ST_AREA(trees.geom))
FROM trees, swamp, tundra
WHERE ST_CONTAINS(tundra.geom, trees.geom) OR ST_CONTAINS(swamp.geom, trees.geom)
GROUP BY vegdesc;