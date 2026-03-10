# Artigo Científico Prático: Replicabilidade de Benchmarking Analítico em Data Lakes na OCI Free Tier

**Resumo:** Este documento apresenta a metodologia e o roteiro de replicação para a avaliação de desempenho de um Data Lake implantado via *Infrastructure as Code* (Terraform e Ansible) na Oracle Cloud Infrastructure (OCI). Baseado na arquitetura do Star Schema Benchmark (SSB), dividimos as atividades experimentais em duas frentes: (I) Comparativo de I/O de disco (Apache Hive) versus processamento em memória (Apache Spark) para uma tabela desnormalizada; (II) Estresse analítico com Modelagem Dimensional Completa (Múltiplos Joins) sob restrições de Hardware utilizando Apache Spark.

---

## 1. Introdução e Metodologia

O objetivo desta prática é validar a capacidade de processamento analítico de um cluster Hadoop distribuído (1 Master, 3 Workers) operando em instâncias ARM Ampere A1 (Free Tier). O experimento foi modelado para fins acadêmicos e de pesquisa, permitindo que os discentes ou pesquisadores repitam os testes de estresse em seus próprios laboratórios de nuvem.

### 1.1 Preparação do Acesso
O usuário deve possuir acesso aos nós de processamento via SSH a partir da máquina local.

```bash
# Acesso ao Master Node
ssh -i /caminho/para/id_rsa_oci opc@<IP_PUBLICO_MASTER>
```

---

## 2. Experimento I: Avaliação Simples (Disco vs. Memória Distribuída)

Este primeiro experimento simula a leitura e agregação de uma grande massa de dados (1 milhão de linhas), submetendo a carga a dois paradigmas de computação: MapReduce (tradicional, orientado a armazenamento) e Spark (processamento em RAM).

### 2.1 Geração e Ingestão do Dataset Base
Criação de um arquivo CSV simulando uma *Fact Table* desnormalizada e submissão ao _Hadoop Distributed File System_ (HDFS).

```bash
# 1. Geração do Dataset via Shell (Terminal opc)
mkdir -p ~/ssb_test/data && cd ~/ssb_test/data
echo "Gerando dados..."
awk 'BEGIN {OFS=","; for(i=1;i<=1000000;i++) print i, int(rand()*10)+1992, int(rand()*5)+1, int(rand()*7)+1, int(rand()*1000)+1, int(rand()*10)+1}' > lineorder.csv

# 2. Transferência para diretório temporário
cp lineorder.csv /tmp/ && chmod 777 /tmp/lineorder.csv

# 3. Submissão ao HDFS (Terminal HDFS)
sudo su - hdfs
hdfs dfs -mkdir -p /user/admin/ssb/lineorder
hdfs dfs -put /tmp/lineorder.csv /user/admin/ssb/lineorder/
hdfs dfs -chmod -R 777 /user/admin/ssb
exit
```

### 2.2 Execução via Motores Padrão de Disco (Apache Hive / MapReduce)
Ao invés do obsoleto comando `hive`, a recomendação de arquitetura é se conectar diretamente ao *HiveServer2* utilizando JDBC via CLI do Beeline.

```bash
# 1. Conexão ao HiveServer2 no Worker 1 (Terminal hive)
sudo su - hive
beeline -u jdbc:hive2://node1.cdp:10000 -n hive
```

> **[ATENÇÃO] Identificação de Falha no Acesso Hive (Connection Refused):**
> * **O que ocorre:** O comando obsoleto `hive` ou o uso do `beeline` mirando o `master.cdp` falhará com erro de _Connect Exception_ ou _Permission Denied_.
> * **Motivo:** O provisionamento Hadoop (ODP/Ambari) instala o componente **HiveServer2** no nó de trabalho subjacente (neste design de infraestrutura o *Worker Node 1*). O usuário de conexão nativo do Sistema Operacional também não possui os perfis de segurança Ranger; o dono dos _Metastores_ é o usuário `hive`.
> * **Como Resolver:** Assuma estritamente a diretiva `sudo su - hive`. Após isso, acione a string JDBC roteando obrigatoriamente para a porta 10000 do nó instalado (`node1.cdp`).

