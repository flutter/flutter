// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:meta/meta.dart';
import 'package:watcher/watcher.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/utils.dart';
import 'preview_code_generator.dart';

/// A path / URI pair used to map previews to a file.
///
/// We don't just use a path or a URI as the file watcher doesn't report URIs
/// (e.g., package:*) but the analyzer APIs do, and the code generator emits
/// package URIs for preview imports.
typedef PreviewPath = ({String path, Uri uri});

/// Represents a set of previews for a given file.
typedef PreviewMapping = Map<PreviewPath, List<PreviewDetails>>;

extension on Token {
  /// Convenience getter to identify tokens for private fields and functions.
  bool get isPrivate => toString().startsWith('_');

  /// Convenience getter to identify WidgetBuilder types.
  bool get isWidgetBuilder => toString() == 'WidgetBuilder';
}

extension on Annotation {
  /// Convenience getter to identify `@Preview` annotations
  bool get isPreview => name.name == 'Preview';
}

/// Convenience getters for examining [String] paths.
extension on String {
  bool get isDartFile => endsWith('.dart');
  bool get isPubspec => endsWith('pubspec.yaml');
  bool get doesContainDartTool => contains('.dart_tool');
  bool get isGeneratedPreviewFile => endsWith(PreviewCodeGenerator.generatedPreviewFilePath);
}

extension on ParsedUnitResult {
  /// Convenience method to package [path] and [uri] into a [PreviewPath]
  PreviewPath toPreviewPath() => (path: path, uri: uri);
}

/// Contains details related to a single preview instance.
final class PreviewDetails {
  PreviewDetails({required this.functionName, required this.isBuilder});

  @visibleForTesting
  PreviewDetails.test({
    required this.functionName,
    required this.isBuilder,
    String? name,
    String? width,
    String? height,
    String? textScaleFactor,
    String? wrapper,
    String? wrapperLibraryUri = '',
  }) : _name = name,
       _width = width,
       _height = height,
       _textScaleFactor = textScaleFactor,
       _wrapper = wrapper,
       _wrapperLibraryUri = wrapperLibraryUri;

  @visibleForTesting
  PreviewDetails copyWith({
    String? functionName,
    bool? isBuilder,
    String? name,
    String? width,
    String? height,
    String? textScaleFactor,
    String? wrapper,
    String? wrapperLibraryUri,
  }) {
    return PreviewDetails.test(
      functionName: functionName ?? this.functionName,
      isBuilder: isBuilder ?? this.isBuilder,
      name: name ?? this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      wrapper: wrapper ?? this.wrapper,
      wrapperLibraryUri: wrapperLibraryUri ?? this.wrapperLibraryUri,
    );
  }

  static const String kName = 'name';
  static const String kWidth = 'width';
  static const String kHeight = 'height';
  static const String kTextScaleFactor = 'textScaleFactor';
  static const String kWrapper = 'wrapper';
  static const String kWrapperLibraryUri = 'wrapperLibraryUrl';

  /// The name of the function returning the preview.
  final String functionName;

  /// Set to `true` if the preview function is returning a [WidgetBuilder]
  /// instead of a [Widget].
  final bool isBuilder;

  /// A description to be displayed alongside the preview.
  ///
  /// If not provided, no name will be associated with the preview.
  String? get name => _name;
  String? _name;

  /// Artificial width constraint to be applied to the [child].
  ///
  /// If not provided, the previewed widget will attempt to set its own width
  /// constraints and may result in an unbounded constraint error.
  String? get width => _width;
  String? _width;

  /// Artificial height constraint to be applied to the [child].
  ///
  /// If not provided, the previewed widget will attempt to set its own height
  /// constraints and may result in an unbounded constraint error.
  String? get height => _height;
  String? _height;

  /// Applies font scaling to text within the [child].
  ///
  /// If not provided, the default text scaling factor provided by [MediaQuery]
  /// will be used.
  String? get textScaleFactor => _textScaleFactor;
  String? _textScaleFactor;

