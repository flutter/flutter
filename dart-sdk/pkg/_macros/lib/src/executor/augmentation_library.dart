// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../api.dart';
import '../executor.dart';
import 'span.dart';

/// A mixin which provides a shared implementation of
/// [MacroExecutor.buildAugmentationLibrary].
mixin AugmentationLibraryBuilder on MacroExecutor {
  @override
  String buildAugmentationLibrary(
      Uri augmentedLibraryUri,
      Iterable<MacroExecutionResult> macroResults,
      TypeDeclaration Function(Identifier) resolveDeclaration,
      ResolvedIdentifier Function(Identifier) resolveIdentifier,
      TypeAnnotation? Function(OmittedTypeAnnotation) typeInferrer,
      {Map<OmittedTypeAnnotation, String>? omittedTypes,
      List<Span>? spans}) {
    return _Builder(augmentedLibraryUri, resolveDeclaration, resolveIdentifier,
            typeInferrer, omittedTypes)
        .build(macroResults, spans: spans);
  }
}

class _Builder {
  /// The import URI for the augmented library.
  final Uri _augmentedLibraryUri;

  final TypeDeclaration Function(Identifier) _resolveDeclaration;
  final ResolvedIdentifier Function(Identifier) _resolveIdentifier;
  final TypeAnnotation? Function(OmittedTypeAnnotation) _typeInferrer;
  final Map<OmittedTypeAnnotation, String>? _omittedTypes;

  final Map<Uri, _SynthesizedNamePart> _importNames = {};
  final Map<OmittedTypeAnnotation, _SynthesizedNamePart> _typeNames = {};
  final List<_AppliedPart<_Part>> _importParts = [];
  final List<_AppliedPart<_Part>> _directivesParts = [];
  final List<_AppliedPart<_StringPart>> _stringParts = [];
  List<_AppliedPart<_StringPart>> _directivesStringPartBuffer = [];

  // Keeps track of the last part written in `lastDirectivePart`.
  String _lastDirectivePart = '';

  _Builder(this._augmentedLibraryUri, this._resolveDeclaration,
      this._resolveIdentifier, this._typeInferrer, this._omittedTypes);

  void _flushStringParts() {
    if (_directivesStringPartBuffer.isNotEmpty) {
      _directivesParts.addAll(_directivesStringPartBuffer);
      _stringParts.addAll(_directivesStringPartBuffer);
      _directivesStringPartBuffer = [];
    }
  }

  void _writeDirectiveStringPart(Key key, String part) {
    _lastDirectivePart = part;
    _directivesStringPartBuffer.add(_AppliedPart.string(key, part));
  }

  void _writeDirectiveSynthesizedNamePart(Key key, _SynthesizedNamePart part) {
    _flushStringParts();
    _lastDirectivePart = '';
    _directivesParts.add(_AppliedPart.synthesized(key, part));
  }

  void _buildString(Key parent, int index, String part) {
    _writeDirectiveStringPart(ContentKey.string(parent, index), part);
  }

  void _buildIdentifier(Key parent, int index, Identifier part) {
    ResolvedIdentifier resolved = _resolveIdentifier(part);
    _SynthesizedNamePart? prefix;
    Uri? resolvedUri = resolved.uri;
    if (resolvedUri != null) {
      prefix = _importNames.putIfAbsent(resolvedUri, () {
        _SynthesizedNamePart prefix = _SynthesizedNamePart();
        _importParts.add(_AppliedPart.string(
            UriKey.importPrefix(resolvedUri), "import '$resolvedUri' as "));
        _importParts.add(_AppliedPart.synthesized(
            UriKey.prefixDefinition(resolvedUri), prefix));
        _importParts
            .add(_AppliedPart.string(UriKey.importSuffix(resolvedUri), ";\n"));
        return prefix;
      });
    }
    if (resolved.kind == IdentifierKind.instanceMember) {
      // Qualify with `this.` if we don't have a receiver.
      if (!_lastDirectivePart.trimRight().endsWith('.')) {
        _writeDirectiveStringPart(
            ContentKey.implicitThis(parent, index), 'this.');
      }
    } else if (prefix != null) {
      _writeDirectiveSynthesizedNamePart(
          PrefixUseKey(parent, index, resolvedUri!), prefix);
      _writeDirectiveStringPart(ContentKey.prefixDot(parent, index), '.');
    }
    if (resolved.kind == IdentifierKind.staticInstanceMember) {
      _writeDirectiveStringPart(
          ContentKey.staticScope(parent, index), '${resolved.staticScope!}.');
    }
    _writeDirectiveStringPart(
        ContentKey.identifierName(parent, index), part.name);
  }

