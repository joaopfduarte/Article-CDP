# 00 -  Pré-requisitos

Este documento descreve todos os requisitos mínimos — de infraestrutura, software e acesso — para que a instalação da OpenSource Data Platform (ODP) 1.2.4.0 seja feita em qualquer ambiente Oracle Cloud Infrastructure (OCI) ou em servidores bare-metal compatíveis, usando **Oracle Linux 9** em **arquitetura ARM64**.

Nos tópicos 1, 2, 3 e 4 abaixo há informações gerais de revisão e recomendações. É importante confirmar que suas máquinas atendem aos requisitos de hardware e consultar as documentações oficiais da Clemlab e da OCI para mais detalhes.

***

## 1. Infra-estrutura mínima

A seguir, a configuração de referência em OCI para cada nó:

| Papel do nó | OCPU mín. | Memória mín. | Shape OCI               | Armazenamento |
|-------------|-----------|--------------|-------------------------|---------------|
| master      | 1 OCPU    | 6 GiB        | VM.Standard.A1.Flex     | 50 GiB        |
| node × 3    | 1 OCPU    | 6 GiB        | VM.Standard.A1.Flex     | 50 GiB        |

> Obs.: Ajuste OCPU e RAM conforme carga de trabalho. Em bare-metal, considere configurações equivalentes.

***

## 2. Rede e DNS

| Item                              | Valor                               |
|-----------------------------------|-------------------------------------|
| VCN CIDR                          | `<CIDR_VCN>` (ex.: 10.0.0.0/16)     |
| Subnet pública CIDR               | `<CIDR_PUBLICA>` (ex.: 10.0.1.0/24) |
| Subnet privada CIDR (dados)       | `<CIDR_PRIVADA>` (ex.: 10.0.2.0/24) |
| Security List / NSG – portas IN   | 22/tcp, 8080/tcp, 8440-8441/tcp     |
| Security List / NSG – portas OUT  | 80/tcp, 443/tcp                     |
| DNS interno                       | `<dominio_local>` (ex.: cdp.dev.br) |

***

## 3. Acesso à Internet ou repositório offline

A instalação pode ser feita de duas formas:

1. **Online:** permitindo saída HTTP/HTTPS (80/443) para `archive.clemlab.com`.
2. **Offline:** baixando previamente:
   - `repos-ambari.tar.gz`
   - `repos.tar.gz`
   - `repos-utils.tar.gz`

Em cenários offline, copie os arquivos para `/opt/odp-repo/` em **todos** os nós e aponte o DNF para o caminho local.

***

## 4. Usuários, chaves e permissões

- **Usuário padrão do SO:** `opc`, com privilégio sudo.
- **SSH:** chave RSA/ECDSA carregada no OCI ou distribuída manualmente (`~/.ssh/id_rsa`).
- **Fuso horário e NTP:** serviço chronyd habilitado e sincronizado.

***

## 5. Dependências do sistema operacional

> Todos os comandos devem ser executados em **todos** os nós (master e workers) com privilégio sudo.

### 5.1 Atualização do sistema

```bash
sudo dnf update -y
sudo reboot
```

### 5.2 Instalação de pacotes essenciais

```bash
sudo dnf install -y \
  java-1.8.0-openjdk-headless \
  java-1.8.0-openjdk-devel \
  python3 python3-pip \
  curl wget tar unzip \
  net-tools bind-utils \
  openssh-server openssh-clients \
  chrony libaio psmisc rsync which
```

### 5.3 Ajustes de kernel e memória

Crie `/etc/sysctl.d/99-odp.conf` com:

```text
# — Desempenho e estabilidade para Hadoop / Spark —
vm.swappiness                 = 1
vm.overcommit_memory          = 1
vm.max_map_count              = 262144

# Buffers de rede
net.core.somaxconn            = 1024
net.core.netdev_max_backlog   = 5000
net.ipv4.tcp_tw_reuse         = 1
net.ipv4.ip_local_port_range  = 10240 65535
```

```bash
sudo sysctl --system
```

### 5.4 Limites de arquivos e processos

Crie `/etc/security/limits.d/99-odp.conf`:

```text
* soft  nofile 65536
* hard  nofile 65536
* soft  nproc  65536
* hard  nproc  65536
```

Verifique PAM:

```bash
grep -q pam_limits.so /etc/pam.d/system-auth \
  || echo "session required pam_limits.so" \
       | sudo tee -a /etc/pam.d/system-auth
```

### 5.5 SELinux

Para evitar bloqueios durante a instalação inicial, configure o SELinux como permissivo em todos os nós:

```bash
getenforce
sudo setenforce 0  # efeito imediato (temporário)
```

Torne permanente editando `/etc/selinux/config` e ajustando:

```text
SELINUX=permissive
```

Reinicie quando viável:

```bash
sudo reboot
```

***

## 6. Sincronização de tempo

```bash
sudo systemctl enable --now chronyd
chronyc sources -v
timedatectl status
```

***

## 7. Portas e firewall

Em cada nó, abra portas com **firewalld**:

```bash
sudo firewall-cmd --permanent --add-port=22/tcp
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=8440-8441/tcp
sudo firewall-cmd --permanent --add-port=50070/tcp
sudo firewall-cmd --permanent --add-port=8088/tcp
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

***

## 8. Definição de hostname

Em cada nó, ajuste o hostname:

```bash
# Master
sudo hostnamectl set-hostname master.cdp

# Node1
sudo hostnamectl set-hostname node1.cdp

# Node2
sudo hostnamectl set-hostname node2.cdp

# Node3
sudo hostnamectl set-hostname node3.cdp

sudo reboot
```

***

## 9. Configuração de DNS interno (/etc/hosts)

Edite `/etc/hosts` em **todos** os nós:

```text
150.230.68.97   master.cdp.dev.br master-cdp
167.234.244.116 node1.cdp.dev.br  node1-cdp
150.230.79.249  node2.cdp.dev.br  node2-cdp
152.70.219.228  node3.cdp.dev.br  node3-cdp
```

Verifique:

```bash
hostname -f
ping -c2 master-cdp
ping -c2 node1-cdp
```

***

## 10. SSH sem senha (passwordless SSH)

Procedimento manual (recomendado, passo a passo) exatamente como validado em produção:

1) No nó master, gere a chave:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

2) Para cada host, crie o diretório de chaves, copie a chave pública e ajuste permissões manualmente.

Exemplo por host (repita para master, node1, node2, node3):

```bash
# Troque <host_fqdn> pelo host_name dos seus hosts:
# (opcional) Primeira conexão para registrar no known_hosts e evitar prompts em loops
ssh -o StrictHostKeyChecking=no opc@<host_fqdn> "echo OK"

# Crie o diretório .ssh com as permissões corretas
ssh opc@<host_fqdn> "mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && chown -R opc:opc ~/.ssh"

# Copie a chave pública do master para o host alvo
scp ~/.ssh/id_rsa.pub opc@<host_fqdn>:/tmp/master_id_rsa.pub

# Anexe ao authorized_keys e remova o arquivo temporário
ssh opc@<host_fqdn> "cat /tmp/master_id_rsa.pub >> ~/.ssh/authorized_keys && rm -f /tmp/master_id_rsa.pub && chmod 600 ~/.ssh/authorized_keys"
```

3) Teste o acesso sem senha para cada host:

```bash
ssh opc@<PUBLIC_IPv4_master> hostname -f
ssh opc@<PUBLIC_IPv4_node1> hostname -f
ssh opc@<PUBLIC_IPv4_node2> hostname -f
ssh opc@<PUBLIC_IPv4_node3> hostname -f
```

Alternativa com loop (sem usar ssh-copy-id):

```bash
for h in master.cdp.dev.br node1.cdp.dev.br node2.cdp.dev.br node3.cdp.dev.br; do
  ssh -o StrictHostKeyChecking=no opc@$h "mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && chown -R opc:opc ~/.ssh" && \
  scp ~/.ssh/id_rsa.pub opc@$h:/tmp/master_id_rsa.pub && \
  ssh opc@$h "cat /tmp/master_id_rsa.pub >> ~/.ssh/authorized_keys && rm -f /tmp/master_id_rsa.pub && chmod 600 ~/.ssh/authorized_keys" && \
  ssh opc@$h "hostname -f" || echo "Falha em $h"
done
```

Notas importantes:
- Execute tudo como usuário `opc` (com sudo disponível), exatamente como na instalação.
- Garanta que a porta 22/tcp esteja liberada no firewall/NSG e que os FQDNs do item 9 resolvam corretamente.
***

## 11. Limpeza e cache do DNF

```bash
sudo dnf clean all
sudo dnf makecache
```

Teste acesso aos repositórios Clemlab:

```bash
curl -I https://archive.clemlab.com/centos9-aarch64/
```

***

Após concluir estes pré-requisitos, prossiga para `01-configuracao-repositorio.md`, onde será configurado o repositório ODP e iniciada a instalação do Ambari.