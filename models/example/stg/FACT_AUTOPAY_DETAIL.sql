{{ config(materialized='view') }}

WITH ban_map AS (

    SELECT
        account_no,
        MAX(external_id) AS external_id
    FROM DLH_BRONZE.KEN.CUSTOMER_ID_ACCT_MAP
    WHERE external_id_type = 1
    GROUP BY account_no

),

pricing_tier AS (

    SELECT
        account_no,
        MAX(param_value) AS pricing_tier
    FROM DLH_BRONZE.KEN.CMF_EXT_DATA
    WHERE param_id = 62
    GROUP BY account_no

),

detail_base AS (

    SELECT

        s.account_no,
        s.tenant_id,
        s.snapshot_month,

        s.disc_component_id,
        s.disc_name,

        s.autopay_yes,
        s.method,

        bm.external_id AS raw_ban,

        REGEXP_REPLACE(
            bm.external_id,
            'MIG$',
            ''
        ) AS ban,

        pt.pricing_tier

    FROM DEV_DXSINGH_DLH_SILVER.BILLING.FACT_AUTOPAY_SNAPSHOT s

    JOIN ban_map bm
      ON s.account_no = bm.account_no

    LEFT JOIN pricing_tier pt
      ON s.account_no = pt.account_no

    WHERE s.snapshot_month =
          TO_VARCHAR(
                TO_DATE('${P_SNAPSHOT_DATE}'),
                'YYYY-MM'
          )

),

last_payment AS (

    SELECT
        ban,
        trans_date,
        last_pay_method
    FROM (
        SELECT

            REGEXP_REPLACE(
                bm.external_id,
                'MIG$',
                ''
            ) AS ban,

            b.trans_date,

            CASE
                WHEN b.trans_source = 84 THEN 'ACH'
                WHEN b.trans_source IN (83,85) THEN 'Card'
            END AS last_pay_method,

            ROW_NUMBER() OVER (
                PARTITION BY REGEXP_REPLACE(bm.external_id,'MIG$','')
                ORDER BY b.trans_date DESC
            ) rn

        FROM DLH_BRONZE.KEN.BMF b

        JOIN ban_map bm
          ON b.account_no = bm.account_no

        WHERE b.trans_source IN (83,84,85)
    )
    WHERE rn=1

)

SELECT

    d.ban,

    d.account_no,
    d.tenant_id,

    d.snapshot_month,

    CASE
        WHEN d.raw_ban LIKE '%MIG'
            THEN 'Y'
        ELSE 'N'
    END AS migrated_t1_t2,

    d.pricing_tier,

    d.disc_component_id,
    d.disc_name,

    d.autopay_yes,
    d.method,

    lp.trans_date AS last_pay_date,
    lp.last_pay_method,

    CURRENT_TIMESTAMP() AS load_dttm

FROM detail_base d

LEFT JOIN last_payment lp
       ON d.ban = lp.ban