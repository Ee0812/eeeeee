/** View data **/
SELECT * FROM `bigquery-public-data.bbc_news.fulltext` LIMIT 5;

/** creates a table with_embeddings from the public dataset and text embeddings generated with the model **/

CREATE OR REPLACE TABLE
  `bbc_news.bbc_news_with_embeddings` AS (
  SELECT
    *
  FROM
    ML.GENERATE_TEXT_EMBEDDING( MODEL `bbc_news.bq_embedding_model`,
      (
      SELECT
        title,
        body,
        CONCAT(title, ": ", body) AS content
      FROM
        `bigquery-public-data.bbc_news.fulltext`
      WHERE
        LENGTH(body) > 0 AND LENGTH(title) > 0
     )
    ) WHERE ARRAY_LENGTH(text_embedding) > 0
    LIMIT 500
  );

/** query the table to return relevant news articles **/
SELECT query.query, base.title, base.body
FROM VECTOR_SEARCH(
  TABLE `bbc_news.bbc_news_with_embeddings`, 'text_embedding',
  (
  SELECT text_embedding, content AS query
  FROM ML.GENERATE_TEXT_EMBEDDING(
  MODEL `bbc_news.bq_embedding_model`,
  (SELECT 'The US Economy' AS content))
  ),
  top_k => 5, options => '{"fraction_lists_to_search": 0.01}')

  

