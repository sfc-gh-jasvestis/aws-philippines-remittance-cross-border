# Demo Script: Cross-Border Remittance Analytics & Corridor Intelligence
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake ingests remittance transactions via Kinesis in real-time, builds corridor analytics with Dynamic Tables, monitors flow anomalies, and provides natural language intelligence for remittance operations — replacing fragmented legacy systems"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Carmen Luisa Uy-Tiongco** | Chief Operations Officer | React App (SPCS) | Corridor volumes, FX margins, transaction success rates, corridor profitability |
| **Kenneth Aldrin Reyes** | Corridor Analytics Manager | Amazon QuickSight | Corridor performance, pricing competitiveness, seasonal patterns, agent network utilization |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 7 tables | CORRIDORS (210), TRANSACTIONS (2400000), SENDERS (850000), RECEIVERS (920000), PAYOUT_AGENTS (14500), FX_RATES (75000), BSP_REPORTS (48) |
| **CURATED** | 4 Dynamic Tables | CORRIDOR_ANALYTICS, SENDER_BEHAVIOR, PAYOUT_PERFORMANCE, CORRIDOR_TIMESERIES |
| **ML** | ML.FORECAST + ML.ANOMALY_DETECTION | Forecasting + anomaly detection |
| **AI** | COMPLETE, AI_CLASSIFY | Classification + extraction |
| **Search** | Cortex Search | 48 documents indexed |
| **Agent** | REMITTANCE_INTELLIGENCE_AGENT | Semantic View + Search tools |


---

## The Story

The Philippines receives $36 billion in remittances annually from 10 million OFWs working across 210 corridors worldwide. A leading Philippine remittance company processes ₱1.8 trillion quarterly — but corridor analytics lives in spreadsheets updated weekly, missing real-time spikes, seasonal patterns, and competitive threats. Snowflake transforms this into a real-time intelligence platform.

---

## Script

### [0:00–0:45] EXECUTIVE COCKPIT

**Show**: Executive Cockpit tab

> "₱1.8 trillion processed in 90 days across 210 corridors serving 10M+ OFW families."

**Action**: Point at ₱1.8T volume KPI

### [0:45–1:30] CORRIDOR ANALYTICS

**Show**: Corridor Analytics tab

> "Saudi Arabia is largest corridor at ₱320B — 14% QoQ growth driven by Ramadan/Eid."

**Action**: Show corridor waterfall by volume

### [1:30–2:15] PAYOUT NETWORK

**Show**: Payout Network tab

> "14,500 payout points — banks, pawnshops (Cebuana, Palawan Express), e-wallets (GCash, Maya)."

**Action**: Show payout channel mix pie chart

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Carmen asks: 'What's our market share in the Saudi corridor?'"

**Action**: Type: 'Market share in Saudi corridor?'

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Kinesis → Snowpipe Streaming → Dynamic Tables → ML → Cortex Agent — end-to-end."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **Snowpipe Streaming for remittance transactions** — Only demo ingesting financial transactions via Snowpipe Streaming at scale
2. **Dynamic Tables for corridor analytics** — Real-time corridor performance without complex ETL
3. **ML.FORECAST for seasonal remittance patterns** — Predicts OFW remittance surges (Eid, Christmas, Undas) weeks ahead
4. **Cortex Agent for remittance operations** — Natural language queries across 210 corridors and 14,500 payout points
5. **Philippine OFW remittance context** — $36B industry with culturally-specific corridors (Saudi, UAE, HK, US, Japan)
6. **BSP regulatory search** — Cortex Search on Bangko Sentral regulatory documents for compliance queries


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM REMITTANCE_OPS.RAW.TRANSACTIONS` → 2400000
- [ ] `SELECT COUNT(*) FROM REMITTANCE_OPS.RAW.PAYOUT_AGENTS` → 14500
- [ ] `SELECT COUNT(DISTINCT CORRIDOR_ID) FROM REMITTANCE_OPS.CURATED.CORRIDOR_ANALYTICS` → 210

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM REMITTANCE_OPS.ML.CORRIDOR_VOLUME_FORECAST_RESULTS` → >0
- [ ] `SELECT SUM(CASE WHEN IS_ANOMALY THEN 1 ELSE 0 END) FROM REMITTANCE_OPS.ML.CORRIDOR_ANOMALY_RESULTS` → >=3

### AI/Agent Verification
- [ ] `SELECT COUNT(*) FROM REMITTANCE_OPS.AI.TRANSACTION_CLASSIFICATION` → >0

