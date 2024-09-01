-- Based off the 8 sample customers provided in the sample from the subscriptions table, 
-- write a brief description about each customer’s onboarding journey.

SELECT 
	sub.customer_id,
    plan.plan_id,
    plan.plan_name,
    sub.start_date
FROM subscriptions sub
JOIN plans plan
	ON sub.plan_id = plan.plan_id
WHERE sub.customer_id IN (1,2,11,13,15,16,18,19);
;

-- Customer 1: the customer started their free trial on August 1, 2020 and has opted to pay for the basic monthly plan
-- Customer 2: the customer started their free trial on August 8, 2020 and has opted to pay for the pro annual plan
-- Customer 11: the customer started their free trial on November 19, 2020 and has canceled at the end of the free trial
-- Customer 13: The customer started ther free trial on December 15, 2020 and has subscribed to the basic monthly tier after the free trial  ends, 
-- and has subscribed to the pro monthly tier after 3 months
-- Customer 15:  The customer started their free trial on March 17, 2020 and has subscribed to the pro monthly tier,
-- but has canceled their subscription after a month.