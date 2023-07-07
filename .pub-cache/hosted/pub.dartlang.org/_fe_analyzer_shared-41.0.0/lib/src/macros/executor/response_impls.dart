// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../executor.dart';
import '../api.dart';
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
          case DeclarationKind.clazz:
            switch (phase) {
              case Phase.types:
                if (macro is ClassTypesMacro) {
                  interfaces |= interfaceMask;
                }
                break;
              case Phase.declarations:
                if (macro is ClassDeclarationsMacro) {
                  interfaces |= interfaceMask;
                }
                break;
              case Phase.definitions:
                if (macro is ClassDefinitionMacro) {
                  interfaces |= interfaceMask;
                }
                break;
            }
            break;
          case DeclarationKind.constructor:
            switch (phase) {
              case Phase.types:
                if (macro is ConstructorTypesMacro) {
                  interfaces |= interfaceMask;
                }
                break;
              case Phase.declarations:
                if (macro is ConstructorDeclarationsMacro) {
                  interfaces |= interfaceMask;
                }
                break;
              case Phase.definitions:
                if (macro is ConstructorDefinitionMacro) {
                  interfaces |= interfaceMask;
                }
                break;
            }
            break;
          case DeclarationKind.field:
            switch (phase) {
              case Phase.types:
                if (macro is FieldTypesMacro) {
                  interfaces |= interfaceMask;
                }
                break;
              case Phase.declarations:
                if (macro is FieldDeclarationsMacro) {
                  interfaces |= interfaceMask;
                }
                break;
              case Phase.definitions:
                if (macro is FieldDefinitionMacro) {
                  interfaces |= interfaceMask;
                }
                break;
            }
            break;
          case DeclarationKind.function:
            switch (phase) {
              case Phase.types:
                if (macro is FunctionTypesMacro) {
                  interfaces |= interfaceMask;
                }
                break;
              case Phase.declarations:
                if (macro is FunctionDeclarationsMacro) {
                  interfaces |= interfaceMask;
                }
                break;
              case Phase.definitions:
                if (macro is FunctionDefinitionMacro) {
                  interfaces |= interfaceMask;
                }
                break;
            }
            break;
          case DeclarationKind.method:
            switch (phase) {
              case Phase.types:
                if (macro is MethodTypesMacro) {
                  interfaces |= interfaceMask;
                }
                break;
              case Phase.declarations:
                if (macro is MethodDeclarationsMacro) {
                  interfaces |= interfaceMask;
                }
                break;
              case Phase.definitions:
                if (macro is MethodDefinitionMacro) {
                  interfaces |= interfaceMask;
                }
                break;
            }
            break;
          case DeclarationKind.variable:
            switch (phase) {
              case Phase.types:
                if (macro is VariableTypesMacro) {
                  interfaces |= interfaceMask;
                }
                break;
              case Phase.declarations:
                if (macro is VariableDeclarationsMacro) {
                  interfaces |= interfaceMask;
                }
                break;
              case Phase.definitions:
                if (macro is VariableDefinitionMacro) {
                  interfaces |= interfaceMask;
                }
                break;
            }
            break;
        }
      }
    }

    return new MacroInstanceIdentifierImpl._(instanceId, interfaces);
  }

  MacroInstanceIdentifierImpl.deserialize(Deserializer deserializer)
      : id = (deserializer..moveNext()).expectInt(),
        _interfaces = (deserializer..moveNext()).expectInt();

  void serialize(Serializer serializer) => serializer
    ..addInt(id)
    ..addInt(_interfaces);

  operator ==(other) => other is MacroInstanceIdentifierImpl && id == other.id;

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
  final Map<String, List<DeclarationCode>> classAugmentations;

  @override
  final List<DeclarationCode> libraryAugmentations;

  @override
  final List<String> newTypeNames;

  MacroExecutionResultImpl({
    required this.classAugmentations,
    required this.libraryAugmentations,
    required this.newTypeNames,
  });

  factory MacroExecutionResultImpl.deserialize(Deserializer deserializer) {
    deserializer.moveNext();
    deserializer.expectList();
    Map<String, List<DeclarationCode>> classAugmentations = {
      for (bool hasNext = deserializer.moveNext();
          hasNext;
          hasNext = deserializer.moveNext())
        deserializer.expectString(): [
          for (bool hasNextCode = (deserializer
                    ..moveNext()
                    ..expectList())
                  .moveNext();
              hasNextCode;
              hasNextCode = deserializer.moveNext())
            deserializer.expectCode(),
        ]
    };

    deserializer.moveNext();
    deserializer.expectList();
    List<DeclarationCode> libraryAugmentations = [
      for (bool hasNext = deserializer.moveNext();
          hasNext;
          hasNext = deserializer.moveNext())
        deserializer.expectCode()
    ];
    deserializer.moveNext();
    deserializer.expectList();
    List<String> newTypeNames = [
      for (bool hasNext = deserializer.moveNext();
          hasNext;
          hasNext = deserializer.moveNext())
        deserializer.expectString()
    ];

    return new MacroExecutionResultImpl(
      classAugmentations: classAugmentations,
      libraryAugmentations: libraryAugmentations,
      newTypeNames: newTypeNames,
    );
  }

  void serialize(Serializer serializer) {
    serializer.startList();
    for (String clazz in classAugmentations.keys) {
      serializer.addString(clazz);
      serializer.startList();
      for (DeclarationCode augmentation in classAugmentations[clazz]!) {
        augmentation.serialize(serializer);
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
    for (String name in newTypeNames) {
      serializer.addString(name);
    }
    serializer.endList();
  }
}
