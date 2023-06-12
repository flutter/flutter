// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/analysis_context.dart' as api;
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/context_root.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/feature_set_provider.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/file_tracker.dart';
import 'package:analyzer/src/dart/analysis/index.dart';
import 'package:analyzer/src/dart/analysis/library_analyzer.dart';
import 'package:analyzer/src/dart/analysis/library_context.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/search.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/analysis/status.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/exception/exception.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine, AnalysisOptions, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/registry.dart' as linter;
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary2/ast_binary_flags.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:meta/meta.dart';

/// This class computes [AnalysisResult]s for Dart files.
///
/// Let the set of "explicitly analyzed files" denote the set of paths that have
/// been passed to [addFile] but not subsequently passed to [removeFile]. Let
/// the "current analysis results" denote the map from the set of explicitly
/// analyzed files to the most recent [AnalysisResult] delivered to [results]
/// for each file. Let the "current file state" represent a map from file path
/// to the file contents most recently read from that file, or fetched from the
/// content cache (considering all possible possible file paths, regardless of
/// whether they're in the set of explicitly analyzed files). Let the
/// "analysis state" be either "analyzing" or "idle".
///
/// (These are theoretical constructs; they may not necessarily reflect data
/// structures maintained explicitly by the driver).
///
/// Then we make the following guarantees:
///
///    - Whenever the analysis state is idle, the current analysis results are
///      consistent with the current file state.
///
///    - A call to [addFile] or [changeFile] causes the analysis state to
///      transition to "analyzing", and schedules the contents of the given
///      files to be read into the current file state prior to the next time
///      the analysis state transitions back to "idle".
///
///    - If at any time the client stops making calls to [addFile], [changeFile],
///      and [removeFile], the analysis state will eventually transition back to
///      "idle" after a finite amount of processing.
///
/// As a result of these guarantees, a client may ensure that the analysis
/// results are "eventually consistent" with the file system by simply calling
/// [changeFile] any time the contents of a file on the file system have changed.
///
/// TODO(scheglov) Clean up the list of implicitly analyzed files.
class AnalysisDriver implements AnalysisDriverGeneric {
  /// The version of data format, should be incremented on every format change.
  static const int DATA_VERSION = 191;

  /// The number of exception contexts allowed to write. Once this field is
  /// zero, we stop writing any new exception contexts in this process.
  static int allowedNumberOfContextsToWrite = 10;

  /// The scheduler that schedules analysis work in this, and possibly other
  /// analysis drivers.
  final AnalysisDriverScheduler _scheduler;

  /// The logger to write performed operations and performance to.
  final PerformanceLog _logger;

  /// The resource provider for working with files.
  final ResourceProvider _resourceProvider;

  /// The byte storage to get and put serialized data.
  ///
  /// It can be shared with other [AnalysisDriver]s.
  final ByteStore _byteStore;

  /// The optional store with externally provided unlinked and corresponding
  /// linked summaries. These summaries are always added to the store for any
  /// file analysis.
  final SummaryDataStore? _externalSummaries;

  /// This [ContentCache] is consulted for a file content before reading
  /// the content from the file.
  final FileContentCache _fileContentCache;

  /// The analysis options to analyze with.
  AnalysisOptionsImpl _analysisOptions;

  /// The [Packages] object with packages and their language versions.
  Packages _packages;

  /// The [SourceFactory] is used to resolve URIs to paths and restore URIs
  /// from file paths.
  SourceFactory _sourceFactory;

  /// The declared environment variables.
  DeclaredVariables declaredVariables = DeclaredVariables();

  /// The analysis context that created this driver / session.
  api.AnalysisContext? analysisContext;

  /// The salt to mix into all hashes used as keys for unlinked data.
  Uint32List _saltForUnlinked = Uint32List(0);

  /// The salt to mix into all hashes used as keys for elements.
  Uint32List _saltForElements = Uint32List(0);

  /// The salt to mix into all hashes used as keys for linked data.
  Uint32List _saltForResolution = Uint32List(0);

  /// The set of priority files, that should be analyzed sooner.
  final _priorityFiles = <String>{};

  /// The mapping from the files for which analysis was requested using
  /// [getResult] to the [Completer]s to report the result.
  final _requestedFiles = <String, List<Completer<ResolvedUnitResult>>>{};

  /// The mapping from the files for which analysis was requested using
  /// [getResolvedLibrary] to the [Completer]s to report the result.
  final _requestedLibraries =
      <String, List<Completer<ResolvedLibraryResult>>>{};

  /// The task that discovers available files.  If this field is not `null`,
  /// and the task is not completed, it should be performed and completed
  /// before any name searching task.
  _DiscoverAvailableFilesTask? _discoverAvailableFilesTask;

  /// The list of tasks to compute files defining a class member name.
  final _definingClassMemberNameTasks = <_FilesDefiningClassMemberNameTask>[];

  /// The list of tasks to compute files referencing a name.
  final _referencingNameTasks = <_FilesReferencingNameTask>[];

  /// The mapping from the files for which errors were requested using
  /// [getErrors] to the [Completer]s to report the result.
  final _errorsRequestedFiles = <String, List<Completer<ErrorsResult>>>{};

  /// The requests from [_errorsRequestedFiles] for files which were found to
  /// be parts without known libraries, so delayed.
  final _errorsRequestedParts = <String, List<Completer<ErrorsResult>>>{};

  /// The mapping from the files for which the index was requested using
  /// [getIndex] to the [Completer]s to report the result.
  final _indexRequestedFiles =
      <String, List<Completer<AnalysisDriverUnitIndex>>>{};

  /// The mapping from the files for which the unit element was requested using
  /// [getUnitElement] to the [Completer]s to report the result.
  final _unitElementRequestedFiles =
      <String, List<Completer<UnitElementResult>>>{};

  /// The mapping from the files for which the unit element was requested using
  /// [getUnitElement], and which were found to be parts without known
  /// libraries, to the [Completer]s to report the result.
  final _unitElementRequestedParts =
      <String, List<Completer<UnitElementResult>>>{};

  /// The mapping from the files for which analysis was requested using
  /// [getResult], and which were found to be parts without known libraries,
  /// to the [Completer]s to report the result.
  final _requestedParts = <String, List<Completer<ResolvedUnitResult>>>{};

  /// The set of part files that are currently scheduled for analysis.
  final _partsToAnalyze = <String>{};

  /// The controller for the [results] stream.
  final _resultController = StreamController<Object>();

  /// The stream that will be written to when analysis results are produced.
  late final Stream<Object> _onResults;

  /// Resolution signatures of the most recently produced results for files.
  final Map<String, String> _lastProducedSignatures = {};

  /// Cached results for [_priorityFiles].
  final Map<String, ResolvedUnitResult> _priorityResults = {};

  /// The controller for the [exceptions] stream.
  final StreamController<ExceptionResult> _exceptionController =
      StreamController<ExceptionResult>();

  /// The instance of the [Search] helper.
  late final Search _search;

  late final AnalysisDriverTestView _testView;

  late FeatureSetProvider featureSetProvider;

  late FileSystemState _fsState;

  /// The [FileTracker] used by this driver.
  late FileTracker _fileTracker;

  /// Whether resolved units should be indexed.
  final bool enableIndex;

  /// The current analysis session.
  late final AnalysisSessionImpl _currentSession = AnalysisSessionImpl(this);

  /// The current library context, consistent with the [_currentSession].
  ///
  /// TODO(scheglov) We probably should tie it into the session.
  LibraryContext? _libraryContext;

  /// Whether `dart:core` has been transitively discovered.
  bool _hasDartCoreDiscovered = false;

  /// If testing data is being retained, a pointer to the object that is
  /// retaining the testing data.  Otherwise `null`.
  final TestingData? testingData;

  /// Create a new instance of [AnalysisDriver].
  ///
  /// The given [SourceFactory] is cloned to ensure that it does not contain a
  /// reference to a [AnalysisContext] in which it could have been used.
  @Deprecated('Use AnalysisDriver.tmp1() instead')
  factory AnalysisDriver(
    AnalysisDriverScheduler scheduler,
    PerformanceLog logger,
    ResourceProvider resourceProvider,
    ByteStore byteStore,
    // ignore: avoid_unused_constructor_parameters
    FileContentOverlay? contentOverlay,
    // ignore: avoid_unused_constructor_parameters
    ContextRoot? contextRoot,
    SourceFactory sourceFactory,
    AnalysisOptionsImpl analysisOptions, {
    Packages? packages,
    bool enableIndex = false,
    SummaryDataStore? externalSummaries,
    bool retainDataForTesting = false,
  }) {
    return AnalysisDriver.tmp1(
      scheduler: scheduler,
      logger: logger,
      resourceProvider: resourceProvider,
      byteStore: byteStore,
      sourceFactory: sourceFactory,
      analysisOptions: analysisOptions,
      packages: packages ?? Packages.empty,
      enableIndex: enableIndex,
      externalSummaries: externalSummaries,
      retainDataForTesting: retainDataForTesting,
    );
  }

  /// Create a new instance of [AnalysisDriver].
  ///
  /// The given [SourceFactory] is cloned to ensure that it does not contain a
  /// reference to a [AnalysisContext] in which it could have been used.
  AnalysisDriver.tmp1({
    required AnalysisDriverScheduler scheduler,
    required PerformanceLog logger,
    required ResourceProvider resourceProvider,
    required ByteStore byteStore,
    required SourceFactory sourceFactory,
    required AnalysisOptionsImpl analysisOptions,
    required Packages packages,
    FileContentCache? fileContentCache,
    bool enableIndex = false,
    SummaryDataStore? externalSummaries,
    bool retainDataForTesting = false,
  })  : _scheduler = scheduler,
        _resourceProvider = resourceProvider,
        _byteStore = byteStore,
        _fileContentCache =
            fileContentCache ?? FileContentCache.ephemeral(resourceProvider),
        _analysisOptions = analysisOptions,
        enableIndex = enableIndex,
        _logger = logger,
        _packages = packages,
        _sourceFactory = sourceFactory,
        _externalSummaries = externalSummaries,
        testingData = retainDataForTesting ? TestingData() : null {
    _onResults = _resultController.stream.asBroadcastStream();
    _testView = AnalysisDriverTestView(this);
    _createFileTracker();
    _scheduler.add(this);
    _search = Search(this);
  }

