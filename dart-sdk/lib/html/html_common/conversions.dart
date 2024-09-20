// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Conversions for IDBKey.
//
// Per http://www.w3.org/TR/IndexedDB/#key-construct
//
// "A value is said to be a valid key if it is one of the following types: Array
// JavaScript objects [ECMA-262], DOMString [WEBIDL], Date [ECMA-262] or float
// [WEBIDL]. However Arrays are only valid keys if every item in the array is
// defined and is a valid key (i.e. sparse arrays can not be valid keys) and if
// the Array doesn't directly or indirectly contain itself. Any non-numeric
// properties are ignored, and thus does not affect whether the Array is a valid
// key. Additionally, if the value is of type float, it is only a valid key if
// it is not NaN, and if the value is of type Date it is only a valid key if its
// [[PrimitiveValue]] internal property, as defined by [ECMA-262], is not NaN."

// What is required is to ensure that an Lists in the key are actually
// JavaScript arrays, and any Dates are JavaScript Dates.

// Conversions for Window.  These check if the window is the local
// window, and if it's not, wraps or unwraps it with a secure wrapper.
// We need to test for EventTarget here as well as it's a base type.
// We omit an unwrapper for Window as no methods take a non-local
// window as a parameter.

part of html_common;

/// Converts a Dart value into a JavaScript SerializedScriptValue.
convertDartToNative_SerializedScriptValue(value) {
  return convertDartToNative_PrepareForStructuredClone(value);
}

/// Since the source object may be viewed via a JavaScript event listener the
/// original may not be modified.
convertNativeToDart_SerializedScriptValue(object) {
  return convertNativeToDart_AcceptStructuredClone(object, mustCopy: true);
}

/**
 * Converts a Dart value into a JavaScript SerializedScriptValue.  Returns the
 * original input or a functional 'copy'.  Does not mutate the original.
 *
 * The main transformation is the translation of Dart Maps are converted to
 * JavaScript Objects.
 *
 * The algorithm is essentially a dry-run of the structured clone algorithm
 * described at
 * http://www.whatwg.org/specs/web-apps/current-work/multipage/common-dom-interfaces.html#structured-clone
 * https://www.khronos.org/registry/typedarray/specs/latest/#9
 *
 * Since the result of this function is expected to be passed only to JavaScript
 * operations that perform the structured clone algorithm which does not mutate
 * its output, the result may share structure with the input [value].
 */
abstract class _StructuredClone {
  // TODO(sra): Replace slots with identity hash table.
  var values = [];
  var copies = []; // initially 'null', 'true' during initial DFS, then a copy.

  int findSlot(value) {
    int length = values.length;
    for (int i = 0; i < length; i++) {
      if (identical(values[i], value)) return i;
    }
    values.add(value);
    copies.add(null);
    return length;
  }

  readSlot(int i) => copies[i];
  writeSlot(int i, x) {
    copies[i] = x;
  }

  cleanupSlots() {} // Will be needed if we mark objects with a property.
  bool cloneNotRequired(object);
  JSObject newJsObject();
  void forEachObjectKey(object, action(key, value));
  void putIntoObject(object, key, value);
  newJsMap();
  List newJsList(length);
  void putIntoMap(map, key, value);

