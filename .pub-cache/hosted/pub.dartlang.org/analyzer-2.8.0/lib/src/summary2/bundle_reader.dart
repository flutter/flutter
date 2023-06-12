// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/ast_binary_reader.dart';
import 'package:analyzer/src/summary2/ast_binary_tag.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/element_flags.dart';
import 'package:analyzer/src/summary2/informative_data.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/task/inference_error.dart';
import 'package:pub_semver/pub_semver.dart';

class BundleReader {
  final SummaryDataReader _reader;
  final Map<Uri, Uint8List> _unitsInformativeBytes;

  final Map<String, LibraryReader> libraryMap = {};

  BundleReader({
    required LinkedElementFactory elementFactory,
    required Uint8List resolutionBytes,
    Map<Uri, Uint8List> unitsInformativeBytes = const {},
  })  : _reader = SummaryDataReader(resolutionBytes),
        _unitsInformativeBytes = unitsInformativeBytes {
    _reader.offset = _reader.bytes.length - 4 * 4;
    var baseResolutionOffset = _reader.readUInt32();
    var librariesOffset = _reader.readUInt32();
    var referencesOffset = _reader.readUInt32();
    var stringsOffset = _reader.readUInt32();
    _reader.createStringTable(stringsOffset);

    var referenceReader = _ReferenceReader(
      elementFactory,
      _reader,
      referencesOffset,
    );

    _reader.offset = librariesOffset;
    var libraryHeaderList = _reader.readTypedList(() {
      return _LibraryHeader(
        uriStr: _reader.readStringReference(),
        offset: _reader.readUInt30(),
        classMembersLengths: _reader.readUInt30List(),
      );
    });

    for (var libraryHeader in libraryHeaderList) {
      var uriStr = libraryHeader.uriStr;
      var reference = elementFactory.rootReference.getChild(uriStr);
      libraryMap[uriStr] = LibraryReader._(
        elementFactory: elementFactory,
        reader: _reader,
        unitsInformativeBytes: _unitsInformativeBytes,
        baseResolutionOffset: baseResolutionOffset,
        referenceReader: referenceReader,
        reference: reference,
        offset: libraryHeader.offset,
        classMembersLengths: libraryHeader.classMembersLengths,
      );
    }
  }
}

class ClassElementLinkedData extends ElementLinkedData<ClassElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;
  void Function()? _readMembers;
  void Function()? applyInformativeDataToMembers;

  ClassElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  /// Ensure that all members of the [element] are available. This includes
  /// being able to ask them for example using [ClassElement.methods], and
  /// as well access them through their [Reference]s. For a class declaration
  /// this means reading them, for a named mixin application this means
  /// computing constructors.
  void readMembers(ClassElementImpl element) {
    if (element.isMixinApplication) {
      element.constructors;
    } else {
      _readMembers?.call();
      _readMembers = null;

      applyInformativeDataToMembers?.call();
      applyInformativeDataToMembers = null;
    }
  }

  @override
  void _read(element, reader) {
    element.metadata = reader._readAnnotationList(
      unitElement: unitElement,
    );
    _readTypeParameters(reader, element.typeParameters);
    element.supertype = reader._readOptionalInterfaceType();
    element.mixins = reader._readInterfaceTypeList();
    element.interfaces = reader._readInterfaceTypeList();
    applyConstantOffsets?.perform();
  }
}

class CompilationUnitElementLinkedData
    extends ElementLinkedData<CompilationUnitElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  CompilationUnitElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _read(element, reader) {
    element.metadata = reader._readAnnotationList(
      unitElement: unitElement,
    );
    applyConstantOffsets?.perform();
  }
}

class ConstructorElementLinkedData
    extends ElementLinkedData<ConstructorElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  ConstructorElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _read(element, reader) {
    _addEnclosingElementTypeParameters(reader, element);

    element.metadata = reader._readAnnotationList(
      unitElement: unitElement,
    );
    reader._addFormalParameters(element.parameters);
    _readFormalParameters(reader, element.parameters);
    element.redirectedConstructor = reader.readElement() as ConstructorElement?;
    element.constantInitializers = reader._readNodeList();
    applyConstantOffsets?.perform();
  }
}

/// Lazy reader of resolution information.
abstract class ElementLinkedData<E extends ElementImpl> {
  final Reference reference;
  final LibraryReader _libraryReader;
  final CompilationUnitElementImpl unitElement;

  /// When this object is created, this offset is the offset of the resolution
  /// information in the [_libraryReader]. After reading is done, this offset
  /// is set to `-1`.
  int _offset;

  ElementLinkedData(
      this.reference, LibraryReader libraryReader, this.unitElement, int offset)
      : _libraryReader = libraryReader,
        _offset = offset;

  void read(ElementImpl element) {
    if (_offset == -1) {
      return null;
    }

    var dataReader = _libraryReader._reader.fork(_offset);
    _offset = -1;

    var reader = ResolutionReader(
      _libraryReader._elementFactory,
      _libraryReader._referenceReader,
      dataReader,
    );

    _read(element as E, reader);
  }

  void _addEnclosingElementTypeParameters(
    ResolutionReader reader,
    ElementImpl element,
  ) {
    var enclosing = element.enclosingElement;
    if (enclosing is ClassElement) {
      reader._addTypeParameters(enclosing.typeParameters);
    } else if (enclosing is CompilationUnitElement) {
      // Nothing.
    } else if (enclosing is ExtensionElement) {
      reader._addTypeParameters(enclosing.typeParameters);
    } else {
      throw UnimplementedError('${enclosing.runtimeType}');
    }
  }

  void _read(E element, ResolutionReader reader);

  void _readFormalParameters(
    ResolutionReader reader,
    List<ParameterElement> parameters,
  ) {
    for (var parameter in parameters) {
      parameter as ParameterElementImpl;
      parameter.metadata = reader._readAnnotationList(
        unitElement: unitElement,
      );
      _readTypeParameters(reader, parameter.typeParameters);
      _readFormalParameters(reader, parameter.parameters);
      parameter.type = reader.readRequiredType();
      if (parameter is ConstVariableElement) {
        var defaultParameter = parameter as ConstVariableElement;
        var initializer = reader._readOptionalExpression();
        if (initializer != null) {
          defaultParameter.constantInitializer = initializer;
        }
      }
      if (parameter is FieldFormalParameterElementImpl) {
        parameter.field = reader.readElement() as FieldElement?;
      }
    }
  }

