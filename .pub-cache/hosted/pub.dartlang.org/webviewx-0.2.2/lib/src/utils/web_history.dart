import 'dart:collection';

/// Web version only.
///
/// Custom history stack coded from scratch.
/// This was needed because I couldn't retrieve accurate information
/// about the current state of the URL from within the iframe.
class HistoryStack<T> {
  T _currentEntry;
  final _backHistory = Queue<T>();
  final _forwardHistory = Queue<T>();

  /// Constructor
  HistoryStack({
    required T initialEntry,
  }) : _currentEntry = initialEntry;

  @override
  String toString() {
    return '\nHistoryStack:\n'
        'Back: $_backHistory\n'
        'Current: $_currentEntry\n'
        'Forward: $_forwardHistory\n';
  }

  /// Returns current history entry (i.e. current page)
  T get currentEntry => _currentEntry;

  /// Returns true if you can go back
  bool get canGoBack => _backHistory.isNotEmpty;

  /// Returns true if you can go forward
  bool get canGoForward => _forwardHistory.isNotEmpty;

  /// Function to add a new history entry.
  /// This is used when accessing another page.
  void addEntry(T newEntry) {
    if (newEntry == _currentEntry) {
      return;
    }

    _backHistory.addLast(_currentEntry);

    _currentEntry = newEntry;

    _forwardHistory.clear();
  }

  /// Function to move back in history.
  /// Returns the new history entry.
  T moveBack() {
    _forwardHistory.addFirst(_currentEntry);

    return _currentEntry = _backHistory.removeLast();
  }

  /// Function to move forward in history.
  /// Returns the new history entry.
  T moveForward() {
    _backHistory.addLast(_currentEntry);

    return _currentEntry = _forwardHistory.removeFirst();
  }
}
