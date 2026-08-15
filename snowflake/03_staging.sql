-- ============================================================================
-- 03_STAGING.SQL — Generate synthetic data for Cross-Border Remittance Analytics & Corridor Intelligence
-- Country: PHILIPPINES | Currency: PHP
-- ============================================================================
USE DATABASE REMITTANCE_OPS;
USE SCHEMA RAW;

-- Data generation scripts are demo-specific.
-- See the handcrafted SQL in the aws-malaysia-semiconductor-yield demo for
-- the full pattern: GENERATOR + UNIFORM + LATERAL for distribution,
-- Cortex Complete for text generation, engineered key demo numbers.

-- Target row counts:
-- CORRIDORS: 210 rows — Send-receive corridor definitions (country pairs)
-- TRANSACTIONS: 2,400,000 rows — 90 days of remittance transactions via Kinesis
-- SENDERS: 850,000 rows — OFW sender profiles (anonymized)
-- RECEIVERS: 920,000 rows — Philippine beneficiary profiles (anonymized)
-- PAYOUT_AGENTS: 14,500 rows — Payout network (banks, pawnshops, e-wallets, door-to-door)
-- FX_RATES: 75,000 rows — Historical FX rates for all corridors
-- BSP_REPORTS: 48 rows — BSP (Bangko Sentral) quarterly remittance statistics
