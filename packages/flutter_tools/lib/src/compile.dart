// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:process/process.dart';
import 'package:usage/uuid/uuid.dart';

import 'artifacts.dart';
import 'base/common.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/io.dart';
import 'base/logger.dart';
import 'build_info.dart';
import 'convert.dart';
import 'globals.dart' as globals;
import 'project.dart';

KernelCompilerFactory get kernelCompilerFactory => context.get<KernelCompilerFactory>();

class KernelCompilerFactory {
  const KernelCompilerFactory({
    @required FileSystem fileSystem,
    @required Artifacts artifacts,
    @required ProcessManager processManager,
    @required Logger logger,
  }) : _fileSystem = fileSystem,
       _artifacts = artifacts,
       _processManager = processManager,
       _logger = logger;

  final Logger _logger;
  final Artifacts _artifacts;
  final ProcessManager _processManager;
  final FileSystem _fileSystem;

  Future<KernelCompiler> create(FlutterProject flutterProject) async {
    return KernelCompiler(
      logger: _logger,
      artifacts: _artifacts,
      fileSystem: _fileSystem,
      processManager: _processManager,
    );
  }
}

/// The target model describes the set of core libraries that are available within
/// the SDK.
class TargetModel {
  /// Parse a [TargetModel] from a raw string.
  ///
  /// Throws an [AssertionError] if passed a value other than 'flutter' or
  /// 'flutter_runner'.
  factory TargetModel(String rawValue) {
    switch (rawValue) {
      case 'flutter':
        return flutter;
      case 'flutter_runner':
        return flutterRunner;
      case 'vm':
        return vm;
      case 'dartdevc':
        return dartdevc;
    }
    assert(false);
    return null;
  }

  const TargetModel._(this._value);

  /// The Flutter patched Dart SDK.
  static const TargetModel flutter = TargetModel._('flutter');

  /// The Fuchsia patched SDK.
  static const TargetModel flutterRunner = TargetModel._('flutter_runner');

  /// The Dart VM.
  static const TargetModel vm = TargetModel._('vm');

  /// The development compiler for JavaScript.
  static const TargetModel dartdevc = TargetModel._('dartdevc');

  final String _value;

  @override
  String toString() => _value;
}

class CompilerOutput {
  const CompilerOutput(this.outputFilename, this.errorCount, this.sources);

  final String outputFilename;
  final int errorCount;
  final List<Uri> sources;
}

enum StdoutState { CollectDiagnostic, CollectDependencies }

/// Handles stdin/stdout communication with the frontend server.
class StdoutHandler {
  StdoutHandler({
    @required Logger logger
  }) : _logger = logger {
    reset();
  }

  final Logger _logger;

  String boundaryKey;
  StdoutState state = StdoutState.CollectDiagnostic;
  Completer<CompilerOutput> compilerOutput;
  final List<Uri> sources = <Uri>[];

  bool _suppressCompilerMessages;
  bool _expectSources;

  void handler(String message) {
    const String kResultPrefix = 'result ';
    if (boundaryKey == null && message.startsWith(kResultPrefix)) {
      boundaryKey = message.substring(kResultPrefix.length);
      return;
    }
    if (message.startsWith(boundaryKey)) {
      if (_expectSources) {
        if (state == StdoutState.CollectDiagnostic) {
          state = StdoutState.CollectDependencies;
          return;
        }
      }
      if (message.length <= boundaryKey.length) {
        compilerOutput.complete(null);
        return;
      }
      final int spaceDelimiter = message.lastIndexOf(' ');
      compilerOutput.complete(
          CompilerOutput(
              message.substring(boundaryKey.length + 1, spaceDelimiter),
              int.parse(message.substring(spaceDelimiter + 1).trim()),
              sources));
      return;
    }
    if (state == StdoutState.CollectDiagnostic) {
      if (!_suppressCompilerMessages) {
        _logger.printError(message);
      } else {
        _logger.printTrace(message);
      }
    } else {
      assert(state == StdoutState.CollectDependencies);
      switch (message[0]) {
        case '+':
          sources.add(Uri.parse(message.substring(1)));
          break;
        case '-':
          sources.remove(Uri.parse(message.substring(1)));
          break;
        default:
          _logger.printTrace('Unexpected prefix for $message uri - ignoring');
      }
    }
  }