  /// Return the set of files explicitly added to analysis using [addFile].
  Set<String> get addedFiles => _fileTracker.addedFiles;

  /// Return the analysis options used to control analysis.
  AnalysisOptions get analysisOptions => _analysisOptions;

  /// Return the current analysis session.
  AnalysisSessionImpl get currentSession => _currentSession;

  /// Return the stream that produces [ExceptionResult]s.
  Stream<ExceptionResult> get exceptions => _exceptionController.stream;

  /// The current file system state.
  FileSystemState get fsState => _fsState;

  @override
  bool get hasFilesToAnalyze {
    return _fileTracker.hasChangedFiles ||
        _requestedFiles.isNotEmpty ||
        _requestedParts.isNotEmpty ||
        _fileTracker.hasPendingFiles ||
        _partsToAnalyze.isNotEmpty;
  }

  /// Return the set of files that are known at this moment. This set does not
  /// always include all added files or all implicitly used file. If a file has
  /// not been processed yet, it might be missing.
  Set<String> get knownFiles => _fsState.knownFilePaths;

  /// Return the context in which libraries should be analyzed.
  LibraryContext get libraryContext {
    return _libraryContext ??= LibraryContext(
      testView: _testView.libraryContextTestView,
      session: currentSession,
      logger: _logger,
      byteStore: _byteStore,
      analysisOptions: _analysisOptions,
      declaredVariables: declaredVariables,
      sourceFactory: _sourceFactory,
      externalSummaries: _externalSummaries,
    );
  }

  /// Return the path of the folder at the root of the context.
  String get name => analysisContext?.contextRoot.root.path ?? '';

  /// Return the number of files scheduled for analysis.
  int get numberOfFilesToAnalyze => _fileTracker.numberOfPendingFiles;

  /// Return the list of files that the driver should try to analyze sooner.
  List<String> get priorityFiles => _priorityFiles.toList(growable: false);

  @override
  set priorityFiles(List<String> priorityPaths) {
    _priorityResults.keys
        .toSet()
        .difference(priorityPaths.toSet())
        .forEach(_priorityResults.remove);
    _priorityFiles.clear();
    _priorityFiles.addAll(priorityPaths);
    _scheduler.notify(this);
  }

  /// Return the [ResourceProvider] that is used to access the file system.
  ResourceProvider get resourceProvider => _resourceProvider;

  /// Return the [Stream] that produces [AnalysisResult]s for added files.
  ///
  /// Note that the stream supports only one single subscriber.
  ///
  /// Analysis starts when the [AnalysisDriverScheduler] is started and the
  /// driver is added to it. The analysis state transitions to "analyzing" and
  /// an analysis result is produced for every added file prior to the next time
  /// the analysis state transitions to "idle".
  ///
  /// [ResolvedUnitResult]s are produced for:
  /// 1. Files requested using [getResult].
  /// 2. Files passed to [addFile] which are also in [priorityFiles].
  ///
  /// [ErrorsResult]s are produced for:
  /// 1. Files passed to [addFile] which are not in [priorityFiles].
  ///
  /// At least one analysis result is produced for every file passed to
  /// [addFile] or [changeFile] prior to the next time the analysis state
  /// transitions to "idle", unless the file is later removed from analysis
  /// using [removeFile]. Analysis results for other files are produced only if
  /// the changes affect analysis results of other files.
  ///
  /// More than one result might be produced for the same file, even if the
  /// client does not change the state of the files.
  ///
  /// Results might be produced even for files that have never been added
  /// using [addFile], for example when [getResult] was called for a file.
  Stream<Object> get results => _onResults;

  /// Return the search support for the driver.
  Search get search => _search;

  /// Return the source factory used to resolve URIs to paths and restore URIs
  /// from file paths.
  SourceFactory get sourceFactory => _sourceFactory;

  @visibleForTesting
  AnalysisDriverTestView get test => _testView;

  @override
  AnalysisDriverPriority get workPriority {
    if (_requestedFiles.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_requestedLibraries.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_discoverAvailableFilesTask != null &&
        !_discoverAvailableFilesTask!.isCompleted) {
      return AnalysisDriverPriority.interactive;
    }
    if (_definingClassMemberNameTasks.isNotEmpty ||
        _referencingNameTasks.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_errorsRequestedFiles.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_indexRequestedFiles.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_unitElementRequestedFiles.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_priorityFiles.isNotEmpty) {
      for (String path in _priorityFiles) {
        if (_fileTracker.isFilePending(path)) {
          return AnalysisDriverPriority.priority;
        }
      }
    }
    if (_fileTracker.hasChangedFiles) {
      return AnalysisDriverPriority.changedFiles;
    }
    if (_fileTracker.hasPendingChangedFiles) {
      return AnalysisDriverPriority.generalChanged;
    }
    if (_fileTracker.hasPendingImportFiles) {
      return AnalysisDriverPriority.generalImportChanged;
    }
    if (_fileTracker.hasPendingErrorFiles) {
      return AnalysisDriverPriority.generalWithErrors;
    }
    if (_fileTracker.hasPendingFiles) {
      return AnalysisDriverPriority.general;
    }
    if (_errorsRequestedParts.isNotEmpty ||
        _requestedParts.isNotEmpty ||
        _partsToAnalyze.isNotEmpty ||
        _unitElementRequestedParts.isNotEmpty) {
      return AnalysisDriverPriority.general;
    }
    return AnalysisDriverPriority.nothing;
  }

  @override
  void addFile(String path) {
    _throwIfNotAbsolutePath(path);
    if (!_fsState.hasUri(path)) {
      return;
    }
    if (file_paths.isDart(resourceProvider.pathContext, path)) {
      _priorityResults.clear();
      _removePotentiallyAffectedLibraries(path);
      _fileTracker.addFile(path);
      _scheduler.notify(this);
    }
  }

  /// The file with the given [path] might have changed - updated, added or
  /// removed. Or not, we don't know. Or it might have, but then changed back.
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// The [path] can be any file - explicitly or implicitly analyzed, or neither.
  ///
  /// Causes the analysis state to transition to "analyzing" (if it is not in
  /// that state already). Schedules the file contents for [path] to be read
  /// into the current file state prior to the next time the analysis state
  /// transitions to "idle".
  ///
  /// Invocation of this method will not prevent a [Future] returned from
  /// [getResult] from completing with a result, but the result is not
  /// guaranteed to be consistent with the new current file state after this
  /// [changeFile] invocation.
  void changeFile(String path) {
    _throwIfNotAbsolutePath(path);
    if (!_fsState.hasUri(path)) {
      return;
    }
    if (file_paths.isDart(resourceProvider.pathContext, path)) {
      _priorityResults.clear();
      _removePotentiallyAffectedLibraries(path);
      _fileTracker.changeFile(path);
      _scheduler.notify(this);
    }
  }

  /// Clear the library context and any related data structures. Mostly we do
  /// this to reduce memory consumption. The library context holds to every
  /// library that was resynthesized, but after some initial analysis we might
  /// not get again to many of these libraries. So, we should clear the context
  /// periodically.
  @visibleForTesting
  void clearLibraryContext() {
    _libraryContext?.invalidAllLibraries();
    _libraryContext = null;
    _currentSession.clearHierarchies();
  }

  /// Some state on which analysis depends has changed, so the driver needs to be
  /// re-configured with the new state.
  ///
  /// At least one of the optional parameters should be provided, but only those
  /// that represent state that has actually changed need be provided.
  void configure({
    api.AnalysisContext? analysisContext,
    AnalysisOptionsImpl? analysisOptions,
    Packages? packages,
    SourceFactory? sourceFactory,
  }) {
    if (analysisContext != null) {
      this.analysisContext = analysisContext;
      _scheduler.driverWatcher?.addedDriver(this);
    }
    if (analysisOptions != null) {
      _analysisOptions = analysisOptions;
    }
    if (packages != null) {
      _packages = packages;
    }
    if (sourceFactory != null) {
      _sourceFactory = sourceFactory;
    }

    _priorityResults.clear();
    clearLibraryContext();

    Iterable<String> addedFiles = _fileTracker.addedFiles;
    _createFileTracker();
    _fileTracker.addFiles(addedFiles);

    _scheduler.notify(this);
  }

  /// Return a [Future] that completes when discovery of all files that are
  /// potentially available is done, so that they are included in [knownFiles].
  Future<void> discoverAvailableFiles() {
    if (_discoverAvailableFilesTask != null &&
        _discoverAvailableFilesTask!.isCompleted) {
      return Future.value();
    }
    _discoverAvailableFiles();
    _scheduler.notify(this);
    return _discoverAvailableFilesTask!.completer.future;
  }

  @override
  void dispose() {
    _scheduler.remove(this);
  }

  /// Return the cached [ResolvedUnitResult] for the Dart file with the given
  /// [path]. If there is no cached result, return `null`. Usually only results
  /// of priority files are cached.
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// The [path] can be any file - explicitly or implicitly analyzed, or neither.
  ResolvedUnitResult? getCachedResult(String path) {
    _throwIfNotAbsolutePath(path);
    return _priorityResults[path];
  }

  /// Return a [Future] that completes with the [ErrorsResult] for the Dart
  /// file with the given [path].
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// This method does not use analysis priorities, and must not be used in
  /// interactive analysis, such as Analysis Server or its plugins.
  Future<SomeErrorsResult> getErrors(String path) async {
    if (!_isAbsolutePath(path)) {
      return Future.value(
        InvalidPathResult(),
      );
    }

    if (!_fsState.hasUri(path)) {
      return Future.value(
        NotPathOfUriResult(),
      );
    }

    var completer = Completer<ErrorsResult>();
    _errorsRequestedFiles
        .putIfAbsent(path, () => <Completer<ErrorsResult>>[])
        .add(completer);
    _scheduler.notify(this);
    return completer.future;
  }

  /// Return a [Future] that completes with the [ErrorsResult] for the Dart
  /// file with the given [path].
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// This method does not use analysis priorities, and must not be used in
  /// interactive analysis, such as Analysis Server or its plugins.
  @Deprecated('Use getErrors() instead')
  Future<SomeErrorsResult> getErrors2(String path) async {
    return getErrors(path);
  }

