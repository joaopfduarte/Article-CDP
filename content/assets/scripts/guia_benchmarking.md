# Guia Prático: Replicação do Benchmark de Data Lakes (OCI Free Tier)

Este documento foi criado para registrar o método exato de replicação do experimento proposto no artigo _"Implantação e Avaliação de Data Lakes em Clouds Free Tier"_, focado na infraestrutura Oracle Cloud Infrastructure (OCI) e ecossistemas Hadoop e Apache Spark utilizando a base de testes Star Schema Benchmark (SSB).

O objetivo é atestar a hipótese de que, em ambientes de hardware extremamente restritos (como instâncias gratuitas com severas limitações de RAM e I/O de disco), o processamento _in-memory_ do Spark com Cache supera massivamente a execução Batch alocada em disco do Hive.

---

## 1. Pré-Requisitos e Infraestrutura

A alocação de hardware e software deve utilizar os gabaritos pré-configurados (Blueprints) via Terraform, com foco no perfil `data-science`, que remove sobrecargas desnecessárias (como Atlas e Ranger) e libera RAM para os processos do Spark nos Workers.

1. No arquivo `variables.tf` (ou `terraform.tfvars`), declare a seguinte variável de perfil:
   ```hcl
   cluster_profile = "data-science"
   ```
2. Após `terraform apply`, certifique-se de que o cluster gerou os 4 nós: `master`, `node1`, `node2`, e `node3`.
   - **Hardware Alocado (Worker/Master):** `VM.Standard.A1.Flex` com _1 OCPU e 6 GB de RAM_.
   - **Serviços Ativos de Foco:** HDFS, YARN, Hive Metastore, Spark3 ThriftServer/Livy2/Client.

---

## 2. Ingestão dos Dados e Transferência para o OCI

Os dados em CSV (tabela Fato e Dimensões do SSB) precisam ser transferidos da sua máquina local para a máquina virtual `master.cdp` da OCI. Faremos o stage no disco secundário, que tem mais espaço (`/var/oled`).

### No Terminal do Servidor (Master Node via SSH):

Acesse o servidor (`ssh -i id_rsa_oci opc@<IP_MASTER>`) e prepare a pasta para receber os dados com permissão de escrita para o seu usuário OCI (`opc`):

```bash
sudo mkdir -p /var/oled/ssb_stage/sample-schema-ssb
sudo chown -R opc:opc /var/oled/ssb_stage
```

### No seu Terminal Local (Sua Máquina):

Em uma **nova aba**, copie os CSVs e os scripts Bash utilitários que foram criados neste projeto para dentro do servidor:

```bash
# 1. Enviar os scripts resilientes (.sh) criados para o laboratório
scp -i ~/.ssh/id_rsa_oci /home/duarte/Documents/cdp/infra-terraform/exp-utils/*.sh opc@<IP_MASTER>:/var/oled/ssb_stage/

# 2. Enviar os arquivos CSV
scp -i ~/.ssh/id_rsa_oci /home/duarte/.../seus_arquivos_csv/*.csv opc@<IP_MASTER>:/var/oled/ssb_stage/sample-schema-ssb/
```

---

## 3. Configuração do Hadoop (Ambiente HDFS)

Com os dados de origem dentro do `master`, agora copiamos tudo para dentro do ecossistema HDFS para ficarem visíveis no modelo distribuído do Cluster. Durante este processo, vamos arrumar diretórios críticos de Staging para prevenir _Permission Denied_ da YARN.

Volte para o terminal do Servidor (`master.cdp`) e execute:

```bash
# Entrar como superusuário HDFS
sudo su hdfs

# 1. Criar e Popular Pastas
hdfs dfs -mkdir -p /tmp/ssb_stage/{lineorder,dwdate,part,supplier,customer}

hdfs dfs -put /var/oled/ssb_stage/sample-schema-ssb/LINEORDER.csv /tmp/ssb_stage/lineorder/
hdfs dfs -put /var/oled/ssb_stage/sample-schema-ssb/DWDATE.csv    /tmp/ssb_stage/dwdate/
hdfs dfs -put /var/oled/ssb_stage/sample-schema-ssb/PART.csv      /tmp/ssb_stage/part/
hdfs dfs -put /var/oled/ssb_stage/sample-schema-ssb/SUPPLIER.csv  /tmp/ssb_stage/supplier/
hdfs dfs -put /var/oled/ssb_stage/sample-schema-ssb/CUSTOMER.csv  /tmp/ssb_stage/customer/

# Permissão global para a base de leitura das tabelas SSB
hdfs dfs -chmod -R 777 /tmp/ssb_stage

# 2. Criar Pastas Domiciliares (Staging Dir do Hive e do Spark)
hdfs dfs -mkdir -p /user/opc
hdfs dfs -chown opc:opc /user/opc
hdfs dfs -mkdir -p /user/hive
hdfs dfs -chown hive:hadoop /user/hive

exit
```

---

## 4. Registro dos Metadados (Hive/Beeline)

A estrutura relacional será mapeada usando os utilitários OpenCSVSerde. Esses metadados serão compartilhados pelo Hive Metastore com o Spark para garantir homogeneidade na leitura.

Conecte-se na CLI do Beeline (como usuário `hive` para evitar negações no Metastore):

```bash
sudo su hive
beeline -u jdbc:hive2://node1.cdp:10000 -n hive
```

Execute o DDL (copie e cole bloco a bloco):

```sql
CREATE DATABASE IF NOT EXISTS ssb;
USE ssb;

-- Tabela Fato
CREATE EXTERNAL TABLE IF NOT EXISTS lineorder (
    LO_ORDERKEY bigint, LO_LINENUMBER int, LO_CUSTKEY int, LO_PARTKEY int,
    LO_SUPPKEY int, LO_ORDERDATE string, LO_ORDERPRIORITY string, LO_SHIPPRIORITY string,
    LO_QUANTITY int, LO_EXTENDEDPRICE int, LO_ORDTOTALPRICE int, LO_DISCOUNT int,
    LO_REVENUE int, LO_SUPPLYCOST int, LO_TAX int, LO_COMMITDATE int, LO_SHIPMODE string
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES ("separatorChar" = ",", "quoteChar" = "\"", "escapeChar" = "\\")
STORED AS TEXTFILE LOCATION '/tmp/ssb_stage/lineorder' tblproperties ("skip.header.line.count"="1");

-- Dimensões
CREATE EXTERNAL TABLE IF NOT EXISTS dwdate (
    D_DATEKEY string, D_DATE string, D_DAYOFWEEK string, D_MONTH string,
    D_YEAR int, D_YEARMONTHNUM int, D_YEARMONTH string, D_DAYNUMINWEEK int,
    D_DAYNUMINMONTH int, D_DAYNUMINYEAR int, D_MONTHNUMINYEAR int,
    D_WEEKNUMINYEAR int, D_SELLINGSEASON string, D_LASTDAYINWWFL int, D_LASTDAYINFL int, D_HOLIDAYFL int, D_WEEKDAYFL int
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde' WITH SERDEPROPERTIES ("separatorChar" = ",", "quoteChar" = "\"", "escapeChar" = "\\")
STORED AS TEXTFILE LOCATION '/tmp/ssb_stage/dwdate' tblproperties ("skip.header.line.count"="1");

CREATE EXTERNAL TABLE IF NOT EXISTS part (
    P_PARTKEY int, P_NAME string, P_MFGR string, P_CATEGORY string, P_BRAND string, P_COLOR string, P_TYPE string, P_SIZE int, P_CONTAINER string
) ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde' WITH SERDEPROPERTIES ("separatorChar" = ",", "quoteChar" = "\"", "escapeChar" = "\\")
STORED AS TEXTFILE LOCATION '/tmp/ssb_stage/part' tblproperties ("skip.header.line.count"="1");

CREATE EXTERNAL TABLE IF NOT EXISTS supplier (
    S_SUPPKEY int, S_NAME string, S_ADDRESS string, S_CITY string, S_NATION string, S_REGION string, S_PHONE string
) ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde' WITH SERDEPROPERTIES ("separatorChar" = ",", "quoteChar" = "\"", "escapeChar" = "\\")
STORED AS TEXTFILE LOCATION '/tmp/ssb_stage/supplier' tblproperties ("skip.header.line.count"="1");

CREATE EXTERNAL TABLE IF NOT EXISTS customer (
    C_CUSTKEY int, C_NAME string, C_ADDRESS string, C_CITY string, C_NATION string, C_REGION string, C_PHONE string, C_MKTSEGMENT string
) ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde' WITH SERDEPROPERTIES ("separatorChar" = ",", "quoteChar" = "\"", "escapeChar" = "\\")
STORED AS TEXTFILE LOCATION '/tmp/ssb_stage/customer' tblproperties ("skip.header.line.count"="1");

!quit
```

