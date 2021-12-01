SELECT*FROM rasters.dem;
SELECT*FROM rasters.landsat8;
SELECT*FROM vectors.porto_parishes;

--TWORZENIE RASTRÓW Z ISTNIEJĄCYCH RASTRÓW I INTERAKCjA Z WEKTORAMI

-- ST_Intersects Przecięcie rastra z wektorem.
--LIKE rozróżnia wielkość liter, ILIKE nie rozróżnia wielkości liter.
DROP TABLE schema_name.intersects;

CREATE TABLE schema_name.intersects AS 
SELECT a.rast, b.municipality FROM rasters.dem AS a, vectors.porto_parishes AS b 
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

SELECT*FROM schema_name.intersects;

-- 1.dodanie serial primary key:
alter table schema_name.intersects add column rid SERIAL PRIMARY KEY;

--2. utworzenie indeksu przestrzennego (index ten przyśpiesza wykonywanie zapytań), ST_ConvexHull - oblicza wypukłą część geometrii:
CREATE INDEX idx_intersects_rast_gist ON schema_name.intersects USING gist (ST_ConvexHull(rast));

--3.dodanie raster constraints Generuje ograniczenia na kolumnie rastrowej, które są używane do wyświetlania informacji w katalogu rastrowym raster_columns:
SELECT AddRasterConstraints('schema_name'::name, 'intersects'::name, 'rast'::name);


-- ST_Clip Obcinanie rastra na podstawie wektora.
DROP TABLE schema_name.clip;

CREATE TABLE schema_name.clip AS SELECT ST_Clip(a.rast, b.geom, true), b.municipality 
FROM rasters.dem AS a, vectors.porto_parishes AS b 
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

SELECT*FROM schema_name.clip;


-- ST_Union Połączenie wielu kafelków w jeden raster.
DROP TABLE schema_name.union;

CREATE TABLE schema_name.union AS SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b 
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);

SELECT*FROM schema_name.union;

--TWORZENIE RASTRÓW Z WEKTORÓW
-- ST_AsRaster(zamiana typu geometry na typ raster) Przykład pokazuje użycie funkcji w celu rastrowania tabeli z parafiami 
--o takiej samej charakterystyce przestrzennej tj.: wielkość piksela, zakresy itp.
DROP TABLE schema_name.porto_parishes;

CREATE TABLE schema_name.porto_parishes AS WITH r AS (SELECT rast FROM rasters.dem LIMIT 1)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id, -32767) AS rast 
FROM vectors.porto_parishes AS a, r WHERE a.municipality ilike 'porto';

SELECT*FROM schema_name.porto_parishes;


--ST_Union Wynikowy raster z poprzedniego zadania to jedna parafia na rekord, na wiersz tabeli. 
--Użyj QGIS lub ArcGIS do wizualizacji wyników. Drugi przykład łączy rekordy z poprzedniego przykładu przy użyciu funkcji 
--ST_UNION w pojedynczy raster.
DROP TABLE schema_name.porto_parishes;

CREATE TABLE schema_name.porto_parishes AS WITH r AS (SELECT rast FROM rasters.dem LIMIT 1)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast 
FROM vectors.porto_parishes AS a, r WHERE a.municipality ilike 'porto';

SELECT*FROM schema_name.porto_parishes;


-- ST_Tile Po uzyskaniu pojedynczego rastra można generować kafelki za pomocą funkcji ST_Tile.
DROP TABLE schema_name.porto_parishes;

CREATE TABLE schema_name.porto_parishes AS WITH r AS (SELECT rast FROM rasters.dem LIMIT 1)
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)),128,128,true,-32767) AS rast 
FROM vectors.porto_parishes AS a, r WHERE a.municipality ilike 'porto';

SELECT*FROM schema_name.porto_parishes;


--KONWERTOWANIE RASTRA NA WEKTORY
--ST_Intersection Funkcja jest podobna do ST_Clip. ST_Clip zwraca raster, a ST_Intersection zwraca zestaw par wartości geometria-piksel,
--ponieważ ta funkcja przekształca raster w wektor przed rzeczywistym „klipem”.
--Zazwyczaj ST_Intersection jest wolniejsze od ST_Clip więc zasadnym jest przeprowadzenie operacji 
--ST_Clip na rastrze przed wykonaniem funkcji ST_Intersection.

CREATE TABLE schema_name.intersection as 
SELECT a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)).val 
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b 
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

SELECT*FROM schema_name.intersection;


---ST_DumpAsPolygons konwertuje rastry w wektory (poligony).
DROP TABLE schema_name.dumppolygons;

CREATE TABLE schema_name.dumppolygons AS SELECT a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val 
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

