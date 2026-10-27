// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';

import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/logger.dart';

/// A service for creating and parsing [Depfile]s.
class DepfileService {
  DepfileService({required this._logger, required this._fileSystem});

  final Logger _logger;
  final FileSystem _fileSystem;

  /// Given an [depfile] File, write the depfile contents.
  ///
  /// If both [depfile] and [Depfile.outputs] are empty,
  /// ensures the file does not exist.
  /// This can be overridden with the [writeEmpty] parameter when
  /// both static and runtime dependencies exist and it is not desired
  /// to force a rerun due to no depfile.
  ///
  /// If [filterOutputs] is true, files that are listed as both inputs and
  /// outputs in the depfile are filtered out from the outputs list before
  /// writing to avoid circular dependency cycles in external systems like Xcode.
  void writeToFile(
    Depfile depfile,
    File output, {
    bool writeEmpty = false,
    bool filterOutputs = false,
  }) {
    if (depfile.inputs.isEmpty && depfile.outputs.isEmpty && !writeEmpty) {
      ErrorHandlingFileSystem.deleteIfExists(output);
      return;
    }
    final List<File> outputsToWrite;
    if (filterOutputs) {
      final Set<String> inputPaths = depfile.inputs.map((File f) => f.absolute.path).toSet();
      outputsToWrite = depfile.outputs
          .where((File file) => !inputPaths.contains(file.absolute.path))
          .toList();
    } else {
      outputsToWrite = depfile.outputs;
    }
    final extensionDepfile = ExtensionDepfile(
      inputs: <String>[
        for (final File file in depfile.inputs) _fileSystem.path.normalize(file.path),
      ],
      outputs: <String>[
        for (final File file in outputsToWrite) _fileSystem.path.normalize(file.path),
      ],
    );
    output.writeAsStringSync(
      extensionDepfile.format(windows: _fileSystem.path.style.separator == r'\'),
    );
  }

  /// Parse the depfile contents from [file].
  ///
  /// If the syntax is invalid, returns an empty [Depfile].
  ///
  /// If [baseDirectory] is provided, any relative paths in the depfile
  /// will be resolved relative to it.
  Depfile parse(File file, [Directory? baseDirectory]) {
    final String contents = file.readAsStringSync();
    final ExtensionDepfile parsed;
    try {
      parsed = ExtensionDepfile.parse(contents);
    } on FormatException {
      _logger.printError('Invalid depfile: ${file.path}');
      return const Depfile(<File>[], <File>[]);
    }
    final List<File> inputs = _resolvePaths(parsed.inputs, baseDirectory);
    final List<File> outputs = _resolvePaths(parsed.outputs, baseDirectory);
    return Depfile(inputs, outputs);
  }

  /// Parse the output of dart2js's used dependencies.
  ///
  /// The [file] contains a list of newline separated file URIs. The output
  /// file must be manually specified.
  Depfile parseDart2js(File file, File output) {
    final inputs = <File>[
      for (final String rawUri in file.readAsLinesSync())
        if (rawUri.trim().isNotEmpty)
          if (Uri.tryParse(rawUri) case final Uri fileUri when fileUri.scheme == 'file')
            _fileSystem.file(fileUri),
    ];
    return Depfile(inputs, <File>[output]);
  }

  List<File> _resolvePaths(List<String> paths, [Directory? baseDirectory]) {
    final isWindows = _fileSystem.path.style.separator == r'\';
    return paths.map((String path) {
      if (isWindows && path.length >= 5 && path.substring(0, 5).toLowerCase() == r'\unc\') {
        path = r'\\' + path.substring(5);
      }
      if (baseDirectory != null && _fileSystem.path.isRelative(path)) {
        return _fileSystem.file(
          _fileSystem.path.normalize(_fileSystem.path.join(baseDirectory.path, path)),
        );
      }
      return _fileSystem.file(_fileSystem.path.normalize(path));
    }).toList();
  }
}

/// A class for representing depfile formats.
class Depfile {
  /// Create a [Depfile] from a list of [inputs] and [outputs].
  const Depfile(this.inputs, this.outputs);

  /// The input files for this depfile.
  final List<File> inputs;

  /// The output files for this depfile.
  final List<File> outputs;
}
