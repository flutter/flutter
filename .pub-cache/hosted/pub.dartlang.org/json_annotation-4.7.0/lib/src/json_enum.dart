// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta_meta.dart';

import 'json_serializable.dart';
import 'json_value.dart';

/// Allows configuration of how `enum` elements are treated as JSON.
@Target({TargetKind.enumType})
class JsonEnum {
  const JsonEnum({
    this.alwaysCreate = false,
    this.fieldRename = FieldRename.none,
    this.valueField,
  });

  /// If `true`, `_$[enum name]EnumMap` is generated for in library containing
  /// the `enum`, even if the `enum` is not used as a field in a class annotated
  /// with [JsonSerializable].
  ///
  /// The default, `false`, means no extra helpers are generated for this `enum`
  /// unless it is used by a class annotated with [JsonSerializable].
  final bool alwaysCreate;

  /// Defines the naming strategy when converting enum entry names to JSON
  /// values.
  ///
  /// With a value [FieldRename.none] (the default), the name of the enum entry
  /// is used without modification.
  ///
  /// See [FieldRename] for details on the other options.
  ///
  /// Note: the value for [JsonValue.value] takes precedence over this option
  /// for entries annotated with [JsonValue].
  final FieldRename fieldRename;

  /// Specifies the field within an "enhanced enum" to use as the value
  /// to use for serialization.
  ///
  /// If an individual `enum` element is annotated with `@JsonValue`
  /// that value still takes precedence.
  final String? valueField;
}
