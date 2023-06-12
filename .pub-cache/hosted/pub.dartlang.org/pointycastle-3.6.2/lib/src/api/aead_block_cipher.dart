part of '../../api.dart';

/// A block cipher mode that includes authenticated encryption
abstract class AEADBlockCipher extends BlockCipher {
  factory AEADBlockCipher(String algorithmName) =>
      registry.create<AEADBlockCipher>(algorithmName);

  /// Process [len] bytes from [inp] starting at offset [inpOff] and output the
  /// result to [out] at offset [outOff].
  ///
  /// Returns the number of bytes written to the output.
  int processBytes(
      Uint8List inp, int inpOff, int len, Uint8List out, int outOff);

  /// Finish the operation either appending or verifying the MAC at the end of
  /// the data.
  ///
  /// Returns the number of bytes written to the output.
  int doFinal(Uint8List out, int outOff);
}

class InvalidCipherTextException implements Exception {
  final String message;

  InvalidCipherTextException(this.message);
}
