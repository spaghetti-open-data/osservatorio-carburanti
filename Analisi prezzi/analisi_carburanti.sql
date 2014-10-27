/* 
- crea DB spatialite.sqlite
- disconnetterlo
- carica in MEMORY-DB spatialite.sqlite
- connetti il DB scrape.sqlite
- importa lo shape file dei confini comunali ISTAT con il nome "comuni" l'SRID corrispondente dovrebbe essere 32632
- importa la tabella csv periodo analisi (il periodo analisi deve partire 1 giorno prima del primo giorno monitorato es. 31 agosto - 30 settembre per analizzare il mese di settembre)
*/

CREATE TABLE tmp_1 AS SELECT * FROM distributori;

UPDATE tmp_1 SET name = REPLACE( name, '"', '' ), addr = REPLACE( addr, '"', '' );

UPDATE tmp_1 SET lat = ROUND(lat, 7), lon = ROUND(lon, 7);

CREATE TABLE distributori_ (id INTEGER NOT NULL PRIMARY KEY, addr TEXT, bnd TEXT, comune TEXT, lat DOUBLE, lon DOUBLE, name TEXT, provincia TEXT);

INSERT INTO distributori_ (id, addr, bnd, comune, lat, lon, name, provincia) SELECT id, addr, bnd, comune, ROUND(lat, 7) AS lat, ROUND(lon, 7) AS lon, name, provincia FROM tmp_1 WHERE lat>30 AND LON > 6;

CREATE TABLE prezzi_ (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, id_d INTEGER, dIns datetime, carb TEXT, isSelf INTEGER, prezzo DUOBLE, dScrape INTEGER); 

INSERT INTO prezzi_ (id_d, dIns, carb, isSelf, prezzo, dScrape) SELECT id_d, dIns, carb, isSelf, prezzo, dScrape FROM prezzi WHERE prezzo > 0;

DROP TABLE tmp_1;

CREATE TABLE tmp_1 AS SELECT b.data, CAST(julianday(b.data) AS DOUBLE) AS day, a.id FROM distributori_ AS a, periodo_analisi AS b ORDER BY a.id, b.data;

CREATE VIEW vtmp_1 AS SELECT CAST(julianday(min(periodo_analisi.data)) AS DOUBLE) AS start_analisi, CAST(julianday(max(periodo_analisi.data)) AS DOUBLE) AS stop_analisi FROM periodo_analisi;

CREATE TABLE tmp_2 (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, id_d INTEGER, data TEXT, day DOUBLE);

INSERT INTO tmp_2 (id_d, data, day) SELECT id, data, day FROM tmp_1;

CREATE TABLE tmp_3 AS SELECT DISTINCT id_d, CAST(strftime('%Y-%m-%d', dIns) AS TEXT) AS data, CAST(julianday(strftime('%Y-%m-%d', dIns)) AS DOUBLE) AS day, carb, CAST(min(prezzo) AS DOUBLE) AS prezzo FROM prezzi_, vtmp_1 WHERE carb = 'Gasolio' AND julianday(dIns) BETWEEN vtmp_1.start_analisi AND vtmp_1.stop_analisi GROUP BY id_d, data, carb ORDER BY id_d, data;

CREATE TABLE tmp_4 AS SELECT a.id AS id, a.id_d AS id_d, a.data AS data, a.day AS day, b.carb AS carb, b.prezzo AS prezzo FROM tmp_2 AS a LEFT JOIN tmp_3 AS b USING (id_d, day);

CREATE TABLE tmp_5 AS SELECT a.id AS id_corrente, CAST(max(b.id) AS INTEGER) AS id_precedente FROM tmp_4 AS a, tmp_4 AS b WHERE a.id_d = b.id_d AND a.day > b.day AND b.prezzo IS NOT NULL GROUP BY a.id;

CREATE TABLE tmp_6 AS SELECT a.*, b.carb AS carburante_precedente, b.prezzo AS prezzo_precedente FROM tmp_4 AS a, tmp_4 AS b, tmp_5 AS c WHERE a.id = c.id_corrente AND c.id_precedente = b.id;

UPDATE tmp_6 SET carb = carburante_precedente, prezzo = prezzo_precedente WHERE prezzo IS NULL AND carb IS NULL;

SELECT AddGeometryColumn('distributori_', 'Geometry', 32632, 'POINT', 'XY');

