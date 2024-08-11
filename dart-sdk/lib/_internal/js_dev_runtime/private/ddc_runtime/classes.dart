// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library defines the operations that define and manipulate Dart
/// classes.  Included in this are:
///   - Generics
///   - Class metadata
///   - Extension methods
///

// TODO(leafp): Consider splitting some of this out.
part of dart._runtime;

/// Returns a new type that mixes members from base and the mixin.
void applyMixin(@notNull Object to, @notNull Object from) {
  JS('', '#[#] = #', to, _mixin, from);
  var toProto = JS<Object>('!', '#.prototype', to);
  var fromProto = JS<Object>('!', '#.prototype', from);
  _copyMembers(toProto, fromProto);
  _mixinSignature(to, from, _methodSig);
  _mixinSignature(to, from, _methodsDefaultTypeArgSig);
  _mixinSignature(to, from, _fieldSig);
  _mixinSignature(to, from, _getterSig);
  _mixinSignature(to, from, _setterSig);
  var mixinOnFn = JS('', '#[#]', from, mixinOn);
  if (mixinOnFn != null) {
    var proto = JS<Object>(
        '!', '#(#).prototype', mixinOnFn, jsObjectGetPrototypeOf(to));
    _copyMembers(toProto, proto);
  }
}

void _copyMembers(@notNull Object to, @notNull Object from) {
  var names = getOwnNamesAndSymbols(from);
  for (int i = 0, n = JS('!', '#.length', names); i < n; ++i) {
    String name = JS('', '#[#]', names, i);
    if ('constructor' == name) continue;
    _copyMember(to, from, name);
  }
}

void _copyMember(
    @notNull Object to, @notNull Object from, @notNull Object name) {
  var desc = getOwnPropertyDescriptor(from, name);
  if (JS('!', '# == Symbol.iterator', name)) {
    // On native types, Symbol.iterator may already be present.
    // TODO(jmesserly): investigate if we still need this.
    // If so, we need to find a better solution.
    // See https://github.com/dart-lang/sdk/issues/28324
    var existing = getOwnPropertyDescriptor(to, name);
    if (existing != null) {
      if (JS('!', '#.writable', existing)) {
        JS('', '#[#] = #.value', to, name, desc);
      }
      return;
    }
  }
  var getter = JS('', '#.get', desc);
  var setter = JS('', '#.set', desc);
  if (getter != null) {
    if (setter == null) {
      var obj = JS<Object>(
          '!', '{ set [#](x) { return super[#] = x; } }', name, name);
      jsObjectSetPrototypeOf(obj, jsObjectGetPrototypeOf(to));
      JS<Object>(
          '!', '#.set = #.set', desc, getOwnPropertyDescriptor(obj, name));
    }
  } else if (setter != null) {
    if (getter == null) {
      var obj =
          JS<Object>('!', '{ get [#]() { return super[#]; } }', name, name);
      jsObjectSetPrototypeOf(obj, jsObjectGetPrototypeOf(to));
      JS<Object>(
          '!', '#.get = #.get', desc, getOwnPropertyDescriptor(obj, name));
    }
  }
  defineProperty(to, name, desc);
}

void _mixinSignature(@notNull Object to, @notNull Object from, kind) {
  JS('', '#[#] = #', to, kind, () {
    var baseMembers = _getMembers(jsObjectGetPrototypeOf(to), kind);
    // Coerce undefined to null.
    baseMembers = baseMembers == null ? null : baseMembers;
    var fromMembers = _getMembers(from, kind);
    if (fromMembers == null) return baseMembers;
    var toSignature = JS('', 'Object.create(#)', baseMembers);
    copyProperties(toSignature, fromMembers);
    return toSignature;
  });
}

final _mixin = JS('', 'Symbol("mixin")');

getMixin(clazz) => JS('', 'Object.hasOwnProperty.call(#, #) ? #[#] : null',
    clazz, _mixin, clazz, _mixin);

final mixinOn = JS('', 'Symbol("mixinOn")');

