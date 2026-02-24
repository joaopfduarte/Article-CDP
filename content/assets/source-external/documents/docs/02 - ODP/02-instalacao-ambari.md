# 02 -  Instalação e Configuração Básica do Ambari

Esta etapa cobre a instalação e configuração inicial do Ambari Server e Ambari Agent em **Oracle Linux 9 ARM64**, preparando o ambiente para provisionar serviços Hadoop/Spark via interface web.

***

## 1. Verificação pré-instalação

Antes de continuar, confirme que os pacotes já foram instalados conforme o documento `01-configuracao-repositorio.md`.

Para validar rapidamente:

```bash
rpm -q ambari-server || echo "Instalar no master: sudo dnf install -y ambari-server"
rpm -q ambari-agent  || echo "Instalar em todos os nós: sudo dnf install -y ambari-agent"
```

***

## 2. Configuração do Ambari Server

No **master-cdp**, execute o setup inicial para configurar banco de dados, JDK e demais parâmetros:

```bash
sudo ambari-server setup -s
```

O modo silencioso (`-s`) aceita as opções padrão:
- Usa JDK OpenJDK 1.8
- Banco interno PostgreSQL
- Desabilita downloads GPL extras

***

## 3. Configuração do Ambari Agent

Em **todos** os nós (incluindo master), edite `/etc/ambari-agent/conf/ambari-agent.ini`:

```ini
[server]
hostname=master.cdp.dev.br
url_port=8440
secured_url_port=8441
```

***

## 4. Inicialização dos Serviços

### 4.1. Ambari Server (master)

```bash
sudo systemctl enable --now ambari-server
```

### 4.2. Ambari Agent (todos os nós)

```bash
sudo systemctl enable --now ambari-agent
```

***

## 5. Verificação dos Serviços

▶ No **master-cdp**:

```bash
sudo systemctl status ambari-server
```

▶ Em cada **node×3**:

```bash
sudo systemctl status ambari-agent
```

O status deve ser **active (running)**.

***

## 6. Acesso à Interface Web do Ambari

Após alguns segundos, acesse:

```
http://<IP_PUBLICO_MASTER>:8080
```

- **Usuário:** admin
- **Senha:** admin

***

## 7. Checklist antes de prosseguir

- Ambari Server instalado e ativo no master
- Ambari Agent instalado e ativo em todos os nós
- Interface Web acessível em porta 8080

Após validar, avance para o documento `03-configuracao-servicos.md` para iniciar o assistente de configuração dos serviços do cluster.