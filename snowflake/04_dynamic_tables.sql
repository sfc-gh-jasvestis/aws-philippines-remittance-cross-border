-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for Cross-Border Remittance Analytics & Corridor Intelligence
-- ============================================================================
USE DATABASE REMITTANCE_OPS;
USE SCHEMA CURATED;

-- CORRIDOR_ANALYTICS: Real-time corridor volumes, margins, and success rates
-- Source: CORRIDORS, TRANSACTIONS, FX_RATES
CREATE OR REPLACE DYNAMIC TABLE CURATED.CORRIDOR_ANALYTICS
  TARGET_LAG = '5 minutes'
  WAREHOUSE = REMIT_WH
AS
SELECT * FROM RAW.CORRIDORS;
-- TODO: Replace with actual join/aggregation logic per demo

-- SENDER_BEHAVIOR: Sender patterns: frequency, amounts, preferred channels
-- Source: SENDERS, TRANSACTIONS
CREATE OR REPLACE DYNAMIC TABLE CURATED.SENDER_BEHAVIOR
  TARGET_LAG = '5 minutes'
  WAREHOUSE = REMIT_WH
AS
SELECT * FROM RAW.SENDERS;
-- TODO: Replace with actual join/aggregation logic per demo

-- PAYOUT_PERFORMANCE: Agent network settlement speed and utilization
-- Source: PAYOUT_AGENTS, TRANSACTIONS
CREATE OR REPLACE DYNAMIC TABLE CURATED.PAYOUT_PERFORMANCE
  TARGET_LAG = '5 minutes'
  WAREHOUSE = REMIT_WH
AS
SELECT * FROM RAW.PAYOUT_AGENTS;
-- TODO: Replace with actual join/aggregation logic per demo

-- CORRIDOR_TIMESERIES: Daily corridor volumes for forecasting and anomaly detection
-- Source: TRANSACTIONS, CORRIDORS
CREATE OR REPLACE DYNAMIC TABLE CURATED.CORRIDOR_TIMESERIES
  TARGET_LAG = '5 minutes'
  WAREHOUSE = REMIT_WH
AS
SELECT * FROM RAW.TRANSACTIONS;
-- TODO: Replace with actual join/aggregation logic per demo

