# 05 – Armazenamento na Oracle Cloud Infrastructure (OCI)

Este documento detalha o planejamento, a provisão e as melhores práticas para o armazenamento de dados em ambientes de Data Lake open source na Oracle Cloud Infrastructure (OCI), com foco em Hadoop (HDFS), Hive e componentes do ecossistema Apache.

---

## 1. Visão geral da arquitetura de armazenamento

A camada de armazenamento é fundamental para garantir escalabilidade, segurança e desempenho no Data Lake. Neste projeto, o armazenamento é provisionado utilizando:

- **Volumes em Bloco (Block Volume OCI):** Discos persistentes de alto desempenho anexados às instâncias de computação (VMs).
- **Disco local NVMe (opcional):** Para workloads temporários e de alta velocidade (não persistente).
- **Object Storage OCI:** Para ingestão de dados brutos, backups e integração com Hadoop/Spark via conectores.

O HDFS é o principal sistema de arquivos para dados estruturados e não estruturados. O Object Storage é recomendado para landing zone, backup e arquivamento.

---





