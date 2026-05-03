#!/bin/bash
# =============================================================================
# run_spark_benchmark.sh
# Executa as 13 consultas SSB no Spark SQL (SEM cache) usando UMA ÚNICA
# sessão spark-sql (um único SparkContext). Isso evita o overhead de
# inicializar o Spark 13 vezes e esgotar os recursos YARN.
#
# Uso:
#   sudo -u hive nohup bash /var/oled/ssb_stage/run_spark_benchmark.sh > /dev/null 2>&1 &
#
# O log será gravado em: /var/oled/ssb_stage/spark_benchmark.log
# =============================================================================

LOGFILE="/var/oled/ssb_stage/spark_benchmark.log"
SQLFILE="/var/oled/ssb_stage/spark_queries.sql"

# Gera o arquivo SQL com todas as queries de uma vez
cat > "$SQLFILE" << 'ENDOFSQL'
USE ssb;

-- Query 01 (Q1.1)
SELECT sum(lo_extendedprice*lo_discount) as revenue
FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey
WHERE d_year = 1993
  AND lo_discount between 1 and 3
  AND lo_quantity < 25;

-- Query 02 (Q1.2)
SELECT sum(lo_extendedprice*lo_discount) as revenue
FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey
WHERE d_yearmonthnum = 199401
  AND lo_discount between 4 and 6
  AND lo_quantity between 26 and 35;

-- Query 03 (Q1.3)
SELECT sum(lo_extendedprice*lo_discount) as revenue
FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey
WHERE d_weeknuminyear = 6
  AND d_year = 1994
  AND lo_discount between 5 and 7
  AND lo_quantity between 26 and 35;

-- Query 04
SELECT sum(lo_revenue), d_year, p_brand
FROM ssb.lineorder
JOIN ssb.dwdate ON lo_orderdate = d_datekey
JOIN ssb.part ON lo_partkey = p_partkey
JOIN ssb.supplier ON lo_suppkey = s_suppkey
WHERE p_category LIKE '%MFGR#12%'
  AND s_region LIKE '%AMERICA%'
GROUP BY d_year, p_brand
ORDER BY d_year, p_brand;

-- Query 05
SELECT sum(lo_revenue), d_year, p_brand
FROM ssb.lineorder
JOIN ssb.dwdate ON lo_orderdate = d_datekey
JOIN ssb.part ON lo_partkey = p_partkey
JOIN ssb.supplier ON lo_suppkey = s_suppkey
WHERE p_brand between 'MFGR#2221' and 'MFGR#2228'
  AND s_region LIKE '%ASIA%'
GROUP BY d_year, p_brand
ORDER BY d_year, p_brand;

-- Query 06
SELECT sum(lo_revenue), d_year, p_brand
FROM ssb.lineorder
JOIN ssb.dwdate ON lo_orderdate = d_datekey
JOIN ssb.part ON lo_partkey = p_partkey
JOIN ssb.supplier ON lo_suppkey = s_suppkey
WHERE p_brand LIKE '%MFGR#2221%'
  AND s_region LIKE '%EUROPE%'
GROUP BY d_year, p_brand
ORDER BY d_year, p_brand;

-- Query 07
SELECT c_nation, s_nation, d_year, sum(lo_revenue) as revenue
FROM ssb.lineorder
JOIN ssb.customer ON lo_custkey = c_custkey
JOIN ssb.supplier ON lo_suppkey = s_suppkey
JOIN ssb.dwdate ON lo_orderdate = d_datekey
WHERE c_region LIKE '%ASIA%' AND s_region LIKE '%ASIA%'
  AND d_year >= 1992 AND d_year <= 1997
GROUP BY c_nation, s_nation, d_year
ORDER BY d_year asc, revenue desc;

-- Query 08
SELECT c_city, s_city, d_year, sum(lo_revenue) as revenue
FROM ssb.lineorder
JOIN ssb.customer ON lo_custkey = c_custkey
JOIN ssb.supplier ON lo_suppkey = s_suppkey
JOIN ssb.dwdate ON lo_orderdate = d_datekey
WHERE c_nation LIKE '%UNITED STATES%'
  AND s_nation LIKE '%UNITED STATES%'
  AND d_year >= 1992 AND d_year <= 1997
GROUP BY c_city, s_city, d_year
ORDER BY d_year asc, revenue desc;

-- Query 09
SELECT c_city, s_city, d_year, sum(lo_revenue) as revenue
FROM ssb.lineorder
JOIN ssb.customer ON lo_custkey = c_custkey
JOIN ssb.supplier ON lo_suppkey = s_suppkey
JOIN ssb.dwdate ON lo_orderdate = d_datekey
WHERE (c_city LIKE '%UNITED KI1%' or c_city LIKE '%UNITED KI5%')
  AND (s_city LIKE '%UNITED KI1%' or s_city LIKE '%UNITED KI5%')
  AND d_year >= 1992 AND d_year <= 1997
