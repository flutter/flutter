part of html_common;

/// Converts native values to their Dart equivalent
///
/// This includes other maps, lists, or values that don't need a conversion e.g.
/// bool, String.
_convertNativeToDart_Value(value) {
  if (value == null) return value;
  if (value is String || value is num || value is bool) return value;
  if (isJavaScriptSimpleObject(value)) {
    return convertNativeToDart_Dictionary(value);
  }
  if (JS('bool', 'Array.isArray(#)', value)) {
    List values = [];
    for (var i = 0; i < JS<int>('int', '#.length', value); i++) {
      values.add(_convertNativeToDart_Value(JS('var', '#[#]', value, i)));
    }

    return values;
  }
  return value;
}

/// Recursively converts a JavaScript object with properties into a Dart Map.
/// This includes maps, lists, and other values that don't need a conversion.
Map<String, dynamic>? convertNativeToDart_Dictionary(object) {
  if (object == null) return null;
  var dict = <String, dynamic>{};
  var keys = JS<JSExtendableArray>(
      'JSExtendableArray', 'Object.getOwnPropertyNames(#)', object);
  for (final key in keys) {
    dict[JS('String', '#', key)] =
        _convertNativeToDart_Value(JS('var', '#[#]', object, key));
  }
  return dict;
}

/// Converts values that occur within a Dart map for map conversion.
///
/// This includes other maps, lists, or values that don't need a conversion e.g.
/// bool, String.
_convertDartToNative_Value(Object? value) {
  if (value == null) return value;
  if (value is String || value is num || value is bool) return value;
  if (value is Map) return convertDartToNative_Dictionary(value);
  if (value is List) {
    var array = JS('var', '[]');
    value.forEach((element) {
      JS('void', '#.push(#)', array, _convertDartToNative_Value(element));
    });
    value = array;
  }
  return value;
}

/// Converts a potentially nested Dart map to a JavaScript object with
/// properties.
///
/// This method requires that the values within the map are either maps
/// themselves, lists, or do not need a conversion.
convertDartToNative_Dictionary(Map? dict, [void postCreate(Object? f)?]) {
  if (dict == null) return null;
  var object = JS('var', '{}');
  if (postCreate != null) {
    postCreate(object);
  }
  dict.forEach((key, value) {
    JS('void', '#[#] = #', object, key, _convertDartToNative_Value(value));
  });
  return object;
}

/**
 * Ensures that the input is a JavaScript Array.
 *
 * Creates a new JavaScript array if necessary, otherwise returns the original.
 */
List convertDartToNative_StringArray(List<String> input) {
  // TODO(sra).  Implement this.
  return input;
}

DateTime convertNativeToDart_DateTime(date) {
  int millisSinceEpoch = JS('int', '#.getTime()', date);
  return new DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch, isUtc: true);
}

convertDartToNative_DateTime(DateTime date) {
  return JS('', 'new Date(#)', date.millisecondsSinceEpoch);
}

convertDartToNative_PrepareForStructuredClone(value) =>
    new _StructuredCloneDart2Js()
        .convertDartToNative_PrepareForStructuredClone(value);

convertNativeToDart_AcceptStructuredClone(object, {mustCopy = false}) =>
    new _AcceptStructuredCloneDart2Js()
        .convertNativeToDart_AcceptStructuredClone(object, mustCopy: mustCopy);

class _StructuredCloneDart2Js extends _StructuredClone {
  JSObject newJsObject() => JS('JSObject', '{}');

  void forEachObjectKey(object, action(key, value)) {
    for (final key
        in JS('returns:JSExtendableArray;new:true', 'Object.keys(#)', object)) {
      action(key, JS('var', '#[#]', object, key));
    }
  }

  void putIntoObject(object, key, value) =>
      JS('void', '#[#] = #', object, key, value);

  newJsMap() => JS('var', '{}');
  putIntoMap(map, key, value) => JS('void', '#[#] = #', map, key, value);
  newJsList(length) => JS('JSExtendableArray', 'new Array(#)', length);
  cloneNotRequired(e) => (e is NativeByteBuffer ||
      e is NativeTypedData ||
      e is MessagePort ||
      e is SharedArrayBuffer);
}

class _AcceptStructuredCloneDart2Js extends _AcceptStructuredClone {
  List newJsList(length) => JS('JSExtendableArray', 'new Array(#)', length);
  List newDartList(length) => newJsList(length);
  bool identicalInJs(a, b) => identical(a, b);

  void forEachJsField(object, action(key, value)) {
    for (final key in JS('JSExtendableArray', 'Object.keys(#)', object)) {
      action(key, JS('var', '#[#]', object, key));
    }
  }
}

bool isJavaScriptDate(value) => JS('bool', '# instanceof Date', value);
bool isJavaScriptRegExp(value) => JS('bool', '# instanceof RegExp', value);
bool isJavaScriptArray(value) => JS('bool', '# instanceof Array', value);
bool isJavaScriptSimpleObject(value) {
  var proto = JS('', 'Object.getPrototypeOf(#)', value);
  return JS('bool', '# === Object.prototype', proto) ||
      JS('bool', '# === null', proto);
}

bool isImmutableJavaScriptArray(value) =>
    JS('bool', r'!!(#.immutable$list)', value);
bool isJavaScriptPromise(value) =>
    JS('bool', r'typeof Promise != "undefined" && # instanceof Promise', value);

const String _serializedScriptValue = 'num|String|bool|'
    'JSExtendableArray|=Object|'
    'Blob|File|NativeByteBuffer|NativeTypedData|MessagePort'
    // TODO(sra): Add Date, RegExp.
    ;
const annotation_Creates_SerializedScriptValue =
    const Creates(_serializedScriptValue);
const annotation_Returns_SerializedScriptValue =
    const Returns(_serializedScriptValue);
