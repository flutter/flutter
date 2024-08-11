// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library defines runtime operations on objects used by the code
/// generator.
part of dart._runtime;

// TODO(jmesserly): remove this in favor of _Invocation.
class InvocationImpl extends Invocation {
  final Symbol memberName;
  final List positionalArguments;
  final Map<Symbol, dynamic> namedArguments;
  final List<Type> typeArguments;
  final bool isMethod;
  final bool isGetter;
  final bool isSetter;
  final String failureMessage;

  InvocationImpl(memberName, List<Object?> positionalArguments,
      {namedArguments,
      List typeArguments = const [],
      this.isMethod = false,
      this.isGetter = false,
      this.isSetter = false,
      this.failureMessage = 'method not found'})
      : memberName =
            isSetter ? _setterSymbol(memberName) : _dartSymbol(memberName),
        positionalArguments = List.unmodifiable(positionalArguments),
        namedArguments = _namedArgsToSymbols(namedArguments),
        typeArguments = List.unmodifiable(typeArguments
            .map((t) => rti.createRuntimeType(JS<rti.Rti>('!', '#', t))));

  static Map<Symbol, dynamic> _namedArgsToSymbols(namedArgs) {
    if (namedArgs == null) return const {};
    return Map.unmodifiable(Map.fromIterable(getOwnPropertyNames(namedArgs),
        key: _dartSymbol, value: (k) => JS('', '#[#]', namedArgs, k)));
  }
}

/// Given an object and a method name, tear off the method.
/// Sets the runtime type of the torn off method appropriately,
/// and also binds the object.
///
/// If the optional `f` argument is passed in, it will be used as the method.
/// This supports cases like `super.foo` where we need to tear off the method
/// from the superclass, not from the `obj` directly.
// TODO(leafp): Consider caching the tearoff on the object?
bind(obj, name, method) {
  if (obj == null) obj = jsNull;
  if (method == null) method = JS('', '#[#]', obj, name);
  var f = JS('', '#.bind(#)', method, obj);
  // TODO(jmesserly): canonicalize tearoffs.
  JS('', '#._boundObject = #', f, obj);
  JS('', '#._boundMethod = #', f, method);
  var objType = getType(obj);
  var methodType = getMethodType(objType, name);
  // Native JavaScript methods do not have Dart signatures attached that need
  // to be copied.
  if (methodType != null) {
    if (rti.isGenericFunctionType(methodType)) {
      // Attach the default type argument values to the new function in case
      // they are needed for a dynamic call.
      var defaultTypeArgs = getMethodDefaultTypeArgs(objType, name);
      JS('', '#._defaultTypeArgs = #', f, defaultTypeArgs);
    }
    JS('', '#[#] = #', f, JS_GET_NAME(JsGetName.SIGNATURE_NAME), methodType);
  }
  return f;
}

/// Binds the `call` method of an interface type, handling null.
///
/// Essentially this works like `obj?.call`. It also handles the needs of
/// [dsend]/[dcall], returning `null` if no method was found with the given
/// canonical member [name].
///
/// [name] is typically `"call"` but it could be the [extensionSymbol] for
/// `call`, if we define it on a native type, and [obj] is known statially to be
/// a native type/interface with `call`.
bindCall(obj, name) {
  if (obj == null) return null;
  var objType = getType(obj);
  var ftype = getMethodType(objType, name);
  if (ftype == null) return null;
  var method = JS('', '#[#]', obj, name);
  var f = JS('', '#.bind(#)', method, obj);
  // TODO(jmesserly): canonicalize tearoffs.
  JS('', '#._boundObject = #', f, obj);
  JS('', '#._boundMethod = #', f, method);
  JS('', '#[#] = #', f, JS_GET_NAME(JsGetName.SIGNATURE_NAME), ftype);
  if (rti.isGenericFunctionType(ftype)) {
    // Attach the default type argument values to the new function in case
    // they are needed for a dynamic call.
    var defaultTypeArgs = getMethodDefaultTypeArgs(objType, name);
    JS('', '#._defaultTypeArgs = #', f, defaultTypeArgs);
  }
  return f;
}

/// Instantiate a generic method.
///
/// We need to apply the type arguments both to the function, as well as its
/// associated function type.
gbind(f, @rest List<Object> typeArgs) {
  Object fnType = JS('!', '#[#]', f, JS_GET_NAME(JsGetName.SIGNATURE_NAME));
  var instantiationBinding =
      rti.bindingRtiFromList(JS<JSArray>('!', '#', typeArgs));
  var instantiatedType = rti.instantiatedGenericFunctionType(
      JS<rti.Rti>('!', '#', fnType), instantiationBinding);
  // Create a JS wrapper function that will also pass the type arguments.
  var result =
      JS('', '(...args) => #.apply(null, #.concat(args))', f, typeArgs);
  // Tag the wrapper with the original function to be used for equality
  // checks.
  JS('', '#["_originalFn"] = #', result, f);
  JS('', '#["_typeArgs"] = #', result, constList(typeArgs, Object));

  // Tag the wrapper with the instantiated function type.
  return fn(result, instantiatedType);
}

dloadRepl(obj, field) => dload(obj, replNameLookup(obj, field));

