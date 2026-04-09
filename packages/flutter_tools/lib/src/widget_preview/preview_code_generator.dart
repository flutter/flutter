// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart' as analyzer;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';

import '../base/file_system.dart';
import '../project.dart';
import 'dependency_graph.dart';
import 'dtd_types.dart';
import 'preview_details.dart';

typedef _PreviewMappingEntry = MapEntry<PreviewPath, LibraryPreviewNode>;

/// Generates the Dart source responsible for importing widget previews from the developer's project
/// into the widget preview scaffold.
class PreviewCodeGenerator {
  PreviewCodeGenerator({required this.widgetPreviewScaffoldProject, required this.fs});

  final FileSystem fs;

  /// The project for the widget preview scaffold found under `.dart_tool/` in the developer's
  /// project.
  final FlutterProject widgetPreviewScaffoldProject;

  static const _kBuildMultiWidgetPreview = 'buildMultiWidgetPreview';
  static const _kBuildWidgetPreview = 'buildWidgetPreview';
  static const _kBuildWidgetPreviewError = 'buildWidgetPreviewError';
  static const _kColumn = 'column';
  static const _kDependencyHasErrors = 'dependencyHasErrors';
  static const _kLine = 'line';
  static const _kListType = 'List';
  static const _kPackageName = 'packageName';
  static const _kPackageUri = 'packageUri';
  static const _kPreview = 'preview';
  static const _kPreviewFunction = 'previewFunction';
  static const _kPreviewFunctionName = 'functionName';
  static const _kPreviewsFunctionName = 'previews';
  static const _kScriptUri = 'scriptUri';
  static const _kTransform = 'transform';
  static const _kTransformedPreview = 'transformedPreview';
  static const _kUtilsUri = 'utils.dart';
  static const _kWidgetPreviewClass = 'WidgetPreview';
  static const _kWidgetPreviewLibraryUri = 'widget_preview.dart';

  static String getGeneratedPreviewFilePath(FileSystem fs) =>
      fs.path.join('lib', 'src', 'generated_preview.dart');

  static String getGeneratedDtdConnectionInfoFilePath(FileSystem fs) =>
      fs.path.join('lib', 'src', 'dtd', 'dtd_connection_info.dart');

  void populateDtdConnectionInfo({
    required Uri dtdUri,
    required String widgetPreviewServiceName,
    required String widgetPreviewScaffoldStreamName,
  }) {
    final emitter = cb.DartEmitter.scoped(useNullSafetySyntax: true);
    final lib = cb.Library(
      (cb.LibraryBuilder b) => b
        ..ignoreForFile.add('implementation_imports')
        ..body.addAll(<cb.Spec>[
          cb.Field((b) {
            b
              ..name = 'kWidgetPreviewDtdUri'
              ..modifier = cb.FieldModifier.constant
              ..type = cb.refer('String')
              ..assignment = cb.literalString(dtdUri.toString()).code;
          }),
          cb.Field((b) {
            b
              ..name = 'kWidgetPreviewService'
              ..modifier = cb.FieldModifier.constant
              ..type = cb.refer('String')
              ..assignment = cb.literalString(widgetPreviewServiceName).code;
          }),
          cb.Field((b) {
            b
              ..name = 'kWidgetPreviewScaffoldStream'
              ..modifier = cb.FieldModifier.constant
              ..type = cb.refer('String')
              ..assignment = cb.literalString(widgetPreviewScaffoldStreamName).code;
          }),
        ]),
    );
    final File generatedDtdConnectionInfoFile = fs.file(
      widgetPreviewScaffoldProject.directory.uri.resolve(getGeneratedDtdConnectionInfoFilePath(fs)),
    );
    generatedDtdConnectionInfoFile.writeAsStringSync(
      // Format the generated file for readability, particularly during feature development.
      // Note: we don't really care _how_ this is formatted, just that it's formatted, so we don't
      // specify a language version.
      DartFormatter(languageVersion: Version.none).format(lib.accept(emitter).toString()),
    );
  }