  /// Return a [Future] that completes with the list of added files that
  /// define a class member with the given [name].
  Future<List<String>> getFilesDefiningClassMemberName(String name) {
    _discoverAvailableFiles();
    var task = _FilesDefiningClassMemberNameTask(this, name);
    _definingClassMemberNameTasks.add(task);
    _scheduler.notify(this);
    return task.completer.future;
  }

  /// Return a [Future] that completes with the list of known files that
  /// reference the given external [name].
  Future<List<String>> getFilesReferencingName(String name) {
    _discoverAvailableFiles();
    var task = _FilesReferencingNameTask(this, name);
    _referencingNameTasks.add(task);
    _scheduler.notify(this);
    return task.completer.future;
  }

  /// Return the [FileResult] for the Dart file with the given [path].
  ///
  /// The [path] must be absolute and normalized.
  SomeFileResult getFileSync(String path) {
    if (!_isAbsolutePath(path)) {
      return InvalidPathResult();
    }

    FileState file = _fileTracker.getFile(path);
    return FileResultImpl(
        _currentSession, path, file.uri, file.lineInfo, file.isPart);
  }

  /// Return the [FileResult] for the Dart file with the given [path].
  ///
  /// The [path] must be absolute and normalized.
  @Deprecated('Use getFileSync() instead')
  SomeFileResult getFileSync2(String path) {
    return getFileSync(path);
  }

  /// Return a [Future] that completes with the [AnalysisDriverUnitIndex] for
  /// the file with the given [path], or with `null` if the file cannot be
  /// analyzed.
  Future<AnalysisDriverUnitIndex?> getIndex(String path) {
    _throwIfNotAbsolutePath(path);
    if (!enableIndex) {
      throw ArgumentError('Indexing is not enabled.');
    }
    if (!_fsState.hasUri(path)) {
      return Future.value();
    }
    var completer = Completer<AnalysisDriverUnitIndex>();
    _indexRequestedFiles
        .putIfAbsent(path, () => <Completer<AnalysisDriverUnitIndex>>[])
        .add(completer);
    _scheduler.notify(this);
    return completer.future;
  }

  /// Return [LibraryElementResult] for the given [file], or `null` if the
  /// file is a part.
  LibraryElement? getLibraryByFile(FileState file) {
    if (file.isPart) {
      return null;
    }

    var element = libraryContext.getLibraryElementIfReady(file.uriStr);
    if (element != null) {
      return element;
    }

    libraryContext.load2(file);
    return libraryContext.getLibraryElement(file.uri);
  }

  /// Return a [Future] that completes with [LibraryElementResult] for the given
  /// [uri], which is either resynthesized from the provided external summary
  /// store, or built for a file to which the given [uri] is resolved.
  Future<SomeLibraryElementResult> getLibraryByUri(String uri) async {
    var uriObj = Uri.parse(uri);
    var fileOr = _fsState.getFileForUri(uriObj);
    return fileOr.map(
      (file) async {
        if (file == null) {
          return CannotResolveUriResult();
        }

        if (file.isPart) {
          return NotLibraryButPartResult();
        }

        var unitResult = await getUnitElement(file.path);
        if (unitResult is UnitElementResult) {
          return LibraryElementResultImpl(unitResult.element.library);
        }

        // Some invalid results are invalid results for this request.
        // Note that up-down promotion does not work.
        if (unitResult is InvalidResult &&
            unitResult is SomeLibraryElementResult) {
          return unitResult as SomeLibraryElementResult;
        }

        // Should not happen.
        return UnspecifiedInvalidResult();
      },
      (externalLibrary) async {
        var element = libraryContext.getLibraryElement(externalLibrary.uri);
        return LibraryElementResultImpl(element);
      },
    );
  }

  /// Return a [Future] that completes with [LibraryElementResult] for the given
  /// [uri], which is either resynthesized from the provided external summary
  /// store, or built for a file to which the given [uri] is resolved.
  @Deprecated('Use getLibraryByUri() instead')
  Future<SomeLibraryElementResult> getLibraryByUri2(String uri) async {
    return getLibraryByUri(uri);
  }

  /// Return a [ParsedLibraryResult] for the library with the given [path].
  ///
  /// The [path] must be absolute and normalized.
  SomeParsedLibraryResult getParsedLibrary(String path) {
    if (!_isAbsolutePath(path)) {
      return InvalidPathResult();
    }

    if (!_fsState.hasUri(path)) {
      return NotPathOfUriResult();
    }

    FileState file = _fsState.getFileForPath(path);

    if (file.isPart) {
      return NotLibraryButPartResult();
    }

    var units = <ParsedUnitResult>[];
    for (var unitFile in file.libraryFiles) {
      var unitPath = unitFile.path;
      var unitResult = parseFileSync(unitPath);
      if (unitResult is! ParsedUnitResult) {
        return UnspecifiedInvalidResult();
      }
      units.add(unitResult);
    }

    return ParsedLibraryResultImpl(currentSession, path, file.uri, units);
  }

  /// Return a [ParsedLibraryResult] for the library with the given [uri].
  SomeParsedLibraryResult getParsedLibraryByUri(Uri uri) {
    var fileOr = _fsState.getFileForUri(uri);
    return fileOr.map(
      (file) {
        if (file == null) {
          return CannotResolveUriResult();
        }
        if (file.isPart) {
          return NotLibraryButPartResult();
        }
        return getParsedLibrary(file.path);
      },
      (externalLibrary) {
        return UriOfExternalLibraryResult();
      },
    );
  }

  /// Return a [Future] that completes with a [ResolvedLibraryResult] for the
  /// Dart library file with the given [path].  If the file cannot be analyzed,
  /// the [Future] completes with an [InvalidResult].
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// The [path] can be any file - explicitly or implicitly analyzed, or neither.
  ///
  /// Invocation of this method causes the analysis state to transition to
  /// "analyzing" (if it is not in that state already), the driver will produce
  /// the resolution result for it, which is consistent with the current file
  /// state (including new states of the files previously reported using
  /// [changeFile]), prior to the next time the analysis state transitions
  /// to "idle".
  Future<SomeResolvedLibraryResult> getResolvedLibrary(String path) {
    if (!_isAbsolutePath(path)) {
      return Future.value(
        InvalidPathResult(),
      );
    }

    if (!_fsState.hasUri(path)) {
      return Future.value(
        NotPathOfUriResult(),
      );
    }

    FileState file = _fsState.getFileForPath(path);

    if (file.isPart) {
      return Future.value(
        NotLibraryButPartResult(),
      );
    }

    // Schedule analysis.
    var completer = Completer<ResolvedLibraryResult>();
    _requestedLibraries
        .putIfAbsent(path, () => <Completer<ResolvedLibraryResult>>[])
        .add(completer);
    _scheduler.notify(this);
    return completer.future;
  }

  /// Return a [Future] that completes with a [ResolvedLibraryResult] for the
  /// Dart library file with the given [uri].  If the file cannot be analyzed,
  /// the [Future] completes with an [InvalidResult].
  ///
  /// Invocation of this method causes the analysis state to transition to
  /// "analyzing" (if it is not in that state already), the driver will produce
  /// the resolution result for it, which is consistent with the current file
  /// state (including new states of the files previously reported using
  /// [changeFile]), prior to the next time the analysis state transitions
  /// to "idle".
  Future<SomeResolvedLibraryResult> getResolvedLibraryByUri(Uri uri) {
    var fileOr = _fsState.getFileForUri(uri);
    return fileOr.map(
      (file) async {
        if (file == null) {
          return CannotResolveUriResult();
        }
        if (file.isPart) {
          return NotLibraryButPartResult();
        }
        return getResolvedLibrary(file.path);
      },
      (externalLibrary) async {
        return UriOfExternalLibraryResult();
      },
    );
  }

  /// Return a [Future] that completes with a [SomeResolvedUnitResult] for the
  /// Dart file with the given [path].  If the file cannot be analyzed,
  /// the [Future] completes with an [InvalidResult].
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// The [path] can be any file - explicitly or implicitly analyzed, or neither.
  ///
  /// If the driver has the cached analysis result for the file, it is returned.
  /// If [sendCachedToStream] is `true`, then the result is also reported into
  /// the [results] stream, just as if it were freshly computed.
  ///
  /// Otherwise causes the analysis state to transition to "analyzing" (if it is
  /// not in that state already), the driver will produce the analysis result for
  /// it, which is consistent with the current file state (including new states
  /// of the files previously reported using [changeFile]), prior to the next
  /// time the analysis state transitions to "idle".
  Future<SomeResolvedUnitResult> getResult(String path,
      {bool sendCachedToStream = false}) {
    if (!_isAbsolutePath(path)) {
      return Future.value(
        InvalidPathResult(),
      );
    }

    if (!_fsState.hasUri(path)) {
      return Future.value(
        NotPathOfUriResult(),
      );
    }

    // Return the cached result.
    {
      ResolvedUnitResult? result = getCachedResult(path);
      if (result != null) {
        if (sendCachedToStream) {
          _resultController.add(result);
        }
        return Future.value(result);
      }
    }

    // Schedule analysis.
    var completer = Completer<ResolvedUnitResult>();
    _requestedFiles
        .putIfAbsent(path, () => <Completer<ResolvedUnitResult>>[])
        .add(completer);
    _scheduler.notify(this);
    return completer.future;
  }

  /// Return a [Future] that completes with a [SomeResolvedUnitResult] for the
  /// Dart file with the given [path].  If the file cannot be analyzed,
  /// the [Future] completes with an [InvalidResult].
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// The [path] can be any file - explicitly or implicitly analyzed, or neither.
  ///
  /// If the driver has the cached analysis result for the file, it is returned.
  /// If [sendCachedToStream] is `true`, then the result is also reported into
  /// the [results] stream, just as if it were freshly computed.
  ///
  /// Otherwise causes the analysis state to transition to "analyzing" (if it is
  /// not in that state already), the driver will produce the analysis result for
  /// it, which is consistent with the current file state (including new states
  /// of the files previously reported using [changeFile]), prior to the next
  /// time the analysis state transitions to "idle".
  @Deprecated('Use getResult() instead')
  Future<SomeResolvedUnitResult> getResult2(String path,
      {bool sendCachedToStream = false}) {
    return getResult(path);
  }

