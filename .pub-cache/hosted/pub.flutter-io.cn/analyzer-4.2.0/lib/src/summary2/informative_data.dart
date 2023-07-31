// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/util/collection.dart';
import 'package:analyzer/src/util/comment.dart';
import 'package:collection/collection.dart';

Uint8List writeUnitInformative(CompilationUnit unit) {
  var byteSink = ByteSink();
  var sink = BufferedSink(byteSink);
  _InformativeDataWriter(sink).write(unit);
  return sink.flushAndTake();
}

/// We want to have actual offsets for tokens of various constants in the
/// element model, such as metadata and constant initializers. But we read
/// these additional pieces of resolution data later, on demand. So, these
/// offsets are different from `nameOffset` for example, which are applied
/// directly after creating corresponding elements during a library loading.
class ApplyConstantOffsets {
  Uint32List? _offsets;
  void Function(_OffsetsApplier)? _function;

  ApplyConstantOffsets(this._offsets, this._function);

  void perform() {
    var offsets = _offsets;
    var function = _function;
    if (offsets != null && function != null) {
      var applier = _OffsetsApplier(
        _SafeListIterator(offsets),
      );
      function.call(applier);
      // Clear the references to possible closure data.
      // TODO(scheglov) We want to null the whole `linkedData` instead.
      _offsets = null;
      _function = null;
    }
  }
}

class InformativeDataApplier {
  final LinkedElementFactory _elementFactory;
  final Map<Uri, Uint8List> _unitsInformativeBytes2;

  InformativeDataApplier(
    this._elementFactory,
    this._unitsInformativeBytes2,
  );

  void applyTo(LibraryElementImpl libraryElement) {
    if (_elementFactory.isApplyingInformativeData) {
      throw StateError('Unexpected recursion.');
    }
    _elementFactory.isApplyingInformativeData = true;

    var unitElements = libraryElement.units;
    for (var i = 0; i < unitElements.length; i++) {
      var unitElement = unitElements[i] as CompilationUnitElementImpl;
      var unitUri = unitElement.source.uri;
      var unitInfoBytes = _unitsInformativeBytes2[unitUri];
      if (unitInfoBytes != null) {
        var unitReader = SummaryDataReader(unitInfoBytes);
        var unitInfo = _InfoUnit(unitReader);

        if (i == 0) {
          _applyToLibrary(libraryElement, unitInfo);
        }

        unitElement.setCodeRange(unitInfo.codeOffset, unitInfo.codeLength);
        unitElement.lineInfo = LineInfo(unitInfo.lineStarts);

        _applyToAccessors(unitElement.accessors, unitInfo.accessors);

        forCorrespondingPairs(
          unitElement.classes
              .where((element) => !element.isMixinApplication)
              .toList(),
          unitInfo.classDeclarations,
          _applyToClassDeclaration,
        );

        forCorrespondingPairs(
          unitElement.classes
              .where((element) => element.isMixinApplication)
              .toList(),
          unitInfo.classTypeAliases,
          _applyToClassTypeAlias,
        );

        forCorrespondingPairs(
            unitElement.enums, unitInfo.enums, _applyToEnumDeclaration);

        forCorrespondingPairs(unitElement.extensions, unitInfo.extensions,
            _applyToExtensionDeclaration);

        forCorrespondingPairs(unitElement.functions, unitInfo.functions,
            _applyToFunctionDeclaration);

        forCorrespondingPairs(unitElement.mixins, unitInfo.mixinDeclarations,
            _applyToMixinDeclaration);

        forCorrespondingPairs(unitElement.topLevelVariables,
            unitInfo.topLevelVariable, _applyToTopLevelVariable);

        forCorrespondingPairs(
          unitElement.typeAliases
              .cast<TypeAliasElementImpl>()
              .where((e) => e.isFunctionTypeAliasBased)
              .toList(),
          unitInfo.functionTypeAliases,
          _applyToFunctionTypeAlias,
        );

        forCorrespondingPairs(
          unitElement.typeAliases
              .cast<TypeAliasElementImpl>()
              .where((e) => !e.isFunctionTypeAliasBased)
              .toList(),
          unitInfo.genericTypeAliases,
          _applyToGenericTypeAlias,
        );
      } else {
        unitElement.lineInfo = LineInfo([0]);
      }
    }

    _elementFactory.isApplyingInformativeData = false;
  }

  void _applyToAccessors(
    List<PropertyAccessorElement> elementList,
    List<_InfoMethodDeclaration> infoList,
  ) {
    forCorrespondingPairs<PropertyAccessorElement, _InfoMethodDeclaration>(
      elementList.notSynthetic,
      infoList,
      (element, info) {
        element as PropertyAccessorElementImpl;
        element.setCodeRange(info.codeOffset, info.codeLength);
        element.nameOffset = info.nameOffset;
        element.documentationComment = info.documentationComment;
        _applyToFormalParameters(
          element.parameters_unresolved,
          info.parameters,
        );

        var linkedData = element.linkedData;
        if (linkedData is PropertyAccessorElementLinkedData) {
          linkedData.applyConstantOffsets = ApplyConstantOffsets(
            info.constantOffsets,
            (applier) {
              applier.applyToMetadata(element);
              applier.applyToTypeParameters(element.typeParameters);
              applier.applyToFormalParameters(element.parameters);
            },
          );
        }
      },
    );
  }

  void _applyToClassDeclaration(
    ClassElement element,
    _InfoClassDeclaration info,
  ) {
    element as ClassElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );

