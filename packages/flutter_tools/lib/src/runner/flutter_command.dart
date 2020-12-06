// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/io.dart' as io;
import '../base/signals.dart';
import '../base/terminal.dart';
import '../base/user_messages.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/targets/icon_tree_shaker.dart' show kIconTreeShakerEnabledDefault;
import '../bundle.dart' as bundle;
import '../cache.dart';
import '../dart/generate_synthetic_packages.dart';
import '../dart/package_map.dart';
import '../dart/pub.dart';
import '../device.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import 'flutter_command_runner.dart';

export '../cache.dart' show DevelopmentArtifact;

enum ExitStatus {
  success,
  warning,
  fail,
  killed,
}

/// [FlutterCommand]s' subclasses' [FlutterCommand.runCommand] can optionally
/// provide a [FlutterCommandResult] to furnish additional information for
/// analytics.
class FlutterCommandResult {
  const FlutterCommandResult(
    this.exitStatus, {
    this.timingLabelParts,
    this.endTimeOverride,
  });

  /// A command that succeeded. It is used to log the result of a command invocation.
  factory FlutterCommandResult.success() {
    return const FlutterCommandResult(ExitStatus.success);
  }

  /// A command that exited with a warning. It is used to log the result of a command invocation.
  factory FlutterCommandResult.warning() {
    return const FlutterCommandResult(ExitStatus.warning);
  }

  /// A command that failed. It is used to log the result of a command invocation.
  factory FlutterCommandResult.fail() {
    return const FlutterCommandResult(ExitStatus.fail);
  }

  final ExitStatus exitStatus;

  /// Optional data that can be appended to the timing event.
  /// https://developers.google.com/analytics/devguides/collection/analyticsjs/field-reference#timingLabel
  /// Do not add PII.
  final List<String> timingLabelParts;

  /// Optional epoch time when the command's non-interactive wait time is
  /// complete during the command's execution. Use to measure user perceivable
  /// latency without measuring user interaction time.
  ///
  /// [FlutterCommand] will automatically measure and report the command's
  /// complete time if not overridden.
  final DateTime endTimeOverride;

  @override
  String toString() {
    switch (exitStatus) {
      case ExitStatus.success:
        return 'success';
      case ExitStatus.warning:
        return 'warning';
      case ExitStatus.fail:
        return 'fail';
      case ExitStatus.killed:
        return 'killed';
      default:
        assert(false);
        return null;
    }
  }
}

/// Common flutter command line options.
class FlutterOptions {
  static const String kExtraFrontEndOptions = 'extra-front-end-options';
  static const String kExtraGenSnapshotOptions = 'extra-gen-snapshot-options';
  static const String kEnableExperiment = 'enable-experiment';
  static const String kFileSystemRoot = 'filesystem-root';
  static const String kFileSystemScheme = 'filesystem-scheme';
  static const String kSplitDebugInfoOption = 'split-debug-info';
  static const String kDartObfuscationOption = 'obfuscate';
  static const String kDartDefinesOption = 'dart-define';
  static const String kBundleSkSLPathOption = 'bundle-sksl-path';
  static const String kPerformanceMeasurementFile = 'performance-measurement-file';
  static const String kNullSafety = 'sound-null-safety';
  static const String kDeviceUser = 'device-user';
  static const String kDeviceTimeout = 'device-timeout';
  static const String kAnalyzeSize = 'analyze-size';
  static const String kNullAssertions = 'null-assertions';
}

abstract class FlutterCommand extends Command<void> {
  /// The currently executing command (or sub-command).
  ///
  /// Will be `null` until the top-most command has begun execution.
  static FlutterCommand get current => context.get<FlutterCommand>();

  /// The option name for a custom observatory port.
  static const String observatoryPortOption = 'observatory-port';

  /// The flag name for whether or not to use ipv6.
  static const String ipv6Flag = 'ipv6';

  @override
  ArgParser get argParser => _argParser;
  final ArgParser _argParser = ArgParser(
    allowTrailingOptions: false,
    usageLineLength: globals.outputPreferences.wrapText ? globals.outputPreferences.wrapColumn : null,
  );

  @override
  FlutterCommandRunner get runner => super.runner as FlutterCommandRunner;

  bool _requiresPubspecYaml = false;

  /// Whether this command uses the 'target' option.
  bool _usesTargetOption = false;

  bool _usesPubOption = false;

  bool _usesPortOption = false;

  bool _usesIpv6Flag = false;

  bool get shouldRunPub => _usesPubOption && boolArg('pub');

  bool get shouldUpdateCache => true;

  bool get deprecated => false;

  @override
  bool get hidden => deprecated;

  bool _excludeDebug = false;

  BuildMode _defaultBuildMode;

  void requiresPubspecYaml() {
    _requiresPubspecYaml = true;
  }