_(Digite `exit` novamente para voltar a ser o usuário `opc`)._

---

## 5. Bateria de Testes (Metodologia Adaptada para Free Tier)

Devido às limitações de timeout e alocação de RAM (OOM - _Out of Memory_) das VMs do modo arm64 Free Tier, a recomendação é **executar os benchmarks via shell script resiliente** com `nohup`.

Isso tem três benefícios:

1. Imunidade à quebra de SSH por inatividade (queries longas do Hive).
2. Parametrização dos limites de memória do Spark (`--driver-memory`, `--num-executors`) de forma engessada, fugindo dos Defaults do YARN que derrubam o NodeManager.
3. Centralização da sessão. Abrir 1 sessão invés de 13.

### 5.1 Teste Nativo em Disco (Apache Hive - Fase 1)

O script automatizado gravará o tempo e o output contínuo de forma sequencial.

```bash
# Configure o arquivo de saída e inicie em Foreground ou em Background com nohup
sudo touch /var/oled/ssb_stage/hive_benchmark.log
sudo chown hive:hadoop /var/oled/ssb_stage/hive_benchmark.log
sudo chmod 777 /var/oled/ssb_stage/hive_benchmark.log

# Rodando o bloco
sudo -u hive nohup bash /var/oled/ssb_stage/run_hive_benchmark.sh > /dev/null 2>&1 &
```

_Acompanhe o painel executando:_ `tail -f /var/oled/ssb_stage/hive_benchmark.log`

### 5.2 Teste Frio em Disco (Apache Spark - Fase 2)

O benchmark utiliza o script isolado para uma **Única Sessão** (para suportar todo o workload sem morrer via limitação da YARN):

```bash
sudo touch /var/oled/ssb_stage/spark_benchmark.log
sudo chown hive:hadoop /var/oled/ssb_stage/spark_benchmark.log
sudo chmod 777 /var/oled/ssb_stage/spark_benchmark.log

# Rodando o bloco com limites drásticos ativados (512MB)
sudo -u hive nohup bash /var/oled/ssb_stage/run_spark_benchmark.sh > /dev/null 2>&1 &
```

_Acompanhe o painel executando:_ `tail -f /var/oled/ssb_stage/spark_benchmark.log`

### 5.3 Teste Quente In-Memory (Apache Spark + Cache - Fase 3)

A fase que atesta a hipótese do estudo pode ser emulada na sua melhor forma diretamente de forma manual no Terminal CLI. Usaremos o controle restrito de cluster nos executores do YARN.

```bash
sudo su hive

# 1. Abrir a sessão do Spark-SQL domada para CPU Free Tier
spark-sql --master yarn \
  --driver-memory 512m \
  --executor-memory 512m \
  --num-executors 1 \
  --executor-cores 1 \
  --conf spark.executor.memoryOverhead=256m \
  --conf spark.sql.shuffle.partitions=4

# 2. Trazer a Data para a RAM (Submeta um de cada vez)
USE ssb;
CACHE TABLE lineorder;
CACHE TABLE dwdate;
CACHE TABLE part;
CACHE TABLE supplier;
CACHE TABLE customer;
```

