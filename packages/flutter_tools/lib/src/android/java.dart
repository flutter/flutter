// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import 'android_studio.dart';

const String _javaHomeEnvironmentVariable = 'JAVA_HOME';
const String _kJavaExecutable = 'java';

/// Represents an installation of Java.
class Java {
  Java({
    required this.javaHome,
    required this.binaryPath,
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

  /// Finds the Java runtime environment that should be used for all java-dependent
  /// operations across the tool.
  ///
  /// This searches for Java in the following places, in order:
  ///
  /// 1. the runtime environment bundled with Android Studio;
  /// 2. the runtime environment found in the JAVA_HOME env variable, if set; or
  /// 3. the java binary found on PATH.
  ///
  /// Returns null if no java binary could be found.
  // TODO(andrewkolos): To prevent confusion when debugging Android-related
  // issues (see https://github.com/flutter/flutter/issues/122609 for an example),
  // this logic should be consistently followed by any Java-dependent operation
  // across the  the tool (building Android apps, interacting with the Android SDK, etc.).
  // Currently, this consistency is fragile since the logic used for building
  // Android apps exists independently of this method.
  // See https://github.com/flutter/flutter/issues/124252.
  static Java? find({
    required AndroidStudio? androidStudio,
    required Logger logger,
    required FileSystem fileSystem,
    required Platform platform,
    required ProcessManager processManager,
  }) {
    final OperatingSystemUtils os = OperatingSystemUtils(
      fileSystem: fileSystem,
      logger: logger,
      platform: platform,
      processManager: processManager
    );
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

    if (binary == null) {
      return null;
    }

    return Java(
      javaHome: home,
      binaryPath: binary,
      logger: logger,
      fileSystem: fileSystem,
      os: os,
      platform: platform,
      processManager: processManager,
    );
  }

  /// The path of the runtime's home directory.
  ///
  /// This should only be used for logging and validation purposes.
  /// If you need to set JAVA_HOME when starting a process, consider
  /// using [environment] instead.
  /// If you need to inspect the files of the runtime, considering adding
  /// a new method to this class instead.
  final String? javaHome;

  /// The path of the runtime's java binary.
  ///
  /// This should be only used for logging and validation purposes.
  /// If you need to invoke the binary directly, consider adding a new method
  /// to this class instead.
  final String binaryPath;

  final Logger _logger;
  final FileSystem _fileSystem;
  final OperatingSystemUtils _os;
  final Platform _platform;
  final ProcessManager _processManager;
  final ProcessUtils _processUtils;

  /// Returns an environment variable map with
  /// 1. JAVA_HOME set if this object has a known home directory, and
  /// 2. The java binary folder appended onto PATH, if the binary location is known.
  ///
  /// This map should be used as the environment when invoking any Java-dependent
  /// processes, such as Gradle or Android SDK tools (avdmanager, sdkmanager, etc.)
  Map<String, String> get environment {
    return <String, String>{
      if (javaHome != null) _javaHomeEnvironmentVariable: javaHome!,
      'PATH': _fileSystem.path.dirname(binaryPath) +
                        _os.pathVarSeparator +
                        _platform.environment['PATH']!,
    };
  }

  /// Returns the version of java in the format \d(.\d)+(.\d)+
  /// Returns null if version could not be determined.
  late final JavaVersion? version = (() {
    final RunResult result = _processUtils.runSync(
      <String>[binaryPath, '--version'],
      environment: environment,
    );
    if (result.exitCode != 0) {
      _logger.printTrace('java --version failed: exitCode: ${result.exitCode}'
        ' stdout: ${result.stdout} stderr: ${result.stderr}');
    }
    return JavaVersion.tryParseFromJavaOutput(result.stdout, logger: _logger);
  })();

  bool canRun() {
    return _processManager.canRun(binaryPath);
  }
}

String? _findJavaHome({
  required Logger logger,
  required AndroidStudio? androidStudio,
  required Platform platform,
}) {
  final String? androidStudioJavaPath = androidStudio?.javaPath;
  if (androidStudioJavaPath != null) {
    return androidStudioJavaPath;
  }

  final String? javaHomeEnv = platform.environment[_javaHomeEnvironmentVariable];
  if (javaHomeEnv != null) {
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
  return operatingSystemUtils.which(_kJavaExecutable)?.path;
}

// Returns a user visible String that says the tool failed to parse
// the version of java along with the output.
String _formatJavaVersionWarning(String javaVersionRaw) {
  return 'Could not parse java version from: \n'
    '$javaVersionRaw \n'
    'If there is a version please look for an existing bug '
    'https://github.com/flutter/flutter/issues/ '
    'and if one does not exist file a new issue.';
}

class JavaVersion {
  JavaVersion({
    required this.longText,
    required this.number
  });

  /// Typically the first line of the output from `java --version`.
  /// For example, `"openjdk 19.0.2 2023-01-17"`.
  final String longText;

  /// The version number. For example, `"19.0.2."`.
  final String number;

  /// Extracts JDK version from the output of java --version.
  static JavaVersion? tryParseFromJavaOutput(String rawVersionOutput, {
    required Logger logger,
  }) {
    final List<String> versionLines = rawVersionOutput.split('\n');
    final String longText = versionLines.length >= 2 ? versionLines[1] : versionLines[0];

    // The contents that matter come in the format '11.0.18' or '1.8.0_202'.
    final RegExp jdkVersionRegex = RegExp(r'\d+\.\d+(\.\d+(?:_\d+)?)?');
    final Iterable<RegExpMatch> matches =
        jdkVersionRegex.allMatches(rawVersionOutput);
    if (matches.isEmpty) {
      logger.printWarning(_formatJavaVersionWarning(rawVersionOutput));
      return null;
    }
    final String? rawShortText = matches.first.group(0);
    if (rawShortText == null || rawShortText.split('_').isEmpty) {
      logger.printWarning(_formatJavaVersionWarning(rawVersionOutput));
      return null;
    }

    // Trim away _d+ from versions 1.8 and below.
    final String shortText = rawShortText.split('_').first;

    return JavaVersion(longText: longText, number: shortText);
  }
}
