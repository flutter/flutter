// See file LICENSE for more information.

part of api;

/// Abstract [CipherParameters] to hold an asymmetric (public or private) key
abstract class AsymmetricKeyParameter<T extends AsymmetricKey>
    implements CipherParameters {
  final T key;

  AsymmetricKeyParameter(this.key);
}
