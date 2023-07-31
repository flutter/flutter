## 20.0.1

* Fix proto3 repeated field encoding without the `packed` option ([#345],
  [#635])

[#345]: https://github.com/google/protobuf.dart/issues/345
[#635]: https://github.com/google/protobuf.dart/pull/635

## 20.0.0

* Stable release generating null-safe code.

## 19.3.1

* Emit binary coded descriptors, which can be used to reflect over the options
  given to the descriptor.

## 19.3.0

* Generate constructors with optional named arguments for prefilling fields.
* Output language version 2.7 in generated files to support extension methods.

## 19.2.1

* Support optional proto3 fields.

## 19.2.0+1

* Fix syntax error introduced by gRPC client interceptor changes.

## 19.2.0

* Support client interceptors for gRPC. Requires grpc package 2.8.0 or newer.

## 19.1.0

* Emit depreciation of generated `copyWith` and `clone` methods.
* Emit exports of `GeneratedMessageGenericExtensions` from `pb.dart` files.
* Make protobuf enum names dependent on a fromEnvironment constant.

  This will allow configuring the omission of the names in the final build.

  If a target is built with `dart_env = {"protobuf.omit_enum_names": "true"}`
  enum names will not be present in the compiled binary.
* Make message and field names dependenc on a fromEnvironment constants
  `protobuf.omit_message_names` and `protobuf.omit_field_names` respectively.
* Omit type on a left hand side of generated static fields for extensions,
  which results in stricter type (`Extension<ExtensionType>` instead of just
  `Extension`).
* Fix escaping of string default values.

## 19.0.3-dev

* Ignore `annotate_overrides` in generated files.
* Requires sdk 2.3.0
* Update pedantic to 1.9.2

## 19.0.2

* Fix: escape the special character `$` in descriptor's `json_name`.

## 19.0.1

* Fix: avoid naming collisions with `Int64` and enum names beginning with digits
  after an initial underscore.

## 19.0.0+1
* Updated protobuf dependency to '>=0.14.4 <2.0.0' to allow 1.0.0.

## 19.0.0
* Breaking: Generates code that requires at least `protobuf` 0.14.4.
  If protoc_plugin is installed in your path with `pub global activate` you can upgrade with `pub global activate protoc_plugin 19.0.0`
  - GeneratedMessage classes now have methods `ensureX` for each message field X.
  - Add specialized getters for `String`, `int`, and `bool` with usual default values.
  - Annotate generated accessors with the tag number of the associated field.
* Breaking: Use unmangled names for the string representation of enum values.
  Mangled names would lead to wrong proto3 json en- and decoding.
* Annotate generated accessors with the tag number of the associated field.

## 18.0.3

* Fix: Allow decoding tagnumbers of up to 29 bits. Would fail before with more than 28 bits.

## 18.0.2

* Fix mangling of extension names, message type names, and enum names that are Dart keywords.

  Now you can have an extension called `is` and an enum called `class`.

## 18.0.1

* Add a `bin/protoc-gen-dart.bat` script making it easier to compile on windows using a local
  checkout.

## 18.0.0

* Breaking: Generates code that requires at least `protobuf` 0.14.0.

* Generate the non-camel-case name of fields when it cannot be derived from the json name.

* Breaking: Use the correct proto3 Json CamelCase names for the string representation of field
  names (also for extensions), instead of using the name of the dart identifier for that field.

  In most cases this name coincides with the name have emitted until now and require no change.

  Exceptions are:
    - Fields with a name that was disambiguated to not clash with other dart entities.
    - fields with an explicit `json_name` option.
    - groups have a different camel-casing scheme.

  For any field with an updated name, this might require changes to uses of
  `GeneratedMessage.getTagNumber(String FieldName)`, and calls to name-related methods of
  `GeneratedMessage._info`.

  `GeneratedMessage.toString()` also uses the string representation. It will now print the
  json-name.

* Well-known types (for now only `google.protobuf.Any` and `google.protobuf.Timestamp`) now uses a
  mixin to add special handling code instead of hardcoding it in the compiler.

## 17.0.5

* Remove unnecessary cast from generated grpc stubs.

## 17.0.4

* Output [language versioning](https://github.com/dart-lang/language/blob/7eeb67b0d29b696b3c3ec8f9fe322334a2d5d87a/accepted/future-releases/language-versioning/feature-specification.md)
  headers in generated code. This prepares for forward compatibility with
  [NNBD](https://github.com/dart-lang/language/blob/7eeb67b0d29b696b3c3ec8f9fe322334a2d5d87a/accepted/future-releases/nnbd/feature-specification.md).

## 17.0.3

* Fix: Copy oneof state when doing `GeneratedMessage.copyWith()`.

## 17.0.2

* Fix: Avoiding `argument_type_not_assignable` and `return_of_invalid_type lint warnings`.

## 17.0.1

* Fix: Actually use prefixed imports from .pbserver, .pb.json, .pbgrpc files.

## 17.0.0

* Breaking change: seal protobuf message classes by using an internal
  private constructor and changing the rest to factories.

## 16.0.7

* Always prefix .pb.dart imports in .pbserver, .pb.json, .pbgrpc files.

## 16.0.6

* Track the original order of proto fields and include it in metadata
  to ensure the correct fields are being referenced.

## 16.0.5

* Fix generation of invalid Dart code for oneof enums
  by adding list of reserved enum names.

## 16.0.4

* Generate '@Deprecated' annotations on fields that have been deprecated in the
  corresponding .proto file.

## 16.0.3

* Sync Kythe metadata updates from internal repo:
* Remove the extra 1 (field name) from generated field paths,
  so they refer to the whole field rather than the name.
* Add missing proto message field metadata to the Dart proto generator
  (attached to setter/getter/has/clear methods). Fix a bug with indented space counting,
  which would cause all indented fields to use the incorrect count (off by the size of the indent)
* Add metadata to the unnamed constructors in the generated dart proto files.
  Removed extra list copy constructor calls when the field path isn't being modified.
  The named constructors (e.g. fromJson) don't need this because, at the call site,
  the class name and the constructor name are two separate links.

## 16.0.2

* Generated files now import 'dart:core' with a prefix
* Add 'camel_case_types' to analysis_options and add it in the 'ignore_for_file' header of the generated files.

## 16.0.1

* Add `DateTime` conversion methods to `google.protobuf.Timestamp`.

## 16.0.0

* Add ability to generate Kythe metadata files via the
  `generate_kythe_info` option.
* Breaking change: Remove the '$checkItem' function from generated message classes and use the new method 'pc' on
  'BuilderInfo' to add repeated composite fields.
  Generated files require package:protobuf version 0.13.4 or newer.
* Breaking change: The generated `*.pbgrpc.dart` files now import `package:grpc/service_api.dart`
  instead of `package:grpc/grpc.dart`.
  Generated code needs at least package:grpc 1.0.1.

## 15.0.3

* Add test for frozen messages with unknown fields and update protobuf dependency to 0.13.1.

## 15.0.2

* The generated `pbgrpc.dart` files now import `package:grpc/grpc.dart` with a prefix.

## 15.0.1

* Add test for frozen messages with extension fields and update protobuf dependency to 0.13.0.

## 15.0.0

*  Breaking change: Changed BuilderInfo call for map fields to include the BuilderInfo object for map entries.
   Generated files require package:protobuf version 0.12.0 or newer.

## 14.0.1

* Remove the benchmark from the protoc_package. It now lives in
  [https://github.com/google/protobuf.dart] as `api_benchmark`.
  This simplifies the dev_dependencies of this package.

## 14.0.0

* Breaking change: generated message classes now have a new instance method `createEmptyInstance`
  that is used to support the new `toBuilder()` semantics of protobuf 0.11.0.
  The generated code requires at least protobuf 0.11.0.

## 13.0.1

* Add test for recursive merging and update protobuf dependency to 0.10.7.

## 13.0.0

* Breaking change: Support for [oneof](https://developers.google.com/protocol-buffers/docs/proto3#oneof)
  Generated files require package:protobuf version 0.10.6 or newer.

## 12.0.0

* Breaking change: Handle identifiers starting with a leading underscore.
  This covers message names, enum names, enum value identifiers and file names.

  Before, these would appear in the generated Dart code as private identifiers.
  Now the underscore is moved to the end.

  Field names and extension field names already had all underscores removed, and these are not
  affected by this change.

  If there is a conflicting name with a trailing underscore defined later in the same scope, a
  disambiguation will happen that can potentially lead to existing identifiers getting a new name in
  the generated Dart.

  For example:

  ```
  message _Foo {}
  message Foo_ {}
  ```

  `_Foo` will get the name `Foo_` and `Foo_` will now end up being called `Foo__`.

## 11.0.0

* Breaking change: Support for [map fields](https://developers.google.com/protocol-buffers/docs/proto3#maps)
  Generated files require package:protobuf version 0.10.5 or newer.
  Protobuf map fields such as:

  message Foo {
    map<int32, string> map_field = 1;
  }
  are now no longer represented as List<Foo_MapFieldEntry> but as Map<int, String>.

  All code handling these fields needs to be updated.

  Accidentally published as 11.0.0 instead of 0.11.0. Continuing from here.

## 0.10.5

* Generated files now import `dart:async` with a prefix to prevent name
  collisions.

## 0.10.4

* Change the fully qualified message name of generated messages to use
  `BuilderInfo.qualifiedMessageName`.
  Requires package:protobuf version 0.10.4 or newer.

## 0.10.3

* Remove runtime `as` check of enum `valueOf` by using correctly typed `Map` of
  values.
  Generated files must require package:protobuf version 0.10.3 or newer.

## 0.10.2

* Add link to source file in generated code.

## 0.10.1

* Prefix generated Dart proto imports by proto file path instead of by package.
  Tighten up member name checks for generated enum classes.

## 0.10.0

* Breaking change: Support for [any](https://developers.google.com/protocol-buffers/docs/proto3#any) messages.
  Generated files require package:protobuf version 0.10.1 or newer.
  `BuilderInfo.messageName` will now be the fully qualified name for generated messages.

## 0.9.0

* Breaking change: Add `copyWith()` to message classes and update `getDefault()` to use `freeze()`.
  Requires package:protobuf version 0.10.0 or newer.

## 0.8.2

* Generated code now imports 'package:protobuf/protobuf.dart' prefixed.
  This avoids name clashes between user defined message names and the protobuf library.

## 0.8.1

* Adjust dependencies to actually be compatible with Dart 2.0 stable.

## 0.8.0+1

* Dart SDK upper constraint raised to declare compatibility with Dart 2.0 stable.

## 0.8.0

* Breaking change: Generated RpcClient stubs use the generic invoke method.
  Requires package:protobuf version 0.8.0 or newer.
* Dart 2 fixes.

## 0.7.11

* Dart 2 fix.

## 0.7.10

* Small performance tweak for DDC.

## 0.7.9

* Add fast getters for common types.
* Only pass index instead of tag and index in generated code.
* Fix uses-dynamic-as-bottom error in generated gRPC code.

## 0.7.8

* Added enumValues to FieldInfo.

## 0.7.7

* Avoid name clashes between import prefix and field names.
* Avoid name clashes between generated enum and extension class names.
* Updated gRPC client stub generation to match latest changes to dart-lang/grpc-dart.

## 0.7.6

* Updated gRPC client stub generation to produce code matching latest changes to
  dart-lang/grpc-dart.

## 0.7.5

* Use real generic syntax instead of comment-based.
* Support 2.0.0 dev SDKs.

## 0.7.4

* Added call options to gRPC client stubs.

## 0.7.3

### gRPC support

* Added gRPC stub generation.
* Updated descriptor.proto from google/protobuf v3.3.0.

## 0.7.2

* Added CHANGELOG.md

## 0.7.1

* Enable executable for `pub global` usage. Protoc plugin can now be installed by running `pub global activate protoc_plugin`.
* Ensure generated extension class names don't conflict with message class names.
* `Function` will soon be a reserved keyword, so don't generate classes with that name.
* Strong mode tweaks and lint fixes.

## 0.7.0 - Not released

* Change how to customize the Dart name of a field to using a `dart_name` option.
* Implemented support for adding external mixins to generate Dart protos.

## 0.6.0+1 - Not released

* Fix missing import when an extension uses an enum in the same .proto file.

## 0.6.0 - Not released

* Move protobuf enums to a separate .pbenum.dart file.
* Move server-side stubs to .pbserver.dart.

## 0.5.2 - Not released

* Generate separate .pbjson.dart files for constants.

## 0.5.1

### Strong mode and Bazel

* Fixed all analyzer diagnostics in strong mode.
* Added experimental support for Bazel.

## 0.5.0

### Performance improvements

This release requires 0.5.0 of the protobuf library.

* significantly improved performance for getters, setters, and hazzers
* Each enum type now has a $json constant that contains its metadata.

## 0.4.1

### Fixed imports, $checkItem, $json

* Fixed all warnings, including in generated code.
* Started generating $checkItem function for verifying the values of repeated fields
* Fixed service stubs to work when a message is in a different package
* Started generating JSON constants to get the original descriptor data for services

## 0.4.0

### Getters for message fields changed

This release changes how getters work for message fields, to detect a common mistake.

Previously, the protobuf API didn't report any error for an incorrect usage of setters. For example, if field "foo" is a message field of type Foo, this code would silently have no effect:

var msg = new SomeMessage();
msg.foo.bar = 123;
This is because "msg.foo" would call "new Foo()" and return it without saving it.

The example can be fixed like this:

var msg = new SomeMessage();
msg.foo = new Foo();
msg.foo.bar = 123;
Or equivalently:

var msg = new SomeMessage()
   ..foo = (new Foo()..bar = 123);
Starting in 0.4.0, the default value of "msg.foo" is an immutable instance of Foo. You can read
the default value of a field the same as before, but writes will throw UnsupportedError.

## 0.3.11

* Fixes issues with reserved names

## 0.3.10

* Adds support for generating stubs from service definitions.

## 0.3.9

* Modify dart_options support so that it supports alternate mixins.
* Move the experimental map implementation to PbMapMixin

For now, new mixins can only be added using a patch:

* add the new class to the protobuf library
* add the class to the list in mixin.dart.

## 0.3.8

### Added option for experimental map API

* Changed the Map API so that operator [] and operator []= support dotted keys such as "foo.bar".

This new API is subject to change without notice, but if you want to try it out anyway, see the unit test.

## 0.3.7 - Unreleased

### Added option for experimental map API

* Added an option to have GeneratedMessage subclasses implement Map.

## 0.3.6

### Added writeToJsonMap and mergeFromJsonMap to reservedNames

The 0.3.6 version of the dart-protobuf library added two new functions, so this release changes the protobuf compiler to avoid using them.

## 0.3.5

Protobuf changes for smaller dart2js code, Int64 fixes

This change is paired with https://chromiumcodereview.appspot.com/814213003

Reduces code size for one app by 0.9%

1. Allow constants for the default value to avoid many trivial closures.
2. Generate and use static M.create() and M.createRepeated() methods on message classes M to ensure there is a shared copy of these closures rather than one copy per use.
3. Parse Int64 values rather than generate from 'int' to ensure no truncation errors in JavaScript.

## 0.3.4

Parameterize uri resolution and parsing of options, use package:path.

This helps make the compiler more configurable
to embed it in other systems (like pub transformers)

## 0.3.3

Update the version number
