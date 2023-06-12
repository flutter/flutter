// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/test_utilities/function_ast_visitor.dart';
import 'package:collection/src/iterable_extensions.dart';

/// Helper for finding elements declared in the resolved [unit].
class FindElement extends _FindElementBase {
  final CompilationUnit unit;

  FindElement(this.unit);

  LibraryElement get libraryElement => unitElement.library;

  @override
  CompilationUnitElement get unitElement => unit.declaredElement!;

  ExportElement export(String targetUri) {
    ExportElement? result;

    for (var export in libraryElement.exports) {
      var exportedUri = export.exportedLibrary?.source.uri.toString();
      if (exportedUri == targetUri) {
        if (result != null) {
          throw StateError('Not unique: $targetUri');
        }
        result = export;
      }
    }

    if (result != null) {
      return result;
    }
    throw StateError('Not found: $targetUri');
  }

  FieldFormalParameterElement fieldFormalParameter(String name) {
    return parameter(name) as FieldFormalParameterElement;
  }

  FunctionElement function(String name) {
    for (var function in unitElement.functions) {
      if (function.name == name) {
        return function;
      }
    }
    throw StateError('Not found: $name');
  }

  ImportElement import(String targetUri, {bool mustBeUnique = true}) {
    ImportElement? importElement;

    for (var import in libraryElement.imports) {
      var importedUri = import.importedLibrary?.source.uri.toString();
      if (importedUri == targetUri) {
        if (importElement == null) {
          importElement = import;
        } else if (mustBeUnique) {
          throw StateError('Not unique: $targetUri');
        }
      }
    }

    if (importElement != null) {
      return importElement;
    }
    throw StateError('Not found: $targetUri');
  }

  ImportFindElement importFind(String targetUri, {bool mustBeUnique = true}) {
    var import = this.import(targetUri, mustBeUnique: mustBeUnique);
    return ImportFindElement(import);
  }

  LabelElement label(String name) {
    LabelElement? result;

    void updateResult(Element element) {
      if (element is LabelElement && element.name == name) {
        if (result != null) {
          throw StateError('Not unique: $name');
        }
        result = element;
      }
    }

    unit.accept(FunctionAstVisitor(
      label: (node) {
        updateResult(node.label.staticElement!);
      },
    ));

    if (result == null) {
      throw StateError('Not found: $name');
    }
    return result!;
  }

  FunctionElement localFunction(String name) {
    FunctionElement? result;

    unit.accept(FunctionAstVisitor(
      functionDeclarationStatement: (node) {
        var element = node.functionDeclaration.declaredElement;
        if (element is FunctionElement && element.name == name) {
          if (result != null) {
            throw StateError('Not unique: $name');
          }
          result = element;
        }
      },
    ));

    if (result == null) {
      throw StateError('Not found: $name');
    }
    return result!;
  }

  LocalVariableElement localVar(String name) {
    LocalVariableElement? result;

    void updateResult(Element element) {
      if (element is LocalVariableElement && element.name == name) {
        if (result != null) {
          throw StateError('Not unique: $name');
        }
        result = element;
      }
    }

    unit.accept(FunctionAstVisitor(
      declaredIdentifier: (node) {
        updateResult(node.declaredElement!);
      },
      simpleIdentifier: (node) {
        if (node.parent is CatchClause) {
          updateResult(node.staticElement!);
        }
      },
      variableDeclaration: (node) {
        updateResult(node.declaredElement!);
      },
    ));

    if (result == null) {
      throw StateError('Not found: $name');
    }
    return result!;
  }

  @override
  ParameterElement parameter(String name) {
    ParameterElement? result;

    void findIn(List<ParameterElement> parameters) {
      for (var parameter in parameters) {
        if (parameter.name == name) {
          if (result != null) {
            throw StateError('Not unique: $name');
          }
          result = parameter;
        }
      }
    }

    void findInExecutables(List<ExecutableElement> executables) {
      for (var executable in executables) {
        findIn(executable.parameters);
      }
    }

    void findInClasses(List<ClassElement> classes) {
      for (var class_ in classes) {
        findInExecutables(class_.accessors);
        findInExecutables(class_.constructors);
        findInExecutables(class_.methods);
      }
    }

    findInExecutables(unitElement.accessors);
    findInExecutables(unitElement.functions);

    findInClasses(unitElement.classes);
    findInClasses(unitElement.enums);
    findInClasses(unitElement.mixins);

    for (var extension_ in unitElement.extensions) {
      findInExecutables(extension_.accessors);
      findInExecutables(extension_.methods);
    }

    for (var alias in unitElement.typeAliases) {
      var aliasedElement = alias.aliasedElement;
      if (aliasedElement is GenericFunctionTypeElement) {
        findIn(aliasedElement.parameters);
      }
    }

    unit.accept(
      FunctionAstVisitor(functionExpression: (node, local) {
        if (local) {
          var functionElement = node.declaredElement!;
          findIn(functionElement.parameters);
        }
      }),
    );

    if (result != null) {
      return result!;
    }
    throw StateError('Not found: $name');
  }