/// The Symbol for storing type arguments on a specialized generic type.
final _typeArguments = JS('', 'Symbol("typeArguments")');

final _originalDeclaration = JS('', 'Symbol("originalDeclaration")');

final mixinNew = JS('', 'Symbol("dart.mixinNew")');

/// Memoize a generic type constructor function.
generic(typeConstructor, setBaseClass) => JS('', '''(() => {
  let length = $typeConstructor.length;
  if (length < 1) {
    $throwInternalError('must have at least one generic type argument');
  }
  let resultMap = new Map();
  // TODO(vsm): Rethink how to clear the resultMap on hot restart.
  // A simple clear via:
  //   _cacheMaps.push(resultMap);
  // will break (a) we hoist type expressions in generated code and
  // (b) we don't clear those type expressions in the presence of a
  // hot restart.  Not clearing this map (as we're doing now) should
  // not affect correctness, but can result in a memory leak across
  // multiple restarts.
  function makeGenericType(...args) {
    if (args.length != length && args.length != 0) {
      $throwInternalError('requires ' + length + ' or 0 type arguments');
    }
    while (args.length < length) args.push(${TYPE_REF<dynamic>()});

    let value = resultMap;
    for (let i = 0; i < length; i++) {
      let arg = args[i];
      if (arg == null) {
        $throwInternalError('type arguments should not be null: '
                          + $typeConstructor);
      }
      let map = value;
      value = map.get(arg);
      if (value === void 0) {
        if (i + 1 == length) {
          value = $typeConstructor.apply(null, args);
          // Save the type constructor and arguments for reflection.
          if (value) {
            value[$_typeArguments] = args;
            value[$_originalDeclaration] = makeGenericType;
          }
          map.set(arg, value);
          if ($setBaseClass != null) $setBaseClass.apply(null, args);
        } else {
          value = new Map();
          map.set(arg, value);
        }
      }
    }
    return value;
  }
  makeGenericType[$_genericTypeCtor] = $typeConstructor;
  return makeGenericType;
})()''');

getGenericClass(type) => safeGetOwnProperty(type, _originalDeclaration);

/// Extracts the type argument as the accessor for the JS class.
///
/// Should be used in place of [getGenericClass] when we know the class we want
/// statically.
///
/// This value is extracted and inlined by the compiler without any runtime
/// operations. The implementation here is only provided as a theoretical fall
/// back and shouldn't actually be run.
///
/// For example `getGenericClassStatic<FutureOr>` emits `async.FutureOr$`
/// directly.
external getGenericClassStatic<T>();

// TODO(markzipan): Make this non-nullable if we can ensure this returns
// an empty list or if null and the empty list are semantically the same.
List? getGenericArgs(type) =>
    JS<List?>('', '#', safeGetOwnProperty(type, _typeArguments));

Object instantiateClass(Object genericClass, List<Object> typeArgs) {
  return JS('', '#.apply(null, #)', genericClass, typeArgs);
}

final _constructorSig = JS('', 'Symbol("sigCtor")');
final _methodSig = JS('', 'Symbol("sigMethod")');
final _methodsDefaultTypeArgSig = JS('', 'Symbol("sigMethodDefaultTypeArgs")');
final _fieldSig = JS('', 'Symbol("sigField")');
final _getterSig = JS('', 'Symbol("sigGetter")');
final _setterSig = JS('', 'Symbol("sigSetter")');
final _staticMethodSig = JS('', 'Symbol("sigStaticMethod")');
final _staticFieldSig = JS('', 'Symbol("sigStaticField")');
final _staticGetterSig = JS('', 'Symbol("sigStaticGetter")');
final _staticSetterSig = JS('', 'Symbol("sigStaticSetter")');
final _genericTypeCtor = JS('', 'Symbol("genericType")');
final _libraryUri = JS('', 'Symbol("libraryUri")');

getConstructors(value) => _getMembers(value, _constructorSig);
getMethods(value) => _getMembers(value, _methodSig);
getMethodsDefaultTypeArgs(value) =>
    _getMembers(value, _methodsDefaultTypeArgSig);