  // Returns the input, or a clone of the input.
  walk(e) {
    if (e == null) return e;
    if (e is bool) return e;
    if (e is num) return e;
    if (e is String) return e;
    if (e is DateTime) {
      return convertDartToNative_DateTime(e);
    }
    if (e is RegExp) {
      // TODO(sra).
      throw new UnimplementedError('structured clone of RegExp');
    }

    // The browser's internal structured cloning algorithm will copy certain
    // types of object, but it will copy only its own implementations and not
    // just any Dart implementations of the interface.

    // TODO(sra): The JavaScript objects suitable for direct cloning by the
    // structured clone algorithm could be tagged with an private interface.

    if (e is File) return e;
    if (e is Blob) return e;
    if (e is FileList) return e;

    // TODO(sra): Firefox: How to convert _TypedImageData on the other end?
    if (e is ImageData) return e;
    if (cloneNotRequired(e)) return e;

    if (e is Map) {
      var slot = findSlot(e);
      var copy = readSlot(slot);
      if (copy != null) return copy;
      copy = newJsMap();
      writeSlot(slot, copy);
      e.forEach((key, value) {
        putIntoMap(copy, key, walk(value));
      });
      return copy;
    }

    if (e is List) {
      // Since a JavaScript Array is an instance of Dart List it is tempting
      // in dart2js to avoid making a copy of the list if there is no need
      // to copy anything reachable from the array.  However, the list may have
      // non-native properties or methods from interceptors and such, e.g.
      // an immutability marker. So we  had to stop doing that.
      var slot = findSlot(e);
      var copy = JS('returns:List|Null;creates:;', '#', readSlot(slot));
      if (copy != null) return copy;
      copy = copyList(e, slot);
      return copy;
    }

    if (e is JSObject) {
      var slot = findSlot(e);
      var copy = readSlot(slot);
      if (copy != null) return copy;
      copy = newJsObject();
      writeSlot(slot, copy);
      // TODO: Consider inlining this so we don't allocate a closure.
      forEachObjectKey(e, (key, value) {
        putIntoObject(copy, key, walk(value));
      });
      return copy;
    }

    throw new UnimplementedError('structured clone of other type');
  }

  List copyList(List e, int slot) {
    int i = 0;
    int length = e.length;
    var copy = newJsList(length);
    writeSlot(slot, copy);
    for (; i < length; i++) {
      copy[i] = walk(e[i]);
    }
    return copy;
  }

  convertDartToNative_PrepareForStructuredClone(value) {
    var copy = walk(value);
    cleanupSlots();
    return copy;
  }
}

/**
 * Converts a native value into a Dart object.
 *
 * If [mustCopy] is [:false:], may return the original input.  May mutate the
 * original input (but will be idempotent if mutation occurs).  It is assumed
 * that this conversion happens on native serializable script values such values
 * from native DOM calls.
 *
 * [object] is the result of a structured clone operation.
 *
 * If necessary, JavaScript Dates are converted into Dart Dates.
 *
 * If [mustCopy] is [:true:], the entire object is copied and the original input
 * is not mutated.  This should be the case where Dart and JavaScript code can
 * access the value, for example, via multiple event listeners for
 * MessageEvents.  Mutating the object to make it more 'Dart-like' would corrupt
 * the value as seen from the JavaScript listeners.
 */
abstract class _AcceptStructuredClone {
  // TODO(sra): Replace slots with identity hash table.
  var values = [];
  var copies = []; // initially 'null', 'true' during initial DFS, then a copy.
  bool mustCopy = false;

  int findSlot(value) {
    int length = values.length;
    for (int i = 0; i < length; i++) {
      if (identicalInJs(values[i], value)) return i;
    }
    values.add(value);
    copies.add(null);
    return length;
  }

  /// Are the two objects identical, but taking into account that two JsObject
  /// wrappers may not be identical, but their underlying Js Object might be.
  bool identicalInJs(a, b);
  readSlot(int i) => copies[i];
  writeSlot(int i, x) {
    copies[i] = x;
  }

  /// Iterate over the JS properties.
  forEachJsField(object, action(key, value));

  /// Create a new Dart list of the given length. May create a native List or
  /// a JsArray, depending if we're in Dartium or dart2js.
  List newDartList(length);

  walk(e) {
    if (e == null) return e;
    if (e is bool) return e;
    if (e is num) return e;
    if (e is String) return e;

    if (isJavaScriptDate(e)) {
      return convertNativeToDart_DateTime(e);
    }

    if (isJavaScriptRegExp(e)) {
      // TODO(sra).
      throw new UnimplementedError('structured clone of RegExp');
    }

    if (isJavaScriptPromise(e)) {
      return promiseToFuture(e);
    }

    if (isJavaScriptSimpleObject(e)) {
      // TODO(sra): If mustCopy is false, swizzle the prototype for one of a Map
      // implementation that uses the properties as storage.
      var slot = findSlot(e);
      var copy = readSlot(slot);
      if (copy != null) return copy;
      var map = {};

      writeSlot(slot, map);
      forEachJsField(e, (key, value) => map[key] = walk(value));
      return map;
    }

    if (isJavaScriptArray(e)) {
      var l = JS<List>('returns:List;creates:;', '#', e);
      var slot = findSlot(l);
      var copy = JS<List?>('returns:List|Null;creates:;', '#', readSlot(slot));
      if (copy != null) return copy;

      int length = l.length;
      // Since a JavaScript Array is an instance of Dart List, we can modify it
      // in-place unless we must copy.
      copy = mustCopy ? newDartList(length) : l;
      writeSlot(slot, copy);

      for (int i = 0; i < length; i++) {
        copy[i] = walk(l[i]);
      }
      return copy;
    }

    // Assume anything else is already a valid Dart object, either by having
    // already been processed, or e.g. a cloneable native class.
    return e;
  }

