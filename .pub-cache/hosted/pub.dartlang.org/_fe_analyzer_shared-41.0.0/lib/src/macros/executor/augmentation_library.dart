// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../api.dart';
import '../executor.dart';

/// A mixin which provides a shared implementation of
/// [MacroExecutor.buildAugmentationLibrary].
mixin AugmentationLibraryBuilder on MacroExecutor {
  @override
  String buildAugmentationLibrary(
      Iterable<MacroExecutionResult> macroResults,
      ResolvedIdentifier Function(Identifier) resolveIdentifier,
      TypeAnnotation? Function(OmittedTypeAnnotation) typeInferrer,
      {Map<OmittedTypeAnnotation, String>? omittedTypes}) {
    Map<Uri, _SynthesizedNamePart> importNames = {};
    Map<OmittedTypeAnnotation, _SynthesizedNamePart> typeNames = {};
    List<_Part> importParts = [];
    List<_Part> directivesParts = [];
    List<_StringPart> stringParts = [];
    StringBuffer directivesStringPartBuffer = new StringBuffer();

    void flushStringParts() {
      if (directivesStringPartBuffer.isNotEmpty) {
        _StringPart stringPart =
            new _StringPart(directivesStringPartBuffer.toString());
        directivesParts.add(stringPart);
        stringParts.add(stringPart);
        directivesStringPartBuffer = new StringBuffer();
      }
    }

    // Keeps track of the last part written in `lastDirectivePart`.
    String lastDirectivePart = '';
    void writeDirectiveStringPart(String part) {
      lastDirectivePart = part;
      directivesStringPartBuffer.write(part);
    }

    void writeDirectiveSynthesizedNamePart(_SynthesizedNamePart part) {
      flushStringParts();
      lastDirectivePart = '';
      directivesParts.add(part);
    }

    void buildCode(Code code) {
      for (Object part in code.parts) {
        if (part is String) {
          writeDirectiveStringPart(part);
        } else if (part is Code) {
          buildCode(part);
        } else if (part is Identifier) {
          ResolvedIdentifier resolved = resolveIdentifier(part);
          _SynthesizedNamePart? prefix;
          if (resolved.uri != null) {
            prefix = importNames.putIfAbsent(resolved.uri!, () {
              _SynthesizedNamePart prefix = new _SynthesizedNamePart();
              importParts.add(new _StringPart("import '${resolved.uri}' as "));
              importParts.add(prefix);
              importParts.add(new _StringPart(";\n"));
              return prefix;
            });
          }
          if (resolved.kind == IdentifierKind.instanceMember) {
            // Qualify with `this.` if we don't have a receiver.
            if (!lastDirectivePart.trimRight().endsWith('.')) {
              writeDirectiveStringPart('this.');
            }
          } else if (prefix != null) {
            writeDirectiveSynthesizedNamePart(prefix);
            writeDirectiveStringPart('.');
          }
          if (resolved.kind == IdentifierKind.staticInstanceMember) {
            writeDirectiveStringPart('${resolved.staticScope!}.');
          }
          writeDirectiveStringPart('${part.name}');
        } else if (part is OmittedTypeAnnotation) {
          TypeAnnotation? type = typeInferrer(part);
          if (type == null) {
            if (omittedTypes != null) {
              _SynthesizedNamePart name =
                  typeNames.putIfAbsent(part, () => new _SynthesizedNamePart());
              writeDirectiveSynthesizedNamePart(name);
            } else {
              throw new ArgumentError("No type inferred for $part");
            }
          } else {
            buildCode(type.code);
          }
        } else {
          throw new ArgumentError(
              'Code objects only support String, Identifier, and Code '
              'instances but got $part which was not one of those.');
        }
      }
    }

    Map<String, List<DeclarationCode>> mergedClassResults = {};
    for (MacroExecutionResult result in macroResults) {
      for (DeclarationCode augmentation in result.libraryAugmentations) {
        buildCode(augmentation);
        writeDirectiveStringPart('\n');
      }
      for (MapEntry<String, Iterable<DeclarationCode>> entry
          in result.classAugmentations.entries) {
        mergedClassResults.update(
            entry.key, (value) => value..addAll(entry.value),
            ifAbsent: () => entry.value.toList());
      }
    }
    for (MapEntry<String, List<DeclarationCode>> entry
        in mergedClassResults.entries) {
      writeDirectiveStringPart('augment class ${entry.key} {\n');
      for (DeclarationCode augmentation in entry.value) {
        buildCode(augmentation);
        writeDirectiveStringPart('\n');
      }
      writeDirectiveStringPart('}\n');
    }
    flushStringParts();

    if (importNames.isNotEmpty) {
      String prefix = _computeFreshPrefix(stringParts, 'prefix');
      int index = 0;
      for (_SynthesizedNamePart part in importNames.values) {
        part.text = '$prefix${index++}';
      }
    }
    if (omittedTypes != null && typeNames.isNotEmpty) {
      String prefix = _computeFreshPrefix(stringParts, 'OmittedType');
      int index = 0;
      typeNames.forEach(
          (OmittedTypeAnnotation omittedType, _SynthesizedNamePart part) {
        String name = '$prefix${index++}';
        part.text = name;
        omittedTypes[omittedType] = name;
      });
    }

    StringBuffer sb = new StringBuffer();
    for (_Part part in importParts) {
      sb.write(part.text);
    }
    sb.write('\n');
    for (_Part part in directivesParts) {
      sb.write(part.text);
    }

    return sb.toString();
  }
}

abstract class _Part {
  String get text;
}

class _SynthesizedNamePart implements _Part {
  late String text;
}

class _StringPart implements _Part {
  final String text;

  _StringPart(this.text);
}

/// Computes a name starting with [name] that is unique with respect to the
/// text in [stringParts].
///
/// This algorithm assumes that no two parts in [stringParts] occur in direct
/// sequence where they are used, i.e. there is always at least one
/// [_SynthesizedNamePart] between them.
String _computeFreshPrefix(List<_StringPart> stringParts, String name) {
  int index = -1;
  String prefix = name;
  for (_StringPart part in stringParts) {
    while (part.text.contains(prefix)) {
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
