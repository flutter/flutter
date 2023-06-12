## 2.1.0

* Update READMEs of `protobuf` and `protoc_plugin`:
  * Use `dart pub` instead of `pub` in command examples ([a7e75cb])
  * Fix typos, clarify installation instructions, mention native compilation,
    fix proto syntax for `protoc_plugin` ([#610], [#617], [#641])
* Update some of the documentation according to Effective Dart documentation
  guide ([#664], [#674])
* Improve runtime perf by removing some of the runtime type checks ([#574],
  [#573])
* Fix a bug when converting negative `Timestamp` to Dart `DateTime` ([#580],
  [#577])
* Document `BuilderInfo` and `FieldInfo` properties ([#597])
* Improve `BuilderInfo` initialization by doing some of the work lazily
  ([#606])
* Improve enum hash code generation ([#556])
* Fix parsing nested `Any` messages from JSON ([#568])
* Improve message hash code generation performance ([#554], [#633])
* Fix reading uninitialized map fields changing equality and hash code of
  messages. ([#638])
* Fix setting an extension field when there's an unknown field with the same
  tag. ([#639])
* Fix sharing backing memory for `repeated bytes` and `optional bytes` fields.
  ([#640])
* `GeneratedMessage.rebuild` now generates a warning when the return value is
  not used. ([#631])
* Fix hash code of messages with empty unknown field set ([#648])
* Show field tags with `protobuf.omit_field_names`, enum value tags with
  `protobuf.omit_enum_names` in debug strings (`toString` methods) ([#649])
* `TimestampMixin.toDateTime` now takes an optional named `bool` argument
  `toLocal` (defaults to `false`) for generating a `DateTime` in the local time
  zone (instead of UTC). ([#653])
* Fix serialization of `infinity` and `nan` doubles in JSON serializers
  ([#652])
* Fix Dart generation for fields starting with underscore ([#651])
* Fix proto3 JSON deserialization of fixed32 fields ([#655])
* Fix uninitialized repeated field values runtime types for frozen messages
  ([#654])

[a7e75cb]: https://github.com/google/protobuf.dart/commit/a7e75cb
[#610]: https://github.com/google/protobuf.dart/pull/610
[#617]: https://github.com/google/protobuf.dart/pull/617
[#574]: https://github.com/google/protobuf.dart/pull/574
[#573]: https://github.com/google/protobuf.dart/issues/573
[#580]: https://github.com/google/protobuf.dart/pull/580
[#577]: https://github.com/google/protobuf.dart/issues/577
[#597]: https://github.com/google/protobuf.dart/pull/597
[#606]: https://github.com/google/protobuf.dart/pull/606
[#556]: https://github.com/google/protobuf.dart/pull/556
[#568]: https://github.com/google/protobuf.dart/pull/568
[#554]: https://github.com/google/protobuf.dart/pull/554
[#633]: https://github.com/google/protobuf.dart/pull/633
[#638]: https://github.com/google/protobuf.dart/pull/638
[#639]: https://github.com/google/protobuf.dart/pull/639
[#640]: https://github.com/google/protobuf.dart/pull/640
[#641]: https://github.com/google/protobuf.dart/pull/641
[#631]: https://github.com/google/protobuf.dart/pull/631
[#648]: https://github.com/google/protobuf.dart/pull/648
[#649]: https://github.com/google/protobuf.dart/pull/649
[#653]: https://github.com/google/protobuf.dart/pull/653
[#652]: https://github.com/google/protobuf.dart/pull/652
[#651]: https://github.com/google/protobuf.dart/pull/651
[#655]: https://github.com/google/protobuf.dart/pull/655
[#654]: https://github.com/google/protobuf.dart/pull/654
[#664]: https://github.com/google/protobuf.dart/pull/664
[#674]: https://github.com/google/protobuf.dart/pull/674

## 2.0.1

* Fix bug of parsing map-values with default values.
* Merge fixes from version `1.1.2` - `1.1.4` into v2.

## 2.0.0

* Stable null safety release.

## 1.1.4

*   Fix comparison of empty lists from frozen messages.
*   Switch repo internals to use `dart format` instead of `dartfmt`.

## 1.1.3

*   Fix that fixed32 int could be negative.

## 1.1.2

*   Fix proto deserialization issue for repeated and map enum value fields where
    the enum value is unknown.

## 1.1.1

*   Fix decoding of `oneof` fields from proto3 json. The 'whichFoo' state would
    not be set.
*   Fix the return type of `copyWith`.

## 1.1.0

*   Require at least Dart SDK 2.7.0 to enable usage of extension methods.
*   Introduce extension methods `GeneratedMessage.rebuild` and
    `GeneratedMessage.deepCopy` replacing `copyWith` and `clone`. Using these
    alternatives can result in smaller binaries, because it is defined once
    instead of once per class. Use `protoc_plugin` from 19.1.0 to generate
    deprecation warnings for `copyWith` and `clone` methods.
*   `GeneratedMessage.getExtension` throws when reading trying to read an
    extension that is present in the unknown fields. We consider this change a
    bug-fix because depending on the old behavior is indicative of a bug in your
    program.

## 1.0.4

*   Requires sdk 2.3.0
*   Update pedantic to 1.9.2

## 1.0.3

*   Enable hashCode memoization for frozen protos.
*   Add `timeout` to `ClientContext`

## 1.0.2

*   Fix hashcode of bytes fields.
*   Fix issue with the `permissiveEnums` option to `mergeFromProto3Json`. The
    comparison did not work properly.
*   Fix binary representation of negative int32 values.

## 1.0.1

*   Fix issue with `ExtensionRegistry.reparseMessage` not handling map fields
    with scalar value types correctly.
*   Fix issue with the non-json name of a field (`protoName`) not being set
    correctly.
*   Fix: Allow decoding tagnumbers of unknown fields of up to 29 bits.

## 1.0.0

*   Graduate package to 1.0. No functional changes.

## 0.14.4

*   Add `permissiveEnums` option to `mergeFromProto3Json`. It will do a
    case-insensitive matching of enum values ignoring `-` and `_`.
*   Add support for 'ensureX' methods generated by `protoc_plugin` 19.0.0.
*   Add specialized getters for `String`, `int`, and `bool` with usual default
    values.
*   Shrink dart2js generated code for `getDefault()`.
*   Added an annotation class `TagNumber`. This is used by code generated by
    `protoc_plugin` from version 19.0.0.

## 0.14.3

*   Fix: Allow decoding tagnumbers of up to 29 bits. Would fail before with more
    than 28 bits.

## 0.14.2

*   Expose `mapEntryBuilderInfo` in `MapFieldInfo`.

## 0.14.1

*   Support for `import public`.

    The generated code for a protofile `a.proto` that `import public "b.proto"`
    will export the generated code for `b.proto`.

    See
    https://developers.google.com/protocol-buffers/docs/proto#importing-definitions.

## 0.14.0

*   Support for proto3 json (json with field names as keys)

    -   encoding and decoding.
    -   Support for well-known types.
    -   Use `GeneratedMessage.toProto3Json()` to encode and
        `GeneratedMessage.mergeFromProto3Json(json)` to decode.

*   `FieldInfo` objects have a new getter `.protoName` that gives the
    non-camel-case name of the field as in the `.proto`-file.

*   **Breaking**: The field-adder methods on `BuilderInfo` now takes only named
    optional arguments. To migrate, update `protoc_plugin` to version 18.0.0 or
    higher.

*   The field-adder methods on `BuilderInfo` all take a new argument
    `protoName`.

*   **Breaking**: Changed `ExtensionRegistry.reparseMessage` to reparse
    extensions deeply, that is it looks at every nested message and tries to
    reparse extensions from its unknown fields.

## 0.13.16+1

*   Reverts `0.13.16` which accidentally introduced a breaking change,
    [#284](https://github.com/google/protobuf.dart/issues/284). This release is
    identical to `0.13.15`.

## 0.13.16

*   Better handling of dummy calls to `BuilderInfo.add` with a tag number of 0.
    These would trigger assertions before.

## 0.13.15

*   Add new getter `GeneratedMessage.isFrozen` to query if the message has been
    frozen.

## 0.13.14

*   Avoid needless copy when reading from a Uint8List buffer.

## 0.13.13

*   `Added`ExtensionRegistry.reparseMessage()` for decoding extensions from
    unknown fields after the initial decoding.

## 0.13.12

*   `BuilderInfo.add` now ignores fields with tag number 0. These would never be
    generated by the protoc_plugin so this is not considered a breaking change.

## 0.13.11

*   Save memory by only initializing `_FieldSet.oneofCases` if the message
    contains oneofs.

## 0.13.10

*   Fix recursive merging of repeated elements.

## 0.13.9

*   Move 'eventPlugin' callback when setting a field in order to notify
    observers about field updates in the correct order.

## 0.13.8

*   Fix JSON serialization of unsigned 64-bit fields.

## 0.13.7

*   Override `operator ==` and `hashCode` in `PbMap` so that two `PbMap`s are
    equal if they have equal key/value pairs.

## 0.13.6

*   Fixed equality check between messages with and without extensions.

## 0.13.5

*   Add new method `addAll` on ExtensionRegistry for more conveniently adding
    multiple extensions at once.

## 0.13.4

*   Add new method `pc` on BuilderInfo for adding repeated composite fields and
    remove redundant type check on items added to a PbList.

    Deprecated `BuilderInfo.pp` and `PbList.forFieldType`.

## 0.13.3

*   Fix issue with parsing map field entries. The values for two different keys
    would sometimes be merged.

*   Deprecated `PBMap.add`.

## 0.13.2

*   Include extension fields in GeneratedMessage.toString().

## 0.13.1

*   Fix issue with not being able to read unknown fields after freezing.

Reading an unknown field set after freeze() now returns the existing field set
before freezing instead of an empty UnknownFieldSet.

## 0.13.0

*   Breaking change: Fix issue with not being able to read extensions after
    freezing.

Reading an extension field after freeze() now returns the value set before
freezing instead of the default value.

## 0.12.0

*   Breaking change: Changed `BuilderInfo.m()` to take class and package name of
    the protobuf message representing the map entry. Also changed
    `BuilderInfo.addMapField` as well as the constructors `PbMap` and
    `MapFieldInfo.map` to take a map entry BuilderInfo object.

    This mostly affects generated code, which should now be built with
    protoc_plugin 15.0.0 or newer.

    With this change we avoid creating a map entry BuilderInfo object for each
    PbMap instance, instead it is passed through the static BuilderInfo object
    in the generated subclasses of GeneratedMessage.

## 0.11.0

*   Breaking change: changed semantics of `GeneratedMessage.toBuilder()` to only
    make a shallow copy.

    `GeneratedMessage` has a new abstract method: `createEmptyInstance()` that
    subclasses must implement.

    Proto files must be rebuilt using protoc_plugin 14.0.0 or newer.

## 0.10.8

*   Fix freezing of map fields.

## 0.10.7

*   Fixed problem with recursive merging of sub messages.

## 0.10.6

*   Added support for
    [oneof](https://developers.google.com/protocol-buffers/docs/proto3#oneof).
    To use oneof support use Dart protoc_plugin version 13.0.0.

## 0.10.5

*   Added support for
    [map fields](https://developers.google.com/protocol-buffers/docs/proto3#maps).
    Map fields are now represented as Dart maps and are accessed through a
    getter with the same name as the map field. To use the map support, use Dart
    protoc_plugin version 11.0.0 or newer.

## 0.10.4

*   Added separate getter for `BuilderInfo.qualifiedMessageName`.

## 0.10.3

*   Added type argument to `ProtobufEnum.initByValue` which allows the return
    value to be fully typed.

## 0.10.2

*   Added ProtobufEnum reserved names.

## 0.10.1

*   Added Support for
    [any](https://developers.google.com/protocol-buffers/docs/proto3#any)
    messages.

## 0.10.0

*   Breaking change: Add `GeneratedMessage.freeze()`. A frozen message and its
    sub-messages cannot be changed.

## 0.9.1

*   Fix problem with encoding negative enum values.
*   Fix problem with encoding byte arrays.

## 0.9.0+1

*   Dart SDK upper constraint raised to declare compatibility with Dart 2.0
    stable.

## 0.9.0

*   Breaking change: Changed signature of `CodedBufferWriter.writeTo` to require
    `Uint8List` for performance.
*   More Dart 2 fixes.

## 0.8.0

*   Breaking change: Added generics to RpcClient.invoke(). Proto files must be
    rebuilt using Dart protoc_plugin version 0.8.0 or newer to match.
*   Dart 2 fixes.

## 0.7.2+1

-   Updated SDK version to 2.0.0-dev.17.0

## 0.7.2

*   Fix hashing for PbList.

## 0.7.1

*   Fix type in PbList.fold() for Dart 2.
*   Small performance tweaks for DDC.

## 0.7.0

*   Added fast getters for common types.
*   Only pass index instead of both tag and index to accessors.
*   Delegate more methods to underlying list in PbList.
*   Small fixes for Dart 2.0.

## 0.6.0

*   Added enumValues to FieldInfo. Fixes #63.
*   Small performance optimization when deserializing repeated messages from
    JSON.
*   Type annotations for strong mode.

## 0.5.5

*   Use real generic syntax instead of comment-based.
*   Support v2 dev SDKs.

## 0.5.4

*   Unknown enum values are ignored when parsing JSON, instead of throwing an
    exception.

## 0.5.3+2

*   Resolved a strong-mode error.

## 0.5.3+1

*   Performance: Avoid excessive cloning in merge.
*   Performance: Use code patterns that dart2js handles better.

## 0.5.3

*   fix zigzag function so all coded buffer reader tests work on dart2js.

## 0.5.2

*   make PbMixin constructor public for use within protoc plugin.

## 0.5.1+5

*   Revert previous change because it causes strong mode type error in the
    generated code. We will revisit this in a new version of mixin support.

## 0.5.1+4

*   Use a more refined implementation of `Map` in `PbMapMixin`

## 0.5.1+3

*   Performance: eliminate some dynamic calls.

## 0.5.1+2

*   Bugfix: remove dependency on `pkg/crypto` for real.

## 0.5.1+1

*   Require at least Dart SDK 1.13.

*   Removed dependency on `pkg/crypto`.

## 0.5.1

*   Experimental support for strong mode.
*   Fixed an issue with GeneratedMessage operator== and Map mixins
*   Added declaration of GeneratedMessage clone method

## 0.5.0+1

*   Support the latest version of package `fixnum`.

## 0.5.0

*   Reorganized internals to improve performance. We now store field values in a
    list instead of a map. Private properties and methods are all moved to the
    \_FieldSet class. There are new entry points for generated getters, hazzers,
    and setters. Improved JSON decoding performance.
*   Dropped compatibility with .pb.dart files before 0.4.2 by removing internal
    constants from GeneratedMessage. Also, protoc plugins before 0.5.0 won't
    work.

## 0.4.2

*   Renamed FieldType to PbFieldType.

## 0.4.1 - DO NOT USE

*   added FieldType class. It turned out that FieldType is a commonly used name,
    even in .proto files. This is renamed to PbFieldType in 0.4.2.
*   Added support for observing field changes. For now, this can only be enabled
    by using a mixin to override the eventPlugin getter.
*   Removed optional third parameter from setField(). It was only intended for
    internal use, and could be used to defeat type checks on fields.
*   clearExtension() removes the value and extension in all cases. (Before, the
    extension would be kept and the list cleared for repeated fields.)
*   Upcoming: clearField() will require its argument to be a known tag number
    (which could be an extension). For now, this is only enforced when a mixin
    provides an eventPlugin.

## 0.4.0

*   Add ReadonlyMessageMixin. The generated message classes use this to for the
    default values of message fields.

## 0.3.11

*   Add meta.dart which declares reserved names for the plugin.

## 0.3.10

*   Add GeneratedService and ProtobufClient interfaces.

## 0.3.9

*   Add experimental mixins_meta library
*   Add experimental PbMapMixin class (in a separate library).
*   Fix bug where ExtensionRegistry would not be used for nested messages.

## 0.3.7

*   More docs.

## 0.3.6

*   Added mergeFromMap() and writeToJsonMap()
*   Fixed an analyzer warning.

## 0.3.5+3

*   Bugfix for `setRange()`: Do not assume Iterable has a `sublist()` method.

## 0.3.5+2

*   Simplify some types used in is checks and correct PbList to match the
*   signature of the List setRange method.

## 0.3.5+1

*   Bugfix for incorrect decoding of protobuf messages: Uint8List views with
    non-zero offsets were handled incorrectly.

## 0.3.5

*   Allow constants as field initial values as well as creation thunks to reduce
    generated code size.

*   Improve the performance of reading a protobuf buffer.

*   Fixed truncation error in least significant bits with large Int64 constants.
