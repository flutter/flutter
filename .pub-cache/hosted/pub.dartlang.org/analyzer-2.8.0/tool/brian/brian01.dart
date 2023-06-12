// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/summary/link.dart' as graph
    show DependencyWalker, Node;
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:args/args.dart';
import 'package:collection/collection.dart';

Future<void> main(List<String> args) async {
  args = ['/Users/scheglov/Source/Dart/sdk.git/sdk/pkg/analysis_server'];

  var parser = createArgParser();
  var result = parser.parse(args);

  if (validArguments(parser, result)) {
    var rootPath = result.rest[0];
    print('Analyzing root: "$rootPath"');

    var finder = MigrationReadyLibraryFinder();
    await finder.compute(rootPath);
  }
  io.exit(0);
}

/// Create a parser that can be used to parse the command-line arguments.
ArgParser createArgParser() {
  var parser = ArgParser();
  parser.addOption(
    'help',
    abbr: 'h',
    help: 'Print this help message.',
  );
  return parser;
}

/// Print usage information for this tool.
void printUsage(ArgParser parser, {String? error}) {
  if (error != null) {
    print(error);
    print('');
  }
  print('usage: dart ready_libraries.dart [options] packagePath');
  print('');
  print('Compute and print a list of libraries that can be migrated.');
  print('');
  print(parser.usage);
}

/// Return `true` if the command-line arguments (represented by the [result] and
/// parsed by the [parser]) are valid.
bool validArguments(ArgParser parser, ArgResults result) {
  if (result.wasParsed('help')) {
    printUsage(parser);
    return false;
  } else if (result.rest.length != 1) {
    printUsage(parser, error: 'No directory path specified.');
    return false;
  }
  var rootPath = result.rest[0];
  if (!io.Directory(rootPath).existsSync()) {
    printUsage(parser, error: 'The directory "$rootPath" does not exist.');
    return false;
  }
  return true;
}

/// An object used to find libraries that can be migrated.
class MigrationReadyLibraryFinder {
  /// The resource provider used to access the files being analyzed.
  final PhysicalResourceProvider resourceProvider =
      PhysicalResourceProvider.INSTANCE;

  /// Initialize a newly created library finder.
  MigrationReadyLibraryFinder();

  Future<void> compute(String rootPath) async {
    final collection = AnalysisContextCollection(
      includedPaths: [rootPath],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    for (var context in collection.contexts) {
      await _findInContext(context.contextRoot);
    }
  }

  Future<void> _findInContext(ContextRoot root) async {
    // Create a new collection to avoid consuming large quantities of memory.
    final collection = AnalysisContextCollection(
      includedPaths: root.includedPaths.toList(),
      excludedPaths: root.excludedPaths.toList(),
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    var context = collection.contexts[0];
    var session = context.currentSession;
    var pathContext = context.contextRoot.resourceProvider.pathContext;
    var walker = _MigrationWalker();
    var totalFiles = 0;
    for (var filePath in context.contextRoot.analyzedFiles()) {
      if (file_paths.isDart(pathContext, filePath)) {
        totalFiles++;
        var uri = session.uriConverter.pathToUri(filePath)!;
        var libraryResult = await session.getLibraryByUri('$uri');
        if (libraryResult is LibraryElementResult) {
          var libraryNode = walker.getNode(libraryResult.element);
          if (!libraryNode.isEvaluated) {
            walker.walk(libraryNode);
          }
        }
      }
    }
    print('Total files: $totalFiles');
  }
}

class _MigrationNode extends graph.Node<_MigrationNode> {
  final _MigrationWalker walker;
  final LibraryElement element;
  late bool isMigrated;

  Set<_MigrationNode>? transitiveLibraries;

  _MigrationNode(this.walker, this.element);

  @override
  bool get isEvaluated => transitiveLibraries != null;

  @override
  List<_MigrationNode> computeDependencies() {
    return element.imports
        .map((e) => e.importedLibrary)
        .whereNotNull()
        .map((e) => walker.getNode(e))
        .toList();
  }

  @override
  String toString() {
    return element.source.fullName;
  }
}

class _MigrationWalker extends graph.DependencyWalker<_MigrationNode> {
  final Map<LibraryElement, _MigrationNode> _nodes = {};

  @override
  void evaluate(_MigrationNode node) {
    evaluateScc([node]);
  }

  @override
  void evaluateScc(List<_MigrationNode> scc) {
    var isMigrated = scc.every((node) => node.element.isNonNullableByDefault);
    for (var node in scc) {
      node.isMigrated = isMigrated;
    }

    var dependenciesToMigrate = _transitiveDependencies(scc);
    for (var node in scc) {
      if (isMigrated) {
        node.transitiveLibraries = {};
      } else {
        node.transitiveLibraries = {...dependenciesToMigrate, ...scc};
      }
    }

    if (!isMigrated) {
      print(
        '[depends: ${dependenciesToMigrate.length}]'
        '[contains: ${scc.length}]'
        '[${scc.map((e) => e.element.source.fullName).toList()}]',
      );
    }
  }

  _MigrationNode getNode(LibraryElement element) {
    return _nodes.putIfAbsent(element, () => _MigrationNode(this, element));
  }

  void walkNodes() {
    for (var node in _nodes.values) {
      if (!node.isEvaluated) {
        walk(node);
      }
    }
  }

  Set<_MigrationNode> _transitiveDependencies(List<_MigrationNode> nodes) {
    var result = <_MigrationNode>{};
    for (var node in nodes) {
      for (var dependency in graph.Node.getDependencies(node)) {
        if (!nodes.contains(dependency)) {
          result.addAll(dependency.transitiveLibraries!);
        }
      }
    }
    return result;
  }
}
