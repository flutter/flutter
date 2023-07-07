// See file LICENSE for more information.

part of api;

/// This kind of exception is thrown when a user tries to create an algorithm
/// or domain parameters that were not correctly registered. This can be
/// because the corresponding class was not imported, or because the algorithm
/// does not exist.
class RegistryFactoryException implements Exception {
  final String message;

  RegistryFactoryException(this.message);

  RegistryFactoryException.unknown(String algorithm, [Type? type])
      : this('No algorithm registered' +
            (type != null ? ' of type $type' : '') +
            ' with name: $algorithm');

  RegistryFactoryException.invalid(String algorithm, [Type? type])
      : this('Algorithm name $algorithm is invalid' +
            (type != null ? ' of type $type' : ''));

  @override
  String toString() => 'RegistryFactoryException: $message';
}
