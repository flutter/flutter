// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/java_io.dart'; // ignore: implementation_imports
import 'package:analyzer/src/generated/sdk.dart'; // ignore: implementation_imports
import 'package:analyzer/src/generated/sdk_io.dart'; // ignore: implementation_imports
import 'package:package_config/packages_file.dart' as packages;
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;

import 'sdk.dart';

// TODO: do we need to traverse into dart: libraries? Or ones that are really packages?

// TODO: added, changed, and removed sources

// TODO: For performance, the lexer should not lex the entire file.

// TODO: switch to sources having sourcerefs that need to be resolved

// TODO: they should know - independently of being dirty - whether all their
// refs were resolved

// TODO: support conditional directives

class SourceGraph {
  SourceGraph(this.directory, this.entryPointPath, { this.parseEmbedderSource: false });

  final Directory directory;
  final String entryPointPath;
  final bool parseEmbedderSource;

  PackagesFile _packagesFile;
  Map<String, String> _dartLibraryMap = <String, String>{};
  bool _wasIncremental = false;
  Map<String, GraphSource> _sourceMap = <String, GraphSource>{};
  List<GraphChange> _changes = <GraphChange>[];

  /// Whether the last parse was incremental, or a full re-parse.
  bool get wasIncremental => _wasIncremental;

  Iterable<GraphSource> get sources => _sourceMap.values;

  List<GraphChange> get changes => _changes;

  void initialParse() {
    _fullParse();
  }

  void reparseSources() {
    if (!_packagesFile.isUpToDate) {
      _fullParse();
      return;
    }

    _wasIncremental = true;

    // TODO: start with the root node again


    // TODO: find any out-of-date sources


    // TODO: find any sources that didn't resolve their dependencies


    // Parse any dirty sources.
    while (sources.any((GraphSource source) => source.dirty)) {
      for (GraphSource source in sources.where((GraphSource source) => source.dirty).toList()) {
        source.parse();
      }
    }

    // TODO: check for no longer referenced sources

  }

  /// Flush any cached file contents.
  void flushCachedFileContents() {
    for (GraphSource source in sources)
      source.flushCachedFileContents();
  }

  void _fullParse() {
    _wasIncremental = false;

    _sourceMap.clear();
    _changes.clear();

    if (parseEmbedderSource) {
      // Parse the libraries.dart file - use that info to resolve dart: references.
      _dartLibraryMap.clear();
      String sdkPath = dartSdkPath;
      File librariesFile = new File(path.join(sdkPath, 'lib/_internal/libraries.dart'));
      if (librariesFile.existsSync()) {
        SdkLibrariesReader reader = new SdkLibrariesReader(false);
        LibraryMap dartLibraryMap = reader.readFromFile(
          new JavaFile(librariesFile.path), librariesFile.readAsStringSync()
        );

        String libPath = path.normalize(path.absolute(path.join(dartSdkPath, 'lib')));
        for (SdkLibrary library in dartLibraryMap.sdkLibraries)
          _dartLibraryMap[library.shortName] = path.join(libPath, library.path);
      }
    }

    // Parse the .packages file.
    _packagesFile = new PackagesFile(new File(path.join(directory.path, '.packages')));
    _packagesFile.parse();

    GraphSource root = _getCreateSource(path.join(directory.path, entryPointPath));
    root.parse();

    // Parse any dirty sources.
    while (sources.any((GraphSource source) => source.dirty)) {
      for (GraphSource source in sources.where((GraphSource source) => source.dirty).toList()) {
        source.parse();
      }
    }
  }

  GraphSource _getCreateSource(String resolvedPath) {
    if (_sourceMap.containsKey(resolvedPath)) {
      return _sourceMap[resolvedPath];
    } else {
      GraphSource source = new GraphSource(this, resolvedPath);
      _sourceMap[resolvedPath] = source;
      return source;
    }
  }

