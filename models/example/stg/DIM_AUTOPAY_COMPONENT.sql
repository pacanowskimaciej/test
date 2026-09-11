{{ config(materialized='view') }}

SELECT * FROM VALUES
    (1000266,'GRAC5',5.00,'Grace'),
    (1000264,'ACH10',10.00,'ACH'),
    (4013004,'ACH10',10.00,'ACH'),
    (1000265,'NACH5',5.00,'Card'),
    (4013005,'NACH5',5.00,'Card'),
    (1000296,'ACH5',5.00,'ACH'),
    (4013017,'ACH5',5.00,'ACH'),
    (1000297,'ACH2',2.50,'ACH'),
    (4013018,'ACH2',2.50,'ACH'),
    (1000072,'AUTOP',0.00,'Legacy'),
    (4008656,'AUTOP',0.00,'Legacy')
AS T
(
    COMPONENT_ID,
    DISCOUNT_CODE,
    DISCOUNT_AMOUNT,
    DISCOUNT_CATEGORY
)