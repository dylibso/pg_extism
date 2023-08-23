# Use postgres:14 as the base image
FROM postgres:14

RUN mkdir -p /wasm

# Copy content from the specified directories in the working directory to the corresponding locations in the Linux container
COPY /target/release/pg_extism-pg14/usr/lib /usr/lib
COPY /target/release/pg_extism-pg14/usr/share /usr/share

# Create an initialization script
RUN echo "CREATE EXTENSION pg_extism;" > /docker-entrypoint-initdb.d/init.sql

COPY /src/*.wasm /wasm