// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config_types.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../android/android_engine_cli_flags.dart';
import '../application_package.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/io.dart' as io;
import '../base/io.dart';
import '../base/os.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../bundle.dart' as bundle;
import '../cache.dart';
import '../convert.dart';
import '../dart/package_map.dart';
import '../dart/pub.dart';
import '../device.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/unified_analytics.dart';
import '../version.dart';
import '../web/web_options.dart';
import 'flutter_command_runner.dart';
import 'options/common_options.dart';
import 'options/option_bundle.dart';
import 'options/option_descriptor.dart';
import 'options/safe_arg_results.dart';
import 'target_devices.dart';

export '../cache.dart' show DevelopmentArtifact;
export 'options/common_options.dart';
export 'options/option_bundle.dart';
export 'options/option_descriptor.dart';
export 'options/safe_arg_results.dart';

abstract class DotEnvRegex {
  // Dot env multi-line block value regex
  static final multiLineBlock = RegExp(r'^\s*([a-zA-Z_]+[a-zA-Z0-9_]*)\s*=\s*"""\s*(.*)$');

  // Dot env full line value regex (eg FOO=bar)
  // Entire line will be matched including key and value
  static final keyValue = RegExp(r'^\s*([a-zA-Z_]+[a-zA-Z0-9_]*)\s*=\s*(.*)?$');

  // Dot env value wrapped in double quotes regex (eg FOO="bar")
  // Value between double quotes will be matched (eg only bar in "bar")
  static final doubleQuotedValue = RegExp(r'^"(.*)"\s*(\#\s*.*)?$');

  // Dot env value wrapped in single quotes regex (eg FOO='bar')
  // Value between single quotes will be matched (eg only bar in 'bar')
  static final singleQuotedValue = RegExp(r"^'(.*)'\s*(\#\s*.*)?$");

  // Dot env value wrapped in back quotes regex (eg FOO=`bar`)
  // Value between back quotes will be matched (eg only bar in `bar`)
  static final backQuotedValue = RegExp(r'^`(.*)`\s*(\#\s*.*)?$');

  // Dot env value without quotes regex (eg FOO=bar)
  // Value without quotes will be matched (eg full value after the equals sign)
  static final unquotedValue = RegExp(r'^([^#\n\s]*)\s*(?:\s*#\s*(.*))?$');
}

abstract class _HttpRegex {
  // https://datatracker.ietf.org/doc/html/rfc7230#section-3.2
  static const _vchar = r'\x21-\x7E';
  static const _spaceOrTab = r'\x20\x09';
  static const _nonDelimiterVchar =
      r'\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7A\x7C\x7E';

  // --web-header is provided as key=value for consistency with --dart-define
  static final httpHeader = RegExp(
    '^([$_nonDelimiterVchar]+)'
    r'\s*=\s*'
    '([$_vchar$_spaceOrTab]+)'
    r'$',
  );
}

enum ExitStatus { success, warning, fail, killed }

/// [FlutterCommand]s' subclasses' [FlutterCommand.runCommand] can optionally
/// provide a [FlutterCommandResult] to furnish additional information for
/// analytics.
class FlutterCommandResult {
  const FlutterCommandResult(this.exitStatus, {this.timingLabelParts, this.endTimeOverride});

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
  final List<String?>? timingLabelParts;

  /// Optional epoch time when the command's non-interactive wait time is
  /// complete during the command's execution. Use to measure user perceivable
  /// latency without measuring user interaction time.
  ///
  /// [FlutterCommand] will automatically measure and report the command's
  /// complete time if not overridden.
  final DateTime? endTimeOverride;

  @override
  String toString() => exitStatus.name;
}

/// Common flutter command line options.
abstract final class FlutterOptions {
  static const kFrontendServerStarterPath = 'frontend-server-starter-path';
  static const kExtraFrontEndOptions = 'extra-front-end-options';
  static const kExtraGenSnapshotOptions = 'extra-gen-snapshot-options';
  static const kEnableExperiment = 'enable-experiment';
  static const kFileSystemRoot = 'filesystem-root';
  static const kFileSystemScheme = 'filesystem-scheme';
  static const kSplitDebugInfoOption = 'split-debug-info';
  static const kDartObfuscationOption = 'obfuscate';
  static const kDartDefinesOption = 'dart-define';
  static const kDartDefineFromFileOption = 'dart-define-from-file';
  static const kWebDefinesOption = 'web-define';
  static const kPerformanceMeasurementFile = 'performance-measurement-file';
  static const kDeviceUser = 'device-user';
  static const kDeviceTimeout = 'device-timeout';
  static const kDeviceConnection = 'device-connection';
  static const kAnalyzeSize = 'analyze-size';
  static const kCodeSizeDirectory = 'code-size-directory';
  static const kAndroidGradleDaemon = 'android-gradle-daemon';
  static const kDeferredComponents = 'deferred-components';
  static const kAndroidProjectArgs = 'android-project-arg';
  static const kAndroidGradleProjectCacheDir = 'android-project-cache-dir';
  static const kAndroidSkipBuildDependencyValidation = 'android-skip-build-dependency-validation';
  static const kInitializeFromDill = 'initialize-from-dill';
  static const kAssumeInitializeFromDillUpToDate = 'assume-initialize-from-dill-up-to-date';
  static const kNativeAssetsYamlFile = 'native-assets-yaml-file';
  static const kFatalWarnings = 'fatal-warnings';
  static const kUseApplicationBinary = 'use-application-binary';
  static const kWebBrowserFlag = 'web-browser-flag';
  static const kWebResourcesCdnFlag = 'web-resources-cdn';
  static const kWebWasmFlag = 'wasm';
  static const kWebExperimentalHotReload = 'web-experimental-hot-reload';
  static const kEnableImpeller = 'enable-impeller';
  static const kCodesignIdentity = 'codesign-identity';
  static const kCodesign = 'codesign';
}

/// flutter command categories for usage.
abstract final class FlutterCommandCategory {
  static const sdk = 'Flutter SDK';
  static const project = 'Project';
  static const tools = 'Tools & Devices';
}

abstract class FlutterCommand extends Command<void> {
  FlutterCommand({this.verboseHelp = false});

  /// Whether this command was invoked with verbose help enabled.
  final bool verboseHelp;

  /// The currently executing command (or sub-command).

  ///
  /// Will be `null` until the top-most command has begun execution.
  static FlutterCommand? get current => context.get<FlutterCommand>();

  /// The option name for a custom VM Service port.
  static const vmServicePortOption = 'vm-service-port';

  /// The option name for a custom DevTools server address.
  static const kDevToolsServerAddress = 'devtools-server-address';

  /// The flag name for whether to launch the DevTools or not.
  static const kEnableDevTools = 'devtools';

  /// The flag name for whether or not to use ipv6.
  static const ipv6Flag = 'ipv6';

  /// The dart define used for adding the Flutter version at runtime.
  @visibleForTesting
  static const flutterVersionDefine = 'FLUTTER_VERSION';

  /// The dart define used for adding the Flutter channel at runtime.
  @visibleForTesting
  static const flutterChannelDefine = 'FLUTTER_CHANNEL';

  /// The dart define used for adding the Flutter git URL at runtime.
  @visibleForTesting
  static const flutterGitUrlDefine = 'FLUTTER_GIT_URL';

  /// The dart define used for adding the Flutter framework revision at runtime.
  @visibleForTesting
  static const flutterFrameworkRevisionDefine = 'FLUTTER_FRAMEWORK_REVISION';

  /// The dart define used for adding the Flutter engine revision at runtime.
  @visibleForTesting
  static const flutterEngineRevisionDefine = 'FLUTTER_ENGINE_REVISION';

  /// The dart define used for adding the Dart version at runtime.
  @visibleForTesting
  static const flutterDartVersionDefine = 'FLUTTER_DART_VERSION';

  /// List of all dart defines used for adding Flutter version information at runtime
  @visibleForTesting
  static const flutterVersionDartDefines = <String>[
    flutterVersionDefine,
    flutterChannelDefine,
    flutterGitUrlDefine,
    flutterFrameworkRevisionDefine,
    flutterEngineRevisionDefine,
    flutterDartVersionDefine,
  ];

  @override
  ArgParser get argParser => _argParser;
  final _argParser = ArgParser(
    usageLineLength: globals.outputPreferences.wrapText
        ? globals.outputPreferences.wrapColumn
        : null,
  );

  @override
  FlutterCommandRunner? get runner => super.runner as FlutterCommandRunner?;

  var _requiresPubspecYaml = false;

  /// Whether this command uses the 'target' option.
  var _usesTargetOption = false;

  /// Enables the target option flag behavior on this command.
  void enableUsesTargetOption() {
    _usesTargetOption = true;
  }

  var _usesPubOption = false;

  /// Enables the pub option flag behavior on this command.
  void enableUsesPubOption() {
    _usesPubOption = true;
  }

  var _usesPortOption = false;

  var _usesIpv6Flag = false;

  var _usesFatalWarnings = false;

  DeprecationBehavior get deprecationBehavior => DeprecationBehavior.none;

  bool get shouldRunPub => _usesPubOption && boolArg('pub');

  bool get outputMachineFormat =>
      argParser.options.containsKey(FlutterGlobalOptions.kMachineFlag) &&
      boolArg(FlutterGlobalOptions.kMachineFlag);

  bool get shouldUpdateCache => true;

