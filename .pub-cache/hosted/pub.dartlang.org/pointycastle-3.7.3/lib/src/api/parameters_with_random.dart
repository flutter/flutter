// See file LICENSE for more information.

part of api;

//TODO consider mixin
/// [CipherParameters] consisting of an underlying [CipherParameters] (of type
/// [UnderlyingParameters]) and an acompanying [SecureRandom].
class ParametersWithRandom<UnderlyingParameters extends CipherParameters>
    implements CipherParameters {
  final UnderlyingParameters parameters;
  final SecureRandom random;

  ParametersWithRandom(this.parameters, this.random);
}