  void _buildOmittedTypeAnnotation(
      Key parent, int index, OmittedTypeAnnotation part) {
    TypeAnnotation? type = _typeInferrer(part);
    Key typeAnnotationKey = OmittedTypeAnnotationKey(parent, index, part);
    if (type == null) {
      if (_omittedTypes != null) {
        _SynthesizedNamePart name =
            _typeNames.putIfAbsent(part, () => _SynthesizedNamePart());
        _writeDirectiveSynthesizedNamePart(typeAnnotationKey, name);
      } else {
        throw ArgumentError("No type inferred for $part");
      }
    } else {
      _buildCode(typeAnnotationKey, type.code);
    }
  }

  void _buildCode(Key parent, Code code) {
    List<Object> parts = code.parts;
    for (int index = 0; index < parts.length; index++) {
      Object part = parts[index];
      if (part is String) {
        _buildString(parent, index, part);
      } else if (part is Code) {
        _buildCode(ContentKey.code(parent, index), part);
      } else if (part is Identifier) {
        _buildIdentifier(parent, index, part);
      } else if (part is OmittedTypeAnnotation) {
        _buildOmittedTypeAnnotation(parent, index, part);
      } else {
        throw ArgumentError(
            'Code objects only support String, Identifier, and Code '
            'instances but got $part which was not one of those.');
      }
    }
  }

