// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart'
    as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/multi_executor.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/protocol.dart' as macro;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/macro_application_error.dart';
import 'package:analyzer/src/summary2/macro_declarations.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

class LibraryMacroApplier {
  final DeclarationBuilder declarationBuilder;
  final LibraryBuilder libraryBuilder;
  final MultiMacroExecutor macroExecutor;

  final List<_MacroTarget> _targets = [];

  late final macro.IdentifierResolver _identifierResolver =
      _IdentifierResolver(_linker.elementFactory, declarationBuilder);

  late final macro.TypeDeclarationResolver _typeDeclarationResolver =
      _TypeDeclarationResolver(declarationBuilder);

  late final macro.TypeIntrospector _typeIntrospector =
      _TypeIntrospector(declarationBuilder);

  late final macro.TypeResolver _typeResolver = _TypeResolver(
    typeSystem: libraryBuilder.element.typeSystem,
  );

  LibraryMacroApplier({
    required this.macroExecutor,
    required this.declarationBuilder,
    required this.libraryBuilder,
  });

  Linker get _linker => libraryBuilder.linker;

  /// Fill [_targets]s with macro applications.
  Future<void> buildApplications({
    required OperationPerformanceImpl performance,
  }) async {
    final collector = _MacroTargetElementCollector();
    libraryBuilder.element.accept(collector);

    for (final targetElement in collector.targets) {
      final targetNode = _linker.elementNodes[targetElement as ElementImpl];
      // TODO(scheglov) support other declarations
      if (targetNode is ClassDeclaration) {
        await performance.runAsync(
          'forClassDeclaration',
          (performance) async {
            await _buildApplications(
              targetElement,
              targetNode.metadata,
              macro.DeclarationKind.clazz,
              () => declarationBuilder.fromNode.classDeclaration(targetNode),
              performance: performance,
            );
          },
        );
      }
    }
  }

  Future<String?> executeDeclarationsPhase() async {
    final results = <macro.MacroExecutionResult>[];
    for (final target in _targets) {
      for (final application in target.applications) {
        if (application.shouldExecute(macro.Phase.declarations)) {
          await _runWithCatchingExceptions(
            () async {
              final result = await application.executeDeclarationsPhase();
              if (result.isNotEmpty) {
                results.add(result);
              }
            },
            annotationIndex: application.annotationIndex,
            onError: (error) {
              target.element.addMacroApplicationError(error);
            },
          );
        }
      }
    }
    return _buildAugmentationLibrary(results);
  }

  Future<String?> executeTypesPhase() async {
    final results = <macro.MacroExecutionResult>[];
    for (final target in _targets) {
      for (final application in target.applications) {
        if (application.shouldExecute(macro.Phase.types)) {
          await _runWithCatchingExceptions(
            () async {
              final result = await application.executeTypesPhase();
              if (result.isNotEmpty) {
                results.add(result);
              }
            },
            annotationIndex: application.annotationIndex,
            onError: (error) {
              target.element.addMacroApplicationError(error);
            },
          );
        }
      }
    }
    return _buildAugmentationLibrary(results);
  }

  /// If there are any macro applications in [annotations], add a new
  /// element into [_targets].
  Future<void> _buildApplications(
    MacroTargetElement targetElement,
    List<Annotation> annotations,
    macro.DeclarationKind declarationKind,
    macro.DeclarationImpl Function() getDeclaration, {
    required OperationPerformanceImpl performance,
  }) async {
    final applications = <_MacroApplication>[];

    for (var i = 0; i < annotations.length; i++) {
      Future<macro.MacroInstanceIdentifier?> instantiateSingle({
        required ClassElementImpl macroClass,
        required String constructorName,
        required ArgumentList argumentsNode,
      }) async {
        final importedLibrary = macroClass.library;
        final macroExecutor = importedLibrary.bundleMacroExecutor;
        if (macroExecutor != null) {
          return await _runWithCatchingExceptions(
            () async {
              final arguments = _buildArguments(
                annotationIndex: i,
                node: argumentsNode,
              );
              return await performance.runAsync('instantiate', (_) {
                return macroExecutor.instantiate(
                  libraryUri: macroClass.librarySource.uri,
                  className: macroClass.name,
                  constructorName: constructorName,
                  arguments: arguments,
                );
              });
            },
            annotationIndex: i,
            onError: (error) {
              targetElement.addMacroApplicationError(error);
            },
          );
        }
        return null;
      }

      final annotation = annotations[i];
      final macroInstance = await _importedMacroDeclaration(
        annotation,
        whenClass: ({
          required macroClass,
          required constructorName,
        }) async {
          final argumentsNode = annotation.arguments;
          if (argumentsNode != null) {
            return await instantiateSingle(
              macroClass: macroClass,
              constructorName: constructorName ?? '',
              argumentsNode: argumentsNode,
            );
          }
        },
        whenGetter: ({
          required macroClass,
          required instanceCreation,
        }) async {
          return await instantiateSingle(
            macroClass: macroClass,
            constructorName: instanceCreation.constructorName.name?.name ?? '',
            argumentsNode: instanceCreation.argumentList,
          );
        },
      );

      if (macroInstance != null) {
        applications.add(
          _MacroApplication(
            annotationIndex: i,
            instanceIdentifier: macroInstance,
          ),
        );
      }
    }

    if (applications.isNotEmpty) {
      _targets.add(
        _MacroTarget(
          applier: this,
          element: targetElement,
          declarationKind: declarationKind,
          declaration: getDeclaration(),
          applications: applications,
        ),
      );
    }
  }

