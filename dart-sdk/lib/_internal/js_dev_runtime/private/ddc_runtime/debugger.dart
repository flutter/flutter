// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
part of dart._runtime;

/// Debugger runtime API used by the debugger to display objects.
///
/// NOTE(annagrin): Some runtime API below do not require
/// runtime information and should be removed  once DDC
/// provides full symbol information and the debugger
/// consumes it.
///
/// Issue: https://github.com/dart-lang/sdk/issues/40273.

/// DDC runtime object kind.
///
/// Object kinds are determined using DDC runtime API and
/// are used to translate from JavaScript objects to their
/// vm service protocol representation, which determines
/// now the object is displayed in debugging tools.
class RuntimeObjectKind {
  static const String object = 'object';
  static const String set = 'set';
  static const String list = 'list';
  static const String map = 'map';
  static const String function = 'function';
  static const String record = 'record';
  static const String type = 'type';
  static const String recordType = 'recordType';
  static const String nativeError = 'nativeError';
  static const String nativeObject = 'nativeObject';
}

/// Collect library metadata.
///
/// Returns a JavaScript object containing a list of class
/// descriptors for all classes in a library:
///
/// ```
/// [
///     <dart class name>,
///     ...
/// ]
/// ```
///
/// TODO(annagrin): remove when debugger consumes debug symbols.
/// Issue: https://github.com/dart-lang/sdk/issues/40273.
@notNull
List<String> getLibraryMetadata(@notNull String libraryUri) {
  var library = getLibrary('$libraryUri');
  if (library == null) throw 'cannot find library for $libraryUri';

  final classes = <String>[];
  for (var name in getOwnPropertyNames(library)) {
    final field = name as String;
    var descriptor = getOwnPropertyDescriptor(library, field);
    // Filter out all getters prevent causing side-effects by calling them.
    if (_get<Object?>(descriptor, 'value') != null &&
        _get<Object?>(descriptor, 'get') == null) {
      final cls = _get<Object?>(library, field);
      if (cls != null && _isDartClassObject(cls)) {
        classes.add(_dartClassName(cls));
      }
    }
  }
  return classes;
}

/// Collect class metadata.
///
/// Returns a JavaScript descriptor for the class [name] class in [libraryUri].
///
/// /// ```
/// {
///   'className': <dart class name>,
///   'superClassName': <super class name, if any>
///   'superClassLibraryId': <super class library ID, if any>
///   'fields': {
///     <name>: {
///       'isConst': <true if the member is const>,
///       'isFinal': <true if the member is final>,
///       'isStatic':  <true if the member is final>,
///       'className': <class name for a field type>,
///       'classLibraryId': <library id for a field type>,
///     }
///   },
///   'methods': {
///     <name>: {
///       'isConst': <true if the member is const>,
///       'isStatic':  <true if the member is static>,
///       'isSetter" <true if the member is a setter>,
///       'isGetter" <true if the member is a getter>,
///     }
///   },
/// }
/// ```
/// TODO(annagrin): remove when debugger reads symbols.
/// Issue: https://github.com/dart-lang/sdk/issues/40273
Object? getClassMetadata(@notNull String libraryUri, @notNull String name) {
  var library = getLibrary('$libraryUri');
  if (library == null) throw 'cannot find library for $libraryUri';

  final rawName = name.split('<').first;
  var cls = _get<Object?>(library, rawName);
  if (cls == null) return null;

  var fieldDescriptors = <String, Object>{};
  _collectFieldDescriptors(
    fieldDescriptors,
    getFields(cls),
  );
  _collectFieldDescriptorsFromNames(
    fieldDescriptors,
    getStaticFields(cls),
    isStatic: true,
  );

  var methodDescriptors = <String, Object>{};

  _collectMethodDescriptors(
    methodDescriptors,
    getMethods(cls),
  );
  _collectMethodDescriptors(
    methodDescriptors,
    getSetters(cls),
    isSetter: true,
  );
  _collectMethodDescriptors(
    methodDescriptors,
    getGetters(cls),
    isGetter: true,
  );

  _collectMethodDescriptorsFromNames(
    methodDescriptors,
    getStaticMethods(cls),
    isStatic: true,
  );
  _collectMethodDescriptorsFromNames(
    methodDescriptors,
    getStaticSetters(cls),
    isStatic: true,
    isSetter: true,
  );
  _collectMethodDescriptorsFromNames(
    methodDescriptors,
    getStaticGetters(cls),
    isStatic: true,
    isGetter: true,
  );

  var className = _dartClassName(cls);
  String? superClassName;
  String? superClassLibraryId;
  if (className != 'Object') {
    var superCls = getPrototypeOf(cls);
    superClassName = _dartClassName(superCls);
    superClassLibraryId = getLibraryUri(superCls);
  }

  return _createJsObject({
    'className': className,
    if (superClassName != null) 'superClassName': superClassName,
    if (superClassLibraryId != null) 'superClassLibraryId': superClassLibraryId,
    'fields': _createJsObject(fieldDescriptors),
    'methods': _createJsObject(methodDescriptors),
  });
}