  void _readTypeParameters(
    ResolutionReader reader,
    List<TypeParameterElement> typeParameters,
  ) {
    reader._addTypeParameters(typeParameters);
    for (var typeParameter in typeParameters) {
      typeParameter as TypeParameterElementImpl;
      typeParameter.metadata = reader._readAnnotationList(
        unitElement: unitElement,
      );
      typeParameter.bound = reader.readType();
      typeParameter.defaultType = reader.readType();
    }
  }
}

class EnumElementLinkedData extends ElementLinkedData<EnumElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  EnumElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _read(element, reader) {
    var typeProvider = element.library.typeProvider;

    element.metadata = reader._readAnnotationList(
      unitElement: element.enclosingElement,
    );

    var indexField = element.getField('index') as FieldElementImpl;
    indexField.type = typeProvider.intType;

    var toStringMethod = element.getMethod('toString') as MethodElementImpl;
    toStringMethod.returnType = typeProvider.stringType;

    for (var constant in element.constants) {
      constant as FieldElementImpl;
      constant.metadata = reader._readAnnotationList(
        unitElement: element.enclosingElement,
      );
    }

    applyConstantOffsets?.perform();
  }
}

class ExtensionElementLinkedData
    extends ElementLinkedData<ExtensionElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  ExtensionElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _read(element, reader) {
    element.metadata = reader._readAnnotationList(
      unitElement: element.enclosingElement,
    );
    _readTypeParameters(reader, element.typeParameters);
    element.extendedType = reader.readRequiredType();
    applyConstantOffsets?.perform();
  }
}

class FieldElementLinkedData extends ElementLinkedData<FieldElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  FieldElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _read(element, reader) {
    _addEnclosingElementTypeParameters(reader, element);
    element.metadata = reader._readAnnotationList(
      unitElement: unitElement,
    );
    element.type = reader.readRequiredType();
    if (element is ConstFieldElementImpl) {
      var initializer = reader._readOptionalExpression();
      if (initializer != null) {
        element.constantInitializer = initializer;
        ConstantContextForExpressionImpl(initializer);
      }
    }
    applyConstantOffsets?.perform();
  }
}

class FunctionElementLinkedData extends ElementLinkedData<FunctionElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  FunctionElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _read(element, reader) {
    element.metadata = reader._readAnnotationList(
      unitElement: unitElement,
    );
    _readTypeParameters(reader, element.typeParameters);
    element.returnType = reader.readRequiredType();
    _readFormalParameters(reader, element.parameters);
    applyConstantOffsets?.perform();
  }
}

class LibraryElementLinkedData extends ElementLinkedData<LibraryElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  LibraryElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  LinkedElementFactory get elementFactory {
    return _libraryReader._elementFactory;
  }

  @override
  void _read(element, reader) {
    element.metadata = reader._readAnnotationList(
      unitElement: unitElement,
    );

    for (var import in element.imports) {
      import as ImportElementImpl;
      import.metadata = reader._readAnnotationList(
        unitElement: unitElement,
      );
      import.importedLibrary = reader.readElement() as LibraryElementImpl?;
    }

    for (var export in element.exports) {
      export as ExportElementImpl;
      export.metadata = reader._readAnnotationList(
        unitElement: unitElement,
      );
      export.exportedLibrary = reader.readElement() as LibraryElementImpl?;
    }

    element.entryPoint = reader.readElement() as FunctionElement?;

    applyConstantOffsets?.perform();
  }
}

class LibraryReader {
  final LinkedElementFactory _elementFactory;
  final SummaryDataReader _reader;
  final Map<Uri, Uint8List> _unitsInformativeBytes;
  final int _baseResolutionOffset;
  final _ReferenceReader _referenceReader;
  final Reference _reference;
  final int _offset;

  final Uint32List _classMembersLengths;
  int _classMembersLengthsIndex = 0;

  late List<Reference> exports;

  LibraryReader._({
    required LinkedElementFactory elementFactory,
    required SummaryDataReader reader,
    required Map<Uri, Uint8List> unitsInformativeBytes,
    required int baseResolutionOffset,
    required _ReferenceReader referenceReader,
    required Reference reference,
    required int offset,
    required Uint32List classMembersLengths,
  })  : _elementFactory = elementFactory,
        _reader = reader,
        _unitsInformativeBytes = unitsInformativeBytes,
        _baseResolutionOffset = baseResolutionOffset,
        _referenceReader = referenceReader,
        _reference = reference,
        _offset = offset,
        _classMembersLengths = classMembersLengths;

  LibraryElementImpl readElement({required Source librarySource}) {
    var analysisContext = _elementFactory.analysisContext;
    var analysisSession = _elementFactory.analysisSession;
    var sourceFactory = analysisContext.sourceFactory;

    _reader.offset = _offset;
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();

    var name = _reader.readStringReference();
    var featureSet = _readFeatureSet();

    var libraryElement = LibraryElementImpl(
        analysisContext, analysisSession, name, -1, 0, featureSet);
    _reference.element = libraryElement;
    libraryElement.reference = _reference;

    libraryElement.languageVersion = _readLanguageVersion();
    libraryElement.imports = _reader.readTypedList(_readImportElement);
    libraryElement.exports = _reader.readTypedList(_readExportElement);
    LibraryElementFlags.read(_reader, libraryElement);

    var unitContainerRef = _reference.getChild('@unit');
    var unitCount = _reader.readUInt30();
    var units = <CompilationUnitElementImpl>[];
    for (var i = 0; i < unitCount; i++) {
      var unitElement = _readUnitElement(
        sourceFactory: sourceFactory,
        unitContainerRef: unitContainerRef,
        libraryElement: libraryElement,
        librarySource: librarySource,
      );
      units.add(unitElement);
    }

    var exportsIndexList = _reader.readUInt30List();
    exports = exportsIndexList
        .map((index) => _referenceReader.referenceOfIndex(index))
        .toList();

    libraryElement.definingCompilationUnit = units[0];
    libraryElement.parts = units.skip(1).toList();

    libraryElement.linkedData = LibraryElementLinkedData(
      reference: _reference,
      libraryReader: this,
      unitElement: units[0],
      offset: resolutionOffset,
    );

    _declareDartCoreDynamicNever();

    InformativeDataApplier(_elementFactory, _unitsInformativeBytes)
        .applyTo(libraryElement);

    return libraryElement;
  }

