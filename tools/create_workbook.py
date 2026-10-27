"""Generate the example insurance pricing workbook (requires XlsxWriter)."""
from pathlib import Path
import xlsxwriter

ROOT = Path(__file__).resolve().parents[1]
book = xlsxwriter.Workbook(ROOT / 'Insurance_Premium_Calculator.xlsx')
book.set_calc_mode('auto')
title = book.add_format({'bold': True, 'font_size': 20, 'font_color': '#17324D'})
head = book.add_format({'bold': True, 'bg_color': '#17324D', 'font_color': 'white'})
input_num = book.add_format({'bg_color': '#E8F3FF', 'font_color': '#1565C0', 'num_format': '#,##0.00'})
input_pct = book.add_format({'bg_color': '#E8F3FF', 'font_color': '#1565C0', 'num_format': '0.0%'})
money = book.add_format({'num_format': '$#,##0.00'})
number = book.add_format({'num_format': '#,##0.00'})
pct = book.add_format({'num_format': '0.0%'})
note = book.add_format({'text_wrap': True, 'font_color': '#526477', 'valign': 'top'})
result = book.add_format({'bold': True, 'bg_color': '#E5F4ED', 'num_format': '$#,##0.00'})

def sheet(name):
    ws = book.add_worksheet(name)
    ws.hide_gridlines(2)
    ws.set_column('A:A', 38)
    ws.set_column('B:B', 23)
    ws.set_column('C:C', 67)
    ws.freeze_panes(3, 1)
    return ws

guide = sheet('Start Here')
guide.merge_range('A1:C1', 'Insurance Premium Calculator', title)
instructions = [
    ('Purpose', 'Illustrative annual insurance pricing using expected claim frequency and severity.'),
    ('1. Review sample history', 'Experience contains synthetic annual data. Replace blue cells with your own data; exposure means policy-years.'),
    ('2. Set assumptions', 'Inputs controls frequency, severity, trend, expenses, and target profit. Blue cells are editable; other cells contain formulas.'),
    ('3. Review the price', 'Pricing calculates annual premium per policy and expected portfolio totals. Sensitivity compares nine frequency/severity scenarios.'),
    ('Units', 'Currency is USD; frequency is claims per policy-year; severity is dollars per claim. Annual premium is dollars per policy-year.'),
    ('Model scope', 'Uses a frequency × severity expected-loss model. No deductibles, limits, investment income, taxes, reinsurance, or credibility adjustments are modeled.'),
    ('Important', 'Sample data and assumptions are fictional. This is a learning and planning template; it is not a rate filing or a professionally validated insurance quote.'),
    ('Formula updates', 'Open in Excel or another compatible spreadsheet application to recalculate after edits. Cached initial results are included.'),
]
for r, (label, value) in enumerate(instructions, 3):
    guide.write(r, 0, label, head)
    guide.merge_range(r, 1, r, 2, value, note)
    guide.set_row(r, 48)

history = sheet('Experience')
history.merge_range('A1:F1', 'Synthetic claims experience', title)
history.set_column('A:F', 21)
history.write_row('A3', ['Year', 'Policy-years', 'Claim count', 'Total claims ($)', 'Frequency', 'Severity ($)'], head)
data = [(2023, 900, 65, 292500), (2024, 1000, 78, 374400), (2025, 1100, 88, 440000)]
for row, values in enumerate(data, 3):
    for col, value in enumerate(values):
        history.write_number(row, col, value, input_num)
    excel = row + 1
    history.write_formula(row, 4, f'=IFERROR(C{excel}/B{excel},0)', pct, values[2]/values[1])
    history.write_formula(row, 5, f'=IFERROR(D{excel}/C{excel},0)', money, values[3]/values[2])
for col, value in [(1,3000),(2,231),(3,1106900)]:
    letter = chr(65+col)
    history.write_formula(7,col,f'=SUM({letter}4:{letter}6)',number,value)
history.write('A8','Total / weighted average',head)
history.write_formula('E8','=IFERROR(C8/B8,0)',pct,0.077)
severity = 1106900 / 231
history.write_formula('F8','=IFERROR(D8/C8,0)',money,severity)
history.data_validation('B4:B6', {'validate':'decimal','criteria':'>','value':0})
history.data_validation('C4:C6', {'validate':'integer','criteria':'>=','value':0})
history.data_validation('D4:D6', {'validate':'decimal','criteria':'>=','value':0})
history.merge_range('A10:F11', 'Claims are assumed fully developed, with consistent coverage and exposure definitions. The weighted severity pools nominal historical dollars; select an appropriate base date and adjust for development or past inflation before using real data.', note)

inputs = sheet('Inputs')
inputs.merge_range('A1:C1','Pricing assumptions',title)
inputs.write_row('A3',['Assumption','Value','Meaning'],head)
assumptions = [
    ('Annual claim frequency', '=Experience!E8', .077, input_pct, 'Defaults to weighted historical frequency; may be overwritten.'),
    ('Average claim severity', '=Experience!F8', severity, input_num, 'Defaults to weighted historical severity; may be overwritten.'),
    ('Annual severity trend', .05, None, input_pct, 'Applied from the selected severity base date to the pricing period.'),
    ('Trend years', 1, None, input_num, 'Time from selected severity base date to pricing period midpoint.'),
    ('Fixed expense per policy', 50, None, input_num, 'Annual administration expense in dollars per policy.'),
    ('Variable expense ratio', .20, None, input_pct, 'Acquisition and other expenses as a fraction of premium.'),
    ('Target underwriting profit ratio', .10, None, input_pct, 'Expected underwriting profit divided by premium.'),
    ('Projected policy-years', 1000, None, input_num, 'Expected annual exposure for portfolio totals.'),
]
for r,(label,value,cache,fmt,meaning) in enumerate(assumptions,3):
    inputs.write(r,0,label)
    if isinstance(value,str): inputs.write_formula(r,1,value,fmt,cache)
    else: inputs.write_number(r,1,value,fmt)
    inputs.write(r,2,meaning,note)
    inputs.set_row(r,32)
