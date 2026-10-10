-- ============================================================================
-- 08_native_transfers.sql - Snowflake-only build: live transfer feed without AWS.
-- Creates RAW.LIVE_TRANSFERS (same columns as the Snowpipe target created by
-- aws/setup_aws.py) and APP.SIMULATE_TRANSFERS(N), which inserts synthetic
-- transfer events with the same value ranges and ~10% EXCEPTION rate as
-- aws/publish_transfers.py. Rows are inserted directly; this simulates a transfer
-- feed and is not Snowpipe Streaming.
-- Run before 06_intelligence.sql (the alert reads RAW.LIVE_TRANSFERS).
-- Idempotent: safe to run in the AWS build too.
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS APP;

CREATE TABLE IF NOT EXISTS RAW.LIVE_TRANSFERS (
  CORRIDOR_ID VARCHAR, EVENT_TS TIMESTAMP_NTZ, AMOUNT_PHP FLOAT, SETTLE_SECONDS FLOAT,
  STATUS VARCHAR, SENT_TS TIMESTAMP_NTZ, SOURCE_FILE VARCHAR,
  LOADED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP());

CREATE OR REPLACE PROCEDURE APP.SIMULATE_TRANSFERS(N NUMBER)
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  IF (N < 1 OR N > 1000) THEN
    RETURN 0;
  END IF;
  INSERT INTO RAW.LIVE_TRANSFERS (CORRIDOR_ID, EVENT_TS, AMOUNT_PHP, SETTLE_SECONDS, STATUS, SENT_TS, SOURCE_FILE)
    WITH g AS (
      SELECT 'COR-' || LPAD(UNIFORM(0, 39, RANDOM())::VARCHAR, 4, '0') AS CORRIDOR_ID,
             UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) < 0.1 AS IS_EXCEPTION,
             SYSDATE() AS TS, SEQ4() AS I
      FROM TABLE(GENERATOR(ROWCOUNT => 1000))
    )
    -- NORMAL() needs constant arguments, so the exception offset is applied outside it.
    SELECT CORRIDOR_ID, TS,
           ROUND(IFF(IS_EXCEPTION, 95000, 15000) * EXP(NORMAL(0, 0.5, RANDOM())), 2),
           ROUND(IFF(IS_EXCEPTION, 1800, 20) * EXP(NORMAL(0, 0.4, RANDOM())), 0),
           IFF(IS_EXCEPTION, 'EXCEPTION', 'OK'), TS, 'APP.SIMULATE_TRANSFERS'
    FROM g
    WHERE I < :N;
  RETURN SQLROWCOUNT;
END;
$$;

-- Optional continuous feed for longer demos (suspended; RESUME to start, SUSPEND after).
CREATE OR REPLACE TASK APP.TASK_SIMULATE_TRANSFERS
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '1 MINUTE'
AS
  CALL APP.SIMULATE_TRANSFERS(5);
