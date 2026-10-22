#!/bin/bash
# ============================================================
# createdb.sh – PlantsByWebSphere DB2 initialisation script
#
# Placed in /var/custom/ so the official DB2 image entrypoint
# (setup_db2_instance.sh) runs it automatically on EVERY start.
#
# On first boot:  creates the database, APP schema, tables, data.
# On every start: activates the database so clients can connect.
# All CREATE steps are idempotent (errors are caught and ignored).
# ============================================================

set -uo pipefail

DB_NAME="PLANTSDB"
DB_USER="db2inst1"
CUSTOM_DIR="/var/custom"
INIT_FLAG="/database/${DB_NAME}/.plantsdb_initialized"

echo ">>> [createdb.sh] PlantsByWebSphere DB2 initialisation starting ..."

# ── Helper: run SQL as db2inst1 in one connection ────────────
run_sql_file() {
    su - "${DB_USER}" -c "db2 -tvf $1"
}

# ── Step 1: Create the database (first boot only) ────────────
if [ ! -f "${INIT_FLAG}" ]; then
    echo ">>> [createdb.sh] First boot detected – creating database ${DB_NAME} ..."
    su - "${DB_USER}" -c "db2 CREATE DATABASE ${DB_NAME} USING CODESET UTF-8 TERRITORY US PAGESIZE 32768"
else
    echo ">>> [createdb.sh] Database ${DB_NAME} already initialised – skipping CREATE."
fi

# ── Step 2: Activate the database (every boot) ───────────────
# Must happen before any connection attempt (prevents SQLCODE=-1035).
echo ">>> [createdb.sh] Activating database ${DB_NAME} ..."
su - "${DB_USER}" -c "db2 ACTIVATE DATABASE ${DB_NAME}"

# ── Step 3: Create schema + tables + data (first boot only) ──
if [ ! -f "${INIT_FLAG}" ]; then
    echo ">>> [createdb.sh] Creating APP schema and tables ..."

    # Build DDL script: connect → set schema → DDL → disconnect
    # Strip UTF-8 BOM from the DDL file (written by Windows tools)
    DDL_CLEAN=$(mktemp /tmp/run_ddl_XXXXXX.sql)
    {
        echo "CONNECT TO ${DB_NAME};"
        echo "SET CURRENT SCHEMA = APP;"
        sed 's/^\xEF\xBB\xBF//' "${CUSTOM_DIR}/schema_ddl.sql"
        echo "CONNECT RESET;"
    } > "${DDL_CLEAN}"

    run_sql_file "${DDL_CLEAN}" \
        && echo ">>> [createdb.sh] DDL applied successfully." \
        || echo ">>> [createdb.sh] DDL errors above (objects may already exist) – continuing."
    rm -f "${DDL_CLEAN}"

    echo ">>> [createdb.sh] Loading seed data ..."

    # Build DML script: connect → set schema → data inserts → disconnect
    # Strip BOM and any stray SET CURRENT SCHEMA lines from the data file
    DATA_CLEAN=$(mktemp /tmp/run_data_XXXXXX.sql)
    {
        echo "CONNECT TO ${DB_NAME};"
        echo "SET CURRENT SCHEMA = APP;"
        sed 's/^\xEF\xBB\xBF//' "${CUSTOM_DIR}/data_dml.sql" \
            | grep -v 'SET CURRENT SCHEMA'
        echo "CONNECT RESET;"
    } > "${DATA_CLEAN}"

    run_sql_file "${DATA_CLEAN}" \
        && echo ">>> [createdb.sh] Seed data loaded successfully." \
        || echo ">>> [createdb.sh] Data errors above (rows may already exist) – continuing."
    rm -f "${DATA_CLEAN}"

    # Mark initialisation complete so subsequent starts skip CREATE steps
    mkdir -p "$(dirname ${INIT_FLAG})"
    touch "${INIT_FLAG}"
    echo ">>> [createdb.sh] First-boot initialisation complete."
fi

echo ">>> [createdb.sh] Database ${DB_NAME} is active and ready."
