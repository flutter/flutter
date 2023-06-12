import 'package:sqflite_common/src/platform/platform.dart';

class _PlatformWeb extends Platform {
  @override
  bool get isWeb => false;
}

/// Platform (Web)
final platform = _PlatformWeb();
