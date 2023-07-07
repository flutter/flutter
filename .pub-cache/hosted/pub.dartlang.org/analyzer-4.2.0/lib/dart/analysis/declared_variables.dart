// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An object used to provide access to the values of variables that have been
/// defined on the command line using the `-D` option.
///
/// Clients may not extend, implement or mix-in this class.
class DeclaredVariables {
  /// A table mapping the names of declared variables to their values.
  final Map<String, String> _declaredVariables = <String, String>{};

  /// Initialize a newly created set of declared variables in which there are no
  /// variables.
  DeclaredVariables();

  /// Initialize a newly created set of declared variables to define variables
  /// whose names are the keys in the give [variableMap] and whose values are
  /// the corresponding values from the map.
  DeclaredVariables.fromMap(Map<String, String> variableMap) {
    _declaredVariables.addAll(variableMap);
  }

  /// Return the names of the variables for which a value has been defined.
  Iterable<String> get variableNames => _declaredVariables.keys;

  /// Return the raw string value of the variable with the given [name],
  /// or `null` if the variable is not defined.
  String? get(String name) => _declaredVariables[name];
}
