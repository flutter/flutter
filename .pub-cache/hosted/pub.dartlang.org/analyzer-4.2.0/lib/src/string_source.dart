// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/engine.dart' show TimestampedData;
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart' as pkg_path;

/// An implementation of [Source] that's based on an in-memory Dart string.
class StringSource extends Source {
  /// The content of the source.
  final String _contents;

  @override
  final String fullName;

  @override
  final Uri uri;

  StringSource(this._contents, String? fullName, {Uri? uri})
      : fullName = fullName ?? '/test.dart',
        uri = _computeUri(uri, fullName);

  @override
  TimestampedData<String> get contents => TimestampedData(0, _contents);

  @override
  int get hashCode => _contents.hashCode ^ fullName.hashCode;

  @override
  String get shortName => fullName;

  /// Return `true` if the given [object] is a string source that is equal to
  /// this source.
  @override
  bool operator ==(Object object) {
    return object is StringSource &&
        object._contents == _contents &&
        object.fullName == fullName;
  }

  @override
  bool exists() => true;

  @override
  String toString() => 'StringSource ($fullName)';

  static Uri _computeUri(Uri? uri, String? fullName) {
    if (uri != null) {
      return uri;
    }

    var isWindows = pkg_path.Style.platform == pkg_path.Style.windows;
    if (isWindows) {
      return pkg_path.toUri(r'C:\test.dart');
    } else {
      return pkg_path.toUri(r'/test.dart');
    }
  }
}
