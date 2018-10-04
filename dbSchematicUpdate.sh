#!/bin/bash
# ===========================================================================================================================

# Author: Vikrant Dhimate
# Create date: 20-09-2018
# Description: For deploying all database changes (Optional script to avoid reboot)

# ===========================================================================================================================

set schema 'crm-core'
psql -U postgres -d cidb -c 'create extension if not exists \"uuid-ossp\"'

for file in "/ci/db/schematic/crm-core"/*
do
  PGOPTIONS='-c search_path=crm-core,public -c ROLE=crm-core_owner' psql -1 -U postgres -f "$file" --set ON_ERROR_STOP=1 cidb
  echo "-- $file --"
done
