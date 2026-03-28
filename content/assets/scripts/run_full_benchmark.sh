#!/usr/bin/env bash

# ==============================================================================
# OCI Free Tier Master Benchmark Script: Hive vs Spark vs Spark (Hybrid Cache)
# ==============================================================================
# Este script automatiza as execuções das 14 consultas do SSB nos três contextos
# de processamento, aplicando limites drásticos de memória no YARN e usando
# 48 partições de shuffle para prevenir 'Out Of Memory' (OOM) no SO Linux.
# As execuções geram logs contínuos na pasta /var/oled/ssb_stage/.

LOG_DIR="/tmp/ssb_logs"
mkdir -p ${LOG_DIR}
HIVE_LOG="${LOG_DIR}/full_hive_benchmark.log"
SPARK_LOG="${LOG_DIR}/full_spark_benchmark.log"
SPARK_CACHE_LOG="${LOG_DIR}/full_spark_cache_benchmark.log"

HIVE_URI="jdbc:hive2://node1.cdp:10000"

echo "====================================================================="
echo " INICIANDO BATERIA COMPLETA DE TESTES OCI FREE TIER (SSB SF1)"
echo " Iniciado em: $(date)"
echo "====================================================================="

# ==============================================================================
# 0. FUNÇÃO PÚBLICA DE FAXINA (EVITA OOM KILLER)
# ==============================================================================
clean_cluster() {
    echo " "
    echo "--> [LIMPANDO CLUSTER] Matando containers Zumbis no YARN..."
    # Lista APENAS apps do Spark e os mata silenciosamente (NÃO PODE MATAR O TEZ DO HIVE!)
    for app in $(yarn application -list -appStates ACCEPTED,RUNNING 2>/dev/null | grep -i "spark" | awk '{print $1}' | grep application_); do 
        yarn application -kill $app > /dev/null 2>&1
    done
    sleep 3
    
    echo "--> [LIMPANDO CLUSTER] Apagando arquivos residuais do SparkStaging..."
    hdfs dfs -rm -r -f /user/hive/.sparkStaging/* 2>/dev/null
    
    echo "--> [CLUSTER LIMPO] Pronto para próxima bateria pesada de queries."
    sleep 5
}

# ==============================================================================
# QUERIES CATÁLOGO (Injetadas em Arquivos Físicos)
# ==============================================================================
cat << 'EOF' > ${LOG_DIR}/queries_raw.sql
SELECT sum(lo_extendedprice*lo_discount) as revenue FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey WHERE d_yearmonthnum = 199401 AND lo_discount between 4 and 6 AND lo_quantity between 26 and 35;
SELECT sum(lo_extendedprice*lo_discount) as revenue FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey WHERE d_year = 1993 AND lo_discount between 1 and 3 AND lo_quantity < 25;
SELECT sum(lo_extendedprice*lo_discount) as revenue FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey WHERE d_yearmonthnum = 199401 AND lo_discount between 4 and 6 AND lo_quantity between 26 and 35;
SELECT sum(lo_extendedprice*lo_discount) as revenue FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey WHERE d_weeknuminyear = 6 AND d_year = 1994 AND lo_discount between 5 and 7 AND lo_quantity between 26 and 35;
SELECT sum(lo_revenue), d_year, p_brand FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey JOIN ssb.part ON lo_partkey = p_partkey JOIN ssb.supplier ON lo_suppkey = s_suppkey WHERE p_category LIKE '%MFGR#12%' AND s_region LIKE '%AMERICA%' GROUP BY d_year, p_brand ORDER BY d_year, p_brand;
SELECT sum(lo_revenue), d_year, p_brand FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey JOIN ssb.part ON lo_partkey = p_partkey JOIN ssb.supplier ON lo_suppkey = s_suppkey WHERE p_brand between 'MFGR#2221' and 'MFGR#2228' AND s_region LIKE '%ASIA%' GROUP BY d_year, p_brand ORDER BY d_year, p_brand;
SELECT sum(lo_revenue), d_year, p_brand FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey JOIN ssb.part ON lo_partkey = p_partkey JOIN ssb.supplier ON lo_suppkey = s_suppkey WHERE p_brand LIKE '%MFGR#2221%' AND s_region LIKE '%EUROPE%' GROUP BY d_year, p_brand ORDER BY d_year, p_brand;
SELECT c_nation, s_nation, d_year, sum(lo_revenue) as revenue FROM ssb.lineorder JOIN ssb.customer ON lo_custkey = c_custkey JOIN ssb.supplier ON lo_suppkey = s_suppkey JOIN ssb.dwdate ON lo_orderdate = d_datekey WHERE c_region LIKE '%ASIA%' AND s_region LIKE '%ASIA%' AND d_year >= 1992 AND d_year <= 1997 GROUP BY c_nation, s_nation, d_year ORDER BY d_year asc, revenue desc;
SELECT c_city, s_city, d_year, sum(lo_revenue) as revenue FROM ssb.lineorder JOIN ssb.customer ON lo_custkey = c_custkey JOIN ssb.supplier ON lo_suppkey = s_suppkey JOIN ssb.dwdate ON lo_orderdate = d_datekey WHERE c_nation LIKE '%UNITED STATES%' AND s_nation LIKE '%UNITED STATES%' AND d_year >= 1992 AND d_year <= 1997 GROUP BY c_city, s_city, d_year ORDER BY d_year asc, revenue desc;
SELECT c_city, s_city, d_year, sum(lo_revenue) as revenue FROM ssb.lineorder JOIN ssb.customer ON lo_custkey = c_custkey JOIN ssb.supplier ON lo_suppkey = s_suppkey JOIN ssb.dwdate ON lo_orderdate = d_datekey WHERE (c_city LIKE '%UNITED KI1%' or c_city LIKE '%UNITED KI5%') AND (s_city LIKE '%UNITED KI1%' or s_city LIKE '%UNITED KI5%') AND d_year >= 1992 AND d_year <= 1997 GROUP BY c_city, s_city, d_year ORDER BY d_year asc, revenue desc;
SELECT c_city, s_city, d_year, sum(lo_revenue) as revenue FROM ssb.lineorder JOIN ssb.customer ON lo_custkey = c_custkey JOIN ssb.supplier ON lo_suppkey = s_suppkey JOIN ssb.dwdate ON lo_orderdate = d_datekey WHERE (c_city LIKE '%UNITED KI1%' or c_city LIKE '%UNITED KI5%') AND (s_city LIKE '%UNITED KI1%' or s_city LIKE '%UNITED KI5%') AND d_yearmonth LIKE '%Dec1997%' GROUP BY c_city, s_city, d_year ORDER BY d_year asc, revenue desc;
SELECT d_year, c_nation, sum(lo_revenue - lo_supplycost) as profit FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey JOIN ssb.customer ON lo_custkey = c_custkey JOIN ssb.supplier ON lo_suppkey = s_suppkey JOIN ssb.part ON lo_partkey = p_partkey WHERE c_region LIKE '%AMERICA%' AND s_region LIKE '%AMERICA%' AND (p_mfgr LIKE '%MFGR#1%' or p_mfgr LIKE '%MFGR#2%') GROUP BY d_year, c_nation ORDER BY d_year, c_nation;
SELECT d_year, s_nation, p_category, sum(lo_revenue - lo_supplycost) as profit FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey JOIN ssb.customer ON lo_custkey = c_custkey JOIN ssb.supplier ON lo_suppkey = s_suppkey JOIN ssb.part ON lo_partkey = p_partkey WHERE c_region LIKE '%AMERICA%' AND s_region LIKE '%AMERICA%' AND (d_year = 1997 or d_year = 1998) AND (p_mfgr LIKE '%MFGR#1%' or p_mfgr LIKE '%MFGR#2%') GROUP BY d_year, s_nation, p_category ORDER BY d_year, s_nation, p_category;
SELECT d_year, s_city, p_brand, sum(lo_revenue - lo_supplycost) as profit FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey JOIN ssb.customer ON lo_custkey = c_custkey JOIN ssb.supplier ON lo_suppkey = s_suppkey JOIN ssb.part ON lo_partkey = p_partkey WHERE c_region LIKE '%AMERICA%' AND s_nation LIKE '%UNITED STATES%' AND (d_year = 1997 or d_year = 1998) AND p_category LIKE '%MFGR#14%' GROUP BY d_year, s_city, p_brand ORDER BY d_year, s_city, p_brand;
EOF


# ==============================================================================
# FASE 1: HIVE (Batch Disco Lento)
# ==============================================================================
clean_cluster
echo "--------------------------------------------------------"
echo " [1/3] INICIANDO FASE 1: Apache Hive (Beeline)"
echo "--------------------------------------------------------"
echo "USE ssb; set hive.query.reexecution.enabled=false;" > ${LOG_DIR}/hive_script.sql
cat ${LOG_DIR}/queries_raw.sql >> ${LOG_DIR}/hive_script.sql

beeline -u ${HIVE_URI} -n hive -f ${LOG_DIR}/hive_script.sql > ${HIVE_LOG} 2>&1
echo " -> [FASE 1] Hive Completo! Log salvo em ${HIVE_LOG}"


# ==============================================================================
# FASE 2: SPARK SQL (Sem Cache / Disco Tungsten)
# ==============================================================================
clean_cluster
echo "--------------------------------------------------------"
echo " [2/3] INICIANDO FASE 2: Spark SQL (Leitura em Disco)"
echo "--------------------------------------------------------"
echo "USE ssb;" > ${LOG_DIR}/spark_script.sql
cat ${LOG_DIR}/queries_raw.sql >> ${LOG_DIR}/spark_script.sql

# Comando otimizado para não sofrer OOM na OCI
spark-sql --master yarn \
  --num-executors 2 \
  --executor-cores 1 \
  --driver-memory 512m \
  --executor-memory 1g \
  --conf spark.executor.memoryOverhead=256m \
  --conf spark.memory.fraction=0.8 \
  --conf spark.sql.shuffle.partitions=48 \
  -f ${LOG_DIR}/spark_script.sql > ${SPARK_LOG} 2>&1

echo " -> [FASE 2] Spark SQL Completo! Log salvo em ${SPARK_LOG}"


# ==============================================================================
# FASE 3: SPARK SQL (Cache Híbrido de Dimensões)
# ==============================================================================
clean_cluster
echo "--------------------------------------------------------"
echo " [3/3] INICIANDO FASE 3: Spark SQL (Cache Híbrido)"
echo "--------------------------------------------------------"

# O Pulso Fino: Somente a Lineorder (Fato Gigante) não vai pro cache
cat << 'EOF' > ${LOG_DIR}/spark_cache_script.sql
USE ssb;
CACHE TABLE dwdate;
CACHE TABLE part;
CACHE TABLE supplier;
CACHE TABLE customer;
-- A Tabela 'lineorder' fica propositalmente de fora para suportar os 6GB do nó!
EOF
cat ${LOG_DIR}/queries_raw.sql >> ${LOG_DIR}/spark_cache_script.sql

spark-sql --master yarn \
  --num-executors 2 \
  --executor-cores 1 \
  --driver-memory 512m \
  --executor-memory 1g \
  --conf spark.executor.memoryOverhead=256m \
  --conf spark.memory.fraction=0.8 \
  --conf spark.sql.shuffle.partitions=48 \
  -f ${LOG_DIR}/spark_cache_script.sql > ${SPARK_CACHE_LOG} 2>&1

echo " -> [FASE 3] Spark SQL com Cache Completo! Log salvo em ${SPARK_CACHE_LOG}"

# ==============================================================================
# FIM
# ==============================================================================
echo " "
echo "====================================================================="
echo " BATERIA FINALIZADA COM SUCESSO AS $(date) !!!"
echo " O Laboratório concluiu o Benchmark tríplice do artigo."
echo " Verifique os logs resultantes na pasta /var/oled/ssb_stage/"
echo "====================================================================="
