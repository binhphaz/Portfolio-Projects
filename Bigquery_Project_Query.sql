-- Big project for SQL


-- Query 01: calculate total visit, pageview, transaction and revenue for Jan, Feb and March 2017 order by month
#standardSQL
SELECT 
 FORMAT_DATE('%Y%m', parse_date('%Y%m%d', date)) as month,
 SUM(totals.visits) as visits, 
 SUM(totals.pageviews) as pageviews, 
 SUM(totals.transactions) as transactions, 
 SUM(totals.totaltransactionrevenue) as revenue  
 FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
 WHERE _table_suffix between '20170101' and '20170331'
 GROUP BY 1
 ORDER BY 1



-- Query 02: Bounce rate per traffic source in July 2017
#standardSQL
SELECT 
 trafficsource.source as source,
 sum(totals.visits) as total_visits, 
 sum(totals.bounces) as totals_no_of_bounces, 
 sum(totals.bounces)*100/sum(totals.visits) as bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
GROUP BY source
ORDER BY total_visits DESC;



-- Query 3: Revenue by traffic source by week, by month in June 2017
WITH month_data as(
SELECT
 'month' as time_type, 
 '201706' as time,
 trafficsource.source as source,
 sum(totals.totaltransactionrevenue) as revenue 
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`
GROUP BY 3),

week_data as(
SELECT 
 'Week' as time_type,
 date as time,
 source,
 SUM(totaltransactionrevenue) as revenue
FROM
(SELECT 
   format_date("%Y%W",parse_date("%Y%m%d",date)) as date, 
   trafficsource.source, 
   totals.totaltransactionrevenue 
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`)sub
GROUP BY 2,3)

SELECT * FROM month_data 
UNION ALL 
SELECT * FROM week_data



--Query 04: Average number of product pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017. Note: totals.transactions >=1 for purchaser and totals.transactions is null for non-purchaser
#standardSQL
WITH avg_pageviews_purchase_data as(
SELECT
 FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) as month,  
 SUM(totals.pageviews)/count(distinct fullvisitorid ) as avg_pageviews_purchase, 
 FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` 
 WHERE _table_suffix between '20170601' and '20170731' and totals.transactions>=1
 GROUP BY 1),

avg_pageviews_non_purchase_data as(
SELECT
 FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) as month,
 SUM(totals.pageviews)/COUNT(distinct fullvisitorid ) as avg_pageviews_non_purchase
 FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` 
 WHERE _table_suffix between '20170601' and '20170731' and totals.transactions is null  
 GROUP BY 1)

 SELECT * 
 FROM avg_pageviews_purchase_data 
 LEFT JOIN avg_pageviews_non_purchase_data 
 USING (month)
 ORDER BY month


-- Query 05: Average number of transactions per user that made a purchase in July 2017
#standardSQL
SELECT
 FORMAT_DATE('%Y%m', parse_date('%Y%m%d',date)) as Month,  
 SUM(totals.transactions)/COUNT(distinct fullvisitorid ) as Avg_total_transactions_per_user 
 FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` 
 WHERE totals.transactions>=1
 GROUP BY 1


-- Query 06: Average amount of money spent per session
#standardSQL
SELECT 
 FORMAT_DATE('%Y%m', parse_date('%Y%m%d',date)) as Month,
 SUM(totals.totaltransactionrevenue)/COUNT(distinct visitid) as avg_revenue_by_user_per_visit 
 FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` 
 WHERE totals.transactions>=1
 GROUP BY 1


-- Query 07: Products purchased by customers who purchased product A (Classic Ecommerce)
#standardSQL

SELECT
 product.v2ProductName,
 SUM(product.productQuantity) as quantity
FROM 
 `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
 UNNEST (hits) hits,
 UNNEST (hits.product) product
WHERE visitId IN
(SELECT visitId
 FROM
  `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
  UNNEST (hits) hits,
  UNNEST (hits.product) product
WHERE
product.v2ProductName="YouTube Men's Vintage Henley"
AND product.productRevenue is not null)
AND product.productRevenue is not null
GROUP BY product.v2ProductName
ORDER BY quantity DESC;

--Query 08: Calculate cohort map from pageview to addtocart to purchase in last 3 month. For example, 100% pageview then 40% add_to_cart and 10% purchase.
#standardSQL

WITH num_product_view_data as (
SELECT
 FORMAT_DATE('%Y%m', parse_date('%Y%m%d',date)) as month, 
 COUNT(*) as num_product_view 
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
 UNNEST (hits) hits, UNNEST (hits.product) product
 WHERE _table_suffix between '20170101' and '20170331' and hits.eCommerceAction.action_type = '2'
 GROUP BY 1),

num_addtocart_data as(
SELECT  
 FORMAT_DATE('%Y%m', parse_date('%Y%m%d',date)) as month, 
 COUNT(*) as num_addtocart 
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
 UNNEST (hits) hits, UNNEST (hits.product) product
WHERE _table_suffix between '20170101' and '20170331' and hits.eCommerceAction.action_type = '3'
GROUP BY 1), 

num_purchase_data as(
SELECT  
 FORMAT_DATE('%Y%m', parse_date('%Y%m%d',date)) as month, 
 COUNT(*) as num_purchase
FROM`bigquery-public-data.google_analytics_sample.ga_sessions_*`,
 UNNEST (hits) hits,
 UNNEST (hits.product) product
WHERE _table_suffix between '20170101' and '20170331' and hits.eCommerceAction.action_type = '6'
GROUP BY 1),

num_data as(
SELECT * FROM num_product_view_data 
LEFT JOIN num_addtocart_data  
USING(month)
LEFT JOIN num_purchase_data 
USING(month))

SELECT 
 *,
 num_addtocart *100/num_product_view as add_to_cart_rate,
 num_purchase*100/num_product_view as purchase_rate   
FROM num_data 
ORDER BY month


