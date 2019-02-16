// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Note: this Builder does not run in the same process as the flutter_tool, so
// the DI provided getters such as `fs` will not work.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build_modules/build_modules.dart';
import 'package:build/build.dart';
import 'package:package_config/packages_file.dart' as packages_file;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

const String _kFlutterDillOutputExtension = '.app.dill';
const String _kPackagesExtension = '.packages';

/// A builder which creates a kernel and packages file for a Flutter app.
///
/// Unlike the package:build kernel builders, this creates a single kernel from
/// dart source using the frontend server binary. The newly created .package
/// file replaces the relative root of the current package with a multi-root
/// which includes the generated directory.
class FlutterKernelBuilder implements Builder {
  const FlutterKernelBuilder({
    @required this.disabled,
    @required this.mainPath,
    @required this.aot,
    @required this.trackWidgetCreation,
    @required this.targetProductVm,
    @required this.linkPlatformKernelIn,
    @required this.extraFrontEndOptions,
    @required this.sdkRoot,
    @required this.packagesPath,
    @required this.incrementalCompilerByteStorePath,
    @required this.frontendServerPath,
    @required this.engineDartBinaryPath,
  });

  /// The path to the entrypoint that will be compiled.
  final String mainPath;

  /// The path to the pub generated .packages file.
  final String packagesPath;

  /// The path to the root of the flutter patched SDK.
  final String sdkRoot;

  /// The path to the frontend server snapshot.
  final String frontendServerPath;

  /// The path to the dart executable to use to run the frontend server
  /// snapshot.
  final String engineDartBinaryPath;

  /// Whether to build an ahead of time build.
  final bool aot;

  /// Whether to disable production of kernel.
  final bool disabled;

  /// Whether the `trackWidgetCreation` flag is provided to the frontend
  /// server.
  final bool trackWidgetCreation;

  /// Whether to provide the Dart product define to the frontend server.
  final bool targetProductVm;

  /// When in batch mode, link platform kernel file into result kernel file.
  final bool linkPlatformKernelIn;

  /// Whether to compile incrementally.
  final String incrementalCompilerByteStorePath;

  /// Additional arguments to pass to the frontend server.
  final List<String> extraFrontEndOptions;

  @override
  Map<String, List<String>> get buildExtensions => const <String, List<String>>{
    '.dart': <String>[_kFlutterDillOutputExtension, _kPackagesExtension],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // Do not resolve dependencies if this does not correspond to the main
    // entrypoint.
    if (!mainPath.contains(buildStep.inputId.path)) {
      return;
    }
    final AssetId outputId = buildStep.inputId.changeExtension(_kFlutterDillOutputExtension);
    final AssetId packagesOutputId = buildStep.inputId.changeExtension(_kPackagesExtension);

    // Use modules to verify dependencies are sound.
    final AssetId moduleId = buildStep.inputId.changeExtension(moduleExtension(DartPlatform.flutter));
    final Module module = Module.fromJson(json.decode(await buildStep.readAsString(moduleId)));
    try {
      await module.computeTransitiveDependencies(buildStep);
    } on MissingModulesException catch (err) {
      log.shout(err);
      return;
    }

    // Do not generate kernel if it has been disabled.
    if (disabled) {
      return;
    }

    // Create a scratch space file that can be read/written by the frontend server.
    // It is okay to hard-code these file names because we will copy them back
    // from the temp directory at the end of the build step.
    final Directory tempDirecory = await Directory.systemTemp.createTemp('_flutter_build');
    final File packagesFile = File(path.join(tempDirecory.path, _kPackagesExtension));
    final File outputFile =  File(path.join(tempDirecory.path, 'main.app.dill'));
    await outputFile.create();
    await packagesFile.create();

    final Directory projectDir = File(packagesPath).parent;
    final String packageName = buildStep.inputId.package;
    final String oldPackagesContents = await File(packagesPath).readAsString();
    // Note: currently we only replace the root package with a multiroot
    // scheme. To support codegen on arbitrary packages we will need to do
    // this for each dependency.
    final String newPackagesContents = oldPackagesContents.replaceFirst('$packageName:lib/', '$packageName:$multiRootScheme:/');
    await packagesFile.writeAsString(newPackagesContents);
    String absoluteMainPath;
    if (path.isAbsolute(mainPath)) {
      absoluteMainPath = mainPath;
    } else {
      absoluteMainPath = path.join(projectDir.absolute.path, mainPath);
    }

    // start up the frontend server with configuration.
    final List<String> arguments = <String>[
      frontendServerPath,
      '--sdk-root',
      sdkRoot,
      '--strong',
      '--target=flutter',
    ];
    if (trackWidgetCreation) {
      arguments.add('--track-widget-creation');
    }
    if (!linkPlatformKernelIn) {
      arguments.add('--no-link-platform');
    }
    if (aot) {
      arguments.add('--aot');
      arguments.add('--tfa');
    }
    if (targetProductVm) {
      arguments.add('-Ddart.vm.product=true');
    }
    if (incrementalCompilerByteStorePath != null) {
      arguments.add('--incremental');
    }
    final String generatedRoot = path.join(projectDir.absolute.path, '.dart_tool', 'build', 'generated', '$packageName', 'lib${Platform.pathSeparator}');
    final String normalRoot =  path.join(projectDir.absolute.path, 'lib${Platform.pathSeparator}');
    arguments.addAll(<String>[
      '--packages',
      Uri.file(packagesFile.path).toString(),
      '--output-dill',
      outputFile.path,
      '--filesystem-root',
      normalRoot,
      '--filesystem-root',
      generatedRoot,
      '--filesystem-scheme',
      multiRootScheme,
    ]);
    if (extraFrontEndOptions != null) {
      arguments.addAll(extraFrontEndOptions);
    }
    final Uri mainUri = _PackageUriMapper.findUri(
      absoluteMainPath,
      packagesFile.path,
      multiRootScheme,
      <String>[normalRoot, generatedRoot],
    );
    arguments.add(mainUri?.toString() ?? absoluteMainPath);
    // Invoke the frontend server and copy the dill back to the output
    // directory.
    try {
      final Process server = await Process.start(engineDartBinaryPath, arguments);
      final _StdoutHandler _stdoutHandler = _StdoutHandler();
      server.stderr
        .transform<String>(utf8.decoder)
        .listen(log.shout);
      server.stdout
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen(_stdoutHandler.handler);
      await server.exitCode;
      await _stdoutHandler.compilerOutput.future;
      await buildStep.writeAsBytes(outputId, await outputFile.readAsBytes());
      await buildStep.writeAsBytes(packagesOutputId, await packagesFile.readAsBytes());
    } catch (err, stackTrace) {
      log.shout('frontend server failed to start: $err, $stackTrace');
    }
  }
}

