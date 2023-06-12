// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/correct_override.dart';
import 'package:analyzer/src/error/getter_setter_types_verifier.dart';
import 'package:analyzer/src/task/inference_error.dart';

class InheritanceOverrideVerifier {
  static const _missingOverridesKey = 'missingOverrides';

  final TypeSystemImpl _typeSystem;
  final TypeProvider _typeProvider;
  final InheritanceManager3 _inheritance;
  final ErrorReporter _reporter;

  InheritanceOverrideVerifier(
      this._typeSystem, this._inheritance, this._reporter)
      : _typeProvider = _typeSystem.typeProvider;

  void verifyUnit(CompilationUnit unit) {
    var library = unit.declaredElement!.library as LibraryElementImpl;
    for (var declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        _ClassVerifier(
          typeSystem: _typeSystem,
          typeProvider: _typeProvider,
          inheritance: _inheritance,
          reporter: _reporter,
          featureSet: unit.featureSet,
          library: library,
          classNameNode: declaration.name,
          implementsClause: declaration.implementsClause,
          members: declaration.members,
          superclass: declaration.extendsClause?.superclass2,
          withClause: declaration.withClause,
        ).verify();
      } else if (declaration is ClassTypeAlias) {
        _ClassVerifier(
          typeSystem: _typeSystem,
          typeProvider: _typeProvider,
          inheritance: _inheritance,
          reporter: _reporter,
          featureSet: unit.featureSet,
          library: library,
          classNameNode: declaration.name,
          implementsClause: declaration.implementsClause,
          superclass: declaration.superclass2,
          withClause: declaration.withClause,
        ).verify();
      } else if (declaration is MixinDeclaration) {
        _ClassVerifier(
          typeSystem: _typeSystem,
          typeProvider: _typeProvider,
          inheritance: _inheritance,
          reporter: _reporter,
          featureSet: unit.featureSet,
          library: library,
          classNameNode: declaration.name,
          implementsClause: declaration.implementsClause,
          members: declaration.members,
          onClause: declaration.onClause,
        ).verify();
      }
    }
  }

  /// Returns [ExecutableElement] members that are in the interface of the
  /// given class, but don't have concrete implementations.
  static List<ExecutableElement> missingOverrides(ClassDeclaration node) {
    return node.name.getProperty(_missingOverridesKey) ?? const [];
  }
}

class _ClassVerifier {
  final TypeSystemImpl typeSystem;
  final TypeProvider typeProvider;
  final InheritanceManager3 inheritance;
  final ErrorReporter reporter;

  final FeatureSet featureSet;
  final LibraryElementImpl library;
  final Uri libraryUri;
  final ClassElementImpl classElement;

  final SimpleIdentifier classNameNode;
  final List<ClassMember> members;
  final ImplementsClause? implementsClause;
  final OnClause? onClause;
  final NamedType? superclass;
  final WithClause? withClause;

  final List<InterfaceType> directSuperInterfaces = [];

  _ClassVerifier({
    required this.typeSystem,
    required this.typeProvider,
    required this.inheritance,
    required this.reporter,
    required this.featureSet,
    required this.library,
    required this.classNameNode,
    this.implementsClause,
    this.members = const [],
    this.onClause,
    this.superclass,
    this.withClause,
  })  : libraryUri = library.source.uri,
        classElement = classNameNode.staticElement as ClassElementImpl;

  bool get _isNonNullableByDefault => typeSystem.isNonNullableByDefault;

