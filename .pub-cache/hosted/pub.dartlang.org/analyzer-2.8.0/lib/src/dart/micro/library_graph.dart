// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/token_impl.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/feature_set_provider.dart';
import 'package:analyzer/src/dart/analysis/unlinked_api_signature.dart';
import 'package:analyzer/src/dart/analysis/unlinked_data.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/micro/cider_byte_store.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/link.dart' as graph
    show DependencyWalker, Node;
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/summary2/informative_data.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:pub_semver/pub_semver.dart';

/// Ensure that the [FileState.libraryCycle] for the [file] and anything it
/// depends on is computed.
void computeLibraryCycle(Uint32List linkedSalt, FileState file) {
  var libraryWalker = _LibraryWalker(linkedSalt);
  libraryWalker.walk(libraryWalker.getNode(file));
}

class CiderUnitTopLevelDeclarations {
  final List<String> extensionNames;
  final List<String> functionNames;
  final List<String> typeNames;
  final List<String> variableNames;

  CiderUnitTopLevelDeclarations({
    required this.extensionNames,
    required this.functionNames,
    required this.typeNames,
    required this.variableNames,
  });

  factory CiderUnitTopLevelDeclarations.read(SummaryDataReader reader) {
    return CiderUnitTopLevelDeclarations(
      extensionNames: reader.readStringUtf8List(),
      functionNames: reader.readStringUtf8List(),
      typeNames: reader.readStringUtf8List(),
      variableNames: reader.readStringUtf8List(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeStringUtf8Iterable(extensionNames);
    sink.writeStringUtf8Iterable(functionNames);
    sink.writeStringUtf8Iterable(typeNames);
    sink.writeStringUtf8Iterable(variableNames);
  }
}

class CiderUnlinkedUnit {
  /// Top-level declarations of the unit.
  final CiderUnitTopLevelDeclarations topLevelDeclarations;

  /// Unlinked summary of the compilation unit.
  final UnlinkedUnit unit;

  CiderUnlinkedUnit({
    required this.topLevelDeclarations,
    required this.unit,
  });

  factory CiderUnlinkedUnit.fromBytes(Uint8List bytes) {
    return CiderUnlinkedUnit.read(
      SummaryDataReader(bytes),
    );
  }

  factory CiderUnlinkedUnit.read(SummaryDataReader reader) {
    return CiderUnlinkedUnit(
      topLevelDeclarations: CiderUnitTopLevelDeclarations.read(reader),
      unit: UnlinkedUnit.read(reader),
    );
  }

  Uint8List toBytes() {
    var byteSink = ByteSink();
    var sink = BufferedSink(byteSink);
    write(sink);
    return sink.flushAndTake();
  }

  void write(BufferedSink sink) {
    topLevelDeclarations.write(sink);
    unit.write(sink);
  }
}

class FileState {
  final _FileStateUnlinked _unlinked;

  /// Files that reference this file.
  final List<FileState> referencingFiles = [];

  _FileStateFiles? _files;

  LibraryCycle? _libraryCycle;

  FileState._(this._unlinked);

  Uint8List get apiSignature => unlinkedUnit.apiSignature;

  Uint8List get digest => _unlinked.digest;

  bool get exists => _unlinked.exists;

  /// Return the [LibraryCycle] this file belongs to, even if it consists of
  /// just this file.  If the library cycle is not known yet, compute it.
  LibraryCycle get libraryCycle {
    if (_libraryCycle == null) {
      computeLibraryCycle(_fsState._linkedSalt, this);
    }
    return _libraryCycle!;
  }

  LineInfo get lineInfo => LineInfo(unlinkedUnit.lineStarts);

  FileState? get partOfLibrary => _unlinked.partOfLibrary;

  String get path => _location.path;

  /// The resolved signature of the file, that depends on the [libraryCycle]
  /// signature, and the content of the file.
  String get resolvedSignature {
    var signatureBuilder = ApiSignature();
    signatureBuilder.addString(path);
    signatureBuilder.addBytes(libraryCycle.signature);

    var content = getContent();
    signatureBuilder.addString(content);

    return signatureBuilder.toHex();
  }

  Source get source => _location.source;

  int get unlinkedId => _unlinked.unlinkedId;

  UnlinkedUnit get unlinkedUnit => _unlinked.unlinked.unit;

  Uri get uri => _location.uri;

  /// Return the [uri] string.
  String get uriStr => uri.toString();

  WorkspacePackage? get workspacePackage => _location.workspacePackage;

  FileSystemState get _fsState => _location._fsState;

  _FileStateLocation get _location => _unlinked.location;

  /// Collect all files that are transitively referenced by this file via
  /// imports, exports, and parts.
  void collectAllReferencedFiles(Set<String> referencedFiles) {
    for (var file in files().directReferencedFiles) {
      if (referencedFiles.add(file.path)) {
        file.collectAllReferencedFiles(referencedFiles);
      }
    }
  }

  _FileStateFiles files({
    OperationPerformanceImpl? performance,
  }) {
    return _files ??= _FileStateFiles(
      owner: this,
      performance: performance ?? OperationPerformanceImpl('<root>'),
    );
  }

  /// Return the content of the file, the empty string if cannot be read.
  ///
  /// We read the file digest, end verify that it is the same as the digest
  /// that was recorded during the file creation. If it is not, then the file
  /// was changed, and we failed to call [FileSystemState.changeFile].
  String getContent() {
    var contentWithDigest = _location._getContent();

    var digest = contentWithDigest.digest;
    if (!const ListEquality<int>().equals(digest, _unlinked.digest)) {
      throw StateError('File was changed, but not invalidated: $path');
    }

    return contentWithDigest.content;
  }

  void internal_setLibraryCycle(LibraryCycle cycle, String signature) {
    _libraryCycle = cycle;
  }

  CompilationUnitImpl parse(
      AnalysisErrorListener errorListener, String content) {
    return _FileStateUnlinked.parse(errorListener, _location, content);
  }

  @override
  String toString() {
    return path;
  }
}

class FileSystemState {
  final ResourceProvider _resourceProvider;
  final CiderByteStore _byteStore;
  final SourceFactory _sourceFactory;
  final Workspace _workspace;
  final Uint32List _linkedSalt;

  /// A function that returns the digest for a file as a String. The function
  /// returns a non null value, returns an empty string if file does
  /// not exist/has no contents.
  final String Function(String path) getFileDigest;

  final Map<String, FileState> _pathToFile = {};
  final Map<Uri, FileState> _uriToFile = {};

  final FeatureSetProvider featureSetProvider;

  /// A function that fetches the given list of files. This function can be used
  /// to batch file reads in systems where file fetches are expensive.
  final void Function(List<String> paths)? prefetchFiles;

  /// A function that returns true if the given file path is likely to be that
  /// of a file that is generated.
  final bool Function(String path)? isGenerated;

  final FileSystemStateTimers timers2 = FileSystemStateTimers();

  final FileSystemStateTestView testView = FileSystemStateTestView();

  FileSystemState(
    this._resourceProvider,
    this._byteStore,
    this._sourceFactory,
    this._workspace,
    this._linkedSalt,
    this.featureSetProvider,
    this.getFileDigest,
    this.prefetchFiles,
    this.isGenerated,
  );

  /// Update the state to reflect the fact that the file with the given [path]
  /// was changed. Specifically this means that we evict this file and every
  /// file that referenced it.
  void changeFile(String path, List<FileState> removedFiles) {
    var file = _pathToFile.remove(path);
    if (file == null) {
      return;
    }

    removedFiles.add(file);
    _uriToFile.remove(file.uri);

    // The removed file does not reference other file anymore.
    for (var referencedFile in file.files().directReferencedFiles) {
      referencedFile.referencingFiles.remove(file);
    }

    // Recursively remove files that reference the removed file.
    for (var reference in file.referencingFiles.toList()) {
      changeFile(reference.path, removedFiles);
    }
  }

  /// Clears all the cached files. Returns the list of ids of all the removed
  /// files.
  Set<int> collectSharedDataIdentifiers() {
    var result = <int>{};
    for (var file in _pathToFile.values) {
      result.add(file._unlinked.unlinkedId);
    }
    return result;
  }

  FeatureSet contextFeatureSet(
    String path,
    Uri uri,
    WorkspacePackage? workspacePackage,
  ) {
    var workspacePackageExperiments = workspacePackage?.enabledExperiments;
    if (workspacePackageExperiments != null) {
      return featureSetProvider.featureSetForExperiments(
        workspacePackageExperiments,
      );
    }

    return featureSetProvider.getFeatureSet(path, uri);
  }

  Version contextLanguageVersion(
    String path,
    Uri uri,
    WorkspacePackage? workspacePackage,
  ) {
    var workspaceLanguageVersion = workspacePackage?.languageVersion;
    if (workspaceLanguageVersion != null) {
      return workspaceLanguageVersion;
    }

    return featureSetProvider.getLanguageVersion(path, uri);
  }

  FileState getFileForPath({
    required String path,
    required OperationPerformanceImpl performance,
  }) {
    var file = _pathToFile[path];
    if (file != null) {
      return file;
    }

    var uri = _sourceFactory.pathToUri(path);
    if (uri == null) {
      throw StateError('Unable to convert path to URI: $path');
    }

    var source = _sourceFactory.forUri2(uri);
    if (source == null) {
      throw StateError('Unable to resolve URI: $uri, path: $path');
    }

    return _newFile(
      source: source,
      performance: performance,
    );
  }

  FileState? getFileForUri({
    FileState? containingLibrary,
    required Uri uri,
    required OperationPerformanceImpl performance,
  }) {
    var file = _uriToFile[uri];
    if (file != null) {
      return file;
    }

    var source = _sourceFactory.forUri2(uri);
    if (source == null) {
      return null;
    }

    return _newFile(
      source: source,
      performance: performance,
    );
  }

  /// Returns a list of files whose contents contains the given string.
  /// Generated files are not included in the search.
  List<String> getFilesContaining(String value) {
    var result = <String>[];
    _pathToFile.forEach((path, file) {
      var genFile = isGenerated == null ? false : isGenerated!(path);
      if (!genFile && file.getContent().contains(value)) {
        result.add(path);
      }
    });
    return result;
  }

  /// Return files that have a top-level declaration with the [name].
  List<FileWithTopLevelDeclaration> getFilesWithTopLevelDeclarations(
    String name,
  ) {
    var result = <FileWithTopLevelDeclaration>[];

    for (var file in _pathToFile.values) {
      void addDeclaration(
        List<String> names,
        FileTopLevelDeclarationKind kind,
      ) {
        if (names.contains(name)) {
          result.add(
            FileWithTopLevelDeclaration(file: file, kind: kind),
          );
        }
      }

      var topLevelDeclarations = file._unlinked.unlinked.topLevelDeclarations;
      addDeclaration(
        topLevelDeclarations.extensionNames,
        FileTopLevelDeclarationKind.extension,
      );
      addDeclaration(
        topLevelDeclarations.functionNames,
        FileTopLevelDeclarationKind.function,
      );
      addDeclaration(
        topLevelDeclarations.typeNames,
        FileTopLevelDeclarationKind.type,
      );
      addDeclaration(
        topLevelDeclarations.variableNames,
        FileTopLevelDeclarationKind.variable,
      );
    }
    return result;
  }

  String? getPathForUri(Uri uri) {
    return _sourceFactory.forUri2(uri)?.fullName;
  }

  /// Computes the set of [FileState]'s used/not used to analyze the given
  /// [files]. Removes the [FileState]'s of the files not used for analysis from
  /// the cache. Returns the set of unused [FileState]'s.
  List<FileState> removeUnusedFiles(List<String> files) {
    var allReferenced = <String>{};
    for (var path in files) {
      allReferenced.add(path);
      _pathToFile[path]?.collectAllReferencedFiles(allReferenced);
    }

    var unusedPaths = _pathToFile.keys.toSet();
    unusedPaths.removeAll(allReferenced);
    testView.removedPaths = unusedPaths;

    var removedFiles = <FileState>[];
    for (var path in unusedPaths) {
      var file = _pathToFile.remove(path)!;
      _uriToFile.remove(file.uri);
      removedFiles.add(file);
    }

    return removedFiles;
  }

  FileState _newFile({
    required Source source,
    required OperationPerformanceImpl performance,
  }) {
    var path = source.fullName;
    var uri = source.uri;

    var workspacePackage = _workspace.findPackageFor(path);
    var featureSet = contextFeatureSet(path, uri, workspacePackage);
    var packageLanguageVersion =
        contextLanguageVersion(path, uri, workspacePackage);

    var location = _FileStateLocation._(this, path, uri, source,
        workspacePackage, featureSet, packageLanguageVersion);
    var file = FileState._(
      _FileStateUnlinked(
        location: location,
        partOfLibrary: null,
        performance: performance,
      ),
    );
    _pathToFile[path] = file;
    _uriToFile[uri] = file;

    // Recurse with recording performance.
    file.files(performance: performance);

    return file;
  }
}

class FileSystemStateTestView {
  final List<String> refreshedFiles = [];
  final List<String> partsDiscoveredLibraries = [];
  Set<String> removedPaths = {};
}

class FileSystemStateTimer {
  final Stopwatch timer = Stopwatch();

  T run<T>(T Function() f) {
    timer.start();
    try {
      return f();
    } finally {
      timer.stop();
    }
  }

  Future<T> runAsync<T>(T Function() f) async {
    timer.start();
    try {
      return f();
    } finally {
      timer.stop();
    }
  }
}

class FileSystemStateTimers {
  final FileSystemStateTimer digest = FileSystemStateTimer();
  final FileSystemStateTimer read = FileSystemStateTimer();
  final FileSystemStateTimer parse = FileSystemStateTimer();
  final FileSystemStateTimer unlinked = FileSystemStateTimer();
  final FileSystemStateTimer prefetch = FileSystemStateTimer();

  void reset() {
    digest.timer.reset();
    read.timer.reset();
    parse.timer.reset();
    unlinked.timer.reset();
    prefetch.timer.reset();
  }
}

/// The kind in [FileWithTopLevelDeclaration].
enum FileTopLevelDeclarationKind { extension, function, type, variable }

/// The data structure for top-level declarations response.
class FileWithTopLevelDeclaration {
  final FileState file;
  final FileTopLevelDeclarationKind kind;

  FileWithTopLevelDeclaration({
    required this.file,
    required this.kind,
  });
}

/// Information about libraries that reference each other, so form a cycle.
class LibraryCycle {
  /// The libraries that belong to this cycle.
  final List<FileState> libraries = [];

  /// The library cycles that this cycle references directly.
  final Set<LibraryCycle> directDependencies = <LibraryCycle>{};

  /// The transitive signature of this cycle.
  ///
  /// It is based on the API signatures of all files of the [libraries], and
  /// the signatures of the cycles that the [libraries] reference
  /// directly.  So, indirectly it is based on the transitive closure of all
  /// files that [libraries] reference (but we don't compute these files).
  late Uint8List signature;

  /// The hash of all the paths of the files in this cycle.
  late String cyclePathsHash;

  /// The ID of the resolution cache entry.
  /// It is `null` if we failed to load libraries of the cycle.
  int? resolutionId;

  LibraryCycle();

  String get signatureStr {
    return hex.encode(signature);
  }

  @override
  String toString() {
    return '[' + libraries.join(', ') + ']';
  }
}

class _ContentWithDigest {
  final String content;
  final Uint8List digest;

  _ContentWithDigest({
    required this.content,
    required this.digest,
  });
}

class _FileStateFiles {
  final List<FileState> imported = [];
  final List<FileState> exported = [];
  final List<FileState> parted = [];
  final List<FileState> ofLibrary = [];

  _FileStateFiles({
    required FileState owner,
    required OperationPerformanceImpl performance,
  }) {
    var unlinked = owner._unlinked;
    var location = unlinked.location;
    var unlinkedUnit = unlinked.unlinked.unit;

    // Build the graph.
    for (var directive in unlinkedUnit.imports) {
      var file = location._fileForRelativeUri(
        relativeUri: directive.uri,
        performance: performance,
      );
      if (file != null) {
        file.referencingFiles.add(owner);
        imported.add(file);
      }
    }
    for (var directive in unlinkedUnit.exports) {
      var file = location._fileForRelativeUri(
        relativeUri: directive.uri,
        performance: performance,
      );
      if (file != null) {
        exported.add(file);
        file.referencingFiles.add(owner);
      }
    }
    for (var uri in unlinkedUnit.parts) {
      var file = location._fileForRelativeUri(
        containingLibrary: owner,
        relativeUri: uri,
        performance: performance,
      );
      if (file != null) {
        parted.add(file);
        file.referencingFiles.add(owner);
      }
    }

    ofLibrary.add(owner);
    ofLibrary.addAll(parted);
  }

  /// Return all directly referenced files - imported, exported or parted.
  Set<FileState> get directReferencedFiles {
    return <FileState>{...imported, ...exported, ...parted};
  }

  /// Return all directly referenced libraries - imported or exported.
  Set<FileState> get directReferencedLibraries {
    return <FileState>{...imported, ...exported};
  }
}

class _FileStateLocation {
  final FileSystemState _fsState;

  /// The path of the file.
  final String path;

  /// The URI of the file.
  final Uri uri;

  /// The [Source] of the file with the [uri].
  final Source source;

  /// The [WorkspacePackage] that contains this file.
  ///
  /// It might be `null` if the file is outside of the workspace.
  final WorkspacePackage? workspacePackage;

  /// The [FeatureSet] for all files in the analysis context.
  ///
  /// Usually it is the feature set of the latest language version, plus
  /// possibly additional enabled experiments (from the analysis options file,
  /// or from SDK allowed experiments).
  ///
  /// This feature set is then restricted, with the [_packageLanguageVersion],
  /// or with a `@dart` language override token in the file header.
  final FeatureSet _contextFeatureSet;

  /// The language version for the package that contains this file.
  final Version _packageLanguageVersion;

  _FileStateLocation._(
    this._fsState,
    this.path,
    this.uri,
    this.source,
    this.workspacePackage,
    this._contextFeatureSet,
    this._packageLanguageVersion,
  );

  File get resource {
    return _fsState._resourceProvider.getFile(path);
  }

  Uri? resolveRelativeUriStr(String relativeUriStr) {
    if (relativeUriStr.isEmpty) {
      return null;
    }

    Uri relativeUri;
    try {
      relativeUri = Uri.parse(relativeUriStr);
    } on FormatException {
      return null;
    }

    return resolveRelativeUri(uri, relativeUri);
  }

  FileState? _fileForRelativeUri({
    FileState? containingLibrary,
    required String relativeUri,
    required OperationPerformanceImpl performance,
  }) {
    var absoluteUri = resolveRelativeUriStr(relativeUri);
    if (absoluteUri == null) {
      return null;
    }

    return _fsState.getFileForUri(
      containingLibrary: containingLibrary,
      uri: absoluteUri,
      performance: performance,
    );
  }

  /// This file has a `part of some.library;` directive. Because it does not
  /// specify the URI of the library, we don't know the library for sure.
  /// But usually the library is one of the sibling files.
  FileState? _findPartOfNameLibrary({
    required OperationPerformanceImpl performance,
  }) {
    var resourceProvider = _fsState._resourceProvider;
    var pathContext = resourceProvider.pathContext;

    var siblings = <Resource>[];
    try {
      siblings = resource.parent2.getChildren();
    } catch (_) {}

    for (var sibling in siblings) {
      if (file_paths.isDart(pathContext, sibling.path)) {
        var siblingState = _fsState.getFileForPath(
          path: sibling.path,
          performance: performance,
        );
        if (siblingState.files().parted.any((part) => part.path == path)) {
          return siblingState;
        }
      }
    }
  }

  _ContentWithDigest _getContent() {
    String content;
    try {
      content = resource.readAsStringSync();
    } catch (_) {
      content = '';
    }

    var digestStr = _fsState.getFileDigest(path);
    var digest = utf8.encode(digestStr) as Uint8List;

    return _ContentWithDigest(content: content, digest: digest);
  }
}

class _FileStateUnlinked {
  final _FileStateLocation location;
  FileState? _partOfLibrary;

  final Uint8List digest;
  final bool exists;
  final CiderUnlinkedUnit unlinked;

  /// id of the cache entry with unlinked data.
  final int unlinkedId;

  factory _FileStateUnlinked({
    required _FileStateLocation location,
    required FileState? partOfLibrary,
    required OperationPerformanceImpl performance,
  }) {
    location._fsState.testView.refreshedFiles.add(location.path);

    int unlinkedId;
    CiderUnlinkedUnit unlinked;

    var digest = performance.run('digest', (performance) {
      performance.getDataInt('count').increment();
      var digestStr = location._fsState.getFileDigest(location.path);
      return utf8.encode(digestStr) as Uint8List;
    });

    var exists = digest.isNotEmpty;

    var unlinkedKey = '${location.path}.unlinked';
    var isUnlinkedFromCache = true;

    // Prepare bytes of the unlinked bundle - existing or new.
    // TODO(migration): should not be nullable
    Uint8List? unlinkedBytes;
    {
      var unlinkedData = location._fsState._byteStore.get(unlinkedKey, digest);
      unlinkedBytes = unlinkedData?.bytes;

      if (unlinkedBytes == null || unlinkedBytes.isEmpty) {
        isUnlinkedFromCache = false;

        var contentWithDigest = performance.run('content', (_) {
          return location._getContent();
        });
        digest = contentWithDigest.digest;
        var content = contentWithDigest.content;

        var unit = performance.run('parse', (performance) {
          performance.getDataInt('count').increment();
          performance.getDataInt('length').add(content.length);
          return parse(AnalysisErrorListener.NULL_LISTENER, location, content);
        });

        performance.run('unlinked', (performance) {
          var unlinkedUnit = serializeAstCiderUnlinked(unit);
          unlinkedBytes = unlinkedUnit.toBytes();
          performance.getDataInt('length').add(unlinkedBytes!.length);
          unlinkedData = location._fsState._byteStore
              .putGet(unlinkedKey, digest, unlinkedBytes!);
          unlinkedBytes = unlinkedData!.bytes;
        });

        unlinked = CiderUnlinkedUnit.fromBytes(unlinkedBytes!);
      }
      unlinkedId = unlinkedData!.id;
    }

    // Read the unlinked bundle.
    unlinked = CiderUnlinkedUnit.fromBytes(unlinkedBytes!);

    var result = _FileStateUnlinked._(
      location: location,
      partOfLibrary: partOfLibrary,
      digest: digest,
      exists: exists,
      unlinked: unlinked,
      unlinkedId: unlinkedId,
    );
    if (isUnlinkedFromCache) {
      performance.run('prefetch', (_) {
        result._prefetchDirectReferences();
      });
    }
    return result;
  }

  _FileStateUnlinked._({
    required this.location,
    required FileState? partOfLibrary,
    required this.digest,
    required this.exists,
    required this.unlinked,
    required this.unlinkedId,
  }) : _partOfLibrary = partOfLibrary;

  FileState? get partOfLibrary {
    var partOfLibrary = _partOfLibrary;
    if (partOfLibrary != null) {
      return partOfLibrary;
    }

    var performance = OperationPerformanceImpl('<root>');

    var libraryName = unlinked.unit.partOfName;
    if (libraryName != null) {
      location._fsState.testView.partsDiscoveredLibraries.add(location.path);
      return _partOfLibrary = location._findPartOfNameLibrary(
        performance: performance,
      );
    }

    var libraryUri = unlinked.unit.partOfUri;
    if (libraryUri != null) {
      location._fsState.testView.partsDiscoveredLibraries.add(location.path);
      return _partOfLibrary = location._fileForRelativeUri(
        relativeUri: libraryUri,
        performance: performance,
      );
    }
  }

  void _prefetchDirectReferences() {
    var prefetchFiles = location._fsState.prefetchFiles;
    if (prefetchFiles == null) {
      return;
    }

    var paths = <String>{};

    void addRelativeUri(String relativeUri) {
      var absoluteUri = location.resolveRelativeUriStr(relativeUri);
      if (absoluteUri != null) {
        var path = location._fsState.getPathForUri(absoluteUri);
        if (path != null) {
          paths.add(path);
        }
      }
    }

    var unlinkedUnit = unlinked.unit;
    for (var directive in unlinkedUnit.imports) {
      addRelativeUri(directive.uri);
    }
    for (var directive in unlinkedUnit.exports) {
      addRelativeUri(directive.uri);
    }
    for (var uri in unlinkedUnit.parts) {
      addRelativeUri(uri);
    }

    prefetchFiles(paths.toList());
  }

  static CompilationUnitImpl parse(AnalysisErrorListener errorListener,
      _FileStateLocation location, String content) {
    CharSequenceReader reader = CharSequenceReader(content);
    Scanner scanner = Scanner(location.source, reader, errorListener)
      ..configureFeatures(
        featureSetForOverriding: location._contextFeatureSet,
        featureSet: location._contextFeatureSet.restrictToVersion(
          location._packageLanguageVersion,
        ),
      );
    Token token = scanner.tokenize(reportScannerErrors: false);
    LineInfo lineInfo = LineInfo(scanner.lineStarts);

    // Pass the feature set from the scanner to the parser
    // because the scanner may have detected a language version comment
    // and downgraded the feature set it holds.
    Parser parser = Parser(
      location.source,
      errorListener,
      featureSet: scanner.featureSet,
    );
    parser.enableOptionalNewAndConst = true;
    var unit = parser.parseCompilationUnit(token);
    unit.lineInfo = lineInfo;

    // StringToken uses a static instance of StringCanonicalizer, so we need
    // to clear it explicitly once we are done using it for this file.
    StringToken.canonicalizer.clear();

    // TODO(scheglov) Use actual versions.
    unit.languageVersion = LibraryLanguageVersion(
      package: ExperimentStatus.currentVersion,
      override: null,
    );

    return unit;
  }

  static CiderUnlinkedUnit serializeAstCiderUnlinked(CompilationUnit unit) {
    var exports = <UnlinkedNamespaceDirective>[];
    var imports = <UnlinkedNamespaceDirective>[];
    var parts = <String>[];
    var hasDartCoreImport = false;
    var hasLibraryDirective = false;
    var hasPartOfDirective = false;
    String? partOfName;
    String? partOfUriStr;
    for (var directive in unit.directives) {
      if (directive is ExportDirective) {
        var builder = _serializeNamespaceDirective(directive);
        exports.add(builder);
      } else if (directive is ImportDirective) {
        var builder = _serializeNamespaceDirective(directive);
        imports.add(builder);
        if (builder.uri == 'dart:core') {
          hasDartCoreImport = true;
        }
      } else if (directive is LibraryDirective) {
        hasLibraryDirective = true;
      } else if (directive is PartDirective) {
        var uriStr = directive.uri.stringValue;
        parts.add(uriStr ?? '');
      } else if (directive is PartOfDirective) {
        hasPartOfDirective = true;
        var libraryName = directive.libraryName;
        var uriStr = directive.uri?.stringValue;
        if (libraryName != null) {
          partOfName = libraryName.components.map((e) => e.name).join('.');
        } else if (uriStr != null) {
          partOfUriStr = uriStr;
        }
      }
    }
    if (!hasDartCoreImport) {
      imports.add(
        UnlinkedNamespaceDirective(
          configurations: [],
          uri: 'dart:core',
        ),
      );
    }

    var declaredExtensions = <String>[];
    var declaredFunctions = <String>[];
    var declaredTypes = <String>[];
    var declaredVariables = <String>[];
    for (var declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        declaredTypes.add(declaration.name.name);
      } else if (declaration is EnumDeclaration) {
        declaredTypes.add(declaration.name.name);
      } else if (declaration is ExtensionDeclaration) {
        var name = declaration.name;
        if (name != null) {
          declaredExtensions.add(name.name);
        }
      } else if (declaration is FunctionDeclaration) {
        declaredFunctions.add(declaration.name.name);
      } else if (declaration is MixinDeclaration) {
        declaredTypes.add(declaration.name.name);
      } else if (declaration is TopLevelVariableDeclaration) {
        for (var variable in declaration.variables.variables) {
          declaredVariables.add(variable.name.name);
        }
      }
    }

    var unlinkedUnit = UnlinkedUnit(
      apiSignature: computeUnlinkedApiSignature(unit),
      exports: exports,
      hasLibraryDirective: hasLibraryDirective,
      hasPartOfDirective: hasPartOfDirective,
      imports: imports,
      informativeBytes: writeUnitInformative(unit),
      lineStarts: Uint32List.fromList(unit.lineInfo!.lineStarts),
      partOfName: partOfName,
      partOfUri: partOfUriStr,
      parts: parts,
    );

    return CiderUnlinkedUnit(
      unit: unlinkedUnit,
      topLevelDeclarations: CiderUnitTopLevelDeclarations(
        extensionNames: declaredExtensions,
        functionNames: declaredFunctions,
        typeNames: declaredTypes,
        variableNames: declaredVariables,
      ),
    );
  }

  static UnlinkedNamespaceDirective _serializeNamespaceDirective(
    NamespaceDirective directive,
  ) {
    return UnlinkedNamespaceDirective(
      configurations: directive.configurations.map((configuration) {
        var name = configuration.name.components.join('.');
        var value = configuration.value?.stringValue ?? '';
        return UnlinkedNamespaceDirectiveConfiguration(
          name: name,
          value: value,
          uri: configuration.uri.stringValue ?? '',
        );
      }).toList(),
      uri: directive.uri.stringValue ?? '',
    );
  }
}

/// Node in [_LibraryWalker].
class _LibraryNode extends graph.Node<_LibraryNode> {
  final _LibraryWalker walker;
  final FileState file;

