// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/task/inference_error.dart';
import 'package:collection/collection.dart';
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
    for (var replacement in _replacements) {
      newCode = newCode.substring(0, replacement.offset) +
          replacement.text +
          newCode.substring(replacement.end);
    }
    File(_testPath!).writeAsStringSync(newCode);
  }
}

/// Write the given [library] elements into the canonical text presentation
/// taking into account the [configuration]. Then compare the actual text with
/// the given [expected] one.
void checkElementTextWithConfiguration(
  LibraryElement library,
  String expected, {
  ElementTextConfiguration? configuration,
}) {
  var writer = _ElementWriter(
    selfUriStr: '${library.source.uri}',
    configuration: configuration ?? ElementTextConfiguration(),
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

      int testFilePathOffset = traceString.lastIndexOf(_testPath!);
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
          _Replacement(expectationOffset, expectationEnd, '\n$actualText'));
    }
  }

  // Print the actual text to simplify copy/paste into the expectation.
  // if (actualText != expected) {
  //   print('-------- Actual --------');
  //   print('$actualText------------------------');
  // }

  expect(actualText, expected);
}

class ElementTextConfiguration {
  bool Function(Object) filter;
  bool withCodeRanges = false;
  bool withDisplayName = false;
  bool withExportScope = false;
  bool withNonSynthetic = false;
  bool withPropertyLinking = false;
  bool withSyntheticDartCoreImport = false;

  ElementTextConfiguration({
    this.filter = _filterTrue,
  });

  static bool _filterTrue(Object element) => true;
}

/// Writes the canonical text presentation of elements.
class _ElementWriter {
  final String? selfUriStr;
  final ElementTextConfiguration configuration;
  final StringBuffer buffer = StringBuffer();
  final _IdMap _idMap = _IdMap();

  String indent = '';

  _ElementWriter({
    this.selfUriStr,
    required this.configuration,
  });