  // This is needed to get ready to process next compilation result output,
  // with its own boundary key and new completer.
  void reset({ bool suppressCompilerMessages = false, bool expectSources = true }) {
    boundaryKey = null;
    compilerOutput = Completer<CompilerOutput>();
    _suppressCompilerMessages = suppressCompilerMessages;
    _expectSources = expectSources;
    state = StdoutState.CollectDiagnostic;
  }
}

/// List the preconfigured build options for a given build mode.
List<String> buildModeOptions(BuildMode mode) {
  switch (mode) {
    case BuildMode.debug:
      return <String>[
        '-Ddart.vm.profile=false',
        '-Ddart.vm.product=false',
        '--bytecode-options=source-positions,local-var-info,debugger-stops,instance-field-initializers,keep-unreachable-code,avoid-closure-call-instructions',
        '--enable-asserts',
      ];
    case BuildMode.profile:
      return <String>[
        '-Ddart.vm.profile=true',
        '-Ddart.vm.product=false',
        '--bytecode-options=source-positions',
      ];
    case BuildMode.release:
      return <String>[
        '-Ddart.vm.profile=false',
        '-Ddart.vm.product=true',
        '--bytecode-options=source-positions',
      ];
  }
  throw Exception('Unknown BuildMode: $mode');
}

/// A compiler interface for producing single (non-incremental) kernel files.
class KernelCompiler {
  KernelCompiler({
    FileSystem fileSystem, // TODO(jonahwilliams): migrate to @required after google3
    Logger logger, // TODO(jonahwilliams): migrate to @required after google3
    ProcessManager processManager, // TODO(jonahwilliams): migrate to @required after google3
    Artifacts artifacts, // TODO(jonahwilliams): migrate to @required after google3
  }) : _logger = logger ?? globals.logger,
       _fileSystem = fileSystem ?? globals.fs,
       _artifacts = artifacts ?? globals.artifacts,
       _processManager = processManager ?? globals.processManager;

  final FileSystem _fileSystem;
  final Artifacts _artifacts;
  final ProcessManager _processManager;
  final Logger _logger;

