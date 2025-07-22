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

  InvocationImpl(
    memberName,
    List<Object?> positionalArguments, {
    namedArguments,
    List typeArguments = const [],
    this.isMethod = false,
    this.isGetter = false,
    this.isSetter = false,
    this.failureMessage = 'method not found',
  }) : memberName =
           isSetter ? _setterSymbol(memberName) : _dartSymbol(memberName),
       positionalArguments = List.unmodifiable(positionalArguments),
       namedArguments = _namedArgsToSymbols(namedArguments),
       typeArguments = List.unmodifiable(
         typeArguments.map(
           (t) => rti.createRuntimeType(JS<rti.Rti>('!', '#', t)),
         ),
       );

  static Map<Symbol, dynamic> _namedArgsToSymbols(namedArgs) {
    if (namedArgs == null) return const {};
    return Map.unmodifiable(
      Map.fromIterable(
        getOwnPropertyNames(namedArgs),
        key: _dartSymbol,
        value: (k) => JS('', '#[#]', namedArgs, k),
      ),
    );
  }
}

/// Encodes [property] as a valid JS member name.
String stringNameForProperty(property) {
  if (JS<bool>('', 'typeof # === "symbol"', property)) {
    var name = _toSymbolName(property);
    // Remove extension method prefixes if necessary.
    if (JS<bool>('', '#.startsWith("dartx.")', name)) {
      return JS<String>('', '#.substring(6, #.length)', name, name);
    }
    return name;
  }
  if (JS<bool>('', 'typeof # === "string"', property)) {
    return '$property';
  }
  throw Exception('Unable to construct a valid JS string name for $property.');
}

/// Used for canonicalizing tearoffs via a two-way lookup of enclosing method
/// target label and member name.
///
/// TODO(markzipan): We can't use a JS WeakMap to key by method context because
/// we sometimes wrap library objects in lazily-loaded proxy objects. We can
/// avoid memory leaks if we handle proxy libraries natively.
final tearoffCache = JS<Object>('!', 'new Map()');

/// Constructs a static tearoff, on `context[property]`.
///
/// [immediateMethodTargetLabel] uniquely identifies the class from which this
/// method is torn off. Static tearoffs provide this at tearoff time.
///
/// Static tearoffs are canonicalized at runtime via the `tearoffCache`. We
/// avoid canonicalizing based on [context] to avoid comparing proxy-wrapped
/// top level library objects.
staticTearoff(context, String immediateMethodTargetLabel, property) {
  if (context == null) context = jsNull;
  var propertyMap = _lookupNonTerminal(
    tearoffCache,
    immediateMethodTargetLabel,
  );
  var canonicalizedTearoff = JS<Object?>('', '#.get(#)', propertyMap, property);
  if (canonicalizedTearoff != null) return canonicalizedTearoff;
  var tear = tearoff(context, immediateMethodTargetLabel, property);
  JS('', '#.set(#, #)', propertyMap, property, tear);
  JS('', '#._isStaticTearoff = true', tear);
  return tear;
}