```sql
/* 2. Criação do Warehouse e Mapeamento Externo (Console Beeline) */
CREATE DATABASE IF NOT EXISTS ssb_test;
USE ssb_test;

CREATE EXTERNAL TABLE IF NOT EXISTS lineorder (
    orderkey INT, order_year INT, custkey INT, suppkey INT, 
    extendedprice DOUBLE, discount DOUBLE
) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LOCATION '/user/admin/ssb/lineorder';

/* 3. Ajuste de Engine Executora (Troubleshooting) */
set hive.execution.engine=mr;
```

> **[ATENÇÃO] Identificação de Falha de NullPointer no Join (Internal Error HIVE):**
> * **O que ocorre:** Se o executor não for mitigado, ao enviar a Query analítica descrita abaixo o Beeline imprimirá o erro _"FAILED: Hive Internal Error: java.lang.NullPointerException nos FailureHooks"_.
> * **Motivo:**  As distribuições ODP tentam otimizar o Hive via **Tez Engine**. Em instâncias _Free Tier_ (RAM escassa), os laços de pré-reserva desse plugin não conseguem contêineres suficientes e quebram no YARN sem relatar explicitamente a exaustão de memória na interface usuária JDBC.
> * **Como Resolver:** Reverter à arquitetura resiliente original do Hadoop rodando o comando acima (`set hive.execution.engine=mr;`). O **MapReduce** opera lendo e escrevendo blocos sequenciais em disco, acomodando limites severos de memória.

```sql
/* 4. Execução da Query Analítica */
SELECT order_year, SUM(extendedprice * discount) AS revenue
FROM lineorder WHERE discount BETWEEN 4 AND 6 AND order_year >= 1993
GROUP BY order_year ORDER BY order_year;
```
> **Resultado do Hive:** O MapReduce serializou a varredura física pelo disco do HDFS, retornando o agrupamento logístico em um tempo médio de **191.95 segundos**.

### 2.3 Execução via Motor In-Memory (Apache Spark)
Como contraprova da metodologia, a mesma carga foi processada injetando a tabela no *Cache* distribuído sobre o framework YARN.

```bash
# 1. Alocação do Motor Spark
# O comando abaixo inicializa o Spark interativo forçando a adesão restrita dos limites de hardware (Ampere).
sudo su - hive
spark3-sql --master yarn --num-executors 3 --executor-memory 2G --executor-cores 1
```

> **[ATENÇÃO] Identificação de Falha de Permissão de Acesso Hive (AccessControlException):**
> * **O que ocorre:** Executar o `spark3-sql` sob outros usuários do Sistema Operacional (ex: `spark` ou `opc`) estourará o erro _"Permission denied: user=spark_ _inode='/warehouse/tablespace/managed/hive'"_.
> * **Motivo:** Como parte da integração do ecossistema, o Apache Spark SQL compartilha a leitura do _Hive Metastore_. O subsistema de armazenamento HDFS é trancado administrativamente. Se rodado com a identidade errada, o job será rejeitado pelas ACLs do *Namenode*.
> * **Como Resolver:** Abandone shells comuns. Conforme o script demonstrado, sempre faça a elevação prévia para `sudo su - hive` garantindo a titularidade das pastas de Warehouse.

```sql
/* 2. Aquecimento da Tabela e Execução (Console Spark SQL) */
USE ssb_test;
CACHE TABLE lineorder;

SELECT order_year, SUM(extendedprice * discount) AS revenue
FROM lineorder WHERE discount BETWEEN 4 AND 6 AND order_year >= 1993
GROUP BY order_year ORDER BY order_year;
```
> **Resultado do Spark (Cache):** O cruzamento ocorreu majoritariamente na RAM dos nós operários (Ampere ARM), desabando o tempo de processamento analítico para **10.22 segundos**.

---

## 3. Experimento II: Avaliação do Star Schema Benchmark (Múltiplos Joins)