    var linkedData = element.linkedData as ClassElementLinkedData;
    linkedData.applyConstantOffsets = ApplyConstantOffsets(
      info.constantOffsets,
      (applier) {
        applier.applyToMetadata(element);
        applier.applyToTypeParameters(element.typeParameters);
      },
    );
    linkedData.applyInformativeDataToMembers = () {
      _applyToConstructors(element.constructors, info.constructors);
      _applyToFields(element.fields, info.fields);
      _applyToAccessors(element.accessors, info.accessors);
      _applyToMethods(element.methods, info.methods);
    };
  }

  void _applyToClassTypeAlias(
    ClassElement element,
    _InfoClassTypeAlias info,
  ) {
    element as ClassElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );

    var linkedData = element.linkedData as ClassElementLinkedData;
    linkedData.applyConstantOffsets = ApplyConstantOffsets(
      info.constantOffsets,
      (applier) {
        applier.applyToMetadata(element);
        applier.applyToTypeParameters(element.typeParameters);
      },
    );
  }

  void _applyToCombinators(
    List<NamespaceCombinator> elementList,
    List<_InfoCombinator> infoList,
  ) {
    forCorrespondingPairs<NamespaceCombinator, _InfoCombinator>(
      elementList,
      infoList,
      (element, info) {
        if (element is ShowElementCombinatorImpl) {
          element.offset = info.offset;
          element.end = info.end;
        }
      },
    );
  }

  void _applyToConstructors(
    List<ConstructorElement> elementList,
    List<_InfoConstructorDeclaration> infoList,
  ) {
    forCorrespondingPairs<ConstructorElement, _InfoConstructorDeclaration>(
      elementList,
      infoList,
      (element, info) {
        element as ConstructorElementImpl;
        element.setCodeRange(info.codeOffset, info.codeLength);
        element.periodOffset = info.periodOffset;
        element.nameOffset = info.nameOffset;
        element.nameEnd = info.nameEnd;
        element.documentationComment = info.documentationComment;

        _applyToFormalParameters(
          element.parameters_unresolved,
          info.parameters,
        );

        var linkedData = element.linkedData as ConstructorElementLinkedData;
        linkedData.applyConstantOffsets = ApplyConstantOffsets(
          info.constantOffsets,
          (applier) {
            applier.applyToMetadata(element);
            applier.applyToFormalParameters(element.parameters);
            applier.applyToConstructorInitializers(element);
          },
        );
      },
    );
  }

  void _applyToEnumDeclaration(
    ClassElement element,
    _InfoClassDeclaration info,
  ) {
    element as EnumElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;

    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );
    _applyToConstructors(element.constructors, info.constructors);
    _applyToFields(element.fields, info.fields);
    _applyToAccessors(element.accessors, info.accessors);
    _applyToMethods(element.methods, info.methods);

    var linkedData = element.linkedData as EnumElementLinkedData;
    linkedData.applyConstantOffsets = ApplyConstantOffsets(
      info.constantOffsets,
      (applier) {
        applier.applyToMetadata(element);
        applier.applyToTypeParameters(element.typeParameters);
      },
    );
  }

  void _applyToExtensionDeclaration(
    ExtensionElement element,
    _InfoClassDeclaration info,
  ) {
    element as ExtensionElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );
    _applyToFields(element.fields, info.fields);
    _applyToAccessors(element.accessors, info.accessors);
    _applyToMethods(element.methods, info.methods);

    var linkedData = element.linkedData as ExtensionElementLinkedData;
    linkedData.applyConstantOffsets = ApplyConstantOffsets(
      info.constantOffsets,
      (applier) {
        applier.applyToMetadata(element);
        applier.applyToTypeParameters(element.typeParameters);
      },
    );
  }

  void _applyToFields(
    List<FieldElement> elementList,
    List<_InfoFieldDeclaration> infoList,
  ) {
    forCorrespondingPairs<FieldElement, _InfoFieldDeclaration>(
      elementList.notSynthetic,
      infoList,
      (element, info) {
        element as FieldElementImpl;
        element.setCodeRange(info.codeOffset, info.codeLength);
        element.nameOffset = info.nameOffset;
        element.documentationComment = info.documentationComment;

        var linkedData = element.linkedData as FieldElementLinkedData;
        linkedData.applyConstantOffsets = ApplyConstantOffsets(
          info.constantOffsets,
          (applier) {
            applier.applyToMetadata(element);
            applier.applyToConstantInitializer(element);
          },
        );
      },
    );
  }

  void _applyToFormalParameters(
    List<ParameterElement> parameters,
    List<_InfoFormalParameter> infoList,
  ) {
    forCorrespondingPairs<ParameterElement, _InfoFormalParameter>(
      parameters,
      infoList,
      (element, info) {
        element as ParameterElementImpl;
        element.setCodeRange(info.codeOffset, info.codeLength);
        element.nameOffset = info.nameOffset;
        _applyToTypeParameters(element.typeParameters, info.typeParameters);
        _applyToFormalParameters(element.parameters, info.parameters);
      },
    );
  }

  void _applyToFunctionDeclaration(
    FunctionElement element,
    _InfoFunctionDeclaration info,
  ) {
    element as FunctionElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );
    _applyToFormalParameters(
      element.parameters_unresolved,
      info.parameters,
    );

    var linkedData = element.linkedData as FunctionElementLinkedData;
    linkedData.applyConstantOffsets = ApplyConstantOffsets(
      info.constantOffsets,
      (applier) {
        applier.applyToMetadata(element);
        applier.applyToTypeParameters(element.typeParameters);
        applier.applyToFormalParameters(element.parameters);
      },
    );
  }

  void _applyToFunctionTypeAlias(
    TypeAliasElement element,
    _InfoFunctionTypeAlias info,
  ) {
    element as TypeAliasElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );

    _setupApplyConstantOffsetsForTypeAlias(
      element,
      info.constantOffsets,
      aliasedFormalParameters: info.parameters,
    );
  }

  void _applyToGenericTypeAlias(
    TypeAliasElement element,
    _InfoGenericTypeAlias info,
  ) {
    element as TypeAliasElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );

    _setupApplyConstantOffsetsForTypeAlias(
      element,
      info.constantOffsets,
      aliasedFormalParameters: info.aliasedFormalParameters,
      aliasedTypeParameters: info.aliasedTypeParameters,
    );
  }

  void _applyToLibrary(LibraryElementImpl element, _InfoUnit info) {
    element.nameOffset = info.libraryName.offset;
    element.nameLength = info.libraryName.length;

    if (info.docComment.isNotEmpty) {
      element.documentationComment = info.docComment;
    }

    forCorrespondingPairs<ImportElement, _InfoImport>(
      element.imports_unresolved,
      info.imports,
      (element, info) {
        element as ImportElementImpl;
        element.nameOffset = info.nameOffset;

        var prefix = element.prefix;
        if (prefix is PrefixElementImpl) {
          prefix.nameOffset = info.prefixOffset;
        }

        _applyToCombinators(element.combinators, info.combinators);
      },
    );

    forCorrespondingPairs<ExportElement, _InfoExport>(
      element.exports_unresolved,
      info.exports,
      (element, info) {
        element as ExportElementImpl;
        element.nameOffset = info.nameOffset;
        _applyToCombinators(element.combinators, info.combinators);
      },
    );

    forCorrespondingPairs<CompilationUnitElement, _InfoPart>(
      element.parts,
      info.parts,
      (element, info) {
        element as CompilationUnitElementImpl;
        var linkedData = element.linkedData as CompilationUnitElementLinkedData;
        linkedData.applyConstantOffsets = ApplyConstantOffsets(
          info.constantOffsets,
          (applier) {
            applier.applyToMetadata(element);
          },
        );
      },
    );

    var linkedData = element.linkedData as LibraryElementLinkedData;
    linkedData.applyConstantOffsets = ApplyConstantOffsets(
      info.libraryConstantOffsets,
      (applier) {
        applier.applyToMetadata(element);
        applier.applyToDirectives(element.imports);
        applier.applyToDirectives(element.exports);
      },
    );
  }

  void _applyToMethods(
    List<MethodElement> elementList,
    List<_InfoMethodDeclaration> infoList,
  ) {
    forCorrespondingPairs<MethodElement, _InfoMethodDeclaration>(
      elementList,
      infoList,
      (element, info) {
        element as MethodElementImpl;
        element.setCodeRange(info.codeOffset, info.codeLength);
        element.nameOffset = info.nameOffset;
        element.documentationComment = info.documentationComment;
        _applyToTypeParameters(
          element.typeParameters_unresolved,
          info.typeParameters,
        );
        _applyToFormalParameters(
          element.parameters_unresolved,
          info.parameters,
        );

        var linkedData = element.linkedData as MethodElementLinkedData;
        linkedData.applyConstantOffsets = ApplyConstantOffsets(
          info.constantOffsets,
          (applier) {
            applier.applyToMetadata(element);
            applier.applyToTypeParameters(element.typeParameters);
            applier.applyToFormalParameters(element.parameters);
          },
        );
      },
    );
  }

  void _applyToMixinDeclaration(
    ClassElement element,
    _InfoClassDeclaration info,
  ) {
    element as MixinElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );
    _applyToConstructors(element.constructors, info.constructors);
    _applyToFields(element.fields, info.fields);
    _applyToAccessors(element.accessors, info.accessors);
    _applyToMethods(element.methods, info.methods);

    var linkedData = element.linkedData as MixinElementLinkedData;
    linkedData.applyConstantOffsets = ApplyConstantOffsets(
      info.constantOffsets,
      (applier) {
        applier.applyToMetadata(element);
        applier.applyToTypeParameters(element.typeParameters);
      },
    );
  }

  void _applyToTopLevelVariable(
    TopLevelVariableElement element,
    _InfoTopLevelVariable info,
  ) {
    element as TopLevelVariableElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;

    var linkedData = element.linkedData as TopLevelVariableElementLinkedData;
    linkedData.applyConstantOffsets = ApplyConstantOffsets(
      info.constantOffsets,
      (applier) {
        applier.applyToMetadata(element);
        applier.applyToConstantInitializer(element);
      },
    );
  }

  void _applyToTypeParameters(
    List<TypeParameterElement> elementList,
    List<_InfoTypeParameter> infoList,
  ) {
    forCorrespondingPairs<TypeParameterElement, _InfoTypeParameter>(
      elementList,
      infoList,
      (element, info) {
        element as TypeParameterElementImpl;
        element.setCodeRange(info.codeOffset, info.codeLength);
        element.nameOffset = info.nameOffset;
      },
    );
  }

  void _setupApplyConstantOffsetsForTypeAlias(
    TypeAliasElementImpl element,
    Uint32List constantOffsets, {
    List<_InfoFormalParameter>? aliasedFormalParameters,
    List<_InfoTypeParameter>? aliasedTypeParameters,
  }) {
    var linkedData = element.linkedData as TypeAliasElementLinkedData;
    linkedData.applyConstantOffsets = ApplyConstantOffsets(
      constantOffsets,
      (applier) {
        applier.applyToMetadata(element);
        applier.applyToTypeParameters(element.typeParameters);

        var aliasedElement = element.aliasedElement;
        if (aliasedElement is FunctionTypedElementImpl) {
          applier.applyToTypeParameters(aliasedElement.typeParameters);
          applier.applyToFormalParameters(aliasedElement.parameters);
          if (aliasedTypeParameters != null) {
            _applyToTypeParameters(
              aliasedElement.typeParameters,
              aliasedTypeParameters,
            );
          }
          if (aliasedFormalParameters != null) {
            _applyToFormalParameters(
              aliasedElement.parameters,
              aliasedFormalParameters,
            );
          }
        }
      },
    );
  }
}