  String _resolveDirectiveUri(String uriString, String basePath) {
    if (!uriString.contains(':')) {
      return path.normalize(path.join(path.dirname(basePath), uriString));
    } else {
      Uri uri = Uri.parse(uriString);

      if (uri.scheme == 'dart') {
        if (parseEmbedderSource) {
          // dart:
          if (_packagesFile.canResolveDart) {
            return _packagesFile.resolveDart(uri.toString());
          } else {
            return _dartLibraryMap[uri.toString()];
          }
        } else {
          return null;
        }
      } else if (uri.scheme == 'package') {
        // package:
        String root = uri.pathSegments.first;
        String relPath = uri.pathSegments.sublist(1).join('/');
        return _packagesFile.resolvePackage(root, relPath);
      } else {
        return null;
      }
    }
  }
}

class GraphSource {
  GraphSource(this.graph, this.fullpath);

  final SourceGraph graph;
  final String fullpath;
  final List<GraphSourceReference> references = <GraphSourceReference>[];
  bool dirty = true;
  DateTime _stamp;
  String _cachedSource;

  bool get isUpToDate => _file.lastModifiedSync() == _stamp;

  String getSource() {
    if (_cachedSource != null && isUpToDate)
      return _cachedSource;

    _cachedSource = _file.readAsStringSync();
    _stamp = _file.lastModifiedSync();
    return _cachedSource;
  }

  void parse() {
    dirty = false;
    references.clear();

    CompilationUnit unit = parseDirectives(getSource(), name: fullpath, suppressErrors: true);

    for (Directive directive in unit.directives) {
      if (directive is ExportDirective || directive is ImportDirective || directive is PartDirective) {
        UriBasedDirective uriBasedDirective = directive;
        String uri = uriBasedDirective.uri.stringValue;

        GraphSourceReference reference = new GraphSourceReference(this, uri);
        references.add(reference);

        // TODO: resolve the reference

        String resolvedPath = graph._resolveDirectiveUri(uri, fullpath);
        // TODO: it's ok if parseEmbedderSource and the dart: ref didn't resolve

        // TODO: What to do if this doesn't return a value?
        if (resolvedPath != null) {
          graph._getCreateSource(resolvedPath);
        }
      }
    }
  }

  File get _file => new File(fullpath);

  @override
  String toString() => fullpath;

  bool get hasCachedFileContents => _cachedSource != null;

  void flushCachedFileContents() {
    _cachedSource = null;
  }
}

class GraphSourceReference {
  GraphSourceReference(this.parent, this.uri);

  final GraphSource parent;
  final String uri;

  bool resolved;
  bool unneeded;

}

class GraphChange {

}

class PackagesFile {
  PackagesFile(this.file);

  final File file;
  DateTime _stamp;
  Map<String, Uri> _packageInfo;

  String _embedderFilePath;
  Map<String, String> _embeddedLibs;

  bool get isUpToDate => file.lastModifiedSync() == _stamp;

  void parse() {
    _packageInfo = packages.parse(file.readAsBytesSync(), file.parent.uri);
    _stamp = file.lastModifiedSync();

    // Look for am _embedder.yaml file with a embedded_libs section.
    _embedderFilePath = null;
    _embeddedLibs = null;

    for (Uri uri in _packageInfo.values) {
      if (uri.scheme == 'file' || uri.scheme.isEmpty) {
        File embedder = new File(path.join(uri.path, '_embedder.yaml'));
        if (embedder.existsSync()) {
          dynamic contents = yaml.loadYaml(embedder.readAsStringSync());
          _embedderFilePath = path.absolute(embedder.parent.path);
          _embeddedLibs = contents is Map ? contents['embedded_libs'] : null;
          break;
        }
      }
    }
  }

  String resolvePackage(String packageName, String relPath) {
    Uri uri = _packageInfo[packageName];
    if (uri == null)
      return null;
    return path.normalize(path.join(uri.path, relPath));
  }

  bool get canResolveDart => _embeddedLibs != null;

  String resolveDart(String dartUri) {
    String dartPath = _embeddedLibs[dartUri];
    if (dartPath == null)
      return null;
    return path.normalize(path.join(_embedderFilePath, dartPath));
  }
}
