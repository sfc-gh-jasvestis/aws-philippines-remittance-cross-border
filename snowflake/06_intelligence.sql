-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-transfer alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes checked __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05, plus 08 (Snowflake only) or
-- aws/setup_aws.py (AWS build) for RAW.LIVE_TRANSFERS.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic exception-handling knowledge base (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.EXCEPTION_DOCS AS
WITH types AS (
  SELECT DISTINCT r.EXCEPTION_TYPE, a.CATEGORY
  FROM RAW.CORRIDOR_DAILY r JOIN RAW.CORRIDORS a ON a.ID = r.ENTITY_ID
  WHERE r.FAILED_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, EXCEPTION_TYPE)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  EXCEPTION_TYPE,
  CATEGORY || ' - ' || EXCEPTION_TYPE || ' exception handling' AS TITLE,
  'Synthetic demo SOP. Send market: ' || CATEGORY || '. Exception type: ' || EXCEPTION_TYPE || '. '
  || 'Step 1: open an exception case, link the transfer reference and hold further payouts on the corridor above the corridor limit until the case is triaged. '
  || 'Step 2: ' || CASE
       WHEN EXCEPTION_TYPE = 'Sanctions screening hit' THEN 'compare the matched sender or beneficiary name, date of birth and location against the screening list entry, and escalate to the compliance officer before releasing the payout.'
       WHEN EXCEPTION_TYPE = 'AML hold' THEN 'review the sender and beneficiary profiles, the stated purpose of the transfer and the last 30 days of corridor activity, and refer unexplained patterns to the financial crime team.'
       WHEN EXCEPTION_TYPE = 'Beneficiary name mismatch' THEN 'confirm the beneficiary name with the sending partner and the sender, and return the transfer to the sender if it cannot be confirmed within the payout window.'
       WHEN EXCEPTION_TYPE = 'Cash pickup not collected' THEN 'send a pickup reminder to the beneficiary, confirm the pickup branch is open, and return the transfer to the sender if it is not collected within the holding period.'
       WHEN EXCEPTION_TYPE = 'Wallet credit rejected' THEN 'check the mobile number and wallet status with the wallet partner, ask the sender to confirm the number, and re-route the payout to cash pickup or bank credit if the wallet stays unavailable.'
       WHEN EXCEPTION_TYPE = 'Bank account closed' THEN 'confirm the account status with the receiving bank, ask the sender for a new account or payout method, and return the transfer if no instruction arrives before the cut-off.'
       WHEN EXCEPTION_TYPE = 'Prefunding shortfall' THEN 'check the projected prefunding balance at the payout partner, request a treasury top-up, and release queued payouts in order of transfer date.'
       ELSE 'review the exception against the corridor profile and escalate if unexplained.'
     END
  || ' Step 3: if the screening hit rate on the corridor exceeds 5% or average time to payout exceeds 45 minutes after triage, keep the case open and request a corridor review. '
  || 'Step 4: record the resolution; if the transfer failed or breached its payout SLA, notify the sending partner and log the breach for the operations report.' AS CONTENT
FROM types;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.EXCEPTION_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, EXCEPTION_TYPE
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, EXCEPTION_TYPE, CONTENT FROM SEARCH.EXCEPTION_DOCS);

