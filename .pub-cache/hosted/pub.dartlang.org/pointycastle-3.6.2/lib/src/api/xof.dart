part of api;

abstract class Xof extends Digest {
  /// Create the Xof specified by the standard [algorithmName].
  factory Xof(String algorithmName) => registry.create<Xof>(algorithmName);

  ///
  int doFinalRange(Uint8List out, int outOff, int outLen);

  int doOutput(Uint8List out, int outOff, int outLen);
}