  /// These elements are implicitly declared in `dart:core`.
  void _declareDartCoreDynamicNever() {
    if (_reference.name == 'dart:core') {
      _reference.getChild('dynamic').element = DynamicElementImpl.instance;
      _reference.getChild('Never').element = NeverElementImpl.instance;
    }
  }

  ClassElementImpl _readClassElement(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
    var name = _reader.readStringReference();
    var reference = unitReference.getChild('@class').getChild(name);

    var element = ClassElementImpl(name, -1);

    var linkedData = ClassElementLinkedData(
      reference: reference,
      libraryReader: this,
      unitElement: unitElement,
      offset: resolutionOffset,
    );
    element.setLinkedData(reference, linkedData);
    ClassElementFlags.read(_reader, element);

    element.typeParameters = _readTypeParameters();

    if (!element.isMixinApplication) {
      var membersOffset = _reader.offset;
      linkedData._readMembers = () {
        _reader.offset = membersOffset;
        _readClassElementMembers(unitElement, element, reference);
      };
      _reader.offset += _classMembersLengths[_classMembersLengthsIndex++];
    }

    return element;
  }

  void _readClassElementMembers(
    CompilationUnitElementImpl unitElement,
    ClassElementImpl element,
    Reference reference,
  ) {
    var accessors = <PropertyAccessorElementImpl>[];
    var fields = <FieldElement>[];
    _readFields(unitElement, element, reference, accessors, fields);
    _readPropertyAccessors(
        unitElement, element, reference, accessors, fields, '@field');
    element.fields = fields;
    element.accessors = accessors;

    element.constructors = _readConstructors(unitElement, element, reference);
    element.methods = _readMethods(unitElement, element, reference);
  }

  void _readClasses(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    var length = _reader.readUInt30();
    unitElement.classes = List.generate(length, (index) {
      return _readClassElement(unitElement, unitReference);
    });
  }

  List<ConstructorElementImpl> _readConstructors(
    CompilationUnitElementImpl unitElement,
    ClassElementImpl classElement,
    Reference classReference,
  ) {
    var containerRef = classReference.getChild('@constructor');
    var length = _reader.readUInt30();
    return List.generate(length, (_) {
      var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
      var name = _reader.readStringReference();
      var reference = containerRef.getChild(name);
      var element = ConstructorElementImpl(name, -1);
      var linkedData = ConstructorElementLinkedData(
        reference: reference,
        libraryReader: this,
        unitElement: unitElement,
        offset: resolutionOffset,
      );
      element.setLinkedData(reference, linkedData);
      ConstructorElementFlags.read(_reader, element);
      element.parameters = _readParameters(element, reference);
      return element;
    });
  }

  EnumElementImpl _readEnumElement(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
    var name = _reader.readStringReference();
    var reference = unitReference.getChild('@enum').getChild(name);

    var element = EnumElementImpl(name, -1);

    var linkedData = EnumElementLinkedData(
      reference: reference,
      libraryReader: this,
      unitElement: unitElement,
      offset: resolutionOffset,
    );
    element.setLinkedData(reference, linkedData);

    var fields = <FieldElement>[];
    var getters = <PropertyAccessorElement>[];

    // Build the 'index' field.
    {
      var field = FieldElementImpl('index', -1)
        ..enclosingElement = element
        ..isSynthetic = true
        ..isFinal = true;
      fields.add(field);
      getters.add(
        PropertyAccessorElementImpl_ImplicitGetter(field,
            reference: reference.getChild('@getter').getChild('index'))
          ..enclosingElement = element,
      );
    }

    // Build the 'values' field.
    {
      var field = ConstFieldElementImpl_EnumValues(element);
      fields.add(field);
      getters.add(
        PropertyAccessorElementImpl_ImplicitGetter(field,
            reference: reference.getChild('@getter').getChild('values'))
          ..enclosingElement = element,
      );
    }

    // Build fields for all enum constants.
    var containerRef = reference.getChild('@constant');
    var constantCount = _reader.readUInt30();
    for (var i = 0; i < constantCount; i++) {
      var constantName = _reader.readStringReference();
      var field = ConstFieldElementImpl_EnumValue(element, constantName, i);
      var constantRef = containerRef.getChild(constantName);
      field.reference = constantRef;
      constantRef.element = field;
      fields.add(field);
      getters.add(
        PropertyAccessorElementImpl_ImplicitGetter(field,
            reference: reference.getChild('@getter').getChild(constantName))
          ..enclosingElement = element,
      );
    }

    element.fields = fields;
    element.accessors = getters;
    element.createToStringMethodElement();

    return element;
  }

  void _readEnums(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    var count = _reader.readUInt30();
    unitElement.enums = List.generate(count, (_) {
      return _readEnumElement(unitElement, unitReference);
    });
  }

  ExportElementImpl _readExportElement() {
    var element = ExportElementImpl(-1);
    element.uri = _reader.readOptionalStringReference();
    element.combinators = _reader.readTypedList(_readNamespaceCombinator);
    return element;
  }

  ExtensionElementImpl _readExtensionElement(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
    var name = _reader.readOptionalStringReference();
    var refName = _reader.readStringReference();
    var reference = unitReference.getChild('@extension').getChild(refName);

    var element = ExtensionElementImpl(name, -1);
    element.setLinkedData(
      reference,
      ExtensionElementLinkedData(
        reference: reference,
        libraryReader: this,
        unitElement: unitElement,
        offset: resolutionOffset,
      ),
    );

    element.typeParameters = _readTypeParameters();

    var accessors = <PropertyAccessorElement>[];
    var fields = <FieldElement>[];
    _readPropertyAccessors(
        unitElement, element, reference, accessors, fields, '@field');
    _readFields(unitElement, element, reference, accessors, fields);
    element.accessors = accessors;
    element.fields = fields;

    element.methods = _readMethods(unitElement, element, reference);

    return element;
  }

  void _readExtensions(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    var count = _reader.readUInt30();
    unitElement.extensions = List.generate(count, (_) {
      return _readExtensionElement(unitElement, unitReference);
    });
  }

  FeatureSet _readFeatureSet() {
    var featureSetEncoded = _reader.readUint8List();
    return ExperimentStatus.fromStorage(featureSetEncoded);
  }

