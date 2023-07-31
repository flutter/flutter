// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/code_style_options.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/analysis_options/code_style_options.dart';
import 'package:analyzer/src/analysis_options/error/option_codes.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/options_rule_validator.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/plugin/options.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

final _OptionsProcessor _processor = _OptionsProcessor();

List<AnalysisError> analyzeAnalysisOptions(
  Source source,
  String content,
  SourceFactory sourceFactory,
  String contextRoot,
  VersionConstraint? sdkVersionConstraint, {
  LintRuleProvider? provider,
}) {
  List<AnalysisError> errors = [];
  Source initialSource = source;
  SourceSpan? initialIncludeSpan;
  AnalysisOptionsProvider optionsProvider =
      AnalysisOptionsProvider(sourceFactory);
  String? firstPluginName;
  Map<Source, SourceSpan> includeChain = {};

  // TODO(srawlins): This code is getting quite complex, with multiple local
  // functions, and should be refactored to a class maintaining state, with less
  // variable shadowing.
  void addDirectErrorOrIncludedError(
      List<AnalysisError> validationErrors, Source source,
      {required bool sourceIsOptionsForContextRoot}) {
    if (!sourceIsOptionsForContextRoot) {
      // [source] is an included file, and we should only report errors in
      // [initialSource], noting that the included file has warnings.
      for (AnalysisError error in validationErrors) {
        var args = [
          source.fullName,
          error.offset.toString(),
          (error.offset + error.length - 1).toString(),
          error.message,
        ];
        errors.add(AnalysisError(
            initialSource,
            initialIncludeSpan!.start.offset,
            initialIncludeSpan!.length,
            AnalysisOptionsWarningCode.INCLUDED_FILE_WARNING,
            args));
      }
    } else {
      // [source] is the options file for [contextRoot]. Report all errors
      // directly.
      errors.addAll(validationErrors);
    }
  }

  // Validate the specified options and any included option files.
  void validate(Source source, YamlMap options, LintRuleProvider? provider) {
    var sourceIsOptionsForContextRoot = initialIncludeSpan == null;
    var validationErrors = OptionsFileValidator(
      source,
      sdkVersionConstraint: sdkVersionConstraint,
      sourceIsOptionsForContextRoot: sourceIsOptionsForContextRoot,
      provider: provider,
    ).validate(options);
    addDirectErrorOrIncludedError(validationErrors, source,
        sourceIsOptionsForContextRoot: sourceIsOptionsForContextRoot);

    var includeNode = options.valueAt(AnalyzerOptions.include);
    if (includeNode == null) {
      // Validate the 'plugins' option in [options], understanding that no other
      // options are included.
      addDirectErrorOrIncludedError(
          _validatePluginsOption(source, options: options), source,
          sourceIsOptionsForContextRoot: sourceIsOptionsForContextRoot);
      return;
    }
    var includeSpan = includeNode.span;
    initialIncludeSpan ??= includeSpan;
    String includeUri = includeSpan.text;
    var includedSource = sourceFactory.resolveUri(source, includeUri);
    if (includedSource == initialSource) {
      errors.add(AnalysisError(
          initialSource,
          initialIncludeSpan!.start.offset,
          initialIncludeSpan!.length,
          AnalysisOptionsWarningCode.RECURSIVE_INCLUDE_FILE,
          [includeUri, source.fullName]));
      return;
    }
    if (includedSource == null || !includedSource.exists()) {
      errors.add(AnalysisError(
          initialSource,
          initialIncludeSpan!.start.offset,
          initialIncludeSpan!.length,
          AnalysisOptionsWarningCode.INCLUDE_FILE_NOT_FOUND,
          [includeUri, source.fullName, contextRoot]));
      return;
    }
    var spanInChain = includeChain[includedSource];
    if (spanInChain != null) {
      errors.add(AnalysisError(
          initialSource,
          initialIncludeSpan!.start.offset,
          initialIncludeSpan!.length,
          AnalysisOptionsWarningCode.INCLUDED_FILE_WARNING, [
        includedSource,
        spanInChain.start.offset,
        spanInChain.length,
        'The file includes itself recursively.',
      ]));
      return;
    }
    includeChain[includedSource] = includeSpan;

    try {
      var includedOptions =
          optionsProvider.getOptionsFromString(includedSource.contents.data);
      validate(includedSource, includedOptions, provider);
      firstPluginName ??= _firstPluginName(includedOptions);
      // Validate the 'plugins' option in [options], taking into account any
      // plugins enabled by [includedOptions].
      addDirectErrorOrIncludedError(
        _validatePluginsOption(source,
            options: options, firstEnabledPluginName: firstPluginName),
        source,
        sourceIsOptionsForContextRoot: sourceIsOptionsForContextRoot,
      );
    } on OptionsFormatException catch (e) {
      var args = [
        includedSource.fullName,
        e.span!.start.offset.toString(),
        e.span!.end.offset.toString(),
        e.message,
      ];
      // Report errors for included option files on the `include` directive
      // located in the initial options file.
      errors.add(AnalysisError(
          initialSource,
          initialIncludeSpan!.start.offset,
          initialIncludeSpan!.length,
          AnalysisOptionsErrorCode.INCLUDED_FILE_PARSE_ERROR,
          args));
    }
  }

  try {
    YamlMap options = optionsProvider.getOptionsFromString(content);
    validate(source, options, provider);
  } on OptionsFormatException catch (e) {
    SourceSpan span = e.span!;
    errors.add(AnalysisError(source, span.start.offset, span.length,
        AnalysisOptionsErrorCode.PARSE_ERROR, [e.message]));
  }
  return errors;
}

