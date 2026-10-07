-- advanced_sql_account_email_analytics.sql
-- Запит: збір інформації по акаунтах та email-метриках, ранжування ТОП-країн
WITH
  -- CTE: інформація по акаунтам
  acc_info AS (
    SELECT
      s.date AS account_date,
      sp.country AS country,
      a.send_interval AS send_interval,
      a.is_verified AS is_verified,
      a.is_unsubscribed AS is_unsubscribed,
      COUNT(a.id) AS account_cnt
    FROM `data-analytics-mate.DA.account` a
    JOIN `data-analytics-mate.DA.account_session` acs
      ON a.id = acs.account_id
    JOIN `data-analytics-mate.DA.session` s
      ON acs.ga_session_id = s.ga_session_id
    JOIN `data-analytics-mate.DA.session_params` sp
      ON acs.ga_session_id = sp.ga_session_id
    GROUP BY s.date, sp.country, a.send_interval, a.is_verified, a.is_unsubscribed
  ),

  -- CTE: інформація по імейлам (es.sent_date — зсув у днях від s.date)
  email_info AS (
    SELECT
      DATE_ADD(s.date, INTERVAL CAST(es.sent_date AS INT64) DAY) AS sent_date,
      sp.country,
      a.send_interval,
      a.is_verified,
      a.is_unsubscribed,
      COUNT(DISTINCT es.id_message) AS sent_msg,
      COUNT(DISTINCT eo.id_message) AS open_msg,
      COUNT(DISTINCT ev.id_message) AS visit_msg
    FROM `data-analytics-mate.DA.email_sent` es
    LEFT JOIN `data-analytics-mate.DA.email_open` eo
      ON es.id_message = eo.id_message
    LEFT JOIN `data-analytics-mate.DA.email_visit` ev
      ON es.id_message = ev.id_message
    JOIN `data-analytics-mate.DA.account_session` acs
      ON es.id_account = acs.account_id
    JOIN `data-analytics-mate.DA.session_params` sp
      ON acs.ga_session_id = sp.ga_session_id
    JOIN `data-analytics-mate.DA.session` s
      ON s.ga_session_id = sp.ga_session_id
    JOIN `data-analytics-mate.DA.account` a
      ON a.id = es.id_account
    GROUP BY sent_date, sp.country, a.send_interval, a.is_verified, a.is_unsubscribed
  ),

  -- об'єднання акаунтів та імейлів
  union_tab AS (
    SELECT
      acc_info.account_date AS date,
      acc_info.country,
      acc_info.send_interval,
      acc_info.is_verified,
      acc_info.is_unsubscribed,
      acc_info.account_cnt,
      NULL AS sent_msg,
      NULL AS open_msg,
      NULL AS visit_msg
    FROM acc_info
    UNION ALL
    SELECT
      email_info.sent_date AS date,
      email_info.country,
      email_info.send_interval,
      email_info.is_verified,
      email_info.is_unsubscribed,
      NULL AS account_cnt,
      email_info.sent_msg,
      email_info.open_msg,
      email_info.visit_msg
    FROM email_info
  ),

  -- агрегація по даті/країні/атрибутах
  gr_date_country AS (
    SELECT
      date,
      country,
      send_interval,
      is_verified,
      is_unsubscribed,
      SUM(account_cnt) AS account_cnt,
      SUM(sent_msg) AS sent_msg,
      SUM(open_msg) AS open_msg,
      SUM(visit_msg) AS visit_msg
    FROM union_tab
    GROUP BY date, country, send_interval, is_verified, is_unsubscribed
  ),

  -- totals: розрахунок загальних сум по країні як колонки
  totals AS (
    SELECT
      g.*,
      SUM(g.account_cnt) OVER (PARTITION BY g.country) AS total_country_account_cnt,
      SUM(g.sent_msg) OVER (PARTITION BY g.country) AS total_country_sent_msg
    FROM gr_date_country g
  ),

  -- sums: ранги на основі тоталів
  sums AS (
    SELECT
      t.*,
      DENSE_RANK() OVER (ORDER BY t.total_country_account_cnt DESC) AS rank_account,
      DENSE_RANK() OVER (ORDER BY t.total_country_sent_msg DESC) AS rank_msg
    FROM totals t
  )

SELECT
  date,
  country,
  account_cnt,
  send_interval,
  is_unsubscribed,
  is_verified,
  sent_msg,
  open_msg,
  visit_msg,
  total_country_account_cnt,
  total_country_sent_msg,
  rank_account,
  rank_msg
FROM sums
WHERE rank_account <= 10 OR rank_msg <= 10
ORDER BY date, rank_account;
