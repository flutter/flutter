## To run the Hello World demo:
```sh
flutter run
```
## To run the Hello World demo showing Arabic:
```sh
flutter run lib/arabic.dart
```

## Hurtig simulator-flow (iOS + Android)
Kør via VS Code Tasks:
- `Flutter: List devices`
- `Flutter: Precache iOS + Android`
- `Flutter: Run iOS (smart)`
- `Flutter: Run Android (smart)`

De to "smart" tasks finder automatisk første tilgængelige simulator/emulator.

Alternativt i terminal:
```sh
bash tool/run_ios.sh
bash tool/run_android.sh
```

## One-click debug i VS Code
I **Run and Debug** kan du nu vælge:
- `Flutter: iOS (iPhone 17 Pro)`
- `Flutter: Android (select device)`
- `Flutter: Profile (selected device)`

Tryk `F5` for at starte den valgte profil.
