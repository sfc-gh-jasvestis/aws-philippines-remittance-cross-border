-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for Cross-Border Remittance Analytics & Corridor Intelligence
-- ============================================================================
USE DATABASE REMITTANCE_OPS;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_philippines_remittance_cross_border_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('<YOUR_EMAIL>');

-- Alert: CORRIDOR_VOLUME_SPIKE
CREATE OR REPLACE ALERT APP.CORRIDOR_VOLUME_SPIKE
  WAREHOUSE = REMIT_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Unusual volume spike in corridor'
IF (EXISTS (
  SELECT 1 FROM CURATED.CORRIDOR_ANALYTICS
  WHERE 1=1 -- Condition: DAILY_VOLUME > 3x ROLLING_AVG for any corridor
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_philippines_remittance_cross_border_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Cross-Border Remittance Analytics & Corridor Intelligence: Unusual volume spike in corridor',
    'Unusual volume spike in corridor'
  );

ALTER ALERT APP.CORRIDOR_VOLUME_SPIKE RESUME;

-- Alert: SETTLEMENT_DELAY_ALERT
CREATE OR REPLACE ALERT APP.SETTLEMENT_DELAY_ALERT
  WAREHOUSE = REMIT_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Payout settlement exceeding 24-hour threshold'
IF (EXISTS (
  SELECT 1 FROM CURATED.CORRIDOR_ANALYTICS
  WHERE 1=1 -- Condition: AVG_SETTLEMENT_HOURS > 24 for any payout agent
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_philippines_remittance_cross_border_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Cross-Border Remittance Analytics & Corridor Intelligence: Payout settlement exceeding 24-hour threshold',
    'Payout settlement exceeding 24-hour threshold'
  );

ALTER ALERT APP.SETTLEMENT_DELAY_ALERT RESUME;

