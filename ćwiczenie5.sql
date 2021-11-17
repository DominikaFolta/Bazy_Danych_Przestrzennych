CREATE EXTENSION postgis;

DROP TABLE obiekty;
CREATE TABLE obiekty(nazwa char(20), geometry geometry );

--
INSERT INTO Obiekty VALUES ('obiekt1',ST_GeomFromtext('COMPOUNDCURVE((0 1, 1 1), CIRCULARSTRING(1 1, 2 0, 3 1), CIRCULARSTRING(3 1, 4 2, 5 1), (5 1, 6 1))'));
INSERT INTO obiekty values ('obiekt2', ST_geomfromtext('CURVEPOLYGON(COMPOUNDCURVE((10 2, 10 6, 14 6), CIRCULARSTRING(14 6, 16 4, 14 2), CIRCULARSTRING(14 2, 12 0, 10 2)), CIRCULARSTRING(11 2, 12 3, 13 2, 12 1, 11 2)) ')); 
--INSERT INTO Obiekty VALUES ('obiekt3', ST_GeomFromtexst'GEOMETRYCOLLECTION(LINESTRING(7 15, 10 17), LINESTRING(10 17, 12 13), LINESTRING(12 13, 7 15))'));
INSERT INTO obiekty values ('obiekt3', ST_geomfromtext('CURVEPOLYGON(COMPOUNDCURVE((7 15, 10 17, 12 13, 7 15)))',0));
INSERT INTO obiekty values ('obiekt4', ST_geomfromtext('COMPOUNDCURVE((20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5))',0));
INSERT INTO obiekty values ('obiekt5', ST_geomfromtext('MULTIPOINT(30 30 59, 38 32 234)',0));
INSERT INTO obiekty values ('obiekt6', ST_geomfromtext('GEOMETRYCOLLECTION(POINT(4 2), LINESTRING(1 1, 3 2))',0));

SELECT * FROM obiekty;


-- 1. Wyznacz pole powierzchni bufora o wielkości 5 jednostek, który został utworzony wokół najkrótszej linii łączącej obiekt 3 i 4.
SELECT  ST_area(ST_buffer(ST_Shortestline(a.geometry,b.geometry), 5)) FROM obiekty a, obiekty b WHERE a.nazwa='obiekt3' AND b.nazwa='obiekt4'

-- 2. Zamień obiekt4 na poligon. Jaki warunek musi być spełniony, aby można było wykonać to zadanie? Zapewnij te warunki.
UPDATE obiekty SET geometry = (SELECT ST_MakePolygon(ST_LineMerge(ST_Union((geometry),'LINESTRING(20.5 19.5,20 20)'))) FROM obiekty WHERE nazwa='obiekt4') WHERE nazwa = 'obiekt4';
-- linia musi być zamknięta aby stworzyć z niej poligon

-- 3. W tabeli obiekty, jako obiekt7 zapisz obiekt złożony z obiektu 3 i obiektu 4.
INSERT INTO obiekty (nazwa, geometry) VALUES ('obiekt7', (SELECT ST_Union(a.geometry, b.geometry) FROM obiekty a, obiekty b WHERE a.nazwa='obiekt3' AND b.nazwa='obiekt4'));

-- 4.  Wyznacz pole powierzchni wszystkich buforów o wielkości 5 jednostek, które zostały utworzone wokół obiektów nie zawierających łuków
SELECT sum(ST_Area(ST_buffer((geometry),5))) FROM obiekty WHERE ST_HasArc(geometry) = 'false';





