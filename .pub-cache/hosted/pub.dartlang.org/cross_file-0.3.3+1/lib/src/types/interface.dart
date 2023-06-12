// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:meta/meta.dart';

import './base.dart';

// ignore_for_file: avoid_unused_constructor_parameters

/// A CrossFile is a cross-platform, simplified File abstraction.
///
/// It wraps the bytes of a selected file, and its (platform-dependant) path.
class XFile extends XFileBase {
  /// Construct a CrossFile object from its path.
  ///
  /// Optionally, this can be initialized with `bytes` and `length`
  /// so no http requests are performed to retrieve data later.
  ///
  /// `name` may be passed from the outside, for those cases where the effective
  /// `path` of the file doesn't match what the user sees when selecting it
  /// (like in web)
  XFile(
    String path, {
    String? mimeType,
    String? name,
    int? length,
    Uint8List? bytes,
    DateTime? lastModified,
    @visibleForTesting CrossFileTestOverrides? overrides,
  }) : super(path) {
    throw UnimplementedError(
        'CrossFile is not available in your current platform.');
  }

  /// Construct a CrossFile object from its data
  XFile.fromData(
    Uint8List bytes, {
    String? mimeType,
    String? name,
    int? length,
    DateTime? lastModified,
    String? path,
    @visibleForTesting CrossFileTestOverrides? overrides,
  }) : super(path) {
    throw UnimplementedError(
        'CrossFile is not available in your current platform.');
  }
}

/// Overrides some functions of CrossFile for testing purposes
@visibleForTesting
class CrossFileTestOverrides {
  /// Default constructor for overrides
  CrossFileTestOverrides({required this.createAnchorElement});

  /// For overriding the creation of the file input element.
  dynamic Function(String href, String suggestedName) createAnchorElement;
}
