// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/token_impl.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:pub_semver/pub_semver.dart';

export 'package:analyzer/error/listener.dart' show RecordingErrorListener;
export 'package:analyzer/src/generated/timestamped_data.dart'
    show TimestampedData;

/// Used by [AnalysisOptions] to allow function bodies to be analyzed in some
/// sources but not others.
typedef AnalyzeFunctionBodiesPredicate = bool Function(Source source);

/// A context in which a single analysis can be performed and incrementally
/// maintained. The context includes such information as the version of the SDK
/// being analyzed against, and how to resolve 'package:' URI's. (Both of which
/// are known indirectly through the [SourceFactory].)
///
/// An analysis context also represents the state of the analysis, which includes
/// knowing which sources have been included in the analysis (either directly or
/// indirectly) and the results of the analysis. Sources must be added and
/// removed from the context using the method [applyChanges], which is also used
/// to notify the context when sources have been modified and, consequently,
/// previously known results might have been invalidated.
///
/// There are two ways to access the results of the analysis. The most common is
/// to use one of the 'get' methods to access the results. The 'get' methods have
/// the advantage that they will always return quickly, but have the disadvantage
/// that if the results are not currently available they will return either
/// nothing or in some cases an incomplete result. The second way to access
/// results is by using one of the 'compute' methods. The 'compute' methods will
/// always attempt to compute the requested results but might block the caller
/// for a significant period of time.
///
/// When results have been invalidated, have never been computed (as is the case
/// for newly added sources), or have been removed from the cache, they are
/// <b>not</b> automatically recreated. They will only be recreated if one of the
/// 'compute' methods is invoked.
///
/// However, this is not always acceptable. Some clients need to keep the
/// analysis results up-to-date. For such clients there is a mechanism that
/// allows them to incrementally perform needed analysis and get notified of the
/// consequent changes to the analysis results. This mechanism is realized by the
/// method [performAnalysisTask].
///
/// Analysis engine allows for having more than one context. This can be used,
/// for example, to perform one analysis based on the state of files on disk and
/// a separate analysis based on the state of those files in open editors. It can
/// also be used to perform an analysis based on a proposed future state, such as
/// the state after a refactoring.
abstract class AnalysisContext {
  /// Return the set of analysis options controlling the behavior of this
  /// context. Clients should not modify the returned set of options.
  AnalysisOptions get analysisOptions;

  /// Set the set of analysis options controlling the behavior of this context to
  /// the given [options]. Clients can safely assume that all necessary analysis
  /// results have been invalidated.
  set analysisOptions(AnalysisOptions options);

  /// Return the set of declared variables used when computing constant values.
  DeclaredVariables get declaredVariables;

  /// Return the source factory used to create the sources that can be analyzed
  /// in this context.
  SourceFactory get sourceFactory;

  /// Set the source factory used to create the sources that can be analyzed in
  /// this context to the given source [factory]. Clients can safely assume that
  /// all analysis results have been invalidated.
  set sourceFactory(SourceFactory factory);
}

/// The entry point for the functionality provided by the analysis engine. There
/// is a single instance of this class.
class AnalysisEngine {
  /// The unique instance of this class.
  static final AnalysisEngine instance = AnalysisEngine._();

  /// The instrumentation service that is to be used by this analysis engine.
  InstrumentationService _instrumentationService =
      InstrumentationService.NULL_SERVICE;

  AnalysisEngine._();

  /// Return the instrumentation service that is to be used by this analysis
  /// engine.
  InstrumentationService get instrumentationService => _instrumentationService;

  /// Set the instrumentation service that is to be used by this analysis engine
  /// to the given [service].
  set instrumentationService(InstrumentationService? service) {
    if (service == null) {
      _instrumentationService = InstrumentationService.NULL_SERVICE;
    } else {
      _instrumentationService = service;
    }
  }

  /// Clear any caches holding on to analysis results so that a full re-analysis
  /// will be performed the next time an analysis context is created.
  void clearCaches() {
    // See https://github.com/dart-lang/sdk/issues/30314.
    StringToken.canonicalizer.clear();
  }
}

/// The analysis errors and line information for the errors.
abstract class AnalysisErrorInfo {
  /// Return the errors that as a result of the analysis, or `null` if there were
  /// no errors.
  List<AnalysisError> get errors;

  /// Return the line information associated with the errors, or `null` if there
  /// were no errors.
  LineInfo get lineInfo;
}

/// The analysis errors and line info associated with a source.
class AnalysisErrorInfoImpl implements AnalysisErrorInfo {
  /// The analysis errors associated with a source, or `null` if there are no
  /// errors.
  @override
  final List<AnalysisError> errors;

  /// The line information associated with the errors, or `null` if there are no
  /// errors.
  @override
  final LineInfo lineInfo;

