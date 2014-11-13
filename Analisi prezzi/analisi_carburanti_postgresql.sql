/*
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 5432
sudo ufw allow 8080
sudo ufw enable

ssh -L 8080:ubuntuServ1204E.cloudapp.net:5432 virtualadmin@ubuntuServ1204E.cloudapp.net

nohup comando &

shp2pgsql -W "latin1" -s 32632 -c -g geom -I Com2011_WGS84.shp public.comuni | psql -d develope -U postgres 

shp2pgsql -W "latin1" -s 32632 -c -g geom -I Com2011_WGS84.shp public.comuni | '/Applications/Postgres.app/Contents/Versions/9.3/bin'/psql -d lorenzo -U lorenzo 

shp2pgsql -W "latin1" -s 32632 -c -g geom -I Prov2011_WGS84.shp public.province | psql -d develope -U postgres 

shp2pgsql -W "latin1" -s 32632 -c -g geom -I Prov2011_WGS84.shp public.province | '/Applications/Postgres.app/Contents/Versions/9.3/bin'/psql -d lorenzo -U lorenzo 

shp2pgsql -W "latin1" -s 32632 -c -g geom -I Reg2011_WGS84.shp public.regioni | psql -d develope -U postgres 

shp2pgsql -W "latin1" -s 32632 -c -g geom -I Reg2011_WGS84.shp public.regioni | '/Applications/Postgres.app/Contents/Versions/9.3/bin'/psql -d lorenzo -U lorenzo 



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

create index index_data_calendar on calendar (data);
*/

drop table if exists tmp1 cascade;

drop table if exists tmp2 cascade;

drop table if exists tmp3 cascade;

drop table if exists tmp4 cascade;

drop table if exists tmp5 cascade;

drop table if exists tmp6 cascade;

drop table if exists tmp7 cascade;

drop table if exists tmp8 cascade;

drop table if exists tmp9 cascade;

drop table if exists tmp10 cascade;

drop table if exists tmp11 cascade;

drop table if exists tmp12 cascade;

drop table if exists tmp11 cascade;

drop table if exists tmp12 cascade;

drop table if exists tmp13 cascade;

drop table if exists tmp14 cascade;

drop table if exists tmp15 cascade;

drop table if exists distributori_ cascade;

drop table if exists prezzi_ cascade;

drop table if exists distributori_prezzi_analisi_gasolio cascade;

drop table if exists distributori_prezzi_analisi_benzina cascade;

drop table if exists distributori_prezzi_analisi_gasolio_today;

drop table if exists distributori_prezzi_analisi_benzina_today;

drop table if exists comuni_prezzo_medio_gasolio_today cascade;

drop table if exists province_prezzo_medio_gasolio_today cascade;

drop table if exists regioni_prezzo_medio_gasolio_today cascade;

drop table if exists comuni_prezzo_medio_benzina_today cascade;

drop table if exists province_prezzo_medio_benzina_today cascade;

drop table if exists regioni_prezzo_medio_benzina_today cascade;

drop table if exists comuni_prezzo_medio_gasolio_today_spatial cascade;

drop table if exists province_prezzo_medio_gasolio_today_spatial cascade;

drop table if exists regioni_prezzo_medio_gasolio_today_spatial cascade;

drop table if exists comuni_prezzo_medio_benzina_today_spatial cascade;

drop table if exists province_prezzo_medio_benzina_today_spatial cascade;

drop table if exists regioni_prezzo_medio_benzina_today_spatial cascade;

/*
drop table if exists distributori_prezzi_massimi_benzina_comune cascade;

drop table if exists distributori_prezzi_massimi_gasolio_comune cascade;

drop table if exists distributori_prezzi_minimi_benzina_comune cascade;

drop table if exists distributori_prezzi_minimi_gasolio_comune cascade;

drop table if exists distributori_prezzi_massimi_benzina_provincia cascade;

drop table if exists distributori_prezzi_massimi_gasolio_provincia cascade;

drop table if exists distributori_prezzi_minimi_benzina_provincia cascade;

drop table if exists distributori_prezzi_minimi_gasolio_provincia cascade;

drop table if exists distributori_prezzi_massimi_benzina_regione cascade;

drop table if exists distributori_prezzi_massimi_gasolio_regione cascade;

drop table if exists distributori_prezzi_minimi_benzina_regione cascade;

drop table if exists distributori_prezzi_minimi_gasolio_regione cascade;
*/

create table tmp1 as select * from distributori;