void _collectMethodDescriptorsFromNames(
  @notNull Map<String, dynamic> methodDescriptors,
  List? methodSymbols, {
  bool isStatic = false,
  bool isGetter = false,
  bool isSetter = false,
}) {
  for (var name in methodSymbols ?? []) {
    methodDescriptors[name] = _createJsObject({
      if (isStatic) 'isStatic': isStatic,
      if (isGetter) 'isGetter': isGetter,
      if (isSetter) 'isSetter': isSetter,
    });
  }
}

void _collectMethodDescriptors(
  @notNull Map<String, dynamic> methodDescriptors,
  Object? methods, {
  bool isStatic = false,
  bool isGetter = false,
  bool isSetter = false,
}) {
  if (methods == null) return;

  for (var symbol in getOwnNamesAndSymbols(methods)) {
    var name = _getDartSymbolName(symbol);
    if (name == null) continue;

    methodDescriptors[name] = _createJsObject({
      if (isStatic) 'isStatic': isStatic,
      if (isGetter) 'isGetter': isGetter,
      if (isSetter) 'isSetter': isSetter,
    });
  }
}

void _collectFieldDescriptorsFromNames(
  @notNull Map<String, dynamic> fieldDescriptors,
  List? fieldNames, {
  bool isStatic = false,
}) {
  for (var name in fieldNames ?? []) {
    fieldDescriptors[name] = _createJsObject({
      // TODO(annagrin) Add final, const, and type information.
      if (isStatic) 'isStatic': isStatic,
    });
  }
}

void _collectFieldDescriptors(
  @notNull Map<String, dynamic> fieldDescriptors,
  Object? fields, {
  bool isStatic = false,
}) {
  if (fields == null) return;

  for (var symbol in getOwnNamesAndSymbols(fields)) {
    var fieldInfo = _get<Object>(fields, symbol);
    var type = _get(fieldInfo, 'type');
    var isConst = _get(fieldInfo, 'isConst');
    var isFinal = _get(fieldInfo, 'isFinal');
    var libraryId = _get(fieldInfo, 'libraryUri');

    var className = typeName(type);
    var name = _getDartSymbolName(symbol);
    if (name == null) continue;

    fieldDescriptors[name] = _createJsObject({
      if (isConst) 'isConst': isConst,
      if (isFinal) 'isFinal': isFinal,
      if (isStatic) 'isStatic': isStatic,
      'className': className,
      if (libraryId != null) 'classLibraryId': libraryId,
    });
  }
}

/// Returns function metadata.
///
/// If [function] is bound to an object of class `C`,
/// returns `C.functionName`.
/// Otherwise, returns function name.
String getFunctionMetadata(@notNull Function function) {
  var name = _get<String>(function, 'name');
  var boundObject = _get<Object?>(function, '_boundObject');

  if (boundObject != null) {
    var cls = _get<Object>(boundObject, 'constructor');
    var className = _dartClassName(cls);

    var boundMethod = _get<Object>(function, '_boundMethod');
    name = className + '.' + _get<String>(boundMethod, 'name');
  }
  return name;
}