  void usesWebOptions({ bool hide = true }) {
    argParser.addOption('web-hostname',
      defaultsTo: 'localhost',
      help:
        'The hostname that the web sever will use to resolve an IP to serve '
        'from. The unresolved hostname is used to launch Chrome when using '
        'the chrome Device. The name "any" may also be used to serve on any '
        'IPV4 for either the Chrome or web-server device.',
      hide: hide,
    );
    argParser.addOption('web-port',
      defaultsTo: null,
      help: 'The host port to serve the web application from. If not provided, the tool '
        'will select a random open port on the host.',
      hide: hide,
    );
    argParser.addOption('web-server-debug-protocol',
      allowed: <String>['sse', 'ws'],
      defaultsTo: 'sse',
      help: 'The protocol (SSE or WebSockets) to use for the debug service proxy '
      'when using the Web Server device and Dart Debug extension. '
      'This is useful for editors/debug adapters that do not support debugging '
      'over SSE (the default protocol for Web Server/Dart Debugger extension).',
      hide: hide,
    );
    argParser.addOption('web-server-debug-backend-protocol',
      allowed: <String>['sse', 'ws'],
      defaultsTo: 'sse',
      help: 'The protocol (SSE or WebSockets) to use for the Dart Debug Extension '
      'backend service when using the Web Server device. '
      'Using WebSockets can improve performance but may fail when connecting through '
      'some proxy servers.',
      hide: hide,
    );
    argParser.addFlag('web-allow-expose-url',
      defaultsTo: false,
      help: 'Enables daemon-to-editor requests (app.exposeUrl) for exposing URLs '
        'when running on remote machines.',
      hide: hide,
    );
    argParser.addFlag('web-run-headless',
      defaultsTo: false,
      help: 'Launches the browser in headless mode. Currently only Chrome '
        'supports this option.',
      hide: true,
    );
    argParser.addOption('web-browser-debug-port',
      help: 'The debug port the browser should use. If not specified, a '
        'random port is selected. Currently only Chrome supports this option. '
        'It serves the Chrome DevTools Protocol '
        '(https://chromedevtools.github.io/devtools-protocol/).',
      hide: true,
    );
    argParser.addFlag('web-enable-expression-evaluation',
      defaultsTo: true,
      help: 'Enables expression evaluation in the debugger.',
      hide: hide,
    );
  }

  void usesTargetOption() {
    argParser.addOption('target',
      abbr: 't',
      defaultsTo: bundle.defaultMainPath,
      help: 'The main entry-point file of the application, as run on the device.\n'
            'If the --target option is omitted, but a file name is provided on '
            'the command line, then that is used instead.',
      valueHelp: 'path');
    _usesTargetOption = true;
  }

  String get targetFile {
    if (argResults.wasParsed('target')) {
      return stringArg('target');
    }
    if (argResults.rest.isNotEmpty) {
      return argResults.rest.first;
    }
    return bundle.defaultMainPath;
  }

  void usesPubOption({bool hide = false}) {
    argParser.addFlag('pub',
      defaultsTo: true,
      hide: hide,
      help: 'Whether to run "flutter pub get" before executing this command.');
    _usesPubOption = true;
  }

  /// Adds flags for using a specific filesystem root and scheme.
  ///
  /// [hide] indicates whether or not to hide these options when the user asks
  /// for help.
  void usesFilesystemOptions({ @required bool hide }) {
    argParser
      ..addOption('output-dill',
        hide: hide,
        help: 'Specify the path to frontend server output kernel file.',
      )
      ..addMultiOption(FlutterOptions.kFileSystemRoot,
        hide: hide,
        help: 'Specify the path, that is used as root in a virtual file system\n'
            'for compilation. Input file name should be specified as Uri in\n'
            'filesystem-scheme scheme. Use only in Dart 2 mode.\n'
            'Requires --output-dill option to be explicitly specified.\n',
      )
      ..addOption(FlutterOptions.kFileSystemScheme,
        defaultsTo: 'org-dartlang-root',
        hide: hide,
        help: 'Specify the scheme that is used for virtual file system used in\n'
            'compilation. See more details on filesystem-root option.\n',
      );
  }

  /// Adds options for connecting to the Dart VM observatory port.
  void usesPortOptions() {
    argParser.addOption(observatoryPortOption,
        help: '(deprecated use host-vmservice-port instead) '
              'Listen to the given port for an observatory debugger connection.\n'
              'Specifying port 0 (the default) will find a random free port.',
    );
    argParser.addOption('device-vmservice-port',
      help: 'Look for vmservice connections only from the specified port.\n'
            'Specifying port 0 (the default) will accept the first vmservice '
            'discovered.',
    );
    argParser.addOption('host-vmservice-port',
      help: 'When a device-side vmservice port is forwarded to a host-side '
            'port, use this value as the host port.\nSpecifying port 0 '
            '(the default) will find a random free host port.'
    );
    _usesPortOption = true;
  }

  void addDdsOptions({@required bool verboseHelp}) {
    argParser.addFlag(
      'disable-dds',
      hide: !verboseHelp,
      help: 'Disable the Dart Developer Service (DDS). This flag should only be provided'
            ' when attaching to an application with an existing DDS instance (e.g.,'
            ' attaching to an application currently connected to by "flutter run") or'
            ' when running certain tests.\n'
            'Note: passing this flag may degrade IDE functionality if a DDS instance is not'
            ' already connected to the target application.'
    );
  }

  /// Gets the vmservice port provided to in the 'observatory-port' or
  /// 'host-vmservice-port option.
  ///
  /// Only one of "host-vmservice-port" and "observatory-port" may be
  /// specified.
  ///
  /// If no port is set, returns null.
  int get hostVmservicePort {
    if (!_usesPortOption ||
        (argResults['observatory-port'] == null &&
      argResults['host-vmservice-port'] == null)) {
      return null;
    }
    if (argResults.wasParsed('observatory-port') &&
        argResults.wasParsed('host-vmservice-port')) {
      throwToolExit('Only one of "--observatory-port" and '
        '"--host-vmservice-port" may be specified.');
    }
    try {
      return int.parse(stringArg('observatory-port') ?? stringArg('host-vmservice-port'));
    } on FormatException catch (error) {
      throwToolExit('Invalid port for `--observatory-port/--host-vmservice-port`: $error');
    }
    return null;
  }

