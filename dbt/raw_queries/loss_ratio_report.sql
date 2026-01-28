-- Monthly loss ratio by policy type
-- Used by the actuarial team for quarterly reviews
-- TODO: migrate to dbt

SELECT
    p.policy_type,
    DATE_TRUNC(c.filed_date, MONTH) as report_month,
    COUNT(DISTINCT p.policy_id) as policy_count,
    SUM(p.premium_amount) as total_premium,
    COUNT(c.claim_id) as claim_count,
    SUM(c.claim_amount) as total_incurred,
    SUM(c.approved_amount) as total_paid,
    SAFE_DIVIDE(SUM(c.approved_amount), SUM(p.premium_amount)) as loss_ratio,
    SAFE_DIVIDE(SUM(c.claim_amount), COUNT(DISTINCT p.policy_id)) as avg_claim_per_policy
FROM `project.raw_insurance.policies` p
LEFT JOIN `project.raw_insurance.claims` c ON p.policy_id = c.policy_id
WHERE p.status = 'active'
    AND c.filed_date >= '2023-01-01'
GROUP BY 1, 2
ORDER BY 1, 2;
