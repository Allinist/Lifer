# Lifer

Lifer is a local-first product tracker for:

- price history
- stock batches
- expiry reminders
- durable usage cycles
- notes and future Obsidian integration

## Current status

This repository now contains:

- product, technical, database, and Flutter architecture docs in `docs/`
- a Flutter app skeleton under `lib/`
- a V1 SQL schema at `lib/data/local/db/schema_v1.sql`

## Next steps

1. Install Flutter SDK and ensure `flutter` is available in PATH.
2. Run `flutter pub get`.
3. Add Drift table definitions and generate code.
4. Start wiring repositories, providers, and feature forms.

## Planned stack

- Flutter
- Riverpod
- go_router
- Drift + SQLite
- flutter_local_notifications