  void verify() {
    if (_checkDirectSuperTypes()) {
      return;
    }

    if (_checkForRecursiveInterfaceInheritance(classElement)) {
      return;
    }

    // Compute the interface of the class.
    var interface = inheritance.getInterface(classElement);

    // Report conflicts between direct superinterfaces of the class.
    for (var conflict in interface.conflicts) {
      _reportInconsistentInheritance(classNameNode, conflict);
    }

    if (classElement.supertype != null) {
      directSuperInterfaces.add(classElement.supertype!);
    }
    directSuperInterfaces.addAll(classElement.superclassConstraints);

    // Each mixin in `class C extends S with M0, M1, M2 {}` is equivalent to:
    //   class S&M0 extends S { ...members of M0... }
    //   class S&M1 extends S&M0 { ...members of M1... }
    //   class S&M2 extends S&M1 { ...members of M2... }
    //   class C extends S&M2 { ...members of C... }
    // So, we need to check members of each mixin against superinterfaces
    // of `S`, and superinterfaces of all previous mixins.
    var mixinNodes = withClause?.mixinTypes2;
    var mixinTypes = classElement.mixins;
    for (var i = 0; i < mixinTypes.length; i++) {
      var mixinType = mixinTypes[i];
      _checkDeclaredMembers(mixinNodes![i], mixinType, mixinIndex: i);
      directSuperInterfaces.add(mixinType);
    }

    directSuperInterfaces.addAll(classElement.interfaces);

    // Check the members if the class itself, against all the previously
    // collected superinterfaces of the supertype, mixins, and interfaces.
    for (var member in members) {
      if (member is FieldDeclaration) {
        var fieldList = member.fields;
        for (var field in fieldList.variables) {
          var fieldElement = field.declaredElement as FieldElement;
          _checkDeclaredMember(field.name, libraryUri, fieldElement.getter);
          _checkDeclaredMember(field.name, libraryUri, fieldElement.setter);
        }
      } else if (member is MethodDeclaration) {
        var hasError = _reportNoCombinedSuperSignature(member);
        if (hasError) {
          continue;
        }

        _checkDeclaredMember(member.name, libraryUri, member.declaredElement,
            methodParameterNodes: member.parameters?.parameters);
      }
    }

    GetterSetterTypesVerifier(
      typeSystem: typeSystem,
      errorReporter: reporter,
    ).checkInterface(classElement, interface);

    if (!classElement.isAbstract) {
      List<ExecutableElement>? inheritedAbstract;

      for (var name in interface.map.keys) {
        if (!name.isAccessibleFor(libraryUri)) {
          continue;
        }

        var interfaceElement = interface.map[name]!;
        var concreteElement = interface.implemented[name];

        // No concrete implementation of the name.
        if (concreteElement == null) {
          if (!_reportConcreteClassWithAbstractMember(name.name)) {
            inheritedAbstract ??= [];
            inheritedAbstract.add(interfaceElement);
          }
          continue;
        }

        // The case when members have different kinds is reported in verifier.
        if (concreteElement.kind != interfaceElement.kind) {
          continue;
        }

        // If a class declaration is not abstract, and the interface has a
        // member declaration named `m`, then:
        // 1. if the class contains a non-overridden member whose signature is
        //    not a valid override of the interface member signature for `m`,
        //    then it's a compile-time error.
        // 2. if the class contains no member named `m`, and the class member
        //    for `noSuchMethod` is the one declared in `Object`, then it's a
        //    compile-time error.
        // TODO(brianwilkerson) This code catches some cases not caught in
        //  _checkDeclaredMember, but also duplicates the diagnostic reported
        //  there in some other cases.
        // TODO(brianwilkerson) In the case of methods inherited via mixins, the
        //  diagnostic should be reported on the name of the mixin defining the
        //  method. In other cases, it should be reported on the name of the
        //  overriding method. The classNameNode is always wrong.
        concreteElement = library.toLegacyElementIfOptOut(concreteElement);
        CorrectOverrideHelper(
          library: library,
          thisMember: concreteElement,
        ).verify(
          superMember: interfaceElement,
          errorReporter: reporter,
          errorNode: classNameNode,
          errorCode: CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE,
        );
      }

      _reportInheritedAbstractMembers(inheritedAbstract);
    }
  }

  /// Check that the given [member] is a valid override of the corresponding
  /// instance members in each of [directSuperInterfaces].  The [libraryUri] is
  /// the URI of the library containing the [member].
  void _checkDeclaredMember(
    AstNode node,
    Uri libraryUri,
    ExecutableElement? member, {
    List<FormalParameter>? methodParameterNodes,
    int mixinIndex = -1,
  }) {
    if (member == null) return;
    if (member.isStatic) return;

    var name = Name(libraryUri, member.name);
    var correctOverrideHelper = CorrectOverrideHelper(
      library: library,
      thisMember: member,
    );

    for (var superType in directSuperInterfaces) {
      var superMember = inheritance.getMember(
        superType,
        name,
        forMixinIndex: mixinIndex,
      );
      if (superMember == null) {
        continue;
      }

      // The case when members have different kinds is reported in verifier.
      // TODO(scheglov) Do it here?
      if (member.kind != superMember.kind) {
        continue;
      }

      correctOverrideHelper.verify(
        superMember: superMember,
        errorReporter: reporter,
        errorNode: node,
      );

      if (!_isNonNullableByDefault &&
          superMember is MethodElement &&
          member is MethodElement &&
          methodParameterNodes != null) {
        _checkForOptionalParametersDifferentDefaultValues(
          superMember,
          member,
          methodParameterNodes,
        );
      }
    }

    if (mixinIndex == -1) {
      CovariantParametersVerifier(thisMember: member).verify(
        errorReporter: reporter,
        errorNode: node,
      );
    }
  }

