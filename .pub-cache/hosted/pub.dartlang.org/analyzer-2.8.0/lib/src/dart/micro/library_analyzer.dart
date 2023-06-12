// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/constant/compute.dart';
import 'package:analyzer/src/dart/constant/constant_verifier.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/constant/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/micro/library_graph.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/legacy_type_asserter.dart';
import 'package:analyzer/src/dart/resolver/resolution_visitor.dart';
import 'package:analyzer/src/error/best_practices_verifier.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/dead_code_verifier.dart';
import 'package:analyzer/src/error/ignore_validator.dart';
import 'package:analyzer/src/error/imports_verifier.dart';
import 'package:analyzer/src/error/inheritance_override.dart';
import 'package:analyzer/src/error/override_verifier.dart';
import 'package:analyzer/src/error/todo_finder.dart';
import 'package:analyzer/src/error/unicode_text_verifier.dart';
import 'package:analyzer/src/error/unused_local_elements_verifier.dart';
import 'package:analyzer/src/generated/declaration_resolver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/hint/sdk_constraint_verifier.dart';
import 'package:analyzer/src/ignore_comments/ignore_info.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/linter_visitor.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/task/strong/checker.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:pub_semver/pub_semver.dart';

/// Analyzer of a single library.
class LibraryAnalyzer {
  /// A marker object used to prevent the initialization of
  /// [_versionConstraintFromPubspec] when the previous initialization attempt
  /// failed.
  static final VersionRange noSpecifiedRange = VersionRange();
  final AnalysisOptionsImpl _analysisOptions;
  final DeclaredVariables _declaredVariables;
  final SourceFactory _sourceFactory;
  final FileState _library;

  final InheritanceManager3 _inheritance;
  final bool Function(Uri) _isLibraryUri;
  final AnalysisContext _context;
  final LinkedElementFactory _elementFactory;

  late LibraryElementImpl _libraryElement;

  final Map<FileState, LineInfo> _fileToLineInfo = {};

  final Map<FileState, IgnoreInfo> _fileToIgnoreInfo = {};
  final Map<FileState, RecordingErrorListener> _errorListeners = {};
  final Map<FileState, ErrorReporter> _errorReporters = {};
  final List<UsedImportedElements> _usedImportedElementsList = [];
  final List<UsedLocalElements> _usedLocalElementsList = [];

  /// Constants in the current library.
  ///
  /// TODO(scheglov) Remove after https://github.com/dart-lang/sdk/issues/31925
  final Set<ConstantEvaluationTarget> _libraryConstants = {};

  final Set<ConstantEvaluationTarget> _constants = {};

  final String Function(FileState file) getFileContent;

  LibraryAnalyzer(
    this._analysisOptions,
    this._declaredVariables,
    this._sourceFactory,
    this._isLibraryUri,
    this._context,
    this._elementFactory,
    this._inheritance,
    this._library,
    this.getFileContent,
  );

  TypeProviderImpl get _typeProvider => _libraryElement.typeProvider;

  TypeSystemImpl get _typeSystem => _libraryElement.typeSystem;

