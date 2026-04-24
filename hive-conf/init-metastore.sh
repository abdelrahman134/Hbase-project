#!/usr/bin/env bash
set -e

/opt/hive/bin/schematool -dbType postgres -info || \
  /opt/hive/bin/schematool -dbType postgres -initSchema
