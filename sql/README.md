# Actuarial SQL toolkit

HNB means **health and benefits** in this toolkit.

## Run

These scripts use a PostgreSQL-compatible SQL subset and also execute on modern SQLite with math functions enabled. Validation here uses SQLite, not a PostgreSQL server.

In a **new, empty PostgreSQL database**, run from the repository root:

```sh
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 --single-transaction -f sql/01_schema.sql -f sql/02_metrics.sql
# Optional fictional demonstration inputs:
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 --single-transaction -f sql/03_sample_data.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f sql/04_reports.sql
```

For real data, skip `03_sample_data.sql`. Insert rows into the four input tables with explicit column lists, following the example in that file. Query the views again whenever the data change; views recalculate automatically. Creation scripts are intentionally not rerunnable migrations. Do not run them against existing production tables.

No database account is included or required for the local demonstration:

```sh
python tools/check_actuarial_sql.py
```

## Inputs and interpretation

| Table | One row represents | Main inputs |
| --- | --- | --- |
| `hnb_experience` | Product and experience period | Member-months, earned premium, reported claim count, cumulative paid claims, outstanding case reserve, selected IBNR, expenses |
| `life_experience` | Disjoint cohort, product, and period | Life-year exposure, policy movements, observed and expected deaths and death benefits, lapse-eligible exposure |
| `life_financials` | Product and financial period | Earned premium, investment income, incurred benefits, expenses, opening and closing reserves |
| `life_cashflows` | Projected payment timing for an in-force cohort at one valuation date | Probability-weighted premiums, benefits, expenses, years to payment, annual effective spot rate |

Use one reporting currency throughout. Use consistent gross or net-of-reinsurance inputs; these examples do not model reinsurance. Do not duplicate product totals across cohorts. Period IDs are sortable integers: examples use calendar years. Health claims and premiums must refer to the same experience period, with claims measured at a specified, consistent valuation/development basis. Retain that valuation information in your source data; this starter table holds one selected valuation per product and period, not a full valuation history.

## Metrics

| View | Outputs and definitions |
| --- | --- |
| `hnb_metrics` | Reported incurred = paid + case; estimated ultimate = paid + case + IBNR; premium and claim costs per member per month; reported claims per 1,000 member-years; reported severity; reported and ultimate loss ratios; expense and combined ratios; underwriting result and margin; outstanding claims and IBNR share |
| `life_experience_metrics` | Deaths per 1,000 life-years; count and amount mortality A/E; expected less actual death benefits; average death benefit; lapses per eligible exposure-year; policy rollforward reconciliation |
| `life_financial_metrics` | Benefit and expense ratios; reserve movement; simplified pretax result and margin, including investment income and reserve changes |
| `life_present_values` | Present values of future premiums, benefits and expenses; prospective net liability = PV(benefits + expenses − premiums) |
| `input_quality_flags` | Selected consistency warnings to investigate before interpreting results |

Ratios are decimals: `0.85` means 85%. Division by zero produces `NULL`, not a zero ratio. A/E above 1 means actual exceeds expected. Frequency counts claims, not unique claimants; it can exceed one claim per member-year. Reported severity excludes unreported claims and must not be described as ultimate severity. Aggregate ratios using sums of numerators and denominators, never unweighted averages of product ratios.

Lapse and mortality exposure rates are central occurrence rates, not annual termination probabilities. The lapse rate is not persistency; persistency requires issue-cohort survival histories. Mortality gain here is a simple expected-minus-actual benefit comparison, not a complete valuation-basis mortality profit analysis.

IBNR, expected mortality, and future cashflows require appropriate actuarial models upstream. These queries do **not** fit a claims development model or calculate IFRS 17 CSM, risk adjustment, statutory reserves, solvency capital, or embedded value. The prospective liability is a simplified deterministic cashflow measure, may be negative, and excludes margins, options, guarantees, tax, and regulatory adjustments. The financial result is not an accounting-standard profit declaration. Quality flags are a starting point, not comprehensive data validation.

## Checked sample results

- 2025 Group medical: premium PMPM **500**, ultimate claims PMPM **375**, ultimate loss ratio **75%**, combined ratio **87.5%**, underwriting result **750,000**.
- Term life: **6** observed versus **5.8** expected deaths; count A/E **1.034483**; policy reconciliation difference **0**; simplified pretax result **360,000**.
- Discounted illustrative net liability: approximately **506,230.09** at the supplied flat 4% spot rates.

Use fictional data for exploration. Validate assumptions, source completeness, timing, and reporting requirements before applying the outputs to decisions.