  /// Gets the vmservice port provided to in the 'device-vmservice-port' option.
  ///
  /// If no port is set, returns null.
  int get deviceVmservicePort {
    if (!_usesPortOption || argResults['device-vmservice-port'] == null) {
      return null;
    }
    try {
      return int.parse(stringArg('device-vmservice-port'));
    } on FormatException catch (error) {
      throwToolExit('Invalid port for `--device-vmservice-port`: $error');
    }
    return null;
  }

  void usesIpv6Flag() {
    argParser.addFlag(ipv6Flag,
      hide: true,
      negatable: false,
      help: 'Binds to IPv6 localhost instead of IPv4 when the flutter tool '
            'forwards the host port to a device port. Not used when the '
            '--debug-port flag is not set.',
    );
    _usesIpv6Flag = true;
  }

  bool get ipv6 => _usesIpv6Flag ? boolArg('ipv6') : null;

  void usesBuildNumberOption() {
    argParser.addOption('build-number',
        help: 'An identifier used as an internal version number.\n'
              'Each build must have a unique identifier to differentiate it from previous builds.\n'
              'It is used to determine whether one build is more recent than another, with higher numbers indicating more recent build.\n'
              "On Android it is used as 'versionCode'.\n"
              "On Xcode builds it is used as 'CFBundleVersion'",
    );
  }

  void usesBuildNameOption() {
    argParser.addOption('build-name',
        help: 'A "x.y.z" string used as the version number shown to users.\n'
              'For each new version of your app, you will provide a version number to differentiate it from previous versions.\n'
              "On Android it is used as 'versionName'.\n"
              "On Xcode builds it is used as 'CFBundleShortVersionString'",
        valueHelp: 'x.y.z');
  }

  void usesDartDefineOption() {
    argParser.addMultiOption(
      FlutterOptions.kDartDefinesOption,
      help: 'Additional key-value pairs that will be available as constants '
            'from the String.fromEnvironment, bool.fromEnvironment, int.fromEnvironment, '
            'and double.fromEnvironment constructors.\n'
            'Multiple defines can be passed by repeating --dart-define multiple times.',
      valueHelp: 'foo=bar',
    );
  }

  void usesDeviceUserOption() {
    argParser.addOption(FlutterOptions.kDeviceUser,
      help: 'Identifier number for a user or work profile on Android only. Run "adb shell pm list users" for available identifiers.',
      valueHelp: '10');
  }

  void usesDeviceTimeoutOption() {
    argParser.addOption(
      FlutterOptions.kDeviceTimeout,
      help: 'Time in seconds to wait for devices to attach. Longer timeouts may be necessary for networked devices.',
      valueHelp: '10'
    );
  }

  Duration get deviceDiscoveryTimeout {
    if (_deviceDiscoveryTimeout == null
        && argResults.options.contains(FlutterOptions.kDeviceTimeout)
        && argResults.wasParsed(FlutterOptions.kDeviceTimeout)) {
      final int timeoutSeconds = int.tryParse(stringArg(FlutterOptions.kDeviceTimeout));
      if (timeoutSeconds == null) {
        throwToolExit( 'Could not parse --${FlutterOptions.kDeviceTimeout} argument. It must be an integer.');
      }
      _deviceDiscoveryTimeout = Duration(seconds: timeoutSeconds);
    }
    return _deviceDiscoveryTimeout;
  }
  Duration _deviceDiscoveryTimeout;

  void addBuildModeFlags({ bool defaultToRelease = true, bool verboseHelp = false, bool excludeDebug = false }) {
    // A release build must be the default if a debug build is not possible.
    assert(defaultToRelease || !excludeDebug);
    _excludeDebug = excludeDebug;
    defaultBuildMode = defaultToRelease ? BuildMode.release : BuildMode.debug;

    if (!excludeDebug) {
      argParser.addFlag('debug',
        negatable: false,
        help: 'Build a debug version of your app${defaultToRelease ? '' : ' (default mode)'}.');
    }
    argParser.addFlag('profile',
      negatable: false,
      help: 'Build a version of your app specialized for performance profiling.');
    argParser.addFlag('release',
      negatable: false,
      help: 'Build a release version of your app${defaultToRelease ? ' (default mode)' : ''}.');
    argParser.addFlag('jit-release',
      negatable: false,
      hide: !verboseHelp,
      help: 'Build a JIT release version of your app${defaultToRelease ? ' (default mode)' : ''}.');
  }

  void addSplitDebugInfoOption() {
    argParser.addOption(FlutterOptions.kSplitDebugInfoOption,
      help: 'In a release build, this flag reduces application size by storing '
        'Dart program symbols in a separate file on the host rather than in the '
        'application. The value of the flag should be a directory where program '
        'symbol files can be stored for later use. These symbol files contain '
        'the information needed to symbolize Dart stack traces. For an app built '
        "with this flag, the 'flutter symbolize' command with the right program "
        'symbol file is required to obtain a human readable stack trace.\n'
        'This flag cannot be combined with --analyze-size',
      valueHelp: '/project-name/v1.2.3/',
    );
  }

