SELECT 
    c.company_name AS company_name,
 
    jp.id AS demand_id,
 
    prev_jp.id AS last_demand_id,
 
    jp.title AS job_title_name,
 
    jp.no_of_opening AS no_of_positions,
 
    jp.user_id AS created_by_account_manager_id,
 
    CONCAT(am.first_name, ' ', am.last_name) AS account_manager_name,
 
    GROUP_CONCAT(
        DISTINCT CASE 
            WHEN u.role_id = 6 
            THEN CONCAT(u.first_name, ' ', u.last_name)
        END
    ) AS delivery_lead,
 
    GROUP_CONCAT(
        DISTINCT CASE 
            WHEN u.role_id = 3 
            THEN CONCAT(u.first_name, ' ', u.last_name)
        END
    ) AS recruiter
 
FROM job_postings jp
 
LEFT JOIN clients c 
    ON c.id = jp.client_id
 
LEFT JOIN users am 
    ON am.id = jp.user_id 
   AND am.role_id = 5
 
LEFT JOIN job_assignments ja 
    ON ja.job_posting_id = jp.id
 
LEFT JOIN users u 
    ON u.id = ja.user_id
 
LEFT JOIN job_postings prev_jp
    ON prev_jp.id = (
        SELECT MAX(id)
        FROM job_postings
        WHERE client_id = jp.client_id
          AND id < jp.id
    )
 
GROUP BY jp.id
 
ORDER BY jp.id DESC;