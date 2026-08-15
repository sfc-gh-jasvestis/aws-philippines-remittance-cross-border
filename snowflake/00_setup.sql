-- ============================================================================
-- Cross-Border Remittance Analytics & Corridor Intelligence
-- 10M OFWs send $36B home annually through 200+ corridors — Snowflake processes remittance streams in real-time, builds corridor analytics with Dynamic Tables, and enables Cortex Agent-powered intelligence for compliance and operations.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS REMITTANCE_OPS;
CREATE WAREHOUSE IF NOT EXISTS REMIT_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE REMITTANCE_OPS;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE REMIT_WH;
