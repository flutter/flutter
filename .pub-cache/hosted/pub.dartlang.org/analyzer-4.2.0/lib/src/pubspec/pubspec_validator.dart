// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/pubspec/validators/dependency_validator.dart';
import 'package:analyzer/src/pubspec/validators/field_validator.dart';
import 'package:analyzer/src/pubspec/validators/flutter_validator.dart';
import 'package:analyzer/src/pubspec/validators/name_validator.dart';
import 'package:source_span/src/span.dart';
import 'package:yaml/yaml.dart';

class BasePubspecValidator {
  /// The resource provider used to access the file system.
  final ResourceProvider provider;

  /// The source representing the file being validated.
  final Source source;

  BasePubspecValidator(this.provider, this.source);

  String? asString(dynamic node) {
    if (node is String) {
      return node;
    }
    if (node is YamlScalar && node.value is String) {
      return node.value as String;
    }
    return null;
  }

  /// Report an error for the given node.
  void reportErrorForNode(
      ErrorReporter reporter, YamlNode node, ErrorCode errorCode,
      [List<Object>? arguments]) {
    SourceSpan span = node.span;
    reporter.reportErrorForOffset(
        errorCode, span.start.offset, span.length, arguments);
  }
}

class PubspecField {
  /// The name of the sub-field (under `flutter`) whose value is a list of
  /// assets available to Flutter apps at runtime.
  static const String ASSETS_FIELD = 'assets';

  /// The name of the field whose value is a map of dependencies.
  static const String DEPENDENCIES_FIELD = 'dependencies';

  /// The name of the field whose value is a map of development dependencies.
  static const String DEV_DEPENDENCIES_FIELD = 'dev_dependencies';

  /// The name of the field whose value is a specification of Flutter-specific
  /// configuration data.
  static const String FLUTTER_FIELD = 'flutter';

  /// The name of the field whose value is a git dependency.
  static const String GIT_FIELD = 'git';

  /// The name of the field whose value is the name of the package.
  static const String NAME_FIELD = 'name';

  /// The name of the field whose value is a path to a package dependency.
  static const String PATH_FIELD = 'path';

  /// The name of the field whose value is the where to publish the package.
  static const String PUBLISH_TO_FIELD = 'publish_to';

  /// The name of the field whose value is the version of the package.
  static const String VERSION_FIELD = 'version';
}

class PubspecValidator {
  /// The resource provider used to access the file system.
  final ResourceProvider provider;

  /// The source representing the file being validated.
  final Source source;

  final DependencyValidator _dependencyValidator;
  final FieldValidator _fieldValidator;
  final FlutterValidator _flutterValidator;
  final NameValidator _nameValidator;

  /// Initialize a newly create validator to validate the content of the given
  /// [source].
  PubspecValidator(this.provider, this.source)
      : _dependencyValidator = DependencyValidator(provider, source),
        _fieldValidator = FieldValidator(provider, source),
        _flutterValidator = FlutterValidator(provider, source),
        _nameValidator = NameValidator(provider, source);

  /// Validate the given [contents].
  List<AnalysisError> validate(Map<dynamic, YamlNode> contents) {
    // TODO(brianwilkerson) This method needs to take a `YamlDocument` rather
    //  than the contents of the document so that it can validate an empty file.
    RecordingErrorListener recorder = RecordingErrorListener();
    ErrorReporter reporter = ErrorReporter(
      recorder,
      source,
      isNonNullableByDefault: false,
    );

    _dependencyValidator.validate(reporter, contents);
    _fieldValidator.validate(reporter, contents);
    _flutterValidator.validate(reporter, contents);
    _nameValidator.validate(reporter, contents);

    return recorder.errors;
  }
}
