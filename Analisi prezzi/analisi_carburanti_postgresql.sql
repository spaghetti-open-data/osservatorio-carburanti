CREATE TABLE "public"."distributori" (
	"id" integer,
	"name" text,
	"bnd" text,
	"lat" numeric,
	"lon" numeric,
	"addr" text,
	"comune" text,
	"provincia" text);


CREATE TABLE "public"."prezzi" (
  "id_d" bigint,
  "dins" timestamp,
  "carb" text,
  "isself" integer,
  "prezzo" numeric,
  "dscrape" bigint);

CREATE TABLE "public"."periodo_analisi" (
"data" timestamp);


create table tmp_1 as select * from distributori;

update tmp_1 set name = replace( name, '"', '' ), addr = replace( addr, '"', '' );

update tmp_1 set lat = round(lat, 7), lon = round(lon, 7);

create table distributori_ (id integer not null primary key, addr text, bnd text, comune text, lat numeric, lon numeric, name text, provincia text);

insert into distributori_ (id, addr, bnd, comune, lat, lon, name, provincia) select id, addr, bnd, comune, round(lat, 7) as lat, round(lon, 7) as lon, name, provincia from tmp_1 where lat>30 and lon > 6 and lat<48 and lon<19;

create table prezzi_ (id serial primary key, id_d integer, dins timestamp, carb text, isself integer, prezzo numeric, dscrape integer); 

insert into prezzi_ (id_d, dins, carb, isself, prezzo, dscrape) select id_d, dins, carb, isself, prezzo, dscrape from prezzi where prezzo > 0;

drop table tmp_1;

create table tmp_1 as select b.data, a.id from distributori_ as a, periodo_analisi as b order by a.id, b.data;

create view vtmp_1 as select min(periodo_analisi.data) as start_analisi, max(periodo_analisi.data) as stop_analisi from periodo_analisi;

create table tmp_2 (id serial primary key, id_d integer, data text);

insert into tmp_2 (id_d, data) select id, data from tmp_1;

create table tmp_3 as select distinct id_d, dins as dins, carb, cast(min(prezzo) as numeric) as prezzo from prezzi_, vtmp_1 where carb = 'gasolio' and dins >= vtmp_1.start_analisi and dins <= vtmp_1.stop_analisi group by id_d, dins, carb order by id_d, dins;






create table tmp_4 as select a.id as id, a.id_d as id_d, a.data, b.dins as data, b.carb as carb, b.prezzo as prezzo from tmp_2 as a left join tmp_3 as b using (id_d, data);

create table tmp_5 as select a.id as id_corrente, cast(max(b.id) as integer) as id_precedente from tmp_4 as a, tmp_4 as b where a.id_d = b.id_d and a.day > b.day and b.prezzo is not null group by a.id;

create table tmp_6 as select a.*, b.carb as carburante_precedente, b.prezzo as prezzo_precedente from tmp_4 as a, tmp_4 as b, tmp_5 as c where a.id = c.id_corrente and c.id_precedente = b.id;

update tmp_6 set carb = carburante_precedente, prezzo = prezzo_precedente where prezzo is null and carb is null;

select addgeometrycolumn('distributori_', 'geometry', 32632, 'point', 'xy');

update distributori_ set geometry = st_transform(makepoint(lon, lat, 4326), 32632);

alter table distributori_ add column cod_istat integer;

alter table distributori_ add column cod_pro integer;

alter table distributori_ add column cod_reg integer;

update distributori_ set cod_istat = (select comuni.cod_istat from comuni where st_contains(comuni.geometry, distributori_.geometry));

update distributori_ set cod_pro = (select comuni.cod_pro from comuni where comuni.cod_istat = distributori_.cod_istat);

update distributori_ set cod_reg = (select comuni.cod_reg from comuni where comuni.cod_istat = distributori_.cod_istat);

create table distributori_prezzi_analisi_gasolio (id integer not null primary key serial, id_d integer, dins text, bnd text, name text, data text, day numeric, carb text, prezzo numeric, cod_istat integer, cod_pro integer, cod_reg integer, lat numeric, lon numeric);

