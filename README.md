# Relógio do Apocalipse

Aplicativo mobile educativo desenvolvido em **Flutter + Firebase** para monitoramento de crises e conflitos internacionais, com foco em visualização de risco global, consulta de eventos recentes, filtros, autenticação e persistência de favoritos.

## Visão geral

O **Relógio do Apocalipse** apresenta um painel com eventos internacionais recentes obtidos pela **Currents API**, calcula um **score global de risco de 0 a 100** e exibe esse resultado de forma clara para o usuário.

A proposta do aplicativo é transformar dados abertos sobre conflitos, tensões geopolíticas e escaladas militares em uma visualização simples, didática e interativa.

## Funcionalidades implementadas

- **Autenticação com Firebase**
  - cadastro de usuário (e-mail e senha)
  - login
  - logout
  - tratamento de erros com mensagens em português

- **Consumo de API internacional**
  - integração com a **Currents API** (`https://currentsapi.services/v1/search`)
  - busca por palavras-chave: `war`, `conflict`, `missile`, `sanctions`, `invasion`, `military`, `nuclear`
  - carregamento de eventos recentes das últimas 48 horas
  - classificação automática de severidade (Crítico / Moderado / Baixo) via análise de palavras-chave
  - tratamento de loading, erro, ausência de conexão e limite de requisições

- **Dashboard principal**
  - score de risco global de **0 a 100**
  - faixas visuais de risco com cores (verde → amarelo → laranja → vermelho)
  - data da última atualização

- **Transparência do cálculo**
  - Bottom Sheet explicando a fórmula utilizada
  - detalhamento dos fatores que impactam o score (quantidade de eventos por severidade e recência)

- **Listagem de eventos**
  - exibição de eventos internacionais recentes em cards
  - pill de severidade com cor
  - país inferido, data e palavras-chave detectadas

- **Detalhes do evento**
  - resumo completo do evento
  - fonte/origem com link selecionável
  - impacto individual do evento no score global
  - palavras-chave detectadas em chips

- **Filtros**
  - filtro por país (inferido a partir do idioma do artigo)
  - filtro por severidade (Crítico, Moderado, Baixo)
  - persistência dos filtros no Firestore

- **Persistência com Cloud Firestore**
  - favoritos por usuário (`users/{uid}/favorites/{eventId}`)
  - histórico de consultas por UID (`users/{uid}/history/{autoId}`)
  - preferências de filtro por UID (`users/{uid}/preferences/profile`)

## API utilizada — Currents API

| Item | Detalhe |
|------|---------|
| **URL base** | `https://api.currentsapi.services/v1/search` |
| **Documentação** | https://currentsapi.services/en/docs/ |
| **Plano** | Gratuito — 1.000 requisições/dia |
| **Motivo da escolha** | JSON padronizado, filtro por palavras-chave e idioma, sem restrição de ambiente, cobertura de 60+ países |

### Campos aproveitados

| Campo da API | Uso no app |
|---|---|
| `title` | Título do evento |
| `description` | Resumo + base para classificar severidade |
| `url` | Link da fonte original |
| `author` | Nome do veículo de notícia |
| `published` | Data de publicação |
| `category` | Proxy para região geográfica |
| `language` | Inferência de país |

### Limitações da API

- Sem campo de país direto (heurística por idioma)
- Sem análise de sentimento/tom
- Formato de data não padrão ISO (parsing alternativo implementado)
- Limite de 1.000 requisições/dia no plano gratuito

## Regra de cálculo do score

A lógica de score converte volume, severidade e recência dos eventos em uma escala de risco global.

### Classificação de severidade

| Severidade | Palavras-chave | Peso |
|---|---|---|
| **Crítico** | nuclear, missile, invasion, chemical, mobilization, war, attack, sanction, retaliation | 3 |
| **Moderado** | conflict, troops, military, border, ceasefire, summit, security, protest, drone | 2 |
| **Baixo** | Nenhuma das anteriores | 1 |

### Fórmula

```text
Score bruto =
  (críticos × 3) +
  (moderados × 2) +
  (baixos × 1) +
  (críticos nas últimas 12h × 2)

Score final = mínimo(100, score bruto × 4)
```