  // TODO(bkonyi): update generated example now that we're computing constants
  /// Generates code used by the widget preview scaffold based on the preview instances listed in
  /// [previews].
  ///
  /// The generated file will contain a single top level function named `previews()` which returns
  /// a `List<WidgetPreview>` that contains each widget preview defined in [previews].
  ///
  /// An example of a formatted generated file containing previews from two files could be:
  ///
  /// ```dart
  /// import 'widget_preview.dart' as _i1;
  /// import 'package:splash/foo.dart' as _i2;
  /// import 'package:splash/main.dart' as _i3;
  /// import 'package:flutter/widgets.dart' as _i4;
  ///
  /// List<_i1.WidgetPreview> previews() => [
  ///   _i1.WidgetPreview(height: 100.0, width: 10000.0, child: _i2.preview()),
  ///   _i1.WidgetPreview(
  ///     name: 'Foo',
  ///     height: 50 + 20,
  ///     width: 200.0,
  ///     textScaleFactor: 2.0,
  ///     child: _i3.preview(),
  ///   ),
  ///   _i1.WidgetPreview(
  ///     name: 'Baz',
  ///     height: 50.0,
  ///     width: 200.0,
  ///     textScaleFactor: 3.0,
  ///     child: _i2.stateInjector(_i3.preview()),
  ///   ),
  ///   _i1.WidgetPreview(name: 'Bar', child: _i4.Builder(builder: _i3.preview2())),
  ///   _i1.WidgetPreview(name: 'Constructor preview', height: 50.0, width: 100.0, child: _i3.MyWidget()),
  ///   _i1.WidgetPreview(
  ///     name: 'Named constructor preview',
  ///     height: 50.0,
  ///     width: 100.0,
  ///     child: _i3.MyWidget.preview(),
  ///   ),
  ///   _i1.WidgetPreview(
  ///     name: 'Static preview',
  ///     height: 50.0,
  ///     width: 100.0,
  ///     child: _i3.MyWidget.staticPreview(),
  ///   ),
  /// ];
  /// ```
  void populatePreviewsInGeneratedPreviewScaffold(PreviewDependencyGraph previews) {
    final emitter = cb.DartEmitter.scoped(useNullSafetySyntax: true);
    final lib = cb.Library(
      (cb.LibraryBuilder b) => b
        ..ignoreForFile.add('implementation_imports')
        ..body.addAll(<cb.Spec>[
          cb.Method(
            (cb.MethodBuilder b) => _buildGeneratedPreviewMethod(
              allocator: emitter.allocator,
              previews: previews,
              builder: b,
            ),
          ),
        ]),
    );
    _writeGeneratedPreviewFile(lib: lib, emitter: emitter);
  }

  void populatePreviewsInGeneratedPreviewScaffoldLsp(FlutterWidgetPreviews update) {
    final allocator = PreviewPrefixedAllocator()..populateKnownImportPrefixes(update.namespaces);
    final emitter = cb.DartEmitter(useNullSafetySyntax: true, allocator: allocator);
    final lib = cb.Library(
      (cb.LibraryBuilder b) => b
        ..ignoreForFile.add('implementation_imports')
        ..body.addAll(<cb.Spec>[
          cb.Method(
            (cb.MethodBuilder b) => _buildGeneratedPreviewMethodLsp(previews: update, builder: b),
          ),
        ]),
    );
    _writeGeneratedPreviewFile(lib: lib, emitter: emitter);
  }

  void _writeGeneratedPreviewFile({required cb.Library lib, required cb.DartEmitter emitter}) {
    final File generatedPreviewFile = fs.file(
      widgetPreviewScaffoldProject.directory.uri.resolve(getGeneratedPreviewFilePath(fs)),
    );
    final code = lib.accept(emitter).toString();
    generatedPreviewFile.writeAsStringSync(
      // Format the generated file for readability, particularly during feature development.
      DartFormatter(languageVersion: Version(3, 7, 0)).format(code),
    );
  }

  void _buildGeneratedPreviewMethod({
    required PreviewDependencyGraph previews,
    required cb.Allocator allocator,
    required cb.MethodBuilder builder,
  }) {
    // Sort the entries by URI so that the code generator assigns import prefixes in a
    // deterministic manner, mainly for testing purposes. This also results in previews being
    // displayed in the same order across platforms with differing path styles.
    final List<_PreviewMappingEntry> sortedPreviews = previews.entries.toList()
      ..sort((_PreviewMappingEntry a, _PreviewMappingEntry b) {
        return a.key.uri.toString().compareTo(b.key.uri.toString());
      });

    builder
      ..body = cb.literalList([
        for (final libraryPreviews in sortedPreviews)
          for (final preview in libraryPreviews.value.previews)
            _buildPreviews(
              preview: preview,
              uri: libraryPreviews.key.uri,
              libraryDetails: libraryPreviews.value,
            ),
      ]).code
      ..name = _kPreviewsFunctionName
      ..returns =
          (cb.TypeReferenceBuilder()
                ..symbol = _kListType
                ..types = ListBuilder<cb.Reference>(<cb.Reference>[
                  cb.refer(_kWidgetPreviewClass, _kWidgetPreviewLibraryUri),
                ]))
              .build();
  }