  void addDartObfuscationOption() {
    argParser.addFlag(FlutterOptions.kDartObfuscationOption,
      help: 'In a release build, this flag removes identifiers and replaces them '
        'with randomized values for the purposes of source code obfuscation. This '
        'flag must always be combined with "--split-debug-info" option, the '
        'mapping between the values and the original identifiers is stored in the '
        'symbol map created in the specified directory. For an app built with this '
        'flag, the \'flutter symbolize\' command with the right program '
        'symbol file is required to obtain a human readable stack trace.\n\n'
        'Because all identifiers are renamed, methods like Object.runtimeType, '
        'Type.toString, Enum.toString, Stacktrace.toString, Symbol.toString '
        '(for constant symbols or those generated by runtime system) will '
        'return obfuscated results. Any code or tests that rely on exact names '
        'will break.'
    );
  }

  void addBundleSkSLPathOption({ @required bool hide }) {
    argParser.addOption(FlutterOptions.kBundleSkSLPathOption,
      help: 'A path to a file containing precompiled SkSL shaders generated '
        'during "flutter run". These can be included in an application to '
        'improve the first frame render times.',
      hide: hide,
      valueHelp: '/project-name/flutter_1.sksl'
    );
  }

  void addTreeShakeIconsFlag({
    bool enabledByDefault
  }) {
    argParser.addFlag('tree-shake-icons',
      negatable: true,
      defaultsTo: enabledByDefault
        ?? kIconTreeShakerEnabledDefault,
      help: 'Tree shake icon fonts so that only glyphs used by the application remain.',
    );
  }

  void addShrinkingFlag() {
    argParser.addFlag('shrink',
      negatable: true,
      defaultsTo: true,
      help: 'Whether to enable code shrinking on release mode. '
            'When enabling shrinking, you also benefit from obfuscation, '
            'which shortens the names of your app’s classes and members, '
            'and optimization, which applies more aggressive strategies to '
            'further reduce the size of your app. '
            'To learn more, see: https://developer.android.com/studio/build/shrink-code',
      );
  }

  void addNullSafetyModeOptions({ @required bool hide }) {
    argParser.addFlag(FlutterOptions.kNullSafety,
      help:
        'Whether to override the inferred null safety mode. This allows null-safe '
        'libraries to depend on un-migrated (non-null safe) libraries. By default, '
        'Flutter mobile & desktop applications will attempt to run at the null safety '
        'level of their entrypoint library (usually lib/main.dart). Flutter web '
        'applications will default to sound null-safety, unless specifically configured.',
      defaultsTo: null,
      hide: hide,
    );
    argParser.addFlag(FlutterOptions.kNullAssertions,
      help:
        'Perform additional null assertions on the boundaries of migrated and '
        'unmigrated code. This setting is not currently supported on desktop '
        'devices.'
    );
  }

  void usesExtraFrontendOptions() {
    argParser.addMultiOption(FlutterOptions.kExtraFrontEndOptions,
      splitCommas: true,
      hide: true,
    );
  }

  void usesFuchsiaOptions({ bool hide = false }) {
    argParser.addOption(
      'target-model',
      help: 'Target model that determines what core libraries are available',
      defaultsTo: 'flutter',
      hide: hide,
      allowed: const <String>['flutter', 'flutter_runner'],
    );
    argParser.addOption(
      'module',
      abbr: 'm',
      hide: hide,
      help: 'The name of the module (required if attaching to a fuchsia device)',
      valueHelp: 'module-name',
    );
  }

  void addEnableExperimentation({ @required bool hide }) {
    argParser.addMultiOption(
      FlutterOptions.kEnableExperiment,
      help:
        'The name of an experimental Dart feature to enable. For more info '
        'see: https://github.com/dart-lang/sdk/blob/master/docs/process/'
        'experimental-flags.md',
      hide: hide,
    );
  }

  void addBuildPerformanceFile({ bool hide = false }) {
    argParser.addOption(
      FlutterOptions.kPerformanceMeasurementFile,
      help:
        'The name of a file where flutter assemble performance and '
        'cachedness information will be written in a JSON format.'
    );
  }

  /// Adds build options common to all of the desktop build commands.
  void addCommonDesktopBuildOptions({ bool verboseHelp = false }) {
    addBuildModeFlags(verboseHelp: verboseHelp);
    addBuildPerformanceFile(hide: !verboseHelp);
    addBundleSkSLPathOption(hide: !verboseHelp);
    addDartObfuscationOption();
    addEnableExperimentation(hide: !verboseHelp);
    addNullSafetyModeOptions(hide: !verboseHelp);
    addSplitDebugInfoOption();
    addTreeShakeIconsFlag();
    usesAnalyzeSizeFlag();
    usesDartDefineOption();
    usesExtraFrontendOptions();
    usesPubOption();
    usesTargetOption();
    usesTrackWidgetCreation(verboseHelp: verboseHelp);
  }

  set defaultBuildMode(BuildMode value) {
    _defaultBuildMode = value;
  }

  BuildMode getBuildMode() {
    // No debug when _excludeDebug is true.
    // If debug is not excluded, then take the command line flag.
    final bool debugResult = !_excludeDebug && boolArg('debug');
    final List<bool> modeFlags = <bool>[
      debugResult,
      boolArg('jit-release'),
      boolArg('profile'),
      boolArg('release'),
    ];
    if (modeFlags.where((bool flag) => flag).length > 1) {
      throw UsageException('Only one of --debug, --profile, --jit-release, '
                           'or --release can be specified.', null);
    }
    if (debugResult) {
      return BuildMode.debug;
    }
    if (boolArg('profile')) {
      return BuildMode.profile;
    }
    if (boolArg('release')) {
      return BuildMode.release;
    }
    if (boolArg('jit-release')) {
      return BuildMode.jitRelease;
    }
    return _defaultBuildMode;
  }