  /// Compute analysis results for all units of the library.
  Map<FileState, UnitAnalysisResult> analyze({
    required String? completionPath,
    required int? completionOffset,
    required OperationPerformanceImpl performance,
  }) {
    var forCompletion = completionPath != null;
    var units = <FileState, CompilationUnitImpl>{};

    // Parse all files.
    performance.run('parse', (performance) {
      for (FileState file in _library.files().ofLibrary) {
        if (completionPath == null || file.path == completionPath) {
          units[file] = _parse(
            file: file,
            performance: performance,
          );
        }
      }
    });

    // Resolve URIs in directives to corresponding sources.
    FeatureSet featureSet = units.values.first.featureSet;

    performance.run('resolveUriDirectives', (performance) {
      units.forEach((file, unit) {
        _validateFeatureSet(unit, featureSet);
        _resolveUriBasedDirectives(file, unit);
      });
    });

    performance.run('libraryElement', (performance) {
      _libraryElement = _elementFactory.libraryOfUri2(_library.uriStr);
    });

    performance.run('resolveDirectives', (performance) {
      _resolveDirectives(units, completionPath);
    });

    performance.run('resolveFiles', (performance) {
      units.forEach((file, unit) {
        _resolveFile(
          completionOffset: completionOffset,
          file: file,
          unit: unit,
        );
      });
    });

    if (!forCompletion) {
      performance.run('computeConstants', (performance) {
        units.values.forEach(_findConstants);
        _clearConstantEvaluationResults();
        _computeConstants();
      });

      _computeDiagnostics(performance: performance, units: units);
    }

    assert(units.values.every(LegacyTypeAsserter.assertLegacyTypes));

    // Return full results.
    Map<FileState, UnitAnalysisResult> results = {};
    units.forEach((file, unit) {
      List<AnalysisError> errors = _getErrorListener(file).errors;
      errors = _filterIgnoredErrors(file, errors);
      results[file] = UnitAnalysisResult(file, unit, errors);
    });
    return results;
  }

  /// Clear evaluation results for all constants before computing them again.
  /// The reason is described in https://github.com/dart-lang/sdk/issues/35940
  ///
  /// Otherwise, we reuse results, including errors are recorded only when
  /// we evaluate constants resynthesized from summaries.
  ///
  /// TODO(scheglov) Remove after https://github.com/dart-lang/sdk/issues/31925
  void _clearConstantEvaluationResults() {
    for (var constant in _libraryConstants) {
      if (constant is ConstFieldElementImpl_ofEnum) continue;
      if (constant is ConstVariableElement) {
        constant.evaluationResult = null;
      }
    }
  }

  void _computeConstantErrors(
      ErrorReporter errorReporter, CompilationUnit unit) {
    ConstantVerifier constantVerifier =
        ConstantVerifier(errorReporter, _libraryElement, _declaredVariables);
    unit.accept(constantVerifier);
  }

  /// Compute [_constants] in all units.
  void _computeConstants() {
    computeConstants(_typeProvider, _typeSystem, _declaredVariables,
        _constants.toList(), _analysisOptions.experimentStatus);
  }

  void _computeDiagnostics({
    required OperationPerformanceImpl performance,
    required Map<FileState, CompilationUnit> units,
  }) {
    performance.run('computeVerifyErrors', (performance) {
      units.forEach((file, unit) {
        _computeVerifyErrors(file, unit);
      });
    });

    if (_analysisOptions.hint) {
      performance.run('computeHints', (performance) {
        units.forEach((file, unit) {
          {
            var visitor = GatherUsedLocalElementsVisitor(_libraryElement);
            unit.accept(visitor);
            _usedLocalElementsList.add(visitor.usedElements);
          }
          {
            var visitor = GatherUsedImportedElementsVisitor(_libraryElement);
            unit.accept(visitor);
            _usedImportedElementsList.add(visitor.usedElements);
          }
        });
        units.forEach((file, unit) {
          _computeHints(file, unit);
        });
      });
    }

    if (_analysisOptions.lint) {
      performance.run('computeLints', (performance) {
        var allUnits = _library.files().ofLibrary.map((file) {
          var content = getFileContent(file);
          return LinterContextUnit(content, units[file]!);
        }).toList();
        for (int i = 0; i < allUnits.length; i++) {
          _computeLints(_library.files().ofLibrary[i], allUnits[i], allUnits);
        }
      });
    }

    // This must happen after all other diagnostics have been computed but
    // before the list of diagnostics has been filtered.
    for (var file in _library.files().ofLibrary) {
      IgnoreValidator(
        _getErrorReporter(file),
        _getErrorListener(file).errors,
        _fileToIgnoreInfo[file]!,
        _fileToLineInfo[file]!,
        _analysisOptions.unignorableNames,
      ).reportErrors();
    }
  }

