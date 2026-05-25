SELECT j.id,j.title as Title, j.designation as Designation, c.Company_name, concat(u.first_name," ",u.last_name) as Created_by, j.no_of_opening,
j.created_at  AS Created_at,
c.id AS Client_id
FROM `job_postings` as j
LEFT JOIN users as u on j.user_id = u.id                                                                                      
LEFT JOIN clients as c on c.user_id = j.client_id
WHERE j.created_at BETWEEN '2026-01-01' AND '2026-01-31'
and c.id not in (1,2)
ORDER BY j.created_at DESC