  FieldElementImpl _readFieldElement(
    CompilationUnitElementImpl unitElement,
    ElementImpl classElement,
    Reference classReference,
    Reference containerRef,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
    var name = _reader.readStringReference();
    var isConstElement = _reader.readBool();
    var reference = containerRef.getChild(name);

    FieldElementImpl element;
    if (isConstElement) {
      element = ConstFieldElementImpl(name, -1);
    } else {
      element = FieldElementImpl(name, -1);
    }

    var linkedData = FieldElementLinkedData(
      reference: reference,
      libraryReader: this,
      unitElement: unitElement,
      offset: resolutionOffset,
    );
    element.setLinkedData(reference, linkedData);

    FieldElementFlags.read(_reader, element);
    element.typeInferenceError = _readTopLevelInferenceError();
    element.createImplicitAccessors(classReference, name);

    return element;
  }

  void _readFields(
    CompilationUnitElementImpl unitElement,
    ElementImpl classElement,
    Reference classReference,
    List<PropertyAccessorElement> accessors,
    List<FieldElement> variables,
  ) {
    var containerRef = classReference.getChild('@field');
    var createdElements = <FieldElement>[];
    var variableElementCount = _reader.readUInt30();
    for (var i = 0; i < variableElementCount; i++) {
      var variable = _readFieldElement(
          unitElement, classElement, classReference, containerRef);
      createdElements.add(variable);
      variables.add(variable);

      var getter = variable.getter;
      if (getter is PropertyAccessorElementImpl) {
        accessors.add(getter);
      }

      var setter = variable.setter;
      if (setter is PropertyAccessorElementImpl) {
        accessors.add(setter);
      }
    }
  }

  void _readFunctions(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    var count = _reader.readUInt30();
    unitElement.functions = List.generate(count, (_) {
      var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
      var name = _reader.readStringReference();
      var reference = unitReference.getChild('@function').getChild(name);

      var element = FunctionElementImpl(name, -1);

      var linkedData = FunctionElementLinkedData(
        reference: reference,
        libraryReader: this,
        unitElement: unitElement,
        offset: resolutionOffset,
      );
      element.setLinkedData(reference, linkedData);

      FunctionElementFlags.read(_reader, element);
      element.typeParameters = _readTypeParameters();
      element.parameters = _readParameters(element, reference);

      return element;
    });
  }

  ImportElementImpl _readImportElement() {
    var element = ImportElementImpl(-1);
    ImportElementFlags.read(_reader, element);
    element.uri = _reader.readOptionalStringReference();
    var prefixName = _reader.readOptionalStringReference();
    if (prefixName != null) {
      var reference = _reference.getChild('@prefix').getChild(prefixName);
      var prefixElement =
          PrefixElementImpl(prefixName, -1, reference: reference);
      element.prefix = prefixElement;
    }
    element.combinators = _reader.readTypedList(_readNamespaceCombinator);
    return element;
  }

  LibraryLanguageVersion _readLanguageVersion() {
    var packageMajor = _reader.readUInt30();
    var packageMinor = _reader.readUInt30();
    var package = Version(packageMajor, packageMinor, 0);

    Version? override;
    if (_reader.readBool()) {
      var overrideMajor = _reader.readUInt30();
      var overrideMinor = _reader.readUInt30();
      override = Version(overrideMajor, overrideMinor, 0);
    }

    return LibraryLanguageVersion(package: package, override: override);
  }

  List<MethodElementImpl> _readMethods(
    CompilationUnitElementImpl unitElement,
    ElementImpl enclosingElement,
    Reference enclosingReference,
  ) {
    var containerRef = enclosingReference.getChild('@method');
    var length = _reader.readUInt30();
    return List.generate(length, (_) {
      var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
      var name = _reader.readStringReference();
      var reference = containerRef.getChild(name);
      var element = MethodElementImpl(name, -1);
      var linkedData = MethodElementLinkedData(
        reference: reference,
        libraryReader: this,
        unitElement: unitElement,
        offset: resolutionOffset,
      );
      element.setLinkedData(reference, linkedData);
      MethodElementFlags.read(_reader, element);
      element.typeParameters = _readTypeParameters();
      element.parameters = _readParameters(element, reference);
      element.typeInferenceError = _readTopLevelInferenceError();
      return element;
    });
  }

  MixinElementImpl _readMixinElement(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
    var name = _reader.readStringReference();
    var reference = unitReference.getChild('@mixin').getChild(name);

    var element = MixinElementImpl(name, -1);

    var linkedData = MixinElementLinkedData(
      reference: reference,
      libraryReader: this,
      unitElement: unitElement,
      offset: resolutionOffset,
    );
    element.setLinkedData(reference, linkedData);

    element.typeParameters = _readTypeParameters();

    var fields = <FieldElement>[];
    var accessors = <PropertyAccessorElement>[];
    _readFields(unitElement, element, reference, accessors, fields);
    _readPropertyAccessors(
        unitElement, element, reference, accessors, fields, '@field');
    element.fields = fields;
    element.accessors = accessors;

    element.constructors = _readConstructors(unitElement, element, reference);
    element.methods = _readMethods(unitElement, element, reference);
    element.superInvokedNames = _reader.readStringReferenceList();

    return element;
  }

  void _readMixins(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    var length = _reader.readUInt30();
    unitElement.mixins = List.generate(length, (index) {
      return _readMixinElement(unitElement, unitReference);
    });
  }

  NamespaceCombinator _readNamespaceCombinator() {
    var tag = _reader.readByte();
    if (tag == Tag.HideCombinator) {
      var combinator = HideElementCombinatorImpl();
      combinator.hiddenNames = _reader.readStringReferenceList();
      return combinator;
    } else if (tag == Tag.ShowCombinator) {
      var combinator = ShowElementCombinatorImpl();
      combinator.shownNames = _reader.readStringReferenceList();
      return combinator;
    } else {
      throw UnimplementedError('tag: $tag');
    }
  }

