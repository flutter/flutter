// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _late_helper;

import 'dart:_internal' show LateError, createSentinel, isSentinel;
import 'dart:_js_helper' show throwExpressionWithWrapper;
import 'dart:_foreign_helper' show JS;

@pragma('dart2js:never-inline')
void throwLateFieldNI(String fieldName) {
  final wrapper = JS('', 'new Error()');
  throwExpressionWithWrapper(LateError.fieldNI(fieldName), wrapper);
}

@pragma('dart2js:never-inline')
void throwLateFieldAI(String fieldName) {
  final wrapper = JS('', 'new Error()');
  throwExpressionWithWrapper(LateError.fieldAI(fieldName), wrapper);
}

@pragma('dart2js:never-inline')
void throwLateFieldADI(String fieldName) {
  final wrapper = JS('', 'new Error()');
  throwExpressionWithWrapper(LateError.fieldADI(fieldName), wrapper);
}

@pragma('dart2js:never-inline')
void throwUnnamedLateFieldNI() {
  final wrapper = JS('', 'new Error()');
  throwExpressionWithWrapper(LateError.fieldNI(''), wrapper);
}

@pragma('dart2js:never-inline')
void throwUnnamedLateFieldAI() {
  final wrapper = JS('', 'new Error()');
  throwExpressionWithWrapper(LateError.fieldAI(''), wrapper);
}

@pragma('dart2js:never-inline')
void throwUnnamedLateFieldADI() {
  final wrapper = JS('', 'new Error()');
  throwExpressionWithWrapper(LateError.fieldADI(''), wrapper);
}

/// A boxed variable used for lowering uninitialized `late` variables when they
/// are locals or statics.
class _Cell {
  final String _name;
  Object? _value;

  @pragma('dart2js:noInline')
  _Cell() : _name = '' {
    // `this` is a unique sentinel.
    _value = this;
  }

  @pragma('dart2js:noInline')
  _Cell.named(this._name) {
    // `this` is a unique sentinel.
    _value = this;
  }

  @pragma('dart2js:tryInline')
  @pragma('dart2js:as:trust')
  T readLocal<T>() => _readLocal() as T;

  @pragma('dart2js:tryInline')
  @pragma('dart2js:as:trust')
  T readField<T>() => _readField() as T;

  Object? _readLocal() {
    if (identical(_value, this)) throw LateError.localNI(_name);
    return _value;
  }

  Object? _readField() {
    if (identical(_value, this)) throw LateError.fieldNI(_name);
    return _value;
  }

  void set value(Object? v) {
    _value = v;
  }

  void set finalLocalValue(Object? v) {
    if (!identical(_value, this)) throw LateError.localAI(_name);
    _value = v;
  }

  void set finalFieldValue(Object? v) {
    if (!identical(_value, this)) throw LateError.fieldAI(_name);
    _value = v;
  }
}

/// A boxed variable used for lowering `late` variables when they are
/// initialized locals.
class _InitializedCell {
  final String _name;
  Object? _value;
  Object? Function() _initializer;

  @pragma('dart2js:noInline')
  _InitializedCell(this._initializer) : _name = '' {
    // `this` is a unique sentinel.
    _value = this;
  }

  @pragma('dart2js:noInline')
  _InitializedCell.named(this._name, this._initializer) {
    // `this` is a unique sentinel.
    _value = this;
  }

  @pragma('dart2js:tryInline')
  @pragma('dart2js:as:trust')
  T read<T>() => _read() as T;

  @pragma('dart2js:tryInline')
  @pragma('dart2js:as:trust')
  T readFinal<T>() => _readFinal() as T;

  Object? _read() {
    if (identical(_value, this)) _value = _initializer();
    return _value;
  }

  Object? _readFinal() {
    if (identical(_value, this)) {
      final result = _initializer();
      if (!identical(_value, this)) throw LateError.localADI(_name);
      _value = result;
    }
    return _value;
  }

  void set value(Object? v) {
    _value = v;
  }

  void set finalValue(Object? v) {
    if (!identical(_value, this)) throw LateError.localAI(_name);
    _value = v;
  }
}

// Helpers for lowering late instance fields:
// TODO(fishythefish): Support specialization of sentinels based on type.

external T _lateReadCheck<T>(Object? value, String name);

external void _lateWriteOnceCheck(Object? value, String name);

external void _lateInitializeOnceCheck(Object? value, String name);
