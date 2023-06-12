// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/context_builder.dart';
import 'package:analyzer/dart/analysis/context_locator.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:graphs/graphs.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late _ImportCheck importCheck;
  setUpAll(() async {
    importCheck = await _ImportCheck.create();
  });
  group('backend', () {
    test('must not import from other subdirectories', () async {
      final entryPoints = [
        _testApiLibrary('backend.dart'),
        ...(await _ImportCheck.findEntrypointsUnder(
            _testApiLibrary('src/backend')))
      ];
      await for (final source
          in importCheck.transitiveSamePackageSources(entryPoints)) {
        for (final import in source.imports) {
          expect(import.pathSegments.skip(1).take(2), ['src', 'backend'],
              reason: 'Invalid import from ${source.uri} : $import');
        }
      }
    });
  });

  group('expect', () {
    test('must not be imported from any other library', () async {
      final entryPoints = [
        _testApiLibrary('hooks.dart'),
        _testApiLibrary('scaffolding.dart'),
        _testApiLibrary('fake.dart')
      ];
      await for (final source
          in importCheck.transitiveSamePackageSources(entryPoints)) {
        for (final import in source.imports) {
          expect(import.path, isNot(contains('test_api.dart')),
              reason: 'Invalid import from ${source.uri} : $import.');
          expect(import.path, isNot(contains('expect')),
              reason: 'Invalid import from ${source.uri} : $import.');
        }
      }
    });

    test('may only import hooks', () async {
      final entryPoint = _testApiLibrary('expect.dart');
      await for (final source
          in importCheck.transitiveSamePackageSources([entryPoint])) {
        // Transitive imports through `hooks.dart` don't follow this restriction
        if (!source.uri.path.contains('expect')) continue;
        for (final import in source.imports) {
          expect(import.path,
              anyOf(['test_api/hooks.dart', startsWith('test_api/src/expect')]),
              reason: 'Invalid import from ${source.uri} : $import');
        }
      }
    });
  });
}

Uri _testApiLibrary(String path) => Uri.parse('package:test_api/$path');

class _ImportCheck {
  final AnalysisContext _context;

  static Future<Iterable<Uri>> findEntrypointsUnder(Uri uri) async {
    if (!uri.path.endsWith('/')) {
      uri = uri.replace(path: '${uri.path}/');
    }
    final directory = p.fromUri(await Isolate.resolvePackageUri(uri));
    return Glob('./**')
        .listSync(root: directory)
        .whereType<File>()
        .map((f) => uri.resolve(p.url.relative(f.path, from: directory)));
  }

  static Future<_ImportCheck> create() async {
    final context = await _createAnalysisContext();
    return _ImportCheck._(context);
  }

  static Future<AnalysisContext> _createAnalysisContext() async {
    final libUri = Uri.parse('package:graphs/');
    final libPath = await _pathForUri(libUri);
    final packagePath = p.dirname(libPath);

    final roots = ContextLocator().locateRoots(includedPaths: [packagePath]);
    if (roots.length != 1) {
      throw StateError('Expected to find exactly one context root, got $roots');
    }
    return ContextBuilder().createContext(contextRoot: roots[0]);
  }

  static Future<String> _pathForUri(Uri uri) async {
    final fileUri = await Isolate.resolvePackageUri(uri);
    if (fileUri == null || !fileUri.isScheme('file')) {
      throw StateError('Expected to resolve $uri to a file URI, got $fileUri');
    }
    return p.fromUri(fileUri);
  }

  _ImportCheck._(this._context);

  Stream<_Source> transitiveSamePackageSources(Iterable<Uri> entryPoints) {
    assert(entryPoints.every((e) => e.scheme == 'package'));
    final package = entryPoints.first.pathSegments.first;
    assert(entryPoints.skip(1).every((e) => e.pathSegments.first == package));
    return crawlAsync<Uri, _Source>(
        entryPoints,
        (uri) async => _Source(uri, await _findImports(uri, package)),
        (_, source) => source.imports);
  }

  Future<Set<Uri>> _findImports(Uri uri, String restrictToPackage) async {
    var path = await _pathForUri(uri);
    var analysisSession = _context.currentSession;
    var parseResult = analysisSession.getParsedUnit(path) as ParsedUnitResult;
    assert(parseResult.content.isNotEmpty,
        'Tried to read an invalid library $uri');
    return parseResult.unit.directives
        .whereType<UriBasedDirective>()
        .map((d) => d.uri.stringValue!)
        .where((uri) => !uri.startsWith('dart:'))
        .map((import) => _resolveImport(import, uri))
        .where((import) => import.pathSegments.first == restrictToPackage)
        .toSet();
  }

  static Uri _resolveImport(String import, Uri from) {
    if (import.startsWith('package:')) return Uri.parse(import);
    assert(from.scheme == 'package');
    final package = from.pathSegments.first;
    final fromPath = p.joinAll(from.pathSegments.skip(1));
    final path = p.normalize(p.join(p.dirname(fromPath), import));
    return Uri.parse('package:${p.join(package, path)}');
  }
}

class _Source {
  final Uri uri;
  final Set<Uri> imports;

  _Source(this.uri, this.imports);
}