class _InfoClassDeclaration {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoConstructorDeclaration> constructors;
  final List<_InfoFieldDeclaration> fields;
  final List<_InfoMethodDeclaration> accessors;
  final List<_InfoMethodDeclaration> methods;
  final Uint32List constantOffsets;

  factory _InfoClassDeclaration(SummaryDataReader reader,
      {int nameOffsetDelta = 0}) {
    return _InfoClassDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30() - nameOffsetDelta,
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
      constructors: reader.readTypedList(
        () => _InfoConstructorDeclaration(reader),
      ),
      fields: reader.readTypedList(
        () => _InfoFieldDeclaration(reader),
      ),
      accessors: reader.readTypedList(
        () => _InfoMethodDeclaration(reader),
      ),
      methods: reader.readTypedList(
        () => _InfoMethodDeclaration(reader),
      ),
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoClassDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.typeParameters,
    required this.constructors,
    required this.fields,
    required this.accessors,
    required this.methods,
    required this.constantOffsets,
  });
}

class _InfoClassTypeAlias {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final Uint32List constantOffsets;

  factory _InfoClassTypeAlias(SummaryDataReader reader) {
    return _InfoClassTypeAlias._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoClassTypeAlias._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.typeParameters,
    required this.constantOffsets,
  });
}

class _InfoCombinator {
  final int offset;
  final int end;

