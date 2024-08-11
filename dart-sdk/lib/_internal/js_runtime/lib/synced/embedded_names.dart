// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: constant_identifier_names, library_names

/// Contains the names of globals that are embedded into the output by the
/// compiler.
///
/// Variables embedded this way should be access with `JS_EMBEDDED_GLOBAL` from
/// the `_foreign_helper` library.
///
/// This library is shared between the compiler and the runtime system.
library dart2js._embedded_names;

/// The name of the property that is used to find the native superclass of
/// an extended class.
///
/// Every class that extends a native class has this property set on its
/// native class.
const NATIVE_SUPERCLASS_TAG_NAME = r"$nativeSuperclassTag";

/// The name of the static-function property name.
///
/// This property is set for all tear-offs of static functions, and provides
/// the static function's unique (potentially minified) name.
const STATIC_FUNCTION_NAME_PROPERTY_NAME = r'$static_name';

/// The name of the embedded global for metadata.
///
/// Use [JsBuiltin.getMetadata] instead of directly accessing this embedded
/// global.
const METADATA = 'metadata';

/// A JS map from mangled global names to their unmangled names.
///
/// If the program does not use reflection, this embedded global may be empty
/// (but not null or undefined).
const MANGLED_GLOBAL_NAMES = 'mangledGlobalNames';

/// A JS map from mangled instance names to their unmangled names.
///
/// This embedded global is mainly used for reflection, but is also used to
/// map const-symbols (`const Symbol('x')`) to the mangled instance names.
///
/// This embedded global may be empty (but not null or undefined).
const MANGLED_NAMES = 'mangledNames';

/// A JS map from dispatch tags (usually constructor names of DOM classes) to
/// interceptor class. This map is used to find the correct interceptor for
/// native classes.
///
/// This embedded global is used for natives.
const INTERCEPTORS_BY_TAG = 'interceptorsByTag';

/// A JS map from dispatch tags (usually constructor names of DOM classes) to
/// booleans. Every tag entry of [INTERCEPTORS_BY_TAG] has a corresponding
/// entry in the leaf-tags map.
///
/// A tag-entry is true, when a class can be treated as leaf class in the
/// hierarchy. That is, even though it might have subclasses, all subclasses
/// have the same code for the used methods.
///
/// This embedded global is used for natives.
const LEAF_TAGS = 'leafTags';

/// A JS function that returns the isolate tag for a given name.
///
/// This function uses the [ISOLATE_TAG] (below) to construct a name that is
/// unique per isolate.
///
/// This embedded global is used for natives.
// TODO(floitsch): should we rename this variable to avoid confusion with
//    [INTERCEPTORS_BY_TAG] and [LEAF_TAGS].
const GET_ISOLATE_TAG = 'getIsolateTag';

/// A string that is different for each running isolate.
///
/// When this embedded global is initialized a global variable is used to
/// ensure that no other running isolate uses the same isolate-tag string.
///
/// This embedded global is used for natives.
// TODO(floitsch): should we rename this variable to avoid confusion with
//    [INTERCEPTORS_BY_TAG] and [LEAF_TAGS].
const ISOLATE_TAG = 'isolateTag';

/// This embedded global (a function) returns the isolate-specific dispatch-tag
/// that is used to accelerate interceptor calls.
const DISPATCH_PROPERTY_NAME = "dispatchPropertyName";

/// An embedded global that maps a [Type] to the [Interceptor] and constructors
/// for that type.
///
/// More documentation can be found in the interceptors library (close to its
/// use).
const TYPE_TO_INTERCEPTOR_MAP = "typeToInterceptorMap";

/// The current script's URI when the program was loaded.
///
/// This embedded global is set at startup, just before invoking `main`.
const CURRENT_SCRIPT = 'currentScript';

