# Golden Truth Queries

Analyst-validated canonical queries for the J2W Offer Letter database. All date ranges are placeholders — adjust to your reporting period.

Standard filters applied across all queries:
- `clients.id NOT IN (1, 2)` — excludes test/internal clients
- Dates stored in UTC; use `CONVERT_TZ(col, '+00:00', '+05:30')` for IST display

---

## 1. Submissions

Candidates submitted to clients (`applied_jobs.current_step > 6`).

```sql
SELECT
    CONVERT_TZ(aj.created_at, '+00:00', '+05:30') AS date,
    CONVERT_TZ(aj.updated_at, '+00:00', '+05:30') AS Updation_date,
    jp.id AS job_ID,
    jp.client_job_id AS client_job_id,
    jp.title AS title,
    cl.company_name AS client,
    CONCAT(u.first_name, ' ', u.last_name) AS Candidate,
    ud.contact_phone AS contact,
    u.email AS mail_ID,
    cw.workflow_step AS status,
    r.reason,
    CONCAT(us.first_name, ' ', us.last_name) AS Recruiter1,
    CONCAT(usr.first_name, ' ', usr.last_name) AS Lead1,
    CONCAT(users.first_name, ' ', users.last_name) AS Manager,
    aj.current_step
FROM applied_jobs AS aj
LEFT JOIN job_postings AS jp ON aj.job_posting_id = jp.id
LEFT JOIN users AS u ON aj.user_id = u.id
LEFT JOIN users AS us ON aj.applied_by_id = us.id
LEFT JOIN clients AS cl ON jp.client_id = cl.user_id
LEFT JOIN candidate_work_flows AS cw ON aj.current_step = cw.step_id
LEFT JOIN reasons AS r ON aj.id = r.applied_job_id
LEFT JOIN users AS usr ON us.reporting_to = usr.id
LEFT JOIN users ON usr.reporting_to = users.id
LEFT JOIN user_details AS ud ON u.id = ud.user_id
WHERE aj.created_at BETWEEN '2026-04-01' AND '2026-06-01'
  AND aj.current_step > 6
  AND jp.id
  AND cl.id NOT IN (1, 2)
GROUP BY Manager, Lead1, Recruiter1, Candidate, contact, mail_ID,
         Updation_date, status, job_ID, client, r.reason, Updation_date;
```

---

## 2. Interviews

Interview schedules from `validation_screens`.

```sql
SELECT
    us.email,
    cwf.workflow_step,
    jp.id AS job_id,
    CONCAT(ur.first_name, ' ', ur.last_name) AS Recruiter1,
    CONCAT(vs.interview_date, ' ', vs.interview_time) AS Interview_date,
    cl.company_name,
    cl.id AS client_id
FROM validation_screens AS vs
LEFT JOIN users AS us ON us.id = vs.applied_candidate_id
LEFT JOIN candidate_work_flows AS cwf ON cwf.step_id = vs.candidate_work_flow_step
LEFT JOIN job_postings AS jp ON jp.id = vs.applied_candidate_for_job_id
LEFT JOIN applied_jobs AS aj ON aj.job_posting_id = jp.id AND aj.user_id = us.id
LEFT JOIN users AS ur ON ur.id = aj.applied_by_id
LEFT JOIN clients AS cl ON jp.client_id = cl.user_id
WHERE interview_date BETWEEN '2026-04-01' AND '2026-06-01'
  AND jp.id
  AND cl.id NOT IN (1, 2);
```

---

## 3. Selections

Candidates selected via `selected_candidates`.

```sql
SELECT
    CONCAT(u.first_name, ' ', u.last_name) AS recruiter,
    CONCAT(usr.first_name, ' ', usr.last_name) AS Lead1,
    jp.id,
    CONCAT(m.first_name, ' ', m.last_name) AS Manager,
    CONCAT(us.first_name, ' ', us.last_name) AS candidate,
    us.email,
    ol.status,
    ol.joining_date,
    sc.created_at AS selection_date,
    DATE(aj.created_at) AS Submission_date,
    c.company_name,
    sc.po,
    sc.margin,
    aj.current_step,
    c.id AS Client_id
FROM selected_candidates AS sc
LEFT JOIN applied_jobs AS aj ON sc.applied_jobs_id = aj.id
LEFT JOIN offer_letters AS ol ON aj.user_id = ol.candidate_id
LEFT JOIN users AS u ON aj.applied_by_id = u.id
LEFT JOIN users AS us ON aj.user_id = us.id
JOIN job_postings AS jp ON jp.id = aj.job_posting_id
JOIN clients AS c ON jp.client_id = c.user_id
LEFT JOIN users AS usr ON u.reporting_to = usr.id
LEFT JOIN users AS m ON usr.reporting_to = m.id
LEFT JOIN validation_screens AS vs ON vs.applied_candidate_id = ol.candidate_id
LEFT JOIN candidate_work_flows AS cwf ON vs.candidate_work_flow_step = cwf.step_id
WHERE sc.created_at BETWEEN '2026-04-01' AND '2026-06-01'
  AND jp.id
  AND c.id NOT IN (1, 2)
  AND cwf.step_id NOT IN ('24', '42')
GROUP BY us.email;
```