  /// Check that instance members of [type] are valid overrides of the
  /// corresponding instance members in each of [directSuperInterfaces].
  void _checkDeclaredMembers(AstNode node, InterfaceType type,
      {required int mixinIndex}) {
    var libraryUri = type.element.library.source.uri;
    for (var method in type.methods) {
      _checkDeclaredMember(node, libraryUri, method, mixinIndex: mixinIndex);
    }
    for (var accessor in type.accessors) {
      _checkDeclaredMember(node, libraryUri, accessor, mixinIndex: mixinIndex);
    }
  }

  /// Verify that the given [namedType] does not extend, implement, or mixes-in
  /// types such as `num` or `String`.
  bool _checkDirectSuperType(NamedType namedType, ErrorCode errorCode) {
    if (namedType.isSynthetic) {
      return false;
    }

    // The SDK implementation may implement disallowed types. For example,
    // JSNumber in dart2js and _Smi in Dart VM both implement int.
    if (library.source.uri.isScheme('dart')) {
      return false;
    }

    DartType type = namedType.typeOrThrow;
    if (type is InterfaceType &&
        typeProvider.isNonSubtypableClass(type.element)) {
      reporter.reportErrorForNode(errorCode, namedType, [type]);
      return true;
    }

    return false;
  }

  /// Verify that direct supertypes are valid, and return `false`.  If there
  /// are direct supertypes that are not valid, report corresponding errors,
  /// and return `true`.
  bool _checkDirectSuperTypes() {
    var hasError = false;
    if (implementsClause != null) {
      for (var namedType in implementsClause!.interfaces2) {
        if (_checkDirectSuperType(
          namedType,
          CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS,
        )) {
          hasError = true;
        }
      }
    }
    if (onClause != null) {
      for (var namedType in onClause!.superclassConstraints2) {
        if (_checkDirectSuperType(
          namedType,
          CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS,
        )) {
          hasError = true;
        }
      }
    }
    if (superclass != null) {
      if (_checkDirectSuperType(
        superclass!,
        CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
      )) {
        hasError = true;
      }
    }
    if (withClause != null) {
      for (var namedType in withClause!.mixinTypes2) {
        if (_checkDirectSuperType(
          namedType,
          CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS,
        )) {
          hasError = true;
        }
      }
    }
    return hasError;
  }

  void _checkForOptionalParametersDifferentDefaultValues(
    MethodElement baseExecutable,
    MethodElement derivedExecutable,
    List<FormalParameter> derivedParameterNodes,
  ) {
    var derivedIsAbstract = derivedExecutable.isAbstract;
    var derivedOptionalNodes = <FormalParameter>[];
    var derivedOptionalElements = <ParameterElementImpl>[];
    var derivedParameterElements = derivedExecutable.parameters;
    for (var i = 0; i < derivedParameterElements.length; i++) {
      var parameterElement =
          derivedParameterElements[i] as ParameterElementImpl;
      if (parameterElement.isOptional) {
        derivedOptionalNodes.add(derivedParameterNodes[i]);
        derivedOptionalElements.add(parameterElement);
      }
    }

    var baseOptionalElements = <ParameterElementImpl>[];
    var baseParameterElements = baseExecutable.parameters;
    for (var i = 0; i < baseParameterElements.length; ++i) {
      var baseParameter = baseParameterElements[i];
      if (baseParameter.isOptional) {
        baseOptionalElements
            .add(baseParameter.declaration as ParameterElementImpl);
      }
    }

    // Stop if no optional parameters.
    if (baseOptionalElements.isEmpty || derivedOptionalElements.isEmpty) {
      return;
    }

    if (derivedOptionalElements[0].isNamed) {
      for (int i = 0; i < derivedOptionalElements.length; i++) {
        var derivedElement = derivedOptionalElements[i];
        if (_isNonNullableByDefault &&
            derivedIsAbstract &&
            !derivedElement.hasDefaultValue) {
          continue;
        }
        var name = derivedElement.name;
        for (var j = 0; j < baseOptionalElements.length; j++) {
          var baseParameter = baseOptionalElements[j];
          if (name == baseParameter.name && baseParameter.hasDefaultValue) {
            var baseValue = baseParameter.computeConstantValue();
            var derivedResult = derivedElement.evaluationResult!;
            if (!_constantValuesEqual(derivedResult.value, baseValue)) {
              reporter.reportErrorForNode(
                StaticWarningCode
                    .INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED,
                derivedOptionalNodes[i],
                [
                  baseExecutable.enclosingElement.displayName,
                  baseExecutable.displayName,
                  name
                ],
              );
            }
          }
        }
      }
    } else {
      for (var i = 0;
          i < derivedOptionalElements.length && i < baseOptionalElements.length;
          i++) {
        var derivedElement = derivedOptionalElements[i];
        if (_isNonNullableByDefault &&
            derivedIsAbstract &&
            !derivedElement.hasDefaultValue) {
          continue;
        }
        var baseElement = baseOptionalElements[i];
        if (baseElement.hasDefaultValue) {
          var baseValue = baseElement.computeConstantValue();
          var derivedResult = derivedElement.evaluationResult!;
          if (!_constantValuesEqual(derivedResult.value, baseValue)) {
            reporter.reportErrorForNode(
              StaticWarningCode
                  .INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL,
              derivedOptionalNodes[i],
              [
                baseExecutable.enclosingElement.displayName,
                baseExecutable.displayName
              ],
            );
          }
        }
      }
    }
  }

