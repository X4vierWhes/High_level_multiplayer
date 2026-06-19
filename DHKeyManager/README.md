# DHKeyManager

Servidor simples de gerenciamento de chaves públicas para o ecossistema **War Multiplayer**.

Este documento descreve, de forma didática, a proposta de funcionamento do projeto, o papel do servidor como **autoridade de chaves públicas** e a arquitetura sugerida para evoluir a solução com segurança e clareza.

---

## 1. Resumo do projeto

A ideia central do `DHKeyManager` é atuar como um serviço confiável que:

1. recebe a chave pública de um usuário;
2. armazena essa chave;
3. permite que outros usuários consultem essa chave;
4. devolve a chave consultada **assinada pela própria autoridade**;
5. permite remover ou revogar a chave quando o usuário sair do sistema.

Em outras palavras, o servidor não é apenas um armazenamento de chaves. Ele funciona como uma **autoridade reconhecida** por todo o sistema, responsável por atestar que determinada chave pública pertence a determinado usuário.

---

## 2. Objetivo do projeto

O objetivo deste serviço é resolver um problema comum em sistemas distribuídos: **como confiar na chave pública de outro usuário**.

Sem uma autoridade central, o cliente não sabe se a chave recebida realmente pertence ao usuário correto. Com este servidor, a chave é entregue junto de uma **assinatura digital**, permitindo que o cliente valide a autenticidade da resposta.

### O que este serviço faz

- cadastra chaves públicas de usuários;
- mantém essas chaves em memória ou em persistência futura;
- consulta uma chave com base em um identificador;
- assina a resposta com a chave privada da autoridade;
- remove ou revoga chaves quando necessário.

### O que este serviço não deve fazer, pelo menos na primeira versão

- não deve substituir um sistema completo de autenticação;
- não deve decidir sozinho quem é o usuário real sem alguma estratégia de identidade;
- não deve expor a chave privada da autoridade;
- não deve confiar cegamente em qualquer requisição recebida.

---

## 3. Visão geral do funcionamento

O fluxo básico pode ser entendido assim:

1. um usuário registra sua chave pública no servidor;
2. o servidor guarda essa chave associada a um identificador;
3. outro usuário solicita essa chave usando o identificador;
4. o servidor recupera a chave pública correspondente;
5. o servidor monta uma resposta com os dados necessários;
6. o servidor assina essa resposta com sua própria chave privada;
7. o cliente valida a assinatura usando a chave pública da autoridade;
8. se a assinatura for válida, o cliente pode confiar naquela chave recebida.

Esse desenho cria uma relação de confiança clara: **o cliente confia na autoridade, e a autoridade atesta a chave do usuário**.

---

## 4. Papel da autoridade de chaves públicas

A autoridade precisa ter seu próprio par de chaves:

- **chave privada da autoridade**: usada apenas pelo servidor para assinar respostas;
- **chave pública da autoridade**: distribuída de forma confiável aos clientes para validação.

### Por que isso é importante?

Porque o cliente precisa de um mecanismo objetivo para verificar se uma chave pública foi realmente emitida pelo servidor e não foi alterada no caminho.

Sem a assinatura da autoridade, qualquer intermediário poderia tentar trocar a chave por outra e o cliente não teria como perceber.

---

## 5. Modelo de confiança

O modelo de confiança proposto é simples:

- o cliente confia previamente na **chave pública da autoridade**;
- o servidor é a fonte autorizada para emitir respostas sobre chaves de usuários;
- toda resposta importante deve ser assinada;
- o cliente verifica a assinatura antes de usar a chave consultada.

### Em resumo

A regra prática é:

> **Se a resposta não estiver assinada pela autoridade, o cliente não deve confiar nela.**

---

## 6. Estrutura recomendada do projeto

Como o projeto está em Spring Boot, a organização mais clara é separar responsabilidades por camadas.

### Estrutura sugerida de pacotes

```text
com.GDWar.DHKeyManager
├── controller
├── service
├── domain
├── dto
├── crypto
├── repository
└── config
```

### Responsabilidade de cada camada

#### `controller`
Recebe as requisições HTTP e devolve respostas HTTP.

Exemplos de responsabilidade:
- ler dados enviados pelo cliente;
- chamar o serviço adequado;
- devolver status HTTP apropriado.

#### `service`
Contém as regras de negócio do sistema.

Exemplos:
- validar entrada;
- cadastrar chave;
- revogar chave;
- localizar chave;
- montar a resposta assinada.

