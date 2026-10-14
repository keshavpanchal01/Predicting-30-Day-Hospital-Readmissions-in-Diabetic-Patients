create database hospital_readmissions;
use hospital_readmissions
;

select count(*)
from diabetic_data
;

select * from diabetic_data
limit 10
;

alter table diabetic_data
modify diag_1 varchar(10)
;

SET SQL_SAFE_UPDATES = 0;


update diabetic_data
set race = nullif('race', '?'),
	weight = nullif('weight', '?'),
    payer_code = nullif('payer_code','?'),
    diag_1 = nullif('diag_1', '?'),
    diag_2 = nullif('diag_2', '?'),
	diag_3 = nullif('diag_3', '?'),
    medical_speciality = nullif('medical_specialty','?')
    ;

select 
	round(sum(weight is null)/count(*)*100,1) as pct_missing_weight,
    round(sum(payer_code is null)/count(*)*100,1) as pct_missing_payer,
    round(sum(medical_specialty is null)/count(*)*100,1) as pct_missing_specialty
from diabetic_data
;

select patient_nbr,
	count(*) as encounter_count
from diabetic_data
group by patient_nbr
having count(*) >1
order by encounter_count desc
limit 10
;

create table diabetic_data_dedup as
select t.*
from diabetic_data as t
inner join (select 
	patient_nbr,
	min(encounter_id) as first_encounter
from diabetic_data
group by patient_nbr) first_enc
on t.patient_nbr = first_enc.patient_nbr
and t.encounter_id = first_enc.first_encounter
;

select count(*) from diabetic_data_dedup
;

select discharge_disposition_id,
count(*) as encounter_count
from diabetic_data
group by discharge_disposition_id
order by encounter_count desc
;
    
select * from ids_mapping
where description like '%hospice%' or description like '%expired%'
or description like '%deceased%'
;

delete from diabetic_data_dedup
where discharge_disposition_id in (11,13,14,19,20,21,26)
;

select * from ids_mapping
;

create table discharge_disposition_map (
discharge_disposition_id int,
description varchar(150)
)
;

create table admission_source_map
( admission_source_id int,
description varchar(150)
)
;

describe discharge_disposition_map;
describe admission_source_map
;
    
INSERT INTO discharge_disposition_map (discharge_disposition_id, description) VALUES
(1, 'Discharged to home'),
(2, 'Discharged/transferred to another short term hospital'),
(3, 'Discharged/transferred to SNF'),
(4, 'Discharged/transferred to ICF'),
(5, 'Discharged/transferred to another type of inpatient care institution'),
(6, 'Discharged/transferred to home with home health service'),
(7, 'Left AMA'),
(8, 'Discharged/transferred to home under care of Home IV provider'),
(9, 'Admitted as an inpatient to this hospital'),
(10, 'Neonate discharged to another hospital for neonatal aftercare'),
(11, 'Expired'),
(12, 'Still patient or expected to return for outpatient services'),
(13, 'Hospice / home'),
(14, 'Hospice / medical facility'),
(15, 'Discharged/transferred within this institution to Medicare approved swing bed'),
(16, 'Discharged/transferred/referred another institution for outpatient services'),
(17, 'Discharged/transferred/referred to this institution for outpatient services'),
(18, NULL),
(19, 'Expired at home. Medicaid only, hospice.'),
(20, 'Expired in a medical facility. Medicaid only, hospice.'),
(21, 'Expired, place unknown. Medicaid only, hospice.'),
(22, 'Discharged/transferred to another rehab fac including rehab units of a hospital .'),
(23, 'Discharged/transferred to a long term care hospital.'),
(24, 'Discharged/transferred to a nursing facility certified under Medicaid but not certified under Medicare.'),
(25, 'Not Mapped'),
(26, 'Unknown/Invalid'),
(30, 'Discharged/transferred to another Type of Health Care Institution not Defined Elsewhere'),
(27, 'Discharged/transferred to a federal health care facility.'),
(28, 'Discharged/transferred/referred to a psychiatric hospital of psychiatric distinct part unit of a hospital'),
(29, 'Discharged/transferred to a Critical Access Hospital (CAH).');

