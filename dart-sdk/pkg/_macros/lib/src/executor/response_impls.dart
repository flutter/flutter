// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../api.dart';
import '../executor.dart';
import 'exception_impls.dart';
import 'introspection_impls.dart';
import 'serialization.dart';
import 'serialization_extensions.dart';

/// Implementation of [MacroInstanceIdentifier].
class MacroInstanceIdentifierImpl implements MacroInstanceIdentifier {
  /// Unique identifier for this instance, passed in from the server.
  final int id;

  /// A single int where each bit indicates whether a specific macro interface
  /// is implemented by this macro.
  final int _interfaces;

  MacroInstanceIdentifierImpl._(this.id, this._interfaces);

  factory MacroInstanceIdentifierImpl(Macro macro, int instanceId) {
    // Build up the interfaces value, there is a bit for each declaration/phase
    // combination (as there is an interface for each).
    int interfaces = 0;
    for (DeclarationKind declarationKind in DeclarationKind.values) {
      for (Phase phase in Phase.values) {
        int interfaceMask = _interfaceMask(declarationKind, phase);
        switch (declarationKind) {
          case DeclarationKind.classType:
            switch (phase) {
              case Phase.types:
                if (macro is ClassTypesMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.declarations:
                if (macro is ClassDeclarationsMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.definitions:
                if (macro is ClassDefinitionMacro) {
                  interfaces |= interfaceMask;
                }
            }
          case DeclarationKind.constructor:
            switch (phase) {
              case Phase.types:
                if (macro is ConstructorTypesMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.declarations:
                if (macro is ConstructorDeclarationsMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.definitions:
                if (macro is ConstructorDefinitionMacro) {
                  interfaces |= interfaceMask;
                }
            }
          case DeclarationKind.extension:
            switch (phase) {
              case Phase.types:
                if (macro is ExtensionTypesMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.declarations:
                if (macro is ExtensionDeclarationsMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.definitions:
                if (macro is ExtensionDefinitionMacro) {
                  interfaces |= interfaceMask;
                }
            }
          case DeclarationKind.extensionType:
            switch (phase) {
              case Phase.types:
                if (macro is ExtensionTypeTypesMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.declarations:
                if (macro is ExtensionTypeDeclarationsMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.definitions:
                if (macro is ExtensionTypeDefinitionMacro) {
                  interfaces |= interfaceMask;
                }
            }
          case DeclarationKind.field:
            switch (phase) {
              case Phase.types:
                if (macro is FieldTypesMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.declarations:
                if (macro is FieldDeclarationsMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.definitions:
                if (macro is FieldDefinitionMacro) {
                  interfaces |= interfaceMask;
                }
            }
          case DeclarationKind.function:
            switch (phase) {
              case Phase.types:
                if (macro is FunctionTypesMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.declarations:
                if (macro is FunctionDeclarationsMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.definitions:
                if (macro is FunctionDefinitionMacro) {
                  interfaces |= interfaceMask;
                }
            }
          case DeclarationKind.library:
            switch (phase) {
              case Phase.types:
                if (macro is LibraryTypesMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.declarations:
                if (macro is LibraryDeclarationsMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.definitions:
                if (macro is LibraryDefinitionMacro) {
                  interfaces |= interfaceMask;
                }
            }
          case DeclarationKind.method:
            switch (phase) {
              case Phase.types:
                if (macro is MethodTypesMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.declarations:
                if (macro is MethodDeclarationsMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.definitions:
                if (macro is MethodDefinitionMacro) {
                  interfaces |= interfaceMask;
                }
            }
          case DeclarationKind.enumType:
            switch (phase) {
              case Phase.types:
                if (macro is EnumTypesMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.declarations:
                if (macro is EnumDeclarationsMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.definitions:
                if (macro is EnumDefinitionMacro) {
                  interfaces |= interfaceMask;
                }
            }
          case DeclarationKind.enumValue:
            switch (phase) {
              case Phase.types:
                if (macro is EnumValueTypesMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.declarations:
                if (macro is EnumValueDeclarationsMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.definitions:
                if (macro is EnumValueDefinitionMacro) {
                  interfaces |= interfaceMask;
                }
            }
          case DeclarationKind.mixinType:
            switch (phase) {
              case Phase.types:
                if (macro is MixinTypesMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.declarations:
                if (macro is MixinDeclarationsMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.definitions:
                if (macro is MixinDefinitionMacro) {
                  interfaces |= interfaceMask;
                }
            }
          case DeclarationKind.typeAlias:
            switch (phase) {
              case Phase.types:
                if (macro is TypeAliasTypesMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.declarations:
                if (macro is TypeAliasDeclarationsMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.definitions:
                // Does not have definitions.
                break;
            }
          case DeclarationKind.variable:
            switch (phase) {
              case Phase.types:
                if (macro is VariableTypesMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.declarations:
                if (macro is VariableDeclarationsMacro) {
                  interfaces |= interfaceMask;
                }
              case Phase.definitions:
                if (macro is VariableDefinitionMacro) {
                  interfaces |= interfaceMask;
                }
            }
        }
      }
    }

    return MacroInstanceIdentifierImpl._(instanceId, interfaces);
  }

  MacroInstanceIdentifierImpl.deserialize(Deserializer deserializer)
      : id = (deserializer..moveNext()).expectInt(),
        _interfaces = (deserializer..moveNext()).expectInt();

  @override
  void serialize(Serializer serializer) => serializer
    ..addInt(id)
    ..addInt(_interfaces);

  @override
  operator ==(other) => other is MacroInstanceIdentifierImpl && id == other.id;

  @override
  int get hashCode => id;

  @override
  bool shouldExecute(DeclarationKind declarationKind, Phase phase) {
    int mask = _interfaceMask(declarationKind, phase);
    if (declarationKind == DeclarationKind.method) {
      // Apply function macros to methods.
      mask |= _interfaceMask(DeclarationKind.function, phase);
    } else if (declarationKind == DeclarationKind.field) {
      // Apply variable macros to fields.
      mask |= _interfaceMask(DeclarationKind.variable, phase);
    }
    return _interfaces & mask != 0x0;
  }

  @override
  bool supportsDeclarationKind(DeclarationKind declarationKind) {
    for (Phase phase in Phase.values) {
      if (shouldExecute(declarationKind, phase)) {
        return true;
      }
    }
    return false;
  }

  /// The mask for a particular interface, which is a combination of a kind of
  /// declaration and a phase.
  static int _interfaceMask(DeclarationKind declarationKind, Phase phase) =>
      0x1 << (declarationKind.index * Phase.values.length) << phase.index;
}

/// Implementation of [MacroExecutionResult].
class MacroExecutionResultImpl implements MacroExecutionResult {
  @override
  final List<Diagnostic> diagnostics;

  @override
  final MacroExceptionImpl? exception;

  @override
  final Map<IdentifierImpl, List<DeclarationCode>> enumValueAugmentations;

  @override
  final Map<IdentifierImpl, NamedTypeAnnotationCode> extendsTypeAugmentations;

  @override
  final Map<IdentifierImpl, List<TypeAnnotationCode>> interfaceAugmentations;

  @override
  final List<DeclarationCode> libraryAugmentations;

  @override
  final Map<IdentifierImpl, List<TypeAnnotationCode>> mixinAugmentations;

  @override
  final List<String> newTypeNames;

  @override
  final Map<IdentifierImpl, List<DeclarationCode>> typeAugmentations;

  MacroExecutionResultImpl({
    required this.diagnostics,
    this.exception,
    required this.enumValueAugmentations,
    required this.extendsTypeAugmentations,
    required this.interfaceAugmentations,
    required this.libraryAugmentations,
    required this.mixinAugmentations,
    required this.newTypeNames,
    required this.typeAugmentations,
  });

  factory MacroExecutionResultImpl.deserialize(Deserializer deserializer) {
    deserializer
      ..moveNext()
      ..expectList();
    List<Diagnostic> diagnostics = [
      for (; deserializer.moveNext();) deserializer.expectDiagnostic(),
    ];

    MacroExceptionImpl? exception = (deserializer..moveNext()).checkNull()
        ? null
        : deserializer.expectRemoteInstance();

    deserializer
      ..moveNext()
      ..expectList();
    Map<IdentifierImpl, List<DeclarationCode>> enumValueAugmentations = {
      for (; deserializer.moveNext();)
        deserializer.expectRemoteInstance(): [
          for (bool hasNextCode = (deserializer
                    ..moveNext()
                    ..expectList())
                  .moveNext();
              hasNextCode;
              hasNextCode = deserializer.moveNext())
            deserializer.expectCode(),
        ]
    };

    deserializer
      ..moveNext()
      ..expectList();
    Map<IdentifierImpl, NamedTypeAnnotationCode> extendsTypeAugmentations = {
      for (; deserializer.moveNext();)
        deserializer.expectRemoteInstance():
            (deserializer..moveNext()).expectCode(),
    };

    deserializer
      ..moveNext()
      ..expectList();
    Map<IdentifierImpl, List<TypeAnnotationCode>> interfaceAugmentations = {
      for (; deserializer.moveNext();)
        deserializer.expectRemoteInstance(): [
          for (bool hasNextCode = (deserializer
                    ..moveNext()
                    ..expectList())
                  .moveNext();
              hasNextCode;
              hasNextCode = deserializer.moveNext())
            deserializer.expectCode(),
        ]
    };

    deserializer
      ..moveNext()
      ..expectList();
    List<DeclarationCode> libraryAugmentations = [
      for (; deserializer.moveNext();) deserializer.expectCode()
    ];

    deserializer
      ..moveNext()
      ..expectList();
    Map<IdentifierImpl, List<TypeAnnotationCode>> mixinAugmentations = {
      for (; deserializer.moveNext();)
        deserializer.expectRemoteInstance(): [
          for (bool hasNextCode = (deserializer
                    ..moveNext()
                    ..expectList())
                  .moveNext();
              hasNextCode;
              hasNextCode = deserializer.moveNext())
            deserializer.expectCode(),
        ]
    };

    deserializer
      ..moveNext()
      ..expectList();
    List<String> newTypeNames = [
      for (; deserializer.moveNext();) deserializer.expectString()
    ];

    deserializer
      ..moveNext()
      ..expectList();
    Map<IdentifierImpl, List<DeclarationCode>> typeAugmentations = {
      for (; deserializer.moveNext();)
        deserializer.expectRemoteInstance(): [
          for (bool hasNextCode = (deserializer
                    ..moveNext()
                    ..expectList())
                  .moveNext();
              hasNextCode;
              hasNextCode = deserializer.moveNext())
            deserializer.expectCode(),
        ]
    };

    return MacroExecutionResultImpl(
      diagnostics: diagnostics,
      exception: exception,
      enumValueAugmentations: enumValueAugmentations,
      extendsTypeAugmentations: extendsTypeAugmentations,
      interfaceAugmentations: interfaceAugmentations,
      libraryAugmentations: libraryAugmentations,
      mixinAugmentations: mixinAugmentations,
      newTypeNames: newTypeNames,
      typeAugmentations: typeAugmentations,
    );
  }

  @override
  void serialize(Serializer serializer) {
    serializer.startList();
    for (Diagnostic diagnostic in diagnostics) {
      diagnostic.serialize(serializer);
    }
    serializer.endList();

    if (exception == null) {
      serializer.addNull();
    } else {
      exception!.serialize(serializer);
    }

    serializer.startList();
    for (IdentifierImpl enuum in enumValueAugmentations.keys) {
      enuum.serialize(serializer);
      serializer.startList();
      for (DeclarationCode augmentation in enumValueAugmentations[enuum]!) {
        augmentation.serialize(serializer);
      }
      serializer.endList();
    }
    serializer.endList();

    serializer.startList();
    for (IdentifierImpl type in extendsTypeAugmentations.keys) {
      type.serialize(serializer);
      extendsTypeAugmentations[type]!.serialize(serializer);
    }
    serializer.endList();

    serializer.startList();
    for (IdentifierImpl type in interfaceAugmentations.keys) {
      type.serialize(serializer);
      serializer.startList();
      for (TypeAnnotationCode interface in interfaceAugmentations[type]!) {
        interface.serialize(serializer);
      }
      serializer.endList();
    }
    serializer.endList();

    serializer.startList();
    for (DeclarationCode augmentation in libraryAugmentations) {
      augmentation.serialize(serializer);
    }
    serializer.endList();

    serializer.startList();
    for (IdentifierImpl type in mixinAugmentations.keys) {
      type.serialize(serializer);
      serializer.startList();
      for (TypeAnnotationCode mixin in mixinAugmentations[type]!) {
        mixin.serialize(serializer);
      }
      serializer.endList();
    }
    serializer.endList();

    serializer.startList();
    for (String name in newTypeNames) {
      serializer.addString(name);
    }
    serializer.endList();

    serializer.startList();
    for (IdentifierImpl type in typeAugmentations.keys) {
      type.serialize(serializer);
      serializer.startList();
      for (DeclarationCode augmentation in typeAugmentations[type]!) {
        augmentation.serialize(serializer);
      }
      serializer.endList();
    }
    serializer.endList();
  }
}
