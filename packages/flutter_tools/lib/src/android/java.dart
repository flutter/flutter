import '../base/file_system.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../globals.dart' as globals;
import 'android_studio.dart';

const String _kJavaHomeEnvironmentVariable = 'JAVA_HOME';
const String _kJavaExecutable = 'java';

/// This sets JAVA_HOME and adds the java binary onto PATH.
/// Returns an environment with the JAVA_HOME set to the appropriate folder and
/// the folder containing the java binary added to PATH.
///
/// This should be used when invoking any Java-dependent command or tool,
/// including Gradle and anything in the Android SDK such as avdmanager or sdkmanager.
Map<String, String> findJavaEnvironment({
  required AndroidStudio? androidStudio,
  required FileSystem fileSystem,
  required OperatingSystemUtils operatingSystemUtils,
  required Platform platform,
}) {
  // If we can locate Java, then add it to the path used to run the Android SDK manager.
  final Map<String, String> result = <String, String>{};
  final String? javaHome = findJavaHome(
    androidStudio: globals.androidStudio,
    platform: globals.platform,
  );
  if (javaHome != null) {
    result[_kJavaHomeEnvironmentVariable] = javaHome;
  }

  final String? javaBinary = findJavaBinary(
    androidStudio: globals.androidStudio,
    fileSystem: globals.fs,
    operatingSystemUtils: globals.os,
    platform: globals.platform,
  );
  if (javaBinary != null && globals.platform.environment['PATH'] != null) {
    result['PATH'] = globals.fs.path.dirname(javaBinary) +
                        globals.os.pathVarSeparator +
                        globals.platform.environment['PATH']!;
  }
  return result;
}

/// Returns the version of java in the format \d(.\d)+(.\d)+
/// Returns null if version not found.
String? getJavaVersion({
  required AndroidStudio? androidStudio,
  required FileSystem fileSystem,
  required OperatingSystemUtils operatingSystemUtils,
  required Platform platform,
  required ProcessUtils processUtils,
}) {
  final String? javaBinary = findJavaBinary(
    androidStudio: androidStudio,
    fileSystem: fileSystem,
    operatingSystemUtils: operatingSystemUtils,
    platform: platform,
  );
  if (javaBinary == null) {
    globals.printTrace('Could not find java binary to get version.');
    return null;
  }
  final RunResult result = processUtils.runSync(
    <String>[javaBinary, '--version'],
    environment: findJavaEnvironment(
      androidStudio: androidStudio,
      fileSystem: fileSystem,
      operatingSystemUtils: operatingSystemUtils,
      platform: platform,
    ),
  );
  if (result.exitCode != 0) {
    globals.printTrace(
        'java --version failed: exitCode: ${result.exitCode} stdout: ${result.stdout} stderr: ${result.stderr}');
    return null;
  }
  return parseJavaVersion(result.stdout);
}

/// Extracts JDK version from the output of java --version.
String? parseJavaVersion(String rawVersionOutput) {
  // The contents that matter come in the format '11.0.18' or '1.8.0_202'.
  final RegExp jdkVersionRegex = RegExp(r'\d+\.\d+(\.\d+(?:_\d+)?)?');
  final Iterable<RegExpMatch> matches =
      jdkVersionRegex.allMatches(rawVersionOutput);
  if (matches.isEmpty) {
    globals.logger.printWarning(_formatJavaVersionWarning(rawVersionOutput));
    return null;
  }
  final String? versionString = matches.first.group(0);
  if (versionString == null || versionString.split('_').isEmpty) {
    globals.logger.printWarning(_formatJavaVersionWarning(rawVersionOutput));
    return null;
  }
  // Trim away _d+ from versions 1.8 and below.
  return versionString.split('_').first;
}

/// A value that would be appropriate to use as JAVA_HOME.
///
/// This method considers jdk in the following order:
/// * the JDK bundled with Android Studio, if one is found;
/// * the JAVA_HOME in the ambient environment, if set;
String? get javaHome {
  return findJavaHome(
    androidStudio: globals.androidStudio,
    platform: globals.platform,
  );
}


String? findJavaHome({
  required AndroidStudio? androidStudio,
  required Platform platform,
}) {
  if (androidStudio?.javaPath != null) {
    globals.printTrace("Using Android Studio's java.");
    return androidStudio!.javaPath;
  }

  final String? javaHomeEnv = platform.environment[_kJavaHomeEnvironmentVariable];
  if (javaHomeEnv != null) {
    globals.printTrace('Using JAVA_HOME from environment valuables.');
    return javaHomeEnv;
  }
  return null;
}

/// Finds the java binary that is used for all operations across the tool.
///
/// This comes from [findJavaHome] if that method returns non-null;
/// otherwise, it gets from searching PATH.
// TODO(andrewkolos): To prevent confusion when debugging Android-related
// issues (see https://github.com/flutter/flutter/issues/122609 for an example),
// this logic should be consistently followed by any Java-dependent operation
// across the  the tool (building Android apps, interacting with the Android SDK, etc.).
// Currently, this consistency is fragile since the logic used for building
// Android apps exists independently of this method.
// See https://github.com/flutter/flutter/issues/124252.
String? findJavaBinary({
  required AndroidStudio? androidStudio,
  required FileSystem fileSystem,
  required OperatingSystemUtils operatingSystemUtils,
  required Platform platform,
}) {
  final String? javaHome = findJavaHome(
    androidStudio: androidStudio,
    platform: platform,
  );

  if (javaHome != null) {
    return fileSystem.path.join(javaHome, 'bin', 'java');
  }

  // Fallback to PATH based lookup.
  final String? pathJava = operatingSystemUtils.which(_kJavaExecutable)?.path;
  if (pathJava != null) {
    globals.printTrace('Using java from PATH.');
  } else {
    globals.printTrace('Could not find java path.');
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
