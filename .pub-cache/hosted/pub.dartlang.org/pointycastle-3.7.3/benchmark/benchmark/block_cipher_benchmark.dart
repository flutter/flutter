// See file LICENSE for more information.

library benchmark.benchmark.block_cipher_benchmark;

import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';

import '../benchmark/rate_benchmark.dart';

typedef CipherParametersFactory = CipherParameters Function();

class BlockCipherBenchmark extends RateBenchmark {
  final String _blockCipherName;
  final bool _forEncryption;
  final CipherParametersFactory _cipherParametersFactory;
  Uint8List? _data;

  late BlockCipher _blockCipher;

  BlockCipherBenchmark(String blockCipherName, String blockCipherVariant,
      bool forEncryption, this._cipherParametersFactory)
      : _blockCipherName = blockCipherName,
        _forEncryption = forEncryption,
        super('BlockCipher | $blockCipherName - $blockCipherVariant - '
            '${forEncryption ? 'encrypt' : 'decrypt'}');

  @override
  void setup() {
    _blockCipher = BlockCipher(_blockCipherName);
    _blockCipher.init(_forEncryption, _cipherParametersFactory());
    _data = Uint8List(_blockCipher.blockSize);
  }

  @override
  void run() {
    _blockCipher.process(_data!);
    addSample(_data!.length);
  }
}