  factory _InfoCombinator(SummaryDataReader reader) {
    return _InfoCombinator._(
      offset: reader.readUInt30(),
      end: reader.readUInt30(),
    );
  }

  _InfoCombinator._({
    required this.offset,
    required this.end,
  });
}

class _InfoConstructorDeclaration {
  final int codeOffset;
  final int codeLength;
  final int? periodOffset;
  final int nameOffset;
  final int nameEnd;
  final String? documentationComment;
  final List<_InfoFormalParameter> parameters;
  final Uint32List constantOffsets;

  factory _InfoConstructorDeclaration(SummaryDataReader reader) {
    return _InfoConstructorDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      periodOffset: reader.readOptionalUInt30(),
      nameOffset: reader.readUInt30(),
      nameEnd: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      parameters: reader.readTypedList(
        () => _InfoFormalParameter(reader),
      ),
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoConstructorDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.periodOffset,
    required this.nameOffset,
    required this.nameEnd,
    required this.documentationComment,
    required this.parameters,
    required this.constantOffsets,
  });
}

class _InfoExport {
  final int nameOffset;
  final List<_InfoCombinator> combinators;

  factory _InfoExport(SummaryDataReader reader) {
    return _InfoExport._(
      nameOffset: reader.readUInt30(),
      combinators: reader.readTypedList(
        () => _InfoCombinator(reader),
      ),
    );
  }

  _InfoExport._({
    required this.nameOffset,
    required this.combinators,
  });
}

class _InfoFieldDeclaration {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final Uint32List constantOffsets;

  factory _InfoFieldDeclaration(SummaryDataReader reader) {
    return _InfoFieldDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoFieldDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.constantOffsets,
  });
}

class _InfoFormalParameter {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoFormalParameter> parameters;

  factory _InfoFormalParameter(SummaryDataReader reader) {
    return _InfoFormalParameter._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30() - 1,
      typeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
      parameters: reader.readTypedList(
        () => _InfoFormalParameter(reader),
      ),
    );
  }

  _InfoFormalParameter._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.typeParameters,
    required this.parameters,
  });
}

class _InfoFunctionDeclaration {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoFormalParameter> parameters;
  final Uint32List constantOffsets;

  factory _InfoFunctionDeclaration(SummaryDataReader reader) {
    return _InfoFunctionDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
      parameters: reader.readTypedList(
        () => _InfoFormalParameter(reader),
      ),
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoFunctionDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.typeParameters,
    required this.parameters,
    required this.constantOffsets,
  });
}

class _InfoFunctionTypeAlias {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoFormalParameter> parameters;
  final Uint32List constantOffsets;

  factory _InfoFunctionTypeAlias(SummaryDataReader reader) {
    return _InfoFunctionTypeAlias._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
      parameters: reader.readTypedList(
        () => _InfoFormalParameter(reader),
      ),
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoFunctionTypeAlias._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.typeParameters,
    required this.parameters,
    required this.constantOffsets,
  });
}

class _InfoGenericTypeAlias {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoTypeParameter> aliasedTypeParameters;
  final List<_InfoFormalParameter> aliasedFormalParameters;
  final Uint32List constantOffsets;

  factory _InfoGenericTypeAlias(SummaryDataReader reader) {
    return _InfoGenericTypeAlias._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
      aliasedTypeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
      aliasedFormalParameters: reader.readTypedList(
        () => _InfoFormalParameter(reader),
      ),
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoGenericTypeAlias._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.typeParameters,
    required this.aliasedTypeParameters,
    required this.aliasedFormalParameters,
    required this.constantOffsets,
  });
}

class _InfoImport {
  final int nameOffset;
  final int prefixOffset;
  final List<_InfoCombinator> combinators;

  factory _InfoImport(SummaryDataReader reader) {
    return _InfoImport._(
      nameOffset: reader.readUInt30(),
      prefixOffset: reader.readUInt30() - 1,
      combinators: reader.readTypedList(
        () => _InfoCombinator(reader),
      ),
    );
  }

  _InfoImport._({
    required this.nameOffset,
    required this.prefixOffset,
    required this.combinators,
  });
}

class _InfoLibraryName {
  final int offset;
  final int length;

  factory _InfoLibraryName(SummaryDataReader reader) {
    return _InfoLibraryName._(
      offset: reader.readUInt30() - 1,
      length: reader.readUInt30(),
    );
  }

  _InfoLibraryName._({
    required this.offset,
    required this.length,
  });
}

class _InfoMethodDeclaration {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoFormalParameter> parameters;
  final Uint32List constantOffsets;

  factory _InfoMethodDeclaration(SummaryDataReader reader) {
    return _InfoMethodDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
      parameters: reader.readTypedList(
        () => _InfoFormalParameter(reader),
      ),
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoMethodDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.typeParameters,
    required this.parameters,
    required this.constantOffsets,
  });
}

class _InfoPart {
  final Uint32List constantOffsets;

