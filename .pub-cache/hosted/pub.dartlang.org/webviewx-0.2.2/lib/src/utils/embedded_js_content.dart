/// Declares some Javascript content (usually a function) which will be
/// embedded ("burned") into the HTML source at runtime.
///
/// Note: One should try to use functions as much as possible, and avoid
/// "raw" javascript.
///
/// Now there are two modes in which you can use this: ("js") or ("mobileJs" and "webJs")
///
/// The "js" param should be used when the JS function you are trying to
/// embed doesn't call any [DartCallback]s or interact in any way with the
/// Dart side, or when it does interact but it's nothing platform-specific.
///
/// Simply put, "js" is only for pure Javascript stuff or crossplatform calls.
///
/// Example what to declare in "js":
///
/// ```dart
/// EmbeddedJsContent(
///   js: 'function sayHi() {
///     console.log('hi');
///   }'
/// ),
/// ```
///
/// Both "mobileJs" and "webJs" should be used when the JS function you are
/// trying to embed WILL call platform-dependent [DartCallback]s and/or interact
/// with the Dart side.
///
/// `Note`: If you set one of them, you must set the other too, even if it will not be used.
/// If you don't need it, just set it to an empty string.
///
/// `Note 2`: If you use "mobileJs" and "webJs", don't use "js" too. Use only one of them.
///
/// If you want to call a platform-dependent Dart callback inside a function,
/// you should define the function twice (for "mobileJs" and "webJs") and
/// call the callback using platform-specific syntax, like this:
///
/// For `MOBILE`:
/// ```dart
///   Some_Callback_Name.postMessage(param1, param2...);
/// ```
///
/// For `WEB`:
/// ```dart
///   Some_Callback_Name(param1, param2...);
/// ```
///
/// Example what to declare in both "mobileJs" and "webJs":
///
/// ```dart
/// EmbeddedJsContent(
///   mobileJs: 'function callDartCallback() {
///     Some_Callback_Name.postMessage('hi');
///   }',
///   webJs: 'function callDartCallback() {
///     Some_Callback_Name('hi');
///   }',
/// ),
/// ```
class EmbeddedJsContent {
  /// This param should be used when the JS you wish to define
  /// doesn't interact in any way with the Dart side
  final String? js;

  /// This (and webJs) param should be used when the JS you wish to define
  /// does interact with the Dart side
  final String? mobileJs;

  /// This (and mobileJs) param should be used when the JS you wish to define
  /// does interact with the Dart side
  final String? webJs;

  /// Constructor
  const EmbeddedJsContent({
    this.js,
    this.mobileJs,
    this.webJs,
  }) : assert(
          js != null || (js == null && mobileJs != null && webJs != null),
          'Choose whether to use globally available js (like console.log), '
          'or platform specific(functions, callbacks, etc; For this, you must fill in '
          'the coresponding function for all platforms)',
        );
}
