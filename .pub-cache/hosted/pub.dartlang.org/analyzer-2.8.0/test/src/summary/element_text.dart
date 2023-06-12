// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/inference_error.dart';
import 'package:test/test.dart';

import 'resolved_ast_printer.dart';

/// Set this path to automatically replace expectations in invocations of
/// [checkElementText] with the new actual texts.
const String? _testPath = null;

/// The list of replacements that update expectations.
final List<_Replacement> _replacements = [];

/// The cached content of the file with the [_testPath].
String? _testCode;

/// The cache line information for the [_testPath] file.
LineInfo? _testCodeLines;

void applyCheckElementTextReplacements() {
  if (_testPath != null && _replacements.isNotEmpty) {
    _replacements.sort((a, b) => b.offset - a.offset);
    String newCode = _testCode!;
    _replacements.forEach((r) {
      newCode =
          newCode.substring(0, r.offset) + r.text + newCode.substring(r.end);
    });
    File(_testPath!).writeAsStringSync(newCode);
  }
}

/// Write the given [library] elements into the canonical text presentation
/// taking into account the specified 'withX' options. Then compare the
/// actual text with the given [expected] one.
void checkElementText(
  LibraryElement library,
  String expected, {
  bool withCodeRanges = false,
  bool withDisplayName = false,
  bool withExportScope = false,
  bool withNonSynthetic = false,
}) {
  var writer = _ElementWriter(
    selfUriStr: '${library.source.uri}',
    withCodeRanges: withCodeRanges,
    withDisplayName: withDisplayName,
    withExportScope: withExportScope,
    withNonSynthetic: withNonSynthetic,
  );
  writer.writeLibraryElement(library);

  String actualText = writer.buffer.toString();
  actualText =
      actualText.split('\n').map((line) => line.trimRight()).join('\n');

  if (_testPath != null && actualText != expected) {
    if (_testCode == null) {
      _testCode = File(_testPath!).readAsStringSync();
      _testCodeLines = LineInfo.fromContent(_testCode!);
    }

    try {
      throw 42;
    } catch (e, trace) {
      String traceString = trace.toString();

      // Assuming traceString contains "$_testPath:$invocationLine:$column",
      // figure out the value of invocationLine.

      int testFilePathOffset = traceString.indexOf(_testPath!);
      expect(testFilePathOffset, isNonNegative);

      // Sanity check: there must be ':' after the path.
      expect(traceString[testFilePathOffset + _testPath!.length], ':');

      int lineOffset = testFilePathOffset + _testPath!.length + ':'.length;
      int invocationLine = int.parse(traceString.substring(
          lineOffset, traceString.indexOf(':', lineOffset)));
      int invocationOffset =
          _testCodeLines!.getOffsetOfLine(invocationLine - 1);

      const String rawStringPrefix = "r'''";
      int expectationOffset =
          _testCode!.indexOf(rawStringPrefix, invocationOffset);

      // Sanity check: there must be no other strings or blocks.
      expect(_testCode!.substring(invocationOffset, expectationOffset),
          isNot(anyOf(contains("'"), contains('"'), contains('}'))));

      expectationOffset += rawStringPrefix.length;
      int expectationEnd = _testCode!.indexOf("'''", expectationOffset);

      _replacements.add(
          _Replacement(expectationOffset, expectationEnd, '\n' + actualText));
    }
  }

  // Print the actual text to simplify copy/paste into the expectation.
  // if (actualText != expected) {
  //   print('-------- Actual --------');
  //   print(actualText + '------------------------');
  // }

  expect(actualText, expected);
}

/// Writes the canonical text presentation of elements.
class _ElementWriter {
  final String? selfUriStr;
  final bool withCodeRanges;
  final bool withDisplayName;
  final bool withExportScope;
  final bool withNonSynthetic;
  final StringBuffer buffer = StringBuffer();

  String indent = '';

  _ElementWriter({
    this.selfUriStr,
    required this.withCodeRanges,
    required this.withDisplayName,
    required this.withExportScope,
    required this.withNonSynthetic,
  });