/// Constructs a new tearoff, on `context[property]`. Tearoffs are represented
/// as a closure that resolves its underlying member late.
///
/// [immediateMethodTargetOrLabel] is either 'null', a method label string, or
/// an object that resolves to a method label (via [getMethodImmediateTarget]).
/// A method label uniquely identifies the class from which this  method is
/// torn off. Static tearoffs pass in a label when the tearoff is created. If
/// null (such as in dynamic/instance tearoffs), we resolve the label via this
/// tearoff's method signature.
///
/// Note: We do not canonicalize instance tearoffs to be consistent with
/// Dart2JS, but we should update this if the spec changes. See #3612.
@notNull
Object tearoff(
  Object? context,
  Object? immediateMethodTargetOrLabel,
  @notNull Object property,
) {
  if (context == null) context = jsNull;
  property = _canonicalMember(context, property);
  var tear = JS<Object>('!', '(...args) => #[#](...args)', context, property);
  var rtiName = JS_GET_NAME(JsGetName.SIGNATURE_NAME);
  defineAccessor(
    tear,
    rtiName,
    get: () {
      var existingRti = JS<Object?>('', '#[#][#]', context, property, rtiName);
      return existingRti ?? getMethodType(context, property);
    },
    configurable: true,
    enumerable: false,
  );
  defineAccessor(
    tear,
    '_boundMethodTarget',
    get: () {
      if (JS<bool>('', '# == null', immediateMethodTargetOrLabel)) {
        return getMethodImmediateTarget(context, null, property);
      }
      if (JS<bool>('', 'typeof # == "string"', immediateMethodTargetOrLabel)) {
        return JS<String>('!', '#', immediateMethodTargetOrLabel);
      }
      return getMethodImmediateTarget(
        context,
        immediateMethodTargetOrLabel,
        property,
      );
    },
    configurable: true,
    enumerable: false,
  );
  JS('', '#._boundObject = #', tear, context);
  return _finishTearoff(tear, context, property);
}

/// Constructs a tearoff on `super.property` from [context].
///
/// [context] is the object whose super member is being torn off.
/// [superclass] is the class definition at the point in [context]'s hierarchy
/// where [property] should be torn off.
/// [property] is the property (string name or symbol) used to access the
/// member being torn off.
@notNull
Object superTearoff(
  @notNull Object context,
  @notNull Object superclass,
  @notNull Object property,
) {
  var superContext = JS<Object>('!', '#.prototype', superclass);
  property = _canonicalMember(superContext, property);
  var tear = JS<Object>(
    '!',
    '(...args) => #[#].bind(#)(...args)',
    superContext,
    property,
    context,
  );
  var rtiName = JS_GET_NAME(JsGetName.SIGNATURE_NAME);
  defineAccessor(
    tear,
    rtiName,
    get: () {
      var existingRti = JS<Object?>('', '#[#][#]', context, property, rtiName);
      return existingRti ?? getMethodType(context, property);
    },
    configurable: true,
    enumerable: false,
  );
  defineAccessor(
    tear,
    '_boundMethodTarget',
    get: () {
      return getMethodImmediateTarget(superContext, superclass, property);
    },
    configurable: true,
    enumerable: false,
  );
  JS('', '#._boundObject = #', tear, context);
  return _finishTearoff(tear, superContext, property);
}

/// Appends hidden members to a tearoff required for correctness.
///
/// Does not append '_boundMethodTarget' and '_boundObject', as these have
/// special handling logic.
@notNull
Object _finishTearoff(
  @notNull Object tear,
  Object? context,
  @notNull Object property,
) {
  // Type-resolving members on tearoffs must be resolved late. Static tearoffs
  // are tagged with their RTIs ahead of time. Runtime/instance tearoffs must
  // access them through `getMethodType` and `getMethodDefaultTypeArgs`.
  defineAccessor(
    tear,
    '_defaultTypeArgs',
    get: () {
      var existingDefaultTypeArgs = JS<Object?>(
        '',
        '#[#][#]',
        context,
        property,
        '_defaultTypeArgs',
      );
      return existingDefaultTypeArgs ??
          getMethodDefaultTypeArgs(context, property);
    },
    configurable: true,
    enumerable: false,
  );
  defineAccessor(
    tear,
    '_boundMethod',
    get: () {
      return JS<Object?>('', '#[#]', context, property);
    },
    configurable: true,
    enumerable: false,
  );
  JS('', '#._boundName = #', tear, stringNameForProperty(property));
  return tear;
}

