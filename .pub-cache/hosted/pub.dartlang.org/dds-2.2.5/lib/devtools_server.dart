// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:browser_launcher/browser_launcher.dart';
import 'package:devtools_shared/devtools_shared.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf;

import 'src/devtools/client.dart';
import 'src/devtools/handler.dart';
import 'src/devtools/machine_mode_command_handler.dart';
import 'src/devtools/memory_profile.dart';
import 'src/devtools/utils.dart';
import 'src/utils/console.dart';

class DevToolsServer {
  static const protocolVersion = '1.1.0';
  static const defaultTryPorts = 10;
  static const commandDescription =
      'Open DevTools (optionally connecting to an existing application).';

  static const argHelp = 'help';
  static const argVmUri = 'vm-uri';
  static const argEnableNotifications = 'enable-notifications';
  static const argAllowEmbedding = 'allow-embedding';
  static const argAppSizeBase = 'appSizeBase';
  static const argAppSizeTest = 'appSizeTest';
  static const argHeadlessMode = 'headless';
  static const argDebugMode = 'debug';
  static const argLaunchBrowser = 'launch-browser';
  static const argMachine = 'machine';
  static const argHost = 'host';
  static const argPort = 'port';
  static const argProfileMemory = 'record-memory-profile';
  static const argTryPorts = 'try-ports';
  static const argVerbose = 'verbose';
  static const argVersion = 'version';
  static const launchDevToolsService = 'launchDevTools';

  MachineModeCommandHandler? _machineModeCommandHandler;
  late ClientManager clientManager;
  final bool _isChromeOS = File('/dev/.cros_milestone').existsSync();

  /// Builds an arg parser for the DevTools server.
  ///
  /// [includeHelpOption] should be set to false if this arg parser will be used
  /// in a Command subclass.
  static ArgParser buildArgParser({
    bool verbose = false,
    bool includeHelpOption = true,
  }) {
    final argParser = ArgParser();

    if (includeHelpOption) {
      argParser.addFlag(
        argHelp,
        negatable: false,
        abbr: 'h',
        help: 'Prints help output.',
      );
    }
    argParser
      ..addFlag(
        argVersion,
        negatable: false,
        help: 'Prints the DevTools version.',
      )
      ..addFlag(
        argVerbose,
        negatable: false,
        abbr: 'v',
        help: 'Output more informational messages.',
      )
      ..addOption(
        argHost,
        valueHelp: 'host',
        help: 'Hostname to serve DevTools on (defaults to localhost).',
      )
      ..addOption(
        argPort,
        defaultsTo: '9100',
        valueHelp: 'port',
        help: 'Port to serve DevTools on; specify 0 to automatically use any '
            'available port.',
      )
      ..addFlag(
        argLaunchBrowser,
        help:
            'Launches DevTools in a browser immediately at start.\n(defaults to on unless in --machine mode)',
      )
      ..addFlag(
        argMachine,
        negatable: false,
        help: 'Sets output format to JSON for consumption in tools.',
      )
      ..addSeparator('Memory profiling options:')
      ..addOption(
        argProfileMemory,
        valueHelp: 'file',
        defaultsTo: 'memory_samples.json',
        help:
            'Start devtools headlessly and write memory profiling samples to the '
            'indicated file.',
      );

    if (verbose) {
      argParser.addSeparator('App size options:');
    }

    // TODO(devoncarew): --appSizeBase and --appSizeTest should be renamed to
    // something like --app-size-base and --app-size-test; #3146.
    argParser
      ..addOption(
        argAppSizeBase,
        valueHelp: 'appSizeBase',
        help: 'Path to the base app size file used for app size debugging.',
        hide: !verbose,
      )
      ..addOption(
        argAppSizeTest,
        valueHelp: 'appSizeTest',
        help:
            'Path to the test app size file used for app size debugging.\nThis '
            'file should only be specified if --$argAppSizeBase is also specified.',
        hide: !verbose,
      );

    if (verbose) {
      argParser.addSeparator('Advanced options:');
    }

    // Args to show for verbose mode.
    argParser
      ..addOption(
        argTryPorts,
        defaultsTo: DevToolsServer.defaultTryPorts.toString(),
        valueHelp: 'count',
        help: 'The number of ascending ports to try binding to before failing '
            'with an error. ',
        hide: !verbose,
      )
      ..addFlag(
        argEnableNotifications,
        negatable: false,
        help: 'Requests notification permissions immediately when a client '
            'connects back to the server.',
        hide: !verbose,
      )
      ..addFlag(
        argAllowEmbedding,
        help: 'Allow embedding DevTools inside an iframe.',
        hide: !verbose,
      )
      ..addFlag(
        argHeadlessMode,
        negatable: false,
        help: 'Causes the server to spawn Chrome in headless mode for use in '
            'automated testing.',
        hide: !verbose,
      );

    // Deprecated and hidden args.
    // TODO: Remove this - prefer that clients use the rest arg.
    argParser
      ..addOption(
        argVmUri,
        defaultsTo: '',
        help: 'VM Service protocol URI.',
        hide: true,
      )

      // Development only args.
      ..addFlag(
        argDebugMode,
        negatable: false,
        help: 'Run a debug build of the DevTools web frontend.',
        hide: true,
      );

    return argParser;
  }

