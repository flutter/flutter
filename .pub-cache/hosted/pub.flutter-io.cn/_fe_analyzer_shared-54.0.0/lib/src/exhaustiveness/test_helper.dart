// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/exhaustive.dart';

import 'space.dart';
import 'static_type.dart';

/// Tags used for id-testing of exhaustiveness.
class Tags {
  static const String error = 'error';
  static const String scrutineeType = 'type';
  static const String scrutineeFields = 'fields';
  static const String space = 'space';
  static const String subtypes = 'subtypes';
  static const String remaining = 'remaining';
}

/// Returns a textual representation for [space] used for testing.
String spaceToText(Space space) => space.toString();

/// Returns a textual representation for [fields] used for testing.
String fieldsToText(Map<String, StaticType> fields) {
  // TODO(johnniwinther): Enforce that field maps are always sorted.
  List<String> sortedNames = fields.keys.toList()..sort();
  StringBuffer sb = new StringBuffer();
  String comma = '';
  sb.write('{');
  for (String name in sortedNames) {
    if (name.startsWith('_')) {
      // Avoid implementation specific fields, like `Object._identityHashCode`
      // and `Enum._name`.
      // TODO(johnniwinther): Support private fields in the test code.
      continue;
    }
    sb.write(comma);
    sb.write(name);
    sb.write(':');
    sb.write(staticTypeToText(fields[name]!));
    comma = ',';
  }
  sb.write('}');
  return sb.toString();
}

/// Returns a textual representation for [type] used for testing.
String staticTypeToText(StaticType type) => type.toString();

/// Returns a textual representation of the subtypes of [type] used for testing.
String? subtypesToText(StaticType type) {
  List<StaticType> subtypes = type.subtypes.toList();
  if (subtypes.isEmpty) return null;
  // TODO(johnniwinther): Sort subtypes.
  StringBuffer sb = new StringBuffer();
  String comma = '';
  sb.write('{');
  for (StaticType subtype in subtypes) {
    sb.write(comma);
    sb.write(staticTypeToText(subtype));
    comma = ',';
  }
  sb.write('}');
  return sb.toString();
}

String errorToText(ExhaustivenessError error) {
  if (error is NonExhaustiveError) {
    return 'non-exhaustive:${error.witness}';
  } else {
    assert(error is UnreachableCaseError);
    return 'unreachable';
  }
}
