// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/token_impl.dart'
    show StringTokenImpl;
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/defined_names.dart';
import 'package:analyzer/src/dart/analysis/feature_set_provider.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/referenced_names.dart';
import 'package:analyzer/src/dart/analysis/unlinked_api_signature.dart';
import 'package:analyzer/src/dart/analysis/unlinked_data.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/exception/exception.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/ignore_comments/ignore_info.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary2/informative_data.dart';
import 'package:analyzer/src/util/either.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/util/uri.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as package_path;
import 'package:pub_semver/pub_semver.dart';

/// The file has a `library augment` directive.
abstract class AugmentationFileStateKind extends LibraryOrAugmentationFileKind {
  final UnlinkedLibraryAugmentationDirective directive;

  AugmentationFileStateKind({
    required super.file,
    required this.directive,
  });

  @override
  LibraryFileStateKind get asLibrary {
    // TODO(scheglov): implement asLibrary
    throw UnimplementedError();
  }

  /// Returns `true` if the `library augment` directive confirms [container].
  bool isAugmentationOf(LibraryOrAugmentationFileKind container);
}

/// The URI of the [directive] can be resolved.
class AugmentationKnownFileStateKind extends AugmentationFileStateKind {
  /// The file that is referenced by the [directive].
  final FileState uriFile;

  AugmentationKnownFileStateKind({
    required super.file,
    required super.directive,
    required this.uriFile,
  });

  /// If the [uriFile] has `import augment` of this file, returns [uriFile].
  /// Otherwise, this file is not a valid augmentation, returns `null`.
  LibraryOrAugmentationFileKind? get augmented {
    final uriKind = uriFile.kind;
    if (uriKind is LibraryOrAugmentationFileKind) {
      if (uriKind.hasAugmentation(this)) {
        return uriKind;
      }
    }
    return null;
  }

  @override
  LibraryFileStateKind? get library {
    final visited = Set<LibraryOrAugmentationFileKind>.identity();
    var current = augmented;
    while (current != null && visited.add(current)) {
      if (current is LibraryFileStateKind) {
        return current;
      } else if (current is AugmentationKnownFileStateKind) {
        current = current.augmented;
      } else {
        return null;
      }
    }
    return null;
  }

  @override
  bool isAugmentationOf(LibraryOrAugmentationFileKind container) {
    return uriFile == container.file;
  }
}

/// The URI of the [directive] can not be resolved.
class AugmentationUnknownFileStateKind extends AugmentationFileStateKind {
  AugmentationUnknownFileStateKind({
    required super.file,
    required super.directive,
  });

  @override
  LibraryFileStateKind? get library => null;

  @override
  bool isAugmentationOf(LibraryOrAugmentationFileKind container) => false;
}

/// Information about a single `import` directive.
class ExportDirectiveState {
  final UnlinkedNamespaceDirective directive;

  ExportDirectiveState({
    required this.directive,
  });

  /// If [exportedSource] corresponds to a library, returns it.
  Source? get exportedLibrarySource => null;

  /// Returns a [Source] that is referenced by this directive. If the are
  /// configurations, selects the one which satisfies the conditions.
  ///
  /// Returns `null` if the selected URI is not valid, or cannot be resolved
  /// into a [Source].
  Source? get exportedSource => null;
}

/// [ExportDirectiveState] that has a valid URI that references a file.
class ExportDirectiveWithFile extends ExportDirectiveState {
  final FileState exportedFile;

  ExportDirectiveWithFile({
    required super.directive,
    required this.exportedFile,
  });

  /// Returns [exportedFile] if it is a library.
  LibraryFileStateKind? get exportedLibrary {
    final kind = exportedFile.kind;
    if (kind is LibraryFileStateKind) {
      return kind;
    }
    return null;
  }

  @override
  Source? get exportedLibrarySource {
    if (exportedFile.kind is LibraryFileStateKind) {
      return exportedSource;
    }
    return null;
  }

  @override
  Source get exportedSource => exportedFile.source;
}

/// [ExportDirectiveState] with a URI that resolves to [InSummarySource].
class ExportDirectiveWithInSummarySource extends ExportDirectiveState {
  @override
  final InSummarySource exportedSource;

  ExportDirectiveWithInSummarySource({
    required super.directive,
    required this.exportedSource,
  });

  @override
  Source? get exportedLibrarySource {
    if (exportedSource.kind == InSummarySourceKind.library) {
      return exportedSource;
    } else {
      return null;
    }
  }
}

/// A library from [SummaryDataStore].
class ExternalLibrary {
  final InSummarySource source;

  ExternalLibrary._(this.source);
}

abstract class FileContent {
  String get content;
  String get contentHash;
  bool get exists;
}

/// [FileContentOverlay] is used to temporary override content of files.
class FileContentOverlay {
  final _map = <String, String>{};

  /// Return the paths currently being overridden.
  Iterable<String> get paths => _map.keys;

  /// Return the content of the file with the given [path], or `null` the
  /// overlay does not override the content of the file.
  ///
  /// The [path] must be absolute and normalized.
  String? operator [](String path) => _map[path];

  /// Return the new [content] of the file with the given [path].
  ///
  /// The [path] must be absolute and normalized.
  void operator []=(String path, String? content) {
    if (content == null) {
      _map.remove(path);
    } else {
      _map[path] = content;
    }
  }
}

abstract class FileContentStrategy {
  FileContent get(String path);
}

/// Information about a file being analyzed, explicitly or implicitly.
///
/// It provides a consistent view on its properties.
///
/// The properties are not guaranteed to represent the most recent state
/// of the file system. To update the file to the most recent state, [refresh]
/// should be called.
class FileState {
  final FileSystemState _fsState;

  /// The absolute path of the file.
  final String path;

  /// The absolute URI of the file.
  final Uri uri;

  /// Properties of the [uri].
  final FileUriProperties uriProperties;

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
  /// This feature set is then restricted, with the [packageLanguageVersion],
  /// or with a `@dart` language override token in the file header.
  final FeatureSet _contextFeatureSet;

  /// The language version for the package that contains this file.
  final Version packageLanguageVersion;

  FileContent? _fileContent;
  LineInfo? _lineInfo;
  Uint8List? _unlinkedSignature;
  String? _unlinkedKey;
  AnalysisDriverUnlinkedUnit? _driverUnlinkedUnit;
  Uint8List? _apiSignature;

  UnlinkedUnit? _unlinked2;

  FileStateKind? _kind;

  /// Files that reference this file.
  final Set<FileState> referencingFiles = {};

  List<FileState?>? _importedFiles;
  List<FileState?>? _exportedFiles;

  Set<FileState>? _directReferencedFiles;

  /// The flag that shows whether the file has an error or warning that
  /// might be fixed by a change to another file.
  bool hasErrorOrWarning = false;

  /// Set to `true` if this file contains code that might be executed by
  /// a macro - declares a macro class itself, or is directly or indirectly
  /// imported into a library that declares one.
  bool mightBeExecutedByMacroClass = false;

