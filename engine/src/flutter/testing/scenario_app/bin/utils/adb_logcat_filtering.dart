/// Some notes about filtering `adb logcat` output, especially as a result of
/// running `adb shell` to instrument the app and test scripts, as it's
/// non-trivial and error-prone.
///
/// 1. It's probably worth keeping `ActivityManager` lines unconditionally.
///    They are the most important ones, and they are not too verbose (for
///    example, they don't typically contain stack traces).
///
/// 2. `ActivityManager` starts with the application name and process ID:
///
/// ```txt
/// [stdout] 02-15 10:20:36.914  1735  1752 I ActivityManager: Start proc 6840:dev.flutter.scenarios/u0a98 for added application dev.flutter.scenarios
/// ```
///
/// The "application" comes from the file `android/app/build.gradle` under
/// `android > defaultConfig > applicationId`.
///
/// 3. Once we have the process ID, we can filter the logcat output further:
///
/// ```txt
/// [stdout] 02-15 10:20:37.430  6840  6840 E GeneratedPluginsRegister: Tried to automatically register plugins with FlutterEngine (io.flutter.embedding.engine.FlutterEngine@144d737) but could not find or invoke the GeneratedPluginRegistrant.
/// ```
///
/// A sample output of `adb logcat` command lives in `./sample_adb_logcat.txt`.
///
/// See also: <https://developer.android.com/tools/logcat>.
library;

/// Represents a line of `adb logcat` output parsed into a structured form.
///
/// For example the line:
/// ```txt
/// 02-22 13:54:39.839   549  3683 I ActivityManager: Force stopping dev.flutter.scenarios appid=10226 user=0: start instr
/// ```
///
/// ## Implementation notes
///
/// The reason this is an extension type and not a class is partially to use the
/// language feature, and partially because extension types work really well
/// with lazy parsing.
extension type const AdbLogLine._(Match _match) {
  // RegEx that parses into the following groups:
  // 1. Everything up to the severity (I, W, E, etc.).
  //    In other words, any whitespace, numbers, hyphens, colons, and periods.
  // 2. The severity (a single uppercase letter).
  // 3. The name of the process (up to the colon).
  // 4. The message (after the colon).
  //
  // This regex is simple versus being more precise. Feel free to improve it.
  static final RegExp _pattern = RegExp(r'([^A-Z]*)([A-Z])\s([^:]*)\:\s(.*)');

  /// Parses the given [adbLogCatLine] into a structured form.
  ///
  /// Returns `null` if the line does not match the expected format.
  static AdbLogLine? tryParse(String adbLogCatLine) {
    final Match? match = _pattern.firstMatch(adbLogCatLine);
    return match == null ? null : AdbLogLine._(match);
  }

  /// The full line of `adb logcat` output.
  String get line => _match.group(0)!;

  /// The process name, such as `ActivityManager`.
  String get process => _match.group(3)!;

  /// The actual log message.
  String get message => _match.group(4)!;
}