#### `domain`
Contém os modelos internos do sistema.

Exemplos:
- registro de chave do usuário;
- dados da autoridade;
- resposta assinada.

#### `dto`
Contém os objetos usados para entrada e saída da API.

Exemplos:
- request de cadastro;
- request de remoção;
- response de consulta.

#### `crypto`
Concentra tudo o que for criptografia.

Exemplos:
- geração do par de chaves da autoridade;
- assinatura de payload;
- verificação de assinatura, se necessário.

#### `repository`
Armazena e recupera dados.

Na primeira versão, pode ser apenas memória. Depois, pode evoluir para banco de dados.

#### `config`
Guarda configurações do sistema.

Exemplos:
- algoritmo de assinatura;
- tamanho das chaves;
- dados da autoridade;
- parâmetros de expiração.

---

## 7. Os três endpoints principais

A proposta inicial contempla exatamente três operações principais.

---

### 7.1 Cadastrar nova chave

**Objetivo:** registrar a chave pública de um usuário no servidor.

**Exemplo conceitual:**

```http
POST /keys
```

**O que esse endpoint faz:**

- recebe o identificador do usuário;
- recebe a chave pública do usuário;
- valida os dados recebidos;
- grava o registro;
- retorna confirmação.

### Regras importantes

- o identificador precisa ser válido;
- a chave pública não pode estar vazia;
- o sistema deve decidir o que fazer se já existir uma chave para o mesmo identificador;
- a chave pode ser atualizada, revogada ou bloqueada conforme a regra definida.

---

### 7.2 Remover chave atual

**Objetivo:** permitir que o próprio usuário deixe o sistema de forma controlada.

**Exemplo conceitual:**

```http
DELETE /keys/{userId}
```

**O que esse endpoint faz:**

- encontra a chave do usuário;
- marca como removida ou revogada;
- impede que ela continue sendo usada como chave ativa.

### Recomendação importante

Em vez de apagar fisicamente tudo no começo, o ideal é fazer **remoção lógica**.

Isso significa:

- a chave deixa de ser válida;
- o histórico pode ser preservado;
- fica mais fácil auditar o que aconteceu;
- evita ambiguidades em consultas antigas.

---

### 7.3 Pedir chave

**Objetivo:** recuperar a chave pública de outro usuário usando um identificador.

**Exemplo conceitual:**

```http
GET /keys/{userId}
```

**O que esse endpoint faz:**

- recebe o identificador do usuário desejado;
- busca a chave correspondente;
- monta uma resposta assinada pela autoridade;
- devolve os dados ao cliente solicitante.

### O que deve vir na resposta

- identificador do usuário;
- chave pública;
- data/hora de emissão;
- identificador da autoridade;
- assinatura da autoridade.

---

## 8. Como funciona a assinatura da resposta

A assinatura é a parte mais importante do desenho.

### O que significa assinar a resposta?

Significa que o servidor aplica sua chave privada sobre os dados retornados, produzindo uma assinatura que o cliente pode verificar com a chave pública da autoridade.

### O que deve ser assinado?

A ideia é assinar o conjunto de dados que define a confiança da resposta, por exemplo:

- `userId`
- `publicKey`
- `issuedAt`
- `authorityId`
- possivelmente `expiresAt` ou `status`

### Por que isso protege o sistema?

Se alguém tentar alterar a chave durante o caminho, a assinatura deixa de bater.

Assim, o cliente consegue detectar adulteração, falsificação ou corrupção dos dados.

---

## 9. Identificador do usuário: IPv4 ou outro valor?

Esse ponto merece atenção especial.

### Uso de IPv4

O IPv4 pode parecer simples, mas tem limitações importantes:

- pode mudar;
- pode ser compartilhado por NAT;
- pode representar vários usuários;
- pode ser alterado por troca de rede;
- não é uma identidade forte por si só.

### Recomendação

O ideal é usar um identificador mais estável, como:

- `userId`;
- `deviceId`;
- algum identificador interno do sistema.

### Quando o IPv4 ainda pode ser útil?

Ele pode ser usado como informação auxiliar, principalmente em ambientes fechados ou testes, mas não deveria ser a base principal de identidade do projeto.

### Decisão recomendada

- **identificador principal:** `userId`
- **IPv4:** metadado opcional ou referência secundária

---

## 10. Regras de negócio sugeridas

Para evitar confusão futura, o projeto deve definir algumas regras desde o começo.

### Regras mínimas

