select CONVERT_TIMEZONE('Europe/Warsaw', CURRENT_TIMESTAMP()) AS current_time_poland
 ,* 
 from {{ref('AUTOPAY_LEAKAGE')}}