-- ---------- Screening hit rate anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.SCREENING_HIT_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, SCREENING_HIT_PCT::FLOAT AS SCREENING_HIT
FROM RAW.CORRIDOR_DAILY;
CREATE OR REPLACE VIEW ML.SCREENING_HIT_TRAIN AS
SELECT * FROM ML.SCREENING_HIT_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.SCREENING_HIT_SERIES);
CREATE OR REPLACE VIEW ML.SCREENING_HIT_DETECT AS
SELECT * FROM ML.SCREENING_HIT_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.SCREENING_HIT_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.SCREENING_HIT_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.SCREENING_HIT_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'SCREENING_HIT',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.SCREENING_HIT_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS SCREENING_HIT, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.SCREENING_HIT_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.SCREENING_HIT_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'SCREENING_HIT'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.REMITTANCE_ANALYTICS
  TABLES (
    corridors AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      COMMENT = 'One row per remittance corridor (send market into a Philippine payout city), 90-day totals',
    risk AS ML.FAILURE_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day transfer-failure probability per corridor',
    exceptions AS CURATED.EXCEPTION_SUMMARY PRIMARY KEY (EXCEPTION_TYPE)
      COMMENT = 'Exceptions, failed transfers and SLA breaches by exception type, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Operator-wide totals per day'
  )
  RELATIONSHIPS (risk_corridor AS risk (ENTITY_ID) REFERENCES corridors)
  FACTS (
    corridors.exceptions_f AS EXCEPTION_COUNT,
    corridors.failed_f AS FAILED_COUNT,
    corridors.breaches_f AS SLA_BREACH_COUNT,
    corridors.transfers_f AS TRANSFER_COUNT,
    corridors.value_f AS VALUE_PHP,
    corridors.recon_due_f AS RECON_DUE,
    corridors.recon_done_f AS RECON_COMPLETED,
    risk.failure_prob_f AS FAILURE_PROB_7D,
    exceptions.type_exceptions_f AS EXCEPTION_COUNT,
    exceptions.type_failed_f AS FAILED_COUNT,
    exceptions.type_breaches_f AS SLA_BREACH_COUNT,
    exceptions.type_value_f AS EXPOSED_VALUE_PHP,
    daily.day_exceptions_f AS EXCEPTION_COUNT,
    daily.day_failed_f AS FAILED_COUNT,
    daily.day_value_f AS VALUE_PHP
  )
  DIMENSIONS (
    corridors.corridor_id AS ENTITY_ID WITH SYNONYMS = ('corridor', 'remittance corridor', 'entities', 'entity'),
    corridors.corridor_name AS ENTITY_NAME,
    corridors.payout_city AS REGION WITH SYNONYMS = ('payout city', 'city', 'destination')
      COMMENT = 'Philippine payout city; every corridor pays out in PHP',
    corridors.send_market AS CATEGORY WITH SYNONYMS = ('send market', 'origin country', 'sending country'),
    corridors.risk_tier AS RISK_TIER COMMENT = 'Payout partner risk tier 1 (low) to 3 (high)',
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    exceptions.exception_type AS EXCEPTION_TYPE WITH SYNONYMS = ('exception', 'exception reason', 'hold reason'),
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    corridors.straight_through_pct AS 100 * (SUM(corridors.transfers_f) - SUM(corridors.exceptions_f)) / NULLIF(SUM(corridors.transfers_f), 0)
      WITH SYNONYMS = ('straight-through rate', 'STP rate')
      COMMENT = 'Transfers without an exception / transfers processed',
    corridors.failure_share_pct AS 100 * SUM(corridors.failed_f) / NULLIF(SUM(corridors.exceptions_f), 0)
      COMMENT = 'Failed transfers / exceptions raised',
    corridors.exceptions_raised AS SUM(corridors.exceptions_f) WITH SYNONYMS = ('exceptions', 'exception volume'),
    corridors.failed_transfers AS SUM(corridors.failed_f) WITH SYNONYMS = ('failures', 'returned transfers'),
    corridors.sla_breaches AS SUM(corridors.breaches_f) WITH SYNONYMS = ('late payouts', 'SLA misses'),
    corridors.transfers_processed AS SUM(corridors.transfers_f),
    corridors.corridors_monitored AS COUNT(corridors.corridor_id) WITH SYNONYMS = ('number of corridors', 'entity count'),
    corridors.total_value_php AS SUM(corridors.value_f) WITH SYNONYMS = ('value', 'volume in PHP'),
    corridors.reconciliation_pct AS 100 * SUM(corridors.recon_done_f) / NULLIF(SUM(corridors.recon_due_f), 0)
      COMMENT = 'Prefunding reconciliations completed / reconciliations due',
    risk.avg_failure_prob AS AVG(risk.failure_prob_f),
    exceptions.type_exceptions AS SUM(exceptions.type_exceptions_f),
    exceptions.type_failed AS SUM(exceptions.type_failed_f),
    exceptions.type_breaches AS SUM(exceptions.type_breaches_f),
    exceptions.type_failure_share_pct AS 100 * SUM(exceptions.type_failed_f) / NULLIF(SUM(exceptions.type_exceptions_f), 0),
    daily.daily_exceptions AS SUM(daily.day_exceptions_f),
    daily.daily_failed AS SUM(daily.day_failed_f),
    daily.daily_value_php AS SUM(daily.day_value_f)
  )
  COMMENT = 'Synthetic Philippine inbound remittance operations analytics (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.REMITTANCE_AGENT
  COMMENT = 'Remittance operations assistant over a synthetic Philippine remittance operator'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic. Give corridor IDs and numbers with units (PHP, %)."
  orchestration: "Use remittance_analyst for transfers, exceptions, failed transfers, SLA breaches, straight-through rate, corridors, payout cities, send markets, exception types and failure risk. Use sop_search for exception-handling procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: remittance_analyst
      description: "Transfers processed, value in PHP, exceptions, failed transfers, SLA breaches, straight-through rate, prefunding reconciliation compliance, exception types and transfer-failure risk scores by corridor, payout city and send market"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic transfer exception-handling SOPs by send market and exception type"