  /// Initialize an newly created error info with the given [errors] and
  /// [lineInfo].
  AnalysisErrorInfoImpl(this.errors, this.lineInfo);
}

/// A set of analysis options used to control the behavior of an analysis
/// context.
abstract class AnalysisOptions {
  /// A flag indicating whether to run checks on AndroidManifest.xml file to
  /// see if it is complaint with Chrome OS.
  bool get chromeOsManifestChecks;

  /// The set of features that are globally enabled for this context.
  FeatureSet get contextFeatures;

  /// Return a list of the names of the packages for which, if they define a
  /// plugin, the plugin should be enabled.
  List<String> get enabledPluginNames;

  /// Return `true` if timing data should be gathered during execution.
  bool get enableTiming;

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

  /// Return the opaque signature of the options.
  Uint32List get signature;

  /// Return `true` if analyzer should use the Dart 2.0 Front End parser.
  bool get useFastaParser;

  /// Return `true` the lint with the given [name] is enabled.
  bool isLintEnabled(String name);

  /// Determine whether two signatures returned by [signature] are equal.
  static bool signaturesEqual(Uint32List a, Uint32List b) {
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
}

/// A set of analysis options used to control the behavior of an analysis
/// context.
class AnalysisOptionsImpl implements AnalysisOptions {
  /// The cached [unlinkedSignature].
  Uint32List? _unlinkedSignature;

  /// The cached [signature].
  Uint32List? _signature;

  /// The cached [signatureForElements].
  Uint32List? _signatureForElements;

  @override
  VersionConstraint? sdkVersionConstraint;

  ExperimentStatus _contextFeatures = ExperimentStatus();

  /// The language version to use for libraries that are not in a package.
  ///
  /// If a library is in a package, this language version is *not* used,
  /// even if the package does not specify the language version.
  Version nonPackageLanguageVersion = ExperimentStatus.currentVersion;

  /// The set of features to use for libraries that are not in a package.
  ///
  /// If a library is in a package, this feature set is *not* used, even if the
  /// package does not specify the language version. Instead [contextFeatures]
  /// is used.
  FeatureSet nonPackageFeatureSet = ExperimentStatus();

  @override
  List<String> enabledPluginNames = const <String>[];

  @override
  bool enableTiming = false;

  /// A list of error processors that are to be used when reporting errors in
  /// some analysis context.
  List<ErrorProcessor>? _errorProcessors;

  /// A list of exclude patterns used to exclude some sources from analysis.
  List<String>? _excludePatterns;

  @override
  bool hint = true;

  @override
  bool lint = false;

  /// The lint rules that are to be run in an analysis context if [lint] returns
  /// `true`.
  List<Linter>? _lintRules;

  @override
  bool useFastaParser = true;

  /// A flag indicating whether implicit casts are allowed in [strongMode]
  /// (they are always allowed in Dart 1.0 mode).
  ///
  /// This option is experimental and subject to change.
  bool implicitCasts = true;

  /// A flag indicating whether implicit dynamic type is allowed, on by default.
  ///
  /// This flag can be used without necessarily enabling [strongMode], but it is
  /// designed with strong mode's type inference in mind. Without type inference,
  /// it will raise many errors. Also it does not provide type safety without
  /// strong mode.
  ///
  /// This option is experimental and subject to change.
  bool implicitDynamic = true;

  /// Indicates whether linter exceptions should be propagated to the caller (by
  /// re-throwing them)
  bool propagateLinterExceptions = false;

  /// Whether implicit casts should be reported as potential problems.
  bool strictCasts = false;

  /// A flag indicating whether inference failures are allowed, off by default.
  ///
  /// This option is experimental and subject to change.
  bool strictInference = false;

  /// Whether raw types (types without explicit type arguments, such as `List`)
  /// should be reported as potential problems.
  ///
  /// Raw types are a common source of `dynamic` being introduced implicitly.
  /// This often leads to cast failures later on in the program.
  bool strictRawTypes = false;

  @override
  bool chromeOsManifestChecks = false;

  /// The set of "un-ignorable" error names, as parsed in [AnalyzerOptions] from
  /// an analysis options file.
  Set<String> unignorableNames = {};

  /// Initialize a newly created set of analysis options to have their default
  /// values.
  AnalysisOptionsImpl();

