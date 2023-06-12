# sqflite common

This package is not intended for direct use.
* See [sqflite](https://pub.dev/packages/sqflite) for flutter mobile
* See [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) for Desktop
and unit test

One exception to import `sqflite_common/sqlite_api.dart` is that you have logic
which is shared across Flutter apps and desktop binaries, and you want to make
your shared logic platform-agnostic. In this case, you can import the
`sqflite_common/sqlite_api.dart` directly in your Dart package for shared logic
and import it in your platform-dependent packages (e.g. using
[sqflite](https://pub.dev/packages/sqflite) for Flutter apps and
[sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) for desktop
binaries).