  /// If there are any [results], builds the augmentation library with them.
  String? _buildAugmentationLibrary(
    List<macro.MacroExecutionResult> results,
  ) {
    if (results.isEmpty) {
      return null;
    }

    final code = macroExecutor.buildAugmentationLibrary(
      results,
      _resolveIdentifier,
      _inferOmittedType,
    );
    return code.trim();
  }

  /// If [annotation] references a macro, invokes the right callback.
  Future<R?> _importedMacroDeclaration<R>(
    Annotation annotation, {
    required Future<R?> Function({
      required ClassElementImpl macroClass,
      required String? constructorName,
    })
        whenClass,
    required Future<R?> Function({
      required ClassElementImpl macroClass,
      required InstanceCreationExpression instanceCreation,
    })
        whenGetter,
  }) async {
    final String? prefix;
    final String name;
    final String? constructorName;
    final nameNode = annotation.name;
    if (nameNode is SimpleIdentifier) {
      prefix = null;
      name = nameNode.name;
      constructorName = annotation.constructorName?.name;
    } else if (nameNode is PrefixedIdentifier) {
      final importPrefixCandidate = nameNode.prefix.name;
      final hasImportPrefix = libraryBuilder.element.libraryImports.any(
          (import) => import.prefix?.element.name == importPrefixCandidate);
      if (hasImportPrefix) {
        prefix = importPrefixCandidate;
        name = nameNode.identifier.name;
        constructorName = annotation.constructorName?.name;
      } else {
        prefix = null;
        name = nameNode.prefix.name;
        constructorName = nameNode.identifier.name;
      }
    } else {
      throw StateError('${nameNode.runtimeType} $nameNode');
    }

    for (final import in libraryBuilder.element.libraryImports) {
      if (import.prefix?.element.name != prefix) {
        continue;
      }

      final importedLibrary = import.importedLibrary;
      if (importedLibrary == null) {
        continue;
      }

      // Skip if a library that is being linked.
      final importedUri = importedLibrary.source.uri;
      if (_linker.builders.containsKey(importedUri)) {
        continue;
      }

      final lookupResult = importedLibrary.scope.lookup(name);
      final element = lookupResult.getter;
      if (element is ClassElementImpl) {
        if (element.isMacro) {
          return await whenClass(
            macroClass: element,
            constructorName: constructorName,
          );
        }
      } else if (element is PropertyAccessorElementImpl &&
          element.isGetter &&
          element.isSynthetic) {
        final variable = element.variable;
        final variableType = variable.type;
        if (variable is ConstTopLevelVariableElementImpl &&
            variableType is InterfaceType) {
          final macroClass = variableType.element;
          final initializer = variable.constantInitializer;
          if (macroClass is ClassElementImpl &&
              macroClass.isMacro &&
              initializer is InstanceCreationExpression) {
            return await whenGetter(
              macroClass: macroClass,
              instanceCreation: initializer,
            );
          }
        }
      }
    }
    return null;
  }

  macro.TypeAnnotation _inferOmittedType(
    macro.OmittedTypeAnnotation omittedType,
  ) {
    throw UnimplementedError();
  }

  macro.ResolvedIdentifier _resolveIdentifier(macro.Identifier identifier) {
    throw UnimplementedError();
  }

