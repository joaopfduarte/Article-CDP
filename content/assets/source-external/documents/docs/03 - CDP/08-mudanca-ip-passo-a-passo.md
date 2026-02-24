# 08 - Mudança de IP (Passo a Passo)

Este guia descreve os passos necessários para atualizar as regras de segurança na Oracle Cloud Infrastructure (OCI) quando o seu endereço IP público muda. Isso é comum para quem trabalha de home office ou utiliza conexões de internet com IPs dinâmicos.

Se o seu IP mudar, você perderá o acesso SSH e o acesso às interfaces web (Ambari, NiFi, etc.) até que a regra de firewall (Security List) seja atualizada.

## Pré-requisitos

1.  Acesso ao Console da Oracle Cloud (OCI).
2.  Saber em qual **Compartment** e **VCN** o ambiente CDP foi criado.

---

## Passo a Passo

### 1. Identificar seu novo IP Público
Acesse um site como [whatismyip.com](https://www.whatismyip.com/) ou [meuip.com.br](https://www.meuip.com.br/) e anote o seu endereço IPv4 atual (ex: `203.0.113.45`).

### 2. Acessar a VCN (Virtual Cloud Network)
1.  Faça login no console da OCI.
2.  No menu de navegação (canto superior esquerdo), vá em **Networking** > **Virtual Cloud Networks**.
3.  Selecione o **Compartment** onde o CDP está instalado.
4.  Clique no nome da VCN utilizada (geralmente criada automaticamente pela Stack ou nomeada conforme seu projeto).

### 3. Localizar a Security List
1.  Dentro da página da VCN, no menu lateral esquerdo, clique em **Security Lists**.
2.  Clique na **Security List** que contém as regras de acesso externo (geralmente chamada de `Default Security List` ou similar, dependendo de como foi criada).

### 4. Editar as Regras de Entrada (Ingress Rules)
1.  Identifique as regras que permitem o acesso SSH (porta 22) e acesso às interfaces Web (portas 8080, 7180, etc.). Normalmente, a coluna **Source** mostrará o seu IP antigo.
2.  Clique nos três pontinhos (menu de ações) na linha da regra desejada e selecione **Edit**.
3.  No campo **Source CIDR**, substitua o IP antigo pelo seu **novo IP**, adicionando `/32` ao final.
    *   Exemplo: Se seu novo IP é `203.0.113.45`, preencha `203.0.113.45/32`.
4.  Clique em **Save Changes**.

> [!TIP]
> Haverá várias regras para diferentes portas vindo do mesmo IP, você precisará editar cada uma delas. 

### 5. Testar o Acesso
Após salvar, a alteração entra em vigor quase imediatamente.
1.  Tente conectar via SSH: `ssh -i chave.pem opc@<IP-DO-BASTION-OU-MANAGER>`
2.  Tente acessar o Ambari ou outra interface web no navegador.

Se conseguir conectar, a liberação foi realizada com sucesso.
