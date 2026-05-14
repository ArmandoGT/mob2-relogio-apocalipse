# Relógio do Apocalipse

Aplicativo mobile educativo desenvolvido em **Flutter + Firebase** para monitoramento de crises e conflitos internacionais, com foco em visualização de risco global, consulta de eventos recentes, filtros, autenticação e persistência de favoritos.

## Visão geral

O **Relógio do Apocalipse** apresenta um painel com eventos internacionais recentes obtidos por API pública, calcula um **score global de risco de 0 a 100** e exibe esse resultado de forma clara para o usuário.

A proposta do aplicativo é transformar dados abertos sobre conflitos, tensões geopolíticas e escaladas militares em uma visualização simples, didática e interativa.

## Funcionalidades implementadas

- **Autenticação com Firebase**
  - cadastro de usuário
  - login
  - logout

- **Consumo de API internacional**
  - integração com a API pública do **GDELT**
  - carregamento de eventos recentes das últimas 48 horas
  - tratamento de loading, erro e ausência de conexão

- **Dashboard principal**
  - score de risco global de **0 a 100**
  - faixas visuais de risco com cores
  - data da última atualização

- **Transparência do cálculo**
  - modal explicando a fórmula usada
  - detalhamento dos fatores que impactam o score

- **Listagem de eventos**
  - exibição de eventos internacionais recentes
  - severidade visual
  - país, data e palavras-chave

- **Detalhes do evento**
  - resumo do evento
  - fonte/origem
  - impacto do evento no score global

- **Filtros**
  - filtro por país
  - filtro por severidade

- **Persistência com Cloud Firestore**
  - favoritos por usuário
  - histórico de consultas por UID
  - preferências de filtro por UID

## Regra de cálculo do score

A lógica de score foi implementada para converter volume, severidade e recência dos eventos em uma escala de risco global.

### Fórmula utilizada

```text
Score bruto =
(críticos × 3) +
(moderados × 2) +
(baixos × 1) +
(críticos nas últimas 12h × 2)

Score final = mínimo(100, score bruto × 4)
```

### Faixas de risco

- **0 a 20** → Baixo
- **21 a 40** → Moderado
- **41 a 60** → Alto
- **61 a 80** → Muito alto
- **81 a 100** → Crítico

## Arquitetura

O projeto segue o padrão **MVC** conforme solicitado na atividade.

```text
lib/
├── controllers/
│   ├── auth_controller.dart
│   ├── event_controller.dart
│   └── score_controller.dart
├── models/
│   ├── event_model.dart
│   └── user_preferences_model.dart
├── services/
│   ├── api_service.dart
│   ├── auth_service.dart
│   └── firestore_service.dart
├── views/
│   ├── details_view.dart
│   ├── favorites_view.dart
│   ├── home_view.dart
│   └── login_view.dart
├── firebase_options.dart
└── main.dart
```

## Tecnologias utilizadas

- **Flutter**
- **Dart**
- **Firebase Authentication**
- **Cloud Firestore**
- **HTTP**
- **Provider**
- **Intl**

## Persistência no Firestore

A estrutura usada no Firestore segue o UID do usuário autenticado:

```text
users/{uid}/favorites/{eventId}
users/{uid}/history/{historyId}
users/{uid}/preferences/profile
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

## Status atual do projeto

- Estrutura MVC implementada
- Firebase integrado ao projeto
- Consumo de API implementado
- Dashboard com score implementado
- Filtros, detalhes e favoritos implementados
- `flutter analyze` sem issues
- `flutter test` passando

## Objetivo acadêmico

Este aplicativo foi desenvolvido como atividade prática com foco em:

- integração entre Flutter e Firebase
- organização arquitetural em MVC
- consumo de API externa
- persistência de dados por usuário
- visualização didática de eventos geopolíticos em formato de dashboard

## Autor

Projeto desenvolvido para a atividade **Relógio do Apocalipse**.