INSERT INTO admission_source_map (admission_source_id, description) VALUES
(1, ' Physician Referral'),
(2, 'Clinic Referral'),
(3, 'HMO Referral'),
(4, 'Transfer from a hospital'),
(5, ' Transfer from a Skilled Nursing Facility (SNF)'),
(6, ' Transfer from another health care facility'),
(7, ' Emergency Room'),
(8, ' Court/Law Enforcement'),
(9, ' Not Available'),
(10, ' Transfer from critial access hospital'),
(11, 'Normal Delivery'),
(12, ' Premature Delivery'),
(13, ' Sick Baby'),
(14, ' Extramural Birth'),
(15, 'Not Available'),
(17, NULL),
(18, ' Transfer From Another Home Health Agency'),
(19, 'Readmission to Same Home Health Agency'),
(20, ' Not Mapped'),
(21, 'Unknown/Invalid'),
(22, ' Transfer from hospital inpt/same fac reslt in a sep claim'),
(23, ' Born inside this hospital'),
(24, ' Born outside this hospital'),
(25, ' Transfer from Ambulatory Surgery Center'),
(26, 'Transfer from Hospice');

select * from discharge_disposition_map;
select * from admission_source_map;

select * from diabetic_data_dedup
limit 50
;

alter table diabetic_data_dedup
add column age_midpoint int
;

UPDATE diabetic_data_dedup
SET age_midpoint = CASE
    WHEN age = '[0–10)'   THEN 5
    WHEN age = '[10–20)'  THEN 15
    WHEN age = '[20–30)'  THEN 25
    WHEN age = '[30–40)'  THEN 35
    WHEN age = '[40–50)'  THEN 45
    WHEN age = '[50–60)'  THEN 55
    WHEN age = '[60–70)'  THEN 65
    WHEN age = '[70–80)'  THEN 75
    WHEN age = '[80–90)'  THEN 85
    WHEN age = '[90–100)' THEN 95
END;


select readmitted,
	count(*) as encounter_count,
    round(count(*)/(select count(*) from diabetic_data_dedup)*100,1) as pct_of_total
from diabetic_data_dedup
group by readmitted
order by encounter_count desc
;

select age,
	age_midpoint,
    count(*) as total_encounters,
    sum(readmitted ='<30') as readmitted_under_30,
    round(sum(readmitted = '<30') / count(*)*100,1) as readmission_rate_pct
from diabetic_data_dedup
group by age, age_midpoint
order by age_midpoint
;
    
SELECT
    m.description as admission_type,
    COUNT(*) as total_encounters,
    ROUND(SUM(d.readmitted = '<30') / COUNT(*) * 100, 1) as readmission_rate_pct
FROM diabetic_data_dedup AS d
JOIN ids_mapping AS m
ON d.admission_type_id = m.admission_type_id
GROUP BY m.description
ORDER BY readmission_rate_pct DESC;


WITH patient_risk_base AS (
    SELECT
        encounter_id,
        patient_nbr,
        age_midpoint,
        time_in_hospital,
        num_medications,
        num_lab_procedures,
        number_diagnoses,
        number_inpatient,
        number_emergency,
        number_outpatient,
        diag_1,
        readmitted,
        CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END AS is_readmitted_30
    FROM diabetic_data_dedup
)
SELECT * FROM patient_risk_base
LIMIT 20;

SELECT DISTINCT age FROM diabetic_data_dedup;

UPDATE diabetic_data_dedup
SET age_midpoint = CASE age
    WHEN '[0-10)'   THEN 5
    WHEN '[10-20)'  THEN 15
    WHEN '[20-30)'  THEN 25
    WHEN '[30-40)'  THEN 35
    WHEN '[40-50)'  THEN 45
    WHEN '[50-60)'  THEN 55
    WHEN '[60-70)'  THEN 65
    WHEN '[70-80)'  THEN 75
    WHEN '[80-90)'  THEN 85
    WHEN '[90-100)' THEN 95
