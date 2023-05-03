import '../base/file_system.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../globals.dart' show printTrace, printWarning;
import 'android_studio.dart';

const String _javaHomeEnvironmentVariable = 'JAVA_HOME';
const String _kJavaExecutable = 'java';

class Java {
  Java({
    required String? home,
    required String? binary,
    required FileSystem fileSystem,
    required OperatingSystemUtils os,
    required Platform platform,
    required ProcessUtils processUtils,
  }): _home = home,
      _binary = binary,
      _fileSystem = fileSystem,
      _os = os,
      _platform = platform,
      _processUtils = processUtils;

  /// Finds the Java runtime that should be used for all java-dependent
  /// operations across the tool.
  ///
  /// This searches for Java in the following places, in order:
  ///
  /// 1. the runtime bundled with Android Studio;
  /// 2. the runtime found in the JAVA_HOME env variable, if set; or
  /// 3. the java binary found on PATH.
  ///
  // TODO(andrewkolos): To prevent confusion when debugging Android-related
  // issues (see https://github.com/flutter/flutter/issues/122609 for an example),
  // this logic should be consistently followed by any Java-dependent operation
  // across the  the tool (building Android apps, interacting with the Android SDK, etc.).
  // Currently, this consistency is fragile since the logic used for building
  // Android apps exists independently of this method.
  // See https://github.com/flutter/flutter/issues/124252.
  factory Java.find({
    required AndroidStudio? androidStudio,
    required FileSystem fileSystem,
    required OperatingSystemUtils os,
    required Platform platform,
    required ProcessUtils processUtils,
  }) {
    final String? home = _findJavaHome(androidStudio: androidStudio, platform: platform);
    final String? binary = _findJavaBinary(
      javaHome: home,
      fileSystem: fileSystem,
      operatingSystemUtils: os,
      platform: platform
    );

    return Java(home: home, binary: binary, fileSystem: fileSystem, os: os, platform: platform, processUtils: processUtils);
  }

  final String? _home;
  final String? _binary;
  final FileSystem _fileSystem;
  final OperatingSystemUtils _os;
  final Platform _platform;
  final ProcessUtils _processUtils;

  late String? _version;

  /// Returns an environment variable map with
  /// 1. JAVA_HOME set if this object has a known home directory, and
  /// 2. The java binary folder appended onto PATH, if the binary location is known.
  ///
  /// This map should be used as the environment when invoking any Java-dependent
  /// processes, such as Gradle or Android SDK tools (avdmanager, sdkmanager, etc.)
  Map<String, String> getJavaEnvironment() {
    return <String, String>{
      if (_home != null) _javaHomeEnvironmentVariable: _home!,
      if (_binary != null) 'PATH': _fileSystem.path.dirname(_binary!) +
                        _os.pathVarSeparator +
                        _platform.environment['PATH']!,
    };
  }

  /// Returns the version of java in the format \d(.\d)+(.\d)+
  /// Returns null if version not found.
  String? getVersionString() {
    if (_binary == null) {
      printTrace('Could not find java binary to get version.');
      return null;
    }
    return _version ??= _getJavaVersion(javaBinary: _binary!, javaEnvironment: getJavaEnvironment(), processUtils: _processUtils);
  }

}

/// Returns the version of java in the format \d(.\d)+(.\d)+
/// Returns null if version not found.
String? _getJavaVersion({
  required String javaBinary,
  required Map<String, String> javaEnvironment,
  required ProcessUtils processUtils,
}) {
  final RunResult result = processUtils.runSync(
    <String>[javaBinary, '--version'],
    environment: javaEnvironment,
  );
  if (result.exitCode != 0) {
    printTrace('java --version failed: exitCode: ${result.exitCode}'
      ' stdout: ${result.stdout} stderr: ${result.stderr}');
    return null;
  }
  return _parseJavaVersion(result.stdout);
}

/// Extracts JDK version from the output of java --version.
String? _parseJavaVersion(String rawVersionOutput) {
  // The contents that matter come in the format '11.0.18' or '1.8.0_202'.
  final RegExp jdkVersionRegex = RegExp(r'\d+\.\d+(\.\d+(?:_\d+)?)?');
  final Iterable<RegExpMatch> matches =
      jdkVersionRegex.allMatches(rawVersionOutput);
  if (matches.isEmpty) {
    printWarning(_formatJavaVersionWarning(rawVersionOutput));
    return null;
  }
  final String? versionString = matches.first.group(0);
  if (versionString == null || versionString.split('_').isEmpty) {
    printWarning(_formatJavaVersionWarning(rawVersionOutput));
    return null;
  }
  // Trim away _d+ from versions 1.8 and below.
  return versionString.split('_').first;
}

String? _findJavaHome({
  required AndroidStudio? androidStudio,
  required Platform platform,
}) {
  if (androidStudio?.javaPath != null) {
    printTrace("Using Android Studio's java.");
    return androidStudio!.javaPath;
  }

  final String? javaHomeEnv = platform.environment[_javaHomeEnvironmentVariable];
  if (javaHomeEnv != null) {
    printTrace('Using JAVA_HOME from environment valuables.');
    return javaHomeEnv;
  }
  return null;
}

String? _findJavaBinary({
  required String? javaHome,
  required FileSystem fileSystem,
  required OperatingSystemUtils operatingSystemUtils,
  required Platform platform,
}) {
  if (javaHome != null) {
    return fileSystem.path.join(javaHome, 'bin', 'java');
  }

  // Fallback to PATH based lookup.
  final String? pathJava = operatingSystemUtils.which(_kJavaExecutable)?.path;
  if (pathJava != null) {
    printTrace('Using java from PATH.');
  } else {
    printTrace('Could not find java path.');
  }
  return pathJava;
}

// Returns a user visible String that says the tool failed to parse
// the version of java along with the output.
String _formatJavaVersionWarning(String javaVersionRaw) {
return 'Could not parse java version from: \n'
    '$javaVersionRaw \n'
    'If there is a version please look for an existing bug '
    'https://github.com/flutter/flutter/issues/'
    ' and if one does not exist file a new issue.';
}