/// Collect object metadata.
///
/// Returns a JavaScript descriptor for the [object].
///
/// ```
/// {
///   'className': <dart class name>,
///   'libraryId': <library uri for the object type>,
///   'runtimeKind': <kind of the object for display purposes>,
///   'length': <length of the object if applicable>,
///   'typeName': <name of the type represented if object is a Type>,
/// }
/// ```
@notNull
Object getObjectMetadata(@notNull Object object) {
  var reifiedType = getReifiedType(object);
  var className = typeName(reifiedType);
  var libraryId = null;
  var cls = _get<Object?>(object, 'constructor');
  if (cls != null) {
    libraryId = getLibraryUri(cls);
  }
  var length = _get(object, 'length');
  var result = _createJsObject({
    'className': className,
    'libraryId': libraryId,
    'runtimeKind': RuntimeObjectKind.object,
    if (length != null) 'length': length,
  });

  if (object is List) {
    _set(result, 'runtimeKind', RuntimeObjectKind.list);
  } else if (object is Map) {
    _set(result, 'runtimeKind', RuntimeObjectKind.map);
  } else if (object is Set) {
    _set(result, 'runtimeKind', RuntimeObjectKind.set);
  } else if (object is Function) {
    _set(result, 'runtimeKind', RuntimeObjectKind.function);
  } else if (object is RecordImpl) {
    var shape = JS<Shape>('!', '#[#]', object, shapeProperty);
    var positionalCount = shape.positionals;
    var namedCount = shape.named?.length ?? 0;
    var length = positionalCount + namedCount;
    _set(result, 'libraryId', 'dart:core');
    _set(result, 'className', 'Record');
    _set(result, 'runtimeKind', RuntimeObjectKind.record);
    _set(result, 'length', length);
  } else if (object is Type) {
    if (_isRecordType(object)) {
      var elements = _recordTypeElementTypes(object);
      var length = _get(elements, 'length');
      _set(result, 'libraryId', 'dart:core');
      _set(result, 'className', 'Type');
      _set(result, 'runtimeKind', RuntimeObjectKind.recordType);
      _set(result, 'length', length);
    } else {
      var name = JS<String>('!', '#.toString()', object);
      _set(result, 'libraryId', 'dart:core');
      _set(result, 'className', 'Type');
      _set(result, 'runtimeKind', RuntimeObjectKind.type);
      _set(result, 'typeName', name);
    }
  } else if (object is NativeError) {
    if (className == 'LegacyJavaScriptObject') {
      // `getReifiedType` incorrectly returns `LegacyJavaScriptObject`
      // for a DartError instance, so we adjust its type here.
      // TODO(annagrin): fix in the type system instead.
      _set(result, 'className', 'NativeError');
    }
    _set(result, 'libraryId', 'dart:_interceptors');
    _set(result, 'runtimeKind', RuntimeObjectKind.nativeError);
  } else if (object is JavaScriptObject) {
    _set(result, 'libraryId', 'dart:_interceptors');
    _set(result, 'runtimeKind', RuntimeObjectKind.nativeObject);
  } else if (libraryId == null) {
    // Plain object with no constructor on the object.
    // Return empty metadata so the object is not displayed in the debugger.
    return _createEmptyJsObject();
  }
  return result;
}

/// Field names for [object].
///
/// Returns list of field names for the [object].
///
/// ```
/// {
///   'fields': [ <field name>, ...],
/// }
/// ```
/// TODO(annagrin): remove when debugger reads symbols.
/// Issue: https://github.com/dart-lang/sdk/issues/40273.
@notNull
List<String> getObjectFieldNames(@notNull Object object) {
  var fieldNames = <String>[];
  var cls = _get<Object>(object, 'constructor');

  _collectObjectFieldNames(fieldNames, getFields(cls));
  return fieldNames..sort();
}

void _collectObjectFieldNames(
  @notNull List<String> fieldNames,
  Object? fields,
) {
  if (fields == null) return;

  for (Object? current = fields;
      current != null;
      current = getPrototypeOf(current)) {
    for (var symbol in getOwnNamesAndSymbols(current)) {
      var name = _getDartSymbolName(symbol);
      if (name != null && !fieldNames.contains(name)) {
        fieldNames.add(name);
      }
    }
  }
}

/// Entries for [set].
///
/// Returns all entries for the [set].
///
/// ```
/// {
///   'entries': [ <entry>, ...],
/// }
/// ```
@notNull
Object getSetElements(@notNull Set set) {
  return _createJsObject({
    'entries': set.toList(),
  });
}

/// Elements for [map].
///
/// Returns all elements for the [map].
///
/// ```
/// {
///   'keys': [ <key>, ...],
///   'values': [ <value>, ...],
/// }
/// ```
@notNull
Object getMapElements(@notNull Map map) {
  return _createJsObject({
    'keys': map.keys.toList(),
    'values': map.values.toList(),
  });
}