1. um identificador deve corresponder a uma chave ativa por vez, salvo regra explícita diferente;
2. chaves removidas devem ser revogadas;
3. consultas devem retornar apenas chaves válidas e ativas;
4. toda resposta de consulta deve ser assinada;
5. dados inválidos devem gerar erro claro;
6. não deve existir exposição da chave privada da autoridade.

### Perguntas que o projeto precisa responder cedo

- uma chave nova substitui a anterior automaticamente?
- é permitido manter várias chaves por usuário?
- quanto tempo uma chave permanece válida?
- como registrar revogação?
- quem pode cadastrar ou remover chaves?

Definir isso logo no início evita mudanças confusas depois.

---

## 11. Modelo de dados sugerido

Abaixo está um modelo conceitual simples para a primeira versão.

### Registro de chave do usuário

Pode conter:

- identificador do usuário;
- chave pública;
- status da chave (`ACTIVE`, `REVOKED`);
- data de criação;
- data de revogação;
- informações adicionais.

### Dados da autoridade

Podem conter:

- identificador da autoridade;
- chave pública da autoridade;
- chave privada da autoridade;
- algoritmo usado;
- versão da chave.

### Resposta assinada

Pode conter:

- payload principal;
- assinatura digital;
- metadados de emissão;
- dados da autoridade emissora.

---

## 12. Persistência: como começar e como evoluir

### Primeira versão

Na fase inicial, o armazenamento pode ser em memória, por simplicidade.

Vantagens:
- fácil de desenvolver;
- fácil de testar;
- rápido para prototipação.

Desvantagem:
- os dados se perdem ao reiniciar o servidor.

### Evolução futura

Depois, o projeto pode evoluir para:

- banco relacional;
- Redis;
- armazenamento distribuído;
- persistência criptografada.

A principal vantagem de separar `repository` desde cedo é que essa troca fica muito mais fácil.

---

## 13. Segurança e cuidados importantes

Mesmo sendo um serviço simples, alguns cuidados são essenciais.

### Cuidados mínimos

- proteger a chave privada da autoridade;
- validar entradas;
- não confiar em payload sem assinatura;
- evitar sobrescrita silenciosa de registros;
- registrar revogações;
- documentar claramente o formato da resposta.

### Observação sobre autenticação

Dependendo do cenário real, talvez seja necessário adicionar autenticação para os endpoints de cadastro e remoção.

Por exemplo:
- somente o próprio usuário pode remover a chave;
- somente clientes autorizados podem cadastrar chaves.

Isso pode ser adicionado na evolução do projeto.

---

## 14. Fluxo resumido de ponta a ponta

### Cadastro

1. usuário gera sua chave pública;
2. envia a chave ao servidor;
3. servidor valida e armazena;
4. chave passa a estar disponível para consulta.

### Consulta

1. outro usuário pede a chave;
2. servidor busca o registro;
3. servidor assina os dados;
4. cliente valida a assinatura;
5. cliente usa a chave com confiança.

### Remoção

1. usuário solicita remoção;
2. servidor revoga a chave;
3. consultas futuras não devem considerá-la ativa.

---

## 15. Estrutura de projeto sugerida para implementação futura

Se a implementação crescer, uma organização possível seria:

```text
src/main/java/com/GDWar/DHKeyManager
├── DhKeyManagerApplication.java
├── controller/
├── service/
├── domain/
├── dto/
├── crypto/
├── repository/
└── config/
```

Essa separação mantém o projeto compreensível e facilita manutenção, testes e evolução.

---

## 16. Próximos passos recomendados

Depois dessa fase de documentação, os próximos passos naturais seriam:

1. definir os contratos JSON dos endpoints;
2. decidir se o identificador principal será `userId` ou IPv4;
3. criar o modelo interno de chave;
4. implementar o serviço em memória;
5. adicionar assinatura das respostas;
6. criar testes de validação;
7. evoluir para persistência real.

---

## 17. Conclusão

O `DHKeyManager` deve funcionar como uma **autoridade de chaves públicas simples e confiável**.

A proposta correta não é apenas guardar chaves, mas sim **atestar** chaves públicas para que outros clientes possam usá-las com segurança.

O desenho mais saudável para começar é:

- três endpoints principais;
- autoridade com seu próprio par de chaves;
- resposta assinada;
- armazenamento inicial em memória;
- identificação preferencial por `userId`;
- revogação lógica em vez de exclusão direta.

Esse formato cria uma base sólida para o sistema crescer sem perder clareza.

