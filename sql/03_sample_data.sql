-- Fictional annual data. Run only in a fresh demonstration database.
INSERT INTO hnb_experience
    (period_id, product, member_months, earned_premium, reported_claim_count,
     paid_claims, case_reserve, ibnr_estimate, ibnr_basis,
     administration_expense, commission)
VALUES
    (2025, 'Group medical', 12000, 6000000, 2400, 3600000, 400000, 500000,
     'Fictional selected ultimate less paid and case; not a fitted estimate', 450000, 300000),
    (2026, 'Group medical', 13200, 6900000, 2700, 4100000, 450000, 550000,
     'Fictional selected ultimate less paid and case; not a fitted estimate', 500000, 345000);

INSERT INTO life_experience
    (period_id, product, cohort, exposure_life_years, opening_policies,
     new_policies, death_count, lapse_count, maturity_count, closing_policies,
     expected_deaths, actual_death_benefit, expected_death_benefit,
     lapse_eligible_exposure_years)
VALUES
    (2025, 'Term life', 'Age 30-39', 950, 1000, 50, 2, 80, 20, 948,
     1.9, 400000, 380000, 940),
    (2025, 'Term life', 'Age 40-49', 780, 800, 30, 4, 50, 10, 766,
     3.9, 1000000, 975000, 770);

INSERT INTO life_financials
    (period_id, product, earned_premium, investment_income, incurred_benefits,
     expense, commission, opening_reserve, closing_reserve)
VALUES (2025, 'Term life', 2400000, 100000, 1400000, 300000, 240000, 2000000, 2200000);

INSERT INTO life_cashflows
    (valuation_date, product, cohort, cashflow_id, years_from_valuation,
     expected_premium, expected_benefit, expected_expense, annual_spot_rate)
VALUES
    ('2025-12-31', 'Term life', 'Existing in-force', 1, 1, 1000000, 800000, 100000, 0.04),
    ('2025-12-31', 'Term life', 'Existing in-force', 2, 2, 900000, 1000000, 90000, 0.04),
    ('2025-12-31', 'Term life', 'Existing in-force', 3, 3, 800000, 1200000, 80000, 0.04);