/// Instantiate a generic method.
///
/// We need to apply the type arguments both to the function, as well as its
/// associated function type.
gbind(f, @rest List<Object> typeArgs) {
  Object fnType = JS('!', '#[#]', f, JS_GET_NAME(JsGetName.SIGNATURE_NAME));
  var typeArgsAsJSArray = JS<JSArray<Object>>('!', '#', typeArgs);
  var instantiationBinding = rti.bindingRtiFromList(typeArgsAsJSArray);
  var instantiatedType = rti.instantiatedGenericFunctionType(
    JS<rti.Rti>('!', '#', fnType),
    instantiationBinding,
  );
  // Create a JS wrapper function that will also pass the type arguments.
  var result = JS(
    '',
    '(...args) => #.apply(null, #.concat(args))',
    f,
    typeArgs,
  );
  // Tag the wrapper with the original function to be used for equality
  // checks.
  JS('', '#["_originalFn"] = #', result, f);
  JS('', '#["_typeArgs"] = #', result, constList<Object>(typeArgsAsJSArray));

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
    var typeSigHolder = getTypeSignatureContainer(obj);

    if (hasField(typeSigHolder, f) || hasGetter(typeSigHolder, f))
      return JS('', '#[#]', obj, f);
    if (hasMethod(typeSigHolder, f)) return tearoff(obj, null, f);

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

dputRepl(obj, field, value) => dput(obj, replNameLookup(obj, field), value);

dput(obj, field, value) {
  var f = _canonicalMember(obj, field);
  trackCall(obj);
  if (f != null) {
    var setterType = getSetterType(obj, f);
    if (setterType != null) {
      return JS(
        '',
        '#[#] = #.#(#)',
        obj,
        f,
        setterType,
        JS_GET_NAME(JsGetName.RTI_FIELD_AS),
        value,
      );
    }
    // Always allow for JS interop objects.
    if (isJsInterop(obj)) return JS('', '#[#] = #', obj, f, value);
  }
  noSuchMethod(
    obj,
    InvocationImpl(field, JS('', '[#]', value), isSetter: true),
  );
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
    var expected =
        requiredCount == maxPositionalCount
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
      if (!JS<bool>(
        '!',
        '#.hasOwnProperty(#) || #.hasOwnProperty(#)',
        requiredNamed,
        name,
        optionalNamed,
        name,
      )) {
        return "Dynamic call with unexpected named argument '$name'.";
      }
    }
  }
  // Verify that all required named parameters are provided an argument.
  Iterable requiredNames = getOwnPropertyNames(requiredNamed);
  if (JS<int>('!', '#.length', requiredNames) > 0) {
    var missingRequired =
        namedActuals == null
            ? requiredNames
            : requiredNames.where(
              (name) =>
                  !JS<bool>('!', '#.hasOwnProperty(#)', namedActuals, name),
            );
    if (missingRequired.isNotEmpty) {
      var argNames = JS<String>('!', '#.join(", ")', missingRequired);
      var error =
          "Dynamic call with missing required named arguments: "
          "$argNames.";
      return error;
    }
  }
  // Now that we know the signature matches, we can perform type checks.
  for (var i = 0; i < requiredCount; ++i) {
    var requiredRti = JS<rti.Rti>('!', '#[#]', requiredPositional, i);
    var passedValue = JS('', '#[#]', actuals, i);
    JS(
      '',
      '#.#(#)',
      requiredRti,
      JS_GET_NAME(JsGetName.RTI_FIELD_AS),
      passedValue,
    );
  }
  for (var i = 0; i < extras; ++i) {
    var optionalRti = JS<rti.Rti>('!', '#[#]', optionalPositional, i);
    var passedValue = JS('', '#[#]', actuals, i + requiredCount);
    JS(
      '',
      '#.#(#)',
      optionalRti,
      JS_GET_NAME(JsGetName.RTI_FIELD_AS),
      passedValue,
    );
  }
  if (names != null) {
    for (var name in names) {
      var namedRti = JS<rti.Rti>(
        '!',
        '#[#] || #[#]',
        requiredNamed,
        name,
        optionalNamed,
        name,
      );
      var passedValue = JS('', '#[#]', namedActuals, name);
      JS(
        '',
        '#.#(#)',
        namedRti,
        JS_GET_NAME(JsGetName.RTI_FIELD_AS),
        passedValue,
      );
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
      ? JS(
        'Symbol',
        '#(new #.new(#, #))',
        const_,
        JS_CLASS_REF(PrivateSymbol),
        _toSymbolName(name),
        name,
      )
      : JS(
        'Symbol',
        '#(new #.new(#))',
        const_,
        JS_CLASS_REF(internal.Symbol),
        _toDisplayName(name),
      );
}

Symbol _setterSymbol(name) {
  return (JS<bool>('!', 'typeof # === "symbol"', name))
      ? JS(
        'Symbol',
        '#(new #.new(# + "=", #))',
        const_,
        JS_CLASS_REF(PrivateSymbol),
        _toSymbolName(name),
        name,
      )
      : JS(
        'Symbol',
        '#(new #.new(# + "="))',
        const_,
        JS_CLASS_REF(internal.Symbol),
        _toDisplayName(name),
      );
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
      InvocationImpl(
        displayName,
        JS<List<Object?>>('!', '#', args),
        namedArguments: named,
        // Repeated the default value here in JS to preserve the historic
        // behavior.
        typeArguments: JS('!', '# || []', typeArgs),
        isMethod: true,
        failureMessage: errorMessage,
      ),
    );
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
      // Use [getMethodType] to determine if 'call' is allowed to be dynamically
      // torn off on this object.
      f = getMethodType(f, 'call') == null ? null : tearoff(f, null, 'call');
      ftype = null;
      displayName = 'call';
    }
    if (f == null ||
        JS<bool>('', '#._boundObject[#._boundName] == null', f, f)) {
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
      throwTypeError(
        'call to JS object `' +
            // Not a String but historically relying on the default JavaScript
            // behavior.
            JS<String>('!', '#', obj) +
            '` with type arguments <' +
            // Not a String but historically relying on the default JavaScript
            // behavior.
            JS<String>('!', '#', typeArgs) +
            '> is not supported.',
      );
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
      return callNSM(
        'Dynamic call with incorrect number of type arguments. '
        'Expected: $typeParameterCount Actual: $typeArgCount',
      );
    } else {
      // Check the provided type arguments against the instantiated bounds.
      for (var i = 0; i < typeParameterCount; i++) {
        var bound = JS<rti.Rti>('!', '#[#]', typeParameterBounds, i);
        var typeArg = JS<rti.Rti>('!', '#[#]', typeArgs, i);
        if (bound != typeArg && !rti.isTopType(bound)) {
          var instantiatedBound = rti.substitute(bound, typeArgs);
          var validSubtype = rti.isSubtype(
            JS_EMBEDDED_GLOBAL('', RTI_UNIVERSE),
            typeArg,
            instantiatedBound,
          );
          if (!validSubtype) {
            throwTypeError(
              "The type '${rti.rtiToString(typeArg)}' "
              "is not a subtype of the type variable bound "
              "'${rti.rtiToString(instantiatedBound)}' "
              "of type variable 'T${i + 1}' "
              "in '${rti.rtiToString(ftype)}'.",
            );
          }
        }
      }
    }
    var instantiationBinding = rti.bindingRtiFromList(
      JS<JSArray>('!', '#', typeArgs),
    );
    ftype = rti.instantiatedGenericFunctionType(
      JS<rti.Rti>('!', '#', ftype),
      instantiationBinding,
    );
  } else if (typeArgs != null) {
    return callNSM(
      'Dynamic call with unexpected type arguments. '
      'Expected: 0 Actual: ${JS<int>('!', '#.length', typeArgs)}',
    );
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
    null,
  );
  if (errorMessage != null) {
    return noSuchMethod(
      f,
      InvocationImpl(
        JS('', '#.name', f),
        args,
        isMethod: true,
        failureMessage: errorMessage,
      ),
    );
  }
  return null;
}