  FileState._(
    this._fsState,
    this.path,
    this.uri,
    this.source,
    this.workspacePackage,
    this._contextFeatureSet,
    this.packageLanguageVersion,
  ) : uriProperties = FileUriProperties(uri);

  /// The unlinked API signature of the file.
  Uint8List get apiSignature => _apiSignature!;

  /// The content of the file.
  String get content => _fileContent!.content;

  /// The MD5 hash of the [content].
  String get contentHash => _fileContent!.contentHash;

  /// The class member names defined by the file.
  Set<String> get definedClassMemberNames {
    return _driverUnlinkedUnit!.definedClassMemberNames;
  }

  /// The top-level names defined by the file.
  Set<String> get definedTopLevelNames {
    return _driverUnlinkedUnit!.definedTopLevelNames;
  }

  /// Return the set of all directly referenced files - imported, exported or
  /// parted.
  /// TODO(scheglov) Stop using [partedFiles].
  Set<FileState> get directReferencedFiles {
    return _directReferencedFiles ??= <FileState>{
      ...importedFiles.whereNotNull(),
      ...exportedFiles.whereNotNull(),
      ...partedFiles.whereNotNull(),
    };
  }

  /// Return `true` if the file exists.
  bool get exists => _fileContent!.exists;

  /// The list of files this file exports.
  List<FileState?> get exportedFiles {
    return _exportedFiles ??= _unlinked2!.exports.map((directive) {
      var uri = _selectRelativeUri(directive);
      return _fileForRelativeUri(uri).map(
        (file) {
          file?.referencingFiles.add(this);
          return file;
        },
        (_) => null,
      );
    }).toList();
  }

  @override
  int get hashCode => uri.hashCode;

  /// The list of files this file imports.
  List<FileState?> get importedFiles {
    return _importedFiles ??= _unlinked2!.imports.map((directive) {
      var uri = _selectRelativeUri(directive);
      return _fileForRelativeUri(uri).map(
        (file) {
          file?.referencingFiles.add(this);
          return file;
        },
        (_) => null,
      );
    }).toList();
  }

  /// Return `true` if the file does not have a `library` directive, and has a
  /// `part of` directive, so is probably a part.
  bool get isPart {
    if (_unlinked2!.libraryDirective != null) {
      return false;
    }
    return _unlinked2!.partOfNameDirective != null ||
        _unlinked2!.partOfUriDirective != null;
  }

  FileStateKind get kind => _kind!;

  /// Return information about line in the file.
  LineInfo get lineInfo => _lineInfo!;

  /// The list of files this library file references as parts.
  List<FileState?> get partedFiles {
    final kind = _kind;
    if (kind is LibraryFileStateKind) {
      return kind.parts.map((part) {
        if (part is PartDirectiveWithFile) {
          return part.includedFile;
        } else {
          return null;
        }
      }).toList();
    } else {
      return [];
    }
  }

  /// The external names referenced by the file.
  Set<String> get referencedNames {
    return _driverUnlinkedUnit!.referencedNames;
  }

  File get resource {
    return _fsState._resourceProvider.getFile(path);
  }

  @visibleForTesting
  FileStateTestView get test => FileStateTestView(this);

  /// Return the set of transitive files - the file itself and all of the
  /// directly or indirectly referenced files.
  Set<FileState> get transitiveFiles {
    var transitiveFiles = <FileState>{};

    void appendReferenced(FileState file) {
      if (transitiveFiles.add(file)) {
        file.directReferencedFiles.forEach(appendReferenced);
      }
    }

    appendReferenced(this);
    return transitiveFiles;
  }

  /// The [UnlinkedUnit] of the file.
  UnlinkedUnit get unlinked2 => _unlinked2!;

  String get unlinkedKey => _unlinkedKey!;

  /// The MD5 signature based on the content, feature sets, language version.
  Uint8List get unlinkedSignature => _unlinkedSignature!;

  /// Return the [uri] string.
  String get uriStr => uri.toString();

  @override
  bool operator ==(Object other) {
    return other is FileState && other.uri == uri;
  }

  /// Collect all files that are transitively referenced by this file via
  /// imports, exports, and parts.
  void collectAllReferencedFiles(Set<String> referencedFiles) {
    for (final file in directReferencedFiles) {
      if (referencedFiles.add(file.path)) {
        file.collectAllReferencedFiles(referencedFiles);
      }
    }
  }

  /// Return a new parsed unresolved [CompilationUnit].
  CompilationUnitImpl parse([AnalysisErrorListener? errorListener]) {
    errorListener ??= AnalysisErrorListener.NULL_LISTENER;
    try {
      return _parse(errorListener);
    } catch (exception, stackTrace) {
      throw CaughtExceptionWithFiles(
        exception,
        stackTrace,
        {path: content},
      );
    }
  }

  /// TODO(scheglov) Remove it when [IgnoreInfo] is stored here.
  CompilationUnitImpl parse2(
    AnalysisErrorListener errorListener,
    String content,
  ) {
    CharSequenceReader reader = CharSequenceReader(content);
    Scanner scanner = Scanner(source, reader, errorListener)
      ..configureFeatures(
        featureSetForOverriding: _contextFeatureSet,
        featureSet: _contextFeatureSet.restrictToVersion(
          packageLanguageVersion,
        ),
      );
    Token token = scanner.tokenize(reportScannerErrors: false);
    LineInfo lineInfo = LineInfo(scanner.lineStarts);

    Parser parser = Parser(
      source,
      errorListener,
      featureSet: scanner.featureSet,
      lineInfo: lineInfo,
    );
    parser.enableOptionalNewAndConst = true;

    var unit = parser.parseCompilationUnit(token);
    unit.languageVersion = LibraryLanguageVersion(
      package: packageLanguageVersion,
      override: scanner.overrideVersion,
    );

    // StringToken uses a static instance of StringCanonicalizer, so we need
    // to clear it explicitly once we are done using it for this file.
    StringTokenImpl.canonicalizer.clear();

    return unit;
  }