  List<ParameterElementImpl> _readParameters(
    ElementImpl enclosingElement,
    Reference enclosingReference,
  ) {
    var containerRef = enclosingReference.getChild('@parameter');
    var length = _reader.readUInt30();
    return List.generate(length, (_) {
      var name = _reader.readStringReference();
      var isInitializingFormal = _reader.readBool();
      var reference = containerRef.getChild(name);

      var kindIndex = _reader.readByte();
      var kind = ResolutionReader._formalParameterKind(kindIndex);

      ParameterElementImpl element;
      if (kind.isRequiredPositional) {
        if (isInitializingFormal) {
          element = FieldFormalParameterElementImpl(
            name: name,
            nameOffset: -1,
            parameterKind: kind,
          );
        } else {
          element = ParameterElementImpl(
            name: name,
            nameOffset: -1,
            parameterKind: kind,
          );
        }
      } else {
        if (isInitializingFormal) {
          element = DefaultFieldFormalParameterElementImpl(
            name: name,
            nameOffset: -1,
            parameterKind: kind,
          );
        } else {
          element = DefaultParameterElementImpl(
            name: name,
            nameOffset: -1,
            parameterKind: kind,
          );
        }
        element.reference = reference;
        reference.element = element;
      }
      ParameterElementFlags.read(_reader, element);
      element.typeParameters = _readTypeParameters();
      element.parameters = _readParameters(element, reference);
      return element;
    });
  }

  PropertyAccessorElementImpl _readPropertyAccessorElement(
    CompilationUnitElementImpl unitElement,
    ElementImpl classElement,
    Reference classReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();

    var name = _reader.readStringReference();

    var element = PropertyAccessorElementImpl(name, -1);
    PropertyAccessorElementFlags.read(_reader, element);

    var reference = classReference
        .getChild(element.isGetter ? '@getter' : '@setter')
        .getChild(name);
    var linkedData = PropertyAccessorElementLinkedData(
      reference: reference,
      libraryReader: this,
      unitElement: unitElement,
      offset: resolutionOffset,
    );
    element.setLinkedData(reference, linkedData);

    element.parameters = _readParameters(element, reference);
    return element;
  }

  void _readPropertyAccessors(
    CompilationUnitElementImpl unitElement,
    ElementImpl enclosingElement,
    Reference enclosingReference,
    List<PropertyAccessorElement> accessors,
    List<PropertyInducingElement> properties,
    String containerRefName,
  ) {
    var containerRef = enclosingReference.getChild(containerRefName);

    var accessorCount = _reader.readUInt30();
    for (var i = 0; i < accessorCount; i++) {
      var accessor = _readPropertyAccessorElement(
        unitElement,
        enclosingElement,
        enclosingReference,
      );
      accessors.add(accessor);

      var name = accessor.displayName;
      var isGetter = accessor.isGetter;

      var reference = containerRef.getChild(name);

      PropertyInducingElementImpl property;
      if (enclosingElement is CompilationUnitElementImpl) {
        var existing = reference.element;
        if (existing is TopLevelVariableElementImpl) {
          property = existing;
        } else {
          var field = TopLevelVariableElementImpl(name, -1);
          property = field;
        }
      } else {
        var existing = reference.element;
        if (existing is FieldElementImpl) {
          property = existing;
        } else {
          var field = FieldElementImpl(name, -1);
          field.isStatic = accessor.isStatic;
          property = field;
        }
      }

      if (reference.element == null) {
        reference.element = property;
        properties.add(property);

        property.enclosingElement = enclosingElement;
        property.isSynthetic = true;
      }

      accessor.variable = property;
      if (isGetter) {
        property.getter = accessor;
      } else {
        property.setter = accessor;
        if (property.isSynthetic) {
          property.isFinal = false;
        }
      }
    }
  }

  TopLevelInferenceError? _readTopLevelInferenceError() {
    var kindIndex = _reader.readByte();
    var kind = TopLevelInferenceErrorKind.values[kindIndex];
    if (kind == TopLevelInferenceErrorKind.none) {
      return null;
    }
    return TopLevelInferenceError(
      kind: kind,
      arguments: _reader.readStringReferenceList(),
    );
  }

  TopLevelVariableElementImpl _readTopLevelVariableElement(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
    var name = _reader.readStringReference();
    var isConst = _reader.readBool();
    var reference = unitReference.getChild('@variable').getChild(name);

    TopLevelVariableElementImpl element;
    if (isConst) {
      element = ConstTopLevelVariableElementImpl(name, -1);
    } else {
      element = TopLevelVariableElementImpl(name, -1);
    }

    var linkedData = TopLevelVariableElementLinkedData(
      reference: reference,
      libraryReader: this,
      unitElement: unitElement,
      offset: resolutionOffset,
    );
    element.setLinkedData(reference, linkedData);

    element.isConst = isConst;
    TopLevelVariableElementFlags.read(_reader, element);
    element.typeInferenceError = _readTopLevelInferenceError();
    element.createImplicitAccessors(unitReference, name);

    return element;
  }

  void _readTopLevelVariables(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
    List<PropertyAccessorElementImpl> accessors,
    List<TopLevelVariableElementImpl> variables,
  ) {
    var variableElementCount = _reader.readUInt30();
    for (var i = 0; i < variableElementCount; i++) {
      var variable = _readTopLevelVariableElement(unitElement, unitReference);
      variables.add(variable);

      var getter = variable.getter;
      if (getter is PropertyAccessorElementImpl) {
        accessors.add(getter);
      }

      var setter = variable.setter;
      if (setter is PropertyAccessorElementImpl) {
        accessors.add(setter);
      }
    }
  }

  TypeAliasElementImpl _readTypeAliasElement(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
    var name = _reader.readStringReference();
    var reference = unitReference.getChild('@typeAlias').getChild(name);

    var isFunctionTypeAliasBased = _reader.readBool();

    TypeAliasElementImpl element;
    if (isFunctionTypeAliasBased) {
      element = TypeAliasElementImpl(name, -1);
      element.isFunctionTypeAliasBased = true;
    } else {
      element = TypeAliasElementImpl(name, -1);
    }

    var linkedData = TypeAliasElementLinkedData(
      reference: reference,
      libraryReader: this,
      unitElement: unitElement,
      offset: resolutionOffset,
    );
    element.setLinkedData(reference, linkedData);

    element.isFunctionTypeAliasBased = isFunctionTypeAliasBased;
    TypeAliasElementFlags.read(_reader, element);

    element.typeParameters = _readTypeParameters();

    return element;
  }

  void _readTypeAliases(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    var length = _reader.readUInt30();
    unitElement.typeAliases = List.generate(length, (_) {
      return _readTypeAliasElement(unitElement, unitReference);
    });
  }

  List<TypeParameterElementImpl> _readTypeParameters() {
    var length = _reader.readUInt30();
    return List.generate(length, (_) {
      var name = _reader.readStringReference();
      var varianceEncoding = _reader.readByte();
      var variance = _decodeVariance(varianceEncoding);
      var element = TypeParameterElementImpl(name, -1);
      element.variance = variance;
      return element;
    });
  }

