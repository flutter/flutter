// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart' as analyzer;
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
// ignore: implementation_imports, can be removed when package:analyzer 8.1.0 is released.
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';

import '../base/file_system.dart';
import '../project.dart';
import 'dependency_graph.dart';
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

  static const _kBuilderType = 'Builder';
  static const _kBuilderLibraryUri = 'package:flutter/widgets.dart';
  static const _kBuilderProperty = 'builder';
  static const _kListType = 'List';
  static const _kPreviewsFunctionName = 'previews';
  static const _kWidgetPreviewClass = 'WidgetPreview';
  static const _kWidgetPreviewLibraryUri = 'widget_preview.dart';

  static String getGeneratedPreviewFilePath(FileSystem fs) =>
      fs.path.join('lib', 'src', 'generated_preview.dart');

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
      (cb.LibraryBuilder b) => b.body.addAll(<cb.Spec>[
        cb.Method(
          (cb.MethodBuilder b) => _buildGeneratedPreviewMethod(
            allocator: emitter.allocator,
            previews: previews,
            builder: b,
          ),
        ),
      ]),
    );
    final File generatedPreviewFile = fs.file(
      widgetPreviewScaffoldProject.directory.uri.resolve(getGeneratedPreviewFilePath(fs)),
    );
    generatedPreviewFile.writeAsStringSync(
      // Format the generated file for readability, particularly during feature development.
      // Note: we don't really care _how_ this is formatted, just that it's formatted, so we don't
      // specify a language version.
      DartFormatter(languageVersion: Version.none).format(lib.accept(emitter).toString()),
    );
  }

  void _buildGeneratedPreviewMethod({
    required PreviewDependencyGraph previews,
    required cb.Allocator allocator,
    required cb.MethodBuilder builder,
  }) {
    final previewExpressions = <cb.Expression>[];
    // Sort the entries by URI so that the code generator assigns import prefixes in a
    // deterministic manner, mainly for testing purposes. This also results in previews being
    // displayed in the same order across platforms with differing path styles.
    final List<_PreviewMappingEntry> sortedPreviews = previews.entries.toList()
      ..sort((_PreviewMappingEntry a, _PreviewMappingEntry b) {
        return a.key.uri.toString().compareTo(b.key.uri.toString());
      });
    for (final _PreviewMappingEntry(
          key: (path: String _, :Uri uri),
          value: LibraryPreviewNode libraryDetails,
        )
        in sortedPreviews) {
      for (final PreviewDetails preview in libraryDetails.previews) {
        previewExpressions.add(
          _buildPreviewWidget(
            allocator: allocator,
            preview: preview,
            uri: uri,
            libraryDetails: libraryDetails,
          ),
        );
      }
    }
    builder
      ..body = cb.literalList(previewExpressions).code
      ..name = _kPreviewsFunctionName
      ..returns =
          (cb.TypeReferenceBuilder()
                ..symbol = _kListType
                ..types = ListBuilder<cb.Reference>(<cb.Reference>[
                  cb.refer(_kWidgetPreviewClass, _kWidgetPreviewLibraryUri),
                ]))
              .build();
  }

  cb.Expression _buildPreviewWidget({
    required cb.Allocator allocator,
    required PreviewDetails preview,
    required Uri uri,
    required LibraryPreviewNode libraryDetails,
  }) {
    cb.Expression previewWidget;
    // TODO(bkonyi): clean up the error related code.
    if (libraryDetails.hasErrors) {
      previewWidget = cb.refer('Text', 'package:flutter/material.dart').newInstance(<cb.Expression>[
        cb.literalString('$uri has errors!'),
      ]);
    } else if (libraryDetails.dependencyHasErrors) {
      previewWidget = cb.refer('Text', 'package:flutter/material.dart').newInstance(<cb.Expression>[
        cb.literalString('Dependency of $uri has errors!'),
      ]);
    } else {
      previewWidget = cb.refer(preview.functionName, uri.toString()).call(<cb.Expression>[]);

      if (preview.isBuilder) {
        previewWidget = cb.refer(_kBuilderType, _kBuilderLibraryUri).newInstance(
          <cb.Expression>[],
          <String, cb.Expression>{_kBuilderProperty: previewWidget},
        );
      }

      if (preview.hasWrapper) {
        previewWidget = preview.wrapper.toExpression().call(<cb.Expression>[previewWidget]);
      }
    }

    previewWidget = cb.Method((cb.MethodBuilder previewBuilder) {
      previewBuilder.body = previewWidget.code;
    }).closure;

    return cb.refer(_kWidgetPreviewClass, _kWidgetPreviewLibraryUri).newInstance(
      <cb.Expression>[],
      <String, cb.Expression>{
        // TODO(bkonyi): try to display the preview name, even if the preview can't be displayed.
        if (!libraryDetails.dependencyHasErrors &&
            !libraryDetails.hasErrors) ...<String, cb.Expression>{
          if (preview.packageName != null)
            PreviewDetails.kPackageName: cb.literalString(preview.packageName!),
          ...?_generateCodeFromAnalyzerExpression(
            allocator: allocator,
            key: PreviewDetails.kName,
            object: preview.name,
          ),
          ...?_generateCodeFromAnalyzerExpression(
            allocator: allocator,
            key: PreviewDetails.kSize,
            object: preview.size,
          ),
          ...?_generateCodeFromAnalyzerExpression(
            allocator: allocator,
            key: PreviewDetails.kTextScaleFactor,
            object: preview.textScaleFactor,
          ),
          ...?_generateCodeFromAnalyzerExpression(
            allocator: allocator,
            key: PreviewDetails.kTheme,
            object: preview.theme,
            isCallback: true,
          ),
          ...?_generateCodeFromAnalyzerExpression(
            allocator: allocator,
            key: PreviewDetails.kBrightness,
            object: preview.brightness,
          ),
          ...?_generateCodeFromAnalyzerExpression(
            allocator: allocator,
            key: PreviewDetails.kLocalizations,
            object: preview.localizations,
            isCallback: true,
          ),
        },
        _kBuilderProperty: previewWidget,
      },
    );
  }

  Map<String, cb.Expression>? _generateCodeFromAnalyzerExpression({
    required cb.Allocator allocator,
    required String key,
    required DartObject? object,
    bool isCallback = false,
  }) {
    if (object == null || object.isNull) {
      return null;
    }
    cb.Expression expression = object.toExpression();
    if (isCallback) {
      expression = expression.call(<cb.Expression>[]);
    }
    return <String, cb.Expression>{key: expression};
  }
}