  /// Return a [Future] that completes with the [SomeUnitElementResult]
  /// for the file with the given [path].
  Future<SomeUnitElementResult> getUnitElement(String path) {
    if (!_isAbsolutePath(path)) {
      return Future.value(
        InvalidPathResult(),
      );
    }

    if (!_fsState.hasUri(path)) {
      return Future.value(
        NotPathOfUriResult(),
      );
    }

    var completer = Completer<UnitElementResult>();
    _unitElementRequestedFiles
        .putIfAbsent(path, () => <Completer<UnitElementResult>>[])
        .add(completer);
    _scheduler.notify(this);
    return completer.future;
  }

  /// Return `true` is the file with the given absolute [uri] is a library,
  /// or `false` if it is a part. More specifically, return `true` if the file
  /// is not known to be a part.
  ///
  /// Correspondingly, return `true` if the [uri] does not correspond to a file,
  /// for any reason, e.g. the file does not exist, or the [uri] cannot be
  /// resolved to a file path, or the [uri] is invalid, e.g. a `package:` URI
  /// without a package name. In these cases we cannot prove that the file is
  /// not a part, so it must be a library.
  bool isLibraryByUri(Uri uri) {
    var fileOr = _fsState.getFileForUri(uri);
    return fileOr.map(
      (file) => file == null || !file.isPart,
      (uri) => false,
    );
  }

  /// Return a [Future] that completes with a [ParsedUnitResult] for the file
  /// with the given [path].
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// The [path] can be any file - explicitly or implicitly analyzed, or neither.
  ///
  /// The parsing is performed in the method itself, and the result is not
  /// produced through the [results] stream (just because it is not a fully
  /// resolved unit).
  @Deprecated('Use parseFileSync() instead')
  Future<SomeParsedUnitResult> parseFile2(String path) async {
    return parseFileSync2(path);
  }

  /// Return a [ParsedUnitResult] for the file with the given [path].
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// The [path] can be any file - explicitly or implicitly analyzed, or neither.
  ///
  /// The parsing is performed in the method itself, and the result is not
  /// produced through the [results] stream (just because it is not a fully
  /// resolved unit).
  SomeParsedUnitResult parseFileSync(String path) {
    if (!_isAbsolutePath(path)) {
      return InvalidPathResult();
    }

    FileState file = _fileTracker.getFile(path);
    RecordingErrorListener listener = RecordingErrorListener();
    CompilationUnit unit = file.parse(listener);
    return ParsedUnitResultImpl(currentSession, file.path, file.uri,
        file.content, file.lineInfo, file.isPart, unit, listener.errors);
  }

  /// Return a [ParsedUnitResult] for the file with the given [path].
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// The [path] can be any file - explicitly or implicitly analyzed, or neither.
  ///
  /// The parsing is performed in the method itself, and the result is not
  /// produced through the [results] stream (just because it is not a fully
  /// resolved unit).
  @Deprecated('Use parseFileSync() instead')
  SomeParsedUnitResult parseFileSync2(String path) {
    return parseFileSync(path);
  }

  @override
  Future<void> performWork() async {
    if (_fileTracker.verifyChangedFilesIfNeeded()) {
      return;
    }

    if (!_hasDartCoreDiscovered) {
      _hasDartCoreDiscovered = true;
      _discoverDartCore();
    }

    // Analyze a requested file.
    if (_requestedFiles.isNotEmpty) {
      String path = _requestedFiles.keys.first;
      try {
        var result = _computeAnalysisResult(path, withUnit: true);
        // If a part without a library, delay its analysis.
        if (result == null) {
          _requestedParts
              .putIfAbsent(path, () => [])
              .addAll(_requestedFiles.remove(path)!);
          return;
        }
        // Notify the completers.
        _requestedFiles.remove(path)!.forEach((completer) {
          completer.complete(result.unitResult!);
        });
        // Remove from to be analyzed and produce it now.
        _fileTracker.fileWasAnalyzed(path);
        _resultController.add(result.unitResult!);
      } catch (exception, stackTrace) {
        _reportException(path, exception, stackTrace);
        _fileTracker.fileWasAnalyzed(path);
        _requestedFiles.remove(path)!.forEach((completer) {
          completer.completeError(exception, stackTrace);
        });
        _clearLibraryContextAfterException();
      }
      return;
    }

    // Analyze a requested library.
    if (_requestedLibraries.isNotEmpty) {
      String path = _requestedLibraries.keys.first;
      try {
        var result = _computeResolvedLibrary(path);
        _requestedLibraries.remove(path)!.forEach((completer) {
          completer.complete(result);
        });
      } catch (exception, stackTrace) {
        _requestedLibraries.remove(path)!.forEach((completer) {
          completer.completeError(exception, stackTrace);
        });
        _clearLibraryContextAfterException();
      }
      return;
    }

    // Process an error request.
    if (_errorsRequestedFiles.isNotEmpty) {
      var path = _errorsRequestedFiles.keys.first;
      var completers = _errorsRequestedFiles.remove(path)!;
      var result = _computeErrors(path: path, asIsIfPartWithoutLibrary: false);
      if (result != null) {
        completers.forEach((completer) {
          completer.complete(result);
        });
      } else {
        _errorsRequestedParts.putIfAbsent(path, () => []).addAll(completers);
      }
      return;
    }

    // Process an index request.
    if (_indexRequestedFiles.isNotEmpty) {
      String path = _indexRequestedFiles.keys.first;
      AnalysisDriverUnitIndex index = _computeIndex(path);
      _indexRequestedFiles.remove(path)!.forEach((completer) {
        completer.complete(index);
      });
      return;
    }

    // Process a unit element request.
    if (_unitElementRequestedFiles.isNotEmpty) {
      String path = _unitElementRequestedFiles.keys.first;
      UnitElementResult? result = _computeUnitElement(path);
      var completers = _unitElementRequestedFiles.remove(path)!;
      if (result != null) {
        completers.forEach((completer) {
          completer.complete(result);
        });
      } else {
        _unitElementRequestedParts
            .putIfAbsent(path, () => [])
            .addAll(completers);
      }
      return;
    }

    // Discover available files.
    if (_discoverAvailableFilesTask != null &&
        !_discoverAvailableFilesTask!.isCompleted) {
      _discoverAvailableFilesTask!.perform();
      return;
    }

    // Compute files defining a name.
    if (_definingClassMemberNameTasks.isNotEmpty) {
      _FilesDefiningClassMemberNameTask task =
          _definingClassMemberNameTasks.first;
      bool isDone = task.perform();
      if (isDone) {
        _definingClassMemberNameTasks.remove(task);
      }
      return;
    }

    // Compute files referencing a name.
    if (_referencingNameTasks.isNotEmpty) {
      _FilesReferencingNameTask task = _referencingNameTasks.first;
      bool isDone = task.perform();
      if (isDone) {
        _referencingNameTasks.remove(task);
      }
      return;
    }

    // Analyze a priority file.
    if (_priorityFiles.isNotEmpty) {
      for (String path in _priorityFiles) {
        if (_fileTracker.isFilePending(path)) {
          try {
            var result = _computeAnalysisResult(path, withUnit: true);
            if (result == null) {
              _partsToAnalyze.add(path);
            } else {
              _resultController.add(result.unitResult!);
            }
          } catch (exception, stackTrace) {
            _reportException(path, exception, stackTrace);
            _clearLibraryContextAfterException();
          } finally {
            _fileTracker.fileWasAnalyzed(path);
          }
          return;
        }
      }
    }

    // Analyze a general file.
    if (_fileTracker.hasPendingFiles) {
      String path = _fileTracker.anyPendingFile;
      try {
        var result = _computeAnalysisResult(path,
            withUnit: false, skipIfSameSignature: true);
        if (result == null) {
          _partsToAnalyze.add(path);
        } else if (result.isUnchangedErrors) {
          // We found that the set of errors is the same as we produced the
          // last time, so we don't need to produce it again now.
        } else {
          _resultController.add(result.errorsResult!);
          _lastProducedSignatures[path] = result._signature;
        }
      } catch (exception, stackTrace) {
        _reportException(path, exception, stackTrace);
        _clearLibraryContextAfterException();
      } finally {
        _fileTracker.fileWasAnalyzed(path);
      }
      return;
    }

    // Analyze a requested part file.
    if (_requestedParts.isNotEmpty) {
      String path = _requestedParts.keys.first;
      try {
        var result = _computeAnalysisResult(path,
            withUnit: true, asIsIfPartWithoutLibrary: true)!;
        // Notify the completers.
        _requestedParts.remove(path)!.forEach((completer) {
          completer.complete(result.unitResult!);
        });
        // Remove from to be analyzed and produce it now.
        _partsToAnalyze.remove(path);
        _resultController.add(result.unitResult!);
      } catch (exception, stackTrace) {
        _reportException(path, exception, stackTrace);
        _partsToAnalyze.remove(path);
        _requestedParts.remove(path)!.forEach((completer) {
          completer.completeError(exception, stackTrace);
        });
        _clearLibraryContextAfterException();
      }
      return;
    }

    // Analyze a general part.
    if (_partsToAnalyze.isNotEmpty) {
      String path = _partsToAnalyze.first;
      _partsToAnalyze.remove(path);
      try {
        var withUnit = _priorityFiles.contains(path);
        if (withUnit) {
          var result = _computeAnalysisResult(path,
              withUnit: true, asIsIfPartWithoutLibrary: true)!;
          _resultController.add(result.unitResult!);
        } else {
          var result = _computeAnalysisResult(path,
              withUnit: false, asIsIfPartWithoutLibrary: true)!;
          _resultController.add(result.errorsResult!);
        }
      } catch (exception, stackTrace) {
        _reportException(path, exception, stackTrace);
        _clearLibraryContextAfterException();
      }
      return;
    }

    // Process a unit element request for a part.
    if (_unitElementRequestedParts.isNotEmpty) {
      String path = _unitElementRequestedParts.keys.first;
      UnitElementResult result =
          _computeUnitElement(path, asIsIfPartWithoutLibrary: true)!;
      _unitElementRequestedParts.remove(path)!.forEach((completer) {
        completer.complete(result);
      });
      return;
    }

    // Compute errors in a part.
    if (_errorsRequestedParts.isNotEmpty) {
      var path = _errorsRequestedParts.keys.first;
      var completers = _errorsRequestedParts.remove(path)!;
      var result = _computeErrors(path: path, asIsIfPartWithoutLibrary: true);
      completers.forEach((completer) {
        completer.complete(result);
      });
      return;
    }
  }

