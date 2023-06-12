// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary2/combinator.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/reference.dart';

class Export {
  final LibraryBuilder exporter;
  final int index;
  final List<Combinator> combinators;

  Export(this.exporter, this.index, this.combinators);

  bool addToExportScope(String name, ExportedReference exported) {
    if (combinators.allows(name)) {
      return exporter.exportScope.export(index, name, exported);
    }
    return false;
  }
}

class ExportedReference {
  final Reference reference;

  ExportedReference({
    required this.reference,
  });

  @override
  String toString() {
    return '$reference';
  }
}

/// [ExportedReference] for a public element declared in the library.
class ExportedReferenceDeclared extends ExportedReference {
  ExportedReferenceDeclared({
    required super.reference,
  });
}

/// [ExportedReference] for an element that is re-exported.
class ExportedReferenceExported extends ExportedReference {
  /// The indexes of `export` directives (at least one) that export the element.
  final List<int> indexes;

  ExportedReferenceExported({
    required super.reference,
    required this.indexes,
  });

  void addExportIndex(int index) {
    if (!indexes.contains(index)) {
      indexes.add(index);
    }
  }
}

class ExportScope {
  final Map<String, ExportedReference> map = {};

  void declare(String name, Reference reference) {
    map[name] = ExportedReferenceDeclared(
      reference: reference,
    );
  }

  bool export(int index, String name, ExportedReference exported) {
    final existing = map[name];
    if (existing?.reference == exported.reference) {
      if (existing is ExportedReferenceExported) {
        existing.addExportIndex(index);
      }
      return false;
    }

    // Ambiguous declaration detected.
    if (existing != null) return false;

    map[name] = ExportedReferenceExported(
      reference: exported.reference,
      indexes: [index],
    );
    return true;
  }

  void forEach(void Function(String name, ExportedReference reference) f) {
    map.forEach(f);
  }
}
