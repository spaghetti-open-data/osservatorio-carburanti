#!/bin/bash

NOW=$(date +"%F")
LOG_NAME="./logs/temp_$NOW.log"
date >> "$LOG_NAME"
psql --host localhost --port 5432 --dbname develope -U postgres < temp.sql &>> "$LOG_NAME"
date >> "$LOG_NAME"

