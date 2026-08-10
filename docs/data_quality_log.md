# Log de Qualidade de Dados — Olist Commercial Performance

Registro técnico dos problemas de qualidade identificados durante a ingestão dos dados e das correções aplicadas via SQL no Databricks.

---

## 1. `order_reviews` — corrupção de linhas na ingestão via `read_files()`

**Sintoma:** contagem inicial da tabela retornava valores inconsistentes entre execuções (104.162, depois 99.249 linhas), divergindo do total de referência do dataset original (99.224 linhas).

**Causa raiz — duas falhas de parsing combinadas:**

1. **Quebras de linha dentro de campos de texto.** Comentários de clientes (`review_comment_message`) por vezes contêm uma quebra de linha real (Enter) dentro do próprio texto. Sem o parâmetro `multiLine => true`, o parser interpretava essa quebra como fim de registro, fragmentando uma avaliação em duas ou mais linhas.

2. **Escape de aspas incompatível com o padrão do arquivo.** O CSV original segue a convenção RFC 4180 (aspas literais representadas por `""`), mas o parser do Spark, por padrão, espera escape via barra invertida (`\"`). Sem o parâmetro `escape => '"'`, aspas legítimas dentro de comentários quebravam o alinhamento das colunas em parte dos registros.

**Correção aplicada:**
```sql
CREATE TABLE order_reviews AS
SELECT * FROM read_files(
  '/Volumes/workspace/default/olist_raw/olist_order_reviews_dataset.csv',
  format => 'csv',
  header => true,
  multiLine => true,
  escape => '"'
);
```

**Resultado:** contagem final de **99.224 linhas**, coincidindo com o valor de referência oficialmente documentado para este dataset. Script completo em [`sql/01_create_tables.sql`](../sql/01_create_tables.sql).

**Decisão descartada:** uma tabela intermediária de "quarentena" (`order_reviews_clean`, filtrando por `LENGTH(review_id) = 32`) foi criada durante a investigação, mas removida após a correção acima — deixou de ser necessária, já que a causa raiz foi eliminada na origem.

---

## 2. `d_products` — valores nulos em `product_category_name`

**Achado:** 610 de 32.951 produtos (≈1,9%) não possuem categoria preenchida.

**Decisão:** os produtos permanecem na base (não foram excluídos), já que possuem vendas registradas e devem contar para KPIs de receita total. Análises quebradas especificamente por categoria naturalmente excluem esses registros pela ausência de valor na dimensão.

---

## 3. `d_name_translation` — cobertura incompleta

**Achado:** 2 categorias presentes em `d_products` (`pc_gamer` e `portateis_cozinha_e_preparadores_de_alimentos`) não possuem correspondência na tabela de tradução.

**Impacto:** nenhum, já que o projeto mantém os nomes de categoria em português. Registrado apenas como observação para eventual necessidade futura de versão em inglês.

---

## 4. Integridade referencial — `f_order_items` → `d_products`

**Verificação:** checagem de `product_id` órfãos (presentes na fato sem correspondência na dimensão).

**Resultado:** 0 registros órfãos — integridade referencial completa entre as duas tabelas.

---

## 5. Granularidade — múltiplas avaliações por pedido

**Achado:** aproximadamente 560 pedidos possuem mais de uma linha em `f_order_reviews` (total de pedidos distintos avaliados: 98.689; total de linhas de avaliação: 99.224).

**Impacto na modelagem:** `f_order_reviews` não pode ser tratada como dimensão 1:1 em relação a `f_orders`. A medida `Nota Media Avaliacao` utiliza `TREATAS()` para propagar corretamente o contexto de filtro entre `f_order_items` e `f_order_reviews`, tabelas fato sem relacionamento físico direto.

---

## 6. Status de pedidos e regra de receita

**Achado:** a base contém 8 valores distintos de `order_status`: delivered (96.478), shipped (1.107), canceled (625), unavailable (609), invoiced (314), processing (301), created (5), approved (2).

**Regra aplicada:** a medida `Receita_Total` exclui pedidos com status `canceled` e `unavailable`, evitando inflar o KPI de receita com pedidos que não geraram transação financeira efetiva. A `Taxa de Cancelamento` usa o total geral de pedidos como base de cálculo (denominador diferente, por medir eficiência operacional, não volume financeiro).
