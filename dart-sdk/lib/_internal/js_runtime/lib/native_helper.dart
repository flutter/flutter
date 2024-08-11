// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _js_helper;

// TODO(ngeoffray): stop using this method once our optimizers can
// change str1.contains(str2) into str1.indexOf(str2) != -1.
bool contains(String userAgent, String name) {
  return JS('int', '#.indexOf(#)', userAgent, name) != -1;
}

int arrayLength(List array) {
  return JS('int', '#.length', array);
}

arrayGet(List array, int index) {
  return JS('var', '#[#]', array, index);
}

void arraySet(List array, int index, var value) {
  JS('var', '#[#] = #', array, index, value);
}

propertyGet(var object, String property) {
  return JS('var', '#[#]', object, property);
}

bool callHasOwnProperty(var function, var object, String property) {
  return JS('bool', '#.call(#, #)', function, object, property);
}

void propertySet(var object, String property, var value) {
  JS('var', '#[#] = #', object, property, value);
}

getPropertyFromPrototype(var object, String name) {
  return JS('var', 'Object.getPrototypeOf(#)[#]', object, name);
}

/// Returns a String tag identifying the type of the native object, or `null`.
/// The tag is not the name of the type, but usually the name of the JavaScript
/// constructor function.  Initialized by [initHooks].
Function? getTagFunction;

/// If a lookup via [getTagFunction] on an object [object] that has [tag] fails,
/// this function is called to provide an alternate tag.  This allows us to fail
/// gracefully if we can make a good guess, for example, when browsers add novel
/// kinds of HTMLElement that we have never heard of.  Initialized by
/// [initHooks].
Function? alternateTagFunction;

/// Returns the prototype for the JavaScript constructor named by an input tag.
/// Returns `null` if there is no such constructor, or if pre-patching of the
/// constructor is to be avoided.  Initialized by [initHooks].
Function? prototypeForTagFunction;

String toStringForNativeObject(var obj) {
  // TODO(sra): Is this code dead?
  // [getTagFunction] might be uninitialized, but in usual usage, toString has
  // been called via an interceptor and initialized it.
  String name = getTagFunction == null
      ? '<Unknown>'
      : JS('String', '#', getTagFunction!(obj));
  return 'Instance of $name';
}

int hashCodeForNativeObject(object) => Primitives.objectHashCode(object);

/// Sets a JavaScript property on an object.
void defineProperty(var obj, String property, var value) {
  JS(
      'void',
      'Object.defineProperty(#, #, '
          '{value: #, enumerable: false, writable: true, configurable: true})',
      obj,
      property,
      value);
}

// Is [obj] an instance of a Dart-defined class?
bool isDartObject(obj) {
  // Some of the extra parens here are necessary.
  return JS(
      'bool',
      '((#) instanceof (#))',
      obj,
      JS_BUILTIN(
          'depends:none;effects:none;', JsBuiltin.dartObjectConstructor));
}

/// A JavaScript object mapping tags to the constructors of interceptors.
/// This is a JavaScript object with no prototype.
///
/// Example: 'HTMLImageElement' maps to the ImageElement class constructor.
get interceptorsByTag => JS_EMBEDDED_GLOBAL('=Object', INTERCEPTORS_BY_TAG);

/// A JavaScript object mapping tags to `true` or `false`.
///
/// Example: 'HTMLImageElement' maps to `true` since, as there are no subclasses
/// of ImageElement, it is a leaf class in the native class hierarchy.
get leafTags => JS_EMBEDDED_GLOBAL('=Object', LEAF_TAGS);

String findDispatchTagForInterceptorClass(interceptorClassConstructor) {
  return JS(
      '', r'#.#', interceptorClassConstructor, NATIVE_SUPERCLASS_TAG_NAME);
}

/// Cache of dispatch records for instances.  This is a JavaScript object used
/// as a map.  Keys are instance tags, e.g. "!SomeThing".  The cache permits the
/// sharing of one dispatch record between multiple instances.
var dispatchRecordsForInstanceTags;

/// Cache of interceptors indexed by uncacheable tags, e.g. "~SomeThing".
/// This is a JavaScript object used as a map.
var interceptorsForUncacheableTags;

lookupInterceptor(String tag) {
  return propertyGet(interceptorsByTag, tag);
}