  String build(Iterable<MacroExecutionResult> macroResults,
      {List<Span>? spans}) {
    Map<Identifier, List<(Key, DeclarationCode)>> mergedTypeResults = {};
    Map<Identifier, List<(Key, DeclarationCode)>> mergedEntryResults = {};
    Map<Identifier, (Key, NamedTypeAnnotationCode)> mergedExtendsResults = {};
    Map<Identifier, List<(Key, TypeAnnotationCode)>> mergedInterfaceResults =
        {};
    Map<Identifier, List<(Key, TypeAnnotationCode)>> mergedMixinResults = {};
    for (MacroExecutionResult result in macroResults) {
      Key key = MacroExecutionResultKey(result);
      int index = 0;
      for (DeclarationCode augmentation in result.libraryAugmentations) {
        _buildCode(ContentKey.libraryAugmentation(key, index), augmentation);
        _writeDirectiveStringPart(
            ContentKey.libraryAugmentationSeparator(key, index), '\n');
        index++;
      }
      result.enumValueAugmentations.forEach((identifier, value) {
        int index = 0;
        final Iterable<(Key, DeclarationCode)> values = value
            .map((e) => (IdentifierKey.enum_(key, index++, identifier), e));
        mergedEntryResults.update(
            identifier, (enumValues) => enumValues..addAll(values),
            ifAbsent: () => values.toList());
      });
      result.extendsTypeAugmentations.forEach((identifier, value) {
        mergedExtendsResults.update(
            identifier,
            (existing) => throw StateError(
                'A class cannot extend multiple classes, ${identifier.name} '
                'tried to extend both ${existing.$2.name.name} and '
                '${value.name.name}.'),
            ifAbsent: () => (IdentifierKey.superclass(key, identifier), value));
      });
      result.interfaceAugmentations.forEach((identifier, value) {
        int index = 0;
        final Iterable<(Key, TypeAnnotationCode)> values = value
            .map((e) => (IdentifierKey.interface(key, index++, identifier), e));
        mergedInterfaceResults.update(
            identifier, (declarations) => declarations..addAll(values),
            ifAbsent: () => values.toList());
      });
      result.mixinAugmentations.forEach((identifier, value) {
        int index = 0;
        final Iterable<(Key, TypeAnnotationCode)> values = value
            .map((e) => (IdentifierKey.mixin(key, index++, identifier), e));
        mergedMixinResults.update(
            identifier, (declarations) => declarations..addAll(values),
            ifAbsent: () => values.toList());
      });
      result.typeAugmentations.forEach((identifier, value) {
        int index = 0;
        final Iterable<(Key, DeclarationCode)> values = value
            .map((e) => (IdentifierKey.member(key, index++, identifier), e));
        mergedTypeResults.update(
            identifier, (declarations) => declarations..addAll(values),
            ifAbsent: () => values.toList());
      });
    }
    final Set<Identifier> mergedAugmentedTypes = {
      ...mergedEntryResults.keys,
      ...mergedExtendsResults.keys,
      ...mergedInterfaceResults.keys,
      ...mergedMixinResults.keys,
      ...mergedTypeResults.keys,
    };
    for (Identifier type in mergedAugmentedTypes) {
      final TypeDeclaration typeDeclaration = _resolveDeclaration(type);
      final TypeDeclarationKey key = TypeDeclarationKey(typeDeclaration);
      String declarationKind = switch (typeDeclaration) {
        ClassDeclaration() => 'class',
        EnumDeclaration() => 'enum',
        ExtensionDeclaration() => 'extension',
        MixinDeclaration() => 'mixin',
        _ => throw UnsupportedError(
            'Unsupported augmentation type $typeDeclaration'),
      };
      final List<String> keywords = [
        if (typeDeclaration is ClassDeclaration) ...[
          if (typeDeclaration.hasAbstract) 'abstract',
          if (typeDeclaration.hasBase) 'base',
          if (typeDeclaration.hasExternal) 'external',
          if (typeDeclaration.hasFinal) 'final',
          if (typeDeclaration.hasInterface) 'interface',
          if (typeDeclaration.hasMixin) 'mixin',
          if (typeDeclaration.hasSealed) 'sealed',
        ] else if (typeDeclaration is MixinDeclaration &&
            typeDeclaration.hasBase)
          'base',
      ];
      // Has the effect of adding a space after the keywords
      if (keywords.isNotEmpty) keywords.add('');

      var hasTypeParams = typeDeclaration is ParameterizedTypeDeclaration &&
          typeDeclaration.typeParameters.isNotEmpty;
      _writeDirectiveStringPart(TypeDeclarationContentKey.declaration(key),
          'augment ${keywords.join(' ')}$declarationKind ${type.name}${hasTypeParams ? '' : ' '}');

      if (hasTypeParams) {
        var typeParameters = typeDeclaration.typeParameters;
        _writeDirectiveStringPart(
            TypeDeclarationContentKey.typeParametersStart(key), '<');
        for (var param in typeParameters) {
          _buildCode(
              key,
              param == typeParameters.first
                  ? param.code
                  : RawCode.fromParts([', ', param.code]));
        }
        _writeDirectiveStringPart(
            TypeDeclarationContentKey.typeParametersEnd(key), '> ');
      }

      if (mergedExtendsResults[type] case (var superclassKey, var superclass)) {
        Key fixedKey = TypeDeclarationContentKey.superclass(key);
        int index = 0;
        _buildString(fixedKey, index++, 'extends ');
        _buildCode(superclassKey, superclass);
        _buildString(fixedKey, index++, ' ');
      }

      if (mergedMixinResults[type] case var mixins? when mixins.isNotEmpty) {
        Key mixinsKey = TypeDeclarationContentKey.mixins(key);
        int index = 0;
        _buildString(mixinsKey, index++, 'with ');
        bool needsComma = false;
        for (var (Key key, TypeAnnotationCode mixin) in mixins) {
          if (needsComma) {
            _buildString(mixinsKey, index++, ', ');
          }
          _buildCode(key, mixin);
          needsComma = true;
        }
        _buildString(mixinsKey, index++, ' ');
      }

      if (mergedInterfaceResults[type] case var interfaces?
          when interfaces.isNotEmpty) {
        Key interfacesKey = TypeDeclarationContentKey.interfaces(key);
        int index = 0;
        _buildString(interfacesKey, index++, 'implements ');
        bool needsComma = false;
        for (var (Key key, TypeAnnotationCode interface) in interfaces) {
          if (needsComma) {
            _buildString(interfacesKey, index++, ', ');
          }
          _buildCode(key, interface);
          needsComma = true;
        }
        _buildString(interfacesKey, index++, ' ');
      }

      _writeDirectiveStringPart(
          TypeDeclarationContentKey.bodyStart(key), '{\n');
      if (typeDeclaration is EnumDeclaration) {
        for (var (Key key, DeclarationCode entryAugmentation)
            in mergedEntryResults[type] ?? []) {
          _buildCode(key, entryAugmentation);
        }
        _writeDirectiveStringPart(
            TypeDeclarationContentKey.enumValueEnd(key), ';\n');
      }
      for (var (Key key, DeclarationCode augmentation)
          in mergedTypeResults[type] ?? []) {
        _buildCode(key, augmentation);
        _writeDirectiveStringPart(
            TypeDeclarationContentKey.declarationSeparator(key), '\n');
      }
      _writeDirectiveStringPart(TypeDeclarationContentKey.bodyEnd(key), '}\n');
    }
    _flushStringParts();

    if (_importNames.isNotEmpty) {
      String prefix = _computeFreshPrefix(_stringParts, 'prefix');
      int index = 0;
      for (_SynthesizedNamePart part in _importNames.values) {
        part.text = '$prefix${index++}';
      }
    }
    if (_omittedTypes != null && _typeNames.isNotEmpty) {
      String prefix = _computeFreshPrefix(_stringParts, 'OmittedType');
      int index = 0;
      _typeNames.forEach(
          (OmittedTypeAnnotation omittedType, _SynthesizedNamePart part) {
        String name = '$prefix${index++}';
        part.text = name;
        _omittedTypes[omittedType] = name;
      });
    }

    StringBuffer sb = StringBuffer();

    void addText(Key key, String text) {
      spans?.add(Span(key, sb.length, text));
      sb.write(text);
    }

    addText(const LibraryAugmentKey(),
        'augment library \'$_augmentedLibraryUri\';\n\n');
    for (_AppliedPart<_Part> appliedPart in _importParts) {
      addText(appliedPart.key, appliedPart.part.text);
    }
    if (_importParts.isNotEmpty) {
      addText(const ImportDeclarationSeparatorKey(), '\n');
    }
    for (_AppliedPart<_Part> appliedPart in _directivesParts) {
      addText(appliedPart.key, appliedPart.part.text);
    }
    addText(const EndOfFileKey(), "");

    return sb.toString();
  }
}