UPDATE distributori_ SET Geometry = ST_Transform(MakePoint(lon, lat, 4326), 32632);

ALTER TABLE distributori_ ADD COLUMN cod_istat INTEGER;

ALTER TABLE distributori_ ADD COLUMN cod_pro INTEGER;

ALTER TABLE distributori_ ADD COLUMN cod_reg INTEGER;

UPDATE distributori_ SET cod_istat = (SELECT comuni.COD_ISTAT FROM comuni WHERE ST_Contains(comuni.Geometry, distributori_.Geometry));

UPDATE distributori_ SET cod_pro = (SELECT comuni.COD_PRO FROM comuni WHERE comuni.COD_ISTAT = distributori_.cod_istat);

UPDATE distributori_ SET cod_reg = (SELECT comuni.COD_REG FROM comuni WHERE comuni.COD_ISTAT = distributori_.cod_istat);

CREATE TABLE distributori_prezzi_analisi_gasolio (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, id_d INTEGER, bnd TEXT, name TEXT, data TEXT, day DOUBLE, carb TEXT, prezzo DOUBLE, cod_istat INTEGER, cod_pro INTEGER, cod_reg INTEGER, lat DOUBLE, lon DOUBLE);

INSERT INTO distributori_prezzi_analisi_gasolio (id_d, bnd, name, data, day, carb, prezzo, cod_istat, cod_pro, cod_reg, lat, lon) SELECT a.id_d AS id_d, b.bnd AS bnd, b.name AS name, a.data AS data, a.day AS day, a.carb AS carb, a.prezzo AS prezzo, b.cod_istat AS cod_istat, b.cod_pro AS cod_pro, b.cod_reg AS cod_reg, b.lat AS lat, b.lon AS lon FROM tmp_6 AS a LEFT JOIN distributori_ AS b ON (a.id_d = b.id);

CREATE INDEX index_prezzo_gasolio ON distributori_prezzi_analisi_gasolio (prezzo);

CREATE INDEX index_cod_pro_gasolio ON distributori_prezzi_analisi_gasolio (cod_pro);

CREATE INDEX index_cod_reg_gasolio ON distributori_prezzi_analisi_gasolio (cod_reg);

CREATE INDEX index_cod_istat_gasolio ON distributori_prezzi_analisi_gasolio (cod_istat);

CREATE INDEX index_data_gasolio ON distributori_prezzi_analisi_gasolio (data);

CREATE INDEX index_data_id_d_gasolio ON distributori_prezzi_analisi_gasolio (id_d);

SELECT AddGeometryColumn('distributori_prezzi_analisi_gasolio', 'Geometry', 32632, 'POINT', 'XY');

UPDATE distributori_prezzi_analisi_gasolio SET Geometry=ST_Transform(MakePoint(lon, lat, 4326), 32632);

SELECT CreateSpatialIndex('distributori_prezzi_analisi_gasolio','Geometry');

CREATE TABLE tmp_7 AS SELECT DISTINCT id_d, CAST(strftime('%Y-%m-%d', dIns) AS TEXT) AS data, CAST(julianday(strftime('%Y-%m-%d', dIns)) AS DOUBLE) AS day, carb, CAST(min(prezzo) AS DOUBLE) AS prezzo FROM prezzi_, vtmp_1 WHERE carb = 'Benzina' AND julianday(dIns) BETWEEN vtmp_1.start_analisi AND vtmp_1.stop_analisi GROUP BY id_d, data, carb ORDER BY id_d, data;

CREATE TABLE tmp_8 AS SELECT a.id AS id, a.id_d AS id_d, a.data AS data, a.day AS day, b.carb AS carb, b.prezzo AS prezzo FROM tmp_2 AS a LEFT JOIN tmp_7 AS b USING (id_d, day);

CREATE TABLE tmp_9 AS SELECT a.id AS id_corrente, CAST(max(b.id) AS INTEGER) AS id_precedente FROM tmp_8 AS a, tmp_8 AS b WHERE a.id_d = b.id_d AND a.day > b.day AND b.prezzo IS NOT NULL GROUP BY a.id;

CREATE TABLE tmp_10 AS SELECT a.*, b.carb AS carburante_precedente, b.prezzo AS prezzo_precedente FROM tmp_8 AS a, tmp_8 AS b, tmp_9 AS c WHERE a.id = c.id_corrente AND c.id_precedente = b.id;