  /// Serves DevTools.
  ///
  /// `handler` is the [shelf.Handler] that the server will use for all requests.
  /// If null, [defaultHandler] will be used. Defaults to null.
  ///
  /// `customDevToolsPath` is a path to a directory containing a pre-built
  /// DevTools application.
  ///
  // Note: this method is used by the Dart CLI and by package:dwds.
  Future<HttpServer?> serveDevTools({
    bool enableStdinCommands = true,
    bool machineMode = false,
    bool debugMode = false,
    bool launchBrowser = false,
    bool enableNotifications = false,
    bool allowEmbedding = true,
    bool headlessMode = false,
    bool verboseMode = false,
    String? hostname,
    String? customDevToolsPath,
    int port = 0,
    int numPortsToTry = defaultTryPorts,
    shelf.Handler? handler,
    String? serviceProtocolUri,
    String? profileFilename,
    String? appSizeBase,
    String? appSizeTest,
  }) async {
    hostname ??= 'localhost';

    // Collect profiling information.
    if (profileFilename != null && serviceProtocolUri != null) {
      final Uri? vmServiceUri = Uri.tryParse(serviceProtocolUri);
      if (vmServiceUri != null) {
        await _hookupMemoryProfiling(
          vmServiceUri,
          profileFilename,
          verboseMode,
        );
      }
      return null;
    }

    if (machineMode) {
      assert(
        enableStdinCommands,
        'machineMode only works with enableStdinCommands.',
      );
    }

    clientManager = ClientManager(
      requestNotificationPermissions: enableNotifications,
    );
    handler ??= await defaultHandler(
      buildDir: customDevToolsPath!,
      clientManager: clientManager,
    );

    HttpServer? server;
    SocketException? ex;
    while (server == null && numPortsToTry >= 0) {
      // If we have tried [numPortsToTry] ports and still have not been able to
      // connect, try port 0 to find a random available port.
      if (numPortsToTry == 0) port = 0;

      try {
        server = await HttpMultiServer.bind(hostname, port);
      } on SocketException catch (e) {
        ex = e;
        numPortsToTry--;
        port++;
      }
    }

    // Re-throw the last exception if we failed to bind.
    if (server == null && ex != null) {
      throw ex;
    }

    final _server = server!;
    if (allowEmbedding) {
      _server.defaultResponseHeaders.remove('x-frame-options', 'SAMEORIGIN');
      // The origin-agent-cluster header is required to support the embedding of
      // Dart DevTools in Chrome DevTools.
      _server.defaultResponseHeaders.add('origin-agent-cluster', '?1');
    }

    // Ensure browsers don't cache older versions of the app.
    _server.defaultResponseHeaders.add(
      HttpHeaders.cacheControlHeader,
      'max-age=0',
    );

    // Serve requests in an error zone to prevent failures
    // when running from another error zone.
    runZonedGuarded(
      () => shelf.serveRequests(_server, handler!),
      (e, _) => print('Error serving requests: $e'),
    );

    final devToolsUrl = 'http://${_server.address.host}:${_server.port}';

    if (launchBrowser) {
      if (serviceProtocolUri != null) {
        serviceProtocolUri =
            normalizeVmServiceUri(serviceProtocolUri).toString();
      }

      final queryParameters = {
        if (serviceProtocolUri != null) 'uri': serviceProtocolUri,
        if (appSizeBase != null) 'appSizeBase': appSizeBase,
        if (appSizeTest != null) 'appSizeTest': appSizeTest,
      };
      String url = Uri.parse(devToolsUrl)
          .replace(queryParameters: queryParameters)
          .toString();

      // If app size parameters are present, open to the standalone `appsize`
      // page, regardless if there is a vm service uri specified. We only check
      // for the presence of [appSizeBase] here because [appSizeTest] may or may
      // not be specified (it should only be present for diffs). If [appSizeTest]
      // is present without [appSizeBase], we will ignore the parameter.
      if (appSizeBase != null) {
        final startQueryParamIndex = url.indexOf('?');
        if (startQueryParamIndex != -1) {
          url = '${url.substring(0, startQueryParamIndex)}'
              '/#/appsize'
              '${url.substring(startQueryParamIndex)}';
        }
      }

      try {
        await Chrome.start([url]);
      } catch (e) {
        print('Unable to launch Chrome: $e\n');
      }
    }

    if (enableStdinCommands) {
      String message = '''Serving DevTools at $devToolsUrl.

          Hit ctrl-c to terminate the server.''';
      if (!machineMode && debugMode) {
        // Add bold to help find the correct url to open.
        message = ConsoleUtils.bold('$message\n');
      }

      DevToolsUtils.printOutput(
        message,
        {
          'event': 'server.started',
          // TODO(dantup): Remove this `method` field when we're sure VS Code
          // users are all on a newer version that uses `event`. We incorrectly
          // used `method` for the original releases.
          'method': 'server.started',
          'params': {
            'host': _server.address.host,
            'port': _server.port,
            'pid': pid,
            'protocolVersion': protocolVersion,
          }
        },
        machineMode: machineMode,
      );

      if (machineMode) {
        _machineModeCommandHandler = MachineModeCommandHandler(server: this);
        await _machineModeCommandHandler!.initialize(
          devToolsUrl: devToolsUrl,
          headlessMode: headlessMode,
        );
      }
    }

    return server;
  }