  void writeLibraryElement(LibraryElement e) {
    _writelnWithIndent('library');
    _withIndent(() {
      var name = e.name;
      if (name.isNotEmpty) {
        _writelnWithIndent('name: $name');
      }

      var nameOffset = e.nameOffset;
      if (nameOffset != -1) {
        _writelnWithIndent('nameOffset: $nameOffset');
      }

      _writeDocumentation(e);
      _writeMetadata(e);

      var imports = e.imports.where((import) => !import.isSynthetic).toList();
      _writeElements('imports', imports, _writeImportElement);

      _writeElements('exports', e.exports, _writeExportElement);

      _writelnWithIndent('definingUnit');
      _withIndent(() {
        _writeUnitElement(e.definingCompilationUnit);
      });

      _writeElements('parts', e.parts, (CompilationUnitElement e) {
        _writelnWithIndent(e.uri!);
        _withIndent(() {
          _writeMetadata(e);
          _writeUnitElement(e);
        });
      });

      if (withExportScope) {
        _writelnWithIndent('exportScope');
        _withIndent(() {
          _writeExportScope(e);
        });
      }
    });
  }

  void _assertNonSyntheticElementSelf(Element element) {
    expect(element.isSynthetic, isFalse);
    expect(element.nonSynthetic, same(element));
  }

  /// Assert that the [accessor] of the [property] is correctly linked to
  /// the same enclosing element as the [property].
  void _assertSyntheticAccessorEnclosing(
      PropertyInducingElement property, PropertyAccessorElement accessor) {
    if (accessor.isSynthetic) {
      // Usually we have a non-synthetic property, and a synthetic accessor.
    } else {
      // But it is possible to have a non-synthetic setter.
      // class A {
      //   final int foo;
      //   set foo(int newValue) {}
      // }
      expect(accessor.isSetter, isTrue);
    }

    expect(accessor.variable, same(property));

    var propertyEnclosing = property.enclosingElement;
    expect(accessor.enclosingElement, same(propertyEnclosing));

    if (propertyEnclosing is CompilationUnitElement) {
      expect(propertyEnclosing.accessors, contains(accessor));
    } else if (propertyEnclosing is ClassElement) {
      expect(propertyEnclosing.accessors, contains(accessor));
    }
  }

  ResolvedAstPrinter _createAstPrinter() {
    return ResolvedAstPrinter(
      selfUriStr: selfUriStr,
      sink: buffer,
      indent: indent,
      withNullability: true,
      withOffsets: true,
    );
  }

  String _getElementLocationString(Element? element) {
    if (element == null || element is MultiplyDefinedElement) {
      return 'null';
    }

    String onlyName(String uri) {
      if (uri.startsWith('file:///')) {
        return uri.substring(uri.lastIndexOf('/') + 1);
      }
      return uri;
    }

    var location = element.location!;
    List<String> components = location.components.toList();
    if (components.isNotEmpty) {
      components[0] = onlyName(components[0]);
    }
    if (components.length >= 2) {
      components[1] = onlyName(components[1]);
      if (components[0] == components[1]) {
        components.removeAt(0);
      }
    }
    return components.join(';');
  }

  String? _typeStr(DartType? type) {
    return type?.getDisplayString(
      withNullability: true,
    );
  }

  void _withIndent(void Function() f) {
    var savedIndent = indent;
    indent = '$savedIndent  ';
    f();
    indent = savedIndent;
  }

  void _writeBodyModifiers(ExecutableElement e) {
    if (e.isAsynchronous) {
      expect(e.isSynchronous, isFalse);
      buffer.write(' async');
    }

    if (e.isSynchronous && e.isGenerator) {
      expect(e.isAsynchronous, isFalse);
      buffer.write(' sync');
    }

    _writeIf(e.isGenerator, '*');
  }

