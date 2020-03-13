// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;

import '../base/file_system.dart';

/// A utility class for interacting with Visual Studio project files (e.g.,
/// .vcxproj).
class VisualStudioProject {
  /// Creates a project object from the project file at [file].
  VisualStudioProject(this.file, {
    @required FileSystem fileSystem,
  }): _fileSystem = fileSystem {
    try {
      content = xml.parse(file.readAsStringSync());
    } on xml.XmlParserException {
      // Silently continue; formatUnderstood will return false.
    }
  }

  final FileSystem _fileSystem;

  /// The file corresponding to this object.
  final File file;

  /// The content of the project file.
  xml.XmlDocument content;

  /// Whether or not the project file was correctly parsed.
  ///
  /// If false, this could indicate that the project file is damaged, or that
  /// it's an unsupported project type.
  bool get formatUnderstood => content != null;

  String _guid;

  /// Returns the ProjectGuid for the project, or null if it's not present.
  String get guid {
    return _guid ??= _findGuid();
  }

  String _findGuid() {
    if (!formatUnderstood) {
      return null;
    }
    try {
      final String guidValue = content.findAllElements('ProjectGuid').single.text.trim();
      // Remove the enclosing {} from the value.
      return guidValue.substring(1, guidValue.length - 1);
    } on StateError {
      // If there is not exactly one ProjectGuid, return null.
      return null;
    }
  }

  String _name;

  /// Returns the ProjectName for the project.
  ///
  /// If not explicitly set in the project, uses the basename of the project
  /// file.
  String get name {
    return _name ??= _findName();
  }

  String _findName() {
    if (!formatUnderstood) {
      return null;
    }
    try {
      return content.findAllElements('ProjectName').first.text.trim();
    } on StateError {
      // If there is no name, fall back to filename.
      return _fileSystem.path.basenameWithoutExtension(file.path);
    }
  }
}
