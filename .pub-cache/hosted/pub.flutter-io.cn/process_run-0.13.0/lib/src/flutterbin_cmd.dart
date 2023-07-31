import 'dart:convert';

import 'package:process_run/shell_run.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:pub_semver/pub_semver.dart';

String? _flutterExecutablePath;

/// Resolved flutter path if found
String? get flutterExecutablePath =>
    _flutterExecutablePath ??= whichSync('flutter');

/// Test only
@Deprecated('Dev only')
set flutterExecutablePath(String? path) {
  _flutterExecutablePath = path;
  // Reset info
  _flutterBinInfo = null;
}

@Deprecated('Dev only')
ProcessCmd flutterCmd(List<String> arguments) => FlutterCmd(arguments);

bool get isFlutterSupported => isFlutterSupportedSync;

/// true if flutter is supported
bool get isFlutterSupportedSync => flutterExecutablePath != null;

/// build a flutter command
class FlutterCmd extends ProcessCmd {
  // Somehow flutter requires runInShell on Linux, does not hurt on windows
  FlutterCmd(List<String> arguments)
      : super(flutterExecutablePath, arguments, runInShell: true);

  @override
  String toString() => executableArgumentsToString('flutter', arguments);
}

// to deprecate
Future<Version?> getFlutterVersion() => getFlutterBinVersion();

/// Get flutter version.
///
/// Returns null if flutter cannot be found in the path
Future<Version?> getFlutterBinVersion() async =>
    (await getFlutterBinInfo())?.version;

/// Get flutter channel. (dev, beta, master, stable)
///
/// Returns null if flutter cannot be found in the path
Future<String?> getFlutterBinChannel() async =>
    (await getFlutterBinInfo())?.channel;

FlutterBinInfo? _flutterBinInfo;

Future<FlutterBinInfo?> getFlutterBinInfo() async =>
    _flutterBinInfo ??= await _getFlutterBinInfo();

/// Parse flutter information
abstract class FlutterBinInfo {
  String? get channel;

  Version? get version;

  /// First line is sufficient
  static FlutterBinInfo? parseVersionOutput(String resultOutput) {
    Version? version;
    String? channel;
    var output = LineSplitter.split(resultOutput)
        .join(' ')
        .split(' ')
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty);
    // Take the first version string after flutter
    var foundFlutter = false;
    var foundChannel = false;

    for (var word in output) {
      if (version == null) {
        if (foundFlutter) {
          try {
            version = Version.parse(word);
          } catch (_) {}
        } else if (word.toLowerCase().contains('flutter')) {
          foundFlutter = true;
        }
      } else if (channel == null) {
        if (foundChannel) {
          channel = word;
          // done
          break;
        } else if (word.toLowerCase().contains('channel')) {
          foundChannel = true;
        }
      }
    }
    if (version != null || channel != null) {
      return FlutterBinInfoImpl(version: version, channel: channel);
    }
    return null;
  }
}

class FlutterBinInfoImpl implements FlutterBinInfo {
  @override
  final String? channel;

  @override
  final Version? version;

  FlutterBinInfoImpl({this.channel, this.version});
}

/// Get flutter info.
///
/// Not exposed yet
///
/// Returns null if flutter cannot be found in the path
Future<FlutterBinInfo?> _getFlutterBinInfo() async {
  // $ flutter --version
  // Flutter 1.7.8+hotfix.4 • channel stable • https://github.com/flutter/flutter.git
  // Framework • revision 20e59316b8 (8 weeks ago) • 2019-07-18 20:04:33 -0700
  // Engine • revision fee001c93f
  // Tools • Dart 2.4.0
  try {
    var results = await run('flutter --version', verbose: false);
    // Take from stderr first
    var resultOutput = results.first.stderr.toString().trim();
    if (resultOutput.isEmpty) {
      resultOutput = results.first.stdout.toString().trim();
    }
    return FlutterBinInfo.parseVersionOutput(resultOutput);
  } catch (_) {}
  return null;
}
