CREATE TABLE "public"."distributori_" (
	"id" smallint,
	"name" varchar(150),
	"bnd" varchar(30),
	"lat" double precision,
	"lon" double precision,
	"addr" varchar(150),
	"comune" varchar(30),
	"provincia" varchar(4));


CREATE TABLE "public"."prezzi_" (
  "id_d" bigint,
  "dIns" date,
  "carb" varchar(20),
  "isSelf" smallint,
  "prezzo" double precision,
  "dScrape" smallint);