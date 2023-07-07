// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Support for client code that wants to consume options contributed to the
/// analysis options file.
import 'package:analyzer/error/listener.dart';
import 'package:yaml/yaml.dart';

/// Validates options as defined in an analysis options file.
///
/// The options file format is intentionally very open-ended, giving clients
/// utmost flexibility in defining their own options.  The only hard and fast
/// expectation is that options files will contain a mapping from Strings
/// (identifying 'scopes') to associated options.  For example, the given
/// content
///
///     linter:
///       rules:
///         camel_case_types: true
///     compiler:
///       resolver:
///         useMultiPackage: true
///       packagePaths:
///         - /foo/bar/pkg
///         - /bar/baz/pkg
///
/// defines two scopes, `linter` and `compiler`.  Parsing would result in a
/// map, mapping the `linter` and `compiler` scope identifiers to their
/// respective parsed option node contents. Extracting values is a simple
/// matter of inspecting the parsed nodes.  For example, testing whether the
/// compiler's resolver is set to use the `useMultiPackage` option might look
/// something like this (eliding error-checking):
///
///     bool useMultiPackage =
///         options['compiler']['resolver']['useMultiPackage'];
///
/// Clients may implement this class when implementing plugins.
///
abstract class OptionsValidator {
  /// Validate [options], reporting any errors to the given [reporter].
  void validate(ErrorReporter reporter, YamlMap options);
}
