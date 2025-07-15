// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart' as analyzer;
import 'package:analyzer/dart/ast/visitor.dart' as analyzer;
import 'package:analyzer/dart/element/element2.dart' as analyzer;
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
        previewWidget = _buildIdentifierReference(
          preview.wrapper!,
        ).call(<cb.Expression>[previewWidget]);
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
            expression: preview.name,
          ),
          ...?_generateCodeFromAnalyzerExpression(
            allocator: allocator,
            key: PreviewDetails.kSize,
            expression: preview.size,
          ),
          ...?_generateCodeFromAnalyzerExpression(
            allocator: allocator,
            key: PreviewDetails.kTextScaleFactor,
            expression: preview.textScaleFactor,
          ),
          ...?_generateCodeFromAnalyzerExpression(
            allocator: allocator,
            key: PreviewDetails.kTheme,
            expression: preview.theme,
            isCallback: true,
          ),
          ...?_generateCodeFromAnalyzerExpression(
            allocator: allocator,
            key: PreviewDetails.kBrightness,
            expression: preview.brightness,
          ),
          ...?_generateCodeFromAnalyzerExpression(
            allocator: allocator,
            key: PreviewDetails.kLocalizations,
            expression: preview.localizations,
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
    required analyzer.Expression? expression,
    bool isCallback = false,
  }) {
    if (expression == null) {
      return null;
    }
    cb.Expression generatedExpression = expression.accept(
      AnalyzerAstToCodeBuilderVisitor(allocator: allocator),
    )!;

    if (isCallback) {
      generatedExpression = generatedExpression.call(<cb.Expression>[]);
    }

    return <String, cb.Expression>{key: generatedExpression};
  }
}

/// Returns the import URI for the [analyzer.LibraryElement2] containing [element].
String? _elementToLibraryIdentifier(analyzer.Element2? element) => element?.library2!.identifier;

cb.Reference _buildIdentifierReference(analyzer.Identifier identifier) {
  return switch (identifier) {
    analyzer.PrefixedIdentifier() => _buildSimpleIdentifierReference(identifier.identifier),
    analyzer.SimpleIdentifier() => _buildSimpleIdentifierReference(identifier),
    _ => throw StateError('Unexpected identifier type: ${identifier.runtimeType}'),
  };
}

cb.Reference _buildSimpleIdentifierReference(analyzer.SimpleIdentifier identifier) {
  return cb.refer(identifier.name, _elementToLibraryIdentifier(identifier.element));
}

class AnalyzerAstToCodeBuilderVisitor extends analyzer.RecursiveAstVisitor<cb.Expression> {
  AnalyzerAstToCodeBuilderVisitor({required this.allocator});

  final cb.Allocator allocator;

  @override
  cb.Expression visitSimpleStringLiteral(analyzer.SimpleStringLiteral node) {
    return cb.literalString(node.value);
  }

  @override
  cb.Expression visitStringInterpolation(analyzer.StringInterpolation node) {
    // TODO(bkonyi): handle multiline
    final buffer = StringBuffer();
    for (final analyzer.InterpolationElement element in node.elements) {
      if (element is analyzer.InterpolationString) {
        buffer.write(element.value);
      } else if (element is analyzer.InterpolationExpression) {
        // The expressions associated with interpolated components of the string need to be
        // referenced with library prefixes. We'll use the same allocator that's used by the
        // DartEmitter to ensure the emitted expression uses the same prefix for the library
        // as the rest of the generated code.
        buffer.write(r'${');
        buffer.write(allocator.allocate(element.expression.accept(this)! as cb.Reference));
        buffer.write('}');
      }
    }
    return cb.literalString(buffer.toString(), raw: node.isRaw);
  }

  @override
  cb.Expression visitSimpleIdentifier(analyzer.SimpleIdentifier node) {
    return _buildSimpleIdentifierReference(node);
  }

  @override
  cb.Expression visitBooleanLiteral(analyzer.BooleanLiteral node) {
    return cb.literalBool(node.value);
  }

  @override
  cb.Expression visitDoubleLiteral(analyzer.DoubleLiteral node) {
    return cb.literalNum(node.value);
  }

  @override
  cb.Expression visitIntegerLiteral(analyzer.IntegerLiteral node) {
    // TODO(bkonyi): handle the case of an invalid integer constant due to overflow.
    return cb.literalNum(node.value!);
  }

