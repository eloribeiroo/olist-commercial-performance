-- Queries de negócio — Etapa 1 

-- Pergunta 1: Quais sellers e categorias geram mais receita?
SELECT
    s.seller_id,
    s.seller_state,
    p.product_category_name,
    ROUND(SUM(oi.price), 2) AS receita_total
FROM order_items oi
JOIN sellers s ON oi.seller_id = s.seller_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY s.seller_id, s.seller_state, p.product_category_name
ORDER BY receita_total DESC
LIMIT 10;

-- Pergunta 2: Existe relação entre prazo de entrega e nota de avaliação?
SELECT
    o.order_id,
    DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) AS dias_entrega,
    DATEDIFF(o.order_estimated_delivery_date, o.order_delivered_customer_date) AS dias_folga_estimativa,
    r.review_score
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL;

-- Pergunta 3: Quais estados concentram vendas / têm oportunidade de expansão?
SELECT
    s.seller_state,
    COUNT(DISTINCT s.seller_id) AS qtd_sellers,
    ROUND(SUM(oi.price), 2) AS receita_total
FROM order_items oi
JOIN sellers s ON oi.seller_id = s.seller_id
GROUP BY s.seller_state
ORDER BY receita_total DESC;

-- Pergunta 4: Qual o ticket médio por categoria?
SELECT
    p.product_category_name,
    COUNT(DISTINCT oi.order_id) AS qtd_pedidos,
    ROUND(SUM(oi.price), 2) AS receita_total,
    ROUND(SUM(oi.price) / COUNT(DISTINCT oi.order_id), 2) AS ticket_medio
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY ticket_medio DESC
LIMIT 15;