getFields(value) => _getMembers(value, _fieldSig);
getGetters(value) => _getMembers(value, _getterSig);
getSetters(value) => _getMembers(value, _setterSig);
getStaticMethods(value) => _getMembers(value, _staticMethodSig);
getStaticFields(value) => _getMembers(value, _staticFieldSig);
getStaticGetters(value) => _getMembers(value, _staticGetterSig);
getStaticSetters(value) => _getMembers(value, _staticSetterSig);

getGenericTypeCtor(value) => JS('', '#[#]', value, _genericTypeCtor);

/// Get the type of an object.
getType(obj) {
  if (obj == null) return JS('!', '#', Object);

  // Object.create(null) produces a js object without a prototype.
  // In that case use the native Object constructor.
  var constructor = JS('!', '#.constructor', obj);
  return JS('!', '# ? # : #.Object.prototype.constructor', constructor,
      constructor, global_);
}

getLibraryUri(value) => JS('', '#[#]', value, _libraryUri);
setLibraryUri(f, uri) => JS('', '#[#] = #', f, _libraryUri, uri);

/// Returns the name of the Dart class represented by [cls] including the
/// instantiated type arguments.
@notNull
String getClassName(Object? cls) {
  if (cls != null) {
    var tag = JS('', '#[#]', cls, rti.interfaceTypeRecipePropertyName);
    if (tag != null) {
      var name = JS<String>('!', '#.name', cls);
      var args = getGenericArgs(cls);
      if (args == null) return name;
      var result = name + '<';
      for (var i = 0; i < JS<int>('!', '#.length', args); ++i) {
        if (i > 0) result += ', ';
        result += typeName(JS('', '#[#]', args, i));
      }
      result += '>';
      return result;
    }
  }
  return 'unknown (null)';
}

/// Returns the class of the instance [obj].
///
/// The passed [obj] is expected to have a Dart class representation.
Object getClass(obj) => _jsInstanceOf(obj, Object)
    ? JS('', '#.constructor', obj)
    : JS('', '#[#]', obj, _extensionType);

bool isJsInterop(obj) {
  if (obj == null) return false;
  if (JS('!', 'typeof # === "function"', obj)) {
    // A function is a Dart function if it has runtime type information.
    return JS('!', '#[#] == null', obj, JS_GET_NAME(JsGetName.SIGNATURE_NAME));
  }
  // Primitive types are not JS interop types.
  if (JS('!', 'typeof # !== "object"', obj)) return false;

  // Extension types are not considered JS interop types.
  // Note that it is still possible to call typed JS interop methods on
  // extension types but the calls must be statically typed.
  if (JS('!', '#[#] != null', obj, _extensionType)) return false;

  // Exclude record types.
  if (_jsInstanceOf(obj, RecordImpl)) return false;
  return !_jsInstanceOf(obj, Object);
}

/// Get the type of a method from a type using the stored signature
getMethodType(type, name) {
  var m = getMethods(type);
  return m != null ? JS('', '#[#]', m, name) : null;
}

/// Returns the default type argument values for the instance method [name] on
/// the class [type].
JSArray<Object> getMethodDefaultTypeArgs(type, name) =>
    JS('!', '#[#]', getMethodsDefaultTypeArgs(type), name);

/// Gets the type of the corresponding setter (this includes writable fields).
getSetterType(type, name) {
  var setters = getSetters(type);
  if (setters != null) {
    var type = JS('', '#[#]', setters, name);
    // TODO(nshahan): setters object has properties installed on the global
    // Object that requires some extra validation to ensure they are intended
    // as setters. ex: dartx.hashCode, dartx._equals, dartx.toString etc.
    //
    // There is a value mapped to 'toString' in setters so broken code like this
    // results in very confusing behavior:
    // `d.toString = 99;`
    if (type != null) {
      return type;
    }
  }
  var fields = getFields(type);
  if (fields != null) {
    var fieldInfo = JS('', '#[#]', fields, name);
    if (fieldInfo != null && JS<bool>('!', '!#.isFinal', fieldInfo)) {
      return JS('', '#.type', fieldInfo);
    }
  }
  return null;
}

