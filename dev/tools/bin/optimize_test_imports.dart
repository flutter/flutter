import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

const List<String> targetBarrels = <String>[
  'package:flutter/widgets.dart',
  'package:flutter/material.dart',
  'package:flutter/rendering.dart',
  'package:flutter/painting.dart',
  'package:flutter/services.dart',
  'package:flutter/gestures.dart',
  'package:flutter/foundation.dart',
  'package:flutter/animation.dart',
  'package:flutter/scheduler.dart',
  'package:flutter/physics.dart',
  'package:flutter/semantics.dart',
  'package:flutter/cupertino.dart',
  'package:flutter_test/flutter_test.dart',
];

void main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Print this usage information.')
    ..addFlag(
      'dry-run',
      abbr: 'd',
      negatable: false,
      help: 'Check if any test files need optimization and exit with a non-zero code if they do.',
    );

  final ArgResults results;
  try {
    results = parser.parse(args);
  } on FormatException catch (e) {
    print('Error: ${e.message}');
    print(parser.usage);
    exit(1);
  }

  if (results['help'] as bool || results.rest.isEmpty) {
    print('Usage: dart optimize_test_imports.dart [options] <path-to-test-file-or-directory>');
    print(parser.usage);
    return;
  }

  final dryRun = results['dry-run'] as bool;
  final List<String> pathsToScan = results.rest;

  final String? repoRoot = _findRepoRoot();
  if (repoRoot == null) {
    print('Error: Could not locate the root of the Flutter repository.');
    exit(1);
  }

  final String flutterPackagePath = p.join(repoRoot, 'packages/flutter');
  final filesToProcess = <String>[];

  for (final path in pathsToScan) {
    final FileSystemEntityType entityType = FileSystemEntity.typeSync(path);
    if (entityType == FileSystemEntityType.file) {
      if (path.endsWith('_test.dart')) {
        filesToProcess.add(p.absolute(path));
      }
    } else if (entityType == FileSystemEntityType.directory) {
      final dir = Directory(path);
      final List<FileSystemEntity> list = dir.listSync(recursive: true);
      for (final entity in list) {
        if (entity is File && entity.path.endsWith('_test.dart')) {
          filesToProcess.add(p.absolute(entity.path));
        }
      }
    }
  }

  if (filesToProcess.isEmpty) {
    print('No test files found to process.');
    return;
  }

  print('Found ${filesToProcess.length} test files to check.');
  print('Initializing AnalysisContextCollection (this may take a few seconds)...');
  final collection = AnalysisContextCollection(
    includedPaths: <String>[flutterPackagePath],
    resourceProvider: PhysicalResourceProvider.INSTANCE,
  );

  final String flutterLibPath = p.join(flutterPackagePath, 'lib/');
  final String flutterTestLibPath = p.join(repoRoot, 'packages/flutter_test/lib/');

  var successCount = 0;
  var skipCount = 0;
  var needOptimizationCount = 0;

  for (var i = 0; i < filesToProcess.length; i++) {
    final String testFilePath = filesToProcess[i];
    final String relativePath = p.relative(testFilePath, from: flutterPackagePath);

    try {
      final AnalysisContext context = collection.contextFor(testFilePath);
      final SomeResolvedUnitResult unitResult = await context.currentSession.getResolvedUnit(
        testFilePath,
      );

      if (unitResult is! ResolvedUnitResult) {
        skipCount++;
        continue;
      }

      final visitor = ElementVisitor();
      unitResult.unit.accept(visitor);

      final optimizedFlutterImports = <String>{};
      final optimizedFlutterTestImports = <String>{};

      for (final String dep in visitor.dependencies) {
        if (dep.startsWith(flutterLibPath)) {
          final String relative = dep.substring(flutterLibPath.length);
          if (relative.startsWith('src/')) {
            optimizedFlutterImports.add("import 'package:flutter/$relative';");
          }
        } else if (dep.startsWith(flutterTestLibPath)) {
          final String relative = dep.substring(flutterTestLibPath.length);
          if (relative.startsWith('src/')) {
            optimizedFlutterTestImports.add("import 'package:flutter_test/$relative';");
          }
        }
      }

      // Find all barrel imports in the original AST
      final barrelDirectives = <ImportDirective>[];
      for (final Directive directive in unitResult.unit.directives) {
        if (directive is ImportDirective) {
          final String? uri = directive.uri.stringValue;
          if (uri != null && targetBarrels.contains(uri)) {
            barrelDirectives.add(directive);
          }
        }
      }

      if (barrelDirectives.isEmpty) {
        skipCount++;
        continue;
      }

      needOptimizationCount++;
      print(
        '[${i + 1}/${filesToProcess.length}] ${dryRun ? "Requires optimization" : "Optimizing"}: $relativePath',
      );

      if (dryRun) {
        continue;
      }

      // Sort optimized imports
      final List<String> sortedFlutterImports = optimizedFlutterImports.toList()..sort();
      final List<String> sortedFlutterTestImports = optimizedFlutterTestImports.toList()..sort();

      final String newImportsBlock = <String>[
        ...sortedFlutterImports,
        if (sortedFlutterImports.isNotEmpty && sortedFlutterTestImports.isNotEmpty) '',
        ...sortedFlutterTestImports,
      ].join('\n');

      final file = File(testFilePath);
      final String originalContent = file.readAsStringSync();
      var rewrittenContent = originalContent;

      // Sort barrel directives in descending order of offset
      barrelDirectives.sort((ImportDirective a, ImportDirective b) => b.offset.compareTo(a.offset));

      final ImportDirective firstBarrel = barrelDirectives.last; // The one with the smallest offset

      for (final directive in barrelDirectives) {
        if (directive == firstBarrel) {
          rewrittenContent = rewrittenContent.replaceRange(
            directive.offset,
            directive.end,
            newImportsBlock,
          );
        } else {
          rewrittenContent = rewrittenContent.replaceRange(directive.offset, directive.end, '');
        }
      }

      file.writeAsStringSync(rewrittenContent);
      successCount++;
    } catch (e) {
      print('  Error processing $relativePath: $e');
      skipCount++;
    }
  }

  print('\n=== Optimization Summary ===');
  print('Total Files Checked: ${filesToProcess.length}');
  if (dryRun) {
    print('Files Needing Optimization: $needOptimizationCount');
    print('Files Already Optimized: $skipCount');
    if (needOptimizationCount > 0) {
      print('\nDry-run failed: Some test files import public barrel libraries.');
      exit(1);
    } else {
      print('\nDry-run succeeded: All files are optimized!');
    }
  } else {
    print('Successfully Optimized: $successCount');
    print('Already Optimized/Skipped: $skipCount');
  }
}

String? _findRepoRoot() {
  Directory dir = Directory.current;
  while (true) {
    if (File(p.join(dir.path, 'bin/flutter')).existsSync()) {
      return dir.path;
    }
    final Directory parent = dir.parent;
    if (parent.path == dir.path) {
      return null;
    }
    dir = parent;
  }
}

class ElementVisitor extends RecursiveAstVisitor<void> {
  final Set<String> dependencies = <String>{};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    super.visitSimpleIdentifier(node);
    _addDeclarationSource(node.element);
  }

  @override
  void visitNamedType(NamedType node) {
    super.visitNamedType(node);
    _addDeclarationSource(node.element);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    super.visitConstructorName(node);
    _addDeclarationSource(node.element);
  }

  void _addDeclarationSource(Element? element) {
    if (element == null) {
      return;
    }

    final LibraryElement? library = element.library;
    if (library != null) {
      final LibraryFragment libSource = library.firstFragment;
      final String path = libSource.source.fullName;
      if (path.endsWith('.dart') && !path.contains('/test/')) {
        dependencies.add(path);
      }
    }
  }
}