  bool get deprecated => false;

  ProcessInfo get processInfo => globals.processInfo;

  /// When the command runs and this is true, trigger an async process to
  /// discover devices from discoverers that support wireless devices for an
  /// extended amount of time and refresh the device cache with the results.
  bool get refreshWirelessDevices => false;

  @override
  bool get hidden => deprecated;

  var _excludeDebug = false;
  var _excludeRelease = false;

  /// Grabs the [Analytics] instance from the global context. It is defined
  /// at the [FlutterCommand] level to enable any classes that extend it to
  /// easily reference it or overwrite as necessary.
  Analytics get analytics => globals.analytics;

  final Map<String, OptionDescriptor<Object?>> _optionRegistry =
      <String, OptionDescriptor<Object?>>{};

  /// Option descriptor registry for type-safe lookups.
  Map<String, OptionDescriptor<Object?>> get optionRegistry => _optionRegistry;

  /// Registers an [OptionBundle] with this command.
  void registerOptionBundle(OptionBundle bundle) {
    bundle.register(this, argParser, _optionRegistry);
  }

  /// Registers multiple [OptionBundle] instances with this command.
  void registerOptionBundles(List<OptionBundle> bundles) => bundles.forEach(registerOptionBundle);

  void requiresPubspecYaml() {
    _requiresPubspecYaml = true;
  }

  void usesWebOptions({required bool verboseHelp}) {
    argParser.addMultiOption(
      'web-header',
      help:
          'Additional key-value pairs that will added by the web server '
          'as headers to all responses. Multiple headers can be passed by '
          'repeating "--web-header" multiple times.',
      valueHelp: 'X-Custom-Header=header-value',
      splitCommas: false,
      hide: !verboseHelp,
    );
    argParser.addOption(
      'web-hostname',
      help:
          'The hostname that the web server will use to resolve an IP to serve '
          'from. The unresolved hostname is used to launch Chrome when using '
          'the chrome Device. The name "any" may also be used to serve on any '
          'IPV4 for either the Chrome or web-server device.',
      hide: !verboseHelp,
    );
    argParser.addOption(
      'web-port',
      help:
          'The host port to serve the web application from. If not provided, the tool '
          'will select a random open port on the host.',
      hide: !verboseHelp,
    );
    argParser.addOption(
      'web-tls-cert-path',
      help:
          'The certificate that host will use to serve using TLS connection. '
          'If not provided, the tool will use default http scheme.',
    );
    argParser.addOption(
      'web-tls-cert-key-path',
      help:
          'The certificate key that host will use to authenticate cert. '
          'If not provided, the tool will use default http scheme.',
    );
    argParser.addOption(
      'web-server-debug-protocol',
      allowed: <String>['sse', 'ws'],
      defaultsTo: 'ws',
      help:
          'The protocol (SSE or WebSockets) to use for the debug service proxy '
          'when using the Web Server device and Dart Debug extension. '
          'This is useful for editors/debug adapters that do not support debugging '
          'over SSE (the default protocol for Web Server/Dart Debugger extension).',
      hide: !verboseHelp,
    );
    argParser.addOption(
      'web-server-debug-backend-protocol',
      allowed: <String>['sse', 'ws'],
      defaultsTo: 'ws',
      help:
          'The protocol (SSE or WebSockets) to use for the Dart Debug Extension '
          'backend service when using the Web Server device. '
          'Using WebSockets can improve performance but may fail when connecting through '
          'some proxy servers.',
      hide: !verboseHelp,
    );
    argParser.addOption(
      'web-server-debug-injected-client-protocol',
      allowed: <String>['sse', 'ws'],
      defaultsTo: 'ws',
      help:
          'The protocol (SSE or WebSockets) to use for the injected client '
          'when using the Web Server device. '
          'Using WebSockets can improve performance but may fail when connecting through '
          'some proxy servers.',
      hide: !verboseHelp,
    );
    argParser.addFlag(
      'web-allow-expose-url',
      help:
          'Enables daemon-to-editor requests (app.exposeUrl) for exposing URLs '
          'when running on remote machines.',
      hide: !verboseHelp,
    );
    argParser.addFlag(
      'web-run-headless',
      help:
          'Launches the browser in headless mode. Currently only Chrome '
          'supports this option.',
      hide: !verboseHelp,
    );
    argParser.addOption(
      'web-browser-debug-port',
      help:
          'The debug port the browser should use. If not specified, a '
          'random port is selected. Currently only Chrome supports this option. '
          'It serves the Chrome DevTools Protocol '
          '(https://chromedevtools.github.io/devtools-protocol/).',
      hide: !verboseHelp,
    );
    argParser.addFlag(
      'web-enable-expression-evaluation',
      defaultsTo: true,
      help: 'Enables expression evaluation in the debugger.',
      hide: !verboseHelp,
    );
    argParser.addOption(
      'web-launch-url',
      help:
          'The URL to provide to the browser. Defaults to an HTTP URL with the host '
          'name of "--web-hostname", the port of "--web-port", and the path set to "/".',
    );
    argParser.addMultiOption(
      FlutterOptions.kWebBrowserFlag,
      help:
          'Additional flag to pass to a browser instance at startup.\n'
          'Chrome: https://www.chromium.org/developers/how-tos/run-chromium-with-flags/\n'
          'Firefox: https://wiki.mozilla.org/Firefox/CommandLineOptions\n'
          'Multiple flags can be passed by repeating "--${FlutterOptions.kWebBrowserFlag}" multiple times.',
      valueHelp: '--foo=bar',
      hide: !verboseHelp,
    );
    argParser.addFlag(
      'cross-origin-isolation',
      help:
          'Adds the Cross-Origin-Opener-Policy and Cross-Origin-Embedder-Policy '
          'headers to the web server. These headers are required for using APIs like '
          'SharedArrayBuffer. This is on by default for the "skwasm" web renderer, '
          'and this flag can be used to override the default. To disable this for the '
          'skwasm renderer, use "--no-cross-origin-isolation".',
      hide: !verboseHelp,
    );
    usesBaseHrefOption();
  }

  void usesBaseHrefOption() {
    argParser.addOption(
      'base-href',
      help:
          'Overrides the href attribute of the <base> tag in web/index.html. '
          'No change is made to web/index.html file if this flag is not provided. '
          'The value must start and end with "/". '
          'For more information: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base',
    );
  }

  void usesTargetOption() {
    CommonOptions.target.addTo(argParser);
    _usesTargetOption = true;
  }

  void usesFatalWarningsOption({required bool verboseHelp}) {
    argParser.addFlag(
      FlutterOptions.kFatalWarnings,
      hide: !verboseHelp,
      help:
          'Causes the command to fail if warnings are sent to the console '
          'during its execution.',
    );
    _usesFatalWarnings = true;
  }

  String get targetFile {
    if (argResults?.wasParsed('target') ?? false) {
      return stringArg('target')!;
    }
    final List<String>? rest = argResults?.rest;
    if (rest != null && rest.isNotEmpty) {
      return rest.first;
    }
    return bundle.defaultMainPath;
  }

  /// Indicates if the current command running has a terminal attached.
  bool get hasTerminal => globals.stdio.hasTerminal;

  /// Path to the Dart's package config file.
  ///
  /// This can be overridden by some of its subclasses.
  String? get packagesPath => stringArg(FlutterGlobalOptions.kPackagesOption, global: true);

  /// Whether flutter is being run from our CI.
  ///
  /// This is true if `--ci` is passed to the command or if environment
  /// variable `LUCI_CI` is `True`.
  bool get usingCISystem {
    return boolArg(FlutterGlobalOptions.kContinuousIntegrationFlag, global: true) ||
        globals.platform.environment['LUCI_CI'] == 'True';
  }

  String? get debugLogsDirectoryPath =>
      stringArg(FlutterGlobalOptions.kDebugLogsDirectoryFlag, global: true);

  /// The value of the `--filesystem-scheme` argument.
  ///
  /// This can be overridden by some of its subclasses.
  String? get fileSystemScheme => argParser.options.containsKey(FlutterOptions.kFileSystemScheme)
      ? stringArg(FlutterOptions.kFileSystemScheme)
      : null;

  /// The values of the `--filesystem-root` argument.
  ///
  /// This can be overridden by some of its subclasses.
  List<String>? get fileSystemRoots => argParser.options.containsKey(FlutterOptions.kFileSystemRoot)
      ? stringsArg(FlutterOptions.kFileSystemRoot)
      : null;

  void usesPubOption({bool hide = false}) {
    CommonOptions.pub.addTo(argParser, hideOverride: hide);
    _usesPubOption = true;
  }

  /// Adds flags for using a specific filesystem root and scheme.
  ///
  /// The `hide` argument indicates whether or not to hide these options when
  /// the user asks for help.
  void usesFilesystemOptions({required bool hide}) {
    argParser
      ..addOption(
        'output-dill',
        hide: hide,
        help: 'Specify the path to frontend server output kernel file.',
      )
      ..addMultiOption(
        FlutterOptions.kFileSystemRoot,
        hide: hide,
        help:
            'Specify the path that is used as the root of a virtual file system '
            'during compilation. The input file name should be specified as a URL '
            'using the scheme given in "--${FlutterOptions.kFileSystemScheme}".\n'
            'Requires the "--output-dill" option to be explicitly specified.',
      )
      ..addOption(
        FlutterOptions.kFileSystemScheme,
        defaultsTo: 'org-dartlang-root',
        hide: hide,
        help:
            'Specify the scheme that is used for virtual file system used in '
            'compilation. See also the "--${FlutterOptions.kFileSystemRoot}" option.',
      );
  }

