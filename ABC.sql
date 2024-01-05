--ABC-анализ товаров аптечной сети.

--Таблица “sales”
--Проверим количество строк:

select
	count(*)
from
	sales

--45128 строк.

--Проверка дубликатов:

select
	count(*)
from
	(
	select
		dr_dat,
		dr_tim,
		dr_nchk,
		dr_ndoc,
		dr_apt,
		dr_kkm,
		dr_tdoc,
		dr_tpay,
		dr_cdrugs,
		dr_ndrugs,
		dr_suppl,
		dr_prod,
		dr_kol,
		dr_czak,
		dr_croz,
		dr_sdisc,
		dr_cdisc,
		dr_bcdisc,
		dr_tabempl,
		dr_pos,
		dr_vzak,
		count(*) as records
	from
		sales
	group by
		1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21
) a
where
	records > 1

--дубликатов нет.

--Количество уникальных товаров, количество уникальных аптек и дней продаж:


select
	count(distinct dr_ndrugs) as count_products,
	count(distinct dr_apt) as count_apt,
	extract(day
from
	max(dr_dat + dr_tim)::timestamp - min(dr_dat + dr_tim)::timestamp) as all_days
from
	sales

--6560 товаров, 8 аптек (2, 6, 7, 11, 13, 15, 17, 18) и 39 дней продаж. 39 дней - это неровное количество дней недели. Поэтому надо посчитать, сколько и каких:

with unique_dat as (
select
	distinct dr_dat
from
	sales),
min_max_dat as (
select
	min(dr_dat) as min_dat,
	max(dr_dat) as max_dat
from
	sales)
select
	to_char(dr_dat,
	'Day') as day_of_week,
	COUNT(*)
from
	unique_dat,
	min_max_dat
where
	min_dat >= '2022-05-01'
	and max_dat <= '2022-06-09'
group by
	to_char(dr_dat,
	'Day')
order by
	day_of_week

--понедельник, пятница и суббота 5 дней, остальные по 6 дней. В сумме 39, потерь нет. Посмотрим на количество проданных товаров по аптекам, уникальных товаров и суммы прибыли. 
--Так как количество дней недели не равное, подгоним данные, разделив метрики по понедельникам, пятницам и субботам на 5 и умножим на 6:

with glob as (
select
	sum(dr_kol) as count_ndrugs,
	count(distinct dr_ndrugs) as count_unique_ndrugs,
	sum((dr_kol * (dr_croz - dr_czak)) - dr_sdisc) as profit,
	dr_apt,
	sum(dr_sdisc) as sum_disc,
	extract(isodow
from
	(dr_dat + dr_tim)::timestamp) as num_weekday,
	to_char((dr_dat + dr_tim)::timestamp,
	'Day') as name_weekday,
	(dr_dat + dr_tim)::timestamp as times
from
	sales
group by
	dr_apt,
	dr_dat,
	dr_tim)
select
	'Monday' as weekdays,
		round((sum(case when num_weekday = 1 then profit end) / 5) * 6) as sum_profit,
		round((sum(case when num_weekday = 1 then count_unique_ndrugs end) / 5) * 6) as uniq_ndrugs,
		round((sum(case when num_weekday = 1 then count_ndrugs end) / 5) * 6) as count_ndrugs
from
	glob
union
select
	'Tuesday' as weekdays,
		round(sum(case when num_weekday = 2 then profit end)) as sum_profit,
		round(sum(case when num_weekday = 2 then count_unique_ndrugs end)) as uniq_ndrugs,
		round(sum(case when num_weekday = 2 then count_ndrugs end)) as count_ndrugs
from
	glob
union
select
	'Wednesday' as weekdays,
		round(sum(case when num_weekday = 3 then profit end)) as sum_profit,
		round(sum(case when num_weekday = 3 then count_unique_ndrugs end)) as uniq_ndrugs,
		round(sum(case when num_weekday = 3 then count_ndrugs end)) as count_ndrugs