void applyToAnalysisOptions(AnalysisOptionsImpl options, YamlMap optionMap) {
  _processor.applyToAnalysisOptions(options, optionMap);
}

/// Returns the name of the first plugin, if one is specified in [options],
/// otherwise `null`.
String? _firstPluginName(YamlMap options) {
  var analyzerMap = options.valueAt(AnalyzerOptions.analyzer);
  if (analyzerMap is! YamlMap) {
    return null;
  }
  var plugins = analyzerMap.valueAt(AnalyzerOptions.plugins);
  if (plugins is YamlScalar) {
    return plugins.value as String?;
  } else if (plugins is YamlList) {
    return plugins.first as String?;
  } else if (plugins is YamlMap) {
    return plugins.keys.first as String?;
  } else {
    return null;
  }
}

/// Validates the 'plugins' options in [options], given
/// [firstEnabledPluginName].
List<AnalysisError> _validatePluginsOption(
  Source source, {
  required YamlMap options,
  String? firstEnabledPluginName,
}) {
  RecordingErrorListener recorder = RecordingErrorListener();
  ErrorReporter reporter = ErrorReporter(
    recorder,
    source,
    isNonNullableByDefault: true,
  );
  PluginsOptionValidator(firstEnabledPluginName).validate(reporter, options);
  return recorder.errors;
}

/// `analyzer` analysis options constants.
class AnalyzerOptions {
  static const String analyzer = 'analyzer';

  static const String cannotIgnore = 'cannot-ignore';
  static const String codeStyle = 'code-style';
  static const String enableExperiment = 'enable-experiment';
  static const String errors = 'errors';
  static const String exclude = 'exclude';
  static const String include = 'include';
  static const String language = 'language';
  static const String optionalChecks = 'optional-checks';
  static const String plugins = 'plugins';
  static const String strongMode = 'strong-mode';

  // Optional checks options.
  static const String chromeOsManifestChecks = 'chrome-os-manifest-checks';

  // Strong mode options (see AnalysisOptionsImpl for documentation).
  static const String declarationCasts = 'declaration-casts';
  static const String implicitCasts = 'implicit-casts';
  static const String implicitDynamic = 'implicit-dynamic';

  // Language options (see AnalysisOptionsImpl for documentation).
  static const String strictCasts = 'strict-casts';
  static const String strictInference = 'strict-inference';
  static const String strictRawTypes = 'strict-raw-types';

  // Code style options
  static const String format = 'format';

  /// Ways to say `ignore`.
  static const List<String> ignoreSynonyms = ['ignore', 'false'];

  /// Valid error `severity`s.
  static final List<String> severities = List.unmodifiable(severityMap.keys);

  /// Ways to say `include`.
  static const List<String> includeSynonyms = ['include', 'true'];

  static const String propagateLinterExceptions = 'propagate-linter-exceptions';

  /// Ways to say `true` or `false`.
  static const List<String> trueOrFalse = ['true', 'false'];

  /// Supported top-level `analyzer` options.
  static const List<String> topLevel = [
    cannotIgnore,
    enableExperiment,
    errors,
    exclude,
    language,
    optionalChecks,
    plugins,
    propagateLinterExceptions,
    strongMode,
  ];

  /// Supported `analyzer` strong-mode options.
  static const List<String> strongModeOptions = [
    declarationCasts, // deprecated
    implicitCasts,
    implicitDynamic,
  ];

  /// Supported `analyzer` language options.
  static const List<String> languageOptions = [
    strictCasts,
    strictInference,
    strictRawTypes,
  ];

  /// Supported 'analyzer' optional checks options.
  static const List<String> optionalChecksOptions = [
    chromeOsManifestChecks,
  ];

  /// Supported 'code-style' options.
  static const List<String> codeStyleOptions = [
    format,
  ];

  /// Proposed values for a `true` or `false` option.
  static String get trueOrFalseProposal =>
      AnalyzerOptions.trueOrFalse.quotedAndCommaSeparatedWithAnd;
}

/// Validates `analyzer` options.
class AnalyzerOptionsValidator extends CompositeValidator {
  AnalyzerOptionsValidator()
      : super([
          TopLevelAnalyzerOptionsValidator(),
          StrongModeOptionValueValidator(),
          ErrorFilterOptionValidator(),
          EnabledExperimentsValidator(),
          LanguageOptionValidator(),
          OptionalChecksValueValidator(),
          CannotIgnoreOptionValidator(),
        ]);
}

