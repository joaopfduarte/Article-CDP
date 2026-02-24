# 04 - Pós-instalação: Instalação e Configuração dos Serviços (um a um)

Este documento orienta a instalação dos serviços restantes do cluster via Ambari, após a base já provisionada no documento 03 (ZooKeeper, HDFS, YARN + MapReduce2 e Tez). O foco é executar os procedimentos pela interface do Ambari; use linha de comando apenas quando explicitamente indicado.

Importante sobre senhas:
- Todas as senhas definidas aqui devem ser armazenadas em local seguro (por exemplo, um cofre de senhas corporativo) e compartilhadas apenas com quem precisa.
- As senhas devem obedecer às políticas de complexidade do Ranger. Recomendação: mínimo 10–12 caracteres, com letras maiúsculas/minúsculas, dígitos e caracteres especiais; evitar dados pessoais; não reutilizar senhas.

Pré-requisitos validados:
- Ambari acessível e agentes ativos (docs/02 - ODP/02-instalacao-ambari.md).
- Setup inicial concluído conforme docs/02 - ODP/03-configuracao-servicos.md.
- Ordem recomendada de instalação (docs/02 - ODP/03.1-configuracao-servicos.md):
  1) Ambari Infra Solr → 2) Ranger → 3) Hive (com Tez) → 4) Kafka → 5) HBase (+ Phoenix Query Server) → 6) NiFi → 7) Spark3 (JobHistory, Livy2, ThriftServer).

Convenções usadas:
- Hostnames de exemplo: master.cdp, node1.cdp, node2.cdp, node3.cdp (ajuste para seu FQDN, ex.: master.cdp.dev.br).
- Stack/versões conforme ODP-VDF 1.2.2.0-128.
- SELinux em modo permissivo durante a instalação (veja 00-prérequisitos.md). Abra as portas necessárias no firewalld conforme indicado por cada serviço.

Vale ainda ressaltar, que para cada componente instalado, consulte a imagem abaixo sobre quais 
instalações devem ir para cada host.

![`padroes-de-instalacao`](../../assets/images/change5.png)

------------------------------------------------------------
## Correções iniciais (ajuste do YARN ATS no HDFS)
------------------------------------------------------------
Execute apenas uma vez, no master, antes de iniciar o YARN Timeline/ATS (necessário para o bundle hbase do ATS):

```bash
# 1) garantir diretório de destino no HDFS
sudo -u hdfs /usr/odp/1.2.2.0-128/hadoop/bin/hdfs dfs -mkdir -p /odp/apps/1.2.2.0-128/hbase

# 2) enviar o pacote forçando overwrite se necessário
sudo -u hdfs /usr/odp/1.2.2.0-128/hadoop/bin/hdfs dfs -put -f \
  /var/lib/ambari-agent/tmp/yarn-ats/1.2.2.0-128/hbase.tar.gz \
  /odp/apps/1.2.2.0-128/hbase/

# 3) ajustar permissões e ownership como esperado pelo script (444 e owner hdfs)
sudo -u hdfs /usr/odp/1.2.2.0-128/hadoop/bin/hdfs dfs -chmod 444 /odp/apps/1.2.2.0-128/hbase/hbase.tar.gz
sudo -u hdfs /usr/odp/1.2.2.0-128/hadoop/bin/hdfs dfs -chown hdfs:hdfs /odp/apps/1.2.2.0-128/hbase

# 4) validar no HDFS
sudo -u hdfs /usr/odp/1.2.2.0-128/hadoop/bin/hdfs dfs -ls -h /odp/apps/1.2.2.0-128/hbase
```

------------------------------------------------------------
## Ambari Infra Solr (Auditoria/log index) – INSTALAR PRIMEIRO
------------------------------------------------------------
Objetivo: prover backend de indexação para auditorias (Ranger) e logs (quando aplicável).

Pela interface do Ambari:
- Actions → Add Service → selecione “Ambari Infra Solr”.
- Assign Masters: instale o servidor principal em master.cdp. Clientes em todos os nós.
- Customize Services (valores típicos):
  - Porta HTTP: 8886 (confirme o default sugerido pela stack).
  - Replication factor: 1 ou 2 (em cluster pequeno, use 1 para economizar recursos).
  - Heap: 512m–1g (ajuste à memória disponível).
- Validação: clique em “Run Service Check”. Acesse a UI (se habilitada) via http://master.cdp:8886/solr/#/ para verificar os cores.
- Firewall: abra 8886/tcp no nó onde o Solr roda.

------------------------------------------------------------
## Ranger (Admin, Usersync, Tagsync) – APÓS INFRA SOLR
------------------------------------------------------------
Objetivo: governança, políticas de acesso e auditoria centralizada nos serviços do ecossistema.