  CompilationUnitElementImpl _readUnitElement({
    required SourceFactory sourceFactory,
    required Reference unitContainerRef,
    required LibraryElementImpl libraryElement,
    required Source librarySource,
  }) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
    var unitUriStr = _reader.readStringReference();
    var unitUri = Uri.parse(unitUriStr);
    var unitSource = sourceFactory.forUri2(unitUri)!;

    var unitElement = CompilationUnitElementImpl();
    unitElement.source = unitSource;
    unitElement.librarySource = librarySource;

    var unitReference = unitContainerRef.getChild(unitUriStr);
    unitElement.setLinkedData(
      unitReference,
      CompilationUnitElementLinkedData(
        reference: unitReference,
        libraryReader: this,
        unitElement: unitElement,
        offset: resolutionOffset,
      ),
    );

    unitElement.uri = _reader.readOptionalStringReference();
    unitElement.isSynthetic = _reader.readBool();

    _readClasses(unitElement, unitReference);
    _readEnums(unitElement, unitReference);
    _readExtensions(unitElement, unitReference);
    _readFunctions(unitElement, unitReference);
    _readMixins(unitElement, unitReference);
    _readTypeAliases(unitElement, unitReference);

    var accessors = <PropertyAccessorElementImpl>[];
    var variables = <TopLevelVariableElementImpl>[];
    _readTopLevelVariables(unitElement, unitReference, accessors, variables);
    _readPropertyAccessors(unitElement, unitElement, unitReference, accessors,
        variables, '@variable');
    unitElement.accessors = accessors;
    unitElement.topLevelVariables = variables;
    return unitElement;
  }

  static Variance? _decodeVariance(int index) {
    var tag = TypeParameterVarianceTag.values[index];
    switch (tag) {
      case TypeParameterVarianceTag.legacy:
        return null;
      case TypeParameterVarianceTag.unrelated:
        return Variance.unrelated;
      case TypeParameterVarianceTag.covariant:
        return Variance.covariant;
      case TypeParameterVarianceTag.contravariant:
        return Variance.contravariant;
      case TypeParameterVarianceTag.invariant:
        return Variance.invariant;
    }
  }
}

class MethodElementLinkedData extends ElementLinkedData<MethodElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  MethodElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _read(element, reader) {
    _addEnclosingElementTypeParameters(reader, element);
    element.metadata = reader._readAnnotationList(
      unitElement: unitElement,
    );
    _readTypeParameters(reader, element.typeParameters);
    _readFormalParameters(reader, element.parameters);
    element.returnType = reader.readRequiredType();
    applyConstantOffsets?.perform();
  }
}

class MixinElementLinkedData extends ElementLinkedData<MixinElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  MixinElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _read(element, reader) {
    element.metadata = reader._readAnnotationList(
      unitElement: element.enclosingElement,
    );
    _readTypeParameters(reader, element.typeParameters);
    element.superclassConstraints = reader._readInterfaceTypeList();
    element.interfaces = reader._readInterfaceTypeList();
    applyConstantOffsets?.perform();
  }
}

class PropertyAccessorElementLinkedData
    extends ElementLinkedData<PropertyAccessorElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  PropertyAccessorElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _read(element, reader) {
    _addEnclosingElementTypeParameters(reader, element);

    element.metadata = reader._readAnnotationList(
      unitElement: unitElement,
    );

    element.returnType = reader.readRequiredType();
    _readFormalParameters(reader, element.parameters);

    applyConstantOffsets?.perform();
  }
}

/// Helper for reading elements and types from their binary encoding.
class ResolutionReader {
  final LinkedElementFactory _elementFactory;
  final _ReferenceReader _referenceReader;
  final SummaryDataReader _reader;

  /// The stack of [TypeParameterElement]s and [ParameterElement] that are
  /// available in the scope of [readElement] and [readType].
  ///
  /// This stack is shared with the client of the reader, and update mostly
  /// by the client. However it is also updated during [_readFunctionType].
  final List<Element> _localElements = [];

  ResolutionReader(
    this._elementFactory,
    this._referenceReader,
    this._reader,
  );

  int readByte() {
    return _reader.readByte();
  }

  double readDouble() {
    return _reader.readDouble();
  }

  Element? readElement() {
    var memberFlags = _reader.readByte();
    var element = _readRawElement();

    if (element == null) {
      return null;
    }

    if (memberFlags == Tag.RawElement) {
      return element;
    }

    if (memberFlags == Tag.MemberLegacyWithTypeArguments ||
        memberFlags == Tag.MemberWithTypeArguments) {
      var arguments = _readTypeList();
      // TODO(scheglov) why to check for empty? If we have this flags.
      if (arguments.isNotEmpty) {
        var typeParameters =
            (element.enclosingElement as TypeParameterizedElement)
                .typeParameters;
        var substitution = Substitution.fromPairs(typeParameters, arguments);
        element =
            ExecutableMember.from2(element as ExecutableElement, substitution);
      }
    }

    if (memberFlags == Tag.MemberLegacyWithTypeArguments) {
      return Member.legacy(element);
    }

    if (memberFlags == Tag.MemberWithTypeArguments) {
      return element;
    }

    throw UnimplementedError('memberFlags: $memberFlags');
  }

  FunctionType? readOptionalFunctionType() {
    var type = readType();
    return type is FunctionType ? type : null;
  }

  List<DartType>? readOptionalTypeList() {
    if (_reader.readBool()) {
      return _readTypeList();
    }
  }

  DartType readRequiredType() {
    return readType()!;
  }

  String readStringReference() {
    return _reader.readStringReference();
  }

  List<String> readStringReferenceList() {
    return _reader.readStringReferenceList();
  }

