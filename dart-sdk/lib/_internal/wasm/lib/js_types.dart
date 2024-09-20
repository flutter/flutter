// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library exists to act as a uniform abstraction layer between the user
/// facing JS interop libraries and backend specific internal representations of
/// JS types.
///
/// For consistency, all of the web backends have a version of this library.
///
/// **WARNING**: You should *not* rely on these runtime types. Not only is this
/// library not guaranteed to be consistent across platforms, these types may
/// change in the future.
library dart._js_types;

import 'dart:_error_utils';
import 'dart:_internal';
import 'dart:_js_helper' as js;
import 'dart:_object_helper';
import 'dart:_simd'
    show
        NaiveUnmodifiableInt32x4List,
        NaiveUnmodifiableFloat32x4List,
        NaiveUnmodifiableFloat64x2List;
import 'dart:_string';
import 'dart:_string_helper';
import 'dart:_wasm';
import 'dart:collection';
import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

part 'js_array.dart';
part 'js_typed_array.dart';

typedef JSAnyRepType = js.JSValue;

typedef JSObjectRepType = js.JSValue;

typedef JSFunctionRepType = js.JSValue;

typedef JSExportedDartFunctionRepType = js.JSValue;

typedef JSArrayRepType = js.JSValue;

typedef JSBoxedDartObjectRepType = js.JSValue;

typedef JSArrayBufferRepType = js.JSValue;

typedef JSDataViewRepType = js.JSValue;

typedef JSTypedArrayRepType = js.JSValue;

typedef JSInt8ArrayRepType = js.JSValue;

typedef JSUint8ArrayRepType = js.JSValue;

typedef JSUint8ClampedArrayRepType = js.JSValue;

typedef JSInt16ArrayRepType = js.JSValue;

typedef JSUint16ArrayRepType = js.JSValue;

typedef JSInt32ArrayRepType = js.JSValue;

typedef JSUint32ArrayRepType = js.JSValue;

typedef JSFloat32ArrayRepType = js.JSValue;

typedef JSFloat64ArrayRepType = js.JSValue;

typedef JSNumberRepType = js.JSValue;

typedef JSBooleanRepType = js.JSValue;

typedef JSStringRepType = js.JSValue;

typedef JSPromiseRepType = js.JSValue;

typedef JSSymbolRepType = js.JSValue;

typedef JSBigIntRepType = js.JSValue;

// While this type is not a JS type, it is here for convenience so we don't need
// to create a new shared library.
typedef ExternalDartReferenceRepType<T> = js.JSValue?;

// JSVoid is just a typedef for void. While we could just use JSUndefined, in
// the future we may be able to use this to elide `return`s in JS trampolines.
typedef JSVoidRepType = void;
