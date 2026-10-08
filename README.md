# Advanced SQL Project: Global Account and Email Analytics

## 📌 Description
This project contains a SQL query that collects and analyzes user account and email activity data.
The query ranks countries by the number of accounts created and emails sent, and selects the **top 10 countries** for each metric.

## 📂 Repository Structure
- `advanced_sql_account_email_analytics.sql` — main SQL query
- `README.md` — documentation (this file)
- `screenshots_query-results.png` — query result screenshots from BigQuery

## ⚙️ Query Logic
1. **acc_info** — collects account data (creation date, country, verification and subscription status).
2. **email_info** — email metrics (sent, opened, clicked).
   - `es.sent_date` stores the **offset in days relative to the session date**.
3. **union_tab** — combines account data and email metrics into one table.
4. **gr_date_country** — aggregation by date, country and account attributes.
5. **totals** — calculates the total number of accounts and emails per country.
6. **sums** — computes **DENSE_RANK** to identify the top 10 countries.
7. **Final SELECT** — selects countries that are in the top 10 by accounts or by emails.

## ▶️ How to Run
1. Open the [Google BigQuery Console](https://console.cloud.google.com/bigquery).
2. Create a new query.
3. Copy the contents of `advanced_sql_account_email_analytics.sql`.
4. Click `Run`.

## 📊 Result
- A table with account and email activity metrics.
- Countries sorted by date and ranking position.
- Only countries that rank in the **top 10** for at least one metric are kept.

![Query results](screenshots_query-results.png)

---

✍️ Author: Stanislav Tsapenko
📅 Date: 09-09-2025
  
![Query results](screenshots_query-results.png)

---

✍️ Автор: Stanislav Tsapenko  
📅 Дата: 09-09-2025