  /// Remove the file with the given [path] from the list of files to analyze.
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// The results of analysis of the file might still be produced by the
  /// [results] stream. The driver will try to stop producing these results,
  /// but does not guarantee this.
  void removeFile(String path) {
    _throwIfNotAbsolutePath(path);
    if (!_fsState.hasUri(path)) {
      return;
    }
    if (file_paths.isDart(resourceProvider.pathContext, path)) {
      _lastProducedSignatures.remove(path);
      _priorityResults.clear();
      _removePotentiallyAffectedLibraries(path);
      _fileTracker.removeFile(path);
      _scheduler.notify(this);
    }
  }

  ResolvedForCompletionResultImpl? resolveForCompletion({
    required String path,
    required int offset,
    required OperationPerformanceImpl performance,
  }) {
    if (!_isAbsolutePath(path)) {
      return null;
    }

    if (!_fsState.hasUri(path)) {
      return null;
    }

    // Process pending changes.
    while (_fileTracker.verifyChangedFilesIfNeeded()) {}

    var file = _fsState.getFileForPath(path);

    var library = file.isPart ? file.library : file;
    if (library == null) {
      return null;
    }

    libraryContext.load2(library);
    var unitElement = libraryContext.computeUnitElement(library, file)
        as CompilationUnitElementImpl;

    var analyzer = LibraryAnalyzer(
        analysisOptions as AnalysisOptionsImpl,
        declaredVariables,
        sourceFactory,
        libraryContext.analysisContext,
        libraryContext.elementFactory.libraryOfUri2(library.uriStr),
        libraryContext.analysisSession.inheritanceManager,
        library,
        testingData: testingData);

    var analysisResult = analyzer.analyzeForCompletion(
      file: file,
      offset: offset,
      unitElement: unitElement,
      performance: performance,
    );

    return ResolvedForCompletionResultImpl(
      analysisSession: currentSession,
      path: path,
      uri: file.uri,
      exists: file.exists,
      content: file.content,
      lineInfo: file.lineInfo,
      parsedUnit: analysisResult.parsedUnit,
      unitElement: unitElement,
      resolvedNodes: analysisResult.resolvedNodes,
    );
  }

  void _addDeclaredVariablesToSignature(ApiSignature buffer) {
    var variableNames = declaredVariables.variableNames;
    buffer.addInt(variableNames.length);

    for (var name in variableNames) {
      var value = declaredVariables.get(name);
      buffer.addString(name);
      buffer.addString(value!);
    }
  }

  /// There was an exception during a file analysis, we don't know why.
  /// But it might have been caused by an inconsistency of files state, and
  /// the library context state. Reset the library context, and hope that
  /// we will solve the inconsistency while loading / building summaries.
  void _clearLibraryContextAfterException() {
    clearLibraryContext();
  }

  /// Return the cached or newly computed analysis result of the file with the
  /// given [path].
  ///
  /// The [withUnit] flag control which result will be returned.
  /// When `true`, [AnalysisResult.unitResult] will be set.
  /// Otherwise [AnalysisResult.errorsResult] will be set.
  ///
  /// Return `null` if the file is a part of an unknown library, so cannot be
  /// analyzed yet. But [asIsIfPartWithoutLibrary] is `true`, then the file is
  /// analyzed anyway, even without a library.
  ///
  /// Return [AnalysisResult._UNCHANGED] if [skipIfSameSignature] is `true` and
  /// the resolved signature of the file in its library is the same as the one
  /// that was the most recently produced to the client.
  AnalysisResult? _computeAnalysisResult(String path,
      {required bool withUnit,
      bool asIsIfPartWithoutLibrary = false,
      bool skipIfSameSignature = false}) {
    FileState file = _fsState.getFileForPath(path);

    // Prepare the library - the file itself, or the known library.
    FileState? library = file.isPart ? file.library : file;
    if (library == null) {
      if (asIsIfPartWithoutLibrary) {
        library = file;
      } else {
        return null;
      }
    }

    // Prepare the signature and key.
    String signature = _getResolvedUnitSignature(library, file);
    String key = _getResolvedUnitKey(signature);

    // Skip reading if the signature, so errors, are the same as the last time.
    if (skipIfSameSignature) {
      assert(!withUnit);
      if (_lastProducedSignatures[path] == signature) {
        return AnalysisResult.unchangedErrors(signature);
      }
    }

    // If we don't need the fully resolved unit, check for the cached result.
    if (!withUnit) {
      var bytes = _byteStore.get(key);
      if (bytes != null) {
        return _getAnalysisResultFromBytes(file, signature, bytes);
      }
    }

    // We need the fully resolved unit, or the result is not cached.
    return _logger.run('Compute analysis result for $path', () {
      _logger.writeln('Work in $name');
      try {
        _testView.numOfAnalyzedLibraries++;

        if (!_hasLibraryByUri('dart:core')) {
          return _newMissingDartLibraryResult(file, 'dart:core');
        }

        if (!_hasLibraryByUri('dart:async')) {
          return _newMissingDartLibraryResult(file, 'dart:async');
        }

        libraryContext.load2(library!);

        LibraryAnalyzer analyzer = LibraryAnalyzer(
            analysisOptions as AnalysisOptionsImpl,
            declaredVariables,
            sourceFactory,
            libraryContext.analysisContext,
            libraryContext.elementFactory.libraryOfUri2(library.uriStr),
            libraryContext.analysisSession.inheritanceManager,
            library,
            testingData: testingData);
        Map<FileState, UnitAnalysisResult> results = analyzer.analyze();

        late Uint8List bytes;
        late CompilationUnit resolvedUnit;
        for (FileState unitFile in results.keys) {
          UnitAnalysisResult unitResult = results[unitFile]!;
          var unitBytes =
              _serializeResolvedUnit(unitResult.unit, unitResult.errors);
          String unitSignature = _getResolvedUnitSignature(library, unitFile);
          String unitKey = _getResolvedUnitKey(unitSignature);
          _byteStore.put(unitKey, unitBytes);
          if (unitFile == file) {
            bytes = unitBytes;
            resolvedUnit = unitResult.unit;
          }
        }

        // Return the result, full or partial.
        _logger.writeln('Computed new analysis result.');
        var result = _getAnalysisResultFromBytes(file, signature, bytes,
            content: withUnit ? file.content : null,
            resolvedUnit: withUnit ? resolvedUnit : null);
        if (withUnit && _priorityFiles.contains(path)) {
          _priorityResults[path] = result.unitResult!;
        }
        return result;
      } catch (exception, stackTrace) {
        String? contextKey =
            _storeExceptionContext(path, library!, exception, stackTrace);
        throw _ExceptionState(exception, stackTrace, contextKey);
      }
    });
  }

  ErrorsResult? _computeErrors({
    required String path,
    required bool asIsIfPartWithoutLibrary,
  }) {
    var analysisResult = _computeAnalysisResult(path,
        withUnit: false, asIsIfPartWithoutLibrary: asIsIfPartWithoutLibrary);

    if (analysisResult == null) {
      return null;
    }

    return analysisResult.errorsResult;
  }

  AnalysisDriverUnitIndex _computeIndex(String path) {
    var analysisResult = _computeAnalysisResult(path,
        withUnit: false, asIsIfPartWithoutLibrary: true);
    return analysisResult!._index!;
  }

  /// Return the newly computed resolution result of the library with the
  /// given [path].
  ResolvedLibraryResultImpl _computeResolvedLibrary(String path) {
    FileState library = _fsState.getFileForPath(path);

    return _logger.run('Compute resolved library $path', () {
      _testView.numOfAnalyzedLibraries++;
      libraryContext.load2(library);

      LibraryAnalyzer analyzer = LibraryAnalyzer(
          analysisOptions as AnalysisOptionsImpl,
          declaredVariables,
          sourceFactory,
          libraryContext.analysisContext,
          libraryContext.elementFactory.libraryOfUri2(library.uriStr),
          libraryContext.analysisSession.inheritanceManager,
          library,
          testingData: testingData);
      Map<FileState, UnitAnalysisResult> unitResults = analyzer.analyze();
      var resolvedUnits = <ResolvedUnitResult>[];

      for (var entry in unitResults.entries) {
        var unitFile = entry.key;
        var unitResult = entry.value;
        resolvedUnits.add(
          ResolvedUnitResultImpl(
            currentSession,
            unitFile.path,
            unitFile.uri,
            unitFile.exists,
            unitFile.content,
            unitFile.lineInfo,
            unitFile.isPart,
            unitResult.unit,
            unitResult.errors,
          ),
        );
      }

      return ResolvedLibraryResultImpl(
        currentSession,
        library.path,
        library.uri,
        resolvedUnits.first.libraryElement,
        resolvedUnits,
      );
    });
  }

  UnitElementResult? _computeUnitElement(String path,
      {bool asIsIfPartWithoutLibrary = false}) {
    FileState file = _fsState.getFileForPath(path);

    // Prepare the library - the file itself, or the known library.
    FileState? library = file.isPart ? file.library : file;
    if (library == null) {
      if (asIsIfPartWithoutLibrary) {
        library = file;
      } else {
        return null;
      }
    }

    return _logger.run('Compute unit element for $path', () {
      _logger.writeln('Work in $name');
      libraryContext.load2(library!);
      var element = libraryContext.computeUnitElement(library, file);
      return UnitElementResultImpl(
        currentSession,
        path,
        file.uri,
        file.lineInfo,
        file.isPart,
        library.transitiveSignature,
        element,
      );
    });
  }