UPDATE tmp_10 SET carb = carburante_precedente, prezzo = prezzo_precedente WHERE prezzo IS NULL AND carb IS NULL;

CREATE TABLE distributori_prezzi_analisi_benzina (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, id_d INTEGER, bnd TEXT, name TEXT, data TEXT, day DOUBLE, carb TEXT, prezzo DOUBLE, cod_istat INTEGER, cod_pro INTEGER, cod_reg INTEGER, lat DOUBLE, lon DOUBLE);

INSERT INTO distributori_prezzi_analisi_benzina (id_d, bnd, name, data, day, carb, prezzo, cod_istat, cod_pro, cod_reg, lat, lon) SELECT a.id_d AS id_d, b.bnd AS bnd, b.name AS name, a.data AS data, a.day AS day, a.carb AS carb, a.prezzo AS prezzo, b.cod_istat AS cod_istat, b.cod_pro AS cod_pro, b.cod_reg AS cod_reg, b.lat AS lat, b.lon AS lon FROM tmp_10 AS a LEFT JOIN distributori_ AS b ON (a.id_d = b.id);

CREATE INDEX index_prezzo_benzina ON distributori_prezzi_analisi_benzina (prezzo);

CREATE INDEX index_cod_pro_benzina ON distributori_prezzi_analisi_benzina (cod_pro);

CREATE INDEX index_cod_reg_benzina ON distributori_prezzi_analisi_benzina (cod_reg);

CREATE INDEX index_cod_istat_benzina ON distributori_prezzi_analisi_benzina (cod_istat);

CREATE INDEX index_data_benzina ON distributori_prezzi_analisi_benzina (data);

CREATE INDEX index_data_id_d_benzina ON distributori_prezzi_analisi_benzina (id_d);

SELECT AddGeometryColumn('distributori_prezzi_analisi_benzina', 'Geometry', 32632, 'POINT', 'XY');

UPDATE distributori_prezzi_analisi_benzina SET Geometry=ST_Transform(MakePoint(lon, lat, 4326), 32632);

SELECT CreateSpatialIndex('distributori_prezzi_analisi_benzina','Geometry');

DROP TABLE tmp_1;

DROP TABLE tmp_2;

DROP TABLE tmp_3;

DROP TABLE tmp_4;

DROP TABLE tmp_5;

DROP TABLE tmp_6;

DROP TABLE tmp_7;

DROP TABLE tmp_8;

DROP TABLE tmp_9;

DROP TABLE tmp_10;

DROP VIEW vtmp_1;

VACUUM;
/* 
- disconnettere scrape
- salvare il DB
- creo un buffer su un distributore da analizzare 
- carico lo shape del buffer
- carico lo spatialite in RAM
*/

CREATE TABLE tmp_1 AS SELECT distributori_prezzi_analisi_gasolio.* FROM distributori_prezzi_analisi_gasolio, enercoop_300sec WHERE ST_Contains(enercoop_300sec.Geometry, distributori_prezzi_analisi_gasolio.Geometry);

CREATE TABLE tmp_2 AS SELECT DISTINCT id_d, name, bnd FROM tmp_1 ORDER BY id_d;

CREATE TABLE tmp_3 AS SELECT * FROM periodo_analisi ORDER BY data ASC;

CREATE INDEX index_data_tmp_3 ON tmp_3 (data);

ALTER TABLE tmp_3 ADD COLUMN TotalErg_5521 DUOBLE;

ALTER TABLE tmp_3 ADD COLUMN TotalErg_5781 DOUBLE;

ALTER TABLE tmp_3 ADD COLUMN AgipEni_7137 DOUBLE;

ALTER TABLE tmp_3 ADD COLUMN AgipEni_8268 DOUBLE;

ALTER TABLE tmp_3 ADD COLUMN Enercoop_10262 DOUBLE;

ALTER TABLE tmp_3 ADD COLUMN AgipEni_12395 DOUBLE;

ALTER TABLE tmp_3 ADD COLUMN Esso_14677 DOUBLE;

ALTER TABLE tmp_3 ADD COLUMN Bentivoglio_17190 DOUBLE;