// Warning: dload, dput, and dsend assume they are never called on methods
// implemented by the Object base class as those methods can always be
// statically resolved.
dload(obj, field) {
  if (JS('!', 'typeof # == "function" && # == "call"', obj, field)) {
    return obj;
  }
  var f = _canonicalMember(obj, field);

  trackCall(obj);
  if (f != null) {
    var type = getType(obj);

    if (hasField(type, f) || hasGetter(type, f)) return JS('', '#[#]', obj, f);
    if (hasMethod(type, f)) return bind(obj, f, null);

    // Handle record types by trying to access [f] via convenience getters.
    if (_jsInstanceOf(obj, RecordImpl) && f is String) {
      // It is a compile-time error for record names to clash, so we don't
      // need to check the positionals or named elements in any order.
      var value = JS('', '#.#', obj, f);
      if (JS('!', '# !== void 0', value)) return value;
    }

    // Always allow for JS interop objects.
    if (isJsInterop(obj)) return JS('', '#[#]', obj, f);
  }
  return noSuchMethod(obj, InvocationImpl(field, JS('', '[]'), isGetter: true));
}

_stripGenericArguments(type) {
  var genericClass = getGenericClass(type);
  if (genericClass != null) return JS('', '#()', genericClass);
  return type;
}

dputRepl(obj, field, value) => dput(obj, replNameLookup(obj, field), value);

dput(obj, field, value) {
  var f = _canonicalMember(obj, field);
  trackCall(obj);
  if (f != null) {
    var setterType = getSetterType(getType(obj), f);
    if (setterType != null) {
      return JS('', '#[#] = #.#(#)', obj, f, setterType,
          JS_GET_NAME(JsGetName.RTI_FIELD_AS), value);
    }
    // Always allow for JS interop objects.
    if (isJsInterop(obj)) return JS('', '#[#] = #', obj, f, value);
  }
  noSuchMethod(
      obj, InvocationImpl(field, JS('', '[#]', value), isSetter: true));
  return value;
}

/// Returns an error message if function of a given [type] can't be applied to
/// [actuals] and [namedActuals].
///
/// Returns `null` if all checks pass.
// TODO(48585): Revise argument types after removing old type representation.
String? _argumentErrors(Object type, @notNull List actuals, namedActuals) {
  var functionParameters = rti.getFunctionParametersForDynamicChecks(type);
  // Check for too few positional arguments.
  var requiredPositional = JS('!', '#.requiredPositional', functionParameters);
  var requiredCount = JS<int>('!', '#.length', requiredPositional);
  var actualsCount = actuals.length;
  if (actualsCount < requiredCount) {
    return 'Dynamic call with missing positional arguments. '
        'Expected: $requiredCount Actual: $actualsCount';
  }
  // Check for too many positional arguments.
  var extras = actualsCount - requiredCount;
  var optionalPositional = JS('!', '#.optionalPositional', functionParameters);
  var optionalPositionalCount = JS<int>('!', '#.length', optionalPositional);
  if (extras > optionalPositionalCount) {
    var maxPositionalCount = requiredCount + optionalPositionalCount;
    var expected = requiredCount == maxPositionalCount
        ? '$maxPositionalCount'
        : '$requiredCount - $maxPositionalCount';
    return 'Dynamic call with too many positional arguments. '
        'Expected: $expected '
        'Actual: $actualsCount';
  }
  // Check if we have invalid named arguments.
  Iterable? names;
  var requiredNamed = JS('!', '#.requiredNamed', functionParameters);
  var optionalNamed = JS('!', '#.optionalNamed', functionParameters);
  if (namedActuals != null) {
    names = getOwnPropertyNames(namedActuals);
    for (var name in names) {
      if (!JS<bool>('!', '#.hasOwnProperty(#) || #.hasOwnProperty(#)',
          requiredNamed, name, optionalNamed, name)) {
        return "Dynamic call with unexpected named argument '$name'.";
      }
    }
  }
  // Verify that all required named parameters are provided an argument.
  Iterable requiredNames = getOwnPropertyNames(requiredNamed);
  if (JS<int>('!', '#.length', requiredNames) > 0) {
    var missingRequired = namedActuals == null
        ? requiredNames
        : requiredNames.where((name) =>
            !JS<bool>('!', '#.hasOwnProperty(#)', namedActuals, name));
    if (missingRequired.isNotEmpty) {
      var argNames = JS<String>('!', '#.join(", ")', missingRequired);
      var error = "Dynamic call with missing required named arguments: "
          "$argNames.";
      if (!JS_GET_FLAG('SOUND_NULL_SAFETY')) {
        _nullWarn(error);
      } else {
        return error;
      }
    }
  }
  // Now that we know the signature matches, we can perform type checks.
  for (var i = 0; i < requiredCount; ++i) {
    var requiredRti = JS<rti.Rti>('!', '#[#]', requiredPositional, i);
    var passedValue = JS('', '#[#]', actuals, i);
    JS('', '#.#(#)', requiredRti, JS_GET_NAME(JsGetName.RTI_FIELD_AS),
        passedValue);
  }
  for (var i = 0; i < extras; ++i) {
    var optionalRti = JS<rti.Rti>('!', '#[#]', optionalPositional, i);
    var passedValue = JS('', '#[#]', actuals, i + requiredCount);
    JS('', '#.#(#)', optionalRti, JS_GET_NAME(JsGetName.RTI_FIELD_AS),
        passedValue);
  }
  if (names != null) {
    for (var name in names) {
      var namedRti = JS<rti.Rti>(
          '!', '#[#] || #[#]', requiredNamed, name, optionalNamed, name);
      var passedValue = JS('', '#[#]', namedActuals, name);
      JS('', '#.#(#)', namedRti, JS_GET_NAME(JsGetName.RTI_FIELD_AS),
          passedValue);
    }
  }
  return null;
}

_toSymbolName(symbol) => JS('', '''(() => {
        let str = $symbol.toString();
        // Strip leading 'Symbol(' and trailing ')'
        return str.substring(7, str.length-1);
    })()''');

