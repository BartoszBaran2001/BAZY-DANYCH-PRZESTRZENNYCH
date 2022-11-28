--cw1
CREATE TABLE Buildings AS (
SELECT T2019.*
FROM T2019_KAR_BUILDINGS AS T2019, 
     T2018_KAR_BUILDINGS AS T2018
WHERE ST_Equals(T2019.geom, T2018.geom) = FALSE AND T2019.polygon_id = T2018.polygon_id);
SELECT * FROM Buildings;
--cw2
SELECT T2019_KAR_POI_TABLE.type,COUNT(DISTINCT T2019_KAR_POI_TABLE.*) 
FROM Buildings,T2019_KAR_POI_TABLE LEFT JOIN T2018_KAR_POI_TABLE on T2019_KAR_POI_TABLE.geom = T2018_KAR_POI_TABLE.geom
WHERE T2018_KAR_POI_TABLE.geom IS NULL
AND ST_Intersects(ST_Buffer(Buildings.geom::geography,500),T2019_KAR_POI_TABLE.geom::geography)
GROUP BY T2019_KAR_POI_TABLE.type
	 
--cw3
CREATE TABLE streets_reprojected AS (
SELECT gid, link_id, st_name, ref_in_id, nref_in_id, func_class, speed_cat, fr_speed_l, to_speed_l, dir_travel, 
       ST_Transform(geom, 3068) as geom
FROM T2019_KAR_STREETS);
SELECT * FROM streets_reprojected;
DROP TABLE streets_reprojected;

--cw4
CREATE TABLE input_points (id INT PRIMARY KEY,
						   geom GEOMETRY); 
INSERT INTO input_points
VALUES (1, ST_GeomFromText('POINT(8.36093 49.03174)', 4326)),
       (2, ST_GeomFromText('POINT(8.39876 49.00644)', 4326));
SELECT *, ST_AsText(geom) FROM input_points;
DROP TABLE input_points;

-- cw5.
UPDATE input_points
SET geom = ST_Transform(input_points.geom,4326);
SELECT *, ST_AsText(geom) AS geom_point 
FROM input_points;