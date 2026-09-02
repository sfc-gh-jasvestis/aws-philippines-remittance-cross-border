# Cross-Border Remittance Analytics & Corridor Intelligence

**Philippines - Remittances & Fintech**
Use case: Cross-Border Remittance Analytics

> 10M OFWs send $36B home annually through 200+ corridors — Snowflake processes remittance streams in real-time, builds corridor analytics with Dynamic Tables, and enables Cortex Agent-powered intelligence for compliance and operations.

## Why Snowflake

Snowflake ingests remittance transactions via Kinesis in real-time, builds corridor analytics with Dynamic Tables, monitors flow anomalies, and provides natural language intelligence for remittance operations — replacing fragmented legacy systems

- **Snowpipe Streaming for remittance transactions** - Only demo ingesting financial transactions via Snowpipe Streaming at scale
- **Dynamic Tables for corridor analytics** - Real-time corridor performance without complex ETL
- **ML.FORECAST for seasonal remittance patterns** - Predicts OFW remittance surges (Eid, Christmas, Undas) weeks ahead
- **Cortex Agent for remittance operations** - Natural language queries across 210 corridors and 14,500 payout points
- **Philippine OFW remittance context** - $36B industry with culturally-specific corridors (Saudi, UAE, HK, US, Japan)
- **BSP regulatory search** - Cortex Search on Bangko Sentral regulatory documents for compliance queries

## What is deployed

| | |
|---|---|
| Database | `PH_REMITTANCE_CROSS_BORDER` |
| Service | `PH_REMITTANCE_CROSS_BORDER_APP` |
| Compute pool | `SEA_DEMOS_PHILIPPINES_POOL` |
| Dimension table | `RAW.BSP_REPORTS` (20 rows) |
| Fact table | `RAW.TRANSACTIONS` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | PHP (₱) |

Regions in play: Metro Manila, Cebu, Davao, Pampanga, Iloilo
Segments: UAE Corridor, Saudi Corridor, Singapore Corridor, US Corridor

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh PH_REMITTANCE_CROSS_BORDER
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| Remittance Volume | `₱142B` | total across Bsp Reports |
| Active Corridors | `42` | total across Bsp Reports |
| Avg Transfer Time | `4.2 hrs` | average per event |
| Transactions (MTD) | `8.4M` | total across Bsp Reports |
| US→PH Share | `38%` | average per event |
| Middle East Share | `24%` | average per event |
| Avg Fee Rate | `2.1%` | average per event |


## Demo flow

1. Executive Cockpit
2. Corridor Analytics
3. Payout Network
4. Ask AI
5. Architecture & Data

## Talking points

- **₱1.8T** - processed in 90 days across 210 corridors
- **2.4M transactions** - ingested via Snowpipe Streaming
- **210 corridors** - monitored with ML.ANOMALY_DETECTION
- **14,500 payout points** - banks, pawnshops, e-wallets tracked
- **42%** - of payouts now via e-wallets (GCash/Maya)
- **3 corridors** - flagged anomalous (volume 3x above normal)

## Business impact

- Philippine remittances reached $36.1B in 2023 — 8.5% of GDP (BSP)
- 10 million OFWs support 40% of Philippine households via remittances (PSA Philippines)
- Digital remittance channels grew 35% in Philippines during 2023 (World Bank)
- Real-time transaction monitoring reduces fraud losses 45% in payments (McKinsey Payments)

---
Generated from `generator/demo_specs/aws-philippines-remittance-cross-border.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-philippines-remittance-cross-border` instead.