dcall(f, args, [named]) => _checkAndCall(
  f,
  null,
  JS('', 'void 0'),
  null,
  args,
  named,
  JS('', '#._boundName || #.name', f, f),
);

dgcall(f, typeArgs, args, [named]) => _checkAndCall(
  f,
  null,
  JS('', 'void 0'),
  typeArgs,
  args,
  named,
  JS('', "#._boundName || #.name || 'call'", f, f),
);

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
  var ftype = getMethodType(obj, symbol);
  if (ftype != null && rti.isGenericFunctionType(ftype) && typeArgs == null) {
    // No type arguments were provided, use the default values in this call.
    typeArgs = getMethodDefaultTypeArgs(obj, symbol);
  }
  // No such method if dart object and ftype is missing.
  return _checkAndCall(f, ftype, obj, typeArgs, args, named, displayName);
}

dsend(obj, method, args, [named]) =>
    callMethod(obj, method, null, args, named, method);

dgsend(obj, typeArgs, method, args, [named]) =>
    callMethod(obj, method, typeArgs, args, named, method);

dsendRepl(obj, method, args, [named]) =>
    callMethod(obj, replNameLookup(obj, method), null, args, named, method);

dgsendRepl(obj, typeArgs, method, args, [named]) =>
    callMethod(obj, replNameLookup(obj, method), typeArgs, args, named, method);