/// Validates the `analyzer` `cannot-ignore` option.
///
/// This includes the format of the `cannot-ignore` section, the format of
/// values in the section, and whether each value is a valid string.
class CannotIgnoreOptionValidator extends OptionsValidator {
  /// Lazily populated set of error codes.
  static final Set<String> _errorCodes =
      errorCodeValues.map((ErrorCode code) => code.name).toSet();

  /// Lazily populated set of lint codes.
  late final Set<String> _lintCodes = Registry.ruleRegistry.rules
      .map((rule) => rule.name.toUpperCase())
      .toSet();

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalyzerOptions.analyzer);
    if (analyzer is YamlMap) {
      var unignorableNames = analyzer.valueAt(AnalyzerOptions.cannotIgnore);
      if (unignorableNames is YamlList) {
        var listedNames = <String>{};
        for (var unignorableNameNode in unignorableNames.nodes) {
          var unignorableName = unignorableNameNode.value;
          if (unignorableName is String) {
            if (AnalyzerOptions.severities.contains(unignorableName)) {
              listedNames.add(unignorableName);
              continue;
            }
            var upperCaseName = unignorableName.toUpperCase();
            if (!_errorCodes.contains(upperCaseName) &&
                !_lintCodes.contains(upperCaseName)) {
              reporter.reportErrorForSpan(
                  AnalysisOptionsWarningCode.UNRECOGNIZED_ERROR_CODE,
                  unignorableNameNode.span,
                  [unignorableName]);
            } else if (listedNames.contains(upperCaseName)) {
              // TODO(srawlins): Create a "duplicate value" code and report it
              // here.
            } else {
              listedNames.add(upperCaseName);
            }
          } else {
            reporter.reportErrorForSpan(
                AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
                unignorableNameNode.span,
                [AnalyzerOptions.cannotIgnore]);
          }
        }
      } else if (unignorableNames != null) {
        reporter.reportErrorForSpan(
            AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
            unignorableNames.span,
            [AnalyzerOptions.cannotIgnore]);
      }
    }
  }
}

/// Validates `code-style` options.
class CodeStyleOptionsValidator extends OptionsValidator {
  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var codeStyle = options.valueAt(AnalyzerOptions.codeStyle);
    if (codeStyle is YamlMap) {
      codeStyle.nodeMap.forEach((keyNode, valueNode) {
        var key = keyNode.value;
        if (key == AnalyzerOptions.format) {
          _validateFormat(reporter, valueNode);
        } else {
          reporter.reportErrorForSpan(
              AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITHOUT_VALUES,
              keyNode.span,
              [AnalyzerOptions.codeStyle, keyNode.toString()]);
        }
      });
    } else if (codeStyle is YamlScalar && codeStyle.value != null) {
      reporter.reportErrorForSpan(
          AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
          codeStyle.span,
          [AnalyzerOptions.codeStyle]);
    } else if (codeStyle is YamlList) {
      reporter.reportErrorForSpan(
          AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
          codeStyle.span,
          [AnalyzerOptions.codeStyle]);
    }
  }

  void _validateFormat(ErrorReporter reporter, YamlNode format) {
    if (format is YamlMap) {
      reporter.reportErrorForSpan(
          AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
          format.span,
          [AnalyzerOptions.format]);
    } else if (format is YamlScalar) {
      var formatValue = toBool(format.valueOrThrow);
      if (formatValue == null) {
        reporter.reportErrorForSpan(
            AnalysisOptionsWarningCode.UNSUPPORTED_VALUE, format.span, [
          AnalyzerOptions.format,
          format.valueOrThrow,
          AnalyzerOptions.trueOrFalseProposal
        ]);
      }
    } else if (format is YamlList) {
      reporter.reportErrorForSpan(
          AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
          format.span,
          [AnalyzerOptions.format]);
    }
  }
}

/// Convenience class for composing validators.
class CompositeValidator extends OptionsValidator {
  final List<OptionsValidator> validators;

  CompositeValidator(this.validators);

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    for (var validator in validators) {
      validator.validate(reporter, options);
    }
  }
}

/// Validates `analyzer` language configuration options.
class EnabledExperimentsValidator extends OptionsValidator {
  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalyzerOptions.analyzer);
    if (analyzer is YamlMap) {
      var experimentNames = analyzer.valueAt(AnalyzerOptions.enableExperiment);
      if (experimentNames is YamlList) {
        var flags =
            experimentNames.nodes.map((node) => node.toString()).toList();
        for (var validationResult in validateFlags(flags)) {
          var flagIndex = validationResult.stringIndex;
          var span = experimentNames.nodes[flagIndex].span;
          if (validationResult is UnrecognizedFlag) {
            reporter.reportErrorForSpan(
                AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITHOUT_VALUES,
                span,
                [AnalyzerOptions.enableExperiment, flags[flagIndex]]);
          } else {
            reporter.reportErrorForSpan(
                AnalysisOptionsWarningCode.INVALID_OPTION,
                span,
                [AnalyzerOptions.enableExperiment, validationResult.message]);
          }
        }
      } else if (experimentNames != null) {
        reporter.reportErrorForSpan(
            AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
            experimentNames.span,
            [AnalyzerOptions.enableExperiment]);
      }
    }
  }
}