// Dispatch tag marks are optional prefixes for a dispatch tag that direct how
// the interceptor for the tag may be cached.

/// No caching permitted.
const UNCACHED_MARK = '~';

/// Dispatch record must be cached per instance
const INSTANCE_CACHED_MARK = '!';

/// Dispatch record is cached on immediate prototype.
const LEAF_MARK = '-';

/// Dispatch record is cached on immediate prototype with a prototype
/// verification to prevent the interceptor being associated with a subclass
/// before a dispatch record is cached on the subclass.
const INTERIOR_MARK = '+';

/// A 'discriminator' function is to be used. TBD.
const DISCRIMINATED_MARK = '*';

/// Returns the interceptor for a native object, or returns `null` if not found.
///
/// A dispatch record is cached according to the specification of the dispatch
/// tag for [obj].
@pragma('dart2js:noInline')
lookupAndCacheInterceptor(obj) {
  assert(!isDartObject(obj));
  String tag = getTagFunction!(obj);

  // Fast path for instance (and uncached) tags because the lookup is repeated
  // for each instance (or getInterceptor call).
  var record = propertyGet(dispatchRecordsForInstanceTags, tag);
  if (record != null) return patchInstance(obj, record);
  var interceptor = propertyGet(interceptorsForUncacheableTags, tag);
  if (interceptor != null) return interceptor;

  // This lookup works for derived dispatch tags because we add them all in
  // [initNativeDispatch].
  var interceptorClass = lookupInterceptor(tag);
  if (interceptorClass == null) {
    String? altTag = alternateTagFunction!(obj, tag);
    if (altTag != null) {
      tag = altTag;
      // Fast path for instance and uncached tags again.
      record = propertyGet(dispatchRecordsForInstanceTags, tag);
      if (record != null) return patchInstance(obj, record);
      interceptor = propertyGet(interceptorsForUncacheableTags, tag);
      if (interceptor != null) return interceptor;

      interceptorClass = lookupInterceptor(tag);
    }
  }

  if (interceptorClass == null) {
    // This object is not known to Dart.  There could be several reasons for
    // that, including (but not limited to):
    //
    // * A bug in native code (hopefully this is caught during development).
    // * An unknown DOM object encountered.
    // * JavaScript code running in an unexpected context.  For example, on
    //   node.js.
    return null;
  }

  interceptor = JS('', '#.prototype', interceptorClass);

  var mark = JS('String|Null', '#[0]', tag);

  if (mark == INSTANCE_CACHED_MARK) {
    record = makeLeafDispatchRecord(interceptor);
    propertySet(dispatchRecordsForInstanceTags, tag, record);
    return patchInstance(obj, record);
  }

  if (mark == UNCACHED_MARK) {
    propertySet(interceptorsForUncacheableTags, tag, interceptor);
    return interceptor;
  }

  if (mark == LEAF_MARK) {
    return patchProto(obj, makeLeafDispatchRecord(interceptor));
  }

  if (mark == INTERIOR_MARK) {
    return patchInteriorProto(obj, interceptor);
  }

  if (mark == DISCRIMINATED_MARK) {
    // TODO(sra): Use discriminator of tag.
    throw UnimplementedError(tag);
  }

  // [tag] was not explicitly an interior or leaf tag, so
  var isLeaf = JS('bool', '(#[#]) === true', leafTags, tag);
  if (isLeaf) {
    return patchProto(obj, makeLeafDispatchRecord(interceptor));
  } else {
    return patchInteriorProto(obj, interceptor);
  }
}

patchInstance(obj, record) {
  setDispatchProperty(obj, record);
  return dispatchRecordInterceptor(record);
}

patchProto(obj, record) {
  setDispatchProperty(JS('', 'Object.getPrototypeOf(#)', obj), record);
  return dispatchRecordInterceptor(record);
}

patchInteriorProto(obj, interceptor) {
  var proto = JS('', 'Object.getPrototypeOf(#)', obj);
  var record = makeDispatchRecord(interceptor, proto, null, null);
  setDispatchProperty(proto, record);
  return interceptor;
}

makeLeafDispatchRecord(interceptor) {
  var fieldName = JS_GET_NAME(JsGetName.IS_INDEXABLE_FIELD_NAME);
  bool indexability = JS('bool', r'!!#[#]', interceptor, fieldName);
  return makeDispatchRecord(interceptor, false, null, indexability);
}

