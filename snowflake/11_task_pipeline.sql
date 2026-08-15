-- ============================================================================
-- 11_TASK_PIPELINE.SQL — Task DAG for Cross-Border Remittance Analytics & Corridor Intelligence
-- ============================================================================
USE DATABASE REMITTANCE_OPS;
USE SCHEMA APP;

CREATE OR REPLACE TASK APP.TASK_INGEST_TRANSACTIONS
  WAREHOUSE = REMIT_WH
  SCHEDULE = 'USING CRON */5 * * * * UTC'
  COMMENT = 'Ingest streaming transactions from Kinesis'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_UPDATE_CORRIDORS
  WAREHOUSE = REMIT_WH
  AFTER APP.TASK_INGEST_TRANSACTIONS
  COMMENT = 'Refresh corridor analytics with latest transactions'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_DETECT_ANOMALIES
  WAREHOUSE = REMIT_WH
  AFTER APP.TASK_UPDATE_CORRIDORS
  COMMENT = 'Run anomaly detection on corridor volumes'
AS
  SELECT 1; -- Replace with actual refresh logic

ALTER TASK APP.TASK_DETECT_ANOMALIES RESUME;
ALTER TASK APP.TASK_UPDATE_CORRIDORS RESUME;
ALTER TASK APP.TASK_INGEST_TRANSACTIONS RESUME;
