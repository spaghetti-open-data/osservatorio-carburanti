#!/bin/bash

NOW=$(date +"%F")
LOG_NAME="./logs/aggiorna_$NOW.log"
date >> "$LOG_NAME"
psql --host localhost --port 5432 --dbname develope -U postgres < analisi_carburanti_postgresql.sql &>> "$LOG_NAME"
date >> "$LOG_NAME"

