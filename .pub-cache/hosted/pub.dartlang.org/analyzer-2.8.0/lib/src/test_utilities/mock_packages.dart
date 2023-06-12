// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';

/// Helper for creating mock packages.
class MockPackages {
  /// Create a fake 'js' package that can be used by tests.
  static void addJsPackageFiles(Folder rootFolder) {
    var libFolder = rootFolder.getChildAssumingFolder('lib');
    libFolder.getChildAssumingFile('js.dart').writeAsStringSync(r'''
library js;

class JS {
  const JS([String js]);
}
''');
  }

  /// Create a fake 'meta' package that can be used by tests.
  static void addMetaPackageFiles(Folder rootFolder) {
    var libFolder = rootFolder.getChildAssumingFolder('lib');
    libFolder.getChildAssumingFile('meta.dart').writeAsStringSync(r'''
library meta;

const _AlwaysThrows alwaysThrows = const _AlwaysThrows();
const _DoNotStore doNotStore = _DoNotStore();
const _Factory factory = const _Factory();
const Immutable immutable = const Immutable();
const _Internal internal = const Internal();
const _Literal literal = const _Literal();
const _MustCallSuper mustCallSuper = const _MustCallSuper();
const _NonVirtual nonVirtual = const _NonVirtual();
const _OptionalTypeArgs optionalTypeArgs = const _OptionalTypeArgs();
const _Protected protected = const _Protected();
const Required required = const Required();
const _Sealed sealed = const _Sealed();
const UseResult useResult = UseResult();
const _VisibleForOverriding visibleForOverriding = _VisibleForOverriding();
const _VisibleForTesting visibleForTesting = const _VisibleForTesting();

class _AlwaysThrows {
  const _AlwaysThrows();
}
@Target({
  TargetKind.field,
  TargetKind.function,
  TargetKind.getter,
  TargetKind.method,
  TargetKind.topLevelVariable,
})
class _DoNotStore {
  const _DoNotStore();
}
class _Factory {
  const _Factory();
}
class Immutable {
  final String reason;
  const Immutable([this.reason]);
}
class _Internal {
  const Internal();
}
class _Literal {
  const _Literal();
}
class _MustCallSuper {
  const _MustCallSuper();
}
class _NonVirtual {
  const _NonVirtual();
}
class _OptionalTypeArgs {
  const _OptionalTypeArgs();
}
class _Protected {
  const _Protected();
}
class Required {
  final String reason;
  const Required([this.reason]);
}
class _Sealed {
  const _Sealed();
}
class UseResult {
  final String? parameterDefined;
  final String reason;
  const UseResult([this.reason = '']);
  const UseResult.unless({required this.parameterDefined, this.reason = ''});
}
class _VisibleForOverriding {
  const _VisibleForOverriding();
}
class _VisibleForTesting {
  const _VisibleForTesting();
}
''');
    libFolder.getChildAssumingFile('meta_meta.dart').writeAsStringSync(r'''
library meta_meta;

class Target {
  final Set<TargetKind> kinds;
  const Target(this.kinds);
}
enum TargetKind {
  classType,
  enumType,
  extension,
  field,
  function,
  library,
  getter,
  method,
  mixinType,
  parameter,
  setter,
  topLevelVariable,
  type,
  typedefType,
}
''');
  }
}