### Faixas de risco

| Score | Nível | Cor |
|---|---|---|
| 0–20 | Baixo | 🟢 Verde |
| 21–40 | Moderado | 🟡 Amarelo |
| 41–60 | Alto | 🟠 Laranja |
| 61–80 | Muito alto | 🔴 Vermelho escuro |
| 81–100 | Crítico | 🔴 Vermelho |

## Arquitetura

O projeto segue o padrão **MVC** conforme solicitado na atividade.

```text
lib/
├── controllers/
│   ├── auth_controller.dart        ← gerencia autenticação
│   ├── event_controller.dart       ← orquestra API, filtros, favoritos
│   └── score_controller.dart       ← calcula e expõe o score
├── models/
│   ├── event_model.dart            ← entidade de evento (toMap/fromMap)
│   └── user_preferences_model.dart ← preferências do usuário
├── services/
│   ├── api_service.dart            ← consumo da Currents API
│   ├── auth_service.dart           ← wrapper do Firebase Auth
│   └── firestore_service.dart      ← wrapper do Cloud Firestore
├── views/
│   ├── login_view.dart             ← tela de login/cadastro
│   ├── home_view.dart              ← dashboard com score + eventos
│   ├── details_view.dart           ← detalhes de um evento
│   └── favorites_view.dart         ← lista de favoritos (stream)
├── firebase_options.dart
└── main.dart
```

## Tecnologias utilizadas

- **Flutter** / **Dart**
- **Firebase Authentication** (e-mail e senha)
- **Cloud Firestore** (persistência por usuário)
- **Currents API** (dados de crises internacionais)
- **Provider** (gerenciamento de estado)
- **HTTP** (requisições REST)
- **Intl** (formatação de datas)

## Persistência no Firestore

A estrutura usada no Firestore segue o UID do usuário autenticado:

```text
users/{uid}/favorites/{eventId}     → eventos favoritados
users/{uid}/history/{autoId}        → histórico de buscas
users/{uid}/preferences/profile     → filtros salvos
```

## Regras de segurança

As regras do Firestore foram definidas para permitir que cada usuário autenticado acesse apenas os seus próprios dados:

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Como executar o projeto

### 1. Instalar dependências

```bash
flutter pub get
```

### 2. Executar análise estática

```bash
flutter analyze
```

### 3. Rodar os testes

```bash
flutter test
```

### 4. Executar no Android

```bash
flutter run
```

## Observações sobre Firebase

O projeto já está preparado para uso com Firebase no Android.

Para autenticação e persistência em ambiente real, é necessário que o projeto Firebase conectado esteja ativo com:

- **Authentication > Email/Password** habilitado
- **Cloud Firestore** habilitado
- `google-services.json` configurado no app Android

O aplicativo é **resiliente a falhas de Firebase**: caso o serviço esteja indisponível, o consumo da API e a visualização de eventos continuam funcionando normalmente.

## Status atual do projeto

- ✅ Estrutura MVC implementada
- ✅ Firebase Auth integrado (login, cadastro, logout)
- ✅ Cloud Firestore integrado (favoritos, histórico, preferências)
- ✅ Consumo da Currents API implementado
- ✅ Dashboard com score de risco implementado
- ✅ Explicação transparente do cálculo do score
- ✅ Filtros por país e severidade
- ✅ Tela de detalhes com impacto no score
- ✅ Tela de favoritos com stream em tempo real
- ✅ Tratamento de loading, erro e ausência de dados
- ✅ Tratamento de falha de conexão e limite da API

## Objetivo acadêmico

Este aplicativo foi desenvolvido como atividade prática da disciplina **Programação Mobile II** com foco em:

- Integração entre Flutter e Firebase (Auth + Firestore)
- Organização arquitetural em MVC
- Consumo de API externa gratuita (Currents API)
- Persistência de dados por usuário
- Visualização didática de eventos geopolíticos em formato de dashboard
- Cálculo transparente de score de risco

## Autor

Projeto desenvolvido para a atividade **Relógio do Apocalipse** — IFRO Campus Ariquemes.