_toDisplayName(name) => JS('', '''(() => {
      // Names starting with _ are escaped names used to disambiguate Dart and
      // JS names.
      if ($name[0] === '_') {
        // Inverse of
        switch($name) {
          case '_get':
            return '[]';
          case '_set':
            return '[]=';
          case '_negate':
            return 'unary-';
          case '_constructor':
          case '_prototype':
            return $name.substring(1);
        }
      }
      return $name;
  })()''');

Symbol _dartSymbol(name) {
  return (JS<bool>('!', 'typeof # === "symbol"', name))
      ? JS('Symbol', '#(new #.new(#, #))', const_, JS_CLASS_REF(PrivateSymbol),
          _toSymbolName(name), name)
      : JS('Symbol', '#(new #.new(#))', const_, JS_CLASS_REF(internal.Symbol),
          _toDisplayName(name));
}

Symbol _setterSymbol(name) {
  return (JS<bool>('!', 'typeof # === "symbol"', name))
      ? JS('Symbol', '#(new #.new(# + "=", #))', const_,
          JS_CLASS_REF(PrivateSymbol), _toSymbolName(name), name)
      : JS('Symbol', '#(new #.new(# + "="))', const_,
          JS_CLASS_REF(internal.Symbol), _toDisplayName(name));
}

