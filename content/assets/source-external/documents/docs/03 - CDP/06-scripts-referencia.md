# 06 - Scripts de Referência

Coleção de scripts "one-liners" e utilitários para operação diária do cluster.

## 1. Monitoramento de Progresso (Watch Loop)

Execute este comando no **Master** para acompanhar o progresso de instalação do cluster em tempo real, sem precisar dar refresh na página.

```bash
watch -n 5 'curl -s -u admin:admin http://localhost:8080/api/v1/clusters/odp-cluster/requests/1 | jq ".Requests | {status: .request_status, progress: .progress_percent, details: .request_context}"'
```

## 2. Validação de Ambari Agents

Verifica rapidamente se todos os nós estão reportando corretamente para o servidor.

```bash
# Executar no Master
curl -s -u admin:admin http://localhost:8080/api/v1/hosts | jq -r '.items[].Hosts.host_name'
```
*Deve retornar 4 nomes (master, node1, node2, node3).*

## 3. Restart Rápido de Serviços (Emergência)

Se precisar reiniciar o Ambari Server e todos os Agentes (ex: após mudança de configuração de rede):

```bash
# No Master
ambari-server stop
ambari-server start

# Loop para reiniciar agents nos workers via SSH (requer acesso root/opc)
for host in node1 node2 node3; do
  ssh $host.cdp "sudo ambari-agent restart"
done
```

## 4. Limpeza de Logs (Manutenção)

Se o disco encher (`df -h` mostrando 100%), limpe os logs antigos do Ambari e Hadoop:

```bash
# Limpar logs antigos do Ambari
rm -rf /var/log/ambari-server/ambari-server.log.*
rm -rf /var/log/ambari-agent/ambari-agent.log.*

# Limpar logs de containers do YARN (se aplicável)
rm -rf /hadoop/yarn/log/*
```

## 5. Teste de Conexão JDBC (Hive/Oozie)

Teste se o Ambari consegue falar com o banco de dados (útil para debug de "Connection Refused").

```bash
# Requer java instalado
java -cp /usr/share/java/postgresql-jdbc.jar org.postgresql.Driver
# (Se não retornar erro de ClassNotFound, o driver está ok)
```
