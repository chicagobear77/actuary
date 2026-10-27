CREATE VIEW hnb_metrics AS
WITH totals AS (
    SELECT *, paid_claims + case_reserve AS reported_incurred,
        paid_claims + case_reserve + ibnr_estimate AS estimated_ultimate,
        administration_expense + commission AS total_expense
    FROM hnb_experience
)
SELECT period_id, product, member_months, earned_premium,
    reported_claim_count, paid_claims, case_reserve, ibnr_estimate,
    reported_incurred, estimated_ultimate, total_expense,
    1.0 * earned_premium / NULLIF(member_months, 0) AS premium_pmpm,
    1.0 * reported_incurred / NULLIF(member_months, 0) AS reported_claims_pmpm,
    1.0 * estimated_ultimate / NULLIF(member_months, 0) AS ultimate_claims_pmpm,
    12000.0 * reported_claim_count / NULLIF(member_months, 0)
        AS reported_claims_per_1000_member_years,
    1.0 * reported_incurred / NULLIF(reported_claim_count, 0)
        AS reported_claim_severity,
    1.0 * reported_incurred / NULLIF(earned_premium, 0) AS reported_loss_ratio,
    1.0 * estimated_ultimate / NULLIF(earned_premium, 0) AS ultimate_loss_ratio,
    1.0 * total_expense / NULLIF(earned_premium, 0) AS expense_ratio,
    1.0 * (estimated_ultimate + total_expense) / NULLIF(earned_premium, 0)
        AS combined_ratio,
    earned_premium - estimated_ultimate - total_expense AS underwriting_result,
    1.0 * (earned_premium - estimated_ultimate - total_expense)
        / NULLIF(earned_premium, 0) AS underwriting_margin,
    case_reserve + ibnr_estimate AS estimated_outstanding_claims,
    1.0 * ibnr_estimate / NULLIF(estimated_ultimate, 0) AS ibnr_share_of_ultimate,
    ibnr_basis
FROM totals;

CREATE VIEW life_experience_metrics AS
WITH totals AS (
    SELECT period_id, product,
        SUM(exposure_life_years) AS exposure_life_years,
        SUM(lapse_eligible_exposure_years) AS lapse_eligible_exposure_years,
        SUM(opening_policies) AS opening_policies,
        SUM(new_policies) AS new_policies,
        SUM(death_count) AS death_count,
        SUM(lapse_count) AS lapse_count,
        SUM(maturity_count) AS maturity_count,
        SUM(closing_policies) AS closing_policies,
        SUM(expected_deaths) AS expected_deaths,
        SUM(actual_death_benefit) AS actual_death_benefit,
        SUM(expected_death_benefit) AS expected_death_benefit
    FROM life_experience GROUP BY period_id, product
)
SELECT *,
    1000.0 * death_count / NULLIF(exposure_life_years, 0)
        AS deaths_per_1000_life_years,
    1.0 * death_count / NULLIF(expected_deaths, 0) AS mortality_ae_count,
    1.0 * actual_death_benefit / NULLIF(expected_death_benefit, 0)
        AS mortality_ae_amount,
    expected_death_benefit - actual_death_benefit AS mortality_experience_gain,
    1.0 * actual_death_benefit / NULLIF(death_count, 0) AS average_death_benefit,
    1.0 * lapse_count / NULLIF(lapse_eligible_exposure_years, 0)
        AS lapse_rate_per_exposure_year,
    opening_policies + new_policies - death_count - lapse_count - maturity_count
        - closing_policies AS policy_rollforward_difference
FROM totals;

-- Exposure rates are central rates, not annual qx probabilities. Persistency
-- needs an issue-cohort survival history and is deliberately not inferred
-- from closing policies / opening policies (which confounds new business).

CREATE VIEW life_financial_metrics AS
SELECT *, closing_reserve - opening_reserve AS reserve_increase,
    1.0 * incurred_benefits / NULLIF(earned_premium, 0) AS benefit_ratio,
    1.0 * (expense + commission) / NULLIF(earned_premium, 0) AS expense_ratio,
    earned_premium + investment_income - incurred_benefits - expense - commission
        - (closing_reserve - opening_reserve) AS simplified_pretax_result,
    1.0 * (earned_premium + investment_income - incurred_benefits - expense
        - commission - (closing_reserve - opening_reserve))
        / NULLIF(earned_premium, 0) AS simplified_margin_on_premium
FROM life_financials;

CREATE VIEW life_present_values AS
WITH discounted AS (
    SELECT *, 1.0 / POWER(1 + annual_spot_rate, years_from_valuation)
        AS discount_factor
    FROM life_cashflows
)
SELECT valuation_date, product, cohort,
    SUM(expected_premium * discount_factor) AS pv_future_premiums,
    SUM(expected_benefit * discount_factor) AS pv_future_benefits,
    SUM(expected_expense * discount_factor) AS pv_future_expenses,
    SUM((expected_benefit + expected_expense - expected_premium)
        * discount_factor) AS prospective_net_liability
FROM discounted GROUP BY valuation_date, product, cohort;
-- A negative net liability is retained, not floored. This is a discounted
-- cashflow measure, NOT an IFRS 17, statutory, solvency, or GAAP reserve.

CREATE VIEW input_quality_flags AS
SELECT 'HNB' AS source_table, period_id, product,
    'Activity with zero exposure' AS issue
FROM hnb_experience
WHERE member_months = 0 AND (earned_premium > 0 OR reported_claim_count > 0
    OR paid_claims + case_reserve + ibnr_estimate > 0)
UNION ALL
SELECT 'HNB', period_id, product, 'Reported claims cost without reported claim count'
FROM hnb_experience WHERE reported_claim_count = 0 AND paid_claims + case_reserve > 0
UNION ALL
SELECT 'HNB', period_id, product, 'IBNR basis missing'
FROM hnb_experience WHERE TRIM(ibnr_basis) = ''
UNION ALL
SELECT 'LIFE', period_id, product, 'Policy rollforward does not reconcile'
FROM life_experience_metrics WHERE policy_rollforward_difference <> 0
UNION ALL
SELECT 'LIFE', period_id, product, 'Deaths with zero life exposure'
FROM life_experience WHERE death_count > 0 AND exposure_life_years = 0
UNION ALL
SELECT 'LIFE', period_id, product, 'Lapses with zero eligible exposure'
FROM life_experience WHERE lapse_count > 0 AND lapse_eligible_exposure_years = 0
UNION ALL
SELECT 'LIFE', period_id, product, 'Deaths with zero expected deaths; count A/E undefined'
FROM life_experience WHERE death_count > 0 AND expected_deaths = 0
UNION ALL
SELECT 'LIFE', period_id, product, 'Death benefit without death count'
FROM life_experience WHERE death_count = 0 AND actual_death_benefit > 0;
