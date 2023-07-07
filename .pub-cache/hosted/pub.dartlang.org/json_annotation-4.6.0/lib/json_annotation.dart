// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Provides annotation classes to use with
/// [json_serializable](https://pub.dev/packages/json_serializable).
///
/// Also contains helper functions and classes – prefixed with `$` used by
/// `json_serializable` when the `use_wrappers` or `checked` options are
/// enabled.
library json_annotation;

export 'src/allowed_keys_helpers.dart';
export 'src/checked_helpers.dart';
export 'src/enum_helpers.dart';
export 'src/json_converter.dart';
export 'src/json_enum.dart';
export 'src/json_key.dart';
export 'src/json_literal.dart';
export 'src/json_serializable.dart';
export 'src/json_value.dart';