dindex(obj, index) => callMethod(obj, '_get', null, [index], null, '[]');

dsetindex(obj, index, value) =>
    callMethod(obj, '_set', null, [index, value], null, '[]=');

bool test(bool? obj) {
  if (obj == null) throw BooleanConversionAssertionError();
  return obj;
}

bool dtest(obj) {
  if (obj is! bool) {
    var actual = typeName(getReifiedType(obj));
    throw TypeErrorImpl("type '$actual' is not a 'bool' in boolean expression");
  }
  return obj;
}

asInt(obj) {
  // Note: null (and undefined) will fail this test.
  if (JS('!', 'Math.floor(#) != #', obj, obj)) {
    castError(obj, TYPE_REF<int>());
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
/// Throws a [TypeError] when [x] is null or undefined.
///
/// This is only used by the compiler when casting from nullable to non-nullable
/// variants of the same type.
nullCast(x, type) {
  if (x == null) {
    castError(x, type);
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

/// The global constant list table.
/// This maps the number of elements in the list (n)
/// to a path of length n of maps indexed by the value
/// of the field.  The final map is indexed by the element
/// type and contains the canonical version of the list.
final constantLists = JS<Object>('!', 'new Map()');

/// Canonicalize a constant list
List<E> constList<E>(JSArray elements) {
  var count = elements.length;
  var map = _lookupNonTerminal(constantLists, count);
  for (var i = 0; i <= count; i++) {
    map = _lookupNonTerminal(map, JS('', '#[#]', elements, i));
  }
  List<E>? result = JS('', '#.get(#)', map, E);
  if (result != null) return result;
  result = JSArray.unmodifiable(elements);
  JS('', '#.set(#, #)', map, E, result);
  return result;
}

/// The global constant map table.
final constantMaps = JS<Object>('!', 'new Map()');

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

Set<E> constSet<E>(JSArray<E> elements) {
  var count = elements.length;
  var map = _lookupNonTerminal(constantSets, count);
  for (var i = 0; i < count; i++) {
    map = _lookupNonTerminal(map, JS('', '#[#]', elements, i));
  }
  Set<E>? result = JS('', '#.get(#)', map, E);
  if (result != null) return result;
  result = ImmutableSet<E>.from(elements);
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
Object toStringTearoff(obj) {
  if (obj == null) obj = jsNull;
  if (JS<bool>('!', '#[#] !== void 0', obj, extensionSymbol('toString'))) {
    // The bind helper can handle finding the toString method for null or Dart
    // Objects.
    return tearoff(obj, null, extensionSymbol('toString'));
  }
  // Otherwise bind the native JavaScript toString method.
  // This differs from dart2js to provide a more useful toString at development
  // time if one is available.
  // If obj does not have a native toString method this will throw but that
  // matches the behavior of dart2js and it would be misleading to make this
  // work at development time but allow it to fail in production.
  return tearoff(obj, null, 'toString');
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
  if (JS<bool>('!', '# !== void 0', probe)) {
    // If this object has a Dart toString method, call it.
    return JS<String>('', '#.call(#)', probe, obj);
  }
  // Otherwise call the native JavaScript toString method.
  // This differs from dart2js to provide a more useful toString at
  // development time if one is available.
  // If obj does not have a native toString method this will throw but that
  // matches the behavior of dart2js and it would be misleading to make this
  // work at development time but allow it to fail in production.
  var result = JS('', '#.toString()', obj);

  if (result is String) return result;
  // It is possible that it doesn't throw but also doesn't return a String so we
  // the result must be checked.
  throw ArgumentError.value(
    obj,
    'obj',
    'The JavaScript `.toString()` method did not return a String',
  );
}

/// An version of [str] that is optimized for values that we know have the Dart
/// Core Object members on their prototype chain somewhere so it is safe to
/// immediately call `.toString()` directly.
///
/// Only called from generated code for string interpolation.
@notNull
String strSafe(obj) {
  return JS('', '#[#]()', obj, extensionSymbol('toString'));
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
Object noSuchMethodTearoff(context) {
  if (context == null) context = jsNull;
  if (JS<bool>(
    '!',
    '#[#] !== void 0',
    context,
    extensionSymbol('noSuchMethod'),
  )) {
    // The bind helper can handle finding the noSuchMethod method for null or
    // Dart Objects.
    return tearoff(context, null, extensionSymbol('noSuchMethod'));
  }
  // Otherwise, tear off the Dart Core Object's noSuchMethod.
  var tear = tearoff(
    JS_CLASS_REF(Object),
    null,
    extensionSymbol('noSuchMethod'),
  );
  // Update the bound object for equality correctness.
  JS('', '#._boundObject = #', tear, context);
  return tear;
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
  if (JS<bool>('!', 'typeof # === "symbol"', name)) return name;

  if (obj != null) {
    // 'toString', 'call', and 'noSuchMethod' use their extension symbol when
    // available but default to their string names.
    if (JS<bool>(
          '!',
          '# === "toString" || # === "noSuchMethod" || # === "call"',
          name,
          name,
          name,
        ) &&
        JS<bool>('!', '#[#] != null', obj, extensionSymbol(name))) {
      return extensionSymbol(name) ?? name;
    }
    if (JS<bool>('!', '#[#] != null', obj, _extensionType)) {
      return extensionSymbol(name);
    }
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
Future<void> loadLibrary(
  @notNull String libraryUri,
  @notNull String importPrefix,
  @notNull String targetModule,
) {
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
      (error) => completer.completeError(error),
    );
    return completer.future;
  }
}

void checkDeferredIsLoaded(
  @notNull String libraryUri,
  @notNull String importPrefix,
) {
  if (!_ddcDeferredLoading) {
    var loaded = JS('', '#.get(#)', deferredImports, libraryUri);
    if (JS<bool>('!', '# === void 0', loaded) ||
        JS<bool>('!', '!#.has(#)', loaded, importPrefix)) {
      throwDeferredIsLoadedError(libraryUri, importPrefix);
    }
  } else {
    var loadId = '$libraryUri::$importPrefix';
    var loaded = JS<bool>(
      '!',
      r'#.deferred_loader.loadIds.has(#)',
      global_,
      loadId,
    );
    if (!loaded) throwDeferredIsLoadedError(libraryUri, importPrefix);
  }
}

/// Provides the experimental functionality for dynamic modules.
Object? dynamicModuleLoader;
Object? dynamicEntrypointHelper;
void setDynamicModuleLoader(Object loaderFunction, Object entrypointHelper) {
  if (dynamicModuleLoader != null) {
    throw StateError('Dynamic module loader already configured.');
  }
  dynamicModuleLoader = loaderFunction;
  dynamicEntrypointHelper = entrypointHelper;
}

/// Defines lazy statics.
void defineLazy(to, from) {
  for (var name in getOwnNamesAndSymbols(from)) {
    defineLazyField(to, name, getOwnPropertyDescriptor(from, name));
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

/// Checks for null or undefined and returns [val].
///
/// Throws a [TypeError] when [val] is null or undefined and the option for
/// these checks has been enabled by [jsInteropNonNullAsserts].
///
/// Called from generated code when the compiler detects a non-static JavaScript
/// interop API access that is typed to be non-nullable.
Object? jsInteropNullCheck(Object? val) {
  if (_jsInteropNonNullAsserts && val == null) {
    throw TypeErrorImpl(
      'Unexpected null value encountered from a '
      'JavaScript Interop API typed as non-nullable.',
    );
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

/// Returns whether or not [property] holds state that should be conserved
/// across hot reloads.
///
/// These are generated for all fields after a hot reload.
bool isStateBearingSymbol(property) => JS<bool>(
  '!',
  'typeof # == "symbol" && #.description.startsWith("_#v_")',
  property,
  property,
);

/// Attempts to assign class [classDeclaration] as [classIdentifier] on
/// [library].
///
/// During a hot reload, should [library.classIdentifier] already exist, this
/// copies the members of [classDeclaration] and its prototype's properties to
/// the existing class. Existing members not prefixed by a special identifier
/// are replaced (see [isStateBearingSymbol]).
declareClass(library, classIdentifier, classDeclaration) {
  var originalClass = JS<Object>('!', '#.#', library, classIdentifier);
  if (JS<bool>('!', '# === void 0', originalClass)) {
    JS('', '#.# = #', library, classIdentifier, classDeclaration);
  } else {
    var newClassProto = JS<Object>('!', '#.prototype', classDeclaration);
    var originalClassProto = JS<Object>('!', '#.prototype', originalClass);
    var copyWhenProto =
        (property) => JS<bool>(
          '!',
          '# || # === void 0',
          !isStateBearingSymbol(property),
          originalClassProto,
        );
    copyProperties(originalClassProto, newClassProto, copyWhen: copyWhenProto);
    var copyWhen =
        (property) => JS<bool>(
          '!',
          '# || # === void 0',
          !isStateBearingSymbol(property),
          originalClass,
        );
    copyProperties(originalClass, classDeclaration, copyWhen: copyWhen);
  }
  return JS<Object>('!', '#.#', library, classIdentifier);
}

/// Declares properties in [propertiesObject] on [topLevelContainer].
///
/// [topLevelContainer] must already exist.
/// During a hot reload, properties in [propertiesObject] not prefixed by a
/// special identifier are replaced (see [isStateBearingSymbol]).
declareTopLevelProperties(topLevelContainer, propertiesObject) {
  if (JS<bool>('!', '# === void 0', topLevelContainer)) {
    throw Exception('$topLevelContainer does not exist.');
  }
  var copyWhen =
      (property) => JS<bool>(
        '!',
        '# || #.# === void 0',
        !isStateBearingSymbol(property),
        topLevelContainer,
        property,
      );
  copyProperties(topLevelContainer, propertiesObject, copyWhen: copyWhen);
  return topLevelContainer;
}

/// Appends const members in [additionalFieldsObject] to [canonicalizedEnum].
///
/// [additionalFieldsObject] is a JS object containing fields that should not
/// be considered for enum identity/equality but may be updated after a hot
/// reload.
extendEnum(canonicalizedEnum, additionalFieldsObject) {
  copyProperties(canonicalizedEnum, additionalFieldsObject);
  return canonicalizedEnum;
}