  /// The name of a tear-off used to wrap the [Widget] returned by the preview
  /// function defined by [functionName].
  ///
  /// If not provided, the [Widget] returned by [functionName] will be used by
  /// the previewer directly.
  String? get wrapper => _wrapper;
  String? _wrapper;

  /// The URI for the library containing the declaration of [wrapper].
  String? get wrapperLibraryUri => _wrapperLibraryUri;
  String? _wrapperLibraryUri;

  bool get hasWrapper => _wrapper != null;

  void _setField({required NamedExpression node}) {
    final String key = node.name.label.name;
    final Expression expression = node.expression;
    final String source = expression.toSource();
    switch (key) {
      case kName:
        _name = source;
      case kWidth:
        _width = source;
      case kHeight:
        _height = source;
      case kTextScaleFactor:
        _textScaleFactor = source;
      case kWrapper:
        _wrapper = source;
        _wrapperLibraryUri = (node.expression as SimpleIdentifier).element!.library2!.identifier;
      default:
        throw StateError('Unknown Preview field "$name": $source');
    }
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    return other.runtimeType == runtimeType &&
        other is PreviewDetails &&
        other.functionName == functionName &&
        other.isBuilder == isBuilder &&
        other.height == height &&
        other.width == width &&
        other.textScaleFactor == textScaleFactor &&
        other.wrapper == wrapper &&
        other.wrapperLibraryUri == wrapperLibraryUri;
  }

  @override
  String toString() =>
      'PreviewDetails(function: $functionName isBuilder: $isBuilder $kName: $name '
      '$kWidth: $width $kHeight: $height $kTextScaleFactor: $textScaleFactor $kWrapper: $wrapper '
      '$kWrapperLibraryUri: $wrapperLibraryUri)';

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hashAll(<Object?>[
    functionName,
    isBuilder,
    height,
    width,
    textScaleFactor,
    wrapper,
    wrapperLibraryUri,
  ]);
}

class PreviewDetector {
  PreviewDetector({
    required this.projectRoot,
    required this.fs,
    required this.logger,
    required this.onChangeDetected,
    required this.onPubspecChangeDetected,
  });

  final Directory projectRoot;
  final FileSystem fs;
  final Logger logger;
  final void Function(PreviewMapping) onChangeDetected;
  final void Function() onPubspecChangeDetected;

  StreamSubscription<WatchEvent>? _fileWatcher;
  final PreviewDetectorMutex _mutex = PreviewDetectorMutex();
  late final PreviewMapping _pathToPreviews;

  late final AnalysisContextCollection collection = AnalysisContextCollection(
    includedPaths: <String>[projectRoot.absolute.path],
    resourceProvider: PhysicalResourceProvider.INSTANCE,
  );

  /// Starts listening for changes to Dart sources under [projectRoot] and returns
  /// the initial [PreviewMapping] for the project.
  Future<PreviewMapping> initialize() async {
    // Find the initial set of previews.
    _pathToPreviews = await findPreviewFunctions(projectRoot);

    final Watcher watcher = Watcher(projectRoot.path);
    _fileWatcher = watcher.events.listen((WatchEvent event) async {
      final String eventPath = event.path;
      // If the pubspec has changed, new dependencies or assets could have been added, requiring
      // the preview scaffold's pubspec to be updated.
      if (eventPath.isPubspec && !eventPath.doesContainDartTool) {
        onPubspecChangeDetected();
        return;
      }
      // Only trigger a reload when changes to Dart sources are detected. We
      // ignore the generated preview file to avoid getting stuck in a loop.
      if (!eventPath.isDartFile || eventPath.isGeneratedPreviewFile) {
        return;
      }
      logger.printStatus('Detected change in $eventPath.');
      final PreviewMapping filePreviewsMapping = await findPreviewFunctions(
        fs.file(Uri.file(event.path)),
      );
      final bool hasExistingPreviews =
          _pathToPreviews.keys.where((PreviewPath e) => e.path == event.path).isNotEmpty;
      if (filePreviewsMapping.isEmpty && !hasExistingPreviews) {
        // No previews found or removed, nothing to do.
        return;
      }
      if (filePreviewsMapping.length > 1) {
        logger.printWarning('Previews from more than one file were detected!');
        logger.printWarning('Previews: $filePreviewsMapping');
      }
      if (filePreviewsMapping.isNotEmpty) {
        // The set of previews has changed, but there are still previews in the file.
        final MapEntry<PreviewPath, List<PreviewDetails>>(
          key: PreviewPath location,
          value: List<PreviewDetails> filePreviews,
        ) = filePreviewsMapping.entries.first;
        logger.printStatus('Updated previews for ${location.uri}: $filePreviews');
        if (filePreviews.isNotEmpty) {
          final List<PreviewDetails>? currentPreviewsForFile = _pathToPreviews[location];
          if (filePreviews != currentPreviewsForFile) {
            _pathToPreviews[location] = filePreviews;
          }
        }
      } else {
        // The file previously had previews that were removed.
        logger.printStatus('Previews removed from $eventPath');
        _pathToPreviews.removeWhere((PreviewPath e, _) => e.path == eventPath);
      }
      onChangeDetected(_pathToPreviews);
    });
    // Wait for file watcher to finish initializing, otherwise we might miss changes and cause
    // tests to flake.
    await watcher.ready;
    return _pathToPreviews;
  }

