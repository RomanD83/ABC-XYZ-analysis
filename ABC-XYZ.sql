--ABC-анализ товаров аптечной сети.

--ABC-анализ — это метод классификации и сегментации ассортимента товаров или клиентов на основе их значимости или важности для бизнеса. 
--Он получил название "ABC" по первым буквам английских терминов: "A" означает наиболее значимые или критически важные элементы, "B" — средне значимые, а "C" — наименее значимые или не критические.
--В основе ABC-анализа лежит принцип Парето, также известный как "правило 80/20", согласно которому примерно 20% элементов порождают 80% результатов. 
--В контексте ABC-анализа это означает, что обычно небольшая доля товаров или клиентов (группа "A") приносит основную часть прибыли или имеет наибольшую стоимость или потенциал для компании. 
--Затем следует сегмент "B" средне значимых товаров или клиентов, которые приносят более умеренные результаты, и группа "C" с наименее значимыми элементами, вклад которых в общие результаты ограничен. 
--ABC-анализ позволяет более эффективно распределить ресурсы и фокусироваться на наиболее важных аспектах бизнеса. 
--Например, в контексте управления запасами, основанным на ABC-анализе, наиболее значимые товары (группа "A") могут быть сконцентрированы для более точного контроля и управления, 
--тогда как товары из групп "B" и "C" могут требовать меньшего внимания и меньших затрат.
--Задача: провести ABC/XYZ-анализ продуктов аптечной сети и вычленить качественные группы по значимости.
--Решение.
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

--6560 товаров, 8 аптек (2, 6, 7, 11, 13, 15, 17, 18) и 39 дней продаж. Несмотря на небольшое количество дней для анализа, особенно для XYZ, примем данную условность за реальную. 
--39 дней - это неровное количество дней недели. Поэтому надо посчитать, сколько и каких:

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

--понедельник, пятница и суббота 5 дней, остальные по 6 дней. В сумме 39, потерь нет.

--Посмотрим на количество проданных товаров по аптекам, уникальных товаров и суммы прибыли. 
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

--в топе по прибыли 2-я и 18-я аптеки. Самое малое - за 7-ой аптекой. Судя по количеству именно уникальных товаров, все дело в ассортименте и разнообразии, 
--которые можно разместить на большей площади (количество полок). Дополнительная причина различий это, возможно, проходимость покупателей (центр города, популярные торговые центры). 

--ABC-анализ.

--Выполним многомерный анализ ABC, который включает следующие аспекты:

--1. Оценка продаж по количеству реализованных позиций - sum_ndrugs.
--2. Определение прибыльности конкретной позиции - profit.
--3. Анализ выручки, полученной от продаж - revenue.

with a as (
select
	dr_ndrugs,
	sum(dr_kol) as sum_ndrugs,
		sum(dr_kol * dr_croz - dr_sdisc) as revenue,
		sum(dr_kol * (dr_croz - dr_czak) - dr_sdisc) as profit
from
	sales
group by
	dr_ndrugs)
select
	dr_ndrugs,
	case
					when sum(sum_ndrugs) over(
		order by sum_ndrugs desc)/ sum(sum_ndrugs) over() <= 0.8 then 'A'
		when sum(sum_ndrugs) over(
		order by sum_ndrugs desc)/ sum(sum_ndrugs) over() <= 0.95 then 'B'
		else 'C'
	end as sum_ndrugs_abc,
					case
					when sum(profit) over(
		order by profit desc)/ sum(profit) over() <= 0.8 then 'A'
		when sum(profit) over(
		order by profit desc)/ sum(profit) over() <= 0.95 then 'B'
		else 'C'
	end as profit_abc,
					case
					when sum(revenue) over(
		order by revenue desc)/ sum(revenue) over() <= 0.8 then 'A'
		when sum(revenue) over(
		order by revenue desc)/ sum(revenue) over() <= 0.95 then 'B'
		else 'C'
	end as revenue_abc
from
	a
order by
	sum_ndrugs_abc,
	profit_abc,
	revenue_abc

--1. Группа A (наиболее значимая):
--   - В группу A включаются товары с наибольшей значимостью или влиянием на прибыль.
--   - Элементы этой группы могут представлять основную часть общей стоимости, дохода.
--   - Рекомендуется уделить особое внимание товарам из группы A и разработать стратегии для привлечения к ним внимания покупателей.

--2. Группа B (умеренная значимость):
--   - Товары в группе B имеют умеренную значимость.
--   - Они вносят некоторый вклад в общий доход или потенциал, но не настолько существенны, как товары из группы A.
--   - Рекомендуется принимать меры для поддержания и улучшения продаваемости товаров из группы B.
--   - Эти товары могут иметь потенциал для роста их продаж или повышения значимости в будущем.

--3. Группа C (наименее значимая):
--   - Товары в группе C имеют наименьшую значимость или влияние на прибыль.
--   - Они вносят небольшой вклад в общий доход.
-- - Можно принять решение о сокращении товаров, связанных с группой C, чтобы сосредоточиться на более значимых товарах.
--   - Необходимо периодически пересматривать товары из группы C, чтобы определить, есть ли у них потенциал.