  /// Creates new [FileSystemState] and [FileTracker] objects.
  ///
  /// This is used both on initial construction and whenever the configuration
  /// changes.
  void _createFileTracker() {
    _fillSalt();

    featureSetProvider = FeatureSetProvider.build(
      sourceFactory: sourceFactory,
      resourceProvider: _resourceProvider,
      packages: _packages,
      packageDefaultFeatureSet: _analysisOptions.contextFeatures,
      nonPackageDefaultLanguageVersion:
          _analysisOptions.nonPackageLanguageVersion,
      nonPackageDefaultFeatureSet: _analysisOptions.nonPackageFeatureSet,
    );

    _fsState = FileSystemState(
      _logger,
      _byteStore,
      _resourceProvider,
      name,
      sourceFactory,
      analysisContext?.contextRoot.workspace,
      analysisOptions,
      declaredVariables,
      _saltForUnlinked,
      _saltForElements,
      featureSetProvider,
      externalSummaries: _externalSummaries,
      fileContentCache: _fileContentCache,
    );
    _fileTracker = FileTracker(_logger, _fsState);
  }

  /// If this has not been done yet, schedule discovery of all files that are
  /// potentially available, so that they are included in [knownFiles].
  void _discoverAvailableFiles() {
    _discoverAvailableFilesTask ??= _DiscoverAvailableFilesTask(this);
  }

  /// When we look at a part that has a `part of name;` directive, we
  /// usually don't know the library (in contrast to `part of uri;`).
  /// So, we have no choice than to resolve this part as its own library.
  /// TODO(scheglov) Maybe just return an error result instead?
  ///
  /// But parts of `dart:xyz` libraries are special. The reason is that
  /// `dart:core` is always implicitly imported. So, when we start building
  /// the library cycle of such "part as a library", we discover `dart:core`,
  /// and see that it contains our part. So, we don't add it as a library on
  /// its own. But have already committed that it is a library. This causes
  /// an exception in `LinkedElementFactory`.
  ///
  /// The current workaround for this is to discover `dart:core` before any
  /// analysis.
  void _discoverDartCore() {
    _fsState.getFileForUri(Uri.parse('dart:core')).map(
      (file) {
        file?.transitiveFiles;
      },
      (externalLibrary) {},
    );
  }

  void _fillSalt() {
    _fillSaltForUnlinked();
    _fillSaltForElements();
    _fillSaltForResolution();
  }

  void _fillSaltForElements() {
    var buffer = ApiSignature();
    buffer.addInt(DATA_VERSION);
    buffer.addUint32List(_analysisOptions.signatureForElements);
    _addDeclaredVariablesToSignature(buffer);
    _saltForElements = buffer.toUint32List();
  }

  void _fillSaltForResolution() {
    var buffer = ApiSignature();
    buffer.addInt(DATA_VERSION);
    buffer.addBool(enableIndex);
    buffer.addBool(enableDebugResolutionMarkers);
    buffer.addUint32List(_analysisOptions.signature);
    _addDeclaredVariablesToSignature(buffer);

    var workspace = analysisContext?.contextRoot.workspace;
    workspace?.contributeToResolutionSalt(buffer);

    _saltForResolution = buffer.toUint32List();
  }

  void _fillSaltForUnlinked() {
    var buffer = ApiSignature();
    buffer.addInt(DATA_VERSION);
    buffer.addBool(enableIndex);
    buffer.addUint32List(_analysisOptions.unlinkedSignature);
    _saltForUnlinked = buffer.toUint32List();
  }

  /// Load the [AnalysisResult] for the given [file] from the [bytes]. Set
  /// optional [content] and [resolvedUnit].
  AnalysisResult _getAnalysisResultFromBytes(
      FileState file, String signature, Uint8List bytes,
      {String? content, CompilationUnit? resolvedUnit}) {
    var unit = AnalysisDriverResolvedUnit.fromBuffer(bytes);
    List<AnalysisError> errors = _getErrorsFromSerialized(file, unit.errors);
    _updateHasErrorOrWarningFlag(file, errors);
    var index = unit.index!;
    if (content != null && resolvedUnit != null) {
      var resolvedUnitResult = ResolvedUnitResultImpl(
        currentSession,
        file.path,
        file.uri,
        file.exists,
        content,
        file.lineInfo,
        file.isPart,
        resolvedUnit,
        errors,
      );
      return AnalysisResult.unit(signature, resolvedUnitResult, index);
    } else {
      var errorsResult = ErrorsResultImpl(
        currentSession,
        file.path,
        file.uri,
        file.lineInfo,
        file.isPart,
        errors,
      );
      return AnalysisResult.errors(signature, errorsResult, index);
    }
  }

  /// Return [AnalysisError]s for the given [serialized] errors.
  List<AnalysisError> _getErrorsFromSerialized(
      FileState file, List<AnalysisDriverUnitError> serialized) {
    List<AnalysisError> errors = <AnalysisError>[];
    for (AnalysisDriverUnitError error in serialized) {
      var analysisError = ErrorEncoding.decode(file.source, error);
      if (analysisError != null) {
        errors.add(analysisError);
      }
    }
    return errors;
  }

  /// Return the key to store fully resolved results for the [signature].
  String _getResolvedUnitKey(String signature) {
    return '$signature.resolved';
  }

  /// Return the signature that identifies fully resolved results for the [file]
  /// in the [library], e.g. element model, errors, index, etc.
  String _getResolvedUnitSignature(FileState library, FileState file) {
    ApiSignature signature = ApiSignature();
    signature.addUint32List(_saltForResolution);
    signature.addString(library.transitiveSignature);
    signature.addString(file.contentHash);
    return signature.toHex();
  }

  bool _hasLibraryByUri(String uriStr) {
    var uri = Uri.parse(uriStr);
    var fileOr = _fsState.getFileForUri(uri);
    return fileOr.map(
      (file) => file != null && file.exists,
      (_) => true,
    );
  }

  bool _isAbsolutePath(String path) {
    return _resourceProvider.pathContext.isAbsolute(path);
  }

  /// We detected that one of the required `dart` libraries is missing.
  /// Return the empty analysis result with the error.
  AnalysisResult _newMissingDartLibraryResult(
      FileState file, String missingUri) {
    // TODO(scheglov) Find a better way to report this.
    var errorsResult = ErrorsResultImpl(
      currentSession,
      file.path,
      file.uri,
      file.lineInfo,
      file.isPart,
      [
        AnalysisError(file.source, 0, 0,
            CompileTimeErrorCode.MISSING_DART_LIBRARY, [missingUri])
      ],
    );
    return AnalysisResult.errors(
        'missing', errorsResult, AnalysisDriverUnitIndexBuilder());
  }

  void _removePotentiallyAffectedLibraries(String path) {
    var affected = <FileState>{};
    _fsState.collectAffected(path, affected);

    for (var file in affected) {
      file.invalidateLibraryCycle();
    }

    _libraryContext?.elementFactory.removeLibraries(
      affected.map((e) => e.uriStr).toSet(),
    );
  }

  void _reportException(String path, Object exception, StackTrace stackTrace) {
    String? contextKey;
    if (exception is _ExceptionState) {
      var state = exception;
      exception = exception.exception;
      stackTrace = state.stackTrace;
      contextKey = state.contextKey;
    }

    CaughtException caught = CaughtException(exception, stackTrace);

    var fileContentMap = <String, String>{};
    var libraryFile = _fsState.getFileForPath(path);
    try {
      for (var file in libraryFile.libraryFiles) {
        var path = file.path;
        fileContentMap[path] = file.content;
      }
    } catch (_) {
      // We might get an exception while parsing to access parts.
      // Ignore, continue with the exception that we are reporting now.
    }

    if (exception is CaughtExceptionWithFiles) {
      for (var nested in exception.fileContentMap.entries) {
        fileContentMap['nested-${nested.key}'] = nested.value;
      }
    }

    _exceptionController.add(
      ExceptionResult(
        filePath: path,
        fileContentMap: fileContentMap,
        fileContent: libraryFile.content,
        exception: caught,
        contextKey: contextKey,
      ),
    );
  }

  /// Serialize the given [resolvedUnit] errors and index into bytes.
  Uint8List _serializeResolvedUnit(
      CompilationUnit resolvedUnit, List<AnalysisError> errors) {
    AnalysisDriverUnitIndexBuilder index = enableIndex
        ? indexUnit(resolvedUnit)
        : AnalysisDriverUnitIndexBuilder();
    return AnalysisDriverResolvedUnitBuilder(
            errors: errors.map((error) {
              return ErrorEncoding.encode(error);
            }).toList(),
            index: index)
        .toBuffer();
  }

  String? _storeExceptionContext(String path, FileState libraryFile,
      Object exception, StackTrace stackTrace) {
    if (allowedNumberOfContextsToWrite <= 0) {
      return null;
    } else {
      allowedNumberOfContextsToWrite--;
    }
    try {
      List<AnalysisDriverExceptionFileBuilder> contextFiles = libraryFile
          .transitiveFiles
          .map((file) => AnalysisDriverExceptionFileBuilder(
              path: file.path, content: file.content))
          .toList();
      contextFiles.sort((a, b) => a.path.compareTo(b.path));
      AnalysisDriverExceptionContextBuilder contextBuilder =
          AnalysisDriverExceptionContextBuilder(
              path: path,
              exception: exception.toString(),
              stackTrace: stackTrace.toString(),
              files: contextFiles);
      var bytes = contextBuilder.toBuffer();

      String _twoDigits(int n) {
        if (n >= 10) return '$n';
        return '0$n';
      }

      String _threeDigits(int n) {
        if (n >= 100) return '$n';
        if (n >= 10) return '0$n';
        return '00$n';
      }

      DateTime time = DateTime.now();
      String m = _twoDigits(time.month);
      String d = _twoDigits(time.day);
      String h = _twoDigits(time.hour);
      String min = _twoDigits(time.minute);
      String sec = _twoDigits(time.second);
      String ms = _threeDigits(time.millisecond);
      String key = 'exception_${time.year}$m${d}_$h$min${sec}_$ms';

      _byteStore.put(key, bytes);
      return key;
    } catch (_) {
      return null;
    }
  }

  /// The driver supports only absolute paths, this method is used to validate
  /// any input paths to prevent errors later.
  void _throwIfNotAbsolutePath(String path) {
    if (!_isAbsolutePath(path)) {
      throw ArgumentError('Only absolute paths are supported: $path');
    }
  }

