import 'package:meta/meta.dart';

/// Mixin with information about the location.
mixin XmlHasBuffer {
  /// Hold a reference to the start in the input buffer.
  String? _buffer;

  /// Return the underlying buffer.
  String? get buffer => _buffer;

  /// Internal helper to attach the buffer to the event, do not call directly.
  @internal
  void attachBuffer(String? buffer) {
    assert(_buffer == null, 'Buffer is already initialized.');
    _buffer = buffer;
  }
}
