-- Generated from generator/demo_specs/aws-philippines-remittance-cross-border.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-philippines-remittance-cross-border
-- This is the schema that is actually deployed for PH_REMITTANCE_CROSS_BORDER.

-- PH_REMITTANCE_CROSS_BORDER  (Cross-Border Remittance Analytics & Corridor Intelligence)
-- generated from generator/demo_specs/aws-philippines-remittance-cross-border.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS PH_REMITTANCE_CROSS_BORDER;
CREATE SCHEMA IF NOT EXISTS PH_REMITTANCE_CROSS_BORDER.RAW;
CREATE SCHEMA IF NOT EXISTS PH_REMITTANCE_CROSS_BORDER.CURATED;
CREATE SCHEMA IF NOT EXISTS PH_REMITTANCE_CROSS_BORDER.APP;
USE DATABASE PH_REMITTANCE_CROSS_BORDER;

-- 5 real regions; entity names carry their region so the two always agree