  /// Initialize a newly created set of analysis options to have the same values
  /// as those in the given set of analysis [options].
  AnalysisOptionsImpl.from(AnalysisOptions options) {
    contextFeatures = options.contextFeatures;
    enabledPluginNames = options.enabledPluginNames;
    enableTiming = options.enableTiming;
    errorProcessors = options.errorProcessors;
    excludePatterns = options.excludePatterns;
    hint = options.hint;
    lint = options.lint;
    lintRules = options.lintRules;
    useFastaParser = options.useFastaParser;
    if (options is AnalysisOptionsImpl) {
      implicitCasts = options.implicitCasts;
      implicitDynamic = options.implicitDynamic;
      propagateLinterExceptions = options.propagateLinterExceptions;
      strictInference = options.strictInference;
      strictRawTypes = options.strictRawTypes;
    }
    sdkVersionConstraint = options.sdkVersionConstraint;
  }

  @override
  FeatureSet get contextFeatures => _contextFeatures;

  set contextFeatures(FeatureSet featureSet) {
    _contextFeatures = featureSet as ExperimentStatus;
    nonPackageFeatureSet = featureSet;
  }

  @deprecated
  set enabledExperiments(List<String> enabledExperiments) {
    _contextFeatures = ExperimentStatus.fromStrings(enabledExperiments);
  }

  @override
  List<ErrorProcessor> get errorProcessors =>
      _errorProcessors ??= const <ErrorProcessor>[];

  /// Set the list of error [processors] that are to be used when reporting
  /// errors in some analysis context.
  set errorProcessors(List<ErrorProcessor> processors) {
    _errorProcessors = processors;
  }

  @override
  List<String> get excludePatterns => _excludePatterns ??= const <String>[];

  /// Set the exclude patterns used to exclude some sources from analysis to
  /// those in the given list of [patterns].
  set excludePatterns(List<String> patterns) {
    _excludePatterns = patterns;
  }

  /// The set of enabled experiments.
  ExperimentStatus get experimentStatus => _contextFeatures;

  @override
  List<Linter> get lintRules => _lintRules ??= const <Linter>[];

  /// Set the lint rules that are to be run in an analysis context if [lint]
  /// returns `true`.
  set lintRules(List<Linter> rules) {
    _lintRules = rules;
  }

  @override
  Uint32List get signature {
    if (_signature == null) {
      ApiSignature buffer = ApiSignature();

      // Append environment.
      if (sdkVersionConstraint != null) {
        buffer.addString(sdkVersionConstraint.toString());
      }

      // Append boolean flags.
      buffer.addBool(implicitCasts);
      buffer.addBool(implicitDynamic);
      buffer.addBool(propagateLinterExceptions);
      buffer.addBool(strictInference);
      buffer.addBool(strictRawTypes);
      buffer.addBool(useFastaParser);

      // Append features.
      buffer.addInt(ExperimentStatus.knownFeatures.length);
      for (var feature in ExperimentStatus.knownFeatures.values) {
        buffer.addBool(contextFeatures.isEnabled(feature));
      }

      // Append error processors.
      buffer.addInt(errorProcessors.length);
      for (ErrorProcessor processor in errorProcessors) {
        buffer.addString(processor.description);
      }

      // Append lints.
      buffer.addString(linterVersion ?? '');
      buffer.addInt(lintRules.length);
      for (Linter lintRule in lintRules) {
        buffer.addString(lintRule.name);
      }

      // Append plugin names.
      buffer.addInt(enabledPluginNames.length);
      for (String enabledPluginName in enabledPluginNames) {
        buffer.addString(enabledPluginName);
      }

      // Hash and convert to Uint32List.
      _signature = buffer.toUint32List();
    }
    return _signature!;
  }

  Uint32List get signatureForElements {
    if (_signatureForElements == null) {
      ApiSignature buffer = ApiSignature();

      // Append features.
      buffer.addInt(ExperimentStatus.knownFeatures.length);
      for (var feature in ExperimentStatus.knownFeatures.values) {
        buffer.addBool(contextFeatures.isEnabled(feature));
      }

      // Hash and convert to Uint32List.
      _signatureForElements = buffer.toUint32List();
    }
    return _signatureForElements!;
  }

  /// Return the opaque signature of the options that affect unlinked data.
  ///
  /// The length of the list is guaranteed to equal [unlinkedSignatureLength].
  Uint32List get unlinkedSignature {
    if (_unlinkedSignature == null) {
      ApiSignature buffer = ApiSignature();

      // Append boolean flags.
      buffer.addBool(useFastaParser);

      // Append the current language version.
      buffer.addInt(ExperimentStatus.currentVersion.major);
      buffer.addInt(ExperimentStatus.currentVersion.minor);

      // Append features.
      buffer.addInt(ExperimentStatus.knownFeatures.length);
      for (var feature in ExperimentStatus.knownFeatures.values) {
        buffer.addBool(contextFeatures.isEnabled(feature));
      }

      // Hash and convert to Uint32List.
      return buffer.toUint32List();
    }
    return _unlinkedSignature!;
  }

  @override
  bool isLintEnabled(String name) {
    return lintRules.any((rule) => rule.name == name);
  }
}
