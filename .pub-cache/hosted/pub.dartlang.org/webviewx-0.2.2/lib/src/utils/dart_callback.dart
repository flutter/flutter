/// Registers a Dart callback, which can be called from the Javascript side.
/// This will be turned into a platform-specific dart callback, on runtime.
///
/// Usage:
///
/// ```dart
/// WebViewX(
///   ...
///   dartCallbacks: {
///     DartCallback(
///       name: 'Unique_Name_Here',
///       callBack: (message) => print(message),
///     ),
///   },
///   ...
/// ),
/// ```
///
/// And then, from the Javascript side, when you need to call back Dart from JS:
///
/// Calling Dart from JS, on Web:
///
/// ```javascript
/// Unique_Name_Here('test');
/// ```
///
///
/// Calling Dart from JS, on Mobile:
///
/// ```javascript
/// Unique_Name_Here.postMessage('test');
///
/// ```
/// For more about the Web and Mobile different call types see [EmbeddedJsContent]
///
class DartCallback {
  /// Callback's name
  ///
  /// Note: Must be UNIQUE
  final String name;

  /// Callback function
  final Function(dynamic message) callBack;

  /// Constructor
  const DartCallback({
    required this.name,
    required this.callBack,
  });

  @override
  bool operator ==(Object other) => other is DartCallback && other.name == name;

  @override
  int get hashCode => name.hashCode;
}
