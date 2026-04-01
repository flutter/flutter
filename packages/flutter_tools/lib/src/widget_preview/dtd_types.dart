// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:collection/collection.dart';

import '../convert.dart';

/// The set of widget previews defined in a script of an analyzed Flutter
/// project.
class FlutterWidgetPreviews {
  const FlutterWidgetPreviews({
    required this.namespaces,
    required this.previews,
    required this.scriptUris,
  });

  /// A set of library URIs and the prefixes used for types in
  /// "previewAnnotation" sources.
  final Map<String, String> namespaces;

  /// The current set of previews in the script.
  final List<FlutterWidgetPreviewDetails> previews;

  /// The URI for the updated script.
  final List<Uri> scriptUris;

  @override
  int get hashCode => Object.hash(
    const DeepCollectionEquality().hash(namespaces),
    const DeepCollectionEquality().hash(previews),
    const DeepCollectionEquality().hash(scriptUris),
  );

  @override
  bool operator ==(Object other) {
    return other is FlutterWidgetPreviews &&
        other.runtimeType == FlutterWidgetPreviews &&
        const DeepCollectionEquality().equals(namespaces, other.namespaces) &&
        const DeepCollectionEquality().equals(previews, other.previews) &&
        const DeepCollectionEquality().equals(scriptUris, other.scriptUris);
  }

  Map<String, Object?> toJson() {
    final result = <String, Object?>{};
    result['namespaces'] = namespaces;
    result['previews'] = previews.map((item) => item.toJson()).toList();
    result['scriptUris'] = scriptUris.map((uri) => uri.toString()).toList();
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  static FlutterWidgetPreviews fromJson(Map<String, Object?> json) {
    final Object? namespacesJson = json['namespaces'];
    final Map<String, String> namespaces = (namespacesJson! as Map<Object, Object?>).map(
      (key, value) => MapEntry(key as String, value! as String),
    );
    final Object? previewsJson = json['previews'];
    final List<FlutterWidgetPreviewDetails> previews = (previewsJson! as List<Object?>)
        .map((item) => FlutterWidgetPreviewDetails.fromJson(item! as Map<String, Object?>))
        .toList();
    final Object? scriptUrisJson = json['scriptUris'];
    final List<Uri> scriptUris = (scriptUrisJson! as List<Object?>)
        .map((item) => Uri.parse(item! as String))
        .toList();
    return FlutterWidgetPreviews(
      namespaces: namespaces,
      previews: previews,
      scriptUris: scriptUris,
    );
  }
}

/// A representation of a widget preview declaration containing all information
/// needed to import the preview into the widget previewer.
class FlutterWidgetPreviewDetails {
  const FlutterWidgetPreviewDetails({
    required this.functionName,
    required this.hasError,
    required this.dependencyHasErrors,
    required this.isBuilder,
    required this.isMultiPreview,
    this.packageName,
    required this.position,
    required this.previewAnnotation,
    required this.scriptUri,
    required this.libraryUri,
  });

  /// The name of the function returning the preview.
  final String functionName;

  /// Set to true if there is an error that will prevent this preview from being
  /// rendered.
  final bool hasError;

  /// Set to true if there is an error in a dependency that will prevent this preview from being
  /// rendered.
  final bool dependencyHasErrors;

  /// Set to true if the preview function is returning a `WidgetBuilder` instead
  /// of a `Widget`.
  final bool isBuilder;

  /// Set to true if `previewAnnotation` represents a `MultiPreview`.
  final bool isMultiPreview;

  /// The name of the package in which this annotated preview function was
  /// defined.
  ///
  ///  For example, if this preview is defined in "package:foo/src/bar.dart",
  /// this will have the value "foo".
  ///
  /// This should only be null if the preview is defined in a file that's not
  /// part of a Flutter package (e.g., is defined in a test).
  final String? packageName;

  /// The source location at which the Preview annotation was applied.
  final Position position;

  /// An equivalent Dart expression to the applied preview annotation, with
  /// namespaces applied to individual types and constant values evaluated.
  ///
  /// This can be any object which extends `Preview` or `MultiPreview`.
  final String previewAnnotation;

  /// The file:// URI pointing to the script in which the preview is defined.
  final Uri scriptUri;

