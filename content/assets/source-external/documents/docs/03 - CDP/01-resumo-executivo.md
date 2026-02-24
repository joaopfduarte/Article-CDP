# 01 - Resumo Executivo: Automação de Cluster Ambari (ODP)

##  Objetivo do Projeto
Este projeto visa providenciar uma infraestrutura completa e automatizada para Big Data utilizando a **Open Source Data Platform (ODP)** gerenciada pelo **Apache Ambari**. A infraestrutura é provisionada na **Oracle Cloud Infrastructure (OCI)** via Terraform, configurada via Ansible, e o cluster Hadoop é implantado automaticamente via Blueprints do Ambari.

---

##  Arquitetura da Solução

### Infraestrutura (Terraform)
*   **Provider**: OCI (Oracle Cloud)
*   **Recursos**: Compute Instances (VMs), VCN, Subnets, Security Lists.
*   **Topologia**:
    *   1x **Master Node** (`master.cdp`): Ambari Server, Banco de Dados, Serviços de Gerenciamento.
    *   3x **Worker Nodes** (`node1`, `node2`, `node3`): DataNodes, NodeManagers, Clientes.

### Configuração (Ansible + Cloud-Init)
*   **Cloud-Init**: Bootstrap inicial das VMs, instalação de dependências básicas e execução do Ansible.
*   **Ansible**:
    *   `site.yml`: Configuração do SO, instalação do Java, Ambari Server/Agents e PostgreSQL.
    *   `cluster_deploy.yml`: Interação com a API do Ambari para aplicar o Blueprint e criar o cluster.

### Cluster Hadoop (Ambari Blueprint)
*   **Stack**: ODP 1.2 (Baseado em HDP 3.x)
*   **Serviços**: HDFS, YARN, Zookeeper, Hive, Spark, Kafka, NiFi, Ranger, Atlas, etc.
*   **Segurança**: Ranger para autorização, Ambari para autenticação.

---

##  Status da Automação

| Componente | Status | Descrição |
| :--- | :--- | :--- |
| **Infraestrutura** |  Concluído | Terraform cria rede e VMs corretas com DNS interno. |
| **Ambari Setup** |  Concluído | Ansible instala e configura Server e Agents automaticamente. |
| **Cluster Deploy** |  Concluído | Blueprint é aplicado e cluster é instanciado via API. |
| **Correções** |  Aplicadas | Fix para driver JDBC MySQL e caracteres de escape em templates. |

---

##  Como Executar
Para subir o ambiente completo do zero:

1.  **Configurar Variáveis**: Ajuste o `terraform.tfvars` ou `variables.tf` com seus OCIDs e chaves SSH.
2.  **Provisionar**:
    ```bash
    terraform init
    terraform apply -auto-approve
    ```
3.  **Aguardar**: O processo total leva entre **25 a 45 minutos**.
4.  **Acessar**:
    *   **Ambari UI**: `http://<MASTER_PUBLIC_IP>:8080`
    *   **Credenciais**: `admin` / `admin` (ou conforme configurado).

---

##  Estrutura de Documentação
Esta pasta contém a documentação atualizada do projeto, organizada sequencialmente:

*   **01-resumo-executivo.md**: Visão geral (este arquivo).
*   **02-guia-tecnico-automacao.md**: Detalhes técnicos da automação.
*   **03-manual-debug.md**: Instruções para intervenção manual e troubleshooting.
*   **04-arquitetura-fluxo.md**: Diagramas visuais do fluxo de dados e provisionamento.
*   **05-senhas-credenciais.md**: Referência de credenciais padrão.
*   **06-scripts-referencia.md**: Códigos e scripts utilizados no processo.
