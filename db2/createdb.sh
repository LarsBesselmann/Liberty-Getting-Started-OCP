#!/bin/bash
# ============================================================
# createdb.sh – PlantsByWebSphere DB2 initialisation script
#
# This script is executed once after the DB2 engine is up and
# the instance has been created.  It:
#   1. Creates the PLANTSDB database (idempotent – skips if it
#      already exists).
#   2. Applies the schema DDL (tables, primary keys).
#   3. Loads the seed data (customers, inventory, suppliers …).
#
# The official DB2 Community image runs any *.sh / *.sql files
# placed in /var/custom/ after the instance is ready, so this
# file is automatically discovered and executed on first boot.
# ============================================================

set -euo pipefail

DB_NAME="PLANTSDB"
DB_USER="db2inst1"
CUSTOM_DIR="/var/custom"

echo ">>> [createdb.sh] Starting PlantsByWebSphere database initialisation"

# ── Step 1: Create the database ─────────────────────────────
echo ">>> [createdb.sh] Creating database ${DB_NAME} ..."
su - "${DB_USER}" -c "db2 CREATE DATABASE ${DB_NAME} USING CODESET UTF-8 TERRITORY US PAGESIZE 32768" \
  || echo ">>> [createdb.sh] Database ${DB_NAME} may already exist – continuing."

# ── Step 2: Activate and connect ────────────────────────────
echo ">>> [createdb.sh] Activating database ${DB_NAME} ..."
su - "${DB_USER}" -c "db2 ACTIVATE DATABASE ${DB_NAME}"

# ── Step 3: Apply DDL ────────────────────────────────────────
echo ">>> [createdb.sh] Applying schema DDL ..."
su - "${DB_USER}" -c "db2 -td';' -f ${CUSTOM_DIR}/schema_ddl.sql" \
  || echo ">>> [createdb.sh] DDL may have partially applied (objects may exist) – continuing."

# ── Step 4: Load seed data ───────────────────────────────────
echo ">>> [createdb.sh] Loading seed data ..."
su - "${DB_USER}" -c "db2 -td';' -f ${CUSTOM_DIR}/data_dml.sql" \
  || echo ">>> [createdb.sh] Some data rows may already exist – continuing."

echo ">>> [createdb.sh] PlantsByWebSphere database initialisation complete."