  /// The unresolved URI pointing to the library in which the preview is
  /// defined. This is either a package: or dart: URI.
  final Uri libraryUri;

  @override
  int get hashCode => Object.hash(
    functionName,
    hasError,
    dependencyHasErrors,
    isBuilder,
    isMultiPreview,
    packageName,
    position,
    previewAnnotation,
    scriptUri,
    libraryUri,
  );

  @override
  bool operator ==(Object other) {
    return other is FlutterWidgetPreviewDetails &&
        other.runtimeType == FlutterWidgetPreviewDetails &&
        functionName == other.functionName &&
        hasError == other.hasError &&
        dependencyHasErrors == other.dependencyHasErrors &&
        isBuilder == other.isBuilder &&
        isMultiPreview == other.isMultiPreview &&
        packageName == other.packageName &&
        position == other.position &&
        previewAnnotation == other.previewAnnotation &&
        scriptUri == other.scriptUri &&
        libraryUri == other.libraryUri;
  }

  Map<String, Object?> toJson() {
    final result = <String, Object?>{};
    result['functionName'] = functionName;
    result['hasError'] = hasError;
    result['dependencyHasErrors'] = dependencyHasErrors;
    result['isBuilder'] = isBuilder;
    result['isMultiPreview'] = isMultiPreview;
    result['packageName'] = packageName;
    result['position'] = position.toJson();
    result['previewAnnotation'] = previewAnnotation;
    result['scriptUri'] = scriptUri.toString();
    result['libraryUri'] = libraryUri.toString();
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  static FlutterWidgetPreviewDetails fromJson(Map<String, Object?> json) {
    final Object? functionNameJson = json['functionName'];
    final functionName = functionNameJson! as String;
    final Object? hasErrorJson = json['hasError'];
    final hasError = hasErrorJson! as bool;
    final Object? dependencyHasErrorsJson = json['dependencyHasErrors'];
    final dependencyHasErrors = dependencyHasErrorsJson! as bool;
    final Object? isBuilderJson = json['isBuilder'];
    final isBuilder = isBuilderJson! as bool;
    final Object? isMultiPreviewJson = json['isMultiPreview'];
    final isMultiPreview = isMultiPreviewJson! as bool;
    final Object? packageNameJson = json['packageName'];
    final packageName = packageNameJson as String?;
    final Object? positionJson = json['position'];
    final Position position = Position.fromJson(positionJson! as Map<String, Object?>);
    final Object? previewAnnotationJson = json['previewAnnotation'];
    final previewAnnotation = previewAnnotationJson! as String;
    final Object? scriptUriJson = json['scriptUri'];
    final Uri scriptUri = Uri.parse(scriptUriJson! as String);
    final Object? libraryUriJson = json['libraryUri'];
    final Uri libraryUri = Uri.parse(libraryUriJson! as String);
    return FlutterWidgetPreviewDetails(
      functionName: functionName,
      hasError: hasError,
      dependencyHasErrors: dependencyHasErrors,
      isBuilder: isBuilder,
      isMultiPreview: isMultiPreview,
      packageName: packageName,
      position: position,
      previewAnnotation: previewAnnotation,
      scriptUri: scriptUri,
      libraryUri: libraryUri,
    );
  }
}

class Position {
  const Position({required this.character, required this.line});

  /// Character offset on a line in a document (zero-based).
  ///
  /// The meaning of this offset is determined by the negotiated
  /// `PositionEncodingKind`.
  ///
  /// If the character value is greater than the line length it defaults back to
  /// the line length.
  final int character;

  /// Line position in a document (zero-based).
  ///
  /// If a line number is greater than the number of lines in a document, it
  /// defaults back to the number of lines in the document. If a line number is
  /// negative, it defaults to 0.
  final int line;

  @override
  int get hashCode => Object.hash(character, line);

  @override
  bool operator ==(Object other) {
    return other is Position &&
        other.runtimeType == Position &&
        character == other.character &&
        line == other.line;
  }

  Map<String, Object?> toJson() {
    final result = <String, Object?>{};
    result['character'] = character;
    result['line'] = line;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  static Position fromJson(Map<String, Object?> json) {
    final Object? characterJson = json['character'];
    final character = characterJson! as int;
    final Object? lineJson = json['line'];
    final line = lineJson! as int;
    return Position(character: character, line: line);
  }
}
