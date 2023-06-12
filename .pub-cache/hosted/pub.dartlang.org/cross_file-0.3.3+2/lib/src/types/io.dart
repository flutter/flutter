// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import './base.dart';

// ignore_for_file: avoid_unused_constructor_parameters

/// A CrossFile backed by a dart:io File.
class XFile extends XFileBase {
  /// Construct a CrossFile object backed by a dart:io File.
  ///
  /// [bytes] is ignored; the parameter exists only to match the web version of
  /// the constructor. To construct a dart:io XFile from bytes, use
  /// [XFile.fromData].
  XFile(
    String path, {
    String? mimeType,
    String? name,
    int? length,
    Uint8List? bytes,
    DateTime? lastModified,
  })  : _mimeType = mimeType,
        _file = File(path),
        _bytes = null,
        _lastModified = lastModified,
        super(path);

  /// Construct an CrossFile from its data
  XFile.fromData(
    Uint8List bytes, {
    String? mimeType,
    String? path,
    String? name,
    int? length,
    DateTime? lastModified,
  })  : _mimeType = mimeType,
        _bytes = bytes,
        _file = File(path ?? ''),
        _length = length,
        _lastModified = lastModified,
        super(path) {
    if (length == null) {
      _length = bytes.length;
    }
  }

  final File _file;
  final String? _mimeType;
  final DateTime? _lastModified;
  int? _length;

  final Uint8List? _bytes;

  @override
  Future<DateTime> lastModified() {
    if (_lastModified != null) {
      return Future<DateTime>.value(_lastModified);
    }
    // ignore: avoid_slow_async_io
    return _file.lastModified();
  }

  @override
  Future<void> saveTo(String path) async {
    if (_bytes == null) {
      await _file.copy(path);
    } else {
      final File fileToSave = File(path);
      await fileToSave.writeAsBytes(_bytes!);
    }
  }

  @override
  String? get mimeType => _mimeType;

  @override
  String get path => _file.path;

  @override
  String get name => _file.path.split(Platform.pathSeparator).last;

  @override
  Future<int> length() {
    if (_length != null) {
      return Future<int>.value(_length);
    }
    return _file.length();
  }

  @override
  Future<String> readAsString({Encoding encoding = utf8}) {
    if (_bytes != null) {
      return Future<String>.value(String.fromCharCodes(_bytes!));
    }
    return _file.readAsString(encoding: encoding);
  }

  @override
  Future<Uint8List> readAsBytes() {
    if (_bytes != null) {
      return Future<Uint8List>.value(_bytes);
    }
    return _file.readAsBytes();
  }

  Stream<Uint8List> _getBytes(int? start, int? end) async* {
    final Uint8List bytes = _bytes!;
    yield bytes.sublist(start ?? 0, end ?? bytes.length);
  }

  @override
  Stream<Uint8List> openRead([int? start, int? end]) {
    if (_bytes != null) {
      return _getBytes(start, end);
    } else {
      return _file
          .openRead(start ?? 0, end)
          .map((List<int> chunk) => Uint8List.fromList(chunk));
    }
  }
}