insert into distributori_prezzi_analisi_gasolio (id_d, bnd, name, dins, data, day, carb, prezzo, cod_istat, cod_pro, cod_reg, lat, lon) select a.id_d as id_d, b.bnd as bnd, b.name as name, a.dins as dins, a.data as data, a.day as day, a.carb as carb, a.prezzo as prezzo, b.cod_istat as cod_istat, b.cod_pro as cod_pro, b.cod_reg as cod_reg, b.lat as lat, b.lon as lon from tmp_6 as a left join distributori_ as b on (a.id_d = b.id);

create index index_prezzo_gasolio on distributori_prezzi_analisi_gasolio (prezzo);

create index index_cod_pro_gasolio on distributori_prezzi_analisi_gasolio (cod_pro);

create index index_cod_reg_gasolio on distributori_prezzi_analisi_gasolio (cod_reg);

create index index_cod_istat_gasolio on distributori_prezzi_analisi_gasolio (cod_istat);

create index index_data_gasolio on distributori_prezzi_analisi_gasolio (data);

create index index_data_id_d_gasolio on distributori_prezzi_analisi_gasolio (id_d);

select addgeometrycolumn('distributori_prezzi_analisi_gasolio', 'geometry', 32632, 'point', 'xy');

update distributori_prezzi_analisi_gasolio set geometry=st_transform(makepoint(lon, lat, 4326), 32632);

select createspatialindex('distributori_prezzi_analisi_gasolio','geometry');

create table tmp_7 as select distinct id_d, dins, cast(strftime('%y-%m-%d', dins) as text) as data, cast(julianday(strftime('%y-%m-%d', dins)) as numeric) as day, carb, cast(min(prezzo) as numeric) as prezzo from prezzi_, vtmp_1 where carb = 'benzina' and julianday(dins) between vtmp_1.start_analisi and vtmp_1.stop_analisi group by id_d, data, carb order by id_d, data;

create table tmp_8 as select a.id as id, a.id_d as id_d, a.data as data, a.day as day, b.dins as dins, b.carb as carb, b.prezzo as prezzo from tmp_2 as a left join tmp_7 as b using (id_d, day);

create table tmp_9 as select a.id as id_corrente, cast(max(b.id) as integer) as id_precedente from tmp_8 as a, tmp_8 as b where a.id_d = b.id_d and a.day > b.day and b.prezzo is not null group by a.id;

create table tmp_10 as select a.*, b.carb as carburante_precedente, b.prezzo as prezzo_precedente from tmp_8 as a, tmp_8 as b, tmp_9 as c where a.id = c.id_corrente and c.id_precedente = b.id;

update tmp_10 set carb = carburante_precedente, prezzo = prezzo_precedente where prezzo is null and carb is null;

create table distributori_prezzi_analisi_benzina (id integer not null primary key serial, id_d integer, dins text, bnd text, name text, data text, day numeric, carb text, prezzo numeric, cod_istat integer, cod_pro integer, cod_reg integer, lat numeric, lon numeric);

insert into distributori_prezzi_analisi_benzina (id_d, bnd, name, dins, data, day, carb, prezzo, cod_istat, cod_pro, cod_reg, lat, lon) select a.id_d as id_d, b.bnd as bnd, b.name as name, a.dins as dins, a.data as data, a.day as day, a.carb as carb, a.prezzo as prezzo, b.cod_istat as cod_istat, b.cod_pro as cod_pro, b.cod_reg as cod_reg, b.lat as lat, b.lon as lon from tmp_10 as a left join distributori_ as b on (a.id_d = b.id);

create index index_prezzo_benzina on distributori_prezzi_analisi_benzina (prezzo);

create index index_cod_pro_benzina on distributori_prezzi_analisi_benzina (cod_pro);

create index index_cod_reg_benzina on distributori_prezzi_analisi_benzina (cod_reg);

create index index_cod_istat_benzina on distributori_prezzi_analisi_benzina (cod_istat);

