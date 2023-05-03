import 'package:process/process.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import 'android_studio.dart';

const String _javaHomeEnvironmentVariable = 'JAVA_HOME';
const String _kJavaExecutable = 'java';

class Java {
  Java({
    this.home,
    this.binary,
    required Logger logger,
    required FileSystem fileSystem,
    required OperatingSystemUtils os,
    required Platform platform,
    required ProcessManager processManager,
  }): _logger = logger,
      _fileSystem = fileSystem,
      _os = os,
      _platform = platform,
      _processManager = processManager,
      _processUtils = ProcessUtils(processManager: processManager, logger: logger);

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
    required Logger logger,
    required FileSystem fileSystem,
    required OperatingSystemUtils os,
    required Platform platform,
    required ProcessManager processManager,
  }) {
    final String? home = _findJavaHome(
      logger: logger,
      androidStudio: androidStudio,
      platform: platform
    );
    final String? binary = _findJavaBinary(
      logger: logger,
      javaHome: home,
      fileSystem: fileSystem,
      operatingSystemUtils: os,
      platform: platform
    );

    return Java(home: home, binary: binary, logger: logger, fileSystem: fileSystem, os: os, platform: platform, processManager: processManager);
  }

  /// The path of the runtime's home directory.
  ///
  /// This should only be used for logging and validation purposes.
  /// If you need to set JAVA_HOME when starting a process, consider
  /// using [getJavaEnvironment] instead.
  /// If you need to inspect the files of the runtime, considering adding
  /// a new method to this class instead.
  final String? home;

  /// The path of the runtime's java binary.
  ///
  /// This should be only used for logging and validation purposes.
  /// If you need to invoke the binary directly, consider adding a new method
  /// to this class instead.
  final String? binary;

  final Logger _logger;
  final FileSystem _fileSystem;
  final OperatingSystemUtils _os;
  final Platform _platform;
  final ProcessManager _processManager;
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
      if (home != null) _javaHomeEnvironmentVariable: home!,
      if (binary != null) 'PATH': _fileSystem.path.dirname(binary!) +
                        _os.pathVarSeparator +
                        _platform.environment['PATH']!,
    };
  }

  /// Returns the version of java in the format \d(.\d)+(.\d)+
  /// Returns null if version not found.
  String? getVersionString() {
    if (binary == null) {
      _logger.printTrace('Could not find java binary to get version.');
      return null;
    }

    if (_version == null) {
      final RunResult result = _processUtils.runSync(
        <String>[binary!, '--version'],
        environment: getJavaEnvironment(),
      );
      if (result.exitCode != 0) {
        _logger.printTrace('java --version failed: exitCode: ${result.exitCode}'
          ' stdout: ${result.stdout} stderr: ${result.stderr}');
      }
      _version = _parseJavaVersion(result.stdout);
    }

    return _version;
  }

  /// Extracts JDK version from the output of java --version.
  String? _parseJavaVersion(String rawVersionOutput) {
    // The contents that matter come in the format '11.0.18' or '1.8.0_202'.
    final RegExp jdkVersionRegex = RegExp(r'\d+\.\d+(\.\d+(?:_\d+)?)?');
    final Iterable<RegExpMatch> matches =
        jdkVersionRegex.allMatches(rawVersionOutput);
    if (matches.isEmpty) {
      _logger.printWarning(_formatJavaVersionWarning(rawVersionOutput));
      return null;
    }
    final String? versionString = matches.first.group(0);
    if (versionString == null || versionString.split('_').isEmpty) {
      _logger.printWarning(_formatJavaVersionWarning(rawVersionOutput));
      return null;
    }
    // Trim away _d+ from versions 1.8 and below.
    return versionString.split('_').first;
  }

  bool canRun() {
    return _processManager.canRun(binary);
  }
}



String? _findJavaHome({
  required Logger logger,
  required AndroidStudio? androidStudio,
  required Platform platform,
}) {
  if (androidStudio?.javaPath != null) {
    logger.printTrace("Using Android Studio's java.");
    return androidStudio!.javaPath;
  }

  final String? javaHomeEnv = platform.environment[_javaHomeEnvironmentVariable];
  if (javaHomeEnv != null) {
    logger.printTrace('Using JAVA_HOME from environment valuables.');
    return javaHomeEnv;
  }
  return null;
}

String? _findJavaBinary({
  required Logger logger,
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
    logger.printTrace('Using java from PATH.');
  } else {
    logger.printTrace('Could not find java path.');
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
