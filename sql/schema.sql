-- Credit Card Fraud Detection: MySQL schema
CREATE DATABASE IF NOT EXISTS fraud_db;
USE fraud_db;

DROP TABLE IF EXISTS predictions;
DROP TABLE IF EXISTS transactions;

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    time_seconds   DOUBLE NOT NULL,          -- seconds since first transaction
    hour_of_day    TINYINT NOT NULL,         -- 0-23, derived from time_seconds
    day_num        TINYINT NOT NULL,         -- 0 or 1 (dataset spans 2 days)
    amount         DECIMAL(10,2) NOT NULL,
    V1 DOUBLE NOT NULL,
    V2 DOUBLE NOT NULL,
    V3 DOUBLE NOT NULL,
    V4 DOUBLE NOT NULL,
    V5 DOUBLE NOT NULL,
    V6 DOUBLE NOT NULL,
    V7 DOUBLE NOT NULL,
    V8 DOUBLE NOT NULL,
    V9 DOUBLE NOT NULL,
    V10 DOUBLE NOT NULL,
    V11 DOUBLE NOT NULL,
    V12 DOUBLE NOT NULL,
    V13 DOUBLE NOT NULL,
    V14 DOUBLE NOT NULL,
    V15 DOUBLE NOT NULL,
    V16 DOUBLE NOT NULL,
    V17 DOUBLE NOT NULL,
    V18 DOUBLE NOT NULL,
    V19 DOUBLE NOT NULL,
    V20 DOUBLE NOT NULL,
    V21 DOUBLE NOT NULL,
    V22 DOUBLE NOT NULL,
    V23 DOUBLE NOT NULL,
    V24 DOUBLE NOT NULL,
    V25 DOUBLE NOT NULL,
    V26 DOUBLE NOT NULL,
    V27 DOUBLE NOT NULL,
    V28 DOUBLE NOT NULL,
    is_fraud       TINYINT(1) NOT NULL,
    INDEX idx_hour (hour_of_day),
    INDEX idx_fraud (is_fraud),
    INDEX idx_amount (amount)
);

CREATE TABLE predictions (
    prediction_id     INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id    INT NOT NULL,
    model_name        VARCHAR(50) NOT NULL,
    fraud_probability DOUBLE NOT NULL,
    predicted_label   TINYINT(1) NOT NULL,
    threshold         DOUBLE NOT NULL,
    scored_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id),
    INDEX idx_prob (fraud_probability)
);