---

## 4. Onboarding

Onboarded employees (`offer_letters.status IN (5, 6)`), filtered by `client_onboard_date`.

```sql
SELECT
    CONCAT(users.first_name, ' ', users.last_name) AS recruiter_name,
    CONCAT(usr.first_name, ' ', usr.last_name) AS 'Lead',
    CONCAT(us.first_name, ' ', us.last_name) AS manager_name,
    offer_letters.full_name,
    offer_letters.employee_type,
    ed.employee_id,
    offer_letters.joining_date AS display_date,
    offer_letters.p_o_value,
    offer_letters.margin AS margin,
    offer_letters.job_posting_id,
    clients.company_name,
    offer_letters.status AS Status,
    selected_candidates.created_at AS Selection_date,
    offer_letters.created_at AS offer_created_date
FROM offer_letters
LEFT JOIN users ON offer_letters.created_by_id = users.id
LEFT JOIN users AS us ON offer_letters.approved_by_id = us.id
LEFT JOIN clients ON offer_letters.client_id = clients.user_id
LEFT JOIN employee_details AS ed ON offer_letters.id = ed.offer_letter_id
LEFT JOIN users AS usr ON users.reporting_to = usr.id
LEFT JOIN applied_jobs AS aj ON aj.user_id = offer_letters.candidate_id
LEFT JOIN selected_candidates ON selected_candidates.applied_jobs_id = aj.id
WHERE offer_letters.status IN (5, 6)
  AND clients.id NOT IN (1, 2)
  AND offer_letters.client_onboard_date BETWEEN '2026-05-01' AND '2026-05-31'
  AND offer_letters.employee_type != 0
  AND offer_letters.job_posting_id
GROUP BY offer_letters.full_name, ed.employee_id;
```

### 4a. Onboarding (filtered by specific job posting)

Same as above but filtered to a single demand.

```sql
SELECT
    CONCAT(users.first_name, ' ', users.last_name) AS recruiter_name,
    CONCAT(usr.first_name, ' ', usr.last_name) AS 'Lead',
    CONCAT(us.first_name, ' ', us.last_name) AS manager_name,
    offer_letters.full_name,
    offer_letters.employee_type,
    ed.employee_id,
    offer_letters.joining_date AS display_date,
    offer_letters.p_o_value,
    offer_letters.margin AS margin,
    offer_letters.job_posting_id,
    clients.company_name,
    offer_letters.status AS Status,
    selected_candidates.created_at AS Selection_date,
    offer_letters.created_at AS offer_created_date
FROM offer_letters
LEFT JOIN users ON offer_letters.created_by_id = users.id
LEFT JOIN users AS us ON offer_letters.approved_by_id = us.id
LEFT JOIN clients ON offer_letters.client_id = clients.user_id
LEFT JOIN employee_details AS ed ON offer_letters.id = ed.offer_letter_id
LEFT JOIN users AS usr ON users.reporting_to = usr.id
LEFT JOIN applied_jobs AS aj ON aj.user_id = offer_letters.candidate_id
LEFT JOIN selected_candidates ON selected_candidates.applied_jobs_id = aj.id
WHERE offer_letters.status IN (5, 6)
  AND clients.id NOT IN (1, 2)
  AND offer_letters.employee_type != 0
  AND offer_letters.job_posting_id
  AND offer_letters.job_posting_id = 105201
GROUP BY offer_letters.full_name, ed.employee_id;
```

---

## 5. Demands

Job postings / requirements from clients.

### 5a. Basic demand listing

