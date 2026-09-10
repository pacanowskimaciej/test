
/*
    Welcome to your first dbt model!
    Did you know that you can also configure models directly within SQL files?
    This will override configurations stated in dbt_project.yml

    Try changing "table" to "view" below
*/

{{ config(materialized='view') }}

WITH months AS (

    SELECT
        TO_VARCHAR(LAST_DAY(DATEADD(MONTH,-2,CURRENT_DATE())),'YYYY-MM') AS month1,
        TO_VARCHAR(LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE())),'YYYY-MM') AS month2,
        TO_VARCHAR(CURRENT_DATE(),'YYYY-MM')                             AS month3
),

pvt AS (

    SELECT
        f.account_no,
        f.tenant_id,

        /* Month 1 */

        MAX(
            CASE
                WHEN f.snapshot_month = m.month1
                THEN f.autopay_yes
            END
        ) AS month1_ap,

        MAX(
            CASE
                WHEN f.snapshot_month = m.month1
                THEN f.method
            END
        ) AS month1_method,

        MAX(
            CASE
                WHEN f.snapshot_month = m.month1
                THEN COALESCE(f.disc_name,'none')
            END
        ) AS month1_disc,


        /* Month 2 */

        MAX(
            CASE
                WHEN f.snapshot_month = m.month2
                THEN f.autopay_yes
            END
        ) AS month2_ap,

        MAX(
            CASE
                WHEN f.snapshot_month = m.month2
                THEN f.method
            END
        ) AS month2_method,

        MAX(
            CASE
                WHEN f.snapshot_month = m.month2
                THEN COALESCE(f.disc_name,'none')
            END
        ) AS month2_disc,


        /* Month 3 */

        MAX(
            CASE
                WHEN f.snapshot_month = m.month3
                THEN f.autopay_yes
            END
        ) AS month3_ap,

        MAX(
            CASE
                WHEN f.snapshot_month = m.month3
                THEN f.method
            END
        ) AS month3_method,

        MAX(
            CASE
                WHEN f.snapshot_month = m.month3
                THEN COALESCE(f.disc_name,'none')
            END
        ) AS month3_disc

    FROM SNOWFLAKE_LEARNING_DB.BILLING.FACT_AUTOPAY_SNAPSHOT f

    CROSS JOIN months m

    GROUP BY
        f.account_no,
        f.tenant_id
)

SELECT
    account_no,
    tenant_id,

    month1_ap,
    month1_method,
    month1_disc,

    month2_ap,
    month2_method,
    month2_disc,

    month3_ap,
    month3_method,
    month3_disc,


    /* Paths */

    COALESCE(month1_disc,'-')
    || ' > ' ||
    COALESCE(month2_disc,'-')
    || ' > ' ||
    COALESCE(month3_disc,'-')
    AS discount_path,


    COALESCE(month1_ap,'-')
    || ' > ' ||
    COALESCE(month2_ap,'-')
    || ' > ' ||
    COALESCE(month3_ap,'-')
    AS autopay_path,


    COALESCE(month1_method,'-')
    || ' > ' ||
    COALESCE(month2_method,'-')
    || ' > ' ||
    COALESCE(month3_method,'-')
    AS method_path,


    /* Change indicators */

    CASE
        WHEN COALESCE(month1_disc,'x')
             = COALESCE(month2_disc,COALESCE(month1_disc,'x'))

         AND COALESCE(month2_disc,'x')
             = COALESCE(month3_disc,COALESCE(month2_disc,'x'))

        THEN 'N'
        ELSE 'Y'
    END AS discount_changed,


    CASE
        WHEN COALESCE(month1_ap,'x')
             = COALESCE(month2_ap,COALESCE(month1_ap,'x'))

         AND COALESCE(month2_ap,'x')
             = COALESCE(month3_ap,COALESCE(month2_ap,'x'))

        THEN 'N'
        ELSE 'Y'
    END AS autopay_changed,


    /* Ever flags */

    CASE
        WHEN 'Y' IN (
            month1_ap,
            month2_ap,
            month3_ap
        )
        THEN 'Y'
        ELSE 'N'
    END AS ever_autopay,


    CASE
        WHEN COALESCE(month1_disc,'none') <> 'none'
          OR COALESCE(month2_disc,'none') <> 'none'
          OR COALESCE(month3_disc,'none') <> 'none'
        THEN 'Y'
        ELSE 'N'
    END AS ever_discount

FROM pvt