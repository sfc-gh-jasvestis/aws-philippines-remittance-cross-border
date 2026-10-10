-- Synthetic corridor-day observations for a fictional Philippine remittance operator.
-- A corridor is one send market paying out to beneficiaries in one Philippine city.
-- Nothing is seeded as a prediction. Randomness is HASH-seeded, so every rebuild
-- is reproducible: per-corridor failure propensity, drift between payout-partner
-- prefunding reconciliations, missed reconciliations, send-market-weighted
-- exception types, exceptions cleared without failure, and two city-wide payout
-- network outages.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.CORRIDORS AS
WITH corridors AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS CORRIDOR_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 40))
), draws AS (
  SELECT CORRIDOR_INDEX,
         MOD(ABS(HASH(CORRIDOR_INDEX, 'phrcb-age')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(CORRIDOR_INDEX, 'phrcb-rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(CORRIDOR_INDEX, 'phrcb-recon')), 1000000) / 1e6 AS U_RECON,
         MOD(ABS(HASH(CORRIDOR_INDEX, 'phrcb-discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(CORRIDOR_INDEX, 'phrcb-tier')), 1000000) / 1e6 AS U_TIER
  FROM corridors
)
SELECT 'COR-' || LPAD(CORRIDOR_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic corridor ' || LPAD(CORRIDOR_INDEX::VARCHAR, 4, '0') AS NAME,
       -- Deterministic spread (5 and 8 are coprime): every payout city and send
       -- market is present. All corridors pay out in the Philippines (PHP).
       CASE MOD(CORRIDOR_INDEX, 5) WHEN 0 THEN 'Quezon City' WHEN 1 THEN 'Cebu City'
            WHEN 2 THEN 'Davao City' WHEN 3 THEN 'Iloilo City' ELSE 'Baguio City' END AS REGION,
       CASE MOD(CORRIDOR_INDEX, 8) WHEN 0 THEN 'Saudi Arabia' WHEN 1 THEN 'Saudi Arabia'
            WHEN 2 THEN 'Saudi Arabia' WHEN 3 THEN 'United Arab Emirates' WHEN 4 THEN 'United Arab Emirates'
            WHEN 5 THEN 'United States' WHEN 6 THEN 'Hong Kong' ELSE 'Singapore' END AS CATEGORY,
       CORRIDOR_INDEX,
       1 + FLOOR(U_TIER * 3) AS RISK_TIER,
       ROUND(0.3 + U_AGE * 6.2, 1) AS CORRIDOR_AGE_YEARS,
       -- Base daily probability of a failed transfer 0.5%-3%; ~15% of corridors
       -- are chronically weak (x3).
       (0.005 + U_RATE * 0.025) * IFF(U_RATE > 0.85, 3, 1) AS BASE_FAILURE_RATE,
       7 * (1 + FLOOR(U_RECON * 3)) AS RECON_INTERVAL_DAYS,
       0.55 + U_DISCIPLINE * 0.45 AS RECON_COMPLETION_PROB,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.CORRIDOR_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), city_events AS (
  -- Two city-wide payout network outages; every corridor paying out in the city
  -- raises an exception that clears once the payout network recovers.
  SELECT * FROM VALUES (23, 'Cebu City'), (58, 'Davao City') AS o(DAY_INDEX, REGION)
), base AS (
  SELECT r.ID AS ENTITY_ID, r.CORRIDOR_INDEX, r.CATEGORY, r.REGION, r.CORRIDOR_AGE_YEARS,
         r.BASE_FAILURE_RATE, r.RECON_INTERVAL_DAYS, r.RECON_COMPLETION_PROB,
         d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         MOD(d.DAY_INDEX + r.CORRIDOR_INDEX * 3, r.RECON_INTERVAL_DAYS) AS DAYS_SINCE_RECON,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phrcb-fail')), 1000000) / 1e6 AS U_FAIL,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phrcb-detect')), 1000000) / 1e6 AS U_DETECT,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phrcb-clear')), 1000000) / 1e6 AS U_CLEAR,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phrcb-type')), 1000000) / 1e6 AS U_TYPE,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phrcb-done')), 1000000) / 1e6 AS U_DONE,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phrcb-volume')), 1000000) / 1e6 AS U_VOLUME,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phrcb-noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phrcb-sla')), 1000000) / 1e6 AS U_SLA,
         e.REGION IS NOT NULL AS CITY_EVENT
  FROM RAW.CORRIDORS r CROSS JOIN days d
  LEFT JOIN city_events e ON e.DAY_INDEX = d.DAY_INDEX AND e.REGION = r.REGION
), recon AS (
  SELECT *,
         IFF(DAYS_SINCE_RECON = 0, 1, 0) AS RECON_DUE,
         IFF(DAYS_SINCE_RECON = 0 AND U_DONE < RECON_COMPLETION_PROB, 1, 0) AS RECON_COMPLETED,
         -- Data-quality drift rises between prefunding reconciliations with the
         -- payout partner; weak reconciliation discipline carries it over.
         DAYS_SINCE_RECON / RECON_INTERVAL_DAYS + (1 - RECON_COMPLETION_PROB) AS DRIFT
  FROM base
), failures AS (
  SELECT *,
         CASE WHEN U_FAIL < LEAST(0.5, BASE_FAILURE_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + CORRIDOR_AGE_YEARS))) / 4 THEN 2
              WHEN U_FAIL < LEAST(0.5, BASE_FAILURE_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + CORRIDOR_AGE_YEARS))) THEN 1
              ELSE 0 END AS FAILURE_RISK_COUNT
  FROM recon
), exceptions AS (
  SELECT *,
         -- About 85% of at-risk transfers are caught as exceptions and end failed
         -- or returned to the sender; the rest pay out late without an exception.
         IFF(CITY_EVENT, 0, IFF(U_DETECT < 0.85, FAILURE_RISK_COUNT, 0)) AS FAILED_COUNT,
         -- Exceptions cleared without failure: higher for high-volume send markets.
         IFF(CITY_EVENT, 1, IFF(U_CLEAR < CASE CATEGORY WHEN 'Saudi Arabia' THEN 0.18
                                                        WHEN 'United Arab Emirates' THEN 0.14
                                                        WHEN 'United States' THEN 0.11 ELSE 0.08 END, 1, 0)) AS CLEARED_COUNT
  FROM failures
), measured AS (
  SELECT *,
         FAILED_COUNT + CLEARED_COUNT AS EXCEPTION_COUNT,
         ROUND(CASE CATEGORY WHEN 'Saudi Arabia' THEN 1400 WHEN 'United Arab Emirates' THEN 950
                             WHEN 'United States' THEN 620 WHEN 'Hong Kong' THEN 480 ELSE 360 END
               * (0.7 + 0.6 * U_VOLUME) * (1 + 0.8 * FAILURE_RISK_COUNT)) AS TRANSFER_COUNT,
         CASE CATEGORY WHEN 'Saudi Arabia' THEN 14500 WHEN 'United Arab Emirates' THEN 13200
                       WHEN 'United States' THEN 27800 WHEN 'Hong Kong' THEN 11900 ELSE 16400 END
           * (0.8 + 0.4 * U_NOISE) AS AVG_TRANSFER_PHP
  FROM exceptions
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE,
       TRANSFER_COUNT,
       ROUND(TRANSFER_COUNT * AVG_TRANSFER_PHP, 2) AS VALUE_PHP,
       EXCEPTION_COUNT, FAILED_COUNT,
       IFF(FAILED_COUNT > 0 AND U_SLA < 0.6, 1, 0) AS SLA_BREACHED,
       CASE WHEN EXCEPTION_COUNT = 0 THEN 'None'
            WHEN CITY_EVENT THEN 'Payout network outage'
            WHEN CATEGORY = 'Saudi Arabia' THEN IFF(U_TYPE < 0.45, 'Beneficiary name mismatch', IFF(U_TYPE < 0.8, 'Cash pickup not collected', 'AML hold'))
            WHEN CATEGORY = 'United Arab Emirates' THEN IFF(U_TYPE < 0.4, 'Beneficiary name mismatch', IFF(U_TYPE < 0.75, 'Wallet credit rejected', 'Sanctions screening hit'))
            WHEN CATEGORY = 'United States' THEN IFF(U_TYPE < 0.5, 'Bank account closed', IFF(U_TYPE < 0.8, 'AML hold', 'Sanctions screening hit'))
            WHEN CATEGORY = 'Hong Kong' THEN IFF(U_TYPE < 0.55, 'Wallet credit rejected', 'Prefunding shortfall')
            ELSE IFF(U_TYPE < 0.5, 'Prefunding shortfall', IFF(U_TYPE < 0.75, 'Bank account closed', 'AML hold')) END AS EXCEPTION_TYPE,
       RECON_DUE, RECON_COMPLETED,
       ROUND(0.6 + 1.8 * DRIFT + 3.2 * FAILURE_RISK_COUNT + U_NOISE * 0.9, 2) AS SCREENING_HIT_PCT,
       ROUND(22 + 14 * DRIFT + 16 * FAILURE_RISK_COUNT + U_NOISE * 7, 1) AS AVG_SETTLE_MIN,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM measured;

-- Payout-partner due-diligence document coverage per corridor (snapshot).
CREATE TABLE RAW.DUE_DILIGENCE_DOCUMENTS AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Saudi Arabia' THEN 'Send-partner licence'
                     WHEN 'United Arab Emirates' THEN 'Exchange-house agreement'
                     WHEN 'United States' THEN 'Money transmitter partner file'
                     WHEN 'Hong Kong' THEN 'Wallet partner agreement'
                     ELSE 'Payout partner due diligence questionnaire' END AS DOC_TYPE,
       1 + MOD(ABS(HASH(ID, 'phrcb-req')), 4) AS REQUIRED_QTY,
       MOD(ABS(HASH(ID, 'phrcb-file')), 5) AS ON_FILE_QTY,
       IFF(MOD(ABS(HASH(ID, 'phrcb-file')), 5) < 1 + MOD(ABS(HASH(ID, 'phrcb-req')), 4),
           MOD(ABS(HASH(ID, 'phrcb-pending')), 3), 0) AS PENDING_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.CORRIDORS;
