// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary2/combinator.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/reference.dart';

class Export {
  final LibraryBuilder exporter;
  final LibraryBuilder? exported;
  final List<Combinator> combinators;

  Export(this.exporter, this.exported, this.combinators);

  bool addToExportScope(String name, Reference reference) {
    for (Combinator combinator in combinators) {
      if (combinator.isShow && !combinator.matches(name)) return false;
      if (combinator.isHide && combinator.matches(name)) return false;
    }
    return exporter.addToExportScope(name, reference);
  }
}