  factory _InfoPart(SummaryDataReader reader) {
    return _InfoPart._(
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoPart._({
    required this.constantOffsets,
  });
}

class _InformativeDataWriter {
  final BufferedSink sink;

  _InformativeDataWriter(this.sink);

  void write(CompilationUnit unit) {
    sink.writeUInt30(unit.offset);
    sink.writeUInt30(unit.length);

    sink.writeUint30List(unit.lineInfo.lineStarts);

    _writeLibraryName(unit);

    var firstDirective = unit.directives.firstOrNull;
    _writeDocumentationCommentNode(firstDirective?.documentationComment);

    sink.writeList2<ImportDirective>(unit.directives, (directive) {
      sink.writeUInt30(directive.keyword.offset);
      sink.writeUInt30(1 + (directive.prefix?.offset ?? -1));
      _writeCombinators(directive.combinators);
    });

    sink.writeList2<ExportDirective>(unit.directives, (directive) {
      sink.writeUInt30(directive.keyword.offset);
      _writeCombinators(directive.combinators);
    });

    sink.writeList2<PartDirective>(unit.directives, (node) {
      _writeOffsets(
        metadata: node.metadata,
      );
    });

    sink.writeList2<ClassDeclaration>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeConstructors(node.members);
      _writeFields(node.members);
      _writeGettersSetters(node.members);
      _writeMethods(node.members);
      _writeOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
      );
    });