```sql
SELECT
    j.id,
    j.title AS Title,
    j.designation AS Designation,
    c.company_name,
    CONCAT(u.first_name, ' ', u.last_name) AS Created_by,
    j.no_of_opening,
    j.created_at AS Created_at,
    c.id AS Client_id
FROM job_postings AS j
LEFT JOIN users AS u ON j.user_id = u.id
LEFT JOIN clients AS c ON c.user_id = j.client_id
WHERE j.created_at BETWEEN '2026-01-01' AND '2026-01-31'
  AND c.id NOT IN (1, 2)
ORDER BY j.created_at DESC;
```

### 5b. Demand listing with salary range

```sql
SELECT
    j.id,
    j.title AS Title,
    j.designation AS Designation,
    c.company_name,
    CONCAT(u.first_name, ' ', u.last_name) AS Created_by,
    j.no_of_opening,
    j.created_at AS Created_at,
    c.id AS Client_id,
    j.salary_from,
    j.salary_to
FROM job_postings AS j
LEFT JOIN users AS u ON j.user_id = u.id
LEFT JOIN clients AS c ON c.user_id = j.client_id
WHERE j.created_at BETWEEN '2026-01-01' AND '2026-01-31'
  AND c.id NOT IN (1, 2)
ORDER BY j.created_at DESC;
```

---

## 6. Exits (Completed)

Employees who have exited (`status = 6`), excluding "No Show".

```sql
SELECT
    recruiter_name,
    CONCAT(us.first_name, ' ', us.last_name) AS manager_name,
    Employee_Information.full_name,
    Employee_Information.employee_type,
    employee_id,
    Employee_Information.joining_date,
    Employee_Information.p_o_value,
    Employee_Information.margin,
    Employee_Information.exit_type,
    Employee_Information.company_name,
    Employee_Information.status,
    ec2.last_work_day
FROM Employee_Information
LEFT JOIN exited_candidates AS ec2 ON ec2.offer_letter_id = Employee_Information.offer_letter_id
LEFT JOIN retained_employees ON ec2.offer_letter_id = retained_employees.offer_letter_id
LEFT JOIN users AS us ON Employee_Information.approved_by_id = us.id
LEFT JOIN offer_letters ON Employee_Information.offer_letter_id = offer_letters.id
LEFT JOIN clients ON offer_letters.client_id = clients.user_id
WHERE Employee_Information.last_work_day BETWEEN '2025-09-01' AND '2025-09-30'
  AND Employee_Information.status = 6
  AND clients.id NOT IN (1, 2)
  AND Employee_Information.employee_type != 0
  AND Employee_Information.exit_type != 'No Show'
GROUP BY Employee_Information.offer_letter_id;
```

---

## 7. Exits (In Progress)

Employees with exit initiated but not yet completed (`exit_status = 0`).

```sql
SELECT
    recruiter_name,
    CONCAT(us.first_name, ' ', us.last_name) AS manager_name,
    Employee_Information.full_name,
    Employee_Information.employee_type,
    employee_id,
    Employee_Information.joining_date,
    Employee_Information.p_o_value,
    Employee_Information.margin,
    Employee_Information.exit_type,
    Employee_Information.company_name,
    Employee_Information.status,
    ec2.tentative_exit_date
FROM Employee_Information
LEFT JOIN exited_candidates AS ec2 ON ec2.offer_letter_id = Employee_Information.offer_letter_id
LEFT JOIN retained_employees ON ec2.offer_letter_id = retained_employees.offer_letter_id
LEFT JOIN users AS us ON Employee_Information.approved_by_id = us.id
LEFT JOIN offer_letters ON Employee_Information.offer_letter_id = offer_letters.id
LEFT JOIN clients ON offer_letters.client_id = clients.user_id
WHERE Employee_Information.exit_status = 0
  AND clients.id NOT IN (1, 2)
  AND Employee_Information.employee_type != 0
GROUP BY Employee_Information.offer_letter_id;
```

---

## 8. Demand ID Mapping (Current to Previous)

Maps each demand to the previous demand for the same client, with assigned recruiter and delivery lead.

```sql
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
LEFT JOIN clients c ON c.id = jp.client_id
LEFT JOIN users am ON am.id = jp.user_id AND am.role_id = 5
LEFT JOIN job_assignments ja ON ja.job_posting_id = jp.id
LEFT JOIN users u ON u.id = ja.user_id
LEFT JOIN job_postings prev_jp ON prev_jp.id = (
    SELECT MAX(id)
    FROM job_postings
    WHERE client_id = jp.client_id
      AND id < jp.id
)
GROUP BY jp.id
ORDER BY jp.id DESC;
```
