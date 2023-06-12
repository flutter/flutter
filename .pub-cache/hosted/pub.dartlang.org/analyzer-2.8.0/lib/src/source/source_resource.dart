// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/// A function that can translate the contents of files on disk as they are
/// read. This is now obsolete, but supported the ability of server to deal with
/// clients that convert all text to an internal format.
typedef FileReadMode = String Function(String s);

/// A source that represents a file.
class FileSource extends Source {
  /// A function that changes the way that files are read off of disk.
  static FileReadMode fileReadMode = (String s) => s;

  /// Map from encoded URI/filepath pair to a unique integer identifier.  This
  /// identifier is used for equality tests and hash codes.
  ///
  /// The URI and filepath are joined into a pair by separating them with an '@'
  /// character.
  static final Map<String, int> _idTable = HashMap<String, int>();

  /// The URI from which this source was originally derived.
  @override
  final Uri uri;

  /// The unique ID associated with this source.
  final int id;

  /// The file represented by this source.
  final File file;

  /// The cached absolute path of this source.
  String? _absolutePath;

  /// The cached encoding for this source.
  String? _encoding;

  /// Initialize a newly created source object to represent the given [file]. If
  /// a [uri] is given, then it will be used as the URI from which the source
  /// was derived, otherwise a `file:` URI will be created based on the [file].
  FileSource(File file, [Uri? uri])
      : uri = uri ?? file.toUri(),
        file = file,
        id = _idTable.putIfAbsent(
            '${uri ?? file.toUri()}@${file.path}', () => _idTable.length);

  @override
  TimestampedData<String> get contents {
    return contentsFromFile;
  }

  /// Get and return the contents and timestamp of the underlying file.
  ///
  /// Clients should consider using the method [AnalysisContext.getContents]
  /// because contexts can have local overrides of the content of a source that
  /// the source is not aware of.
  ///
  /// Throws an exception if the contents of this source could not be accessed.
  /// See [contents].
  TimestampedData<String> get contentsFromFile {
    return TimestampedData<String>(
        file.modificationStamp, fileReadMode(file.readAsStringSync()));
  }

  @Deprecated('Not used anymore')
  @override
  String get encoding => _encoding ??= uri.toString();

  @override
  String get fullName => _absolutePath ??= file.path;

  @override
  int get hashCode => uri.hashCode;

  @Deprecated('Use uri.isScheme("dart") instead')
  @override
  bool get isInSystemLibrary => uri.scheme == DartUriResolver.DART_SCHEME;

  @Deprecated('Not used anymore')
  @override
  int get modificationStamp {
    try {
      return file.modificationStamp;
    } on FileSystemException {
      return -1;
    }
  }

  @override
  String get shortName => file.shortName;

  @Deprecated('Use Source.uri instead')
  @override
  UriKind get uriKind => UriKind.fromScheme(uri.scheme);

  @override
  bool operator ==(Object object) {
    if (object is FileSource) {
      return id == object.id;
    } else if (object is Source) {
      return uri == object.uri;
    }
    return false;
  }

  @override
  bool exists() => file.exists;

  @override
  String toString() {
    return file.path;
  }
}
