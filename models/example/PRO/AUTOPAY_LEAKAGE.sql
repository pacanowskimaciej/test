{{ config(materialized='view') }}

SELECT *

FROM SNOWFLAKE_LEARNING_DB.BILLING.FACT_AUTOPAY_SNAPSHOT

WHERE
(
    method = 'ACH'
    AND COALESCE(disc_name,'X')
        NOT IN ('ACH10','ACH5','ACH2','GRAC5')
)

OR
(
    method = 'Card'
    AND disc_name IS NULL
)

OR
(
    autopay_yes = 'Y'
    AND disc_name IS NULL
)