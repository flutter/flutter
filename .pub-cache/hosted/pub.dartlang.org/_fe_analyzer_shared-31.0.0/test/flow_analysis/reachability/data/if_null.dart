// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void variable_if_null_reachable(int? i) {
  i ?? 0;
}

void variable_if_null_assign_reachable(int? i) {
  i ??= 0;
}

void variable_if_null_unreachable(int i) {
  // Reachable since the value of i might come from legacy code
  i ?? 0;
}

void variable_if_null_assign_unreachable(int i) {
  // Reachable since the value of i might come from legacy code
  i ??= 0;
}

void variable_if_null_assign_unreachable_due_to_promotion(int? i) {
  if (i == null) return;
  // Reachable since the value of i might come from legacy code
  i ??= 0;
}

/*member: topLevelNullable:doesNotComplete*/
int? get topLevelNullable => 0;
void set topLevelNullable(int? value) {}

/*member: topLevelNonNullGet:doesNotComplete*/
int get topLevelNonNullGet => 0;
void set topLevelNonNullGet(int? value) {}

void top_level_if_null_reachable() {
  topLevelNullable ?? 0;
}

void top_level_if_null_assign_reachable() {
  topLevelNullable ??= 0;
}

void top_level_if_null_unreachable() {
  // Reachable since the value returned by topLevelNonNullGet might come from
  // legacy code
  topLevelNonNullGet ?? 0;
}

void top_level_if_null_assign_unreachable() {
  // Reachable since the value returned by topLevelNonNullGet might come from
  // legacy code
  topLevelNonNullGet ??= 0;
}

class HasProperty<T> {
  /*member: HasProperty.prop:doesNotComplete*/
  T get prop => throw '';
  set prop(T? value) {}
}

void property_if_null_reachable(HasProperty<int?> x) {
  x.prop ?? 0;
}

void property_if_null_assign_reachable(HasProperty<int?> x) {
  x.prop ??= 0;
}

void property_if_null_unreachable(HasProperty<int> x) {
  // Reachable since the value returned by prop might come from legacy code
  x.prop ?? 0;
}

void property_if_null_assign_unreachable(HasProperty<int> x) {
  // Reachable since the value returned by prop might come from legacy code
  x.prop ??= 0;
}

void null_aware_property_if_null_reachable(HasProperty<int?>? x) {
  x?.prop ?? 0;
}

void null_aware_property_if_null_assign_reachable(HasProperty<int?>? x) {
  x?.prop ??= 0;
}

void null_aware_property_if_null_not_shortened(HasProperty<int>? x) {
  // Reachable since the value returned by prop might come from legacy code.
  // Also since `??` doesn't participate in null shortening.
  x?.prop ?? 0;
}

void null_aware_property_if_null_assign_unreachable(HasProperty<int>? x) {
  // Reachable since the value returned by prop might come from legacy code.
  x?.prop ??= 0;
}

class SuperIntQuestionProperty extends HasProperty<int?> {
  void if_null_reachable() {
    super.prop ?? 0;
  }

  void if_null_assign_reachable() {
    super.prop ??= 0;
  }
}

class SuperIntProperty extends HasProperty<int> {
  void if_null_unreachable() {
    // Reachable since the value returned by prop might come from legacy code.
    super.prop ?? 0;
  }

  void if_null_assign_unreachable() {
    // Reachable since the value returned by prop might come from legacy code.
    super.prop ??= 0;
  }
}

extension ExtensionProperty<T> on HasProperty<T> {
  /*member: ExtensionProperty|get#extendedProp:doesNotComplete*/
  T get extendedProp => prop;
  set extendedProp(T? value) {
    prop = value;
  }
}

void extended_property_if_null_reachable(HasProperty<int?> x) {
  x.extendedProp ?? 0;
}

void extended_property_if_null_assign_reachable(HasProperty<int?> x) {
  x.extendedProp ??= 0;
}

void extended_property_if_null_unreachable(HasProperty<int> x) {
  // Reachable since the value returned by extendedProp might come from legacy
  // code.
  x.extendedProp ?? 0;
}

void extended_property_if_null_assign_unreachable(HasProperty<int> x) {
  // Reachable since the value returned by extendedProp might come from legacy
  // code.
  x.extendedProp ??= 0;
}

void null_aware_extended_property_if_null_reachable(HasProperty<int?>? x) {
  x?.extendedProp ?? 0;
}

void null_aware_extended_property_if_null_assign_reachable(
    HasProperty<int?>? x) {
  x?.extendedProp ??= 0;
}

void null_aware_extended_property_if_null_not_shortened(HasProperty<int>? x) {
  // Reachable since the value returned by extendedProp might come from legacy
  // code, and because `??` doesn't participate in null shortening.
  x?.extendedProp ?? 0;
}

void null_aware_extended_property_if_null_assign_unreachable(
    HasProperty<int>? x) {
  // Reachable since the value returned by extendedProp might come from legacy
  // code.
  x?.extendedProp ??= 0;
}

void explicit_extended_property_if_null_reachable(HasProperty<int?> x) {
  ExtensionProperty(x).extendedProp ?? 0;
}

void explicit_extended_property_if_null_assign_reachable(HasProperty<int?> x) {
  ExtensionProperty(x).extendedProp ??= 0;
}

void explicit_extended_property_if_null_unreachable(HasProperty<int> x) {
  // Reachable since the value returned by extendedProp might come from legacy
  // code.
  ExtensionProperty(x).extendedProp ?? 0;
}

void explicit_extended_property_if_null_assign_unreachable(HasProperty<int> x) {
  // Reachable since the value returned by extendedProp might come from legacy
  // code.
  ExtensionProperty(x).extendedProp ??= 0;
}

