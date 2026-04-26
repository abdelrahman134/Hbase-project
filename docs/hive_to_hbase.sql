
-- 1. Create the HBase Bridge Table
DROP TABLE IF EXISTS airbnb.hbase_serving_bridge;

CREATE TABLE airbnb.hbase_serving_bridge (
  row_key                 STRING,
  country                 STRING,
  market                  STRING,
  room_type               STRING,
  property_type           STRING,
  listing_count           BIGINT,
  host_count              BIGINT,
  avg_price               DOUBLE,
  median_price            DOUBLE,
  avg_price_per_guest     DOUBLE,
  avg_rating_stars        DOUBLE,
  avg_review_score        DOUBLE,
  availability_rate_365   DOUBLE,
  booking_pressure_score  DOUBLE,
  superhost_rate          DOUBLE,
  host_verified_rate      DOUBLE,
  total_reviews           INT
)
STORED BY 'org.apache.hadoop.hive.hbase.HBaseStorageHandler'
WITH SERDEPROPERTIES (
  "hbase.columns.mapping" = ":key,info:country,info:market,info:room,info:prop,metrics:list_cnt,metrics:host_cnt,metrics:price,metrics:median,metrics:price_gst,metrics:stars,metrics:score,metrics:avail,metrics:press,metrics:super,metrics:verif,metrics:reviews",
  "hbase.zookeeper.quorum" = "zookeeper",
  "hbase.zookeeper.property.clientPort" = "2181"
)
TBLPROPERTIES (
  "hbase.table.name" = "airbnb_serving_all",
  "hbase.zookeeper.quorum" = "zookeeper",
  "hbase.zookeeper.property.clientPort" = "2181"
);

-- 2. Migration (Move data from Parquet/HDFS to HBase)
-- Note: This triggers a MapReduce job
INSERT INTO TABLE hbase_serving_bridge
SELECT 
    CONCAT(country_code, '_', market, '_', room_type) AS row_key,
    country,
    market,
    room_type,
    property_type,
    listing_count,
    host_count,
    avg_price,
    median_price,
    avg_price_per_guest,
    avg_rating_stars,
    avg_review_score,
    availability_rate_365,
    booking_pressure_score,
    superhost_rate,
    host_verified_rate,
    total_reviews
FROM market_room_type_summary;

-- 3. Verification
SELECT * FROM hbase_serving_bridge LIMIT 10;