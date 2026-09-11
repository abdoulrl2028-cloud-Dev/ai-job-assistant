# AI Job Assistant

Application Flutter de suivi de candidatures et de profil technique pour la recherche d'emploi.

## Fonctionnalites

- Tableau de bord avec suivi des candidatures et des actions hebdomadaires.
- Profil technique avec competences Cloud, CI/CD, tests, Docker, PostgreSQL, observabilite et architecture evenementielle.
- Navigation pour les candidatures, les documents et le profil.

## Executer

```bash
flutter pub get
flutter run -d chrome --dart-define-from-file=config/app_config.json
```

Copiez `config/app_config.json.example` vers `config/app_config.json` et preencha apenas a URL e a chave publicavel do Supabase. Nao envie esse arquivo ao Git. As chaves Stripe e a service role do Supabase pertencem apenas aos segredos das Edge Functions.

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
