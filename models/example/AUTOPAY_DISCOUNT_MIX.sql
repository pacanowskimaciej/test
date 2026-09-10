{{ config(materialized='view') }}
SELECT
    snapshot_month,

    COALESCE(disc_name,'(none)') AS discount_code,

    COUNT(*) AS accounts

FROM SNOWFLAKE_LEARNING_DB.BILLING.FACT_AUTOPAY_SNAPSHOT

GROUP BY
    snapshot_month,
    COALESCE(disc_name,'(none)')