/// Builds error reports with value proposals.
class ErrorBuilder {
  static AnalysisOptionsWarningCode get noProposalCode =>
      AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITHOUT_VALUES;

  static AnalysisOptionsWarningCode get pluralProposalCode =>
      AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES;

  static AnalysisOptionsWarningCode get singularProposalCode =>
      AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUE;

  final String proposal;

  final AnalysisOptionsWarningCode code;

  /// Create a builder for the given [supportedOptions].
  factory ErrorBuilder(List<String> supportedOptions) {
    var proposal = supportedOptions.quotedAndCommaSeparatedWithAnd;
    if (supportedOptions.isEmpty) {
      return ErrorBuilder._(proposal: proposal, code: noProposalCode);
    } else if (supportedOptions.length == 1) {
      return ErrorBuilder._(proposal: proposal, code: singularProposalCode);
    } else {
      return ErrorBuilder._(proposal: proposal, code: pluralProposalCode);
    }
  }

  ErrorBuilder._({
    required this.proposal,
    required this.code,
  });

  /// Report an unsupported [node] value, defined in the given [scopeName].
  void reportError(ErrorReporter reporter, String scopeName, YamlNode node) {
    if (proposal.isNotEmpty) {
      reporter.reportErrorForSpan(
          code, node.span, [scopeName, node.valueOrThrow, proposal]);
    } else {
      reporter
          .reportErrorForSpan(code, node.span, [scopeName, node.valueOrThrow]);
    }
  }
}

/// Validates `analyzer` error filter options.
class ErrorFilterOptionValidator extends OptionsValidator {
  /// Legal values.
  static final List<String> legalValues =
      List.from(AnalyzerOptions.ignoreSynonyms)
        ..addAll(AnalyzerOptions.includeSynonyms)
        ..addAll(AnalyzerOptions.severities);

  /// Pretty String listing legal values.
  static final String legalValueString =
      legalValues.quotedAndCommaSeparatedWithAnd;

  /// Lazily populated set of error codes.
  static final Set<String> _errorCodes =
      errorCodeValues.map((ErrorCode code) => code.name).toSet();

  /// Lazily populated set of lint codes.
  late final Set<String> _lintCodes = Registry.ruleRegistry.rules
      .map((rule) => rule.name.toUpperCase())
      .toSet();

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalyzerOptions.analyzer);
    if (analyzer is YamlMap) {
      var filters = analyzer.valueAt(AnalyzerOptions.errors);
      if (filters is YamlMap) {
        filters.nodes.forEach((k, v) {
          String? value;
          if (k is YamlScalar) {
            value = toUpperCase(k.value);
            if (!_errorCodes.contains(value) && !_lintCodes.contains(value)) {
              reporter.reportErrorForSpan(
                  AnalysisOptionsWarningCode.UNRECOGNIZED_ERROR_CODE,
                  k.span,
                  [k.value.toString()]);
            }
          }
          if (v is YamlScalar) {
            value = toLowerCase(v.value);
            if (!legalValues.contains(value)) {
              reporter.reportErrorForSpan(
                  AnalysisOptionsWarningCode
                      .UNSUPPORTED_OPTION_WITH_LEGAL_VALUES,
                  v.span,
                  [
                    AnalyzerOptions.errors,
                    v.value.toString(),
                    legalValueString
                  ]);
            }
          } else {
            reporter.reportErrorForSpan(
                AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
                v.span,
                [AnalyzerOptions.enableExperiment]);
          }
        });
      } else if (filters != null) {
        reporter.reportErrorForSpan(
            AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
            filters.span,
            [AnalyzerOptions.enableExperiment]);
      }
    }
  }
}

/// Validates `analyzer` language configuration options.
class LanguageOptionValidator extends OptionsValidator {
  final ErrorBuilder _builder = ErrorBuilder(AnalyzerOptions.languageOptions);

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalyzerOptions.analyzer);
    if (analyzer is YamlMap) {
      var language = analyzer.valueAt(AnalyzerOptions.language);
      if (language is YamlMap) {
        language.nodes.forEach((k, v) {
          String? key, value;
          bool validKey = false;
          if (k is YamlScalar) {
            key = k.value?.toString();
            if (!AnalyzerOptions.languageOptions.contains(key)) {
              _builder.reportError(reporter, AnalyzerOptions.language, k);
            } else {
              // If we have a valid key, go on and check the value.
              validKey = true;
            }
          }
          if (validKey && v is YamlScalar) {
            value = toLowerCase(v.value);
            // `null` is not a valid key, so we can safely assume `key` is
            // non-`null`.
            if (!AnalyzerOptions.trueOrFalse.contains(value)) {
              reporter.reportErrorForSpan(
                  AnalysisOptionsWarningCode.UNSUPPORTED_VALUE,
                  v.span,
                  [key!, v.valueOrThrow, AnalyzerOptions.trueOrFalseProposal]);
            }
          }
        });
      } else if (language is YamlScalar && language.value != null) {
        reporter.reportErrorForSpan(
            AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
            language.span,
            [AnalyzerOptions.language]);
      } else if (language is YamlList) {
        reporter.reportErrorForSpan(
            AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
            language.span,
            [AnalyzerOptions.language]);
      }
    }
  }
}