Pela interface do Ambari:
- Actions → Add Service → selecione “Ranger”.
- Componentes: Ranger Admin e Ranger Usersync em master.cdp; Ranger Tagsync em um worker (ex.: node1.cdp).
- Database (Customize Services):
  - DB Flavor: POSTGRES (padrão suportado pelo Ambari no master), ou MySQL externo se preferir.
  - Host/Port: master.cdp:5432 (para Postgres no master), nome do DB: ranger, usuário: rangeradmin.
  - Defina senhas fortes e guarde-as com segurança. Elas devem obedecer às políticas de senha do Ranger.
- Auditoria para Solr:
  - Habilite “Audit to Solr”.
  - URL de Solr: http://master.cdp:8886/solr (o core “ranger_audits” será criado automaticamente).
- Inicialização e validação:
  - Continue o wizard, aguarde a instalação e start dos componentes.
  - Rode “Run Service Check”.
  - Acesse o Ranger: http://master.cdp:6080 (usuário inicial típico: admin). Na primeira entrada, ajuste a senha seguindo a política.
- Dica: em Ranger → Security Zone/Policies, valide que os serviços instalados (HDFS, YARN, Hive, Kafka, HBase, NiFi, Spark) aparecerão para criação de policies após seus plugins serem instalados/ativados.
- Firewall: abra 6080/tcp no host do Ranger Admin; mantenha 8886/tcp aberto para a auditoria em Solr.

Observação crítica sobre senhas e política do Ranger:
- No Ranger Admin, revise “Settings → User Management → Password Policy”. Garanta que SENHAS de serviços/usuários criados obedeçam a essa regra. Senhas fora do padrão causam falhas silenciosas na criação de bancos de dados, inicialização de plugins ou login.

------------------------------------------------------------
## Hive (com Tez) – Metastore e HiveServer2
------------------------------------------------------------
Pré-requisitos: HDFS, YARN e Tez saudáveis; Ranger instalado (opcional, mas recomendado, para aplicar políticas cedo).

Pela interface do Ambari:
- Actions → Add Service → selecione “Hive”.
- Assign Masters:
  - Hive Metastore: master.cdp
  - HiveServer2: master.cdp (ou um worker dedicado, se preferir)
  - Clients: nos nodes que usarão Hive CLI/Beeline.
- Database do Metastore:
  - Opção A (recomendada neste blueprint): MySQL Server gerenciado pela stack (instalado em um dos nós, ex.: node1.cdp). O Ambari cuidará do schema e do driver.
  - Opção B: PostgreSQL (no master). Ajuste host, DB, usuário e senha conforme configurado.
  - Em ambos os casos, escolha senhas fortes e compatíveis com a política do Ranger.
- Diretórios e parâmetros:
  - Warehouse dir (HDFS): /apps/hive/warehouse (Ambari cria com permissões corretas).
  - Enable Tez for Hive: habilitado (usa Tez para execução de queries).
- Inicialização e validação:
  - Conclua o wizard e inicie o serviço.
  - Run Service Check (Hive). Use Quick Links para abrir a UI (se disponível).
  - Opcional (linha de comando): via Beeline no master: beeline -u jdbc:hive2://master.cdp:10000 -n hive -e "show databases;"
- Firewall: abra 10000/tcp (HiveServer2) e 9083/tcp (Metastore) conforme necessidade de acesso.

------------------------------------------------------------
## Kafka – Brokers nos workers
------------------------------------------------------------
Pré-requisitos: ZooKeeper estável e em quorum.

Pela interface do Ambari:
- Actions → Add Service → selecione “Kafka”.
- Assign Masters:
  - Brokers: node1.cdp, node2.cdp, node3.cdp.
- Customize Services:
  - Listeners (PLAINTEXT): :6667 (ou confirme o padrão sugerido).
  - zookeeper.connect: master.cdp:2181,node1.cdp:2181,node2.cdp:2181 (ajuste aos seus nós ZK).
  - log.dirs: /var/log/kafka (ou diretório dedicado de dados).
- Inicialização e validação:
  - Instale, inicie e rode "Run Service Check".
  - Opcional (CLI em um broker): criar e listar tópicos para validação.
- Firewall: abra 6667/tcp nos nós brokers.

------------------------------------------------------------
## HBase (+ Phoenix Query Server)
------------------------------------------------------------
Pré-requisitos: HDFS e ZooKeeper estáveis.

Pela interface do Ambari:
- Actions → Add Service → selecione “HBase”.
- Assign Masters:
  - HBase Master: master.cdp
  - RegionServers: node1.cdp, node2.cdp, node3.cdp
  - Phoenix Query Server: master.cdp
- Customize Services:
  - hbase.rootdir: hdfs://<namenode-host>:8020/hbase (Ambari preenche conforme NameNode).
  - hbase.zookeeper.quorum: master.cdp,node1.cdp,node2.cdp (ajuste conforme seus servidores ZK).
  - Ajuste heap sizes para Master/RegionServer conforme RAM.
