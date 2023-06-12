// See file LICENSE for more information.

part of api;

/// [CipherParameters] consisting of an underlying [CipherParameters] (of type
/// [UnderlyingParameters]) and an acompanying salt of type [Uint8List].
class ParametersWithSalt<UnderlyingParameters extends CipherParameters>
    implements CipherParameters {
  final UnderlyingParameters parameters;
  final Uint8List salt;

  ParametersWithSalt(this.parameters, this.salt);
}
