Dart SDK dependency
===================

The Dart SDK is downloaded from one of [the supported channels](https://www.dartlang.org/install/archive),
cached in `bin/cache/dart-sdk` and is used to run Flutter Dart code.

The file `bin/internal/dart-sdk.version` determines the version of Dart SDK
that will be downloaded. Normally it points to the `dev` channel (for example,
`1.24.0-dev.6.7`), but it can also point to particular bleeding edge build
of Dart (for example, `hash/c0617d20158955d99d6447036237fe2639ba088c`).