  /// Check that [classElement] is not a superinterface to itself.
  /// The [path] is a list containing the potentially cyclic implements path.
  ///
  /// See [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE],
  /// [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_EXTENDS],
  /// [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS],
  /// [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_ON],
  /// [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_WITH].
  bool _checkForRecursiveInterfaceInheritance(ClassElement element,
      [List<ClassElement>? path]) {
    path ??= <ClassElement>[];

    // Detect error condition.
    int size = path.length;
    // If this is not the base case (size > 0), and the enclosing class is the
    // given class element then report an error.
    if (size > 0 && classElement == element) {
      String className = classElement.displayName;
      if (size > 1) {
        // Construct a string showing the cyclic implements path:
        // "A, B, C, D, A"
        String separator = ", ";
        StringBuffer buffer = StringBuffer();
        for (int i = 0; i < size; i++) {
          buffer.write(path[i].displayName);
          buffer.write(separator);
        }
        buffer.write(element.displayName);
        reporter.reportErrorForElement(
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
            classElement,
            [className, buffer.toString()]);
        return true;
      } else {
        // RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS or
        // RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS or
        // RECURSIVE_INTERFACE_INHERITANCE_ON or
        // RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_WITH
        reporter.reportErrorForElement(
            _getRecursiveErrorCode(element), classElement, [className]);
        return true;
      }
    }

    if (path.indexOf(element) > 0) {
      return false;
    }
    path.add(element);

    // n-case
    var supertype = element.supertype;
    if (supertype != null &&
        _checkForRecursiveInterfaceInheritance(supertype.element, path)) {
      return true;
    }

    for (InterfaceType type in element.mixins) {
      if (_checkForRecursiveInterfaceInheritance(type.element, path)) {
        return true;
      }
    }

    for (InterfaceType type in element.superclassConstraints) {
      if (_checkForRecursiveInterfaceInheritance(type.element, path)) {
        return true;
      }
    }

    for (InterfaceType type in element.interfaces) {
      if (_checkForRecursiveInterfaceInheritance(type.element, path)) {
        return true;
      }
    }

    path.removeAt(path.length - 1);
    return false;
  }

  /// Return the error code that should be used when the given class [element]
  /// references itself directly.
  ErrorCode _getRecursiveErrorCode(ClassElement element) {
    if (element.supertype?.element == classElement) {
      return CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_EXTENDS;
    }

    for (InterfaceType type in element.superclassConstraints) {
      if (type.element == classElement) {
        return CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_ON;
      }
    }

    for (InterfaceType type in element.mixins) {
      if (type.element == classElement) {
        return CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_WITH;
      }
    }

    return CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS;
  }