class _StdoutHandler {
  _StdoutHandler() {
    reset();
  }

  bool compilerMessageReceived = false;
  String boundaryKey;
  Completer<_CompilerOutput> compilerOutput;

  bool _suppressCompilerMessages;

  void handler(String message) {
    const String kResultPrefix = 'result ';
    if (boundaryKey == null) {
      if (message.startsWith(kResultPrefix))
        boundaryKey = message.substring(kResultPrefix.length);
    } else if (message.startsWith(boundaryKey)) {
      if (message.length <= boundaryKey.length) {
        compilerOutput.complete(null);
        return;
      }
      final int spaceDelimiter = message.lastIndexOf(' ');
      compilerOutput.complete(
        _CompilerOutput(
          message.substring(boundaryKey.length + 1, spaceDelimiter),
          int.parse(message.substring(spaceDelimiter + 1).trim())));
    } else if (!_suppressCompilerMessages) {
      if (compilerMessageReceived == false) {
        log.info('\nCompiler message:');
        compilerMessageReceived = true;
      }
      log.info(message);
    }
  }

  // This is needed to get ready to process next compilation result output,
  // with its own boundary key and new completer.
  void reset({bool suppressCompilerMessages = false}) {
    boundaryKey = null;
    compilerMessageReceived = false;
    compilerOutput = Completer<_CompilerOutput>();
    _suppressCompilerMessages = suppressCompilerMessages;
  }
}


class _CompilerOutput {
  const _CompilerOutput(this.outputFilename, this.errorCount);

  final String outputFilename;
  final int errorCount;
}

/// Converts filesystem paths to package URIs.
class _PackageUriMapper {
  _PackageUriMapper(String scriptPath, String packagesPath, String fileSystemScheme, List<String> fileSystemRoots) {
    final List<int> bytes = File(path.absolute(packagesPath)).readAsBytesSync();
    final Map<String, Uri> packageMap = packages_file.parse(bytes, Uri.file(packagesPath, windows: Platform.isWindows));
    final String scriptUri = Uri.file(scriptPath, windows: Platform.isWindows).toString();

    for (String packageName in packageMap.keys) {
      final String prefix = packageMap[packageName].toString();
      if (fileSystemScheme != null && fileSystemRoots != null && prefix.contains(fileSystemScheme)) {
        _packageName = packageName;
        _uriPrefixes = fileSystemRoots
          .map((String name) => Uri.file(name, windows: Platform.isWindows).toString())
          .toList();
        return;
      }
      if (scriptUri.startsWith(prefix)) {
        _packageName = packageName;
        _uriPrefixes = <String>[prefix];
        return;
      }
    }
  }

  String _packageName;
  List<String> _uriPrefixes;

  Uri map(String scriptPath) {
    if (_packageName == null) {
      return null;
    }
    final String scriptUri = Uri.file(scriptPath, windows: Platform.isWindows).toString();
    for (String uriPrefix in _uriPrefixes) {
      if (scriptUri.startsWith(uriPrefix)) {
        return Uri.parse('package:$_packageName/${scriptUri.substring(uriPrefix.length)}');
      }
    }
    return null;
  }

  static Uri findUri(String scriptPath, String packagesPath, String fileSystemScheme, List<String> fileSystemRoots) {
    return _PackageUriMapper(scriptPath, packagesPath, fileSystemScheme, fileSystemRoots).map(scriptPath);
  }
}
