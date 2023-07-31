// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart';
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
import 'package:analyzer/src/dart/analysis/unlinked_unit_store.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/exception/exception.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary2/informative_data.dart';
import 'package:analyzer/src/util/either.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/util/uri.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as package_path;
import 'package:pub_semver/pub_semver.dart';

/// The file has a `library augment` directive.
abstract class AugmentationFileKind extends LibraryOrAugmentationFileKind {
  final UnlinkedLibraryAugmentationDirective unlinked;

  AugmentationFileKind({
    required super.file,
    required this.unlinked,
  });

  @override
  LibraryFileKind get asLibrary {
    // TODO(scheglov): implement asLibrary
    throw UnimplementedError();
  }

  /// Returns `true` if the `library augment` directive confirms [container].
  bool isAugmentationOf(LibraryOrAugmentationFileKind container);
}

/// Information about a single `import augment` directive.
class AugmentationImportState<U extends DirectiveUri> extends DirectiveState {
  final UnlinkedAugmentationImportDirective unlinked;
  final U uri;

  AugmentationImportState({
    required this.unlinked,
    required this.uri,
  });

  /// Returns a [Source] that is referenced by this directive.
  ///
  /// Returns `null` if the URI cannot be resolved into a [Source].
  Source? get importedSource => null;
}

/// [AugmentationImportWithUri] that has a valid URI that references a file.
class AugmentationImportWithFile
    extends AugmentationImportWithUri<DirectiveUriWithFile> {
  final LibraryOrAugmentationFileKind container;

  AugmentationImportWithFile({
    required this.container,
    required super.unlinked,
    required super.uri,
  }) {
    importedFile.referencingFiles.add(container.file);
  }

  /// If [importedFile] is an [AugmentationFileKind], and it confirms that
  /// it is an augmentation of the [container], returns the [importedFile].
  AugmentationFileKind? get importedAugmentation {
    final kind = importedFile.kind;
    if (kind is AugmentationFileKind && kind.isAugmentationOf(container)) {
      return kind;
    }
    return null;
  }

  FileState get importedFile => uri.file;

  @override
  Source get importedSource => importedFile.source;

  @override
  void dispose() {
    importedFile.referencingFiles.remove(container.file);
  }
}

/// [AugmentationImportState] that has a valid URI.
class AugmentationImportWithUri<U extends DirectiveUriWithUri>
    extends AugmentationImportWithUriStr<U> {
  AugmentationImportWithUri({
    required super.unlinked,
    required super.uri,
  });
}

/// [AugmentationImportState] that has a relative URI string.
class AugmentationImportWithUriStr<U extends DirectiveUriWithString>
    extends AugmentationImportState<U> {
  AugmentationImportWithUriStr({
    required super.unlinked,
    required super.uri,
  });
}

/// The URI of the [unlinked] can be resolved.
class AugmentationKnownFileKind extends AugmentationFileKind {
  /// The file that is referenced by the [unlinked].
  final FileState uriFile;