  void _computeHints(FileState file, CompilationUnit unit) {
    AnalysisErrorListener errorListener = _getErrorListener(file);
    ErrorReporter errorReporter = _getErrorReporter(file);

    if (!_libraryElement.isNonNullableByDefault) {
      unit.accept(
        LegacyDeadCodeVerifier(
          errorReporter,
          typeSystem: _typeSystem,
        ),
      );
    }

    unit.accept(DeadCodeVerifier(errorReporter));

    var content = getFileContent(file);
    UnicodeTextVerifier(errorReporter).verify(unit, content);

    unit.accept(
      BestPracticesVerifier(
        errorReporter,
        _typeProvider,
        _libraryElement,
        unit,
        content,
        declaredVariables: _declaredVariables,
        typeSystem: _typeSystem,
        inheritanceManager: _inheritance,
        analysisOptions: _context.analysisOptions,
        workspacePackage: _library.workspacePackage,
      ),
    );

    unit.accept(OverrideVerifier(
      _inheritance,
      _libraryElement,
      errorReporter,
    ));

    TodoFinder(errorReporter).findIn(unit);

    // Verify imports.
    {
      ImportsVerifier verifier = ImportsVerifier();
      verifier.addImports(unit);
      _usedImportedElementsList.forEach(verifier.removeUsedElements);
      verifier.generateDuplicateImportHints(errorReporter);
      verifier.generateDuplicateShownHiddenNameHints(errorReporter);
      verifier.generateUnusedImportHints(errorReporter);
      verifier.generateUnusedShownNameHints(errorReporter);
    }

    // Unused local elements.
    {
      UsedLocalElements usedElements =
          UsedLocalElements.merge(_usedLocalElementsList);
      UnusedLocalElementsVerifier visitor = UnusedLocalElementsVerifier(
          errorListener, usedElements, _inheritance, _libraryElement);
      unit.accept(visitor);
    }

    //
    // Find code that uses features from an SDK version that does not satisfy
    // the SDK constraints specified in analysis options.
    //
    var sdkVersionConstraint = _analysisOptions.sdkVersionConstraint;
    if (sdkVersionConstraint != null) {
      SdkConstraintVerifier verifier = SdkConstraintVerifier(
          errorReporter, _libraryElement, _typeProvider, sdkVersionConstraint);
      unit.accept(verifier);
    }
  }

  void _computeLints(FileState file, LinterContextUnit currentUnit,
      List<LinterContextUnit> allUnits) {
    var unit = currentUnit.unit;

    ErrorReporter errorReporter = _getErrorReporter(file);

    var nodeRegistry = NodeLintRegistry(_analysisOptions.enableTiming);
    final workspacePackage = _getPackage(currentUnit.unit);
    var context = LinterContextImpl(
        allUnits,
        currentUnit,
        _declaredVariables,
        _typeProvider,
        _typeSystem,
        _inheritance,
        _analysisOptions,
        workspacePackage);
    for (Linter linter in _analysisOptions.lintRules) {
      linter.reporter = errorReporter;
      linter.registerNodeProcessors(nodeRegistry, context);
    }

    // Run lints that handle specific node types.
    unit.accept(
      LinterVisitor(
        nodeRegistry,
        LinterExceptionHandler(
          propagateExceptions: _analysisOptions.propagateLinterExceptions,
        ).logException,
      ),
    );
  }

  void _computeVerifyErrors(FileState file, CompilationUnit unit) {
    RecordingErrorListener errorListener = _getErrorListener(file);

    CodeChecker checker = CodeChecker(
      _typeProvider,
      _typeSystem,
      _inheritance,
      errorListener,
    );
    checker.visitCompilationUnit(unit);

    ErrorReporter errorReporter = _getErrorReporter(file);

    //
    // Validate the directives.
    //
    _validateUriBasedDirectives(file, unit);

    //
    // Use the ConstantVerifier to compute errors.
    //
    _computeConstantErrors(errorReporter, unit);

    //
    // Compute inheritance and override errors.
    //
    var inheritanceOverrideVerifier =
        InheritanceOverrideVerifier(_typeSystem, _inheritance, errorReporter);
    inheritanceOverrideVerifier.verifyUnit(unit);

    //
    // Use the ErrorVerifier to compute errors.
    //
    ErrorVerifier errorVerifier = ErrorVerifier(
        errorReporter, _libraryElement, _typeProvider, _inheritance);
    unit.accept(errorVerifier);
  }

