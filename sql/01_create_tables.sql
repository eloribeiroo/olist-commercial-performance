-- Criação das tabelas a partir dos CSVs (Volume)
-- Fonte: Olist Brazilian E-Commerce Dataset (Kaggle)

CREATE TABLE sellers AS
SELECT * FROM read_files(
  '/Volumes/workspace/default/olist_raw/olist_sellers_dataset.csv',
  format => 'csv', header => true
);

CREATE TABLE products AS
SELECT * FROM read_files(
  '/Volumes/workspace/default/olist_raw/olist_products_dataset.csv',
  format => 'csv', header => true
);

CREATE TABLE customers AS
SELECT * FROM read_files(
  '/Volumes/workspace/default/olist_raw/olist_customers_dataset.csv',
  format => 'csv', header => true
);

CREATE TABLE geolocation AS
SELECT * FROM read_files(
  '/Volumes/workspace/default/olist_raw/olist_geolocation_dataset.csv',
  format => 'csv', header => true
);

CREATE TABLE name_translation AS
SELECT * FROM read_files(
  '/Volumes/workspace/default/olist_raw/product_category_name_translation.csv',
  format => 'csv', header => true
);

CREATE TABLE order_items AS
SELECT * FROM read_files(
  '/Volumes/workspace/default/olist_raw/olist_order_items_dataset.csv',
  format => 'csv', header => true
);

CREATE TABLE order_payments AS
SELECT * FROM read_files(
  '/Volumes/workspace/default/olist_raw/olist_order_payments_dataset.csv',
  format => 'csv', header => true
);

CREATE TABLE orders AS
SELECT * FROM read_files(
  '/Volumes/workspace/default/olist_raw/olist_orders_dataset.csv',
  format => 'csv', header => true
);

-- order_reviews exige tratamento especial: comentários de clientes contêm
-- quebras de linha e aspas mal-formatadas que quebram o parser CSV padrão.
-- multiLine => true resolve quebras de linha dentro de campos de texto.
-- unescapedQuoteHandling => 'BACK_TO_DELIMITER' resolve aspas soltas mal-formatadas.
DROP TABLE IF EXISTS order_reviews;

CREATE TABLE order_reviews AS
SELECT * FROM read_files(
  '/Volumes/workspace/default/olist_raw/olist_order_reviews_dataset.csv',
  format => 'csv',
  header => true,
  multiLine => true,
  unescapedQuoteHandling => 'BACK_TO_DELIMITER'
);

-- Camada "clean": remove ~0,02% de registros com review_id corrompido
-- (limitação residual conhecida da fonte, documentada em docs/data_quality_log.md)

CREATE OR REPLACE TABLE order_reviews_clean AS
SELECT *
FROM order_reviews
WHERE LENGTH(review_id) = 32;