/// Fields for [type].
///
/// Returns all fields for the [type] object.
///
/// ```
/// {
///   'hashCode': <hash code>,
///   'runtimeType': <runtime type>,
/// }
/// ```
/// TODO(annagrin): remove when debugger reads symbols.
/// Issue: https://github.com/dart-lang/sdk/issues/40273.
@notNull
Object getTypeFields(@notNull Type type) {
  return _createJsObject({
    'hashCode': type.hashCode,
    'runtimeType': type.runtimeType,
  });
}

/// Fields for [record].
///
/// Returns all fields for the [record].
///
/// ```
/// {
///   'positionalCount': <number of positional elements>,
///   'named': [ <name>, ...],
///   'values': [ <positional value>, ..., <named value>, ... ],
/// }
/// ```
@notNull
Object getRecordFields(@notNull RecordImpl record) {
  var shape = JS<Shape>('!', '#[#]', record, shapeProperty);
  var positionalCount = shape.positionals;
  var named = shape.named?.toList();
  var values = JS('!', '#[#]', record, valuesProperty);

  return _createJsObject({
    'positionalCount': positionalCount,
    'named': named,
    'values': values,
  });
}

/// Type fields for [recordType].
///
/// Returns all type fields for the [recordType].
///
/// ```
/// {
///   'positionalCount': <number of positional types>,
///   'named': [ <name>, ...],
///   'types': [ <positional type>, ..., <named type>, ... ],
/// }
/// ```
@notNull
Object getRecordTypeFields(@notNull Type recordType) {
  var types = _recordTypeElementTypes(recordType);
  var shape = _recordTypeShape(recordType);
  var positionalCount = shape.positionals;
  var named = shape.named?.toList();

  return _createJsObject({
    'positionalCount': positionalCount,
    'named': named,
    'types': types,
  });
}

/// Sub-range of [object]'s elements for partial display.
///
/// Returns a sub-range of at most [count] of [object] elements
/// starting at [offset] for Set, List and Map types.
/// Returns the original object for other types.
@notNull
Object getSubRange(@notNull Object object, int offset, int count) {
  if (object is Set) {
    return object.skip(offset).take(count).toList();
  }
  if (object is List) {
    return object.skip(offset).take(count).toList();
  }
  if (object is Map) {
    return object.entries.skip(offset).take(count).toList();
  }
  return object;
}

@notNull
bool _isDartClassObject(@notNull Object object) =>
    _get(object, rti.interfaceTypeRecipePropertyName) != null;

@notNull
String _dartClassName(@notNull Object cls) {
  String recipe = _get(cls, rti.interfaceTypeRecipePropertyName);
  return recipe.split('|').last;
}

@notNull
bool _isRecordType(@notNull Type type) => rti.isRecordType(type);

@notNull
List _recordTypeElementTypes(@notNull Type type) =>
    rti.getRecordTypeElementTypes(type);

@notNull
Shape _recordTypeShape(@notNull Type type) {
  var shapeKey = rti.getRecordTypeShapeKey(type);
  return _getValue<Shape>(shapes, shapeKey);
}

@notNull
String _symbolDescription(@notNull Object symbol) =>
    _get(symbol, 'description');

String? _getDartSymbolName(@notNull dynamic symbol) => symbol is String
    ? _getDartName(symbol)
    : _getDartName(_symbolDescription(symbol));

String? _getDartName(String? name) {
  if (name == null || name.startsWith('dartx.')) {
    return null;
  }
  // Show late fields: '_#C#lateField'.
  if (name.startsWith('_#')) {
    name = name.substring(name.indexOf('#') + 1);
  }
  if (name.contains('#')) {
    name = name.substring(name.indexOf('#') + 1);
  }
  // Do not show late field helpers: '_#C#lateField#isSet'.
  if (name.contains('#')) {
    return null;
  }
  return name.split('.').last;
}

Object _createEmptyJsObject() => JS('!', '{}');

Object _createJsObject(Map<String, dynamic> map) {
  var object = JS<Object>('!', '{}');
  for (var entry in map.entries) {
    _set(object, entry.key, entry.value);
  }
  return object;
}

void _set<T>(Object object, Object field, T value) =>
    JS('', '#[#] = #', object, field, value);

T _get<T>(Object object, Object field) => JS<T>('', '#[#]', object, field);

T _getValue<T>(dynamic map, Object key) => JS<T>('', '#.get(#)', map, key);