  /// Adds options for connecting to the Dart VM Service port.
  void usesPortOptions({required bool verboseHelp}) {
    argParser.addOption(
      vmServicePortOption,
      help:
          '(deprecated; use host-vmservice-port instead) '
          'Listen to the given port for a Dart VM Service connection.\n'
          'Specifying port 0 (the default) will find a random free port.\n '
          'if the Dart Development Service (DDS) is enabled, this will not be the port '
          'of the VmService instance advertised on the command line.',
      hide: !verboseHelp,
    );
    argParser.addOption(
      'device-vmservice-port',
      help:
          'Look for vmservice connections only from the specified port.\n'
          'Specifying port 0 (the default) will accept the first vmservice '
          'discovered.',
    );
    argParser.addOption(
      'host-vmservice-port',
      help:
          'When a device-side vmservice port is forwarded to a host-side '
          'port, use this value as the host port.\nSpecifying port 0 '
          '(the default) will find a random free host port.',
    );
    _usesPortOption = true;
  }

  /// Add option values for output directory of artifacts
  void usesOutputDir() {
    CommonOptions.outputDir.addTo(argParser);
  }

  void addDevToolsOptions({required bool verboseHelp, bool includeEnableDevTools = true}) {
    if (includeEnableDevTools) {
      argParser.addFlag(
        kEnableDevTools,
        hide: !verboseHelp,
        defaultsTo: true,
        help:
            'Enable (or disable, with "--no-$kEnableDevTools") the launching of the '
            'Flutter DevTools debugger and profiler. '
            'If "--no-$kEnableDevTools" is specified, "--$kDevToolsServerAddress" is ignored.',
      );
    }
    final ignoredMessage = includeEnableDevTools
        ? ' Ignored if "--no-$kEnableDevTools" is specified.'
        : '';
    argParser.addOption(
      kDevToolsServerAddress,
      hide: !verboseHelp,
      help:
          'When this value is provided, the Flutter tool will not spin up a '
          'new DevTools server instance, and will instead use the one provided '
          'at the given address.$ignoredMessage',
    );
  }

  void addDdsOptions({required bool verboseHelp}) {
    argParser.addOption(
      'dds-port',
      help:
          'When this value is provided, the Dart Development Service (DDS) will be '
          'bound to the provided port.\n'
          'Specifying port 0 (the default) will find a random free port.',
    );
    argParser.addFlag(
      'dds',
      defaultsTo: true,
      help:
          'Enable the Dart Developer Service (DDS).\n'
          'It may be necessary to disable this when attaching to an application with '
          'an existing DDS instance (e.g., attaching to an application currently '
          'connected to by "flutter run"), or when running certain tests.\n'
          'Disabling this feature may degrade IDE functionality if a DDS instance is '
          'not already connected to the target application.',
    );
    argParser.addFlag(
      'disable-dds',
      hide: !verboseHelp,
      help:
          '(deprecated; use "--no-dds" instead) '
          'Disable the Dart Developer Service (DDS).',
    );
  }

  late final bool enableDds = boolArg('dds');

  bool get _hostVmServicePortProvided =>
      (argResults?.wasParsed(vmServicePortOption) ?? false) ||
      (argResults?.wasParsed('host-vmservice-port') ?? false);

  int _tryParseHostVmservicePort() {
    final String? vmServicePort = stringArg(vmServicePortOption);
    final String? hostPort = stringArg('host-vmservice-port');
    if (vmServicePort == null && hostPort == null) {
      throwToolExit('Invalid port for `--vm-service-port/--host-vmservice-port`');
    }
    try {
      return int.parse((vmServicePort ?? hostPort)!);
    } on FormatException catch (error) {
      throwToolExit('Invalid port for `--vm-service-port/--host-vmservice-port`: $error');
    }
  }

  int get ddsPort {
    if (argResults?.wasParsed('dds-port') != true && _hostVmServicePortProvided) {
      // If an explicit DDS port is _not_ provided, use the host-vmservice-port for DDS.
      return _tryParseHostVmservicePort();
    } else if (argResults?.wasParsed('dds-port') ?? false) {
      // If an explicit DDS port is provided, use dds-port for DDS.
      return int.tryParse(stringArg('dds-port')!) ?? 0;
    }
    // Otherwise, DDS can bind to a random port.
    return 0;
  }

  Uri? get devToolsServerAddress {
    if (argResults?.wasParsed(kDevToolsServerAddress) ?? false) {
      final Uri? uri = Uri.tryParse(stringArg(kDevToolsServerAddress)!);
      if (uri != null && uri.host.isNotEmpty && uri.port != 0) {
        return uri;
      }
    }
    return null;
  }

  /// Gets the vmservice port provided to in the 'vm-service-port' or
  /// 'host-vmservice-port option.
  ///
  /// Only one of "host-vmservice-port" and "vm-service-port" may be
  /// specified.
  ///
  /// If no port is set, returns null.
  int? get hostVmservicePort {
    if (!_usesPortOption || !_hostVmServicePortProvided) {
      return null;
    }
    if ((argResults?.wasParsed(vmServicePortOption) ?? false) &&
        (argResults?.wasParsed('host-vmservice-port') ?? false)) {
      throwToolExit(
        'Only one of "--vm-service-port" and '
        '"--host-vmservice-port" may be specified.',
      );
    }
    // If DDS is enabled and no explicit DDS port is provided, use the
    // host-vmservice-port for DDS instead and bind the VM service to a random
    // port.
    if (enableDds && argResults?.wasParsed('dds-port') != true) {
      return null;
    }
    return _tryParseHostVmservicePort();
  }

  /// Gets the vmservice port provided to in the 'device-vmservice-port' option.
  ///
  /// If no port is set, returns null.
  int? get deviceVmservicePort {
    final String? devicePort = stringArg('device-vmservice-port');
    if (!_usesPortOption || devicePort == null) {
      return null;
    }
    try {
      return int.parse(devicePort);
    } on FormatException catch (error) {
      throwToolExit('Invalid port for `--device-vmservice-port`: $error');
    }
  }

  void addPublishPort({bool enabledByDefault = true, bool verboseHelp = false}) {
    argParser.addFlag(
      'publish-port',
      hide: !verboseHelp,
      help:
          'Publish the VM service port over mDNS. Disable to prevent the '
          'local network permission app dialog in debug and profile build modes (iOS devices only).',
      defaultsTo: enabledByDefault,
    );
  }

  Future<bool> get disablePortPublication async => !boolArg('publish-port');

  void usesIpv6Flag({required bool verboseHelp}) {
    argParser.addFlag(
      ipv6Flag,
      negatable: false,
      help:
          'Binds to IPv6 localhost instead of IPv4 when the flutter tool '
          'forwards the host port to a device port.',
      hide: !verboseHelp,
    );
    _usesIpv6Flag = true;
  }

  bool? get ipv6 => _usesIpv6Flag ? boolArg('ipv6') : null;

  void usesBuildNumberOption() {
    CommonOptions.buildNumber.addTo(argParser);
  }

  void usesBuildNameOption() {
    CommonOptions.buildName.addTo(argParser);
  }

  void usesDartDefineOption() {
    CommonOptions.dartDefines.addTo(argParser);
    _usesDartDefineFromFileOption();
  }

  void usesWebDefineOption() {
    argParser.addMultiOption(
      FlutterOptions.kWebDefinesOption,
      help:
          'Additional key-value pairs that will be available as template variables '
          'in web/index.html and web/flutter_bootstrap.js files during development and build.\n'
          'Variables are replaced in the format {{VARIABLE_NAME}}.\n'
          'Multiple defines can be passed by repeating "--${FlutterOptions.kWebDefinesOption}" multiple times.\n'
          'If a template contains a variable placeholder but no corresponding "--web-define" is provided, '
          'it will warn that you have an unhandled variable.',
      valueHelp: 'API_URL=https://api.example.com',
      splitCommas: false,
    );
  }

  void _usesDartDefineFromFileOption() {
    CommonOptions.dartDefineFromFile.addTo(argParser);
  }

  void usesWebResourcesCdnFlag() {
    argParser.addFlag(
      FlutterOptions.kWebResourcesCdnFlag,
      defaultsTo: true,
      help: 'Use Web static resources hosted on a CDN.',
    );
  }

  void usesDeviceUserOption() {
    argParser.addOption(
      FlutterOptions.kDeviceUser,
      help:
          'Identifier number for a user or work profile on Android only. Run "adb shell pm list users" for available identifiers.',
      valueHelp: '10',
    );
  }

  void usesDeviceTimeoutOption() {
    argParser.addOption(
      FlutterOptions.kDeviceTimeout,
      help:
          'Time in seconds to wait for devices to attach. Longer timeouts may be necessary for networked devices.',
      valueHelp: '10',
    );
  }

  void usesDeviceConnectionOption() {
    argParser.addOption(
      FlutterOptions.kDeviceConnection,
      defaultsTo: 'both',
      help: 'Discover devices based on connection type.',
      allowed: <String>['attached', 'wireless', 'both'],
      allowedHelp: <String, String>{
        'both': 'Searches for both attached and wireless devices.',
        'attached':
            'Only searches for devices connected by USB or built-in (such as simulators/emulators, MacOS/Windows, Chrome)',
        'wireless':
            'Only searches for devices connected wirelessly. Discovering wireless devices may take longer.',
      },
    );
  }