  void _printUsage(ArgParser argParser) {
    print(commandDescription);
    print('\nUsage: devtools [arguments] [service protocol uri]');
    print(argParser.usage);
  }

  /// Wraps [serveDevTools] `arguments` parsed, as from the command line.
  ///
  /// For more information on `handler`, see [serveDevTools].
  // Note: this method is used in google3 as well as by DevTools' main method.
  Future<HttpServer?> serveDevToolsWithArgs(
    List<String> arguments, {
    shelf.Handler? handler,
    String? customDevToolsPath,
  }) async {
    ArgResults args;
    final verbose = arguments.contains('-v') || arguments.contains('--verbose');
    final argParser = buildArgParser(verbose: verbose);
    try {
      args = argParser.parse(arguments);
    } on FormatException catch (e) {
      print(e.message);
      print('');
      _printUsage(argParser);
      return null;
    }

    return await _serveDevToolsWithArgs(
      args,
      verbose,
      handler: handler,
      customDevToolsPath: customDevToolsPath,
    );
  }

  Future<HttpServer?> _serveDevToolsWithArgs(
    ArgResults args,
    bool verbose, {
    shelf.Handler? handler,
    String? customDevToolsPath,
  }) async {
    final help = args[argHelp];
    final bool version = args[argVersion];
    final bool machineMode = args[argMachine];
    // launchBrowser defaults based on machine-mode if not explicitly supplied.
    final bool launchBrowser = args.wasParsed(argLaunchBrowser)
        ? args[argLaunchBrowser]
        : !machineMode;
    final bool enableNotifications = args[argEnableNotifications];
    final bool allowEmbedding =
        args.wasParsed(argAllowEmbedding) ? args[argAllowEmbedding] : true;

    final port = args[argPort] != null ? int.tryParse(args[argPort]) ?? 0 : 0;

    final bool headlessMode = args[argHeadlessMode];
    final bool debugMode = args[argDebugMode];

    final numPortsToTry = args[argTryPorts] != null
        ? int.tryParse(args[argTryPorts]) ?? 0
        : defaultTryPorts;

    final bool verboseMode = args[argVerbose];
    final String? hostname = args[argHost];
    final String? appSizeBase = args[argAppSizeBase];
    final String? appSizeTest = args[argAppSizeTest];

    if (help) {
      print(
          'Dart DevTools version ${await DevToolsUtils.getVersion(customDevToolsPath ?? "")}');
      print('');
      _printUsage(buildArgParser(verbose: verbose));
      return null;
    }

    if (version) {
      final versionStr =
          await DevToolsUtils.getVersion(customDevToolsPath ?? '');
      DevToolsUtils.printOutput(
        'Dart DevTools version $versionStr',
        {
          'version': versionStr,
        },
        machineMode: machineMode,
      );
      return null;
    }

    // Prefer getting the VM URI from the rest args; fall back on the 'vm-url'
    // option otherwise.
    String? serviceProtocolUri;
    if (args.rest.isNotEmpty) {
      serviceProtocolUri = args.rest.first;
    } else if (args.wasParsed(argVmUri)) {
      serviceProtocolUri = args[argVmUri];
    }

    // Support collecting profile data.
    String? profileFilename;
    if (args.wasParsed(argProfileMemory)) {
      profileFilename = args[argProfileMemory];
    }
    if (profileFilename != null && !path.isAbsolute(profileFilename)) {
      profileFilename = path.absolute(profileFilename);
    }

    return serveDevTools(
      machineMode: machineMode,
      debugMode: debugMode,
      launchBrowser: launchBrowser,
      enableNotifications: enableNotifications,
      allowEmbedding: allowEmbedding,
      port: port,
      headlessMode: headlessMode,
      numPortsToTry: numPortsToTry,
      handler: handler,
      customDevToolsPath: customDevToolsPath,
      serviceProtocolUri: serviceProtocolUri,
      profileFilename: profileFilename,
      verboseMode: verboseMode,
      hostname: hostname,
      appSizeBase: appSizeBase,
      appSizeTest: appSizeTest,
    );
  }