- Inicialização e validação:
  - Instale e inicie. Rode "Run Service Check".
  - Opcional (CLI): acessar http://master.cdp:16010 (UI do Master) e http://<regionserver>:16030 (UI do RegionServer), se expostas; Phoenix QS típico em 8765/tcp.
- Firewall: abra 16010/16020/16030 (HBase) e 8765 (PQS) conforme necessidade de acesso.

------------------------------------------------------------
## NiFi (Fluxos de dados)
------------------------------------------------------------
Objetivo: orquestração/ingestão de dados de forma visual.

Pela interface do Ambari:
- Actions → Add Service → selecione “NiFi”.
- Assign Masters:
  - NiFi Master: node2.cdp (ou outro worker dedicado)
  - NiFi CA: node2.cdp (ou master.cdp se preferir centralizar)
- Customize Services (valores comuns e alinhados ao blueprint):
  - Modo inicial: HTTP (nifi.node.ssl.isenabled = false). Porta HTTP típica: 9090.
  - nifi.initial.admin.identity: admin (você criará/ajustará depois a credencial de admin na UI, seguindo a política de senhas do Ranger).
  - Para ativar HTTPS posteriormente: habilite TLS/CA e defina keystore/truststore pela própria UI/ambari.
- Inicialização e validação:
  - Instale, inicie e rode "Run Service Check".
  - Acesse: http://node2.cdp:9090/nifi (ajuste host/porta conforme sua instalação). Crie/ajuste credenciais conforme política.
- Firewall: abra 9090/tcp (ou 9443/tcp para HTTPS, quando habilitado).

------------------------------------------------------------
## Spark3 (JobHistory, Livy2, ThriftServer)
------------------------------------------------------------
Pré-requisitos: HDFS e YARN funcionando; Hive instalado para uso do ThriftServer.

Pela interface do Ambari:
- Actions → Add Service → selecione “Spark3”.
- Assign Masters:
  - Spark3 JobHistoryServer: master.cdp
  - Livy2 Server: node1.cdp e node3.cdp (alta disponibilidade básica)
  - Spark3 ThriftServer: node3.cdp (ou outro worker)
- Customize Services (conforme blueprint/VDF):
  - Livy: porta 8998; master = yarn; impersonation = true.
  - History Server UI: 18080; diretório de eventos no HDFS (ex.: hdfs:///spark-history).
  - Ajuste memória/cores de executores conforme sua capacidade.
- Inicialização e validação:
  - Instale, inicie e rode "Run Service Check".
  - Opcional: Submeter SparkPi via Ambari Quick Links ou CLI (spark-submit) e verificar no History Server.
- Firewall: abra 18080/tcp (History), 8998/tcp (Livy), 10015/tcp (ThriftServer) conforme necessidade de acesso.

------------------------------------------------------------
## Serviços opcionais/tardios
------------------------------------------------------------
Dependendo do seu caso de uso, você pode instalar depois (um a um): Knox, Atlas, Ranger KMS, Oozie, Sqoop, Spark2, NiFi Registry, Zeppelin, Flink, Hue, Ambari Metrics, Log Search. Verifique versões no ODP-VDF e impactos de recursos.

------------------------------------------------------------
## Checklist de validação final
------------------------------------------------------------
- Todos os serviços com status Green no Ambari e Service Checks bem-sucedidos.
- UIs principais acessíveis (quando aplicável): Ranger (6080), Infra Solr (8886), HiveServer2 (10000), Kafka (6667), HBase (16010/16030), NiFi (9090/9443), Spark History (18080), Livy (8998), ThriftServer (10015).
- Policies básicas criadas no Ranger (HDFS/Hive/Kafka/HBase/NiFi/Spark) e auditoria chegando ao Solr.
- Senhas documentadas/armazenadas em cofre e em conformidade com a política do Ranger.
- Firewall ajustado apenas para as portas realmente necessárias.

------------------------------------------------------------
## Solução de problemas comuns
------------------------------------------------------------
- Falhas por senha fora do padrão: revise a política no Ranger e recrie usuários/credenciais atendendo aos requisitos. Evite caracteres não suportados por determinados backends (ex.: barras invertidas em alguns contextos JDBC).
- Service Check falha logo após instalação: aguarde estabilização, confirme dependências (ZK/HDFS/YARN), reabra portas no firewall e verifique SELinux (use permissive durante a instalação; depois, avalie políticas SE para produção).
- Banco do Hive Metastore não inicializa: confirme driver JDBC instalado (o Ambari geralmente provisiona), credenciais válidas, e que a senha cumpre a política. Verifique logs em /var/log/hive/ e /var/log/ambari-agent/.
- Ranger sem auditoria: valide URL do Solr (8886), estado do core "ranger_audits" e conectividade de rede.