  DartType? readType() {
    var tag = _reader.readByte();
    if (tag == Tag.NullType) {
      return null;
    } else if (tag == Tag.DynamicType) {
      var type = DynamicTypeImpl.instance;
      return _readAliasElementArguments(type);
    } else if (tag == Tag.FunctionType) {
      var type = _readFunctionType();
      return _readAliasElementArguments(type);
    } else if (tag == Tag.InterfaceType) {
      var element = readElement() as ClassElement;
      var typeArguments = _readTypeList();
      var nullability = _readNullability();
      var type = InterfaceTypeImpl(
        element: element,
        typeArguments: typeArguments,
        nullabilitySuffix: nullability,
      );
      return _readAliasElementArguments(type);
    } else if (tag == Tag.InterfaceType_noTypeArguments_none) {
      var element = readElement() as ClassElement;
      var type = InterfaceTypeImpl(
        element: element,
        typeArguments: const <DartType>[],
        nullabilitySuffix: NullabilitySuffix.none,
      );
      return _readAliasElementArguments(type);
    } else if (tag == Tag.InterfaceType_noTypeArguments_question) {
      var element = readElement() as ClassElement;
      var type = InterfaceTypeImpl(
        element: element,
        typeArguments: const <DartType>[],
        nullabilitySuffix: NullabilitySuffix.question,
      );
      return _readAliasElementArguments(type);
    } else if (tag == Tag.InterfaceType_noTypeArguments_star) {
      var element = readElement() as ClassElement;
      var type = InterfaceTypeImpl(
        element: element,
        typeArguments: const <DartType>[],
        nullabilitySuffix: NullabilitySuffix.star,
      );
      return _readAliasElementArguments(type);
    } else if (tag == Tag.NeverType) {
      var nullability = _readNullability();
      var type = NeverTypeImpl.instance.withNullability(nullability);
      return _readAliasElementArguments(type);
    } else if (tag == Tag.TypeParameterType) {
      var element = readElement() as TypeParameterElement;
      var nullability = _readNullability();
      var type = TypeParameterTypeImpl(
        element: element,
        nullabilitySuffix: nullability,
      );
      return _readAliasElementArguments(type);
    } else if (tag == Tag.VoidType) {
      var type = VoidTypeImpl.instance;
      return _readAliasElementArguments(type);
    } else {
      throw UnimplementedError('$tag');
    }
  }

  List<T> readTypedList<T>(T Function() read) {
    var length = readUInt30();
    return List<T>.generate(length, (_) {
      return read();
    });
  }

  int readUInt30() {
    return _reader.readUInt30();
  }

  int readUInt32() {
    return _reader.readUInt32();
  }

  void _addFormalParameters(List<ParameterElement> parameters) {
    for (var parameter in parameters) {
      _localElements.add(parameter);
    }
  }

  void _addTypeParameters(List<TypeParameterElement> typeParameters) {
    for (var typeParameter in typeParameters) {
      _localElements.add(typeParameter);
    }
  }

  ElementImpl? _readAliasedElement(CompilationUnitElementImpl unitElement) {
    var tag = _reader.readByte();
    if (tag == AliasedElementTag.nothing) {
      return null;
    } else if (tag == AliasedElementTag.genericFunctionElement) {
      var typeParameters = _readTypeParameters(unitElement);
      var formalParameters = _readFormalParameters(unitElement);
      var returnType = readRequiredType();

      _localElements.length -= typeParameters.length;

      return GenericFunctionTypeElementImpl.forOffset(-1)
        ..typeParameters = typeParameters
        ..parameters = formalParameters
        ..returnType = returnType;
    } else {
      throw UnimplementedError('tag: $tag');
    }
  }

  DartType _readAliasElementArguments(DartType type) {
    var aliasElement = _readRawElement();
    if (aliasElement is TypeAliasElement) {
      var aliasArguments = _readTypeList();
      if (type is DynamicType) {
        // TODO(scheglov) add support for `dynamic` aliasing
        return type;
      } else if (type is FunctionType) {
        return FunctionTypeImpl(
          typeFormals: type.typeFormals,
          parameters: type.parameters,
          returnType: type.returnType,
          nullabilitySuffix: type.nullabilitySuffix,
          alias: InstantiatedTypeAliasElementImpl(
            element: aliasElement,
            typeArguments: aliasArguments,
          ),
        );
      } else if (type is InterfaceType) {
        return InterfaceTypeImpl(
          element: type.element,
          typeArguments: type.typeArguments,
          nullabilitySuffix: type.nullabilitySuffix,
          alias: InstantiatedTypeAliasElementImpl(
            element: aliasElement,
            typeArguments: aliasArguments,
          ),
        );
      } else if (type is TypeParameterType) {
        return TypeParameterTypeImpl(
          element: type.element,
          nullabilitySuffix: type.nullabilitySuffix,
          alias: InstantiatedTypeAliasElementImpl(
            element: aliasElement,
            typeArguments: aliasArguments,
          ),
        );
      } else if (type is VoidType) {
        // TODO(scheglov) add support for `void` aliasing
        return type;
      } else {
        throw UnimplementedError('${type.runtimeType}');
      }
    }
    return type;
  }

  List<ElementAnnotationImpl> _readAnnotationList({
    required CompilationUnitElementImpl unitElement,
  }) {
    var length = _reader.readUInt30();
    if (length == 0) {
      return const <ElementAnnotationImpl>[];
    }
    return List.generate(length, (_) {
      var ast = _readRequiredNode() as Annotation;
      return ElementAnnotationImpl(unitElement)
        ..annotationAst = ast
        ..element = ast.element;
    });
  }

  List<ParameterElementImpl> _readFormalParameters(
    CompilationUnitElementImpl? unitElement,
  ) {
    var formalParameterCount = _reader.readUInt30();
    return List.generate(formalParameterCount, (_) {
      var kindIndex = _reader.readByte();
      var kind = _formalParameterKind(kindIndex);
      var hasImplicitType = _reader.readBool();
      var isInitializingFormal = _reader.readBool();
      var typeParameters = _readTypeParameters(unitElement);
      var type = readRequiredType();
      var name = readStringReference();
      if (kind.isRequiredPositional) {
        ParameterElementImpl element;
        if (isInitializingFormal) {
          element = FieldFormalParameterElementImpl(
            name: name,
            nameOffset: -1,
            parameterKind: kind,
          )..type = type;
        } else {
          element = ParameterElementImpl(
            name: name,
            nameOffset: -1,
            parameterKind: kind,
          )..type = type;
        }
        element.hasImplicitType = hasImplicitType;
        element.typeParameters = typeParameters;
        element.parameters = _readFormalParameters(unitElement);
        // TODO(scheglov) reuse for formal parameters
        _localElements.length -= typeParameters.length;
        if (unitElement != null) {
          element.metadata = _readAnnotationList(unitElement: unitElement);
        }
        return element;
      } else {
        var element = DefaultParameterElementImpl(
          name: name,
          nameOffset: -1,
          parameterKind: kind,
        )..type = type;
        element.hasImplicitType = hasImplicitType;
        element.typeParameters = typeParameters;
        element.parameters = _readFormalParameters(unitElement);
        // TODO(scheglov) reuse for formal parameters
        _localElements.length -= typeParameters.length;
        if (unitElement != null) {
          element.metadata = _readAnnotationList(unitElement: unitElement);
        }
        return element;
      }
    });
  }