  AugmentationKnownFileKind({
    required super.file,
    required super.unlinked,
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
  LibraryFileKind? get library {
    final visited = Set<LibraryOrAugmentationFileKind>.identity();
    var current = augmented;
    while (current != null && visited.add(current)) {
      if (current is LibraryFileKind) {
        return current;
      } else if (current is AugmentationKnownFileKind) {
        current = current.augmented;
      } else {
        return null;
      }
    }
    return null;
  }

  @override
  void dispose() {
    super.dispose();
    invalidateLibraryCycle();
  }

  @override
  void invalidateLibraryCycle() {
    augmented?.invalidateLibraryCycle();
  }

  @override
  bool isAugmentationOf(LibraryOrAugmentationFileKind container) {
    return uriFile == container.file;
  }
}

/// The URI of the [unlinked] can not be resolved.
class AugmentationUnknownFileKind extends AugmentationFileKind {
  AugmentationUnknownFileKind({
    required super.file,
    required super.unlinked,
  });

  @override
  LibraryFileKind? get library => null;

  @override
  bool isAugmentationOf(LibraryOrAugmentationFileKind container) => false;
}

/// Information about a directive that "includes" a file - `import`, `export`,
/// or `part`. But not `part of` or `library augment` - these are modelled as
/// kinds.
class DirectiveState {
  void dispose() {}
}

/// Meaning of a URI referenced in a directive.
class DirectiveUri {
  Source? get source => null;
}

/// [DirectiveUriWithUri] with URI that resolves to a [FileState].
class DirectiveUriWithFile extends DirectiveUriWithSource {
  final FileState file;

  DirectiveUriWithFile({
    required super.relativeUriStr,
    required super.relativeUri,
    required this.file,
  });

  @override
  Source get source => file.source;

  @override
  String toString() => '$file';
}

/// [DirectiveUriWithSource] with a [InSummarySource].
class DirectiveUriWithInSummarySource extends DirectiveUriWithSource {
  @override
  final InSummarySource source;

  DirectiveUriWithInSummarySource({
    required super.relativeUriStr,
    required super.relativeUri,
    required this.source,
  });

  @override
  String toString() => '$source';
}

/// [DirectiveUriWithUri] that can be resolved into a [Source].
abstract class DirectiveUriWithSource extends DirectiveUriWithUri {
  DirectiveUriWithSource({
    required super.relativeUriStr,
    required super.relativeUri,
  });

  @override
  Source get source;

  @override
  String toString() => '$source';
}

/// [DirectiveUri] for which we can get its relative URI string.
class DirectiveUriWithString extends DirectiveUri {
  final String relativeUriStr;

  DirectiveUriWithString({
    required this.relativeUriStr,
  });

  @override
  String toString() => relativeUriStr;
}

/// [DirectiveUriWithString] that can be parsed into a relative URI.
class DirectiveUriWithUri extends DirectiveUriWithString {
  final Uri relativeUri;

  DirectiveUriWithUri({
    required super.relativeUriStr,
    required this.relativeUri,
  });

  @override
  String toString() => '$relativeUri';
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

abstract class FileKind {
  final FileState file;

  FileKind({
    required this.file,
  });

  /// When [library] returns `null`, this getter is used to look at this
  /// file itself as a library.
  LibraryFileKind get asLibrary {
    return LibraryFileKind(
      file: file,
      name: null,
    );
  }

  /// Returns the library in which this file should be analyzed.
  LibraryFileKind? get library;

  @mustCallSuper
  void dispose() {}
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

  FileKind? _kind;

  /// Files that reference this file.
  final Set<FileState> referencingFiles = {};

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

  /// Return `true` if the file exists.
  bool get exists => _fileContent!.exists;

  @override
  int get hashCode => uri.hashCode;

  FileKind get kind => _kind!;

  /// Return information about line in the file.
  LineInfo get lineInfo => _lineInfo!;

  /// The external names referenced by the file.
  Set<String> get referencedNames {
    return _driverUnlinkedUnit!.referencedNames;
  }

  File get resource {
    return _fsState.resourceProvider.getFile(path);
  }

  @visibleForTesting
  FileStateTestView get test => FileStateTestView(this);

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
    var previousUnlinkedKey = _unlinkedKey;
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
    _driverUnlinkedUnit = _getUnlinkedUnit(previousUnlinkedKey);
    _unlinked2 = _driverUnlinkedUnit!.unit;
    _lineInfo = LineInfo(_unlinked2!.lineStarts);

    _prefetchDirectReferences();

    // Prepare API signature.
    var newApiSignature = _unlinked2!.apiSignature;
    bool apiSignatureChanged = _apiSignature != null &&
        !_equalByteLists(_apiSignature, newApiSignature);
    _apiSignature = newApiSignature;

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

  DirectiveUri _buildDirectiveUri(String? relativeUriStr) {
    if (relativeUriStr == null) {
      return DirectiveUri();
    }

    final relativeUri = uriCache.tryParse(relativeUriStr);
    if (relativeUri == null) {
      return DirectiveUriWithString(
        relativeUriStr: relativeUriStr,
      );
    }

    final absoluteUri = uriCache.resolveRelative(uri, relativeUri);
    return _fsState.getFileForUri(absoluteUri).map(
      (file) {
        if (file != null) {
          return DirectiveUriWithFile(
            relativeUriStr: relativeUriStr,
            relativeUri: relativeUri,
            file: file,
          );
        } else {
          return DirectiveUriWithUri(
            relativeUriStr: relativeUriStr,
            relativeUri: relativeUri,
          );
        }
      },
      (externalLibrary) {
        return DirectiveUriWithInSummarySource(
          relativeUriStr: relativeUriStr,
          relativeUri: relativeUri,
          source: externalLibrary.source,
        );
      },
    );
  }

  /// TODO(scheglov) move to _fsState?
  NamespaceDirectiveUris _buildNamespaceDirectiveUris(
    UnlinkedNamespaceDirective directive,
  ) {
    final primaryUri = _buildDirectiveUri(directive.uri);

    DirectiveUri? selectedConfigurationUri;
    final configurationUris = directive.configurations.map((configuration) {
      final configurationUri = _buildDirectiveUri(configuration.uri);
      // Maybe select this URI.
      final name = configuration.name;
      final value = configuration.valueOrTrue;
      if (_fsState._declaredVariables.get(name) == value) {
        selectedConfigurationUri ??= configurationUri;
      }
      // Include it anyway.
      return configurationUri;
    }).toFixedList();

    return NamespaceDirectiveUris(
      primary: primaryUri,
      configurations: configurationUris,
      selected: selectedConfigurationUri ?? primaryUri,
    );
  }

  /// Return the [FileState] for the given [relativeUriStr], or `null` if the
  /// URI cannot be parsed, cannot correspond any file, etc.
  Either2<FileState?, ExternalLibrary> _fileForRelativeUri(
    String relativeUriStr,
  ) {
    Uri absoluteUri;
    try {
      var relativeUri = uriCache.parse(relativeUriStr);
      absoluteUri = uriCache.resolveRelative(uri, relativeUri);
    } on FormatException {
      return Either2.t1(null);
    }

    return _fsState.getFileForUri(absoluteUri);
  }

  /// Return the unlinked unit, freshly deserialized from bytes,
  /// previously deserialized from bytes, or new.
  AnalysisDriverUnlinkedUnit _getUnlinkedUnit(String? previousUnlinkedKey) {
    if (previousUnlinkedKey != null) {
      if (previousUnlinkedKey != _unlinkedKey) {
        _fsState.unlinkedUnitStore.release(previousUnlinkedKey);
      } else {
        return _driverUnlinkedUnit!;
      }
    }

    final testData = _fsState.testData?.forFile(resource, uri);
    var fromStore = _fsState.unlinkedUnitStore.get(_unlinkedKey!);
    if (fromStore != null) {
      testData?.unlinkedKeyGet.add(unlinkedKey);
      return fromStore;
    }

    var bytes = _fsState._byteStore.get(_unlinkedKey!);
    if (bytes != null && bytes.isNotEmpty) {
      testData?.unlinkedKeyGet.add(unlinkedKey);
      var result = AnalysisDriverUnlinkedUnit.fromBytes(bytes);
      _fsState.unlinkedUnitStore.put(_unlinkedKey!, result);
      return result;
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

  CompilationUnitImpl _parse(AnalysisErrorListener errorListener) {
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

    // Ensure the string canonicalization cache size is reasonable.
    pruneStringCanonicalizationCache();

    return unit;
  }

  /// TODO(scheglov) write tests
  void _prefetchDirectReferences() {
    final prefetchFiles = _fsState.prefetchFiles;
    if (prefetchFiles == null) {
      return;
    }

    var paths = <String>{};

    void addRelativeUri(String? relativeUriStr) {
      if (relativeUriStr == null) {
        return;
      }
      final Uri absoluteUri;
      try {
        final relativeUri = uriCache.parse(relativeUriStr);
        absoluteUri = uriCache.resolveRelative(uri, relativeUri);
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

  void _updateKind() {
    _kind?.dispose();

    final libraryAugmentationDirective = unlinked2.libraryAugmentationDirective;
    final libraryDirective = unlinked2.libraryDirective;
    final partOfNameDirective = unlinked2.partOfNameDirective;
    final partOfUriDirective = unlinked2.partOfUriDirective;
    if (libraryAugmentationDirective != null) {
      final uriStr = libraryAugmentationDirective.uri;
      // TODO(scheglov) This could be a useful method of `Either`.
      final uriFile = uriStr != null
          ? _fileForRelativeUri(uriStr).map(
              (file) => file,
              (_) => null,
            )
          : null;
      if (uriFile != null) {
        _kind = AugmentationKnownFileKind(
          file: this,
          unlinked: libraryAugmentationDirective,
          uriFile: uriFile,
        );
      } else {
        _kind = AugmentationUnknownFileKind(
          file: this,
          unlinked: libraryAugmentationDirective,
        );
      }
    } else if (libraryDirective != null) {
      _kind = LibraryFileKind(
        file: this,
        name: libraryDirective.name,
      );
    } else if (partOfNameDirective != null) {
      _kind = PartOfNameFileKind(
        file: this,
        unlinked: partOfNameDirective,
      );
    } else if (partOfUriDirective != null) {
      final uriStr = partOfUriDirective.uri;
      final uriFile = uriStr != null
          ? _fileForRelativeUri(uriStr).map(
              (file) => file,
              (_) => null,
            )
          : null;
      if (uriFile != null) {
        _kind = PartOfUriKnownFileKind(
          file: this,
          unlinked: partOfUriDirective,
          uriFile: uriFile,
        );
      } else {
        _kind = PartOfUriUnknownFileKind(
          file: this,
          unlinked: partOfUriDirective,
        );
      }
    } else {
      _kind = LibraryFileKind(
        file: this,
        name: null,
      );
    }
  }

  static UnlinkedUnit serializeAstUnlinked2(
    CompilationUnit unit, {
    required bool isDartCore,
  }) {
    UnlinkedLibraryDirective? libraryDirective;
    UnlinkedLibraryAugmentationDirective? libraryAugmentationDirective;
    UnlinkedPartOfNameDirective? partOfNameDirective;
    UnlinkedPartOfUriDirective? partOfUriDirective;
    var augmentations = <UnlinkedAugmentationImportDirective>[];
    var exports = <UnlinkedLibraryExportDirective>[];
    var imports = <UnlinkedLibraryImportDirective>[];
    var parts = <UnlinkedPartDirective>[];
    var macroClasses = <MacroClass>[];
    var hasDartCoreImport = false;
    for (var directive in unit.directives) {
      if (directive is ExportDirective) {
        var builder = _serializeExport(directive);
        exports.add(builder);
      } else if (directive is AugmentationImportDirectiveImpl) {
        augmentations.add(
          UnlinkedAugmentationImportDirective(
            augmentKeywordOffset: directive.augmentKeyword.offset,
            importKeywordOffset: directive.importKeyword.offset,
            uri: directive.uri.stringValue,
          ),
        );
      } else if (directive is ImportDirectiveImpl) {
        var builder = _serializeImport(directive);
        imports.add(builder);
        if (builder.uri == 'dart:core') {
          hasDartCoreImport = true;
        }
      } else if (directive is LibraryAugmentationDirective) {
        final uri = directive.uri;
        final uriStr = uri.stringValue;
        if (uriStr != null) {
          libraryAugmentationDirective = UnlinkedLibraryAugmentationDirective(
            augmentKeywordOffset: directive.augmentKeyword.offset,
            libraryKeywordOffset: directive.libraryKeyword.offset,
            uri: uriStr,
            uriRange: UnlinkedSourceRange(
              offset: uri.offset,
              length: uri.length,
            ),
          );
        }
      } else if (directive is LibraryDirective) {
        libraryDirective = UnlinkedLibraryDirective(
          name: directive.name2?.name,
        );
      } else if (directive is PartDirective) {
        parts.add(
          UnlinkedPartDirective(
            uri: directive.uri.stringValue,
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
              .map((e) => e.name?.lexeme ?? '')
              .where((e) => !e.startsWith('_'))
              .toFixedList();
          if (constructors.isNotEmpty) {
            macroClasses.add(
              MacroClass(
                name: declaration.name.lexeme,
                constructors: constructors,
              ),
            );
          }
        }
      }
    }
    if (!isDartCore && !hasDartCoreImport) {
      imports.add(
        UnlinkedLibraryImportDirective(
          combinators: const [],
          configurations: const [],
          importKeywordOffset: -1,
          isSyntheticDartCore: true,
          prefix: null,
          uri: 'dart:core',
        ),
      );
    }

    final topLevelDeclarations = <String>{};
    for (final declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        topLevelDeclarations.add(declaration.name.lexeme);
      } else if (declaration is EnumDeclaration) {
        topLevelDeclarations.add(declaration.name.lexeme);
      } else if (declaration is ExtensionDeclaration) {
        var name = declaration.name;
        if (name != null) {
          topLevelDeclarations.add(name.lexeme);
        }
      } else if (declaration is FunctionDeclaration) {
        topLevelDeclarations.add(declaration.name.lexeme);
      } else if (declaration is MixinDeclaration) {
        topLevelDeclarations.add(declaration.name.lexeme);
      } else if (declaration is TopLevelVariableDeclaration) {
        for (var variable in declaration.variables.variables) {
          topLevelDeclarations.add(variable.name.lexeme);
        }
      }
    }

    return UnlinkedUnit(
      apiSignature: Uint8List.fromList(computeUnlinkedApiSignature(unit)),
      augmentations: augmentations.toFixedList(),
      exports: exports.toFixedList(),
      imports: imports.toFixedList(),
      informativeBytes: writeUnitInformative(unit),
      libraryAugmentationDirective: libraryAugmentationDirective,
      libraryDirective: libraryDirective,
      lineStarts: Uint32List.fromList(unit.lineInfo.lineStarts),
      macroClasses: macroClasses.toFixedList(),
      parts: parts.toFixedList(),
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

  static List<UnlinkedCombinator> _serializeCombinators(
    List<Combinator> combinators,
  ) {
    return combinators.map((combinator) {
      if (combinator is ShowCombinator) {
        return UnlinkedCombinator(
          keywordOffset: combinator.keyword.offset,
          endOffset: combinator.end,
          isShow: true,
          names: combinator.shownNames.map((e) => e.name).toFixedList(),
        );
      } else {
        combinator as HideCombinator;
        return UnlinkedCombinator(
          keywordOffset: combinator.keyword.offset,
          endOffset: combinator.end,
          isShow: false,
          names: combinator.hiddenNames.map((e) => e.name).toFixedList(),
        );
      }
    }).toFixedList();
  }

  static List<UnlinkedNamespaceDirectiveConfiguration> _serializeConfigurations(
    List<Configuration> configurations,
  ) {
    return configurations.map((configuration) {
      var name = configuration.name.components.join('.');
      var value = configuration.value?.stringValue ?? '';
      return UnlinkedNamespaceDirectiveConfiguration(
        name: name,
        value: value,
        uri: configuration.uri.stringValue,
      );
    }).toFixedList();
  }

  static UnlinkedLibraryExportDirective _serializeExport(ExportDirective node) {
    return UnlinkedLibraryExportDirective(
      combinators: _serializeCombinators(node.combinators),
      configurations: _serializeConfigurations(node.configurations),
      exportKeywordOffset: node.exportKeyword.offset,
      uri: node.uri.stringValue,
    );
  }

  static UnlinkedLibraryImportDirective _serializeImport(ImportDirective node) {
    UnlinkedLibraryImportPrefix? unlinkedPrefix;
    final prefix = node.prefix;
    if (prefix != null) {
      unlinkedPrefix = UnlinkedLibraryImportPrefix(
        deferredOffset: node.deferredKeyword?.offset,
        asOffset: node.asKeyword!.offset,
        name: prefix.name,
        nameOffset: prefix.offset,
      );
    }

    return UnlinkedLibraryImportDirective(
      combinators: _serializeCombinators(node.combinators),
      configurations: _serializeConfigurations(node.configurations),
      importKeywordOffset: node.importKeyword.offset,
      uri: node.uri.stringValue,
      prefix: unlinkedPrefix,
    );
  }
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
  final ResourceProvider resourceProvider;
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

  /// Mapping from a library name to the [LibraryFileKind] that have it.
  final _LibraryNameToFiles _libraryNameToFiles = _LibraryNameToFiles();

  /// The map of subtyped names to files where these names are subtyped.
  final Map<String, Set<FileState>> _subtypedNameToFiles = {};

  /// The value of this field is incremented when the set of files is updated.
  int fileStamp = 0;

  final FileContentStrategy fileContentStrategy;
  final UnlinkedUnitStore unlinkedUnitStore;

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
    this.resourceProvider,
    this.contextName,
    this._sourceFactory,
    this._workspace,
    this._declaredVariables,
    this._saltForUnlinked,
    this._saltForElements,
    this.featureSetProvider, {
    required this.fileContentStrategy,
    required this.unlinkedUnitStore,
    required this.prefetchFiles,
    required this.isGenerated,
    required this.testData,
  }) {
    _testView = FileSystemStateTestView(this);
  }

  package_path.Context get pathContext => resourceProvider.pathContext;

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

    // The removed file does not reference other files anymore.
    file._kind?.dispose();

    // Recursively remove files that reference the removed file.
    for (var reference in file.referencingFiles.toList()) {
      changeFile(reference.path, removedFiles);
    }
  }

  /// Collected files that transitively reference a file with the [path].
  /// These files are potentially affected by the change.
  void collectAffected(String path, Set<FileState> affected) {
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

  FileState? getExistingFromPath(String path) {
    return _pathToFile[path];
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
      File resource = resourceProvider.getFile(path);
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

      File resource = resourceProvider.getFile(path);

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
  /// resolved to another file, e.g. a generated one in Blaze, Gn, etc, we
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
          kind.libraryImports;
          kind.libraryExports;
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
  /// [paths]. Removes the [FileState]'s of the files not used for analysis from
  /// the cache. Returns the set of unused [FileState]'s.
  Set<FileState> removeUnusedFiles(List<String> paths) {
    final referenced = <FileState>{};
    for (final path in paths) {
      final library = _pathToFile[path]?.kind.library;
      library?.collectTransitive(referenced);
    }

    final removed = <FileState>{};
    for (final file in _pathToFile.values.toList()) {
      if (!referenced.contains(file)) {
        changeFile(file.path, removed);
      }
    }

    return removed;
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
    // TODO(jensj): If we use finalizers we shouldn't clear.
    unlinkedUnitStore.clear();
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

/// Information about a single `export` directive.
class LibraryExportState<U extends DirectiveUri> extends DirectiveState {
  final UnlinkedLibraryExportDirective unlinked;
  final U selectedUri;
  final NamespaceDirectiveUris uris;

  LibraryExportState({
    required this.unlinked,
    required this.selectedUri,
    required this.uris,
  });

  /// If [exportedSource] corresponds to a library, returns it.
  Source? get exportedLibrarySource => null;

  /// Returns a [Source] that is referenced by this directive. If there are
  /// configurations, selects the one which satisfies the conditions.
  ///
  /// Returns `null` if the selected URI is not valid, or cannot be resolved
  /// into a [Source].
  Source? get exportedSource => null;
}

/// [LibraryExportWithUri] that has a valid URI that references a file.
class LibraryExportWithFile extends LibraryExportWithUri<DirectiveUriWithFile> {
  final LibraryOrAugmentationFileKind container;

  LibraryExportWithFile({
    required this.container,
    required super.unlinked,
    required super.selectedUri,
    required super.uris,
  }) {
    exportedFile.referencingFiles.add(container.file);
  }

  FileState get exportedFile => selectedUri.file;

  /// Returns [exportedFile] if it is a library.
  LibraryFileKind? get exportedLibrary {
    final kind = exportedFile.kind;
    if (kind is LibraryFileKind) {
      return kind;
    }
    return null;
  }

  @override
  Source? get exportedLibrarySource {
    if (exportedFile.kind is LibraryFileKind) {
      return exportedSource;
    }
    return null;
  }

  @override
  Source get exportedSource => exportedFile.source;

  @override
  void dispose() {
    exportedFile.referencingFiles.remove(container.file);
  }
}

/// [LibraryExportWithUri] with a URI that resolves to [InSummarySource].
class LibraryExportWithInSummarySource
    extends LibraryExportWithUri<DirectiveUriWithInSummarySource> {
  LibraryExportWithInSummarySource({
    required super.unlinked,
    required super.selectedUri,
    required super.uris,
  });

  @override
  Source? get exportedLibrarySource {
    if (exportedSource.kind == InSummarySourceKind.library) {
      return exportedSource;
    } else {
      return null;
    }
  }

  @override
  InSummarySource get exportedSource => selectedUri.source;
}

/// [LibraryExportState] that has a valid URI.
class LibraryExportWithUri<U extends DirectiveUriWithUri>
    extends LibraryExportWithUriStr<U> {
  LibraryExportWithUri({
    required super.unlinked,
    required super.selectedUri,
    required super.uris,
  });
}

/// [LibraryExportState] that has a relative URI string.
class LibraryExportWithUriStr<U extends DirectiveUriWithString>
    extends LibraryExportState<U> {
  LibraryExportWithUriStr({
    required super.unlinked,
    required super.selectedUri,
    required super.uris,
  });
}

class LibraryFileKind extends LibraryOrAugmentationFileKind {
  /// The name of the library from the `library` directive.
  /// Or `null` if no `library` directive.
  final String? name;

  List<PartState>? _parts;

  LibraryCycle? _libraryCycle;

  LibraryFileKind({
    required super.file,
    required this.name,
  }) {
    file._fsState._libraryNameToFiles.add(this);
  }

  /// All augmentations of this library, in the depth-first pre-order order.
  List<AugmentationFileKind> get augmentations {
    final result = <AugmentationFileKind>[];

    void visitAugmentations(LibraryOrAugmentationFileKind kind) {
      if (kind is AugmentationFileKind) {
        result.add(kind);
      }
      for (final import in kind.augmentationImports) {
        if (import is AugmentationImportWithFile) {
          final augmentation = import.importedAugmentation;
          if (augmentation != null) {
            visitAugmentations(augmentation);
          }
        }
      }
    }

    visitAugmentations(this);
    return result;
  }

  /// The list of files that this library consists of, i.e. this library file
  /// itself, its [parts], and augmentations.
  List<FileState> get files {
    return [
      file,
      ...parts
          .whereType<PartWithFile>()
          .map((partState) => partState.includedPart)
          .whereNotNull()
          .map((partKind) => partKind.file),
      ...augmentations.map((e) => e.file),
    ];
  }

  LibraryCycle? get internal_libraryCycle => _libraryCycle;

  @override
  LibraryFileKind get library => this;

  /// Return the [LibraryCycle] this file belongs to, even if it consists of
  /// just this file.  If the library cycle is not known yet, compute it.
  LibraryCycle get libraryCycle {
    if (_libraryCycle == null) {
      computeLibraryCycle(file._fsState._saltForElements, this);
    }

    return _libraryCycle!;
  }

  List<PartState> get parts {
    return _parts ??= file.unlinked2.parts.map((unlinked) {
      final uri = file._buildDirectiveUri(unlinked.uri);
      if (uri is DirectiveUriWithFile) {
        return PartWithFile(
          library: this,
          unlinked: unlinked,
          uri: uri,
        );
      } else if (uri is DirectiveUriWithUri) {
        return PartWithUri(
          library: this,
          unlinked: unlinked,
          uri: uri,
        );
      } else if (uri is DirectiveUriWithString) {
        return PartWithUriStr(
          library: this,
          unlinked: unlinked,
          uri: uri,
        );
      } else {
        return PartState(
          library: this,
          unlinked: unlinked,
          uri: uri,
        );
      }
    }).toFixedList();
  }

  @override
  void collectTransitive(Set<FileState> files) {
    super.collectTransitive(files);
    for (final part in parts) {
      if (part is PartWithFile) {
        files.add(part.includedFile);
      }
    }
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
    _parts?.disposeAll();
    super.dispose();
  }

  bool hasPart(PartFileKind partKind) {
    for (final partDirective in parts) {
      if (partDirective is PartWithFile) {
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

  @override
  void invalidateLibraryCycle() {
    _libraryCycle?.invalidate();
    _libraryCycle = null;
  }
}

/// Information about a single `import` directive.
class LibraryImportState<U extends DirectiveUri> extends DirectiveState {
  final UnlinkedLibraryImportDirective unlinked;
  final U selectedUri;
  final NamespaceDirectiveUris uris;

  LibraryImportState({
    required this.unlinked,
    required this.selectedUri,
    required this.uris,
  });

  /// If [importedSource] corresponds to a library, returns it.
  Source? get importedLibrarySource => null;

  /// Returns a [Source] that is referenced by this directive. If there are
  /// configurations, selects the one which satisfies the conditions.
  ///
  /// Returns `null` if the selected URI is not valid, or cannot be resolved
  /// into a [Source].
  Source? get importedSource => null;

  bool get isSyntheticDartCore => unlinked.isSyntheticDartCore;
}

/// [LibraryImportWithUri] that has a valid URI that references a file.
class LibraryImportWithFile extends LibraryImportWithUri<DirectiveUriWithFile> {
  final LibraryOrAugmentationFileKind container;

  LibraryImportWithFile({
    required this.container,
    required super.unlinked,
    required super.selectedUri,
    required super.uris,
  }) {
    importedFile.referencingFiles.add(container.file);
  }

  FileState get importedFile => selectedUri.file;

  /// Returns [importedFile] if it is a library.
  LibraryFileKind? get importedLibrary {
    final kind = importedFile.kind;
    if (kind is LibraryFileKind) {
      return kind;
    }
    return null;
  }

  @override
  Source? get importedLibrarySource {
    if (importedFile.kind is LibraryFileKind) {
      return importedSource;
    }
    return null;
  }

  @override
  Source get importedSource => importedFile.source;

  @override
  void dispose() {
    importedFile.referencingFiles.remove(container.file);
  }
}

/// [LibraryImportWithUri] with a URI that resolves to [InSummarySource].
class LibraryImportWithInSummarySource
    extends LibraryImportWithUri<DirectiveUriWithInSummarySource> {
  LibraryImportWithInSummarySource({
    required super.unlinked,
    required super.selectedUri,
    required super.uris,
  });

  @override
  Source? get importedLibrarySource {
    if (importedSource.kind == InSummarySourceKind.library) {
      return importedSource;
    } else {
      return null;
    }
  }

  @override
  InSummarySource get importedSource => selectedUri.source;
}

/// [LibraryImportState] that has a valid URI.
class LibraryImportWithUri<U extends DirectiveUriWithUri>
    extends LibraryImportWithUriStr<U> {
  LibraryImportWithUri({
    required super.unlinked,
    required super.selectedUri,
    required super.uris,
  });
}

/// [LibraryImportState] that has a relative URI string.
class LibraryImportWithUriStr<U extends DirectiveUriWithString>
    extends LibraryImportState<U> {
  LibraryImportWithUriStr({
    required super.unlinked,
    required super.selectedUri,
    required super.uris,
  });
}

abstract class LibraryOrAugmentationFileKind extends FileKind {
  List<AugmentationImportState>? _augmentationImports;
  List<LibraryExportState>? _libraryExports;
  List<LibraryImportState>? _libraryImports;

  LibraryOrAugmentationFileKind({
    required super.file,
  });

  List<AugmentationImportState> get augmentationImports {
    return _augmentationImports ??=
        file.unlinked2.augmentations.map((unlinked) {
      final uri = file._buildDirectiveUri(unlinked.uri);
      if (uri is DirectiveUriWithFile) {
        return AugmentationImportWithFile(
          container: this,
          unlinked: unlinked,
          uri: uri,
        );
      } else if (uri is DirectiveUriWithUri) {
        return AugmentationImportWithUri(
          unlinked: unlinked,
          uri: uri,
        );
      } else if (uri is DirectiveUriWithString) {
        return AugmentationImportWithUriStr(
          unlinked: unlinked,
          uri: uri,
        );
      } else {
        return AugmentationImportState(
          unlinked: unlinked,
          uri: uri,
        );
      }
    }).toFixedList();
  }

  List<LibraryExportState> get libraryExports {
    return _libraryExports ??=
        file.unlinked2.exports.map<LibraryExportState>((unlinked) {
      final uris = file._buildNamespaceDirectiveUris(unlinked);
      final selectedUri = uris.selected;
      if (selectedUri is DirectiveUriWithFile) {
        return LibraryExportWithFile(
          container: this,
          unlinked: unlinked,
          selectedUri: selectedUri,
          uris: uris,
        );
      } else if (selectedUri is DirectiveUriWithInSummarySource) {
        return LibraryExportWithInSummarySource(
          unlinked: unlinked,
          selectedUri: selectedUri,
          uris: uris,
        );
      } else if (selectedUri is DirectiveUriWithUri) {
        return LibraryExportWithUri(
          unlinked: unlinked,
          selectedUri: selectedUri,
          uris: uris,
        );
      } else if (selectedUri is DirectiveUriWithString) {
        return LibraryExportWithUriStr(
          unlinked: unlinked,
          selectedUri: selectedUri,
          uris: uris,
        );
      } else {
        return LibraryExportState(
          unlinked: unlinked,
          selectedUri: selectedUri,
          uris: uris,
        );
      }
    }).toFixedList();
  }

  List<LibraryImportState> get libraryImports {
    return _libraryImports ??=
        file.unlinked2.imports.map<LibraryImportState>((unlinked) {
      final uris = file._buildNamespaceDirectiveUris(unlinked);
      final selectedUri = uris.selected;
      if (selectedUri is DirectiveUriWithFile) {
        return LibraryImportWithFile(
          container: this,
          unlinked: unlinked,
          selectedUri: selectedUri,
          uris: uris,
        );
      } else if (selectedUri is DirectiveUriWithInSummarySource) {
        return LibraryImportWithInSummarySource(
          unlinked: unlinked,
          selectedUri: selectedUri,
          uris: uris,
        );
      } else if (selectedUri is DirectiveUriWithUri) {
        return LibraryImportWithUri(
          unlinked: unlinked,
          selectedUri: selectedUri,
          uris: uris,
        );
      } else if (selectedUri is DirectiveUriWithString) {
        return LibraryImportWithUriStr(
          unlinked: unlinked,
          selectedUri: selectedUri,
          uris: uris,
        );
      } else {
        return LibraryImportState(
          unlinked: unlinked,
          selectedUri: selectedUri,
          uris: uris,
        );
      }
    }).toFixedList();
  }

  /// Collect files that are transitively referenced by this library.
  @mustCallSuper
  void collectTransitive(Set<FileState> files) {
    if (files.add(file)) {
      for (final augmentation in augmentationImports) {
        if (augmentation is AugmentationImportWithFile) {
          augmentation.importedAugmentation?.collectTransitive(files);
        }
      }
      for (final export in libraryExports) {
        if (export is LibraryExportWithFile) {
          export.exportedLibrary?.collectTransitive(files);
        }
      }
      for (final import in libraryImports) {
        if (import is LibraryImportWithFile) {
          import.importedLibrary?.collectTransitive(files);
        }
      }
    }
  }

  /// Directives are usually pulled lazily (so that we can parse a file
  /// without pulling all its transitive references), but when we output
  /// textual dumps we want to check that we reference only objects that
  /// are available. So, we need to discover all referenced files before
  /// we register available objects.
  @visibleForTesting
  void discoverReferencedFiles() {
    libraryExports;
    libraryImports;
    for (final import in augmentationImports) {
      if (import is AugmentationImportWithFile) {
        import.importedAugmentation?.discoverReferencedFiles();
      }
    }
  }

  @override
  void dispose() {
    _augmentationImports?.disposeAll();
    _libraryExports?.disposeAll();
    _libraryImports?.disposeAll();
    super.dispose();
  }

  bool hasAugmentation(AugmentationFileKind augmentation) {
    for (final import in augmentationImports) {
      if (import is AugmentationImportWithFile) {
        if (import.importedFile == augmentation.file) {
          return true;
        }
      }
    }
    return false;
  }

  /// Returns `true` if [file] is imported as a library, or an augmentation.
  bool importsFile(FileState file) {
    return augmentationImports
            .whereType<AugmentationImportWithFile>()
            .any((import) => import.importedFile == file) ||
        libraryImports
            .whereType<LibraryImportWithFile>()
            .any((import) => import.importedFile == file);
  }

  /// Invalidates the containing [LibraryFileKind] cycle.
  void invalidateLibraryCycle() {}
}

class NamespaceDirectiveUris {
  final DirectiveUri primary;
  final List<DirectiveUri> configurations;
  final DirectiveUri selected;

  NamespaceDirectiveUris({
    required this.primary,
    required this.configurations,
    required this.selected,
  });
}

/// The file has `part of` directive.
abstract class PartFileKind extends FileKind {
  PartFileKind({
    required super.file,
  }) {
    _invalidateLibraries();
  }

  @override
  void dispose() {
    _invalidateLibraries();
    super.dispose();
  }

  /// Returns `true` if the `part of` directive confirms the [library].
  bool isPartOf(LibraryFileKind library);

  /// This method is invoked when the part file is updated.
  /// The file either becomes a part, or might stop being a part.
  void _invalidateLibraries() {
    for (final reference in file.referencingFiles) {
      final referenceKind = reference.kind;
      if (referenceKind is LibraryFileKind) {
        referenceKind.invalidateLibraryCycle();
      }
    }
  }
}

/// The file has `part of name` directive.
class PartOfNameFileKind extends PartFileKind {
  final UnlinkedPartOfNameDirective unlinked;

  PartOfNameFileKind({
    required super.file,
    required this.unlinked,
  });

  /// Libraries with the same name as in [unlinked].
  List<LibraryFileKind> get libraries {
    final files = file._fsState._libraryNameToFiles;
    return files[unlinked.name] ?? [];
  }

  /// If there are libraries that include this file as a part, return the
  /// first one as if sorted by path.
  @override
  LibraryFileKind? get library {
    discoverLibraries();

    LibraryFileKind? result;
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
      var resourceProvider = file._fsState.resourceProvider;
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
  bool isPartOf(LibraryFileKind library) {
    return unlinked.name == library.name;
  }
}

/// The file has `part of URI` directive.
abstract class PartOfUriFileKind extends PartFileKind {
  final UnlinkedPartOfUriDirective unlinked;

  PartOfUriFileKind({
    required super.file,
    required this.unlinked,
  });
}

/// The file has `part of URI` directive, and the URI can be resolved.
class PartOfUriKnownFileKind extends PartOfUriFileKind {
  final FileState uriFile;

  PartOfUriKnownFileKind({
    required super.file,
    required super.unlinked,
    required this.uriFile,
  });

  @override
  LibraryFileKind? get library {
    final uriKind = uriFile.kind;
    if (uriKind is LibraryFileKind) {
      if (uriKind.hasPart(this)) {
        return uriKind;
      }
    }
    return null;
  }

  @override
  bool isPartOf(LibraryFileKind library) {
    return uriFile == library.file;
  }
}

/// The file has `part of URI` directive, and the URI cannot be resolved.
class PartOfUriUnknownFileKind extends PartOfUriFileKind {
  PartOfUriUnknownFileKind({
    required super.file,
    required super.unlinked,
  });

  @override
  LibraryFileKind? get library => null;

  @override
  bool isPartOf(LibraryFileKind library) => false;
}

/// Information about a single `part` directive.
class PartState<U extends DirectiveUri> extends DirectiveState {
  final LibraryFileKind library;
  final UnlinkedPartDirective unlinked;
  final U uri;

  PartState({
    required this.library,
    required this.unlinked,
    required this.uri,
  });

  /// Returns a [Source] that is referenced by this directive.
  ///
  /// Returns `null` if the URI cannot be resolved into a [Source].
  Source? get includedSource => null;
}

/// [PartWithUri] that has a valid URI that references a file.
class PartWithFile extends PartWithUri<DirectiveUriWithFile> {
  PartWithFile({
    required super.library,
    required super.unlinked,
    required super.uri,
  }) {
    includedFile.referencingFiles.add(library.file);
  }

  FileState get includedFile => uri.file;

  /// If [includedFile] is a [PartFileKind], and it confirms that it
  /// is a part of the [library], returns the [includedFile].
  PartFileKind? get includedPart {
    final kind = includedFile.kind;
    if (kind is PartFileKind && kind.isPartOf(library)) {
      return kind;
    }
    return null;
  }

  @override
  Source? get includedSource => includedFile.source;

  @override
  void dispose() {
    includedFile.referencingFiles.remove(library.file);
  }
}

/// [PartState] that has a valid URI.
class PartWithUri<U extends DirectiveUriWithUri> extends PartWithUriStr<U> {
  PartWithUri({
    required super.library,
    required super.unlinked,
    required super.uri,
  });
}

/// [PartState] that has a relative URI string.
class PartWithUriStr<U extends DirectiveUriWithString> extends PartState<U> {
  PartWithUriStr({
    required super.library,
    required super.unlinked,
    required super.uri,
  });
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
  final Map<String, List<LibraryFileKind>> _map = {};

  List<LibraryFileKind>? operator [](String name) {
    return _map[name];
  }

  /// If [kind] is a named library, register it.
  void add(LibraryFileKind kind) {
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
  void remove(LibraryFileKind kind) {
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

extension on List<DirectiveState> {
  void disposeAll() {
    for (final directive in this) {
      directive.dispose();
    }
  }
}
