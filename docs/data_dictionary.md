# Dicionário de Dados — Olist Commercial Performance

Documentação das tabelas utilizadas no projeto, após ingestão via Databricks (SQL) e modelagem em Power BI. Nomes de tabela refletem a convenção adotada no modelo: prefixo `f_` para fato, `d_` para dimensão.

---

## Tabelas Fato

### `f_order_items`
Grão: 1 linha = 1 item vendido dentro de um pedido. Tabela fato principal do modelo.

| Coluna | Tipo | Descrição |
|---|---|---|
| order_id | texto | Identificador do pedido |
| order_item_id | número | Posição sequencial do item dentro do pedido |
| product_id | texto | Identificador do produto (liga a `d_products`) |
| seller_id | texto | Identificador do vendedor (liga a `d_sellers`) |
| shipping_limit_date | data/hora | Prazo limite para envio do item |
| price | decimal | Preço de venda do item |
| freight_value | decimal | Valor do frete do item |

### `f_orders`
Grão: 1 linha = 1 pedido. Funciona como dimensão de contexto/ponte entre os demais fatos (não possui métrica numérica somável).

| Coluna | Tipo | Descrição |
|---|---|---|
| order_id | texto | Identificador único do pedido |
| customer_id | texto | Identificador do cliente (liga a `d_customers`) |
| order_status | texto | Status do pedido (delivered, shipped, canceled, unavailable, invoiced, processing, created, approved) |
| order_purchase_timestamp | data/hora | Data/hora da compra |
| order_approved_at | data/hora | Data/hora de aprovação do pagamento |
| order_delivered_carrier_date | data/hora | Data de postagem/entrega à transportadora |
| order_delivered_customer_date | data/hora | Data de entrega ao cliente |
| order_estimated_delivery_date | data | Data estimada de entrega |

### `f_order_payments`
Grão: 1 linha = 1 pagamento (um pedido pode ter mais de uma linha, em caso de parcelamento/múltiplas formas de pagamento).

| Coluna | Tipo | Descrição |
|---|---|---|
| order_id | texto | Identificador do pedido |
| payment_sequential | número | Sequência do pagamento dentro do pedido |
| payment_type | texto | Forma de pagamento (cartão, boleto, etc.) |
| payment_installments | número | Número de parcelas |
| payment_value | decimal | Valor do pagamento |

### `f_order_reviews`
Grão: 1 linha = 1 avaliação. Um pedido pode ter mais de uma avaliação (~560 casos identificados na base).

| Coluna | Tipo | Descrição |
|---|---|---|
| review_id | texto | Identificador único da avaliação (32 caracteres) |
| order_id | texto | Identificador do pedido avaliado |
| review_score | número (1-5) | Nota dada pelo cliente |
| review_comment_title | texto | Título do comentário (frequentemente vazio) |
| review_comment_message | texto | Corpo do comentário |
| review_creation_date | data | Data de criação da avaliação |
| review_answer_timestamp | data/hora | Data/hora de resposta da avaliação |

---

## Tabelas Dimensão

### `d_sellers`
| Coluna | Tipo | Descrição |
|---|---|---|
| seller_id | texto | Identificador único do vendedor |
| seller_zip_code_prefix | texto | Prefixo de CEP do vendedor |
| seller_city | texto | Cidade do vendedor |
| seller_state | texto | UF do vendedor (sigla de 2 letras) |

### `d_products`
| Coluna | Tipo | Descrição |
|---|---|---|
| product_id | texto | Identificador único do produto |
| product_category_name | texto | Categoria do produto, em português (610 produtos sem valor preenchido) |
| product_name_lenght | número | Tamanho do nome do produto (caracteres) |
| product_description_lenght | número | Tamanho da descrição (caracteres) |
| product_photos_qty | número | Quantidade de fotos do anúncio |
| product_weight_g | número | Peso em gramas |
| product_length_cm / product_height_cm / product_width_cm | número | Dimensões físicas do produto |

### `d_customers`
| Coluna | Tipo | Descrição |
|---|---|---|
| customer_id | texto | Identificador do cliente associado ao pedido |
| customer_unique_id | texto | Identificador único do cliente (persiste entre pedidos) |
| customer_zip_code_prefix | texto | Prefixo de CEP do cliente |
| customer_city | texto | Cidade do cliente |
| customer_state | texto | UF do cliente |

### `d_geolocation`
| Coluna | Tipo | Descrição |
|---|---|---|
| geolocation_zip_code_prefix | texto | Prefixo de CEP |
| geolocation_lat / geolocation_lng | decimal | Latitude/longitude |
| geolocation_city | texto | Cidade |
| geolocation_state | texto | UF |

> Não utilizada nas análises atuais do dashboard — candidata a uso futuro para análises de distância seller-cliente.

### `d_name_translation`
| Coluna | Tipo | Descrição |
|---|---|---|
| product_category_name | texto | Categoria em português (chave de ligação com `d_products`) |
| product_category_name_english | texto | Tradução da categoria para inglês |

> 2 categorias (`pc_gamer`, `portateis_cozinha_e_preparadores_de_alimentos`) não possuem tradução correspondente nesta tabela.

### `d_Calendario`
Tabela de datas criada via DAX (`CALENDAR()`), cobrindo de 01/01/2016 a 31/12/2018. Colunas derivadas: `Ano`, `Número Mes`, `Nome Mes`, `Mes Ano`, `Trimestre`, `Ordem Mes` (auxiliar de ordenação cronológica).

---

## Relacionamentos do modelo

| De | Para | Cardinalidade | Direção do filtro |
|---|---|---|---|
| f_order_items | d_sellers | Muitos : 1 | Única |
| f_order_items | d_products | Muitos : 1 | Única |
| f_order_items | f_orders | Muitos : 1 | Única |
| f_order_payments | f_orders | Muitos : 1 | Única |
| f_order_reviews | f_orders | Muitos : 1 | Única |
| f_orders | d_customers | Muitos : 1 | Bidirecional |
| f_orders | d_Calendario | Muitos : 1 | Única |
| d_products | d_name_translation | Muitos : 1 | Única |

**Nota técnica:** `f_order_items` e `f_order_reviews` não possuem relacionamento físico direto entre si (ambas se conectam a `f_orders`). A medida `Nota Media Avaliacao` utiliza `TREATAS()` em DAX para propagar corretamente o filtro de contexto entre as duas tabelas fato.
