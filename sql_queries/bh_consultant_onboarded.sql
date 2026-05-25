WITH bh_per_offer AS (
  SELECT
    c.id                                         AS client_id,
    COALESCE(
      CASE WHEN bh4.type = 'UserBusinessHead' THEN bh4.id END,
      CASE WHEN bh3.type = 'UserBusinessHead' THEN bh3.id END,
      CASE WHEN bh2.type = 'UserBusinessHead' THEN bh2.id END
    )                                            AS bh_id,
    COALESCE(
      CASE WHEN bh4.type = 'UserBusinessHead' THEN CONCAT(bh4.first_name, ' ', bh4.last_name) END,
      CASE WHEN bh3.type = 'UserBusinessHead' THEN CONCAT(bh3.first_name, ' ', bh3.last_name) END,
      CASE WHEN bh2.type = 'UserBusinessHead' THEN CONCAT(bh2.first_name, ' ', bh2.last_name) END
    )                                            AS bh_name
  FROM offer_letters ol
  JOIN clients   c   ON c.user_id = ol.client_id
  JOIN users     rec ON rec.id    = ol.created_by_id
  LEFT JOIN users bh2 ON bh2.id   = rec.reporting_to
  LEFT JOIN users bh3 ON bh3.id   = bh2.reporting_to
  LEFT JOIN users bh4 ON bh4.id   = bh3.reporting_to
  WHERE ol.status IN (5, 6)
    AND ol.employee_type <> 0
    AND ol.job_posting_id IS NOT NULL
    AND ol.client_onboard_date IS NOT NULL
    AND ol.client_onboard_date <= CURDATE()
),
client_bh_counts AS (
  SELECT client_id, bh_id, bh_name, COUNT(*) AS offer_count
  FROM bh_per_offer
  WHERE bh_name IS NOT NULL
  GROUP BY client_id, bh_id, bh_name
),
client_primary_bh AS (
  SELECT client_id, bh_id, bh_name, offer_count
  FROM (
    SELECT client_id, bh_id, bh_name, offer_count,
           ROW_NUMBER() OVER (PARTITION BY client_id ORDER BY offer_count DESC) AS rn
    FROM client_bh_counts
  ) ranked
  WHERE rn = 1
)
SELECT
  ol.id                       AS offer_letter_id,
  ol.candidate_id,
  u.email,
  ol.full_name,
  ol.designation,
  ol.joining_date,
  ol.client_onboard_date,
  ol.employee_type,
  ol.client_id,
  c.company_name,
  c.min_margin_percentage     AS client_margin_pct,
  c.target_margin             AS client_target_margin,
  ol.job_posting_id,
  ol.ctc                      AS ctc_text,
  ol.total_ctc                AS total_ctc_text,
  ol.variable_comp,
  sb.total                    AS ctc_numeric,
  sb.gross_earning,
  sb.basic,
  sb.hra,
  sb.special_allowance,
  ol.p_o_value,
  ol.margin,
  cbh.bh_name                 AS business_head_name,
  cbh.offer_count             AS bh_attributed_offers_for_client
FROM offer_letters ol
LEFT JOIN users             u   ON u.id              = ol.candidate_id
LEFT JOIN clients           c   ON c.user_id         = ol.client_id
LEFT JOIN salary_breakups   sb  ON sb.offer_letter_id = ol.id
LEFT JOIN client_primary_bh cbh ON cbh.client_id    = c.id
WHERE ol.status IN (5, 6)
  AND ol.employee_type <> 0
  AND ol.job_posting_id IS NOT NULL
  AND ol.client_onboard_date IS NOT NULL
  AND ol.client_onboard_date <= CURDATE()
