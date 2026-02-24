# 00 • Pré-requisitos para OCI

## 1. Criação da conta
Inicialmente, acesse este link e crie uma conta do tipo free tier. Dessa forma, será capaz de utilizar os recursos da Oracle cloud com um crédito base de $300,00. [Link de acesso](https://www.oracle.com/cloud/free/).

> É interessante que mesmo com este crédito, também adicione um cartão de crédito à conta, mesmo que não seja utilizado. Ocorre que alguns recuros de hardware, como a máquina que será utilizada, em termos de quantidade de instâncias, são limitadas.

## 2. Sequência de Procedimentos para Preparação do Ambiente na OCI

A tabela abaixo apresenta, em ordem lógica e sequencial, os principais passos para preparar o ambiente na Oracle Cloud Infrastructure (OCI) antes da criação das instâncias que comporão o cluster Hadoop/ODP/Ambari.

| Etapa | Descrição | Observações Importantes |
|-------|-----------|------------------------|
| 1     | Criar Compartimento (Compartment) | Organize recursos do projeto em um compartimento dedicado. |
| 2     | Criar Rede Virtual (VCN) | Defina um bloco CIDR adequado (ex: 10.0.0.0/16). |
| 3     | Criar Sub-rede Pública | Para acesso SSH e Ambari Web; exemplo: 10.0.1.0/24. |
| 4     | Criar Sub-rede Privada (opcional) | Para dados internos do cluster, se desejar isolar tráfego. |
| 5     | Criar Gateway de Internet | Necessário para acesso externo/SSH. |
| 6     | Criar Gateway NAT (opcional) | Permite que sub-redes privadas acessem a internet. |
| 7     | Criar Tabela de Rotas | Associe rotas para internet/NAT às sub-redes correspondentes. |
| 8     | Criar Security List (Lista de Segurança) | Libere portas 22 (SSH), 8080 (Ambari), 8440-8441 (Ambari Agent), 80/443 (atualizações). |
| 9     | Criar Network Security Groups (NSG) | Permite regras de firewall mais flexíveis por aplicação. |
| 10    | Associar Security List e NSG às sub-redes | Garanta que as regras estejam ativas para as VMs. |
| 11    | Criar Par de Chaves SSH | Geração local para acesso seguro às instâncias. |
| 12    | (Opcional) Criar Block Volumes | Para armazenamento de dados HDFS/Hive em cada VM. |
| 13    | Revisar Limites de Quotas | Verifique se há recursos suficientes para criar todas as VMs necessárias. |
| 14    | Criar Instâncias de Computação (VMs) | Master, node1, node2, node3, com Oracle Linux 9. |
| 15    | Anexar Volumes em Bloco às VMs | Para dados do cluster, se necessário. |
| 16    | Validar Acesso SSH e Configuração de Rede | Teste conectividade e resolução de nomes entre as VMs. |

---
> **Importante:** Execute cada etapa sequencialmente, validando o funcionamento antes de prosseguir. Estarei utilizando valores genéricos nos exemplos (CIDR, nomes, IPs), portanto é necessário que substitua posteriormente por dados do seu cluster.
---

## 2.1 Nomenclatura Sugerida para Componentes do Projeto

Abaixo há sugestões de nomes genéricos para cada recurso que será criado. Você pode usar esses nomes caso queira, mas sinta-se livre para criar a nomeclatura que desejar.

| Componente                  | Nome sugerido                  | Observações                        |
|-----------------------------|-------------------------------|------------------------------------|
| Compartimento               | `comp-datalake-projeto`       | Compartimento dedicado ao projeto  |
| VCN (Virtual Cloud Network) | `vcn-datalake`                | Rede principal do cluster          |
| Sub-rede pública            | `subnet-pub-datalake`         | Para acesso SSH/Ambari Web         |
| Sub-rede privada (opcional) | `subnet-priv-datalake`        | Para tráfego interno do cluster    |
| Gateway de Internet         | `igw-datalake`                | Permite acesso externo             |
| Gateway NAT (opcional)      | `natgw-datalake`              | Acesso internet para sub-rede priv.|
| Tabela de Rotas             | `rt-datalake`                 | Associada à VCN                    |
| Security List               | `sl-datalake`                 | Lista de segurança do cluster      |
| Network Security Group      | `nsg-datalake`                | Grupo de segurança do cluster      |
| Par de Chaves SSH           | `datalake-key`                | Chave SSH para acesso às VMs       |
| Volume em Bloco (dados)     | `bv-datalake-node1`           | Um para cada VM de dados           |
| Instância VM Master         | `master`          | Nó master do cluster               |
| Instância VM Node 1         | `node1`           | Worker node 1                      |
| Instância VM Node 2         | `node2`           | Worker node 2                      |
| Instância VM Node 3         | `node3`           | Worker node 3                      |
| Bucket Object Storage       | `bucket-datalake`             | Para ingestão/backup de dados      |

---

## 3. Resumo e associação de tópicos

A tabela abaixo serve apenas para associar as etapas com componentes e seus respectivos nomes sugeridos.

| Etapa Sequencial | Componente                  | Nome sugerido              | Observações / Quando criar                                      |
|------------------|----------------------------|----------------------------|-----------------------------------------------------------------|
| 1                | Compartimento               | `comp-datalake-projeto`    | Primeiro recurso a ser criado, para isolar todos os demais      |
| 2                | VCN (Virtual Cloud Network) | `vcn-datalake`             | Criar após o compartimento, rede principal do cluster           |
| 3                | Sub-rede pública            | `subnet-pub-datalake`      | Após a VCN, para SSH/Ambari Web                                 |
| 4                | Sub-rede privada (opcional) | `subnet-priv-datalake`     | Após a VCN, para tráfego interno (se desejar isolamento)        |
| 5                | Gateway de Internet         | `igw-datalake`             | Após sub-rede pública, para acesso externo                      |
| 6                | Gateway NAT (opcional)      | `natgw-datalake`           | Após sub-rede privada, para acesso externo da rede privada      |
| 7                | Tabela de Rotas             | `rt-datalake`              | Após gateways, associar rotas às sub-redes                      |
| 8                | Security List               | `sl-datalake`              | Após sub-redes, para definir regras de firewall                 |
| 9                | Network Security Group      | `nsg-datalake`             | Após sub-redes, para regras de firewall mais flexíveis          |
| 10               | Par de Chaves SSH           | `datalake-key`             | Antes de criar as VMs, para acesso seguro                       |
| 11               | Volume em Bloco (dados)     | `bv-datalake-node1`        | Antes ou após as VMs, um volume para cada nó de dados           |
| 12               | Instância VM Master         | `vm-datalake-master`       | Após toda a infraestrutura de rede e segurança estar pronta     |
| 13               | Instância VM Node 1         | `vm-datalake-node1`        | Após toda a infraestrutura de rede e segurança estar pronta     |
| 14               | Instância VM Node 2         | `vm-datalake-node2`        | Após toda a infraestrutura de rede e segurança estar pronta     |
| 15               | Instância VM Node 3         | `vm-datalake-node3`        | Após toda a infraestrutura de rede e segurança estar pronta     |
| 16               | Bucket Object Storage       | `bucket-datalake`          | Após a VCN, para ingestão/backup de dados                       |

---

**Dicas de boas práticas:**
- Use nomes descritivos, sem espaços ou caracteres especiais.
- Padronize prefixos (ex: `vcn-`, `subnet-`, `vm-`, `nsg-`, `sl-`, `bv-`) para facilitar a identificação do tipo de recurso.











