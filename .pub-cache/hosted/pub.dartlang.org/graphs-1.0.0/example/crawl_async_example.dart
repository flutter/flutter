// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/context_builder.dart';
import 'package:analyzer/dart/analysis/context_locator.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:graphs/graphs.dart';
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';

/// Print a transitive set of imported URIs where libraries are read
/// asynchronously.
Future<Null> main() async {
  // Limits calls to [findImports].
  var _pool = Pool(10);
  var allImports = await crawlAsync<Uri, Source>(
          [Uri.parse('package:graphs/graphs.dart')],
          read,
          (from, source) => _pool.withResource(() => findImports(from, source)))
      .toList();
  print(allImports.map((s) => s.uri).toList());
}

AnalysisContext? _analysisContext;

Future<AnalysisContext> get analysisContext async {
  var context = _analysisContext;
  if (context == null) {
    var libUri = Uri.parse('package:graphs/');
    var libPath = await pathForUri(libUri);
    var packagePath = p.dirname(libPath);

    var roots = ContextLocator().locateRoots(includedPaths: [packagePath]);
    if (roots.length != 1) {
      throw StateError('Expected to find exactly one context root, got $roots');
    }

    context = _analysisContext =
        ContextBuilder().createContext(contextRoot: roots[0]);
  }

  return context;
}

Future<Iterable<Uri>> findImports(Uri from, Source source) async {
  return source.unit.directives
      .whereType<UriBasedDirective>()
      .map((d) => d.uri.stringValue!)
      .where((uri) => !uri.startsWith('dart:'))
      .map((import) => resolveImport(import, from));
}

Future<CompilationUnit> parseUri(Uri uri) async {
  var path = await pathForUri(uri);
  var analysisSession = (await analysisContext).currentSession;
  var parseResult = analysisSession.getParsedUnit(path);
  return parseResult.unit;
}

Future<String> pathForUri(Uri uri) async {
  var fileUri = await Isolate.resolvePackageUri(uri);
  if (fileUri == null || !fileUri.isScheme('file')) {
    throw StateError('Expected to resolve $uri to a file URI, got $fileUri');
  }
  return p.fromUri(fileUri);
}

Future<Source> read(Uri uri) async => Source(uri, await parseUri(uri));

Uri resolveImport(String import, Uri from) {
  if (import.startsWith('package:')) return Uri.parse(import);
  assert(from.scheme == 'package');
  final package = from.pathSegments.first;
  final fromPath = p.joinAll(from.pathSegments.skip(1));
  final path = p.normalize(p.join(p.dirname(fromPath), import));
  return Uri.parse('package:${p.join(package, path)}');
}

class Source {
  final Uri uri;
  final CompilationUnit unit;

  Source(this.uri, this.unit);
}
