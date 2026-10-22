# ============================================================
# PlantsByWebSphere – DB2 Containerised Database
#
# Builds on top of the official IBM DB2 Community Edition image
# and automatically creates the PLANTSDB database, schema,
# tables, and seed data on first start.
#
# Usage:
#   docker build -t plantsdb-db2 .
#   docker run -d \
#     --name plantsdb-db2 \
#     -p 50000:50000 \
#     -e DB2INST1_PASSWORD=db2password \
#     -e LICENSE=accept \
#     plantsdb-db2
# ============================================================

FROM icr.io/db2_community/db2:latest

# Accept the DB2 license (required at build-time for some layers)
ENV LICENSE=accept

# DB2 instance / database configuration
ENV DB2INST1_PASSWORD=db2password
ENV DBNAME=PLANTSDB

# Copy SQL scripts into the image
COPY schema_ddl.sql /var/custom/schema_ddl.sql
COPY data_dml.sql   /var/custom/data_dml.sql

# Copy the init script that will run after DB2 starts
COPY createdb.sh    /var/custom/createdb.sh
RUN  chmod +x       /var/custom/createdb.sh

# Expose the default DB2 port
EXPOSE 50000

# Use the official entrypoint; the custom script is invoked from createdb.sh
# by mounting it as a pre-start hook via DB2_CUSTOM_INIT_COMPLETE_NOTIFICATION
ENV HADR_ENABLED=false
