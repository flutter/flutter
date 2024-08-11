// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Built-in types, collections,
/// and other core functionality for every Dart program.
///
/// This library is automatically imported.
///
/// Some classes in this library,
/// such as [String] and [num],
/// support Dart's built-in data types.
/// Other classes, such as [List] and [Map], provide data structures
/// for managing collections of objects.
/// And still other classes represent commonly used types of data
/// such as URIs, dates and times, and errors.
///
/// ## Numbers and booleans
///
/// [int] and [double] provide support for Dart's built-in numerical data types:
/// integers and double-precision floating point numbers, respectively.
/// An object of type [bool] is either true or false.
/// Variables of these types can be constructed from literals:
/// ```dart
/// int meaningOfLife = 42;
/// double valueOfPi  = 3.141592;
/// bool visible      = true;
/// ```
/// ## Strings and regular expressions
///
/// A [String] is immutable and represents a sequence of characters.
/// ```dart
/// String shakespeareQuote = "All the world's a stage, ...";
/// ```
/// [StringBuffer] provides a way to construct strings efficiently.
/// ```dart
/// var moreShakespeare = StringBuffer();
/// moreShakespeare.write('And all the men and women ');
/// moreShakespeare.write('merely players; ...');
/// ```
/// The [String] and [StringBuffer] classes implement string splitting,
/// concatenation, and other string manipulation features.
/// ```dart
/// bool isPalindrome(String text) => text == text.split('').reversed.join();
/// ```
/// [RegExp] implements Dart regular expressions,
/// which provide a grammar for matching patterns within text.
/// For example, here's a regular expression that matches
/// a substring containing one or more digits:
/// ```dart
/// var numbers = RegExp(r'\d+');
/// ```
/// Dart regular expressions have the same syntax and semantics as
/// JavaScript regular expressions. See
/// <http://ecma-international.org/ecma-262/5.1/#sec-15.10>
/// for the specification of JavaScript regular expressions.
///
/// ## Collections
///
/// The `dart:core` library provides basic collections,
/// such as [List], [Map], and [Set].
///
/// A [List] is an ordered collection of objects, with a length.
/// Lists are sometimes called arrays.
/// Use a [List] when you need to access objects by index.
/// ```dart
/// var superheroes = ['Batman', 'Superman', 'Harry Potter'];
/// ```
/// A [Set] is an unordered collection of unique objects.
/// You cannot get an item efficiently by index (position).
/// Adding an element which is already in the set, has no effect.
/// ```dart
/// var villains = {'Joker'};
/// print(villains.length); // 1
/// villains.addAll(['Joker', 'Lex Luthor', 'Voldemort']);
/// print(villains.length); // 3
/// ```
/// A [Map] is an unordered collection of key-value pairs,
/// where each key can only occur once.
/// Maps are sometimes called associative arrays because
/// maps associate a key to some value for easy retrieval.
/// Use a [Map] when you need to access objects
/// by a unique identifier.
/// ```dart
/// var sidekicks = {'Batman': 'Robin',
///                  'Superman': 'Lois Lane',
///                  'Harry Potter': 'Ron and Hermione'};
/// ```
/// In addition to these classes,
/// `dart:core` contains [Iterable],
/// an interface that defines functionality
/// common in collections of objects.
/// Examples include the ability
/// to run a function on each element in the collection,
/// to apply a test to each element,
/// to retrieve an object, and to determine the number of elements.
///
/// [Iterable] is implemented by [List] and [Set],
/// and used by [Map] for its keys and values.
///
/// For other kinds of collections, check out the
/// `dart:collection` library.
///
/// ## Date and time
///
/// Use [DateTime] to represent a point in time
/// and [Duration] to represent a span of time.
///
/// You can create [DateTime] objects with constructors
/// or by parsing a correctly formatted string.
/// ```dart
/// var now = DateTime.now();
/// var berlinWallFell = DateTime(1989, 11, 9);
/// var moonLanding = DateTime.parse("1969-07-20");
/// ```
/// Create a [Duration] object by specifying the individual time units.
/// ```dart
/// var timeRemaining = const Duration(hours: 56, minutes: 14);
/// ```
/// In addition to [DateTime] and [Duration],
/// `dart:core` contains the [Stopwatch] class for measuring elapsed time.
///
/// ## Uri
///
/// A [Uri] object represents a uniform resource identifier,
/// which identifies a resource, for example on the web.
/// ```dart
/// var dartlang = Uri.parse('http://dartlang.org/');
/// ```
/// ## Errors
///
/// The [Error] class represents the occurrence of an error
/// during runtime.
/// Subclasses of this class represent specific kinds of errors.
///
/// ## Other documentation
///
/// For more information about how to use the built-in types, refer to
/// [Built-in Types](https://dart.dev/guides/language/language-tour#built-in-types)
/// in
/// [A tour of the Dart language](https://dart.dev/guides/language/language-tour).
///
/// Also, see
/// [dart:core - numbers, collections, strings, and more](https://dart.dev/guides/libraries/library-tour#dartcore---numbers-collections-strings-and-more)
/// for more coverage of types in this library.
///
/// The [Dart Language Specification](https://dart.dev/guides/language/spec)
/// provides technical details.
///
/// {@category Core}
library dart.core;

import "dart:collection";
import "dart:_internal" hide Symbol, LinkedList, LinkedListEntry;
import "dart:_internal" as internal show Symbol;
import "dart:convert"
    show
        ascii,
        base64,
        Base64Codec,
        Encoding,
        latin1,
        StringConversionSink,
        utf8;
import "dart:math" show Random; // Used by List.shuffle.
import "dart:typed_data" show Uint8List;

@Since("2.1")
export "dart:async" show Future, Stream;
@Since("2.12")
export "dart:async" show FutureExtensions;
@Since("3.0")
export "dart:async"
    show
        FutureIterable,
        FutureRecord2,
        FutureRecord3,
        FutureRecord4,
        FutureRecord5,
        FutureRecord6,
        FutureRecord7,
        FutureRecord8,
        FutureRecord9,
        ParallelWaitError;

export "dart:collection" show NullableIterableExtensions, IterableExtensions;

part "annotations.dart";
part "bigint.dart";
part "bool.dart";
part "comparable.dart";
part "date_time.dart";
part "double.dart";
part "duration.dart";
part "enum.dart";
part "errors.dart";
part "exceptions.dart";
part "function.dart";
part "identical.dart";
part "int.dart";
part "invocation.dart";
part "iterable.dart";
part "iterator.dart";
part "list.dart";
part "map.dart";
part "null.dart";
part "num.dart";
part "object.dart";
part "pattern.dart";
part "print.dart";
part "record.dart";
part "regexp.dart";
part "set.dart";
part "sink.dart";
part "stacktrace.dart";
part "stopwatch.dart";
part "string.dart";
part "string_buffer.dart";
part "string_sink.dart";
part "symbol.dart";
part "type.dart";
part "uri.dart";
part "weak.dart";