/// Validates `linter` top-level options.
/// TODO(pq): move into `linter` package and plugin.
class LinterOptionsValidator extends TopLevelOptionValidator {
  LinterOptionsValidator() : super('linter', const ['rules']);
}

/// Validates `analyzer` optional-checks value configuration options.
class OptionalChecksValueValidator extends OptionsValidator {
  final ErrorBuilder _builder =
      ErrorBuilder(AnalyzerOptions.optionalChecksOptions);

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalyzerOptions.analyzer);
    if (analyzer is YamlMap) {
      var v = analyzer.valueAt(AnalyzerOptions.optionalChecks);
      if (v is YamlScalar) {
        var value = toLowerCase(v.value);
        if (value != AnalyzerOptions.chromeOsManifestChecks) {
          _builder.reportError(
              reporter, AnalyzerOptions.chromeOsManifestChecks, v);
        }
      } else if (v is YamlMap) {
        v.nodes.forEach((k, v) {
          String? key, value;
          if (k is YamlScalar) {
            key = k.value?.toString();
            if (key != AnalyzerOptions.chromeOsManifestChecks) {
              _builder.reportError(
                  reporter, AnalyzerOptions.chromeOsManifestChecks, k);
            } else {
              value = toLowerCase(v.value);
              if (!AnalyzerOptions.trueOrFalse.contains(value)) {
                reporter.reportErrorForSpan(
                    AnalysisOptionsWarningCode.UNSUPPORTED_VALUE, v.span, [
                  key!,
                  v.valueOrThrow,
                  AnalyzerOptions.trueOrFalseProposal
                ]);
              }
            }
          }
        });
      } else if (v != null) {
        reporter.reportErrorForSpan(
            AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
            v.span,
            [AnalyzerOptions.enableExperiment]);
      }
    }
  }
}

/// Validates options defined in an analysis options file.
class OptionsFileValidator {
  /// The source being validated.
  final Source source;

  final List<OptionsValidator> _validators;

  OptionsFileValidator(
    this.source, {
    required VersionConstraint? sdkVersionConstraint,
    required bool sourceIsOptionsForContextRoot,
    LintRuleProvider? provider,
  }) : _validators = [
          AnalyzerOptionsValidator(),
          CodeStyleOptionsValidator(),
          LinterOptionsValidator(),
          LinterRuleOptionsValidator(
            provider: provider,
            sdkVersionConstraint: sdkVersionConstraint,
            sourceIsOptionsForContextRoot: sourceIsOptionsForContextRoot,
          ),
        ];

  List<AnalysisError> validate(YamlMap options) {
    RecordingErrorListener recorder = RecordingErrorListener();
    ErrorReporter reporter = ErrorReporter(
      recorder,
      source,
      isNonNullableByDefault: false,
    );
    for (var validator in _validators) {
      validator.validate(reporter, options);
    }
    return recorder.errors;
  }
}

/// Validates `analyzer` plugins configuration options.
class PluginsOptionValidator extends OptionsValidator {
  /// The name of the first included plugin, if there is one.
  ///
  /// If there are no included plugins, this is `null`.
  final String? _firstIncludedPluginName;

