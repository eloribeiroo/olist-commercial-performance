-- Criação das tabelas a partir dos CSVs 
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

-- order_reviews exige tratamento especial: comentários de clientes
-- contêm quebras de linha e aspas dentro do próprio texto, o que
-- quebra o parser CSV padrão do Spark. Dois parâmetros resolvem:
--
--   multiLine => true
--     Permite que um campo entre aspas contenha quebras de linha
--     reais, sem que o parser interprete isso como fim do registro.
--
--   escape => '"'
--     Informa que aspas duplicadas ("") dentro de um campo de texto
--     representam uma aspas literal (padrão RFC 4180) — sem isso,
--     o Spark usa barra invertida como escape por padrão, o que não
--     bate com o formato real do arquivo e gera linhas corrompidas.
--

DROP TABLE IF EXISTS order_reviews;

CREATE TABLE order_reviews AS
SELECT * FROM read_files(
  '/Volumes/workspace/default/olist_raw/olist_order_reviews_dataset.csv',
  format => 'csv',
  header => true,
  multiLine => true,
  escape => '"'
);