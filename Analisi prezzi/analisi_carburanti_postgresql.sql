/*
ssh -L 8080:ubuntuServ1204E.cloudapp.net:5432 virtualadmin@ubuntuServ1204E.cloudapp.net

shp2pgsql -W "latin1" -s 32632 -c -g geom -I Com2011_WGS84.shp public.comuni | psql -d develope -U postgres 

shp2pgsql -W "latin1" -s 32632 -c -g geom -I Com2011_WGS84.shp public.province | psql -d develope -U postgres 

shp2pgsql -W "latin1" -s 32632 -c -g geom -I Com2011_WGS84.shp public.regioni | psql -d develope -U postgres 


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

CREATE TABLE calendar (
  data DATE NOT NULL PRIMARY KEY,
  year SMALLINT NOT NULL, -- 2012 to 2038
  month SMALLINT NOT NULL, -- 1 to 12
  day SMALLINT NOT NULL, -- 1 to 31
  quarter SMALLINT NOT NULL, -- 1 to 4
  day_of_week SMALLINT NOT NULL, -- 0 () to 6 ()
  day_of_year SMALLINT NOT NULL, -- 1 to 366
  week_of_year SMALLINT NOT NULL, -- 1 to 53
  CONSTRAINT con_month CHECK (month >= 1 AND month <= 31),
  CONSTRAINT con_day_of_year CHECK (day_of_year >= 1 AND day_of_year <= 366), -- 366 allows for leap years
  CONSTRAINT con_week_of_year CHECK (week_of_year >= 1 AND week_of_year <= 53)
);

INSERT INTO calendar (data, year, month, day, quarter, day_of_week, day_of_year, week_of_year)
(SELECT ts, 
  EXTRACT(YEAR FROM ts),
  EXTRACT(MONTH FROM ts),
  EXTRACT(DAY FROM ts),
  EXTRACT(QUARTER FROM ts),
  EXTRACT(DOW FROM ts),
  EXTRACT(DOY FROM ts),
  EXTRACT(WEEK FROM ts)
  FROM generate_series('2012-01-01'::timestamp, '2038-01-01', '1day'::interval) AS t(ts));

drop table tmp_1;

drop table tmp_2;

drop table tmp_3;

drop table tmp_4;

drop table tmp_5;

drop table tmp_6;

drop table tmp_7;

drop table tmp_8;

drop table distributori_;

drop table prezzi_;

drop table tmp_9;

drop table tmp_10;*/

create table tmp1 as select * from distributori;

update tmp1 set name = replace( name, '"', '' ), addr = replace( addr, '"', '' );

update tmp1 set lat = round(lat, 7), lon = round(lon, 7);

create table distributori_ (id integer not null primary key, addr text, bnd text, comune text, lat numeric, lon numeric, name text, provincia text);

insert into distributori_ (id, addr, bnd, comune, lat, lon, name, provincia) select id, addr, bnd, comune, round(lat, 7) as lat, round(lon, 7) as lon, name, provincia from tmp1 where lat>30 and lon > 6 and lat<48 and lon<19;

create table prezzi_ (id serial primary key, id_d integer, dins timestamp, carb text, isself integer, prezzo numeric, dscrape integer); 

insert into prezzi_ (id_d, dins, carb, isself, prezzo, dscrape) select id_d, dins, carb, isself, prezzo, dscrape from prezzi where prezzo > 0;

create table tmp2 as select cast('2014-07-01' as timestamp) as start_analisi, now()::timestamp::date as stop_analisi;

create table tmp3 as select calendar.data, distributori_.id from distributori_ , calendar, tmp2 where calendar.data >= tmp2.start_analisi and calendar.data <= tmp2.stop_analisi order by distributori_.id, calendar.data;

create table tmp4 (id serial primary key, id_d integer, data timestamp);

insert into tmp4 (id_d, data) select id, data from tmp3;

create table tmp5 as select distinct id_d, dins as dins, carb, min(prezzo) as prezzo from prezzi_, tmp2 where carb = 'Gasolio' and dins >= tmp2.start_analisi and dins <= tmp2.stop_analisi group by id_d, dins, carb order by id_d, dins;

create table tmp6 as select tmp4.id as id, tmp4.id_d as id_d, tmp4.data::timestamp::date as data, tmp5.carb as carb, tmp5.prezzo as prezzo from tmp4 left outer join tmp5 on tmp4.id_d = tmp5.id_d and tmp4.data = tmp5.dins::timestamp::date;

create table tmp7 as select a.id as id_corrente, max(b.id) as id_precedente from tmp6 as a, tmp6 as b where a.id_d = b.id_d and a.data > b.data and b.prezzo is not null group by a.id;

create table tmp8 as select a.*, b.carb as carburante_precedente, b.prezzo as prezzo_precedente from tmp6 as a, tmp6 as b, tmp7 as c where a.id = c.id_corrente and c.id_precedente = b.id;

update tmp8 set carb = carburante_precedente, prezzo = prezzo_precedente where prezzo is null and carb is null;

select addgeometrycolumn('public','distributori_', 'geom', 32632, 'point', 2);

update distributori_ set geom = st_transform(st_setsrid(st_makepoint(lon, lat), 4326),32632);

alter table distributori_ add column cod_istat integer;

alter table distributori_ add column cod_pro integer;

alter table distributori_ add column cod_reg integer;

update distributori_ set cod_istat = (select comuni.cod_istat from comuni where st_contains(comuni.geom, distributori_.geom));

