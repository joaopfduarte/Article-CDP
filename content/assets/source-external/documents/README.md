# Documentação do Projeto de Iniciação Científica
Plataforma de Data Lake Open Source na Oracle Cloud Infrastructure (CDP)

Este repositório contém a documentação e os scripts para a criação de um cluster Hadoop/Spark baseado em **ODP (OpenSource Data Platform)** dentro da **OCI (Oracle Cloud Infrastructure)**.

> Atenção: todos os valores sensíveis (OCIDs, endereços IP, nomes de VCN, senhas) estão representados por **placeholders**. Substitua-os antes de executar qualquer comando.

## Sumário

1. [Visão Geral](./docs/00%20-%20Visão%20Geral)
2. [Implantação Automatizada (Recomendado)](./docs/03%20-%20CDP)
3. [Implantação Manual (Didática)](./docs/01%20-%20OCI)
4. [Anexos](./assets)

---

## Implantação Automatizada (Recomendado)

Esta é a maneira mais simples, rápida e robusta de provisionar o ambiente. Utilizamos **Terraform** e **OCI Resource Manager (Stacks)** para criar toda a infraestrutura e configurar o cluster Ambari/ODP automaticamente, sem intervenção manual complexa.

Consulte a documentação detalhada em **[03 - CDP](./docs/03%20-%20CDP)**:

1.  **[Resumo Executivo](./docs/03%20-%20CDP/01-resumo-executivo.md)**: Entenda a arquitetura e o que será instalado.
2.  **[Guia de Deploy Automático](./docs/03%20-%20CDP/07-guia-deploy-oci-stacks.md)**: Passo a passo para subir o cluster usando OCI Stacks (Interface Gráfica).
3.  **[Credenciais e Senhas](./docs/03%20-%20CDP/05-senhas-credenciais.md)**: Dados de acesso após a instalação.

---

## Implantação Manual 

Se o seu objetivo é **aprender** sobre cada componente da infraestrutura ou realizar uma instalação "from scratch" para fins de estudo, siga o fluxo manual original. Este método é mais trabalhoso e suscetível a erros humanos, sendo recomendado apenas para aprofundamento técnico.

1.  **[Fase 1: Infraestrutura OCI](./docs/01%20-%20OCI/00-prerequisitos.md)**: Provisionamento manual de VCN, Subnets, Firewalls e Compute Instances.
2.  **[Fase 2: Instalação do ODP](./docs/02%20-%20ODP/00-prérequisitos.md)**: Instalação e configuração manual do Ambari e serviços Hadoop.

---

## Modelos e Anexos

Consulte a pasta **[Assets](https://github.com/Ecosystem-CDP/assets)** para exemplos de arquivos de configuração e templates genéricos utilizados no projeto.

---

> **Nota**: Para ambientes de produção ou pesquisa séria, utilize sempre o método de **Implantação Automatizada**.