  /// Given the list of [errors] for the [file], update the [file]'s
  /// [FileState.hasErrorOrWarning] flag.
  void _updateHasErrorOrWarningFlag(
      FileState file, List<AnalysisError> errors) {
    for (AnalysisError error in errors) {
      ErrorSeverity severity = error.errorCode.errorSeverity;
      if (severity == ErrorSeverity.ERROR ||
          severity == ErrorSeverity.WARNING) {
        file.hasErrorOrWarning = true;
        return;
      }
    }
    file.hasErrorOrWarning = false;
  }
}

/// A generic schedulable interface via the AnalysisDriverScheduler. Currently
/// only implemented by [AnalysisDriver] and the angular plugin, at least as
/// a temporary measure until the official plugin API is ready (and a different
/// scheduler is used)
abstract class AnalysisDriverGeneric {
  /// Return `true` if the driver has a file to analyze.
  bool get hasFilesToAnalyze;

  /// Set the list of files that the driver should try to analyze sooner.
  ///
  /// Every path in the list must be absolute and normalized.
  ///
  /// The driver will produce the results through the [results] stream. The
  /// exact order in which results are produced is not defined, neither
  /// between priority files, nor between priority and non-priority files.
  set priorityFiles(List<String> priorityPaths);

  /// Return the priority of work that the driver needs to perform.
  AnalysisDriverPriority get workPriority;

  /// Add the file with the given [path] to the set of files that are explicitly
  /// being analyzed.
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// The results of analysis are eventually produced by the [results] stream.
  void addFile(String path);

  /// Notify the driver that the client is going to stop using it.
  void dispose();

  /// Perform a single chunk of work and produce [results].
  Future<void> performWork();
}

/// Priorities of [AnalysisDriver] work. The farther a priority to the beginning
/// of the list, the earlier the corresponding [AnalysisDriver] should be asked
/// to perform work.
enum AnalysisDriverPriority {
  nothing,
  general,
  generalWithErrors,
  generalImportChanged,
  generalChanged,
  changedFiles,
  priority,
  interactive
}

/// Instances of this class schedule work in multiple [AnalysisDriver]s so that
/// work with the highest priority is performed first.
class AnalysisDriverScheduler {
  /// Time interval in milliseconds before pumping the event queue.
  ///
  /// Relinquishing execution flow and running the event loop after every task
  /// has too much overhead. Instead we use a fixed length of time, so we can
  /// spend less time overall and still respond quickly enough.
  static const int _MS_BEFORE_PUMPING_EVENT_QUEUE = 2;

  /// Event queue pumping is required to allow IO and other asynchronous data
  /// processing while analysis is active. For example Analysis Server needs to
  /// be able to process `updateContent` or `setPriorityFiles` requests while
  /// background analysis is in progress.
  ///
  /// The number of pumpings is arbitrary, might be changed if we see that
  /// analysis or other data processing tasks are starving. Ideally we would
  /// need to run all asynchronous operations using a single global scheduler.
  static const int _NUMBER_OF_EVENT_QUEUE_PUMPINGS = 128;

  final PerformanceLog _logger;

  /// The object used to watch as analysis drivers are created and deleted.
  final DriverWatcher? driverWatcher;

  final List<AnalysisDriverGeneric> _drivers = [];
  final Monitor _hasWork = Monitor();
  final StatusSupport _statusSupport = StatusSupport();

  bool _started = false;

  /// The optional worker that is invoked when its work priority is higher
  /// than work priorities in drivers.
  ///
  /// Don't use outside of Analyzer and Analysis Server.
  SchedulerWorker? outOfBandWorker;

  AnalysisDriverScheduler(this._logger, {this.driverWatcher});

  /// Return `true` if we are currently analyzing code.
  bool get isAnalyzing => _hasFilesToAnalyze;

  /// Return the stream that produces [AnalysisStatus] events.
  Stream<AnalysisStatus> get status => _statusSupport.stream;

  /// Return `true` if there is a driver with a file to analyze.
  bool get _hasFilesToAnalyze {
    for (AnalysisDriverGeneric driver in _drivers) {
      if (driver.hasFilesToAnalyze) {
        return true;
      }
    }
    return false;
  }

  /// Add the given [driver] and schedule it to perform its work.
  void add(AnalysisDriverGeneric driver) {
    _drivers.add(driver);
    _hasWork.notify();
    if (driver is AnalysisDriver && driver.analysisContext != null) {
      driverWatcher?.addedDriver(driver);
    }
  }

  /// Notify that there is a change to the [driver], it it might need to
  /// perform some work.
  void notify(AnalysisDriverGeneric? driver) {
    // TODO(brianwilkerson) Consider removing the parameter, given that it isn't
    //  referenced in the body.
    _hasWork.notify();
    _statusSupport.preTransitionToAnalyzing();
  }

  /// Remove the given [driver] from the scheduler, so that it will not be
  /// asked to perform any new work.
  void remove(AnalysisDriverGeneric driver) {
    if (driver is AnalysisDriver) {
      driverWatcher?.removedDriver(driver);
    }
    _drivers.remove(driver);
    _hasWork.notify();
  }

  /// Start the scheduler, so that any [AnalysisDriver] created before or
  /// after will be asked to perform work.
  void start() {
    if (_started) {
      throw StateError('The scheduler has already been started.');
    }
    _started = true;
    _run();
  }

  /// Usually we transition status to analyzing only if there are files to
  /// analyze. However when used in the server, there are rare cases when
  /// analysis roots don't have any Dart files, but for consistency we still
  /// want to get status to transition to analysis, and back to idle.
  void transitionToAnalyzingToIdleIfNoFilesToAnalyze() {
    if (!_hasFilesToAnalyze) {
      _statusSupport.transitionToAnalyzing();
      _statusSupport.transitionToIdle();
    }
  }

  /// Return a future that will be completed the next time the status is idle.
  ///
  /// If the status is currently idle, the returned future will be signaled
  /// immediately.
  Future<void> waitForIdle() => _statusSupport.waitForIdle();

  /// Run infinitely analysis cycle, selecting the drivers with the highest
  /// priority first.
  Future<void> _run() async {
    // Give other microtasks the time to run before doing the analysis cycle.
    await null;
    Stopwatch timer = Stopwatch()..start();
    PerformanceLogSection? analysisSection;
    while (true) {
      // Pump the event queue.
      if (timer.elapsedMilliseconds > _MS_BEFORE_PUMPING_EVENT_QUEUE) {
        await _pumpEventQueue(_NUMBER_OF_EVENT_QUEUE_PUMPINGS);
        timer.reset();
      }

      await _hasWork.signal;

      // Transition to analyzing if there are files to analyze.
      if (_hasFilesToAnalyze) {
        _statusSupport.transitionToAnalyzing();
        analysisSection ??= _logger.enter('Analyzing');
      }

      // Find the driver with the highest priority.
      late AnalysisDriverGeneric bestDriver;
      AnalysisDriverPriority bestPriority = AnalysisDriverPriority.nothing;
      for (AnalysisDriverGeneric driver in _drivers) {
        AnalysisDriverPriority priority = driver.workPriority;
        if (priority.index > bestPriority.index) {
          bestDriver = driver;
          bestPriority = priority;
        }
      }

      if (outOfBandWorker != null) {
        var workerPriority = outOfBandWorker!.workPriority;
        if (workerPriority != AnalysisDriverPriority.nothing) {
          if (workerPriority.index > bestPriority.index) {
            await outOfBandWorker!.performWork();
            _hasWork.notify();
            continue;
          }
        }
      }

      // Transition to idle if no files to analyze.
      if (!_hasFilesToAnalyze) {
        _statusSupport.transitionToIdle();
        analysisSection?.exit();
        analysisSection = null;
      }

      // Continue to sleep if no work to do.
      if (bestPriority == AnalysisDriverPriority.nothing) {
        continue;
      }

      // Ask the driver to perform a chunk of work.
      await bestDriver.performWork();

      // Schedule one more cycle.
      _hasWork.notify();
    }
  }

  /// Returns a [Future] that completes after performing [times] pumpings of
  /// the event queue.
  static Future _pumpEventQueue(int times) {
    if (times == 0) {
      return Future.value();
    }
    return Future.delayed(Duration.zero, () => _pumpEventQueue(times - 1));
  }
}

@visibleForTesting
class AnalysisDriverTestView {
  final AnalysisDriver driver;
  final LibraryContextTestView libraryContextTestView =
      LibraryContextTestView();

  int numOfAnalyzedLibraries = 0;

  AnalysisDriverTestView(this.driver);

  FileTracker get fileTracker => driver._fileTracker;

  LibraryContext? get libraryContext => driver._libraryContext;

  Map<String, ResolvedUnitResult> get priorityResults {
    return driver._priorityResults;
  }
}

/// The result of analyzing of a single file.
///
/// These results are self-consistent, i.e. the file content, line info, the
/// resolved unit correspond to each other. All referenced elements, even
/// external ones, are also self-consistent. But none of the results is
/// guaranteed to be consistent with the state of the files.
///
/// Every result is independent, and is not guaranteed to be consistent with
/// any previously returned result, even inside of the same library.
class AnalysisResult {
  /// The signature of the result based on the content of the file, and the
  /// transitive closure of files imported and exported by the library of
  /// the requested file.
  final String _signature;

  final bool isUnchangedErrors;

  /// Is not `null` if this result is a result with errors.
  /// Otherwise is `null`, and usually [unitResult] is set.
  final ErrorsResultImpl? errorsResult;

  /// Is not `null` if this result is a result with a resolved unit.
  /// Otherwise is `null`, and usually [errorsResult] is set.
  final ResolvedUnitResultImpl? unitResult;

  /// The index of the unit.
  final AnalysisDriverUnitIndex? _index;

  AnalysisResult.errors(
      this._signature, this.errorsResult, AnalysisDriverUnitIndex index)
      : isUnchangedErrors = false,
        unitResult = null,
        _index = index;

  AnalysisResult.unchangedErrors(this._signature)
      : isUnchangedErrors = true,
        errorsResult = null,
        unitResult = null,
        _index = null;