  /// We identified that the current non-abstract class does not have the
  /// concrete implementation of a method with the given [name].  If this is
  /// because the class itself defines an abstract method with this [name],
  /// report the more specific error, and return `true`.
  bool _reportConcreteClassWithAbstractMember(String name) {
    bool checkMemberNameCombo(ClassMember member, String memberName) {
      if (memberName == name) {
        reporter.reportErrorForNode(
            CompileTimeErrorCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER,
            member,
            [name, classElement.name]);
        return true;
      } else {
        return false;
      }
    }

    for (var member in members) {
      if (member is MethodDeclaration) {
        var name2 = member.name.name;
        if (member.isSetter) {
          name2 += '=';
        }
        if (checkMemberNameCombo(member, name2)) return true;
      } else if (member is FieldDeclaration) {
        for (var variableDeclaration in member.fields.variables) {
          var name2 = variableDeclaration.name.name;
          if (checkMemberNameCombo(member, name2)) return true;
          if (!variableDeclaration.isFinal) {
            name2 += '=';
            if (checkMemberNameCombo(member, name2)) return true;
          }
        }
      }
    }
    return false;
  }

  void _reportInconsistentInheritance(AstNode node, Conflict conflict) {
    var name = conflict.name;

    if (conflict is GetterMethodConflict) {
      // Members that participate in inheritance are always enclosed in named
      // elements so it is safe to assume that
      // `conflict.getter.enclosingElement.name` and
      // `conflict.method.enclosingElement.name` are both non-`null`.
      reporter.reportErrorForNode(
        CompileTimeErrorCode.INCONSISTENT_INHERITANCE_GETTER_AND_METHOD,
        node,
        [
          name.name,
          conflict.getter.enclosingElement.name!,
          conflict.method.enclosingElement.name!
        ],
      );
    } else if (conflict is CandidatesConflict) {
      var candidatesStr = conflict.candidates.map((candidate) {
        var className = candidate.enclosingElement.name;
        var typeStr = candidate.type.getDisplayString(
          withNullability: _isNonNullableByDefault,
        );
        return '$className.${name.name} ($typeStr)';
      }).join(', ');

      reporter.reportErrorForNode(
        CompileTimeErrorCode.INCONSISTENT_INHERITANCE,
        node,
        [name.name, candidatesStr],
      );
    } else {
      throw StateError('${conflict.runtimeType}');
    }
  }

  void _reportInheritedAbstractMembers(List<ExecutableElement>? elements) {
    if (elements == null) {
      return;
    }

    classNameNode.setProperty(
      InheritanceOverrideVerifier._missingOverridesKey,
      elements,
    );

    var descriptions = <String>[];
    for (ExecutableElement element in elements) {
      String prefix = '';
      if (element is PropertyAccessorElement) {
        if (element.isGetter) {
          prefix = 'getter ';
        } else {
          prefix = 'setter ';
        }
      }

      var elementName = element.displayName;
      var enclosingElement = element.enclosingElement;
      var enclosingName = enclosingElement.displayName;
      var description = "$prefix$enclosingName.$elementName";

      descriptions.add(description);
    }
    descriptions.sort();

    if (descriptions.length == 1) {
      reporter.reportErrorForNode(
        CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
        classNameNode,
        [descriptions[0]],
      );
    } else if (descriptions.length == 2) {
      reporter.reportErrorForNode(
        CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO,
        classNameNode,
        [descriptions[0], descriptions[1]],
      );
    } else if (descriptions.length == 3) {
      reporter.reportErrorForNode(
        CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE,
        classNameNode,
        [descriptions[0], descriptions[1], descriptions[2]],
      );
    } else if (descriptions.length == 4) {
      reporter.reportErrorForNode(
        CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR,
        classNameNode,
        [descriptions[0], descriptions[1], descriptions[2], descriptions[3]],
      );
    } else {
      reporter.reportErrorForNode(
        CompileTimeErrorCode
            .NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS,
        classNameNode,
        [
          descriptions[0],
          descriptions[1],
          descriptions[2],
          descriptions[3],
          descriptions.length - 4
        ],
      );
    }
  }

  bool _reportNoCombinedSuperSignature(MethodDeclaration node) {
    var element = node.declaredElement;
    if (element is MethodElementImpl) {
      var inferenceError = element.typeInferenceError;
      if (inferenceError?.kind ==
          TopLevelInferenceErrorKind.overrideNoCombinedSuperSignature) {
        reporter.reportErrorForNode(
          CompileTimeErrorCode.NO_COMBINED_SUPER_SIGNATURE,
          node.name,
          [
            classElement.name,
            inferenceError!.arguments[0],
          ],
        );
        return true;
      }
    }
    return false;
  }

  static bool _constantValuesEqual(DartObject? x, DartObject? y) {
    // If either constant value couldn't be computed due to an error, the
    // corresponding DartObject will be `null`.  Since an error has already been
    // reported, there's no need to report another.
    if (x == null || y == null) return true;
    return x == y;
  }
}