extension on DartObject {
  cb.Expression toExpression() {
    final objectImpl = this as DartObjectImpl;
    final DartType type = this.type!;
    return switch (type) {
      DartType(isDartCoreBool: true) => cb.literalBool(toBoolValue()!),
      DartType(isDartCoreDouble: true) => cb.literalNum(toDoubleValue()!),
      DartType(isDartCoreInt: true) => cb.literalNum(toIntValue()!),
      DartType(isDartCoreString: true) => cb.literalString(toStringValue()!),
      DartType(isDartCoreNull: true) => cb.literalNull,
      InterfaceType(element3: EnumElement2()) => _createEnumInstance(objectImpl),
      InterfaceType() => _createInstance(type, objectImpl),
      FunctionType() => _createTearoff(toFunctionValue2()!),
      _ => throw UnsupportedError('Unexpected DartObject type: $runtimeType'),
    };
  }

  cb.Expression _createTearoff(ExecutableElement2 element) {
    return cb.refer(element.displayName, _elementToLibraryIdentifier(element));
  }

  cb.Expression _createEnumInstance(DartObjectImpl object) {
    final VariableElement2 variable = object.variable2!;
    return switch (variable) {
      FieldElement2(
        isEnumConstant: true,
        displayName: final enumValue,
        enclosingElement2: EnumElement2(displayName: final enumName),
      ) =>
        cb.refer('$enumName.$enumValue', _elementToLibraryIdentifier(variable)),
      PropertyInducingElement2(:final displayName) => cb.refer(
        displayName,
        _elementToLibraryIdentifier(variable),
      ),
      _ => throw UnsupportedError('Unexpected enum variable type: ${variable.runtimeType}'),
    };
  }

  cb.Expression _createInstance(InterfaceType dartType, DartObjectImpl object) {
    final ConstructorInvocation constructorInvocation = object.getInvocation()!;
    final ConstructorElement2 constructor = constructorInvocation.constructor2;
    final cb.Expression type = cb.refer(
      dartType.element3.name3!,
      _elementToLibraryIdentifier(dartType.element3),
    );
    final String? name = constructor.name3 == 'new' ? null : constructor.name3;

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

  /// Returns the import URI for the [analyzer.LibraryElement2] containing [element].
  String? _elementToLibraryIdentifier(analyzer.Element2? element) => element?.library2!.identifier;
}
