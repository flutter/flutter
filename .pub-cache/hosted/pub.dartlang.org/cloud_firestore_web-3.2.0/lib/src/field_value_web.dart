// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'interop/firestore.dart' as firestore_interop;

/// Implementation of [FieldValuePlatform] that is compatible with
/// the Firestore web plugin.

class FieldValueWeb {
  /// The js-interop delegate for this [FieldValuePlatform]
  firestore_interop.FieldValue data;

  /// Constructs a web version of [FieldValuePlatform] wrapping a web [FieldValue].
  FieldValueWeb(this.data);

  @override
  //ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is FieldValueWeb && other.data == data;

  @override
  //ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => data.hashCode;
}
