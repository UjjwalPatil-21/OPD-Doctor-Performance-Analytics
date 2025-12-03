-- Task 1: Doctor-wise OPD load monthly; top 5 busiest per branch
SELECT
    v.branch_id,
    strftime('%Y-%m', v.visit_datetime) AS month,
    v.doctor_id,
    COUNT(*) AS total_visits
FROM OPD_Visit v
GROUP BY v.branch_id, month, v.doctor_id
ORDER BY total_visits DESC;

-- Task 2: New vs Follow-up ratio per branch per month
SELECT
    branch_id,
    strftime('%Y-%m', visit_datetime) AS month,
    SUM(CASE WHEN consultation_type='New' THEN 1 ELSE 0 END) AS new_visits,
    SUM(CASE WHEN consultation_type='Follow-up' THEN 1 ELSE 0 END) AS followup_visits
FROM OPD_Visit
GROUP BY branch_id, month;

-- Task 3: Top 3 diagnoses per specialization
WITH diag AS (
    SELECT d.specialization, dx.diagnosis_name, COUNT(*) AS count_diag
    FROM OPD_Diagnosis dx
    JOIN OPD_Visit v ON dx.visit_id=v.visit_id
    JOIN Doctor d ON v.doctor_id=d.doctor_id
    GROUP BY d.specialization, dx.diagnosis_name
),
ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY specialization ORDER BY count_diag DESC) AS rn
    FROM diag
)
SELECT specialization, diagnosis_name, count_diag
FROM ranked
WHERE rn<=3;

-- Task 4: Most prescribed medicines with patient count
SELECT
    medicine_name,
    COUNT(DISTINCT visit_id) AS patient_count
FROM OPD_Prescription
GROUP BY medicine_name
ORDER BY patient_count DESC;

-- Task 5: Monthly revenue per branch (gross & net)
SELECT
    b.branch_id,
    strftime('%Y-%m', v.visit_datetime) AS month,
    SUM(bi.consultation_fee + bi.additional_charges) AS gross_revenue,
    SUM(bi.consultation_fee + bi.additional_charges - bi.discount_amount) AS net_revenue
FROM OPD_Billing bi
JOIN OPD_Visit v ON bi.visit_id=v.visit_id
JOIN Branch b ON v.branch_id=b.branch_id
GROUP BY b.branch_id, month;

-- Task 6: Avg ticket size by payment mode
SELECT
    payment_mode,
    ROUND(AVG(consultation_fee + additional_charges - discount_amount),2) AS avg_ticket_size
FROM OPD_Billing
GROUP BY payment_mode;

-- Task 7: Doctor performance: visits, revenue, avg fee
SELECT 
    d.doctor_id,
    d.doctor_name,
    d.specialization,
    COUNT(v.visit_id) AS total_visits,
    SUM(b.consultation_fee + b.additional_charges - b.discount_amount) AS total_revenue,
    ROUND(AVG(b.consultation_fee + b.additional_charges - b.discount_amount), 2) AS avg_fee
FROM Doctor d
LEFT JOIN OPD_Visit v ON d.doctor_id = v.doctor_id
LEFT JOIN OPD_Billing b ON v.visit_id = b.visit_id
GROUP BY d.doctor_id
ORDER BY total_revenue DESC;

-- Task 8: Peak hour analysis
WITH hourly_visits AS (
    SELECT 
        v.branch_id,
        strftime('%H', v.visit_datetime) AS hour,
        COUNT(*) AS visits
    FROM OPD_Visit v
    GROUP BY v.branch_id, hour
),
ranked AS (
    SELECT 
        branch_id,
        hour,
        visits,
        ROW_NUMBER() OVER (PARTITION BY branch_id ORDER BY visits DESC) AS rn
    FROM hourly_visits
)
SELECT branch_id, hour AS peak_hour, visits
FROM ranked
WHERE rn=1;