  PluginsOptionValidator(this._firstIncludedPluginName);

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalyzerOptions.analyzer);
    if (analyzer is! YamlMap) {
      return;
    }
    var plugins = analyzer.valueAt(AnalyzerOptions.plugins);
    if (plugins is YamlScalar && plugins.value != null) {
      if (_firstIncludedPluginName != null &&
          _firstIncludedPluginName != plugins.value) {
        reporter.reportErrorForSpan(
          AnalysisOptionsWarningCode.MULTIPLE_PLUGINS,
          plugins.span,
          [_firstIncludedPluginName!],
        );
      }
    } else if (plugins is YamlList) {
      var pluginValues = plugins.nodes.whereType<YamlNode>().toList();
      if (_firstIncludedPluginName != null) {
        // There is already at least one plugin specified in included options.
        for (var plugin in pluginValues) {
          if (plugin.value != _firstIncludedPluginName) {
            reporter.reportErrorForSpan(
              AnalysisOptionsWarningCode.MULTIPLE_PLUGINS,
              plugin.span,
              [_firstIncludedPluginName!],
            );
          }
        }
      } else if (plugins.length > 1) {
        String? firstPlugin;
        for (var plugin in pluginValues) {
          if (firstPlugin == null) {
            var pluginValue = plugin.value;
            if (pluginValue is String) {
              firstPlugin = pluginValue;
              continue;
            } else {
              // This plugin is bad and should not be marked as the first one.
              continue;
            }
          } else if (plugin.value != firstPlugin) {
            reporter.reportErrorForSpan(
              AnalysisOptionsWarningCode.MULTIPLE_PLUGINS,
              plugin.span,
              [firstPlugin],
            );
          }
        }
      }
    } else if (plugins is YamlMap) {
      var pluginValues = plugins.nodes.keys.cast<YamlNode?>();
      if (_firstIncludedPluginName != null) {
        // There is already at least one plugin specified in included options.
        for (var plugin in pluginValues) {
          if (plugin != null && plugin.value != _firstIncludedPluginName) {
            reporter.reportErrorForSpan(
              AnalysisOptionsWarningCode.MULTIPLE_PLUGINS,
              plugin.span,
              [_firstIncludedPluginName!],
            );
          }
        }
      } else if (plugins.length > 1) {
        String? firstPlugin;
        for (var plugin in pluginValues) {
          if (firstPlugin == null) {
            var pluginValue = plugin?.value;
            if (pluginValue is String) {
              firstPlugin = pluginValue;
              continue;
            } else {
              // This plugin is bad and should not be marked as the first one.
              continue;
            }
          } else if (plugin != null && plugin.value != firstPlugin) {
            reporter.reportErrorForSpan(
              AnalysisOptionsWarningCode.MULTIPLE_PLUGINS,
              plugin.span,
              [firstPlugin],
            );
          }
        }
      }
    }
  }
}

/// Validates `analyzer` strong-mode value configuration options.
class StrongModeOptionValueValidator extends OptionsValidator {
  final ErrorBuilder _builder = ErrorBuilder(AnalyzerOptions.strongModeOptions);

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalyzerOptions.analyzer);
    if (analyzer is YamlMap) {
      var strongModeNode = analyzer.valueAt(AnalyzerOptions.strongMode);
      if (strongModeNode is YamlScalar) {
        return _validateStrongModeAsScalar(reporter, strongModeNode);
      } else if (strongModeNode is YamlMap) {
        return _validateStrongModeAsMap(reporter, strongModeNode);
      } else if (strongModeNode != null) {
        reporter.reportErrorForSpan(
            AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
            strongModeNode.span,
            [AnalyzerOptions.strongMode]);
      }
    }
  }

  void _validateStrongModeAsMap(
      ErrorReporter reporter, YamlMap strongModeNode) {
    strongModeNode.nodes.forEach((k, v) {
      if (k is YamlScalar) {
        var key = k.value?.toString();
        if (!AnalyzerOptions.strongModeOptions.contains(key)) {
          _builder.reportError(reporter, AnalyzerOptions.strongMode, k);
        } else if (key == AnalyzerOptions.declarationCasts) {
          reporter.reportErrorForSpan(
              AnalysisOptionsWarningCode.ANALYSIS_OPTION_DEPRECATED,
              k.span,
              [AnalyzerOptions.declarationCasts]);
        } else if (key == AnalyzerOptions.implicitCasts) {
          reporter.reportErrorForSpan(
              AnalysisOptionsWarningCode
                  .ANALYSIS_OPTION_DEPRECATED_WITH_REPLACEMENT,
              k.span,
              [AnalyzerOptions.implicitCasts, 'strict-casts']);
        } else if (key == AnalyzerOptions.implicitDynamic) {
          reporter.reportErrorForSpan(
              AnalysisOptionsWarningCode
                  .ANALYSIS_OPTION_DEPRECATED_WITH_REPLACEMENT,
              k.span,
              [AnalyzerOptions.implicitDynamic, 'strict-raw-types']);
        } else {
          // The key is valid.
          if (v is YamlScalar) {
            var value = toLowerCase(v.value);
            if (!AnalyzerOptions.trueOrFalse.contains(value)) {
              reporter.reportErrorForSpan(
                  AnalysisOptionsWarningCode.UNSUPPORTED_VALUE,
                  v.span,
                  [key!, v.valueOrThrow, AnalyzerOptions.trueOrFalseProposal]);
            }
          }
        }
      }
    });
  }

  void _validateStrongModeAsScalar(
      ErrorReporter reporter, YamlScalar strongModeNode) {
    var stringValue = toLowerCase(strongModeNode.value);
    if (!AnalyzerOptions.trueOrFalse.contains(stringValue)) {
      reporter.reportErrorForSpan(
          AnalysisOptionsWarningCode.UNSUPPORTED_VALUE, strongModeNode.span, [
        AnalyzerOptions.strongMode,
        strongModeNode.valueOrThrow,
        AnalyzerOptions.trueOrFalseProposal
      ]);
    } else if (stringValue == 'false') {
      reporter.reportErrorForSpan(
          AnalysisOptionsWarningCode.SPEC_MODE_REMOVED, strongModeNode.span);
    } else if (stringValue == 'true') {
      reporter.reportErrorForSpan(
          AnalysisOptionsHintCode.STRONG_MODE_SETTING_DEPRECATED,
          strongModeNode.span);
    }
  }
}