  _LibraryNode(this.walker, this.file);

  @override
  bool get isEvaluated => file._libraryCycle != null;

  @override
  List<_LibraryNode> computeDependencies() {
    return file.files().directReferencedLibraries.map(walker.getNode).toList();
  }
}

/// Helper that organizes dependencies of a library into topologically
/// sorted [LibraryCycle]s.
class _LibraryWalker extends graph.DependencyWalker<_LibraryNode> {
  final Uint32List _linkedSalt;
  final Map<FileState, _LibraryNode> nodesOfFiles = {};

  _LibraryWalker(this._linkedSalt);

  @override
  void evaluate(_LibraryNode v) {
    evaluateScc([v]);
  }

  @override
  void evaluateScc(List<_LibraryNode> scc) {
    var cycle = LibraryCycle();

    var signature = ApiSignature();
    signature.addUint32List(_linkedSalt);

    // Sort libraries to produce stable signatures.
    scc.sort((first, second) {
      var firstPath = first.file.path;
      var secondPath = second.file.path;
      return firstPath.compareTo(secondPath);
    });

    // Append direct referenced cycles.
    for (var node in scc) {
      var file = node.file;
      _appendDirectlyReferenced(cycle, signature, file.files().imported);
      _appendDirectlyReferenced(cycle, signature, file.files().exported);
    }

    // Fill the cycle with libraries.
    for (var node in scc) {
      cycle.libraries.add(node.file);

      signature.addString(node.file.uriStr);

      signature.addInt(node.file.files().ofLibrary.length);
      for (var file in node.file.files().ofLibrary) {
        signature.addBool(file.exists);
        signature.addBytes(file.apiSignature);
      }
    }

    // Compute the general library cycle signature.
    cycle.signature = signature.toByteList();

    // Compute the cycle file paths signature.
    var filePathsSignature = ApiSignature();
    for (var node in scc) {
      filePathsSignature.addString(node.file.path);
    }
    cycle.cyclePathsHash = filePathsSignature.toHex();

    // Compute library specific signatures.
    for (var node in scc) {
      var librarySignatureBuilder = ApiSignature()
        ..addString(node.file.uriStr)
        ..addBytes(cycle.signature);
      var librarySignature = librarySignatureBuilder.toHex();

      node.file.internal_setLibraryCycle(
        cycle,
        librarySignature,
      );
    }
  }

  _LibraryNode getNode(FileState file) {
    return nodesOfFiles.putIfAbsent(file, () => _LibraryNode(this, file));
  }

  void _appendDirectlyReferenced(
    LibraryCycle cycle,
    ApiSignature signature,
    List<FileState> directlyReferenced,
  ) {
    signature.addInt(directlyReferenced.length);
    for (var referencedLibrary in directlyReferenced) {
      var referencedCycle = referencedLibrary._libraryCycle;
      // We get null when the library is a part of the cycle being build.
      if (referencedCycle == null) continue;

      if (cycle.directDependencies.add(referencedCycle)) {
        signature.addBytes(referencedCycle.signature);
      }
    }
  }
}