  void usesApplicationBinaryOption() {
    argParser.addOption(
      FlutterOptions.kUseApplicationBinary,
      help:
          'Specify a pre-built application binary to use when running. For Android applications, '
          'this must be the path to an APK. For iOS applications, the path to an IPA. Other device types '
          'do not yet support prebuilt application binaries.',
      valueHelp: 'path/to/app.apk',
    );
  }

  /// Whether it is safe for this command to use a cached pub invocation.
  bool get cachePubGet => true;

  late final Duration? deviceDiscoveryTimeout = () {
    if ((argResults?.options.contains(FlutterOptions.kDeviceTimeout) ?? false) &&
        (argResults?.wasParsed(FlutterOptions.kDeviceTimeout) ?? false)) {
      final int? timeoutSeconds = int.tryParse(stringArg(FlutterOptions.kDeviceTimeout)!);
      if (timeoutSeconds == null) {
        throwToolExit(
          'Could not parse "--${FlutterOptions.kDeviceTimeout}" argument. It must be an integer.',
        );
      }
      return Duration(seconds: timeoutSeconds);
    }
    return null;
  }();

  DeviceConnectionInterface? get deviceConnectionInterface {
    if ((argResults?.options.contains(FlutterOptions.kDeviceConnection) ?? false) &&
        (argResults?.wasParsed(FlutterOptions.kDeviceConnection) ?? false)) {
      return switch (stringArg(FlutterOptions.kDeviceConnection)) {
        'attached' => DeviceConnectionInterface.attached,
        'wireless' => DeviceConnectionInterface.wireless,
        _ => null,
      };
    }
    return null;
  }

  late final _targetDevices = TargetDevices(
    platform: globals.platform,
    deviceManager: globals.deviceManager!,
    logger: globals.logger,
    deviceConnectionInterface: deviceConnectionInterface,
  );

  void addBuildModeFlags({
    required bool verboseHelp,
    bool defaultToRelease = true,
    bool excludeDebug = false,
    bool excludeRelease = false,
  }) {
    // A release build must be the default if a debug build is not possible.
    assert(defaultToRelease || !excludeDebug);
    _excludeDebug = excludeDebug;
    _excludeRelease = excludeRelease;
    defaultBuildMode = defaultToRelease ? BuildMode.release : BuildMode.debug;

    if (!excludeDebug) {
      argParser.addFlag(
        'debug',
        negatable: false,
        help: 'Build a debug version of your app${defaultToRelease ? '' : ' (default mode)'}.',
      );
    }
    argParser.addFlag(
      'profile',
      negatable: false,
      help: 'Build a version of your app specialized for performance profiling.',
    );
    if (!excludeRelease) {
      argParser.addFlag(
        'release',
        negatable: false,
        help: 'Build a release version of your app${defaultToRelease ? ' (default mode)' : ''}.',
      );
      argParser.addFlag(
        'jit-release',
        negatable: false,
        hide: !verboseHelp,
        help:
            'Build a JIT release version of your app${defaultToRelease ? ' (default mode)' : ''}.',
      );
    }
  }

  void addSplitDebugInfoOption() {
    BuildInfoOptions.splitDebugInfo.addTo(argParser);
  }

  void addDartObfuscationOption() {
    BuildInfoOptions.obfuscate.addTo(argParser);
  }

  void addTreeShakeIconsFlag({bool? enabledByDefault}) {
    CommonOptions.treeShakeIcons.addTo(argParser, hideOverride: enabledByDefault == false);
  }

  void addShrinkingFlag({required bool verboseHelp}) {
    argParser.addFlag(
      'shrink',
      hide: !verboseHelp,
      help:
          'This flag has no effect. Code shrinking is always enabled in release builds. '
          'To learn more, see: https://developer.android.com/studio/build/shrink-code',
    );
  }

  void usesFrontendServerStarterPathOption({required bool verboseHelp}) {
    BuildInfoOptions.frontendServerStarterPath.addTo(argParser, verboseHelp: verboseHelp);
  }

  /// Enables support for the hidden options --extra-front-end-options and
  /// --extra-gen-snapshot-options.
  void usesExtraDartFlagOptions({required bool verboseHelp}) {
    BuildInfoOptions.extraFrontEndOptions.addTo(argParser, verboseHelp: verboseHelp);
    BuildInfoOptions.extraGenSnapshotOptions.addTo(argParser, verboseHelp: verboseHelp);
  }

  void usesFuchsiaOptions({bool hide = false}) {
    argParser.addOption(
      'target-model',
      help: 'Target model that determines what core libraries are available.',
      defaultsTo: 'flutter',
      hide: hide,
      allowed: const <String>['flutter', 'flutter_runner'],
    );
    argParser.addOption(
      'module',
      abbr: 'm',
      hide: hide,
      help: 'The name of the module (required if attaching to a fuchsia device).',
      valueHelp: 'module-name',
    );
  }

  void addEnableExperimentation({required bool hide}) {
    CommonOptions.enableExperiment.addTo(argParser, hideOverride: hide);
  }

  void addBuildPerformanceFile({bool hide = false}) {
    BuildInfoOptions.performanceMeasurementFile.addTo(argParser, hideOverride: hide);
  }

  void addAndroidSpecificBuildOptions({bool hide = false}) {
    BuildInfoOptions.androidGradleDaemon.addTo(argParser, hideOverride: hide);
    BuildInfoOptions.androidSkipBuildDependencyValidation.addTo(argParser, hideOverride: hide);
    BuildInfoOptions.androidProjectArg.addTo(argParser, hideOverride: hide);
    BuildInfoOptions.androidProjectCacheDir.addTo(argParser, hideOverride: hide);
  }

  void addNativeNullAssertions({bool hide = false}) {
    CommonOptions.nativeNullAssertions.addTo(argParser, hideOverride: hide);
  }

  void usesInitializeFromDillOption({required bool hide}) {
    BuildInfoOptions.initializeFromDill.addTo(argParser, hideOverride: hide);
    BuildInfoOptions.assumeInitializeFromDillUpToDate.addTo(argParser, hideOverride: hide);
  }

  void usesNativeAssetsOption({required bool hide}) {
    argParser.addOption(
      FlutterOptions.kNativeAssetsYamlFile,
      help:
          'Initializes the resident compiler with a custom native assets '
          'yaml file instead of the default cached location.',
      hide: hide,
    );
  }

  void addIgnoreDeprecationOption({bool hide = false}) {
    argParser.addFlag(
      'ignore-deprecation',
      negatable: false,
      help:
          'Indicates that the app should ignore deprecation warnings and continue to build '
          'using deprecated APIs. Use of this flag may cause your app to fail to build when '
          'deprecated APIs are removed.',
    );
  }

  /// Adds build options common to all of the desktop build commands.
  void addCommonDesktopBuildOptions({required bool verboseHelp}) {
    addBuildModeFlags(verboseHelp: verboseHelp);
    addBuildPerformanceFile(hide: !verboseHelp);
    addDartObfuscationOption();
    addEnableExperimentation(hide: !verboseHelp);
    addSplitDebugInfoOption();
    addTreeShakeIconsFlag();
    usesAnalyzeSizeFlag();
    usesDartDefineOption();
    usesExtraDartFlagOptions(verboseHelp: verboseHelp);
    usesPubOption();
    usesTargetOption();
    usesTrackWidgetCreation(verboseHelp: verboseHelp);
    usesBuildNumberOption();
    usesBuildNameOption();
  }

  /// The build mode that this command will use if no build mode is
  /// explicitly specified.
  ///
  /// Use [getBuildMode] to obtain the actual effective build mode.
  BuildMode defaultBuildMode = BuildMode.debug;

  BuildMode getBuildMode() {
    // No debug when _excludeDebug is true. If debug is not excluded, then take
    // the command line flag (if such exists for this command).
    bool argIfDefined(String flagName, bool ifNotDefined) {
      return argParser.options.containsKey(flagName) ? boolArg(flagName) : ifNotDefined;
    }

    final bool debugResult = !_excludeDebug && argIfDefined('debug', false);
    final bool jitReleaseResult = !_excludeRelease && argIfDefined('jit-release', false);
    final bool releaseResult = !_excludeRelease && argIfDefined('release', false);
    final bool profileResult = argIfDefined('profile', false);
    final modeFlags = <bool>[debugResult, profileResult, jitReleaseResult, releaseResult];
    if (modeFlags.where((bool flag) => flag).length > 1) {
      throw UsageException(
        'Only one of "--debug", "--profile", "--jit-release", '
            'or "--release" can be specified.',
        '',
      );
    }
    if (debugResult) {
      return BuildMode.debug;
    }
    if (profileResult) {
      return BuildMode.profile;
    }
    if (releaseResult) {
      return BuildMode.release;
    }
    if (jitReleaseResult) {
      return BuildMode.jitRelease;
    }
    return defaultBuildMode;
  }

  void usesFlavorOption() {
    BuildInfoOptions.flavor.addTo(argParser);
  }