create index index_data_benzina on distributori_prezzi_analisi_benzina (data);

create index index_data_id_d_benzina on distributori_prezzi_analisi_benzina (id_d);

select addgeometrycolumn('distributori_prezzi_analisi_benzina', 'geometry', 32632, 'point', 'xy');

update distributori_prezzi_analisi_benzina set geometry=st_transform(makepoint(lon, lat, 4326), 32632);

select createspatialindex('distributori_prezzi_analisi_benzina','geometry');

drop table tmp_1;

drop table tmp_2;

drop table tmp_3;

drop table tmp_4;

drop table tmp_5;

drop table tmp_6;

drop table tmp_7;

drop table tmp_8;

drop table tmp_9;

drop table tmp_10;

drop view vtmp_1;

vacuum;
/* 
- disconnettere scrape
- salvare il db
- creo un buffer su un distributore da analizzare 
- carico lo shape del buffer
- carico lo spatialite in ram
- inserisco limiti amministrativi provinciali e regionali da istat
*/

create view province_gasolio_day as select avg(prezzo), cod_pro from distributori_prezzi_analisi_gasolio where data = '2014-09-01' group by cod_pro;

create view regioni_gasolio_day as select avg(prezzo), cod_reg from distributori_prezzi_analisi_gasolio where data = '2014-09-01' group by cod_reg;

create view comuni_gasolio_day as select avg(prezzo), cod_istat from distributori_prezzi_analisi_gasolio where data = '2014-09-01' group by cod_istat;

create view "province_gasolio_day_spatial" as select "a"."rowid" as "rowid", "a"."pk_uid" as "pk_uid", "a"."cod_pro" as "cod_pro", "a"."geometry" as "geometry", "b"."avg(prezzo)" as "avg(prezzo)" from "province" as "a" join "province_gasolio_day" as "b" on ("a"."cod_pro" = "b"."cod_pro");

create view "regioni_gasolio_day_spatial" as select "a"."rowid" as "rowid", "a"."pk_uid" as "pk_uid", "a"."cod_reg" as "cod_reg", "a"."geometry" as "geometry", "b"."avg(prezzo)" as "avg(prezzo)" from "regioni" as "a" join "regioni_gasolio_day" as "b" on ("a"."cod_reg" = "b"."cod_reg");

create view "comuni_gasolio_day_spatial" as select "a"."rowid" as "rowid", "a"."pk_uid" as "pk_uid", "a"."cod_istat" as "cod_istat", "a"."geometry" as "geometry", "b"."avg(prezzo)" as "avg(prezzo)" from "comuni" as "a" join "comuni_gasolio_day" as "b" on ("a"."cod_istat" = "b"."cod_istat");

insert into "views_geometry_columns"("view_name","view_geometry","view_rowid","f_table_name","f_geometry_column","read_only") values ( 'comuni_gasolio_day_spatial','geometry','rowid','comuni','geometry',1 );

insert into "views_geometry_columns"("view_name","view_geometry","view_rowid","f_table_name","f_geometry_column","read_only") values ( 'province_gasolio_day_spatial','geometry','rowid','province','geometry',1 );

insert into "views_geometry_columns"("view_name","view_geometry","view_rowid","f_table_name","f_geometry_column","read_only") values ( 'regioni_gasolio_day_spatial','geometry','rowid','regioni','geometry',1 );

create table tmp_1 as select distributori_prezzi_analisi_gasolio.* from distributori_prezzi_analisi_gasolio, enercoop_300sec where st_contains(enercoop_300sec.geometry, distributori_prezzi_analisi_gasolio.geometry);

create table tmp_2 as select distinct id_d, name, bnd from tmp_1 order by id_d;

create table tmp_3 as select * from periodo_analisi order by data asc;

create index index_data_tmp_3 on tmp_3 (data);

alter table tmp_3 add column totalerg_5521 duoble;

alter table tmp_3 add column totalerg_5781 numeric;

alter table tmp_3 add column agipeni_7137 numeric;