  Future<CompilerOutput> compile({
    String sdkRoot,
    String mainPath,
    String outputFilePath,
    String depFilePath,
    TargetModel targetModel = TargetModel.flutter,
    bool linkPlatformKernelIn = false,
    bool aot = false,
    List<String> extraFrontEndOptions,
    List<String> fileSystemRoots,
    String fileSystemScheme,
    String initializeFromDill,
    String platformDill,
    @required String packagesPath,
    @required BuildMode buildMode,
    @required bool trackWidgetCreation,
    @required List<String> dartDefines,
    @required PackageConfig packageConfig,
  }) async {
    final String frontendServer = _artifacts.getArtifactPath(
      Artifact.frontendServerSnapshotForEngineDartSdk
    );
    // This is a URI, not a file path, so the forward slash is correct even on Windows.
    if (!sdkRoot.endsWith('/')) {
      sdkRoot = '$sdkRoot/';
    }
    final String engineDartPath = _artifacts.getArtifactPath(Artifact.engineDartBinary);
    if (!_processManager.canRun(engineDartPath)) {
      throwToolExit('Unable to find Dart binary at $engineDartPath');
    }
    Uri mainUri;
    if (packagesPath != null) {
      mainUri = packageConfig.toPackageUri(_fileSystem.file(mainPath).uri);
    }
    if (outputFilePath != null && !_fileSystem.isFileSync(outputFilePath)) {
      _fileSystem.file(outputFilePath).createSync(recursive: true);
    }
    final List<String> command = <String>[
      engineDartPath,
      '--disable-dart-dev',
      frontendServer,
      '--sdk-root',
      sdkRoot,
      '--target=$targetModel',
      '-Ddart.developer.causal_async_stacks=${buildMode == BuildMode.debug}',
      for (final Object dartDefine in dartDefines)
        '-D$dartDefine',
      ...buildModeOptions(buildMode),
      if (trackWidgetCreation) '--track-widget-creation',
      if (!linkPlatformKernelIn) '--no-link-platform',
      if (aot) ...<String>[
        '--aot',
        '--tfa',
      ],
      if (packagesPath != null) ...<String>[
        '--packages',
        packagesPath,
      ],
      if (outputFilePath != null) ...<String>[
        '--output-dill',
        outputFilePath,
      ],
      if (depFilePath != null && (fileSystemRoots == null || fileSystemRoots.isEmpty)) ...<String>[
        '--depfile',
        depFilePath,
      ],
      if (fileSystemRoots != null)
        for (final String root in fileSystemRoots) ...<String>[
          '--filesystem-root',
          root,
        ],
      if (fileSystemScheme != null) ...<String>[
        '--filesystem-scheme',
        fileSystemScheme,
      ],
      if (initializeFromDill != null) ...<String>[
        '--initialize-from-dill',
        initializeFromDill,
      ],
      if (platformDill != null) ...<String>[
        '--platform',
        platformDill,
      ],
      ...?extraFrontEndOptions,
      mainUri?.toString() ?? mainPath,
    ];

    _logger.printTrace(command.join(' '));
    final Process server = await _processManager.start(command);

    final StdoutHandler _stdoutHandler = StdoutHandler(logger: _logger);
    server.stderr
      .transform<String>(utf8.decoder)
      .listen(_logger.printError);
    server.stdout
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen(_stdoutHandler.handler);
    final int exitCode = await server.exitCode;
    if (exitCode == 0) {
      return _stdoutHandler.compilerOutput.future;
    }
    return null;
  }
}

/// Class that allows to serialize compilation requests to the compiler.
abstract class _CompilationRequest {
  _CompilationRequest(this.completer);

  Completer<CompilerOutput> completer;

  Future<CompilerOutput> _run(DefaultResidentCompiler compiler);

  Future<void> run(DefaultResidentCompiler compiler) async {
    completer.complete(await _run(compiler));
  }
}

class _RecompileRequest extends _CompilationRequest {
  _RecompileRequest(
    Completer<CompilerOutput> completer,
    this.mainUri,
    this.invalidatedFiles,
    this.outputPath,
    this.packageConfig,
    this.suppressErrors,
  ) : super(completer);

  Uri mainUri;
  List<Uri> invalidatedFiles;
  String outputPath;
  PackageConfig packageConfig;
  bool suppressErrors;

  @override
  Future<CompilerOutput> _run(DefaultResidentCompiler compiler) async =>
      compiler._recompile(this);
}

class _CompileExpressionRequest extends _CompilationRequest {
  _CompileExpressionRequest(
    Completer<CompilerOutput> completer,
    this.expression,
    this.definitions,
    this.typeDefinitions,
    this.libraryUri,
    this.klass,
    this.isStatic,
  ) : super(completer);

  String expression;
  List<String> definitions;
  List<String> typeDefinitions;
  String libraryUri;
  String klass;
  bool isStatic;

  @override
  Future<CompilerOutput> _run(DefaultResidentCompiler compiler) async =>
      compiler._compileExpression(this);
}

class _CompileExpressionToJsRequest extends _CompilationRequest {
  _CompileExpressionToJsRequest(
    Completer<CompilerOutput> completer,
    this.libraryUri,
    this.line,
    this.column,
    this.jsModules,
    this.jsFrameValues,
    this.moduleName,
    this.expression,
  ) : super(completer);

  final String libraryUri;
  final int line;
  final int column;
  final Map<String, String> jsModules;
  final Map<String, String> jsFrameValues;
  final String moduleName;
  final String expression;

  @override
  Future<CompilerOutput> _run(DefaultResidentCompiler compiler) async =>
      compiler._compileExpressionToJs(this);
}

