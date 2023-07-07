// See file LICENSE for more information.

part of api;

/// [CipherParameters] consisting of an underlying [CipherParameters] (of type [UnderlyingParameters]) and an initialization
/// vector of arbitrary length.
class ParametersWithIV<UnderlyingParameters extends CipherParameters?>
    implements CipherParameters {
  final Uint8List iv;
  final UnderlyingParameters? parameters;

  ParametersWithIV(this.parameters, this.iv);
}