  void _buildGeneratedPreviewMethodLsp({
    required FlutterWidgetPreviews previews,
    required cb.MethodBuilder builder,
  }) {
    // Sort the entries by URI so that the code generator assigns import prefixes in a
    // deterministic manner, mainly for testing purposes. This also results in previews being
    // displayed in the same order across platforms with differing path styles.
    final List<FlutterWidgetPreviewDetails> sortedPreviews = previews.previews.toList()
      ..sort((FlutterWidgetPreviewDetails a, FlutterWidgetPreviewDetails b) {
        return a.scriptUri.toString().compareTo(b.scriptUri.toString());
      });

    builder
      ..body = cb.literalList([
        for (final preview in sortedPreviews)
          _buildPreviewsLsp(preview: preview, uri: preview.libraryUri),
      ]).code
      ..name = _kPreviewsFunctionName
      ..returns =
          (cb.TypeReferenceBuilder()
                ..symbol = _kListType
                ..types = ListBuilder<cb.Reference>(<cb.Reference>[
                  cb.refer(_kWidgetPreviewClass, _kWidgetPreviewLibraryUri),
                ]))
              .build();
  }

  cb.Expression _buildPreviews({
    required PreviewDetails preview,
    required Uri uri,
    required LibraryPreviewNode libraryDetails,
  }) {
    final args = <String, cb.Expression>{
      _kPackageName: cb.literalString(preview.packageName!),
      _kScriptUri: cb.literalString(preview.scriptUri.toString()),
      _kLine: cb.literalNum(preview.line),
      _kColumn: cb.literalNum(preview.column),
    };
    // TODO(bkonyi): improve the error related code.
    if (libraryDetails.hasErrors || libraryDetails.dependencyHasErrors) {
      return cb.refer(_kBuildWidgetPreviewError, _kUtilsUri).call([], {
        ...args,
        _kPackageUri: cb.literalString(uri.toString()),
        _kPreviewFunctionName: cb.literalString(preview.functionName),
        _kDependencyHasErrors: cb.literalBool(libraryDetails.dependencyHasErrors),
      });
    }

    final cb.Expression previewWidget = cb
        .refer(preview.functionName, uri.toString())
        .call(<cb.Expression>[]);

    args.addAll({
      _kPreviewFunction: cb.Method((builder) => builder.body = previewWidget.code).closure,
    });

    if (preview.isMultiPreview) {
      return cb.refer(_kBuildMultiWidgetPreview, _kUtilsUri).call([], {
        ...args,
        _kPreview: preview.previewAnnotation.toExpression(),
      }).spread;
    }

    return cb.refer(_kBuildWidgetPreview, _kUtilsUri).call([], {
      ...args,
      _kTransformedPreview: preview.previewAnnotation.toExpression().property(_kTransform).call([]),
    });
  }

  cb.Expression _buildPreviewsLsp({
    required FlutterWidgetPreviewDetails preview,
    required Uri uri,
  }) {
    final args = <String, cb.Expression>{
      _kPackageName: cb.literalString(preview.packageName!),
      _kScriptUri: cb.literalString(preview.scriptUri.toString()),
      _kLine: cb.literalNum(preview.position.line),
      _kColumn: cb.literalNum(preview.position.character),
    };
    // TODO(bkonyi): improve the error related code.
    if (preview.hasError || preview.dependencyHasErrors) {
      return cb.refer(_kBuildWidgetPreviewError, _kUtilsUri).call([], {
        ...args,
        _kPackageUri: cb.literalString(uri.toString()),
        _kPreviewFunctionName: cb.literalString(preview.functionName),
        _kDependencyHasErrors: cb.literalBool(preview.dependencyHasErrors),
      });
    }

    final cb.Expression previewWidget = cb
        .refer(preview.functionName, uri.toString())
        .call(<cb.Expression>[]);

    args.addAll({
      _kPreviewFunction: cb.Method((builder) => builder.body = previewWidget.code).closure,
    });

    if (preview.isMultiPreview) {
      return cb.refer(_kBuildMultiWidgetPreview, _kUtilsUri).call([], {
        ...args,
        _kPreview: cb.CodeExpression(cb.Code(preview.previewAnnotation)),
      }).spread;
    }

    return cb.refer(_kBuildWidgetPreview, _kUtilsUri).call([], {
      ...args,
      _kTransformedPreview: cb.CodeExpression(
        cb.Code(preview.previewAnnotation),
      ).property(_kTransform).call([]),
    });
  }
}

