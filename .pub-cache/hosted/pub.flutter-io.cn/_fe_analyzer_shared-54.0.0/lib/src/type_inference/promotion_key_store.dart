// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This data structure assigns a unique integer identifier to everything that
/// might undergo promotion in the user's code (local variables and properties).
/// An integer identifier is also assigned to `this` (even though `this` is not
/// promotable), because promotable properties can be reached using `this` as a
/// starting point.
class PromotionKeyStore<Variable extends Object> {
  /// Special promotion key to represent `this`.
  late final int thisPromotionKey = _makeNewKey();

  final Map<Variable, int> _variableKeys = new Map<Variable, int>.identity();

  final List<_PromotionKeyInfo<Variable>> _keyToInfo = [];

  /// Gets the key of the next promotable entity whose [_rootVariableKey] is the
  /// same as [key].  Keys with the same root are linked together in a loop (so
  /// to iterate through them, continue walking the chain until you reach your
  /// starting point).
  int getNextKeyWithSameRoot(int key) => _keyToInfo[key].nextKeyWithSameRoot;

  int getProperty(int targetKey, String propertyName) =>
      (_keyToInfo[targetKey].properties ??= {})[propertyName] ??=
          _makeNewKey(targetKey: targetKey);

  /// Gets the variable key for the variable that forms the root of the property
  /// accesses that led to [promotionKey].  For example, the root variable key
  /// for a property access `a.b.c` is the promotion key for `a`.
  int getRootVariableKey(int promotionKey) =>
      _keyToInfo[promotionKey].rootVariableKey;

  int keyForVariable(Variable variable) =>
      _variableKeys[variable] ??= _makeNewKey(variable: variable);

  /// Creates a fresh promotion key that hasn't been used before (and won't be
  /// reused again).  This is used by flow analysis to model the synthetic
  /// variables used during pattern matching to cache the values that the
  /// pattern, and its subpatterns, are being matched against.
  int makeTemporaryKey() => _makeNewKey();

  Variable? variableForKey(int variableKey) => _keyToInfo[variableKey].variable;

  int _makeNewKey({Variable? variable, int? targetKey}) {
    int key = _keyToInfo.length;
    int rootVariableKey;
    int nextKeyWithSameRoot;
    if (targetKey == null) {
      rootVariableKey = key;
      // This key does not represent a property, so its nextKeyWithSameRoot
      // pointer should point to itself.
      nextKeyWithSameRoot = key;
    } else {
      _PromotionKeyInfo<Variable> targetInfo = _keyToInfo[targetKey];
      rootVariableKey = targetInfo.rootVariableKey;
      // This key represents a property of [targetKey], so its
      // nextKeyWithSameRoot should be linked into whatever chain [targetKey]
      // is in.
      nextKeyWithSameRoot = targetInfo.nextKeyWithSameRoot;
      targetInfo.nextKeyWithSameRoot = key;
    }
    _keyToInfo.add(new _PromotionKeyInfo(
        variable: variable,
        nextKeyWithSameRoot: nextKeyWithSameRoot,
        rootVariableKey: rootVariableKey));
    return key;
  }
}

/// Class storing detailed information about a single promotion key.
class _PromotionKeyInfo<Variable extends Object> {
  /// The variable associated with the key, if any.
  final Variable? variable;

  /// Map indicating the set of properties of this promotable entity being
  /// tracked by flow analysis.  The map is indexed by the property name.
  ///
  /// Null is considered equivalent to an empty map (this allows us to save
  /// memory due to the fact that most promotion keys won't be subject to any
  /// property access).
  Map<String, int>? properties;

  /// The key of the next promotable entity whose [_rootVariableKey] is the same
  /// as this one.  Keys with the same root are linked together in a loop (so to
  /// iterate through them, continue walking the chain until you reach your
  /// starting point).
  int nextKeyWithSameRoot;

  /// The variable key for the variable that forms the root of the property
  /// accesses that led to this variable key.  For example, the entry for a
  /// property access `a.b.c` points to the promotion key for `a`.
  final int rootVariableKey;

  _PromotionKeyInfo(
      {required this.variable,
      required this.nextKeyWithSameRoot,
      required this.rootVariableKey});
}
