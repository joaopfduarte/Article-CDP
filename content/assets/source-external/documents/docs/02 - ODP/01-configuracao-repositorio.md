# 01 -  Configuração do Repositório ODP e Instalação do Ambari/ODP

Este documento detalha como configurar os repositórios oficiais da Clemlab para **Oracle Linux 9 ARM64** e instalar os componentes Ambari Server, Ambari Agent e ODP Stack.

> **Importante:** As URLs dos repositórios usam autenticação temporária; em caso de erro **403 Forbidden**, refaça o login no portal Clemlab e tente novamente.

***

## 1. Importar a chave GPG

Em **todos** os nós, execute:

```bash
sudo curl -fsSL -o /etc/pki/rpm-gpg/RPM-GPG-KEY-clemlab \
  https://clemlabs.s3.eu-west-3.amazonaws.com/RPM-GPG-KEY-SHA256-Jenkins
sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-clemlab
```

***

## 2. Criar os arquivos de repositório

Em **todos** os nós, crie os seguintes arquivos em `/etc/yum.repos.d/`:

### 2.1 ODP Stack

`/etc/yum.repos.d/odp-release.repo`

```ini
[ODP-1.2.2.0-128]
name=ODP-1.2.2.0-128-aarch64
baseurl=https://clemlabs.s3.eu-west-3.amazonaws.com/centos9-aarch64/odp-release/1.2.2.0-128/rpms/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-clemlab
```

### 2.2 Utilitários ODP

`/etc/yum.repos.d/odp-utils.repo`

```ini
[ODP-UTILS-1.2.2.0]
name=ODP-UTILS-1.2.2.0-aarch64
baseurl=https://clemlabs.s3.eu-west-3.amazonaws.com/centos9-aarch64/odp-utils/1.2.2.0/rpms/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-clemlab
```

### 2.3 Ambari

`/etc/yum.repos.d/ambari-release.repo`

```ini
[ambari-2.7.9.0-61]
name=ambari-2.7.9.0-61
baseurl=https://clemlabs.s3.eu-west-3.amazonaws.com/centos9-aarch64/ambari-release/2.7.9.0.0-61/rpms/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-clemlab
```

***

## 3. Atualizar o cache do DNF

```bash
sudo dnf clean all
sudo dnf makecache
```

***

## 4. Instalar o Ambari Agent (todos os nós)

```bash
sudo dnf install -y ambari-agent
```

Verifique:

```bash
rpm -q ambari-agent
```

***

## 5. Instalar o Ambari Server (apenas no master)

No **master-cdp**, execute:

```bash
sudo dnf install -y ambari-server
```

Verifique:

```bash
rpm -q ambari-server
```
***

## 6. Pós-instalação do Ambari Server (master)

No **master-cdp**, finalize:

```bash
sudo ambari-server setup -s
sudo systemctl enable --now ambari-server
```

Verifique status:

```bash
sudo systemctl status ambari-server
```

***

## 7. Configurar e iniciar o Ambari Agent

Em **todos** os nós (incluindo o master):

1. Ajuste `/etc/ambari-agent/conf/ambari-agent.ini`, definindo:
   ```
   [server]
   hostname=master.cdp
   url_port=8440
   ```
2. Habilite e inicie:
   ```bash
   sudo systemctl enable --now ambari-agent
   sudo systemctl status ambari-agent
   ```

***

Após estes passos, abra o Ambari Web em `http://<IP_PUBLICO_MASTER>:8080` e prossiga com o wizard de provisionamento do cluster.

***

## 8. Modo offline (opcional)

Se estiver seguindo a instalação offline descrita em `00-prérequisitos.md`, após copiar os pacotes para `/opt/odp-repo/` em todos os nós, ajuste os arquivos `.repo` para apontarem para o caminho local usando `file:///`.

Exemplo (ajuste os caminhos conforme a estrutura baixada):

```ini
[ambari-2.7.9.0-61]
name=ambari-2.7.9.0-61
baseurl=file:///opt/odp-repo/centos9-aarch64/ambari-release/2.7.9.0.0-61/rpms/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-clemlab
```

Recrie o cache do DNF:

```bash
sudo dnf clean all
sudo dnf makecache
```