/// Contains a map from load-ids to lists of part indexes.
///
/// To load the deferred library that is represented by the load-id, the runtime
/// must load all associated URIs (named in DEFERRED_PART_URIS) and initialize
/// all the loaded hunks (DEFERRED_PART_HASHES).
///
/// This embedded global is only used for deferred loading.
const DEFERRED_LIBRARY_PARTS = 'deferredLibraryParts';

/// Contains a list of URIs (Strings), indexed by part.
///
/// The lists in the DEFERRED_LIBRARY_PARTS map contain indexes into this list.
///
/// This embedded global is only used for deferred loading.
const DEFERRED_PART_URIS = 'deferredPartUris';

/// Contains a list of hashes, indexed by part.
///
/// The lists in the DEFERRED_LIBRARY_PARTS map contain indexes into this list.
///
/// The hashes are associated with the URIs of the load-ids (see
/// [DEFERRED_PART_URIS]). They are SHA1 (or similar) hashes of the code that
/// must be loaded. By using cryptographic hashes we can (1) handle loading in
/// the same web page the parts from multiple Dart applications (2) avoid
/// loading similar code multiple times.
///
/// This embedded global is only used for deferred loading.
const DEFERRED_PART_HASHES = 'deferredPartHashes';

/// Initialize a loaded hunk.
///
/// Once a hunk (the code from a deferred URI) has been loaded it must be
/// initialized. Calling this function with the corresponding hash (see
/// [DEFERRED_LIBRARY_HASHES]) initializes the code.
///
/// This embedded global is only used for deferred loading.
const INITIALIZE_LOADED_HUNK = 'initializeLoadedHunk';

/// Returns, whether a hunk (identified by its hash) has already been loaded.
///
/// This embedded global is only used for deferred loading.
const IS_HUNK_LOADED = 'isHunkLoaded';

/// Returns, whether a hunk (identified by its hash) has already been
/// initialized.
///
/// This embedded global is only used for deferred loading.
const IS_HUNK_INITIALIZED = 'isHunkInitialized';

/// A set (implemented as map to booleans) of hunks (identified by hashes) that
/// have already been initialized.
///
/// This embedded global is only used for deferred loading.
///
/// This global is an emitter-internal embedded global, and not used by the
/// runtime. The constant remains in this file to make sure that other embedded
/// globals don't clash with it.
const DEFERRED_INITIALIZED = 'deferredInitialized';

/// Property name for the reference to the initialization event log which is
/// included in exceptions when deferred loading fails.
///
/// The event log is a JS array where each entry is a plain JS object
/// representing event data. Each entry will be passed to JSON.stringify()
/// before being appended to the thrown exception.
///
/// This embedded global is only used for deferred loading.
const INITIALIZATION_EVENT_LOG = 'eventLog';

/// An embedded global used to collect and access runtime metrics.
const RUNTIME_METRICS = 'rm';

/// Global name that holds runtime metrics Dart2JS apps.
const RUNTIME_METRICS_CONTAINER = 'runtimeMetrics';

/// An embedded global used to collect and access startup metrics.
const STARTUP_METRICS = 'sm';

/// An embedded global that contains combinator functions for generating record
/// type checks.
// TODO(51016): This might be moved to improve deferred loading.
const RECORD_TYPE_TEST_COMBINATORS_PROPERTY = 'rttc';

/// Names of fields of collected tear-off parameters object.
///
/// Tear-off getters are created before the Dart classes are initialized, so a
/// plain JavaScript object is used to group the parameters. The object has a
/// fixed shape, with the following properties. The names are short since there
/// is no minifier for these property names.
class TearOffParametersPropertyNames {
  static const String container = 'co';
  static const String isStatic = 'iS';
  static const String isIntercepted = 'iI';
  static const String requiredParameterCount = 'rC';
  static const String optionalParameterDefaultValues = 'dV';
  static const String callNames = 'cs';
  static const String funsOrNames = 'fs';
  static const String funType = 'fT';
  static const String applyIndex = 'aI';
  static const String needsDirectAccess = 'nDA';
}
