CREATE SCHEMA mapa;

CREATE TABLE mapa.budynki(id integer PRIMARY KEY NOT null, geometria geometry, nazwa varchar(15));
CREATE TABLE mapa.drogi(id integer PRIMARY KEY NOT null, geometria geometry, nazwa varchar(15));
CREATE TABLE mapa.pktinfo(id integer PRIMARY KEY NOT null, geometria geometry, nazwa varchar(15));

INSERT INTO mapa.budynki VALUES
    (1, ST_GeomFromText('polygon( (9 9, 10 9, 10 8, 9 8, 9 9) )'), 'BuildingD'),
    (2, ST_GeomFromText('polygon( (8 4, 10.5 4, 10.5 1.5, 8 1.5, 8 4) )'), 'BuildingA'),
    (3, ST_GeomFromText('polygon( (1 2, 2 2, 2 1, 1 1, 1 2) )'), 'BuildingF' ),
    (4, ST_GeomFromText('polygon( (3 8, 5 8, 5 6, 3 6, 3 8) )'), 'BuildingC'),
    (5, ST_GeomFromText('polygon( (4 7, 6 7, 6 5, 4 5, 4 7) )'), 'BuildingB');

INSERT INTO mapa.pktinfo VALUES
    (1, ST_GeomFromText('point( 6 9.5 )'), 'K'),
    (2, ST_GeomFromText('point( 6.5 6 )'), 'J'),
    (3, ST_GeomFromText('point( 9.5 6 )'), 'I'),
    (4, ST_GeomFromText('point( 5.5 1.5 )'), 'H'),
    (5, ST_GeomFromText('point( 1 3.5 )'), 'G');

INSERT INTO mapa.drogi VALUES
    (1, ST_GeomFromText('LINESTRING(7.5 10.5, 7.5 0)'), 'RoadY'),
    (2, ST_GeomFromText('LINESTRING(0 4.5, 12 4.5)'), 'RoadX');
------------------------------------------------------------------------------------------------------------------------cw1
SELECT SUM(ST_Length(geometria)) FROM mapa.drogi
-------------------------------------------------------cw2
SELECT ST_AsEWKT(geometria) AS geometria, ST_Area(geometria) AS pole_powierzchni, ST_Perimeter(geometria) AS obwod 
FROM mapa.budynki WHERE nazwa = 'BuildingA'
-------------------------------------------------------------cw3
SELECT nazwa, ST_Area(geometria) AS pole_powierzchni FROM mapa.budynki ORDER BY nazwa;
----------------------------------------------------------------------------------------cw4
SELECT nazwa, ST_Perimeter(geometria) AS obwod FROM mapa.budynki ORDER BY obwod DESC LIMIT 2;
--------------------------------------------------------------------------------------------------cw6 
SELECT ST_Area(
		ST_Difference((SELECT geometria FROM mapa.budynki WHERE nazwa = 'BuildingC'), ST_Buffer(geometria, 0.5))
		)
FROM mapa.budynki WHERE nazwa = 'BuildingB'
---------------------------------------------cw7
SELECT budynki.nazwa
FROM mapa.budynki, mapa.drogi
WHERE drogi.nazwa = 'RoadX' AND ST_Y(ST_Centroid(budynki.geometria)) > ST_Y(ST_Centroid(drogi.geometria));
-------------------------------------------------------------------------------------------------------------cw8
SELECT ST_Area(
				ST_SymDifference(
				ST_GeomFromText('polygon((4 7, 6 7, 6 8, 4 8, 4 7))'), geometria)
				) 
				AS pole
FROM mapa.budynki WHERE nazwa = 'BuildingC';