update tmp1 set name = replace( name, '"', '' ), addr = replace( addr, '"', '' );

update tmp1 set lat = round(lat, 7), lon = round(lon, 7);

/* attenzione ai distributori costieri, molti sono al di fuori dei poligoni ISTAT dei comuni */

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

create table tmp8 as select a.*, b.carb as carburante_precedente, b.prezzo as prezzo_precedente from tmp6 as a left outer join tmp7 on a.id = tmp7.id_corrente left outer join tmp6 as b on b.id = tmp7.id_precedente order by id_d, data;

update tmp8 set carb = carburante_precedente, prezzo = prezzo_precedente where prezzo is null and carb is null;

select addgeometrycolumn('public','distributori_', 'geom', 32632, 'point', 2);

update distributori_ set geom = st_transform(st_setsrid(st_makepoint(lon, lat), 4326),32632);

alter table distributori_ add column cod_istat integer;

alter table distributori_ add column cod_pro integer;

alter table distributori_ add column cod_reg integer;

update distributori_ set cod_istat = (select comuni.cod_istat from comuni where st_contains(comuni.geom, distributori_.geom));

update distributori_ set cod_pro = (select comuni.cod_pro from comuni where comuni.cod_istat = distributori_.cod_istat);

update distributori_ set cod_reg = (select comuni.cod_reg from comuni where comuni.cod_istat = distributori_.cod_istat);

create table distributori_prezzi_analisi_gasolio (id serial primary key, id_d integer, bnd text, name text, data timestamp, carb text, prezzo numeric, cod_istat integer, cod_pro integer, cod_reg integer, lat numeric, lon numeric);

insert into distributori_prezzi_analisi_gasolio (id_d, bnd, name, data, carb, prezzo, cod_istat, cod_pro, cod_reg, lat, lon) select a.id_d as id_d, b.bnd as bnd, b.name as name, a.data::timestamp::date as data, a.carb as carb, a.prezzo as prezzo, b.cod_istat as cod_istat, b.cod_pro as cod_pro, b.cod_reg as cod_reg, b.lat as lat, b.lon as lon from tmp8 as a left join distributori_ as b on (a.id_d = b.id) where prezzo is not null order by id_d, data;

create index index_prezzo_gasolio on distributori_prezzi_analisi_gasolio (prezzo);

create index index_cod_pro_gasolio on distributori_prezzi_analisi_gasolio (cod_pro);

create index index_cod_reg_gasolio on distributori_prezzi_analisi_gasolio (cod_reg);

create index index_cod_istat_gasolio on distributori_prezzi_analisi_gasolio (cod_istat);

create index index_data_gasolio on distributori_prezzi_analisi_gasolio (data);

create index index_data_id_d_gasolio on distributori_prezzi_analisi_gasolio (id_d);

select addgeometrycolumn('public', 'distributori_prezzi_analisi_gasolio', 'geom', 32632, 'point', 2);

update distributori_prezzi_analisi_gasolio set geom=st_transform(st_setsrid(st_makepoint(lon, lat), 4326),32632);

create index distributori_prezzi_analisi_gasolio_gix on distributori_prezzi_analisi_gasolio using gist (geom);

create table tmp9 as select distinct id_d, dins as dins, carb, min(prezzo) as prezzo from prezzi_, tmp2 where carb = 'Benzina' and dins >= tmp2.start_analisi and dins <= tmp2.stop_analisi group by id_d, dins, carb order by id_d, dins;

create table tmp10 as select tmp4.id as id, tmp4.id_d as id_d, tmp4.data::timestamp::date as data, tmp9.carb as carb, tmp9.prezzo as prezzo from tmp4 left outer join tmp9 on tmp4.id_d = tmp9.id_d and tmp4.data = tmp9.dins::timestamp::date;

create table tmp11 as select a.id as id_corrente, max(b.id) as id_precedente from tmp10 as a, tmp10 as b where a.id_d = b.id_d and a.data > b.data and b.prezzo is not null group by a.id;

create table tmp12 as select a.*, b.carb as carburante_precedente, b.prezzo as prezzo_precedente from tmp10 as a left outer join tmp11 on a.id = tmp11.id_corrente left outer join tmp10 as b on b.id = tmp11.id_precedente order by id_d, data;;

update tmp12 set carb = carburante_precedente, prezzo = prezzo_precedente where prezzo is null and carb is null;

