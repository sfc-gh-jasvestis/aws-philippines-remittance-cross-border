-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Cross-Border Remittance Analytics & Corridor Intelligence
-- ============================================================================
USE DATABASE REMITTANCE_OPS;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.BSP_REGULATORY_SEARCH
  ON REPORT_CONTENT
  ATTRIBUTES QUARTER, CORRIDOR_TYPE, REGULATION_TYPE
  WAREHOUSE = REMIT_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.BSP_REPORTS
);
