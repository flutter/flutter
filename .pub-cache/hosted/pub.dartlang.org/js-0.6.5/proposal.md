# Better JavaScript and Dart interoperability

Table of contents:

<!-- toc -->

- [Motivation](#motivation)
- [Typed APIs](#typed-apis)
  * [Automatic Typed API Generation](#automatic-typed-api-generation)
  * [Static Dispatch](#static-dispatch)
    + [Extension Fields](#extension-fields)
  * [JS Interop Checked Mode](#js-interop-checked-mode)
  * [Data Type Interoperability](#data-type-interoperability)
  * [Implicit and Explicit Conversions](#implicit-and-explicit-conversions)
- [Functions](#functions)
  * [Optional Arguments](#optional-arguments)
  * [Named Arguments](#named-arguments)
  * [Overloads](#overloads)
  * [This Argument](#this-argument)
  * [Method Tearoffs](#method-tearoffs)
  * [Generic Type Parameters](#generic-type-parameters)
- [Data Types Conversions](#data-types-conversions)
  * [Generic Types, List and JS Array](#generic-types-list-and-js-array)
  * [Null and Undefined](#null-and-undefined)
  * [Future and JS Promise](#future-and-js-promise)
  * [Iterable and JS Iterable](#iterable-and-js-iterable)
  * [Stream and JS Async Iterable](#stream-and-js-async-iterable)
  * [Stream and Callbacks](#stream-and-callbacks)
  * [DateTime and JS Date](#datetime-and-js-date)
  * [Map/Set and JS Map/Set](#mapset-and-js-mapset)
  * [Maps and JS Objects](#maps-and-js-objects)
    + [Wrapper-based JSObjectMap](#wrapper-based-jsobjectmap)
    + [Autoboxing JSObjectMap](#autoboxing-jsobjectmap)
- [Less Static Interop](#less-static-interop)
  * [Virtual Dispatch](#virtual-dispatch)
  * [Interface and Dynamic dispatch](#interface-and-dynamic-dispatch)
  * [JS Proxy](#js-proxy)
  * [JS Reflection](#js-reflection)
- [Exporting Dart to JS](#exporting-dart-to-js)
  * [Exporting classes and libraries](#exporting-classes-and-libraries)
  * [Inheritance between Dart and JS](#inheritance-between-dart-and-js)
  * [Interop with JS Modules](#interop-with-js-modules)
  * [Exposing JS Methods as Getters](#exposing-js-methods-as-getters)
- [JS Types in the Dart Type System](#js-types-in-the-dart-type-system)
- [Implementation Roadmap](#implementation-roadmap)
- [Compatibility and Evolution](#compatibility-and-evolution)
- [FAQ](#faq)
  * [Q: How does JSON work?](#q-how-does-json-work)
  * [Q: Would new Dart language features help?](#q-would-new-dart-language-features-help)
  * [Q: Can dart2js and dartdevc share implementation for JS interop?](#q-can-dart2js-and-dartdevc-share-implementation-for-js-interop)
  * [Q: If a JS API returns "Object" does this break dart2js tree shaking?](#q-if-a-js-api-returns-object-does-this-break-dart2js-tree-shaking)
  * [Q: Could we use dynamic interop instead?](#q-could-we-use-dynamic-interop-instead)

<!-- tocstop -->

## Motivation

Better interoperability with JavaScript is one of the most highly requested 
features for Dart. Previous work has made JS interop possible, but gaps remain.
This proposal outlines a series of usability improvements that, taken together,
make it much easier to use JS from Dart and vice versa.

Here's an example of JS interop is like today, from the [Firebase package](https://pub.dev/packages/firebase):
```dart
import 'interop/app_interop.dart';

/// A Firebase App holds the initialization information for a collection
/// of services.
///
/// See: <https://firebase.google.com/docs/reference/js/firebase.app>.
class App extends JsObjectWrapper<AppJsImpl> {
  // [ed: doc comments removed to condense code]
  static final _expando = Expando<App>();

  String get name => jsObject.name;
  FirebaseOptions get options => jsObject.options;

  static App getInstance(AppJsImpl jsObject) {
    if (jsObject == null) {
      return null;
    }
    return _expando[jsObject] ??= App._fromJsObject(jsObject);
  }

  App._fromJsObject(AppJsImpl jsObject) : super.fromJsObject(jsObject);

  Auth auth() => Auth.getInstance(jsObject.auth());
  Database database() => Database.getInstance(jsObject.database());
  Future delete() => handleThenable(jsObject.delete());
  Firestore firestore() => Firestore.getInstance(jsObject.firestore());

  Storage storage([String url]) {
    var jsObjectStorage =
        (url != null) ? jsObject.storage(url) : jsObject.storage();
    return Storage.getInstance(jsObjectStorage);
  }
}

// [ed: in interop/app_interop.dart]

@JS('App')
abstract class AppJsImpl {
  external String get name;
  external FirebaseOptions get options;
  external AuthJsImpl auth();
  external DatabaseJsImpl database();
  external PromiseJsImpl delete();
  external StorageJsImpl storage([String url]);
  external FirestoreJsImpl firestore();
}
```

Nearly all of the Firebase classes are wrapped like that. It's a lot of work and
boilerplate to implement wrappers like this, and it adds overhead to every
operation.

What we'd like to write is more like this:
```dart
@JS()
class App {
  external String get name;
  external FirebaseOptions get options;

  // Wrappers no longer necessary for these classes.
  external Auth auth();
  external Database database();
  external Firestore firestore();

  // Promise -> Future is handled automatically
  external Future delete();

  // Optional arguments are handled correctly by the compiler.
  // (In advanced cases, there are ways to declare overloads.)
  external Storage storage([String url]);
}
```

The [Google Maps API](https://github.com/a14n/dart-google-maps) package is
similar, but generated using the [js_wrapping](https://github.com/a14n/dart-js-wrapping)
code generator:

```dart
@GeneratedFrom(_LatLngBounds)
@JsName('google.maps.LatLngBounds')
class LatLngBounds extends JsInterface {
  LatLngBounds([LatLng sw, LatLng ne])
      : this.created(JsObject(context['google']['maps']['LatLngBounds'],
            [__codec0.encode(sw), __codec0.encode(ne)]));
  LatLngBounds.created(JsObject o) : super.created(o);

  bool contains(LatLng latLng) =>
      asJsObject(this).callMethod('contains', [__codec0.encode(latLng)]);
  bool equals(LatLngBounds other) =>
      asJsObject(this).callMethod('equals', [__codec1.encode(other)]);
  LatLngBounds extend(LatLng point) => __codec1
      .decode(asJsObject(this).callMethod('extend', [__codec0.encode(point)]));
  LatLng get center => _getCenter();
  LatLng _getCenter() =>
      __codec0.decode(asJsObject(this).callMethod('getCenter'));
  LatLng get northEast => _getNorthEast();
  LatLng _getNorthEast() =>
      __codec0.decode(asJsObject(this).callMethod('getNorthEast'));
  LatLng get southWest => _getSouthWest();
  LatLng _getSouthWest() =>
      __codec0.decode(asJsObject(this).callMethod('getSouthWest'));
  bool intersects(LatLngBounds other) =>
      asJsObject(this).callMethod('intersects', [__codec1.encode(other)]);
  bool get isEmpty => _isEmpty();
  bool _isEmpty() => asJsObject(this).callMethod('isEmpty');
  LatLng toSpan() => __codec0.decode(asJsObject(this).callMethod('toSpan'));
  String toString() => asJsObject(this).callMethod('toString');
  String toUrlValue([num precision]) =>
      asJsObject(this).callMethod('toUrlValue', [precision]);
  LatLngBounds union(LatLngBounds other) => __codec1
      .decode(asJsObject(this).callMethod('union', [__codec1.encode(other)]));
}
```

What we'd like to write instead:
```dart
@JS('google.maps.LatLngBounds')
class LatLngBounds {
  external LatLngBounds([LatLng sw, LatLng ne]);

  external bool contains(LatLng latLng);
  external bool equals(LatLngBounds other);
  external LatLngBounds extend(LatLng point);
  external bool intersects(LatLngBounds other);
  external LatLng toSpan();
  external String toString();
  external String toUrlValue([num precision]);
  external LatLngBounds union(LatLngBounds other);

  @sealed
  LatLng get center => _getCenter();
  @sealed
  LatLng get northEast => _getNorthEast();
  @sealed
  LatLng get southWest => _getSouthWest();
  @sealed
  bool get isEmpty => _isEmpty();

  @JS('getCenter')
  external LatLng _getCenter();
  @JS('getNorthEast')
  external LatLng _getNorthEast();
  @JS('getSouthWest')
  external LatLng _getSouthWest();
  @JS('isEmpty')
  external bool _isEmpty();
}
```

The rest of the proposal outlines how we get there, as well as many other
usability and correctness improvements.


## Typed APIs

The key principle behind Dart and JS interop is declaring API signatures,
as illustrated above. The two main pieces of this are `@JS()` annotations and
the `external` keyword:

```dart
@JS('firebase.app')
library firebase.app;

import 'package:js/js.dart' show JS;

@JS('App')
class App {
  external String get name;
  // [...]
}
```

The `external` keyword marks a class member or library member as representing a 
JavaScript API. It allows the body of the API to be omitted, and is only valid
on a declaration that is in a `@JS()` context (either it is marked with `@JS()`
itself, or is within a library/class that is marked).

The `@JS()` annotation marks a declaration (library, class, library member or
class member) as representing a JavaScript API. An optional string can be
provided, to specify the name of the declaration in JS. This allows APIs to be
renamed. For example:

```dart
@JS()
@anonymous
class UserInfo {
  // [...]

  /// Returns a JSON-serializable representation of this object.
  @JS('toJSON')
  @JSConvert(dartify)
  external Map<String, dynamic> toJson();
}
```

In the example above `toJSON()` was named `toJson()` to match Dart naming
conventions. (This also implicitly marks it as `@sealed`.)

Typed APIs provide many benefits:
- They assist discovery and use of the API, via autocompletion in the editor.
- They provide static type checking to help use the API correctly.
- They're the foundation of automatic data type conversions, and adding Dart
  members to JS interop classes, to provide a more Dart-like API when desired.


### Automatic Typed API Generation

Many JavaScript APIs have types now, either from TypeScript or Closure Compiler
comments. We'd like to have a tool to automatically generate
Dart interop APIs from those. The resulting file can then be hand edited, if
desired, to further customize the interop, or used immediately.


### Static Dispatch

The example above renames *instance members*, allowing the API to be made
more Dart-friendly. This feature is crucial for interoperability, as the
JavaScript API may have a name that is not legal in Dart, or its name may have
different visibility, such as names starting with underscore.

Renames are made possible by taking advantage of the static type of the
receiver. This is similar to static calls and extension methods.

```dart
UserInfo user = someExpression;
print(user.toJson());
```

The compiler only needs to generate something like:

```js
let user = someExpression;
core.print(js.dartify(user.toJSON()));
```

Here a conversion was also inserted, based on the `@JSConvert(dartify)`
annotation. Because it's static, the compilers are able to inline JS code if
they choose to.

Static dispatch lets us reshape APIs in very powerful ways, without the
overhead and complexity of wrappers. It also provides a good user experience
in the IDE.

Notably, this interop is extremely similar to the language team's
[Static Extension Types](https://github.com/dart-lang/language/issues/42) and
[Static Extension Methods](https://github.com/dart-lang/language/issues/41)
proposals. All members in a JS interop class that have Dart implementation code
(i.e. function bodies, rather than `external`) are required to be nonextensible.
If we get those language features, they'll provide an alternate syntax, and
offer additional capabilities.


#### Extension Fields

In existing web compilers, there is some ambiguity about how fields on JS types
are interpreted:

```dart
@JS()
class MyJSClass {
  external int get foo;
  external set foo(int value);

  int bar;

  @JS()
  int baz;
}
```

Both compilers support "foo". DDC interprets "bar" as a getter/setter pair
similar to "foo" but dart2js does not. Neither compiler recognizes the `@JS` on
"baz".

Existing JS interop code suggests we need to provide two features:
- make it easy to declare external getter/setter pairs.
- add Dart state to JS classes.

We can accomplish this by using `@JS` to indicate a JS field. With the new
interpretation:

```dart
@JS()
class MyJSClass {
  external int get foo; // external getter/setter
  external set foo(int value);

  @sealed
  int bar; // Dart extension field

  @JS() // sugar for external getter/setter, can't have an initializer
  int baz;
}
```

The "extension field" is essentially an expando:

```dart
@JS()
class MyJSClass {
  // [...]
  @sealed
  int get bar => _bar[this];
  @sealed
  void set bar(value) { _bar[this] = value; }
}

final _bar = Expando<int>();
```

(Web compilers may implement it differently, such as a JS Symbol property stored
on the instance.)


### JS Interop Checked Mode

We may want a "JS interop checked mode" to instrument APIs and check that
parameters and return types match their declarations. This would provide a lot
of added safety. It could be turned on for tests, for example.
If implemented, this would be an opt-in capability


### Data Type Interoperability

To use typed APIs, we need to be able to pass data back and forth, and write
type annotations for the parameters and return value. One of the key questions
then is: can JS and Dart objects be passed directly, or is some type of
conversion or wrappers required?

As the Firebase example illustrates, using wrappers everywhere has significant
cost in code size, performance, and usability.

However, it is impossible to make every single Dart and JS object "just work" in
the other environment. Consider this example:

```dart
  external factory RecaptchaVerifier(container,
      [@JSConvert(jsify) Map<String, Object> parameters, App app]);
```

While JavaScript has a [Map class](https://tc39.github.io/ecma262/#sec-map-objects) 
now, many APIs still use raw JS Objects, such as `{ "size": "invisible" }`. In
Dart `Map<String, Object>` is an interface that at runtime, could contain any
class that implements Map (including user-defined Maps). Dart's equality
semantics (`operator ==` and `hashCode`) are different from JS too.

(Even if we're only interested in Dart's default LinkedHashMap with String
keys, it would be difficult to make this work. The Map class would need to
store its data as properties on itself. Some keys would not work correctly such
as "__proto__", and some operations would have different performance 
characteristics. The map can be modified from JS, so it's difficult to see how
things like `length` and `keys` could be implemented efficiently.)

For these reasons, we can't take an all-or-nothing approach: ideally most types
are wrapperless, but we'll need good support for conversions too.


### Implicit and Explicit Conversions

Wrapperless types are very convenient: you pass them back and forth, and they
just work. Explicit conversions involve a lot of boilerplate that must be
repeated everywhere. For example, we could've written the earlier `toJson()`
example like this:

```dart
@JS()
@anonymous
class UserInfo {
  // [...]

  /// Returns a JSON-serializable representation of this object.
  @sealed
  Map<String, dynamic> toJson() => dartify(_toJson());

  @JS('toJSON')
  external Map<String, dynamic> _toJson();
}
```

Or worse, the original version of the Recaptcha example shown earlier:
```dart
factory RecaptchaVerifier(container,
          [Map<String, dynamic> parameters, App app]) =>
      (parameters != null)
          ? ((app != null)
              ? RecaptchaVerifier.fromJsObject(RecaptchaVerifierJsImpl(
                  container, jsify(parameters), app.jsObject))
              : RecaptchaVerifier.fromJsObject(
                  RecaptchaVerifierJsImpl(container, jsify(parameters))))
          : RecaptchaVerifier.fromJsObject(RecaptchaVerifierJsImpl(container));

// [ed: in interop/auth_interop.dart]

  external factory RecaptchaVerifierJsImpl(container,
      [Object parameters, AppJsImpl app]);
```

Implicit conversions reduce the boilerplate and make the types feel more
like directly passed (wrapperless) types. They require less developer input to
get the correct conversion. The downside is that the conversion is less visible,
and the implications of conversions may surprise the developer. Overall these
conversion are similar to "autoboxing" in C# and Java, and are probably a net
usability benefit.

There's a language issue for [implicit conversions](https://github.com/dart-lang/language/issues/107),
so that may provide us better support. The native FFI also has a similar
mechanism for marshalling.


## Functions

Similar to Array, functions from JS do not have reified type information and are
allowed to be cast to any Dart function. This is already implemented in Dart web
compilers.

Ideally Dart functions could also be directly passed to JS. However this is not
the case in dart2js. It is not simple to change that, however.

In the meantime, automatic converisons will be provided:
- passing a Dart function type to any JS parameter performs an `allowInterop`
  conversion.
- passing any Dart value to a JS function type performs an `allowInterop`
  conversion if the runtime value is a Dart function.
- Function typed parameters/variables can be annotated with `@JS()` to indicate
  that they should be treated as being passed to JS, implying an `allowInterop`
  conversion.
- Typedefs can be annoated with `@JS()` to indicated they should be treated as
  being passed to JS, implying an `allowInterop` conversion.

One particular challenge is that dartdevc (DDC) represents Dart functions as JS
functions, so it is difficult to catch problems that may arise later in dart2js.
It should not occur much in practice, thanks to implicit conversions, and the
previously mentioned "checked mode" provides a means to catch it.


### Optional Arguments

To pass functions between JS and Dart, we need to define how calling conventions
work. The general principle is "when calling JS, work like JS". Consider the
first example again:

```dart
  Storage storage([String url]) {
    var jsObjectStorage =
        (url != null) ? jsObject.storage(url) : jsObject.storage();
    return Storage.getInstance(jsObjectStorage);
  }

  // What we'd like to write:
  external Storage storage([String url]);
```

Or for a more complex case, consider the Recaptcha example:
```dart
factory RecaptchaVerifier(container,
          [Map<String, dynamic> parameters, App app]) =>
      (parameters != null)
          ? ((app != null)
              ? RecaptchaVerifier.fromJsObject(RecaptchaVerifierJsImpl(
                  container, jsify(parameters), app.jsObject))
              : RecaptchaVerifier.fromJsObject(
                  RecaptchaVerifierJsImpl(container, jsify(parameters))))
          : RecaptchaVerifier.fromJsObject(RecaptchaVerifierJsImpl(container));

// [ed: in interop/auth_interop.dart]
  external factory RecaptchaVerifierJsImpl(container,
      [Object parameters, AppJsImpl app]);
```

These methods are dispatching the call manually, to handle the difference in
JS and Dart calling conventions: optional arguments are not passed as `null`
in JS, but are visible via `arguments.length` and their value defaults to
`undefined` rather than `null`.

What we'd like to write for Recaptcha is: 
```dart
  external factory RecaptchaVerifier(container,
      [@JSMapToObject() Map<String, Object> parameters, App app]);
```

Because it's now a JS function, the compilers must call it with the correct
number of arguments. For example, this Dart code:
```dart
RecaptchaVerifier(container);
RecaptchaVerifier(container, {'foo': 'bar'});
RecaptchaVerifier(container, {'foo': 'bar'}, app);
```

Should compile to JS code similar to:
```js
new auth.RecaptchaVerifier(container);
new auth.RecaptchaVerifier(container, {'foo': 'bar'});
new auth.RecaptchaVerifier(container, {'foo': 'bar'}, app);
```

If someone wants to forward multiple parameters, we could provide an annotation
to help:

```dart
@JS()
class Example {
  @sealed
  Object wrapsMethodWithOptionalArgs([Object foo, Object bar]) {
    // [...]
    return _underlyingJSMethod(foo, bar);
  }

  @JS('underlyingJSMethod')
  external Object _underlyingJSMethod(
      [@JSNullToOptional() Object foo, @JSNullToOptional() Object bar]);
}
```

With `@JSNullToOptional()` the compiler would automatically check for `null` in
those arguments and dispatch the call to the correct JS signature.


### Named Arguments

JS functions don't have a notion of named arguments; rather by convention, JS
Object literals are passed, and optionally destructured into parameters by the
callee.

Named arguments will be allowed as syntactic sugar for passing a JS object
literal. For example:

```dart
class Example {
  external takesJSObject({String a, int b})
}
f(Example e) {
  e.takesJSObject(a: 'hi', b: 123);
}
```

Is equivalent to this JS:

```js
function f(e) {
  e.takesJSObject({a: 'hi', b: 123});
}
```

Similarly if a Dart function that takes named arguments is passed to JS, it
must desugar them. To make this work, we'll need to restrict JS function types
to having only optional or named arguments, not both.


### Overloads

Method overloads do not exist in JavaScript. They can be helpful for
expressing type signatures, and calling native APIs that are
overloaded, such as Canvas's [createImageData](https://html.spec.whatwg.org/multipage/canvas.html#pixel-manipulation).
 
Overloads can be expressed by declaring multiple Dart methods and giving them
the same JavaScript name:

```dart
// in CanvasRenderingContext2D
  @JS('createImageData')
  external ImageData createImageDataFromImage(ImageData imagedata);
  @JS()
  external ImageData createImageData(int sw, int sh);
```

If the author wanted to expose those as the same method, they could instead do:

```dart
  @JS()
  external ImageData createImageData(imagedata_OR_sw, [int sh]);
```

Dispatching based on types should not generally be required, but if it is, it
can be written like this:

```dart
  @sealed
  ImageData createImageData(imagedata_OR_sw, [int sh]) {
    if (imagedata_OR_sw is int && sh != null) {
      return _createImageData(imagedata_OR_sw, sh);
    } else {
      return _createImageDataFromImage(imagedata_OR_sw);
    }
  }
  JS('createImageData')
  external ImageData _createImageDataFromImage(ImageData imagedata);
  @JS()
  external ImageData _createImageData(int sw, int sh);
```

The language team is also considering the problem of declaring Dart APIs like
this, see [issue 145](https://github.com/dart-lang/language/issues/145).


### This Argument

JS functions have a hidden `this` parameter, and it is sometimes important for
Dart to be able to pass that to JS, or receive it from JS.

That's accomplished with the `@JSThis()` annotation:

```dart
@JS('Object')
abstract class JSObject {
  external static _JSObjectPrototype prototype;
}

@JS()
@anonymous
abstract class _JSObjectPrototype {
  external static bool hasOwnProperty(@JSThis() target, propertyKey);
}

@JS()
@anonymous
class PropertyDescriptor {
  @JS() Object value;
  @JS() bool writable;
  @JS() bool configurable;
  @JS() bool enumerable;
  external Object Function(@JSThis() Object) get;
  external void Function(@JSThis() Object, Object) set;
}
```

This lets you declare which parameter should receive `this`/be passed as `this`.


### Method Tearoffs

Tearoffs of JS types should bind `this`, as noted in
[issue 32370](https://github.com/dart-lang/sdk/issues/32370). We also need to
decide what runtime type information to attach. Tearoffs could get the
statically visible type at the call site, or they could be treated like other
JS functions, and be assignable to any function type. Untyped is advantageous
for performance/simplicity, so it's probably preferable, unless we find
compelling examples.


### Generic Type Parameters

JavaScript does not have reified generic types. Generic types can
be used in interop signatures, but they have no effect at runtime, and no type
argument is passed. 

For JS code calling into exported Dart functions (e.g. `@JSExport`), generic
type arguments will come through as a special, runtime-only type `JSAny` that
represents the absence of a reified generic type. This is discussed further in
the next section, about Generic Types, List and JS Array.


## Data Types Conversions

This section discusses specific data types, and has recommendations for how
these should be handled in the Dart web compilers

### Generic Types, List and JS Array

Both Dart web compilers already use JS Array to implement Dart `List<T>` in
a wrapperless style. The main challenge for JS interop is how to handle generic
types.

Generic types in Dart are reified, in other words, generic type arguments are
represented and stored at run time. These are used by `is` and `as` checks, for
example, `<int>[1, 2, 3] is List<int>` will return true, and the cast
`<int>[1, 2, 3] as List<int>` will succeed. But `<int>[1, 2, 3] is List<String>`
will return false.

JavaScript cannot create Arrays that have an associated Dart generic type.
Currently these are interpreted as `List<dynamic>`, which frequently results in
a cast failure, or requires a workaround. For example:
```dart
List<App> get apps => firebase.apps
    // explicitly typing the param as dynamic to work-around
    // https://github.com/dart-lang/sdk/issues/33537
    .map((dynamic e) => App.getInstance(e))
    .toList();

// [in another file]

@JS()
external List<AppJsImpl> get apps;
```

The problem is that `List<AppJsImpl> get apps` actually returns `List<dynamic>`,
so calls like `.map` will fail Dart's reified generic checks (because the list
could contain anything, the parameter `e` must be typed to accept anything).
This leads to other strange results, such as:

```dart
@JS()
external List<String> get stringsFromJS;

main() {
  // Either prints `true` or `false`!
  // True if the compiler optimizes it, false if it's evaluated at runtime.
  print(stringsFromJS is List<String>);

  List list = stringsFromJS;
  List<String> list2 = list; // type error: not a List<String>.
}
```

The new version of this API is simply:
```dart
external List<App> get apps;
```

And it works mostly how you'd expect with `is` and `as` checks:

```dart
main() {
  List apps = firebase.apps;
  print(apps is List<App>); // true
  apps as List<App>; // works

  // prints list of names names, `(a)` is inferred as `(App a)`
  print(apps.map((a) => a.name).toList());

  apps is List<int>         // true: `int` could be from JS
  apps is List<MyDartClass> // false: can't be a list of Dart classes
                            // (unless the class is exported to JS)
}
```

The last check is an example of one consequence of the looser checking. 
Conceptually we have a `JSAny` type. This type only exists in runtime, and does
not require a representation, since it results from the absence of type
information. This is discussed later when we look at the type system.

Besides JS Arrays, Dart generic functions and methods can also be called from
JS. In that case, the reified generic type will usually be omitted. This is
discussed later when we look at exporting Dart classes to JS.


### Null and Undefined

Dart web compilers generally treat these as interchangeable; while they don't
create `undefined` themselves, it's treated as `== null`. This makes interop
easier, so it's probably worth keeping. We should also add an `undefined`
constant to "package:js", for cases where it's necessary to pass it explicitly
to JS.


### Future and JS Promise

JS Promises are very common in web APIs, as many operations are asynchronous.
These function very similarly to Dart's `Future<T>` interface.

There are several possible answers:
1. provide an implicit conversion
2. both types implement the other's interface
3. have _Future be a JS Promise

Option 3 is not feasible. Option 2 is ideal, but may cause issues in dart2js,
because they currently assume no JS types implement `Future` (this avoids
"getInterceptor" overhead). So we probably need to go with Option 1. The
dart:html library already has a conversion in one direction, and `dartdevc` may
soon have both directions (to use JS async/await).

If we did want to do the adapter design, here is a rough sketch:

```dart
@JS('Promise')
@JSInterfaceDispatch()
@JSDynamicDispatch() // Note: because existing SDK native types support this.
class JSPromise<T> implements Future<T> {
  @JS('then')
  external JSPromise<R> _then<R>(
    /*R | Thenable<R>*/Object Function(T) onFulfilled,
    [/*R | Thenable<R>*/Object Function(Object) onRejected]);

  external factory JSPromise.resolve(/*R | Thenable<R>*/Object value);

  Future<R> then<R>(FutureOr<R> onValue(T value), {Function onError}) {
    return _then(
        Zone.current.bindUnaryCallback(onValue),
        onError != null
            // Note: real impl must also support an `onError` callback that 
            // takes a StackTrace as the second argument.
            ? Zone.current.bindUnaryCallback(onError as dynamic)
            : null);
  }
  // [...]
}

class _Future<T> implements Future<T> {
  // [...]

  // Note: in reality this could be injected by the compiler on any class
  // implementing Future<T> if we want them to be Promise-like.
  @JSExport('then')
  JSPromise<R> _jsThen<R>(
    /*R | Thenable<R>*/Object Function(T) onFulfilled,
    [/*R | Thenable<R>*/Object Function(Object) onRejected]) {

    Future<R> f = then((value) => JSPromise.resolve(onFulfilled(value)),
        onError: onRejected != null
            ? (error) => JSPromise.resolve(onRejected(error))
            : null);
    // This conversion is not necessary if we only want to implement Thenable.
    return JSPromise.resolve(f);
  }
}
```


### Iterable<T> and JS Iterable

All Dart `Iterable<T>` classes should implement `[Symbol.iterator]`, which
allows them to be used in JS `for-of` loops.

Converting from a JS iterable to a Dart Iterable requires a conversion
(either implicit or explicit).

Avoiding a conversion is probably not ideal. We'd need `Iterable<T>` methods
on any JS object that contains `[Symbol.iterator]`. This requires compilers to
place `Iterable<T>` members on Object.prototype, or handle this at the
interceptor level. The current theory is that not many JS APIs return
iterables (Arrays are much more common). A wrapper-based conversion, either
implicit or explcit, should be enought to handle this.


### Stream<T> and JS Async Iterable

The EcmaScript draft contains a new feature [for-await-of loops](https://tc39.github.io/ecma262/#sec-for-in-and-for-of-statements)
and `Symbol.asyncIterator` (see also [MDN for-await-of](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/for-await...of)).
Once JS has that, `Stream<T>` could work similarly to `Future<T>`.


### Stream<T> and Callbacks

These will require a conversion in either direction. However we can provide
helpers to make this easy. Consider this example from Firebase:

```dart
class Auth extends JsObjectWrapper<AuthJsImpl> {
  // [...]
  Func0 _onAuthUnsubscribe;
  StreamController<User> _changeController;

  Stream<User> get onAuthStateChanged {
    if (_changeController == null) {
      var nextWrapper = allowInterop((firebase_interop.UserJsImpl user) {
        _changeController.add(User.getInstance(user));
      });

      var errorWrapper = allowInterop((e) => _changeController.addError(e));

      void startListen() {
        assert(_onAuthUnsubscribe == null);
        _onAuthUnsubscribe =
            jsObject.onAuthStateChanged(nextWrapper, errorWrapper);
      }

      void stopListen() {
        _onAuthUnsubscribe();
        _onAuthUnsubscribe = null;
      }

      _changeController = StreamController<User>.broadcast(
          onListen: startListen, onCancel: stopListen, sync: true);
    }
    return _changeController.stream;
  }
}

// [in interop/auth_iterop.dart]
@JS('Auth')
class AuthJsImpl {
  // [...]
  external Func0 onAuthStateChanged(nextOrObserver,
      [Func1 opt_error, Func0 opt_completed]);
}
```

With the right helpers and elimination of wrappers, this becomes:

```dart
@JS()
class Auth {
  @sealed
  Stream<User> _changeStream;

  @JS('onAuthStateChanged')
  external Func0 _onAuthStateChanged(Func1<User, void> nextOrObserver,
      [Func1 opt_error, Func0 opt_completed]);

  @sealed
  Stream<User> get onAuthStateChanged =>
      _changeStream ??= CreateStream(_onAuthStateChanged);
}

// Note: package:js will defined some helpers like this.
// More research is needed to find all of the common patterns.
static Stream<T> CreateStream<T>(
    @JS() Func0 Function(Func1<T, void> nextOrObserver, [Func1 opt_error])
        subscribeToEvent) {
  Func0 unsubscribe;
  StreamController<T> controller;
  controller = StreamController.broadcast(
      onListen: () {
        // Because `subscribeToEvent` is annotated with `@JS()`, `allowInterop`
        // will be automatically handled on these callbacks.
        unsubscribe = subscribeToEvent(controller.add, controller.addError);
      },
      onCancel: unsubscribe,
      sync: true);
  return controller.stream;
}
```


### DateTime and JS Date

Similar to Future/Promise, we can investigate and determine which of these is
best:
- implement DateTime on top of JS Date
- have them implement each other's interfaces
- provide an implicit conversion


### Map/Set and JS Map/Set

At the very least, we'll provide `JSMap<K, V>` and `JSSet<T>` types in
"package:js" that will implement the corresponding Dart interfaces and also be
wrapperless JS Maps/Sets.

Both web compilers already use (or have prototyped use of) ES6 Map/Set under
some circumstances, such as identity Maps/Sets. So it may be possible to have
the objects returned by `HashMap.identity()` and `HashSet.identity()` simply be
JS Map/Set respectively. That would be a nice feature, but is not necessary
to provide good interop with these types.

Declaring a JS API as returning a Dart Map will be a hint, because it will
probably not work the way the developer expects (if they are expecting a JS
object to be interpreted as a Map). Instead they can:
- use `JSMap<K, V>` if they intended the JS Map class.
- use `JSObjectMap<K, V>` if the return value is a JS object. It's a normal Dart
  class that implements Map and is backed by the JS Object. This indicates a
  wrapping conversion.
- use `@JSConvert()` to provide a custom conversion to Map
- use some other JS class type, which declares the properties that the map
  contains. Useful when a JS Object is returned, and the data is structured.

Open question: are the generic type arguments to JSMap/JSSet reified if
allocated in Dart? I think they should be, for consistency with `List<T>`.
Similar to `List<T>` however, a `Map` allocated in JS could be cast to
`JSMap<K, V>` for any types `K` and `V` that subtype `JSAny`.


### Maps and JS Objects

Converting arbitrary Dart maps to JS Objects is probably not feasible, for
reasons discussed in "Data Type Interoperability". However we can provide
a conversion: 

```dart
  external factory RecaptchaVerifier(container,
      [@JSConvert(jsify) Map<String, Object> parameters, App app]);
```

The `jsify` function is declared by Firebase, and does a deep conversion based
on the specific types Firebase APIs use. However most of that will no longer be
necessary, so we might be able to get away with:

```dart
  external factory RecaptchaVerifier(container,
      [@MapToJSObject() Map<String, Object> parameters, App app]);
```

This uses a built-in shallow conversion from a Dart Map to a JS object.


#### Wrapper-based JSObjectMap

To make it easier to work with JS objects via indexing, we could provide several
classes in "package:js" to help:

```dart
@JS()
@anonymous
class JSIndexable<K extends Object, V extends Object> {
  external V operator [](K key);
  external void operator []=(K key, Object value);

  Map<K2, V2> toMap<K2, V2>() => JSObjectMap(this);
}

/// Wraps a JS Object in a Dart Map.
class JSObjectMap<K, V> with MapMixin<K, V> implements Map<K, V> {
  final JSIndexable object;

  JSObjectMap([Object object])
      : object = object as JSIndexable ?? JSIndexable();

  factory JSObjectMap.from(Map other) => JSObjectMap<K, V>()..addAll(other);
  factory JSObjectMap.of(Map<K, V> other) = JSObjectMap.from;
  factory JSObjectMap.fromEntries(Iterable<MapEntry<K, V>> entries) =>
      JSObjectMap<K, V>()..addEntries(entries);

  bool containsKey(Object key) => Reflect.has(object, key);
  V operator [](Object key) => object[key];
  void operator []=(Object key, value) {
    object[key] = value;
  }
  List<K> get keys => Reflect.ownKeys(object) as List<K>;
  V remove(Object key) {
    if (Reflect.has(object, key)) {
      var result = object[key];
      Reflect.deleteProperty(object, key);
      return result;
    }
    return null;
  }
  void clear() {
    for (var key in Reflect.ownKeys(object)) {
      Reflect.deleteProperty(object, key);
    }
  }
}
```

Here `JSObjectMap` works like a normal Dart class, but it's easy to get the
raw JS object from it. Meanwhile any JS object can be cast to `JSIndexable` to
provide access to the index operators and the `toMap()` function.


#### Autoboxing JSObjectMap


*NOTE*: we probably won't want/need this, but I wanted to mention it as a
possible optoon. It provides a means of implementing Dart interfaces from JS
classes, that is reasonably friendly to optimizations.

An alternative design for `JSObjectMap` is to work similarly to `JSIndexable`.
This provides a Map-like view of an arbitrary JS object. Then the question
becomes: how do we cast our type to a `Map<K, V>`? Autoboxing would allow us to
do that.

Here's a rough sketch:

```dart
@JS()
@JSAutobox()
class JSObjectMap<K, V> extends MapBase<K, V> {
  factory JSObjectMap() => _create(null);
  factory JSObjectMap.from(Map other) => _create<K, V>(null)..addAll(other);
  factory JSObjectMap.of(Map<K, V> other) = JSObjectMap.from;
  factory JSObjectMap.fromEntries(Iterable<MapEntry<K, V>> entries) =>
      _create<K, V>(null)..addEntries(entries);

  @JS('create')
  external static JSObjectMap<K2, V2> _create<K2, V2>(Object proto);

  external V operator [](Object key);
  external void operator []=(Object key, Object value);
  
  bool containsKey(Object key) => Reflect.has(this, key);
  List<K> get keys => Reflect.ownKeys(this) as List<K>;

  V remove(Object key) {
    if (Reflect.has(this, key)) {
      var result = this[key];
      Reflect.deleteProperty(this, key);
      return result;
    }
    return null;
  }

  void clear() {
    for (var key in Reflect.ownKeys(this)) {
      Reflect.deleteProperty(this, key);
    }
  }
}
```

Because this type uses `@JSAutobox()`, the JS object will be automatically
boxed when cast to any Dart interface that it implements (except for dart:core
Object). This reduces the boilerplate that might otherwise be required.

The benefit of this approach is that any JS object can be freely cast to
`JSObjectMap`, providing efficient access using Map-like APIs. For example,
let's revist our `UserInfo.toJson()` example:

```dart
@JS()
@anonymous
class UserInfo {
  // [...]
  /// Returns a JSON-serializable representation of this object.
  @JS('toJSON')
  external JSObjectMap<String, dynamic> toJson();
}

// [code snippet from auth_test.dart]

  test('toJson()', () async {
    // [...]
    var userMap = userCredential.user.toJson();
    expect(userMap, isNotNull);
    expect(userMap as Map, isNotEmpty); // [note: `as Map` was added]
    expect(userMap["displayName"], "Other User");
    expect(userMap["photoURL"], "http://google.com");
    // [...]
  });
```

Consider the line `expect(userMap as Map, isNotEmpty)` in this example.
The `as Map` is necessary to trigger boxing, so the `isNotEmpty` matcher will
work.

Autoboxing would be a neat way to provide support for implementing Dart
interfaces from JS. Autoboxing has proven useful in other languages for native
interop. It may be useful for advanced JS interop scenarios, such as providing
a dart:html-like API without JS dynamic/interface dispatch.


## Less Static Interop

### Virtual Dispatch

In many cases JS interop can take advantage of virtual dispatch, even with
`@sealed`, because the JS method it calls will dispatch with normal JS rules
(i.e. lookup the property on the prototype chain). `@sealed` procludes overrides
of itself with another Dart member, however.

We support virtual Dart methods on JS types, with a bit more work. This doesn't
compromise the model very much, but it does add additional dispatch cost.
Implementing interfaces and dynamic dispatch would still be restricted.


### Interface and Dynamic dispatch

In the future, we may want to provide something like `@JSInterfaceDispatch()` or
`@JSDynamicDispatch()`, that preserves RTTI and enables interface/dynamic
dispatch. Our compilers already support this, as they use it themselves for core
types in the SDK, and for the HTML libraries.

There are several issues with exposing this:
- extensions would now have to be globally unique for a given JS prototype.
- this requires compile time checking (dart2js) or runtime checking (dartdevc).
- it's possible to subvert compile time checking accidentally (if the same JS 
  prototype is exposed with two different names).
- we'd need to standardize the annotations between the compilers and ensure
  they have the same semantics.

Scoped extension method approaches for dynamic languages may help for the naming
conflicts (e.g.
[as discussed in this paper](https://arxiv.org/pdf/1708.01679.pdf)),
but those have performance/complexity/usability tradeoffs.

Many users have requested flags to disable dynamic dispatch, so this may not be
the direction we need go. Implementing interfaces can be useful however.
(The "autoboxing" approach discussed previously may be a possible compromise.)


### JS Proxy

One question that comes up occasionally is how to use JS Proxy from Dart.
We can expose JSProxy from "package:js":

```dart
@JS('Proxy')
class JSProxy {
  external factory JSProxy(Object target, JSProxyHadler handler);
}

@JS()
@anonymous
abstract class JSProxyHandler {
  // Note: these are defined as field to allow only a subset of them to be
  // implemented
  @JS()
  Object Function(Object target) getPrototypeOf;

  @JS()
  Object Function(Object target, Object proto) setPrototypeOf;

  // [...]

  @JS()
  bool Function(Object target, Object key) has;

  @JS()
  Object Function(Object target, Object key) get;

  @JS()
  Object Function(Object target, Object key, Object value) set;

  @JS()
  bool Function(Object target, Object key) deleteProperty;

  external factory JSProxyHandler({
      this.getPrototypeOf,
      this.setPrototypeOf,
      this.get,
      this.set,
      this.has,
      this.deleteProperty /* [...] */});
}
```

It's possible to implement a proxy handler that forwards to Dart's
noSuchMethod, or the reverse, if someone wanted to do that.

(It's also possible to have a noSuchMethod that uses JS Reflect and Object APIs
to access the JS object. It's not necessary though, because `@JS()` classes are
essentially a more optimized form of that.)


### JS Reflection

JS Reflection APIs are useful for low level support, and these can be provided
by "package:js":

```dart
@JS('Reflect')
class JSReflect {
  external static Object apply(target, thisArgument, argumentsList);
  external static Object construct(target, argumentsList, [newTarget]);
  external static bool defineProperty(
      target, propertyKey, PropertyDescriptor attributes);
  external static bool deleteProperty(target, propertyKey, [receiver]);
  external static Object get(target, propertyKey);
  external static PropertyDescriptor getOwnPropertyDescriptor(
      target, propertyKey);
  external static Object getPrototypeOf(target);
  external static bool has(target, propertyKey);
  external static bool isExtensible(target);
  external static List<Object> ownKeys(target);
  external static void preventExtensions();
  external static set(target, propertyKey, value, [receiver]);
  external static setPrototypeOf(target, prototype);

  static bool hasOwnProperty(target, propertyKey) {
    // Note: could also be implemented using `getOwnPropertyDescriptor`
    return _JSObject.prototype.hasOwnProperty(target, propertyKey);
  }

  static Object getOwnProperty(target, propertyKey) {
    var desc = getOwnPropertyDescriptor(target, propertyKey);
    if (desc == null) return null;
    if (desc.get != null) return desc.get(target);
    return desc.value;
  }
}

@JS('Object')
abstract class _JSObject {
  external static _JSObjectPrototype prototype;
}

@JS()
@anonymous
abstract class _JSObjectPrototype {
  external static bool hasOwnProperty(@JSThis() target, propertyKey);
}

@JS()
@anonymous
class PropertyDescriptor {
  Object value;
  bool writable;
  bool configurable;
  bool enumerable;
  Object Function(@JSThis() Object) get;
  void Function(@JSThis() Object, Object) set;
}
```


## Exporting Dart to JS

Dart functions and accessors can be exported to JS with `@JSExport`. A compiler
must provide a version of the function that is callable via the JS interop
calling conventions described earlier, and ensure that version of the function
is used when it is passed to JavaScript. (It may have other versions of the
function that use optimized, dart-specific calling conventions.)


### Exporting classes and libraries

This will use `@JSExport` similar to top-level functions/accessors.

TODO: more details here

### Inheritance between Dart and JS

Conceptually extending a JS class from Dart is similar to adding methods,
because `super` calls are statically dispatched. The tricky part is what to do
with constructors. JS constructors are normally written as `external factory`
which precludes extending them. Also there are some notable differences in
field initialization+super constructor call order between Dart and JS.

(JS requires super before initializing fields, Dart requires super after
initializing final fields. Dart's approach is nice because it prevents
virtual methods from observing uninitialized state. But for interop, the problem
is that the two orders are incompatible.)

We may be able to provide a method that creates your class:

```dart
class MyDartClass extends TheirJSClass {
  final int x = 1;
  int y, z;
  factory MyDartClass(int y, int z) {
    // super constructor parameters passed here?
    var self = createJS<MyDartClass>(); 
    self.y = y;
    self.z = z;
    return self;
  }
  // ...
}
```

It's not the most satisfying solution, but it seems like a relatively easy way
to support this.

TODO: extending a Dart class from JS


### Interop with JS Modules

We'll need a way to declare a JS interop library corresponds to a JS module.
This could be done on the library tag:

```dart
@JSImport('goog.editor', moduleFormat: 'closure')
library goog.editor;
```

The compiler can then generate the appropriate import, instead of a global
reference. This will need to be coordinated with the overall build and server
system, however, to ensure the JS module is available to the module loader
(requirejs, ES6 imports, etc).

Typically the module format will be assumed to be passed in globally to the
compiler, as there is generally one standardized module format, so that argument
won't be present. (Closure library is illustrated here as it can be used in
addition to other formats, it may be useful to tell the compiler "this module
is definitely a closure namespace, import it as such".)


### Exposing JS Methods as Getters

One common pattern that comes up is converting "getX" methods into "get X"
getters. We could add `@JSMethod` syntactic sugar to simplify that.
Consider this prior example of a Google Maps API:

```dart
  LatLng get center => _getCenter();
  LatLng get northEast => _getNorthEast();
  LatLng get southWest => _getSouthWest();
  bool get isEmpty => _isEmpty();

  @JS('getCenter')
  external LatLng _getCenter();
  @JS('getNorthEast')
  external LatLng _getNorthEast();
  @JS('getSouthWest')
  external LatLng _getSouthWest();
  @JS('isEmpty')
  external bool _isEmpty();
```

It could be written as:

```dart
  @JSMethod('getCenter')
  external LatLng get center;

  @JSMethod('getNorthEast')
  external LatLng get northEast;

  @JSMethod('getSouthWest')
  external LatLng get southWest;

  @JSMethod('isEmpty')
  external bool get isEmpty;
```

## JS Types in the Dart Type System

As discussed earlier, at runtime the absence of reified type information will be
tracked with a `JSAny` type. `JSAny` can contain types that may originate from
JS, and it only exists at run time. Here are some examples:

```dart
import 'package:firebase/firebase.dart' show App, Database;
import 'package:firebase/firebase.dart' as firebase;
main() {
  List apps = firebase.apps;
  apps is List<Object>      // true: Object can hold JS types
  apps is List<int>         // true: `int` could be from JS
  apps is List<List>        // true: `List` could be from JS
  apps is List<Database>    // true: could be a list of any JS interop types
  apps is List<MyDartClass> // false: can't be a Dart class
  apps is List<Stopwatch>   // false: can't be a Dart class like Stopwatch
}
```

We'll probably want to provide access to JS `typeof` and `instanceof` as library
functions in "package:js".

The proposed typing rules for JSAny allow it assigned to/from these types:
- primitives: Null | bool | int | num | double | String
- JS interop classes (`@JS()`)
- Dart classes exported to JS (`@JSExport()`)
- `List<JSAny>`
- other "native" SDK types
- functions (restrict to JSAny param/return types?)

This type will not exist in the static type system. The hope is that these
restrictions keep the unsoundness restricted to objects allocated from JS, and
to types that are likely to be used by existing JS APIs. By excluding Dart
classes, we're able to catch things like `List<JSAny>` assigned to
`List<MyDartClass>`, which is unlikely to work.

Open question: should preserve reified JSAny if that type parameter is used to
construct other types? For example:

```dart
@JS()
external List foo();
bar() {
  var list = foo();
  var set = list.toSet() as Set<int>; // does this work?
  // ...
}
```


## Implementation Roadmap

Here's a rough breakdown of the features into different categories.
Details subject to change. The items are not in any particular order.

Required features (P0):
- static dispatch (with rename support)
- static type checking rules (warnings/errors for incorrect usage)
- runtime type checking rules
- conversions for builtin types:
  - Functions
  - Dart Map to/from JS Object
  - Future/Promise
- calling conventions for optional arguments, "this"
- exporting top-level functions, accessors to JS

Important features (P1):
- user defined conversions
- conversions for types (e.g. DateTime, Iterables)
- named arguments
- exporting classes/members to JS
- package:js helper library
  - common conversion functions, e.g. jsify/dartify
  - predefined interop for core JS types like Set/Map
- extension fields

Nice to have features (P2):
- helpers for common callback-to-stream patterns
- other helpers like `@JSMethod`
- autoboxing to implement Dart interfaces(?)

Features for building "package:html" (P2?):
- virtual dispatch for JS classes
- subtyping Dart classes from JS
- subtyping JS classes from Dart
- interface dispatch for JS classes (useful for migrating to package:html)
- dynamic dispatch for JS classes (useful for migrating to package:html)


## Compatibility and Evolution

Most of the features described here are backwards compatible, relative to the
set of JS interop supported by both web compilers.

One question that came up is interfaces: currently JS interop classes can be
implemented by Dart classes (although this may lead to inconsistent behavior
between the compilers). If `@sealed` Dart members are added to a JS interop
class, then it won't be legal to implement that as an interface. But this is a
new feature, so it's only "breaking" in the sense that adding `@sealed` members
is a breaking change for the package API. (Technically: adding *any* public
member to a Dart class is a breaking change, for this reason. In practice many
types are not intended to be used as interfaces, so they don't treat new members
as breaking).

If we discover something that is too backwards incompatible, we can add new
annotations and leave the current behavior for the existing ones. Or we can
bump the major version on "package:js". There's a lot of possibilities.


## FAQ

### Q: How does JSON work?

A: If the JSON is relatively typed, then it can be 


### Q: Would new Dart language features help?

A: Yes! All of these features would be helpful:
- extension methods/members
- extension types
- implicit conversions
- autoboxing
- non-null
- generalized typedefs
- `external` on fields (sugar for external getter/setter)

In the meantime, this proposal provides a way to improve interop, and is
intended to be compatible with those features.


### Q: Can dart2js and dartdevc share implementation for JS interop?

A: Probably, especially for the static features.

If both compilers are exclusively using Kernel, much of this can
be implemented as a Kernel transform. The static checking can also be done in
a shared way.

Dynamic dispatch, calling conventions, and runtime type checks, and native SDK
types are different between the two compilers, so those details would require
separete work.


### Q: If a JS API returns "Object" does this break dart2js tree shaking?

A: It does not. Dart classes can be tree-shaken, unless they're explicitly
exported to JS. Static dispatch members can be tree shaken. Static JS Interop
types, by design, do not require any runtime type information (RTTI).
Opt-in features like interface or dynamic dispatch will cause more RTTI to be
retained.

This question may be referring to "dart:html". It supports dynamic dispatch, and
this causes RTTI to be retained, unless great care is taken on the part
of dart:html authors (to carefully annotate return types, and avoid untyped
results) and by developers (to carefully avoid dynamic calls that use names in
"dart:html", and to avoid JS interop features that could return HTML elements).

We may be able to find a better solution, such a providing new "package:html"
bindings that are mostly static (and using interface/dynamic dispatch sparingly,
in places where it's really needed).


### Q: Could we use dynamic interop instead?

A: It's certainly possible to imagine interop that works "like JS"
(example from Closure Library's
[goog.editor Example](https://github.com/google/closure-library/blob/master/closure/goog/demos/editor/editor.html#L84)):

```dart
// Hypothetical dynamic interop
dynamic goog = window.goog;
dynamic myField = goog.editor.Field.new('editMe');

// Create and register all of the editing plugins you want to use.
myField.registerPlugin(goog.editor.plugins.BasicTextFormatter.new());
```

The problem is it'll run into the same issues around data type conversions, but
it won't be able to address them without wrapper classes. As illustrated by the
".new" it will never be as simple as copying and pasting JS code, and there
won't be any tooling to help.

What we may want to do is provide a way to write small chunk of JS code (in a
Dart file), similar to GWT. But that shouldn't be used much, with the
improvements in this proposal to calling conventions and easy ways to access
properties on JS objects.
