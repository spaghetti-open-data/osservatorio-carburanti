/*su scrape*/
CREATE TABLE tmp_1 AS SELECT * FROM distributori;

UPDATE tmp_1 SET name = REPLACE( name, '"', '' ), addr = REPLACE( addr, '"', '' );

UPDATE tmp_1 SET lat = ROUND(lat, 7), lon = ROUND(lon, 7);

CREATE TABLE tmp_2 AS SELECT id, addr, bnd, comune, ROUND(lat, 7) AS lat, ROUND(lon, 7) AS lon, name, provincia FROM tmp_1 WHERE lat>30 AND LON > 6;
/*esporta tmp_2 in formato CSV con header denominandola distributori.csv, esporta la tabella prezzi come prezzi.csv con header
apri la tabella csv in qgis ed esportala come SQLITE SRID 32632, aggiungi al file SQLITE la tabella prezzi.csv*/

/*inserimento del codice ISTAT comunale nel distributore
CREATE TABLE distributori_comuni AS SELECT distributori.*, comuni. 

CREATE TRIGGER update_poly_id AFTER INSERT ON pts FOR EACH ROW 
BEGIN 
UPDATE pts SET poly_id=(SELECT poly_id FROM polys WHERE ST_Contains(polys.geometry, pts.geometry));
END*/

/*su spatialite*/

CREATE TABLE tmp_1 AS SELECT b.data, CAST(julianday(b.data) AS DOUBLE) AS day, a.id FROM distributori AS a, periodo_analisi AS b ORDER BY a.id, b.data;

CREATE VIEW vtmp_1 AS SELECT CAST(julianday(min(periodo_analisi.data)) AS DOUBLE) AS start_analisi, CAST(julianday(max(periodo_analisi.data)) AS DOUBLE) AS stop_analisi, CAST(julianday(min(periodo_analisi.data)) AS DOUBLE) - 30 AS start_data FROM periodo_analisi;

CREATE TABLE tmp_2 (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, id_d INTEGER, data TEXT, day DOUBLE);

INSERT INTO tmp_2 (id_d, data, day) SELECT id, data, day FROM tmp_1;

CREATE TABLE tmp_3 AS SELECT DISTINCT id_d, CAST(strftime(%Y-%m-%d, dIns) AS TEXT) AS data, CAST(julianday(strftime(%Y-%m-%d, dIns)) AS DOUBLE) AS day, carb, CAST(min(prezzo) AS DOUBLE) AS prezzo FROM prezzi, vtmp_1 WHERE carb = 'Gasolio' AND julianday(dIns) BETWEEN vtmp_1.start_data AND vtmp_1.stop_analisi GROUP BY id_d, data, carb ORDER BY id_d, data;

CREATE TABLE tmp_4 AS SELECT a.id AS id, a.id_d AS id_d, a.data AS data, a.day AS day, b.carb AS carb, b.prezzo AS prezzo FROM tmp_2 AS a LEFT JOIN tmp_3 AS b USING (id_d, day);

CREATE TABLE tmp_5 AS SELECT a.id AS id_corrente, CAST(max(b.id) AS INTEGER) AS id_precedente FROM tmp_4 AS a, tmp_4 AS b WHERE a.id_d = b.id_d AND a.day > b.day AND b.prezzo IS NOT NULL GROUP BY a.id;

CREATE TABLE tmp_6 AS SELECT a.*, b.carb AS carburante_precedente, b.prezzo AS prezzo_precedente FROM tmp_4 AS a, tmp_4 AS b, tmp_5 AS c WHERE a.id = c.id_corrente AND c.id_precedente = b.id;

UPDATE tmp_6 SET carb = carburante_precedente, prezzo = prezzo_precedente WHERE prezzo IS NULL AND carb IS NULL;

CREATE TABLE distributori_prezzi_analisi AS SELECT a.id AS id, a.id_d AS id_d, a.data AS data, a.day AS day, a.carb AS carb, a.prezzo AS prezzo, b.ROWID AS ROWID, b.Geometry AS Geometry, X(b.Geometry) AS X, Y(b.Geometry) AS Y FROM tmp_6 AS a LEFT JOIN distributori AS b ON (a.id_d = b.id);

SELECT AddGeometryColumn('distributori_prezzi_analisi', 'Geometry', 32632, 'POINT', 'XY');

UPDATE distributori_prezzi_analisi SET Geometry=MakePoint(X, Y, 32632);

SELECT CreateSpatialIndex('distributori_prezzi_analisi','Geometry');

CREATE INDEX index_prezzo ON distributori_prezzi_analisi (prezzo);






































