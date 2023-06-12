export 'platform_io.dart' if (dart.library.js) 'platform_web.dart';

/// IO/web support
abstract class Platform {
  /// True if web
  bool get isWeb => false;

  /// True if IO windows
  bool get isWindows => false;

  /// True if IO ios
  bool get isIOS => false;

  /// True if IO Android
  bool get isAndroid => false;

  /// True if IO Linux
  bool get isLinux => false;

  /// True if IO MacOS
  bool get isMacOS => false;
}