  void usesFlavorOption() {
    argParser.addOption(
      'flavor',
      help: 'Build a custom app flavor as defined by platform-specific build setup.\n'
            'Supports the use of product flavors in Android Gradle scripts, and '
            'the use of custom Xcode schemes.',
    );
  }

  void usesTrackWidgetCreation({ bool hasEffect = true, @required bool verboseHelp }) {
    argParser.addFlag(
      'track-widget-creation',
      hide: !hasEffect && !verboseHelp,
      defaultsTo: true,
      help: 'Track widget creation locations. This enables features such as the widget inspector. '
            'This parameter is only functional in debug mode (i.e. when compiling JIT, not AOT).',
    );
  }

  void usesAnalyzeSizeFlag() {
    argParser.addFlag(
      FlutterOptions.kAnalyzeSize,
      defaultsTo: false,
      help: 'Whether to produce additional profile information for artifact output size. '
        'This flag is only supported on release builds. When building for Android, a single '
        'ABI must be specified at a time with the --target-platform flag. When building for iOS, '
        'only the symbols from the arm64 architecture are used to analyze code size.\n'
        'This flag cannot be combined with --split-debug-info.'
    );
  }

  /// Compute the [BuildInfo] for the current flutter command.
  /// Commands that build multiple build modes can pass in a [forcedBuildMode]
  /// to be used instead of parsing flags.
  ///
  /// Throws a [ToolExit] if the current set of options is not compatible with
  /// each other.
  BuildInfo getBuildInfo({ BuildMode forcedBuildMode }) {
    final bool trackWidgetCreation = argParser.options.containsKey('track-widget-creation') &&
      boolArg('track-widget-creation');

    final String buildNumber = argParser.options.containsKey('build-number')
      ? stringArg('build-number')
      : null;

    final List<String> experiments =
      argParser.options.containsKey(FlutterOptions.kEnableExperiment)
        ? stringsArg(FlutterOptions.kEnableExperiment).toList()
        : <String>[];
    final List<String> extraGenSnapshotOptions =
      argParser.options.containsKey(FlutterOptions.kExtraGenSnapshotOptions)
        ? stringsArg(FlutterOptions.kExtraGenSnapshotOptions).toList()
        : <String>[];
    final List<String> extraFrontEndOptions =
      argParser.options.containsKey(FlutterOptions.kExtraFrontEndOptions)
          ? stringsArg(FlutterOptions.kExtraFrontEndOptions).toList()
          : <String>[];

    if (experiments.isNotEmpty) {
      for (final String expFlag in experiments) {
        final String flag = '--enable-experiment=' + expFlag;
        extraFrontEndOptions.add(flag);
        extraGenSnapshotOptions.add(flag);
      }
    }

    String codeSizeDirectory;
    if (argParser.options.containsKey(FlutterOptions.kAnalyzeSize) && boolArg(FlutterOptions.kAnalyzeSize)) {
      final Directory directory = globals.fsUtils.getUniqueDirectory(
        globals.fs.directory(getBuildDirectory()),
        'flutter_size',
      );
      directory.createSync(recursive: true);
      codeSizeDirectory = directory.path;
    }

    NullSafetyMode nullSafetyMode = NullSafetyMode.unsound;
    if (argParser.options.containsKey(FlutterOptions.kNullSafety)) {
      final bool nullSafety = boolArg(FlutterOptions.kNullSafety);
      // Explicitly check for `true` and `false` so that `null` results in not
      // passing a flag. This will use the automatically detected null-safety
      // value based on the entrypoint
      if (nullSafety == true) {
        nullSafetyMode = NullSafetyMode.sound;
        extraFrontEndOptions.add('--sound-null-safety');
      } else if (nullSafety == false) {
        nullSafetyMode = NullSafetyMode.unsound;
        extraFrontEndOptions.add('--no-sound-null-safety');
      } else if (extraFrontEndOptions.contains('--enable-experiment=non-nullable')) {
        nullSafetyMode = NullSafetyMode.autodetect;
      }
    }

    final bool dartObfuscation = argParser.options.containsKey(FlutterOptions.kDartObfuscationOption)
      && boolArg(FlutterOptions.kDartObfuscationOption);

    final String splitDebugInfoPath = argParser.options.containsKey(FlutterOptions.kSplitDebugInfoOption)
      ? stringArg(FlutterOptions.kSplitDebugInfoOption)
      : null;

    if (dartObfuscation && (splitDebugInfoPath == null || splitDebugInfoPath.isEmpty)) {
      throwToolExit(
        '"--${FlutterOptions.kDartObfuscationOption}" can only be used in '
        'combination with "--${FlutterOptions.kSplitDebugInfoOption}"',
      );
    }
    final BuildMode buildMode = forcedBuildMode ?? getBuildMode();
    if (buildMode != BuildMode.release && codeSizeDirectory != null) {
      throwToolExit('--analyze-size can only be used on release builds.');
    }
    if (codeSizeDirectory != null && splitDebugInfoPath != null) {
      throwToolExit('--analyze-size cannot be combined with --split-debug-info.');
    }

    final bool treeShakeIcons = argParser.options.containsKey('tree-shake-icons')
      && buildMode.isPrecompiled
      && boolArg('tree-shake-icons');

    final String bundleSkSLPath = argParser.options.containsKey(FlutterOptions.kBundleSkSLPathOption)
      ? stringArg(FlutterOptions.kBundleSkSLPathOption)
      : null;

    final String performanceMeasurementFile = argParser.options.containsKey(FlutterOptions.kPerformanceMeasurementFile)
      ? stringArg(FlutterOptions.kPerformanceMeasurementFile)
      : null;

    return BuildInfo(buildMode,
      argParser.options.containsKey('flavor')
        ? stringArg('flavor')
        : null,
      trackWidgetCreation: trackWidgetCreation,
      extraFrontEndOptions: extraFrontEndOptions?.isNotEmpty ?? false
        ? extraFrontEndOptions
        : null,
      extraGenSnapshotOptions: extraGenSnapshotOptions?.isNotEmpty ?? false
        ? extraGenSnapshotOptions
        : null,
      fileSystemRoots: argParser.options.containsKey(FlutterOptions.kFileSystemRoot)
          ? stringsArg(FlutterOptions.kFileSystemRoot)
          : null,
      fileSystemScheme: argParser.options.containsKey(FlutterOptions.kFileSystemScheme)
          ? stringArg(FlutterOptions.kFileSystemScheme)
          : null,
      buildNumber: buildNumber,
      buildName: argParser.options.containsKey('build-name')
          ? stringArg('build-name')
          : null,
      treeShakeIcons: treeShakeIcons,
      splitDebugInfoPath: splitDebugInfoPath,
      dartObfuscation: dartObfuscation,
      dartDefines: argParser.options.containsKey(FlutterOptions.kDartDefinesOption)
          ? stringsArg(FlutterOptions.kDartDefinesOption)
          : const <String>[],
      bundleSkSLPath: bundleSkSLPath,
      dartExperiments: experiments,
      performanceMeasurementFile: performanceMeasurementFile,
      packagesPath: globalResults['packages'] as String ?? '.packages',
      nullSafetyMode: nullSafetyMode,
      codeSizeDirectory: codeSizeDirectory,
    );
  }

