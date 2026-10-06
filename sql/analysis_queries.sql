-- Credit Card Fraud Detection: transaction analytics
USE fraud_db;

-- 1. Overall fraud summary
SELECT COUNT(*)                                        AS total_txns,
       SUM(is_fraud)                                   AS fraud_txns,
       ROUND(100 * AVG(is_fraud), 3)                   AS fraud_rate_pct,
       ROUND(SUM(CASE WHEN is_fraud = 1 THEN amount END), 2) AS total_fraud_amount
FROM transactions;

-- 2. Fraud rate by hour of day
SELECT hour_of_day,
       COUNT(*)                      AS txns,
       SUM(is_fraud)                 AS frauds,
       ROUND(100 * AVG(is_fraud), 3) AS fraud_rate_pct
FROM transactions
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- 3. Fraud by transaction amount band
SELECT CASE
         WHEN amount = 0     THEN '0 (verification)'
         WHEN amount < 10    THEN '0.01-9.99'
         WHEN amount < 100   THEN '10-99.99'
         WHEN amount < 500   THEN '100-499.99'
         WHEN amount < 1000  THEN '500-999.99'
         ELSE '1000+'
       END                           AS amount_band,
       COUNT(*)                      AS txns,
       SUM(is_fraud)                 AS frauds,
       ROUND(100 * AVG(is_fraud), 3) AS fraud_rate_pct,
       ROUND(AVG(amount), 2)         AS avg_amount
FROM transactions
GROUP BY amount_band
ORDER BY MIN(amount);

-- 4. Average / median-ish amount: fraud vs legit
SELECT is_fraud,
       COUNT(*)              AS txns,
       ROUND(AVG(amount), 2) AS avg_amount,
       ROUND(MAX(amount), 2) AS max_amount
FROM transactions
GROUP BY is_fraud;

-- 5. Day-over-day comparison
SELECT day_num,
       COUNT(*)                      AS txns,
       SUM(is_fraud)                 AS frauds,
       ROUND(100 * AVG(is_fraud), 3) AS fraud_rate_pct
FROM transactions
GROUP BY day_num;

-- 6. Rank hours by fraud rate (window function)
SELECT hour_of_day, frauds, fraud_rate_pct,
       RANK() OVER (ORDER BY fraud_rate_pct DESC) AS risk_rank
FROM (
    SELECT hour_of_day,
           SUM(is_fraud)                 AS frauds,
           ROUND(100 * AVG(is_fraud), 3) AS fraud_rate_pct
    FROM transactions
    GROUP BY hour_of_day
) h;

-- 7. Rolling 3-hour fraud count (window function)
SELECT day_num, hour_of_day, frauds,
       SUM(frauds) OVER (ORDER BY day_num, hour_of_day
                         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3h_frauds
FROM (
    SELECT day_num, hour_of_day, SUM(is_fraud) AS frauds
    FROM transactions
    GROUP BY day_num, hour_of_day
) t
ORDER BY day_num, hour_of_day;

-- 8. Model confusion matrix computed in SQL
SELECT SUM(t.is_fraud = 1 AND p.predicted_label = 1) AS true_positives,
       SUM(t.is_fraud = 0 AND p.predicted_label = 1) AS false_positives,
       SUM(t.is_fraud = 1 AND p.predicted_label = 0) AS false_negatives,
       SUM(t.is_fraud = 0 AND p.predicted_label = 0) AS true_negatives
FROM predictions p
JOIN transactions t ON t.transaction_id = p.transaction_id;

-- 9. Money caught vs missed by the model
SELECT ROUND(SUM(CASE WHEN t.is_fraud = 1 AND p.predicted_label = 1 THEN t.amount ELSE 0 END), 2) AS fraud_amount_caught,
       ROUND(SUM(CASE WHEN t.is_fraud = 1 AND p.predicted_label = 0 THEN t.amount ELSE 0 END), 2) AS fraud_amount_missed
FROM predictions p
JOIN transactions t ON t.transaction_id = p.transaction_id;

-- 10. Alert precision by probability band (how trustworthy are high scores?)
SELECT CASE
         WHEN p.fraud_probability >= 0.9 THEN '0.9-1.0'
         WHEN p.fraud_probability >= 0.7 THEN '0.7-0.9'
         WHEN p.fraud_probability >= 0.5 THEN '0.5-0.7'
         WHEN p.fraud_probability >= 0.2 THEN '0.2-0.5'
         ELSE '<0.2'
       END                             AS prob_band,
       COUNT(*)                        AS txns,
       SUM(t.is_fraud)                 AS actual_frauds,
       ROUND(100 * AVG(t.is_fraud), 2) AS pct_actually_fraud
FROM predictions p
JOIN transactions t ON t.transaction_id = p.transaction_id
GROUP BY prob_band
ORDER BY MIN(p.fraud_probability) DESC;

-- 11. Review queue: top 20 highest-risk transactions the model flagged
SELECT p.transaction_id, t.hour_of_day, t.amount,
       ROUND(p.fraud_probability, 4) AS fraud_probability, t.is_fraud AS actual
FROM predictions p
JOIN transactions t ON t.transaction_id = p.transaction_id
WHERE p.predicted_label = 1
ORDER BY p.fraud_probability DESC
LIMIT 20;