  void writeLibraryElement(LibraryElement e) {
    e as LibraryElementImpl;

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

      _writeLibraryOrAugmentationElement(e);

      _writeElements('parts', e.parts, _writePartElement);

      if (configuration.withExportScope) {
        _writelnWithIndent('exportedReferences');
        _withIndent(() {
          _writeExportedReferences(e);
        });
        _writelnWithIndent('exportNamespace');
        _withIndent(() {
          _writeExportNamespace(e);
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
    } else if (propertyEnclosing is InterfaceElement) {
      expect(propertyEnclosing.accessors, contains(accessor));
    }
  }

  ResolvedAstPrinter _createAstPrinter() {
    return ResolvedAstPrinter(
      selfUriStr: selfUriStr,
      sink: buffer,
      indent: indent,
      // TODO(scheglov) https://github.com/dart-lang/sdk/issues/49101
      withParameterElements: false,
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

  void _withIndent(void Function() f) {
    var savedIndent = indent;
    indent = '$savedIndent  ';
    f();
    indent = savedIndent;
  }

  void _writeAugmentationElement(LibraryAugmentationElement e) {
    _writeLibraryOrAugmentationElement(e);
  }

  void _writeAugmentationImportElement(AugmentationImportElement e) {
    final uri = e.uri;
    _writeIndentedLine(() {
      _writeDirectiveUri(e.uri);
    });

    _withIndent(() {
      _writeMetadata(e);
      if (uri is DirectiveUriWithAugmentation) {
        _writeAugmentationElement(uri.augmentation);
      }
    });
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

    if (e is ExecutableElementImpl && e.invokesSuperSelf) {
      buffer.write(' invokesSuperSelf');
    }
  }

  void _writeClassElement(InterfaceElement e) {
    _writeIndentedLine(() {
      if (e is ClassElement) {
        _writeIf(e.isAbstract, 'abstract ');
        _writeIf(e.isMacro, 'macro ');
        _writeIf(e.isSealed, 'sealed ');
        _writeIf(e.isBase, 'base ');
        _writeIf(e.isInterface, 'interface ');
        _writeIf(e.isFinal, 'final ');
        _writeIf(e.isMixinClass, 'mixin ');
      }
      _writeIf(!e.isSimplyBounded, 'notSimplyBounded ');

      if (e is EnumElement) {
        buffer.write('enum ');
      } else if (e is MixinElement) {
        _writeIf(e.isSealed, 'sealed ');
        _writeIf(e.isBase, 'base ');
        _writeIf(e.isInterface, 'interface ');
        _writeIf(e.isFinal, 'final ');
        buffer.write('mixin ');
      } else {
        buffer.write('class ');
      }
      if (e is ClassElement) {
        _writeIf(e.isMixinApplication, 'alias ');
      }

      _writeName(e);
    });

    _withIndent(() {
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeCodeRange(e);
      _writeTypeParameterElements(e.typeParameters);

      final supertype = e.supertype;
      if (supertype != null &&
          (supertype.element.name != 'Object' || e.mixins.isNotEmpty)) {
        _writeType('supertype', supertype);
      }

      if (e is MixinElement) {
        var superclassConstraints = e.superclassConstraints;
        if (superclassConstraints.isEmpty) {
          throw StateError('At least Object is expected.');
        }
        _writeTypeList('superclassConstraints', superclassConstraints);
      }

      _writeTypeList('mixins', e.mixins);
      _writeTypeList('interfaces', e.interfaces);

      _writeElements('fields', e.fields, _writePropertyInducingElement);

      var constructors = e.constructors;
      if (e is MixinElement) {
        expect(constructors, isEmpty);
      } else {
        expect(constructors, isNotEmpty);
        _writeElements('constructors', constructors, _writeConstructorElement);
      }

      _writeElements('accessors', e.accessors, _writePropertyAccessorElement);
      _writeElements('methods', e.methods, _writeMethodElement);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeCodeRange(Element e) {
    if (configuration.withCodeRanges && !e.isSynthetic) {
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

    // Check that the reference exists, and filled with the element.
    var reference = e.reference;
    if (reference == null) {
      fail('Every constructor must have a reference.');
    } else {
      var classReference = reference.parent!.parent!;
      // We need this `if` for duplicate declarations.
      // The reference might be filled by another declaration.
      if (identical(classReference.element, e.enclosingElement)) {
        expect(reference.element, same(e));
      }
    }

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

      var superConstructor = e.superConstructor;
      if (superConstructor != null) {
        final enclosingElement = superConstructor.enclosingElement;
        if (enclosingElement is ClassElement &&
            !enclosingElement.isDartCoreObject) {
          _writeElementReference('superConstructor', superConstructor);
        }
      }

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
      if (!e.isTempAugmentation) {
        expect(e.nameOffset, isPositive);
      }
    }
  }

  void _writeDirectiveUri(DirectiveUri uri) {
    if (uri is DirectiveUriWithAugmentationImpl) {
      buffer.write('${uri.augmentation.source.uri}');
    } else if (uri is DirectiveUriWithLibraryImpl) {
      buffer.write('${uri.library.source.uri}');
    } else if (uri is DirectiveUriWithUnit) {
      buffer.write('${uri.unit.source.uri}');
    } else if (uri is DirectiveUriWithSource) {
      buffer.write("source '${uri.source.uri}'");
    } else if (uri is DirectiveUriWithRelativeUri) {
      buffer.write("relativeUri '${uri.relativeUri}'");
    } else if (uri is DirectiveUriWithRelativeUriString) {
      buffer.write("relativeUriString '${uri.relativeUriString}'");
    } else {
      buffer.write('noRelativeUriString');
    }
  }

  void _writeDisplayName(Element e) {
    if (configuration.withDisplayName) {
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

  void _writeElements<T extends Object>(
    String name,
    List<T> elements,
    void Function(T) f,
  ) {
    var filtered = elements.where(configuration.filter).toList();
    if (filtered.isNotEmpty) {
      _writelnWithIndent(name);
      _withIndent(() {
        for (var element in filtered) {
          f(element);
        }
      });
    }
  }

  void _writeExportedReferences(LibraryElementImpl e) {
    final exportedReferences = e.exportedReferences.toList();
    exportedReferences.sortBy((e) => e.reference.toString());

    for (final exported in exportedReferences) {
      _writeIndentedLine(() {
        if (exported is ExportedReferenceDeclared) {
          buffer.write('declared ');
        } else if (exported is ExportedReferenceExported) {
          buffer.write('exported${exported.locations} ');
        }
        // TODO(scheglov) Use the same writer as for resolved AST.
        buffer.write(exported.reference);
      });
    }
  }

  void _writeExportElement(LibraryExportElement e) {
    e.location;

    _writeIndentedLine(() {
      _writeDirectiveUri(e.uri);
    });

    _withIndent(() {
      _writeMetadata(e);
      _writeNamespaceCombinators(e.combinators);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeExportNamespace(LibraryElement e) {
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
      _writeType('extendedType', e.extendedType);
    });

    _withIndent(() {
      _writeElements('fields', e.fields, _writePropertyInducingElement);
      _writeElements('accessors', e.accessors, _writePropertyAccessorElement);
      _writeElements('methods', e.methods, _writeMethodElement);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeFieldFormalParameterField(ParameterElement e) {
    if (e is FieldFormalParameterElement) {
      var field = e.field;
      if (field != null) {
        _writeElementReference('field', field);
      } else {
        _writelnWithIndent('field: <null>');
      }
    }
  }

  void _writeFunctionElement(FunctionElement e) {
    expect(e.isStatic, isTrue);

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
      _writeType('returnType', e.returnType);
    });

    _assertNonSyntheticElementSelf(e);
  }

  void _writeIf(bool flag, String str) {
    if (flag) {
      buffer.write(str);
    }
  }

  void _writeImportElement(LibraryImportElement e) {
    e.location;

    _writeIndentedLine(() {
      _writeDirectiveUri(e.uri);
      _writeIf(e.isSynthetic, ' synthetic');
      _writeImportElementPrefix(e.prefix);
    });

    _withIndent(() {
      _writeMetadata(e);
      _writeNamespaceCombinators(e.combinators);
    });
  }

  void _writeImportElementPrefix(ImportElementPrefix? prefix) {
    if (prefix != null) {
      _writeIf(prefix is DeferredImportElementPrefix, ' deferred');
      buffer.write(' as ');
      _writeName(prefix.element);
    }
  }

  void _writeIndentedLine(void Function() f) {
    buffer.write(indent);
    f();
    buffer.writeln();
  }

  void _writeLibraryOrAugmentationElement(LibraryOrAugmentationElement e) {
    _writeDocumentation(e);
    _writeMetadata(e);

    var imports = e.libraryImports.where((import) {
      return configuration.withSyntheticDartCoreImport || !import.isSynthetic;
    }).toList();
    _writeElements('imports', imports, _writeImportElement);

    _writeElements('exports', e.libraryExports, _writeExportElement);

    _writeElements('augmentationImports', e.augmentationImports,
        _writeAugmentationImportElement);

    _writelnWithIndent('definingUnit');
    _withIndent(() {
      _writeUnitElement(e.definingCompilationUnit);
    });
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
      _writeType('returnType', e.returnType);
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
    if (configuration.withNonSynthetic) {
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
        buffer.write('requiredNamed ');
      } else if (e.isOptionalNamed) {
        buffer.write('optionalNamed ');
      }

      _writeIf(e.isConst, 'const ');
      _writeIf(e.isCovariant, 'covariant ');
      _writeIf(e.isFinal, 'final ');

      if (e is FieldFormalParameterElement) {
        buffer.write('this.');
      } else if (e is SuperFormalParameterElement) {
        buffer.write('super.');
      }

      _writeName(e);
    });

    _withIndent(() {
      _writeType('type', e.type);
      _writeMetadata(e);
      _writeCodeRange(e);
      _writeTypeParameterElements(e.typeParameters);
      _writeParameterElements(e.parameters);
      _writeConstantInitializer(e);
      _writeNonSyntheticElement(e);
      _writeFieldFormalParameterField(e);
      _writeSuperConstructorParameter(e);
    });
  }

  void _writeParameterElements(List<ParameterElement> elements) {
    _writeElements('parameters', elements, _writeParameterElement);
  }

  void _writePartElement(PartElement e) {
    final uri = e.uri;
    _writeIndentedLine(() {
      _writeDirectiveUri(e.uri);
    });

    _withIndent(() {
      _writeMetadata(e);
      if (uri is DirectiveUriWithUnit) {
        _writeUnitElement(uri.unit);
      }
    });
  }

  void _writePropertyAccessorElement(PropertyAccessorElement e) {
    e as PropertyAccessorElementImpl;

    PropertyInducingElement variable = e.variable;
    expect(variable, isNotNull);

    var variableEnclosing = variable.enclosingElement;
    if (variableEnclosing is CompilationUnitElement) {
      expect(variableEnclosing.topLevelVariables, contains(variable));
    } else if (variableEnclosing is InterfaceElement) {
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
      if (!e.isTempAugmentation) {
        expect(e.nameOffset, isPositive);
      }
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

    void writeLinking() {
      if (configuration.withPropertyLinking) {
        _writelnWithIndent('id: ${_idMap[e]}');
        _writelnWithIndent('variable: ${_idMap[e.variable]}');
      }
    }

    _withIndent(() {
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeCodeRange(e);

      expect(e.typeParameters, isEmpty);
      _writeParameterElements(e.parameters);
      _writeType('returnType', e.returnType);
      _writeNonSyntheticElement(e);
      writeLinking();
    });
  }

  void _writePropertyInducingElement(PropertyInducingElement e) {
    e as PropertyInducingElementImpl;

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

      if (!e.isTempAugmentation) {
        expect(e.nameOffset, isPositive);
      }
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
      if (e is FieldElementImpl) {
        _writeIf(e.isEnumConstant, 'enumConstant ');
        _writeIf(e.isPromotable, 'promotable ');
      }

      _writeName(e);
    });

    void writeLinking() {
      if (configuration.withPropertyLinking) {
        _writelnWithIndent('id: ${_idMap[e]}');

        final getter = e.getter;
        if (getter != null) {
          _writelnWithIndent('getter: ${_idMap[getter]}');
        }

        final setter = e.setter;
        if (setter != null) {
          _writelnWithIndent('setter: ${_idMap[setter]}');
        }
      }
    }

    _withIndent(() {
      _writeDocumentation(e);
      _writeMetadata(e);
      _writeCodeRange(e);
      _writeTypeInferenceError(e);
      _writeType('type', e.type);
      _writeShouldUseTypeForInitializerInference(e);
      _writeConstantInitializer(e);
      _writeNonSyntheticElement(e);
      writeLinking();
    });
  }

  void _writeShouldUseTypeForInitializerInference(
    PropertyInducingElementImpl e,
  ) {
    if (!e.isSynthetic) {
      _writelnWithIndent(
        'shouldUseTypeForInitializerInference: '
        '${e.shouldUseTypeForInitializerInference}',
      );
    }
  }

  void _writeSuperConstructorParameter(ParameterElement e) {
    if (e is SuperFormalParameterElement) {
      var superParameter = e.superConstructorParameter;
      if (superParameter != null) {
        _writeElementReference('superConstructorParameter', superParameter);
      } else {
        _writelnWithIndent('superConstructorParameter: <null>');
      }
    }
  }

  void _writeType(String name, DartType type) {
    _createAstPrinter().writeType(type, name: name);
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
      _writeType('aliasedType', aliasedType);

      var aliasedElement = e.aliasedElement;
      if (aliasedElement is GenericFunctionTypeElementImpl) {
        _writelnWithIndent('aliasedElement: GenericFunctionTypeElement');
        _withIndent(() {
          _writeTypeParameterElements(aliasedElement.typeParameters);
          _writeParameterElements(aliasedElement.parameters);
          _writeType('returnType', aliasedElement.returnType);
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
      _withIndent(() {
        if (kindName == 'dependencyCycle') {
          _writelnWithIndent('arguments: ${inferenceError?.arguments}');
        }
      });
    }
  }

  void _writeTypeList(String name, List<DartType> types) {
    _createAstPrinter().writeTypeList(name, types);
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
        _writeType('bound', bound);
      }

      var defaultType = e.defaultType;
      if (defaultType != null) {
        _writeType('defaultType', defaultType);
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
}

class _IdMap {
  final Map<Element, String> fieldMap = Map.identity();
  final Map<Element, String> getterMap = Map.identity();
  final Map<Element, String> setterMap = Map.identity();

  String operator [](Element element) {
    if (element is FieldElement) {
      return fieldMap[element] ??= 'field_${fieldMap.length}';
    } else if (element is TopLevelVariableElement) {
      return fieldMap[element] ??= 'variable_${fieldMap.length}';
    } else if (element is PropertyAccessorElement && element.isGetter) {
      return getterMap[element] ??= 'getter_${getterMap.length}';
    } else if (element is PropertyAccessorElement && element.isSetter) {
      return setterMap[element] ??= 'setter_${setterMap.length}';
    } else {
      return '???';
    }
  }
}

class _Replacement {
  final int offset;
  final int end;
  final String text;

  _Replacement(this.offset, this.end, this.text);
}

extension on ClassElement {
  bool get isMacro {
    final self = this;
    return self is ClassElementImpl && self.isMacro;
  }
}