END;

SELECT age, age_midpoint, COUNT(*)
FROM diabetic_data_dedup
GROUP BY age, age_midpoint
ORDER BY age_midpoint;


WITH patient_risk_base AS (
    SELECT
        encounter_id, age_midpoint, num_medications, readmitted,
        CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END AS is_readmitted_30
    FROM diabetic_data_dedup
)
SELECT
    encounter_id,
    age_midpoint,
    num_medications,
    RANK() OVER (PARTITION BY age_midpoint ORDER BY num_medications DESC) as med_rank_age_group
FROM patient_risk_base
ORDER BY age_midpoint, med_rank_age_group
LIMIT 200;


WITH patient_risk_base AS (
    SELECT
        encounter_id, number_inpatient, readmitted,
        CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END AS is_readmitted_30
    FROM diabetic_data_dedup
)
SELECT
    encounter_id,
    number_inpatient,
    NTILE(4) OVER (ORDER BY number_inpatient DESC) as risk_quartile
FROM patient_risk_base;


SELECT
    encounter_id,
    num_medications,
    CASE
        WHEN num_medications <= 10 THEN 'Low'
        WHEN num_medications BETWEEN 11 AND 20 THEN 'Medium'
        ELSE 'HIGH'
    END AS medication_burden_tier,
    CASE
        WHEN number_diagnoses <= 5 THEN 'Low Complexity'
        WHEN number_diagnoses BETWEEN 6 AND 9 THEN 'Moderate Complexity'
        ELSE 'High Complexity'
    END AS diagnosis_complexity_tier
FROM diabetic_data_dedup;


WITH diag_categorized AS (
    SELECT
        encounter_id,
        readmitted,
        CASE
            WHEN diag_1 LIKE '250%' THEN 'Diabetes'
            WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 390 AND 459 THEN 'CIRCULATORY'
            WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 460 AND 519 THEN 'Respiratory'
            WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 520 AND 579 THEN 'Digestive'
            WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 580 AND 629 THEN 'Genitourinary'
            WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 800 AND 999 THEN 'Injury'
            ELSE 'Other'
        END AS diagnosis_category,
        CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END AS is_readmitted_30
    FROM diabetic_data_dedup
    WHERE diag_1 IS NOT NULL
)
SELECT
    diagnosis_category,
    COUNT(*) AS total_encounters,
    ROUND(AVG(is_readmitted_30) * 100, 1) AS readmission_rate_pct
FROM diag_categorized
GROUP BY diagnosis_category
HAVING AVG(is_readmitted_30) > (
    SELECT AVG(is_readmitted_30) FROM diag_categorized
)
ORDER BY readmission_rate_pct DESC;



SELECT
    `change`,
    COUNT(*) as total_encounters,
    ROUND(SUM(readmitted = '<30') / COUNT(*) * 100, 1) AS readmission_rate_pct
FROM diabetic_data_dedup
GROUP BY `change`;


SELECT
    m.description as discharge_disposition,
    COUNT(*) AS total_encounters,
    ROUND(SUM(d.readmitted = '<30') / COUNT(*) * 100, 1) AS readmission_rate_pct
FROM diabetic_data_dedup as d
JOIN discharge_disposition_map as m
ON d.discharge_disposition_id = m.discharge_disposition_id
GROUP BY m.description
HAVING COUNT(*) > 100
ORDER BY readmission_rate_pct DESC
LIMIT 10;



SELECT
    A1Cresult,
    COUNT(*) as total_encounters,
    ROUND(SUM(readmitted = '<30') / COUNT(*) * 100, 1) AS readmission_rate_pct
FROM diabetic_data_dedup
GROUP BY A1Cresult;