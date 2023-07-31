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
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/summary2/informative_data.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/macro_application_error.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/task/inference_error.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';
import 'package:pub_semver/pub_semver.dart';

class BundleReader {
  final SummaryDataReader _reader;
  final Map<Uri, Uint8List> _unitsInformativeBytes;

  final Map<Uri, LibraryReader> libraryMap = {};

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
        uri: uriCache.parse(_reader.readStringReference()),
        offset: _reader.readUInt30(),
        classMembersLengths: _reader.readUInt30List(),
      );
    });

    for (var libraryHeader in libraryHeaderList) {
      var uri = libraryHeader.uri;
      var reference = elementFactory.rootReference.getChild('$uri');
      libraryMap[uri] = LibraryReader._(
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
  void readMembers(ClassOrMixinElementImpl element) {
    if (element is ClassElementImpl && element.isMixinApplication) {
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
  CompilationUnitElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _read(element, reader) {}
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
    element.superConstructor = reader.readElement() as ConstructorElement?;
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
      return;
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
    if (enclosing is InterfaceElement) {
      reader._addTypeParameters(enclosing.typeParameters);
    } else if (enclosing is CompilationUnitElement) {
      // Nothing.
    } else if (enclosing is EnumElement) {
      reader._addTypeParameters(enclosing.typeParameters);
    } else if (enclosing is ExtensionElement) {
      reader._addTypeParameters(enclosing.typeParameters);
    } else if (enclosing is MixinElement) {
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
    element.metadata = reader._readAnnotationList(
      unitElement: element.enclosingElement,
    );
    _readTypeParameters(reader, element.typeParameters);
    element.supertype = reader._readOptionalInterfaceType();
    element.mixins = reader._readInterfaceTypeList();
    element.interfaces = reader._readInterfaceTypeList();
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
        ConstantContextForExpressionImpl(element, initializer);
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

/// Not an [ElementLinkedData], just a bundle with data.
class LibraryAugmentationElementLinkedData {
  final int offset;
  ApplyConstantOffsets? applyConstantOffsets;

  LibraryAugmentationElementLinkedData({
    required this.offset,
  });
}

class LibraryElementLinkedData extends ElementLinkedData<LibraryElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  /// When we are applying offsets to a library, we want to lock it.
  bool _isLocked = false;

  LibraryElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  LinkedElementFactory get elementFactory {
    return _libraryReader._elementFactory;
  }

  void lock() {
    assert(!_isLocked);
    _isLocked = true;
  }

  @override
  void read(ElementImpl element) {
    if (!_isLocked) {
      super.read(element);
    }
  }

  void unlock() {
    assert(_isLocked);
    _isLocked = false;
  }

  @override
  void _read(element, reader) {
    _readLibraryOrAugmentation(element, reader);
    for (final part in element.parts) {
      part.metadata = reader._readAnnotationList(
        unitElement: unitElement,
      );
    }

    element.entryPoint = reader.readElement() as FunctionElement?;

    applyConstantOffsets?.perform();
  }

  void _readLibraryOrAugmentation(
    LibraryOrAugmentationElementImpl element,
    ResolutionReader reader,
  ) {
    element.metadata = reader._readAnnotationList(
      unitElement: unitElement,
    );

    for (var import in element.libraryImports) {
      import.metadata = reader._readAnnotationList(
        unitElement: unitElement,
      );
      final uri = import.uri;
      if (uri is DirectiveUriWithLibraryImpl) {
        uri.library = reader.libraryOfUri(uri.source.uri);
      }
    }

    for (var export in element.libraryExports) {
      export.metadata = reader._readAnnotationList(
        unitElement: unitElement,
      );
      final uri = export.uri;
      if (uri is DirectiveUriWithLibraryImpl) {
        uri.library = reader.libraryOfUri(uri.source.uri);
      }
    }

    for (var import in element.augmentationImports) {
      import.metadata = reader._readAnnotationList(
        // TODO(scheglov) Here and for parts, unit is not valid. Test and fix.
        unitElement: unitElement,
      );
      final importedAugmentation = import.importedAugmentation;
      if (importedAugmentation != null) {
        final linkedData = importedAugmentation.linkedData!;
        reader.setOffset(linkedData.offset);
        _readLibraryOrAugmentation(importedAugmentation, reader);
        linkedData.applyConstantOffsets?.perform();
      }
    }
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

    _reader.offset = _offset;
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();

    var name = _reader.readStringReference();
    var featureSet = _readFeatureSet();

    var libraryElement = LibraryElementImpl(
        analysisContext, analysisSession, name, -1, 0, featureSet);
    _reference.element = libraryElement;
    libraryElement.reference = _reference;

    libraryElement.languageVersion = _readLanguageVersion();
    _readLibraryOrAugmentationElement(libraryElement);
    LibraryElementFlags.read(_reader, libraryElement);

    libraryElement.definingCompilationUnit = _readUnitElement(
      containerSource: librarySource,
      unitSource: librarySource,
      unitContainerRef: _reference.getChild('@unit'),
    );

    libraryElement.parts = _reader.readTypedList(() {
      return _readPartElement(
        libraryElement: libraryElement,
      );
    });

    libraryElement.exportedReferences = _reader.readTypedList(
      _readExportedReference,
    );

    libraryElement.linkedData = LibraryElementLinkedData(
      reference: _reference,
      libraryReader: this,
      unitElement: libraryElement.definingCompilationUnit,
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

  LibraryAugmentationElementImpl _readAugmentationElement({
    required LibraryOrAugmentationElementImpl augmentationTarget,
    required Source unitSource,
  }) {
    final definingUnit = _readUnitElement(
      containerSource: unitSource,
      unitSource: unitSource,
      unitContainerRef: _reference.getChild('@augmentation'),
    );

    final augmentation = LibraryAugmentationElementImpl(
      augmentationTarget: augmentationTarget,
      nameOffset: -1, // TODO(scheglov) implement, test
    );
    augmentation.definingCompilationUnit = definingUnit;
    augmentation.reference = definingUnit.reference!;

    final resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
    _readLibraryOrAugmentationElement(augmentation);

    augmentation.linkedData = LibraryAugmentationElementLinkedData(
      offset: resolutionOffset,
    );

    return augmentation;
  }

  AugmentationImportElementImpl _readAugmentationImportElement({
    required LibraryOrAugmentationElementImpl container,
  }) {
    final uri = _readDirectiveUri(
      container: container,
    );
    return AugmentationImportElementImpl(
      importKeywordOffset: -1, // TODO(scheglov) implement, test
      uri: uri,
    );
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
    element.macroApplicationErrors = _reader.readTypedList(
      () => MacroApplicationError(_reader),
    );

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
    var fields = <FieldElementImpl>[];
    _readFields(unitElement, element, reference, accessors, fields);
    _readPropertyAccessors(
        unitElement, element, reference, accessors, fields, '@field');
    element.fields = fields.toFixedList();
    element.accessors = accessors.toFixedList();

    element.constructors = _readConstructors(unitElement, element, reference);
    element.methods = _readMethods(unitElement, element, reference);
  }

  void _readClasses(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    unitElement.classes = _reader.readTypedList(() {
      return _readClassElement(unitElement, unitReference);
    });
  }

  List<ConstructorElementImpl> _readConstructors(
    CompilationUnitElementImpl unitElement,
    AbstractClassElementImpl classElement,
    Reference classReference,
  ) {
    var containerRef = classReference.getChild('@constructor');
    return _reader.readTypedList(() {
      var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
      var name = _reader.readStringReference();
      var referenceName = name.ifNotEmptyOrElse('new');
      var reference = containerRef.getChild(referenceName);
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

  DirectiveUri _readDirectiveUri({
    required LibraryOrAugmentationElementImpl container,
  }) {
    DirectiveUriWithRelativeUriStringImpl readWithRelativeUriString() {
      final relativeUriString = _reader.readStringReference();
      return DirectiveUriWithRelativeUriStringImpl(
        relativeUriString: relativeUriString,
      );
    }

    DirectiveUriWithRelativeUriImpl readWithRelativeUri() {
      final parent = readWithRelativeUriString();
      final relativeUri = uriCache.parse(_reader.readStringReference());
      return DirectiveUriWithRelativeUriImpl(
        relativeUriString: parent.relativeUriString,
        relativeUri: relativeUri,
      );
    }

    DirectiveUriWithSourceImpl readWithSource() {
      final parent = readWithRelativeUri();

      final analysisContext = _elementFactory.analysisContext;
      final sourceFactory = analysisContext.sourceFactory;

      final sourceUriStr = _reader.readStringReference();
      final sourceUri = uriCache.parse(sourceUriStr);
      final source = sourceFactory.forUri2(sourceUri);

      // TODO(scheglov) https://github.com/dart-lang/sdk/issues/49431
      final fixedSource = source ?? sourceFactory.forUri('dart:math')!;

      return DirectiveUriWithSourceImpl(
        relativeUriString: parent.relativeUriString,
        relativeUri: parent.relativeUri,
        source: fixedSource,
      );
    }

    final kindIndex = _reader.readByte();
    final kind = DirectiveUriKind.values[kindIndex];
    switch (kind) {
      case DirectiveUriKind.withAugmentation:
        final parent = readWithSource();
        final augmentation = _readAugmentationElement(
          augmentationTarget: container,
          unitSource: parent.source,
        );
        return DirectiveUriWithAugmentationImpl(
          relativeUriString: parent.relativeUriString,
          relativeUri: parent.relativeUri,
          source: parent.source,
          augmentation: augmentation,
        );
      case DirectiveUriKind.withLibrary:
        final parent = readWithSource();
        return DirectiveUriWithLibraryImpl.read(
          relativeUriString: parent.relativeUriString,
          relativeUri: parent.relativeUri,
          source: parent.source,
        );
      case DirectiveUriKind.withUnit:
        final parent = readWithSource();
        final unitElement = _readUnitElement(
          containerSource: container.source,
          unitSource: parent.source,
          unitContainerRef: _reference.getChild('@unit'),
        );
        return DirectiveUriWithUnitImpl(
          relativeUriString: parent.relativeUriString,
          relativeUri: parent.relativeUri,
          unit: unitElement,
        );
      case DirectiveUriKind.withSource:
        return readWithSource();
      case DirectiveUriKind.withRelativeUri:
        return readWithRelativeUri();
      case DirectiveUriKind.withRelativeUriString:
        return readWithRelativeUriString();
      case DirectiveUriKind.withNothing:
        return DirectiveUriImpl();
    }
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
    EnumElementFlags.read(_reader, element);

    element.typeParameters = _readTypeParameters();

    var accessors = <PropertyAccessorElementImpl>[];
    var fields = <FieldElementImpl>[];

    _readFields(unitElement, element, reference, accessors, fields);
    _readPropertyAccessors(
        unitElement, element, reference, accessors, fields, '@field');
    element.fields = fields.toFixedList();
    element.accessors = accessors.toFixedList();

    element.constructors = _readConstructors(unitElement, element, reference);
    element.methods = _readMethods(unitElement, element, reference);

    return element;
  }

  void _readEnums(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    unitElement.enums = _reader.readTypedList(() {
      return _readEnumElement(unitElement, unitReference);
    });
  }

  ExportedReference _readExportedReference() {
    final kind = _reader.readByte();
    if (kind == 0) {
      final index = _reader.readUInt30();
      final reference = _referenceReader.referenceOfIndex(index);
      return ExportedReferenceDeclared(
        reference: reference,
      );
    } else if (kind == 1) {
      final index = _reader.readUInt30();
      final reference = _referenceReader.referenceOfIndex(index);
      return ExportedReferenceExported(
        reference: reference,
        locations: _reader.readTypedList(_readExportLocation),
      );
    } else {
      throw StateError('kind: $kind');
    }
  }

  LibraryExportElementImpl _readExportElement({
    required LibraryOrAugmentationElementImpl container,
  }) {
    return LibraryExportElementImpl(
      combinators: _reader.readTypedList(_readNamespaceCombinator),
      exportKeywordOffset: -1,
      uri: _readDirectiveUri(
        container: container,
      ),
    );
  }

  ExportLocation _readExportLocation() {
    return ExportLocation(
      containerIndex: _reader.readUInt30(),
      exportIndex: _reader.readUInt30(),
    );
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

    var accessors = <PropertyAccessorElementImpl>[];
    var fields = <FieldElementImpl>[];
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
    unitElement.extensions = _reader.readTypedList(() {
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
    unitElement.functions = _reader.readTypedList(() {
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

  LibraryImportElementImpl _readImportElement({
    required LibraryOrAugmentationElementImpl container,
  }) {
    final element = LibraryImportElementImpl(
      combinators: _reader.readTypedList(_readNamespaceCombinator),
      importKeywordOffset: -1,
      prefix: _readImportElementPrefix(
        container: container,
      ),
      uri: _readDirectiveUri(
        container: container,
      ),
    );
    LibraryImportElementFlags.read(_reader, element);
    return element;
  }

  ImportElementPrefixImpl? _readImportElementPrefix({
    required LibraryOrAugmentationElementImpl container,
  }) {
    PrefixElementImpl buildElement(String name) {
      // TODO(scheglov) Make reference required.
      final containerRef = container.reference!;
      final reference = containerRef.getChild('@prefix').getChild(name);
      final existing = reference.element;
      if (existing is PrefixElementImpl) {
        return existing;
      } else {
        return PrefixElementImpl(name, -1, reference: reference);
      }
    }

    final kindIndex = _reader.readByte();
    final kind = ImportElementPrefixKind.values[kindIndex];
    switch (kind) {
      case ImportElementPrefixKind.isDeferred:
        final name = _reader.readStringReference();
        return DeferredImportElementPrefixImpl(
          element: buildElement(name),
        );
      case ImportElementPrefixKind.isNotDeferred:
        final name = _reader.readStringReference();
        return ImportElementPrefixImpl(
          element: buildElement(name),
        );
      case ImportElementPrefixKind.isNull:
        return null;
    }
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

  void _readLibraryOrAugmentationElement(
    LibraryOrAugmentationElementImpl container,
  ) {
    container.libraryImports = _reader.readTypedList(() {
      return _readImportElement(
        container: container,
      );
    });

    container.libraryExports = _reader.readTypedList(() {
      return _readExportElement(
        container: container,
      );
    });

    container.augmentationImports = _reader.readTypedList(() {
      return _readAugmentationImportElement(
        container: container,
      );
    });

    for (final import in container.libraryImports) {
      final prefixElement = import.prefix?.element;
      if (prefixElement is PrefixElementImpl) {
        container.encloseElement(prefixElement);
      }
    }
  }

  List<MethodElementImpl> _readMethods(
    CompilationUnitElementImpl unitElement,
    ElementImpl enclosingElement,
    Reference enclosingReference,
  ) {
    var containerRef = enclosingReference.getChild('@method');
    return _reader.readTypedList(() {
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
    MixinElementFlags.read(_reader, element);

    element.typeParameters = _readTypeParameters();

    var fields = <FieldElementImpl>[];
    var accessors = <PropertyAccessorElementImpl>[];
    _readFields(unitElement, element, reference, accessors, fields);
    _readPropertyAccessors(
        unitElement, element, reference, accessors, fields, '@field');
    element.fields = fields.toFixedList();
    element.accessors = accessors.toFixedList();

    element.constructors = _readConstructors(unitElement, element, reference);
    element.methods = _readMethods(unitElement, element, reference);
    element.superInvokedNames = _reader.readStringReferenceList();

    return element;
  }

  void _readMixins(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    unitElement.mixins = _reader.readTypedList(() {
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
    return _reader.readTypedList(() {
      var name = _reader.readStringReference();
      var isInitializingFormal = _reader.readBool();
      var isSuperFormal = _reader.readBool();
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
        } else if (isSuperFormal) {
          element = SuperFormalParameterElementImpl(
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
        } else if (isSuperFormal) {
          element = DefaultSuperFormalParameterElementImpl(
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

  PartElementImpl _readPartElement({
    required LibraryElementImpl libraryElement,
  }) {
    final uri = _readDirectiveUri(
      container: libraryElement,
    );

    return PartElementImpl(
      uri: uri,
    );
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

      bool canUseExisting(PropertyInducingElement property) {
        return property.isSynthetic ||
            accessor.isSetter && property.setter == null;
      }

      final PropertyInducingElementImpl property;
      final reference = containerRef.getChild(name);
      final existing = reference.element;
      if (enclosingElement is CompilationUnitElementImpl) {
        if (existing is TopLevelVariableElementImpl &&
            canUseExisting(existing)) {
          property = existing;
        } else {
          property = TopLevelVariableElementImpl(name, -1)
            ..enclosingElement = enclosingElement
            ..isSynthetic = true;
          reference.element ??= property;
          properties.add(property);
        }
      } else {
        if (existing is FieldElementImpl && canUseExisting(existing)) {
          property = existing;
        } else {
          property = FieldElementImpl(name, -1)
            ..enclosingElement = enclosingElement
            ..isStatic = accessor.isStatic
            ..isSynthetic = true;
          reference.element ??= property;
          properties.add(property);
        }
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
    unitElement.typeAliases = _reader.readTypedList(() {
      return _readTypeAliasElement(unitElement, unitReference);
    });
  }

  List<TypeParameterElementImpl> _readTypeParameters() {
    return _reader.readTypedList(() {
      var name = _reader.readStringReference();
      var varianceEncoding = _reader.readByte();
      var variance = _decodeVariance(varianceEncoding);
      var element = TypeParameterElementImpl(name, -1);
      element.variance = variance;
      return element;
    });
  }

  CompilationUnitElementImpl _readUnitElement({
    required Source containerSource,
    required Source unitSource,
    required Reference unitContainerRef,
  }) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();

    var unitElement = CompilationUnitElementImpl(
      source: unitSource,
      librarySource: containerSource,
      lineInfo: LineInfo([0]),
    );

    final unitReference = unitContainerRef.getChild('${unitSource.uri}');
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
    unitElement.accessors = accessors.toFixedList();
    unitElement.topLevelVariables = variables.toFixedList();
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

  LibraryElementImpl libraryOfUri(Uri uri) {
    return _elementFactory.libraryOfUri2(uri);
  }

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
      element as ExecutableElement;
      var enclosing = element.enclosingElement as TypeParameterizedElement;
      var typeParameters = enclosing.typeParameters;
      var typeArguments = _readTypeList();
      var substitution = Substitution.fromPairs(typeParameters, typeArguments);
      element = ExecutableMember.from2(element, substitution);
    }

    if (memberFlags == Tag.MemberLegacyWithoutTypeArguments ||
        memberFlags == Tag.MemberLegacyWithTypeArguments) {
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
    } else {
      return null;
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
      var element = readElement() as InterfaceElement;
      var typeArguments = _readTypeList();
      var nullability = _readNullability();
      var type = InterfaceTypeImpl(
        element: element,
        typeArguments: typeArguments,
        nullabilitySuffix: nullability,
      );
      return _readAliasElementArguments(type);
    } else if (tag == Tag.InterfaceType_noTypeArguments_none) {
      var element = readElement() as InterfaceElement;
      var type = InterfaceTypeImpl(
        element: element,
        typeArguments: const <DartType>[],
        nullabilitySuffix: NullabilitySuffix.none,
      );
      return _readAliasElementArguments(type);
    } else if (tag == Tag.InterfaceType_noTypeArguments_question) {
      var element = readElement() as InterfaceElement;
      var type = InterfaceTypeImpl(
        element: element,
        typeArguments: const <DartType>[],
        nullabilitySuffix: NullabilitySuffix.question,
      );
      return _readAliasElementArguments(type);
    } else if (tag == Tag.InterfaceType_noTypeArguments_star) {
      var element = readElement() as InterfaceElement;
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
    } else if (tag == Tag.RecordType) {
      final type = _readRecordType();
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
    return _reader.readTypedList(read);
  }

  int readUInt30() {
    return _reader.readUInt30();
  }

  int readUInt32() {
    return _reader.readUInt32();
  }

  void setOffset(int offset) {
    _reader.offset = offset;
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
      } else if (type is RecordTypeImpl) {
        return RecordTypeImpl(
          positionalFields: type.positionalFields,
          namedFields: type.namedFields,
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
    return readTypedList(() {
      var ast = _readRequiredNode() as Annotation;
      return ElementAnnotationImpl(unitElement)
        ..annotationAst = ast
        ..element = ast.element;
    });
  }

  List<ParameterElementImpl> _readFormalParameters(
    CompilationUnitElementImpl? unitElement,
  ) {
    return readTypedList(() {
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
    return readTypedList(_readInterfaceType);
  }

  List<T> _readNodeList<T>() {
    return readTypedList(() {
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
    } else {
      return null;
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

  RecordTypeImpl _readRecordType() {
    final positionalFields = readTypedList(() {
      return RecordTypePositionalFieldImpl(
        type: readRequiredType(),
      );
    });

    final namedFields = readTypedList(() {
      return RecordTypeNamedFieldImpl(
        name: _reader.readStringReference(),
        type: readRequiredType(),
      );
    });

    final nullabilitySuffix = _readNullability();

    return RecordTypeImpl(
      positionalFields: positionalFields,
      namedFields: namedFields,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  AstNode _readRequiredNode() {
    var astReader = AstBinaryReader(reader: this);
    return astReader.readNode();
  }

  List<DartType> _readTypeList() {
    return readTypedList(() {
      return readRequiredType();
    });
  }

  List<TypeParameterElementImpl> _readTypeParameters(
    CompilationUnitElementImpl? unitElement,
  ) {
    var typeParameters = readTypedList(() {
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
        ConstantContextForExpressionImpl(element, initializer);
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
  final Uri uri;
  final int offset;

  /// We don't read class members when reading libraries, by performance
  /// reasons - in many cases only some classes of a library are used. But
  /// we need to know how much data to skip for each class.
  final Uint32List classMembersLengths;

  _LibraryHeader({
    required this.uri,
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
