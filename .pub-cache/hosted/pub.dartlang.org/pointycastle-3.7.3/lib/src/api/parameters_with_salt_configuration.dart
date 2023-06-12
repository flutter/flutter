// See file LICENSE for more information.

part of api;

/// [CipherParameters] consisting of an underlying [CipherParameters] (of type
/// [UnderlyingParameters]), an acompanying [SecureRandom], and salt length.
class ParametersWithSaltConfiguration<
    UnderlyingParameters extends CipherParameters> implements CipherParameters {
  final UnderlyingParameters parameters;
  final SecureRandom random;
  final int saltLength;

  ParametersWithSaltConfiguration(
      this.parameters, this.random, this.saltLength);
}
