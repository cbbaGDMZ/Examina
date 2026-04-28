# Examina - Corrector Óptico de Exámenes

## Project Type
- Flutter app (Android/iOS/Web)
- Phase 1: Scanner with corner marker detection & image processing
- Phase 2: OMR (Optical Mark Recognition)

## Key Dependencies
- `google_mlkit_document_scanner` - Document scanning
- `image` - Image processing (crop, resize, filters)
- `sqflite` - Local database (planea migrar a Isar)
- `flutter_riverpod` - State management

## Architecture
```
lib/
├── main.dart              # Entry point
├── modelos/              # Data models (Examen, Resultado, HojaPatron, etc.)
├── pantallas/            # UI screens
├── servicios/            # Business logic (OMR, camera, image processing)
└── estado/              # State management
```

## Run Commands

```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter run -d <device_id>

# List devices
flutter devices

# Launch emulator
flutter emulators --launch <emulator_id>

# Build APK
flutter build apk --debug

# Analyze code
flutter analyze
```

## Important Notes

- **Android NDK issue**: If build fails with NDK error, delete `/home/matius/Android/Sdk/ndk/` folder and rebuild
- **Google ML Kit Document Scanner**: Requires real device for full testing (camera doesn't work in emulator)
- **Image encoding**: Uses `image` package - `encodeJpg` returns `List<int>`, convert to `Uint8List` when needed
- **Puntaje Fijo navigation**: Currently configured to navigate to `/escaneo` on valid form submission
- **Puntaje Variado**: Not implemented, focused only on puntaje fijo flow
- **SQLite**: Currently used but user plans to migrate to Isar

## Current Phase

**Phase 1 - Scanner Pipeline:**
- Scanner with Google ML Kit
- 4 corner marker detection (black squares at corners)
- Perspective correction
- Geometric validation
- Quality check (brightness, contrast, blur)
- Image normalization (800x1200)
- Re-scan flow (max 3 attempts)

## Testing

For full testing, use physical Android device with camera:
1. Enable developer options → tap 7x on build number
2. Enable USB debugging
3. Connect device via USB
4. Authorize computer on device
5. Run `flutter run`