Para classificar o ambiente dentro de rigores analíticos complexos (padrão TPC-H derivado), é imperativo aferir a resiliência do _scheduler_ do Hadoop lidando com o embaralhamento de rede (*Network Shuffle*) exigido por consultas entre uma *Fact Table* escalonável e *Dimension Tables* satélites periféricas interligadas por chaves estrangeiras lógicas. 

### 3.1 Prototipagem da Malha Dimensional (Python)
Para este experimento, formulamos dados dimensionais condizentes com o ambiente simulado (`dwdate`, `customer`, `supplier`, `part` e a tabela fato iterativa `lineorder_fato`).

```bash
# 1. Geração Automática das Matrizes Dimensionais e Fato
cat << 'EOF' > /tmp/gen_ssb.py
import random
import os
from datetime import datetime, timedelta

out_dir = "/tmp/ssb_full/"
os.makedirs(out_dir, exist_ok=True)

with open(out_dir + "dwdate.csv", "w") as f:
    start = datetime(1992, 1, 1)
    for i in range(2556):
        d = start + timedelta(days=i)
        f.write(f"{int(d.strftime('%Y%m%d'))},{d.year},{d.month},{d.strftime('%Y-%m-%d')}\n")

with open(out_dir + "customer.csv", "w") as f:
    regions = ['AMERICA', 'ASIA', 'EUROPE', 'AFRICA']
    for i in range(1, 10001): f.write(f"{i},Customer#{i},City{i},{random.choice(regions)}\n")

with open(out_dir + "supplier.csv", "w") as f:
    regions = ['AMERICA', 'ASIA', 'EUROPE', 'AFRICA']
    for i in range(1, 1001): f.write(f"{i},Supplier#{i},City{i},{random.choice(regions)}\n")

with open(out_dir + "part.csv", "w") as f:
    categories = ['MFGR#12', 'MFGR#13', 'MFGR#14', 'MFGR#22']
    brands = ['MFGR#2221', 'MFGR#2228', 'BrandX']
    for i in range(1, 50001): f.write(f"{i},Part#{i},{random.choice(categories)},{random.choice(brands)}\n")

with open(out_dir + "lineorder.csv", "w") as f:
    date_keys = [int((start + timedelta(days=i)).strftime("%Y%m%d")) for i in range(2556)]
    for i in range(1, 1000001):
        disc, price = random.randint(1, 10), random.uniform(100.0, 1000.0)
        f.write(f"{i},{random.randint(1, 10000)},{random.randint(1, 50000)},{random.randint(1, 1000)},{random.choice(date_keys)},{price:.2f},{disc},{price*disc:.2f}\n")
EOF

python3 /tmp/gen_ssb.py
chmod -R 777 /tmp/ssb_full
```

### 3.2 Ingestão das Dimensões no Data Lake
```bash
# Submissão ao HDFS como usuário hdfs
sudo su - hdfs
for d in dwdate customer supplier part lineorder; do
  hdfs dfs -mkdir -p /user/admin/ssb_star/$d
  hdfs dfs -put /tmp/ssb_full/$d.csv /user/admin/ssb_star/$d/
done
hdfs dfs -chmod -R 777 /user/admin/ssb_star
exit
```

### 3.3 Tratativa de Limitações de Memória do Cluster (Free Tier)
Em virtude das rígidas demarcações dos OCI VMs Free-Tier (limitando em 2GB Ram/Node), solicitar o isolamento do *Spark Context* com prioridade in-memory (`CACHE TABLE` simultâneo para as 5 matrizes) induziu _Deadlocks_ transacionais por *OOM (Out Of Memory)* do container JVM.

Para assegurar a completude da tarefa por intermédio da arquitetura *Catalyst Optimizer* do Spark, o modelo deve se apoiar no fracionamento dos *Resilient Distributed Datasets* via disco. O recurso foi submetido restringindo a demanda passiva global de memória YARN para contornar filas em modo *PENDING*, da seguinte forma:

```bash
sudo su - hive
spark3-sql --master yarn --num-executors 1 --executor-memory 1G
```

