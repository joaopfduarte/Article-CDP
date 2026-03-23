# Problemas Conhecidos e Troubleshooting Avançado (OCI)

Este documento centraliza problemas técnicos complexos que podem afetar o acesso e a operação da infraestrutura na Oracle Cloud Infrastructure, detalhando sintomas, diagnósticos e soluções.

---

## 1. Falha de Roteamento por Provedor de Internet (ISP) - "SSH Timeout"

### Descrição do Problema
O usuário perde a capacidade de acessar as instâncias na OCI (SSH, HTTP/HTTPS) através de sua conexão de internet fixa principal, mas o acesso continua funcionando normalmente através de outras redes (ex: 4G/5G, VPN corporativa ou outro provedor).

### Sintomas Observados
1.  **SSH Hang/Timeout**: Ao tentar conectar via SSH, o terminal "trava" e depois exibe `Connection timed out`.
2.  **Perda de Pacotes**: Comandos como `ping` falham completamente para o IP público da instância.
3.  **Acesso Alternativo Funcional**: O acesso funciona perfeitamente ao rotear o tráfego por um Hotspot móvel (4G) ou outra rede.
4.  **Regras de Firewall Corretas**: As Security Lists e Network Security Groups (NSG) na OCI já permitem o tráfego do IP do usuário.

### Diagnóstico Técnico Passo a Passo

Para confirmar que o problema é de **roteamento intermediário (ISP)** e não da OCI, execute os testes abaixo.

#### Passo 1: Teste de Conexão Verboso (SSH)
Execute o SSH com a flag `-vvv` para ver onde a conexão para.
```bash
ssh -vvv -i sua-chave.key opc@<IP_DA_INSTANCIA>
```
*   **Resultado Típico**: O log mostra `Connecting to <IP> port 22`, fica parado por vários segundos e retorna `Connection timed out`. Isso indica que o pacote SYN foi enviado, mas não houve resposta (SYN-ACK) ou ela se perdeu no caminho.

#### Passo 2: Rastreamento de Rota (Trace Route)
Esta é a prova definitiva. O comando mostra por onde os pacotes passam antes de falhar.

**No Windows (PowerShell/CMD):**
```powershell
tracert -d <IP_DA_INSTANCIA>
```

**No Linux/macOS:**
```bash
traceroute -n <IP_DA_INSTANCIA>
```

*   **Interpretação**:
    *   Se o trace completar até o final, a rota está ok.
    *   Se o trace parar **dentro da rede do seu provedor** (ex: saltos 3, 4 ou 5) e começar a dar "Request timed out" (*), o problema está no **Uplink/BGP** do provedor com a Oracle.
    *   Se o trace chegar até a borda da Oracle mas falhar no final, pode ser Security List. Mas se funciona no 4G, isso é descartado.

#### Passo 3: Teste Cruzado (Isolamento)
*   Desconecte o computador da rede fixa (Cabo/Wi-Fi).
*   Rotear a internet do celular (4G) para o computador.
*   Tente conectar novamente.
*   **Se funcionar**: O problema é 100% isolado no seu Provedor de Internet (ISP).

### Solução

Este problema **não pode ser resolvido pelo usuário final** nem pela OCI, pois trata-se de uma falha de publicidade de rotas (BGP) ou bloqueio em um link de trânsito específico do provedor.

**Ação Necessária**:
1.  Abra um chamado técnico no seu Provedor de Internet.

Geralmente, o NOC (Network Operations Center) do provedor precisará ajustar a rota de saída ou trocar o link de trânsito utilizado para o tráfego destinado à Oracle Cloud.
