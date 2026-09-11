{{ config(materialized='view') }}


WITH base AS (

    SELECT
        c.account_no,
        c.tenant_id,
        TO_DATE('${P_SNAPSHOT_DATE}') AS snapshot_date,
        TO_VARCHAR(TO_DATE('${P_SNAPSHOT_DATE}'),'YYYY-MM') AS snapshot_month
    FROM DLH_BRONZE.KEN.CMF c
    WHERE c.account_category IN (170,180)
      AND c.date_active <= TO_DATE('${P_SNAPSHOT_DATE}')
      AND (
             c.date_inactive IS NULL
             OR c.date_inactive > TO_DATE('${P_SNAPSHOT_DATE}')
          )

),

component_data AS (

    SELECT
        b.account_no,
        MAX(cpc.component_id) AS disc_component_id
    FROM base b
    LEFT JOIN DLH_BRONZE.KEN.CMF_PACKAGE_COMPONENT cpc
      ON cpc.parent_account_no = b.account_no
     AND cpc.parent_subscr_no IS NULL
     AND cpc.component_id IN
     (
        1000266,1000264,1000265,
        1000296,1000297,1000072,
        4013004,4013005,
        4013017,4013018,4008656
     )
     AND cpc.active_dt <= TO_DATE('${P_SNAPSHOT_DATE}')
     AND (
           cpc.inactive_dt IS NULL
           OR cpc.inactive_dt > TO_DATE('${P_SNAPSHOT_DATE}')
         )
    GROUP BY b.account_no

),

payment_data AS (

    SELECT
        account_no,
        trans_source
    FROM (
        SELECT
            p.account_no,
            p.trans_source,
            ROW_NUMBER() OVER (
                PARTITION BY p.account_no
                ORDER BY p.trans_date DESC
            ) rn
        FROM DLH_BRONZE.KEN.BMF p
        WHERE p.trans_source IN (83,84,85)
          AND p.trans_date >= DATE_TRUNC('MONTH',TO_DATE('${P_SNAPSHOT_DATE}'))
          AND p.trans_date <= TO_DATE('${P_SNAPSHOT_DATE}')
    )
    WHERE rn=1

)

SELECT

    b.account_no,
    b.tenant_id,

    b.snapshot_date,
    b.snapshot_month,

    c.disc_component_id,

    d.discount_code AS disc_name,

    p.trans_source AS pay_src_month,

    CASE
        WHEN p.trans_source = 84 THEN 'ACH'
        WHEN p.trans_source IN (83,85) THEN 'Card'
        ELSE 'None'
    END AS method,

    CASE
        WHEN c.disc_component_id = 1000266
            THEN 'Grace (GRAC5)'

        WHEN c.disc_component_id IN
        (
          1000264,1000296,1000297,
          4013004,4013017,4013018
        )
        OR p.trans_source = 84
            THEN 'ACH'

        WHEN c.disc_component_id IN
        (
          1000265,4013005
        )
        OR p.trans_source IN (83,85)
            THEN 'Card/Non-ACH'

        WHEN c.disc_component_id IN
        (
           1000072,4008656
        )
            THEN 'Legacy AUTOP'

        ELSE 'No AutoPay'
    END AS bucket,

    CASE
        WHEN c.disc_component_id IS NOT NULL THEN 'Y'
        ELSE 'N'
    END AS autopay_yes,

    CURRENT_TIMESTAMP() AS load_dttm

FROM base b

LEFT JOIN component_data c
    ON b.account_no = c.account_no

LEFT JOIN payment_data p
    ON b.account_no = p.account_no

LEFT JOIN DEV_DXSINGH_DLH_SILVER.BILLING.DIM_AUTOPAY_COMPONENT d
    ON c.disc_component_id = d.component_id