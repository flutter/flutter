import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/src/impl/entropy.dart';

import 'platform_check.dart';

class PlatformGeneric extends Platform {
  static final PlatformGeneric instance = PlatformGeneric();

  const PlatformGeneric();

  @override
  bool get isNative => false;

  @override
  String get platform => 'generic';

  @override
  EntropySource platformEntropySource() {
    return _genericEntropySource();
  }
}

Platform getPlatform() => PlatformGeneric.instance;

// Uses the built in entropy source
class _genericEntropySource implements EntropySource {
  final _src = Random.secure();

  @override
  Uint8List getBytes(int len) {
    return Uint8List.fromList(
        List<int>.generate(len, (i) => _src.nextInt(256)));
  }
}
