# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A SQL analytics and data export toolkit for the J2W **Offer Letter** production MySQL database (`offerletter` on Amazon RDS, `ap-south-1`). The database has 187 tables powering J2W's recruitment platform — from candidate sourcing through offer letters, onboarding, and employee exit.

This repo contains:
- **`export_sql_to_csv.py`** — Python script that runs a `.sql` file against the DB and streams results to CSV
- **`sql_queries/`** — Reusable SQL queries (demands, BH-consultant onboarding, demand mapping)
- **`offer_letter_db_schemas/`** — Comprehensive schema documentation (3 files covering full schema, recruitment attribution, and recruiter app reference)
- **`golden_truth_queries.md`** — Analyst-validated canonical queries for submissions, interviews, selections, onboarding, exits, and demands
- **`results/`** — CSV output from query runs

## Running Queries

```bash
# Default query (bh_consultant_onboarded.sql → results/bh_consultant_onboarded.csv)
python export_sql_to_csv.py

# Specific query
python export_sql_to_csv.py sql_queries/demand.sql -o results/demand.csv
```

Dependencies: `pymysql`, `python-dotenv`. DB credentials are in `.env` (read-only replica).

## Database Connection

- **Host:** read-only replica at `offerletter-replica.ca8kj4bjkq5a.ap-south-1.rds.amazonaws.com:3306`
- **SSL required**, credentials in `.env`
- **Read-only access** — no INSERT/UPDATE/DELETE
- **Shared production replica** — avoid expensive queries; always use LIMIT on large tables

## Critical Schema Knowledge

### Core tables (star = most important)
- **`applied_jobs`** (~1.4M) ⭐ — Central recruitment pipeline. Each row = one candidate application. `current_step` maps to `candidate_work_flows.step_id`
- **`offer_letters`** (~34.5K) ⭐ — Offer records with status lifecycle (0=Draft → 6=Active Employee → 7=Exited)
- **`exited_candidates`** (~23.4K) ⭐ — Employee exit records with type/reason
- **`job_postings`** (~95K) — Demands/requirements from clients
- **`users`** (~1.3M) — All platform users via STI (`type` column: UserCandidate, UserRecruiter, UserBusinessHead, etc.)
- **`clients`** (~1K) — Client companies

### Large tables (always use LIMIT)
`api_candidates_skills` (30M), `candidate_skills` (13M), `histories` (7M), `app_notifications` (5.6M), `timesheets` (4.5M), `audits` (3M)

### Non-obvious join patterns
- `clients.user_id = job_postings.client_id` — the FK stores the client's *user ID*, not `clients.id`
- `applied_jobs.current_step` is `varchar(255)` — always quote in SQL: `WHERE current_step = '7'`
- `validation_screens` has no `user_id` column — use `applied_candidate_id` for candidate, and join `applied_jobs` on BOTH `job_posting_id` AND `user_id = applied_candidate_id` to get the recruiter

### Standard filters (apply to all business queries)
- `clients.id NOT IN (1, 2)` — exclude test/internal clients
- `users.id <> 887485` — exclude system recruiter account

### Key metric definitions
- **Submission** = `applied_jobs.current_step > 6` (past Client Submit)
- **Onboarded** = `offer_letters.status IN (5, 6)` AND `employee_type <> 0` AND `job_posting_id IS NOT NULL`, date by `client_onboard_date`
- **Active employee** = `offer_letters.status = 6`
- `joining_date` ≠ `client_onboard_date` — use `client_onboard_date` for onboarding metrics, `joining_date` for HC planning

### Role hierarchy (via `users.reporting_to`)
```
Recruiter (role_id=3) → Lead/DL (role_id=6) → Account Manager (role_id=5) → Business Head (role_id=23)
```
Some teams skip the Lead level. Active user filter: `users.locked = 0 AND user_details.status = 0`.

### Enum mappings
- **offer_letters.status:** 0=Draft, 1=Pending Approval, 2=Approved, 3=Released, 4=Accepted, 5=Onboarded, 6=Active, 7=Exited, 8=Terminated
- **offer_letters.employee_type:** 0=Standard Contract, 1=Fixed Term, 2=Third-party Payroll, 3=Permanent, 4=Consultant, 5=Intern, 6=On-Demand, 7=Other
- **job_postings.status:** 0=Draft, 1=Active, 2=Closed, 3=On Hold

### Timezone
Raw `DATETIME` columns (e.g. `created_at`) are stored in UTC. Use `CONVERT_TZ(col, '+00:00', '+05:30')` for IST display. `DATE` columns (`interview_date`, `joining_date`, `client_onboard_date`) have no time component.

## Schema Reference Files

For detailed table schemas, relationship diagrams, workflow step definitions (102 steps in `candidate_work_flows`), and analyst-validated SQL patterns, see:
- `offer_letter_db_schemas/offer-letter-db-schema.md` — Full 187-table reference
- `offer_letter_db_schemas/offer-letter-recruitment-attribution.md` — Role hierarchy, attribution chains, canonical metric queries
- `offer_letter_db_schemas/offer-letter-db-for-recruiter-app.md` — Recruiter app-oriented reference with write-path details
