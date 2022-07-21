-- Main Objective (1): Identifying Repeat Vistors

-- Task: An Email was sent on Novmber 01-2014 from the Marketing Director: Tom Parmesan and it includes the following:

-- We’ve been thinking about customer value based solely ontheir first session conversion and revenue. But if customers have repeat sessions, they may be more valuable than we thought .
-- If that’s the case, we might be able to spend a bit more to acquire them.
-- Could you please pull data on how many of our website visitors come back for another session ? 2014 to date is good.
-- -----------------------------------------------------------------------------------------------------------------------------

-- Solution Starts:
-- To solve this we are going to do the following:
-- STEP 1: Find the relevant new sessions
-- STEP 2: Use the user_id values from STEP 1 to find any repeat sessions those users had
-- STEP 3: Analyze the data at the user level (how many sessions did each user have?)
-- STEP 4: Aggregate the user-level analysis to generate your behavioral analysis


-- To understand the solution, check the next query (A)

SELECT*FROM website_sessions
WHERE user_id = 152837;

-- The following query is to obtain the new sessions only not the repeated ones.
-- then you can join it as a subquery to the same table to figure out which one of those new sessions where repeated in the following step

SELECT
website_session_id,
user_id
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-01'
 AND is_repeat_session = 0; -- For New Sessions Only
 
 
CREATE TEMPORARY TABLE session_w_repeat
SELECT
New_sessions.user_id,
New_sessions.website_session_id AS New_session_id,
website_sessions.website_session_id AS Repeated_session_id -- We are only bringing in repeat sessions from the website_sessions Table
FROM
(
SELECT
website_session_id,
user_id
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-01'
 AND is_repeat_session = 0 -- For New Sessions Only
 ) AS New_Sessions
 
 LEFT JOIN website_sessions
 ON website_sessions.user_id=New_sessions.user_id -- Condition 1
 AND website_sessions.is_repeat_session = 1 -- Condition 2: We are only bringing in repeat sessions from the website_sessions Table
 AND website_sessions.website_session_id > New_sessions.website_session_id -- Condition 3: Sessions was later than new session (redundant to add with condition 2 active since the webiste_session_id will automatically be higher in case of repeated sessions ) - Check Query (A)
 AND website_sessions.created_at BETWEEN '2014-01-01' AND '2014-11-01'; -- Condition 4
 
 
-- For QA
SELECT*FROM session_w_repeat;

-- We will use the next query as a subquery in the following step
SELECT
user_id,
COUNT(DISTINCT New_session_id) AS new_sessions,
COUNT(DISTINCT Repeated_session_id) AS repeated_sessions -- How many repeated sessions did the user have  (0,1,2,3) ?
FROM session_w_repeat
GROUP BY user_id;


SELECT
repeated_sessions,
COUNT(DISTINCT user_id) AS Number_of_users
FROM 
(
SELECT
user_id,
COUNT(DISTINCT New_session_id) AS new_sessions,
COUNT(DISTINCT Repeated_session_id) AS repeated_sessions
FROM session_w_repeat
GROUP BY user_id ) AS user_level

GROUP BY repeated_sessions;

-- Conlcusion to question(1):
-- A fair number of the customers are coming back. However, for 2 repeated sessions the number of customers were less than the number of customers who had 3 repeated sessions
-- -----------------------------------------------------------------------------------------------------------------------------

-- Main Objective (2): Identifying Repeat Vistors

-- Task: An Email was sent on Novmber 03-2014 from the Marketing Director: Tom Parmesan and it includes the following:

-- Ok, so the repeat session data was really interesting to see. Now you’ve got me curious to better understand the behavior of these repeat customers.
-- Could you help me understand the minimum, maximum, and average time between the first and second session for customers who do come back?
-- Again, analyzing 2014 to date is probably the right time period.
-- -----------------------------------------------------------------------------------------------------------------------------

-- Solution Starts:

-- To solve this we are going to do the following:
-- STEP 1: Find the relevant new sessions
-- STEP 2: Use the user_id values from STEP 1 to find any repeat sessions those users had
-- STEP 3: find the created at times for the first and second sessions and the difference between them
-- STEP 4: Aggregate the user-level analysis to generate your behavioral analysis

CREATE TEMPORARY TABLE session_w_repeat_for_time_difference
SELECT
New_sessions.user_id,
New_sessions.website_session_id AS New_session_id,
New_sessions.created_at AS New_session_created_at,
website_sessions.website_session_id AS Repeated_session_id, -- We are only bringing in repeat sessions from the website_sessions Table
website_sessions.created_at AS Repeated_session_created_at
FROM
(
SELECT
website_session_id,
user_id,
created_at
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-03'
 AND is_repeat_session = 0 -- For New Sessions Only
 ) AS New_Sessions
 
 LEFT JOIN website_sessions
 ON website_sessions.user_id=New_sessions.user_id -- Condition 1
 AND website_sessions.is_repeat_session = 1 -- Condition 2: We are only bringing in repeat sessions from the website_sessions Table
 AND website_sessions.website_session_id > New_sessions.website_session_id -- Condition 3: Sessions was later than new session (redundant to add with condition 2 active since the webiste_session_id will automatically be higher in case of repeated sessions ) - Check Query (A)
 AND website_sessions.created_at BETWEEN '2014-01-01' AND '2014-11-03'; -- Condition 4
 
 -- For QA