tool_resources:
  remittance_analyst:
    semantic_view: __DEMO_DB__.APP.REMITTANCE_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.EXCEPTION_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;

-- ---------- Live-transfer alert ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), CORRIDOR_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, AMOUNT_PHP FLOAT, SETTLE_SECONDS FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION PH_REMITTANCE_CROSS_BORDER_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_ALERTS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (CORRIDOR_ID, EVENT_TS, AMOUNT_PHP, SETTLE_SECONDS, SOP_HINT)
    SELECT p.CORRIDOR_ID, p.EVENT_TS, p.AMOUNT_PHP, p.SETTLE_SECONDS,
           'Check ' || r.CATEGORY || ' exception SOPs; current risk band ' || COALESCE(s.RISK_BAND, 'n/a')
    FROM RAW.LIVE_TRANSFERS p
    JOIN RAW.CORRIDORS r ON r.ID = p.CORRIDOR_ID
    LEFT JOIN ML.FAILURE_RISK_SCORES s ON s.ENTITY_ID = p.CORRIDOR_ID
    WHERE p.STATUS = 'EXCEPTION'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.CORRIDOR_ID = p.CORRIDOR_ID AND l.EVENT_TS = p.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('PH_REMITTANCE_CROSS_BORDER_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Remittance exception alert',
      'New live transfer exceptions logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_TRANSFER_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_TRANSFERS p
    WHERE p.STATUS = 'EXCEPTION'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.CORRIDOR_ID = p.CORRIDOR_ID AND l.EVENT_TS = p.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_ALERTS();

-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.EXCEPTION_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.FAILURE_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.FAILURE_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.FAILURE_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'RISK_TIER', RISK_TIER, 'CORRIDOR_AGE_YEARS', CORRIDOR_AGE_YEARS,
             'SCREENING_HIT_PCT', SCREENING_HIT_PCT, 'AVG_SETTLE_MIN', AVG_SETTLE_MIN,
             'SCREENING_HIT_7D', SCREENING_HIT_7D, 'FAILED_30D', FAILED_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, ROUND(PRED:probability:FAILURE::FLOAT, 4) AS FAILURE_PROB_7D,
         CASE WHEN PRED:probability:FAILURE::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:FAILURE::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;
