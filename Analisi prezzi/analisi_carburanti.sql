CREATE TABLE tmp_1 AS SELECT b.data, CAST(julianday(b.data) AS DOUBLE) AS day, a.id FROM distributori AS a, periodo_analisi AS b ORDER BY a.id, b.data;

CREATE VIEW vtmp_1 AS SELECT CAST(julianday(min(periodo_analisi.data)) AS DOUBLE) AS start_analisi, CAST(julianday(max(periodo_analisi.data)) AS DOUBLE) AS stop_analisi, CAST(julianday(min(periodo_analisi.data)) AS DOUBLE) - 30 AS start_data FROM periodo_analisi;

CREATE TABLE tmp_2 (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, id_d INTEGER, data TEXT, day DOUBLE);

INSERT INTO tmp_2 (id_d, data, day) SELECT id, data, day FROM tmp_1;

CREATE TABLE tmp_3 AS SELECT DISTINCT id_d, CAST(strftime("%Y-%m-%d", dIns) AS TEXT) AS data, CAST(julianday(strftime("%Y-%m-%d", dIns)) AS DOUBLE) AS day, carb, CAST(min(prezzo) AS DOUBLE) AS prezzo FROM prezzi, vtmp_1 WHERE carb = 'Gasolio' AND julianday(dIns) BETWEEN vtmp_1.start_data AND vtmp_1.stop_analisi GROUP BY id_d, data, carb ORDER BY id_d, data;

CREATE TABLE tmp_4 AS SELECT a.id AS id, a.id_d AS id_d, a.data AS data, a.day AS day, b.carb AS carb, b.prezzo AS prezzo FROM tmp_2 AS a LEFT JOIN tmp_3 AS b USING (id_d, day);

CREATE TABLE tmp_5 AS SELECT a.id AS id_corrente, CAST(max(b.id) AS INTEGER) AS id_precedente FROM tmp_4 AS a, tmp_4 AS b WHERE a.id_d = b.id_d AND a.day > b.day AND b.prezzo IS NOT NULL GROUP BY a.id;

CREATE TABLE tmp_6 AS SELECT a.*, b.carb AS carburante_precedente, b.prezzo AS prezzo_precedente FROM tmp_4 AS a, tmp_4 AS b, tmp_5 AS c WHERE a.id = c.id_corrente AND c.id_precedente = b.id;

UPDATE tmp_6 SET carb = carburante_precedente, prezzo = prezzo_precedente WHERE prezzo IS NULL AND carb IS NULL;

CREATE TABLE distributori_prezzi_analisi (PK_UID INTEGER NOT NULL PRIMARY KEY, id_d INTEGER, data TEXT, day DOUBLE, carb TEXT, prezzo DOUBLE);

INSERT INTO  distributori_prezzi_analisi (PK_UID, id_d, data, day, carb, prezzo) SELECT id, id_d, data, day, carb, prezzo FROM tmp_6, vtmp_1 WHERE julianday(data) BETWEEN start_analisi AND stop_analisi;

SELECT AddGeometryColumn('distributori_prezzi_analisi', 'Geometry', 4326, 'POINT', 'XY');

UPDATE distributori_prezzi_analisi SET Geometry = ST_Transform((SELECT "b"."Geometry" AS "Geometry" FROM "distributori_prezzi_analisi" AS "a" LEFT OUTER JOIN "distributori" AS "b" ON ("a"."id_d" = "b"."id")),4326);

SELECT CreateSpatialIndex('distributori_prezzi_analisi','Geometry');

CREATE INDEX index_prezzo ON distributori_prezzi_analisi (prezzo);





