class _RejectRequest extends _CompilationRequest {
  _RejectRequest(Completer<CompilerOutput> completer) : super(completer);

  @override
  Future<CompilerOutput> _run(DefaultResidentCompiler compiler) async =>
      compiler._reject();
}

/// Wrapper around incremental frontend server compiler, that communicates with
/// server via stdin/stdout.
///
/// The wrapper is intended to stay resident in memory as user changes, reloads,
/// restarts the Flutter app.
abstract class ResidentCompiler {
  factory ResidentCompiler(String sdkRoot, {
    @required BuildMode buildMode,
    Logger logger, // TODO(jonahwilliams): migrate to @required after google3
    ProcessManager processManager, // TODO(jonahwilliams): migrate to @required after google3
    Artifacts artifacts, // TODO(jonahwilliams): migrate to @required after google3
    bool trackWidgetCreation,
    String packagesPath,
    List<String> fileSystemRoots,
    String fileSystemScheme,
    String initializeFromDill,
    TargetModel targetModel,
    bool unsafePackageSerialization,
    List<String> extraFrontEndOptions,
    String platformDill,
    List<String> dartDefines,
    String librariesSpec,
    // Deprecated
    List<String> experimentalFlags,
  }) = DefaultResidentCompiler;

  // TODO(jonahwilliams): find a better way to configure additional file system
  // roots from the runner.
  // See: https://github.com/flutter/flutter/issues/50494
  void addFileSystemRoot(String root);

  /// If invoked for the first time, it compiles Dart script identified by
  /// [mainPath], [invalidatedFiles] list is ignored.
  /// On successive runs [invalidatedFiles] indicates which files need to be
  /// recompiled. If [mainPath] is [null], previously used [mainPath] entry
  /// point that is used for recompilation.
  /// Binary file name is returned if compilation was successful, otherwise
  /// null is returned.
  Future<CompilerOutput> recompile(
    Uri mainUri,
    List<Uri> invalidatedFiles, {
    @required String outputPath,
    @required PackageConfig packageConfig,
    bool suppressErrors = false,
  });

  Future<CompilerOutput> compileExpression(
    String expression,
    List<String> definitions,
    List<String> typeDefinitions,
    String libraryUri,
    String klass,
    bool isStatic,
  );

  /// Compiles [expression] in [libraryUri] at [line]:[column] to JavaScript
  /// in [moduleName].
  ///
  /// Values listed in [jsFrameValues] are substituted for their names in the
  /// [expression].
  ///
  /// Ensures that all [jsModules] are loaded and accessible inside the
  /// expression.
  ///
  /// Example values of parameters:
  /// [moduleName] is of the form '/packages/hello_world_main.dart'
  /// [jsFrameValues] is a map from js variable name to its primitive value
  /// or another variable name, for example
  /// { 'x': '1', 'y': 'y', 'o': 'null' }
  /// [jsModules] is a map from variable name to the module name, where
  /// variable name is the name originally used in JavaScript to contain the
  /// module object, for example:
  /// { 'dart':'dart_sdk', 'main': '/packages/hello_world_main.dart' }
  /// Returns a [CompilerOutput] including the name of the file containing the
  /// compilation result and a number of errors.
  Future<CompilerOutput> compileExpressionToJs(
    String libraryUri,
    int line,
    int column,
    Map<String, String> jsModules,
    Map<String, String> jsFrameValues,
    String moduleName,
    String expression,
  );

  /// Should be invoked when results of compilation are accepted by the client.
  ///
  /// Either [accept] or [reject] should be called after every [recompile] call.
  void accept();

  /// Should be invoked when results of compilation are rejected by the client.
  ///
  /// Either [accept] or [reject] should be called after every [recompile] call.
  Future<CompilerOutput> reject();

  /// Should be invoked when frontend server compiler should forget what was
  /// accepted previously so that next call to [recompile] produces complete
  /// kernel file.
  void reset();

  Future<dynamic> shutdown();
}

