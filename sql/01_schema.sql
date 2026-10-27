-- Portable PostgreSQL/SQLite SQL. All amounts must use ONE reporting currency.
-- Load aggregated, de-identified inputs; do not mix monthly and annual periods.
CREATE TABLE hnb_experience (
    period_id INTEGER NOT NULL,
    product VARCHAR(100) NOT NULL,
    member_months NUMERIC NOT NULL CHECK (member_months >= 0),
    earned_premium NUMERIC NOT NULL CHECK (earned_premium >= 0),
    reported_claim_count INTEGER NOT NULL CHECK (reported_claim_count >= 0),
    paid_claims NUMERIC NOT NULL CHECK (paid_claims >= 0),
    case_reserve NUMERIC NOT NULL CHECK (case_reserve >= 0),
    ibnr_estimate NUMERIC NOT NULL CHECK (ibnr_estimate >= 0),
    ibnr_basis VARCHAR(500) NOT NULL,
    administration_expense NUMERIC NOT NULL CHECK (administration_expense >= 0),
    commission NUMERIC NOT NULL CHECK (commission >= 0),
    PRIMARY KEY (period_id, product)
);

-- Distinct reporting periods, all evaluated on a consistent development basis.
-- Claim counts count claims, not claim lines; costs and premiums share scope.
-- Paid + case are reported incurred. IBNR is a supplied actuarial estimate,
-- including IBNER if appropriate, never inferred from reported claim counts.

CREATE TABLE life_experience (
    period_id INTEGER NOT NULL,
    product VARCHAR(100) NOT NULL,
    cohort VARCHAR(100) NOT NULL,
    exposure_life_years NUMERIC NOT NULL CHECK (exposure_life_years >= 0),
    opening_policies INTEGER NOT NULL CHECK (opening_policies >= 0),
    new_policies INTEGER NOT NULL CHECK (new_policies >= 0),
    death_count INTEGER NOT NULL CHECK (death_count >= 0),
    lapse_count INTEGER NOT NULL CHECK (lapse_count >= 0),
    maturity_count INTEGER NOT NULL CHECK (maturity_count >= 0),
    closing_policies INTEGER NOT NULL CHECK (closing_policies >= 0),
    expected_deaths NUMERIC NOT NULL CHECK (expected_deaths >= 0),
    actual_death_benefit NUMERIC NOT NULL CHECK (actual_death_benefit >= 0),
    expected_death_benefit NUMERIC NOT NULL CHECK (expected_death_benefit >= 0),
    lapse_eligible_exposure_years NUMERIC NOT NULL CHECK (lapse_eligible_exposure_years >= 0),
    PRIMARY KEY (period_id, product, cohort)
);
-- Each cohort row is disjoint. expected_deaths and expected_death_benefit
-- are externally calculated using the chosen mortality basis and actual
-- exposure. Do not approximate amount-weighted expected benefits using an
-- unweighted mean sum assured. Benefit amounts above use incurred deaths,
-- not cash payments for deaths from other periods.

CREATE TABLE life_financials (
    period_id INTEGER NOT NULL,
    product VARCHAR(100) NOT NULL,
    earned_premium NUMERIC NOT NULL CHECK (earned_premium >= 0),
    investment_income NUMERIC NOT NULL,
    incurred_benefits NUMERIC NOT NULL CHECK (incurred_benefits >= 0),
    expense NUMERIC NOT NULL CHECK (expense >= 0),
    commission NUMERIC NOT NULL CHECK (commission >= 0),
    opening_reserve NUMERIC NOT NULL,
    closing_reserve NUMERIC NOT NULL,
    PRIMARY KEY (period_id, product)
);

CREATE TABLE life_cashflows (
    valuation_date DATE NOT NULL,
    product VARCHAR(100) NOT NULL,
    cohort VARCHAR(100) NOT NULL,
    cashflow_id INTEGER NOT NULL,
    years_from_valuation NUMERIC NOT NULL CHECK (years_from_valuation >= 0),
    expected_premium NUMERIC NOT NULL CHECK (expected_premium >= 0),
    expected_benefit NUMERIC NOT NULL CHECK (expected_benefit >= 0),
    expected_expense NUMERIC NOT NULL CHECK (expected_expense >= 0),
    annual_spot_rate NUMERIC NOT NULL CHECK (annual_spot_rate > -1),
    PRIMARY KEY (valuation_date, product, cohort, cashflow_id)
);
-- Cashflows are externally projected, probability-weighted amounts for
-- currently in-force business. Rates are annual effective spot rates for
-- each cashflow maturity. Premiums/benefits/expenses share timing and scope.