extension on DartObject {
  cb.Expression toExpression() {
    final DartType type = this.type!;
    return switch (type) {
      DartType(isDartCoreBool: true) => cb.literalBool(toBoolValue()!),
      DartType(isDartCoreDouble: true) => cb.literalNum(toDoubleValue()!),
      DartType(isDartCoreInt: true) => cb.literalNum(toIntValue()!),
      DartType(isDartCoreString: true) => cb.literalString(toStringValue()!),
      DartType(isDartCoreNull: true) => cb.literalNull,
      DartType(isDartCoreList: true) => cb.literalList([
        for (final item in toListValue()!) item.toExpression(),
      ]),
      DartType(isDartCoreMap: true) => cb.literalMap(
        toMapValue()!.map(
          (key, value) => MapEntry(
            key?.toExpression() ?? cb.literalNull,
            value?.toExpression() ?? cb.literalNull,
          ),
        ),
      ),
      DartType(isDartCoreSet: true) => cb.literalSet([
        for (final item in toSetValue()!) item.toExpression(),
      ]),
      RecordType() => () {
        final (:Map<String, DartObject> named, :List<DartObject> positional) = toRecordValue()!;
        return cb.literalRecord(
          positional.map((field) => field.toExpression()).toList(),
          named.map((key, value) => MapEntry(key, value.toExpression())),
        );
      }(),
      InterfaceType(element: EnumElement()) => _createEnumInstance(this),
      InterfaceType() => _createInstance(type, this),
      FunctionType() => _createTearoff(toFunctionValue()!),
      _ => throw UnsupportedError('Unexpected DartObject type: $runtimeType'),
    };
  }

  cb.Expression _createTearoff(ExecutableElement element) {
    return cb.refer(element.displayName, _elementToLibraryIdentifier(element));
  }

  cb.Expression _createEnumInstance(DartObject object) {
    final VariableElement variable = object.variable!;
    return switch (variable) {
      FieldElement(
        isEnumConstant: true,
        displayName: final enumValue,
        enclosingElement: EnumElement(displayName: final enumName),
      ) =>
        cb.refer('$enumName.$enumValue', _elementToLibraryIdentifier(variable)),
      PropertyInducingElement(:final displayName) => cb.refer(
        displayName,
        _elementToLibraryIdentifier(variable),
      ),
      _ => throw UnsupportedError('Unexpected enum variable type: ${variable.runtimeType}'),
    };
  }

  cb.Expression _createInstance(InterfaceType dartType, DartObject object) {
    final ConstructorInvocation constructorInvocation = object.constructorInvocation!;
    final ConstructorElement constructor = constructorInvocation.constructor;
    final cb.Expression type = cb.refer(
      dartType.element.name!,
      _elementToLibraryIdentifier(dartType.element),
    );
    final String? name = constructor.name == 'new' ? null : constructor.name;

    final List<cb.Expression> positionalArguments = constructorInvocation.positionalArguments
        .map((e) => e.toExpression())
        .toList();
    final namedArguments = <String, cb.Expression>{
      for (final MapEntry(key: name, :value) in constructorInvocation.namedArguments.entries)
        name: value.toExpression(),
    };
    // TODO(bkonyi): handle type arguments?
    final typeArguments = <cb.Reference>[];
    return cb.InvokeExpression.constOf(
      type,
      positionalArguments,
      namedArguments,
      typeArguments,
      name,
    );
  }

  /// Returns the import URI for the [analyzer.LibraryElement] containing [element].
  String? _elementToLibraryIdentifier(analyzer.Element? element) => element?.library!.identifier;
}

class PreviewPrefixedAllocator implements cb.Allocator {
  static const _doNotPrefix = ['dart:core'];

  final _imports = <String, int>{};
  static const _kInitialKey = 1;
  int _keys = _kInitialKey;

  @override
  String allocate(cb.Reference reference) {
    final String? symbol = reference.symbol;
    String? url = reference.url;
    if (url == null || _doNotPrefix.contains(url)) {
      return symbol!;
    }
    url = _fixUrl(url);
    return '_i${_imports.putIfAbsent(url, _nextKey)}.$symbol';
  }

  void populateKnownImportPrefixes(Map<String, String> imports) {
    if (_keys != _kInitialKey) {
      throw StateError(
        'Attempted to populated known import prefixes when prefixes have been allocated',
      );
    }
    _imports.addAll({
      for (final MapEntry(:key, :value) in imports.entries) key: int.parse(value.substring(2)),
    });
    _keys += _imports.length;
  }

  int _nextKey() => _keys++;

  @override
  Iterable<cb.Directive> get imports =>
      _imports.keys.map((u) => cb.Directive.import(u, as: '_i${_imports[u]}'));
}

/// Applies hardcoded fixes to [url].
///
/// See [cb.Allocator.imports] for explanations.
String _fixUrl(String url) {
  if (url.startsWith('package:fixnum/src/')) {
    return 'package:fixnum/fixnum.dart';
  }
  return url;
}
