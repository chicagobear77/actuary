# Insurance Premium Calculator

For health and benefits and life actuarial calculations using SQL, see [the SQL toolkit](sql/README.md). It includes input tables, metric views, fictional sample data, and executable validation checks.

Open `Insurance_Premium_Calculator.xlsx` in Excel or a compatible spreadsheet application. Begin with **Start Here**, review the synthetic **Experience**, edit blue cells on **Inputs**, then review **Pricing** and **Sensitivity**.

The workbook estimates annual premium per policy-year as:

```
(claim frequency × average severity × (1 + severity trend)^years + fixed expense)
/ (1 − variable expense ratio − target profit ratio)
```

Defaults indicate an annual premium of **$624.88** per policy and a monthly equivalent of **$52.07**. All data are fictional. The model is educational and does not account for policy limits, deductibles, taxes, reinsurance, development, or credibility.

To regenerate the workbook with Python 3 and XlsxWriter installed:

```sh
python tools/create_workbook.py
```

Excel recalculates formulas after edits; initial calculated values are cached for other viewers. No credentials or running services are required.
