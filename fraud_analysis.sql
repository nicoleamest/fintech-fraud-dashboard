/* ============================================================
   FinTech Fraud Dashboard — SQL Analysis (MySQL)
   DB: fintech_fraud
   Table: creditcard

   Notes:
   - Class = 1 is fraud, Class = 0 is non-fraud
   - Time is seconds since the first transaction in the dataset
   - Amount is transaction amount
   ============================================================ */

USE fintech_fraud;

-- 1) Total transactions + fraud transactions
SELECT
  COUNT(*) AS total_tx,
  SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS fraud_tx
FROM creditcard;

-- 2) Fraud rate (%)
SELECT
  ROUND(
    100 * SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) / COUNT(*),
    4
  ) AS fraud_rate_pct
FROM creditcard;

-- 3) Total fraud exposure ($) = sum of Amount where Class=1
SELECT
  ROUND(SUM(Amount), 2) AS total_fraud_exposure_usd
FROM creditcard
WHERE Class = 1;

-- 4) Average fraud amount ($)
SELECT
  ROUND(AVG(Amount), 2) AS avg_fraud_amount_usd
FROM creditcard
WHERE Class = 1;

-- 5) Hour number (0–47-ish): convert Time seconds -> hour bucket
-- (Time / 3600) gives hour since start; FLOOR makes an integer bucket.
SELECT
  FLOOR(Time / 3600) AS hour_number,
  COUNT(*) AS fraud_tx_count,
  ROUND(SUM(Amount), 2) AS fraud_exposure_usd
FROM creditcard
WHERE Class = 1
GROUP BY hour_number
ORDER BY hour_number;

-- 6) Amount bands for risk concentration (fraud only)
SELECT
  CASE
    WHEN Amount < 20 THEN '< $20'
    WHEN Amount < 50 THEN '$20–$50'
    WHEN Amount < 100 THEN '$50–$100'
    WHEN Amount < 200 THEN '$100–$200'
    ELSE '> $200'
  END AS amount_band,
  COUNT(*) AS fraud_cnt,
  ROUND(SUM(Amount), 2) AS fraud_exposure_usd
FROM creditcard
WHERE Class = 1
GROUP BY amount_band
ORDER BY
  CASE amount_band
    WHEN '< $20' THEN 1
    WHEN '$20–$50' THEN 2
    WHEN '$50–$100' THEN 3
    WHEN '$100–$200' THEN 4
    WHEN '> $200' THEN 5
  END;

-- 7) Optional: fraud exposure share by band (% of total fraud exposure)
SELECT
  amount_band,
  fraud_exposure_usd,
  ROUND(100 * fraud_exposure_usd / SUM(fraud_exposure_usd) OVER (), 2) AS exposure_share_pct
FROM (
  SELECT
    CASE
      WHEN Amount < 20 THEN '< $20'
      WHEN Amount < 50 THEN '$20–$50'
      WHEN Amount < 100 THEN '$50–$100'
      WHEN Amount < 200 THEN '$100–$200'
      ELSE '> $200'
    END AS amount_band,
    SUM(Amount) AS fraud_exposure_usd
  FROM creditcard
  WHERE Class = 1
  GROUP BY amount_band
) t
ORDER BY
  CASE amount_band
    WHEN '< $20' THEN 1
    WHEN '$20–$50' THEN 2
    WHEN '$50–$100' THEN 3
    WHEN '$100–$200' THEN 4
    WHEN '> $200' THEN 5
  END;
