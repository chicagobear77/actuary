"""Execute SQL and independently check sample and edge-case calculations."""
from pathlib import Path
import math
import sqlite3

root = Path(__file__).resolve().parents[1]
db = sqlite3.connect(':memory:')
db.row_factory = sqlite3.Row
for filename in ['01_schema.sql', '02_metrics.sql', '03_sample_data.sql']:
    db.executescript((root / 'sql' / filename).read_text())

def near(actual, expected):
    assert math.isclose(actual, expected, rel_tol=1e-9, abs_tol=1e-8), (actual, expected)

h = db.execute('SELECT * FROM hnb_metrics WHERE period_id=2025').fetchone()
for column, expected in {
    'premium_pmpm': 500, 'ultimate_claims_pmpm': 375,
    'reported_claims_per_1000_member_years': 2400,
    'reported_claim_severity': 4000000/2400,
    'ultimate_loss_ratio': .75, 'combined_ratio': .875,
    'underwriting_result': 750000, 'estimated_outstanding_claims': 900000,
}.items():
    near(h[column], expected)
l = db.execute('SELECT * FROM life_experience_metrics').fetchone()
near(l['mortality_ae_count'], 6/5.8)
near(l['mortality_ae_amount'], 1400000/1355000)
near(l['lapse_rate_per_exposure_year'], 130/1710)
assert l['policy_rollforward_difference'] == 0
near(db.execute('SELECT simplified_pretax_result FROM life_financial_metrics').fetchone()[0], 360000)
pv = db.execute('SELECT * FROM life_present_values').fetchone()
expected_pv = -100000/1.04 + 190000/1.04**2 + 480000/1.04**3
near(pv['prospective_net_liability'], expected_pv)
assert db.execute('SELECT COUNT(*) FROM input_quality_flags').fetchone()[0] == 0
db.executescript((root / 'sql' / '04_reports.sql').read_text())

# Empty denominators must remain undefined, not silently imply good results.
db.execute("INSERT INTO hnb_experience VALUES (2025,'Empty',0,0,0,0,0,0,'No exposure',0,0)")
empty = db.execute("SELECT * FROM hnb_metrics WHERE product='Empty'").fetchone()
assert empty['premium_pmpm'] is None
assert empty['combined_ratio'] is None
assert empty['reported_claim_severity'] is None
# Views must reflect new inputs; intentionally inconsistent input must be flagged.
db.execute("UPDATE hnb_experience SET paid_claims=100 WHERE product='Empty'")
assert db.execute("SELECT COUNT(*) FROM input_quality_flags WHERE product='Empty'").fetchone()[0] == 2
near(db.execute("SELECT estimated_ultimate FROM hnb_metrics WHERE product='Empty'").fetchone()[0], 100)
try:
    db.execute("UPDATE hnb_experience SET member_months=-1 WHERE product='Empty'")
except sqlite3.IntegrityError:
    pass
else:
    raise AssertionError('Negative exposure was accepted')
print('PASS: all SQL scripts execute; health, life, cashflow, zero-denominator, live-update, quality-flag and constraint checks passed.')
print(f'Sample prospective net liability: {expected_pv:,.2f}')
