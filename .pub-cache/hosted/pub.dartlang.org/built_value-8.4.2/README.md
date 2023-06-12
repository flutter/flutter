# Built Values for Dart
[![Build Status](https://travis-ci.org/google/built_value.dart.svg?branch=master)](https://travis-ci.org/google/built_value.dart)
## Introduction

Built Value provides:

- Immutable value types;
- EnumClass, classes that behave like enums;
- JSON serialization.

Immutable collections are from
[built_collection](https://github.com/google/built_collection.dart#built-collections-for-dart).

See the [API docs](https://pub.dev/documentation/built_value/latest/built_value/built_value-library.html).

## Articles

- [`built_value` for Immutable Object Models](https://medium.com/@davidmorgan_14314/darts-built-value-for-immutable-object-models-83e2497922d4#.48dyezxcl)
- [`built_value` for Serialization](https://medium.com/@davidmorgan_14314/darts-built-value-for-serialization-f5db9d0f4159#.h12y94wu7)
- [Building a Chat App in Dart](https://medium.com/@davidmorgan_14314/building-a-chat-app-in-dart-815fcd0e5a31#.ku4vtbmk2)
- [End to End Testing in One Short Second with Dart](https://medium.com/@davidmorgan_14314/end-to-end-testing-in-one-short-second-with-dart-e699c8146fd6#.c7xfxohg4)
- [Moving Fast with Dart Immutable Values](https://medium.com/@davidmorgan_14314/moving-fast-with-dart-immutable-values-1e717925fafb)
- [Flutter JSON Serialization](https://aloisdeniel.github.io/flutter-json-serialization/)
- [Flutter TODO App Example](https://gitlab.com/brianegan/flutter_architecture_samples/tree/master/example/built_redux)
  using `built_value`, [built_redux](https://pub.dev/packages/built_redux), and [flutter_built_redux](https://pub.dev/packages/flutter_built_redux)
- [Building a (large) Flutter app with Redux](https://hillelcoren.com/2018/06/01/building-a-large-flutter-app-with-redux/)
- [Some Options for Deserializing JSON with Flutter](https://medium.com/flutter-io/some-options-for-deserializing-json-with-flutter-7481325a4450)

## Tutorials

 - [Custom Serializers](https://medium.com/@solid.goncalo/creating-custom-built-value-serializers-with-builtvalueserializer-46a52c75d4c5)
 - [Flutter + built_value + Reddit Tutorial](https://steemit.com/utopian-io/@tensor/building-immutable-models-with-built-value-and-built-collection-in-dart-s-flutter-framework);
   [video](https://www.youtube.com/watch?v=hNbOSSgpneI);
   [source code](https://github.com/tensor-programming/built_flutter_tutorial)

## Tools

 - [Json to Dart built_value class converter](https://charafau.github.io/json2builtvalue/)
 - [Json or js Object to Dart built_value class converter](https://januwa.github.io/p5_object_2_builtvalue/index.html)
- [VSCode extension](https://marketplace.visualstudio.com/items?itemName=GiancarloCode.built-value-snippets)
 - [IntelliJ plugin](https://plugins.jetbrains.com/plugin/13786-built-value-snippets)

## Examples

For an end to end example see the
[chat example](https://github.com/google/built_value.dart/tree/master/chat_example), which was
[demoed](https://www.youtube.com/watch?v=TMeJxWltoVo) at the Dart Summit 2016.
The
[data model](https://github.com/google/built_value.dart/blob/master/chat_example/lib/data_model/data_model.dart),
used both client and server side, uses value types, enums and serialization from
built_value.

Simple examples are
[here](https://github.com/google/built_value.dart/tree/master/example/lib/example.dart).

Since `v5.2.0` codegen is triggered by running `pub run build_runner build` to
do a one-off build or `pub run build_runner watch` to continuously watch your
source and update the generated output when it changes. Note that you need a
dev dependency on `built_value_generator` and `build_runner`. See the example
[pubspec.yaml](https://github.com/google/built_value.dart/blob/master/example/pubspec.yaml).

If using Flutter, the equivalent command is `flutter packages pub run build_runner build`.
Alternatively, put your `built_value` classes in a separate Dart package with no dependency
on Flutter. You can then use `built_value` as normal.

If using a version before v5.2.0, codegen is triggered via either a
[build.dart](https://github.com/google/built_value.dart/blob/92783c27a08ac3c73f28bb08736b9d4a30fa3b7e/example/tool/build.dart)
to do a one-off build or a
[watch.dart](https://github.com/google/built_value.dart/blob/92783c27a08ac3c73f28bb08736b9d4a30fa3b7e/example/tool/watch.dart)
to continuously watch your source and update generated output.

## Value Types

Value types are, for our purposes, classes that are considered
interchangeable if their fields have the same values.

Common examples include `Date`, `Money` and `Url`. Most code introduces
its own value types. For example, every web app probably has some
version of `Account` and `User`.

Value types are very commonly sent by RPC and/or stored for later
retrieval.

The problems that led to the creation of the Built Value library have
been
[discussed at great length](https://docs.google.com/presentation/d/14u_h-lMn7f1rXE1nDiLX0azS3IkgjGl5uxp5jGJ75RE/edit)
in the context of
[AutoValue](https://github.com/google/auto/tree/master/value#autovalue)
for Java.

In short: creating and maintaining value types by hand requires a lot of
boilerplate. It's boring to write, and if you make a mistake, you very
likely create a bug that's hard to track down.

Any solution for value types needs to allow them to participate in object
oriented design. `Date`, for example, is the right place for code that
does simple date manipulation.

[AutoValue](https://github.com/google/auto/tree/master/value#autovalue)
solves the problem for Java with code generation, and Built Values does
the same for Dart. The boilerplate is generated for you, leaving you to
specify which fields you need and to add code for the behaviour of the
class.

### Generating boilerplate for Value Types

Value types require a bit of boilerplate in order to connect it to generated
code. Luckily, even this bit of boilerplate can be automated using code
snippets support in your favourite text editor. For example, in IntelliJ you
can use the following live template:

```dart
abstract class $CLASS_NAME$ implements Built<$CLASS_NAME$, $CLASS_NAME$Builder> {
  $CLASS_NAME$._();
  factory $CLASS_NAME$([void Function($CLASS_NAME$Builder) updates]) = _$$$CLASS_NAME$;
}
```

Using this template, you would only have to manually enter a name for your data
class, which is something that can't be automated.

## Enum Class

Enum Classes provide classes with enum features.

Enums are very helpful in modelling the real world: whenever there are a
small fixed set of options, an enum is a natural choice. For an object
oriented design, though, enums need to be classes. Dart falls short here,
so Enum Classes provide what's missing!

Design:

- Constants have `name` and `toString`, can be used in `switch` statements,
  and are real classes that can hold code and implement interfaces
- Generated `values` method that returns all the enum values in a `BuiltSet` (immutable set)
- Generated `valueOf` method that takes a `String`

## Serialization

Built Values comes with JSON serialization support which allows you to
serialize a complete data model of Built Values, Enum Classes and
Built Collections. The
[chat example](https://github.com/google/built_value.dart/tree/master/chat_example) shows 
how easy this makes building a full application with Dart on the server and
client.

Here are the major features of the serialization support:

It _fully supports object oriented design_: any object model that you can 
design can be serialized, including full use of generics and interfaces.
Some other libraries require concrete types or do not fully support generics.

It _allows different object oriented models over the same data_. For
example, in a client server application, it's likely that the client and server
want different functionality from their data model. So, they are allowed to have
different classes that map to the same data. Most other libraries enforce a 1:1
mapping between classes and types on the wire.

It _requires well behaved types_. They must be immutable, can use
interface but not concrete inheritance, must have predictable nullability,
`hashCode`, `equals` and `toString`. In fact, they must be Enum Classes, Built
Collections or Built Values. Some other libraries allow badly behaved types to
be serialized.

It _supports changes to the data model_. Optional fields can be added or
removed, and fields can be switched from optional to required, allowing your
data model to evolve without breaking compatbility. Some other libraries break
compatibility on any change to any serializable class.

It's _modular_. Each endpoint can choose which classes to know about;
for example, you can have multiple clients that each know about only a subset of
the classes the server knows. Most other libraries are monolithic, requiring all
endpoints to know all types.

It _has first class support for validation_ via Built Values. An important 
part of a powerful data model is ensuring it's valid, so classes can make
guarantees about what they can do. Other libraries also support validation
but usually in a less prominent way.

It's _pluggable_. You can add serializers for your own types, and you can add
[plugins](https://github.com/google/built_value.dart/blob/master/built_value/lib/standard_json_plugin.dart)
which run before and after all serializers. This could be used to
interoperate with other tools or to add hand coded high performance serializers
for specific classes. Some other libraries are not so extensible.

It was designed to be _multi language_, mapping to equivalent object models in
Java and other languages. Currently only Dart is supported. The need for other
languages didn't materialize as servers are typically either written in Dart
or owned by third parties. Please open an issue if you'd like to explore
support in more languages.

## Common Usage

While full, compiled examples are available in
[`example/lib`](https://github.com/google/built_value.dart/tree/master/example/lib),
a common usage example is shown here. This example assumes that you are writing
a client for a JSON API representing a person that looks like the following:

```json
{
  "id": 12345,
  "age": 35,
  "first_name": "Jimmy",
  "hobbies": ["jumping", "basketball"]
}
```

The corresponding dart class employing `built_value` might look like this. Note
that it is using the
[`@nullable`](https://pub.dev/documentation/built_value/latest/built_value/nullable-constant.html)
annotation to indicate that the field does not have to be present on the
response, as well as the
[`@BuiltValueField`](https://pub.dev/documentation/built_value/latest/built_value/BuiltValueField-class.html)
annotation to map between the property name on the response and the name of the
member variable in the `Person` class.

```dart
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';

part 'person.g.dart';

abstract class Person implements Built<Person, PersonBuilder> {
  static Serializer<Person> get serializer => _$personSerializer;

  // Can never be null.
  int get id;

  @nullable
  int get age;

  @nullable
  @BuiltValueField(wireName: 'first_name')
  String get firstName;

  @nullable
  BuiltList<String> get hobbies;

  Person._();
  factory Person([void Function(PersonBuilder) updates]) = _$Person;
}
```

## FAQ

### How do I check a field is valid on instantiation?

The value class private constructor runs when all fields are initialized and
can do arbitrary checks:

```dart
abstract class MyValue {
  MyValue._() {
    if (field < 0) {
      throw ArgumentError(field, 'field', 'Must not be negative.');
    }
  }
```

### How do I process a field on instantiation?

Add a hook that runs immediately before a builder is built. For example, you
could sort a list, so it's always sorted directly before the value is created:

```dart
abstract class MyValue {
  @BuiltValueHook(finalizeBuilder: true)
  static void _sortItems(MyValueBuilder b) =>
      b..items.sort();
```

### How do I set a default for a field?

Add a hook that runs whenever a builder is created:

```dart
abstract class MyValue {
  @BuiltValueHook(initializeBuilder: true)
  static void _setDefaults(MyValueBuilder b) =>
      b
        ..name = 'defaultName'
        ..count = 0;
```

### Should I check in and/or publish in the generated `.g.dart` files?

See the [build_runner](https://pub.dev/packages/build_runner#source-control)
docs. You usually should not check in generated files, but you _do_ need to publish
them.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/google/built_value.dart/issues
