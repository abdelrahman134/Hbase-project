# Hbase-project

Local big-data pipeline for the Airbnb sample collection:

MongoDB Atlas `sample_airbnb.listingsAndReviews` -> Spark -> HDFS Parquet -> Hive handoff -> HBase handoff.

This repo stops at the Spark/Parquet handoff. Hive table creation and HBase loading are documented for the next step, but not executed by the Spark job.

For the full architecture, environment, service roles, and expected Hive/HBase layers, see [docs/architecture.md](docs/architecture.md).

## What Spark Produces

The ingestion job writes three HDFS Parquet datasets:

- Raw copy partitioned by `ingest_date`: `hdfs://namenode:9000/data/airbnb/raw/listingsAndReviews`
- Clean Hive-ready table: `hdfs://namenode:9000/data/airbnb/clean/listings`
- Analytics summary: `hdfs://namenode:9000/data/airbnb/analytics/market_room_type_summary`

The raw dataset keeps the MongoDB document shape as closely as Spark can represent it and stores each run under `ingest_date=YYYY-MM-DD`. The clean dataset flattens stable Airbnb fields, writes Snappy-compressed Parquet, and partitions by `country_code` for Hive. The analytics summary aggregates market, room type, and property type metrics such as median price, price per guest, booking pressure, review quality, and host verification rates.

## Setup

Create a local env file:

```bash
cp env.example .env
```

Edit `.env` and set `MONGODB_URI` to the Atlas URI. Do not commit `.env`.

`AIRBNB_INGEST_DATE` is optional. Leave it empty to use the run date, or set it to a specific `YYYY-MM-DD` value for reproducible backfills.

`AIRBNB_RAW_FULL_REFRESH=true` rewrites the full raw dataset into the partitioned layout. Leave it `false` for normal runs so each run only replaces its own `ingest_date=...` raw partition.

If a real MongoDB password has ever been pasted into chat or committed to Git, rotate it in MongoDB Atlas before sharing the repo.

## Run

Start the minimum services for ingestion:

```bash
docker compose up -d
```

Run the notebook-backed Spark job:

```bash
docker compose run --rm airbnb-ingest
```

Compose executes `notebooks/mongo_airbnb_to_parquet.ipynb` with `jupyter nbconvert`, so the same notebook can also be opened from the `jupyter` service for development.

Optional services for teammate work:

```bash
docker compose --profile hive up -d
docker compose --profile hbase up -d
docker compose --profile dev up -d jupyter
```

Profiles keep optional tools out of the default startup path. The default stack is only HDFS and Spark; the `jobs` profile is used internally by the one-shot `airbnb-ingest` service when you run it directly.

## Verify Outputs

Check HDFS paths:

```bash
docker compose exec namenode hdfs dfs -ls /data/airbnb/raw/listingsAndReviews
docker compose exec namenode hdfs dfs -ls /data/airbnb/raw/listingsAndReviews/ingest_date=$(date +%F)
docker compose exec namenode hdfs dfs -ls /data/airbnb/clean/listings
docker compose exec namenode hdfs dfs -ls /data/airbnb/analytics/market_room_type_summary
```

Check the clean Parquet row count from Spark:

```bash
docker compose run --rm airbnb-ingest pyspark --master spark://spark-master:7077
```

Then run:

```python
spark.read.parquet("hdfs://namenode:9000/data/airbnb/clean/listings").count()
```

## Hive Handoff

The Hive external-table SQL files are:

- `docs/hive_airbnb_clean.sql`
- `docs/hive_airbnb_market_summary.sql`

After the Spark job finishes, your coworker can run that SQL in Hive. The table points at:

```text
/data/airbnb/clean/listings
```

Because the clean output is partitioned by `country_code`, run:

```sql
MSCK REPAIR TABLE airbnb.listings_clean;
```

## Notes

- MongoDB is read with the official MongoDB Spark Connector package.
- The connector package defaults to `org.mongodb.spark:mongo-spark-connector_2.12:10.2.2` and can be overridden with `MONGO_SPARK_CONNECTOR_PACKAGE`.
- Spark uses adaptive query execution, Kryo serialization, compressed shuffles, and Snappy Parquet compression.
- The clean output is intentionally simple and scalar-heavy so Hive can query it easily and HBase loading can choose row keys/column families later.
