# Build Runner Instructions

## Step 1: Install Dependencies
```bash
flutter pub get
```

## Step 2: Run Code Generation
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate the following files:
- `lib/core/errors/failures.freezed.dart`
- `lib/core/utils/result.freezed.dart`
- `lib/data/models/user_model.g.dart`
- `lib/data/models/product_model.g.dart`
- `lib/data/models/field_model.g.dart`
- `lib/data/models/task_model.g.dart`

## Step 3: Watch Mode (Optional)
For development, you can use watch mode to automatically regenerate files:
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Troubleshooting

### If build_runner fails:
1. Clean the project:
   ```bash
   flutter clean
   flutter pub get
   ```

2. Delete generated files manually:
   ```bash
   find . -name "*.g.dart" -delete
   find . -name "*.freezed.dart" -delete
   ```

3. Run build_runner again:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

### Common Issues:
- **"Part file not found"**: Make sure all part directives are correct
- **"Type not found"**: Run `flutter pub get` first
- **"Conflicting outputs"**: Use `--delete-conflicting-outputs` flag

## After Code Generation

Once code generation is complete, you can:
1. Run the app: `flutter run`
2. Check for errors: `flutter analyze`
3. Test the app functionality