makeDefaultDispatchRecord(tag, interceptorClass, proto) {
  var interceptor = JS('', '#.prototype', interceptorClass);
  var isLeaf = JS('bool', '(#[#]) === true', leafTags, tag);
  if (isLeaf) {
    return makeLeafDispatchRecord(interceptor);
  } else {
    return makeDispatchRecord(interceptor, proto, null, null);
  }
}

/// [proto] should have no shadowing prototypes that are not also assigned a
/// dispatch rescord.
setNativeSubclassDispatchRecord(proto, interceptor) {
  setDispatchProperty(proto, makeLeafDispatchRecord(interceptor));
}

String constructorNameFallback(object) {
  return JS('returns:String;effects:none;depends:none', '#(#)',
      _constructorNameFallback, object);
}

var initNativeDispatchFlag; // null or true

@pragma('dart2js:noInline')
void initNativeDispatch() {
  if (true == initNativeDispatchFlag) return;
  initNativeDispatchFlag = true;
  initNativeDispatchContinue();
}

@pragma('dart2js:noInline')
void initNativeDispatchContinue() {
  dispatchRecordsForInstanceTags = JS('', 'Object.create(null)');
  interceptorsForUncacheableTags = JS('', 'Object.create(null)');

  initHooks();

  // Try to pro-actively patch prototypes of DOM objects.  For each of our known
  // tags `TAG`, if `window.TAG` is a (constructor) function, set the dispatch
  // property if the function's prototype to a dispatch record.
  var map = interceptorsByTag;
  JSArray tags = JS('JSMutableArray', 'Object.getOwnPropertyNames(#)', map);

  if (JS('bool', 'typeof window != "undefined"')) {
    var context = JS('=Object', 'window');
    var fun = JS('=Object', 'function () {}');
    for (int i = 0; i < tags.length; i++) {
      var tag = tags[i];
      var proto = prototypeForTagFunction!(tag);
      if (proto != null) {
        var interceptorClass = JS('', '#[#]', map, tag);
        var record = makeDefaultDispatchRecord(tag, interceptorClass, proto);
        if (record != null) {
          setDispatchProperty(proto, record);
          // Ensure the modified prototype is still fast by assigning it to
          // the prototype property of a function object.
          JS('', '#.prototype = #', fun, proto);
        }
      }
    }
  }

  // [interceptorsByTag] maps 'plain' dispatch tags.  Add all the derived
  // dispatch tags to simplify lookup of derived tags.
  for (int i = 0; i < tags.length; i++) {
    var tag = JS('String', '#[#]', tags, i);
    if (JS('bool', '/^[A-Za-z_]/.test(#)', tag)) {
      var interceptorClass = propertyGet(map, tag);
      propertySet(map, INSTANCE_CACHED_MARK + tag, interceptorClass);
      propertySet(map, UNCACHED_MARK + tag, interceptorClass);
      propertySet(map, LEAF_MARK + tag, interceptorClass);
      propertySet(map, INTERIOR_MARK + tag, interceptorClass);
      propertySet(map, DISCRIMINATED_MARK + tag, interceptorClass);
    }
  }
}

