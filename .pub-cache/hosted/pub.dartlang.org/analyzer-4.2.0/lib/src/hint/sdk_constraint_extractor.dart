// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// A utility class used to extract the SDK version constraint from a
/// `pubspec.yaml` file.
class SdkConstraintExtractor {
  /// The file from which the constraint is to be extracted.
  final File pubspecFile;

  /// A flag indicating whether the [_constraintText], [_constraintOffset] and
  /// [_constraint] have been initialized.
  bool _initialized = false;

  /// The text of the constraint, or `null` if the range has not yet been
  /// computed or if there was an error when attempting to compute the range.
  String? _constraintText;

  /// The offset of the constraint text, or `-1` if the offset is not known.
  int _constraintOffset = -1;

  /// The cached range of supported versions, or `null` if the range has not yet
  /// been computed or if there was an error when attempting to compute the
  /// range.
  VersionConstraint? _constraint;

  /// Initialize a newly created extractor to extract the SDK version constraint
  /// from the given `pubspec.yaml` file.
  SdkConstraintExtractor(this.pubspecFile);

  /// Return the range of supported versions, or `null` if the range could not
  /// be computed.
  VersionConstraint? constraint() {
    if (_constraint == null) {
      var text = constraintText();
      if (text != null) {
        try {
          _constraint = VersionConstraint.parse(text);
        } catch (e) {
          // Ignore this, leaving [_constraint] unset.
        }
      }
    }
    return _constraint;
  }

  /// Return the offset of the constraint text, or `-1` if there is an
  /// error or if the pubspec does not contain an sdk constraint.
  int constraintOffset() {
    if (_constraintText == null) {
      _initializeTextAndOffset();
    }
    return _constraintOffset;
  }

  /// Return the constraint text following "sdk:", or `null` if there is an
  /// error or if the pubspec does not contain an sdk constraint.
  String? constraintText() {
    if (_constraintText == null) {
      _initializeTextAndOffset();
    }
    return _constraintText;
  }

  /// Initialize both [_constraintText] and [_constraintOffset], or neither if
  /// there is an error or if the pubspec does not contain an sdk constraint.
  void _initializeTextAndOffset() {
    if (!_initialized) {
      _initialized = true;
      try {
        String fileContent = pubspecFile.readAsStringSync();
        YamlDocument document = loadYamlDocument(fileContent);
        YamlNode contents = document.contents;
        if (contents is YamlMap) {
          YamlNode? environment = contents.nodes['environment'];
          if (environment is YamlMap) {
            YamlNode? sdk = environment.nodes['sdk'];
            if (sdk is YamlScalar) {
              _constraintText = sdk.value;
              _constraintOffset = sdk.span.start.offset;
              if (sdk.style == ScalarStyle.SINGLE_QUOTED ||
                  sdk.style == ScalarStyle.DOUBLE_QUOTED) {
                _constraintOffset++;
              }
            }
          }
        }
      } catch (e) {
        // Ignore this, leaving both fields unset.
      }
    }
  }
}
