@JS()
import 'dart:math';
import 'dart:typed_data';

import 'package:js/js.dart';
import 'package:pointycastle/src/impl/entropy.dart';

import 'node_crypto.dart';
import 'platform_check.dart';

class PlatformWeb extends Platform {
  static final PlatformWeb instance = PlatformWeb();
  static bool useBuiltInRng = false;

  PlatformWeb() {
    try {
      Random.secure();
      useBuiltInRng = true;
    } on UnsupportedError {
      useBuiltInRng = false;
    }
  }

  @override
  bool get isNative => false;

  @override
  String get platform => 'web';

  @override
  EntropySource platformEntropySource() {
    if (useBuiltInRng) {
      return _JsBuiltInEntropySource();
    } else {
      //
      // Assume that if we cannot get a built in Secure RNG then we are
      // probably on NodeJS.
      //
      return _JsNodeEntropySource();
    }
  }
}

// Uses the built in entropy source
class _JsBuiltInEntropySource implements EntropySource {
  final _src = Random.secure();

  @override
  Uint8List getBytes(int len) {
    return Uint8List.fromList(
        List<int>.generate(len, (i) => _src.nextInt(256)));
  }
}

///
class _JsNodeEntropySource implements EntropySource {
  @override
  Uint8List getBytes(int len) {
    NodeCrypto j = require('crypto');
    var list = Uint8List(len);
    j.randomFillSync(list);
    return list;
  }
}

Platform getPlatform() => PlatformWeb.instance;
