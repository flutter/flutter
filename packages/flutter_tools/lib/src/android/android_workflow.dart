// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/user_messages.dart' hide userMessages;
import '../base/version.dart';
import '../convert.dart';
import '../doctor_validator.dart';
import '../features.dart';
import 'android_sdk.dart';
import 'android_studio.dart';

const int kAndroidSdkMinVersion = 29;
final Version kAndroidJavaMinVersion = Version(1, 8, 0);
final Version kAndroidSdkBuildToolsMinVersion = Version(28, 0, 3);

AndroidWorkflow? get androidWorkflow => context.get<AndroidWorkflow>();
AndroidValidator? get androidValidator => context.get<AndroidValidator>();
AndroidLicenseValidator? get androidLicenseValidator => context.get<AndroidLicenseValidator>();

enum LicensesAccepted {
  none,
  some,
  all,
  unknown,
}

final RegExp licenseCounts = RegExp(r'(\d+) of (\d+) SDK package licenses? not accepted.');
final RegExp licenseNotAccepted = RegExp(r'licenses? not accepted', caseSensitive: false);
final RegExp licenseAccepted = RegExp(r'All SDK package licenses accepted.');

class AndroidWorkflow implements Workflow {
  AndroidWorkflow({
    required AndroidSdk? androidSdk,
    required FeatureFlags featureFlags,
    required OperatingSystemUtils operatingSystemUtils,
  }) : _androidSdk = androidSdk,
       _featureFlags = featureFlags,
       _operatingSystemUtils = operatingSystemUtils;

  final AndroidSdk? _androidSdk;
  final FeatureFlags _featureFlags;
  final OperatingSystemUtils _operatingSystemUtils;

  @override
  bool get appliesToHostPlatform => _featureFlags.isAndroidEnabled
    // Android Studio is not currently supported on Linux Arm64 Hosts.
    && _operatingSystemUtils.hostPlatform != HostPlatform.linux_arm64;

  @override
  bool get canListDevices => _androidSdk != null
    && _androidSdk?.adbPath != null;

  @override
  bool get canLaunchDevices => _androidSdk != null
    && _androidSdk?.adbPath != null
    && _androidSdk?.validateSdkWellFormed().isEmpty == true;

  @override
  bool get canListEmulators => _androidSdk != null
    && _androidSdk?.adbPath != null
    && _androidSdk?.emulatorPath != null;
}

/// A validator that checks if the Android SDK and Java SDK are available and
/// installed correctly.
///
/// Android development requires the Android SDK, and at least one Java SDK. While
/// newer Java compilers can be used to compile the Java application code, the SDK
/// tools themselves required JDK 1.8. This older JDK is normally bundled with
/// Android Studio.
class AndroidValidator extends DoctorValidator {
  AndroidValidator({
    required AndroidSdk? androidSdk,
    required AndroidStudio? androidStudio,
    required FileSystem fileSystem,
    required Logger logger,
    required Platform platform,
    required ProcessManager processManager,
    required UserMessages userMessages,
  }) : _androidSdk = androidSdk,
       _androidStudio = androidStudio,
       _fileSystem = fileSystem,
       _logger = logger,
       _operatingSystemUtils = OperatingSystemUtils(
         fileSystem: fileSystem,
         logger: logger,
         platform: platform,
         processManager: processManager,
       ),
       _platform = platform,
       _processManager = processManager,
       _userMessages = userMessages,
       super('Android toolchain - develop for Android devices');

  final AndroidSdk? _androidSdk;
  final AndroidStudio? _androidStudio;
  final FileSystem _fileSystem;
  final Logger _logger;
  final OperatingSystemUtils _operatingSystemUtils;
  final Platform _platform;
  final ProcessManager _processManager;
  final UserMessages _userMessages;

  @override
  String get slowWarning => '${_task ?? 'This'} is taking a long time...';
  String? _task;

  /// Finds the semantic version anywhere in a text.
  static final RegExp _javaVersionPattern = RegExp(r'(\d+)(\.(\d+)(\.(\d+))?)?');

  /// `java -version` response is not only a number, but also includes other
  /// information eg. `openjdk version "1.7.0_212"`.
  /// This method extracts only the semantic version from from that response.
  static String? _extractJavaVersion(String? text) {
    if (text == null || text.isEmpty) {
      return null;
    }
    final Match? match = _javaVersionPattern.firstMatch(text);
    if (match == null) {
      return null;
    }
    return text.substring(match.start, match.end);
  }