alter table tmp_3 add column agipeni_8268 numeric;

alter table tmp_3 add column enercoop_10262 numeric;

alter table tmp_3 add column agipeni_12395 numeric;

alter table tmp_3 add column esso_14677 numeric;

alter table tmp_3 add column bentivoglio_17190 numeric;

alter table tmp_3 add column gepoil_17870 numeric;

alter table tmp_3 add column agipeni_21035 numeric;

alter table tmp_3 add column apiip_21449 numeric;

alter table tmp_3 add column q8_23011 numeric;

update tmp_3 set totalerg_5521 = (select distributori_prezzi_analisi_gasolio.prezzo from distributori_prezzi_analisi_gasolio where distributori_prezzi_analisi_gasolio.id_d = 5521 and distributori_prezzi_analisi_gasolio.data = tmp_3.data);

update tmp_3 set totalerg_5781 = (select distributori_prezzi_analisi_gasolio.prezzo from distributori_prezzi_analisi_gasolio where distributori_prezzi_analisi_gasolio.id_d = 5781 and distributori_prezzi_analisi_gasolio.data = tmp_3.data);

update tmp_3 set agipeni_7137 = (select distributori_prezzi_analisi_gasolio.prezzo from distributori_prezzi_analisi_gasolio where distributori_prezzi_analisi_gasolio.id_d = 7137 and distributori_prezzi_analisi_gasolio.data = tmp_3.data);

update tmp_3 set agipeni_8268 = (select distributori_prezzi_analisi_gasolio.prezzo from distributori_prezzi_analisi_gasolio where distributori_prezzi_analisi_gasolio.id_d = 8268 and distributori_prezzi_analisi_gasolio.data = tmp_3.data);

update tmp_3 set enercoop_10262 = (select distributori_prezzi_analisi_gasolio.prezzo from distributori_prezzi_analisi_gasolio where distributori_prezzi_analisi_gasolio.id_d = 10262 and distributori_prezzi_analisi_gasolio.data = tmp_3.data);

update tmp_3 set agipeni_12395 = (select distributori_prezzi_analisi_gasolio.prezzo from distributori_prezzi_analisi_gasolio where distributori_prezzi_analisi_gasolio.id_d = 12395 and distributori_prezzi_analisi_gasolio.data = tmp_3.data);

update tmp_3 set esso_14677 = (select distributori_prezzi_analisi_gasolio.prezzo from distributori_prezzi_analisi_gasolio where distributori_prezzi_analisi_gasolio.id_d = 14677 and distributori_prezzi_analisi_gasolio.data = tmp_3.data);

update tmp_3 set bentivoglio_17190 = (select distributori_prezzi_analisi_gasolio.prezzo from distributori_prezzi_analisi_gasolio where distributori_prezzi_analisi_gasolio.id_d = 17190 and distributori_prezzi_analisi_gasolio.data = tmp_3.data);

update tmp_3 set gepoil_17870 = (select distributori_prezzi_analisi_gasolio.prezzo from distributori_prezzi_analisi_gasolio where distributori_prezzi_analisi_gasolio.id_d = 17870 and distributori_prezzi_analisi_gasolio.data = tmp_3.data);

update tmp_3 set agipeni_21035 = (select distributori_prezzi_analisi_gasolio.prezzo from distributori_prezzi_analisi_gasolio where distributori_prezzi_analisi_gasolio.id_d = 21035 and distributori_prezzi_analisi_gasolio.data = tmp_3.data);

update tmp_3 set apiip_21449 = (select distributori_prezzi_analisi_gasolio.prezzo from distributori_prezzi_analisi_gasolio where distributori_prezzi_analisi_gasolio.id_d = 21449 and distributori_prezzi_analisi_gasolio.data = tmp_3.data);

update tmp_3 set q8_23011 = (select distributori_prezzi_analisi_gasolio.prezzo from distributori_prezzi_analisi_gasolio where distributori_prezzi_analisi_gasolio.id_d = 23011 and distributori_prezzi_analisi_gasolio.data = tmp_3.data);