/// Initializes [getTagFunction] and [alternateTagFunction].
///
/// These functions are 'hook functions', collectively 'hooks'.  They
/// initialized by applying a series of hooks transformers.  Built-in hooks
/// transformers deal with various known browser behaviours.
///
/// Each hook transformer takes a 'hooks' input which is a JavaScript object
/// containing the hook functions, and returns the same or a new object with
/// replacements.  The replacements can wrap the originals to provide alternate
/// or modified behaviour.
///
///     { getTag: function(obj) {...},
///       getUnknownTag: function(obj, tag) {...},
///       prototypeForTag: function(tag) {...},
///       discriminator: function(tag) {...},
///      }
///
/// * getTag(obj) returns the dispatch tag, or `null`.
/// * getUnknownTag(obj, tag) returns a tag when [getTag] fails.
/// * prototypeForTag(tag) returns the prototype of the constructor for tag,
///   or `null` if not available or prepatching is undesirable.
/// * discriminator(tag) returns a function TBD.
///
/// The web site can adapt a dart2js application by loading code ahead of the
/// dart2js application that defines hook transformers to be after the built in
/// ones.  Code defining a transformer HT should use the following pattern to
/// ensure multiple transformers can be composed:
///
///     (dartNativeDispatchHooksTransformer =
///      window.dartNativeDispatchHooksTransformer || []).push(HT);
///
///
/// TODO: Implement and describe dispatch tags and their caching methods.
void initHooks() {
  // The initial simple hooks:
  var hooks = JS('', '#()', _baseHooks);

  // Customize for browsers where `object.constructor.name` fails:
  var _fallbackConstructorHooksTransformer = JS('', '#(#)',
      _fallbackConstructorHooksTransformerGenerator, _constructorNameFallback);
  hooks = applyHooksTransformer(_fallbackConstructorHooksTransformer, hooks);

  // Customize for browsers:
  hooks = applyHooksTransformer(_firefoxHooksTransformer, hooks);
  hooks = applyHooksTransformer(_ieHooksTransformer, hooks);
  hooks = applyHooksTransformer(_operaHooksTransformer, hooks);
  hooks = applyHooksTransformer(_safariHooksTransformer, hooks);

  hooks = applyHooksTransformer(_fixDocumentHooksTransformer, hooks);

  // TODO(sra): Update ShadowDOM polyfil to use
  // [dartNativeDispatchHooksTransformer] and remove this hook.
  hooks = applyHooksTransformer(
      _dartExperimentalFixupGetTagHooksTransformer, hooks);

  // Apply global hooks.
  //
  // If defined, dartNativeDispatchHookdTransformer should be a single function
  // of a JavaScript Array of functions.

  if (JS('bool', 'typeof dartNativeDispatchHooksTransformer != "undefined"')) {
    var transformers = JS('', 'dartNativeDispatchHooksTransformer');
    if (JS('bool', 'typeof # == "function"', transformers)) {
      transformers = [transformers];
    }
    if (JS('bool', 'Array.isArray(#)', transformers)) {
      for (int i = 0; i < JS('int', '#.length', transformers); i++) {
        var transformer = JS('', '#[#]', transformers, i);
        if (JS('bool', 'typeof # == "function"', transformer)) {
          hooks = applyHooksTransformer(transformer, hooks);
        }
      }
    }
  }

  var getTag = JS('', '#.getTag', hooks);
  var getUnknownTag = JS('', '#.getUnknownTag', hooks);
  var prototypeForTag = JS('', '#.prototypeForTag', hooks);

  getTagFunction = (o) => JS('String|Null', '#(#)', getTag, o);
  alternateTagFunction =
      (o, String tag) => JS('String|Null', '#(#, #)', getUnknownTag, o, tag);
  prototypeForTagFunction =
      (String tag) => JS('', '#(#)', prototypeForTag, tag);
}

applyHooksTransformer(transformer, hooks) {
  var newHooks = JS('=Object|Null', '#(#)', transformer, hooks);
  return JS('', '# || #', newHooks, hooks);
}

// JavaScript code fragments.
//
// This is a temporary place for the JavaScript code.
//
// TODO(sra): These code fragments are not minified.  They could be generated by
// the code emitter, or JS_CONST could be improved to parse entire functions and
// take care of the minification.

const _baseHooks = JS_CONST(r'''
function() {
  var toStringFunction = Object.prototype.toString;
  function getTag(o) {
    var s = toStringFunction.call(o);
    return s.substring(8, s.length - 1);
  }
  function getUnknownTag(object, tag) {
    // This code really belongs in [getUnknownTagGenericBrowser] but having it
    // here allows [getUnknownTag] to be tested on d8.
    if (/^HTML[A-Z].*Element$/.test(tag)) {
      // Check that it is not a simple JavaScript object.
      var name = toStringFunction.call(object);
      if (name == "[object Object]") return null;
      return "HTMLElement";
    }
  }
  function getUnknownTagGenericBrowser(object, tag) {
    if (object instanceof HTMLElement) return "HTMLElement";
    return getUnknownTag(object, tag);
  }
  function prototypeForTag(tag) {
    if (typeof window == "undefined") return null;
    if (typeof window[tag] == "undefined") return null;
    var constructor = window[tag];
    if (typeof constructor != "function") return null;
    return constructor.prototype;
  }
  function discriminator(tag) { return null; }

  // The difference for a browser here is that HTMLElement gets special
  // treatment in [getUnknownTagGenericBrowser].
  var isBrowser = typeof HTMLElement == "function";

  return {
    getTag: getTag,
    getUnknownTag: isBrowser ? getUnknownTagGenericBrowser : getUnknownTag,
    prototypeForTag: prototypeForTag,
    discriminator: discriminator };
}''');

