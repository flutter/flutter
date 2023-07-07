// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show immutable;

/// Represents binary data stored in [Uint8List].
@immutable
class Blob {
  /// Creates a blob.
  const Blob(this.bytes);

  /// The bytes that are contained in this blob.
  final Uint8List bytes;

  @override
  bool operator ==(Object other) =>
      other is Blob &&
      const DeepCollectionEquality().equals(other.bytes, bytes);

  @override
  int get hashCode => Object.hashAll(bytes);
}