SELECT*FROM session_w_repeat_for_time_difference;

-- We will use the next query as a subquery in the following step
SELECT
user_id,
New_session_id,
New_session_created_at,
MIN(repeated_session_id) AS Second_session_id, -- First session that is not a repeat session
MIN(repeated_session_created_at) AS Second_session_created_at -- First session that is not a repeat session
FROM session_w_repeat_for_time_difference
WHERE Repeated_session_id IS NOT NULL
GROUP BY 1,2,3;


CREATE TEMPORARY TABLE users_first_to_second
SELECT
user_id,
datediff(second_session_created_at,new_session_created_at) AS days_first_to_second_session
FROM
(
SELECT
user_id,
New_session_id,
New_session_created_at,
MIN(repeated_session_id) AS Second_session_id, -- First session that is not a repeat session
MIN(repeated_session_created_at) AS Second_session_created_at -- First session that is not a repeat session
FROM session_w_repeat_for_time_difference
WHERE Repeated_session_id IS NOT NULL
GROUP BY 1,2,3 ) AS First_Second;

-- For QA
SELECT*FROM users_first_to_second;

SELECT
AVG(days_first_to_second_session) AS avg_days_first_to_second_session,
MIN(days_first_to_second_session) AS min_days_first_to_second_session,
MAX(days_first_to_second_session) AS max_days_first_to_second_session
FROM users_first_to_second;

-- Conlcusion to question(2):
-- repeat vistors are coming back after a month on average
-- -----------------------------------------------------------------------------------------------------------------------------

-- Main Objective (3): New VS Repeat Channel Patterns

-- Task: An Email was sent on Novmber 05-2014 from the Marketing Director: Tom Parmesan and it includes the following:

-- Can you help me understand the channels they come back through? Curious if it’s all direct type in, or if we’re paying for these customers with paid search ads multiple times.
-- Comparing new vs. repeat sessions by channel would be really valuable, if you’re able to pull it! 2014 to date is great.
-- -----------------------------------------------------------------------------------------------------------------------------

-- Solution Starts:

-- Start with the following query:

SELECT
utm_source,
utm_campaign,
http_referer,
COUNT(CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END) AS new_sessions,
COUNT(CASE WHEN is_repeat_session=1 THEN website_session_id ELSE NULL END) AS repeated_sessions
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-05'
GROUP BY 1,2,3
ORDER BY 5 DESC;

-- Then perform channel grouping for cleaner output as follows:

SELECT
CASE
	WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com','https://www.bsearch.com') THEN 'organic search'
    WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
    WHEN utm_campaign = 'brand' THEN 'paid_brand'
    WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
    WHEN utm_source = 'socialbook' THEN 'paid_social'
    END AS Channel_group,
    COUNT(CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END) AS new_sessions,
    COUNT(CASE WHEN is_repeat_session=1 THEN website_session_id ELSE NULL END) AS repeated_sessions
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-05'
GROUP BY 1
ORDER BY 3 DESC;

-- Conlcusion to question(3):
-- When vistors come back, they usuall do so via organic search, paid brand and direct type in
-- only 1/3 are coming through a paid channel (paid brand). However, brand clicks are cheaper than nonbrand.
-- So the company is not paying that much for the subsequent visits,
-- -----------------------------------------------------------------------------------------------------------------------------

-- Main Objective (4): New VS Repeat Performance

-- Task: An Email was sent on Novmber 08-2014 from the Website Manager: Morgan Rockwell and it includes the following:

-- I’d love to do a comparison of conversion rates and revenue per session for repeat sessions vs new sessions.
-- Let’s continue using data from 2014, year to date.
-- -----------------------------------------------------------------------------------------------------------------------------

-- Solution Starts:

SELECT
is_repeat_session,
COUNT(DISTINCT website_sessions.website_session_id) AS Number_of_sessions,
COUNT(DISTINCT orders.order_id) AS Number_of_orders,
COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conversion_rate,
SUM(orders.price_usd) AS revenue,
SUM(orders.price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS Revenue_per_session
FROM website_sessions
LEFT JOIN Orders
ON website_sessions.website_session_id=orders.website_session_id
WHERE website_sessions.created_at BETWEEN '2014-01-01' AND '2014-11-08'
GROUP BY 1;

-- Conlcusion to question(4):
-- Repeat Sessions convert more into orders and make more revenue per session since customers are more familiar with the company already
-- -----------------------------------------------------------------------------------------------------------------------------