/// Get the type of a constructor from a class using the stored signature
/// If name is undefined, returns the type of the default constructor
/// Returns undefined if the constructor is not found.
classGetConstructorType(cls, name) {
  if (cls == null) return null;
  if (name == null) name = 'new';
  var ctors = getConstructors(cls);
  return ctors != null ? JS('', '#[#]', ctors, name) : null;
}

void setMethodSignature(f, sigF) => JS('', '#[#] = #', f, _methodSig, sigF);
void setMethodsDefaultTypeArgSignature(f, sigF) =>
    JS('', '#[#] = #', f, _methodsDefaultTypeArgSig, sigF);
void setFieldSignature(f, sigF) => JS('', '#[#] = #', f, _fieldSig, sigF);
void setGetterSignature(f, sigF) => JS('', '#[#] = #', f, _getterSig, sigF);
void setSetterSignature(f, sigF) => JS('', '#[#] = #', f, _setterSig, sigF);

// Set up the constructor signature field on the constructor
void setConstructorSignature(f, sigF) =>
    JS('', '#[#] = #', f, _constructorSig, sigF);

// Set up the static signature field on the constructor
void setStaticMethodSignature(f, sigF) =>
    JS('', '#[#] = #', f, _staticMethodSig, sigF);

void setStaticFieldSignature(f, sigF) =>
    JS('', '#[#] = #', f, _staticFieldSig, sigF);

void setStaticGetterSignature(f, sigF) =>
    JS('', '#[#] = #', f, _staticGetterSig, sigF);

void setStaticSetterSignature(f, sigF) =>
    JS('', '#[#] = #', f, _staticSetterSig, sigF);

_getMembers(type, kind) {
  var sig = JS('', '#[#]', type, kind);
  // The results of these lookups are sometimes used as a proto for new
  // signature storage objects in subclasses. Undefined is coerced to null so
  // the value can be used in `Object.setPrototypeOf()`.
  if (sig == null) return null;
  return JS<bool>('!', 'typeof # == "function"', sig)
      ? JS('', '#[#] = #()', type, kind, sig)
      : sig;
}

bool _hasMember(type, kind, name) {
  var sig = _getMembers(type, kind);
  return sig != null && JS<bool>('!', '# in #', name, sig);
}

bool hasMethod(type, name) => _hasMember(type, _methodSig, name);
bool hasGetter(type, name) => _hasMember(type, _getterSig, name);
bool hasSetter(type, name) => _hasMember(type, _setterSig, name);
bool hasField(type, name) => _hasMember(type, _fieldSig, name);

final _extensionType = JS('', 'Symbol("extensionType")');

final dartx = JS('', 'dartx');

/// Install properties in prototype-first order.  Properties / descriptors from
/// more specific types should overwrite ones from less specific types.
void _installProperties(jsProto, dartType, installedParent) {
  if (JS('!', '# === #', dartType, JS_CLASS_REF(Object))) {
    _installPropertiesForObject(jsProto);
    return;
  }
  // If the extension methods of the parent have been installed on the parent
  // of [jsProto], the methods will be available via prototype inheritance.
  var dartSupertype = jsObjectGetPrototypeOf(JS<Object>('!', '#', dartType));
  if (JS('!', '# !== #', dartSupertype, installedParent)) {
    _installProperties(jsProto, dartSupertype, installedParent);
  }

  var dartProto = JS<Object>('!', '#.prototype', dartType);
  copyTheseProperties(jsProto, dartProto, getOwnPropertySymbols(dartProto));
}

void _installPropertiesForObject(jsProto) {
  // core.Object members need to be copied from the non-symbol name to the
  // symbol name.
  var coreObjProto = JS<Object>('!', '#.prototype', JS_CLASS_REF(Object));
  var names = getOwnPropertyNames(coreObjProto);
  for (int i = 0, n = JS('!', '#.length', names); i < n; ++i) {
    var name = JS<String>('!', '#[#]', names, i);
    if ('constructor' == name) continue;
    var desc = getOwnPropertyDescriptor(coreObjProto, name);
    defineProperty(jsProto, JS('', '#.#', dartx, name), desc);
  }
}

