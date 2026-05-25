Query to get the submission: 

select CONVERT_Tz(aj.created_at,'+00:00','+05:30') as  date,CONVERT_Tz(aj.updated_at,'+00:00','+05:30') Updation_date ,jp.id as job_ID, jp.client_job_id as client_job_id, jp.title as title, cl.company_name as client, concat(u.first_name," ",u.last_name) as Candidate,ud.contact_phone as contact,u.email as mail_ID, cw.workflow_step as status , r.reason, concat(us.first_name," ",us.last_name) as Recruiter1,concat(usr.first_name," ",usr.last_name) as Lead1,concat(users.first_name," ",users.last_name) as Manager, aj.current_step   from applied_jobs as aj left join job_postings as jp on aj.job_posting_id=jp.id left join users as u on aj.user_id = u.id left join users as us on aj.applied_by_id=us.id left join clients as cl on jp.client_id=cl.user_id left join candidate_work_flows as cw on aj.current_step=cw.step_id  left join reasons as r on aj.id = r.applied_job_id left join users as usr on us.reporting_to = usr.id left join users on usr.reporting_to = users.id left join user_details as ud on u.id=ud.user_id where aj.created_at between '2026-04-01' and '2026-06-01' and aj.current_step >6 and jp.id  

and cl.id not in (1,2)  group by Manager,Lead1,Recruiter1,Candidate,contact,mail_ID,Updation_date,status,job_ID,client,r.reason,Updation_date 

 

Query to get the interview : 

SELECT us.email,cwf.workflow_step, jp.id as job_id,concat(ur.first_name," ",ur.last_name) as Recruiter1, concat(vs.interview_date," ",vs.interview_time) as Interview_date , cl.company_name , cl.id as client_id FROM `validation_screens` as vs 

LEFT JOIN users as us on us.id=vs.applied_candidate_id 

LEFT JOIN candidate_work_flows as cwf on cwf.step_id=vs.candidate_work_flow_step 

LEFT JOIN job_postings as jp on jp.id = vs.applied_candidate_for_job_id 

LEFT JOIN applied_jobs as aj on aj.job_posting_id=jp.id and aj.user_id=us.id 

left JOIN users as ur on ur.id=aj.applied_by_id 

left join clients as cl on jp.client_id=cl.user_id  

 

WHERE interview_date BETWEEN '2026-04-01' and '2026-06-01' and jp.id 

and cl.id not in (1,2) 

Query to get the Selection: 

select concat(u.first_name," ",u.last_name) as recruiter ,concat(usr.first_name," ",usr.last_name) as Lead1 ,jp.id,concat(m.first_name," ",m.last_name) as Manager, 

concat(us.first_name," ",us.last_name) as candidate, 

us.email,ol.status,ol.joining_date,sc.created_at  as selection_date,date(aj.created_at) as Submission_date,c.company_name,sc.po,sc.margin,aj.current_step, c.id AS Client_id from selected_candidates as sc  

left join applied_jobs as aj on sc.applied_jobs_id=aj.id  

left join offer_letters as ol on aj.user_id=ol.candidate_id 

left join users as u on aj.applied_by_id=u.id 

left join users as us on aj.user_id=us.id 

join job_postings as jp ON jp.id=aj.job_posting_id 

JOIN clients as c ON jp.client_id=c.user_id 

left join users as usr on u.reporting_to=usr.id  

left join users as m on usr.reporting_to=m.id  

LEFT JOIN validation_screens AS VS ON VS.applied_candidate_id = ol.candidate_id 

LEFT JOIN candidate_work_flows AS cwf ON VS.candidate_work_flow_step = cwf.step_id 

 

where sc.created_at between '2026-04-01' AND '2026-06-01'  and jp.id  and c.id not in (1,2)  

AND cwf.step_id NOT IN ('24','42') 

GROUP BY us.email 

Query to get the Onboarding: 

 

select concat(users.first_name,' ', users.last_name) as recruiter_name ,concat(usr.first_name,' ', usr.last_name) as ‘Lead’ , concat (us.first_name , ' ' , us.last_name) as manager_name, offer_letters.full_name, offer_letters.employee_type, ed.employee_id,offer_letters. joining_date as display_date ,offer_letters.p_o_value,offer_letters.margin as margin,offer_letters.job_posting_id,clients.company_name,offer_letters.status as Status, selected_candidates.created_at as Selection_date, offer_letters.created_at as offer_created_date 

from offer_letters left join users on offer_letters.created_by_id = users.id 

left join users as us on offer_letters.approved_by_id = us.id  

left join clients on offer_letters.client_id = clients.user_id  

left join employee_details as ed on offer_letters.id=ed.offer_letter_id  

left join users as usr on users.reporting_to=usr.id 

left join applied_jobs as aj on aj.user_id = offer_letters.candidate_id 

left join selected_candidates on selected_candidates.applied_jobs_id = aj.id 

