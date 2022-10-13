DROP TABLE IF EXISTS dim.product CASCADE;
CREATE TABLE dim.product (
    id serial not null primary key,
    code varchar(20) not null,
    name varchar(250) not null,
    artist varchar(150) not null,
    product_type varchar(20) not null,
    product_category varchar(30) not null,
    unit_price float8 not null,
    unit_cost float8 not null,
    status varchar(15) not null,
    effective_ts date not null,
    expire_ts date not null,
    is_current bool
);

INSERT INTO dim.product (code, name, artist, product_type, product_category, unit_price, unit_cost, status, effective_ts, expire_ts, is_current)
WITH genres as (
    SELECT DISTINCT m2g.music_id, first_value(g.name) over (partition by music_id order by genre_id) as genre_id
    FROM nds.music_to_genres m2g
    JOIN nds.genres g on g.id = m2g.genre_id
)
SELECT
  m.id::varchar as code,
  m.album as name,
  coalesce(a.name, 'Неизвестно') as artist,
  'Музыка' as product_type,
  coalesce(genres.genre_id, 'Неизвестно') as product_category,
  m.price as unit_price,
  m.cost as unit_cost,
  CASE
      WHEN m.status = 'p' THEN 'Ожидается'
      WHEN m.status = 'o' THEN 'Доступен'
      WHEN m.status = 'e' THEN 'Не продаётся'
  END AS status,
  m.start_ts as effective_ts,
  m.end_ts as expire_ts,
  m.is_current
FROM nds.music m
LEFT JOIN nds.artists a on a.id = m.artist_id
LEFT JOIN genres on genres.music_id = m.id
;


INSERT INTO dim.product (code, name, artist, product_type, product_category, unit_price, unit_cost, status, effective_ts, expire_ts, is_current)
with cameraman as (select  distinct  ftc.film_id  , first_value(fc."name") over (partition by film_id  order by cameraman_id) as cameraman_id  
	from nds.films_to_cameraman ftc
	join nds.films_cameraman fc on fc.id = ftc.cameraman_id )
select 
	f.id::varchar  as code,
	f.title as name,
	coalesce (cameraman.cameraman_id, 'Неизвестно') as artist,
	fc2.name  as product_type,
	coalesce (fg.name, 'Неизвестно') as product_category,
	f.price as unit_price,
	f.cost as unit_cost,
	case 
		when f.status = 'p' then 'Ожидается'
		when f.status = 'o' then 'Доступен'
		when f.status = 'e' then 'Не продается'
	end as status,
	f.start_ts as effective_ts,
	f.end_ts as expire_ts,
	f.is_current as is_current		
from nds.films f  
full join nds.films_genre fg on fg.id = f.genre_id  
join nds.films_category fc2 on fc2.id = f.category_id 
full join cameraman  on cameraman.film_id = f.id  

select * from dim.product p 
where product_type = 'Кино'

select * from fact.sale_item si 

DROP TABLE fact.sale_item;
CREATE TABLE fact.sale_item (
    date_key int not null references dim.date(id),
    customer_key int not null references dim.customer(id),
    product_key int references dim.product(id),
    store_key int references dim.store(id),
    dt timestamp not null,
    transaction_id int not null,
    line_number smallint not null,
    quantity smallint not null,
    unit_price float8,
    unit_cost float8,
    sales_value float8,
    sales_cost float8,
    margin float8
);


INSERT INTO fact.sale_item (date_key, customer_key, product_key, dt, transaction_id, line_number, quantity, unit_price, unit_cost, sales_value, sales_cost, margin)
SELECT
     to_char(dt, 'YYYYMMDD')::int as date_key,
     customer_id,
     p.id,
     dt, transaction_id, line_number, quantity,
     p.unit_price, p.unit_cost, p.unit_price * si.quantity, p.unit_cost*si.quantity, p.unit_price * si.quantity - p.unit_cost*si.quantity
FROM nds.sale_item si
LEFT JOIN dim.product p ON p.code::int = si.music_id
;


INSERT INTO fact.sale_item (date_key, customer_key, product_key, dt, transaction_id, line_number, quantity, unit_price, unit_cost, sales_value, sales_cost, margin)
SELECT
     to_char(dt, 'YYYYMMDD')::int as date_key,
     customer_id,
     p.id,
     dt, transaction_id, line_number, quantity,
     p.unit_price, p.unit_cost, p.unit_price * si.quantity, p.unit_cost*si.quantity, p.unit_price * si.quantity - p.unit_cost*si.quantity
FROM nds.sale_item si
LEFT JOIN dim.product p ON p.code::int = si.film_id 
;