  /// Returns false if we cannot determine the Java version or if the version
  /// is older that the minimum allowed version of 1.8.
  Future<bool> _checkJavaVersion(String javaBinary, List<ValidationMessage> messages) async {
    _task = 'Checking Java status';
    try {
      if (!_processManager.canRun(javaBinary)) {
        messages.add(ValidationMessage.error(_userMessages.androidCantRunJavaBinary(javaBinary)));
        return false;
      }
      String? javaVersionText;
      try {
        _logger.printTrace('java -version');
        final ProcessResult result = await _processManager.run(<String>[javaBinary, '-version']);
        if (result.exitCode == 0) {
          final List<String> versionLines = (result.stderr as String).split('\n');
          javaVersionText = versionLines.length >= 2 ? versionLines[1] : versionLines[0];
        }
      } on Exception catch (error) {
        _logger.printTrace(error.toString());
      }
      final Version? javaVersion = Version.parse(_extractJavaVersion(javaVersionText));
      if (javaVersionText == null || javaVersionText.isEmpty || javaVersion == null) {
        // Could not determine the java version.
        messages.add(ValidationMessage.error(_userMessages.androidUnknownJavaVersion));
        return false;
      }
      if (javaVersion < kAndroidJavaMinVersion) {
        messages.add(ValidationMessage.error(_userMessages.androidJavaMinimumVersion(javaVersionText)));
        return false;
      }
      messages.add(ValidationMessage(_userMessages.androidJavaVersion(javaVersionText)));
      return true;
    } finally {
      _task = null;
    }
  }

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    final AndroidSdk? androidSdk = _androidSdk;
    if (androidSdk == null) {
      // No Android SDK found.
      if (_platform.environment.containsKey(kAndroidHome)) {
        final String androidHomeDir = _platform.environment[kAndroidHome]!;
        messages.add(ValidationMessage.error(_userMessages.androidBadSdkDir(kAndroidHome, androidHomeDir)));
      } else {
        // Instruct user to set [kAndroidSdkRoot] and not deprecated [kAndroidHome]
        // See https://github.com/flutter/flutter/issues/39301
        messages.add(ValidationMessage.error(_userMessages.androidMissingSdkInstructions(_platform)));
      }
      return ValidationResult(ValidationType.missing, messages);
    }

    if (androidSdk.licensesAvailable && !androidSdk.platformToolsAvailable) {
      messages.add(ValidationMessage.hint(_userMessages.androidSdkLicenseOnly(kAndroidHome)));
      return ValidationResult(ValidationType.partial, messages);
    }

    messages.add(ValidationMessage(_userMessages.androidSdkLocation(androidSdk.directory.path)));

    String? sdkVersionText;
    final AndroidSdkVersion? androidSdkLatestVersion = androidSdk.latestVersion;
    if (androidSdkLatestVersion != null) {
      if (androidSdkLatestVersion.sdkLevel < kAndroidSdkMinVersion || androidSdkLatestVersion.buildToolsVersion < kAndroidSdkBuildToolsMinVersion) {
        messages.add(ValidationMessage.error(
          _userMessages.androidSdkBuildToolsOutdated(
            _androidSdk!.sdkManagerPath,
            kAndroidSdkMinVersion,
            kAndroidSdkBuildToolsMinVersion.toString(),
            _platform,
          )),
        );
        return ValidationResult(ValidationType.missing, messages);
      }
      sdkVersionText = _userMessages.androidStatusInfo(androidSdkLatestVersion.buildToolsVersionName);

      messages.add(ValidationMessage(_userMessages.androidSdkPlatformToolsVersion(
        androidSdkLatestVersion.platformName,
        androidSdkLatestVersion.buildToolsVersionName)));
    } else {
      messages.add(ValidationMessage.error(_userMessages.androidMissingSdkInstructions(_platform)));
    }