  Future<void> dispose() async {
    // Guard disposal behind a mutex to make sure the analyzer has finished
    // processing the latest file updates to avoid throwing an exception.
    await _mutex.runGuarded(() async {
      await _fileWatcher?.cancel();
      await collection.dispose();
    });
  }

  /// Search for functions annotated with `@Preview` in the current project.
  Future<PreviewMapping> findPreviewFunctions(FileSystemEntity entity) async {
    final PreviewMapping previews = PreviewMapping();
    // Only process one FileSystemEntity at a time so we don't invalidate an AnalysisSession that's
    // in use when we call context.changeFile(...).
    await _mutex.runGuarded(() async {
      // TODO(bkonyi): this can probably be replaced by a call to collection.contextFor(...),
      // but we need to figure out the right path format for Windows.
      for (final AnalysisContext context in collection.contexts) {
        logger.printStatus('Finding previews in ${entity.path}...');

        // If we're processing a single file, it means the file watcher detected a
        // change in a Dart source. We need to notify the analyzer that this file
        // has changed so it can reanalyze the file.
        if (entity is File) {
          context.changeFile(entity.path);
          await context.applyPendingFileChanges();
        }

        for (final String filePath in context.contextRoot.analyzedFiles()) {
          logger.printTrace('Checking file: $filePath');
          if (!filePath.isDartFile || !filePath.startsWith(entity.path)) {
            logger.printTrace('Skipping $filePath');
            continue;
          }
          final SomeResolvedLibraryResult lib = await context.currentSession.getResolvedLibrary(
            filePath,
          );
          // TODO(bkonyi): ensure this can handle part files.
          if (lib is ResolvedLibraryResult) {
            for (final ResolvedUnitResult libUnit in lib.units) {
              final List<PreviewDetails> previewEntries =
                  previews[libUnit.toPreviewPath()] ?? <PreviewDetails>[];
              final PreviewVisitor visitor = PreviewVisitor();
              libUnit.unit.visitChildren(visitor);
              previewEntries.addAll(visitor.previewEntries);
              if (previewEntries.isNotEmpty) {
                previews[libUnit.toPreviewPath()] = previewEntries;
              }
            }
          } else {
            logger.printWarning('Unknown library type at $filePath: $lib');
          }
        }
      }
      final int previewCount = previews.values.fold<int>(
        0,
        (int count, List<PreviewDetails> value) => count + value.length,
      );
      logger.printStatus('Found $previewCount ${pluralize('preview', previewCount)}.');
    });
    return previews;
  }
}

/// Visitor which detects previews and extracts [PreviewDetails] for later code
/// generation.
// TODO(bkonyi): this visitor needs better error detection to identify invalid
// previews and report them to the previewer without causing the entire
// environment to shutdown or fail to render valid previews.
class PreviewVisitor extends RecursiveAstVisitor<void> {
  final List<PreviewDetails> previewEntries = <PreviewDetails>[];

