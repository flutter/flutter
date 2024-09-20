// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// A function value.
///
/// The `Function` class is a supertype of all *function types*, and contains
/// no values itself. All objects that implement `Function`
/// have a function type as their runtime type.
///
/// The `Function` type does not carry information about the
/// parameter signatures or return type of a function.
/// To express a more precise function type, use the function type syntax,
/// which is the `Function` keyword followed by a parameter list,
/// or a type argument list and a parameter list, and which can also have
/// an optional return type.
///
/// The function type syntax mirrors the definition of a function,
/// with the function name replaced by the word "Function".
///
/// Example:
/// ```dart
/// String numberToString(int n) => "$n";
/// String Function(int n) fun = numberToString; // Type annotation
/// assert(fun is String Function(int)); // Type check.
/// List<String Function(int)> functions = [fun]; // Type argument.
/// ```
/// The type `String Function(int)` is the type of a function
/// that takes one positional `int` argument and returns a `String`.
///
/// Example with generic function type:
/// ```dart
/// T id<T>(T value) => value;
/// X Function<X>(X) anotherId = id; // Parameter name may be omitted.
/// int Function(int) intId = id<int>;
/// ```
///
/// A function type can be used anywhere a type is allowed,
/// and is often used for functions taking other functions, "callbacks",
/// as arguments.
///
/// ```dart
/// void doSomething(String Function(int) callback) {
///   print(callback(1));
/// }
/// ```
///
/// A function type has all the members declared by [Object],
/// since function types are subtypes of [Object].
///
/// A function type also has a `call` method with a signature
/// that has the same function type as the function type itself.
/// Calling the `call` method behaves just as calling the function.
/// This is mainly used to conditionally call a nullable function value.
/// ```dart
/// String Function(int) fun = (n) => "$n";
/// String Function(int) fun2 = fun.call; // Valid.
/// print(fun2.call(1)); // Prints "1".
///
/// String Function(int)? maybeFun = Random().nextBool() ? fun : null;
/// print(maybeFun?.call(1)); // Prints "1" or "null".
/// ```
///
/// The [Function] type has a number of special features which are not visible
/// in this `class` declaration.
///
/// The `Function` type itself allows any function to be assigned to it,
/// since it is a supertype of any function type,
/// but does not say how the function can be called.
///
/// However, a value with the static type `Function` *can* still be called
/// like a function.
/// ```dart
/// Function f = (int x) => "$x";
/// print(f(1)); // Prints "1".
///
/// f("not", "one", "int"); // Throws! No static warning.
/// ```
/// Such an invocation is a *dynamic* invocation,
/// precisely as if the function value had been statically typed as [dynamic],
/// and is precisely as unsafe as any other dynamic invocation.
/// Checks will be performed at run-time to ensure that the argument
/// list matches the function's parameters, and if not the call will
/// fail with an [Error].
/// There is no static type checking for such a call, any argument list
/// is accepted and checked at runtime.
///
/// Like every function type has a `call` method with its own function type,
/// the `Function` type has a special `call` member
/// which acts as if it is a method with a function type of `Function`
/// (which is not a method signature which can be expressed in normal
/// Dart code).
/// ```dart
/// Function fun = (int x) => "$x";
///
/// var fun2 = fun.call; // Inferred type of `fun2` is `Function`.
///
/// print(fun2.call(1)); // Prints "1";
///
/// Function? maybeFun = Random().nextBool() ? fun : null;
/// print(maybeFun?.call(1)); // Prints "1" or "null".
/// ```
abstract final class Function {
  /// Dynamically call [function] with the specified arguments.
  ///
  /// Acts the same as dynamically calling [function] with
  /// positional arguments corresponding to the elements of [positionalArguments]
  /// and named arguments corresponding to the elements of [namedArguments].
  ///
  /// This includes giving the same errors if [function]
  /// expects different parameters.
  ///
  /// Example:
  /// ```dart
  /// void printWineDetails(int vintage, {String? country, String? name}) {
  ///   print('Name: $name, Country: $country, Vintage: $vintage');
  /// }
  ///
  /// void main() {
  ///   Function.apply(
  ///       printWineDetails, [2018], {#country: 'USA', #name: 'Dominus Estate'});
  /// }
  ///
  /// // Output of the example is:
  /// // Name: Dominus Estate, Country: USA, Vintage: 2018
  /// ```
  ///
  /// If [positionalArguments] is null, it's considered an empty list.
  /// If [namedArguments] is omitted or null, it is considered an empty map.
  ///
  /// ```dart
  /// void helloWorld() {
  ///   print('Hello world!');
  /// }
  ///
  /// void main() {
  ///   Function.apply(helloWorld, null);
  /// }
  /// // Output of the example is:
  /// // Hello world!
  /// ```
  external static apply(Function function, List<dynamic>? positionalArguments,
      [Map<Symbol, dynamic>? namedArguments]);

  /// A hash code value that is compatible with `operator==`.
  int get hashCode;

  /// Test whether another object is equal to this function.
  ///
  /// Function objects are only equal to other function objects (an object
  /// satisfying `object is Function`), and never to non-function objects.
  ///
  /// Some function objects are considered equal by `==` because they are
  /// recognized as representing the "same function":
  ///
  /// - It is the same object. Static and top-level functions are compile time
  ///   constants when used as values, so referring to the same function twice
  ///   always yields the same object, as does referring to a local function
  ///   declaration twice in the same scope where it was declared.
  ///
  ///   ```dart
  ///   void main() {
  ///     assert(identical(print, print));
  ///     int add(int x, int y) => x + y;
  ///     assert(identical(add, add));
  ///   }
  ///   ```
  ///
  /// - The functions are same member method extracted from the same object.
  ///   Repeatedly extracting ("tearing off") the same instance method of the
  ///   same object to a function value gives equal, but not necessarily
  ///   identical, function values.
  ///
  ///   ```dart
  ///   var o = Object();
  ///   assert(o.toString == o.toString);
  ///   ```
  ///
  /// - Instantiations of equal generic functions with the *same* types
  ///   yields equal results.
  ///
  ///   ```dart
  ///   T id<T>(T value) => value;
  ///   assert(id<int> == id<int>);
  ///   ```
  ///
  ///   (If the function is a constant and the type arguments are known at
  ///   compile-time, the results may also be identical.)
  ///
  /// Different evaluations of function literals are not guaranteed or required
  /// to give rise to identical or equal function objects. For example:
  ///
  /// ```dart
  /// var functions = <Function>[];
  /// for (var i = 0; i < 2; i++) {
  ///   functions.add((x) => x);
  /// }
  /// print(identical(functions[0], functions[1])); // 'true' or 'false'
  /// print(functions[0] == functions[1]); // 'true' or 'false'
  /// ```
  ///
  /// If the distinct values are identical, they are always equal.
  ///
  /// If the function values are equal, they are guaranteed to behave
  /// indistinguishably for all arguments.
  ///
  /// If two functions values behave differently, they are never equal or
  /// identical.
  ///
  /// The reason to not require a specific equality or identity of the values
  /// of a function expression is to allow compiler optimizations. If a
  /// function expression does not depend on surrounding variables, an
  /// implementation can safely be shared between multiple evaluations. For
  /// example:
  ///
  /// ```dart
  /// List<int> ints = [6, 2, 5, 1, 4, 3];
  /// ints.sort((x, y) => x - y);
  /// print(ints);
  /// ```
  ///
  /// A compiler can convert the closure `(x, y) => x - y` into a top-level
  /// function.
  bool operator ==(Object other);
}