    if (_platform.environment.containsKey(kAndroidHome)) {
      final String androidHomeDir = _platform.environment[kAndroidHome]!;
      messages.add(ValidationMessage('$kAndroidHome = $androidHomeDir'));
    }
    if (_platform.environment.containsKey(kAndroidSdkRoot)) {
      final String androidSdkRoot = _platform.environment[kAndroidSdkRoot]!;
      messages.add(ValidationMessage('$kAndroidSdkRoot = $androidSdkRoot'));
    }

    final List<String> validationResult = androidSdk.validateSdkWellFormed();

    if (validationResult.isNotEmpty) {
      // Android SDK is not functional.
      messages.addAll(validationResult.map<ValidationMessage>((String message) {
        return ValidationMessage.error(message);
      }));
      messages.add(ValidationMessage(_userMessages.androidSdkInstallHelp(_platform)));
      return ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
    }

    // Now check for the JDK.
    final String? javaBinary = AndroidSdk.findJavaBinary(
      androidStudio: _androidStudio,
      fileSystem: _fileSystem,
      operatingSystemUtils: _operatingSystemUtils,
      platform: _platform,
    );
    if (javaBinary == null) {
      messages.add(ValidationMessage.error(_userMessages.androidMissingJdk));
      return ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
    }
    messages.add(ValidationMessage(_userMessages.androidJdkLocation(javaBinary)));

    // Check JDK version.
    if (! await _checkJavaVersion(javaBinary, messages)) {
      return ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
    }

    // Success.
    return ValidationResult(ValidationType.installed, messages, statusInfo: sdkVersionText);
  }
}

/// A subvalidator that checks if the licenses within the detected Android
/// SDK have been accepted.
class AndroidLicenseValidator extends DoctorValidator {
  AndroidLicenseValidator({
    required AndroidSdk androidSdk,
    required Platform platform,
    required OperatingSystemUtils operatingSystemUtils,
    required FileSystem fileSystem,
    required ProcessManager processManager,
    required Logger logger,
    required AndroidStudio? androidStudio,
    required Stdio stdio,
    required UserMessages userMessages,
  }) : _androidSdk = androidSdk,
       _platform = platform,
       _operatingSystemUtils = operatingSystemUtils,
       _fileSystem = fileSystem,
       _processManager = processManager,
       _logger = logger,
       _androidStudio = androidStudio,
       _stdio = stdio,
       _userMessages = userMessages,
       super('Android license subvalidator');

  final AndroidSdk _androidSdk;
  final AndroidStudio? _androidStudio;
  final Stdio _stdio;
  final OperatingSystemUtils _operatingSystemUtils;
  final Platform _platform;
  final FileSystem _fileSystem;
  final ProcessManager _processManager;
  final Logger _logger;
  final UserMessages _userMessages;