--XYZ-анализ.

--Анализ XYZ используется для классификации товаров в зависимости от регулярности их продаж. 
--Этот метод позволяет определить оптимальное количество товара на складе, чтобы избежать его излишков или дефицита и обеспечить максимальную прибыль. 
--Для проведения анализа требуется информация о продажах товаров за несколько месяцев, чтобы оценить устойчивость спроса в различные периоды. 
--XYZ-анализ выделяет товары с различными уровнями стабильности спроса. 
--Это достигается путем расчета изменения объема продаж от месяца к месяцу и определения коэффициента вариации для каждой группы товаров. 
--Коэффициент вариации указывает на вариативность спроса в определенный период:

--- Товары класса X характеризуются стабильным спросом с колебаниями в пределах 0−10%.
--- Товары класса Y, например, сезонные товары, имеют средний уровень стабильности спроса с колебаниями от 10 до 25%.
--- Товары класса Z обладают случайным спросом с колебаниями свыше 25%.

--Так как в данных всего лишь 39 дней, вместо месяцев возьмем недели. Всего их шесть, включая неполные. 
--За ориентир определения качества продаж возьмем продажи товара в течении четырех и более недель. Вычленим недели и количество продаж. Запрос:

select
	dr_ndrugs as product,
	to_char(dr_dat,
	'WW') as week_sales,
	sum(dr_kol) as sales
from
	sales
group by
	product,
	week_sales

--Теперь выделим качество товаров по регулярности продаж. Запрос:

with xyz_sales as (
select
	dr_ndrugs as product,
	to_char(dr_dat,
	'WW') as week_sales,
	sum(dr_kol) as sales
from
	sales
group by
	product,
	week_sales)
select
	product,
	case
		when stddev_samp(sales)/ avg(sales) >= 0.25 then 'Z'
		when stddev_samp(sales)/ avg(sales) >= 0.1 then 'Y'
		else 'X'
	end xyz_sales
from
	xyz_sales
group by
	product
having
	count(distinct week_sales) >= 4

--Вывод.

--Категория X представляет товары, которые привлекают большое количество покупателей, и поэтому всегда должны быть в наличии на складе.

	--Категория Y характеризуется небольшим, но предсказуемым спросом на товары. Нет необходимости закупаться ими в больших количествах. 
--Однако стоит проанализировать, почему товары попали в эту группу. Возможно, это связано с сезонными факторами или возникли проблемы с производством и поставками. 
--Поняв причину, можно определить, как лучше обращаться с товарами этой категории.

--Категория Z включает товары, которые характеризуются единичными или редкими покупками. 
--В отношении товаров этой группы можно безболезненно отказаться или осуществлять их поставку по предварительным заказам. Однако следует убедиться, 
--что товары действительно попали в эту группу из-за снижения спроса, а не из-за проблем с поставкой.

--Оба запроса по ABC и XYZ анализам можно объединить в один:

with abc_sales as (
select
	dr_ndrugs as product,
	sum(dr_kol) as sum_ndrugs,
	sum(dr_kol *(dr_croz - dr_czak) - dr_sdisc) as profit,
	sum(dr_kol * dr_croz - dr_sdisc) as revenue
from
	sales s
group by
	dr_ndrugs
),
xyz_sales as (
select
	dr_ndrugs as product,
	to_char(dr_dat,
	'YYYY-WW') as ym,
	sum(dr_kol) as sales
from
	sales
group by
	product,
	ym
),
xyz_analysis as (
select
	product,
	case
		when stddev_samp(sales)/ avg(sales) >= 0.25 then 'Z'
		when stddev_samp(sales)/ avg(sales) >= 0.1 then 'Y'
		else 'X'
	end xyz_sales
from
	xyz_sales
group by
	product
having
	count(distinct ym) >= 4
)
select
	abc.product,
	case
		when sum(sum_ndrugs) over(
		order by sum_ndrugs desc) / sum(sum_ndrugs) over() <= 0.8 then 'A'
		when sum(sum_ndrugs) over(
		order by sum_ndrugs desc) / sum(sum_ndrugs) over() <= 0.95 then 'B'
		else 'C'
	end sum_ndrugs_abc,
	case
		when sum(profit) over(
		order by profit desc) / sum(profit) over() <= 0.8 then 'A'
		when sum(profit) over(
		order by profit desc) / sum(profit) over() <= 0.95 then 'B'
		else 'C'
	end profit_abc,
	case
		when sum(revenue) over(
		order by revenue desc) / sum(revenue) over() <= 0.8 then 'A'
		when sum(revenue) over(
		order by revenue desc) / sum(revenue) over() <= 0.95 then 'B'
		else 'C'
	end revenue_abc,
	x.xyz_sales
from
	abc_sales as abc
left join xyz_analysis as x
on
	abc.product = x.product
order by
	sum_ndrugs_abc,
	profit_abc,
	revenue_abc,
	xyz_sales