  void setupApplicationPackages() {
    applicationPackages ??= ApplicationPackageStore();
  }

  /// The path to send to Google Analytics. Return null here to disable
  /// tracking of the command.
  Future<String> get usagePath async {
    if (parent is FlutterCommand) {
      final FlutterCommand commandParent = parent as FlutterCommand;
      final String path = await commandParent.usagePath;
      // Don't report for parents that return null for usagePath.
      return path == null ? null : '$path/$name';
    } else {
      return name;
    }
  }

  /// Additional usage values to be sent with the usage ping.
  Future<Map<CustomDimensions, String>> get usageValues async =>
      const <CustomDimensions, String>{};

  /// Runs this command.
  ///
  /// Rather than overriding this method, subclasses should override
  /// [verifyThenRunCommand] to perform any verification
  /// and [runCommand] to execute the command
  /// so that this method can record and report the overall time to analytics.
  @override
  Future<void> run() {
    final DateTime startTime = globals.systemClock.now();

    return context.run<void>(
      name: 'command',
      overrides: <Type, Generator>{FlutterCommand: () => this},
      body: () async {
        // Prints the welcome message if needed.
        globals.flutterUsage.printWelcome();
        _printDeprecationWarning();
        final String commandPath = await usagePath;
        _registerSignalHandlers(commandPath, startTime);
        FlutterCommandResult commandResult = FlutterCommandResult.fail();
        try {
          commandResult = await verifyThenRunCommand(commandPath);
        } finally {
          final DateTime endTime = globals.systemClock.now();
          globals.printTrace(userMessages.flutterElapsedTime(name, getElapsedAsMilliseconds(endTime.difference(startTime))));
          _sendPostUsage(commandPath, commandResult, startTime, endTime);
        }
      },
    );
  }

  void _printDeprecationWarning() {
    if (deprecated) {
      globals.printStatus('$warningMark The "$name" command is deprecated and '
          'will be removed in a future version of Flutter. '
          'See https://flutter.dev/docs/development/tools/sdk/releases '
          'for previous releases of Flutter.');
      globals.printStatus('');
    }
  }

  void _registerSignalHandlers(String commandPath, DateTime startTime) {
    final SignalHandler handler = (io.ProcessSignal s) {
      Cache.releaseLock();
      _sendPostUsage(
        commandPath,
        const FlutterCommandResult(ExitStatus.killed),
        startTime,
        globals.systemClock.now(),
      );
    };
    globals.signals.addHandler(io.ProcessSignal.SIGTERM, handler);
    globals.signals.addHandler(io.ProcessSignal.SIGINT, handler);
  }

  /// Logs data about this command.
  ///
  /// For example, the command path (e.g. `build/apk`) and the result,
  /// as well as the time spent running it.
  void _sendPostUsage(
    String commandPath,
    FlutterCommandResult commandResult,
    DateTime startTime,
    DateTime endTime,
  ) {
    if (commandPath == null) {
      return;
    }
    assert(commandResult != null);
    // Send command result.
    CommandResultEvent(commandPath, commandResult).send();

    // Send timing.
    final List<String> labels = <String>[
      if (commandResult.exitStatus != null)
        getEnumName(commandResult.exitStatus),
      if (commandResult.timingLabelParts?.isNotEmpty ?? false)
        ...commandResult.timingLabelParts,
    ];

    final String label = labels
        .where((String label) => !_isBlank(label))
        .join('-');
    globals.flutterUsage.sendTiming(
      'flutter',
      name,
      // If the command provides its own end time, use it. Otherwise report
      // the duration of the entire execution.
      (commandResult.endTimeOverride ?? endTime).difference(startTime),
      // Report in the form of `success-[parameter1-parameter2]`, all of which
      // can be null if the command doesn't provide a FlutterCommandResult.
      label: label == '' ? null : label,
    );
  }