SELECT*FROM schema_name.dumppolygons;

--geomval to złożony typ danych składający się z obiektu geometrycznego, do którego odwołuje się pole .geom i val, wartość podwójnej precyzji, 
--która reprezentuje wartość piksela w określonej lokalizacji geometrycznej w paśmie rastrowym.


--ANALIZA RASTRÓW
-- ST_Band Funkcja służy do wyodrębniania pasm z rastraZwraca jeden lub więcej pasm istniejącego rastra jako nowy raster.
DROP TABLE schema_name.landsat_nir;

CREATE TABLE schema_name.landsat_nir AS SELECT rid, ST_Band(rast,4) AS rast 
FROM rasters.landsat8;

SELECT*FROM schema_name.landsat_nir;


-- ST_Clip może być użyty do wycięcia rastra z innego rastra. Poniższy przykład wycina jedną parafię z tabeli vectors.porto_parishes.
--Wynik będzie potrzebny do wykonania kolejnych przykładów.
DROP TABLE schema_name.paranhos_dem;

CREATE TABLE schema_name.paranhos_dem AS SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast 
FROM rasters.dem AS a, vectors.porto_parishes AS b 
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

SELECT*FROM schema_name.paranhos_dem;


-- ST_Slope (tworzy raster reprezentujący nachylenia stoków) wygeneruje nachylenie przy użyciu poprzednio wygenerowanej tabeli (wzniesienie).

CREATE TABLE schema_name.paranhos_slope AS SELECT a.rid, ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast 
FROM schema_name.paranhos_dem AS a;

SELECT*FROM schema_name.paranhos_slope;


--ST_Reclass - sluży do zreklasyfikownia rastra. 

CREATE TABLE schema_name.paranhos_slope_reclass AS
SELECT a.rid, ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3',
'32BF',0)
FROM schema_name.paranhos_slope AS a;

SELECT*FROM schema_name.paranhos_slope_reclass;


--ST_SummaryStats - oblicza statystyki rastramin, max, suma, wariancja, odchylenie standardowe, liczebność)
--Poniższy przykład wygeneruje statystyki dla kafelka.

SELECT st_summarystats(a.rast) AS stats
FROM schema_name.paranhos_dem AS a;


-- ST_SummaryStats oraz Union - Przy użyciu UNION można wygenerować jedną statystykę wybranego rastra.

SELECT st_summarystats(ST_Union(a.rast))
FROM schema_name.paranhos_dem AS a;

--ST_SummaryStats z lepszą kontrolą złożonego typu danych

WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM schema_name.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

-- ST_SummaryStats w połączeniu z GROUP BY - Aby wyświetlić statystykę dla każdego poligonu "parish" 
WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,
b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;



--ST_Value
--Funkcja ST_Value pozwala wyodrębnić wartość piksela z punktu lub zestawu punktów. Poniższy
--przykład wyodrębnia punkty znajdujące się w tabeli vectors.places.
--Ponieważ geometria punktów jest wielopunktowa, a funkcja ST_Value wymaga geometrii
--jednopunktowej, należy przekonwertować geometrię wielopunktową na geometrię jednopunktową
--za pomocą funkcji (ST_Dump(b.geom)).geom.

SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;


-- ST_TPI - TPI porównuje wysokość każdej komórki w DEM ze średnią wysokością określonego sąsiedztwa wokół tej komórki. 

create table schema_name.tpi30 as
select ST_TPI(a.rast,1) as rast
from rasters.dem a;

SELECT*FROM schema_name.tpi30;


--Poniższa kwerenda utworzy indeks przestrzenny:
CREATE INDEX idx_tpi30_rast_gist ON schema_name.tpi30
USING gist (ST_ConvexHull(rast));

--Dodanie constraintów:
SELECT AddRasterConstraints('schema_name'::name,
'tpi30'::name,'rast'::name);


--Problem do samodzielnego rozwiązania
create table schema_name.tpi30_porto as
SELECT ST_TPI(a.rast,1) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto'

--Dodanie indeksu przestrzennego:
CREATE INDEX idx_tpi30_porto_rast_gist ON schema_name.tpi30_porto
USING gist (ST_ConvexHull(rast));

--Dodanie constraintów:
SELECT AddRasterConstraints('schema_name'::name,
'tpi30_porto'::name,'rast'::name);



--ALGEBRA MAP
--NDVI=(NIR-Red)/(NIR+Red)
--Wyrażenie Algebry Map
-- ST_MapAlgebra - umożliwia wykonywanie operacji matematycznych na odpowiadających sobie pikselach,

CREATE TABLE schema_name.porto_ndvi AS
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

