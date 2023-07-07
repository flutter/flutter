// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:js/js_util.dart';

import 'field_value_web.dart';
import 'utils/encode_utility.dart';
import 'interop/firestore.dart' as firestore_interop;

/// An implementation of [FieldValueFactoryPlatform] which builds [FieldValuePlatform]
/// instances that are [jsify] friendly.
class FieldValueFactoryWeb extends FieldValueFactoryPlatform {
  @override
  FieldValueWeb arrayRemove(List elements) =>
      FieldValueWeb(firestore_interop.FieldValue.arrayRemove(
          EncodeUtility.valueEncode(elements)));

  @override
  FieldValueWeb arrayUnion(List elements) =>
      FieldValueWeb(firestore_interop.FieldValue.arrayUnion(
          EncodeUtility.valueEncode(elements)));

  @override
  FieldValueWeb delete() =>
      FieldValueWeb(firestore_interop.FieldValue.delete());

  @override
  FieldValueWeb increment(num value) =>
      FieldValueWeb(firestore_interop.FieldValue.increment(value));

  @override
  FieldValueWeb serverTimestamp() =>
      FieldValueWeb(firestore_interop.FieldValue.serverTimestamp());
}
