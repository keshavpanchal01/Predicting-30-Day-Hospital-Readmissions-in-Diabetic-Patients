# Hospital Readmissions Analysis (Diabetic Patients)

**Question:** Which diabetic patients and hospital stays are most likely to be readmitted within 30 days?

**Data:** Diabetes 130-US Hospitals (1999–2008, UCI). 101,766 encounters, 50 columns. Target: `readmitted = '<30'`.

**Tools:** MySQL 8 (CTEs, window functions, joins).

## Files
- `SQL File.sql`: all cleaning and analysis queries, in order
- `Data Used.csv`: encounter data (`diabetic_data`)
- `IDS_Mapping.csv`: ID-to-description lookup (`ids_mapping`)

## Method
1. **Clean:** convert `?` to `NULL`, check missingness (weight, payer code, specialty).
2. **De-duplicate:** keep each patient's first encounter only.
3. **Exclude:** drop deaths and hospice discharges, since those patients can't be readmitted.
4. **Engineer:** age midpoint, 30-day flag, medication-burden tiers, diagnosis-complexity tiers, ICD-9 diagnosis groups.
5. **Analyze:** readmission rate by age, admission type, diagnosis group, discharge destination, medication change, and HbA1c result. Also uses `RANK()` and `NTILE()` for risk ranking.

## Key Findings
- Overall 30-day readmission rate: **X%**
- Highest-risk age group: **...**
- Highest-risk diagnosis group: **...**
- Highest-risk discharge destination: **...**
- Medication change vs. none: **X% vs Y%**

## Run it
Import both CSVs into MySQL, then run `SQL File.sql` top to bottom.

## Limitations
Many missing values in weight, payer code and specialty. First-encounter-only filtering hides repeat-admission patterns. Data is US-only and 1999–2008. Results show association, not cause.