create table distributori_prezzi_analisi_benzina (id serial primary key, id_d integer, bnd text, name text, data timestamp, day numeric, carb text, prezzo numeric, cod_istat integer, cod_pro integer, cod_reg integer, lat numeric, lon numeric);

insert into distributori_prezzi_analisi_benzina (id_d, bnd, name, data, carb, prezzo, cod_istat, cod_pro, cod_reg, lat, lon) select a.id_d as id_d, b.bnd as bnd, b.name as name, a.data::timestamp::date as data, a.carb as carb, a.prezzo as prezzo, b.cod_istat as cod_istat, b.cod_pro as cod_pro, b.cod_reg as cod_reg, b.lat as lat, b.lon as lon from tmp12 as a left join distributori_ as b on (a.id_d = b.id) where prezzo is not null order by id_d, data;

create index index_prezzo_benzina on distributori_prezzi_analisi_benzina (prezzo);

create index index_cod_pro_benzina on distributori_prezzi_analisi_benzina (cod_pro);

create index index_cod_reg_benzina on distributori_prezzi_analisi_benzina (cod_reg);

create index index_cod_istat_benzina on distributori_prezzi_analisi_benzina (cod_istat);

create index index_data_benzina on distributori_prezzi_analisi_benzina (data);

create index index_data_id_d_benzina on distributori_prezzi_analisi_benzina (id_d);

select addgeometrycolumn('public', 'distributori_prezzi_analisi_benzina', 'geom', 32632, 'point', 2);

update distributori_prezzi_analisi_benzina set geom=st_transform(st_setsrid(st_makepoint(lon, lat), 4326),32632);

create index distributori_prezzi_analisi_benzina_gix on distributori_prezzi_analisi_benzina using gist (geom);

create table distributori_prezzi_analisi_benzina_today as select id_d, bnd, name, data, carb, prezzo, cod_istat, cod_pro, cod_reg, lat, lon, geom from distributori_prezzi_analisi_benzina where distributori_prezzi_analisi_benzina.data = NOW()::timestamp::date;

create index distributori_prezzi_analisi_benzina_today_gix on distributori_prezzi_analisi_benzina_today using gist (geom);

create table distributori_prezzi_analisi_gasolio_today as select id_d, bnd, name, data, carb, prezzo, cod_istat, cod_pro, cod_reg, lat, lon, geom from distributori_prezzi_analisi_gasolio where data = NOW()::timestamp::date;

create index distributori_prezzi_analisi_gasolio_today_gix on distributori_prezzi_analisi_gasolio_today using gist (geom);

create table province_prezzo_medio_gasolio_today as select a.cod_pro, b.nome, round(avg(a.prezzo), 3) as prezzo_medio from distributori_prezzi_analisi_gasolio as a, province as b where data = cast((NOW()::timestamp::date) as timestamp) and a.cod_pro = b.cod_pro group by a.cod_pro, b.nome;

create index index_cod_pro_province_prezzo_medio_gasolio_today on province_prezzo_medio_gasolio_today (cod_pro);

create index index_prezzo_province_prezzo_medio_gasolio_today on province_prezzo_medio_gasolio_today (prezzo_medio);

create table regioni_prezzo_medio_gasolio_today as select a.cod_reg, b.nome, round(avg(a.prezzo), 3) as prezzo_medio from distributori_prezzi_analisi_gasolio as a, regioni as b where data = cast((NOW()::timestamp::date) as timestamp) and a.cod_reg = b.cod_reg group by a.cod_reg, b.nome;

create index index_cod_reg_regioni_prezzo_medio_gasolio_today on regioni_prezzo_medio_gasolio_today (cod_reg);

create index index_prezzo_regioni_prezzo_medio_gasolio_today on regioni_prezzo_medio_gasolio_today (prezzo_medio);

create table comuni_prezzo_medio_gasolio_today as select a.cod_istat, b.nome, round(avg(a.prezzo), 3) as prezzo_medio from distributori_prezzi_analisi_gasolio as a, comuni as b where data = cast((NOW()::timestamp::date) as timestamp) and a.cod_istat = b.cod_istat group by a.cod_istat, b.nome;

create index index_cod_istat_comuni_prezzo_medio_gasolio_today on comuni_prezzo_medio_gasolio_today (cod_istat);

create index index_prezzo_comuni_prezzo_medio_gasolio_today on comuni_prezzo_medio_gasolio_today (prezzo_medio);

create table province_prezzo_medio_gasolio_today_spatial as select a.cod_pro, a.nome, a.geom, b.prezzo_medio as prezzo_medio from province as a join province_prezzo_medio_gasolio_today as b on (a.cod_pro = b.cod_pro);

