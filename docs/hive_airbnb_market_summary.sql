CREATE DATABASE IF NOT EXISTS airbnb;

CREATE EXTERNAL TABLE IF NOT EXISTS airbnb.market_room_type_summary (
  country STRING,
  market STRING,
  room_type STRING,
  property_type STRING,
  listing_count BIGINT,
  host_count BIGINT,
  avg_price DOUBLE,
  median_price DOUBLE,
  avg_price_per_guest DOUBLE,
  avg_rating_stars DOUBLE,
  avg_review_score DOUBLE,
  availability_rate_365 DOUBLE,
  booking_pressure_score DOUBLE,
  superhost_rate DOUBLE,
  host_verified_rate DOUBLE,
  total_reviews INT
)
PARTITIONED BY (country_code STRING)
STORED AS PARQUET
LOCATION '/data/airbnb/analytics/market_room_type_summary';

MSCK REPAIR TABLE airbnb.market_room_type_summary;

SELECT * FROM airbnb.market_room_type_summary LIMIT 5;