@visibleForTesting
class DefaultResidentCompiler implements ResidentCompiler {
  DefaultResidentCompiler(
    String sdkRoot, {
    @required this.buildMode,
    Logger logger, // TODO(jonahwilliams): migrate to @required after google3
    ProcessManager processManager, // TODO(jonahwilliams): migrate to @required after google3
    Artifacts artifacts, // TODO(jonahwilliams): migrate to @required after google3
    this.trackWidgetCreation = true,
    this.packagesPath,
    this.fileSystemRoots,
    this.fileSystemScheme,
    this.initializeFromDill,
    this.targetModel = TargetModel.flutter,
    this.unsafePackageSerialization,
    this.extraFrontEndOptions,
    this.platformDill,
    List<String> dartDefines,
    this.librariesSpec,
    // Deprecated
    List<String> experimentalFlags, // ignore: avoid_unused_constructor_parameters
  }) : assert(sdkRoot != null),
       _logger = logger ?? globals.logger,
       _processManager = processManager ?? globals.processManager,
       _artifacts = artifacts ?? globals.artifacts,
       _stdoutHandler = StdoutHandler(logger: logger),
       dartDefines = dartDefines ?? const <String>[],
       // This is a URI, not a file path, so the forward slash is correct even on Windows.
       sdkRoot = sdkRoot.endsWith('/') ? sdkRoot : '$sdkRoot/';

  final Logger _logger;
  final ProcessManager _processManager;
  final Artifacts _artifacts;

  final BuildMode buildMode;
  final bool trackWidgetCreation;
  final String packagesPath;
  final TargetModel targetModel;
  final List<String> fileSystemRoots;
  final String fileSystemScheme;
  final String initializeFromDill;
  final bool unsafePackageSerialization;
  final List<String> extraFrontEndOptions;
  final List<String> dartDefines;
  final String librariesSpec;

  @override
  void addFileSystemRoot(String root) {
    fileSystemRoots.add(root);
  }

  /// The path to the root of the Dart SDK used to compile.
  ///
  /// This is used to resolve the [platformDill].
  final String sdkRoot;

  /// The path to the platform dill file.
  ///
  /// This does not need to be provided for the normal Flutter workflow.
  final String platformDill;

  Process _server;
  final StdoutHandler _stdoutHandler;
  bool _compileRequestNeedsConfirmation = false;

  final StreamController<_CompilationRequest> _controller = StreamController<_CompilationRequest>();

  @override
  Future<CompilerOutput> recompile(
    Uri mainUri,
    List<Uri> invalidatedFiles, {
    @required String outputPath,
    @required PackageConfig packageConfig,
    bool suppressErrors = false,
  }) async {
    assert(outputPath != null);
    if (!_controller.hasListener) {
      _controller.stream.listen(_handleCompilationRequest);
    }

    final Completer<CompilerOutput> completer = Completer<CompilerOutput>();
    _controller.add(
      _RecompileRequest(completer, mainUri, invalidatedFiles, outputPath, packageConfig, suppressErrors)
    );
    return completer.future;
  }

  Future<CompilerOutput> _recompile(_RecompileRequest request) async {
    _stdoutHandler.reset();
    _compileRequestNeedsConfirmation = true;
    _stdoutHandler._suppressCompilerMessages = request.suppressErrors;

    if (_server == null) {
      return _compile(
        request.packageConfig.toPackageUri(request.mainUri)?.toString() ?? request.mainUri.toString(),
        request.outputPath,
      );
    }
    final String inputKey = Uuid().generateV4();
    final String mainUri = request.packageConfig.toPackageUri(request.mainUri)?.toString()
      ?? request.mainUri.toString();
    _server.stdin.writeln('recompile $mainUri $inputKey');
    _logger.printTrace('<- recompile $mainUri $inputKey');
    for (final Uri fileUri in request.invalidatedFiles) {
      String message;
      if (fileUri.scheme == 'package') {
        message = fileUri.toString();
      } else {
        message = request.packageConfig.toPackageUri(fileUri)?.toString()
          ?? fileUri.toString();
      }
      _server.stdin.writeln(message);
      _logger.printTrace(message);
    }
    _server.stdin.writeln(inputKey);
    _logger.printTrace('<- $inputKey');

    return _stdoutHandler.compilerOutput.future;
  }