  /// Return a subset of the given [errors] that are not marked as ignored in
  /// the [file].
  List<AnalysisError> _filterIgnoredErrors(
      FileState file, List<AnalysisError> errors) {
    if (errors.isEmpty) {
      return errors;
    }

    IgnoreInfo ignoreInfo = _fileToIgnoreInfo[file]!;
    if (!ignoreInfo.hasIgnores) {
      return errors;
    }

    LineInfo lineInfo = _fileToLineInfo[file]!;

    bool isIgnored(AnalysisError error) {
      int errorLine = lineInfo.getLocation(error.offset).lineNumber;
      return ignoreInfo.ignoredAt(error.errorCode, errorLine);
    }

    return errors.where((AnalysisError e) => !isIgnored(e)).toList();
  }

  /// Find constants to compute.
  void _findConstants(CompilationUnit unit) {
    ConstantFinder constantFinder = ConstantFinder();
    unit.accept(constantFinder);
    _libraryConstants.addAll(constantFinder.constantsToCompute);
    _constants.addAll(constantFinder.constantsToCompute);

    var dependenciesFinder = ConstantExpressionsDependenciesFinder();
    unit.accept(dependenciesFinder);
    _constants.addAll(dependenciesFinder.dependencies);
  }

  RecordingErrorListener _getErrorListener(FileState file) =>
      _errorListeners.putIfAbsent(file, () => RecordingErrorListener());

  ErrorReporter _getErrorReporter(FileState file) {
    return _errorReporters.putIfAbsent(file, () {
      RecordingErrorListener listener = _getErrorListener(file);
      return ErrorReporter(listener, file.source);
    });
  }

  WorkspacePackage? _getPackage(CompilationUnit unit) {
    final libraryPath = _library.source.fullName;
    final session = unit.declaredElement!.session;
    final workspace = session.analysisContext.contextRoot.workspace;
    return workspace.findPackageFor(libraryPath);
  }

  /// Return the name of the library that the given part is declared to be a
  /// part of, or `null` if the part does not contain a part-of directive.
  _NameOrSource? _getPartLibraryNameOrUri(Source partSource,
      CompilationUnit partUnit, List<Directive> directivesToResolve) {
    for (Directive directive in partUnit.directives) {
      if (directive is PartOfDirective) {
        directivesToResolve.add(directive);
        var libraryName = directive.libraryName;
        if (libraryName != null) {
          return _NameOrSource(libraryName.name, null);
        }
        var uri = directive.uri?.stringValue;
        if (uri != null) {
          var librarySource = _sourceFactory.resolveUri(partSource, uri);
          if (librarySource != null) {
            return _NameOrSource(null, librarySource);
          }
        }
      }
    }
    return null;
  }

  bool _isExistingSource(Source source) {
    for (var file in _library.files().directReferencedFiles) {
      if (file.uri == source.uri) {
        return file.exists;
      }
    }
    return false;
  }

  /// Return `true` if the given [source] is a library.
  bool _isLibrarySource(Source source) {
    return _isLibraryUri(source.uri);
  }

  /// Return a  parsed unresolved [CompilationUnit].
  CompilationUnitImpl _parse({
    required FileState file,
    required OperationPerformanceImpl performance,
  }) {
    String content = getFileContent(file);

    performance.getDataInt('count').increment();
    performance.getDataInt('length').add(content.length);

    AnalysisErrorListener errorListener = _getErrorListener(file);
    var unit = file.parse(errorListener, content);

    LineInfo lineInfo = unit.lineInfo!;
    _fileToLineInfo[file] = lineInfo;
    _fileToIgnoreInfo[file] = IgnoreInfo.forDart(unit, content);

    return unit;
  }

