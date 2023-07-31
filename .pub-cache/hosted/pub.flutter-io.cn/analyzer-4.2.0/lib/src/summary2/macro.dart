// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/macros/bootstrap.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/isolated_executor.dart'
    as isolated_executor;
import 'package:_fe_analyzer_shared/src/macros/executor/multi_executor.dart'
    as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/serialization.dart'
    as macro;
import 'package:analyzer/src/summary2/kernel_compilation_service.dart';
import 'package:path/path.dart' as package_path;

class BundleMacroExecutor {
  final macro.MultiMacroExecutor macroExecutor;
  late final macro.ExecutorFactoryToken _executorFactoryToken;
  final Uint8List kernelBytes;
  Uri? _kernelUriCached;

  BundleMacroExecutor({
    required this.macroExecutor,
    required Uint8List kernelBytes,
    required Set<Uri> libraries,
  }) : kernelBytes = Uint8List.fromList(kernelBytes) {
    _executorFactoryToken = macroExecutor.registerExecutorFactory(
      () => isolated_executor.start(
        macro.SerializationMode.byteDataServer,
        _kernelUri,
      ),
      libraries,
    );
  }

  Uri get _kernelUri {
    return _kernelUriCached ??=
        // ignore: avoid_dynamic_calls
        (Isolate.current as dynamic).createUriForKernelBlob(kernelBytes);
  }

  void dispose() {
    macroExecutor.unregisterExecutorFactory(_executorFactoryToken);
    final kernelUriCached = _kernelUriCached;
    if (kernelUriCached != null) {
      // ignore: avoid_dynamic_calls
      (Isolate.current as dynamic).unregisterKernelBlobUri(kernelUriCached);
      _kernelUriCached = null;
    }
  }

  /// Any macro must be instantiated using this method to guarantee that
  /// the corresponding kernel was registered first. Although as it is now,
  /// it is still possible to request an unrelated [libraryUri].
  Future<macro.MacroInstanceIdentifier> instantiate({
    required Uri libraryUri,
    required String className,
    required String constructorName,
    required macro.Arguments arguments,
  }) async {
    return await macroExecutor.instantiateMacro(
        libraryUri, className, constructorName, arguments);
  }
}

class MacroClass {
  final String name;
  final List<String> constructors;

  MacroClass({
    required this.name,
    required this.constructors,
  });
}

abstract class MacroFileEntry {
  String get content;

  /// When CFE searches for `package_config.json` we need to check this.
  bool get exists;
}

abstract class MacroFileSystem {
  /// Used to convert `file:` URIs into paths.
  package_path.Context get pathContext;

  MacroFileEntry getFile(String path);
}

class MacroKernelBuilder {
  const MacroKernelBuilder();

  Future<Uint8List> build({
    required MacroFileSystem fileSystem,
    required List<MacroLibrary> libraries,
  }) async {
    final macroMainContent = macro.bootstrapMacroIsolate(
      {
        for (final library in libraries)
          library.uri.toString(): {
            for (final c in library.classes) c.name: c.constructors
          },
      },
      macro.SerializationMode.byteDataClient,
    );

    final macroMainPath = '${libraries.first.path}.macro';
    final overlayFileSystem = _OverlayMacroFileSystem(fileSystem);
    overlayFileSystem.overlays[macroMainPath] = macroMainContent;

    return KernelCompilationService.compile(
      fileSystem: overlayFileSystem,
      path: macroMainPath,
    );
  }
}

class MacroLibrary {
  final Uri uri;
  final String path;
  final List<MacroClass> classes;

  MacroLibrary({
    required this.uri,
    required this.path,
    required this.classes,
  });

  String get uriStr => uri.toString();
}

/// [MacroFileEntry] for a file with overridden content.
class _OverlayMacroFileEntry implements MacroFileEntry {
  @override
  final String content;

  _OverlayMacroFileEntry(this.content);

  @override
  bool get exists => true;
}

/// Wrapper around another [MacroFileSystem] that can be configured to
/// provide (or override) content of files.
class _OverlayMacroFileSystem implements MacroFileSystem {
  final MacroFileSystem _fileSystem;

  /// The mapping from the path to the file content.
  final Map<String, String> overlays = {};

  _OverlayMacroFileSystem(this._fileSystem);

  @override
  package_path.Context get pathContext => _fileSystem.pathContext;

  @override
  MacroFileEntry getFile(String path) {
    final overlayContent = overlays[path];
    if (overlayContent != null) {
      return _OverlayMacroFileEntry(overlayContent);
    }
    return _fileSystem.getFile(path);
  }
}
