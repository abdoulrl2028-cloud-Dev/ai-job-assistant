<p align="center">
  <img src="https://raw.githubusercontent.com/abdoulrl2028-cloud-Dev/abdoulrl2028-cloud-Dev/main/assets/projects/ai-jobs.jpg" alt="AI Job Assistant" width="100%">
</p>

# AI Job Assistant

International Flutter app for finding jobs, keeping resumes private, tracking applications, and preparing AI flows on the backend.

## Features

- Supabase authentication and per-user access control (RLS).
- Real jobs synced on the backend from the authorized Remotive API, with cache, deduplication, and Realtime.
- Text search and workplace filters, a paginated list, and details with the official application link.
- PDF and DOCX resumes in a private bucket, with type and size checks and stored metadata.
- Applications, saved jobs, interviews, messages, notifications, audit records, plans, and subscriptions modeled in the database.

## Run

```bash
flutter pub get
flutter run -d chrome --dart-define-from-file=config/app_config.json
```

Copy `config/app_config.json.example` to `config/app_config.json` and fill in only the public Supabase URL and key. Do not commit that file.

## Backend

1. Create a Supabase project. Set the redirect URL `com.aijobassistant.ai_job_assistant://` for Android and iOS, and the HTTPS URL for web.
2. Run every migration in `supabase/migrations/` with the Supabase CLI or the SQL editor. They create tables, indexes, RLS, Realtime, and the private `user-resumes` bucket.
3. Copy `supabase/.env.example` to `supabase/.env` and fill secrets only in the deploy environment. Never put `SUPABASE_SERVICE_ROLE_KEY`, `STRIPE_SECRET_KEY`, `JOB_SYNC_SECRET`, or an AI key in the Flutter app.
4. Deploy the Edge Functions: `create-checkout`, `customer-portal`, `stripe-webhook`, and `sync-remotive-jobs`.
5. Point the Stripe webhook at `stripe-webhook`. The webhook, not the frontend, updates the subscription.
6. Run `sync-remotive-jobs` from a secure scheduler every hour, sending the `x-sync-secret` header. The function upserts jobs by source and external id and refreshes the cache.

The database publishes Realtime events for jobs, applications, subscriptions, messages, interviews, and notifications. Flutter reads jobs and applications from Supabase streams.

## Features that need an external provider

- Structured PDF/DOCX extraction and an estimated match score: an Edge Function calls the chosen AI provider with `AI_PROVIDER_API_KEY`. Save the result in `resume_analysis` and label it as an estimate.
- The `analyze-resume` Edge Function already compares an authenticated `resumeId` and `jobId`, checks ownership, never exposes the key to Flutter, and stores the estimated review. Set `AI_BASE_URL`, `AI_MODEL`, and `AI_PROVIDER_API_KEY` before deploying it.
- A dynamic interview, scoring, and PDF report run on the backend and are stored in `interviews`, `interview_questions`, `interview_answers`, and `interview_reports`.
- Email: use an authorized transactional provider, and send only after the user confirms.
- WhatsApp: use only the official WhatsApp Business API, with opt-in and per-message authorization. Do not send messages automatically.

## Platform builds

```bash
flutter build apk --release
flutter build appbundle --release
flutter build web --release --dart-define-from-file=config/app_config.json
flutter build linux --release
flutter build windows --release
flutter build macos --release
flutter build ipa --release
```

Android and web can be built on Ubuntu. The Linux build needs `libgtk-3-dev`. Windows requires Windows. macOS, iOS, iPadOS, and watchOS require macOS, Xcode, and Apple certificates. Apple Watch should be a native watchOS extension in Swift that uses the same Supabase backend. Wear OS should be a separate Android module.

## Check

```bash
flutter analyze
flutter test
```