  /// Read the file content and ensure that all of the file properties are
  /// consistent with the read content, including API signature.
  ///
  /// Return how the file changed since the last refresh.
  FileStateRefreshResult refresh() {
    _invalidateCurrentUnresolvedData();

    final rawFileState = _fsState.fileContentStrategy.get(path);
    final contentChanged =
        _fileContent?.contentHash != rawFileState.contentHash;
    _fileContent = rawFileState;

    // Prepare the unlinked bundle key.
    {
      var signature = ApiSignature();
      signature.addUint32List(_fsState._saltForUnlinked);
      signature.addFeatureSet(_contextFeatureSet);
      signature.addLanguageVersion(packageLanguageVersion);
      signature.addString(contentHash);
      signature.addBool(exists);
      _unlinkedSignature = signature.toByteList();
      var signatureHex = hex.encode(_unlinkedSignature!);
      // TODO(scheglov) Use the path as the key, and store the signature.
      _unlinkedKey = '$signatureHex.unlinked2';
    }

    // Prepare the unlinked unit.
    _driverUnlinkedUnit = _getUnlinkedUnit();
    _unlinked2 = _driverUnlinkedUnit!.unit;
    _lineInfo = LineInfo(_unlinked2!.lineStarts);

    _prefetchDirectReferences();

    // Prepare API signature.
    var newApiSignature = _unlinked2!.apiSignature;
    bool apiSignatureChanged = _apiSignature != null &&
        !_equalByteLists(_apiSignature, newApiSignature);
    _apiSignature = newApiSignature;

    // The API signature changed.
    //   Flush affected library cycles.
    //   Flush exported top-level declarations of all files.
    if (apiSignatureChanged) {
      // TODO(scheglov) Make it a method of FileStateKind?
      final kind = _kind;
      if (kind is LibraryFileStateKind) {
        kind._libraryCycle?.invalidate();
      }
      _invalidatesLibrariesOfThisPart();
    }

    // It is possible that this file does not reference these files.
    _stopReferencingByThisFile();

    // Read imports/exports on demand.
    _importedFiles = null;
    _exportedFiles = null;
    _directReferencedFiles = null;

    // Read parts eagerly to link parts to libraries.
    _updateKind();

    // Update mapping from subtyped names to files.
    for (var name in _driverUnlinkedUnit!.subtypedNames) {
      var files = _fsState._subtypedNameToFiles[name];
      if (files == null) {
        files = <FileState>{};
        _fsState._subtypedNameToFiles[name] = files;
      }
      files.add(this);
    }

    // Return how the file changed.
    if (apiSignatureChanged) {
      return FileStateRefreshResult.apiChanged;
    } else if (contentChanged) {
      return FileStateRefreshResult.contentChanged;
    } else {
      return FileStateRefreshResult.nothing;
    }
  }

  @override
  String toString() {
    return '$uri = $path';
  }

  /// Return the [FileState] for the given [relativeUri], or `null` if the
  /// URI cannot be parsed, cannot correspond any file, etc.
  Either2<FileState?, ExternalLibrary> _fileForRelativeUri(
    String relativeUri,
  ) {
    if (relativeUri.isEmpty) {
      return Either2.t1(null);
    }

    Uri absoluteUri;
    try {
      absoluteUri = resolveRelativeUri(uri, Uri.parse(relativeUri));
    } on FormatException {
      return Either2.t1(null);
    }

    return _fsState.getFileForUri(absoluteUri);
  }

  /// Return the unlinked unit, from bytes or new.
  AnalysisDriverUnlinkedUnit _getUnlinkedUnit() {
    final testData = _fsState.testData?.forFile(resource, uri);

    var bytes = _fsState._byteStore.get(_unlinkedKey!);
    if (bytes != null && bytes.isNotEmpty) {
      testData?.unlinkedKeyGet.add(unlinkedKey);
      return AnalysisDriverUnlinkedUnit.fromBytes(bytes);
    }

    var unit = parse();
    return _fsState._logger.run('Create unlinked for $path', () {
      var unlinkedUnit = serializeAstUnlinked2(
        unit,
        isDartCore: uriStr == 'dart:core',
      );
      var definedNames = computeDefinedNames(unit);
      var referencedNames = computeReferencedNames(unit);
      var subtypedNames = computeSubtypedNames(unit);
      var driverUnlinkedUnit = AnalysisDriverUnlinkedUnit(
        definedTopLevelNames: definedNames.topLevelNames,
        definedClassMemberNames: definedNames.classMemberNames,
        referencedNames: referencedNames,
        subtypedNames: subtypedNames,
        unit: unlinkedUnit,
      );
      var bytes = driverUnlinkedUnit.toBytes();
      _fsState._byteStore.putGet(_unlinkedKey!, bytes);
      testData?.unlinkedKeyPut.add(unlinkedKey);
      return driverUnlinkedUnit;
    });
  }

  /// Invalidate any data that depends on the current unlinked data of the file,
  /// because [refresh] is going to recompute the unlinked data.
  void _invalidateCurrentUnresolvedData() {
    if (_driverUnlinkedUnit != null) {
      for (var name in _driverUnlinkedUnit!.subtypedNames) {
        var files = _fsState._subtypedNameToFiles[name];
        files?.remove(this);
      }
    }
  }

  /// If this is a part, invalidate the libraries that use it.
  /// TODO(scheglov) Make it a method of `PartFileStateKind`?
  void _invalidatesLibrariesOfThisPart() {
    if (_kind is PartFileStateKind) {
      final libraries = _fsState._pathToFile.values
          .map((file) => file._kind)
          .whereType<LibraryFileStateKind>()
          .toList();

      for (final library in libraries) {
        for (final partDirective in library.parts) {
          if (partDirective is PartDirectiveWithFile) {
            if (partDirective.includedFile == this) {
              library._libraryCycle?.invalidate();
            }
          }
        }
      }
    }
  }

  CompilationUnitImpl _parse(AnalysisErrorListener errorListener) {
    return parse2(errorListener, content);
  }

  /// TODO(scheglov) write tests
  void _prefetchDirectReferences() {
    final prefetchFiles = _fsState.prefetchFiles;
    if (prefetchFiles == null) {
      return;
    }

    var paths = <String>{};

    void addRelativeUri(String relativeUriStr) {
      final Uri absoluteUri;
      try {
        final relativeUri = Uri.parse(relativeUriStr);
        absoluteUri = resolveRelativeUri(uri, relativeUri);
      } on FormatException {
        return;
      }
      final path = _fsState._sourceFactory.forUri2(absoluteUri)?.fullName;
      if (path != null) {
        paths.add(path);
      }
    }

    for (final directive in unlinked2.imports) {
      addRelativeUri(directive.uri);
    }
    for (final directive in unlinked2.exports) {
      addRelativeUri(directive.uri);
    }
    for (final directive in unlinked2.parts) {
      addRelativeUri(directive.uri);
    }

    prefetchFiles(paths.toList());
  }

  /// TODO(scheglov) move to _fsState?
  String _selectRelativeUri(UnlinkedNamespaceDirective directive) {
    for (var configuration in directive.configurations) {
      var name = configuration.name;
      var value = configuration.value;
      if (value.isEmpty) {
        value = 'true';
      }
      if (_fsState._declaredVariables.get(name) == value) {
        return configuration.uri;
      }
    }
    return directive.uri;
  }

  void _stopReferencingByThisFile() {
    void removeForOne(List<FileState?>? referencedFiles) {
      if (referencedFiles != null) {
        for (var referenced in referencedFiles) {
          referenced?.referencingFiles.remove(this);
        }
      }
    }

    removeForOne(_exportedFiles);
    removeForOne(_importedFiles);
  }

