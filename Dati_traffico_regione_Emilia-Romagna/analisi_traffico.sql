CREATE TABLE mts_2014_marker (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, numero_progressivo INTEGER, postazione INTEGER, latitudine VARCHAR(255), y FLOAT, longitudine VARCHAR(255), x FLOAT, tratto VARCHAR(255), nn_corsie INTEGER, progressiva_km VARCHAR(255));

INSERT INTO mts_2014_marker (numero_progressivo, postazione, latitudine, y, longitudine, x, tratto, nn_corsie, progressiva_km) SELECT DISTINCT numero_progressivo, postazione, latitudine, y, longitudine, x, tratto, nn_corsie, progressiva_km FROM mts_2014;

SELECT AddGeometryColumn('mts_2014_marker', 'Geometry', 32632, 'POINT', 'XY');

UPDATE mts_2014_marker SET Geometry = ST_Transform(MakePoint(x, y, 4326), 32632);

SELECT CreateSpatialIndex('mts_2014_marker','Geometry');

CREATE INDEX index_postazione ON mts_2014_marker (postazione);

CREATE TABLE dati_traffico_aggregati AS ((id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, postazione INTEGER, data TEXT, Auto_Monovolume INTEGER, Auto_Monovolume_Rimorchio INTEGER, Furgoncini_Camioncini INTEGER, Camion_Medi INTEGER, Camion_Grandi INTEGER, Autotreni INTEGER, Autoarticolati INTEGER, Autobus INTEGER, Altri INTEGER);

INSERT INTO dati_traffico_aggregati (postazione, data, Auto_Monovolume, Auto_Monovolume_Rimorchio, Furgoncini_Camioncini, Camion_Medi, Camion_Grandi, Autotreni, Autoarticolati, Autobus, Altri) SELECT CAST(Apparato AS INTEGER) AS postazione, CAST(strftime('%Y-%m-%d', Giorno || "-" || Mese || "-" || Anno|) AS data, sum(CAST (Auto_Monovolume AS INTEGER)) AS Auto_Monovolume, sum(CAST (Auto_Monovolume_Rimorchio AS INTEGER)) AS Auto_Monovolume_Rimorchio, sum(CAST (Furgoncini_Camioncini AS INTEGER)) AS Furgoncini_Camioncini, sum(CAST (Camion_Medi AS INTEGER)) AS Camion_Medi, sum(CAST (Camion_Grandi AS INTEGER)) AS Camion_Grandi, sum(CAST (Autotreni AS INTEGER)) AS Autotreni, sum(CAST (Autoarticolati AS INTEGER)) AS Autoarticolati, sum(CAST (Autobus AS INTEGER)) AS Autobus, sum(CAST (Altri AS INTEGER)) AS Altri FROM dati_traffico GROUP BY postazione, data ORDER BY postazione, data ASC;