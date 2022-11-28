CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;
CREATE DATABASE postgis_raster
CREATE SCHEMA Baran;

--raster2pgsql.exe -s 3763 -N -32767 -t 100x100 -I -C -M -d C:\Users\barba\Desktop\studia\5semestr\bazydanychprzestrzennych\cwiczenia\cw6\rasters\srtm_1arc_v3.tif rasters.dem | psql -d postgis_raster -h localhost -U postgres -p 5432
--raster2pgsql.exe -s 3763 -N -32767 -t 128x128 -I -C -M -d C:\Users\barba\Desktop\studia\5semestr\bazydanychprzestrzennych\cwiczenia\cw6\rasters\Landsat8_L1TP_RGBN.tif rasters.landsat8 | psql -d postgis_raster -h localhost -U postgres -p 5432

--przeciecie rastra z wektorem
CREATE TABLE baran.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

--dodanie serial primary key
alter table baran.intersects
add column rid SERIAL PRIMARY KEY;

--utworzenie indeksu przestrzennego 
CREATE INDEX idx_intersects_rast_gist ON baran.intersects
USING gist (ST_ConvexHull(rast));

--dodanie raster constraints
SELECT AddRasterConstraints('baran'::name,
'intersects'::name,'rast'::name);

--ST_Clip obcinanie rastra na podstawie wektora
CREATE TABLE baran.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

--ST_Union - polaczenie wielu kafelkow w jeden raster 
CREATE TABLE baran.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);

--ST_AsRaster
CREATE TABLE baran.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--ST_Union
DROP TABLE baran.porto_parishes; --> drop table porto_parishes first
CREATE TABLE baran.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--ST_Tile
DROP TABLE baran.porto_parishes; --> drop table porto_parishes first
CREATE TABLE baran.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--ST_Intersection
create table baran.intersection as
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)
).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--ST_DumpAsPolygons
CREATE TABLE baran.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--ST_Band
CREATE TABLE baran.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

--ST_Clip
CREATE TABLE baran.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--ST_Slope
CREATE TABLE baran.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM baran.paranhos_dem AS a;

--ST_Reclass
CREATE TABLE baran.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3',
'32BF',0)
FROM baran.paranhos_slope AS a;

--ST_SummaryStats
SELECT st_summarystats(a.rast) AS stats
FROM baran.paranhos_dem AS a;

--ST_SummaryStats oraz Union
SELECT st_summarystats(ST_Union(a.rast))
FROM baran.paranhos_dem AS a;

--ST_SummaryStats z lepsza kontrola zlozonego typu danych
WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM baran.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

--ST_SummaryStats w połączeniu z GROUP BY
WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,
b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;

--ST_Value
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;

--ST_TPI
create table baran.tpi30 as
select ST_TPI(a.rast,1) as rast
from rasters.dem a;

-- indeks przestrzenny 
CREATE INDEX idx_tpi30_rast_gist ON baran.tpi30
USING gist (ST_ConvexHull(rast));

--dodanie constraintow
SELECT AddRasterConstraints('baran'::name,
'tpi30'::name,'rast'::name);

--do samodzielnego wykonania
CREATE TABLE baran.tpi30porto AS
SELECT ST_TPI(a.rast,1) AS rast FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ILIKE 'porto'

--wyrazenie algebry map 
CREATE TABLE baran.porto_ndvi AS
WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
	r.rid,ST_MapAlgebra(
		r.rast, 1,
		r.rast, 4,
			'([rast2.val] - [rast1.val]) / ([rast2.val] +
[rast1.val])::float','32BF'
	) AS rast
FROM r;

--utworzenie indeksu przestrzennego na wczesniej stworzonej tabeli 
CREATE INDEX idx_porto_ndvi_rast_gist ON baran.porto_ndvi
USING gist (ST_ConvexHull(rast));

--dodanie constraintow
SELECT AddRasterConstraints('baran'::name,
'porto_ndvi'::name,'rast'::name);

--funkcja zwrotna/ utworzenie funkcji, ktora bedzie wywolywana pozniej 
create or replace function baran.ndvi(
	value double precision [] [] [],
	pos integer [][],
	VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
	--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
	RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value
[1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

--wywolanie wczesniej zdefiniowanej funkcji w kwerendzie algebry map 
CREATE TABLE baran.porto_ndvi2 AS
WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
	r.rid,ST_MapAlgebra(
		r.rast, ARRAY[1,4],
		'baran.ndvi(double precision[],
integer[],text[])'::regprocedure, --> This is the function!
			'32BF'::text
) 	AS rast
FROM r;

--dodanie indeksu przestrzennego
CREATE INDEX idx_porto_ndvi2_rast_gist ON baran.porto_ndvi2
USING gist (ST_ConvexHull(rast));

--dodanie constraintow
SELECT AddRasterConstraints('baran'::name,
'porto_ndvi2'::name,'rast'::name);

--ST_AsTiff
SELECT ST_AsTiff(ST_Union(rast))
FROM baran.porto_ndvi;

--St_AsGDALRaster
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
FROM baran.porto_ndvi;

--wyswietlanie listy formatow obslugiwanych przez biblioteke
SELECT ST_GDALDrivers();

--zapisywanie danych na dysku za pomoca duzego obiektu
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM baran.porto_ndvi;
----------------------------------------------
SELECT lo_export(loid, 'C:\Users\barba\Desktop\studia\5semestr\bazydanychprzestrzennych\cwiczenia\cw6\rasters\myraster.tiff') --> Save the file in a place where the user postgres have access. In windows a flash drive usualy works fine.
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.


------------------------------------------------------
create table baran.tpi30_porto as
SELECT ST_TPI(a.rast,1) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto'

--dodanie indeksu przestrzennego
CREATE INDEX idx_tpi30_porto_rast_gist ON baran.tpi30_porto
USING gist (ST_ConvexHull(rast));

--dodanie constraintow
SELECT AddRasterConstraints('baran'::name,
'tpi30_porto'::name,'rast'::name);