  List<String> get _enabledExperiments => argParser.options.containsKey(FlutterOptions.kEnableExperiment)
    ? stringsArg(FlutterOptions.kEnableExperiment)
    : <String>[];

  /// Perform validation then call [runCommand] to execute the command.
  /// Return a [Future] that completes with an exit code
  /// indicating whether execution was successful.
  ///
  /// Subclasses should override this method to perform verification
  /// then call this method to execute the command
  /// rather than calling [runCommand] directly.
  @mustCallSuper
  Future<FlutterCommandResult> verifyThenRunCommand(String commandPath) async {
    // Populate the cache. We call this before pub get below so that the
    // sky_engine package is available in the flutter cache for pub to find.
    if (shouldUpdateCache) {
      // First always update universal artifacts, as some of these (e.g.
      // ios-deploy on macOS) are required to determine `requiredArtifacts`.
      await globals.cache.updateAll(<DevelopmentArtifact>{DevelopmentArtifact.universal});

      await globals.cache.updateAll(await requiredArtifacts);
    }

    await validateCommand();

    if (shouldRunPub) {
      final FlutterProject project = FlutterProject.current();
      final Environment environment = Environment(
        artifacts: globals.artifacts,
        logger: globals.logger,
        cacheDir: globals.cache.getRoot(),
        engineVersion: globals.flutterVersion.engineRevision,
        fileSystem: globals.fs,
        flutterRootDir: globals.fs.directory(Cache.flutterRoot),
        outputDir: globals.fs.directory(getBuildDirectory()),
        processManager: globals.processManager,
        projectDir: project.directory,
      );

      await generateLocalizationsSyntheticPackage(
        environment: environment,
        buildSystem: globals.buildSystem,
      );

      await pub.get(
        context: PubContext.getVerifyContext(name),
        generateSyntheticPackage: project.manifest.generateSyntheticPackage,
      );
      // All done updating dependencies. Release the cache lock.
      Cache.releaseLock();
      await project.ensureReadyForPlatformSpecificTooling(checkProjects: true);
    } else {
      Cache.releaseLock();
    }

    setupApplicationPackages();

    if (commandPath != null) {
      final Map<CustomDimensions, Object> additionalUsageValues =
        <CustomDimensions, Object>{
          ...?await usageValues,
          CustomDimensions.commandHasTerminal: globals.stdio.hasTerminal,
          CustomDimensions.nullSafety: _enabledExperiments.contains('non-nullable'),
        };
      Usage.command(commandPath, parameters: additionalUsageValues);
    }

    return await runCommand();
  }

  /// The set of development artifacts required for this command.
  ///
  /// Defaults to an empty set. Including [DevelopmentArtifact.universal] is
  /// not required as it is always updated.
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  /// Subclasses must implement this to execute the command.
  /// Optionally provide a [FlutterCommandResult] to send more details about the
  /// execution for analytics.
  Future<FlutterCommandResult> runCommand();

  /// Find and return all target [Device]s based upon currently connected
  /// devices and criteria entered by the user on the command line.
  /// If no device can be found that meets specified criteria,
  /// then print an error message and return null.
  Future<List<Device>> findAllTargetDevices() async {
    if (!globals.doctor.canLaunchAnything) {
      globals.printError(userMessages.flutterNoDevelopmentDevice);
      return null;
    }
    final DeviceManager deviceManager = globals.deviceManager;
    List<Device> devices = await deviceManager.findTargetDevices(FlutterProject.current(), timeout: deviceDiscoveryTimeout);

    if (devices.isEmpty && deviceManager.hasSpecifiedDeviceId) {
      globals.printStatus(userMessages.flutterNoMatchingDevice(deviceManager.specifiedDeviceId));
      return null;
    } else if (devices.isEmpty) {
      if (deviceManager.hasSpecifiedAllDevices) {
        globals.printStatus(userMessages.flutterNoDevicesFound);
      } else {
        globals.printStatus(userMessages.flutterNoSupportedDevices);
      }
      final List<Device> unsupportedDevices = await deviceManager.getDevices();
      if (unsupportedDevices.isNotEmpty) {
        final StringBuffer result = StringBuffer();
        result.writeln(userMessages.flutterFoundButUnsupportedDevices);
        result.writeAll(
          await Device.descriptions(unsupportedDevices)
              .map((String desc) => desc)
              .toList(),
          '\n',
        );
        result.writeln('');
        result.writeln(userMessages.flutterMissPlatformProjects(
          Device.devicesPlatformTypes(unsupportedDevices),
        ));
        globals.printStatus(result.toString());
      }
      return null;
    } else if (devices.length > 1 && !deviceManager.hasSpecifiedAllDevices) {
      if (deviceManager.hasSpecifiedDeviceId) {
       globals.printStatus(userMessages.flutterFoundSpecifiedDevices(devices.length, deviceManager.specifiedDeviceId));
      } else {
        globals.printStatus(userMessages.flutterSpecifyDeviceWithAllOption);
        devices = await deviceManager.getAllConnectedDevices();
      }
      globals.printStatus('');
      await Device.printDevices(devices);
      return null;
    }
    return devices;
  }