  void _resolveDirectives(
    Map<FileState, CompilationUnitImpl> units,
    String? completionPath,
  ) {
    if (completionPath != null) {
      var completionUnit = units.values.first;
      var unitElement = _unitElementWithPath(completionPath);
      // TODO(scheglov) https://github.com/dart-lang/sdk/issues/44840
      if (unitElement == null) {
        String shortString(String s) {
          const maxLength = 1000;
          if (s.length > maxLength) {
            return s.substring(0, maxLength);
          }
          return s;
        }

        var libraryContent = '<unknown>';
        try {
          libraryContent = _library.getContent();
          libraryContent = shortString(libraryContent);
        } catch (_) {}

        var libraryUnitPaths =
            _libraryElement.units.map((e) => e.source.fullName).toList();
        throw '[completionPath: $completionPath]'
            '[library.path: ${_library.path}]'
            '[library.uri: ${_library.uri}]'
            '[libraryUnitPaths: $libraryUnitPaths]'
            '[libraryContent: $libraryContent]'
            '[unitStr: ${shortString('$completionUnit')}]';
      }
      completionUnit.element = unitElement;
      return;
    }

    var definingCompilationUnit = units[_library]!;
    definingCompilationUnit.element = _libraryElement.definingCompilationUnit;

    bool matchNodeElement(Directive node, Element element) {
      return node.keyword.offset == element.nameOffset;
    }

    ErrorReporter libraryErrorReporter = _getErrorReporter(_library);

    LibraryIdentifier? libraryNameNode;
    var seenPartSources = <Source>{};
    var directivesToResolve = <DirectiveImpl>[];
    int partIndex = 0;
    for (Directive directive in definingCompilationUnit.directives) {
      if (directive is LibraryDirectiveImpl) {
        libraryNameNode = directive.name;
        directivesToResolve.add(directive);
      } else if (directive is ImportDirectiveImpl) {
        for (ImportElement importElement in _libraryElement.imports) {
          if (matchNodeElement(directive, importElement)) {
            directive.element = importElement;
            directive.prefix?.staticElement = importElement.prefix;
            var source = importElement.importedLibrary?.source;
            if (source != null && !_isLibrarySource(source)) {
              // It is safe to assume that `directive.uri.stringValue` is
              // non-`null`, because the only time it is `null` is if the URI
              // contains a string interpolation, in which case the import
              // would never have resolved in the first place.
              ErrorCode errorCode = CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY;
              libraryErrorReporter.reportErrorForNode(
                  errorCode, directive.uri, [directive.uri.stringValue!]);
            }
          }
        }
      } else if (directive is ExportDirectiveImpl) {
        for (ExportElement exportElement in _libraryElement.exports) {
          if (matchNodeElement(directive, exportElement)) {
            directive.element = exportElement;
            var source = exportElement.exportedLibrary?.source;
            if (source != null && !_isLibrarySource(source)) {
              // It is safe to assume that `directive.uri.stringValue` is
              // non-`null`, because the only time it is `null` is if the URI
              // contains a string interpolation, in which case the export
              // would never have resolved in the first place.
              libraryErrorReporter.reportErrorForNode(
                  CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY,
                  directive.uri,
                  [directive.uri.stringValue!]);
            }
          }
        }
      } else if (directive is PartDirectiveImpl) {
        StringLiteral partUri = directive.uri;

        FileState partFile = _library.files().parted[partIndex];
        var partUnit = units[partFile]!;
        CompilationUnitElement partElement = _libraryElement.parts[partIndex];
        partUnit.element = partElement;
        directive.element = partElement;
        partIndex++;

        var partSource = directive.uriSource;
        if (partSource == null) {
          continue;
        }

        //
        // Validate that the part source is unique in the library.
        //
        if (!seenPartSources.add(partSource)) {
          libraryErrorReporter.reportErrorForNode(
              CompileTimeErrorCode.DUPLICATE_PART, partUri, [partSource.uri]);
        }

        //
        // Validate that the part contains a part-of directive with the same
        // name or uri as the library.
        //
        if (_isExistingSource(partSource)) {
          var nameOrSource = _getPartLibraryNameOrUri(
              partSource, partUnit, directivesToResolve);
          if (nameOrSource == null) {
            libraryErrorReporter.reportErrorForNode(
                CompileTimeErrorCode.PART_OF_NON_PART,
                partUri,
                [partUri.toSource()]);
          } else {
            var name = nameOrSource.name;
            if (name != null) {
              if (libraryNameNode == null) {
                libraryErrorReporter.reportErrorForNode(
                    CompileTimeErrorCode.PART_OF_UNNAMED_LIBRARY,
                    partUri,
                    [name]);
              } else if (libraryNameNode.name != name) {
                libraryErrorReporter.reportErrorForNode(
                    CompileTimeErrorCode.PART_OF_DIFFERENT_LIBRARY,
                    partUri,
                    [libraryNameNode.name, name]);
              }
            } else {
              var source = nameOrSource.source!;
              if (source != _library.source) {
                libraryErrorReporter.reportErrorForNode(
                    CompileTimeErrorCode.PART_OF_DIFFERENT_LIBRARY,
                    partUri,
                    [_library.uriStr, source.uri]);
              }
            }
          }
        }
      }
    }

    // TODO(brianwilkerson) Report the error
    // ResolverErrorCode.MISSING_LIBRARY_DIRECTIVE_WITH_PART

    //
    // Resolve the relevant directives to the library element.
    //
    for (var directive in directivesToResolve) {
      directive.element = _libraryElement;
    }

    // TODO(scheglov) remove DirectiveResolver class
  }

