-- Regional exposure concentration
-- Underwriting team needs this for capacity planning
-- Should flag regions where we're overexposed

SELECT
    cust.region,
    pol.policy_type,
    COUNT(DISTINCT pol.policy_id) as active_policies,
    SUM(pol.coverage_limit) as total_exposure,
    SUM(pol.premium_amount) as total_premium,
    SAFE_DIVIDE(SUM(pol.coverage_limit), SUM(pol.premium_amount)) as leverage_ratio,
    MAX(pol.coverage_limit) as max_single_exposure,
    PERCENTILE_CONT(pol.coverage_limit, 0.95) OVER (PARTITION BY cust.region) as p95_exposure
FROM `project.raw_insurance.policies` pol
JOIN `project.raw_insurance.customers` cust ON pol.customer_id = cust.customer_id
WHERE pol.status = 'active'
    AND pol.expiration_date > CURRENT_DATE()
GROUP BY 1, 2
HAVING total_exposure > 1000000
ORDER BY total_exposure DESC;
