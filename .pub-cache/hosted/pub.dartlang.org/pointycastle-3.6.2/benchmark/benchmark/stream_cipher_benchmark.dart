// See file LICENSE for more information.

library benchmark.benchmark.stream_cipher_benchmark;

import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';

import '../benchmark/rate_benchmark.dart';

typedef CipherParametersFactory = CipherParameters Function();

class StreamCipherBenchmark extends RateBenchmark {
  final String _streamCipherName;
  final bool _forEncryption;
  final CipherParametersFactory _cipherParametersFactory;
  final Uint8List _data;

  late StreamCipher _streamCipher;

  StreamCipherBenchmark(String streamCipherName, String? streamCipherVariant,
      bool forEncryption, this._cipherParametersFactory,
      [int dataLength = 1024 * 1024])
      : _streamCipherName = streamCipherName,
        _forEncryption = forEncryption,
        _data = Uint8List(dataLength),
        super(
            'StreamCipher | $streamCipherName ${_formatVariant(streamCipherVariant)}- '
            '${forEncryption ? 'encrypt' : 'decrypt'}');

  @override
  void setup() {
    _streamCipher = StreamCipher(_streamCipherName);
    _streamCipher.init(_forEncryption, _cipherParametersFactory());
  }

  @override
  void run() {
    _streamCipher.process(_data);
    addSample(_data.length);
  }
}

String _formatVariant(String? streamCipherVariant) {
  if (streamCipherVariant == null) {
    return '';
  } else {
    return '- $streamCipherVariant ';
  }
}