/// Validates `analyzer` top-level options.
class TopLevelAnalyzerOptionsValidator extends TopLevelOptionValidator {
  TopLevelAnalyzerOptionsValidator()
      : super(AnalyzerOptions.analyzer, AnalyzerOptions.topLevel);
}

/// Validates top-level options. For example,
///     plugin:
///       top-level-option: true
class TopLevelOptionValidator extends OptionsValidator {
  final String pluginName;
  final List<String> supportedOptions;
  final String _valueProposal;
  final AnalysisOptionsWarningCode _warningCode;

  TopLevelOptionValidator(this.pluginName, this.supportedOptions)
      : assert(supportedOptions.isNotEmpty),
        _valueProposal = supportedOptions.quotedAndCommaSeparatedWithAnd,
        _warningCode = supportedOptions.length == 1
            ? AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUE
            : AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES;

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var node = options.valueAt(pluginName);
    if (node is YamlMap) {
      node.nodes.forEach((k, v) {
        if (k is YamlScalar) {
          if (!supportedOptions.contains(k.value)) {
            reporter.reportErrorForSpan(_warningCode, k.span,
                [pluginName, k.valueOrThrow, _valueProposal]);
          }
        }
        //TODO(pq): consider an error if the node is not a Scalar.
      });
    }
    // TODO(srawlins): Report non-Map with
    //  AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT.
  }
}

class _OptionsProcessor {
  /// Apply the options in the given [optionMap] to the given analysis
  /// [options].
  void applyToAnalysisOptions(AnalysisOptionsImpl options, YamlMap? optionMap) {
    if (optionMap == null) {
      return;
    }
    var analyzer = optionMap.valueAt(AnalyzerOptions.analyzer);
    if (analyzer is YamlMap) {
      // Process strong mode option.
      var strongMode = analyzer.valueAt(AnalyzerOptions.strongMode);
      _applyStrongOptions(options, strongMode);

      // Process filters.
      var filters = analyzer.valueAt(AnalyzerOptions.errors);
      _applyProcessors(options, filters);

      // Process enabled experiments.
      var experimentNames = analyzer.valueAt(AnalyzerOptions.enableExperiment);
      if (experimentNames is YamlList) {
        List<String> enabledExperiments = <String>[];
        for (var element in experimentNames.nodes) {
          var experimentName = _toString(element);
          if (experimentName != null) {
            enabledExperiments.add(experimentName);
          }
        }
        options.contextFeatures = FeatureSet.fromEnableFlags2(
          sdkLanguageVersion: ExperimentStatus.currentVersion,
          flags: enabledExperiments,
        );
      }

      // Process optional checks options.
      var optionalChecks = analyzer.valueAt(AnalyzerOptions.optionalChecks);
      _applyOptionalChecks(options, optionalChecks);

      // Process language options.
      var language = analyzer.valueAt(AnalyzerOptions.language);
      _applyLanguageOptions(options, language);

      // Process excludes.
      var excludes = analyzer.valueAt(AnalyzerOptions.exclude);
      _applyExcludes(options, excludes);

      var cannotIgnore = analyzer.valueAt(AnalyzerOptions.cannotIgnore);
      _applyUnignorables(options, cannotIgnore);

      // Process plugins.
      var plugins = analyzer.valueAt(AnalyzerOptions.plugins);
      _applyPlugins(options, plugins);
    }

    // Process the 'code-style' option.
    var codeStyle = optionMap.valueAt(AnalyzerOptions.codeStyle);
    options.codeStyleOptions = _buildCodeStyleOptions(options, codeStyle);

    var config = parseConfig(optionMap);
    if (config != null) {
      Iterable<LintRule> lintRules = Registry.ruleRegistry.enabled(config);
      if (lintRules.isNotEmpty) {
        options.lint = true;
        options.lintRules = lintRules.toList();
      }
    }
  }

  void _applyExcludes(AnalysisOptionsImpl options, YamlNode? excludes) {
    if (excludes is YamlList) {
      // TODO(srawlins): Report non-String items
      options.excludePatterns = excludes.whereType<String>().toList();
    }
    // TODO(srawlins): Report non-List with
    //  AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT.
  }

  void _applyLanguageOption(
      AnalysisOptionsImpl options, Object? feature, Object value) {
    var boolValue = toBool(value);
    if (boolValue != null) {
      if (feature == AnalyzerOptions.strictCasts) {
        options.strictCasts = boolValue;
      }
      if (feature == AnalyzerOptions.strictInference) {
        options.strictInference = boolValue;
      }
      if (feature == AnalyzerOptions.strictRawTypes) {
        options.strictRawTypes = boolValue;
      }
    }
  }