  void _writeClassElement(ClassElement e) {
    _writeIndentedLine(() {
      _writeIf(e.isAbstract && !e.isMixin, 'abstract ');
      _writeIf(!e.isSimplyBounded, 'notSimplyBounded ');

      if (e.isEnum) {
        buffer.write('enum ');
      } else if (e.isMixin) {
        buffer.write('mixin ');
      } else {
        buffer.write('class ');
      }
      _writeIf(e.isMixinApplication, 'alias ');

      _writeName(e);
    });

    _withIndent(() {
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeCodeRange(e);
      _writeTypeParameterElements(e.typeParameters);

      var supertype = e.supertype;
      if (supertype != null &&
          (supertype.element.name != 'Object' || e.mixins.isNotEmpty)) {
        _writeType(supertype, name: 'supertype');
      }

      if (e.isMixin) {
        var superclassConstraints = e.superclassConstraints;
        if (superclassConstraints.isEmpty) {
          throw StateError('At least Object is expected.');
        }
        _writeElements<DartType>(
          'superclassConstraints',
          superclassConstraints,
          _writeType,
        );
      }

      _writeElements<DartType>('mixins', e.mixins, _writeType);
      _writeElements<DartType>('interfaces', e.interfaces, _writeType);

      _writeElements('fields', e.fields, _writePropertyInducingElement);

      var constructors = e.constructors;
      if (e.isEnum) {
        expect(constructors, isEmpty);
      } else {
        expect(constructors, isNotEmpty);
      }
      _writeElements('constructors', constructors, _writeConstructorElement);

      _writeElements('accessors', e.accessors, _writePropertyAccessorElement);
      _writeElements('methods', e.methods, _writeMethodElement);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeCodeRange(Element e) {
    if (withCodeRanges && !e.isSynthetic) {
      e as ElementImpl;
      _writelnWithIndent('codeOffset: ${e.codeOffset}');
      _writelnWithIndent('codeLength: ${e.codeLength}');
    }
  }

  void _writeConstantInitializer(Element e) {
    if (e is ConstVariableElement) {
      var initializer = e.constantInitializer;
      if (initializer != null) {
        _writelnWithIndent('constantInitializer');
        _withIndent(() {
          _writeNode(initializer);
        });
      }
    }
  }

  void _writeConstructorElement(ConstructorElement e) {
    e as ConstructorElementImpl;

    _writeIndentedLine(() {
      _writeIf(e.isSynthetic, 'synthetic ');
      _writeIf(e.isExternal, 'external ');
      _writeIf(e.isConst, 'const ');
      _writeIf(e.isFactory, 'factory ');
      expect(e.isAbstract, isFalse);
      _writeName(e);
    });

    _withIndent(() {
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeCodeRange(e);
      _writeDisplayName(e);

      var periodOffset = e.periodOffset;
      var nameEnd = e.nameEnd;
      if (periodOffset != null && nameEnd != null) {
        _writelnWithIndent('periodOffset: $periodOffset');
        _writelnWithIndent('nameEnd: $nameEnd');
      }

      _writeParameterElements(e.parameters);

      _writeElements(
        'constantInitializers',
        e.constantInitializers,
        _writeNode,
      );

      var redirectedConstructor = e.redirectedConstructor;
      if (redirectedConstructor != null) {
        _writeElementReference('redirectedConstructor', redirectedConstructor);
      }

      _writeNonSyntheticElement(e);
    });

    expect(e.isAsynchronous, isFalse);
    expect(e.isGenerator, isFalse);

    if (e.isSynthetic) {
      expect(e.nameOffset, -1);
      expect(e.nonSynthetic, same(e.enclosingElement));
    } else {
      expect(e.nameOffset, isPositive);
    }
  }

  void _writeDisplayName(Element e) {
    if (withDisplayName) {
      _writelnWithIndent('displayName: ${e.displayName}');
    }
  }

  void _writeDocumentation(Element element) {
    var documentation = element.documentationComment;
    if (documentation != null) {
      var str = documentation;
      str = str.replaceAll('\n', r'\n');
      str = str.replaceAll('\r', r'\r');
      _writelnWithIndent('documentationComment: $str');
    }
  }

  void _writeElementReference(String name, Element element) {
    var printer = _createAstPrinter();
    printer.writeElement(name, element);
  }

  void _writeElements<T>(String name, List<T> elements, void Function(T) f) {
    if (elements.isNotEmpty) {
      _writelnWithIndent(name);
      _withIndent(() {
        for (var element in elements) {
          f(element);
        }
      });
    }
  }

  void _writeExportElement(ExportElement e) {
    _writeIndentedLine(() {
      _writeUri(e.exportedLibrary?.source);
    });

    _withIndent(() {
      _writeMetadata(e);
      _writeNamespaceCombinators(e.combinators);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeExportScope(LibraryElement e) {
    var map = e.exportNamespace.definedNames;
    var names = map.keys.toList()..sort();
    for (var name in names) {
      var element = map[name];
      var elementLocationStr = _getElementLocationString(element);
      _writelnWithIndent('$name: $elementLocationStr');
    }
  }

  void _writeExtensionElement(ExtensionElement e) {
    _writeIndentedLine(() {
      _writeName(e);
    });

    _withIndent(() {
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeCodeRange(e);
      _writeTypeParameterElements(e.typeParameters);
      _writeType(e.extendedType, name: 'extendedType');
    });

    _withIndent(() {
      _writeElements('fields', e.fields, _writePropertyInducingElement);
      _writeElements('accessors', e.accessors, _writePropertyAccessorElement);
      _writeElements('methods', e.methods, _writeMethodElement);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeFunctionElement(FunctionElement e) {
    _writeIndentedLine(() {
      _writeIf(e.isExternal, 'external ');
      _writeName(e);
      _writeBodyModifiers(e);
    });

    _withIndent(() {
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeCodeRange(e);
      _writeTypeParameterElements(e.typeParameters);
      _writeParameterElements(e.parameters);
      _writeType(e.returnType, name: 'returnType');
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeIf(bool flag, String str) {
    if (flag) {
      buffer.write(str);
    }
  }

  void _writeImportElement(ImportElement e) {
    _writeIndentedLine(() {
      _writeUri(e.importedLibrary?.source);
      _writeIf(e.isDeferred, ' deferred');

      var prefix = e.prefix;
      if (prefix != null) {
        buffer.write(' as ');
        _writeName(prefix);
      }
    });

    _withIndent(() {
      _writeMetadata(e);
      _writeNamespaceCombinators(e.combinators);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeIndentedLine(void Function() f) {
    buffer.write(indent);
    f();
    buffer.writeln();
  }

  void _writelnWithIndent(String line) {
    buffer.write(indent);
    buffer.writeln(line);
  }

  void _writeMetadata(Element element) {
    var annotations = element.metadata;
    if (annotations.isNotEmpty) {
      _writelnWithIndent('metadata');
      _withIndent(() {
        for (var annotation in annotations) {
          annotation as ElementAnnotationImpl;
          _writeNode(annotation.annotationAst);
        }
      });
    }
  }

  void _writeMethodElement(MethodElement e) {
    _writeIndentedLine(() {
      _writeIf(e.isSynthetic, 'synthetic ');
      _writeIf(e.isStatic, 'static ');
      _writeIf(e.isAbstract, 'abstract ');
      _writeIf(e.isExternal, 'external ');

      _writeName(e);
      _writeBodyModifiers(e);
    });

    _withIndent(() {
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeCodeRange(e);
      _writeTypeInferenceError(e);

      _writeTypeParameterElements(e.typeParameters);
      _writeParameterElements(e.parameters);
      _writeType(e.returnType, name: 'returnType');
      _writeNonSyntheticElement(e);
    });

    if (e.isSynthetic && e.enclosingElement is EnumElementImpl) {
      expect(e.name, 'toString');
      expect(e.nonSynthetic, same(e.enclosingElement));
    } else {
      _assertNonSyntheticElementSelf(e);
    }
  }

  void _writeName(Element e) {
    // TODO(scheglov) Use 'name' everywhere.
    var name = e is ConstructorElement ? e.name : e.displayName;
    buffer.write(name);
    buffer.write(name.isNotEmpty ? ' @' : '@');
    buffer.write(e.nameOffset);
  }

  void _writeNamespaceCombinator(NamespaceCombinator e) {
    _writeIndentedLine(() {
      if (e is ShowElementCombinator) {
        buffer.write('show: ');
        buffer.write(e.shownNames.join(', '));
      } else if (e is HideElementCombinator) {
        buffer.write('hide: ');
        buffer.write(e.hiddenNames.join(', '));
      }
    });
  }

  void _writeNamespaceCombinators(List<NamespaceCombinator> elements) {
    _writeElements('combinators', elements, _writeNamespaceCombinator);
  }

  void _writeNode(AstNode node) {
    buffer.write(indent);
    node.accept(
      _createAstPrinter(),
    );
  }

  void _writeNonSyntheticElement(Element e) {
    if (withNonSynthetic) {
      _writeElementReference('nonSynthetic', e.nonSynthetic);
    }
  }

  void _writeParameterElement(ParameterElement e) {
    _writeIndentedLine(() {
      if (e.isRequiredPositional) {
        buffer.write('requiredPositional ');
      } else if (e.isOptionalPositional) {
        buffer.write('optionalPositional ');
      } else if (e.isRequiredNamed) {
        buffer.write('requiredName ');
      } else if (e.isOptionalNamed) {
        buffer.write('optionalNamed ');
      }

      _writeIf(e.isConst, 'const ');
      _writeIf(e.isCovariant, 'covariant ');
      _writeIf(e.isFinal, 'final ');

      if (e is FieldFormalParameterElement) {
        buffer.write('this.');
      }

      _writeName(e);
    });

    _withIndent(() {
      _writeType(e.type, name: 'type');
      _writeMetadata(e);
      _writeCodeRange(e);
      _writeTypeParameterElements(e.typeParameters);
      _writeParameterElements(e.parameters);
      _writeConstantInitializer(e);
      _writeNonSyntheticElement(e);
    });
  }

  void _writeParameterElements(List<ParameterElement> elements) {
    _writeElements('parameters', elements, _writeParameterElement);
  }

  void _writePropertyAccessorElement(PropertyAccessorElement e) {
    PropertyInducingElement variable = e.variable;
    expect(variable, isNotNull);

    var variableEnclosing = variable.enclosingElement;
    if (variableEnclosing is CompilationUnitElement) {
      expect(variableEnclosing.topLevelVariables, contains(variable));
    } else if (variableEnclosing is ClassElement) {
      expect(variableEnclosing.fields, contains(variable));
    }

    if (e.isGetter) {
      expect(variable.getter, same(e));
      if (variable.setter != null) {
        expect(variable.setter!.variable, same(variable));
      }
    } else {
      expect(variable.setter, same(e));
      if (variable.getter != null) {
        expect(variable.getter!.variable, same(variable));
      }
    }

    if (e.isSynthetic) {
      expect(e.nameOffset, -1);
    } else {
      expect(e.nameOffset, isPositive);
      _assertNonSyntheticElementSelf(e);
    }

    _writeIndentedLine(() {
      _writeIf(e.isSynthetic, 'synthetic ');
      _writeIf(e.isStatic, 'static ');
      _writeIf(e.isAbstract, 'abstract ');
      _writeIf(e.isExternal, 'external ');

      if (e.isGetter) {
        buffer.write('get ');
      } else {
        buffer.write('set ');
      }

      _writeName(e);
      _writeBodyModifiers(e);
    });

    _withIndent(() {
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeCodeRange(e);

      expect(e.typeParameters, isEmpty);
      _writeParameterElements(e.parameters);
      _writeType(e.returnType, name: 'returnType');
      _writeNonSyntheticElement(e);
    });
  }

  void _writePropertyInducingElement(PropertyInducingElement e) {
    DartType type = e.type;
    expect(type, isNotNull);

    if (e.isSynthetic) {
      expect(e.nameOffset, -1);
    } else {
      expect(e.getter, isNotNull);
      _assertSyntheticAccessorEnclosing(e, e.getter!);

      if (e.setter != null) {
        _assertSyntheticAccessorEnclosing(e, e.setter!);
      }

      expect(e.nameOffset, isPositive);
      _assertNonSyntheticElementSelf(e);
    }

    _writeIndentedLine(() {
      _writeIf(e.isSynthetic, 'synthetic ');
      _writeIf(e.isStatic, 'static ');
      _writeIf(e is FieldElementImpl && e.isAbstract, 'abstract ');
      _writeIf(e is FieldElementImpl && e.isCovariant, 'covariant ');
      _writeIf(e is FieldElementImpl && e.isExternal, 'external ');
      _writeIf(e.isLate, 'late ');
      _writeIf(e.isFinal, 'final ');
      _writeIf(e.isConst, 'const ');

      _writeName(e);
    });

    _withIndent(() {
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeCodeRange(e);
      _writeTypeInferenceError(e);
      _writeType(e.type, name: 'type');
      _writeConstantInitializer(e);
      _writeNonSyntheticElement(e);
    });
  }

  void _writeType(DartType type, {String? name}) {
    var typeStr = _typeStr(type);
    if (name != null) {
      _writelnWithIndent('$name: $typeStr');
    } else {
      _writelnWithIndent('$typeStr');
    }

    var alias = type.alias;
    if (alias != null) {
      _withIndent(() {
        _createAstPrinter().writeElement('aliasElement', alias.element);

        _writeElements<DartType>(
          'aliasArguments',
          alias.typeArguments,
          _writeType,
        );
      });
    }
  }

  void _writeTypeAliasElement(TypeAliasElement e) {
    e as TypeAliasElementImpl;

    _writeIndentedLine(() {
      _writeIf(e.isFunctionTypeAliasBased, 'functionTypeAliasBased ');
      _writeIf(!e.isSimplyBounded, 'notSimplyBounded ');
      _writeName(e);
    });

    _withIndent(() {
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeCodeRange(e);
      _writeTypeParameterElements(e.typeParameters);

      var aliasedType = e.aliasedType;
      _writeType(aliasedType, name: 'aliasedType');
      // TODO(scheglov) https://github.com/dart-lang/sdk/issues/44629
      // TODO(scheglov) Remove it when we stop providing it everywhere.
      if (aliasedType is FunctionType) {
        expect(aliasedType.element, isNull);
      }

      var aliasedElement = e.aliasedElement;
      if (aliasedElement is GenericFunctionTypeElementImpl) {
        _writelnWithIndent('aliasedElement: GenericFunctionTypeElement');
        _withIndent(() {
          _writeTypeParameterElements(aliasedElement.typeParameters);
          _writeParameterElements(aliasedElement.parameters);
          _writeType(aliasedElement.returnType, name: 'returnType');
        });
      }
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeTypeInferenceError(Element e) {
    TopLevelInferenceError? inferenceError;
    if (e is MethodElementImpl) {
      inferenceError = e.typeInferenceError;
    } else if (e is PropertyInducingElementImpl) {
      inferenceError = e.typeInferenceError;
    }

    if (inferenceError != null) {
      String kindName = inferenceError.kind.toString();
      if (kindName.startsWith('TopLevelInferenceErrorKind.')) {
        kindName = kindName.substring('TopLevelInferenceErrorKind.'.length);
      }
      _writelnWithIndent('typeInferenceError: $kindName');
    }
  }

  void _writeTypeParameterElement(TypeParameterElement e) {
    e as TypeParameterElementImpl;

    _writeIndentedLine(() {
      buffer.write('${e.variance} ');
      _writeName(e);
    });

    _withIndent(() {
      _writeCodeRange(e);

      var bound = e.bound;
      if (bound != null) {
        _writeType(bound, name: 'bound');
      }

      var defaultType = e.defaultType;
      if (defaultType != null) {
        _writeType(defaultType, name: 'defaultType');
      }

      _writeMetadata(e);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeTypeParameterElements(List<TypeParameterElement> elements) {
    _writeElements('typeParameters', elements, _writeTypeParameterElement);
  }

  void _writeUnitElement(CompilationUnitElement e) {
    _writeElements('classes', e.classes, _writeClassElement);
    _writeElements('enums', e.enums, _writeClassElement);
    _writeElements('extensions', e.extensions, _writeExtensionElement);
    _writeElements('mixins', e.mixins, _writeClassElement);
    _writeElements('typeAliases', e.typeAliases, _writeTypeAliasElement);
    _writeElements(
      'topLevelVariables',
      e.topLevelVariables,
      _writePropertyInducingElement,
    );
    _writeElements(
      'accessors',
      e.accessors,
      _writePropertyAccessorElement,
    );
    _writeElements('functions', e.functions, _writeFunctionElement);
  }

  void _writeUri(Source? source) {
    if (source != null) {
      Uri uri = source.uri;
      String uriStr = uri.toString();
      if (uri.isScheme('file')) {
        uriStr = uri.pathSegments.last;
      }
      buffer.write('$uriStr');
    } else {
      buffer.write('<unresolved>');
    }
  }
}

class _Replacement {
  final int offset;
  final int end;
  final String text;

  _Replacement(this.offset, this.end, this.text);
}
