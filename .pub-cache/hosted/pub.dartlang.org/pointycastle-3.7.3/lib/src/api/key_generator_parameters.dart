// See file LICENSE for more information.

part of api;

/// Abstract [CipherParameters] to init an asymmetric key generator.
abstract class KeyGeneratorParameters implements CipherParameters {
  final int bitStrength;

  KeyGeneratorParameters(this.bitStrength);
}
