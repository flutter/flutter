// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import 'package:path/path.dart' as path;

@Deprecated('Use ResourceProvider and path context instead.')
class JavaFile {
  @deprecated
  static path.Context pathContext = path.context;
  static final String separator = Platform.pathSeparator;
  static final int separatorChar = Platform.pathSeparator.codeUnitAt(0);
  late final String _path;
  JavaFile(String path) {
    _path = path;
  }
  JavaFile.fromUri(Uri uri) : this(path.context.fromUri(uri));
  JavaFile.relative(JavaFile base, String child) {
    if (child.isEmpty) {
      _path = base._path;
    } else {
      _path = path.context.join(base._path, child);
    }
  }
  @override
  int get hashCode => _path.hashCode;
  @override
  bool operator ==(Object other) {
    return other is JavaFile && other._path == _path;
  }

  bool exists() {
    if (_newFile().existsSync()) {
      return true;
    }
    if (_newDirectory().existsSync()) {
      return true;
    }
    return false;
  }

  JavaFile getAbsoluteFile() => JavaFile(getAbsolutePath());
  String getAbsolutePath() {
    String abolutePath = path.context.absolute(_path);
    abolutePath = path.context.normalize(abolutePath);
    return abolutePath;
  }

  JavaFile getCanonicalFile() => JavaFile(getCanonicalPath());
  String getCanonicalPath() {
    return _newFile().resolveSymbolicLinksSync();
  }

  String getName() => path.context.basename(_path);
  String? getParent() {
    var result = path.context.dirname(_path);
    // "." or  "/" or  "C:\"
    if (result.length < 4) return null;
    return result;
  }

  JavaFile? getParentFile() {
    var parent = getParent();
    if (parent == null) return null;
    return JavaFile(parent);
  }

  String getPath() => _path;
  bool isDirectory() {
    return _newDirectory().existsSync();
  }

  bool isExecutable() {
    return _newFile().statSync().mode & 0x111 != 0;
  }

  bool isFile() {
    return _newFile().existsSync();
  }

  int lastModified() {
    try {
      return _newFile().lastModifiedSync().millisecondsSinceEpoch;
    } catch (exception) {
      return -1;
    }
  }

  List<JavaFile> listFiles() {
    var files = <JavaFile>[];
    var entities = _newDirectory().listSync();
    for (FileSystemEntity entity in entities) {
      files.add(JavaFile(entity.path));
    }
    return files;
  }

  String readAsStringSync() => _newFile().readAsStringSync();
  @override
  String toString() => _path.toString();
  Uri toURI() {
    String absolutePath = getAbsolutePath();
    return path.context.toUri(absolutePath);
  }

  Directory _newDirectory() => Directory(_path);
  File _newFile() => File(_path);
}
