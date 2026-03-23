# 04 - Arquitetura e Fluxo de Automação

##  Fluxo de Provisionamento (End-to-End)

O diagrama abaixo ilustra todo o processo desde o comando `terraform apply` até o cluster estar operacional.

```mermaid
sequenceDiagram
    participant User as Usuário (Terraform)
    participant OCI as Oracle Cloud (OCI)
    participant Master as VM Master
    participant Workers as VM Workers
    participant AmbariSrv as Ambari Server
    participant AmbariAgt as Ambari Agents

    User->>OCI: Terraform Apply
    OCI->>Master: Provisionar VM & Network
    OCI->>Workers: Provisionar VMs
    
    Note over Master,Workers: Cloud-Init (User Data) Start
    
    Master->>Master: Auto-Update OS
    Master->>Master: Install Python/Ansible
    
    Workers->>Workers: Auto-Update OS
    Workers->>Workers: Install Ambari Agent
    
    Master->>Master: Run "run-ansible.sh"
    Master->>Master: Ansible: Install Java, Postgres, Ambari Serv
    Master->>AmbariSrv: Start Ambari Service
    
    Workers->>AmbariAgt: Start Agent
    AmbariAgt->>AmbariSrv: Register (Heartbeat)
    
    AmbariSrv-->>Master: Hosts Registered (Wait Loop)
    
    Master->>AmbariSrv: POST /api/v1/blueprints (Upload JSON)
    Master->>AmbariSrv: POST /api/v1/clusters (Create Cluster)
    
    AmbariSrv->>Workers: Install Hadoop Services (HDFS, YARN...)
    AmbariSrv->>Master: Install Services (Hive, Zoo, Ranger...)
    
    Note over AmbariSrv: Cluster Installation Progress
    
    AmbariSrv-->>User: Cluster Ready (Web UI Available)
```

##  Topologia da Infraestrutura

```mermaid
graph TB
    subgraph OCI_VCN [Oracle Cloud VCN]
        subgraph Public_Subnet [Public Subnet 10.0.0.0/24]
            direction TB
            Master[Master Node<br>10.0.0.2<br>Ambari Server + Services]
            Node1[Worker 1<br>10.0.0.3<br>DataNode + NodeManager]
            Node2[Worker 2<br>10.0.0.4<br>DataNode + NodeManager]
            Node3[Worker 3<br>10.0.0.5<br>DataNode + NodeManager]
        end
        IGW[Internet Gateway]
    end
    
    User[Admin PC] -->|SSH/HTTP 8080| IGW
    IGW --> Master
    IGW --> Node1
    IGW --> Node2
    IGW --> Node3
    
    Master <-->|Internal Traffic| Node1
    Master <-->|Internal Traffic| Node2
    Master <-->|Internal Traffic| Node3
```

##  Fluxo de Dados de Configuração

1.  **Local Machine**: `blueprint.json` e `*.tf`
2.  **Transferência**: Terraform `file provisioner` envia arquivos para `/root` no Master.
3.  **Processamento**: Ansible lê variáveis e arquivos locais do Master.
4.  **Aplicação**: Ambari lê Blueprint e distribui configurações para os Agents nos nós.
