// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

/// A user-defined test runtime, based on an existing runtime but with
/// different configuration.
class CustomRuntime {
  /// The human-friendly name of the runtime.
  final String name;

  /// The location that [name] was defined in the configuration file.
  final SourceSpan nameSpan;

  /// The identifier used to look up the runtime.
  final String identifier;

  /// The location that [identifier] was defined in the configuration file.
  final SourceSpan identifierSpan;

  /// The identifier of the runtime that this extends.
  final String parent;

  /// The location that [parent] was defined in the configuration file.
  final SourceSpan parentSpan;

  /// The user's settings for this runtime.
  final YamlMap settings;

  CustomRuntime(this.name, this.nameSpan, this.identifier, this.identifierSpan,
      this.parent, this.parentSpan, this.settings);
}