  void _resolveFile({
    required int? completionOffset,
    required FileState file,
    required CompilationUnit unit,
  }) {
    Source source = file.source;

    RecordingErrorListener errorListener = _getErrorListener(file);

    var unitElement = unit.declaredElement as CompilationUnitElementImpl;

    unit.accept(
      ResolutionVisitor(
        unitElement: unitElement,
        errorListener: errorListener,
        featureSet: unit.featureSet,
        nameScope: _libraryElement.scope,
        elementWalker: ElementWalker.forCompilationUnit(unitElement),
      ),
    );

    unit.accept(ScopeResolverVisitor(
        _libraryElement, source, _typeProvider, errorListener,
        nameScope: _libraryElement.scope));

    // Nothing for RESOLVED_UNIT8?
    // Nothing for RESOLVED_UNIT9?
    // Nothing for RESOLVED_UNIT10?

    FlowAnalysisHelper flowAnalysisHelper =
        FlowAnalysisHelper(_typeSystem, false, unit.featureSet);

    var resolverVisitor = ResolverVisitor(
        _inheritance, _libraryElement, source, _typeProvider, errorListener,
        featureSet: unit.featureSet, flowAnalysisHelper: flowAnalysisHelper);

    var donePartialResolution = false;
    if (completionOffset != null) {
      var node = NodeLocator(completionOffset).searchWithin(unit);
      var nodeToResolve = node?.thisOrAncestorMatching((e) {
        return e.parent is ClassDeclaration ||
            e.parent is CompilationUnit ||
            e.parent is MixinDeclaration;
      });
      if (nodeToResolve != null) {
        var can = resolverVisitor.prepareForResolving(nodeToResolve);
        if (can) {
          nodeToResolve.accept(resolverVisitor);
          donePartialResolution = true;
        }
      }
    }

    if (!donePartialResolution) {
      unit.accept(resolverVisitor);
    }
  }