GROUP BY c_city, s_city, d_year
ORDER BY d_year asc, revenue desc;

-- Query 10
SELECT c_city, s_city, d_year, sum(lo_revenue) as revenue
FROM ssb.lineorder
JOIN ssb.customer ON lo_custkey = c_custkey
JOIN ssb.supplier ON lo_suppkey = s_suppkey
JOIN ssb.dwdate ON lo_orderdate = d_datekey
WHERE (c_city LIKE '%UNITED KI1%' or c_city LIKE '%UNITED KI5%')
  AND (s_city LIKE '%UNITED KI1%' or s_city LIKE '%UNITED KI5%')
  AND d_yearmonth LIKE '%Dec1997%'
GROUP BY c_city, s_city, d_year
ORDER BY d_year asc, revenue desc;

-- Query 11
SELECT d_year, c_nation, sum(lo_revenue - lo_supplycost) as profit
FROM ssb.lineorder
JOIN ssb.dwdate ON lo_orderdate = d_datekey
JOIN ssb.customer ON lo_custkey = c_custkey
JOIN ssb.supplier ON lo_suppkey = s_suppkey
JOIN ssb.part ON lo_partkey = p_partkey
WHERE c_region LIKE '%AMERICA%'
  AND s_region LIKE '%AMERICA%'
  AND (p_mfgr LIKE '%MFGR#1%' or p_mfgr LIKE '%MFGR#2%')
GROUP BY d_year, c_nation
ORDER BY d_year, c_nation;

-- Query 12
SELECT d_year, s_nation, p_category, sum(lo_revenue - lo_supplycost) as profit
FROM ssb.lineorder
JOIN ssb.dwdate ON lo_orderdate = d_datekey
JOIN ssb.customer ON lo_custkey = c_custkey
JOIN ssb.supplier ON lo_suppkey = s_suppkey
JOIN ssb.part ON lo_partkey = p_partkey
WHERE c_region LIKE '%AMERICA%'
  AND s_region LIKE '%AMERICA%'
  AND (d_year = 1997 or d_year = 1998)
  AND (p_mfgr LIKE '%MFGR#1%' or p_mfgr LIKE '%MFGR#2%')
GROUP BY d_year, s_nation, p_category
ORDER BY d_year, s_nation, p_category;

-- Query 13
SELECT d_year, s_city, p_brand, sum(lo_revenue - lo_supplycost) as profit
FROM ssb.lineorder
JOIN ssb.dwdate ON lo_orderdate = d_datekey
JOIN ssb.customer ON lo_custkey = c_custkey
JOIN ssb.supplier ON lo_suppkey = s_suppkey
JOIN ssb.part ON lo_partkey = p_partkey
WHERE c_region LIKE '%AMERICA%'
  AND s_nation LIKE '%UNITED STATES%'
  AND (d_year = 1997 or d_year = 1998)
  AND p_category LIKE '%MFGR#14%'
GROUP BY d_year, s_city, p_brand
ORDER BY d_year, s_city, p_brand;
ENDOFSQL

# Limpa log anterior
> "$LOGFILE"

echo "=============================================" | tee -a "$LOGFILE"
echo " Spark SQL (Sem Cache) - Início: $(date)"     | tee -a "$LOGFILE"
echo " Executando 13 queries em sessão única"        | tee -a "$LOGFILE"
echo "=============================================" | tee -a "$LOGFILE"

START_TS=$(date +%s%N)

# Executa TUDO em uma única sessão spark-sql
# O Spark imprime "Time taken: X.XXX seconds" após cada statement
# Memória reduzida para caber no cluster Free Tier (evitar OOM kills nos workers)
spark-sql --master yarn \
  --driver-memory 512m \
  --executor-memory 512m \
  --num-executors 1 \
  --executor-cores 1 \
  --conf spark.executor.memoryOverhead=256m \
  --conf spark.sql.shuffle.partitions=4 \
  -f "$SQLFILE" 2>&1 | tee -a "$LOGFILE"

END_TS=$(date +%s%N)
ELAPSED_MS=$(( (END_TS - START_TS) / 1000000 ))
ELAPSED_S=$(awk "BEGIN {printf \"%.3f\", ${ELAPSED_MS}/1000}")

echo "" | tee -a "$LOGFILE"
echo "=============================================" | tee -a "$LOGFILE"
echo " Spark SQL (Sem Cache) - Fim: $(date)"        | tee -a "$LOGFILE"
echo " Tempo total: ${ELAPSED_S}s"                   | tee -a "$LOGFILE"
echo "=============================================" | tee -a "$LOGFILE"

# Limpa arquivo SQL temporário
rm -f "$SQLFILE"