  final List<_CompilationRequest> _compilationQueue = <_CompilationRequest>[];

  Future<void> _handleCompilationRequest(_CompilationRequest request) async {
    final bool isEmpty = _compilationQueue.isEmpty;
    _compilationQueue.add(request);
    // Only trigger processing if queue was empty - i.e. no other requests
    // are currently being processed. This effectively enforces "one
    // compilation request at a time".
    if (isEmpty) {
      while (_compilationQueue.isNotEmpty) {
        final _CompilationRequest request = _compilationQueue.first;
        await request.run(this);
        _compilationQueue.removeAt(0);
      }
    }
  }

  Future<CompilerOutput> _compile(
    String scriptUri,
    String outputPath,
  ) async {
    final String frontendServer = _artifacts.getArtifactPath(
      Artifact.frontendServerSnapshotForEngineDartSdk
    );
    final List<String> command = <String>[
      _artifacts.getArtifactPath(Artifact.engineDartBinary),
      '--disable-dart-dev',
      frontendServer,
      '--sdk-root',
      sdkRoot,
      '--incremental',
      '--target=$targetModel',
      // TODO(jonahwilliams): remove once this becomes the default behavior
      // in the frontend_server.
      // https://github.com/flutter/flutter/issues/52693
      '--debugger-module-names',
      // TODO(annagrin): remove once this becomes the default behavior
      // in the frontend_server.
      // https://github.com/flutter/flutter/issues/59902
      '--experimental-emit-debug-metadata',
      '-Ddart.developer.causal_async_stacks=${buildMode == BuildMode.debug}',
      for (final Object dartDefine in dartDefines)
        '-D$dartDefine',
      if (outputPath != null) ...<String>[
        '--output-dill',
        outputPath,
      ],
      if (librariesSpec != null) ...<String>[
        '--libraries-spec',
        librariesSpec,
      ],
      if (packagesPath != null) ...<String>[
        '--packages',
        packagesPath,
      ],
      ...buildModeOptions(buildMode),
      if (trackWidgetCreation) '--track-widget-creation',
      if (fileSystemRoots != null)
        for (final String root in fileSystemRoots) ...<String>[
          '--filesystem-root',
          root,
        ],
      if (fileSystemScheme != null) ...<String>[
        '--filesystem-scheme',
        fileSystemScheme,
      ],
      if (initializeFromDill != null) ...<String>[
        '--initialize-from-dill',
        initializeFromDill,
      ],
      if (platformDill != null) ...<String>[
        '--platform',
        platformDill,
      ],
      if (unsafePackageSerialization == true) '--unsafe-package-serialization',
      ...?extraFrontEndOptions,
    ];
    _logger.printTrace(command.join(' '));
    _server = await _processManager.start(command);
    _server.stdout
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen(
        _stdoutHandler.handler,
        onDone: () {
          // when outputFilename future is not completed, but stdout is closed
          // process has died unexpectedly.
          if (!_stdoutHandler.compilerOutput.isCompleted) {
            _stdoutHandler.compilerOutput.complete(null);
            throwToolExit('the Dart compiler exited unexpectedly.');
          }
        });

    _server.stderr
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen(_logger.printError);

    unawaited(_server.exitCode.then((int code) {
      if (code != 0) {
        throwToolExit('the Dart compiler exited unexpectedly.');
      }
    }));

    _server.stdin.writeln('compile $scriptUri');
    _logger.printTrace('<- compile $scriptUri');

    return _stdoutHandler.compilerOutput.future;
  }

  @override
  Future<CompilerOutput> compileExpression(
    String expression,
    List<String> definitions,
    List<String> typeDefinitions,
    String libraryUri,
    String klass,
    bool isStatic,
  ) {
    if (!_controller.hasListener) {
      _controller.stream.listen(_handleCompilationRequest);
    }

    final Completer<CompilerOutput> completer = Completer<CompilerOutput>();
    _controller.add(
        _CompileExpressionRequest(
            completer, expression, definitions, typeDefinitions, libraryUri, klass, isStatic)
    );
    return completer.future;
  }