/// Returns the name of the constructor function for browsers where
/// `object.constructor.name` is not reliable.
///
/// This function is split out of
/// [_fallbackConstructorHooksTransformerGenerator] as it is called from both
/// the dispatch hooks and via [constructorNameFallback] from objectToString.
const _constructorNameFallback = JS_CONST(r'''
function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}''');

const _fallbackConstructorHooksTransformerGenerator = JS_CONST(r'''
function(getTagFallback) {
  return function(hooks) {
    // If we are not in a browser, assume we are in d8.
    // TODO(sra): Recognize jsshell.
    if (typeof navigator != "object") return hooks;
    var userAgent = navigator.userAgent;
    if (typeof userAgent != "string") return hooks;
    // TODO(antonm): remove a reference to DumpRenderTree.
    if (userAgent.indexOf("DumpRenderTree") >= 0) return hooks;
    if (userAgent.indexOf("Chrome") >= 0) {
      // Confirm constructor name is usable for dispatch.
      function confirm(p) {
        return typeof window == "object" && window[p] && window[p].name == p;
      }
      if (confirm("Window") && confirm("HTMLElement")) return hooks;
    }

    hooks.getTag = getTagFallback;
  };
}''');

const _ieHooksTransformer = JS_CONST(r'''
function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Trident/") == -1) return hooks;

  var getTag = hooks.getTag;

  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "HTMLDDElement": "HTMLElement",
    "HTMLDTElement": "HTMLElement",
    "HTMLPhraseElement": "HTMLElement",
    "Position": "Geoposition"
  };

  function getTagIE(o) {
    var tag = getTag(o);
    var newTag = quickMap[tag];
    if (newTag) return newTag;
    // Patches for types which report themselves as Objects.
    if (tag == "Object") {
      if (window.DataView && (o instanceof window.DataView)) return "DataView";
    }
    return tag;
  }

  function prototypeForTagIE(tag) {
    var constructor = window[tag];
    if (constructor == null) return null;
    return constructor.prototype;
  }

  hooks.getTag = getTagIE;
  hooks.prototypeForTag = prototypeForTagIE;
}''');

const _fixDocumentHooksTransformer = JS_CONST(r'''
function(hooks) {
  var getTag = hooks.getTag;
  var prototypeForTag = hooks.prototypeForTag;
  function getTagFixed(o) {
    var tag = getTag(o);
    if (tag == "Document") {
      // Some browsers and the polymer polyfill call both HTML and XML documents
      // "Document", so we check for the xmlVersion property, which is the empty
      // string on HTML documents. Since both dart:html classes Document and
      // HtmlDocument share the same type, we must patch the instances and not
      // the prototype.
      if (!!o.xmlVersion) return "!Document";
      return "!HTMLDocument";
    }
    return tag;
  }

  function prototypeForTagFixed(tag) {
    if (tag == "Document") return null;  // Do not pre-patch Document.
    return prototypeForTag(tag);
  }

  hooks.getTag = getTagFixed;
  hooks.prototypeForTag = prototypeForTagFixed;
}''');

const _firefoxHooksTransformer = JS_CONST(r'''
function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Firefox") == -1) return hooks;

  var getTag = hooks.getTag;

  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "GeoGeolocation": "Geolocation",
    "Location": "!Location",               // Fixes issue 18151
    "WorkerMessageEvent": "MessageEvent",
    "XMLDocument": "!Document"};

  function getTagFirefox(o) {
    var tag = getTag(o);
    return quickMap[tag] || tag;
  }

  hooks.getTag = getTagFirefox;
}''');

const _operaHooksTransformer = JS_CONST(r'''
function(hooks) { return hooks; }
''');

const _safariHooksTransformer = JS_CONST(r'''
function(hooks) { return hooks; }
''');

const _dartExperimentalFixupGetTagHooksTransformer = JS_CONST(r'''
function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}''');