    sink.writeList2<ClassTypeAlias>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
      );
    });

    sink.writeList2<EnumDeclaration>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeConstructors(node.members);
      _writeEnumFields(node.constants, node.members);
      _writeGettersSetters(node.members);
      _writeMethods(node.members);
      _writeOffsets(
        metadata: node.metadata,
        enumConstants: node.constants,
        typeParameters: node.typeParameters,
      );
    });

    sink.writeList2<ExtensionDeclaration>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(1 + (node.name?.offset ?? -1));
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeConstructors(node.members);
      _writeFields(node.members);
      _writeGettersSetters(node.members);
      _writeMethods(node.members);
      _writeOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
      );
    });

    sink.writeList2<FunctionDeclaration>(
      unit.declarations
          .whereType<FunctionDeclaration>()
          .where((e) => e.isGetter || e.isSetter)
          .toList(),
      (node) {
        sink.writeUInt30(node.offset);
        sink.writeUInt30(node.length);
        sink.writeUInt30(node.name.offset);
        _writeDocumentationComment(node);
        _writeTypeParameters(node.functionExpression.typeParameters);
        _writeFormalParameters(node.functionExpression.parameters);
        _writeOffsets(
          metadata: node.metadata,
          typeParameters: node.functionExpression.typeParameters,
          formalParameters: node.functionExpression.parameters,
        );
      },
    );

    sink.writeList2<FunctionDeclaration>(
        unit.declarations
            .whereType<FunctionDeclaration>()
            .where((e) => !(e.isGetter || e.isSetter))
            .toList(), (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.functionExpression.typeParameters);
      _writeFormalParameters(node.functionExpression.parameters);
      _writeOffsets(
        metadata: node.metadata,
        typeParameters: node.functionExpression.typeParameters,
        formalParameters: node.functionExpression.parameters,
      );
    });

    sink.writeList2<FunctionTypeAlias>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeFormalParameters(node.parameters);
      _writeOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
        formalParameters: node.parameters,
      );
    });

    sink.writeList2<GenericTypeAlias>(unit.declarations, (node) {
      var aliasedType = node.type;
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      if (aliasedType is GenericFunctionType) {
        _writeTypeParameters(aliasedType.typeParameters);
        _writeFormalParameters(aliasedType.parameters);
      } else {
        _writeTypeParameters(null);
        _writeFormalParameters(null);
      }
      _writeOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
        aliasedType: node.type,
      );
    });

    sink.writeList2<MixinDeclaration>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeConstructors(node.members);
      _writeFields(node.members);
      _writeGettersSetters(node.members);
      _writeMethods(node.members);
      _writeOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
      );
    });

    sink.writeList<VariableDeclaration>(
      unit.declarations
          .whereType<TopLevelVariableDeclaration>()
          .expand((declaration) => declaration.variables.variables)
          .toList(),
      _writeTopLevelVariable,
    );
  }

  int _codeOffsetForVariable(VariableDeclaration node) {
    var codeOffset = node.offset;
    var variableList = node.parent as VariableDeclarationList;
    if (variableList.variables[0] == node) {
      codeOffset = variableList.parent!.offset;
    }
    return codeOffset;
  }

  void _writeCombinators(List<Combinator> combinators) {
    sink.writeList<Combinator>(combinators, (combinator) {
      sink.writeUInt30(combinator.offset);
      sink.writeUInt30(combinator.end);
    });
  }

  void _writeConstructors(List<ClassMember> members) {
    sink.writeList2<ConstructorDeclaration>(members, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeOptionalUInt30(node.period?.offset);
      var nameNode = node.name ?? node.returnType;
      sink.writeUInt30(nameNode.offset);
      sink.writeUInt30(nameNode.end);
      _writeDocumentationComment(node);
      _writeFormalParameters(node.parameters);
      _writeOffsets(
        metadata: node.metadata,
        formalParameters: node.parameters,
        constructorInitializers: node.initializers,
      );
    });
  }

  void _writeDocumentationComment(AnnotatedNode node) {
    _writeDocumentationCommentNode(node.documentationComment);
  }

  void _writeDocumentationCommentNode(Comment? commentNode) {
    var commentText = getCommentNodeRawText(commentNode);
    sink.writeStringUtf8(commentText ?? '');
  }

  void _writeEnumFields(
    List<EnumConstantDeclaration> constants,
    List<ClassMember> members,
  ) {
    var fields = members
        .whereType<FieldDeclaration>()
        .expand((declaration) => declaration.fields.variables)
        .toList();

    sink.writeUInt30(constants.length + fields.length);

    // Write constants in the same format as fields.
    for (var node in constants) {
      var codeOffset = node.offset;
      sink.writeUInt30(codeOffset);
      sink.writeUInt30(node.end - codeOffset);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      _writeOffsets(
        metadata: node.metadata,
        enumConstantArguments: node.arguments,
      );
    }

    for (var field in fields) {
      _writeField(field);
    }
  }

  void _writeField(VariableDeclaration node) {
    var codeOffset = _codeOffsetForVariable(node);
    sink.writeUInt30(codeOffset);
    sink.writeUInt30(node.end - codeOffset);
    sink.writeUInt30(node.name.offset);
    _writeDocumentationComment(node);

    // TODO(scheglov) Replace with some kind of double-iterating list.
    var declaration = node.parent!.parent as FieldDeclaration;

    _writeOffsets(
      metadata: declaration.metadata,
      constantInitializer: node.initializer,
    );
  }

  void _writeFields(List<ClassMember> members) {
    sink.writeList<VariableDeclaration>(
      members
          .whereType<FieldDeclaration>()
          .expand((declaration) => declaration.fields.variables)
          .toList(),
      _writeField,
    );
  }

  void _writeFormalParameters(FormalParameterList? parameterList) {
    var parameters = parameterList?.parameters ?? <FormalParameter>[];
    sink.writeList<FormalParameter>(parameters, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(1 + (node.identifier?.offset ?? -1));

      var notDefault = node.notDefault;
      if (notDefault is FieldFormalParameter) {
        _writeTypeParameters(notDefault.typeParameters);
        _writeFormalParameters(notDefault.parameters);
      } else if (notDefault is FunctionTypedFormalParameter) {
        _writeTypeParameters(notDefault.typeParameters);
        _writeFormalParameters(notDefault.parameters);
      } else if (notDefault is SuperFormalParameter) {
        _writeTypeParameters(notDefault.typeParameters);
        _writeFormalParameters(notDefault.parameters);
      } else {
        _writeTypeParameters(null);
        _writeFormalParameters(null);
      }
    });
  }

  void _writeGettersSetters(List<ClassMember> members) {
    sink.writeList<MethodDeclaration>(
      members
          .whereType<MethodDeclaration>()
          .where((e) => e.isGetter || e.isSetter)
          .toList(),
      (node) {
        sink.writeUInt30(node.offset);
        sink.writeUInt30(node.length);
        sink.writeUInt30(node.name.offset);
        _writeDocumentationComment(node);
        _writeTypeParameters(node.typeParameters);
        _writeFormalParameters(node.parameters);
        _writeOffsets(
          metadata: node.metadata,
          typeParameters: node.typeParameters,
          formalParameters: node.parameters,
        );
      },
    );
  }

  void _writeLibraryName(CompilationUnit unit) {
    Directive? firstDirective;
    var nameOffset = -1;
    var nameLength = 0;
    for (var directive in unit.directives) {
      firstDirective ??= directive;
      if (directive is LibraryDirective) {
        nameOffset = directive.name.offset;
        nameLength = directive.name.length;
        break;
      }
    }
    sink.writeUInt30(1 + nameOffset);
    sink.writeUInt30(nameLength);
    _writeOffsets(
      metadata: firstDirective?.metadata,
      importDirectives: unit.directives.whereType<ImportDirective>(),
      exportDirectives: unit.directives.whereType<ExportDirective>(),
    );
  }

  void _writeMethods(List<ClassMember> members) {
    sink.writeList<MethodDeclaration>(
      members
          .whereType<MethodDeclaration>()
          .where((e) => !(e.isGetter || e.isSetter))
          .toList(),
      (node) {
        sink.writeUInt30(node.offset);
        sink.writeUInt30(node.length);
        sink.writeUInt30(node.name.offset);
        _writeDocumentationComment(node);
        _writeTypeParameters(node.typeParameters);
        _writeFormalParameters(node.parameters);
        _writeOffsets(
          metadata: node.metadata,
          typeParameters: node.typeParameters,
          formalParameters: node.parameters,
        );
      },
    );
  }

  void _writeOffsets({
    NodeList<Annotation>? metadata,
    Iterable<ImportDirective>? importDirectives,
    Iterable<ExportDirective>? exportDirectives,
    TypeParameterList? typeParameters,
    FormalParameterList? formalParameters,
    Expression? constantInitializer,
    NodeList<ConstructorInitializer>? constructorInitializers,
    NodeList<EnumConstantDeclaration>? enumConstants,
    TypeAnnotation? aliasedType,
    EnumConstantArguments? enumConstantArguments,
  }) {
    var collector = _OffsetsCollector();

    void addDirectives(Iterable<Directive>? directives) {
      if (directives != null) {
        for (var directive in directives) {
          directive.metadata.accept(collector);
        }
      }
    }

    void addTypeParameters(TypeParameterList? typeParameters) {
      if (typeParameters != null) {
        for (var typeParameter in typeParameters.typeParameters) {
          typeParameter.metadata.accept(collector);
        }
      }
    }

    void addFormalParameters(FormalParameterList? formalParameters) {
      if (formalParameters != null) {
        for (var parameter in formalParameters.parameters) {
          parameter.metadata.accept(collector);
          addFormalParameters(
            parameter is FunctionTypedFormalParameter
                ? parameter.parameters
                : null,
          );
          if (parameter is DefaultFormalParameter) {
            parameter.defaultValue?.accept(collector);
          }
        }
      }
    }

    metadata?.accept(collector);
    addDirectives(importDirectives);
    addDirectives(exportDirectives);
    addTypeParameters(typeParameters);
    addFormalParameters(formalParameters);
    constantInitializer?.accept(collector);
    constructorInitializers?.accept(collector);
    if (enumConstants != null) {
      for (var enumConstant in enumConstants) {
        enumConstant.metadata.accept(collector);
      }
    }
    if (aliasedType is GenericFunctionType) {
      addTypeParameters(aliasedType.typeParameters);
      addFormalParameters(aliasedType.parameters);
    }
    enumConstantArguments?.typeArguments?.accept(collector);
    enumConstantArguments?.argumentList.arguments.accept(collector);
    sink.writeUint30List(collector.offsets);
  }

  void _writeTopLevelVariable(VariableDeclaration node) {
    var codeOffset = _codeOffsetForVariable(node);
    sink.writeUInt30(codeOffset);
    sink.writeUInt30(node.end - codeOffset);
    sink.writeUInt30(node.name.offset);
    _writeDocumentationComment(node);

    // TODO(scheglov) Replace with some kind of double-iterating list.
    var declaration = node.parent!.parent as TopLevelVariableDeclaration;

    _writeOffsets(
      metadata: declaration.metadata,
      constantInitializer: node.initializer,
    );
  }

  void _writeTypeParameters(TypeParameterList? parameterList) {
    var parameters = parameterList?.typeParameters ?? <TypeParameter>[];
    sink.writeList<TypeParameter>(parameters, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
    });
  }
}

