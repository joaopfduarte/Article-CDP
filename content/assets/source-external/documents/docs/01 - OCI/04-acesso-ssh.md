# 04 • Acesso via OpenSSH às Máquinas Virtuais

Após criar suas instâncias na Oracle Cloud Infrastructure (OCI) e informar a chave pública SSH durante a criação, você poderá acessá-las remotamente a partir do seu computador local.

### 1. Pré-requisitos

- Ter o arquivo de chave privada (`id_rsa` ou nome personalizado) salvo no seu computador, normalmente no diretório `~/.ssh/` (Linux/macOS) ou `C:\Users\<SeuUsuario>\.ssh\` (Windows).
- Ter o comando `ssh` disponível no terminal (Linux/macOS) ou no PowerShell (Windows 10+).

### 2. Estrutura dos comandos

O comando geral para acessar uma máquina via SSH é:

```bash
ssh -i <caminho_para_sua_chave_privada> opc@<ip_publico_da_maquina>
```


- `-i <caminho_para_sua_chave_privada>`: caminho completo para o arquivo da chave privada (ex: `~/.ssh/id_rsa`)
- `opc`: usuário padrão das instâncias Oracle Linux 9 criadas na OCI
- `<ip_publico_da_maquina>`: endereço IP público da VM, obtido no painel da OCI

### 3. Exemplo prático para 4 máquinas

Supondo que os IPs públicos das suas máquinas sejam:

| Máquina         | IP Público         |
|-----------------|-------------------|
| master          | 152.67.10.101     |
| node1           | 152.67.10.102     |
| node2           | 152.67.10.103     |
| node3           | 152.67.10.104     |

No terminal do seu computador local, acesse cada máquina com:

Acesse o master
```bash
ssh -i ~/.ssh/id_rsa opc@152.67.10.101
```
Acesse o node1
```bash
ssh -i ~/.ssh/id_rsa opc@152.67.10.102
```
Acesse o node2
```bash
ssh -i ~/.ssh/id_rsa opc@152.67.10.103
```

Acesse o node3
```bash
ssh -i ~/.ssh/id_rsa opc@152.67.10.104
```