void null_aware_explicit_extended_property_if_null_reachable(
    HasProperty<int?>? x) {
  ExtensionProperty(x)?.extendedProp ?? 0;
}

void null_aware_explicit_extended_property_if_null_assign_reachable(
    HasProperty<int?>? x) {
  ExtensionProperty(x)?.extendedProp ??= 0;
}

void null_aware_explicit_extended_property_if_null_not_shortened(
    HasProperty<int>? x) {
  // Reachable since the value returned by extendedProp might come from legacy
  // code, and because `??` doesn't participate in null shortening.
  ExtensionProperty(x)?.extendedProp ?? 0;
}

void null_aware_explicit_extended_property_if_null_assign_unreachable(
    HasProperty<int>? x) {
  // Reachable since the value returned by extendedProp might come from legacy
  // code.
  ExtensionProperty(x)?.extendedProp ??= 0;
}

class Indexable<T> {
  /*member: Indexable.[]:doesNotComplete*/
  T operator [](int index) => throw '';
  operator []=(int index, T? value) {}
}

void index_if_null_reachable(Indexable<int?> x) {
  x[0] ?? 0;
}

void index_if_null_unreachable(Indexable<int> x) {
  // Reachable since the value returned by operator[] might come from legacy
  // code.
  x[0] ?? 0;
}

void index_if_null_assign_reachable(Indexable<int?> x) {
  x[0] ??= 0;
}

void index_if_null_assign_unreachable(Indexable<int> x) {
  // Reachable since the value returned by operator[] might come from legacy
  // code.
  x[0] ??= 0;
}

void null_aware_index_if_null_reachable(Indexable<int?>? x) {
  x?[0] ?? 0;
}

void null_aware_index_if_null_unreachable(Indexable<int>? x) {
  // Reachable since the value returned by operator[] might come from legacy
  // code, and because `??` doesn't participate in null shortening.
  x?[0] ?? 0;
}

void null_aware_index_if_null_assign_reachable(Indexable<int?>? x) {
  x?[0] ??= 0;
}

void null_aware_index_if_null_assign_unreachable(Indexable<int>? x) {
  // Reachable since the value returned by operator[] might come from legacy
  // code.
  x?[0] ??= 0;
}

class SuperIntQuestionIndex extends Indexable<int?> {
  void if_null_reachable() {
    super[0] ?? 0;
  }

  void if_null_assign_reachable() {
    super[0] ??= 0;
  }
}

class SuperIntIndex extends Indexable<int> {
  void if_null_unreachable() {
    // Reachable since the value returned by operator[] might come from legacy
    // code.
    super[0] ?? 0;
  }

  void if_null_assign_unreachable() {
    // Reachable since the value returned by operator[] might come from legacy
    // code.
    super[0] ??= 0;
  }
}

extension ExtensionIndex<T> on HasProperty<T> {
  /*member: ExtensionIndex|[]:doesNotComplete*/
  T operator [](int index) => prop;
  operator []=(int index, T? value) {
    prop = value;
  }
}

void extended_index_if_null_reachable(HasProperty<int?> x) {
  x[0] ?? 0;
}

void extended_index_if_null_assign_reachable(HasProperty<int?> x) {
  x[0] ??= 0;
}

void extended_index_if_null_unreachable(HasProperty<int> x) {
  // Reachable since the value returned by operator[] might come from legacy
  // code.
  x[0] ?? 0;
}

void extended_index_if_null_assign_unreachable(HasProperty<int> x) {
  // Reachable since the value returned by operator[] might come from legacy
  // code.
  x[0] ??= 0;
}

void null_aware_extended_index_if_null_reachable(HasProperty<int?>? x) {
  x?[0] ?? 0;
}

void null_aware_extended_index_if_null_assign_reachable(HasProperty<int?>? x) {
  x?[0] ??= 0;
}

void null_aware_extended_index_if_null_not_shortened(HasProperty<int>? x) {
  // Reachable since the value returned by operator[] might come from legacy
  // code, and because `??` doesn't participate in null shortening.
  x?[0] ?? 0;
}

void null_aware_extended_index_if_null_assign_unreachable(HasProperty<int>? x) {
  // Reachable since the value returned by operator[] might come from legacy
  // code.
  x?[0] ??= 0;
}

void explicit_extended_index_if_null_reachable(HasProperty<int?> x) {
  ExtensionIndex(x)[0] ?? 0;
}

void explicit_extended_index_if_null_assign_reachable(HasProperty<int?> x) {
  ExtensionIndex(x)[0] ??= 0;
}

void explicit_extended_index_if_null_unreachable(HasProperty<int> x) {
  // Reachable since the value returned by operator[] might come from legacy
  // code.
  ExtensionIndex(x)[0] ?? 0;
}

void explicit_extended_index_if_null_assign_unreachable(HasProperty<int> x) {
  // Reachable since the value returned by operator[] might come from legacy
  // code.
  ExtensionIndex(x)[0] ??= 0;
}

void null_aware_explicit_extended_index_if_null_reachable(
    HasProperty<int?>? x) {
  ExtensionIndex(x)?[0] ?? 0;
}

void null_aware_explicit_extended_index_if_null_assign_reachable(
    HasProperty<int?>? x) {
  ExtensionIndex(x)?[0] ??= 0;
}

void null_aware_explicit_extended_index_if_null_not_shortened(
    HasProperty<int>? x) {
  // Reachable since the value returned by operator[] might come from legacy
  // code, and because `??` doesn't participate in null shortening.
  ExtensionIndex(x)?[0] ?? 0;
}

void null_aware_explicit_extended_index_if_null_assign_unreachable(
    HasProperty<int>? x) {
  // Reachable since the value returned by operator[] might come from legacy
  // code.
  ExtensionIndex(x)?[0] ??= 0;
}