  convertNativeToDart_AcceptStructuredClone(object, {mustCopy = false}) {
    this.mustCopy = mustCopy;
    var copy = walk(object);
    return copy;
  }
}

// Conversions for ContextAttributes.
//
// On Firefox, the returned ContextAttributes is a plain object.
class ContextAttributes {
  bool alpha;
  bool antialias;
  bool depth;
  bool premultipliedAlpha;
  bool preserveDrawingBuffer;
  bool stencil;
  bool failIfMajorPerformanceCaveat;

  ContextAttributes(
      this.alpha,
      this.antialias,
      this.depth,
      this.failIfMajorPerformanceCaveat,
      this.premultipliedAlpha,
      this.preserveDrawingBuffer,
      this.stencil);
}

convertNativeToDart_ContextAttributes(nativeContextAttributes) {
  // On Firefox the above test fails because ContextAttributes is a plain
  // object so we create a _TypedContextAttributes.

  return new ContextAttributes(
      JS('var', '#.alpha', nativeContextAttributes),
      JS('var', '#.antialias', nativeContextAttributes),
      JS('var', '#.depth', nativeContextAttributes),
      JS('var', '#.failIfMajorPerformanceCaveat', nativeContextAttributes),
      JS('var', '#.premultipliedAlpha', nativeContextAttributes),
      JS('var', '#.preserveDrawingBuffer', nativeContextAttributes),
      JS('var', '#.stencil', nativeContextAttributes));
}

// Conversions for ImageData
//
// On Firefox, the returned ImageData is a plain object.

class _TypedImageData implements ImageData {
  final Uint8ClampedList data;
  final int height;
  final int width;

  _TypedImageData(this.data, this.height, this.width);
}

ImageData convertNativeToDart_ImageData(nativeImageData) {
  // None of the native getters that return ImageData are declared as returning
  // [ImageData] since that is incorrect for FireFox, which returns a plain
  // Object.  So we need something that tells the compiler that the ImageData
  // class has been instantiated.
  // TODO(sra): Remove this when all the ImageData returning APIs have been
  // annotated as returning the union ImageData + Object.
  JS('ImageData', '0');

  if (nativeImageData is ImageData) {
    // Fix for Issue 16069: on IE, the `data` field is a CanvasPixelArray which
    // has Array as the constructor property.  This interferes with finding the
    // correct interceptor.  Fix it by overwriting the constructor property.
    var data = nativeImageData.data;
    if (JS('bool', '#.constructor === Array', data)) {
      if (JS('bool', 'typeof CanvasPixelArray !== "undefined"')) {
        JS('void', '#.constructor = CanvasPixelArray', data);
        // This TypedArray property is missing from CanvasPixelArray.
        JS('void', '#.BYTES_PER_ELEMENT = 1', data);
      }
    }

    return nativeImageData;
  }

  // On Firefox the above test fails because [nativeImageData] is a plain
  // object.  So we create a _TypedImageData.

  return new _TypedImageData(
      JS('NativeUint8ClampedList', '#.data', nativeImageData),
      JS('var', '#.height', nativeImageData),
      JS('var', '#.width', nativeImageData));
}

// We can get rid of this conversion if _TypedImageData implements the fields
// with native names.
convertDartToNative_ImageData(ImageData imageData) {
  if (imageData is _TypedImageData) {
    return JS('', '{data: #, height: #, width: #}', imageData.data,
        imageData.height, imageData.width);
  }
  return imageData;
}
