{{ config(materialized='view') }}

SELECT
    snapshot_month,

    COUNT(*) AS active_base,

    COUNT_IF(autopay_yes = 'Y') AS autopay_yes,

    COUNT_IF(autopay_yes = 'N') AS autopay_no,

    COUNT_IF(bucket = 'ACH') AS ach,

    COUNT_IF(bucket = 'Grace (GRAC5)') AS grace,

    COUNT_IF(bucket = 'Card/Non-ACH') AS card,

    COUNT_IF(bucket = 'Legacy AUTOP') AS legacy_autop

FROM SNOWFLAKE_LEARNING_DB.BILLING.FACT_AUTOPAY_SNAPSHOT

GROUP BY
    snapshot_month