  Future<Map<String, dynamic>> launchDevTools(
    Map<String, dynamic> params,
    Uri vmServiceUri,
    String devToolsUrl,
    bool headlessMode,
    bool machineMode,
  ) async {
    // First see if we have an existing DevTools client open that we can
    // reuse.
    final canReuse =
        params.containsKey('reuseWindows') && params['reuseWindows'] == true;
    final shouldNotify =
        params.containsKey('notify') && params['notify'] == true;
    final page = params['page'];
    if (canReuse &&
        _tryReuseExistingDevToolsInstance(
          vmServiceUri,
          page,
          shouldNotify,
        )) {
      _emitLaunchEvent(
        reused: true,
        notified: shouldNotify,
        pid: null,
        machineMode: machineMode,
      );
      return {
        'reused': true,
        'notified': shouldNotify,
      };
    }

    final uriParams = <String, dynamic>{};

    // Copy over queryParams passed by the client
    params['queryParams']?.forEach((key, value) => uriParams[key] = value);

    // Add the URI to the VM service
    uriParams['uri'] = vmServiceUri.toString();

    final devToolsUri = Uri.parse(devToolsUrl);
    final uriToLaunch = _buildUriToLaunch(uriParams, page, devToolsUri);

    // TODO(dantup): When ChromeOS has support for tunneling all ports we can
    // change this to always use the native browser for ChromeOS and may wish to
    // handle this inside `browser_launcher`; https://crbug.com/848063.
    final useNativeBrowser = _isChromeOS &&
        _isAccessibleToChromeOSNativeBrowser(devToolsUri) &&
        _isAccessibleToChromeOSNativeBrowser(vmServiceUri);
    int? browserPid;
    if (useNativeBrowser) {
      await Process.start('x-www-browser', [uriToLaunch.toString()]);
    } else {
      final args = headlessMode
          ? [
              '--headless',
              // When running headless, Chrome will quit immediately after loading
              // the page unless we have the debug port open.
              '--remote-debugging-port=9223',
              '--disable-gpu',
              '--no-sandbox',
            ]
          : <String>[];
      final proc = await Chrome.start([uriToLaunch.toString()], args: args);
      browserPid = proc.pid;
    }
    _emitLaunchEvent(
        reused: false,
        notified: false,
        pid: browserPid!,
        machineMode: machineMode);
    return {
      'reused': false,
      'notified': false,
      'pid': browserPid,
    };
  }