  AnalysisResult.unit(this._signature, ResolvedUnitResultImpl unitResult,
      AnalysisDriverUnitIndex index)
      : isUnchangedErrors = false,
        errorsResult = null,
        unitResult = unitResult,
        _index = index;
}

/// An object that watches for the creation and removal of analysis drivers.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DriverWatcher {
  /// The context manager has just added the given analysis [driver]. This method
  /// must be called before the driver has been allowed to perform any analysis.
  void addedDriver(AnalysisDriver driver);

  /// The context manager has just removed the given analysis [driver].
  void removedDriver(AnalysisDriver driver);
}

class ErrorEncoding {
  static AnalysisError? decode(
    Source source,
    AnalysisDriverUnitError error,
  ) {
    String errorName = error.uniqueName;
    ErrorCode? errorCode =
        errorCodeByUniqueName(errorName) ?? _lintCodeByUniqueName(errorName);
    if (errorCode == null) {
      // This could fail because the error code is no longer defined, or, in
      // the case of a lint rule, if the lint rule has been disabled since the
      // errors were written.
      AnalysisEngine.instance.instrumentationService
          .logError('No error code for "$error" in "$source"');
      return null;
    }

    var contextMessages = <DiagnosticMessageImpl>[];
    for (var message in error.contextMessages) {
      var url = message.url;
      contextMessages.add(
        DiagnosticMessageImpl(
          filePath: message.filePath,
          length: message.length,
          message: message.message,
          offset: message.offset,
          url: url.isEmpty ? null : url,
        ),
      );
    }

    return AnalysisError.forValues(
      source,
      error.offset,
      error.length,
      errorCode,
      error.message,
      error.correction.isEmpty ? null : error.correction,
      contextMessages: contextMessages,
    );
  }

  static AnalysisDriverUnitErrorBuilder encode(AnalysisError error) {
    var contextMessages = <DiagnosticMessageBuilder>[];
    for (var message in error.contextMessages) {
      contextMessages.add(
        DiagnosticMessageBuilder(
          filePath: message.filePath,
          length: message.length,
          message: message.messageText(includeUrl: false),
          offset: message.offset,
          url: message.url,
        ),
      );
    }

    return AnalysisDriverUnitErrorBuilder(
      offset: error.offset,
      length: error.length,
      uniqueName: error.errorCode.uniqueName,
      message: error.message,
      correction: error.correction ?? '',
      contextMessages: contextMessages,
    );
  }

  /// Return the lint code with the given [errorName], or `null` if there is no
  /// lint registered with that name.
  static ErrorCode? _lintCodeByUniqueName(String errorName) {
    return linter.Registry.ruleRegistry.codeForUniqueName(errorName);
  }
}

/// Exception that happened during analysis.
class ExceptionResult {
  /// The path of the library being analyzed when the [exception] happened.
  ///
  /// Absolute and normalized.
  final String filePath;

  /// The content of the library and its parts.
  final Map<String, String> fileContentMap;

  /// The path of the file being analyzed when the [exception] happened.
  @Deprecated('Use fileContentMap instead')
  final String fileContent;

  /// The exception during analysis of the file with the [filePath].
  final CaughtException exception;

  /// If the exception happened during a file analysis, and the context in which
  /// the exception happened was stored, this field is the key of the context
  /// in the byte store. May be `null` if the context is unknown, the maximum
  /// number of context to store was reached, etc.
  final String? contextKey;

  ExceptionResult({
    required this.filePath,
    required this.fileContentMap,
    required this.fileContent,
    required this.exception,
    required this.contextKey,
  });
}

/// Worker in [AnalysisDriverScheduler].
abstract class SchedulerWorker {
  /// Return the priority of work that this worker needs to perform.
  AnalysisDriverPriority get workPriority;

  /// Perform a single chunk of work.
  Future<void> performWork();
}

/// Task that discovers all files that are available to the driver, and makes
/// them known.
class _DiscoverAvailableFilesTask {
  static const int _MS_WORK_INTERVAL = 5;

  final AnalysisDriver driver;

  final Completer<void> completer = Completer<void>();

  Iterator<Folder>? folderIterator;

  final List<String> files = [];

  int fileIndex = 0;

  _DiscoverAvailableFilesTask(this.driver);

  bool get isCompleted => completer.isCompleted;

  /// Perform the next piece of work, and set [isCompleted] to `true` to
  /// indicate that the task is done, or keeps it `false` to indicate that the
  /// task should continue to be run.
  void perform() {
    if (folderIterator == null) {
      files.addAll(driver.addedFiles);

      // Discover SDK libraries.
      var dartSdk = driver._sourceFactory.dartSdk;
      if (dartSdk != null) {
        for (var sdkLibrary in dartSdk.sdkLibraries) {
          var file = dartSdk.mapDartUri(sdkLibrary.shortName)!.fullName;
          files.add(file);
        }
      }

      // Discover files in package/lib folders.
      var packageMap = driver._sourceFactory.packageMap;
      if (packageMap != null) {
        folderIterator = packageMap.values.expand((f) => f).iterator;
      } else {
        folderIterator = <Folder>[].iterator;
      }
    }

    // List each package/lib folder recursively.
    Stopwatch timer = Stopwatch()..start();
    while (folderIterator!.moveNext()) {
      var folder = folderIterator!.current;
      _appendFilesRecursively(folder);

      // Note: must check if we are exiting before calling moveNext()
      // otherwise we will skip one iteration of the loop when we come back.
      if (timer.elapsedMilliseconds > _MS_WORK_INTERVAL) {
        return;
      }
    }

    // Get know files one by one.
    while (fileIndex < files.length) {
      if (timer.elapsedMilliseconds > _MS_WORK_INTERVAL) {
        return;
      }
      var file = files[fileIndex++];
      driver._fsState.getFileForPath(file);
    }

    // The task is done, clean up.
    folderIterator = null;
    files.clear();
    completer.complete();
  }

  void _appendFilesRecursively(Folder folder) {
    try {
      var pathContext = driver.resourceProvider.pathContext;
      for (var child in folder.getChildren()) {
        if (child is File) {
          var path = child.path;
          if (file_paths.isDart(pathContext, path)) {
            files.add(path);
          }
        } else if (child is Folder) {
          _appendFilesRecursively(child);
        }
      }
    } catch (_) {}
  }
}

/// Information about an exception and its context.
class _ExceptionState {
  final Object exception;
  final StackTrace stackTrace;

  /// The key under which the context of the exception was stored, or `null`
  /// if unknown, the maximum number of context to store was reached, etc.
  final String? contextKey;

  _ExceptionState(this.exception, this.stackTrace, this.contextKey);

  @override
  String toString() => '$exception\n$stackTrace';
}

/// Task that computes the list of files that were added to the driver and
/// declare a class member with the given [name].
class _FilesDefiningClassMemberNameTask {
  static const int _MS_WORK_INTERVAL = 5;

  final AnalysisDriver driver;
  final String name;
  final Completer<List<String>> completer = Completer<List<String>>();

  final List<String> definingFiles = <String>[];
  final Set<String> checkedFiles = <String>{};
  final List<String> filesToCheck = <String>[];

  _FilesDefiningClassMemberNameTask(this.driver, this.name);

  /// Perform work for a fixed length of time, and complete the [completer] to
  /// either return `true` to indicate that the task is done, or return `false`
  /// to indicate that the task should continue to be run.
  ///
  /// Each invocation of an asynchronous method has overhead, which looks as
  /// `_SyncCompleter.complete` invocation, we see as much as 62% in some
  /// scenarios. Instead we use a fixed length of time, so we can spend less time
  /// overall and keep quick enough response time.
  bool perform() {
    Stopwatch timer = Stopwatch()..start();
    while (timer.elapsedMilliseconds < _MS_WORK_INTERVAL) {
      // Prepare files to check.
      if (filesToCheck.isEmpty) {
        Set<String> newFiles = driver.knownFiles.difference(checkedFiles);
        filesToCheck.addAll(newFiles);
      }

      // If no more files to check, complete and done.
      if (filesToCheck.isEmpty) {
        completer.complete(definingFiles);
        return true;
      }

      // Check the next file.
      String path = filesToCheck.removeLast();
      FileState file = driver._fsState.getFileForPath(path);
      if (file.definedClassMemberNames.contains(name)) {
        definingFiles.add(path);
      }
      checkedFiles.add(path);
    }

    // We're not done yet.
    return false;
  }
}

/// Task that computes the list of files that were added to the driver and
/// have at least one reference to an identifier [name] defined outside of the
/// file.
class _FilesReferencingNameTask {
  static const int _WORK_FILES = 100;
  static const int _MS_WORK_INTERVAL = 5;

  final AnalysisDriver driver;
  final String name;
  final Completer<List<String>> completer = Completer<List<String>>();

  int fileStamp = -1;
  List<FileState>? filesToCheck;
  int filesToCheckIndex = -1;

  final List<String> referencingFiles = <String>[];

  _FilesReferencingNameTask(this.driver, this.name);

  /// Perform work for a fixed length of time, and complete the [completer] to
  /// either return `true` to indicate that the task is done, or return `false`
  /// to indicate that the task should continue to be run.
  ///
  /// Each invocation of an asynchronous method has overhead, which looks as
  /// `_SyncCompleter.complete` invocation, we see as much as 62% in some
  /// scenarios. Instead we use a fixed length of time, so we can spend less time
  /// overall and keep quick enough response time.
  bool perform() {
    if (driver._fsState.fileStamp != fileStamp) {
      filesToCheck = null;
      referencingFiles.clear();
    }

    // Prepare files to check.
    if (filesToCheck == null) {
      fileStamp = driver._fsState.fileStamp;
      filesToCheck = driver._fsState.knownFiles;
      filesToCheckIndex = 0;
    }

    Stopwatch timer = Stopwatch()..start();
    while (filesToCheckIndex < filesToCheck!.length) {
      if (filesToCheckIndex % _WORK_FILES == 0 &&
          timer.elapsedMilliseconds > _MS_WORK_INTERVAL) {
        return false;
      }
      FileState file = filesToCheck![filesToCheckIndex++];
      if (file.referencedNames.contains(name)) {
        referencingFiles.add(file.path);
      }
    }

    // If no more files to check, complete and done.
    completer.complete(referencingFiles);
    return true;
  }
}
