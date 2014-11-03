CREATE TABLE "public"."distributori_" (
	"id" integer,
	"name" text,
	"bnd" text,
	"lat" numeric,
	"lon" numeric,
	"addr" text,
	"comune" text,
	"provincia" text);


CREATE TABLE "public"."prezzi_" (
  "id_d" bigint,
  "dins" timestamp,
  "carb" text,
  "isself" integer,
  "prezzo" numeric,
  "dscrape" bigint);