/// Sets the [identityEquals] method to the equality operator from the Core
/// Object class.
///
/// Only called once by generated code after the Core Object class definition.
void _installIdentityEquals() {
  identityEquals ??= JS('', '#.prototype[dartx._equals]', JS_CLASS_REF(Object));
}

final _extensionMap = JS('', 'new Map()');

/// Adds Dart properties to native JS types.
void _applyExtension(jsType, dartExtType) {
  // Exit early when encountering a JS type without a prototype (such as
  // structs).
  if (jsType == null) return;
  var jsProto = JS<Object?>('', '#.prototype', jsType);
  if (jsProto == null) return;

  if (JS('!', '# === #', dartExtType, JS_CLASS_REF(Object))) return;

  if (JS('!', '# === #.Object', jsType, global_)) {
    var extName = JS<String>('!', '#.name', dartExtType);
    _warn(
        "Attempting to install properties from non-Object type '$extName' onto the native JS Object.");
    return;
  }

  _installProperties(
      jsProto, dartExtType, JS('', '#[#]', jsProto, _extensionType));

  // Mark the JS type's instances so we can easily check for extensions.
  if (JS('!', '# !== #', dartExtType, JS_CLASS_REF(JSFunction))) {
    JS('', '#[#] = #', jsProto, _extensionType, dartExtType);
  }

  // Attach member signature tags.
  JS('', '#[#] = #[#]', jsType, _methodSig, dartExtType, _methodSig);
  JS('', '#[#] = #[#]', jsType, _methodsDefaultTypeArgSig, dartExtType,
      _methodsDefaultTypeArgSig);
  JS('', '#[#] = #[#]', jsType, _fieldSig, dartExtType, _fieldSig);
  JS('', '#[#] = #[#]', jsType, _getterSig, dartExtType, _getterSig);
  JS('', '#[#] = #[#]', jsType, _setterSig, dartExtType, _setterSig);
}

/// Apply the previously registered extension to the type of [nativeObject].
/// This is intended for types that are not available to polyfill at startup.
applyExtension(name, nativeObject) {
  var dartExtType = JS('', '#.get(#)', _extensionMap, name);
  var jsType = JS('', '#.constructor', nativeObject);
  _applyExtension(jsType, dartExtType);
}

/// Apply all registered extensions to a window.  This is intended for
/// different frames, where registrations need to be reapplied.
applyAllExtensions(global) {
  JS('', '#.forEach((dartExtType, name) => #(#[name], dartExtType))',
      _extensionMap, _applyExtension, global);
}

/// Copy symbols from the prototype of the source to destination.
/// These are the only properties safe to copy onto an existing public
/// JavaScript class.
registerExtension(name, dartExtType) {
  JS('', '#.set(#, #)', _extensionMap, name, dartExtType);
  var jsType = JS('', '#[#]', global_, name);
  _applyExtension(jsType, dartExtType);
}

/// Apply a previously registered extension for testing purposes.
///
/// This method's only purpose is to aid in testing native classes. Most native
/// tests define JavaScript classes in user code (e.g. in an eval string). The
/// dartdevc compiler properly calls `registerExtension` when processing the
/// native class declarations in Dart, but at that point in time the JavaScript
/// counterpart is not defined.
///
/// This method is used to lookup those registrations and reapply the extension
/// after the JavaScript declarations are added.
///
/// An alternative to this would be to invest in a better test infrastructure
/// that would let us define the JavaScript code prior to loading the compiled
/// module.
applyExtensionForTesting(name) {
  var dartExtType = JS('', '#.get(#)', _extensionMap, name);
  var jsType = JS('', '#[#]', global_, name);
  _applyExtension(jsType, dartExtType);
}