  void _updateKind() {
    _kind?.dispose();

    final libraryAugmentationDirective = unlinked2.libraryAugmentationDirective;
    final libraryDirective = unlinked2.libraryDirective;
    final partOfNameDirective = unlinked2.partOfNameDirective;
    final partOfUriDirective = unlinked2.partOfUriDirective;
    if (libraryAugmentationDirective != null) {
      final uri = libraryAugmentationDirective.uri;
      // TODO(scheglov) This could be a useful method of `Either`.
      final uriFile = _fileForRelativeUri(uri).map(
        (file) => file,
        (_) => null,
      );
      if (uriFile != null) {
        _kind = AugmentationKnownFileStateKind(
          file: this,
          directive: libraryAugmentationDirective,
          uriFile: uriFile,
        );
      } else {
        _kind = AugmentationUnknownFileStateKind(
          file: this,
          directive: libraryAugmentationDirective,
        );
      }
    } else if (libraryDirective != null) {
      final kind = _kind = LibraryFileStateKind(
        file: this,
        name: libraryDirective.name,
      );
      _fsState._libraryNameToFiles.add(kind);
    } else if (partOfNameDirective != null) {
      _kind = PartOfNameFileStateKind(
        file: this,
        directive: partOfNameDirective,
      );
    } else if (partOfUriDirective != null) {
      final uri = partOfUriDirective.uri;
      final uriFile = _fileForRelativeUri(uri).map(
        (file) => file,
        (_) => null,
      );
      if (uriFile != null) {
        _kind = PartOfUriKnownFileStateKind(
          file: this,
          directive: partOfUriDirective,
          uriFile: uriFile,
        );
      } else {
        _kind = PartOfUriUnknownFileStateKind(
          file: this,
          directive: partOfUriDirective,
        );
      }
    } else {
      _kind = LibraryFileStateKind(
        file: this,
        name: null,
      );
    }

    _invalidatesLibrariesOfThisPart();
  }

  static UnlinkedUnit serializeAstUnlinked2(
    CompilationUnit unit, {
    required bool isDartCore,
  }) {
    UnlinkedLibraryDirective? libraryDirective;
    UnlinkedLibraryAugmentationDirective? libraryAugmentationDirective;
    UnlinkedPartOfNameDirective? partOfNameDirective;
    UnlinkedPartOfUriDirective? partOfUriDirective;
    var augmentations = <UnlinkedImportAugmentationDirective>[];
    var exports = <UnlinkedNamespaceDirective>[];
    var imports = <UnlinkedNamespaceDirective>[];
    var parts = <UnlinkedPartDirective>[];
    var macroClasses = <MacroClass>[];
    var hasDartCoreImport = false;
    for (var directive in unit.directives) {
      if (directive is ExportDirective) {
        var builder = _serializeNamespaceDirective(directive);
        exports.add(builder);
      } else if (directive is ImportDirectiveImpl) {
        if (directive.augmentKeyword != null) {
          augmentations.add(
            UnlinkedImportAugmentationDirective(
              uri: directive.uri.stringValue ?? '',
            ),
          );
        } else {
          var builder = _serializeNamespaceDirective(directive);
          imports.add(builder);
          if (builder.uri == 'dart:core') {
            hasDartCoreImport = true;
          }
        }
      } else if (directive is LibraryAugmentationDirective) {
        final uri = directive.uri;
        final uriStr = uri.stringValue;
        if (uriStr != null) {
          libraryAugmentationDirective = UnlinkedLibraryAugmentationDirective(
            uri: uriStr,
            uriRange: UnlinkedSourceRange(
              offset: uri.offset,
              length: uri.length,
            ),
          );
        }
      } else if (directive is LibraryDirective) {
        libraryDirective = UnlinkedLibraryDirective(
          name: directive.name.name,
        );
      } else if (directive is PartDirective) {
        parts.add(
          UnlinkedPartDirective(
            uri: directive.uri.stringValue ?? '',
          ),
        );
      } else if (directive is PartOfDirective) {
        final libraryName = directive.libraryName;
        final uri = directive.uri;
        if (libraryName != null) {
          partOfNameDirective = UnlinkedPartOfNameDirective(
            name: libraryName.name,
            nameRange: UnlinkedSourceRange(
              offset: libraryName.offset,
              length: libraryName.length,
            ),
          );
        } else if (uri != null) {
          final uriStr = uri.stringValue;
          if (uriStr != null) {
            partOfUriDirective = UnlinkedPartOfUriDirective(
              uri: uriStr,
              uriRange: UnlinkedSourceRange(
                offset: uri.offset,
                length: uri.length,
              ),
            );
          }
        }
      }
    }
    for (var declaration in unit.declarations) {
      if (declaration is ClassDeclarationImpl) {
        if (declaration.macroKeyword != null) {
          var constructors = declaration.members
              .whereType<ConstructorDeclaration>()
              .map((e) => e.name?.name ?? '')
              .where((e) => !e.startsWith('_'))
              .toList();
          if (constructors.isNotEmpty) {
            macroClasses.add(
              MacroClass(
                name: declaration.name.name,
                constructors: constructors,
              ),
            );
          }
        }
      }
    }
    if (!isDartCore && !hasDartCoreImport) {
      imports.add(
        UnlinkedNamespaceDirective(
          configurations: [],
          isSyntheticDartCoreImport: true,
          uri: 'dart:core',
        ),
      );
    }

    final topLevelDeclarations = <String>{};
    for (final declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        topLevelDeclarations.add(declaration.name.name);
      } else if (declaration is EnumDeclaration) {
        topLevelDeclarations.add(declaration.name.name);
      } else if (declaration is ExtensionDeclaration) {
        var name = declaration.name;
        if (name != null) {
          topLevelDeclarations.add(name.name);
        }
      } else if (declaration is FunctionDeclaration) {
        topLevelDeclarations.add(declaration.name.name);
      } else if (declaration is MixinDeclaration) {
        topLevelDeclarations.add(declaration.name.name);
      } else if (declaration is TopLevelVariableDeclaration) {
        for (var variable in declaration.variables.variables) {
          topLevelDeclarations.add(variable.name.name);
        }
      }
    }

