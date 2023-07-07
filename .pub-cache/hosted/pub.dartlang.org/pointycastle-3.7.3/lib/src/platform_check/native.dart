import 'dart:io' as io;
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/src/impl/entropy.dart';

import 'platform_check.dart';

class PlatformIO extends Platform {
  static final PlatformIO instance = PlatformIO();

  const PlatformIO();

  @override
  String get platform {
    if (io.Platform.isAndroid) return 'Android';
    if (io.Platform.isIOS) return 'iOS';
    if (io.Platform.isWindows) return 'Windows';
    if (io.Platform.isLinux) return 'Linux';
    if (io.Platform.isFuchsia) return 'Fuchsia';
    if (io.Platform.isMacOS) return 'MacOS';

    return 'native';
  }

  @override
  bool get isNative => true;

  @override
  EntropySource platformEntropySource() {
    return _NativeRngProvider();
  }
}

class _NativeRngProvider implements EntropySource {
  final _src = Random.secure();

  @override
  Uint8List getBytes(int len) {
    return Uint8List.fromList(
        List<int>.generate(len, (i) => _src.nextInt(256)));
  }
}

Platform getPlatform() => PlatformIO.instance;