///
/// Mark a concrete type as implementing extension methods.
/// For example: `class MyIter implements Iterable`.
///
/// This takes a list of names, which are the extension methods implemented.
/// It will add a forwarder, so the extension method name redirects to the
/// normal Dart method name. For example:
///
///     defineExtensionMembers(MyType, ['add', 'remove']);
///
/// Results in:
///
///     MyType.prototype[dartx.add] = MyType.prototype.add;
///     MyType.prototype[dartx.remove] = MyType.prototype.remove;
///
// TODO(jmesserly): essentially this gives two names to the same method.
// This benefit is roughly equivalent call performance either way, but the
// cost is we need to call defineExtensionMembers any time a subclass
// overrides one of these methods.
defineExtensionMethods(type, Iterable memberNames) {
  var proto = JS('', '#.prototype', type);
  for (var name in memberNames) {
    JS('', '#[dartx.#] = #[#]', proto, name, proto, name);
  }
}

/// Like [defineExtensionMethods], but for getter/setter pairs.
void defineExtensionAccessors(type, Iterable memberNames) {
  var proto = JS<Object>('!', '#.prototype', type);
  for (var name in memberNames) {
    // Find the member. It should always exist (or we have a compiler bug).
    var member;
    Object? p = proto;
    for (; p != null; p = jsObjectGetPrototypeOf(p)) {
      member = getOwnPropertyDescriptor(p, name);
      if (member != null) break;
    }
    defineProperty(proto, JS('', 'dartx[#]', name), member);
  }
}

definePrimitiveHashCode(proto) {
  defineProperty(proto, identityHashCode_,
      getOwnPropertyDescriptor(proto, extensionSymbol('hashCode')));
}

/// Link the [dartType] to the native [jsType] it is extending as a base class.
///
/// Used for generic extension types such as `JSArray<E>`.
void setExtensionBaseClass(@notNull Object dartType, @notNull Object jsType) {
  // Mark the generic type as an extension type and link the prototype objects.
  var dartProto = JS<Object>('!', '#.prototype', dartType);
  JS('', '#[#] = #', dartProto, _extensionType, dartType);
  jsObjectSetPrototypeOf(dartProto, JS('', '#.prototype', jsType));
}

/// A runtime mapping of interface type recipe to the symbol used to tag the
/// class for simple identification in the dart:rti library.
///
/// Maps String -> JavaScript Symbol.
final _typeTagSymbols = JS<Object>('!', 'new Map()');

Object typeTagSymbol(String recipe) {
  var tag = '${JS_GET_NAME(JsGetName.OPERATOR_IS_PREFIX)}${recipe}';
  var probe = JS<Object?>('', '#[#]', _typeTagSymbols, tag);
  if (probe != null) return probe;
  var tagSymbol = JS<Object>('!', 'Symbol(#)', tag);
  JS('', '#[#] = #', _typeTagSymbols, tag, tagSymbol);
  return tagSymbol;
}

/// Attaches the class type recipe and the type tags for all implemented
/// [interfaceRecipes] to [classRef].
///
/// The tags are used for simple identification of instances in the dart:rti
/// library.
///
/// The first element of [interfaceRecipes] must always be the type recipe for
/// the type represented by [classRef].
void addRtiResources(Object classRef, JSArray<String> interfaceRecipes) {
  // Create a rti object cache property used in dart:_rti.
  JS('', '#[#] = null', classRef, rti.constructorRtiCachePropertyName);
  // Attach the [classRef]'s own interface type recipe.
  // The recipe is used in dart:_rti to create an [rti.Rti] instance when
  // needed.
  JS('', r'#.# = #[0]', classRef, rti.interfaceTypeRecipePropertyName,
      interfaceRecipes);
  // Add specialized test resources used for fast interface type checks in
  // dart:_rti.
  var prototype = JS<Object>('!', '#.prototype', classRef);
  for (var recipe in interfaceRecipes) {
    var tagSymbol = typeTagSymbol(recipe);
    JS('', '#.# = #', prototype, tagSymbol, true);
  }
}

/// The default `operator ==` that calls [identical].
var identityEquals;
