#!/bin/bash
# =============================================================================
# run_hive_benchmark.sh
# Executa as 14 consultas SSB no Hive/Beeline em modo batch, gravando
# resultados e tempos em arquivo de log. Roda com nohup/screen para
# sobreviver a quedas de conexão SSH.
#
# Uso:
#   sudo su hive
#   nohup bash /var/oled/ssb_stage/run_hive_benchmark.sh > /dev/null 2>&1 &
#
# O log completo será gravado em: /var/oled/ssb_stage/hive_benchmark.log
# =============================================================================

BEELINE="beeline -u jdbc:hive2://node1.cdp:10000 -n hive --silent=false"
LOGFILE="/var/oled/ssb_stage/hive_benchmark.log"

# Limpa log anterior
> "$LOGFILE"

echo "=============================================" | tee -a "$LOGFILE"
echo " Hive SSB Benchmark - Início: $(date)"        | tee -a "$LOGFILE"
echo "=============================================" | tee -a "$LOGFILE"

run_query() {
    local QUERY_NUM=$1
    local SQL=$2

    echo "" | tee -a "$LOGFILE"
    echo "---------------------------------------------" | tee -a "$LOGFILE"
    echo " Query ${QUERY_NUM} - Início: $(date)" | tee -a "$LOGFILE"
    echo "---------------------------------------------" | tee -a "$LOGFILE"
    echo "SQL: ${SQL}" >> "$LOGFILE"

    START_TS=$(date +%s%N)

    $BEELINE -e "USE ssb; ${SQL}" 2>&1 | tee -a "$LOGFILE"

    END_TS=$(date +%s%N)
    ELAPSED_MS=$(( (END_TS - START_TS) / 1000000 ))
    ELAPSED_S=$(awk "BEGIN {printf \"%.3f\", ${ELAPSED_MS}/1000}")

    echo "" | tee -a "$LOGFILE"
    echo ">>> Query ${QUERY_NUM} - Tempo: ${ELAPSED_S}s  (Fim: $(date))" | tee -a "$LOGFILE"
}

# ---- Query 05 ----
run_query "05" "
SELECT sum(lo_revenue), d_year, p_brand
FROM ssb.lineorder
JOIN ssb.dwdate ON lo_orderdate = d_datekey
JOIN ssb.part ON lo_partkey = p_partkey
JOIN ssb.supplier ON lo_suppkey = s_suppkey
WHERE p_category LIKE '%MFGR#12%'
  AND s_region LIKE '%AMERICA%'
GROUP BY d_year, p_brand
ORDER BY d_year, p_brand;
"

# ---- Query 06 ----
run_query "06" "
SELECT sum(lo_revenue), d_year, p_brand
FROM ssb.lineorder
JOIN ssb.dwdate ON lo_orderdate = d_datekey
JOIN ssb.part ON lo_partkey = p_partkey
JOIN ssb.supplier ON lo_suppkey = s_suppkey
WHERE p_brand between 'MFGR#2221' and 'MFGR#2228'
  AND s_region LIKE '%ASIA%'
GROUP BY d_year, p_brand
ORDER BY d_year, p_brand;
"

# ---- Query 07 ----
run_query "07" "
SELECT sum(lo_revenue), d_year, p_brand
FROM ssb.lineorder
JOIN ssb.dwdate ON lo_orderdate = d_datekey
JOIN ssb.part ON lo_partkey = p_partkey
JOIN ssb.supplier ON lo_suppkey = s_suppkey
WHERE p_brand LIKE '%MFGR#2221%'
  AND s_region LIKE '%EUROPE%'
GROUP BY d_year, p_brand
ORDER BY d_year, p_brand;
"

# ---- Query 08 ----
run_query "08" "
SELECT c_nation, s_nation, d_year, sum(lo_revenue) as revenue
FROM ssb.lineorder
JOIN ssb.customer ON lo_custkey = c_custkey
JOIN ssb.supplier ON lo_suppkey = s_suppkey
JOIN ssb.dwdate ON lo_orderdate = d_datekey
WHERE c_region LIKE '%ASIA%' AND s_region LIKE '%ASIA%'
  AND d_year >= 1992 AND d_year <= 1997
GROUP BY c_nation, s_nation, d_year
ORDER BY d_year asc, revenue desc;
"

# ---- Query 09 ----
run_query "09" "
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
"

# ---- Query 10 ----
run_query "10" "
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
"

# ---- Query 11 ----
run_query "11" "
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
"

# ---- Query 12 ----
run_query "12" "
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
"

# ---- Query 13 ----
run_query "13" "
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
"

# ---- Query 14 ----
run_query "14" "
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
"

echo "" | tee -a "$LOGFILE"
echo "=============================================" | tee -a "$LOGFILE"
echo " Hive SSB Benchmark - Fim: $(date)"           | tee -a "$LOGFILE"
echo "=============================================" | tee -a "$LOGFILE"
echo " Log completo em: ${LOGFILE}"                  | tee -a "$LOGFILE"
