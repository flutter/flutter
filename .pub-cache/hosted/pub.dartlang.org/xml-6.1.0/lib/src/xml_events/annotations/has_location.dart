import 'package:meta/meta.dart';

/// Mixin with information about the location.
mixin XmlHasLocation {
  /// Hold an optional reference to the start in the input buffer.
  int? _start;

  /// Return the start location in the input buffer, or `null`.
  int? get start => _start;

  /// Hold an optional reference to the end in the input buffer.
  int? _stop;

  /// Return the start location in the input buffer, or `null`.
  int? get stop => _stop;

  /// Internal helper to attach the location to the event, do not call directly.
  @internal
  void attachLocation(int? start, int? stop) {
    assert(_start == null && _stop == null, 'Location is already initialized.');
    _start = start;
    _stop = stop;
  }
}