  /// Return the result of resolve the given [uriContent], reporting errors
  /// against the [uriLiteral].
  Source? _resolveUri(FileState file, bool isImport, StringLiteral uriLiteral,
      String? uriContent) {
    var code =
        UriBasedDirectiveImpl.validateUri(isImport, uriLiteral, uriContent);
    if (code == null) {
      return _sourceFactory.resolveUri(file.source, uriContent);
    } else if (code == UriValidationCode.URI_WITH_INTERPOLATION) {
      _getErrorReporter(file).reportErrorForNode(
          CompileTimeErrorCode.URI_WITH_INTERPOLATION, uriLiteral);
      return null;
    } else if (code == UriValidationCode.INVALID_URI) {
      // It is safe to assume [uriContent] is non-null because the only way for
      // it to be null is if the string literal contained an interpolation, and
      // in that case the validation code would have been
      // UriValidationCode.URI_WITH_INTERPOLATION.
      _getErrorReporter(file).reportErrorForNode(
          CompileTimeErrorCode.INVALID_URI, uriLiteral, [uriContent!]);
      return null;
    }
    return null;
  }

  void _resolveUriBasedDirectives(FileState file, CompilationUnit unit) {
    for (var directive in unit.directives) {
      if (directive is UriBasedDirectiveImpl) {
        StringLiteral uriLiteral = directive.uri;
        var uriContent = uriLiteral.stringValue?.trim();
        directive.uriContent = uriContent;
        var defaultSource = _resolveUri(
            file, directive is ImportDirective, uriLiteral, uriContent);
        directive.uriSource = defaultSource;
      }
    }
  }

  CompilationUnitElement? _unitElementWithPath(String path) {
    for (var unitElement in _libraryElement.units) {
      if (unitElement.source.fullName == path) {
        return unitElement;
      }
    }
    return null;
  }

  /// Validate that the feature set associated with the compilation [unit] is
  /// the same as the [expectedSet] of features supported by the library.
  void _validateFeatureSet(CompilationUnit unit, FeatureSet expectedSet) {
    FeatureSet actualSet = unit.featureSet;
    if (actualSet != expectedSet) {
      // TODO(brianwilkerson) Generate a diagnostic.
    }
  }

  /// Check the given [directive] to see if the referenced source exists and
  /// report an error if it does not.
  void _validateUriBasedDirective(
      FileState file, UriBasedDirectiveImpl directive) {
    var source = directive.uriSource;
    if (source != null) {
      if (_isExistingSource(source)) {
        return;
      }
    } else {
      // Don't report errors already reported by ParseDartTask.resolveDirective
      // TODO(scheglov) we don't use this task here
      if (directive.validate() != null) {
        return;
      }
    }

    var uriContent = directive.uriContent;
    if (uriContent != null && uriContent.startsWith('dart-ext:')) {
      _getErrorReporter(file).reportErrorForNode(
        CompileTimeErrorCode.USE_OF_NATIVE_EXTENSION,
        directive.uri,
      );
      return;
    }

    StringLiteral uriLiteral = directive.uri;
    CompileTimeErrorCode errorCode = CompileTimeErrorCode.URI_DOES_NOT_EXIST;
    if (isGeneratedSource(source)) {
      errorCode = CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED;
    }
    // It is safe to assume that `uriContent` is non-null because the only way
    // for it to be null is if the string literal contained an interpolation,
    // and in that case the call to `directive.validate()` above would have
    // returned a non-null validation code.
    _getErrorReporter(file)
        .reportErrorForNode(errorCode, uriLiteral, [uriContent!]);
  }

  /// Check each directive in the given [unit] to see if the referenced source
  /// exists and report an error if it does not.
  void _validateUriBasedDirectives(FileState file, CompilationUnit unit) {
    for (var directive in unit.directives) {
      if (directive is UriBasedDirectiveImpl) {
        _validateUriBasedDirective(file, directive);
      }
    }
  }
}

/// Analysis result for single file.
class UnitAnalysisResult {
  final FileState file;
  final CompilationUnit unit;
  final List<AnalysisError> errors;

  UnitAnalysisResult(this.file, this.unit, this.errors);
}

/// Either the name or the source associated with a part-of directive.
class _NameOrSource {
  final String? name;
  final Source? source;

  _NameOrSource(this.name, this.source);
}
