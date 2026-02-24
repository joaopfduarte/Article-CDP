# 03 - Manual de Debug e Intervenção

Este documento serve como referência para quando a automação falhar ou quando for necessária uma intervenção manual no cluster.

##  Cheat-Sheet de Comandos (Nó Master)

### Serviços Ambari
```bash
# Verificar status
ambari-server status
ambari-agent status

# Logs principais
tail -f /var/log/ambari-server/ambari-server.log
tail -f /var/log/ambari-agent/ambari-agent.log
```

### Automação (Cloud-Init & Ansible)
```bash
# Log da inicialização da VM
tail -f /var/log/cloud-init-output.log

# Log da execução do Ansible
tail -f /var/log/ansible/ansible.log
```

---

##  Procedimentos de Recuperação (Redeploy)

Se o cluster estiver em um estado inconsistente e você precisar recomeçar sem destruir as VMs (Terraform), siga este procedimento:

### 1. Limpeza do Cluster Antigo
No nó **Master**:
```bash
# Parar o servidor
ambari-server stop

# Resetar o banco de dados do Ambari (apaga tudo!)
ambari-server reset --silent

# Reiniciar
ambari-server start
```

### 2. Relançar o Deploy
Você pode invocar o playbook do Ansible novamente para refazer a configuração e deploy do cluster:

```bash
cd /root
ansible-playbook cluster_deploy.yml
```

---

##  Troubleshooting Comum

### 1. Hosts não aparecem no Ambari
Se o passo de registro de hosts falhar ou travar esperando:
*   Verifique se o `ambari-agent` está rodando nos workers (`node1`, `node2`, `node3`).
*   Verifique a resolução de nomes: `ping master.cdp` deve funcionar a partir dos workers.
*   Verifique o arquivo `/etc/ambari-agent/conf/ambari-agent.ini` nos workers. O campo `hostname` deve apontar para `master.cdp`.

### 2. Erro "Hive Metastore schema initialization failed"
Geralmente causado por senha incorreta ou banco de dados PostgreSQL não inicializado.
*   **Solução**: Verifique se o serviço PostgreSQL está rodando (`systemctl status postgresql`). Tente conectar manualmente: `psql -U hive -h localhost -d hive`. A senha deve corresponder à definida no blueprint.

### 3. Erro na Instalação de Pacotes (Yum/Dnf)
Se houver falha de download:
*   Verifique a conexão de internet do Master (Gateway NAT ou IP Público).
*   Verifique se os repositórios ODP/HDP estão acessíveis.

### 4. Interface Web Inacessível
Se o Ambari Server diz "Running" mas você não acessa a porta 8080:
*   Verifique o Firewall da Oracle Cloud (Security List da VCN). A porta 8080 deve estar aberta para o seu IP.
*   Verifique firewall local (embora normalmente desabilitado pela automação): `systemctl status firewalld`.

### 5. Timeout ou Falha de Conexão via ISP Específico (Roteamento)
Se você não consegue acessar suas instâncias (SSH timeout, falha de ping/tracert) mas o acesso funciona normalmente via 4G ou outra rede:

*   **Sintomas**:
    *   SSH na porta 22 dá timeout.
    *   Interfaces web não carregam.
    *   Security Lists e Firewalls estão corretos (testado via outra rede).
*   **Diagnóstico**:
    *   Execute um `tracert` (Windows) ou `traceroute` (Linux) para o IP da instância. Se o tráfego morrer no backbone do seu provedor antes de chegar à Oracle, é um problema de roteamento (BGP/Uplink).
*   **Solução**:
    *   Entre em contato com o suporte técnico do seu provedor de internet (ISP).
    *   Informe que há uma falha de roteamento para os prefixos de IP da Oracle Cloud.
    *   Este é um problema de borda/uplink do provedor e não requer alterações na sua infraestrutura ou na OCI.

---

##  Acesso Manual à API
Você pode usar o `curl` para interagir diretamente com o Ambari e verificar o estado detalhado das requisições.

**Listar Hosts:**
```bash
curl -u admin:admin -H "X-Requested-By: ambari" http://localhost:8080/api/v1/hosts
```

**Verificar Status de Requisições (Progresso da Instalação):**
```bash
# Liste as requisições (requests) para achar o ID (geralmente 1)
curl -u admin:admin -H "X-Requested-By: ambari" http://localhost:8080/api/v1/clusters/odp-cluster/requests

# Detalhes da requisição 1
curl -u admin:admin -H "X-Requested-By: ambari" http://localhost:8080/api/v1/clusters/odp-cluster/requests/1
```