class _AppliedPart<T extends _Part> {
  final Key key;
  final T part;

  _AppliedPart(this.key, this.part);

  static _AppliedPart<_StringPart> string(Key key, String part) =>
      _AppliedPart<_StringPart>(key, _StringPart(part));

  static _AppliedPart<_SynthesizedNamePart> synthesized(
          Key key, _SynthesizedNamePart part) =>
      _AppliedPart<_SynthesizedNamePart>(key, part);
}

abstract class _Part {
  String get text;
}

class _SynthesizedNamePart implements _Part {
  @override
  late String text;
}

class _StringPart implements _Part {
  @override
  final String text;

  _StringPart(this.text);
}

/// Computes a name starting with [name] that is unique with respect to the
/// text in [stringParts].
///
/// This algorithm assumes that no two parts in [stringParts] occur in direct
/// sequence where they are used, i.e. there is always at least one
/// [_SynthesizedNamePart] between them.
String _computeFreshPrefix(
    List<_AppliedPart<_StringPart>> stringParts, String name) {
  int index = -1;
  String prefix = name;
  for (_AppliedPart<_StringPart> appliedPart in stringParts) {
    while (appliedPart.part.text.contains(prefix)) {
      index++;
      prefix = '$name$index';
    }
  }

  if (index > 0) {
    // Add a separator when an index was needed. This is to ensure that
    // suffixing number to [prefix] doesn't blend the digits.
    prefix = '${prefix}_';
  }
  return prefix;
}