  void usesDarwinCodeSignXCFrameworksOption() {
    BuildInfoOptions.codesign.addTo(argParser);
    argParser.addOption(
      FlutterOptions.kCodesignIdentity,
      help:
          'The identity to use for code-signing XCFrameworks. If an identity is not provided and '
          '"${FlutterOptions.kCodesign}" is enabled, a code signing identity will be selected '
          "automatically from the Flutter app's Xcode project settings or Flutter config. To see "
          'a list of valid identities run "security find-identity -p codesigning -v".',
    );
  }

  void usesTrackWidgetCreation({bool hasEffect = true, required bool verboseHelp}) {
    BuildInfoOptions.trackWidgetCreation.addTo(
      argParser,
      verboseHelp: verboseHelp,
      hideOverride: !hasEffect && !verboseHelp,
    );
  }

  void usesAnalyzeSizeFlag() {
    BuildInfoOptions.analyzeSize.addTo(argParser);
    BuildInfoOptions.codeSizeDirectory.addTo(argParser);
  }

  void addEnableImpellerFlag({required bool verboseHelp}) {
    argParser.addFlag(
      FlutterOptions.kEnableImpeller,
      hide: !verboseHelp,
      defaultsTo: null,
      help:
          'Whether to enable the Impeller rendering engine. '
          'Impeller is the default renderer on iOS. On Android, Impeller '
          'is available but not the default. This flag will cause Impeller '
          'to be used on Android. On other platforms, this flag will be '
          'ignored.',
    );
  }

  void addEnableFlutterGpuFlag({required bool verboseHelp}) {
    argParser.addFlag(
      'enable-flutter-gpu',
      hide: !verboseHelp,
      defaultsTo: null,
      help:
          'Whether to enable the Flutter GPU API (https://api.flutter.dev/flutter/flutter_gpu/). '
          'This feature is only supported with the Impeller rendering engine, '
          'which can be enabled via the "--${FlutterOptions.kEnableImpeller}" '
          'option.',
    );
  }

  void addEnableVulkanValidationFlag({required bool verboseHelp}) {
    argParser.addFlag(
      'enable-vulkan-validation',
      hide: !verboseHelp,
      help:
          'Enable vulkan validation on the Impeller rendering backend if '
          'Vulkan is in use and the validation layers are available to the '
          'application.',
    );
  }

  void addEnableEmbedderApiFlag({required bool verboseHelp}) {
    argParser.addFlag(
      'enable-embedder-api',
      hide: !verboseHelp,
      help: 'Whether to enable the experimental embedder API on iOS.',
    );
  }

  void addMachineOutputFlag({required bool verboseHelp}) {
    argParser.addFlag(
      FlutterGlobalOptions.kMachineFlag,
      negatable: false,
      help: 'Outputs in a machine readable structured JSON format.',
      hide: !verboseHelp,
    );
  }

  void addEnableHcppFlag({required bool verboseHelp}) {
    argParser.addFlag(
      'enable-hcpp',
      hide: !verboseHelp,
      help:
          'Enable the use of the HCPP platform view rendering mode on the Impeller rendering '
          'backend. An explicit value takes priority over the EnableHcpp metadata in '
          'AndroidManifest.xml: build commands write it into the manifest of the artifact they '
          'produce, and "run", "test", and "drive" additionally apply it at launch. Without the '
          'flag, the manifest decides.',
    );
  }

  /// The explicit `--[no-]enable-hcpp` value, or null when the flag was not
  /// passed (or the command does not define it).
  ///
  /// This takes priority over the `io.flutter.embedding.android.EnableHcpp`
  /// manifest entry: it is passed to Gradle, which writes it into the merged
  /// manifest over any value already there. Commands that launch the app
  /// (run/test/drive) additionally forward it to the device.
  bool? get explicitEnableHcpp {
    final ArgResults? results = argResults;
    if (results == null ||
        !results.options.contains('enable-hcpp') ||
        !results.wasParsed('enable-hcpp')) {
      return null;
    }
    return boolArg('enable-hcpp');
  }

  /// The HCPP value for an Android artifact when the developer did not pass
  /// `--[no-]enable-hcpp`: currently always false.
  ///
  /// This is only a default. Gradle injects it when the merged manifest does
  /// not set `io.flutter.embedding.android.EnableHcpp` at all, so an entry in
  /// the manifest wins over it. [explicitEnableHcpp] in turn wins over both.
  bool get enableHcpp => explicitEnableHcpp ?? false;

  void addTestFlag({required bool verboseHelp}) {
    argParser.addFlag(
      'test-flag',
      hide: !verboseHelp,
      help: 'No-op flag for testing purposes; use for testing flag priorities only.',
    );
  }

  /// Returns a [FlutterProject] view of the current directory or a ToolExit error,
  /// if `pubspec.yaml` or `example/pubspec.yaml` is invalid.
  FlutterProject get project => FlutterProject.current();

  /// The path to the package config for the current project.
  ///
  /// If an explicit argument is given, that is returned. Otherwise the file
  /// system is searched for the package config. For projects in pub workspaces
  /// the package config might be located in a parent directory.
  ///
  /// If none is found `.dart_tool/package_config.json` is returned.
  String packageConfigPath() {
    final String? packagesPath = this.packagesPath;
    return packagesPath ?? findPackageConfigFileOrDefault(project.directory).path;
  }

  /// Compute the [BuildInfo] for the current flutter command.
  ///
  /// Commands that build multiple build modes can pass in a [forcedBuildMode]
  /// to be used instead of parsing flags.
  ///
  /// Throws a [ToolExit] if the current set of options is not compatible with
  /// each other.
  Future<BuildInfo> getBuildInfo({
    BuildMode? forcedBuildMode,
    File? forcedTargetFile,
    bool? forcedUseLocalCanvasKit,
    // TODO(nshahan): Delete when fully migrated to new module system,
    // https://github.com/flutter/flutter/issues/142060.
    bool? forcedWebEnableHotReload,
  }) async {
    final bool trackWidgetCreation =
        hasOption(BuildInfoOptions.trackWidgetCreation) &&
        getValue(BuildInfoOptions.trackWidgetCreation);

    final String? buildNumber = getValue(CommonOptions.buildNumber);

    final String? buildName = getValue(CommonOptions.buildName);

    final File packageConfigFile = globals.fs.file(packageConfigPath());

    final PackageConfig packageConfig = await loadPackageConfigWithLogging(
      packageConfigFile,
      logger: globals.logger,
      throwOnError: false,
    );

    final List<String> experiments = getValue(CommonOptions.enableExperiment);
    final List<String> extraGenSnapshotOptions = getValue(
      BuildInfoOptions.extraGenSnapshotOptions,
    ).toList();
    final List<String> extraFrontEndOptions = getValue(
      BuildInfoOptions.extraFrontEndOptions,
    ).toList();

    if (experiments.isNotEmpty) {
      for (final expFlag in experiments) {
        final flag = '--enable-experiment=$expFlag';
        extraFrontEndOptions.add(flag);
        extraGenSnapshotOptions.add(flag);
      }
    }
    String? codeSizeDirectory;
    if (getValue(BuildInfoOptions.analyzeSize)) {
      final String? customDir = getValue(BuildInfoOptions.codeSizeDirectory);
      final Directory directory = (customDir != null)
          ? globals.fs.directory(customDir)
          : globals.fsUtils.getUniqueDirectory(
              globals.fs.directory(getBuildDirectory()),
              'flutter_size',
            );
      directory.createSync(recursive: true);
      codeSizeDirectory = directory.path;
    }

    final bool dartObfuscation = getValue(BuildInfoOptions.obfuscate);

    final String? splitDebugInfoPath = getValue(BuildInfoOptions.splitDebugInfo);

    final bool androidGradleDaemon =
        !hasOption(BuildInfoOptions.androidGradleDaemon) ||
        getValue(BuildInfoOptions.androidGradleDaemon);

    final bool androidSkipBuildDependencyValidation =
        !hasOption(BuildInfoOptions.androidSkipBuildDependencyValidation) ||
        getValue(BuildInfoOptions.androidSkipBuildDependencyValidation);

    final List<String> androidProjectArgs = getValue(BuildInfoOptions.androidProjectArg);

    final String? androidGradleProjectCacheDir = getValue(BuildInfoOptions.androidProjectCacheDir);

    if (dartObfuscation && (splitDebugInfoPath == null || splitDebugInfoPath.isEmpty)) {
      throwToolExit(
        '"--${FlutterOptions.kDartObfuscationOption}" can only be used in '
        'combination with "--${FlutterOptions.kSplitDebugInfoOption}"',
      );
    }
    final BuildMode buildMode = forcedBuildMode ?? getBuildMode();
    if (buildMode != BuildMode.release && codeSizeDirectory != null) {
      throwToolExit('"--${FlutterOptions.kAnalyzeSize}" can only be used on release builds.');
    }
    if (codeSizeDirectory != null && splitDebugInfoPath != null) {
      throwToolExit(
        '"--${FlutterOptions.kAnalyzeSize}" cannot be combined with "--${FlutterOptions.kSplitDebugInfoOption}".',
      );
    }

    final bool treeShakeIcons =
        hasOption(CommonOptions.treeShakeIcons) &&
        buildMode.isPrecompiled &&
        getValue(CommonOptions.treeShakeIcons);

    final String? performanceMeasurementFile = getValue(
      BuildInfoOptions.performanceMeasurementFile,
    );

    final Map<String, Object?> defineConfigJsonMap = extractDartDefineConfigJsonMap();
    final List<String> dartDefines = extractDartDefines(defineConfigJsonMap: defineConfigJsonMap);

    final bool useCdn = getValue(WebOptions.webResourcesCdn);
    var useLocalWebSdk = false;
    if (globalResults?.wasParsed(FlutterGlobalOptions.kLocalWebSDKOption) ?? false) {
      useLocalWebSdk = stringArg(FlutterGlobalOptions.kLocalWebSDKOption, global: true) != null;
    }
    final bool useLocalCanvasKit = forcedUseLocalCanvasKit ?? (!useCdn || useLocalWebSdk);

    final String? defaultFlavor = project.manifest.defaultFlavor;
    final String? cliFlavor = getValue(BuildInfoOptions.flavor);
    final String? flavor = cliFlavor ?? defaultFlavor;

    _ensureReservedDartDefineIsUnset(kAppFlavor, dartDefines);
    if (flavor != null) {
      dartDefines.add('$kAppFlavor=$flavor');
    }
    for (final (String define, String? value) in <(String, String?)>[
      (kAppBuildName, buildName ?? project.manifest.buildName),
      (kAppBuildNumber, buildNumber ?? project.manifest.buildNumber),
    ]) {
      _ensureReservedDartDefineIsUnset(define, dartDefines);
      if (value != null) {
        dartDefines.add('$define=$value');
      }
    }
    _addFlutterVersionToDartDefines(globals.flutterVersion, dartDefines);
    _addFeatureFlagsToDartDefines(dartDefines);

    return BuildInfo(
      buildMode,
      flavor,
      trackWidgetCreation: trackWidgetCreation,
      frontendServerStarterPath: getValue(BuildInfoOptions.frontendServerStarterPath),
      extraFrontEndOptions: extraFrontEndOptions.isNotEmpty ? extraFrontEndOptions : null,
      extraGenSnapshotOptions: extraGenSnapshotOptions.isNotEmpty ? extraGenSnapshotOptions : null,
      fileSystemRoots: fileSystemRoots,
      fileSystemScheme: fileSystemScheme,
      buildNumber: buildNumber,
      buildName: buildName,
      treeShakeIcons: treeShakeIcons,
      splitDebugInfoPath: splitDebugInfoPath,
      dartObfuscation: dartObfuscation,
      dartDefines: dartDefines,
      dartExperiments: experiments,
      performanceMeasurementFile: performanceMeasurementFile,
      packageConfigPath: packagesPath ?? packageConfigFile.path,
      codeSizeDirectory: codeSizeDirectory,
      androidGradleDaemon: androidGradleDaemon,
      androidSkipBuildDependencyValidation: androidSkipBuildDependencyValidation,
      androidEnableHcpp: enableHcpp,
      explicitAndroidEnableHcpp: explicitEnableHcpp,
      packageConfig: packageConfig,
      androidProjectArgs: androidProjectArgs,
      androidGradleProjectCacheDir: androidGradleProjectCacheDir,
      initializeFromDill: getValue(BuildInfoOptions.initializeFromDill),
      assumeInitializeFromDillUpToDate: getValue(BuildInfoOptions.assumeInitializeFromDillUpToDate),
      useLocalCanvasKit: useLocalCanvasKit,
      webEnableHotReload: true,
    );
  }