from
	glob
union
select
	'Thursday' as weekdays,
		round(sum(case when num_weekday = 4 then profit end)) as sum_profit,
		round(sum(case when num_weekday = 4 then count_unique_ndrugs end)) as uniq_ndrugs,
		round(sum(case when num_weekday = 4 then count_ndrugs end)) as count_ndrugs
from
	glob
union
select
	'Friday' as weekdays,
		round((sum(case when num_weekday = 5 then profit end) / 5) * 6) as sum_profit,
		round((sum(case when num_weekday = 5 then count_unique_ndrugs end) / 5) * 6) as uniq_ndrugs,
		round((sum(case when num_weekday = 5 then count_ndrugs end) / 5) * 6) as count_ndrugs
from
	glob
union
select
	'Saturday' as weekdays,
		round((sum(case when num_weekday = 6 then profit end) / 5) * 6) as sum_profit,
		round((sum(case when num_weekday = 6 then count_unique_ndrugs end) / 5) * 6) as uniq_ndrugs,
		round((sum(case when num_weekday = 6 then count_ndrugs end) / 5) * 6) as count_ndrugs
from
	glob
union
select
	'Sunday' as weekdays,
		round(sum(case when num_weekday = 7 then profit end)) as sum_profit,
		round(sum(case when num_weekday = 7 then count_unique_ndrugs end)) as uniq_ndrugs,
		round(sum(case when num_weekday = 7 then count_ndrugs end)) as count_ndrugs
from
	glob
order by sum_profit desc

--в топе по прибыли среда и пятница, но пятница по количеству товаров, как уникальных, так и общему. 
--Со средой не понятно, почему прибыли больше, у нас около сорока дней наблюдений и вывод сделать сложно. 
--Пятница это последний день недели, когда люди закупаются впрок на выходные не только продуктами, но и остальными необходимыми товарами. 
--Суббота и воскресенье в меньшинстве, возможно, потому что это выходные дни, активность покупателей в эти дни недели всегда низкая. 
--Посмотрим на прибыль и количество уникальных и всех проданных товаров по аптекам. Запрос:

with glob as (
select
	sum(dr_kol) as count_ndrugs,
	count(distinct dr_ndrugs) as count_unique_ndrugs,
	sum((dr_kol * (dr_croz - dr_czak)) - dr_sdisc) as profit,
	dr_apt,
	sum(dr_sdisc) as sum_disc,
	extract(isodow
from
	(dr_dat + dr_tim)::timestamp) as num_weekday,
	to_char((dr_dat + dr_tim)::timestamp,
	'Day') as name_weekday,
	(dr_dat + dr_tim)::timestamp as times
from
	sales
group by
	dr_apt,
	dr_dat,
	dr_tim)
select
	'Monday' as weekdays,
	dr_apt,
		round((sum(case when num_weekday = 1 then profit end) / 5) * 6) as sum_profit,
		round((sum(case when num_weekday = 1 then count_unique_ndrugs end) / 5) * 6) as uniq_ndrugs,
		round((sum(case when num_weekday = 1 then count_ndrugs end) / 5) * 6) as count_ndrugs
from
	glob
group by
	dr_apt
union
select
	'Tuesday' as weekdays,
	dr_apt,
		round(sum(case when num_weekday = 2 then profit end)) as sum_profit,
		round(sum(case when num_weekday = 2 then count_unique_ndrugs end)) as uniq_ndrugs,
		round(sum(case when num_weekday = 2 then count_ndrugs end)) as count_ndrugs
from
	glob
group by
	dr_apt
union
select
	'Wednesday' as weekdays,
	dr_apt,
		round(sum(case when num_weekday = 3 then profit end)) as sum_profit,
		round(sum(case when num_weekday = 3 then count_unique_ndrugs end)) as uniq_ndrugs,
		round(sum(case when num_weekday = 3 then count_ndrugs end)) as count_ndrugs
