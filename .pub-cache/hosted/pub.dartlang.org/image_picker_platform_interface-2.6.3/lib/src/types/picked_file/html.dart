// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http show readBytes;

import './base.dart';

/// A PickedFile that works on web.
///
/// It wraps the bytes of a selected file.
class PickedFile extends PickedFileBase {
  /// Construct a PickedFile object from its ObjectUrl.
  ///
  /// Optionally, this can be initialized with `bytes`
  /// so no http requests are performed to retrieve files later.
  const PickedFile(this.path, {Uint8List? bytes})
      : _initBytes = bytes,
        super(path);

  @override
  final String path;
  final Uint8List? _initBytes;

  Future<Uint8List> get _bytes async {
    if (_initBytes != null) {
      return Future<Uint8List>.value(UnmodifiableUint8ListView(_initBytes!));
    }
    return http.readBytes(Uri.parse(path));
  }

  @override
  Future<String> readAsString({Encoding encoding = utf8}) async {
    return encoding.decode(await _bytes);
  }

  @override
  Future<Uint8List> readAsBytes() async {
    return Future<Uint8List>.value(await _bytes);
  }

  @override
  Stream<Uint8List> openRead([int? start, int? end]) async* {
    final Uint8List bytes = await _bytes;
    yield bytes.sublist(start ?? 0, end ?? bytes.length);
  }
}
