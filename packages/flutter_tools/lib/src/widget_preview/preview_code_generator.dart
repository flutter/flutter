// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';

import '../base/file_system.dart';
import '../project.dart';
import 'preview_detector.dart';

/// Generates the Dart source responsible for importing widget previews from the developer's project
/// into the widget preview scaffold.
class PreviewCodeGenerator {
  PreviewCodeGenerator({required this.widgetPreviewScaffoldProject, required this.fs});

  final FileSystem fs;

  /// The project for the widget preview scaffold found under `.dart_tool/` in the developer's
  /// project.
  final FlutterProject widgetPreviewScaffoldProject;

  static const String generatedPreviewFilePath = 'lib/src/generated_preview.dart';

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
  void populatePreviewsInGeneratedPreviewScaffold(PreviewMapping previews) {
    final TypeReference returnType =
        (TypeReferenceBuilder()
              ..symbol = 'List'
              ..types = ListBuilder<Reference>(<Reference>[
                refer('WidgetPreview', 'widget_preview.dart'),
              ]))
            .build();
    final Library lib = Library(
      (LibraryBuilder b) => b.body.addAll(<Spec>[
        Method((MethodBuilder b) {
          final List<Expression> previewExpressions = <Expression>[];
          for (final MapEntry<PreviewPath, List<PreviewDetails>>(
                key: (path: String _, :Uri uri),
                value: List<PreviewDetails> previewMethods,
              )
              in previews.entries) {
            for (final PreviewDetails preview in previewMethods) {
              Expression previewWidget = refer(
                preview.functionName,
                uri.toString(),
              ).call(<Expression>[]);

              if (preview.isBuilder) {
                previewWidget = refer(
                  'Builder',
                  'package:flutter/widgets.dart',
                ).newInstance(<Expression>[], <String, Expression>{'builder': previewWidget});
              }
              if (preview.hasWrapper) {
                previewWidget = refer(
                  preview.wrapper!,
                  preview.wrapperLibraryUri,
                ).call(<Expression>[previewWidget]);
              }
              previewWidget =
                  Method((MethodBuilder previewBuilder) {
                    previewBuilder.body = previewWidget.code;
                  }).closure;
              previewExpressions.add(
                refer(
                  'WidgetPreview',
                  'widget_preview.dart',
                ).newInstance(<Expression>[], <String, Expression>{
                  if (preview.name != null) PreviewDetails.kName: refer(preview.name!).expression,
                  ...?_buildDoubleParameters(key: PreviewDetails.kHeight, property: preview.height),
                  ...?_buildDoubleParameters(key: PreviewDetails.kWidth, property: preview.width),
                  ...?_buildDoubleParameters(
                    key: PreviewDetails.kTextScaleFactor,
                    property: preview.textScaleFactor,
                  ),
                  'builder': previewWidget,
                }),
              );
            }
          }
          b
            ..body = literalList(previewExpressions).code
            ..name = 'previews'
            ..returns = returnType;
        }),
      ]),
    );
    final DartEmitter emitter = DartEmitter.scoped(useNullSafetySyntax: true);
    final File generatedPreviewFile = fs.file(
      widgetPreviewScaffoldProject.directory.uri.resolve(generatedPreviewFilePath),
    );
    // TODO(bkonyi): do we want to bother with formatting this?
    generatedPreviewFile.writeAsStringSync(lib.accept(emitter).toString());
  }

  Map<String, Expression>? _buildDoubleParameters({
    required String key,
    required String? property,
  }) {
    if (property == null) {
      return null;
    }
    return <String, Expression>{
      key: CodeExpression(Code('${double.tryParse(property) ?? property}')),
    };
  }
}
