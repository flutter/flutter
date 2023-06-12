// See file LICENSE for more information.

library benchmark.benchmark.signer_benchmark;

import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';

import '../benchmark/rate_benchmark.dart';

typedef CipherParametersFactory = CipherParameters Function();

class SignerBenchmark extends RateBenchmark {
  final String _signerName;
  final Uint8List _data;
  final CipherParametersFactory _cipherParametersFactory;
  final bool _forSigning;

  late Signer _signer;

  SignerBenchmark(
      String signerName, bool forSigning, this._cipherParametersFactory,
      [int dataLength = 1024 * 1024])
      : _signerName = signerName,
        _forSigning = forSigning,
        _data = Uint8List(dataLength),
        super('Signer | $signerName - ${forSigning ? 'sign' : 'verify'}');

  @override
  void setup() {
    _signer = Signer(_signerName);
    _signer.init(_forSigning, _cipherParametersFactory());
  }

  @override
  void run() {
    _signer.generateSignature(_data);
    addSample(_data.length);
  }
}