create index province_prezzo_medio_gasolio_today_spatial_gix on province_prezzo_medio_gasolio_today_spatial using gist (geom);

create index index_cod_pro_province_prezzo_medio_gasolio_today_spatial on province_prezzo_medio_gasolio_today_spatial (cod_pro);

create index index_prezzo_province_prezzo_medio_gasolio_today_spatial on province_prezzo_medio_gasolio_today_spatial (prezzo_medio);

alter table province_prezzo_medio_gasolio_today_spatial add primary key (cod_pro);

create table regioni_prezzo_medio_gasolio_today_spatial as select a.cod_reg, a.nome, a.geom, b.prezzo_medio as prezzo_medio from regioni as a join regioni_prezzo_medio_gasolio_today as b on (a.cod_reg = b.cod_reg);

create index regioni_prezzo_medio_gasolio_today_spatial_gix on regioni_prezzo_medio_gasolio_today_spatial using gist (geom);

create index index_cod_reg_regioni_prezzo_medio_gasolio_today_spatial on regioni_prezzo_medio_gasolio_today_spatial (cod_reg);

create index index_prezzo_regioni_prezzo_medio_gasolio_today_spatial on regioni_prezzo_medio_gasolio_today_spatial (prezzo_medio);

alter table regioni_prezzo_medio_gasolio_today_spatial add primary key (cod_reg);

create table comuni_prezzo_medio_gasolio_today_spatial as select a.cod_istat, a.nome, a.geom, b.prezzo_medio as prezzo_medio from comuni as a join comuni_prezzo_medio_gasolio_today as b on (a.cod_istat = b.cod_istat);

create index comuni_prezzo_medio_gasolio_today_spatial_gix on comuni_prezzo_medio_gasolio_today_spatial using gist (geom);

create index index_cod_istat_comuni_prezzo_medio_gasolio_today_spatial on comuni_prezzo_medio_gasolio_today_spatial (cod_istat);

create index index_prezzo_comuni_prezzo_medio_gasolio_today_spatial on comuni_prezzo_medio_gasolio_today_spatial (prezzo_medio);

alter table comuni_prezzo_medio_gasolio_today_spatial add primary key (cod_istat);

create table province_prezzo_medio_benzina_today as select avg(a.prezzo) as prezzo_medio, a.cod_pro, b.nome from distributori_prezzi_analisi_benzina as a, province as b where data = cast((NOW()::timestamp::date) as timestamp) and a.cod_pro = b.cod_pro group by a.cod_pro, b.nome;

create index index_cod_pro_province_prezzo_medio_benzina_today on province_prezzo_medio_benzina_today (cod_pro);

create index index_prezzo_province_prezzo_medio_benzina_today on province_prezzo_medio_benzina_today (prezzo_medio);

create table regioni_prezzo_medio_benzina_today as select avg(a.prezzo) as prezzo_medio, a.cod_reg, b.nome from distributori_prezzi_analisi_benzina as a, regioni as b where data = cast((NOW()::timestamp::date) as timestamp) and a.cod_reg = b.cod_reg group by a.cod_reg, b.nome;

create index index_cod_reg_regioni_prezzo_medio_benzina_today on regioni_prezzo_medio_benzina_today (cod_reg);

create index index_prezzo_rregioni_prezzo_medio_benzina_today on regioni_prezzo_medio_benzina_today (prezzo_medio);

create table comuni_prezzo_medio_benzina_today as select avg(a.prezzo) as prezzo_medio, a.cod_istat, b.nome from distributori_prezzi_analisi_benzina as a, comuni as b where data = cast((NOW()::timestamp::date) as timestamp) and a.cod_istat = b.cod_istat group by a.cod_istat, b.nome;

create index index_cod_istat_comuni_prezzo_medio_benzina_today on comuni_prezzo_medio_benzina_today (cod_istat);

create index index_prezzo_comuni_prezzo_medio_benzina_today on comuni_prezzo_medio_benzina_today (prezzo_medio);

create table province_prezzo_medio_benzina_today_spatial as select a.cod_pro, a.nome, a.geom, b.prezzo_medio as prezzo_medio from province as a join province_prezzo_medio_benzina_today as b on (a.cod_pro = b.cod_pro);

create index province_prezzo_medio_benzina_today_spatial_gix on province_prezzo_medio_benzina_today_spatial using gist (geom);

