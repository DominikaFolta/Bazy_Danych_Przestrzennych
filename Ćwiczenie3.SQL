CREATE DATABASE Cwiczenie3;
CREATE EXTENSION postgis;


-- Wyznacz liczbę budynków położonych w odległości mniejszej niż 1000 m od głównych rzek. Budynki spełniające to kryterium zapisz do osobnej tabeli tableB.

SELECT popp.gid, popp.cat, popp.f_codedesc, popp.f_code, popp.type, popp.geom INTO tableB
FROM popp, majrivers
WHERE ST_Distance(popp.geom, majrivers.geom) < 1000 AND popp.f_codedesc = 'Building';
SELECT * FROM tableB;

--5. Utwórz tabelę o nazwie airportsNew. Z tabeli airports do zaimportuj nazwy lotnisk, ich geometrię, a także atrybut elev, reprezentujący wysokość n.p.m.

SELECT name, elev, geom INTO airportsNew
FROM airports;
SELECT * FROM airportsNew;

--a) Znajdź lotnisko, które położone jest najbardziej na zachód i najbardziej na wschód.

--najbardziej na wschód
SELECT name
FROM airportsNew
ORDER BY ST_X(airportsNew.geom) DESC LIMIT 1;

--najbardziej na zachód
SELECT name
FROM airportsNew  
ORDER BY ST_X(airportsNew.geom)LIMIT 1;

--b) Do tabeli airportsNew dodaj nowy obiekt - lotnisko, które położone jest w punkcie środkowym drogi 
--pomiędzy lotniskami znalezionymi w punkcie a. Lotnisko nazwij airportB. Wysokość n.p.m. przyjmij dowolną.

INSERT INTO airportsNew (name, elev, geom)
SELECT 'airportB', 244, ST_Centroid(ST_MakeLine(a.geom, b.geom))
FROM airports a, airports b
WHERE a.name = 'ATKA' AND b.name = 'ANNETTE ISLAND';

SELECT * FROM airportsNew;

--6. Wyznacz pole powierzchni obszaru, który oddalony jest mniej niż 1000 jednostek
--od najkrótszej linii łączącej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER”

SELECT ST_Area(ST_Buffer(ST_MakeLine(ST_Centroid(lakes.geom), airports.geom), 1000))
FROM lakes, airports
WHERE lakes.names = 'Iliamna Lake' AND airports.name = 'AMBLER'

--7. Napisz zapytanie, które zwróci sumaryczne pole powierzchni poligonów reprezentujących poszczególne typy drzew znajdujących się na obszarze tundry i bagien (swamps).

SELECT trees.vegdesc, SUM(ST_Area(trees.geom)) 
FROM trees, tundra, swamp
WHERE ST_Contains(trees.geom, swamp.geom) OR ST_Contains(trees.geom, tundra.geom) GROUP BY trees.vegdesc;



