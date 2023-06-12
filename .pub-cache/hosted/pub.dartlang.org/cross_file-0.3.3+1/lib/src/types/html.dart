// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import './base.dart';
import '../web_helpers/web_helpers.dart';

// Four Gigabytes, in bytes.
const int _fourGigabytes = 4 * 1024 * 1024 * 1024;

/// A CrossFile that works on web.
///
/// It wraps the bytes of a selected file.
class XFile extends XFileBase {
  /// Construct a CrossFile object from its ObjectUrl.
  ///
  /// Optionally, this can be initialized with `bytes` and `length`
  /// so no http requests are performed to retrieve files later.
  ///
  /// `name` needs to be passed from the outside, since it's only available
  /// while handling [html.File]s (when the ObjectUrl is created).
  XFile(
    String path, {
    String? mimeType,
    String? name,
    int? length,
    Uint8List? bytes,
    DateTime? lastModified,
    @visibleForTesting CrossFileTestOverrides? overrides,
  })  : _mimeType = mimeType,
        _path = path,
        _length = length,
        _overrides = overrides,
        _lastModified = lastModified ?? DateTime.fromMillisecondsSinceEpoch(0),
        _name = name ?? '',
        super(path) {
    // Cache `bytes` as Blob, if passed.
    if (bytes != null) {
      _browserBlob = _createBlobFromBytes(bytes, mimeType);
    }
  }

  /// Construct an CrossFile from its data
  XFile.fromData(
    Uint8List bytes, {
    String? mimeType,
    String? name,
    int? length,
    DateTime? lastModified,
    String? path,
    @visibleForTesting CrossFileTestOverrides? overrides,
  })  : _mimeType = mimeType,
        _length = length,
        _overrides = overrides,
        _lastModified = lastModified ?? DateTime.fromMillisecondsSinceEpoch(0),
        _name = name ?? '',
        super(path) {
    if (path == null) {
      _browserBlob = _createBlobFromBytes(bytes, mimeType);
      _path = Url.createObjectUrl(_browserBlob);
    } else {
      _path = path;
    }
  }

  // Initializes a Blob from a bunch of `bytes` and an optional `mimeType`.
  Blob _createBlobFromBytes(Uint8List bytes, String? mimeType) {
    return (mimeType == null)
        ? Blob(<dynamic>[bytes])
        : Blob(<dynamic>[bytes], mimeType);
  }

  // Overridable (meta) data that can be specified by the constructors.

  // MimeType of the file (eg: "image/gif").
  final String? _mimeType;
  // Name (with extension) of the file (eg: "anim.gif")
  final String _name;
  // Path of the file (must be a valid Blob URL, when set manually!)
  late String _path;
  // The size of the file (in bytes).
  final int? _length;
  // The time the file was last modified.
  final DateTime _lastModified;

  // The link to the binary object in the browser memory (Blob).
  // This can be passed in (as `bytes` in the constructor) or derived from
  // [_path] with a fetch request.
  // (Similar to a (read-only) dart:io File.)
  Blob? _browserBlob;

  // An html Element that will be used to trigger a "save as" dialog later.
  // TODO(dit): https://github.com/flutter/flutter/issues/91400 Remove this _target.
  late Element _target;

  // Overrides for testing
  // TODO(dit): https://github.com/flutter/flutter/issues/91400 Remove these _overrides,
  // they're only used to Save As...
  final CrossFileTestOverrides? _overrides;

  bool get _hasTestOverrides => _overrides != null;

  @override
  String? get mimeType => _mimeType;

  @override
  String get name => _name;

  @override
  String get path => _path;

  @override
  Future<DateTime> lastModified() async => _lastModified;

  Future<Blob> get _blob async {
    if (_browserBlob != null) {
      return _browserBlob!;
    }

    // Attempt to re-hydrate the blob from the `path` via a (local) HttpRequest.
    // Note that safari hangs if the Blob is >=4GB, so bail out in that case.
    if (isSafari() && _length != null && _length! >= _fourGigabytes) {
      throw Exception('Safari cannot handle XFiles larger than 4GB.');
    }

    late HttpRequest request;
    try {
      request = await HttpRequest.request(path, responseType: 'blob');
    } on ProgressEvent catch (e) {
      if (e.type == 'error') {
        throw Exception(
            'Could not load Blob from its URL. Has it been revoked?');
      }
      rethrow;
    }

    _browserBlob = request.response;

    assert(_browserBlob != null, 'The Blob backing this XFile cannot be null!');

    return _browserBlob!;
  }

  @override
  Future<Uint8List> readAsBytes() async {
    return _blob.then(_blobToByteBuffer);
  }

  @override
  Future<int> length() async => _length ?? (await _blob).size;

  @override
  Future<String> readAsString({Encoding encoding = utf8}) async {
    return readAsBytes().then(encoding.decode);
  }

  // TODO(dit): https://github.com/flutter/flutter/issues/91867 Implement openRead properly.
  @override
  Stream<Uint8List> openRead([int? start, int? end]) async* {
    final Blob blob = await _blob;

    final Blob slice = blob.slice(start ?? 0, end ?? blob.size, blob.type);

    final Uint8List convertedSlice = await _blobToByteBuffer(slice);

    yield convertedSlice;
  }

  // Converts an html Blob object to a Uint8List, through a FileReader.
  Future<Uint8List> _blobToByteBuffer(Blob blob) async {
    final FileReader reader = FileReader();
    reader.readAsArrayBuffer(blob);

    await reader.onLoadEnd.first;

    final Uint8List? result = reader.result as Uint8List?;

    if (result == null) {
      throw Exception('Cannot read bytes from Blob. Is it still available?');
    }

    return result;
  }

  /// Saves the data of this CrossFile at the location indicated by path.
  /// For the web implementation, the path variable is ignored.
  // TODO(dit): https://github.com/flutter/flutter/issues/91400
  // Move implementation to web_helpers.dart
  @override
  Future<void> saveTo(String path) async {
    // Create a DOM container where the anchor can be injected.
    _target = ensureInitialized('__x_file_dom_element');

    // Create an <a> tag with the appropriate download attributes and click it
    // May be overridden with CrossFileTestOverrides
    final AnchorElement element = _hasTestOverrides
        ? _overrides!.createAnchorElement(this.path, name) as AnchorElement
        : createAnchorElement(this.path, name);

    // Clear the children in _target and add an element to click
    _target.children.clear();
    addElementToContainerAndClick(_target, element);
  }
}

/// Overrides some functions to allow testing
// TODO(dit): https://github.com/flutter/flutter/issues/91400
// Move this to web_helpers_test.dart
@visibleForTesting
class CrossFileTestOverrides {
  /// Default constructor for overrides
  CrossFileTestOverrides({required this.createAnchorElement});

  /// For overriding the creation of the file input element.
  Element Function(String href, String suggestedName) createAnchorElement;
}