    return UnlinkedUnit(
      apiSignature: Uint8List.fromList(computeUnlinkedApiSignature(unit)),
      augmentations: augmentations,
      exports: exports,
      imports: imports,
      informativeBytes: writeUnitInformative(unit),
      libraryAugmentationDirective: libraryAugmentationDirective,
      libraryDirective: libraryDirective,
      lineStarts: Uint32List.fromList(unit.lineInfo.lineStarts),
      macroClasses: macroClasses,
      parts: parts,
      partOfNameDirective: partOfNameDirective,
      partOfUriDirective: partOfUriDirective,
      topLevelDeclarations: topLevelDeclarations,
    );
  }

  /// Return `true` if the given byte lists are equal.
  static bool _equalByteLists(List<int>? a, List<int>? b) {
    if (a == null) {
      return b == null;
    } else if (b == null) {
      return false;
    }
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  static UnlinkedNamespaceDirective _serializeNamespaceDirective(
      NamespaceDirective directive) {
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

abstract class FileStateKind {
  final FileState file;

  FileStateKind({
    required this.file,
  });

  /// When [library] returns `null`, this getter is used to look at this
  /// file itself as a library.
  LibraryFileStateKind get asLibrary {
    return LibraryFileStateKind(
      file: file,
      name: null,
    );
  }

  /// Returns the library in which this file should be analyzed.
  LibraryFileStateKind? get library;

  @mustCallSuper
  void dispose() {}
}

enum FileStateRefreshResult {
  /// No changes to the content, so no changes at all.
  nothing,

  /// The content changed, but the API of the file is the same.
  contentChanged,

  /// The content changed, and the API of the file is different.
  apiChanged,
}

@visibleForTesting
class FileStateTestView {
  final FileState file;

  FileStateTestView(this.file);

  String get unlinkedKey => file._unlinkedKey!;
}

/// Information about known file system state.
class FileSystemState {
  final PerformanceLog _logger;
  final ResourceProvider _resourceProvider;
  final String contextName;
  final ByteStore _byteStore;
  final SourceFactory _sourceFactory;
  final Workspace? _workspace;
  final DeclaredVariables _declaredVariables;
  final Uint32List _saltForUnlinked;
  final Uint32List _saltForElements;

  final FeatureSetProvider featureSetProvider;

  /// Mapping from a URI to the corresponding [FileState].
  final Map<Uri, FileState> _uriToFile = {};

  /// All known file paths.
  final Set<String> knownFilePaths = <String>{};

  /// All known files.
  final List<FileState> knownFiles = [];

  /// Mapping from a path to the flag whether there is a URI for the path.
  final Map<String, bool> _hasUriForPath = {};

  /// Mapping from a path to the corresponding [FileState].
  final Map<String, FileState> _pathToFile = {};

  /// Mapping from a library name to the [LibraryFileStateKind] that have it.
  final _LibraryNameToFiles _libraryNameToFiles = _LibraryNameToFiles();

  /// The map of subtyped names to files where these names are subtyped.
  final Map<String, Set<FileState>> _subtypedNameToFiles = {};

  /// The value of this field is incremented when the set of files is updated.
  int fileStamp = 0;

  final FileContentStrategy fileContentStrategy;

  /// A function that fetches the given list of files. This function can be used
  /// to batch file reads in systems where file fetches are expensive.
  final void Function(List<String> paths)? prefetchFiles;

  /// A function that returns true if the given file path is likely to be that
  /// of a file that is generated.
  final bool Function(String path) isGenerated;

  late final FileSystemStateTestView _testView;

  final FileSystemTestData? testData;

  FileSystemState(
    this._logger,
    this._byteStore,
    this._resourceProvider,
    this.contextName,
    this._sourceFactory,
    this._workspace,
    this._declaredVariables,
    this._saltForUnlinked,
    this._saltForElements,
    this.featureSetProvider, {
    required this.fileContentStrategy,
    required this.prefetchFiles,
    required this.isGenerated,
    required this.testData,
  }) {
    _testView = FileSystemStateTestView(this);
  }

  package_path.Context get pathContext => _resourceProvider.pathContext;

  @visibleForTesting
  FileSystemStateTestView get test => _testView;

  /// Update the state to reflect the fact that the file with the given [path]
  /// was changed. Specifically this means that we evict this file and every
  /// file that referenced it.
  void changeFile(String path, Set<FileState> removedFiles) {
    var file = _pathToFile.remove(path);
    if (file == null) {
      return;
    }

    if (!removedFiles.add(file)) {
      return;
    }

    _uriToFile.remove(file.uri);

    // The removed file does not reference other file anymore.
    for (var referencedFile in file.directReferencedFiles) {
      referencedFile.referencingFiles.remove(file);
    }

    // Recursively remove files that reference the removed file.
    for (var reference in file.referencingFiles.toList()) {
      changeFile(reference.path, removedFiles);
    }

    file._kind?.dispose();
  }

  /// Collected files that transitively reference a file with the [path].
  /// These files are potentially affected by the change.
  void collectAffected(String path, Set<FileState> affected) {
    // TODO(scheglov) This should not be necessary.
    // We use affected files to remove library elements, and we can only get
    // these library elements when we link or load them, using library cycles.
    // And we get library cycles by asking `directReferencedFiles`.
    for (var file in knownFiles.toList()) {
      file.directReferencedFiles;
    }

    collectAffected(FileState file) {
      if (affected.add(file)) {
        for (var other in file.referencingFiles) {
          collectAffected(other);
        }
      }
    }

    var file = _pathToFile[path];
    if (file != null) {
      collectAffected(file);
    }
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

  /// Notifies this object that it is about to be discarded.
  ///
  /// Returns the keys of the artifacts that are no longer used.
  Set<String> dispose() {
    final result = <String>{};
    for (final file in _pathToFile.values) {
      result.add(file._unlinkedKey!);
    }
    _pathToFile.clear();
    _uriToFile.clear();
    return result;
  }

  FileState? getExisting(File file) {
    return _pathToFile[file.path];
  }

  /// Return the [FileState] for the given absolute [path]. The returned file
  /// has the last known state since if was last refreshed.
  /// TODO(scheglov) Merge with [getFileForPath2].
  FileState getFileForPath(String path) {
    return getFileForPath2(
      path: path,
      performance: OperationPerformanceImpl('<root>'),
    );
  }

  /// Return the [FileState] for the given absolute [path]. The returned file
  /// has the last known state since if was last refreshed.
  FileState getFileForPath2({
    required String path,
    required OperationPerformanceImpl performance,
  }) {
    var file = _pathToFile[path];
    if (file == null) {
      File resource = _resourceProvider.getFile(path);
      Uri uri = _sourceFactory.pathToUri(path)!;
      file = _newFile(resource, path, uri);
    }
    return file;
  }

  /// The given [uri] must be absolute.
  ///
  /// If [uri] corresponds to a library from the summary store, return a
  /// [ExternalLibrary].
  ///
  /// Otherwise the [uri] is resolved to a file, and the corresponding
  /// [FileState] is returned. Might be `null` if the [uri] cannot be resolved
  /// to a file, for example because it is invalid (e.g. a `package:` URI
  /// without a package name), or we don't know this package. The returned
  /// file has the last known state since if was last refreshed.
  Either2<FileState?, ExternalLibrary> getFileForUri(Uri uri) {
    final uriSource = _sourceFactory.forUri2(uri);

    // If the external store has this URI, create a stub file for it.
    // We are given all required unlinked and linked summaries for it.
    if (uriSource is InSummarySource) {
      return Either2.t2(ExternalLibrary._(uriSource));
    }

    FileState? file = _uriToFile[uri];
    if (file == null) {
      // If the URI cannot be resolved, for example because the factory
      // does not understand the scheme, return the unresolved file instance.
      if (uriSource == null) {
        return Either2.t1(null);
      }

      String path = uriSource.fullName;

      // Check if already resolved to this path via different URI.
      // That different URI must be the canonical one.
      file = _pathToFile[path];
      if (file != null) {
        return Either2.t1(file);
      }

      File resource = _resourceProvider.getFile(path);

      var rewrittenUri = rewriteToCanonicalUri(_sourceFactory, uri);
      if (rewrittenUri == null) {
        return Either2.t1(null);
      }

      file = _newFile(resource, path, rewrittenUri);
    }
    return Either2.t1(file);
  }

  /// Returns a list of files whose contents contains the given string.
  /// Generated files are not included in the search.
  List<String> getFilesContaining(String value) {
    var result = <String>[];
    _pathToFile.forEach((path, file) {
      // TODO(scheglov) tests for excluding generated
      if (!isGenerated(path)) {
        if (file.content.contains(value)) {
          result.add(path);
        }
      }
    });
    return result;
  }

  /// Return files where the given [name] is subtyped, i.e. used in `extends`,
  /// `with` or `implements` clauses.
  Set<FileState>? getFilesSubtypingName(String name) {
    return _subtypedNameToFiles[name];
  }

  /// Return files that have a top-level declaration with the [name].
  List<FileState> getFilesWithTopLevelDeclarations(String name) {
    final result = <FileState>[];
    for (final file in _pathToFile.values) {
      if (file.unlinked2.topLevelDeclarations.contains(name)) {
        result.add(file);
      }
    }
    return result;
  }

  /// Return `true` if there is a URI that can be resolved to the [path].
  ///
  /// When a file exists, but for the URI that corresponds to the file is
  /// resolved to another file, e.g. a generated one in Bazel, Gn, etc, we
  /// cannot analyze the original file.
  bool hasUri(String path) {
    bool? flag = _hasUriForPath[path];
    if (flag == null) {
      Uri uri = _sourceFactory.pathToUri(path)!;
      Source? uriSource = _sourceFactory.forUri2(uri);
      flag = uriSource?.fullName == path;
      _hasUriForPath[path] = flag;
    }
    return flag;
  }

  /// When printing the state for testing, we want to see all files.
  @visibleForTesting
  void pullReferencedFiles() {
    while (true) {
      final fileCount = _pathToFile.length;
      for (final file in _pathToFile.values.toList()) {
        final kind = file.kind;
        if (kind is LibraryOrAugmentationFileKind) {
          kind.imports;
          kind.exports;
        }
      }
      if (_pathToFile.length == fileCount) {
        break;
      }
    }
  }

  /// Remove the file with the given [path].
  void removeFile(String path) {
    _clearFiles();
  }

  /// Computes the set of [FileState]'s used/not used to analyze the given
  /// [files]. Removes the [FileState]'s of the files not used for analysis from
  /// the cache. Returns the set of unused [FileState]'s.
  Set<FileState> removeUnusedFiles(List<String> files) {
    var allReferenced = <String>{};
    for (var path in files) {
      allReferenced.add(path);
      _pathToFile[path]?.collectAllReferencedFiles(allReferenced);
    }

    var unusedPaths = _pathToFile.keys.toSet();
    unusedPaths.removeAll(allReferenced);

    var removedFiles = <FileState>{};
    for (var path in unusedPaths) {
      changeFile(path, removedFiles);
    }

    return removedFiles;
  }

  /// Clear all [FileState] data - all maps from path or URI, etc.
  void _clearFiles() {
    _uriToFile.clear();
    knownFilePaths.clear();
    knownFiles.clear();
    _hasUriForPath.clear();
    _pathToFile.clear();
    _subtypedNameToFiles.clear();
    _libraryNameToFiles.clear();
  }

  FileState _newFile(File resource, String path, Uri uri) {
    FileSource uriSource = FileSource(resource, uri);
    WorkspacePackage? workspacePackage = _workspace?.findPackageFor(path);
    FeatureSet featureSet = contextFeatureSet(path, uri, workspacePackage);
    Version packageLanguageVersion =
        contextLanguageVersion(path, uri, workspacePackage);
    var file = FileState._(this, path, uri, uriSource, workspacePackage,
        featureSet, packageLanguageVersion);
    _pathToFile[path] = file;
    _uriToFile[uri] = file;
    knownFilePaths.add(path);
    knownFiles.add(file);
    fileStamp++;
    file.refresh();
    return file;
  }
}

@visibleForTesting
class FileSystemStateTestView {
  final FileSystemState state;

  FileSystemStateTestView(this.state);
}

class FileSystemTestData {
  final Map<File, FileTestData> files = {};

  FileTestData forFile(File file, Uri uri) {
    return files[file] ??= FileTestData._(file, uri);
  }
}

class FileTestData {
  final File file;
  final Uri uri;

  /// We add the key every time we get unlinked data from the byte store.
  final List<String> unlinkedKeyGet = [];

  /// We add the key every time we put unlinked data into the byte store.
  final List<String> unlinkedKeyPut = [];

  FileTestData._(this.file, this.uri);

  @override
  int get hashCode => file.hashCode;

  @override
  bool operator ==(Object other) {
    return other is FileTestData && other.file == file && other.uri == uri;
  }
}

/// Precomputed properties of a file URI, used because [Uri] is relatively
/// expensive to work with, if we do this thousand times.
class FileUriProperties {
  static const int _isDart = 1 << 0;
  static const int _isDartInternal = 1 << 1;
  static const int _isSrc = 1 << 2;

  final int _flags;
  final String? packageName;

  factory FileUriProperties(Uri uri) {
    if (uri.isScheme('dart')) {
      var dartName = uri.pathSegments.firstOrNull;
      return FileUriProperties._dart(
        isInternal: dartName != null && dartName.startsWith('_'),
      );
    } else if (uri.isScheme('package')) {
      var segments = uri.pathSegments;
      if (segments.length >= 2) {
        return FileUriProperties._package(
          packageName: segments[0],
          isSrc: segments[1] == 'src',
        );
      }
    }
    return const FileUriProperties._unknown();
  }

  const FileUriProperties._dart({
    required bool isInternal,
  })  : _flags = _isDart | (isInternal ? _isDartInternal : 0),
        packageName = null;

  FileUriProperties._package({
    required this.packageName,
    required bool isSrc,
  }) : _flags = isSrc ? _isSrc : 0;

  const FileUriProperties._unknown()
      : _flags = 0,
        packageName = null;

  bool get isDart => (_flags & _isDart) != 0;

  bool get isDartInternal => (_flags & _isDartInternal) != 0;

  bool get isSrc => (_flags & _isSrc) != 0;
}

/// Information about a single `import augment` directive.
class ImportAugmentationDirectiveState {
  final LibraryOrAugmentationFileKind container;
  final UnlinkedImportAugmentationDirective directive;

  ImportAugmentationDirectiveState({
    required this.container,
    required this.directive,
  });

  /// Returns a [Source] that is referenced by this directive.
  ///
  /// Returns `null` if the URI cannot be resolved into a [Source].
  Source? get importedSource => null;
}

/// [PartDirectiveState] that has a valid URI that references a file.
class ImportAugmentationDirectiveWithFile
    extends ImportAugmentationDirectiveState {
  final FileState importedFile;

  ImportAugmentationDirectiveWithFile({
    required super.container,
    required super.directive,
    required this.importedFile,
  });

  /// If [importedFile] is a [AugmentationFileStateKind], and it confirms that
  /// it is an augmentation of the [container], returns the [importedFile].
  AugmentationFileStateKind? get importedAugmentation {
    final kind = importedFile.kind;
    if (kind is AugmentationFileStateKind && kind.isAugmentationOf(container)) {
      return kind;
    }
    return null;
  }

  @override
  Source? get importedSource => importedFile.source;
}

/// Information about a single `import` directive.
class ImportDirectiveState {
  final UnlinkedNamespaceDirective directive;

  ImportDirectiveState({
    required this.directive,
  });

  /// If [importedSource] corresponds to a library, returns it.
  Source? get importedLibrarySource => null;

  /// Returns a [Source] that is referenced by this directive. If the are
  /// configurations, selects the one which satisfies the conditions.
  ///
  /// Returns `null` if the selected URI is not valid, or cannot be resolved
  /// into a [Source].
  Source? get importedSource => null;

  bool get isSyntheticDartCoreImport => directive.isSyntheticDartCoreImport;
}

/// [ImportDirectiveState] that has a valid URI that references a file.
class ImportDirectiveWithFile extends ImportDirectiveState {
  final FileState importedFile;

  ImportDirectiveWithFile({
    required super.directive,
    required this.importedFile,
  });

  /// Returns [importedFile] if it is a library.
  LibraryFileStateKind? get importedLibrary {
    final kind = importedFile.kind;
    if (kind is LibraryFileStateKind) {
      return kind;
    }
    return null;
  }

  @override
  Source? get importedLibrarySource {
    if (importedFile.kind is LibraryFileStateKind) {
      return importedSource;
    }
    return null;
  }

  @override
  Source get importedSource => importedFile.source;
}

/// [ImportDirectiveState] with a URI that resolves to [InSummarySource].
class ImportDirectiveWithInSummarySource extends ImportDirectiveState {
  @override
  final InSummarySource importedSource;

  ImportDirectiveWithInSummarySource({
    required super.directive,
    required this.importedSource,
  });

  @override
  Source? get importedLibrarySource {
    if (importedSource.kind == InSummarySourceKind.library) {
      return importedSource;
    } else {
      return null;
    }
  }
}

class LibraryFileStateKind extends LibraryOrAugmentationFileKind {
  /// The name of the library from the `library` directive.
  /// Or `null` if no `library` directive.
  final String? name;

  List<PartDirectiveState>? _parts;

  LibraryCycle? _libraryCycle;

  LibraryFileStateKind({
    required super.file,
    required this.name,
  });

  /// The list of files files that this library consists of, i.e. this library
  /// file itself, its [parts], and augmentations.
  List<FileState> get files {
    final files = [
      file,
    ];

    // TODO(scheglov) When we include only valid parts, use this instead.
    final includeOnlyValidParts = 0 > 1;
    for (final part in parts) {
      if (part is PartDirectiveWithFile) {
        if (includeOnlyValidParts) {
          files.addIfNotNull(part.includedPart?.file);
        } else {
          files.add(part.includedFile);
        }
      }
    }

    // TODO(scheglov) Include augmentations.
    return files;
  }

  LibraryCycle? get internal_libraryCycle => _libraryCycle;

  @override
  LibraryFileStateKind get library => this;

  /// Return the [LibraryCycle] this file belongs to, even if it consists of
  /// just this file.  If the library cycle is not known yet, compute it.
  LibraryCycle get libraryCycle {
    if (_libraryCycle == null) {
      computeLibraryCycle(file._fsState._saltForElements, this);
    }

    return _libraryCycle!;
  }

  List<PartDirectiveState> get parts {
    return _parts ??= file.unlinked2.parts.map((directive) {
      return file._fileForRelativeUri(directive.uri).map(
        (refFile) {
          if (refFile != null) {
            refFile.referencingFiles.add(file);
            return PartDirectiveWithFile(
              library: this,
              directive: directive,
              includedFile: refFile,
            );
          } else {
            return PartDirectiveState(
              library: this,
              directive: directive,
            );
          }
        },
        (externalLibrary) {
          return PartDirectiveState(
            library: this,
            directive: directive,
          );
        },
      );
    }).toList();
  }

  @override
  void discoverReferencedFiles() {
    super.discoverReferencedFiles();
    parts;
  }

  @override
  void dispose() {
    invalidateLibraryCycle();
    file._fsState._libraryNameToFiles.remove(this);

    final parts = _parts;
    if (parts != null) {
      for (final part in parts) {
        if (part is PartDirectiveWithFile) {
          part.includedFile.referencingFiles.remove(file);
        }
      }
    }

    super.dispose();
  }

  bool hasPart(PartFileStateKind partKind) {
    for (final partDirective in parts) {
      if (partDirective is PartDirectiveWithFile) {
        if (partDirective.includedFile == partKind.file) {
          return true;
        }
      }
    }
    return false;
  }

  void internal_setLibraryCycle(LibraryCycle? cycle) {
    _libraryCycle = cycle;
  }

  void invalidateLibraryCycle() {
    _libraryCycle?.invalidate();
    _libraryCycle = null;
  }
}

abstract class LibraryOrAugmentationFileKind extends FileStateKind {
  List<ImportAugmentationDirectiveState>? _augmentations;
  List<ExportDirectiveState>? _exports;
  List<ImportDirectiveState>? _imports;

  LibraryOrAugmentationFileKind({
    required super.file,
  });

  List<ImportAugmentationDirectiveState> get augmentations {
    return _augmentations ??= file.unlinked2.augmentations.map((directive) {
      return file._fileForRelativeUri(directive.uri).map(
        (refFile) {
          if (refFile != null) {
            refFile.referencingFiles.add(file);
            return ImportAugmentationDirectiveWithFile(
              container: this,
              directive: directive,
              importedFile: refFile,
            );
          } else {
            return ImportAugmentationDirectiveState(
              container: this,
              directive: directive,
            );
          }
        },
        (externalLibrary) {
          return ImportAugmentationDirectiveState(
            container: this,
            directive: directive,
          );
        },
      );
    }).toList();
  }

  List<ExportDirectiveState> get exports {
    return _exports ??= file.unlinked2.exports.map((directive) {
      final uriStr = file._selectRelativeUri(directive);
      return file._fileForRelativeUri(uriStr).map(
        (refFile) {
          if (refFile != null) {
            refFile.referencingFiles.add(file);
            return ExportDirectiveWithFile(
              directive: directive,
              exportedFile: refFile,
            );
          } else {
            return ExportDirectiveState(
              directive: directive,
            );
          }
        },
        (externalLibrary) {
          return ExportDirectiveWithInSummarySource(
            directive: directive,
            exportedSource: externalLibrary.source,
          );
        },
      );
    }).toList();
  }

  List<ImportDirectiveState> get imports {
    return _imports ??= file.unlinked2.imports.map((directive) {
      final uriStr = file._selectRelativeUri(directive);
      return file._fileForRelativeUri(uriStr).map(
        (refFile) {
          if (refFile != null) {
            refFile.referencingFiles.add(file);
            return ImportDirectiveWithFile(
              directive: directive,
              importedFile: refFile,
            );
          } else {
            return ImportDirectiveState(
              directive: directive,
            );
          }
        },
        (externalLibrary) {
          return ImportDirectiveWithInSummarySource(
            directive: directive,
            importedSource: externalLibrary.source,
          );
        },
      );
    }).toList();
  }

  /// Directives are usually pulled lazily (so that we can parse a file
  /// without pulling all its transitive references), but when we output
  /// textual dumps we want to check that we reference only objects that
  /// are available. So, we need to discover all referenced files before
  /// we register available objects.
  @visibleForTesting
  void discoverReferencedFiles() {
    exports;
    imports;
    for (final import in augmentations) {
      if (import is ImportAugmentationDirectiveWithFile) {
        import.importedAugmentation?.discoverReferencedFiles();
      }
    }
  }

  @override
  void dispose() {
    final augmentations = _augmentations;
    if (augmentations != null) {
      for (final import in augmentations) {
        if (import is ImportAugmentationDirectiveWithFile) {
          import.importedFile.referencingFiles.remove(file);
        }
      }
    }

    final exports = _exports;
    if (exports != null) {
      for (final export in exports) {
        if (export is ExportDirectiveWithFile) {
          export.exportedFile.referencingFiles.remove(file);
        }
      }
    }

    final imports = _imports;
    if (imports != null) {
      for (final import in imports) {
        if (import is ImportDirectiveWithFile) {
          import.importedFile.referencingFiles.remove(file);
        }
      }
    }

    super.dispose();
  }

  bool hasAugmentation(AugmentationFileStateKind augmentation) {
    for (final import in augmentations) {
      if (import is ImportAugmentationDirectiveWithFile) {
        if (import.importedFile == augmentation.file) {
          return true;
        }
      }
    }
    return false;
  }
}

/// Information about a single `part` directive.
class PartDirectiveState {
  final LibraryFileStateKind library;
  final UnlinkedPartDirective directive;

  PartDirectiveState({
    required this.library,
    required this.directive,
  });

  /// Returns a [Source] that is referenced by this directive.
  ///
  /// Returns `null` if the URI cannot be resolved into a [Source].
  Source? get includedSource => null;
}

/// [PartDirectiveState] that has a valid URI that references a file.
class PartDirectiveWithFile extends PartDirectiveState {
  final FileState includedFile;

  PartDirectiveWithFile({
    required super.library,
    required super.directive,
    required this.includedFile,
  });

  /// If [includedFile] is a [PartFileStateKind], and it confirms that it
  /// is a part of the [library], returns the [includedFile].
  PartFileStateKind? get includedPart {
    final kind = includedFile.kind;
    if (kind is PartFileStateKind && kind.isPartOf(library)) {
      return kind;
    }
    return null;
  }

  @override
  Source? get includedSource => includedFile.source;
}

/// The file has `part of` directive.
abstract class PartFileStateKind extends FileStateKind {
  PartFileStateKind({
    required super.file,
  });

  /// Returns `true` if the `part of` directive confirms the [library].
  bool isPartOf(LibraryFileStateKind library);
}

/// The file has `part of name` directive.
class PartOfNameFileStateKind extends PartFileStateKind {
  final UnlinkedPartOfNameDirective directive;

  PartOfNameFileStateKind({
    required super.file,
    required this.directive,
  });

  /// Libraries with the same name as in [directive].
  List<LibraryFileStateKind> get libraries {
    final files = file._fsState._libraryNameToFiles;
    return files[directive.name] ?? [];
  }

  /// If there are libraries that include this file as a part, return the
  /// first one as if sorted by path.
  @override
  LibraryFileStateKind? get library {
    discoverLibraries();

    LibraryFileStateKind? result;
    for (final library in libraries) {
      if (library.hasPart(this)) {
        if (result == null) {
          result = library;
        } else if (library.file.path.compareTo(result.file.path) < 0) {
          result = library;
        }
      }
    }
    return result;
  }

  @visibleForTesting
  void discoverLibraries() {
    if (libraries.isEmpty) {
      var resourceProvider = file._fsState._resourceProvider;
      var pathContext = resourceProvider.pathContext;

      var siblings = <Resource>[];
      try {
        siblings = file.resource.parent.getChildren();
      } catch (_) {}

      for (final sibling in siblings) {
        if (file_paths.isDart(pathContext, sibling.path)) {
          file._fsState.getFileForPath2(
            path: sibling.path,
            performance: OperationPerformanceImpl('<root>'),
          );
        }
      }
    }
  }

  @override
  bool isPartOf(LibraryFileStateKind library) {
    return directive.name == library.name;
  }
}

/// The file has `part of URI` directive.
abstract class PartOfUriFileStateKind extends PartFileStateKind {
  final UnlinkedPartOfUriDirective directive;

  PartOfUriFileStateKind({
    required super.file,
    required this.directive,
  });
}

/// The file has `part of URI` directive, and the URI can be resolved.
class PartOfUriKnownFileStateKind extends PartOfUriFileStateKind {
  final FileState uriFile;

  PartOfUriKnownFileStateKind({
    required super.file,
    required super.directive,
    required this.uriFile,
  });

  @override
  LibraryFileStateKind? get library {
    final uriKind = uriFile.kind;
    if (uriKind is LibraryFileStateKind) {
      if (uriKind.hasPart(this)) {
        return uriKind;
      }
    }
    return null;
  }

  @override
  bool isPartOf(LibraryFileStateKind library) {
    return uriFile == library.file;
  }
}

/// The file has `part of URI` directive, and the URI cannot be resolved.
class PartOfUriUnknownFileStateKind extends PartOfUriFileStateKind {
  PartOfUriUnknownFileStateKind({
    required super.file,
    required super.directive,
  });

  @override
  LibraryFileStateKind? get library => null;

  @override
  bool isPartOf(LibraryFileStateKind library) => false;
}

class StoredFileContent implements FileContent {
  @override
  final String content;

  @override
  final String contentHash;

  @override
  final bool exists;

  StoredFileContent({
    required this.content,
    required this.contentHash,
    required this.exists,
  });
}

class StoredFileContentStrategy implements FileContentStrategy {
  final FileContentCache _fileContentCache;

  StoredFileContentStrategy(this._fileContentCache);

  @override
  FileContent get(String path) {
    final fileContent = _fileContentCache.get(path);
    return StoredFileContent(
      content: fileContent.content,
      contentHash: fileContent.contentHash,
      exists: fileContent.exists,
    );
  }

  /// The file with the given [path] might have changed, so ensure that it is
  /// read the next time it is refreshed.
  void markFileForReading(String path) {
    _fileContentCache.invalidate(path);
  }
}

class _LibraryNameToFiles {
  final Map<String, List<LibraryFileStateKind>> _map = {};

  List<LibraryFileStateKind>? operator [](String name) {
    return _map[name];
  }

  /// If [kind] is a named library, register it.
  void add(LibraryFileStateKind kind) {
    final name = kind.name;
    if (name != null) {
      final libraries = _map[name] ??= [];
      libraries.add(kind);
    }
  }

  void clear() {
    _map.clear();
  }

  /// If [kind] is a named library, unregister it.
  void remove(LibraryFileStateKind kind) {
    final name = kind.name;
    if (name != null) {
      final libraries = _map[name];
      if (libraries != null) {
        libraries.remove(kind);
        if (libraries.isEmpty) {
          _map.remove(name);
        }
      }
    }
  }
}