class _InfoTopLevelVariable {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final Uint32List constantOffsets;

  factory _InfoTopLevelVariable(SummaryDataReader reader) {
    return _InfoTopLevelVariable._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoTopLevelVariable._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.constantOffsets,
  });
}

class _InfoTypeParameter {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;

  factory _InfoTypeParameter(SummaryDataReader reader) {
    return _InfoTypeParameter._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
    );
  }

  _InfoTypeParameter._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
  });
}

class _InfoUnit {
  final int codeOffset;
  final int codeLength;
  final List<int> lineStarts;
  final _InfoLibraryName libraryName;
  final Uint32List libraryConstantOffsets;
  final String docComment;
  final List<_InfoImport> imports;
  final List<_InfoExport> exports;
  final List<_InfoPart> parts;
  final List<_InfoClassDeclaration> classDeclarations;
  final List<_InfoClassTypeAlias> classTypeAliases;
  final List<_InfoClassDeclaration> enums;
  final List<_InfoClassDeclaration> extensions;
  final List<_InfoMethodDeclaration> accessors;
  final List<_InfoFunctionDeclaration> functions;
  final List<_InfoFunctionTypeAlias> functionTypeAliases;
  final List<_InfoGenericTypeAlias> genericTypeAliases;
  final List<_InfoClassDeclaration> mixinDeclarations;
  final List<_InfoTopLevelVariable> topLevelVariable;

  factory _InfoUnit(SummaryDataReader reader) {
    return _InfoUnit._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      lineStarts: reader.readUInt30List(),
      libraryName: _InfoLibraryName(reader),
      libraryConstantOffsets: reader.readUInt30List(),
      docComment: reader.readStringUtf8(),
      imports: reader.readTypedList(
        () => _InfoImport(reader),
      ),
      exports: reader.readTypedList(
        () => _InfoExport(reader),
      ),
      parts: reader.readTypedList(
        () => _InfoPart(reader),
      ),
      classDeclarations: reader.readTypedList(
        () => _InfoClassDeclaration(reader),
      ),
      classTypeAliases: reader.readTypedList(
        () => _InfoClassTypeAlias(reader),
      ),
      enums: reader.readTypedList(
        () => _InfoClassDeclaration(reader),
      ),
      extensions: reader.readTypedList(
        () => _InfoClassDeclaration(reader, nameOffsetDelta: 1),
      ),
      accessors: reader.readTypedList(
        () => _InfoMethodDeclaration(reader),
      ),
      functions: reader.readTypedList(
        () => _InfoFunctionDeclaration(reader),
      ),
      functionTypeAliases: reader.readTypedList(
        () => _InfoFunctionTypeAlias(reader),
      ),
      genericTypeAliases: reader.readTypedList(
        () => _InfoGenericTypeAlias(reader),
      ),
      mixinDeclarations: reader.readTypedList(
        () => _InfoClassDeclaration(reader),
      ),
      topLevelVariable: reader.readTypedList(
        () => _InfoTopLevelVariable(reader),
      ),
    );
  }

  _InfoUnit._({
    required this.codeOffset,
    required this.codeLength,
    required this.lineStarts,
    required this.libraryName,
    required this.libraryConstantOffsets,
    required this.docComment,
    required this.imports,
    required this.exports,
    required this.parts,
    required this.classDeclarations,
    required this.classTypeAliases,
    required this.enums,
    required this.extensions,
    required this.accessors,
    required this.functions,
    required this.functionTypeAliases,
    required this.genericTypeAliases,
    required this.mixinDeclarations,
    required this.topLevelVariable,
  });
}

class _OffsetsApplier extends _OffsetsAstVisitor {
  final _SafeListIterator<int> _iterator;

  _OffsetsApplier(this._iterator);

  void applyToConstantInitializer(Element element) {
    if (element is ConstFieldElementImpl && element.isEnumConstant) {
      _applyToEnumConstantInitializer(element);
    } else if (element is ConstVariableElement) {
      element.constantInitializer?.accept(this);
    }
  }

  void applyToConstructorInitializers(ConstructorElementImpl element) {
    for (var initializer in element.constantInitializers) {
      initializer.accept(this);
    }
  }

  void applyToDirectives(List<UriReferencedElement> elements) {
    for (var element in elements) {
      applyToMetadata(element);
    }
  }

  void applyToEnumConstants(List<FieldElement> constants) {
    for (var constant in constants) {
      applyToMetadata(constant);
    }
  }

  void applyToFormalParameters(List<ParameterElement> formalParameters) {
    for (var parameter in formalParameters) {
      applyToMetadata(parameter);
      applyToFormalParameters(parameter.parameters);
      applyToConstantInitializer(parameter);
    }
  }

  void applyToMetadata(Element element) {
    for (var annotation in element.metadata) {
      var node = (annotation as ElementAnnotationImpl).annotationAst;
      node.accept(this);
    }
  }

  void applyToTypeParameters(List<TypeParameterElement> typeParameters) {
    for (var typeParameter in typeParameters) {
      applyToMetadata(typeParameter);
    }
  }

