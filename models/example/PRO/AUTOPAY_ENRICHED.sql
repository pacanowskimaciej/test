SELECT
    f.account_no,
    f.tenant_id,
    f.snapshot_date,
    f.snapshot_month,
    f.disc_component_id,
    f.disc_name,
    f.pay_src_month,
    f.method,
    f.bucket,
    f.autopay_yes,

    d.discount_code,
    d.discount_amount,
    d.discount_category,

    f.load_dttm

FROM SNOWFLAKE_LEARNING_DB.BILLING.FACT_AUTOPAY_SNAPSHOT f

LEFT JOIN SNOWFLAKE_LEARNING_DB.BILLING.DIM_AUTOPAY_COMPONENT d
    ON f.disc_component_id = d.component_id