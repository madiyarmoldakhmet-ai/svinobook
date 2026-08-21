# Contributing

## Development

1. Run `flutter pub get`.
2. Keep application logic in `lib/services/` and presentation in `lib/views/` or `lib/widgets/`.
3. Prefer `const` constructors and stable keys for repeated list items.
4. Use `package:svinobook/...` imports for shared project files.

## Validation

Before opening a pull request, run:

```bash
flutter analyze
flutter test
flutter build web --release
```

Add a focused unit or widget test for every behavior change. Do not commit `build/`, `.dart_tool/`, or `coverage/` artifacts.