ALTER TABLE tmp_3 ADD COLUMN Gepoil_17870 DOUBLE;

ALTER TABLE tmp_3 ADD COLUMN AgipEni_21035 DOUBLE;

ALTER TABLE tmp_3 ADD COLUMN ApiIp_21449 DOUBLE;

ALTER TABLE tmp_3 ADD COLUMN Q8_23011 DOUBLE;

UPDATE tmp_3 SET TotalErg_5521 = (SELECT distributori_prezzi_analisi_gasolio.prezzo FROM distributori_prezzi_analisi_gasolio WHERE distributori_prezzi_analisi_gasolio.id_d = 5521 AND distributori_prezzi_analisi_gasolio.data = tmp_3.data);

UPDATE tmp_3 SET TotalErg_5781 = (SELECT distributori_prezzi_analisi_gasolio.prezzo FROM distributori_prezzi_analisi_gasolio WHERE distributori_prezzi_analisi_gasolio.id_d = 5781 AND distributori_prezzi_analisi_gasolio.data = tmp_3.data);

UPDATE tmp_3 SET AgipEni_7137 = (SELECT distributori_prezzi_analisi_gasolio.prezzo FROM distributori_prezzi_analisi_gasolio WHERE distributori_prezzi_analisi_gasolio.id_d = 7137 AND distributori_prezzi_analisi_gasolio.data = tmp_3.data);

UPDATE tmp_3 SET AgipEni_8268 = (SELECT distributori_prezzi_analisi_gasolio.prezzo FROM distributori_prezzi_analisi_gasolio WHERE distributori_prezzi_analisi_gasolio.id_d = 8268 AND distributori_prezzi_analisi_gasolio.data = tmp_3.data);

UPDATE tmp_3 SET Enercoop_10262 = (SELECT distributori_prezzi_analisi_gasolio.prezzo FROM distributori_prezzi_analisi_gasolio WHERE distributori_prezzi_analisi_gasolio.id_d = 10262 AND distributori_prezzi_analisi_gasolio.data = tmp_3.data);

UPDATE tmp_3 SET AgipEni_12395 = (SELECT distributori_prezzi_analisi_gasolio.prezzo FROM distributori_prezzi_analisi_gasolio WHERE distributori_prezzi_analisi_gasolio.id_d = 12395 AND distributori_prezzi_analisi_gasolio.data = tmp_3.data);

UPDATE tmp_3 SET Esso_14677 = (SELECT distributori_prezzi_analisi_gasolio.prezzo FROM distributori_prezzi_analisi_gasolio WHERE distributori_prezzi_analisi_gasolio.id_d = 14677 AND distributori_prezzi_analisi_gasolio.data = tmp_3.data);

UPDATE tmp_3 SET Bentivoglio_17190 = (SELECT distributori_prezzi_analisi_gasolio.prezzo FROM distributori_prezzi_analisi_gasolio WHERE distributori_prezzi_analisi_gasolio.id_d = 17190 AND distributori_prezzi_analisi_gasolio.data = tmp_3.data);

UPDATE tmp_3 SET Gepoil_17870 = (SELECT distributori_prezzi_analisi_gasolio.prezzo FROM distributori_prezzi_analisi_gasolio WHERE distributori_prezzi_analisi_gasolio.id_d = 17870 AND distributori_prezzi_analisi_gasolio.data = tmp_3.data);

UPDATE tmp_3 SET AgipEni_21035 = (SELECT distributori_prezzi_analisi_gasolio.prezzo FROM distributori_prezzi_analisi_gasolio WHERE distributori_prezzi_analisi_gasolio.id_d = 21035 AND distributori_prezzi_analisi_gasolio.data = tmp_3.data);

UPDATE tmp_3 SET ApiIp_21449 = (SELECT distributori_prezzi_analisi_gasolio.prezzo FROM distributori_prezzi_analisi_gasolio WHERE distributori_prezzi_analisi_gasolio.id_d = 21449 AND distributori_prezzi_analisi_gasolio.data = tmp_3.data);

UPDATE tmp_3 SET Q8_23011 = (SELECT distributori_prezzi_analisi_gasolio.prezzo FROM distributori_prezzi_analisi_gasolio WHERE distributori_prezzi_analisi_gasolio.id_d = 23011 AND distributori_prezzi_analisi_gasolio.data = tmp_3.data);


