  Future<CompilerOutput> _compileExpression(_CompileExpressionRequest request) async {
    _stdoutHandler.reset(suppressCompilerMessages: true, expectSources: false);

    // 'compile-expression' should be invoked after compiler has been started,
    // program was compiled.
    if (_server == null) {
      return null;
    }

    final String inputKey = Uuid().generateV4();
    _server.stdin
      ..writeln('compile-expression $inputKey')
      ..writeln(request.expression);
    request.definitions?.forEach(_server.stdin.writeln);
    _server.stdin.writeln(inputKey);
    request.typeDefinitions?.forEach(_server.stdin.writeln);
    _server.stdin
      ..writeln(inputKey)
      ..writeln(request.libraryUri ?? '')
      ..writeln(request.klass ?? '')
      ..writeln(request.isStatic ?? false);

    return _stdoutHandler.compilerOutput.future;
  }

  @override
  Future<CompilerOutput> compileExpressionToJs(
    String libraryUri,
    int line,
    int column,
    Map<String, String> jsModules,
    Map<String, String> jsFrameValues,
    String moduleName,
    String expression,
  ) {
    if (!_controller.hasListener) {
      _controller.stream.listen(_handleCompilationRequest);
    }

    final Completer<CompilerOutput> completer = Completer<CompilerOutput>();
    _controller.add(
        _CompileExpressionToJsRequest(
            completer, libraryUri, line, column, jsModules, jsFrameValues, moduleName, expression)
    );
    return completer.future;
  }

  Future<CompilerOutput> _compileExpressionToJs(_CompileExpressionToJsRequest request) async {
    _stdoutHandler.reset(suppressCompilerMessages: true, expectSources: false);

    // 'compile-expression-to-js' should be invoked after compiler has been started,
    // program was compiled.
    if (_server == null) {
      return null;
    }

    final String inputKey = Uuid().generateV4();
    _server.stdin
      ..writeln('compile-expression-to-js $inputKey')
      ..writeln(request.libraryUri ?? '')
      ..writeln(request.line)
      ..writeln(request.column);
    request.jsModules?.forEach((String k, String v) { _server.stdin.writeln('$k:$v'); });
    _server.stdin.writeln(inputKey);
    request.jsFrameValues?.forEach((String k, String v) { _server.stdin.writeln('$k:$v'); });
    _server.stdin
      ..writeln(inputKey)
      ..writeln(request.moduleName ?? '')
      ..writeln(request.expression ?? '');

    return _stdoutHandler.compilerOutput.future;
  }

  @override
  void accept() {
    if (_compileRequestNeedsConfirmation) {
      _server.stdin.writeln('accept');
      _logger.printTrace('<- accept');
    }
    _compileRequestNeedsConfirmation = false;
  }

  @override
  Future<CompilerOutput> reject() {
    if (!_controller.hasListener) {
      _controller.stream.listen(_handleCompilationRequest);
    }

    final Completer<CompilerOutput> completer = Completer<CompilerOutput>();
    _controller.add(_RejectRequest(completer));
    return completer.future;
  }

  Future<CompilerOutput> _reject() {
    if (!_compileRequestNeedsConfirmation) {
      return Future<CompilerOutput>.value(null);
    }
    _stdoutHandler.reset(expectSources: false);
    _server.stdin.writeln('reject');
    _logger.printTrace('<- reject');
    _compileRequestNeedsConfirmation = false;
    return _stdoutHandler.compilerOutput.future;
  }

  @override
  void reset() {
    _server?.stdin?.writeln('reset');
    _logger.printTrace('<- reset');
  }

  @override
  Future<dynamic> shutdown() async {
    // Server was never successfully created.
    if (_server == null) {
      return 0;
    }
    _logger.printTrace('killing pid ${_server.pid}');
    _server.kill();
    return _server.exitCode;
  }
}
