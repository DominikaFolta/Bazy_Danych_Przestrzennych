CREATE DATABASE Cwiczenie2;
CREATE EXTENSION postgis;

--2.Utwórz trzy tabele: buildings (id, geometry, name), roads (id, geometry, name), poi (id, geometry, name).
CREATE TABLE buildings (id INT PRIMARY KEY NOT NULL, geometry geometry,  name VARCHAR(20));
CREATE TABLE roads (id INT PRIMARY KEY NOT NULL, geometry geometry,  name VARCHAR(20));
CREATE TABLE poi (id INT PRIMARY KEY NOT NULL, geometry geometry,  name VARCHAR(20));

INSERT INTO buildings VALUES
(1, 'POLYGON((8 4, 10.5 4, 10.5 1.5, 2.5 1.5, 8 4))','BuildingA'),
(2, 'POLYGON((6 5, 6 7, 4 7, 4 5, 6 5))','BuildingB'),
(3, 'POLYGON((5 6, 5 8, 3 8, 3 6, 5 6))','BuildingC'),
(4, 'POLYGON((9 9, 10 9, 10 8, 9 8, 9 9))','BuildingD'),
(5,'POLYGON((2 2, 2 1, 1 1, 1 2, 2 2))','BuildingF');
SELECT * FROM buildings;


INSERT INTO roads VALUES
(6, 'LINESTRING(7.5 0, 7.5 10.5)','RoadY'),
(7, 'LINESTRING(0 4.5, 12 4.5)','RoadX');
SELECT * FROM roads;

INSERT INTO poi VALUES
(8, 'POINT(1 3.5)','G'),
(9, 'POINT(5.5 1.5)','H'),
(10, 'POINT(9.5 6)','I'), 
(11, 'POINT(6.5 6)','J'),
(12, 'POINT(6 9.6)','K');
SELECT * FROM poi;

--6
--a. Całkowita długość dróg w analizowanym mieście.

SELECT SUM(ST_Length(geometry)) AS całkowita_dlugosc FROM roads;

--b. Geometria (WKT), pole powierzchni oraz obwód poligonu reprezentującego budynek o nazwie BuildingA.

SELECT name, ST_AsText(geometry), ST_Area(geometry), ST_Perimeter(geometry) FROM buildings WHERE name = 'BuildingA';

--c. Nazwy i pola powierzchni wszystkich poligonów w warstwie budynki. Wyniki posortuj alfabetycznie.

SELECT name, ST_Area(geometry) FROM buildings ORDER BY name;

--d. Nazwy i obwody 2 budynków o największej powierzchni.

SELECT name, ST_Perimeter(geometry) FROM buildings ORDER BY ST_Area(geometry) DESC LIMIT 2;

--e. Najkrótsza odległość między budynkiem BuildingC a punktem G.

SELECT ST_Distance(buildings.geometry, poi.geometry) AS min_dystans
FROM buildings, poi
WHERE buildings.name='BuildingC' AND poi.name='G';

--f. Pole powierzchni tej części budynku BuildingC, która znajduje się w odległości większej niż 0.5 od budynku BuildingB.

SELECT ST_Area(ST_Difference(c.geometry, ST_Buffer(b.geometry, 0.5) )) FROM buildings b, buildings c
WHERE c.name = 'BuildingC' AND b.name = 'BuildingB';

--g. Budynki, których centroid (ST_Centroid) znajduje się powyżej drogi o nazwie RoadX. 

SELECT buildings.name 
FROM buildings
WHERE ST_Y(ST_Centroid(buildings.geometry)) > ST_Y(ST_PointN((SELECT geometry FROM roads WHERE name = 'RoadX'), 1));

--8. Oblicz pole powierzchni tych części budynku BuildingC i poligonu o współrzędnych (4 7, 6 7, 6 8, 4 8, 4 7), które nie są wspólne dla tych dwóch obiektów.

SELECT ST_Area(ST_SymDifference(buildings.geometry, 'POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))', 0))
FROM buildings
WHERE buildings.name = 'BuildingC';


