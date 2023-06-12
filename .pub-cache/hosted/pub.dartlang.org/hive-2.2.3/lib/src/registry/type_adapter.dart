part of hive;

/// Type adapters can be implemented to support non primitive values.
@immutable
abstract class TypeAdapter<T> {
  /// Called for type registration
  int get typeId;

  /// Is called when a value has to be decoded.
  T read(BinaryReader reader);

  /// Is called when a value has to be encoded.
  void write(BinaryWriter writer, T obj);
}
