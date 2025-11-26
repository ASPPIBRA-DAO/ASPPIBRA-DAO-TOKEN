# ASPPIBRA-DAO-TOKEN

## Visão Geral

Este projeto implementa um sistema de Organização Autônoma Descentralizada (DAO) para a ASPPIBRA. O sistema é composto por um token de governança ERC20 (ASPPIBRAToken), um contrato de Timelock para a execução de propostas com um atraso de tempo, e o contrato principal do DAO que gerencia o processo de votação e governança.

O sistema utiliza os contratos auditados e seguros da OpenZeppelin como base para o token, o timelock e o governador.

## Status Atual

Os contratos principais foram desenvolvidos e os scripts de implantação foram criados. O desafio principal, que era a correta configuração de permissões entre o DAO e o Timelock durante a implantação, foi identificado e resolvido no script `deploy_dao.ts`.

O próximo passo é executar a sequência de implantação completa em um ambiente limpo para verificar a solução.

## Arquitetura dos Contratos

- **`contracts/token/ASPPIBRAToken.sol`**: O token de governança ERC20. É um token padrão com a funcionalidade `ERC20Votes`, essencial para que os detentores de tokens possam delegar seu poder de voto e participar da governança.

- **`contracts/governance/Timelock.sol`**: Um contrato que atua como `TimelockController`. Todas as propostas aprovadas pelo DAO devem passar por este contrato, que impõe um atraso mínimo (atualmente configurado para 2 dias) antes que a proposta possa ser executada. Isso funciona como uma salvaguarda, dando tempo para a comunidade auditar e, se necessário, reagir a uma proposta maliciosa.

- **`contracts/governance/ASPPIBRADAO.sol`**: O cérebro do sistema. Este contrato herda de `Governor` e `GovernorTimelockControl` da OpenZeppelin. Ele é responsável por:
    - Gerenciar o processo de criação de propostas.
    - Contabilizar os votos.
    - Enfileirar propostas aprovadas no `Timelock`.
    - É implantado usando um padrão de proxy (ERC1967) para permitir futuras atualizações de lógica sem alterar o endereço do contrato.

## Processo de Implantação

Os contratos devem ser implantados em uma ordem específica, pois a implantação de um depende do endereço do outro.

**Pré-requisito:** Certifique-se de que o Hardhat está instalado e configurado.

1.  **Limpar o Ambiente (Recomendado):**
    Para garantir que não haja artefatos de compilação antigos, execute:
    ```bash
    npx hardhat clean
    ```

2.  **Compilar os Contratos:**
    ```bash
    npx hardhat compile
    ```

3.  **Implantar o Token de Governança:**
    Este script implanta `ASPPIBRAToken.sol` e salva seu endereço em `deployment-addresses.json`.
    ```bash
    npx hardhat run scripts/deploy_token.ts --network hardhat
    ```

4.  **Implantar o Timelock:**
    Este script implanta `Timelock.sol` e adiciona seu endereço ao `deployment-addresses.json`.
    ```bash
    npx hardhat run scripts/deploy_timelock.ts --network hardhat
    ```

5.  **Implantar e Configurar o DAO:**
    Este é o passo mais crítico. O script `deploy_dao.ts`:
    a. Implanta a implementação do `ASPPIBRADAO`.
    b. Implanta o proxy `ERC1967Proxy` que aponta para a implementação.
    c. Lê os endereços do token e do timelock do arquivo `deployment-addresses.json`.
    d. Chama a função `initialize` no proxy do DAO.
    e. **Configura as permissões no Timelock**: concede o `PROPOSER_ROLE` ao DAO e revoga o `TIMELOCK_ADMIN_ROLE` do implantador, transferindo o controle para o próprio DAO.
    ```bash
    npx hardhat run scripts/deploy_dao.ts --network hardhat
    ```

## Próximos Passos (To-Do)

- [ ] **Executar a Implantação Completa:** Realizar com sucesso toda a sequência de implantação na rede de desenvolvimento Hardhat para validar a correção final.
- [ ] **Escrever Testes Abrangentes:** Criar testes para simular todo o ciclo de vida de uma proposta: criação, delegação de votos, votação, enfileiramento no timelock e execução.
- [ ] **Transferir Propriedade do Token:** Após a implantação, a propriedade do `ASPPIBRAToken` (se houver funções de cunhagem ou administrativas) deve ser transferida para o DAO ou para o Timelock, para que a comunidade possa controlar o suprimento futuro de tokens.
- [ ] **Documentação da Interface:** Documentar as principais funções e eventos dos contratos para facilitar a integração com um front-end.
- [ ] **Desenvolvimento de Front-End:** Construir uma interface de usuário para que os membros da comunidade possam facilmente:
    - Consultar seu saldo de tokens.
    - Delegar seu poder de voto.
    - Criar e visualizar propostas.
    - Votar em propostas ativas.
- [ ] **Preparar para Implantação em Testnet:** Configurar o `hardhat.config.ts` para uma rede de testes pública (ex: Sepolia) e planejar a implantação.
