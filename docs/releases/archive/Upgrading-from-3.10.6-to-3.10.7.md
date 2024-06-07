Because of the serious performance regression that was introduced with iOS 16.6 ([#131319](https://github.com/flutter/flutter/issues/131319)), a one-time special hotfix was made for the older release 3.10.6 even though a newer stable release was available ([3.13.0](https://docs.flutter.dev/release/archive)). While it is recommended that most users upgrade to the newest release on their current channel via `flutter upgrade`, for users who cannot upgrade their Flutter version for other reasons, can issue the following terminal commands in their Flutter SDK checkout:

```
git fetch --tags
git checkout 3.10.7
flutter --version
```