import 'dart:async';

/// Minimal offline service placeholder.
/// Replace with connectivity_plus or a caching layer when ready.
class OfflineService {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _isOffline = false;

  Stream<bool> get changes => _controller.stream;
  bool get isOffline => _isOffline;

  void setOffline(bool value) {
    if (value == _isOffline) return;
    _isOffline = value;
    _controller.add(_isOffline);
  }

  void dispose() {
    _controller.close();
  }
}
