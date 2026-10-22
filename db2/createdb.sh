#!/bin/bash
# ============================================================
# createdb.sh – PlantsByWebSphere DB2 initialisation script
#
# This script is executed once after the DB2 engine is up and
# the instance has been created.  It:
#   1. Creates the PLANTSDB database (idempotent – skips if
#      it already exists).
#   2. Creates the APP schema inside PLANTSDB.
#   3. Applies the DDL (tables, primary keys) under APP schema.
#   4. Loads the seed data under APP schema.
#
# The official DB2 Community image automatically runs *.sh files
# placed in /var/custom/ after the instance is ready.
# ============================================================

set -uo pipefail

DB_NAME="PLANTSDB"
DB_USER="db2inst1"
CUSTOM_DIR="/var/custom"

echo ">>> [createdb.sh] Starting PlantsByWebSphere database initialisation"

# ── Step 1: Create the database ─────────────────────────────
echo ">>> [createdb.sh] Creating database ${DB_NAME} ..."
su - "${DB_USER}" -c "db2 CREATE DATABASE ${DB_NAME} USING CODESET UTF-8 TERRITORY US PAGESIZE 32768" \
  || echo ">>> [createdb.sh] Database ${DB_NAME} may already exist – continuing."

# ── Step 2: Create APP schema ────────────────────────────────
# Each db2 CLP invocation is its own connection; SET CURRENT SCHEMA
# only persists for the lifetime of that connection.  We therefore
# build a single inline script that connects, sets the schema, and
# runs all DDL in one shot.
echo ">>> [createdb.sh] Creating APP schema ..."
su - "${DB_USER}" -c "
  db2 -v CONNECT TO ${DB_NAME}
  db2 -v \"CREATE SCHEMA APP\" || true
  db2 -v CONNECT RESET
"

# ── Step 3: Apply DDL under APP schema ───────────────────────
# Write a wrapper script that connects, sets schema, then runs DDL.
echo ">>> [createdb.sh] Applying schema DDL ..."
cat > /tmp/run_ddl.sql <<'ENDSQL'
CONNECT TO PLANTSDB;
SET CURRENT SCHEMA = APP;
ENDSQL
cat "${CUSTOM_DIR}/schema_ddl.sql" >> /tmp/run_ddl.sql
echo "CONNECT RESET;" >> /tmp/run_ddl.sql

su - "${DB_USER}" -c "db2 -tvf /tmp/run_ddl.sql" \
  || echo ">>> [createdb.sh] DDL may have partially applied (objects may exist) – continuing."

# ── Step 4: Load seed data under APP schema ──────────────────
echo ">>> [createdb.sh] Loading seed data ..."

# Strip UTF-8 BOM if present (written by Windows tools)
sed 's/^\xEF\xBB\xBF//' "${CUSTOM_DIR}/data_dml.sql" > /tmp/data_clean.sql

# Build wrapper: connect + set schema + data inserts
cat > /tmp/run_data.sql <<'ENDSQL'
CONNECT TO PLANTSDB;
SET CURRENT SCHEMA = APP;
ENDSQL
# Skip any SET CURRENT SCHEMA line already in the data file (handled above)
grep -v 'SET CURRENT SCHEMA' /tmp/data_clean.sql >> /tmp/run_data.sql
echo "CONNECT RESET;" >> /tmp/run_data.sql

su - "${DB_USER}" -c "db2 -tvf /tmp/run_data.sql" \
  || echo ">>> [createdb.sh] Some data rows may already exist – continuing."

echo ">>> [createdb.sh] PlantsByWebSphere database initialisation complete."