  /// TODO(scheglov) Optimize for write/read of types without type parameters.
  FunctionType _readFunctionType() {
    // TODO(scheglov) reuse for formal parameters
    var typeParameters = _readTypeParameters(null);
    var returnType = readRequiredType();
    var formalParameters = _readFormalParameters(null);

    var nullability = _readNullability();

    _localElements.length -= typeParameters.length;

    return FunctionTypeImpl(
      typeFormals: typeParameters,
      parameters: formalParameters,
      returnType: returnType,
      nullabilitySuffix: nullability,
    );
  }

  InterfaceType _readInterfaceType() {
    return readType() as InterfaceType;
  }

  List<InterfaceType> _readInterfaceTypeList() {
    var length = _reader.readUInt30();
    if (length == 0) {
      return const <InterfaceType>[];
    }
    return List.generate(length, (_) => _readInterfaceType());
  }

  List<T> _readNodeList<T>() {
    var length = _reader.readUInt30();
    return List<T>.generate(length, (_) {
      return _readRequiredNode() as T;
    });
  }

  NullabilitySuffix _readNullability() {
    var index = _reader.readByte();
    return NullabilitySuffix.values[index];
  }

  ExpressionImpl? _readOptionalExpression() {
    if (_reader.readBool()) {
      return _readRequiredNode() as ExpressionImpl;
    }
  }

  InterfaceType? _readOptionalInterfaceType() {
    return readType() as InterfaceType?;
  }

  Element? _readRawElement() {
    var index = _reader.readUInt30();

    if ((index & 0x1) == 0x1) {
      return _localElements[index >> 1];
    }

    var referenceIndex = index >> 1;
    var reference = _referenceReader.referenceOfIndex(referenceIndex);

    return _elementFactory.elementOfReference(reference);
  }

  AstNode _readRequiredNode() {
    var astReader = AstBinaryReader(reader: this);
    return astReader.readNode();
  }

  List<DartType> _readTypeList() {
    var types = <DartType>[];
    var length = _reader.readUInt30();
    for (var i = 0; i < length; i++) {
      var argument = readType()!;
      types.add(argument);
    }
    return types;
  }

  List<TypeParameterElementImpl> _readTypeParameters(
    CompilationUnitElementImpl? unitElement,
  ) {
    var typeParameterCount = _reader.readUInt30();
    var typeParameters = List.generate(typeParameterCount, (_) {
      var name = readStringReference();
      var typeParameter = TypeParameterElementImpl(name, -1);
      _localElements.add(typeParameter);
      return typeParameter;
    });

    for (var typeParameter in typeParameters) {
      typeParameter.bound = readType();
      if (unitElement != null) {
        typeParameter.metadata = _readAnnotationList(unitElement: unitElement);
      }
    }
    return typeParameters;
  }

  static ParameterKind _formalParameterKind(int encoding) {
    if (encoding == Tag.ParameterKindRequiredPositional) {
      return ParameterKind.REQUIRED;
    } else if (encoding == Tag.ParameterKindOptionalPositional) {
      return ParameterKind.POSITIONAL;
    } else if (encoding == Tag.ParameterKindRequiredNamed) {
      return ParameterKind.NAMED_REQUIRED;
    } else if (encoding == Tag.ParameterKindOptionalNamed) {
      return ParameterKind.NAMED;
    } else {
      throw StateError('Unexpected parameter kind encoding: $encoding');
    }
  }
}

class TopLevelVariableElementLinkedData
    extends ElementLinkedData<TopLevelVariableElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  TopLevelVariableElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _read(element, reader) {
    element.metadata = reader._readAnnotationList(
      unitElement: unitElement,
    );
    element.type = reader.readRequiredType();
    if (element is ConstTopLevelVariableElementImpl) {
      var initializer = reader._readOptionalExpression();
      if (initializer != null) {
        element.constantInitializer = initializer;
        ConstantContextForExpressionImpl(initializer);
      }
    }
    applyConstantOffsets?.perform();
  }
}

class TypeAliasElementLinkedData
    extends ElementLinkedData<TypeAliasElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  TypeAliasElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _read(element, reader) {
    element.metadata = reader._readAnnotationList(
      unitElement: unitElement,
    );
    _readTypeParameters(reader, element.typeParameters);
    element.aliasedElement = reader._readAliasedElement(unitElement);
    element.aliasedType = reader.readRequiredType();
    applyConstantOffsets?.perform();
  }
}

/// Information that we need to know about each library before reading it,
/// and without reading it.
///
/// Specifically, the [offset] allows us to know the location of each library,
/// so that when we need to read this library, we know where it starts without
/// reading previous libraries.
class _LibraryHeader {
  final String uriStr;
  final int offset;

  /// We don't read class members when reading libraries, by performance
  /// reasons - in many cases only some classes of a library are used. But
  /// we need to know how much data to skip for each class.
  final Uint32List classMembersLengths;

  _LibraryHeader({
    required this.uriStr,
    required this.offset,
    required this.classMembersLengths,
  });
}

class _ReferenceReader {
  final LinkedElementFactory elementFactory;
  final SummaryDataReader _reader;
  late final Uint32List _parents;
  late final Uint32List _names;
  late final List<Reference?> _references;

  _ReferenceReader(this.elementFactory, this._reader, int offset) {
    _reader.offset = offset;
    _parents = _reader.readUInt30List();
    _names = _reader.readUInt30List();
    assert(_parents.length == _names.length);

    _references = List.filled(_names.length, null);
  }

  Reference referenceOfIndex(int index) {
    var reference = _references[index];
    if (reference != null) {
      return reference;
    }

    if (index == 0) {
      reference = elementFactory.rootReference;
      _references[index] = reference;
      return reference;
    }

    var nameIndex = _names[index];
    var name = _reader.stringOfIndex(nameIndex);

    var parentIndex = _parents[index];
    var parent = referenceOfIndex(parentIndex);

    reference = parent.getChild(name);
    _references[index] = reference;

    return reference;
  }
}