> **[ATENÇÃO] Identificação de Falha no Shell do Spark (Console Congelado/Hang + OOM):**
> * **O que ocorre:** O Terminal não avança após a mensagem *“falling back to uploading libraries”* ou imprime repetidas vezes *“Initial job has not accepted any resources”* antes de ter as Jobs canceladas à força pela JVM.
> * **Motivo:** Ao testar um modelo distribuído forçando um excesso de processamento e cache (`CACHE TABLE` para dezenas de milhões de atributos) num ambiente _AArch64_ grátis, o alocador do YARN se depara com zero blocos de RAM satisfatórios. Como resultado, o *Job Scheduler* emite um estado _PENDING_ permanente congelando o prompt do experimentador num laço infinito (*Deadlock Resource*) até estourar a Heap nativa.
> * **Como Resolver:**  Para testes com alta profundidade em _Free Tiers_, a CLI do spark (`spark3-sql`) deve ser invocada cortando sua taxa de *Memory Executor* (utilizando apenas `1G` em oposição aos `2G` padrão). Em sequência, o cientista de dados **deve abster-se** de tentar subir partições gigantescas na memória (*Cache*), submetendo a instrução diretamente, para que o Catalyst acione instâncias transientes particionando do disco gradativamente pelo YARN.

### 3.4 Execução da Query SSB Complexa (Sem Cache)
```sql
/* 1. Mapeamento Lógico Pelo Console Spark SQL */
USE ssb_test;

CREATE EXTERNAL TABLE IF NOT EXISTS dwdate (d_datekey INT, d_year INT, d_month INT, d_date STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LOCATION '/user/admin/ssb_star/dwdate';
CREATE EXTERNAL TABLE IF NOT EXISTS customer (c_custkey INT, c_name STRING, c_city STRING, c_region STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LOCATION '/user/admin/ssb_star/customer';
CREATE EXTERNAL TABLE IF NOT EXISTS supplier (s_suppkey INT, s_name STRING, s_city STRING, s_region STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LOCATION '/user/admin/ssb_star/supplier';
CREATE EXTERNAL TABLE IF NOT EXISTS part (p_partkey INT, p_name STRING, p_category STRING, p_brand STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LOCATION '/user/admin/ssb_star/part';
CREATE EXTERNAL TABLE IF NOT EXISTS lineorder_fato (lo_orderkey INT, lo_custkey INT, lo_partkey INT, lo_suppkey INT, lo_orderdate INT, lo_extendedprice DOUBLE, lo_discount DOUBLE, lo_revenue DOUBLE) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LOCATION '/user/admin/ssb_star/lineorder';

/* 2. Execução da Amostra Complexa sem Aquecimento via RAM */
SELECT sum(lo_revenue) AS lucro, d_year, p_brand
FROM lineorder_fato
JOIN dwdate ON lo_orderdate = d_datekey
JOIN part ON lo_partkey = p_partkey
JOIN supplier ON lo_suppkey = s_suppkey
WHERE p_category = 'MFGR#12' 
  AND s_region = 'AMERICA'
GROUP BY d_year, p_brand
ORDER BY d_year, p_brand;
```

> **Resultado do Experimento Complexo:** Mesmo extraindo os quadros relacionais cruamente sobre I/O do rígido sem valer-se da tolerância do Cache in-Memory (devido a contenções de hardware da infraestrutura *free tier* em tela), o modelo analítico performático do Spark conseguiu agrupar o relacionamento e reduzir os Hash Joins em meros **31.42 segundos**, retornando as instâncias aglutinadas em tela com notável integridade.

---

## 4. Conclusões

Os experimentos solidificam a funcionalidade plena dos agrupamentos *HDFS/YARN* provisionados *as-a-code*. Verificou-se não só o amadurecimento das matrizes e conexões subjacentes (Networking interno, Permissões Hive Metastore e Engine JDBC em balanceamento nativo), como também comprovou-se matematicamente (31.4s *no-cache* multiview contra 191s *disk base* single-view e um ápice de 10.2s *RAM Cached* single-view) as latentes propriedades modernistas do formato Catalyst/DAG utilizado por *Apache Spark*, permitindo inferir um Data Lake funcional e pronto para exploração científica e produtiva dentro de restritos recursos públicos providos via free tiers nas nuvens corporativas contemporâneas.
