# XX • problemas-conhecidos

### 1. Inserção manual da chave pública SSH

É possível configurar o acesso SSH sem senha de forma **manual**, copiando o conteúdo da chave pública do nó master e colando diretamente nos arquivos dos demais nós.

#### Passo 1: Gere a chave no nó master (caso ainda não tenha feito)

```bash
ssh-keygen -b 4096 -t rsa -C "odp-cluster" -N "" -f ~/.ssh/id_rsa
```

> Isso criará os arquivos `~/.ssh/id_rsa` (chave privada) e `~/.ssh/id_rsa.pub` (chave pública).

#### Passo 2: Visualize a chave pública
Copie o conteúdo da saída (linha única que começa com `ssh-rsa`).
Na sua máquina Master, pegue sua chave pública com o seguinte comando:

```bash
cat ~/.ssh/id_rsa.pub
```
#### Passo 3: Em cada nó (incluindo o próprio master)

Edite (ou crie) o arquivo `~/.ssh/authorized_keys`:

```bash
nano ~/.ssh/authorized_keys
```

Cole a chave pública copiada da etapa anterior. Salve e saia (`Ctrl + O`, `Enter`, `Ctrl + X` no nano).

#### Passo 4: Ajuste as permissões (necessário)

Ainda em cada nó, execute os comandos abaixo para garantir a segurança correta do diretório e do arquivo:

```bash
echo "<your-public-key>" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chown opc:opc ~/.ssh ~/.ssh/authorized_keys
```

> Esses ajustes são **obrigatórios**. Se não forem feitos, a autenticação SSH por chave pode falhar silenciosamente.

#### Passo 5: Teste a conexão sem senha

De volta ao master, teste o acesso sem senha a cada nó:

```bash
ssh opc@node1
ssh opc@node2
ssh opc@node3
```
