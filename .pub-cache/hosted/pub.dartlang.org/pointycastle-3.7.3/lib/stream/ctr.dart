// See file LICENSE for more information.

library impl.stream_cipher.ctr;

import 'package:pointycastle/api.dart';
import 'package:pointycastle/stream/sic.dart';
import 'package:pointycastle/src/registry/registry.dart';

/// Just an alias to be able to create SIC as CTR
class CTRStreamCipher extends SICStreamCipher {
  /// Intended for internal use.
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.suffix(
      StreamCipher,
      '/CTR',
      (_, final Match match) => () {
            var digestName = match.group(1);
            return CTRStreamCipher(BlockCipher(digestName!));
          });

  CTRStreamCipher(BlockCipher underlyingCipher) : super(underlyingCipher);
  @override
  String get algorithmName => '${underlyingCipher.algorithmName}/CTR';
}