  /// Find and return the target [Device] based upon currently connected
  /// devices and criteria entered by the user on the command line.
  /// If a device cannot be found that meets specified criteria,
  /// then print an error message and return null.
  Future<Device> findTargetDevice() async {
    List<Device> deviceList = await findAllTargetDevices();
    if (deviceList == null) {
      return null;
    }
    if (deviceList.length > 1) {
      globals.printStatus(userMessages.flutterSpecifyDevice);
      deviceList = await globals.deviceManager.getAllConnectedDevices();
      globals.printStatus('');
      await Device.printDevices(deviceList);
      return null;
    }
    return deviceList.single;
  }

  @protected
  @mustCallSuper
  Future<void> validateCommand() async {
    if (_requiresPubspecYaml && !isUsingCustomPackagesPath) {
      // Don't expect a pubspec.yaml file if the user passed in an explicit .packages file path.

      // If there is no pubspec in the current directory, look in the parent
      // until one can be found.
      bool changedDirectory = false;
      while (!globals.fs.isFileSync('pubspec.yaml')) {
        final Directory nextCurrent = globals.fs.currentDirectory.parent;
        if (nextCurrent == null || nextCurrent.path == globals.fs.currentDirectory.path) {
          throw ToolExit(userMessages.flutterNoPubspec);
        }
        globals.fs.currentDirectory = nextCurrent;
        changedDirectory = true;
      }
      if (changedDirectory) {
        globals.printStatus('Changing current working directory to: ${globals.fs.currentDirectory.path}');
      }
    }

    if (_usesTargetOption) {
      final String targetPath = targetFile;
      if (!globals.fs.isFileSync(targetPath)) {
        throw ToolExit(userMessages.flutterTargetFileMissing(targetPath));
      }
    }
  }

  @override
  String get usage {
    final String usageWithoutDescription = super.usage.substring(
      // The description plus two newlines.
      description.length + 2,
    );
    final String help = <String>[
      if (deprecated)
        '$warningMark Deprecated. This command will be removed in a future version of Flutter.',
      description,
      '',
      'Global options:',
      runner.argParser.usage,
      '',
      usageWithoutDescription,
    ].join('\n');
    return help;
  }

  ApplicationPackageStore applicationPackages;

  /// Gets the parsed command-line option named [name] as `bool`.
  bool boolArg(String name) => argResults[name] as bool;

  /// Gets the parsed command-line option named [name] as `String`.
  String stringArg(String name) => argResults[name] as String;

  /// Gets the parsed command-line option named [name] as `List<String>`.
  List<String> stringsArg(String name) => argResults[name] as List<String>;
}

/// A mixin which applies an implementation of [requiredArtifacts] that only
/// downloads artifacts corresponding to an attached device.
mixin DeviceBasedDevelopmentArtifacts on FlutterCommand {
  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async {
    // If there are no attached devices, use the default configuration.
    // Otherwise, only add development artifacts which correspond to a
    // connected device.
    final List<Device> devices = await globals.deviceManager.getDevices();
    if (devices.isEmpty) {
      return super.requiredArtifacts;
    }
    final Set<DevelopmentArtifact> artifacts = <DevelopmentArtifact>{
      DevelopmentArtifact.universal,
    };
    for (final Device device in devices) {
      final TargetPlatform targetPlatform = await device.targetPlatform;
      final DevelopmentArtifact developmentArtifact = _artifactFromTargetPlatform(targetPlatform);
      if (developmentArtifact != null) {
        artifacts.add(developmentArtifact);
      }
    }
    return artifacts;
  }
}

/// A mixin which applies an implementation of [requiredArtifacts] that only
/// downloads artifacts corresponding to a target device.
mixin TargetPlatformBasedDevelopmentArtifacts on FlutterCommand {
  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async {
    // If there is no specified target device, fallback to the default
    // confiugration.
    final String rawTargetPlatform = stringArg('target-platform');
    final TargetPlatform targetPlatform = getTargetPlatformForName(rawTargetPlatform);
    if (targetPlatform == null) {
      return super.requiredArtifacts;
    }

    final Set<DevelopmentArtifact> artifacts = <DevelopmentArtifact>{};
    final DevelopmentArtifact developmentArtifact = _artifactFromTargetPlatform(targetPlatform);
    if (developmentArtifact != null) {
      artifacts.add(developmentArtifact);
    }
    return artifacts;
  }
}

// Returns the development artifact for the target platform, or null
// if none is supported
DevelopmentArtifact _artifactFromTargetPlatform(TargetPlatform targetPlatform) {
  switch (targetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.android_arm:
    case TargetPlatform.android_arm64:
    case TargetPlatform.android_x64:
    case TargetPlatform.android_x86:
      return DevelopmentArtifact.androidGenSnapshot;
    case TargetPlatform.web_javascript:
      return DevelopmentArtifact.web;
    case TargetPlatform.ios:
      return DevelopmentArtifact.iOS;
    case TargetPlatform.darwin_x64:
      if (featureFlags.isMacOSEnabled) {
        return DevelopmentArtifact.macOS;
      }
      return null;
    case TargetPlatform.windows_x64:
      if (featureFlags.isWindowsEnabled) {
        return DevelopmentArtifact.windows;
      }
      return null;
    case TargetPlatform.linux_x64:
      if (featureFlags.isLinuxEnabled) {
        return DevelopmentArtifact.linux;
      }
      return null;
    case TargetPlatform.fuchsia_arm64:
    case TargetPlatform.fuchsia_x64:
    case TargetPlatform.tester:
      // No artifacts currently supported.
      return null;
  }
  return null;
}

/// Returns true if s is either null, empty or is solely made of whitespace characters (as defined by String.trim).
bool _isBlank(String s) => s == null || s.trim().isEmpty;
