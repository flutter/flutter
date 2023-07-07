import 'package:pointycastle/src/impl/entropy.dart';

import 'abstract.dart'
    if (dart.library.io) 'native.dart'
    if (dart.library.js) 'web.dart';

abstract class Platform {
  static Platform get instance => getPlatform();
  static const bool _fwInteger = 9007199254740992 + 1 != 9007199254740992;

  const Platform();

  String get platform;

  bool get isNative;

  bool get fullWidthInteger => _fwInteger;

  void assertFullWidthInteger() {
    if (!_fwInteger) {
      throw PlatformException(
          'full width integer not supported on this platform');
    }
  }

  /// Platform dependent entropy source.
  EntropySource platformEntropySource();
}

class PlatformException implements Exception {
  String cause;

  PlatformException(this.cause);

  @override
  String toString() => cause;
}
