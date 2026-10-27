-- First investigate flagged inputs; ratios with zero denominators are NULL.
SELECT * FROM input_quality_flags ORDER BY source_table, period_id, product;
SELECT * FROM hnb_metrics ORDER BY period_id, product;
SELECT * FROM life_experience_metrics ORDER BY period_id, product;
SELECT * FROM life_financial_metrics ORDER BY period_id, product;
SELECT * FROM life_present_values ORDER BY valuation_date, product, cohort;

-- Consecutive available observations, not necessarily consecutive years.
WITH prior AS (
    SELECT period_id, product, ultimate_claims_pmpm,
        LAG(period_id) OVER (PARTITION BY product ORDER BY period_id) AS prior_period,
        LAG(ultimate_claims_pmpm) OVER (PARTITION BY product ORDER BY period_id)
            AS prior_pmpm
    FROM hnb_metrics
)
SELECT *, 1.0 * ultimate_claims_pmpm / NULLIF(prior_pmpm, 0) - 1
    AS pmpm_change_since_prior_observation
FROM prior ORDER BY product, period_id;
