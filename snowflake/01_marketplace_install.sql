-- ============================================================================
-- 01_MARKETPLACE_INSTALL.SQL — Install marketplace data for Cross-Border Remittance Analytics & Corridor Intelligence
-- ============================================================================
USE DATABASE REMITTANCE_OPS;
USE SCHEMA RAW;

-- Free listings to install from Snowflake Marketplace:
-- Install: Snowflake Public Data (Free)
--   https://app.snowflake.com/marketplace/listing/GZTSZ290BV255

-- Paid listing (mock): Cybersyn FX Rates
--   Real data: https://app.snowflake.com/marketplace/listing/GZTSZAS2KCS
--   Using mock table: FX_RATES
CREATE TABLE IF NOT EXISTS RAW.FX_RATES (
  ID INT AUTOINCREMENT, DATA VARIANT, LOADED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

