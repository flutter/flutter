// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/code_style_options.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:pub_semver/src/version_constraint.dart';

/// A set of analysis options used to control the behavior of an analysis
/// context.
///
/// Clients may not extend, implement or mix-in this class.
abstract class AnalysisOptions {
  /// A flag indicating whether to run checks on AndroidManifest.xml file to
  /// see if it is complaint with Chrome OS.
  bool get chromeOsManifestChecks;

  /// Return the options used to control the code that is generated.
  CodeStyleOptions get codeStyleOptions;

  /// The set of features that are globally enabled for this context.
  FeatureSet get contextFeatures;

  /// Return a list of the names of the packages for which, if they define a
  /// plugin, the plugin should be enabled.
  List<String> get enabledPluginNames;

  /// Return a list of error processors that are to be used when reporting
  /// errors in some analysis context.
  List<ErrorProcessor> get errorProcessors;

  /// Return a list of exclude patterns used to exclude some sources from
  /// analysis.
  List<String> get excludePatterns;

  /// Return `true` if analysis is to generate hint results (e.g. type inference
  /// based information and pub best practices).
  bool get hint;

  /// Return `true` if analysis is to generate lint warnings.
  bool get lint;

  /// Return a list of the lint rules that are to be run in an analysis context
  /// if [lint] returns `true`.
  List<Linter> get lintRules;

  /// The version range for the SDK specified in `pubspec.yaml`, or `null` if
  /// there is no `pubspec.yaml` or if it does not contain an SDK range.
  VersionConstraint? get sdkVersionConstraint;

  /// Return `true` the lint with the given [name] is enabled.
  bool isLintEnabled(String name);
}
