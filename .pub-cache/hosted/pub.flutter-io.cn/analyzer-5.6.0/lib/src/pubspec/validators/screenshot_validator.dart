// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class ScreenshotsValidator extends BasePubspecValidator {
  ScreenshotsValidator(super.provider, super.source);

  /// Validate screenshots.
  void validate(ErrorReporter reporter, Map<dynamic, YamlNode> contents) {
    var screenshots = contents[PubspecField.SCREENSHOTS_FIELD];
    if (screenshots is! YamlList) return;
    for (var entry in screenshots) {
      if (entry is! YamlMap) continue;
      var entryValue = entry.valueAt(PubspecField.PATH_FIELD);
      if (entryValue is! YamlScalar) continue;
      var path = entryValue.value;
      if (path is String && !_fileExistsAtPath(path)) {
        reportErrorForNode(reporter, entryValue,
            PubspecWarningCode.PATH_DOES_NOT_EXIST, [entryValue.valueOrThrow]);
      }
    }
  }

  bool _fileExistsAtPath(String filePath) {
    var context = provider.pathContext;
    var normalizedEntry = context.joinAll(p.posix.split(filePath));
    var directoryRoot = context.dirname(source.fullName);
    var fullPath = context.join(directoryRoot, normalizedEntry);
    var file = provider.getFile(fullPath);
    return file.exists;
  }
}