SELECT*FROM schema_name.porto_ndvi;


--Poniższe zapytanie utworzy indeks przestrzenny na wcześniej stworzonej tabeli:
CREATE INDEX idx_porto_ndvi_rast_gist ON schema_name.porto_ndvi
USING gist (ST_ConvexHull(rast));


--Dodanie constraintów:
SELECT AddRasterConstraints('schema_name'::name,
'porto_ndvi'::name,'rast'::name);


--Funkcja zwrotna
--W pierwszym kroku należy utworzyć funkcję, które będzie wywołana później:

create or replace function schema_name.ndvi(
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

--W kwerendzie algebry map należy można wywołać zdefiniowaną wcześniej funkcję:
CREATE TABLE schema_name.porto_ndvi2 AS
WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
	r.rid,ST_MapAlgebra(
		r.rast, ARRAY[1,4],
		'schema_name.ndvi(double precision[],
		integer[],text[])'::regprocedure, --> This is the function!
		'32BF'::text
) AS rast
FROM r;

--Dodanie indeksu przestrzennego:
CREATE INDEX idx_porto_ndvi2_rast_gist ON schema_name.porto_ndvi2
USING gist (ST_ConvexHull(rast));

--Dodanie constraintów:
SELECT AddRasterConstraints('schema_name'::name,
'porto_ndvi2'::name,'rast'::name);




--ST_AsTiff tworzy dane wyjściowe jako binarną reprezentację pliku tiff, może to być przydatne
--na stronach internetowych, skryptach itp., w których programista może kontrolować, co zrobić z
--plikiem binarnym, na przykład zapisać go na dysku lub po prostu wyświetlić.
SELECT ST_AsTiff(ST_Union(rast))
FROM schema_name.porto_ndvi;


--ST_AsGDALRaster
--Podobnie do funkcji ST_AsTiff, ST_AsGDALRaster nie zapisuje danych wyjściowych bezpośrednio na
--dysku, natomiast dane wyjściowe są reprezentacją binarną dowolnego formatu GDAL.
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
FROM schema_name.porto_ndvi;



--Funkcje ST_AsGDALRaster pozwalają nam zapisać raster w dowolnym formacie obsługiwanym przez
--gdal. Aby wyświetlić listę formatów obsługiwanych przez bibliotekę uruchom:
SELECT ST_GDALDrivers();


--Zapisywanie danych na dysku za pomocą dużego obiektu (large object, lo)
DROP TABLE tmp_out;

CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
 ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
 ) AS loid
FROM schema_name.porto_ndvi;
----------------------------------------------
SELECT lo_export(loid, 'D:\myraster.tiff') --> Save the file in a place
--where the user postgres have access. In windows a flash drive usualy works
--fine.
 FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.

-- Użycie Gdal
--Gdal obsługuje rastry z PostGISa. Polecenie gdal_translate eksportuje raster do dowolnego formatu
--obsługiwanego przez GDAL.
gdal_translate -co COMPRESS=DEFLATE -co PREDICTOR=2 -co ZLEVEL=9
PG:"host=localhost port=5432 dbname=cw6 user=postgres
password=postgis schema=schema_name table=porto_ndvi mode=2"
porto_ndvi.tiff


--Mapfile
MAP
NAME 'map'
SIZE 800 650
STATUS ON
EXTENT -58968 145487 30916 206234
UNITS METERS
WEB
METADATA
'wms_title' 'Terrain wms'
'wms_srs' 'EPSG:3763 EPSG:4326 EPSG:3857'
'wms_enable_request' '*'
'wms_onlineresource'
'http://54.37.13.53/mapservices/srtm'
END
END
PROJECTION
'init=epsg:3763'
END
LAYER
NAME srtm
TYPE raster
STATUS OFF
DATA "PG:host=localhost port=5432 dbname='postgis_raster'
user='sasig' password='postgis' schema='rasters' table='dem' mode='2'"
PROCESSING "SCALE=AUTO"
PROCESSING "NODATA=-32767"
OFFSITE 0 0 0
METADATA
'wms_title' 'srtm'
END
END
END




--GEOSERVER

CREATE TABLE public.mosaic (
    name character varying(254) COLLATE pg_catalog."default" NOT NULL,
    tiletable character varying(254) COLLATE pg_catalog."default" NOT NULL,
    minx double precision,
    miny double precision,
    maxx double precision,
    maxy double precision,
    resx double precision,
    resy double precision,
    CONSTRAINT mosaic_pkey PRIMARY KEY (name, tiletable)
);

insert into mosaic (name,tiletable) values ('mosaicpgraster','rasters.dem');