  /// Throws a [ToolExit] if [define], a dart-define key reserved by the
  /// framework, has been set either in the environment or through
  /// `--${FlutterOptions.kDartDefinesOption}` / `--${FlutterOptions.kDartDefineFromFileOption}`.
  void _ensureReservedDartDefineIsUnset(String define, List<String> dartDefines) {
    if (globals.platform.environment[define] != null) {
      throwToolExit('$define is used by the framework and cannot be set in the environment.');
    }
    if (dartDefines.any((String d) => d == define || d.startsWith('$define='))) {
      throwToolExit(
        '$define is used by the framework and cannot be '
        'set using --${FlutterOptions.kDartDefinesOption} or --${FlutterOptions.kDartDefineFromFileOption}',
      );
    }
  }

  // This adds the Dart defines used to access various Flutter version information at runtime.
  void _addFlutterVersionToDartDefines(FlutterVersion version, List<String> dartDefines) {
    for (final String dartDefine in flutterVersionDartDefines) {
      if (dartDefines.any((String define) => define.startsWith(dartDefine))) {
        throwToolExit(
          '$dartDefine is used by the framework and cannot be '
          'set using --${FlutterOptions.kDartDefinesOption} or --${FlutterOptions.kDartDefineFromFileOption}. '
          'Use FlutterVersion to access it in Flutter code',
        );
      }
    }

    dartDefines.addAll(<String>[
      '$flutterVersionDefine=${version.frameworkVersion}',
      '$flutterChannelDefine=${version.channel}',
      '$flutterGitUrlDefine=${version.repositoryUrl}',
      '$flutterFrameworkRevisionDefine=${version.frameworkRevisionShort}',
      '$flutterEngineRevisionDefine=${version.engineRevisionShort}',
      '$flutterDartVersionDefine=${version.dartSdkVersion}',
    ]);
  }

  void _addFeatureFlagsToDartDefines(List<String> dartDefines) {
    if (dartDefines.any((String define) => define.startsWith(kEnabledFeatureFlags))) {
      throwToolExit(
        '$kEnabledFeatureFlags is used by the framework and cannot be '
        'set using --${FlutterOptions.kDartDefinesOption} or --${FlutterOptions.kDartDefineFromFileOption}.\n'
        '\n'
        'Use the "flutter config" command to enable feature flags.',
      );
    }

    final String enabledFeatureFlags = featureFlags.allFeatures
        .where((Feature feature) => featureFlags.isEnabled(feature))
        .where((Feature feature) => feature.runtimeId != null)
        .map((Feature feature) => feature.runtimeId!)
        .join(',');

    if (enabledFeatureFlags.isNotEmpty) {
      dartDefines.add('$kEnabledFeatureFlags=$enabledFeatureFlags');
    }
  }

  void setupApplicationPackages() {
    applicationPackages ??= ApplicationPackageFactory.instance;
  }

  /// The path to send to Google Analytics. Return null here to disable
  /// tracking of the command.
  Future<String?> get usagePath async {
    if (parent is FlutterCommand) {
      final commandParent = parent as FlutterCommand?;
      final String? path = await commandParent?.usagePath;
      // Don't report for parents that return null for usagePath.
      return path == null ? null : '$path/$name';
    } else {
      return name;
    }
  }

