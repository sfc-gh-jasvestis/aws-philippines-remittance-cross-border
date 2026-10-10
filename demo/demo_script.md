# Philippine Inbound Remittance Operations

**Philippines - Inbound Remittance Corridors**
Use case: Remittance transfer exceptions, payout controls and corridor risk

> Operations monitoring for 40 inbound corridors of a fictional Philippine remittance operator, from 5 send markets into 5 Philippine payout cities: dynamic tables, a holdout-evaluated failed-transfer classifier, an exception-volume forecast and grounded AI answers.

## Why Snowflake

- **Dynamic tables** reconcile transfers, exceptions, failed transfers, payout SLA breaches and prefunding reconciliation compliance from RAW corridor data, with checks in `run_core.py`
- **Failed-transfer classification** gives a holdout-evaluated next-7-day probability per corridor
- **Exception forecast** projects 14 days of operator-wide exception volume with prediction intervals, for operations staffing
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live transfers**: a native simulator (Snowflake only) or Firehose, S3 and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.CORRIDORS` (40 rows) |
| Fact table | `RAW.CORRIDOR_DAILY` (3,600 corridor-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `EXCEPTION_SUMMARY`, `TREND_ANALYSIS` |
| ML | `ML.FAILURE_RISK_SCORES`, `ML.FAILURE_RISK_HOLDOUT_METRICS`, `ML.EXCEPTION_FORECAST`, `ML.SCREENING_HIT_ANOMALIES` |

Payout currency: PHP. Payout cities: Quezon City, Cebu City, Davao City, Iloilo City, Baguio City.
Send markets: Saudi Arabia, United Arab Emirates, United States, Hong Kong, Singapore. The operator, payout partners and corridors are fictional.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| Straight-Through Rate | 99.98% |
| Exceptions Raised | 755 |
| Failed Transfers | 232 |
| Exception Failure Rate | 30.7% |
| SLA Breaches | 120 |
| Value Processed (PHP M) | 55,236 |
| Transfers Processed | 3,635,360 |
| Prefunding Reconciliation Compliance | 73.1% |
| Corridors Monitored | 40 |
| Due Diligence Coverage | 59.2% |
| Due Diligence Documents Pending | 20 |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily exceptions against failed transfers, exceptions and failures by exception type, corridor table
2. Predictive: holdout metrics, risk bands, 14-day exception forecast, screening hit rate anomalies
3. Controls: prefunding reconciliation compliance, payout-partner due-diligence coverage and pending documents, reconciliation compliance against failed transfers, then generate the action memo for Marisol Dizon
4. Live Transfers: run `CALL APP.SIMULATE_TRANSFERS(20)` (Snowflake only) or `python aws/publish_transfers.py --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_TRANSFER_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- 99.98% of transfers pay out straight through; the 755 exceptions are where operations time goes, and about 3 in 10 of them (30.7%) end as failed or returned transfers.
- Beneficiary name mismatches produce the most failed transfers (56 of 230). Payout network outages hit every corridor paying out in one city at once (Cebu City and Davao City in this data) and always clear.
- Quezon City corridors carry the most failed transfers (93), so that is where to start the corridor review.
- The risk model is evaluated on a time-based holdout: precision 0.47 and recall 0.35 at 0.5, against a 0.26 base rate. Present it as triage, not a verdict.
- Payout network outages are excluded from model training, because they are not corridor-driven.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
