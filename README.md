# AI Job Assistant

Plataforma Flutter internacional para encontrar vagas, manter CVs privados, acompanhar candidaturas e preparar fluxos de IA no backend.

## Fonctionnalites

- Autenticacao Supabase e controle de acesso por usuario (RLS).
- Vagas reais sincronizadas no backend a partir da API autorizada Remotive, com cache, deduplicacao e Realtime.
- Pesquisa por texto e filtros de modalidade; lista paginada e detalhes com link oficial de candidatura.
- CVs PDF/DOCX em bucket privado com validacao de tipo/tamanho e registro de metadados.
- Candidaturas, vagas salvas, entrevistas, mensagens, notificacoes, auditoria, planos e assinaturas modelados no banco.

## Executer

```bash
flutter pub get
flutter run -d chrome --dart-define-from-file=config/app_config.json
```

Copie `config/app_config.json.example` para `config/app_config.json` e preencha apenas a URL e a chave publicavel do Supabase. Nao envie esse arquivo ao Git.

## Configurar backend

1. Crie um projeto Supabase e configure a URL de redirecionamento `com.aijobassistant.ai_job_assistant://` para Android/iOS e a URL HTTPS do Web.
2. Execute todas as migracoes em `supabase/migrations/` usando Supabase CLI ou SQL Editor. Elas criam tabelas, indices, RLS, Realtime e o bucket privado `user-resumes`.
3. Copie `supabase/.env.example` para `supabase/.env` e preencha os segredos somente no ambiente de deploy. Nunca use `SUPABASE_SERVICE_ROLE_KEY`, `STRIPE_SECRET_KEY`, `JOB_SYNC_SECRET` ou chave de IA no Flutter.
4. Implante as Edge Functions: `create-checkout`, `customer-portal`, `stripe-webhook` e `sync-remotive-jobs`.
5. Configure o webhook Stripe para a URL de `stripe-webhook`. O webhook, e nao o frontend, atualiza a assinatura.
6. Execute `sync-remotive-jobs` de um agendador seguro a cada hora, enviando o cabeçalho `x-sync-secret`. A funcao usa Remotive, faz upsert por fonte/ID externo e atualiza o cache de vagas.

O banco publica eventos Realtime para vagas, candidaturas, assinaturas, mensagens, entrevistas e notificacoes. O Flutter consome vagas e candidaturas por streams Supabase sem polling manual.

## Recursos que exigem provedores externos

- Extracao estruturada de PDF/DOCX e analise de compatibilidade estimada: implemente uma Edge Function que chama o provedor de IA escolhido com `AI_PROVIDER_API_KEY`. O resultado deve ser salvo em `resume_analysis` e rotulado como estimativa.
- A Edge Function `analyze-resume` ja implementa a comparacao autenticada `resumeId`/`jobId`, valida a propriedade do CV, nunca expoe a chave ao Flutter e persiste a avaliacao estimada. Configure `AI_BASE_URL`, `AI_MODEL` e `AI_PROVIDER_API_KEY` antes de implanta-la.
- Entrevista dinamica, avaliacao e relatorio PDF: execute no backend e grave em `interviews`, `interview_questions`, `interview_answers` e `interview_reports`.
- E-mail: use um provedor transacional autorizado, com envio somente apos confirmacao explicita do usuario.
- WhatsApp: use exclusivamente a API oficial WhatsApp Business, com opt-in e autorizacao por mensagem; nunca envie automaticamente.

## Builds por plataforma

```bash
flutter build apk --release
flutter build appbundle --release
flutter build web --release --dart-define-from-file=config/app_config.json
flutter build linux --release
flutter build windows --release
flutter build macos --release
flutter build ipa --release
```

Android e Web podem ser gerados neste Ubuntu. O build Linux requer `libgtk-3-dev`. Windows exige Windows; macOS, iOS/iPadOS e watchOS exigem macOS, Xcode e certificados Apple. O Apple Watch deve ser criado como extensao watchOS nativa em Swift, consumindo o mesmo backend Supabase, e o Wear OS como modulo Android separado.

## Verifier

```bash
flutter analyze
flutter test
```