  Future<void> _hookupMemoryProfiling(
    Uri observatoryUri,
    String profileFile, [
    bool verboseMode = false,
  ]) async {
    final service = await DevToolsUtils.connectToVmService(observatoryUri);
    if (service == null) {
      return;
    }

    final memoryProfiler = MemoryProfile(service, profileFile, verboseMode);
    memoryProfiler.startPolling();

    print('Writing memory profile samples to $profileFile...');
  }

  bool _tryReuseExistingDevToolsInstance(
    Uri vmServiceUri,
    String? page,
    bool notifyUser,
  ) {
    // First try to find a client that's already connected to this VM service,
    // and just send the user a notification for that one.
    final existingClient =
        clientManager.findExistingConnectedReusableClient(vmServiceUri);
    if (existingClient != null) {
      try {
        if (page != null) {
          existingClient.showPage(page);
        }
        if (notifyUser) {
          existingClient.notify();
        }
        return true;
      } catch (e) {
        print('Failed to reuse existing connected DevTools client');
        print(e);
      }
    }

    final reusableClient = clientManager.findReusableClient();
    if (reusableClient != null) {
      try {
        reusableClient.connectToVmService(vmServiceUri, notifyUser);
        return true;
      } catch (e) {
        print('Failed to reuse existing DevTools client');
        print(e);
      }
    }
    return false;
  }

  String _buildUriToLaunch(
    Map<String, dynamic> uriParams,
    String? page,
    Uri devToolsUri,
  ) {
    final queryStringNameValues = [];
    uriParams.forEach((key, value) => queryStringNameValues.add(
        '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}'));

    if (page != null) {
      queryStringNameValues.add('page=${Uri.encodeQueryComponent(page)}');
    }

    return devToolsUri
        .replace(
            path: '${devToolsUri.path.isEmpty ? '/' : devToolsUri.path}',
            fragment: '?${queryStringNameValues.join('&')}')
        .toString();
  }

  /// Prints a launch event to stdout so consumers of the DevTools server
  /// can see when clients are being launched/reused.
  void _emitLaunchEvent(
      {required bool reused,
      required bool notified,
      required int? pid,
      required bool machineMode}) {
    DevToolsUtils.printOutput(
      null,
      {
        'event': 'client.launch',
        'params': {
          'reused': reused,
          'notified': notified,
          'pid': pid,
        },
      },
      machineMode: machineMode,
    );
  }

  bool _isAccessibleToChromeOSNativeBrowser(Uri uri) {
    const tunneledPorts = {
      8000,
      8008,
      8080,
      8085,
      8888,
      9005,
      3000,
      4200,
      5000
    };
    return uri.hasPort && tunneledPorts.contains(uri.port);
  }
}