  static macro.Arguments _buildArguments({
    required int annotationIndex,
    required ArgumentList node,
  }) {
    final positional = <Object?>[];
    final named = <String, Object?>{};
    for (var i = 0; i < node.arguments.length; ++i) {
      final argument = node.arguments[i];
      final evaluation = _ArgumentEvaluation(
        annotationIndex: annotationIndex,
        argumentIndex: i,
      );
      if (argument is NamedExpression) {
        final value = evaluation.evaluate(argument.expression);
        named[argument.name.label.name] = value;
      } else {
        final value = evaluation.evaluate(argument);
        positional.add(value);
      }
    }
    return macro.Arguments(positional, named);
  }

  /// Run the [body], report exceptions as [MacroApplicationError]s to [onError].
  static Future<T?> _runWithCatchingExceptions<T>(
    Future<T> Function() body, {
    required int annotationIndex,
    required void Function(MacroApplicationError) onError,
  }) async {
    try {
      return await body();
    } on MacroApplicationError catch (e) {
      onError(e);
    } on macro.RemoteException catch (e) {
      onError(
        UnknownMacroApplicationError(
          annotationIndex: annotationIndex,
          message: e.error,
          stackTrace: e.stackTrace ?? '<null>',
        ),
      );
    } catch (e, stackTrace) {
      onError(
        UnknownMacroApplicationError(
          annotationIndex: annotationIndex,
          message: e.toString(),
          stackTrace: stackTrace.toString(),
        ),
      );
    }
    return null;
  }
}

/// Helper class for evaluating arguments for a single constructor based
/// macro application.
class _ArgumentEvaluation {
  final int annotationIndex;
  final int argumentIndex;

  _ArgumentEvaluation({
    required this.annotationIndex,
    required this.argumentIndex,
  });

  Object? evaluate(Expression node) {
    if (node is AdjacentStrings) {
      return node.strings.map(evaluate).join('');
    } else if (node is BooleanLiteral) {
      return node.value;
    } else if (node is DoubleLiteral) {
      return node.value;
    } else if (node is IntegerLiteral) {
      return node.value;
    } else if (node is ListLiteral) {
      return node.elements.cast<Expression>().map(evaluate).toList();
    } else if (node is NullLiteral) {
      return null;
    } else if (node is PrefixExpression &&
        node.operator.type == TokenType.MINUS) {
      final operandValue = evaluate(node.operand);
      if (operandValue is double) {
        return -operandValue;
      } else if (operandValue is int) {
        return -operandValue;
      }
    } else if (node is SetOrMapLiteral) {
      return _setOrMapLiteral(node);
    } else if (node is SimpleStringLiteral) {
      return node.value;
    }
    _throwError(node, 'Not supported: ${node.runtimeType}');
  }

  Object _setOrMapLiteral(SetOrMapLiteral node) {
    if (node.elements.every((e) => e is Expression)) {
      final result = <Object?>{};
      for (final element in node.elements) {
        if (element is! Expression) {
          _throwError(element, 'Expression expected');
        }
        final value = evaluate(element);
        result.add(value);
      }
      return result;
    }

    final result = <Object?, Object?>{};
    for (final element in node.elements) {
      if (element is! MapLiteralEntry) {
        _throwError(element, 'MapLiteralEntry expected');
      }
      final key = evaluate(element.key);
      final value = evaluate(element.value);
      result[key] = value;
    }
    return result;
  }

  Never _throwError(AstNode node, String message) {
    throw ArgumentMacroApplicationError(
      annotationIndex: annotationIndex,
      argumentIndex: argumentIndex,
      message: message,
    );
  }
}

class _IdentifierResolver extends macro.IdentifierResolver {
  final LinkedElementFactory elementFactory;
  final DeclarationBuilder declarationBuilder;

  _IdentifierResolver(
    this.elementFactory,
    this.declarationBuilder,
  );

  @override
  Future<macro.Identifier> resolveIdentifier(Uri library, String name) async {
    final libraryElement = elementFactory.libraryOfUri2(library);
    final element = libraryElement.scope.lookup(name).getter!;
    return declarationBuilder.fromElement.identifier(element);
  }
}

class _MacroApplication {
  late final _MacroTarget target;
  final int annotationIndex;
  final macro.MacroInstanceIdentifier instanceIdentifier;

  _MacroApplication({
    required this.annotationIndex,
    required this.instanceIdentifier,
  });

  Future<macro.MacroExecutionResult> executeDeclarationsPhase() async {
    final applier = target.applier;
    final executor = applier.macroExecutor;
    return await executor.executeDeclarationsPhase(
      instanceIdentifier,
      target.declaration,
      applier._identifierResolver,
      applier._typeDeclarationResolver,
      applier._typeResolver,
      applier._typeIntrospector,
    );
  }