/// Checks for a valid function, receiver and arguments before calling [f].
///
/// If passed, [args] and [typeArgs] must be native JavaScript arrays.
///
/// NOTE: The contents of [args] may be modified before calling [f]. If it
/// originated outside of the SDK it must be copied first.
// TODO(48585) Revise argument types after removing old type representation.
_checkAndCall(f, ftype, obj, typeArgs, args, named, displayName) {
  trackCall(obj);
  var originalTarget = JS<bool>('!', '# === void 0', obj) ? f : obj;

  callNSM(@notNull String errorMessage) {
    return noSuchMethod(
        originalTarget,
        InvocationImpl(displayName, JS<List<Object?>>('!', '#', args),
            namedArguments: named,
            // Repeated the default value here in JS to preserve the historic
            // behavior.
            typeArguments: JS('!', '# || []', typeArgs),
            isMethod: true,
            failureMessage: errorMessage));
  }

  if (f == null) return callNSM('Dynamic call of null.');
  if (!JS<bool>('!', '# instanceof Function', f)) {
    // We're not a function (and hence not a method either)
    // Grab the `call` method if it's not a function.
    if (f != null) {
      // Getting the member succeeded, so update the originalTarget.
      // (we're now trying `call()` on `f`, so we want to call its nSM rather
      // than the original target's nSM).
      originalTarget = f;
      f = bindCall(f, _canonicalMember(f, 'call'));
      ftype = null;
      displayName = 'call';
    }
    if (f == null) {
      return callNSM("Dynamic call of object has no instance method 'call'.");
    }
  }
  // If f is a function, but not a method (no method type)
  // then it should have been a function valued field, so
  // get the type from the function.
  if (ftype == null) {
    ftype = JS<rti.Rti?>('', '#[#]', f, JS_GET_NAME(JsGetName.SIGNATURE_NAME));
  }

  if (ftype == null) {
    // TODO(leafp): Allow JS objects to go through?
    if (typeArgs != null) {
      // TODO(jmesserly): is there a sensible way to handle these?
      throwTypeError('call to JS object `' +
          // Not a String but historically relying on the default JavaScript
          // behavior.
          JS<String>('!', '#', obj) +
          '` with type arguments <' +
          // Not a String but historically relying on the default JavaScript
          // behavior.
          JS<String>('!', '#', typeArgs) +
          '> is not supported.');
    }

    if (named != null) JS('', '#.push(#)', args, named);
    return JS('', '#.apply(#, #)', f, obj, args);
  }

  // Apply type arguments if needed.
  if (rti.isGenericFunctionType(ftype)) {
    var typeParameterBounds = rti.getGenericFunctionBounds(ftype);
    var typeParameterCount = JS<int>('!', '#.length', typeParameterBounds);
    if (typeArgs == null) {
      // No type arguments were provided so they will take on their default
      // values that are attached to generic function tearoffs for this
      // purpose.
      //
      // Note the default value is not always equivalent to the bound for a
      // given type parameter. The bound can reference other type parameters
      // and contain infinite cycles where the default value is determined
      // with an algorithm that will terminate. This means that the default
      // values will need to be checked against the instantiated bounds just
      // like any other type arguments.
      typeArgs = JS('!', '#._defaultTypeArgs', f);
    }
    var typeArgCount = JS<int>('!', '#.length', typeArgs);
    if (typeArgCount != typeParameterCount) {
      return callNSM('Dynamic call with incorrect number of type arguments. '
          'Expected: $typeParameterCount Actual: $typeArgCount');
    } else {
      // Check the provided type arguments against the instantiated bounds.
      for (var i = 0; i < typeParameterCount; i++) {
        var bound = JS<rti.Rti>('!', '#[#]', typeParameterBounds, i);
        var typeArg = JS<rti.Rti>('!', '#[#]', typeArgs, i);
        // TODO(nshahan): Skip type checks when the bound is a top type once
        // there is no longer any warnings/errors in weak null safety mode.
        if (bound != typeArg) {
          var instantiatedBound = rti.substitute(bound, typeArgs);
          var validSubtype = rti.isSubtype(
              JS_EMBEDDED_GLOBAL('', RTI_UNIVERSE), typeArg, instantiatedBound);
          if (!validSubtype) {
            throwTypeError("The type '${rti.rtiToString(typeArg)}' "
                "is not a subtype of the type variable bound "
                "'${rti.rtiToString(instantiatedBound)}' "
                "of type variable 'T${i + 1}' "
                "in '${rti.rtiToString(ftype)}'.");
          }
        }
      }
    }
    var instantiationBinding =
        rti.bindingRtiFromList(JS<JSArray>('!', '#', typeArgs));
    ftype = rti.instantiatedGenericFunctionType(
        JS<rti.Rti>('!', '#', ftype), instantiationBinding);
  } else if (typeArgs != null) {
    return callNSM('Dynamic call with unexpected type arguments. '
        'Expected: 0 Actual: ${JS<int>('!', '#.length', typeArgs)}');
  }
  var errorMessage = _argumentErrors(ftype, JS<List>('!', '#', args), named);
  if (errorMessage == null) {
    if (typeArgs != null) args = JS('', '#.concat(#)', typeArgs, args);
    if (named != null) JS('', '#.push(#)', args, named);
    return JS('', '#.apply(#, #)', f, obj, args);
  }
  return callNSM(errorMessage);
}

/// Given a Dart function [f] that was wrapped in a `Function.toJS` call, and
/// the corresponding [args] used to call it, validates that the arity and types
/// of [args] are correct.
///
/// Returns null if it's valid call and a [noSuchMethod] invocation with the
/// specific error otherwise.
validateFunctionToJSArgs(f, List args) {
  var errorMessage = _argumentErrors(
      JS<Object>('', '#[#]', f, JS_GET_NAME(JsGetName.SIGNATURE_NAME)),
      args,
      null);
  if (errorMessage != null) {
    return noSuchMethod(
        f,
        InvocationImpl(JS('', 'f.name'), args,
            isMethod: true, failureMessage: errorMessage));
  }
  return null;
}

dcall(f, args, [@undefined named]) => _checkAndCall(
    f, null, JS('', 'void 0'), null, args, named, JS('', 'f.name'));

dgcall(f, typeArgs, args, [@undefined named]) => _checkAndCall(f, null,
    JS('', 'void 0'), typeArgs, args, named, JS('', "f.name || 'call'"));

/// Helper for REPL dynamic invocation variants that make a best effort to
/// enable accessing private members across library boundaries.
replNameLookup(object, field) => JS('', '''(() => {
  let rawField = $field;
  if (typeof(field) == 'symbol') {
    // test if the specified field exists in which case it is safe to use it.
    if ($field in $object) return $field;

    // Symbol is from a different library. Make a best effort to
    $field = $field.toString();
    $field = $field.substring('Symbol('.length, field.length - 1);

  } else if ($field.charAt(0) != '_') {
    // Not a private member so default call path is safe.
    return $field;
  }

  // If the exact field name is present, invoke callback with it.
  if ($field in $object) return $field;

  // TODO(jacobr): warn if there are multiple private members with the same
  // name which could happen if super classes in different libraries have
  // the same private member name.
  let proto = $object;
  while (proto !== null) {
    // Private field (indicated with "_").
    let symbols = Object.getOwnPropertySymbols(proto);
    let target = 'Symbol(' + $field + ')';

    for (let s = 0; s < symbols.length; s++) {
      let sym = symbols[s];
      if (target == sym.toString()) return sym;
    }
    proto = Object.getPrototypeOf(proto);
  }
  // We didn't find a plausible alternate private symbol so just fall back
  // to the regular field.
  return rawField;
})()''');

/// Shared code for dsend, dindex, and dsetindex.
callMethod(obj, name, typeArgs, args, named, displayName) {
  if (JS('!', 'typeof # == "function" && # == "call"', obj, name)) {
    return dgcall(obj, typeArgs, args, named);
  }
  var symbol = _canonicalMember(obj, name);
  if (symbol == null) {
    return noSuchMethod(obj, InvocationImpl(displayName, args, isMethod: true));
  }
  var f = obj != null ? JS('', '#[#]', obj, symbol) : null;
  var type = getType(obj);
  var ftype = getMethodType(type, symbol);
  if (ftype != null && rti.isGenericFunctionType(ftype) && typeArgs == null) {
    // No type arguments were provided, use the default values in this call.
    typeArgs = getMethodDefaultTypeArgs(type, symbol);
  }
  // No such method if dart object and ftype is missing.
  return _checkAndCall(f, ftype, obj, typeArgs, args, named, displayName);
}

dsend(obj, method, args, [@undefined named]) =>
    callMethod(obj, method, null, args, named, method);

dgsend(obj, typeArgs, method, args, [@undefined named]) =>
    callMethod(obj, method, typeArgs, args, named, method);

dsendRepl(obj, method, args, [@undefined named]) =>
    callMethod(obj, replNameLookup(obj, method), null, args, named, method);

dgsendRepl(obj, typeArgs, method, args, [@undefined named]) =>
    callMethod(obj, replNameLookup(obj, method), typeArgs, args, named, method);

dindex(obj, index) => callMethod(obj, '_get', null, [index], null, '[]');

dsetindex(obj, index, value) =>
    callMethod(obj, '_set', null, [index, value], null, '[]=');

bool test(bool? obj) {
  if (obj == null) throw BooleanConversionAssertionError();
  return obj;
}

bool dtest(obj) {
  // Only throw an AssertionError in weak mode for compatibility. Strong mode
  // should throw a TypeError.
  if (obj is! bool)
    booleanConversionFailed(JS_GET_FLAG('SOUND_NULL_SAFETY') ? obj : test(obj));
  return obj;
}

Never booleanConversionFailed(obj) {
  var actual = typeName(getReifiedType(obj));
  throw TypeErrorImpl("type '$actual' is not a 'bool' in boolean expression");
}

asInt(obj) {
  // Note: null (and undefined) will fail this test.
  if (JS('!', 'Math.floor(#) != #', obj, obj)) {
    if (obj == null && !JS_GET_FLAG('SOUND_NULL_SAFETY')) {
      _nullWarnOnType(JS('', '#', int));
      return null;
    } else {
      castError(obj, JS('', '#', int));
    }
  }
  return obj;
}

asNullableInt(obj) => obj == null ? null : asInt(obj);

/// Checks for null or undefined and returns [x].
///
/// Throws [NoSuchMethodError] when it is null or undefined.
//
// TODO(jmesserly): inline this, either by generating it as a function into
// the module, or via some other pattern such as:
//
//     <expr> || nullErr()
//     (t0 = <expr>) != null ? t0 : nullErr()
@JSExportName('notNull')
_notNull(x) {
  if (x == null) throwNullValueError();
  return x;
}

/// Checks for null or undefined and returns [x].
///
/// Throws a [TypeError] when [x] is null or undefined (under sound null safety
/// mode) or emits a runtime warning (otherwise).
///
/// This is only used by the compiler when casting from nullable to non-nullable
/// variants of the same type.
nullCast(x, type) {
  if (x == null) {
    if (!JS_GET_FLAG('SOUND_NULL_SAFETY')) {
      _nullWarnOnType(type);
    } else {
      castError(x, type);
    }
  }
  return x;
}

/// Checks for null or undefined and returns [x].
///
/// Throws a [TypeError] when [x] is null or undefined.
///
/// This is only used by the compiler for the runtime null check operator `!`.
nullCheck(x) {
  if (x == null) throw TypeErrorImpl("Unexpected null value.");
  return x;
}

/// The global constant map table.
final constantMaps = JS<Object>('!', 'new Map()');

// TODO(leafp): This table gets quite large in apps.
// Keeping the paths is probably expensive.  It would probably
// be more space efficient to just use a direct hash table with
// an appropriately defined structural equality function.
Object _lookupNonTerminal(Object map, Object? key) {
  var result = JS('', '#.get(#)', map, key);
  if (result != null) return result;
  JS('', '#.set(#, # = new Map())', map, key, result);
  return result!;
}

Map<K, V> constMap<K, V>(JSArray elements) {
  var count = elements.length;
  var map = _lookupNonTerminal(constantMaps, count);
  for (var i = 0; i < count; i++) {
    map = _lookupNonTerminal(map, JS('', '#[#]', elements, i));
  }
  map = _lookupNonTerminal(map, K);
  Map<K, V>? result = JS('', '#.get(#)', map, V);
  if (result != null) return result;
  result = ImmutableMap<K, V>.from(elements);
  JS('', '#.set(#, #)', map, V, result);
  return result;
}

final constantSets = JS<Object>('!', 'new Map()');
var _immutableSetConstructor;

// We cannot invoke private class constructors directly in Dart.
Set<E> _createImmutableSet<E>(JSArray<E> elements) {
  _immutableSetConstructor ??=
      JS('', '#.#', getLibrary('dart:collection'), '_ImmutableSet\$');
  return JS('', 'new (#(#)).from(#)', _immutableSetConstructor, E, elements);
}

Set<E> constSet<E>(JSArray<E> elements) {
  var count = elements.length;
  var map = _lookupNonTerminal(constantSets, count);
  for (var i = 0; i < count; i++) {
    map = _lookupNonTerminal(map, JS('', '#[#]', elements, i));
  }
  Set<E>? result = JS('', '#.get(#)', map, E);
  if (result != null) return result;
  result = _createImmutableSet<E>(elements);
  JS('', '#.set(#, #)', map, E, result);
  return result;
}

final _value = JS('', 'Symbol("_value")');

///
/// Looks up a sequence of [keys] in [map], recursively, and
/// returns the result. If the value is not found, [valueFn] will be called to
/// add it. For example:
///
///     let map = new Map();
///     putIfAbsent(map, [1, 2, 'hi ', 'there '], () => 'world');
///
/// ... will create a Map with a structure like:
///
///     { 1: { 2: { 'hi ': { 'there ': 'world' } } } }
///
multiKeyPutIfAbsent(map, keys, valueFn) => JS('', '''(() => {
  for (let k of $keys) {
    let value = $map.get(k);
    if (!value) {
      // TODO(jmesserly): most of these maps are very small (e.g. 1 item),
      // so it may be worth optimizing for that.
      $map.set(k, value = new Map());
    }
    $map = value;
  }
  if ($map.has($_value)) return $map.get($_value);
  let value = $valueFn();
  $map.set($_value, value);
  return value;
})()''');

/// The global constant table.
/// This maps the number of names in the object (n)
/// to a path of length 2*n of maps indexed by the name and
/// and value of the field.  The final map is
/// indexed by runtime type, and contains the canonical
/// version of the object.
final constants = JS('!', 'new Map()');

///
/// Canonicalize a constant object.
///
/// Preconditions:
/// - `obj` is an objects or array, not a primitive.
/// - nested values of the object are themselves already canonicalized.
///
@JSExportName('const')
const_(obj) => JS('', '''(() => {
  let names = $getOwnNamesAndSymbols($obj);
  let count = names.length;
  // Index by count.  All of the paths through this map
  // will have 2*count length.
  let map = $_lookupNonTerminal($constants, count);
  // TODO(jmesserly): there's no guarantee in JS that names/symbols are
  // returned in the same order.
  //
  // We could probably get the same order if we're judicious about
  // initializing fields in a consistent order across all const constructors.
  // Alternatively we need a way to sort them to make consistent.
  //
  // Right now we use the (name,value) pairs in sequence, which prevents
  // an object with incorrect field values being returned, but won't
  // canonicalize correctly if key order is different.
  //
  // See issue https://github.com/dart-lang/sdk/issues/30876
  for (let i = 0; i < count; i++) {
    let name = names[i];
    map = $_lookupNonTerminal(map, name);
    map = $_lookupNonTerminal(map, $obj[name]);
  }
  // TODO(leafp): It may be the case that the reified type
  // is always one of the keys already used above?
  let type = $getReifiedType($obj);
  let value = map.get(type);
  if (value) return value;
  map.set(type, $obj);
  return $obj;
})()''');

/// The global constant list table.
/// This maps the number of elements in the list (n)
/// to a path of length n of maps indexed by the value
/// of the field.  The final map is indexed by the element
/// type and contains the canonical version of the list.
final constantLists = JS('', 'new Map()');

/// Canonicalize a constant list
constList(elements, elementType) => JS('', '''(() => {
  let count = $elements.length;
  let map = $_lookupNonTerminal($constantLists, count);
  for (let i = 0; i < count; i++) {
    map = $_lookupNonTerminal(map, elements[i]);
  }
  let value = map.get($elementType);
  if (value) return value;

  ${getGenericClassStatic<JSArray>()}($elementType).unmodifiable($elements);
  map.set($elementType, elements);
  return elements;
})()''');

constFn(x) => JS('', '() => x');

/// Gets the extension symbol given a member [name].
///
/// This is inlined by the compiler when used with a literal string.
extensionSymbol(String name) => JS('', 'dartx[#]', name);

/// Helper method for `operator ==` used when the receiver isn't statically
/// known to have one attached to its prototype (null or a JavaScript interop
/// value).
@notNull
bool equals(x, y) {
  // We handle `y == null` inside our generated operator methods, to keep this
  // function minimal.
  // This pattern resulted from performance testing; it found that dispatching
  // was the fastest solution, even for primitive types.
  if (JS<bool>('!', '# == null', x)) return JS<bool>('!', '# == null', y);
  var probe = JS('', '#[#]', x, extensionSymbol('_equals'));
  if (JS<bool>('!', '# !== void 0', probe)) {
    return JS('!', '#.call(#, #)', probe, x, y);
  }
  return JS<bool>('!', '# === #', x, y);
}

/// Helper method for `.hashCode` used when the receiver isn't statically known
/// to have one attached to its prototype (null or a JavaScript interop value).
@notNull
int hashCode(obj) {
  if (obj == null) return 0;
  var probe = JS('', '#[#]', obj, extensionSymbol('hashCode'));
  if (JS<bool>('!', '# !== void 0', probe)) return JS<int>('!', '#', probe);
  return identityHashCode(obj);
}

/// Helper method for `.toString` used when the receiver isn't statically known
/// to have one attached to its prototype (null or a JavaScript interop value).
@JSExportName('toString')
@notNull
String _toString(obj) {
  if (obj is String) return obj;
  if (obj == null) return 'null';
  // If this object has a Dart toString method, call it.
  var probe = JS('', '#[#]', obj, extensionSymbol('toString'));
  if (JS<bool>('!', '# !== void 0', probe)) {
    return JS('', '#.call(#)', probe, obj);
  }
  // Otherwise call the native JavaScript toString method.
  // This differs from dart2js to provide a more useful toString at development
  // time if one is available.
  // If obj does not have a native toString method this will throw but that
  // matches the behavior of dart2js and it would be misleading to make this
  // work at development time but allow it to fail in production.
  return JS('', '#.toString()', obj);
}

/// Helper method to provide a `.toString` tearoff used when the receiver isn't
/// statically known to have one attached to its prototype (null or a JavaScript
/// interop value).
@notNull
String Function() toStringTearoff(obj) {
  if (obj == null ||
      JS<bool>('!', '#[#] !== void 0', obj, extensionSymbol('toString'))) {
    // The bind helper can handle finding the toString method for null or Dart
    // Objects.
    return bind(obj, extensionSymbol('toString'), null);
  }
  // Otherwise bind the native JavaScript toString method.
  // This differs from dart2js to provide a more useful toString at development
  // time if one is available.
  // If obj does not have a native toString method this will throw but that
  // matches the behavior of dart2js and it would be misleading to make this
  // work at development time but allow it to fail in production.
  return bind(obj, 'toString', null);
}

/// Converts to a non-null [String], equivalent to
/// `dart.notNull(dart.toString(obj))`.
///
/// Only called from generated code for string interpolation.
@notNull
String str(obj) {
  if (obj is String) return obj;
  if (obj == null) return "null";
  var probe = JS('', '#[#]', obj, extensionSymbol('toString'));
  // TODO(40614): Declare `result` as String once non-nullability is sound.
  final result = JS<bool>('!', '# !== void 0', probe)
      // If this object has a Dart toString method, call it.
      ? JS('', '#.call(#)', probe, obj)
      // Otherwise call the native JavaScript toString method.
      // This differs from dart2js to provide a more useful toString at
      // development time if one is available.
      // If obj does not have a native toString method this will throw but that
      // matches the behavior of dart2js and it would be misleading to make this
      // work at development time but allow it to fail in production.
      : JS('', '#.toString()', obj);
  if (result is String) return result;
  // Since Dart 2.0, `null` is the only other option.
  throw ArgumentError.value(obj, 'object', "toString method returned 'null'");
}

/// An version of [str] that is optimized for values that we know have the Dart
/// Core Object members on their prototype chain somewhere so it is safe to
/// immediately call `.toString()` directly.
///
/// Converts to a non-null [String], equivalent to
/// `dart.notNull(dart.toString(obj))`.
///
/// Only called from generated code for string interpolation.
@notNull
String strSafe(obj) {
  // TODO(40614): Declare `result` as String once non-nullability is sound.
  final result = JS('', '#[#]()', obj, extensionSymbol('toString'));
  if (result is String) return result;
  // Since Dart 2.0, `null` is the only other option.
  throw ArgumentError.value(obj, 'object', "toString method returned 'null'");
}

/// Helper method for `.noSuchMethod` used when the receiver isn't statically
/// known to have one attached to its prototype (null or a JavaScript interop
/// value).
// TODO(jmesserly): is the argument type verified statically?
@notNull
noSuchMethod(obj, Invocation invocation) {
  if (obj == null ||
      JS<bool>('!', '#[#] == null', obj, extensionSymbol('noSuchMethod'))) {
    defaultNoSuchMethod(obj, invocation);
  }
  return JS('', '#[#](#)', obj, extensionSymbol('noSuchMethod'), invocation);
}

/// Helper method to provide a `.noSuchMethod` tearoff used when the receiver
/// isn't statically known to have one attached to its prototype (null or a
/// JavaScript interop value).
@notNull
dynamic Function(Invocation) noSuchMethodTearoff(obj) {
  if (obj == null ||
      JS<bool>('!', '#[#] !== void 0', obj, extensionSymbol('noSuchMethod'))) {
    // The bind helper can handle finding the toString method for null or Dart
    // Objects.
    return bind(obj, extensionSymbol('noSuchMethod'), null);
  }
  // Otherwise, manually pass the Dart Core Object noSuchMethod to the bind
  // helper.
  return bind(
      obj,
      extensionSymbol('noSuchMethod'),
      JS('!', '#.prototype[#]', JS_CLASS_REF(Object),
          extensionSymbol('noSuchMethod')));
}

/// The default implementation of `noSuchMethod` to match `Object.noSuchMethod`.
Never defaultNoSuchMethod(obj, Invocation i) {
  throw NoSuchMethodError.withInvocation(obj, i);
}

/// Helper method to provide a `.toString` tearoff used when the receiver isn't
/// statically known to have one attached to its prototype (null or a JavaScript
/// interop value).
// TODO(nshahan) Replace with rti.getRuntimeType() when classes representing
// native types don't have to "pretend" to be Dart classes. Ex:
// JSNumber -> int or double
// JSArray<E> -> List<E>
// NativeFloat32List -> Float32List
@notNull
Type runtimeType(obj) {
  if (obj == null) return Null;
  var probe = JS<Type?>('', '#[#]', obj, extensionSymbol('runtimeType'));
  if (JS<bool>('!', '# !== void 0', probe)) return JS<Type>('!', '#', probe);
  return rti.createRuntimeType(JS<rti.Rti>('!', '#', getReifiedType(obj)));
}

final identityHashCode_ = JS<Object>('!', 'Symbol("_identityHashCode")');

/// Adapts a Dart `get iterator` into a JS `[Symbol.iterator]`.
// TODO(jmesserly): instead of an adaptor, we could compile Dart iterators
// natively implementing the JS iterator protocol. This would allow us to
// optimize them a bit.
final JsIterator = JS('', '''
  class JsIterator {
    constructor(dartIterator) {
      this.dartIterator = dartIterator;
    }
    next() {
      let i = this.dartIterator;
      let done = !i.moveNext();
      return { done: done, value: done ? void 0 : i.current };
    }
  }
''');

_canonicalMember(obj, name) {
  // Private names are symbols and are already canonical.
  if (JS('!', 'typeof # === "symbol"', name)) return name;

  if (obj != null && JS<bool>('!', '#[#] != null', obj, _extensionType)) {
    return JS('', 'dartx.#', name);
  }

  // Check for certain names that we can't use in JS
  if (JS('!', '# == "constructor" || # == "prototype"', name, name)) {
    JS('', '# = "+" + #', name, name);
  }
  return name;
}

@notNull
bool _ddcDeferredLoading = false;

/// Sets the runtime mode to perform deferred loading (instead of just runtime
/// correctness checks on loaded libraries).
///
/// This is only supported in the DDC module system.
void ddcDeferredLoading(bool enable) {
  _ddcDeferredLoading = enable;
}

@notNull
bool _ddcNewLoadLibraryTiming = false;

/// Makes DDC return non-sync Futures from `loadLibrary` calls.
///
/// This makes DDC's `loadLibrary` semantics consistent with Dart2JS's.
/// Remove this when we switch to the new semantics by default.
///
/// /// This is only supported in the DDC module system.
void ddcNewLoadLibraryTiming(bool enable) {
  _ddcNewLoadLibraryTiming = enable;
}

/// A map from libraries to a set of import prefixes that have been loaded.
///
/// Used to validate deferred library conventions.
final deferredImports = JS<Object>('!', 'new Map()');

/// Loads the element [importPrefix] in the module [targetModule] from the
/// context of the library [libraryUri].
///
/// Will load any modules required by [targetModule] as a side effect.
/// Only supported in the DDC module system.
Future<void> loadLibrary(@notNull String libraryUri,
    @notNull String importPrefix, @notNull String targetModule) {
  if (!_ddcDeferredLoading) {
    var result = JS('', '#.get(#)', deferredImports, libraryUri);
    if (JS<bool>('!', '# === void 0', result)) {
      JS('', '#.set(#, # = new Set())', deferredImports, libraryUri, result);
    }
    JS('', '#.add(#)', result, importPrefix);
    return _ddcNewLoadLibraryTiming ? Future(() {}) : Future.value();
  } else {
    int currentHotRestartIteration = hotRestartIteration;
    var loadId = '$libraryUri::$importPrefix';
    if (targetModule.isEmpty) {
      throw ArgumentError('Empty module passed for deferred load: $loadId.');
    }
    if (JS<bool>('!', r'#.deferred_loader.isLoaded(#)', global_, loadId)) {
      return Future.value();
    }
    var completer = Completer();

    // Don't mark a load ID as loaded across hot restart boundaries.
    void internalComplete(void Function()? beforeComplete) {
      if (hotRestartIteration == currentHotRestartIteration &&
          beforeComplete != null) {
        beforeComplete();
      }
      completer.complete();
    }

    JS(
        '',
        r'#.deferred_loader.loadDeferred(#, #, #, #)',
        global_,
        loadId,
        targetModule,
        internalComplete,
        (error) => completer.completeError(error));
    return completer.future;
  }
}

void checkDeferredIsLoaded(
    @notNull String libraryUri, @notNull String importPrefix) {
  if (!_ddcDeferredLoading) {
    var loaded = JS('', '#.get(#)', deferredImports, libraryUri);
    if (JS<bool>('!', '# === void 0', loaded) ||
        JS<bool>('!', '!#.has(#)', loaded, importPrefix)) {
      throwDeferredIsLoadedError(libraryUri, importPrefix);
    }
  } else {
    var loadId = '$libraryUri::$importPrefix';
    var loaded =
        JS<bool>('!', r'#.deferred_loader.loadIds.has(#)', global_, loadId);
    if (!loaded) throwDeferredIsLoadedError(libraryUri, importPrefix);
  }
}

/// Defines lazy statics.
///
/// TODO: Remove useOldSemantics when non-null-safe late static field behavior is
/// deprecated.
void defineLazy(to, from, bool useOldSemantics) {
  for (var name in getOwnNamesAndSymbols(from)) {
    if (useOldSemantics) {
      defineLazyFieldOld(to, name, getOwnPropertyDescriptor(from, name));
    } else {
      defineLazyField(to, name, getOwnPropertyDescriptor(from, name));
    }
  }
}

/// Defines a lazy static field.
/// After initial get or set, it will replace itself with a value property.
// TODO(jmesserly): reusing descriptor objects has been shown to improve
// performance in other projects (e.g. webcomponents.js ShadowDOM polyfill).
defineLazyField(to, name, desc) => JS('', '''(() => {
  const initializer = $desc.get;
  const final = $desc.set == null;
  // Tracks if the initializer has been called.
  let initialized = false;
  let init = initializer;
  let value = null;
  // Tracks if these local variables have been saved so they can be restored
  // after a hot restart.
  let savedLocals = false;
  $desc.get = function() {
    if (init == null) return value;
    if (final && initialized) $throwLateInitializationError($name);
    if (!savedLocals) {
      // Record the field on first execution so we can reset it later if
      // needed (hot restart).
      $resetFields.push(() => {
        init = initializer;
        value = null;
        savedLocals = false;
        initialized = false;
      });
      savedLocals = true;
    }
    // Must set before calling init in case it is recursive.
    initialized = true;
    try {
      value = init();
    } catch (e) {
      // Reset to false so the initializer can be executed again if the
      // exception was caught.
      initialized = false;
      throw e;
    }
    init = null;
    return value;
  };
  $desc.configurable = true;
  let setter = $desc.set;
  if (setter != null) {
    $desc.set = function(x) {
      if (!savedLocals) {
        $resetFields.push(() => {
          init = initializer;
          value = null;
          savedLocals = false;
          initialized = false;
        });
        savedLocals = true;
      }
      init = null;
      value = x;
      setter(x);
    };
  }
  return ${defineProperty(to, name, desc)};
})()''');

/// Defines a lazy static field with pre-null-safety semantics.
defineLazyFieldOld(to, name, desc) => JS('', '''(() => {
  const initializer = $desc.get;
  let init = initializer;
  let value = null;
  // Tracks if these local variables have been saved so they can be restored
  // after a hot restart.
  let savedLocals = false;
  $desc.get = function() {
    if (init == null) return value;
    let f = init;
    init = $throwCyclicInitializationError;
    if (f === init) f($name); // throw cycle error

    // On the first (non-cyclic) execution, record the field so we can reset it
    // later if needed (hot restart).
    if (!savedLocals) {
      $resetFields.push(() => {
        init = initializer;
        value = null;
        savedLocals = false;
      });
      savedLocals = true;
    }

    // Try to evaluate the field, using try+catch to ensure we implement the
    // correct Dart error semantics.
    try {
      value = f();
      init = null;
      return value;
    } catch (e) {
      init = null;
      value = null;
      throw e;
    }
  };
  $desc.configurable = true;
  let setter = $desc.set;
  if (setter != null) {
    $desc.set = function(x) {
      if (!savedLocals) {
        $resetFields.push(() => {
          init = initializer;
          value = null;
          savedLocals = false;
        });
        savedLocals = true;
      }
      init = null;
      value = x;
      setter(x);
    };
  }
  return ${defineProperty(to, name, desc)};
})()''');

/// Checks for null or undefined and returns [val].
///
/// Throws a [TypeError] when [val] is null or undefined and the option for
/// these checks has been enabled by [jsInteropNonNullAsserts].
///
/// Called from generated code when the compiler detects a non-static JavaScript
/// interop API access that is typed to be non-nullable.
Object? jsInteropNullCheck(Object? val) {
  if (_jsInteropNonNullAsserts && val == null) {
    throw TypeErrorImpl('Unexpected null value encountered from a '
        'JavaScript Interop API typed as non-nullable.');
  }
  return val;
}

checkNativeNonNull(dynamic variable) {
  if (_nativeNonNullAsserts && variable == null) {
    // TODO(srujzs): Add link/patch for instructions to disable in internal
    // build systems.
    throw TypeErrorImpl('''
      Unexpected null value encountered in Dart web platform libraries.
      This may be a bug in the Dart SDK APIs. If you would like to report a bug
      or disable this error, you can use the following instructions:
      https://github.com/dart-lang/sdk/tree/master/sdk/lib/html/doc/NATIVE_NULL_ASSERTIONS.md
    ''');
  }
  return variable;
}
