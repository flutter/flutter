// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:file/file.dart';
import 'package:path/path.dart' as path;

/// A typedef that contains a set of [File]s which import Cupertino,
/// and a set of [File]s which import Material.
typedef CrossImportingFiles = ({Set<File> cupertinoImports, Set<File> materialImports});

/// A library that is checked for cross imports.
abstract interface class CrossImportCheckedLibrary {
  /// Get the error message that is used to assert in [getImportError],
  /// that an import error is expected.
  ///
  /// This error message should describe why an import is not allowed.
  ///
  /// For example: "Only Material is allowed to import Material"
  String get cannotImportMessage;

  /// Get the list of known cross imports for this [CrossImportCheckedLibrary].
  Set<String> get knownCrossImports;

  /// The short name of the library.
  ///
  /// For example `packages/flutter/test/widgets` or `examples/api/foo`.
  String get libraryName;

  /// The message that instructs how to remove now-fixed cross imports for this library,
  /// in the relevant cross imports checker.
  ///
  /// For example:
  /// "However, they now need to be removed from the\n cross imports list in the script /dev/bots/check_tests_cross_imports.dart."
  String get removeCrossImportsInstructionMessage;

  /// Returns whether this library may contain the given [import].
  bool canImport(LibraryCrossImportStatementType import);

  /// Get an error message that describes that [filesCount] files
  /// have a disallowed import of [importedLibraryName].
  ///
  /// This message is used as preamble when listing the import errors emitted by a cross imports checker.
  ///
  /// For example:
  /// "The following $filesCount files have a disallowed import of $importedLibraryName. Refactor them or move them to $importedLibraryName."
  String getDisallowedImportMessage(String importedLibraryName, int filesCount);
}

/// An enum that defines the possible cross import statements for libraries,
/// which are of special interest for a cross imports checker.
enum LibraryCrossImportStatementType {
  /// A cross import of the Material library.
  material('Material', "import 'package:flutter/material.dart'"),

  /// A cross import of the Cupertino library.
  cupertino('Cupertino', "import 'package:flutter/cupertino.dart'");

  const LibraryCrossImportStatementType(this.readableName, this.importString);

  /// The readable name for the library that is being cross imported.
  ///
  /// For example `Material` or `Cupertino`.
  final String readableName;

  /// The import statement string for a cross import of this type.
  ///
  /// This string is a valid Dart import statement,
  /// for example `import 'package:flutter/material.dart'`.
  ///
  /// This import statement does not include a trailing semicolon,
  /// as there may be a `show` keyword following the import statement in the affected library.
  final String importString;
}

/// Returns the [Set] of paths in [knownPaths] that are not in [files].
///
/// Each file is expected to have a path that includes [prefix].
Set<String> differencePaths(Set<String> knownPaths, Set<File> files, {required Pattern prefix}) {
  final Set<String> testPaths = files.map((File file) {
    final int index = file.absolute.path.indexOf(prefix);
    if (index < 0) {
      throw ArgumentError('All files must include $prefix in their path.', 'files');
    }

    return file.absolute.path.substring(index).replaceAll(Platform.pathSeparator, '/');
  }).toSet();

  return knownPaths.difference(testPaths);
}

/// Get the [Map] of files, per [CrossImportCheckedLibrary],
/// of the files that have cross imports on Material and Cupertino.
Map<CrossImportCheckedLibrary, CrossImportingFiles> getCrossImports(
  Map<CrossImportCheckedLibrary, Set<File>> libraries,
) {
  final Map<CrossImportCheckedLibrary, CrossImportingFiles> crossImports = {};

  for (final MapEntry<CrossImportCheckedLibrary, Set<File>> entry in libraries.entries) {
    final Set<File> cupertinoImports = {};
    final Set<File> materialImports = {};

    for (final File file in entry.value) {
      final String contents = file.readAsStringSync();

      for (final LibraryCrossImportStatementType importStatement
          in LibraryCrossImportStatementType.values) {
        switch (importStatement) {
          case .cupertino:
            if (!entry.key.canImport(importStatement) &&
                contents.contains(importStatement.importString)) {
              cupertinoImports.add(file);
            }
          case .material:
            if (!entry.key.canImport(importStatement) &&
                contents.contains(importStatement.importString)) {
              materialImports.add(file);
            }
        }
      }
    }

    crossImports[entry.key] = (
      cupertinoImports: cupertinoImports,
      materialImports: materialImports,
    );
  }

  return crossImports;
}

/// Returns the error message for the given [fixedPaths]
/// that no longer have a cross import.
///
/// The [library] must not be the Material library,
/// because Material is allowed to cross-import.
String getFixedImportError(Set<String> fixedPaths, CrossImportCheckedLibrary library) {
  assert(fixedPaths.isNotEmpty);
  final buffer = StringBuffer(
    'Huzzah! The following files in ${library.libraryName} no longer contain cross imports!\n',
  );
  for (final path in fixedPaths) {
    buffer.writeln('  $path');
  }
  buffer.write(library.removeCrossImportsInstructionMessage);

  return buffer.toString().trimRight();
}

/// Returns the import error for the [files] in [checkedLibrary] which contain the given [importStatement].
String getImportError({
  required Set<File> files,
  required Directory flutterRoot,
  required CrossImportCheckedLibrary checkedLibrary,
  required LibraryCrossImportStatementType importStatement,
}) {
  assert(!checkedLibrary.canImport(importStatement), checkedLibrary.cannotImportMessage);

  final String importedLibraryName = importStatement.readableName;
  final buffer = StringBuffer(
    checkedLibrary.getDisallowedImportMessage(importedLibraryName, files.length),
  );
  for (final file in files) {
    buffer.writeln(
      '  ${getRelativePath(file, flutterRoot: flutterRoot).replaceAll(Platform.pathSeparator, '/')}',
    );
  }
  return buffer.toString().trimRight();
}

/// Returns the [file]'s relative path, relative to [flutterRoot].
String getRelativePath(File file, {required Directory flutterRoot}) {
  return path.relative(file.absolute.path, from: flutterRoot.absolute.path);
}

/// Returns the [Set] of files that are not in [knownPaths].
///
/// Each file is expected to have a path that includes [prefix].
Set<File> getUnknowns(Set<String> knownPaths, Set<File> files, {required Pattern prefix}) {
  return files.where((File file) {
    final int index = file.absolute.path.indexOf(prefix);

    if (index < 0) {
      throw ArgumentError('All files must include $prefix in their path.', 'files');
    }

    final String comparablePath = file.absolute.path
        .substring(index)
        .replaceAll(Platform.pathSeparator, '/');

    return !knownPaths.contains(comparablePath);
  }).toSet();
}