where offer_letters.status IN(5,6) and clients.id not in (1,2) and offer_letters.client_onboard_date between '2026-05-01' AND '2026-05-31' and offer_letters.employee_type != 0 AND offer_letters.job_posting_id  

GROUP BY offer_letters.full_name,ed.employee_id 

Demands:
SELECT j.id,j.title as Title, j.designation as Designation, c.Company_name, concat(u.first_name," ",u.last_name) as Created_by, j.no_of_opening,
j.created_at  AS Created_at,
c.id AS Client_id
FROM `job_postings` as j
LEFT JOIN users as u on j.user_id = u.id                                                                                      
LEFT JOIN clients as c on c.user_id = j.client_id
WHERE j.created_at BETWEEN '2026-01-01' AND '2026-01-31'
and c.id not in (1,2)
ORDER BY j.created_at DESC



SELECT j.id,j.title as Title, j.designation as Designation, c.Company_name, concat(u.first_name," ",u.last_name) as Created_by, j.no_of_opening,
j.created_at  AS Created_at,
c.id AS Client_id,j.salary_from,j.salary_to
FROM `job_postings` as j 
LEFT JOIN users as u on j.user_id = u.id 	
LEFT JOIN clients as c on c.user_id = j.client_id 
WHERE j.created_at BETWEEN '2026-01-01' AND '2026-01-31'
and c.id not in (1,2) 
ORDER BY j.created_at DESC

select concat(users.first_name,' ', users.last_name) as recruiter_name ,concat(usr.first_name,' ', usr.last_name) as ‘Lead’ , concat (us.first_name , ' ' , us.last_name) as manager_name, offer_letters.full_name, offer_letters.employee_type, ed.employee_id,offer_letters. joining_date as display_date ,offer_letters.p_o_value,offer_letters.margin as margin,offer_letters.job_posting_id,clients.company_name,offer_letters.status as Status, selected_candidates.created_at as Selection_date, offer_letters.created_at as offer_created_date

from offer_letters left join users on offer_letters.created_by_id = users.id

left join users as us on offer_letters.approved_by_id = us.id 

left join clients on offer_letters.client_id = clients.user_id 

left join employee_details as ed on offer_letters.id=ed.offer_letter_id 

left join users as usr on users.reporting_to=usr.id

left join applied_jobs as aj on aj.user_id = offer_letters.candidate_id

left join selected_candidates on selected_candidates.applied_jobs_id = aj.id

where offer_letters.status IN(5,6) and clients.id not in (1,2)  and offer_letters.employee_type != 0 AND offer_letters.job_posting_id 

and offer_letters.job_posting_id = 105201

GROUP  BY offer_letters.full_name, ed.employee_id


Exit :
 
SELECT  recruiter_name,concat (us.first_name , ' ' , us.last_name) as manager_name, Employee_Information.full_name,Employee_Information.employee_type,employee_id,Employee_Information.joining_date,Employee_Information.p_o_value,Employee_Information.margin,Employee_Information.exit_type,Employee_Information.company_name,Employee_Information.status,ec2.last_work_day FROM `Employee_Information`
 
LEFT JOIN exited_candidates as ec2 on ec2.offer_letter_id = Employee_Information.offer_letter_id
LEFT JOIN retained_employees on ec2.offer_letter_id=retained_employees.offer_letter_id
left join users as us on Employee_Information.approved_by_id = us.id
LEFT JOIN offer_letters on Employee_Information.offer_letter_id=offer_letters.id
LEFT JOIN clients on offer_letters.client_id=clients.user_id
 
 
WHERE Employee_Information.last_work_day BETWEEN '2025-09-01' AND '2025-09-30'  and Employee_Information.status = 6 and clients.id not in (1,2) and Employee_Information.employee_type != 0
and Employee_Information.exit_type != "No Show"
GROUP by Employee_Information.offer_letter_id



Exit In progress  :
 
SELECT  recruiter_name,concat (us.first_name , ' ' , us.last_name) as manager_name, Employee_Information.full_name,Employee_Information.employee_type,employee_id,Employee_Information.joining_date,Employee_Information.p_o_value,Employee_Information.margin,Employee_Information.exit_type,Employee_Information.company_name,Employee_Information.status,ec2.tentative_exit_date FROM `Employee_Information` 
LEFT JOIN exited_candidates as ec2 on ec2.offer_letter_id = Employee_Information.offer_letter_id 
 
LEFT JOIN retained_employees on ec2.offer_letter_id=retained_employees.offer_letter_id 
 
left join users as us on Employee_Information.approved_by_id = us.id  
 
LEFT JOIN offer_letters on Employee_Information.offer_letter_id=offer_letters.id 
 
LEFT JOIN clients on offer_letters.client_id=clients.user_id 
WHERE Employee_Information.exit_status=0 and clients.id not in (1,2) and  Employee_Information.employee_type != 0 
 
GROUP by Employee_Information.offer_letter_id
GROUP by Employee_Information.offer_letter_id


Mapping between current demand id and old demand id:
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