create index index_cod_pro_province_prezzo_medio_benzina_today_spatial on province_prezzo_medio_benzina_today_spatial (cod_pro);

create index index_prezzo_province_prezzo_medio_benzina_today_spatial on province_prezzo_medio_benzina_today_spatial (prezzo_medio);

alter table province_prezzo_medio_benzina_today_spatial add primary key (cod_pro);

create table regioni_prezzo_medio_benzina_today_spatial as select a.cod_reg, a.nome, a.geom, b.prezzo_medio as prezzo_medio from regioni as a join regioni_prezzo_medio_benzina_today as b on (a.cod_reg = b.cod_reg);

create index regioni_prezzo_medio_benzina_today_spatial_gix on regioni_prezzo_medio_benzina_today_spatial using gist (geom);

create index index_cod_reg_regioni_prezzo_medio_benzina_today_spatial on regioni_prezzo_medio_benzina_today_spatial (cod_reg);

create index index_prezzo_regioni_prezzo_medio_benzina_today_spatial on regioni_prezzo_medio_benzina_today_spatial (prezzo_medio);

alter table regioni_prezzo_medio_benzina_today_spatial add primary key (cod_reg);

create table comuni_prezzo_medio_benzina_today_spatial as select a.cod_istat, a.nome, a.geom, b.prezzo_medio as prezzo_medio from comuni as a join comuni_prezzo_medio_benzina_today as b on (a.cod_istat = b.cod_istat);

create index comuni_prezzo_medio_benzina_today_spatial_gix on comuni_prezzo_medio_benzina_today_spatial using gist (geom);

create index index_cod_istat_comuni_prezzo_medio_benzina_today_spatial on comuni_prezzo_medio_benzina_today_spatial (cod_istat);

create index index_prezzo_comuni_prezzo_medio_benzina_today_spatial on comuni_prezzo_medio_benzina_today_spatial (prezzo_medio);

alter table comuni_prezzo_medio_benzina_today_spatial add primary key (cod_istat);

/* utilità dei valori minimi massimi dubbia
create table tmp13 AS select cod_istat, max(prezzo) as prezzo_massimo from distributori_prezzi_analisi_gasolio where data = now()::timestamp::date group by cod_istat;

create table distributori_prezzi_massimi_gasolio_comune_spatial as select distinct a.cod_istat as cod_istat, a.id_d as id_d, a.bnd as bnd, a.name as name, a.carb as carb, a.prezzo as prezzo, a.geom from distributori_prezzi_analisi_gasolio as a, tmp13 as b where a.cod_istat = b.cod_istat and a.prezzo = b.prezzo_massimo;

alter table distributori_prezzi_massimi_gasolio_comune_spatial add primary key (id_d);

create index distributori_prezzi_massimi_gasolio_comune_spatial_gix on distributori_prezzi_massimi_gasolio_comune_spatial using gist (geom);

create table tmp14 AS select cod_istat, max(prezzo) as prezzo_massimo from distributori_prezzi_analisi_benzina where data = now()::timestamp::date group by cod_istat;

create table distributori_prezzi_massimi_benzina_comune_spatial as select distinct a.cod_istat as cod_istat, a.id_d as id_d, a.bnd as bnd, a.name as name, a.carb as carb, a.prezzo as prezzo, a.geom from distributori_prezzi_analisi_benzina as a, tmp14 as b where a.cod_istat = b.cod_istat and a.prezzo = b.prezzo_massimo;

alter table distributori_prezzi_massimi_benzina_comune_spatial add primary key (id_d);

create index distributori_prezzi_massimi_benzina_comune_spatial_gix on distributori_prezzi_massimi_benzina_comune_spatial using gist (geom);

create table tmp15 AS select cod_istat, min(prezzo) as prezzo_minimo from distributori_prezzi_analisi_gasolio where data = now()::timestamp::date group by cod_istat;

create table distributori_prezzi_minimi_gasolio_comune_spatial as select distinct a.cod_istat as cod_istat, a.id_d as id_d, a.bnd as bnd, a.name as name, a.carb as carb, a.prezzo as prezzo, a.geom from distributori_prezzi_analisi_gasolio as a, tmp15 as b where a.cod_istat = b.cod_istat and a.prezzo = b.prezzo_minimo;

alter table distributori_prezzi_minimi_gasolio_comune_spatial add primary key (id_d);

create index distributori_prezzi_minimi_gasolio_comune_spatial_gix on distributori_prezzi_minimi_gasolio_comune_spatial using gist (geom);
*/

















