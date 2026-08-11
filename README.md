# Olist Commercial Performance Analysis

Análise de performance comercial de vendedores (sellers) no marketplace Olist, construída para identificar oportunidades de crescimento, gargalos operacionais e concentração de receita — usando SQL (Databricks) e Power BI.

Projeto de portfólio desenvolvido do zero ao dashboard final, cobrindo todo o pipeline de um projeto real de BI: definição de negócio, engenharia de dados, modelagem dimensional, DAX e storytelling visual.

---

## Contexto

A [Olist](https://olist.com) é uma plataforma brasileira que conecta pequenos e médios lojistas a grandes marketplaces (Mercado Livre, Americanas, etc.) através de uma vitrine única. Este projeto usa o dataset público [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle), com cerca de 100 mil pedidos realizados entre 2016 e 2018.

## Problema de negócio

A Olist quer entender o desempenho comercial dos sellers na plataforma, identificando quem performa bem, quem tem potencial de crescimento e onde estão os gargalos que impedem o atingimento de metas de receita.

## Perguntas de negócio

1. Quais sellers e categorias geram mais receita, e qual a tendência ao longo do período?
2. Existe relação entre prazo de entrega (prometido x real) e a nota de avaliação do pedido?
3. Quais estados têm maior concentração de vendas, e quais representam oportunidade de expansão?
4. Qual o ticket médio por categoria, e onde há espaço para aumentar receita por pedido?

**Fora de escopo:** lucratividade real dos sellers (a base não contém dados de custo/COGS dos produtos — apenas preço de venda e frete) e análise de método de pagamento (não conecta diretamente às perguntas de performance comercial definidas).

## Stakeholders

- **Gerência Comercial** — foco principal: performance de sellers, oportunidades de expansão geográfica
- **Diretoria de Operações** — foco secundário: prazos de entrega e correlação com satisfação do cliente

---

## KPIs

| KPI | Descrição |
|---|---|
| Receita Total | Soma de preço + frete, excluindo pedidos cancelados/indisponíveis |
| Ticket Médio | Receita total ÷ número de pedidos |
| Taxa de Cancelamento | Pedidos cancelados ÷ total de pedidos |
| Nota Média de Avaliação | Média de review_score |
| Prazo Médio de Entrega | Dias entre compra e entrega ao cliente |
| % Pedidos no Prazo | Pedidos entregues até a data estimada |
| Receita por Seller/Categoria/Estado | Receita quebrada por dimensão |
| Concentração de Receita | Distribuição de receita entre sellers (visualizada via treemap) |

---

## Arquitetura

```
CSV (Kaggle) → Databricks (Volume) → SQL (ingestão + limpeza)
→ Tabelas tratadas → Power BI (Power Query) → Star Schema → DAX → Dashboard
```

A arquitetura segue um padrão de camadas (raw → tratada → consumo), simulando o fluxo real de um pipeline de engenharia de dados, mesmo em escala de portfólio.

## Tecnologias

- **Databricks Community Edition** (SQL / Spark) — ingestão e tratamento de dados
- **Power BI Desktop** (Power Query + DAX) — modelagem e visualização
- **Git & GitHub** — versionamento
- **Figma / PowerPoint** — design de layout e paleta institucional
- **Kaggle** — fonte de dados

---

## Qualidade de dados — desafios reais enfrentados

Durante a ingestão da tabela `order_reviews`, dois problemas reais do arquivo CSV original precisaram de investigação e correção:

1. **Quebras de linha dentro de comentários de clientes** — texto livre com Enter literal no meio do comentário fragmentava registros em múltiplas linhas. Corrigido com o parâmetro `multiLine => true` no `read_files()`.
2. **Aspas duplicadas não reconhecidas pelo parser padrão** — o Spark, por padrão, espera escape de aspas via barra invertida (`\"`), mas o CSV original segue o padrão RFC 4180 (`""`). Corrigido com `escape => '"'`.

Após as duas correções, a contagem de linhas da tabela bateu exatamente com o valor de referência oficialmente documentado para esse dataset: **99.224 registros**, eliminando a necessidade de qualquer tabela de "quarentena" para registros corrompidos.

Também foi identificado que **~560 pedidos possuem mais de uma avaliação**, exigindo o uso da função `TREATAS()` em DAX para propagar corretamente o filtro entre `f_order_items` e `f_order_reviews` (tabelas fato sem relacionamento físico direto entre si).

Detalhes completos das queries de correção em [`sql/01_create_tables.sql`](sql/01_create_tables.sql).

---

## Modelagem — Star Schema

**Tabelas fato:**
- `f_order_items` (fato principal — grão: item vendido dentro de um pedido)
- `f_order_payments` (grão: pagamento/parcela)
- `f_order_reviews` (grão: avaliação — pode haver múltiplas por pedido)
- `f_orders` (funciona como ponte/dimensão de contexto — datas e status do pedido)

**Tabelas dimensão:**
- `d_sellers`, `d_products`, `d_customers`, `d_geolocation`, `d_name_translation`, `d_Calendario`

O modelo usa múltiplas tabelas fato conectadas às mesmas dimensões — um padrão comum em modelos reais, onde diferentes fatos (venda, pagamento, avaliação) compartilham o mesmo contexto de pedido.

## Medidas DAX (20 medidas, organizadas por pasta)

| Pasta | Medidas |
|---|---|
| 01. Receita | Receita Total, Ticket Médio, % Receita Categoria |
| 02. Operacional | % Atrasados, % Cancelamento, Prazo Médio Entrega, % No Prazo |
| 03. Satisfação Clientes | Nota Média Avaliação |
| 04. Sellers | Ranking Seller, Qtd Sellers Ativos, Qtd Pedidos, Receita Média Seller, Seller Top1 |
| 05. Comparativos Temporais | Receita Mês Anterior, % Var MoM, Receita YTD, Receita Ano Anterior, % Var YoY |
| 06. Geografia | Estados Atendidos, Maior Receita, Receita Média Estado, % Receita Fora SP |

> **Nota de decisão:** as medidas da pasta "05. Comparativos Temporais" (MoM, YTD, YoY) foram implementadas para demonstrar competência técnica em inteligência temporal (`DATEADD`, `SAMEPERIODLASTYEAR`, `TOTALYTD`), mas **não são expostas no dashboard** — o dataset cobre 2016-2018 com volume muito baixo em 2016, o que tornaria comparações ano-a-ano estatisticamente não confiáveis para boa parte do período.

---

## Páginas do Dashboard

| Página | Conteúdo |
|---|---|
| **Visão Executiva** | 4 KPIs principais + receita por mês + top sellers + receita por categoria + mapa de receita por estado |
| **Performance Sellers** | KPIs de seller + scatter de desempenho (receita x ticket médio) + treemap de concentração + tabela detalhada com busca |
| **Logística e Satisfação** | Scatter prazo x nota + indicador de % no prazo + evolução de prazo e nota ao longo do tempo |
| **Geografia** | Mapa de receita, concentração de sellers por estado e scatter de oportunidade de expansão |

As páginas Visão Executiva, Performance Sellers e Logística compartilham um painel de filtros (Estado, Período, Categoria) acionado por botão, com navegação lateral consistente.

> **Nota de decisão:** a página Geografia não possui painel de filtros interativo — decisão consciente, já que o mapa e o scatter da própria página já funcionam como filtro visual (clique em um estado recorta os demais visuais), e um painel adicional seria redundante com a informação que a página já expõe.

---

## Possíveis melhorias futuras

- Explorar geolocalização (`d_geolocation`) para análises de distância entre seller e cliente
- Avaliar exposição das medidas de comparação temporal (MoM/YoY) caso o dataset seja futuramente atualizado com mais anos de histórico

---

## Estrutura do repositório

```
├── docs/          → definição de negócio, dicionário de dados, log de qualidade, paleta institucional
├── sql/           → scripts de criação de tabelas e queries de negócio
├── powerbi/       → arquivo .pbix, temas e layout de referência
└── images/        → prints do dashboard final
```

## Autor

**Eloisa Ribeiro** — Analista de BI Jr
MBA em Data Science, AI and Analytics — USP/ESALQ