  CompilationUnitElement part(String targetUri) {
    CompilationUnitElement? partElement;

    for (var part in libraryElement.parts) {
      if (part.uri == targetUri) {
        if (partElement != null) {
          throw StateError('Not unique: $targetUri');
        }
        partElement = part;
      }
    }

    if (partElement != null) {
      return partElement;
    }
    throw StateError('Not found: $targetUri');
  }

  PartFindElement partFind(String targetUri) {
    var part = this.part(targetUri);
    return PartFindElement(part);
  }

  PrefixElement prefix(String name) {
    for (var import_ in libraryElement.imports) {
      var prefix = import_.prefix;
      if (prefix?.name == name) {
        return prefix!;
      }
    }
    throw StateError('Not found: $name');
  }

  TypeParameterElement typeParameter(String name) {
    TypeParameterElement? result;

    void findIn(List<TypeParameterElement> typeParameters) {
      for (var typeParameter in typeParameters) {
        if (typeParameter.name == name) {
          if (result != null) {
            throw StateError('Not unique: $name');
          }
          result = typeParameter;
        }
      }
    }

    void findInClass(ClassElement class_) {
      findIn(class_.typeParameters);
      for (var method in class_.methods) {
        findIn(method.typeParameters);
      }
    }

    for (var type in unitElement.functions) {
      findIn(type.typeParameters);
    }

    for (var alias in unitElement.typeAliases) {
      findIn(alias.typeParameters);

      var aliasedElement = alias.aliasedElement;
      if (aliasedElement is GenericFunctionTypeElement) {
        findIn(aliasedElement.typeParameters);
      }
    }

    for (var class_ in unitElement.classes) {
      findInClass(class_);
    }

    for (var enum_ in unitElement.enums) {
      findInClass(enum_);
    }

    for (var extension_ in unitElement.extensions) {
      findIn(extension_.typeParameters);
    }

    for (var mixin in unitElement.mixins) {
      findInClass(mixin);
    }

    if (result != null) {
      return result!;
    }
    throw StateError('Not found: $name');
  }
}

/// Helper for searching imported elements.
class ImportFindElement extends _FindElementBase {
  final ImportElement import;

  ImportFindElement(this.import);

  LibraryElement get importedLibrary => import.importedLibrary!;

  PrefixElement? get prefix => import.prefix;

  @override
  CompilationUnitElement get unitElement {
    return importedLibrary.definingCompilationUnit;
  }
}

class PartFindElement extends _FindElementBase {
  @override
  final CompilationUnitElement unitElement;

  PartFindElement(this.unitElement);
}

abstract class _FindElementBase {
  CompilationUnitElement get unitElement;

  ClassElement class_(String name) {
    for (var class_ in unitElement.classes) {
      if (class_.name == name) {
        return class_;
      }
    }
    throw StateError('Not found: $name');
  }

  ClassElement classOrMixin(String name) {
    for (var class_ in unitElement.classes) {
      if (class_.name == name) {
        return class_;
      }
    }
    for (var mixin in unitElement.mixins) {
      if (mixin.name == name) {
        return mixin;
      }
    }
    throw StateError('Not found: $name');
  }

  ConstructorElement constructor(String name, {String? of}) {
    assert(name != '');

    ConstructorElement? result;

    void findIn(List<ConstructorElement> constructors) {
      for (var constructor in constructors) {
        if (constructor.name == name) {
          if (result != null) {
            throw StateError('Not unique: $name');
          }
          result = constructor;
        }
      }
    }

    for (var class_ in unitElement.classes) {
      if (of == null || class_.name == of) {
        findIn(class_.constructors);
      }
    }

    for (var enum_ in unitElement.enums) {
      if (of == null || enum_.name == of) {
        findIn(enum_.constructors);
      }
    }

    if (result != null) {
      return result!;
    }
    throw StateError('Not found: $name');
  }