  Future<macro.MacroExecutionResult> executeTypesPhase() async {
    final applier = target.applier;
    final executor = applier.macroExecutor;
    return await executor.executeTypesPhase(
      instanceIdentifier,
      target.declaration,
      applier._identifierResolver,
    );
  }

  bool shouldExecute(macro.Phase phase) {
    return instanceIdentifier.shouldExecute(target.declarationKind, phase);
  }
}

class _MacroTarget {
  final LibraryMacroApplier applier;
  final MacroTargetElement element;
  final macro.DeclarationKind declarationKind;
  final macro.DeclarationImpl declaration;
  final List<_MacroApplication> applications;

  _MacroTarget({
    required this.applier,
    required this.element,
    required this.declarationKind,
    required this.declaration,
    required this.applications,
  }) {
    for (final application in applications) {
      application.target = this;
    }
  }
}

class _MacroTargetElementCollector extends GeneralizingElementVisitor<void> {
  final List<MacroTargetElement> targets = [];

  @override
  void visitElement(covariant ElementImpl element) {
    if (element is MacroTargetElement) {
      targets.add(element as MacroTargetElement);
    }
    if (element is MacroTargetElementContainer) {
      element.visitChildren(this);
    }
  }
}

class _StaticTypeImpl extends macro.StaticType {
  final TypeSystemImpl typeSystem;
  final DartType type;

  _StaticTypeImpl(this.typeSystem, this.type);

  @override
  Future<bool> isExactly(_StaticTypeImpl other) {
    // TODO: implement isExactly
    throw UnimplementedError();
  }

  @override
  Future<bool> isSubtypeOf(_StaticTypeImpl other) {
    // TODO(scheglov) write tests
    return Future.value(
      typeSystem.isSubtypeOf(type, other.type),
    );
  }
}

class _TypeDeclarationResolver implements macro.TypeDeclarationResolver {
  final DeclarationBuilder declarationBuilder;

  _TypeDeclarationResolver(this.declarationBuilder);

  @override
  Future<macro.TypeDeclaration> declarationOf(
    covariant IdentifierImpl identifier,
  ) async {
    final element = identifier.element;
    if (element is ClassElementImpl) {
      return declarationBuilder.fromElement.classElement(element);
    } else {
      throw ArgumentError('element: $element');
    }
  }
}

class _TypeIntrospector implements macro.TypeIntrospector {
  final DeclarationBuilder declarationBuilder;

  _TypeIntrospector(this.declarationBuilder);

  @override
  Future<List<macro.ConstructorDeclaration>> constructorsOf(
      covariant macro.IntrospectableType type) {
    // TODO: implement constructorsOf
    throw UnimplementedError();
  }

  @override
  Future<List<macro.FieldDeclaration>> fieldsOf(
    covariant macro.IntrospectableType type,
  ) async {
    if (type is! IntrospectableClassDeclarationImpl) {
      throw UnsupportedError('Only introspection on classes is supported');
    }
    return type.element.fields
        .where((e) => !e.isSynthetic)
        .map(declarationBuilder.fromElement.fieldElement)
        .toList();
  }

  @override
  Future<List<macro.MethodDeclaration>> methodsOf(
      covariant macro.IntrospectableType clazz) {
    // TODO: implement methodsOf
    throw UnimplementedError();
  }
}

class _TypeResolver implements macro.TypeResolver {
  final TypeSystemImpl typeSystem;

  _TypeResolver({
    required this.typeSystem,
  });

  @override
  Future<macro.StaticType> resolve(macro.TypeAnnotationCode type) async {
    var dartType = _resolve(type);
    return _StaticTypeImpl(typeSystem, dartType);
  }

  DartType _resolve(macro.TypeAnnotationCode type) {
    // TODO(scheglov) write tests
    if (type is macro.NamedTypeAnnotationCode) {
      final identifier = type.name as IdentifierImpl;
      final element = identifier.element;
      if (element is ClassElementImpl) {
        return element.instantiate(
          typeArguments: type.typeArguments.map(_resolve).toList(),
          nullabilitySuffix: type.isNullable
              ? NullabilitySuffix.question
              : NullabilitySuffix.none,
        );
      } else {
        // TODO(scheglov) Implement other elements.
        throw UnimplementedError('(${element.runtimeType}) $element');
      }
    } else {
      // TODO(scheglov) Implement other types.
      throw UnimplementedError('(${type.runtimeType}) $type');
    }
  }
}

extension on macro.MacroExecutionResult {
  bool get isNotEmpty =>
      libraryAugmentations.isNotEmpty || classAugmentations.isNotEmpty;
}
