// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

/// The interface for a CrossFile.
///
/// A CrossFile is a container that wraps the path of a selected
/// file by the user and (in some platforms, like web) the bytes
/// with the contents of the file.
///
/// This class is a very limited subset of dart:io [File], so all
/// the methods should seem familiar.
abstract class XFileBase {
  /// Construct a CrossFile
  // ignore: avoid_unused_constructor_parameters
  XFileBase(String? path);

  /// Save the CrossFile at the indicated file path.
  Future<void> saveTo(String path) {
    throw UnimplementedError('saveTo has not been implemented.');
  }

  /// Get the path of the picked file.
  ///
  /// This should only be used as a backwards-compatibility clutch
  /// for mobile apps, or cosmetic reasons only (to show the user
  /// the path they've picked).
  ///
  /// Accessing the data contained in the picked file by its path
  /// is platform-dependant (and won't work on web), so use the
  /// byte getters in the CrossFile instance instead.
  String get path {
    throw UnimplementedError('.path has not been implemented.');
  }

  /// The name of the file as it was selected by the user in their device.
  ///
  /// Use only for cosmetic reasons, do not try to use this as a path.
  String get name {
    throw UnimplementedError('.name has not been implemented.');
  }

  /// For web, it may be necessary for a file to know its MIME type.
  String? get mimeType {
    throw UnimplementedError('.mimeType has not been implemented.');
  }

  /// Get the length of the file. Returns a `Future<int>` that completes with the length in bytes.
  Future<int> length() {
    throw UnimplementedError('.length() has not been implemented.');
  }

  /// Asynchronously read the entire file contents as a string using the given [Encoding].
  ///
  /// By default, `encoding` is [utf8].
  ///
  /// Throws Exception if the operation fails.
  Future<String> readAsString({Encoding encoding = utf8}) {
    throw UnimplementedError('readAsString() has not been implemented.');
  }

  /// Asynchronously read the entire file contents as a list of bytes.
  ///
  /// Throws Exception if the operation fails.
  Future<Uint8List> readAsBytes() {
    throw UnimplementedError('readAsBytes() has not been implemented.');
  }

  /// Create a new independent [Stream] for the contents of this file.
  ///
  /// If `start` is present, the file will be read from byte-offset `start`. Otherwise from the beginning (index 0).
  ///
  /// If `end` is present, only up to byte-index `end` will be read. Otherwise, until end of file.
  ///
  /// In order to make sure that system resources are freed, the stream must be read to completion or the subscription on the stream must be cancelled.
  Stream<Uint8List> openRead([int? start, int? end]) {
    throw UnimplementedError('openRead() has not been implemented.');
  }

  /// Get the last-modified time for the CrossFile
  Future<DateTime> lastModified() {
    throw UnimplementedError('lastModified() has not been implemented.');
  }
}