update distributori_ set cod_pro = (select comuni.cod_pro from comuni where comuni.cod_istat = distributori_.cod_istat);

update distributori_ set cod_reg = (select comuni.cod_reg from comuni where comuni.cod_istat = distributori_.cod_istat);

create table distributori_prezzi_analisi_gasolio (id serial primary key, id_d integer, bnd text, name text, data text, carb text, prezzo numeric, cod_istat integer, cod_pro integer, cod_reg integer, lat numeric, lon numeric);

insert into distributori_prezzi_analisi_gasolio (id_d, bnd, name, data, carb, prezzo, cod_istat, cod_pro, cod_reg, lat, lon) select a.id_d as id_d, b.bnd as bnd, b.name as name, a.data as data, a.carb as carb, a.prezzo as prezzo, b.cod_istat as cod_istat, b.cod_pro as cod_pro, b.cod_reg as cod_reg, b.lat as lat, b.lon as lon from tmp6 as a left join distributori_ as b on (a.id_d = b.id);

create index index_prezzo_gasolio on distributori_prezzi_analisi_gasolio (prezzo);

create index index_cod_pro_gasolio on distributori_prezzi_analisi_gasolio (cod_pro);

create index index_cod_reg_gasolio on distributori_prezzi_analisi_gasolio (cod_reg);

create index index_cod_istat_gasolio on distributori_prezzi_analisi_gasolio (cod_istat);

create index index_data_gasolio on distributori_prezzi_analisi_gasolio (data);

create index index_data_id_d_gasolio on distributori_prezzi_analisi_gasolio (id_d);

select addgeometrycolumn('public', 'distributori_prezzi_analisi_gasolio', 'geom', 32632, 'point', 2);

update distributori_prezzi_analisi_gasolio set geom=ST_Transform(ST_SetSRID(ST_MakePoint(lon, lat), 4326),32632);

create index distributori_prezzi_analisi_gasolio_gix on distributori_prezzi_analisi_gasolio using gist (geom);


select createspatialindex('distributori_prezzi_analisi_gasolio','geom');

create table tmp11 as select distinct id_d, dins, cast(strftime('%y-%m-%d', dins) as text) as data, cast(julianday(strftime('%y-%m-%d', dins)) as numeric) as day, carb, cast(min(prezzo) as numeric) as prezzo from prezzi_, vtmp_1 where carb = 'benzina' and julianday(dins) between vtmp_1.start_analisi and vtmp_1.stop_analisi group by id_d, data, carb order by id_d, data;

create table tmp12 as select a.id as id, a.id_d as id_d, a.data as data, a.day as day, b.dins as dins, b.carb as carb, b.prezzo as prezzo from tmp_2 as a left join tmp_7 as b using (id_d, day);

create table tmp13 as select a.id as id_corrente, cast(max(b.id) as integer) as id_precedente from tmp_8 as a, tmp_8 as b where a.id_d = b.id_d and a.day > b.day and b.prezzo is not null group by a.id;

create table tmp14 as select a.*, b.carb as carburante_precedente, b.prezzo as prezzo_precedente from tmp_8 as a, tmp_8 as b, tmp_9 as c where a.id = c.id_corrente and c.id_precedente = b.id;

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











create view province_gasolio_day as select avg(prezzo), cod_pro from distributori_prezzi_analisi_gasolio where data = '2014-09-01' group by cod_pro;

create view regioni_gasolio_day as select avg(prezzo), cod_reg from distributori_prezzi_analisi_gasolio where data = '2014-09-01' group by cod_reg;

create view comuni_gasolio_day as select avg(prezzo), cod_istat from distributori_prezzi_analisi_gasolio where data = '2014-09-01' group by cod_istat;

create view "province_gasolio_day_spatial" as select "a"."rowid" as "rowid", "a"."pk_uid" as "pk_uid", "a"."cod_pro" as "cod_pro", "a"."geometry" as "geometry", "b"."avg(prezzo)" as "avg(prezzo)" from "province" as "a" join "province_gasolio_day" as "b" on ("a"."cod_pro" = "b"."cod_pro");

create view "regioni_gasolio_day_spatial" as select "a"."rowid" as "rowid", "a"."pk_uid" as "pk_uid", "a"."cod_reg" as "cod_reg", "a"."geometry" as "geometry", "b"."avg(prezzo)" as "avg(prezzo)" from "regioni" as "a" join "regioni_gasolio_day" as "b" on ("a"."cod_reg" = "b"."cod_reg");

create view "comuni_gasolio_day_spatial" as select "a"."rowid" as "rowid", "a"."pk_uid" as "pk_uid", "a"."cod_istat" as "cod_istat", "a"."geometry" as "geometry", "b"."avg(prezzo)" as "avg(prezzo)" from "comuni" as "a" join "comuni_gasolio_day" as "b" on ("a"."cod_istat" = "b"."cod_istat");

insert into "views_geometry_columns"("view_name","view_geometry","view_rowid","f_table_name","f_geometry_column","read_only") values ( 'comuni_gasolio_day_spatial','geometry','rowid','comuni','geometry',1 );

insert into "views_geometry_columns"("view_name","view_geometry","view_rowid","f_table_name","f_geometry_column","read_only") values ( 'province_gasolio_day_spatial','geometry','rowid','province','geometry',1 );

insert into "views_geometry_columns"("view_name","view_geometry","view_rowid","f_table_name","f_geometry_column","read_only") values ( 'regioni_gasolio_day_spatial','geometry','rowid','regioni','geometry',1 );