from
	glob
group by
	dr_apt
union
select
	'Thursday' as weekdays,
	dr_apt,
		round(sum(case when num_weekday = 4 then profit end)) as sum_profit,
		round(sum(case when num_weekday = 4 then count_unique_ndrugs end)) as uniq_ndrugs,
		round(sum(case when num_weekday = 4 then count_ndrugs end)) as count_ndrugs
from
	glob
group by
	dr_apt
union
select
	'Friday' as weekdays,
	dr_apt,
		round((sum(case when num_weekday = 5 then profit end) / 5) * 6) as sum_profit,
		round((sum(case when num_weekday = 5 then count_unique_ndrugs end) / 5) * 6) as uniq_ndrugs,
		round((sum(case when num_weekday = 5 then count_ndrugs end) / 5) * 6) as count_ndrugs
from
	glob
group by
	dr_apt
union
select
	'Saturday' as weekdays,
	dr_apt,
		round((sum(case when num_weekday = 6 then profit end) / 5) * 6) as sum_profit,
		round((sum(case when num_weekday = 6 then count_unique_ndrugs end) / 5) * 6) as uniq_ndrugs,
		round((sum(case when num_weekday = 6 then count_ndrugs end) / 5) * 6) as count_ndrugs
from
	glob
group by
	dr_apt
union
select
	'Sunday' as weekdays,
	dr_apt,
		round(sum(case when num_weekday = 7 then profit end)) as sum_profit,
		round(sum(case when num_weekday = 7 then count_unique_ndrugs end)) as uniq_ndrugs,
		round(sum(case when num_weekday = 7 then count_ndrugs end)) as count_ndrugs
from
	glob
group by
	dr_apt
order by
	sum_profit desc

--в топе по прибыли 2-я и 18-я аптеки. Самое малое - за 7-ой аптекой. 
--Судя по количеству именно уникальных товаров, все дело в ассортименте и разнообразии, которые можно разместить на большей площади (количество полок). 
--Дополнительная причина различий это проходимость (центр города, популярные торговые центры). 


	--ABC-анализ.

--Выполним многомерный анализ ABC, который включает следующие аспекты:

--1. Оценка продаж по количеству реализованных позиций.
--2. Определение прибыльности конкретной позиции.
--3. Анализ выручки, полученной от продаж.

with glob as (
select
	sum(dr_kol) as count_ndrugs,
	sum(dr_kol * dr_croz - dr_sdisc) as revenue,
	sum((dr_kol * (dr_croz - dr_czak)) - dr_sdisc) as sum_profit,
	dr_apt,
	dr_ndrugs
from
	sales
group by
	dr_apt,
	dr_ndrugs)
select
	dr_ndrugs,
	dr_apt,
	case
					when sum(count_ndrugs) over(
	order by
		count_ndrugs desc)/ sum(count_ndrugs) over() <= 0.8 then 'A'
		when sum(count_ndrugs) over(
	order by
		count_ndrugs desc)/ sum(count_ndrugs) over() <= 0.95 then 'B'
		else 'C'
	end as amount_abc,
					case
					when sum(sum_profit) over(
	order by
		sum_profit desc)/ sum(sum_profit) over() <= 0.8 then 'A'
		when sum(sum_profit) over(
	order by
		sum_profit desc)/ sum(sum_profit) over() <= 0.95 then 'B'
		else 'C'
	end as profit_abc,
					case
					when sum(revenue) over(
	order by
		revenue desc)/ sum(revenue) over() <= 0.8 then 'A'
		when sum(revenue) over(
	order by
		revenue desc)/ sum(revenue) over() <= 0.95 then 'B'
		else 'C'
	end as revenue_abc
from
	glob
group by
	dr_apt,
	dr_ndrugs,
	count_ndrugs,
	sum_profit,
	revenue
order by
	dr_apt,
	amount_abc,
	profit_abc,
	revenue_abc

