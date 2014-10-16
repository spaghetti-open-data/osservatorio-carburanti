/* 
- crea DB spatialite.sqlite
- disconnetterlo
- carica in MEMORY-DB spatialite.sqlite
- connetti il DB scrape.sqlite
- importa lo shape file dei confini comunali ISTAT con il nome "comuni" l'SRID corrispondente dovrebbe essere 32632
- importa la tabella csv periodo analisi
*/

CREATE TABLE tmp_1 AS SELECT * FROM distributori;

UPDATE tmp_1 SET name = REPLACE( name, '"', '' ), addr = REPLACE( addr, '"', '' );

UPDATE tmp_1 SET lat = ROUND(lat, 7), lon = ROUND(lon, 7);

CREATE TABLE distributori_ AS SELECT id, addr, bnd, comune, ROUND(lat, 7) AS lat, ROUND(lon, 7) AS lon, name, provincia FROM tmp_1 WHERE lat>30 AND LON > 6;

CREATE TABLE prezzi_ as SELECT * FROM prezzi;

DROP TABLE tmp_1;

CREATE TABLE tmp_1 AS SELECT b.data, CAST(julianday(b.data) AS DOUBLE) AS day, a.id FROM distributori_ AS a, periodo_analisi AS b ORDER BY a.id, b.data;

CREATE VIEW vtmp_1 AS SELECT CAST(julianday(min(periodo_analisi.data)) AS DOUBLE) AS start_analisi, CAST(julianday(max(periodo_analisi.data)) AS DOUBLE) AS stop_analisi, CAST(julianday(min(periodo_analisi.data)) AS DOUBLE) - 30 AS start_data FROM periodo_analisi;

CREATE TABLE tmp_2 (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, id_d INTEGER, data TEXT, day DOUBLE);

INSERT INTO tmp_2 (id_d, data, day) SELECT id, data, day FROM tmp_1;

CREATE TABLE tmp_3 AS SELECT DISTINCT id_d, CAST(strftime('%Y-%m-%d', dIns) AS TEXT) AS data, CAST(julianday(strftime('%Y-%m-%d', dIns)) AS DOUBLE) AS day, carb, CAST(min(prezzo) AS DOUBLE) AS prezzo FROM prezzi_, vtmp_1 WHERE carb = 'Gasolio' AND julianday(dIns) BETWEEN vtmp_1.start_data AND vtmp_1.stop_analisi GROUP BY id_d, data, carb ORDER BY id_d, data;

CREATE TABLE tmp_4 AS SELECT a.id AS id, a.id_d AS id_d, a.data AS data, a.day AS day, b.carb AS carb, b.prezzo AS prezzo FROM tmp_2 AS a LEFT JOIN tmp_3 AS b USING (id_d, day);

CREATE TABLE tmp_5 AS SELECT a.id AS id_corrente, CAST(max(b.id) AS INTEGER) AS id_precedente FROM tmp_4 AS a, tmp_4 AS b WHERE a.id_d = b.id_d AND a.day > b.day AND b.prezzo IS NOT NULL GROUP BY a.id;

CREATE TABLE tmp_6 AS SELECT a.*, b.carb AS carburante_precedente, b.prezzo AS prezzo_precedente FROM tmp_4 AS a, tmp_4 AS b, tmp_5 AS c WHERE a.id = c.id_corrente AND c.id_precedente = b.id;

UPDATE tmp_6 SET carb = carburante_precedente, prezzo = prezzo_precedente WHERE prezzo IS NULL AND carb IS NULL;

SELECT AddGeometryColumn('distributori_', 'Geometry', 32632, 'POINT', 'XY');

UPDATE distributori_ SET Geometry=MakePoint(lon, lat, 32632);

ALTER TABLE distributori_ ADD COLUMN cod_istat INTEGER;
 
UPDATE distributori_ SET cod_istat = (SELECT comuni.COD_ISTAT FROM comuni WHERE ST_Contains(comuni.Geometry, distributori_.Geometry));

CREATE TABLE distributori_prezzi_analisi AS SELECT a.id AS id, a.id_d AS id_d, a.data AS data, a.day AS day, a.carb AS carb, a.prezzo AS prezzo, b.ROWID AS ROWID, b.lat AS lat, b.lon AS Y FROM tmp_6 AS a LEFT JOIN distributori_ AS b ON (a.id_d = b.id);

CREATE INDEX index_prezzo ON distributori_prezzi_analisi (prezzo);

SELECT AddGeometryColumn('distributori_prezzo_analisi', 'Geometry', 32632, 'POINT', 'XY');

UPDATE distributori_prezzo_analisi SET Geometry=MakePoint(lon, lat, 32632);

SELECT CreateSpatialIndex('distributori_prezzi_analisi','Geometry');

DROP TABLE tmp_1;

DROP TABLE tmp_2;

DROP TABLE tmp_3;

DROP TABLE tmp_4;

DROP TABLE tmp_5;

DROP TABLE tmp_6;

DROP VIEW vtmp_1;

VACUUM;
/* 
- disconnettere scrape
- salvare il DB
*/





