  @override
  void handleToken(Token token) {
    var offset = _iterator.take();
    if (offset != null) {
      token.offset = offset;
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // We store FunctionExpression(s) as empty stubs: `() {}`.
    // We just need it to have right code range, so we apply 2 offsets.
    node.parameters?.leftParenthesis.offset = _iterator.take() ?? 0;

    var body = node.body;
    if (body is BlockFunctionBody) {
      body.block.rightBracket.offset = _iterator.take() ?? 0;
    }
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    super.visitSimpleFormalParameter(node);

    var element = node.declaredElement;
    var identifier = node.identifier;
    if (element is ParameterElementImpl && identifier != null) {
      element.nameOffset = identifier.offset;
    }
  }

  void _applyToEnumConstantInitializer(ConstFieldElementImpl element) {
    var initializer = element.constantInitializer;
    if (initializer is InstanceCreationExpression) {
      initializer.constructorName.type.typeArguments?.accept(this);
      for (var argument in initializer.argumentList.arguments) {
        argument.accept(this);
      }
    }
  }
}

abstract class _OffsetsAstVisitor extends RecursiveAstVisitor<void> {
  void handleToken(Token token);

  @override
  void visitAnnotation(Annotation node) {
    _tokenOrNull(node.atSign);
    _tokenOrNull(node.period);
    super.visitAnnotation(node);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _tokenOrNull(node.leftParenthesis);
    _tokenOrNull(node.rightParenthesis);
    super.visitArgumentList(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    _tokenOrNull(node.asOperator);
    super.visitAsExpression(node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _tokenOrNull(node.assertKeyword);
    _tokenOrNull(node.leftParenthesis);
    _tokenOrNull(node.comma);
    _tokenOrNull(node.rightParenthesis);
    super.visitAssertInitializer(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _tokenOrNull(node.operator);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _tokenOrNull(node.operator);
    super.visitBinaryExpression(node);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _tokenOrNull(node.literal);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _tokenOrNull(node.question);
    _tokenOrNull(node.colon);
    super.visitConditionalExpression(node);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _tokenOrNull(node.thisKeyword);
    _tokenOrNull(node.equals);
    super.visitConstructorFieldInitializer(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    node.type.accept(this);
    _tokenOrNull(node.period);
    node.name?.accept(this);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _tokenOrNull(node.literal);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _tokenOrNull(node.leftParenthesis);
    _tokenOrNull(node.leftDelimiter);
    _tokenOrNull(node.rightDelimiter);
    _tokenOrNull(node.rightParenthesis);
    super.visitFormalParameterList(node);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    _tokenOrNull(node.functionKeyword);
    super.visitGenericFunctionType(node);
  }

  @override
  void visitIfElement(IfElement node) {
    _tokenOrNull(node.ifKeyword);
    _tokenOrNull(node.leftParenthesis);
    _tokenOrNull(node.rightParenthesis);
    _tokenOrNull(node.elseKeyword);
    super.visitIfElement(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _tokenOrNull(node.leftBracket);
    _tokenOrNull(node.rightBracket);
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _tokenOrNull(node.keyword);
    node.constructorName.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _tokenOrNull(node.literal);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _tokenOrNull(node.leftBracket);
    _tokenOrNull(node.rightBracket);
    super.visitInterpolationExpression(node);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    _tokenOrNull(node.contents);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _tokenOrNull(node.isOperator);
    super.visitIsExpression(node);
  }

  @override
  void visitLabel(Label node) {
    _tokenOrNull(node.colon);
    super.visitLabel(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _tokenOrNull(node.constKeyword);
    _tokenOrNull(node.leftBracket);
    _tokenOrNull(node.rightBracket);
    super.visitListLiteral(node);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    _tokenOrNull(node.separator);
    super.visitMapLiteralEntry(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    node.target?.accept(this);
    _tokenOrNull(node.operator);
    node.methodName.accept(this);
    node.typeArguments?.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitNamedType(NamedType node) {
    _tokenOrNull(node.question);
    super.visitNamedType(node);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _tokenOrNull(node.literal);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _tokenOrNull(node.leftParenthesis);
    _tokenOrNull(node.rightParenthesis);
    super.visitParenthesizedExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _tokenOrNull(node.operator);
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    node.prefix.accept(this);
    _tokenOrNull(node.period);
    node.identifier.accept(this);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _tokenOrNull(node.operator);
    super.visitPrefixExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    node.target?.accept(this);
    _tokenOrNull(node.operator);
    node.propertyName.accept(this);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _tokenOrNull(node.thisKeyword);
    _tokenOrNull(node.period);
    super.visitRedirectingConstructorInvocation(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _tokenOrNull(node.constKeyword);
    _tokenOrNull(node.leftBracket);
    _tokenOrNull(node.rightBracket);
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _tokenOrNull(node.requiredKeyword);
    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _tokenOrNull(node.token);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _tokenOrNull(node.literal);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    _tokenOrNull(node.spreadOperator);
    super.visitSpreadElement(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _tokenOrNull(node.superKeyword);
    _tokenOrNull(node.period);
    super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    _tokenOrNull(node.superKeyword);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    _tokenOrNull(node.poundSign);
    node.components.forEach(_tokenOrNull);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _tokenOrNull(node.thisKeyword);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _tokenOrNull(node.throwKeyword);
    super.visitThrowExpression(node);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    _tokenOrNull(node.leftBracket);
    _tokenOrNull(node.rightBracket);
    super.visitTypeArgumentList(node);
  }

  void _tokenOrNull(Token? token) {
    if (token != null) {
      handleToken(token);
    }
  }
}

class _OffsetsCollector extends _OffsetsAstVisitor {
  final List<int> offsets = [];

  @override
  void handleToken(Token token) {
    offsets.add(token.offset);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    offsets.add(node.offset);
    offsets.add(node.end - 1);
  }
}

class _SafeListIterator<T> {
  final List<T> _elements;
  int _index = 0;

  _SafeListIterator(this._elements);

  bool get hasNext {
    return _index < _elements.length;
  }

  T? take() {
    if (hasNext) {
      return _elements[_index++];
    } else {
      return null;
    }
  }
}

extension on String {
  String? get nullIfEmpty {
    return isNotEmpty ? this : null;
  }
}

extension _ListOfElement<T extends Element> on List<T> {
  List<T> get notSynthetic {
    return where((e) => !e.isSynthetic).toList();
  }
}