  @override
  String get slowWarning => 'Checking Android licenses is taking an unexpectedly long time...';

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];

    // Match pre-existing early termination behavior
    if (_androidSdk == null || _androidSdk.latestVersion == null ||
        _androidSdk.validateSdkWellFormed().isNotEmpty ||
        ! await _checkJavaVersionNoOutput()) {
      return ValidationResult(ValidationType.missing, messages);
    }

    final String sdkVersionText = _userMessages.androidStatusInfo(_androidSdk.latestVersion!.buildToolsVersionName);

    // Check for licenses.
    switch (await licensesAccepted) {
      case LicensesAccepted.all:
        messages.add(ValidationMessage(_userMessages.androidLicensesAll));
        break;
      case LicensesAccepted.some:
        messages.add(ValidationMessage.hint(_userMessages.androidLicensesSome));
        return ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
      case LicensesAccepted.none:
        messages.add(ValidationMessage.error(_userMessages.androidLicensesNone));
        return ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
      case LicensesAccepted.unknown:
        messages.add(ValidationMessage.error(_userMessages.androidLicensesUnknown(_platform)));
        return ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
    }
    return ValidationResult(ValidationType.installed, messages, statusInfo: sdkVersionText);
  }

  Future<bool> _checkJavaVersionNoOutput() async {
    final String? javaBinary = AndroidSdk.findJavaBinary(
      androidStudio: _androidStudio,
      fileSystem: _fileSystem,
      operatingSystemUtils: _operatingSystemUtils,
      platform: _platform,
    );
    if (javaBinary == null) {
      return false;
    }
    if (!_processManager.canRun(javaBinary)) {
      return false;
    }
    String? javaVersion;
    try {
      final ProcessResult result = await _processManager.run(<String>[javaBinary, '-version']);
      if (result.exitCode == 0) {
        final List<String> versionLines = (result.stderr as String).split('\n');
        javaVersion = versionLines.length >= 2 ? versionLines[1] : versionLines[0];
      }
    } on Exception catch (error) {
      _logger.printTrace(error.toString());
    }
    if (javaVersion == null) {
      // Could not determine the java version.
      return false;
    }
    return true;
  }

  Future<LicensesAccepted> get licensesAccepted async {
    LicensesAccepted? status;

    void _handleLine(String line) {
      if (licenseCounts.hasMatch(line)) {
        final Match? match = licenseCounts.firstMatch(line);
        if (match?.group(1) != match?.group(2)) {
          status = LicensesAccepted.some;
        } else {
          status = LicensesAccepted.none;
        }
      } else if (licenseNotAccepted.hasMatch(line)) {
        // The licenseNotAccepted pattern is trying to match the same line as
        // licenseCounts, but is more general. In case the format changes, a
        // more general match may keep doctor mostly working.
        status = LicensesAccepted.none;
      } else if (licenseAccepted.hasMatch(line)) {
        status ??= LicensesAccepted.all;
      }
    }

    if (!_canRunSdkManager()) {
      return LicensesAccepted.unknown;
    }

    try {
      final Process process = await _processManager.start(
        <String>[_androidSdk.sdkManagerPath, '--licenses'],
        environment: _androidSdk.sdkManagerEnv,
      );
      process.stdin.write('n\n');
      // We expect logcat streams to occasionally contain invalid utf-8,
      // see: https://github.com/flutter/flutter/pull/8864.
      final Future<void> output = process.stdout
        .transform<String>(const Utf8Decoder(reportErrors: false))
        .transform<String>(const LineSplitter())
        .listen(_handleLine)
        .asFuture<void>(null);
      final Future<void> errors = process.stderr
        .transform<String>(const Utf8Decoder(reportErrors: false))
        .transform<String>(const LineSplitter())
        .listen(_handleLine)
        .asFuture<void>(null);
      await Future.wait<void>(<Future<void>>[output, errors]);
      return status ?? LicensesAccepted.unknown;
    } on ProcessException catch (e) {
      _logger.printTrace('Failed to run Android sdk manager: $e');
      return LicensesAccepted.unknown;
    }
  }

  /// Run the Android SDK manager tool in order to accept SDK licenses.
  Future<bool> runLicenseManager() async {
    if (_androidSdk == null) {
      _logger.printStatus(_userMessages.androidSdkShort);
      return false;
    }

    if (!_canRunSdkManager()) {
      throwToolExit(_userMessages.androidMissingSdkManager(_androidSdk.sdkManagerPath, _platform));
    }

    try {
      final Process process = await _processManager.start(
        <String>[_androidSdk.sdkManagerPath, '--licenses'],
        environment: _androidSdk.sdkManagerEnv,
      );

      // The real stdin will never finish streaming. Pipe until the child process
      // finishes.
      unawaited(process.stdin.addStream(_stdio.stdin)
        // If the process exits unexpectedly with an error, that will be
        // handled by the caller.
        .catchError((dynamic err, StackTrace stack) {
          _logger.printTrace('Echoing stdin to the licenses subprocess failed:');
          _logger.printTrace('$err\n$stack');
        }
      ));

      // Wait for stdout and stderr to be fully processed, because process.exitCode
      // may complete first.
      try {
        await Future.wait<void>(<Future<void>>[
          _stdio.addStdoutStream(process.stdout),
          _stdio.addStderrStream(process.stderr),
        ]);
      } on Exception catch (err, stack) {
        _logger.printTrace('Echoing stdout or stderr from the license subprocess failed:');
        _logger.printTrace('$err\n$stack');
      }

      final int exitCode = await process.exitCode;
      return exitCode == 0;
    } on ProcessException catch (e) {
      throwToolExit(_userMessages.androidCannotRunSdkManager(
        _androidSdk.sdkManagerPath,
        e.toString(),
        _platform,
      ));
    }
  }

  bool _canRunSdkManager() {
    final String sdkManagerPath = _androidSdk.sdkManagerPath;
    return _processManager.canRun(sdkManagerPath);
  }
}