  void _applyLanguageOptions(AnalysisOptionsImpl options, YamlNode? configs) {
    if (configs is YamlMap) {
      configs.nodes.forEach((key, value) {
        if (key is YamlScalar && value is YamlScalar) {
          var feature = key.value?.toString();
          _applyLanguageOption(options, feature, value.valueOrThrow);
        }
      });
    }
  }

  void _applyOptionalChecks(AnalysisOptionsImpl options, YamlNode? config) {
    if (config is YamlMap) {
      config.nodes.forEach((k, v) {
        if (k is YamlScalar && v is YamlScalar) {
          _applyOptionalChecksOption(
              options, k.value?.toString(), v.valueOrThrow);
        }
      });
    }
    if (config is YamlScalar) {
      if (config.value?.toString() == AnalyzerOptions.chromeOsManifestChecks) {
        options.chromeOsManifestChecks = true;
      }
    }
  }

  void _applyOptionalChecksOption(
      AnalysisOptionsImpl options, String? feature, Object value) {
    var boolValue = toBool(value);
    if (boolValue != null) {
      if (feature == AnalyzerOptions.chromeOsManifestChecks) {
        options.chromeOsManifestChecks = boolValue;
      }
    }
  }

  void _applyPlugins(AnalysisOptionsImpl options, YamlNode? plugins) {
    var pluginName = _toString(plugins);
    if (pluginName != null) {
      options.enabledPluginNames = [pluginName];
    } else if (plugins is YamlList) {
      for (var element in plugins.nodes) {
        var pluginName = _toString(element);
        if (pluginName != null) {
          // Only the first plugin is supported.
          options.enabledPluginNames = [pluginName];
          return;
        }
      }
    } else if (plugins is YamlMap) {
      for (var key in plugins.nodes.keys.cast<YamlNode?>()) {
        var pluginName = _toString(key);
        if (pluginName != null) {
          // Only the first plugin is supported.
          options.enabledPluginNames = [pluginName];
          return;
        }
      }
    }
  }

  void _applyProcessors(AnalysisOptionsImpl options, YamlNode? codes) {
    ErrorConfig config = ErrorConfig(codes);
    options.errorProcessors = config.processors;
  }

  void _applyStrongModeOption(
      AnalysisOptionsImpl options, String? feature, Object value) {
    var boolValue = toBool(value);
    if (boolValue != null) {
      if (feature == AnalyzerOptions.implicitCasts) {
        options.implicitCasts = boolValue;
      }
      if (feature == AnalyzerOptions.implicitDynamic) {
        options.implicitDynamic = boolValue;
      }
      if (feature == AnalyzerOptions.propagateLinterExceptions) {
        options.propagateLinterExceptions = boolValue;
      }
    }
  }

  void _applyStrongOptions(AnalysisOptionsImpl options, YamlNode? config) {
    if (config is YamlMap) {
      config.nodes.forEach((k, v) {
        if (k is YamlScalar && v is YamlScalar) {
          _applyStrongModeOption(options, k.value?.toString(), v.valueOrThrow);
        }
      });
    }
  }

  void _applyUnignorables(AnalysisOptionsImpl options, YamlNode? cannotIgnore) {
    if (cannotIgnore is YamlList) {
      var names = <String>{};
      var stringValues = cannotIgnore.whereType<String>().toSet();
      for (var severity in AnalyzerOptions.severities) {
        if (stringValues.contains(severity)) {
          // [severity] is a marker denoting all error codes with severity
          // equal to [severity].
          stringValues.remove(severity);
          // Replace name like 'error' with error codes with this named
          // severity.
          for (var e in errorCodeValues) {
            // If the severity of [error] is also changed in this options file
            // to be [severity], we add [error] to the un-ignorable list.
            var processors = options.errorProcessors
                .where((processor) => processor.code == e.name);
            if (processors.isNotEmpty &&
                processors.first.severity?.displayName == severity) {
              names.add(e.name);
              continue;
            }
            // Otherwise, add [error] if its default severity is [severity].
            if (e.errorSeverity.displayName == severity) {
              names.add(e.name);
            }
          }
        }
      }
      names.addAll(stringValues.map((name) => name.toUpperCase()));
      options.unignorableNames = names;
    }
  }

  CodeStyleOptions _buildCodeStyleOptions(
      AnalysisOptionsImpl options, YamlNode? config) {
    var useFormatter = false;
    if (config is YamlMap) {
      var formatNode = config.valueAt(AnalyzerOptions.format);
      if (formatNode != null) {
        var formatValue = toBool(formatNode);
        if (formatValue is bool) {
          useFormatter = formatValue;
        }
      }
    }
    return CodeStyleOptionsImpl(options, useFormatter: useFormatter);
  }

  String? _toString(YamlNode? node) {
    if (node is YamlScalar) {
      var value = node.value;
      if (value is String) {
        return value;
      }
    }
    return null;
  }
}