  @override
  cb.Expression visitRecordLiteral(analyzer.RecordLiteral node) {
    // TODO(bkonyi): fully implement. Low priority as records aren't currently arguments
    // to @Preview(...).
    final positionalFieldValues = <Object?>[];
    final namedFieldValues = <String, Object?>{};
    return node.isConst
        ? cb.literalRecord(positionalFieldValues, namedFieldValues)
        : cb.literalConstRecord(positionalFieldValues, namedFieldValues);
  }

  @override
  cb.Expression visitNullLiteral(analyzer.NullLiteral node) {
    return cb.literalNull;
  }

  @override
  cb.Expression visitListLiteral(analyzer.ListLiteral node) {
    final literals = <Object?>[
      for (final analyzer.CollectionElement literal in node.elements) literal.accept(this),
    ];
    return node.isConst ? cb.literalConstList(literals) : cb.literalList(literals);
  }

  @override
  cb.Expression visitSetOrMapLiteral(analyzer.SetOrMapLiteral node) {
    if (node.isMap) {
      final values = <Object?, Object?>{
        for (final analyzer.MapLiteralEntry entry in node.elements.cast<analyzer.MapLiteralEntry>())
          entry.key.accept(this): entry.value.accept(this),
      };
      return node.isConst ? cb.literalConstMap(values) : cb.literalMap(values);
    } else {
      final values = <Object?>{
        for (final analyzer.CollectionElement entry in node.elements) entry.accept(this),
      };
      return node.isConst ? cb.literalConstSet(values) : cb.literalSet(values);
    }
  }

  @override
  cb.Expression visitNamedType(analyzer.NamedType node) {
    return cb.refer(node.name2.lexeme, _elementToLibraryIdentifier(node.element2));
  }

  @override
  cb.Expression visitPrefixedIdentifier(analyzer.PrefixedIdentifier node) {
    final String libraryUri = _elementToLibraryIdentifier(node.element)!;

    // If the prefix is an enum, don't strip the prefix from the emitted code.
    if (node.prefix.element! is analyzer.EnumElement2) {
      return cb.refer('${node.prefix.name}.${node.identifier.name}', libraryUri);
    }
    // Otherwise, new prefixes are generated automatically and the old one can
    // be discarded.
    return cb.refer(node.identifier.name, libraryUri);
  }

  @override
  cb.Expression visitBinaryExpression(analyzer.BinaryExpression node) {
    final String lhs = _expressionToString(node.leftOperand.accept(this)!);
    final String operator = node.operator.lexeme;
    final String rhs = _expressionToString(node.rightOperand.accept(this)!);
    // There's unfortunately not a nice way to build a binary expression based on an operator
    // string using package:code_builder without creating an exhaustive switch statement. It's less
    // risky (and less cumbersome) to just build the expression manually.
    return cb.CodeExpression(cb.Code('$lhs $operator $rhs'));
  }

  @override
  cb.Expression visitInstanceCreationExpression(analyzer.InstanceCreationExpression node) {
    final cb.Expression type = node.constructorName.type.accept(this)!;
    final String? name = node.constructorName.name?.name;
    final List<cb.Expression> positionalArguments = node.argumentList.arguments
        .where((analyzer.Expression e) => e is! analyzer.NamedExpression)
        .map<cb.Expression>((analyzer.Expression e) => e.accept(this)!)
        .toList();
    final namedArguments = <String, cb.Expression>{
      for (final analyzer.NamedExpression e
          in node.argumentList.arguments.whereType<analyzer.NamedExpression>())
        e.name.label.name: e.expression.accept(this)!,
    };
    final typeArguments = <cb.Reference>[
      // TODO(bkonyi): consider handling type arguments
    ];
    return node.isConst
        ? cb.InvokeExpression.constOf(
            type,
            positionalArguments,
            namedArguments,
            typeArguments,
            name,
          )
        : cb.InvokeExpression.newOf(type, positionalArguments, namedArguments, typeArguments, name);
  }

  @override
  cb.Expression visitPropertyAccess(analyzer.PropertyAccess node) {
    // Needed to handle case where an enum is accessed via a prefixed import.
    final String target = _expressionToString(node.realTarget.accept(this)!);
    return cb.CodeExpression(cb.Code('$target.${node.propertyName.name}'));
  }

  /// Converts [expression] to a [String], using [allocator] to ensure library scope prefixes are
  /// consistent.
  String _expressionToString(cb.Expression expression) {
    return cb.DartEmitter(allocator: allocator).visitSpec(expression).toString();
  }
}