  FunctionDeclaration? _currentFunction;
  ConstructorDeclaration? _currentConstructor;
  MethodDeclaration? _currentMethod;
  PreviewDetails? _currentPreview;

  /// Handles previews defined on top-level functions.
  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    assert(_currentFunction == null);
    if (node.name.isPrivate) {
      return;
    }

    final TypeAnnotation? returnType = node.returnType;
    if (returnType == null || returnType.question != null) {
      return;
    }
    _scopedVisitChildren(node, (FunctionDeclaration? node) => _currentFunction = node);
  }

  /// Handles previews defined on constructors.
  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _scopedVisitChildren(node, (ConstructorDeclaration? node) => _currentConstructor = node);
  }

  /// Handles previews defined on static methods within classes.
  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!node.isStatic) {
      return;
    }
    _scopedVisitChildren(node, (MethodDeclaration? node) => _currentMethod = node);
  }

  @override
  void visitAnnotation(Annotation node) {
    if (!node.isPreview) {
      return;
    }
    assert(_currentFunction != null || _currentConstructor != null || _currentMethod != null);
    if (_currentFunction != null) {
      final NamedType returnType = _currentFunction!.returnType! as NamedType;
      _currentPreview = PreviewDetails(
        functionName: _currentFunction!.name.toString(),
        isBuilder: returnType.name2.isWidgetBuilder,
      );
    } else if (_currentConstructor != null) {
      final SimpleIdentifier returnType = _currentConstructor!.returnType as SimpleIdentifier;
      final Token? name = _currentConstructor!.name;
      _currentPreview = PreviewDetails(
        functionName: '$returnType${name == null ? '' : '.$name'}',
        isBuilder: false,
      );
    } else if (_currentMethod != null) {
      final NamedType returnType = _currentMethod!.returnType! as NamedType;
      final ClassDeclaration parentClass = _currentMethod!.parent! as ClassDeclaration;
      _currentPreview = PreviewDetails(
        functionName: '${parentClass.name}.${_currentMethod!.name}',
        isBuilder: returnType.name2.isWidgetBuilder,
      );
    }
    node.visitChildren(this);
    previewEntries.add(_currentPreview!);
    _currentPreview = null;
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    // Extracts named properties from the @Preview annotation.
    _currentPreview?._setField(node: node);
  }

  void _scopedVisitChildren<T extends AstNode>(T node, void Function(T?) setter) {
    setter(node);
    node.visitChildren(this);
    setter(null);
  }
}

/// Used to protect global state accessed in blocks containing calls to
/// asynchronous methods.
///
/// Originally from DDS:
/// https://github.com/dart-lang/sdk/blob/3fe58da3cfe2c03fb9ee691a7a4709082fad3e73/pkg/dds/lib/src/utils/mutex.dart
class PreviewDetectorMutex {
  /// Executes a block of code containing asynchronous calls atomically.
  ///
  /// If no other asynchronous context is currently executing within
  /// [criticalSection], it will immediately be called. Otherwise, the
  /// caller will be suspended and entered into a queue to be resumed once the
  /// lock is released.
  Future<T> runGuarded<T>(FutureOr<T> Function() criticalSection) async {
    try {
      await _acquireLock();
      return await criticalSection();
    } finally {
      _releaseLock();
    }
  }

  Future<void> _acquireLock() async {
    if (!_locked) {
      _locked = true;
      return;
    }

    final Completer<void> request = Completer<void>();
    _outstandingRequests.add(request);
    await request.future;
  }

  void _releaseLock() {
    if (_outstandingRequests.isNotEmpty) {
      final Completer<void> request = _outstandingRequests.removeFirst();
      request.complete();
      return;
    }
    // Only release the lock if no other requests are pending to prevent races
    // between the next request from the queue to be handled and incoming
    // requests.
    _locked = false;
  }

  bool _locked = false;
  final Queue<Completer<void>> _outstandingRequests = Queue<Completer<void>>();
}
