This folder is reserved for Drift table definitions.

Recommended next step after Flutter and Dart tooling are installed:

1. Create `app_database.dart` with a Drift `@DriftDatabase` annotation.
2. Split table declarations into one file per table.
3. Run:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

The SQL blueprint for V1 currently lives in:

- `lib/data/local/db/schema_v1.sql`