inputs.data_validation('B4:B8',{'validate':'decimal','criteria':'>=','value':0})
inputs.data_validation('B9:B10',{'validate':'custom','value':'=AND(ISNUMBER(B9),B9>=0,B9<1,SUM($B$9:$B$10)<1)','error_message':'Ratios must be nonnegative and sum to less than 100%.','error_type':'stop'})
inputs.data_validation('B11',{'validate':'decimal','criteria':'>','value':0})
inputs.write('A13','Input status',head)
valid = 'AND(COUNT(B4:B11)=8,MIN(B4:B10)>=0,B11>0,SUM(B9:B10)<1)'
inputs.write_formula('B13',f'=IF({valid},"OK","CHECK INPUTS")',None,'OK')
inputs.merge_range('A15:C16','Zero claims produce zero historical severity; select a credible severity assumption before pricing. Validation is a convenience: pasted values can bypass it, so confirm the input status before relying on results.',note)

pricing = sheet('Pricing')
pricing.merge_range('A1:C1','Annual indicated premium',title)
pricing.write_row('A3',['Metric','Value','Calculation'],head)
loss = .077 * severity * 1.05
premium = (loss+50)/.7
metrics = [
    ('Trended claim severity','=Inputs!B5*(1+Inputs!B6)^Inputs!B7',severity*1.05,money,'Base severity × (1 + annual trend) ^ trend years'),
    ('Expected claims cost per policy','=Inputs!B4*B4',loss,money,'Frequency × trended severity'),
    ('Fixed expense per policy','=Inputs!B8',50,money,'From Inputs'),
    ('Available premium fraction','=1-Inputs!B9-Inputs!B10',.7,pct,'1 − variable expense ratio − profit ratio'),
    ('Annual premium per policy','=(B5+B6)/B7',premium,result,'(Expected claims + fixed expense) / available fraction'),
    ('Monthly equivalent','=B8/12',premium/12,money,'Annual premium / 12; no installment fees modeled'),
    ('Expected loss ratio','=B5/B8',loss/premium,pct,'Expected claims / premium'),
    ('Projected portfolio premium','=B8*Inputs!B11',premium*1000,money,'Annual premium × projected policy-years'),
    ('Projected portfolio claims','=B5*Inputs!B11',loss*1000,money,'Expected claims cost × projected policy-years'),
    ('Projected portfolio expenses','=(B6+B8*Inputs!B9)*Inputs!B11',(50+premium*.2)*1000,money,'Fixed expenses plus variable expenses'),
    ('Projected underwriting profit','=B11-B12-B13',premium*.1*1000,money,'Portfolio premium − claims − expenses'),
]
for r,(label,formula,cache,fmt,meaning) in enumerate(metrics,3):
    pricing.write(r,0,label)
    pricing.write_formula(r,1,f'=IF(Inputs!B13="OK",{formula[1:]},NA())',fmt,cache)
    pricing.write(r,2,meaning,note)
pricing.write_row('E3',['Premium component','Annual dollars'],head)
pricing.set_column('E:E',23)
pricing.set_column('F:F',19)
for r,(label,formula,value) in enumerate([
    ('Claims','=B5',loss),('Fixed expense','=B6',50),
    ('Variable expense','=B8*Inputs!B9',premium*.2),('Profit','=B8*Inputs!B10',premium*.1)],3):
    pricing.write(r,4,label)
    pricing.write_formula(r,5,formula,money,value)
chart = book.add_chart({'type':'column'})
chart.add_series({'name':'Annual premium components','categories':'=Pricing!$E$4:$E$7','values':'=Pricing!$F$4:$F$7','fill':{'color':'#247B91'}})
chart.set_title({'name':'Where the annual premium goes'})
chart.set_y_axis({'name':'USD per policy-year','num_format':'$#,##0'})
chart.set_legend({'none':True})
pricing.insert_chart('E10',chart,{'x_scale':1.15})

scenario = sheet('Sensitivity')
scenario.merge_range('A1:D1','Annual premium sensitivity',title)
scenario.set_column('A:D',24)
scenario.write('A3','Frequency / severity',head)
for col,factor in enumerate([.9,1,1.1],1):
    scenario.write_number(2,col,factor,pct)
for row,factor in enumerate([.9,1,1.1],3):
    scenario.write_number(row,0,factor,pct)
    for col,sev_factor in enumerate([.9,1,1.1],1):
        letter=chr(65+col)
        formula=f'=IF(Inputs!B13="OK",(Inputs!B4*$A{row+1}*Pricing!$B$4*{letter}$3+Inputs!B8)/(1-Inputs!B9-Inputs!B10),NA())'
        scenario.write_formula(row,col,formula,money,(loss*factor*sev_factor+50)/.7)
scenario.conditional_format('B4:D6',{'type':'3_color_scale'})
scenario.merge_range('A9:D10','Row factors multiply claim frequency; column factors multiply trended severity. Expenses and target profit remain unchanged. The center cell matches the annual premium on Pricing.',note)
book.close()
print(ROOT / 'Insurance_Premium_Calculator.xlsx')
