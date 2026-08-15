-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Cross-Border Remittance Analytics & Corridor Intelligence
-- ============================================================================
USE DATABASE REMITTANCE_OPS;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.REMITTANCE_ANALYTICS
  COMMENT = 'Cross-border remittance corridor, volume, FX, and payout analytics'
AS
  TABLES (
    CURATED.CORRIDOR_ANALYTICS AS corridor_analytics,CURATED.SENDER_BEHAVIOR AS sender_behavior,CURATED.PAYOUT_PERFORMANCE AS payout_performance,CURATED.CORRIDOR_TIMESERIES AS corridor_timeseries
  );