  ClassElement enum_(String name) {
    for (var enum_ in unitElement.enums) {
      if (enum_.name == name) {
        return enum_;
      }
    }
    throw StateError('Not found: $name');
  }

  ExtensionElement extension_(String name) {
    for (var extension_ in unitElement.extensions) {
      if (extension_.name == name) {
        return extension_;
      }
    }
    throw StateError('Not found: $name');
  }

  FieldElement field(String name, {String? of}) {
    return _findInClassesLike(
      className: of,
      fromClass: (element) => element.getField(name),
      fromExtension: (element) => element.getField(name),
    );
  }

  PropertyAccessorElement getter(String name, {String? of}) {
    return _findInClassesLike(
      className: of,
      fromClass: (element) => element.getGetter(name),
      fromExtension: (element) => element.getGetter(name),
    );
  }

  MethodElement method(String name, {String? of}) {
    return _findInClassesLike(
      className: of,
      fromClass: (element) => element.getMethod(name),
      fromExtension: (element) => element.getMethod(name),
    );
  }

  ClassElement mixin(String name) {
    for (var mixin in unitElement.mixins) {
      if (mixin.name == name) {
        return mixin;
      }
    }
    throw StateError('Not found: $name');
  }

  ParameterElement parameter(String name) {
    ParameterElement? result;

    for (var class_ in unitElement.classes) {
      for (var constructor in class_.constructors) {
        for (var parameter in constructor.parameters) {
          if (parameter.name == name) {
            if (result != null) {
              throw StateError('Not unique: $name');
            }
            result = parameter;
          }
        }
      }
    }

    if (result != null) {
      return result;
    }
    throw StateError('Not found: $name');
  }

  PropertyAccessorElement setter(String name, {String? of}) {
    return _findInClassesLike(
      className: of,
      fromClass: (element) => element.getSetter(name),
      fromExtension: (element) => element.getSetter(name),
    );
  }

  FunctionElement topFunction(String name) {
    for (var function in unitElement.functions) {
      if (function.name == name) {
        return function;
      }
    }
    throw StateError('Not found: $name');
  }

  PropertyAccessorElement topGet(String name) {
    return topVar(name).getter!;
  }

  PropertyAccessorElement topSet(String name) {
    return topVar(name).setter!;
  }

  TopLevelVariableElement topVar(String name) {
    for (var variable in unitElement.topLevelVariables) {
      if (variable.name == name) {
        return variable;
      }
    }
    throw StateError('Not found: $name');
  }

  TypeAliasElement typeAlias(String name) {
    for (var element in unitElement.typeAliases) {
      if (element.name == name) {
        return element;
      }
    }
    throw StateError('Not found: $name');
  }

  ConstructorElement unnamedConstructor(String name) {
    return _findInClassesLike(
      className: name,
      fromClass: (e) => e.unnamedConstructor,
      fromExtension: (_) => null,
    );
  }

  T _findInClassesLike<T extends Element>({
    required String? className,
    required T? Function(ClassElement element) fromClass,
    required T? Function(ExtensionElement element) fromExtension,
  }) {
    bool filter(Element element) {
      return className == null || element.name == className;
    }

    var classes = [
      ...unitElement.classes,
      ...unitElement.enums,
      ...unitElement.mixins,
    ];

    var results = [
      ...classes.where(filter).map(fromClass),
      ...unitElement.extensions.where(filter).map(fromExtension),
    ].whereNotNull().toList();

    var result = results.singleOrNull;
    if (result != null) {
      return result;
    }

    if (results.isEmpty) {
      throw StateError('Not found');
    } else {
      throw StateError('Not unique');
    }
  }
}

extension ExecutableElementExtensions on ExecutableElement {
  ParameterElement parameter(String name) {
    for (var parameter in parameters) {
      if (parameter.name == name) {
        return parameter;
      }
    }
    throw StateError('Not found: $name');
  }

  SuperFormalParameterElement superFormalParameter(String name) {
    for (var parameter in parameters) {
      if (parameter is SuperFormalParameterElement && parameter.name == name) {
        return parameter;
      }
    }
    throw StateError('Not found: $name');
  }
}