  /// Additional usage values to be sent with the usage ping for
  /// package:unified_analytics.
  ///
  /// Implementations of [FlutterCommand] can override this getter in order
  /// to add additional parameters in the [Event.commandUsageValues] constructor.
  Future<Event> unifiedAnalyticsUsageValues(String commandPath) async =>
      Event.commandUsageValues(workflow: commandPath, commandHasTerminal: hasTerminal);

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
        if (_usesFatalWarnings) {
          globals.logger.fatalWarnings = boolArg(FlutterOptions.kFatalWarnings);
        }
        _printDeprecationWarning();
        final String? commandPath = await usagePath;
        if (commandPath != null) {
          _registerSignalHandlers(commandPath, startTime);
        }
        var commandResult = FlutterCommandResult.fail();
        try {
          commandResult = await verifyThenRunCommand(commandPath);
        } finally {
          final DateTime endTime = globals.systemClock.now();
          globals.printTrace(
            globals.userMessages.flutterElapsedTime(
              name,
              getElapsedAsMilliseconds(endTime.difference(startTime)),
            ),
          );
          if (commandPath != null) {
            _sendPostUsage(commandPath, commandResult, startTime, endTime);
          }
          if (_usesFatalWarnings) {
            globals.logger.checkForFatalLogs();
          }
        }
      },
    );
  }

  @override
  void printUsage() {
    globals.logger.printStatus(usage);
  }

  @visibleForOverriding
  String get deprecationWarning {
    return '${globals.logger.terminal.warningMark} The "$name" command is '
        'deprecated and will be removed in a future version of Flutter. '
        'See https://flutter.dev/to/previous-releases '
        'for previous releases of Flutter.\n';
  }

  void _printDeprecationWarning() {
    if (deprecated) {
      globals.printWarning(deprecationWarning);
    }
  }

  List<String> extractDartDefines({required Map<String, Object?> defineConfigJsonMap}) {
    final dartDefines = <String>[];

    defineConfigJsonMap.forEach((String key, Object? value) {
      dartDefines.add('$key=$value');
    });

    if (argParser.options.containsKey(FlutterOptions.kDartDefinesOption)) {
      final Iterable<String> defines = stringsArg(
        FlutterOptions.kDartDefinesOption,
      ).where((string) => string.isNotEmpty);
      dartDefines.addAll(defines);
    }

    return dartDefines;
  }

  Map<String, String> extractWebDefines() {
    final webDefines = <String, String>{};

    if (argParser.options.containsKey(FlutterOptions.kWebDefinesOption)) {
      final List<String> defines = stringsArg(FlutterOptions.kWebDefinesOption);
      for (final define in defines) {
        final int separatorIndex = define.indexOf('=');
        if (separatorIndex == -1 || separatorIndex == 0) {
          throwToolExit(
            'Invalid web-define format: $define\n'
            'Expected format: KEY=VALUE (e.g., API_URL=https://api.example.com)',
          );
        }
        final String key = define.substring(0, separatorIndex);
        final String value = define.substring(separatorIndex + 1);
        webDefines[key] = value;
      }
    }

    return webDefines;
  }

  Map<String, Object?> extractDartDefineConfigJsonMap() {
    final dartDefineConfigJsonMap = <String, Object?>{};

    if (argParser.options.containsKey(FlutterOptions.kDartDefineFromFileOption)) {
      final List<String> configFilePaths = stringsArg(FlutterOptions.kDartDefineFromFileOption);

      for (final path in configFilePaths) {
        if (!globals.fs.isFileSync(path)) {
          throwToolExit(
            'Did not find the file passed to "--${FlutterOptions.kDartDefineFromFileOption}". Path: $path',
          );
        }

        String configRaw;
        try {
          configRaw = decodeUtf8OrUtf16(globals.fs.file(path).readAsBytesSync());
        } on Exception catch (err) {
          throwToolExit(
            'Unable to decode the file at path "$path". '
            'Ensure that the file is encoded in UTF-8 or UTF-16.\n'
            'Error details: $err',
          );
        }

        // Determine whether the file content is JSON or .env format.
        String configJsonRaw;
        if (configRaw.trim().startsWith('{')) {
          configJsonRaw = configRaw;
        } else {
          // Convert env file to JSON.
          configJsonRaw = convertEnvFileToJsonRaw(configRaw);
        }

        try {
          // Fix json convert Object value :type '_InternalLinkedHashMap<String, dynamic>' is not a subtype of type 'Map<String, Object>' in type cast
          (json.decode(configJsonRaw) as Map<String, dynamic>).forEach((String key, Object? value) {
            dartDefineConfigJsonMap[key] = value;
          });
        } on FormatException catch (err) {
          throwToolExit(
            'Unable to parse the file at path "$path" due to a formatting error. '
            'Ensure that the file contains valid JSON.\n'
            'Error details: $err',
          );
        }
      }
    }

    return dartDefineConfigJsonMap;
  }

  /// Parse a property line from an env file.
  /// Supposed property structure should be:
  ///   key=value
  ///
  /// Where: key is a string without spaces and value is a string.
  /// Value can also contain '=' char.
  ///
  /// Returns a record of key and value as strings.
  MapEntry<String, String> _parseProperty(String line) {
    if (DotEnvRegex.multiLineBlock.hasMatch(line)) {
      throwToolExit('Multi-line value is not supported: $line');
    }

    final Match? keyValueMatch = DotEnvRegex.keyValue.firstMatch(line);
    if (keyValueMatch == null) {
      throwToolExit(
        'Unable to parse file provided for '
        '--${FlutterOptions.kDartDefineFromFileOption}.\n'
        'Invalid property line: $line',
      );
    }

    final String key = keyValueMatch.group(1)!;
    final String value = keyValueMatch.group(2) ?? '';

    // Remove wrapping quotes and trailing line comment.
    final Match? doubleQuotedValueMatch = DotEnvRegex.doubleQuotedValue.firstMatch(value);
    if (doubleQuotedValueMatch != null) {
      return MapEntry<String, String>(key, doubleQuotedValueMatch.group(1)!);
    }

    final Match? singleQuotedValueMatch = DotEnvRegex.singleQuotedValue.firstMatch(value);
    if (singleQuotedValueMatch != null) {
      return MapEntry<String, String>(key, singleQuotedValueMatch.group(1)!);
    }

    final Match? backQuotedValueMatch = DotEnvRegex.backQuotedValue.firstMatch(value);
    if (backQuotedValueMatch != null) {
      return MapEntry<String, String>(key, backQuotedValueMatch.group(1)!);
    }

    final Match? unquotedValueMatch = DotEnvRegex.unquotedValue.firstMatch(value);
    if (unquotedValueMatch != null) {
      return MapEntry<String, String>(key, unquotedValueMatch.group(1)!);
    }

    return MapEntry<String, String>(key, value);
  }

  /// Converts an .env file string to its equivalent JSON string.
  ///
  /// For example, the .env file string
  ///   key=value # comment
  ///   complexKey="foo#bar=baz"
  /// would be converted to a JSON string equivalent to:
  ///   {
  ///     "key": "value",
  ///     "complexKey": "foo#bar=baz"
  ///   }
  ///
  /// Multiline values are not supported.
  String convertEnvFileToJsonRaw(String configRaw) {
    final List<String> lines = configRaw
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .where((String line) => !line.startsWith('#')) // Remove comment lines.
        .toList();

    final propertyMap = <String, String>{};
    for (final line in lines) {
      final MapEntry<String, String> property = _parseProperty(line);
      propertyMap[property.key] = property.value;
    }

    return jsonEncode(propertyMap);
  }

  Map<String, String> extractWebHeaders() {
    final webHeaders = <String, String>{};

    if (argParser.options.containsKey('web-header')) {
      final List<String> candidates = stringsArg('web-header');
      final invalidHeaders = <String>[];
      for (final candidate in candidates) {
        final Match? keyValueMatch = _HttpRegex.httpHeader.firstMatch(candidate);
        if (keyValueMatch == null) {
          invalidHeaders.add(candidate);
          continue;
        }

        webHeaders[keyValueMatch.group(1)!] = keyValueMatch.group(2)!;
      }

      if (invalidHeaders.isNotEmpty) {
        throwToolExit('Invalid web headers: ${invalidHeaders.join(', ')}');
      }
    }

    return webHeaders;
  }

  void _registerSignalHandlers(String commandPath, DateTime startTime) {
    void handler(io.ProcessSignal s) {
      globals.cache.releaseLock();
      _sendPostUsage(
        commandPath,
        const FlutterCommandResult(ExitStatus.killed),
        startTime,
        globals.systemClock.now(),
      );
    }

    globals.signals.addHandler(io.ProcessSignal.sigterm, handler);
    globals.signals.addHandler(io.ProcessSignal.sigint, handler);
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
    // Send command result.
    final int? maxRss = getMaxRss(processInfo);
    analytics.send(
      Event.flutterCommandResult(
        commandPath: commandPath,
        result: commandResult.toString(),
        maxRss: maxRss,
        commandHasTerminal: hasTerminal,
      ),
    );

    // Send timing.
    final labels = <String?>[
      commandResult.exitStatus.name,
      if (commandResult.timingLabelParts?.isNotEmpty ?? false) ...?commandResult.timingLabelParts,
    ];

    final String label = labels
        .where((String? label) => label != null && !_isBlank(label))
        .join('-');

    // If the command provides its own end time, use it. Otherwise report
    // the duration of the entire execution.
    final Duration elapsedDuration = (commandResult.endTimeOverride ?? endTime).difference(
      startTime,
    );
    analytics.send(
      Event.timing(
        workflow: 'flutter',
        variableName: name,
        elapsedMilliseconds: elapsedDuration.inMilliseconds,
        // Report in the form of `success-[parameter1-parameter2]`, all of which
        // can be null if the command doesn't provide a FlutterCommandResult.
        label: label == '' ? null : label,
      ),
    );
  }

  /// Perform validation then call [runCommand] to execute the command.
  /// Return a [Future] that completes with an exit code
  /// indicating whether execution was successful.
  ///
  /// Subclasses should override this method to perform verification
  /// then call this method to execute the command
  /// rather than calling [runCommand] directly.
  @mustCallSuper
  Future<FlutterCommandResult> verifyThenRunCommand(String? commandPath) async {
    globals.preRunValidator.validate();

    if (argParser.options.containsKey(FlutterOptions.kEnableImpeller) &&
        (argResults?.wasParsed(FlutterOptions.kEnableImpeller) ?? false)) {
      if (getBuildMode().isRelease) {
        final bool enableImpeller = boolArg(FlutterOptions.kEnableImpeller);
        final flagName = enableImpeller
            ? '--${FlutterOptions.kEnableImpeller}'
            : '--no-${FlutterOptions.kEnableImpeller}';
        globals.logger.printWarning(
          'The "$flagName" flag is ignored in release builds. '
          'The rendering backend is determined at build time.',
        );
      }
    }

    if (globals.os.hostPlatform == .darwin_x64 &&
        globals.persistentToolState!.shouldShowIntelMacWarning) {
      globals.logger.printWarning(
        'Flutter is deprecating support for Intel-based Macs. '
        'A future version of Flutter will require an Apple Silicon Mac to build applications.',
      );
      globals.persistentToolState!.shouldShowIntelMacWarning = false;
    }

    if (refreshWirelessDevices) {
      // Loading wireless devices takes longer so start it early.
      _targetDevices.startExtendedWirelessDeviceDiscovery(
        deviceDiscoveryTimeout: deviceDiscoveryTimeout,
      );
    }

    final FlutterProject project;
    try {
      project = await _updateCacheAndRunPubGet();
    } finally {
      globals.cache.releaseLock();
    }

    if (regeneratePlatformSpecificToolingDuringVerify) {
      await regeneratePlatformSpecificToolingIfApplicable(
        project,
        releaseMode: getBuildMode().isRelease,
      );
    }

    setupApplicationPackages();

    if (commandPath != null) {
      analytics.send(await unifiedAnalyticsUsageValues(commandPath));
    }

    return runCommand();
  }

  Future<FlutterProject> _updateCacheAndRunPubGet() async {
    // Populate the cache. We call this before pub get below so that the
    // sky_engine package is available in the flutter cache for pub to find.
    if (shouldUpdateCache) {
      // First always update universal artifacts, as some of these (e.g.
      // ios-deploy on macOS) are required to determine `requiredArtifacts`.
      final bool offline;
      if (argParser.options.containsKey('offline')) {
        offline = boolArg('offline');
      } else {
        offline = false;
      }
      await globals.cache.updateAll(<DevelopmentArtifact>{
        DevelopmentArtifact.universal,
      }, offline: offline);
      await globals.cache.updateAll(await requiredArtifacts, offline: offline);
    }
    await validateCommand();

    final FlutterProject project = FlutterProject.current();
    project.checkForDeprecation(deprecationBehavior: deprecationBehavior);

    if (shouldRunPub) {
      await pub.get(
        context: PubContext.getVerifyContext(name),
        project: project,
        checkUpToDate: cachePubGet,
      );
    }
    return project;
  }

  /// Whether to run [FlutterProject.regeneratePlatformSpecificTooling] in [verifyThenRunCommand].
  ///
  /// By default `true`, but sub-commands that do _meta_ builds (make multiple different
  /// builds sequentially in one-go) may choose to override this and provide `false`, instead
  /// calling [FlutterProject.regeneratePlatformSpecificTooling] manually when applicable.
  @visibleForOverriding
  bool get regeneratePlatformSpecificToolingDuringVerify => true;

  /// Runs [FlutterProject.regeneratePlatformSpecificTooling] for [project] with appropriate configuration.
  ///
  /// This method should only be called when [shouldRunPub] is `true`:
  /// ```dart
  /// if (shouldRunPub) {
  ///   await regeneratePlatformSpecificTooling(project);
  /// }
  /// ```
  ///
  /// See also:
  ///
  /// - <https://github.com/flutter/flutter/issues/162649>.
  @protected
  @nonVirtual
  Future<void> regeneratePlatformSpecificToolingIfApplicable(
    FlutterProject project, {
    required bool releaseMode,
  }) async {
    if (!shouldRunPub) {
      return;
    }
    await project.regeneratePlatformSpecificTooling(releaseMode: releaseMode);
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
  ///
  /// If [canPrompt] is true, the tool will interactively prompt the user to
  /// select a device when multiple devices are found and a terminal is
  /// attached. If [canPrompt] is false, the interactive prompt is bypassed.
  /// If not specified, [canPrompt] defaults to `!outputMachineFormat`.
  Future<List<Device>?> findAllTargetDevices({
    bool? canPrompt,
    bool includeDevicesUnsupportedByProject = false,
  }) async {
    return _targetDevices.findAllTargetDevices(
      canPrompt: canPrompt ?? !outputMachineFormat,
      deviceDiscoveryTimeout: deviceDiscoveryTimeout,
      includeDevicesUnsupportedByProject: includeDevicesUnsupportedByProject,
    );
  }

  /// Find and return the target [Device] based upon currently connected
  /// devices and criteria entered by the user on the command line.
  /// If a device cannot be found that meets specified criteria,
  /// then print an error message and return null.
  ///
  /// If [includeDevicesUnsupportedByProject] is true, the tool does not filter
  /// the list by the current project support list.
  Future<Device?> findTargetDevice({bool includeDevicesUnsupportedByProject = false}) async {
    final List<Device>? deviceList = await findAllTargetDevices(
      includeDevicesUnsupportedByProject: includeDevicesUnsupportedByProject,
    );
    if (deviceList == null) {
      return null;
    }
    if (deviceList.length > 1) {
      globals.printStatus(globals.userMessages.flutterSpecifyDevice);
      final List<Device> allDevices = await globals.deviceManager!.getAllDevices();
      globals.printStatus('');
      await Device.printDevices(allDevices, globals.logger);
      return null;
    }
    return deviceList.single;
  }

  @protected
  void validateUseApplicationBinaryForAndroidEngineConfigOptions() {
    final String? applicationBinary = argParser.options.containsKey(FlutterOptions.kUseApplicationBinary)
        ? stringArg(FlutterOptions.kUseApplicationBinary)
        : null;
    if (applicationBinary != null && applicationBinary.toLowerCase().endsWith('.apk')) {
      final BuildMode buildMode = getBuildMode();
      if (buildMode == BuildMode.release) {
        final Iterable<String> intentFlags = AndroidEngineCliFlags.allFlags.where(
          (String flag) =>
              argParser.options.containsKey(flag) && argResults?.wasParsed(flag) == true,
        );

        if (intentFlags.isNotEmpty) {
          throwToolExit(
            'Using --${FlutterOptions.kUseApplicationBinary} in release mode and additional flags used to configure the Flutter Android embedding '
            'is not supported for Android (${intentFlags.join(', ')}). Please do not use a prebuilt binary or define the '
            'required flags via the Android manifest. See TODO(camsim99) for more details.',
          );
        }
      }
    }
  }

  @protected
  @mustCallSuper
  Future<void> validateCommand() async {
    validateUseApplicationBinaryForAndroidEngineConfigOptions();
    if (_requiresPubspecYaml && globalResults?.wasParsed('packages') != true) {
      // Don't expect a pubspec.yaml file if the user passed in an explicit package_config.json file path.

      // If there is no pubspec in the current directory, look in the parent
      // until one can be found.
      final String? path = findProjectRoot(globals.fs, globals.fs.currentDirectory.path);
      if (path == null) {
        throwToolExit(globals.userMessages.flutterNoPubspec);
      }
      if (path != globals.fs.currentDirectory.path) {
        globals.fs.currentDirectory = path;
        globals.printStatus(
          'Changing current working directory to: ${globals.fs.currentDirectory.path}',
        );
      }
    }

    if (_usesTargetOption) {
      final String targetPath = targetFile;
      if (!globals.fs.isFileSync(targetPath)) {
        throwToolExit(globals.userMessages.flutterTargetFileMissing(targetPath));
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
        '${globals.logger.terminal.warningMark} Deprecated. This command will be removed in a future version of Flutter.',
      description,
      '',
      'Global options:',
      '${runner?.argParser.usage}',
      '',
      usageWithoutDescription,
    ].join('\n');
    return help;
  }

  ApplicationPackageFactory? applicationPackages;

  /// Gets the parsed command-line flag named [name] as a `bool`.
  ///
  /// If no flag named [name] was added to the [ArgParser], an [ArgumentError]
  /// will be thrown.
  bool boolArg(String name, {bool global = false}) {
    return (global ? globalResults : argResults)!.flag(name);
  }

  /// Gets the parsed command-line option named [name] as a `String`.
  ///
  /// If no option named [name] was added to the [ArgParser], an [ArgumentError]
  /// will be thrown.
  String? stringArg(String name, {bool global = false}) {
    return (global ? globalResults : argResults)!.option(name);
  }

  /// Gets the parsed command-line option named [name] as `List<String>`.
  List<String> stringsArg(String name, {bool global = false}) {
    return (global ? globalResults : argResults)!.multiOption(name);
  }
}

/// A mixin which applies an implementation of [requiredArtifacts] that only
/// downloads artifacts corresponding to potentially connected devices.
mixin DeviceBasedDevelopmentArtifacts on FlutterCommand {
  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async {
    // If there are no devices, use the default configuration.
    // Otherwise, only add development artifacts corresponding to
    // potentially connected devices. We might not be able to determine if a
    // device is connected yet, so include it in case it becomes connected.
    final List<Device> devices = await globals.deviceManager!.getDevices(
      filter: DeviceDiscoveryFilter(excludeDisconnected: false),
    );
    if (devices.isEmpty) {
      return super.requiredArtifacts;
    }
    final artifacts = <DevelopmentArtifact>{DevelopmentArtifact.universal};
    for (final device in devices) {
      final TargetPlatform targetPlatform = await device.targetPlatform;
      final DevelopmentArtifact? developmentArtifact = artifactFromTargetPlatform(targetPlatform);
      if (developmentArtifact != null) {
        artifacts.add(developmentArtifact);
      }
    }
    return artifacts;
  }
}

// Returns the development artifact for the target platform, or null
// if none is supported
@protected
DevelopmentArtifact? artifactFromTargetPlatform(TargetPlatform targetPlatform) {
  switch (targetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.android_arm:
    case TargetPlatform.android_arm64:
    case TargetPlatform.android_x64:
      return DevelopmentArtifact.androidGenSnapshot;
    case TargetPlatform.web_javascript:
      return DevelopmentArtifact.web;
    case TargetPlatform.ios:
      return DevelopmentArtifact.iOS;
    case TargetPlatform.darwin:
      if (featureFlags.isMacOSEnabled) {
        return DevelopmentArtifact.macOS;
      }
      return null;
    case TargetPlatform.windows_x64:
    case TargetPlatform.windows_arm64:
      if (featureFlags.isWindowsEnabled) {
        return DevelopmentArtifact.windows;
      }
      return null;
    case TargetPlatform.linux_x64:
    case TargetPlatform.linux_arm64:
    case TargetPlatform.linux_riscv64:
      if (featureFlags.isLinuxEnabled) {
        return DevelopmentArtifact.linux;
      }
      return null;
    case TargetPlatform.fuchsia_arm64:
    case TargetPlatform.fuchsia_x64:
    case TargetPlatform.tester:
    case TargetPlatform.unsupported:
      return null;
  }
}

/// Returns true if s is either null, empty or is solely made of whitespace characters (as defined by String.trim).
bool _isBlank(String s) => s.trim().isEmpty;