**ATENÇÃO**: Neste cenário as tabelas estão retidas nativamente na RAM do executor do Spark e você não deve fechar ou encerrar (Ctrl+C). Envie (Copy-Paste) as 13 queries para o console do `spark-sql` neste momento e comece a observar milissegundos nas respostas ("Time taken").

---

## 6. Consultas Analíticas (Catálogo)

Cansadas as correções semânticas de parsing e JOIN referenciado que existiam erradas na documentação original de SSB.

_(Copie em Bloco ou Individualmente se for usar no `spark-sql` interativo)_

```sql
-- Q1.1
SELECT sum(lo_extendedprice*lo_discount) as revenue FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey WHERE d_year = 1993 AND lo_discount between 1 and 3 AND lo_quantity < 25;

-- Q1.2
SELECT sum(lo_extendedprice*lo_discount) as revenue FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey WHERE d_yearmonthnum = 199401 AND lo_discount between 4 and 6 AND lo_quantity between 26 and 35;

-- Q1.3
SELECT sum(lo_extendedprice*lo_discount) as revenue FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey WHERE d_weeknuminyear = 6 AND d_year = 1994 AND lo_discount between 5 and 7 AND lo_quantity between 26 and 35;

-- Q2.1
SELECT sum(lo_revenue), d_year, p_brand FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey JOIN ssb.part ON lo_partkey = p_partkey JOIN ssb.supplier ON lo_suppkey = s_suppkey WHERE p_category LIKE '%MFGR#12%' AND s_region LIKE '%AMERICA%' GROUP BY d_year, p_brand ORDER BY d_year, p_brand;

-- Q2.2
SELECT sum(lo_revenue), d_year, p_brand FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey JOIN ssb.part ON lo_partkey = p_partkey JOIN ssb.supplier ON lo_suppkey = s_suppkey WHERE p_brand between 'MFGR#2221' and 'MFGR#2228' AND s_region LIKE '%ASIA%' GROUP BY d_year, p_brand ORDER BY d_year, p_brand;

-- Q2.3
SELECT sum(lo_revenue), d_year, p_brand FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey JOIN ssb.part ON lo_partkey = p_partkey JOIN ssb.supplier ON lo_suppkey = s_suppkey WHERE p_brand LIKE '%MFGR#2221%' AND s_region LIKE '%EUROPE%' GROUP BY d_year, p_brand ORDER BY d_year, p_brand;

-- Q3.1
SELECT c_nation, s_nation, d_year, sum(lo_revenue) as revenue FROM ssb.lineorder JOIN ssb.customer ON lo_custkey = c_custkey JOIN ssb.supplier ON lo_suppkey = s_suppkey JOIN ssb.dwdate ON lo_orderdate = d_datekey WHERE c_region LIKE '%ASIA%' AND s_region LIKE '%ASIA%' AND d_year >= 1992 AND d_year <= 1997 GROUP BY c_nation, s_nation, d_year ORDER BY d_year asc, revenue desc;

-- Q3.2
SELECT c_city, s_city, d_year, sum(lo_revenue) as revenue FROM ssb.lineorder JOIN ssb.customer ON lo_custkey = c_custkey JOIN ssb.supplier ON lo_suppkey = s_suppkey JOIN ssb.dwdate ON lo_orderdate = d_datekey WHERE c_nation LIKE '%UNITED STATES%' AND s_nation LIKE '%UNITED STATES%' AND d_year >= 1992 AND d_year <= 1997 GROUP BY c_city, s_city, d_year ORDER BY d_year asc, revenue desc;

-- Q3.3
SELECT c_city, s_city, d_year, sum(lo_revenue) as revenue FROM ssb.lineorder JOIN ssb.customer ON lo_custkey = c_custkey JOIN ssb.supplier ON lo_suppkey = s_suppkey JOIN ssb.dwdate ON lo_orderdate = d_datekey WHERE (c_city LIKE '%UNITED KI1%' or c_city LIKE '%UNITED KI5%') AND (s_city LIKE '%UNITED KI1%' or s_city LIKE '%UNITED KI5%') AND d_year >= 1992 AND d_year <= 1997 GROUP BY c_city, s_city, d_year ORDER BY d_year asc, revenue desc;

-- Q3.4
SELECT c_city, s_city, d_year, sum(lo_revenue) as revenue FROM ssb.lineorder JOIN ssb.customer ON lo_custkey = c_custkey JOIN ssb.supplier ON lo_suppkey = s_suppkey JOIN ssb.dwdate ON lo_orderdate = d_datekey WHERE (c_city LIKE '%UNITED KI1%' or c_city LIKE '%UNITED KI5%') AND (s_city LIKE '%UNITED KI1%' or s_city LIKE '%UNITED KI5%') AND d_yearmonth LIKE '%Dec1997%' GROUP BY c_city, s_city, d_year ORDER BY d_year asc, revenue desc;

-- Q4.1
SELECT d_year, c_nation, sum(lo_revenue - lo_supplycost) as profit FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey JOIN ssb.customer ON lo_custkey = c_custkey JOIN ssb.supplier ON lo_suppkey = s_suppkey JOIN ssb.part ON lo_partkey = p_partkey WHERE c_region LIKE '%AMERICA%' AND s_region LIKE '%AMERICA%' AND (p_mfgr LIKE '%MFGR#1%' or p_mfgr LIKE '%MFGR#2%') GROUP BY d_year, c_nation ORDER BY d_year, c_nation;

-- Q4.2
SELECT d_year, s_nation, p_category, sum(lo_revenue - lo_supplycost) as profit FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey JOIN ssb.customer ON lo_custkey = c_custkey JOIN ssb.supplier ON lo_suppkey = s_suppkey JOIN ssb.part ON lo_partkey = p_partkey WHERE c_region LIKE '%AMERICA%' AND s_region LIKE '%AMERICA%' AND (d_year = 1997 or d_year = 1998) AND (p_mfgr LIKE '%MFGR#1%' or p_mfgr LIKE '%MFGR#2%') GROUP BY d_year, s_nation, p_category ORDER BY d_year, s_nation, p_category;

-- Q4.3
SELECT d_year, s_city, p_brand, sum(lo_revenue - lo_supplycost) as profit FROM ssb.lineorder JOIN ssb.dwdate ON lo_orderdate = d_datekey JOIN ssb.customer ON lo_custkey = c_custkey JOIN ssb.supplier ON lo_suppkey = s_suppkey JOIN ssb.part ON lo_partkey = p_partkey WHERE c_region LIKE '%AMERICA%' AND s_nation LIKE '%UNITED STATES%' AND (d_year = 1997 or d_year = 1998) AND p_category LIKE '%MFGR#14%' GROUP BY d_year, s_city, p_brand ORDER BY d_year, s_city, p_brand;
```

---

## 7. Troubleshooting e Limpeza

- **Stray YARN Apps e Falhas Fatais por Out of Memory:**
  Se em algum instante anterior os benchmarks falharem (ou você abortar com CTRL+C na execução interativa do Spark sem matar corretamente o Master) o cluster ficará drenado com `ACCEPTED Apps`. Você pode matar todas de uma só vez:

  ```bash
  sudo su hive
  for app in $(yarn application -list -appStates ACCEPTED,RUNNING | awk '{print $1}' | grep application_); do yarn application -kill $app; done
  ```

- **Limpando arquivos mortos nas pastas de Staging:**
  É comum em instâncias lenticulares que processos zumbis mantenham arquivos `.sparkStaging` em peso impedindo futuras execuções. Para matar e higienizar:
  ```bash
  sudo su hdfs
  hdfs dfs -rm -r -f /user/hive/.sparkStaging/*
  ```
