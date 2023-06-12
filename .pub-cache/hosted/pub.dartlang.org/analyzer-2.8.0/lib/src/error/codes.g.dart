// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart pkg/analyzer/tool/messages/generate.dart' to update.

import "package:analyzer/error/error.dart";
import "package:analyzer/src/error/analyzer_error_code.dart";

// It is hard to visually separate each code's _doc comment_ from its published
// _documentation comment_ when each is written as an end-of-line comment.
// ignore_for_file: slash_for_doc_comments

class CompileTimeErrorCode extends AnalyzerErrorCode {
  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a field that has the `abstract`
  // modifier also has an initializer.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because `f` is marked as
  // `abstract` and has an initializer:
  //
  // ```dart
  // abstract class C {
  //   abstract int [!f!] = 0;
  // }
  // ```
  //
  // The following code produces this diagnostic because `f` is marked as
  // `abstract` and there's an initializer in the constructor:
  //
  // ```dart
  // abstract class C {
  //   abstract int f;
  //
  //   C() : [!f!] = 0;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the field must be abstract, then remove the initializer:
  //
  // ```dart
  // abstract class C {
  //   abstract int f;
  // }
  // ```
  //
  // If the field isn't required to be abstract, then remove the keyword:
  //
  // ```dart
  // abstract class C {
  //   int f = 0;
  // }
  // ```
  static const CompileTimeErrorCode ABSTRACT_FIELD_CONSTRUCTOR_INITIALIZER =
      CompileTimeErrorCode(
    'ABSTRACT_FIELD_INITIALIZER',
    "Abstract fields can't have initializers.",
    correctionMessage:
        "Try removing the field initializer or the 'abstract' keyword from the field declaration.",
    hasPublishedDocs: true,
    uniqueName: 'ABSTRACT_FIELD_CONSTRUCTOR_INITIALIZER',
  );

  /**
   * No parameters.
   */
  static const CompileTimeErrorCode ABSTRACT_FIELD_INITIALIZER =
      CompileTimeErrorCode(
    'ABSTRACT_FIELD_INITIALIZER',
    "Abstract fields can't have initializers.",
    correctionMessage:
        "Try removing the initializer or the 'abstract' keyword.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the display name for the kind of the found abstract member
   * 1: the name of the member
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an inherited member is
  // referenced using `super`, but there is no concrete implementation of the
  // member in the superclass chain. Abstract members can't be invoked.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `B` doesn't inherit a
  // concrete implementation of `a`:
  //
  // ```dart
  // abstract class A {
  //   int get a;
  // }
  // class B extends A {
  //   int get a => super.[!a!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the invocation of the abstract member, possibly replacing it with an
  // invocation of a concrete member.
  // TODO(brianwilkerson) This either needs to be generalized (use 'member'
  //  rather than '{0}') or split into multiple codes.
  static const CompileTimeErrorCode ABSTRACT_SUPER_MEMBER_REFERENCE =
      CompileTimeErrorCode(
    'ABSTRACT_SUPER_MEMBER_REFERENCE',
    "The {0} '{1}' is always abstract in the supertype.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the ambiguous element
   * 1: the name of the first library in which the type is found
   * 2: the name of the second library in which the type is found
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when two or more export directives
  // cause the same name to be exported from multiple libraries.
  //
  // #### Example
  //
  // Given a file named `a.dart` containing
  //
  // ```dart
  // %uri="lib/a.dart"
  // class C {}
  // ```
  //
  // And a file named `b.dart` containing
  //
  // ```dart
  // %uri="lib/b.dart"
  // class C {}
  // ```
  //
  // The following code produces this diagnostic because the name `C` is being
  // exported from both `a.dart` and `b.dart`:
  //
  // ```dart
  // export 'a.dart';
  // export [!'b.dart'!];
  // ```
  //
  // #### Common fixes
  //
  // If none of the names in one of the libraries needs to be exported, then
  // remove the unnecessary export directives:
  //
  // ```dart
  // export 'a.dart';
  // ```
  //
  // If all of the export directives are needed, then hide the name in all
  // except one of the directives:
  //
  // ```dart
  // export 'a.dart';
  // export 'b.dart' hide C;
  // ```
  static const CompileTimeErrorCode AMBIGUOUS_EXPORT = CompileTimeErrorCode(
    'AMBIGUOUS_EXPORT',
    "The name '{0}' is defined in the libraries '{1}' and '{2}'.",
    correctionMessage:
        "Try removing the export of one of the libraries, or explicitly hiding the name in one of the export directives.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the member
   * 1: the names of the declaring extensions
   */
  // #### Description
  //
  // When code refers to a member of an object (for example, `o.m()` or `o.m` or
  // `o[i]`) where the static type of `o` doesn't declare the member (`m` or
  // `[]`, for example), then the analyzer tries to find the member in an
  // extension. For example, if the member is `m`, then the analyzer looks for
  // extensions that declare a member named `m` and have an extended type that
  // the static type of `o` can be assigned to. When there's more than one such
  // extension in scope, the extension whose extended type is most specific is
  // selected.
  //
  // The analyzer produces this diagnostic when none of the extensions has an
  // extended type that's more specific than the extended types of all of the
  // other extensions, making the reference to the member ambiguous.
  //
  // #### Example
  //
  // The following code produces this diagnostic because there's no way to
  // choose between the member in `E1` and the member in `E2`:
  //
  // ```dart
  // extension E1 on String {
  //   int get charCount => 1;
  // }
  //
  // extension E2 on String {
  //   int get charCount => 2;
  // }
  //
  // void f(String s) {
  //   print(s.[!charCount!]);
  // }
  // ```
  //
  // #### Common fixes
  //
  // If you don't need both extensions, then you can delete or hide one of them.
  //
  // If you need both, then explicitly select the one you want to use by using
  // an extension override:
  //
  // ```dart
  // extension E1 on String {
  //   int get charCount => length;
  // }
  //
  // extension E2 on String {
  //   int get charCount => length;
  // }
  //
  // void f(String s) {
  //   print(E2(s).charCount);
  // }
  // ```
  static const CompileTimeErrorCode AMBIGUOUS_EXTENSION_MEMBER_ACCESS =
      CompileTimeErrorCode(
    'AMBIGUOUS_EXTENSION_MEMBER_ACCESS',
    "A member named '{0}' is defined in {1}, and none are more specific.",
    correctionMessage:
        "Try using an extension override to specify the extension you want to be chosen.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the ambiguous type
   * 1: the name of the first library that the type is found
   * 2: the name of the second library that the type is found
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a name is referenced that is
  // declared in two or more imported libraries.
  //
  // #### Example
  //
  // Given a library (`a.dart`) that defines a class (`C` in this example):
  //
  // ```dart
  // %uri="lib/a.dart"
  // class A {}
  // class C {}
  // ```
  //
  // And a library (`b.dart`) that defines a different class with the same name:
  //
  // ```dart
  // %uri="lib/b.dart"
  // class B {}
  // class C {}
  // ```
  //
  // The following code produces this diagnostic:
  //
  // ```dart
  // import 'a.dart';
  // import 'b.dart';
  //
  // void f([!C!] c1, [!C!] c2) {}
  // ```
  //
  // #### Common fixes
  //
  // If any of the libraries aren't needed, then remove the import directives
  // for them:
  //
  // ```dart
  // import 'a.dart';
  //
  // void f(C c1, C c2) {}
  // ```
  //
  // If the name is still defined by more than one library, then add a `hide`
  // clause to the import directives for all except one library:
  //
  // ```dart
  // import 'a.dart' hide C;
  // import 'b.dart';
  //
  // void f(C c1, C c2) {}
  // ```
  //
  // If you must be able to reference more than one of these types, then add a
  // prefix to each of the import directives, and qualify the references with
  // the appropriate prefix:
  //
  // ```dart
  // import 'a.dart' as a;
  // import 'b.dart' as b;
  //
  // void f(a.C c1, b.C c2) {}
  // ```
  static const CompileTimeErrorCode AMBIGUOUS_IMPORT = CompileTimeErrorCode(
    'AMBIGUOUS_IMPORT',
    "The name '{0}' is defined in the libraries {1}.",
    correctionMessage:
        "Try using 'as prefix' for one of the import directives, or hiding the name from all but one of the imports.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // Because map and set literals use the same delimiters (`{` and `}`), the
  // analyzer looks at the type arguments and the elements to determine which
  // kind of literal you meant. When there are no type arguments, then the
  // analyzer uses the types of the elements. If all of the elements are literal
  // map entries and all of the spread operators are spreading a `Map` then it's
  // a `Map`. If none of the elements are literal map entries and all of the
  // spread operators are spreading an `Iterable`, then it's a `Set`. If neither
  // of those is true then it's ambiguous.
  //
  // The analyzer produces this diagnostic when at least one element is a
  // literal map entry or a spread operator spreading a `Map`, and at least one
  // element is neither of these, making it impossible for the analyzer to
  // determine whether you are writing a map literal or a set literal.
  //
  // #### Example
  //
  // The following code produces this diagnostic:
  //
  // ```dart
  // union(Map<String, String> a, List<String> b, Map<String, String> c) =>
  //     [!{...a, ...b, ...c}!];
  // ```
  //
  // The list `b` can only be spread into a set, and the maps `a` and `c` can
  // only be spread into a map, and the literal can't be both.
  //
  // #### Common fixes
  //
  // There are two common ways to fix this problem. The first is to remove all
  // of the spread elements of one kind or another, so that the elements are
  // consistent. In this case, that likely means removing the list and deciding
  // what to do about the now unused parameter:
  //
  // ```dart
  // union(Map<String, String> a, List<String> b, Map<String, String> c) =>
  //     {...a, ...c};
  // ```
  //
  // The second fix is to change the elements of one kind into elements that are
  // consistent with the other elements. For example, you can add the elements
  // of the list as keys that map to themselves:
  //
  // ```dart
  // union(Map<String, String> a, List<String> b, Map<String, String> c) =>
  //     {...a, for (String s in b) s: s, ...c};
  // ```
  static const CompileTimeErrorCode AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH =
      CompileTimeErrorCode(
    'AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH',
    "The literal can't be either a map or a set because it contains at least one literal map entry or a spread operator spreading a 'Map', and at least one element which is neither of these.",
    correctionMessage:
        "Try removing or changing some of the elements so that all of the elements are consistent.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // Because map and set literals use the same delimiters (`{` and `}`), the
  // analyzer looks at the type arguments and the elements to determine which
  // kind of literal you meant. When there are no type arguments and all of the
  // elements are spread elements (which are allowed in both kinds of literals)
  // then the analyzer uses the types of the expressions that are being spread.
  // If all of the expressions have the type `Iterable`, then it's a set
  // literal; if they all have the type `Map`, then it's a map literal.
  //
  // This diagnostic is produced when none of the expressions being spread have
  // a type that allows the analyzer to decide whether you were writing a map
  // literal or a set literal.
  //
  // #### Example
  //
  // The following code produces this diagnostic:
  //
  // ```dart
  // union(a, b) => [!{...a, ...b}!];
  // ```
  //
  // The problem occurs because there are no type arguments, and there is no
  // information about the type of either `a` or `b`.
  //
  // #### Common fixes
  //
  // There are three common ways to fix this problem. The first is to add type
  // arguments to the literal. For example, if the literal is intended to be a
  // map literal, you might write something like this:
  //
  // ```dart
  // union(a, b) => <String, String>{...a, ...b};
  // ```
  //
  // The second fix is to add type information so that the expressions have
  // either the type `Iterable` or the type `Map`. You can add an explicit cast
  // or, in this case, add types to the declarations of the two parameters:
  //
  // ```dart
  // union(List<int> a, List<int> b) => {...a, ...b};
  // ```
  //
  // The third fix is to add context information. In this case, that means
  // adding a return type to the function:
  //
  // ```dart
  // Set<String> union(a, b) => {...a, ...b};
  // ```
  //
  // In other cases, you might add a type somewhere else. For example, say the
  // original code looks like this:
  //
  // ```dart
  // union(a, b) {
  //   var x = [!{...a, ...b}!];
  //   return x;
  // }
  // ```
  //
  // You might add a type annotation on `x`, like this:
  //
  // ```dart
  // union(a, b) {
  //   Map<String, String> x = {...a, ...b};
  //   return x;
  // }
  // ```
  static const CompileTimeErrorCode AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER =
      CompileTimeErrorCode(
    'AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER',
    "This literal must be either a map or a set, but the elements don't have enough information for type inference to work.",
    correctionMessage:
        "Try adding type arguments to the literal (one for sets, two for maps).",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the actual argument type
   * 1: the name of the expected type
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the static type of an argument
  // can't be assigned to the static type of the corresponding parameter.
  //
  // #### Example
  //
  // The following code produces this diagnostic because a `num` can't be
  // assigned to a `String`:
  //
  // ```dart
  // %language=2.9
  // String f(String x) => x;
  // String g(num y) => f([!y!]);
  // ```
  //
  // #### Common fixes
  //
  // If possible, rewrite the code so that the static type is assignable. In the
  // example above you might be able to change the type of the parameter `y`:
  //
  // ```dart
  // %language=2.9
  // String f(String x) => x;
  // String g(String y) => f(y);
  // ```
  //
  // If that fix isn't possible, then add code to handle the case where the
  // argument value isn't the required type. One approach is to coerce other
  // types to the required type:
  //
  // ```dart
  // %language=2.9
  // String f(String x) => x;
  // String g(num y) => f(y.toString());
  // ```
  //
  // Another approach is to add explicit type tests and fallback code:
  //
  // ```dart
  // %language=2.9
  // String f(String x) => x;
  // String g(num y) => f(y is String ? y : '');
  // ```
  //
  // If you believe that the runtime type of the argument will always be the
  // same as the static type of the parameter, and you're willing to risk having
  // an exception thrown at runtime if you're wrong, then add an explicit cast:
  //
  // ```dart
  // String f(String x) => x;
  // String g(num y) => f(y as String);
  // ```
  static const CompileTimeErrorCode ARGUMENT_TYPE_NOT_ASSIGNABLE =
      CompileTimeErrorCode(
    'ARGUMENT_TYPE_NOT_ASSIGNABLE',
    "The argument type '{0}' can't be assigned to the parameter type '{1}'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a redirecting constructor (a
  // constructor that redirects to another constructor in the same class) has an
  // assert in the initializer list.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the unnamed constructor
  // is a redirecting constructor and also has an assert in the initializer
  // list:
  //
  // ```dart
  // class C {
  //   C(int x) : [!assert(x > 0)!], this.name();
  //   C.name() {}
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the assert isn't needed, then remove it:
  //
  // ```dart
  // class C {
  //   C(int x) : this.name();
  //   C.name() {}
  // }
  // ```
  //
  // If the assert is needed, then convert the constructor into a factory
  // constructor:
  //
  // ```dart
  // class C {
  //   factory C(int x) {
  //     assert(x > 0);
  //     return C.name();
  //   }
  //   C.name() {}
  // }
  // ```
  static const CompileTimeErrorCode ASSERT_IN_REDIRECTING_CONSTRUCTOR =
      CompileTimeErrorCode(
    'ASSERT_IN_REDIRECTING_CONSTRUCTOR',
    "A redirecting constructor can't have an 'assert' initializer.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when it finds an assignment to a
  // top-level variable, a static field, or a local variable that has the
  // `const` modifier. The value of a compile-time constant can't be changed at
  // runtime.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `c` is being assigned a
  // value even though it has the `const` modifier:
  //
  // ```dart
  // const c = 0;
  //
  // void f() {
  //   [!c!] = 1;
  //   print(c);
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the variable must be assignable, then remove the `const` modifier:
  //
  // ```dart
  // var c = 0;
  //
  // void f() {
  //   c = 1;
  //   print(c);
  // }
  // ```
  //
  // If the constant shouldn't be changed, then either remove the assignment or
  // use a local variable in place of references to the constant:
  //
  // ```dart
  // const c = 0;
  //
  // void f() {
  //   var v = 1;
  //   print(v);
  // }
  // ```
  static const CompileTimeErrorCode ASSIGNMENT_TO_CONST = CompileTimeErrorCode(
    'ASSIGNMENT_TO_CONST',
    "Constant variables can't be assigned a value.",
    correctionMessage:
        "Try removing the assignment, or remove the modifier 'const' from the variable.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the final variable
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when it finds an invocation of a
  // setter, but there's no setter because the field with the same name was
  // declared to be `final` or `const`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `v` is final:
  //
  // ```dart
  // class C {
  //   final v = 0;
  // }
  //
  // f(C c) {
  //   c.[!v!] = 1;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If you need to be able to set the value of the field, then remove the
  // modifier `final` from the field:
  //
  // ```dart
  // class C {
  //   int v = 0;
  // }
  //
  // f(C c) {
  //   c.v = 1;
  // }
  // ```
  static const CompileTimeErrorCode ASSIGNMENT_TO_FINAL = CompileTimeErrorCode(
    'ASSIGNMENT_TO_FINAL',
    "'{0}' can't be used as a setter because it's final.",
    correctionMessage:
        "Try finding a different setter, or making '{0}' non-final.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a local variable that was
  // declared to be final is assigned after it was initialized.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `x` is final, so it
  // can't have a value assigned to it after it was initialized:
  //
  // ```dart
  // void f() {
  //   final x = 0;
  //   [!x!] = 3;
  //   print(x);
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the keyword `final`, and replace it with `var` if there's no type
  // annotation:
  //
  // ```dart
  // void f() {
  //   var x = 0;
  //   x = 3;
  //   print(x);
  // }
  // ```
  static const CompileTimeErrorCode ASSIGNMENT_TO_FINAL_LOCAL =
      CompileTimeErrorCode(
    'ASSIGNMENT_TO_FINAL_LOCAL',
    "The final variable '{0}' can only be set once.",
    correctionMessage: "Try making '{0}' non-final.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a reference to a setter is
  // found; there is no setter defined for the type; but there is a getter
  // defined with the same name.
  //
  // #### Example
  //
  // The following code produces this diagnostic because there is no setter
  // named `x` in `C`, but there is a getter named `x`:
  //
  // ```dart
  // class C {
  //   int get x => 0;
  //   set y(int p) {}
  // }
  //
  // void f(C c) {
  //   c.[!x!] = 1;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If you want to invoke an existing setter, then correct the name:
  //
  // ```dart
  // class C {
  //   int get x => 0;
  //   set y(int p) {}
  // }
  //
  // void f(C c) {
  //   c.y = 1;
  // }
  // ```
  //
  // If you want to invoke the setter but it just doesn't exist yet, then
  // declare it:
  //
  // ```dart
  // class C {
  //   int get x => 0;
  //   set x(int p) {}
  //   set y(int p) {}
  // }
  //
  // void f(C c) {
  //   c.x = 1;
  // }
  // ```
  static const CompileTimeErrorCode ASSIGNMENT_TO_FINAL_NO_SETTER =
      CompileTimeErrorCode(
    'ASSIGNMENT_TO_FINAL_NO_SETTER',
    "There isn’t a setter named '{0}' in class '{1}'.",
    correctionMessage:
        "Try correcting the name to reference an existing setter, or declare the setter.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the name of a function appears
  // on the left-hand side of an assignment expression.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the assignment to the
  // function `f` is invalid:
  //
  // ```dart
  // void f() {}
  //
  // void g() {
  //   [!f!] = () {};
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the right-hand side should be assigned to something else, such as a
  // local variable, then change the left-hand side:
  //
  // ```dart
  // void f() {}
  //
  // void g() {
  //   var x = () {};
  //   print(x);
  // }
  // ```
  //
  // If the intent is to change the implementation of the function, then define
  // a function-valued variable instead of a function:
  //
  // ```dart
  // void Function() f = () {};
  //
  // void g() {
  //   f = () {};
  // }
  // ```
  static const CompileTimeErrorCode ASSIGNMENT_TO_FUNCTION =
      CompileTimeErrorCode(
    'ASSIGNMENT_TO_FUNCTION',
    "Functions can't be assigned a value.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the target of an assignment is a
  // method.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `f` can't be assigned a
  // value because it's a method:
  //
  // ```dart
  // class C {
  //   void f() {}
  //
  //   void g() {
  //     [!f!] = null;
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // Rewrite the code so that there isn't an assignment to a method.
  static const CompileTimeErrorCode ASSIGNMENT_TO_METHOD = CompileTimeErrorCode(
    'ASSIGNMENT_TO_METHOD',
    "Methods can't be assigned a value.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the name of a type name appears
  // on the left-hand side of an assignment expression.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the assignment to the
  // class `C` is invalid:
  //
  // ```dart
  // class C {}
  //
  // void f() {
  //   [!C!] = null;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the right-hand side should be assigned to something else, such as a
  // local variable, then change the left-hand side:
  //
  // ```dart
  // void f() {}
  //
  // void g() {
  //   var c = null;
  //   print(c);
  // }
  // ```
  static const CompileTimeErrorCode ASSIGNMENT_TO_TYPE = CompileTimeErrorCode(
    'ASSIGNMENT_TO_TYPE',
    "Types can't be assigned a value.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an async for-in loop is found in
  // a function or method whose body isn't marked as being either `async` or
  // `async*`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the body of `f` isn't
  // marked as being either `async` or `async*`, but `f` contains an async
  // for-in loop:
  //
  // ```dart
  // void f(list) {
  //   await for (var e [!in!] list) {
  //     print(e);
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the function should return a `Future`, then mark the body with `async`:
  //
  // ```dart
  // Future<void> f(list) async {
  //   await for (var e in list) {
  //     print(e);
  //   }
  // }
  // ```
  //
  // If the function should return a `Stream` of values, then mark the body with
  // `async*`:
  //
  // ```dart
  // Stream<void> f(list) async* {
  //   await for (var e in list) {
  //     print(e);
  //   }
  // }
  // ```
  //
  // If the function should be synchronous, then remove the `await` before the
  // loop:
  //
  // ```dart
  // void f(list) {
  //   for (var e in list) {
  //     print(e);
  //   }
  // }
  // ```
  static const CompileTimeErrorCode ASYNC_FOR_IN_WRONG_CONTEXT =
      CompileTimeErrorCode(
    'ASYNC_FOR_IN_WRONG_CONTEXT',
    "The async for-in loop can only be used in an async function.",
    correctionMessage:
        "Try marking the function body with either 'async' or 'async*', or removing the 'await' before the for-in loop.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a local variable that has the
  // `late` modifier uses an `await` expression in the initializer.
  //
  // #### Example
  //
  // The following code produces this diagnostic because an `await` expression
  // is used in the initializer for `v`, a local variable that is marked `late`:
  //
  // ```dart
  // Future<int> f() async {
  //   late var v = [!await!] 42;
  //   return v;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the initializer can be rewritten to not use `await`, then rewrite it:
  //
  // ```dart
  // Future<int> f() async {
  //   late var v = 42;
  //   return v;
  // }
  // ```
  //
  // If the initializer can't be rewritten, then remove the `late` modifier:
  //
  // ```dart
  // Future<int> f() async {
  //   var v = await 42;
  //   return v;
  // }
  // ```
  static const CompileTimeErrorCode AWAIT_IN_LATE_LOCAL_VARIABLE_INITIALIZER =
      CompileTimeErrorCode(
    'AWAIT_IN_LATE_LOCAL_VARIABLE_INITIALIZER',
    "The 'await' expression can't be used in a 'late' local variable's initializer.",
    correctionMessage:
        "Try removing the 'late' modifier, or rewriting the initializer without using the 'await' expression.",
    hasPublishedDocs: true,
  );

  /**
   * 16.30 Await Expressions: It is a compile-time error if the function
   * immediately enclosing _a_ is not declared asynchronous. (Where _a_ is the
   * await expression.)
   */
  static const CompileTimeErrorCode AWAIT_IN_WRONG_CONTEXT =
      CompileTimeErrorCode(
    'AWAIT_IN_WRONG_CONTEXT',
    "The await expression can only be used in an async function.",
    correctionMessage:
        "Try marking the function body with either 'async' or 'async*'.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a method or function has a
  // return type that's [potentially non-nullable][] but would implicitly return
  // `null` if control reached the end of the function.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because the method `m` has an
  // implicit return of `null` inserted at the end of the method, but the method
  // is declared to not return `null`:
  //
  // ```dart
  // class C {
  //   int [!m!](int t) {
  //     print(t);
  //   }
  // }
  // ```
  //
  // The following code produces this diagnostic because the method `m` has an
  // implicit return of `null` inserted at the end of the method, but because
  // the class `C` can be instantiated with a non-nullable type argument, the
  // method is effectively declared to not return `null`:
  //
  // ```dart
  // class C<T> {
  //   T [!m!](T t) {
  //     print(t);
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If there's a reasonable value that can be returned, then add a `return`
  // statement at the end of the method:
  //
  // ```dart
  // class C<T> {
  //   T m(T t) {
  //     print(t);
  //     return t;
  //   }
  // }
  // ```
  //
  // If the method won't reach the implicit return, then add a `throw` at the
  // end of the method:
  //
  // ```dart
  // class C<T> {
  //   T m(T t) {
  //     print(t);
  //     throw '';
  //   }
  // }
  // ```
  //
  // If the method intentionally returns `null` at the end, then change the
  // return type so that it's valid to return `null`:
  //
  // ```dart
  // class C<T> {
  //   T? m(T t) {
  //     print(t);
  //   }
  // }
  // ```
  static const CompileTimeErrorCode BODY_MIGHT_COMPLETE_NORMALLY =
      CompileTimeErrorCode(
    'BODY_MIGHT_COMPLETE_NORMALLY',
    "The body might complete normally, causing 'null' to be returned, but the return type is a potentially non-nullable type.",
    correctionMessage:
        "Try adding either a return or a throw statement at the end.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a break in a case clause inside
  // a switch statement has a label that is associated with another case clause.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the label `l` is
  // associated with the case clause for `0`:
  //
  // ```dart
  // void f(int i) {
  //   switch (i) {
  //     l: case 0:
  //       break;
  //     case 1:
  //       break [!l!];
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the intent is to transfer control to the statement after the switch,
  // then remove the label from the break statement:
  //
  // ```dart
  // void f(int i) {
  //   switch (i) {
  //     case 0:
  //       break;
  //     case 1:
  //       break;
  //   }
  // }
  // ```
  //
  // If the intent is to transfer control to a different case block, then use
  // `continue` rather than `break`:
  //
  // ```dart
  // void f(int i) {
  //   switch (i) {
  //     l: case 0:
  //       break;
  //     case 1:
  //       continue l;
  //   }
  // }
  // ```
  static const CompileTimeErrorCode BREAK_LABEL_ON_SWITCH_MEMBER =
      CompileTimeErrorCode(
    'BREAK_LABEL_ON_SWITCH_MEMBER',
    "A break label resolves to the 'case' or 'default' statement.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the built-in identifier that is being used
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the name used in the declaration
  // of a class, extension, mixin, typedef, type parameter, or import prefix is
  // a built-in identifier. Built-in identifiers can’t be used to name any of
  // these kinds of declarations.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `mixin` is a built-in
  // identifier:
  //
  // ```dart
  // extension [!mixin!] on int {}
  // ```
  //
  // #### Common fixes
  //
  // Choose a different name for the declaration.
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_EXTENSION_NAME =
      CompileTimeErrorCode(
    'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    "The built-in identifier '{0}' can't be used as an extension name.",
    correctionMessage: "Try choosing a different name for the extension.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_EXTENSION_NAME',
  );

  /**
   * Parameters:
   * 0: the built-in identifier that is being used
   */
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_PREFIX_NAME =
      CompileTimeErrorCode(
    'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    "The built-in identifier '{0}' can't be used as a prefix name.",
    correctionMessage: "Try choosing a different name for the prefix.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_PREFIX_NAME',
  );

  /**
   * Parameters:
   * 0: the built-in identifier that is being used
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a built-in identifier is used
  // where a type name is expected.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `import` can't be used
  // as a type because it's a built-in identifier:
  //
  // ```dart
  // [!import!]<int> x;
  // ```
  //
  // #### Common fixes
  //
  // Replace the built-in identifier with the name of a valid type:
  //
  // ```dart
  // List<int> x;
  // ```
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPE =
      CompileTimeErrorCode(
    'BUILT_IN_IDENTIFIER_AS_TYPE',
    "The built-in identifier '{0}' can't be used as a type.",
    correctionMessage: "Try correcting the name to match an existing type.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the built-in identifier that is being used
   */
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME =
      CompileTimeErrorCode(
    'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    "The built-in identifier '{0}' can't be used as a typedef name.",
    correctionMessage: "Try choosing a different name for the typedef.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME',
  );

  /**
   * Parameters:
   * 0: the built-in identifier that is being used
   */
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPE_NAME =
      CompileTimeErrorCode(
    'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    "The built-in identifier '{0}' can't be used as a type name.",
    correctionMessage: "Try choosing a different name for the type.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_TYPE_NAME',
  );

  /**
   * Parameters:
   * 0: the built-in identifier that is being used
   */
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME =
      CompileTimeErrorCode(
    'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    "The built-in identifier '{0}' can't be used as a type parameter name.",
    correctionMessage: "Try choosing a different name for the type parameter.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME',
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the last statement in a `case`
  // block isn't one of the required terminators: `break`, `continue`,
  // `rethrow`, `return`, or `throw`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the `case` block ends
  // with an assignment:
  //
  // ```dart
  // %language=2.9
  // void f(int x) {
  //   switch (x) {
  //     [!case!] 0:
  //       x += 2;
  //     default:
  //       x += 1;
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // Add one of the required terminators:
  //
  // ```dart
  // %language=2.9
  // void f(int x) {
  //   switch (x) {
  //     case 0:
  //       x += 2;
  //       break;
  //     default:
  //       x += 1;
  //   }
  // }
  // ```
  static const CompileTimeErrorCode CASE_BLOCK_NOT_TERMINATED =
      CompileTimeErrorCode(
    'CASE_BLOCK_NOT_TERMINATED',
    "The last statement of the 'case' should be 'break', 'continue', 'rethrow', 'return', or 'throw'.",
    correctionMessage: "Try adding one of the required statements.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the this of the switch case expression
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the type of the expression
  // following the keyword `case` has an implementation of the `==` operator
  // other than the one in `Object`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the expression
  // following the keyword `case` (`C(0)`) has the type `C`, and the class `C`
  // overrides the `==` operator:
  //
  // ```dart
  // class C {
  //   final int value;
  //
  //   const C(this.value);
  //
  //   bool operator ==(Object other) {
  //     return false;
  //   }
  // }
  //
  // void f(C c) {
  //   switch (c) {
  //     case [!C(0)!]:
  //       break;
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If there isn't a strong reason not to do so, then rewrite the code to use
  // an if-else structure:
  //
  // ```dart
  // class C {
  //   final int value;
  //
  //   const C(this.value);
  //
  //   bool operator ==(Object other) {
  //     return false;
  //   }
  // }
  //
  // void f(C c) {
  //   if (c == C(0)) {
  //     // ...
  //   }
  // }
  // ```
  //
  // If you can't rewrite the switch statement and the implementation of `==`
  // isn't necessary, then remove it:
  //
  // ```dart
  // class C {
  //   final int value;
  //
  //   const C(this.value);
  // }
  //
  // void f(C c) {
  //   switch (c) {
  //     case C(0):
  //       break;
  //   }
  // }
  // ```
  //
  // If you can't rewrite the switch statement and you can't remove the
  // definition of `==`, then find some other value that can be used to control
  // the switch:
  //
  // ```dart
  // class C {
  //   final int value;
  //
  //   const C(this.value);
  //
  //   bool operator ==(Object other) {
  //     return false;
  //   }
  // }
  //
  // void f(C c) {
  //   switch (c.value) {
  //     case 0:
  //       break;
  //   }
  // }
  // ```
  static const CompileTimeErrorCode CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS =
      CompileTimeErrorCode(
    'CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS',
    "The switch case expression type '{0}' can't override the '==' operator.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the type of the case expression
   * 1: the type of the switch expression
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the expression following `case`
  // in a `switch` statement has a static type that isn't a subtype of the
  // static type of the expression following `switch`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `1` is an `int`, which
  // isn't a subtype of `String` (the type of `s`):
  //
  // ```dart
  // void f(String s) {
  //   switch (s) {
  //     case [!1!]:
  //       break;
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the value of the `case` expression is wrong, then change the `case`
  // expression so that it has the required type:
  //
  // ```dart
  // void f(String s) {
  //   switch (s) {
  //     case '1':
  //       break;
  //   }
  // }
  // ```
  //
  // If the value of the `case` expression is correct, then change the `switch`
  // expression to have the required type:
  //
  // ```dart
  // void f(int s) {
  //   switch (s) {
  //     case 1:
  //       break;
  //   }
  // }
  // ```
  static const CompileTimeErrorCode
      CASE_EXPRESSION_TYPE_IS_NOT_SWITCH_EXPRESSION_SUBTYPE =
      CompileTimeErrorCode(
    'CASE_EXPRESSION_TYPE_IS_NOT_SWITCH_EXPRESSION_SUBTYPE',
    "The switch case expression type '{0}' must be a subtype of the switch expression type '{1}'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the name following the `as` in a
  // cast expression is defined to be something other than a type.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `x` is a variable, not
  // a type:
  //
  // ```dart
  // num x = 0;
  // int y = x as [!x!];
  // ```
  //
  // #### Common fixes
  //
  // Replace the name with the name of a type:
  //
  // ```dart
  // num x = 0;
  // int y = x as int;
  // ```
  static const CompileTimeErrorCode CAST_TO_NON_TYPE = CompileTimeErrorCode(
    'CAST_TO_NON_TYPE',
    "The name '{0}' isn't a type, so it can't be used in an 'as' expression.",
    correctionMessage:
        "Try changing the name to the name of an existing type, or creating a type with the name '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the member
   */
  static const CompileTimeErrorCode
      CLASS_INSTANTIATION_ACCESS_TO_INSTANCE_MEMBER = CompileTimeErrorCode(
    'CLASS_INSTANTIATION_ACCESS_TO_MEMBER',
    "The instance member '{0}' can't be accessed on a class instantiation.",
    correctionMessage:
        "Try changing the member name to the name of a constructor.",
    uniqueName: 'CLASS_INSTANTIATION_ACCESS_TO_INSTANCE_MEMBER',
  );

  /**
   * Parameters:
   * 0: the name of the member
   */
  static const CompileTimeErrorCode
      CLASS_INSTANTIATION_ACCESS_TO_STATIC_MEMBER = CompileTimeErrorCode(
    'CLASS_INSTANTIATION_ACCESS_TO_MEMBER',
    "The static member '{0}' can't be accessed on a class instantiation.",
    correctionMessage:
        "Try removing the type arguments from the class name, or changing the member name to the name of a constructor.",
    uniqueName: 'CLASS_INSTANTIATION_ACCESS_TO_STATIC_MEMBER',
  );

  /**
   * Parameters:
   * 0: the name of the member
   */
  static const CompileTimeErrorCode
      CLASS_INSTANTIATION_ACCESS_TO_UNKNOWN_MEMBER = CompileTimeErrorCode(
    'CLASS_INSTANTIATION_ACCESS_TO_MEMBER',
    "The class '{0} doesn't have a constructor named '{1}.",
    correctionMessage:
        "Try invoking a different constructor, or defining a constructor named '{1}'.",
    uniqueName: 'CLASS_INSTANTIATION_ACCESS_TO_UNKNOWN_MEMBER',
  );

  /**
   * Parameters:
   * 0: the name of the abstract method
   * 1: the name of the enclosing class
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a member of a concrete class is
  // found that doesn't have a concrete implementation. Concrete classes aren't
  // allowed to contain abstract members.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `m` is an abstract
  // method but `C` isn't an abstract class:
  //
  // ```dart
  // class C {
  //   [!void m();!]
  // }
  // ```
  //
  // #### Common fixes
  //
  // If it's valid to create instances of the class, provide an implementation
  // for the member:
  //
  // ```dart
  // class C {
  //   void m() {}
  // }
  // ```
  //
  // If it isn't valid to create instances of the class, mark the class as being
  // abstract:
  //
  // ```dart
  // abstract class C {
  //   void m();
  // }
  // ```
  static const CompileTimeErrorCode CONCRETE_CLASS_WITH_ABSTRACT_MEMBER =
      CompileTimeErrorCode(
    'CONCRETE_CLASS_WITH_ABSTRACT_MEMBER',
    "'{0}' must have a method body because '{1}' isn't abstract.",
    correctionMessage: "Try making '{1}' abstract, or adding a body to '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the constructor and field
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a named constructor and either a
  // static method or static field have the same name. Both are accessed using
  // the name of the class, so having the same name makes the reference
  // ambiguous.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because the static field `foo`
  // and the named constructor `foo` have the same name:
  //
  // ```dart
  // class C {
  //   C.[!foo!]();
  //   static int foo = 0;
  // }
  // ```
  //
  // The following code produces this diagnostic because the static method `foo`
  // and the named constructor `foo` have the same name:
  //
  // ```dart
  // class C {
  //   C.[!foo!]();
  //   static void foo() {}
  // }
  // ```
  //
  // #### Common fixes
  //
  // Rename either the member or the constructor.
  static const CompileTimeErrorCode CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD =
      CompileTimeErrorCode(
    'CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER',
    "'{0}' can't be used to name both a constructor and a static field in this class.",
    correctionMessage: "Try renaming either the constructor or the field.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD',
  );

  /**
   * Parameters:
   * 0: the name of the constructor and getter
   */
  static const CompileTimeErrorCode CONFLICTING_CONSTRUCTOR_AND_STATIC_GETTER =
      CompileTimeErrorCode(
    'CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER',
    "'{0}' can't be used to name both a constructor and a static getter in this class.",
    correctionMessage: "Try renaming either the constructor or the getter.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_GETTER',
  );

  /**
   * Parameters:
   * 0: the name of the constructor
   */
  static const CompileTimeErrorCode CONFLICTING_CONSTRUCTOR_AND_STATIC_METHOD =
      CompileTimeErrorCode(
    'CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER',
    "'{0}' can't be used to name both a constructor and a static method in this class.",
    correctionMessage: "Try renaming either the constructor or the method.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_METHOD',
  );

  /**
   * Parameters:
   * 0: the name of the constructor and setter
   */
  static const CompileTimeErrorCode CONFLICTING_CONSTRUCTOR_AND_STATIC_SETTER =
      CompileTimeErrorCode(
    'CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER',
    "'{0}' can't be used to name both a constructor and a static setter in this class.",
    correctionMessage: "Try renaming either the constructor or the setter.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_SETTER',
  );

  /**
   * 10.11 Class Member Conflicts: Let `C` be a class. It is a compile-time
   * error if `C` declares a getter or a setter with basename `n`, and has a
   * method named `n`.
   *
   * Parameters:
   * 0: the name of the class defining the conflicting field
   * 1: the name of the conflicting field
   * 2: the name of the class defining the method with which the field conflicts
   */
  static const CompileTimeErrorCode CONFLICTING_FIELD_AND_METHOD =
      CompileTimeErrorCode(
    'CONFLICTING_FIELD_AND_METHOD',
    "Class '{0}' can't define field '{1}' and have method '{2}.{1}' with the same name.",
    correctionMessage:
        "Try converting the getter to a method, or renaming the field to a name that doesn't conflict.",
  );

  /**
   * Parameters:
   * 0: the name of the class implementing the conflicting interface
   * 1: the first conflicting type
   * 2: the second conflicting type
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a class attempts to implement a
  // generic interface multiple times, and the values of the type arguments
  // aren't the same.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `C` is defined to
  // implement both `I<int>` (because it extends `A`) and `I<String>` (because
  // it implements`B`), but `int` and `String` aren't the same type:
  //
  // ```dart
  // class I<T> {}
  // class A implements I<int> {}
  // class B implements I<String> {}
  // class [!C!] extends A implements B {}
  // ```
  //
  // #### Common fixes
  //
  // Rework the type hierarchy to avoid this situation. For example, you might
  // make one or both of the inherited types generic so that `C` can specify the
  // same type for both type arguments:
  //
  // ```dart
  // class I<T> {}
  // class A<S> implements I<S> {}
  // class B implements I<String> {}
  // class C extends A<String> implements B {}
  // ```
  static const CompileTimeErrorCode CONFLICTING_GENERIC_INTERFACES =
      CompileTimeErrorCode(
    'CONFLICTING_GENERIC_INTERFACES',
    "The class '{0}' can't implement both '{1}' and '{2}' because the type arguments are different.",
    hasPublishedDocs: true,
  );

  /**
   * 10.11 Class Member Conflicts: Let `C` be a class. It is a compile-time
   * error if `C` declares a method named `n`, and has a getter or a setter
   * with basename `n`.
   *
   * Parameters:
   * 0: the name of the class defining the conflicting method
   * 1: the name of the conflicting method
   * 2: the name of the class defining the field with which the method conflicts
   */
  static const CompileTimeErrorCode CONFLICTING_METHOD_AND_FIELD =
      CompileTimeErrorCode(
    'CONFLICTING_METHOD_AND_FIELD',
    "Class '{0}' can't define method '{1}' and have field '{2}.{1}' with the same name.",
    correctionMessage:
        "Try converting the method to a getter, or renaming the method to a name that doesn't conflict.",
  );

  /**
   * 10.11 Class Member Conflicts: Let `C` be a class. It is a compile-time
   * error if `C` declares a static member with basename `n`, and has an
   * instance member with basename `n`.
   *
   * Parameters:
   * 0: the name of the class defining the conflicting member
   * 1: the name of the conflicting static member
   * 2: the name of the class defining the field with which the method conflicts
   */
  static const CompileTimeErrorCode CONFLICTING_STATIC_AND_INSTANCE =
      CompileTimeErrorCode(
    'CONFLICTING_STATIC_AND_INSTANCE',
    "Class '{0}' can't define static member '{1}' and have instance member '{2}.{1}' with the same name.",
    correctionMessage:
        "Try renaming the member to a name that doesn't conflict.",
  );

  /**
   * Parameters:
   * 0: the name of the type variable
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a class, mixin, or extension
  // declaration declares a type parameter with the same name as the class,
  // mixin, or extension that declares it.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the type parameter `C`
  // has the same name as the class `C` of which it's a part:
  //
  // ```dart
  // class C<[!C!]> {}
  // ```
  //
  // #### Common fixes
  //
  // Rename either the type parameter, or the class, mixin, or extension:
  //
  // ```dart
  // class C<T> {}
  // ```
  static const CompileTimeErrorCode CONFLICTING_TYPE_VARIABLE_AND_CLASS =
      CompileTimeErrorCode(
    'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
    "'{0}' can't be used to name both a type variable and the class in which the type variable is defined.",
    correctionMessage: "Try renaming either the type variable or the class.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_CLASS',
  );

  /**
   * Parameters:
   * 0: the name of the type variable
   */
  static const CompileTimeErrorCode CONFLICTING_TYPE_VARIABLE_AND_EXTENSION =
      CompileTimeErrorCode(
    'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
    "'{0}' can't be used to name both a type variable and the extension in which the type variable is defined.",
    correctionMessage:
        "Try renaming either the type variable or the extension.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_EXTENSION',
  );

  /**
   * Parameters:
   * 0: the name of the type variable
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a class, mixin, or extension
  // declaration declares a type parameter with the same name as one of the
  // members of the class, mixin, or extension that declares it.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the type parameter `T`
  // has the same name as the field `T`:
  //
  // ```dart
  // class C<[!T!]> {
  //   int T = 0;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Rename either the type parameter or the member with which it conflicts:
  //
  // ```dart
  // class C<T> {
  //   int total = 0;
  // }
  // ```
  static const CompileTimeErrorCode CONFLICTING_TYPE_VARIABLE_AND_MEMBER_CLASS =
      CompileTimeErrorCode(
    'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
    "'{0}' can't be used to name both a type variable and a member in this class.",
    correctionMessage: "Try renaming either the type variable or the member.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER_CLASS',
  );

  /**
   * Parameters:
   * 0: the name of the type variable
   */
  static const CompileTimeErrorCode
      CONFLICTING_TYPE_VARIABLE_AND_MEMBER_EXTENSION = CompileTimeErrorCode(
    'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
    "'{0}' can't be used to name both a type variable and a member in this extension.",
    correctionMessage: "Try renaming either the type variable or the member.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER_EXTENSION',
  );

  /**
   * Parameters:
   * 0: the name of the type variable
   */
  static const CompileTimeErrorCode CONFLICTING_TYPE_VARIABLE_AND_MEMBER_MIXIN =
      CompileTimeErrorCode(
    'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
    "'{0}' can't be used to name both a type variable and a member in this mixin.",
    correctionMessage: "Try renaming either the type variable or the member.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER_MIXIN',
  );

  /**
   * Parameters:
   * 0: the name of the type variable
   */
  static const CompileTimeErrorCode CONFLICTING_TYPE_VARIABLE_AND_MIXIN =
      CompileTimeErrorCode(
    'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
    "'{0}' can't be used to name both a type variable and the mixin in which the type variable is defined.",
    correctionMessage: "Try renaming either the type variable or the mixin.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_MIXIN',
  );

  /**
   * 16.12.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   */
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH =
      CompileTimeErrorCode(
    'CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH',
    "In a const constructor, a value of type '{0}' can't be assigned to the field '{1}', which has type '{2}'.",
    correctionMessage: "Try using a subtype, or removing the keyword 'const'.",
  );

  /**
   * Parameters:
   * 0: the type of the runtime value of the argument
   * 1: the static type of the parameter
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the runtime type of a constant
  // value can't be assigned to the static type of a constant constructor's
  // parameter.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the runtime type of `i`
  // is `int`, which can't be assigned to the static type of `s`:
  //
  // ```dart
  // class C {
  //   final String s;
  //
  //   const C(this.s);
  // }
  //
  // const dynamic i = 0;
  //
  // void f() {
  //   const C([!i!]);
  // }
  // ```
  //
  // #### Common fixes
  //
  // Pass a value of the correct type to the constructor:
  //
  // ```dart
  // class C {
  //   final String s;
  //
  //   const C(this.s);
  // }
  //
  // const dynamic i = 0;
  //
  // void f() {
  //   const C('$i');
  // }
  // ```
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH =
      CompileTimeErrorCode(
    'CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH',
    "A value of type '{0}' can't be assigned to a parameter of type '{1}' in a const constructor.",
    correctionMessage: "Try using a subtype, or removing the keyword 'const'.",
    hasPublishedDocs: true,
  );

  /**
   * 16.12.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   */
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_THROWS_EXCEPTION =
      CompileTimeErrorCode(
    'CONST_CONSTRUCTOR_THROWS_EXCEPTION',
    "Const constructors can't throw exceptions.",
    correctionMessage:
        "Try removing the throw statement, or removing the keyword 'const'.",
  );

  /**
   * Parameters:
   * 0: the name of the field
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a constructor has the keyword
  // `const`, but a field in the class is initialized to a non-constant value.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the field `s` is
  // initialized to a non-constant value:
  //
  // ```dart
  // class C {
  //   final String s = 3.toString();
  //   [!const!] C();
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the field can be initialized to a constant value, then change the
  // initializer to a constant expression:
  //
  // ```dart
  // class C {
  //   final String s = '3';
  //   const C();
  // }
  // ```
  //
  // If the field can't be initialized to a constant value, then remove the
  // keyword `const` from the constructor:
  //
  // ```dart
  // class C {
  //   final String s = 3.toString();
  //   C();
  // }
  // ```
  static const CompileTimeErrorCode
      CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST =
      CompileTimeErrorCode(
    'CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST',
    "Can't define the 'const' constructor because the field '{0}' is initialized with a non-constant value.",
    correctionMessage:
        "Try initializing the field to a constant value, or removing the keyword 'const' from the constructor.",
    hasPublishedDocs: true,
  );

  /**
   * 7.6.3 Constant Constructors: The superinitializer that appears, explicitly
   * or implicitly, in the initializer list of a constant constructor must
   * specify a constant constructor of the superclass of the immediately
   * enclosing class or a compile-time error occurs.
   *
   * 12.1 Mixin Application: For each generative constructor named ... an
   * implicitly declared constructor named ... is declared. If Sq is a
   * generative const constructor, and M does not declare any fields, Cq is
   * also a const constructor.
   *
   * Parameters:
   * 0: the name of the instance field.
   */
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD =
      CompileTimeErrorCode(
    'CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD',
    "This constructor can't be declared 'const' because a mixin adds the instance field: {0}.",
    correctionMessage:
        "Try removing the 'const' keyword or removing the 'with' clause from the class declaration, or removing the field from the mixin class.",
  );

  /**
   * 7.6.3 Constant Constructors: The superinitializer that appears, explicitly
   * or implicitly, in the initializer list of a constant constructor must
   * specify a constant constructor of the superclass of the immediately
   * enclosing class or a compile-time error occurs.
   *
   * 12.1 Mixin Application: For each generative constructor named ... an
   * implicitly declared constructor named ... is declared. If Sq is a
   * generative const constructor, and M does not declare any fields, Cq is
   * also a const constructor.
   *
   * Parameters:
   * 0: the names of the instance fields.
   */
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELDS =
      CompileTimeErrorCode(
    'CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD',
    "This constructor can't be declared 'const' because the mixins add the instance fields: {0}.",
    correctionMessage:
        "Try removing the 'const' keyword or removing the 'with' clause from the class declaration, or removing the fields from the mixin classes.",
    uniqueName: 'CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELDS',
  );

  /**
   * Parameters:
   * 0: the name of the superclass
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a constructor that is marked as
  // `const` invokes a constructor from its superclass that isn't marked as
  // `const`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the `const` constructor
  // in `B` invokes the constructor `nonConst` from the class `A`, and the
  // superclass constructor isn't a `const` constructor:
  //
  // ```dart
  // class A {
  //   const A();
  //   A.nonConst();
  // }
  //
  // class B extends A {
  //   const B() : [!super.nonConst()!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // If it isn't essential to invoke the superclass constructor that is
  // currently being invoked, then invoke a constant constructor from the
  // superclass:
  //
  // ```dart
  // class A {
  //   const A();
  //   A.nonConst();
  // }
  //
  // class B extends A {
  //   const B() : super();
  // }
  // ```
  //
  // If it's essential that the current constructor be invoked and if you can
  // modify it, then add `const` to the constructor in the superclass:
  //
  // ```dart
  // class A {
  //   const A();
  //   const A.nonConst();
  // }
  //
  // class B extends A {
  //   const B() : super.nonConst();
  // }
  // ```
  //
  // If it's essential that the current constructor be invoked and you can't
  // modify it, then remove `const` from the constructor in the subclass:
  //
  // ```dart
  // class A {
  //   const A();
  //   A.nonConst();
  // }
  //
  // class B extends A {
  //   B() : super.nonConst();
  // }
  // ```
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER =
      CompileTimeErrorCode(
    'CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER',
    "A constant constructor can't call a non-constant super constructor of '{0}'.",
    correctionMessage:
        "Try calling a constant constructor in the superclass, or removing the keyword 'const' from the constructor.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a constructor is marked as a
  // const constructor, but the constructor is defined in a class that has at
  // least one non-final instance field (either directly or by inheritance).
  //
  // #### Example
  //
  // The following code produces this diagnostic because the field `x` isn't
  // final:
  //
  // ```dart
  // class C {
  //   int x;
  //
  //   const [!C!](this.x);
  // }
  // ```
  //
  // #### Common fixes
  //
  // If it's possible to mark all of the fields as final, then do so:
  //
  // ```dart
  // class C {
  //   final int x;
  //
  //   const C(this.x);
  // }
  // ```
  //
  // If it isn't possible to mark all of the fields as final, then remove the
  // keyword `const` from the constructor:
  //
  // ```dart
  // class C {
  //   int x;
  //
  //   C(this.x);
  // }
  // ```
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD =
      CompileTimeErrorCode(
    'CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD',
    "Can't define a const constructor for a class with non-final fields.",
    correctionMessage:
        "Try making all of the fields final, or removing the keyword 'const' from the constructor.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a class from a library that is
  // imported using a deferred import is used to create a `const` object.
  // Constants are evaluated at compile time, and classes from deferred
  // libraries aren't available at compile time.
  //
  // For more information, see the language tour's coverage of
  // [deferred loading](https://dart.dev/guides/language/language-tour#lazily-loading-a-library).
  //
  // #### Example
  //
  // The following code produces this diagnostic because it attempts to create a
  // `const` instance of a class from a deferred library:
  //
  // ```dart
  // import 'dart:convert' deferred as convert;
  //
  // const json2 = [!convert.JsonCodec()!];
  // ```
  //
  // #### Common fixes
  //
  // If the object isn't required to be a constant, then change the code so that
  // a non-constant instance is created:
  //
  // ```dart
  // import 'dart:convert' deferred as convert;
  //
  // final json2 = convert.JsonCodec();
  // ```
  //
  // If the object must be a constant, then remove `deferred` from the import
  // directive:
  //
  // ```dart
  // import 'dart:convert' as convert;
  //
  // const json2 = convert.JsonCodec();
  // ```
  static const CompileTimeErrorCode CONST_DEFERRED_CLASS = CompileTimeErrorCode(
    'CONST_DEFERRED_CLASS',
    "Deferred classes can't be created with 'const'.",
    correctionMessage:
        "Try using 'new' to create the instance, or changing the import to not be deferred.",
    hasPublishedDocs: true,
  );

  /**
   * 16.12.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   */
  static const CompileTimeErrorCode CONST_EVAL_THROWS_EXCEPTION =
      CompileTimeErrorCode(
    'CONST_EVAL_THROWS_EXCEPTION',
    "Evaluation of this constant expression throws an exception.",
  );

  /**
   * 16.12.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   */
  static const CompileTimeErrorCode CONST_EVAL_THROWS_IDBZE =
      CompileTimeErrorCode(
    'CONST_EVAL_THROWS_IDBZE',
    "Evaluation of this constant expression throws an IntegerDivisionByZeroException.",
  );

  /**
   * 16.12.2 Const: An expression of one of the forms !e, e1 && e2 or e1 || e2,
   * where e, e1 and e2 are constant expressions that evaluate to a boolean
   * value.
   */
  static const CompileTimeErrorCode CONST_EVAL_TYPE_BOOL = CompileTimeErrorCode(
    'CONST_EVAL_TYPE_BOOL',
    "In constant expressions, operands of this operator must be of type 'bool'.",
  );

  /**
   * 16.12.2 Const: An expression of one of the forms !e, e1 && e2 or e1 || e2,
   * where e, e1 and e2 are constant expressions that evaluate to a boolean
   * value.
   */
  static const CompileTimeErrorCode CONST_EVAL_TYPE_BOOL_INT =
      CompileTimeErrorCode(
    'CONST_EVAL_TYPE_BOOL_INT',
    "In constant expressions, operands of this operator must be of type 'bool' or 'int'.",
  );

  /**
   * 16.12.2 Const: An expression of one of the forms e1 == e2 or e1 != e2 where
   * e1 and e2 are constant expressions that evaluate to a numeric, string or
   * boolean value or to null.
   */
  static const CompileTimeErrorCode CONST_EVAL_TYPE_BOOL_NUM_STRING =
      CompileTimeErrorCode(
    'CONST_EVAL_TYPE_BOOL_NUM_STRING',
    "In constant expressions, operands of this operator must be of type 'bool', 'num', 'String' or 'null'.",
  );

  /**
   * 16.12.2 Const: An expression of one of the forms ~e, e1 ^ e2, e1 & e2,
   * e1 | e2, e1 >> e2 or e1 << e2, where e, e1 and e2 are constant expressions
   * that evaluate to an integer value or to null.
   */
  static const CompileTimeErrorCode CONST_EVAL_TYPE_INT = CompileTimeErrorCode(
    'CONST_EVAL_TYPE_INT',
    "In constant expressions, operands of this operator must be of type 'int'.",
  );

  /**
   * 16.12.2 Const: An expression of one of the forms e, e1 + e2, e1 - e2, e1
   * e2, e1 / e2, e1 ~/ e2, e1 > e2, e1 < e2, e1 >= e2, e1 <= e2 or e1 % e2,
   * where e, e1 and e2 are constant expressions that evaluate to a numeric
   * value or to null.
   */
  static const CompileTimeErrorCode CONST_EVAL_TYPE_NUM = CompileTimeErrorCode(
    'CONST_EVAL_TYPE_NUM',
    "In constant expressions, operands of this operator must be of type 'num'.",
  );

  static const CompileTimeErrorCode CONST_EVAL_TYPE_TYPE = CompileTimeErrorCode(
    'CONST_EVAL_TYPE_TYPE',
    "In constant expressions, operands of this operator must be of type 'Type'.",
  );

  /**
   * Parameters:
   * 0: the name of the type of the initializer expression
   * 1: the name of the type of the field
   */
  static const CompileTimeErrorCode CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE =
      CompileTimeErrorCode(
    'FIELD_INITIALIZER_NOT_ASSIGNABLE',
    "The initializer type '{0}' can't be assigned to the field type '{1}' in a const constructor.",
    correctionMessage: "Try using a subtype, or removing the 'const' keyword",
    hasPublishedDocs: true,
    uniqueName: 'CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE',
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a value that isn't statically
  // known to be a constant is assigned to a variable that's declared to be a
  // `const` variable.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `x` isn't declared to
  // be `const`:
  //
  // ```dart
  // var x = 0;
  // const y = [!x!];
  // ```
  //
  // #### Common fixes
  //
  // If the value being assigned can be declared to be `const`, then change the
  // declaration:
  //
  // ```dart
  // const x = 0;
  // const y = x;
  // ```
  //
  // If the value can't be declared to be `const`, then remove the `const`
  // modifier from the variable, possibly using `final` in its place:
  //
  // ```dart
  // var x = 0;
  // final y = x;
  // ```
  static const CompileTimeErrorCode CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE =
      CompileTimeErrorCode(
    'CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE',
    "Const variables must be initialized with a constant value.",
    correctionMessage:
        "Try changing the initializer to be a constant expression.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a `const` variable is
  // initialized using a `const` variable from a library that is imported using
  // a deferred import. Constants are evaluated at compile time, and values from
  // deferred libraries aren't available at compile time.
  //
  // For more information, see the language tour's coverage of
  // [deferred loading](https://dart.dev/guides/language/language-tour#lazily-loading-a-library).
  //
  // #### Example
  //
  // The following code produces this diagnostic because the variable `pi` is
  // being initialized using the constant `math.pi` from the library
  // `dart:math`, and `dart:math` is imported as a deferred library:
  //
  // ```dart
  // import 'dart:math' deferred as math;
  //
  // const pi = [!math.pi!];
  // ```
  //
  // #### Common fixes
  //
  // If you need to reference the value of the constant from the imported
  // library, then remove the keyword `deferred`:
  //
  // ```dart
  // import 'dart:math' as math;
  //
  // const pi = math.pi;
  // ```
  //
  // If you don't need to reference the imported constant, then remove the
  // reference:
  //
  // ```dart
  // const pi = 3.14;
  // ```
  static const CompileTimeErrorCode
      CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY =
      CompileTimeErrorCode(
    'CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used to initialize a 'const' variable.",
    correctionMessage:
        "Try initializing the variable without referencing members of the deferred library, or changing the import to not be deferred.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an instance field is marked as
  // being const.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `f` is an instance
  // field:
  //
  // ```dart
  // class C {
  //   [!const!] int f = 3;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the field needs to be an instance field, then remove the keyword
  // `const`, or replace it with `final`:
  //
  // ```dart
  // class C {
  //   final int f = 3;
  // }
  // ```
  //
  // If the field really should be a const field, then make it a static field:
  //
  // ```dart
  // class C {
  //   static const int f = 3;
  // }
  // ```
  static const CompileTimeErrorCode CONST_INSTANCE_FIELD = CompileTimeErrorCode(
    'CONST_INSTANCE_FIELD',
    "Only static fields can be declared as const.",
    correctionMessage:
        "Try declaring the field as final, or adding the keyword 'static'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the type of the entry's key
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the class of object used as a
  // key in a constant map literal implements the `==` operator. The
  // implementation of constant maps uses the `==` operator, so any
  // implementation other than the one inherited from `Object` requires
  // executing arbitrary code at compile time, which isn't supported.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the constant map
  // contains a key whose type is `C`, and the class `C` overrides the
  // implementation of `==`:
  //
  // ```dart
  // class C {
  //   const C();
  //
  //   bool operator ==(Object other) => true;
  // }
  //
  // const map = {[!C()!] : 0};
  // ```
  //
  // #### Common fixes
  //
  // If you can remove the implementation of `==` from the class, then do so:
  //
  // ```dart
  // class C {
  //   const C();
  // }
  //
  // const map = {C() : 0};
  // ```
  //
  // If you can't remove the implementation of `==` from the class, then make
  // the map be non-constant:
  //
  // ```dart
  // class C {
  //   const C();
  //
  //   bool operator ==(Object other) => true;
  // }
  //
  // final map = {C() : 0};
  // ```
  static const CompileTimeErrorCode
      CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS = CompileTimeErrorCode(
    'CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS',
    "The type of a key in a constant map can't override the '==' operator, but the class '{0}' does.",
    correctionMessage:
        "Try using a different value for the key, or removing the keyword 'const' from the map.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the uninitialized final variable
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a variable that is declared to
  // be a constant doesn't have an initializer.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `c` isn't initialized:
  //
  // ```dart
  // const [!c!];
  // ```
  //
  // #### Common fixes
  //
  // Add an initializer:
  //
  // ```dart
  // const c = 'c';
  // ```
  static const CompileTimeErrorCode CONST_NOT_INITIALIZED =
      CompileTimeErrorCode(
    'CONST_NOT_INITIALIZED',
    "The constant '{0}' must be initialized.",
    correctionMessage: "Try adding an initialization to the declaration.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the type of the element
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the class of object used as an
  // element in a constant set literal implements the `==` operator. The
  // implementation of constant sets uses the `==` operator, so any
  // implementation other than the one inherited from `Object` requires
  // executing arbitrary code at compile time, which isn't supported.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the constant set
  // contains an element whose type is `C`, and the class `C` overrides the
  // implementation of `==`:
  //
  // ```dart
  // class C {
  //   const C();
  //
  //   bool operator ==(Object other) => true;
  // }
  //
  // const set = {[!C()!]};
  // ```
  //
  // #### Common fixes
  //
  // If you can remove the implementation of `==` from the class, then do so:
  //
  // ```dart
  // class C {
  //   const C();
  // }
  //
  // const set = {C()};
  // ```
  //
  // If you can't remove the implementation of `==` from the class, then make
  // the set be non-constant:
  //
  // ```dart
  // class C {
  //   const C();
  //
  //   bool operator ==(Object other) => true;
  // }
  //
  // final set = {C()};
  // ```
  static const CompileTimeErrorCode CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS =
      CompileTimeErrorCode(
    'CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS',
    "The type of an element in a constant set can't override the '==' operator, but the type '{0}' does.",
    correctionMessage:
        "Try using a different value for the element, or removing the keyword 'const' from the set.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the expression of a spread
  // operator in a constant list or set evaluates to something other than a list
  // or a set.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the value of `list1` is
  // `null`, which is neither a list nor a set:
  //
  // ```dart
  // %language=2.9
  // const List<int> list1 = null;
  // const List<int> list2 = [...[!list1!]];
  // ```
  //
  // #### Common fixes
  //
  // Change the expression to something that evaluates to either a constant list
  // or a constant set:
  //
  // ```dart
  // %language=2.9
  // const List<int> list1 = [];
  // const List<int> list2 = [...list1];
  // ```
  static const CompileTimeErrorCode CONST_SPREAD_EXPECTED_LIST_OR_SET =
      CompileTimeErrorCode(
    'CONST_SPREAD_EXPECTED_LIST_OR_SET',
    "A list or a set is expected in this spread.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the expression of a spread
  // operator in a constant map evaluates to something other than a map.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the value of `map1` is
  // `null`, which isn't a map:
  //
  // ```dart
  // %language=2.9
  // const Map<String, int> map1 = null;
  // const Map<String, int> map2 = {...[!map1!]};
  // ```
  //
  // #### Common fixes
  //
  // Change the expression to something that evaluates to a constant map:
  //
  // ```dart
  // %language=2.9
  // const Map<String, int> map1 = {};
  // const Map<String, int> map2 = {...map1};
  // ```
  static const CompileTimeErrorCode CONST_SPREAD_EXPECTED_MAP =
      CompileTimeErrorCode(
    'CONST_SPREAD_EXPECTED_MAP',
    "A map is expected in this spread.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the keyword `const` is used to
  // invoke a constructor that isn't marked with `const`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the constructor in `A`
  // isn't a const constructor:
  //
  // ```dart
  // class A {
  //   A();
  // }
  //
  // A f() => [!const!] A();
  // ```
  //
  // #### Common fixes
  //
  // If it's desirable and possible to make the class a constant class (by
  // making all of the fields of the class, including inherited fields, final),
  // then add the keyword `const` to the constructor:
  //
  // ```dart
  // class A {
  //   const A();
  // }
  //
  // A f() => const A();
  // ```
  //
  // Otherwise, remove the keyword `const`:
  //
  // ```dart
  // class A {
  //   A();
  // }
  //
  // A f() => A();
  // ```
  static const CompileTimeErrorCode CONST_WITH_NON_CONST = CompileTimeErrorCode(
    'CONST_WITH_NON_CONST',
    "The constructor being called isn't a const constructor.",
    correctionMessage: "Try removing 'const' from the constructor invocation.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a const constructor is invoked
  // with an argument that isn't a constant expression.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `i` isn't a constant:
  //
  // ```dart
  // class C {
  //   final int i;
  //   const C(this.i);
  // }
  // C f(int i) => const C([!i!]);
  // ```
  //
  // #### Common fixes
  //
  // Either make all of the arguments constant expressions, or remove the
  // `const` keyword to use the non-constant form of the constructor:
  //
  // ```dart
  // class C {
  //   final int i;
  //   const C(this.i);
  // }
  // C f(int i) => C(i);
  // ```
  static const CompileTimeErrorCode CONST_WITH_NON_CONSTANT_ARGUMENT =
      CompileTimeErrorCode(
    'CONST_WITH_NON_CONSTANT_ARGUMENT',
    "Arguments of a constant creation must be constant expressions.",
    correctionMessage:
        "Try making the argument a valid constant, or use 'new' to call the constructor.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the non-type element
   */
  static const CompileTimeErrorCode CONST_WITH_NON_TYPE = CompileTimeErrorCode(
    'CREATION_WITH_NON_TYPE',
    "The name '{0}' isn't a class.",
    correctionMessage: "Try correcting the name to match an existing class.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
    uniqueName: 'CONST_WITH_NON_TYPE',
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a type parameter is used as a
  // type argument in a `const` invocation of a constructor. This isn't allowed
  // because the value of the type parameter (the actual type that will be used
  // at runtime) can't be known at compile time.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the type parameter `T`
  // is being used as a type argument when creating a constant:
  //
  // ```dart
  // class C<T> {
  //   const C();
  // }
  //
  // C<T> newC<T>() => const C<[!T!]>();
  // ```
  //
  // #### Common fixes
  //
  // If the type that will be used for the type parameter can be known at
  // compile time, then remove the use of the type parameter:
  //
  // ```dart
  // class C<T> {
  //   const C();
  // }
  //
  // C<int> newC() => const C<int>();
  // ```
  //
  // If the type that will be used for the type parameter can't be known until
  // runtime, then remove the keyword `const`:
  //
  // ```dart
  // class C<T> {
  //   const C();
  // }
  //
  // C<T> newC<T>() => C<T>();
  // ```
  static const CompileTimeErrorCode CONST_WITH_TYPE_PARAMETERS =
      CompileTimeErrorCode(
    'CONST_WITH_TYPE_PARAMETERS',
    "A constant creation can't use a type parameter as a type argument.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  static const CompileTimeErrorCode
      CONST_WITH_TYPE_PARAMETERS_CONSTRUCTOR_TEAROFF = CompileTimeErrorCode(
    'CONST_WITH_TYPE_PARAMETERS',
    "A constant constructor tearoff can't use a type parameter as a type argument.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
    uniqueName: 'CONST_WITH_TYPE_PARAMETERS_CONSTRUCTOR_TEAROFF',
  );

  /**
   * No parameters.
   */
  static const CompileTimeErrorCode
      CONST_WITH_TYPE_PARAMETERS_FUNCTION_TEAROFF = CompileTimeErrorCode(
    'CONST_WITH_TYPE_PARAMETERS',
    "A constant function tearoff can't use a type parameter as a type argument.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
    uniqueName: 'CONST_WITH_TYPE_PARAMETERS_FUNCTION_TEAROFF',
  );

  /**
   * 16.12.2 Const: It is a compile-time error if <i>T.id</i> is not the name of
   * a constant constructor declared by the type <i>T</i>.
   *
   * Parameters:
   * 0: the name of the type
   * 1: the name of the requested constant constructor
   */
  static const CompileTimeErrorCode CONST_WITH_UNDEFINED_CONSTRUCTOR =
      CompileTimeErrorCode(
    'CONST_WITH_UNDEFINED_CONSTRUCTOR',
    "The class '{0}' doesn't have a constant constructor '{1}'.",
    correctionMessage: "Try calling a different constructor.",
  );

  /**
   * 16.12.2 Const: It is a compile-time error if <i>T.id</i> is not the name of
   * a constant constructor declared by the type <i>T</i>.
   *
   * Parameters:
   * 0: the name of the type
   */
  static const CompileTimeErrorCode CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT =
      CompileTimeErrorCode(
    'CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT',
    "The class '{0}' doesn't have an unnamed constant constructor.",
    correctionMessage: "Try calling a different constructor.",
  );

  static const CompileTimeErrorCode CONTINUE_LABEL_ON_SWITCH =
      CompileTimeErrorCode(
    'CONTINUE_LABEL_ON_SWITCH',
    "A continue label resolves to switch, must be loop or switch member",
  );

  /**
   * Parameters:
   * 0: the name of the type parameter
   * 1: detail text explaining why the type could not be inferred
   */
  static const CompileTimeErrorCode COULD_NOT_INFER = CompileTimeErrorCode(
    'COULD_NOT_INFER',
    "Couldn't infer type parameter '{0}'.{1}",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when it finds a use of the default
  // constructor for the class `List` in code that has opted in to null safety.
  //
  // #### Example
  //
  // Assuming the following code is opted in to null safety, it produces this
  // diagnostic because it uses the default `List` constructor:
  //
  // ```dart
  // var l = [!List<int>!]();
  // ```
  //
  // #### Common fixes
  //
  // If no initial size is provided, then convert the code to use a list
  // literal:
  //
  // ```dart
  // var l = <int>[];
  // ```
  //
  // If an initial size needs to be provided and there is a single reasonable
  // initial value for the elements, then use `List.filled`:
  //
  // ```dart
  // var l = List.filled(3, 0);
  // ```
  //
  // If an initial size needs to be provided but each element needs to be
  // computed, then use `List.generate`:
  //
  // ```dart
  // var l = List.generate(3, (i) => i);
  // ```
  static const CompileTimeErrorCode DEFAULT_LIST_CONSTRUCTOR =
      CompileTimeErrorCode(
    'DEFAULT_LIST_CONSTRUCTOR',
    "The default 'List' constructor isn't available when null safety is enabled.",
    correctionMessage:
        "Try using a list literal, 'List.filled' or 'List.generate'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a factory constructor that
  // redirects to another constructor specifies a default value for an optional
  // parameter.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the factory constructor
  // in `A` has a default value for the optional parameter `x`:
  //
  // ```dart
  // class A {
  //   factory A([int [!x!] = 0]) = B;
  // }
  //
  // class B implements A {
  //   B([int x = 1]) {}
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the default value from the factory constructor:
  //
  // ```dart
  // class A {
  //   factory A([int x]) = B;
  // }
  //
  // class B implements A {
  //   B([int x = 1]) {}
  // }
  // ```
  //
  // Note that this fix might change the value used when the optional parameter
  // is omitted. If that happens, and if that change is a problem, then consider
  // making the optional parameter a required parameter in the factory method:
  //
  // ```dart
  // class A {
  //  factory A(int x) = B;
  // }
  //
  // class B implements A {
  //   B([int x = 1]) {}
  // }
  // ```
  static const CompileTimeErrorCode
      DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR = CompileTimeErrorCode(
    'DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR',
    "Default values aren't allowed in factory constructors that redirect to another constructor.",
    correctionMessage: "Try removing the default value.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a named parameter has both the
  // `required` modifier and a default value. If the parameter is required, then
  // a value for the parameter is always provided at the call sites, so the
  // default value can never be used.
  //
  // #### Example
  //
  // The following code generates this diagnostic:
  //
  // ```dart
  // void log({required String [!message!] = 'no message'}) {}
  // ```
  //
  // #### Common fixes
  //
  // If the parameter is really required, then remove the default value:
  //
  // ```dart
  // void log({required String message}) {}
  // ```
  //
  // If the parameter isn't always required, then remove the `required`
  // modifier:
  //
  // ```dart
  // void log({String message = 'no message'}) {}
  // ```
  static const CompileTimeErrorCode DEFAULT_VALUE_ON_REQUIRED_PARAMETER =
      CompileTimeErrorCode(
    'DEFAULT_VALUE_ON_REQUIRED_PARAMETER',
    "Required named parameters can't have a default value.",
    correctionMessage:
        "Try removing either the default value or the 'required' modifier.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a library that is imported using
  // a deferred import declares an extension that is visible in the importing
  // library. Extension methods are resolved at compile time, and extensions
  // from deferred libraries aren't available at compile time.
  //
  // For more information, see the language tour's coverage of
  // [deferred loading](https://dart.dev/guides/language/language-tour#lazily-loading-a-library).
  //
  // #### Example
  //
  // Given a file (`a.dart`) that defines a named extension:
  //
  // ```dart
  // %uri="lib/a.dart"
  // class C {}
  //
  // extension E on String {
  //   int get size => length;
  // }
  // ```
  //
  // The following code produces this diagnostic because the named extension is
  // visible to the library:
  //
  // ```dart
  // import [!'a.dart'!] deferred as a;
  //
  // void f() {
  //   a.C();
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the library must be imported as `deferred`, then either add a `show`
  // clause listing the names being referenced or add a `hide` clause listing
  // all of the named extensions. Adding a `show` clause would look like this:
  //
  // ```dart
  // import 'a.dart' deferred as a show C;
  //
  // void f() {
  //   a.C();
  // }
  // ```
  //
  // Adding a `hide` clause would look like this:
  //
  // ```dart
  // import 'a.dart' deferred as a hide E;
  //
  // void f() {
  //   a.C();
  // }
  // ```
  //
  // With the first fix, the benefit is that if new extensions are added to the
  // imported library, then the extensions won't cause a diagnostic to be
  // generated.
  //
  // If the library doesn't need to be imported as `deferred`, or if you need to
  // make use of the extension method declared in it, then remove the keyword
  // `deferred`:
  //
  // ```dart
  // import 'a.dart' as a;
  //
  // void f() {
  //   a.C();
  // }
  // ```
  static const CompileTimeErrorCode DEFERRED_IMPORT_OF_EXTENSION =
      CompileTimeErrorCode(
    'DEFERRED_IMPORT_OF_EXTENSION',
    "Imports of deferred libraries must hide all extensions.",
    correctionMessage:
        "Try adding either a show combinator listing the names you need to reference or a hide combinator listing all of the extensions.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the variable that is invalid
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when [definite assignment][] analysis
  // shows that a local variable that's marked as `late` is read before being
  // assigned.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `x` wasn't assigned a
  // value before being read:
  //
  // ```dart
  // void f(bool b) {
  //   late int x;
  //   print([!x!]);
  // }
  // ```
  //
  // #### Common fixes
  //
  // Assign a value to the variable before reading from it:
  //
  // ```dart
  // void f(bool b) {
  //   late int x;
  //   x = b ? 1 : 0;
  //   print(x);
  // }
  // ```
  static const CompileTimeErrorCode DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE =
      CompileTimeErrorCode(
    'DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE',
    "The late local variable '{0}' is definitely unassigned at this point.",
    correctionMessage:
        "Ensure that it is assigned on necessary execution paths.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  static const CompileTimeErrorCode DISALLOWED_TYPE_INSTANTIATION_EXPRESSION =
      CompileTimeErrorCode(
    'DISALLOWED_TYPE_INSTANTIATION_EXPRESSION',
    "Only a generic type, generic function, generic instance method, or generic constructor can be type instantiated.",
    correctionMessage:
        "Try instantiating the type(s) of a generic type, generic function, generic instance method, or generic constructor.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a class declares more than one
  // unnamed constructor or when it declares more than one constructor with the
  // same name.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because there are two
  // declarations for the unnamed constructor:
  //
  // ```dart
  // class C {
  //   C();
  //
  //   [!C!]();
  // }
  // ```
  //
  // The following code produces this diagnostic because there are two
  // declarations for the constructor named `m`:
  //
  // ```dart
  // class C {
  //   C.m();
  //
  //   [!C.m!]();
  // }
  // ```
  //
  // #### Common fixes
  //
  // If there are multiple unnamed constructors and all of the constructors are
  // needed, then give all of them, or all except one of them, a name:
  //
  // ```dart
  // class C {
  //   C();
  //
  //   C.n();
  // }
  // ```
  //
  // If there are multiple unnamed constructors and all except one of them are
  // unneeded, then remove the constructors that aren't needed:
  //
  // ```dart
  // class C {
  //   C();
  // }
  // ```
  //
  // If there are multiple named constructors and all of the constructors are
  // needed, then rename all except one of them:
  //
  // ```dart
  // class C {
  //   C.m();
  //
  //   C.n();
  // }
  // ```
  //
  // If there are multiple named constructors and all except one of them are
  // unneeded, then remove the constructorsthat aren't needed:
  //
  // ```dart
  // class C {
  //   C.m();
  // }
  // ```
  static const CompileTimeErrorCode DUPLICATE_CONSTRUCTOR_DEFAULT =
      CompileTimeErrorCode(
    'DUPLICATE_CONSTRUCTOR',
    "The unnamed constructor is already defined.",
    correctionMessage: "Try giving one of the constructors a name.",
    hasPublishedDocs: true,
    uniqueName: 'DUPLICATE_CONSTRUCTOR_DEFAULT',
  );

  /**
   * Parameters:
   * 0: the name of the duplicate entity
   */
  static const CompileTimeErrorCode DUPLICATE_CONSTRUCTOR_NAME =
      CompileTimeErrorCode(
    'DUPLICATE_CONSTRUCTOR',
    "The constructor with name '{0}' is already defined.",
    correctionMessage: "Try renaming one of the constructors.",
    hasPublishedDocs: true,
    uniqueName: 'DUPLICATE_CONSTRUCTOR_NAME',
  );

  /**
   * Parameters:
   * 0: the name of the duplicate entity
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a name is declared, and there is
  // a previous declaration with the same name in the same scope.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the name `x` is
  // declared twice:
  //
  // ```dart
  // int x = 0;
  // int [!x!] = 1;
  // ```
  //
  // #### Common fixes
  //
  // Choose a different name for one of the declarations.
  //
  // ```dart
  // int x = 0;
  // int y = 1;
  // ```
  static const CompileTimeErrorCode DUPLICATE_DEFINITION = CompileTimeErrorCode(
    'DUPLICATE_DEFINITION',
    "The name '{0}' is already defined.",
    correctionMessage: "Try renaming one of the declarations.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the field
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when there's more than one field
  // formal parameter for the same field in a constructor's parameter list. It
  // isn't useful to assign a value that will immediately be overwritten.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `this.f` appears twice
  // in the parameter list:
  //
  // ```dart
  // class C {
  //   int f;
  //
  //   C(this.f, this.[!f!]) {}
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove one of the field formal parameters:
  //
  // ```dart
  // class C {
  //   int f;
  //
  //   C(this.f) {}
  // }
  // ```
  static const CompileTimeErrorCode DUPLICATE_FIELD_FORMAL_PARAMETER =
      CompileTimeErrorCode(
    'DUPLICATE_FIELD_FORMAL_PARAMETER',
    "The field '{0}' can't be initialized by multiple parameters in the same constructor.",
    correctionMessage:
        "Try removing one of the parameters, or using different fields.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the parameter that was duplicated
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an invocation has two or more
  // named arguments that have the same name.
  //
  // #### Example
  //
  // The following code produces this diagnostic because there are two arguments
  // with the name `a`:
  //
  // ```dart
  // %language=2.9
  // void f(C c) {
  //   c.m(a: 0, [!a!]: 1);
  // }
  //
  // class C {
  //   void m({int a, int b}) {}
  // }
  // ```
  //
  // #### Common fixes
  //
  // If one of the arguments should have a different name, then change the name:
  //
  // ```dart
  // %language=2.9
  // void f(C c) {
  //   c.m(a: 0, b: 1);
  // }
  //
  // class C {
  //   void m({int a, int b}) {}
  // }
  // ```
  //
  // If one of the arguments is wrong, then remove it:
  //
  // ```dart
  // %language=2.9
  // void f(C c) {
  //   c.m(a: 1);
  // }
  //
  // class C {
  //   void m({int a, int b}) {}
  // }
  // ```
  static const CompileTimeErrorCode DUPLICATE_NAMED_ARGUMENT =
      CompileTimeErrorCode(
    'DUPLICATE_NAMED_ARGUMENT',
    "The argument for the named parameter '{0}' was already specified.",
    correctionMessage:
        "Try removing one of the named arguments, or correcting one of the names to reference a different named parameter.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the URI of the duplicate part
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a single file is referenced in
  // multiple part directives.
  //
  // #### Example
  //
  // Given a file named `part.dart` containing
  //
  // ```dart
  // %uri="lib/part.dart"
  // part of lib;
  // ```
  //
  // The following code produces this diagnostic because the file `part.dart` is
  // included multiple times:
  //
  // ```dart
  // library lib;
  //
  // part 'part.dart';
  // part [!'part.dart'!];
  // ```
  //
  // #### Common fixes
  //
  // Remove all except the first of the duplicated part directives:
  //
  // ```dart
  // library lib;
  //
  // part 'part.dart';
  // ```
  static const CompileTimeErrorCode DUPLICATE_PART = CompileTimeErrorCode(
    'DUPLICATE_PART',
    "The library already contains a part with the URI '{0}'.",
    correctionMessage:
        "Try removing all except one of the duplicated part directives.",
    hasPublishedDocs: true,
  );

  static const CompileTimeErrorCode ENUM_CONSTANT_SAME_NAME_AS_ENCLOSING =
      CompileTimeErrorCode(
    'ENUM_CONSTANT_SAME_NAME_AS_ENCLOSING',
    "The name of the enum constant can't be the same as the enum's name.",
    correctionMessage: "Try renaming the constant.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when two elements in a constant set
  // literal have the same value. The set can only contain each value once,
  // which means that one of the values is unnecessary.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the string `'a'` is
  // specified twice:
  //
  // ```dart
  // const Set<String> set = {'a', [!'a'!]};
  // ```
  //
  // #### Common fixes
  //
  // Remove one of the duplicate values:
  //
  // ```dart
  // const Set<String> set = {'a'};
  // ```
  //
  // Note that literal sets preserve the order of their elements, so the choice
  // of which element to remove might affect the order in which elements are
  // returned by an iterator.
  static const CompileTimeErrorCode EQUAL_ELEMENTS_IN_CONST_SET =
      CompileTimeErrorCode(
    'EQUAL_ELEMENTS_IN_CONST_SET',
    "Two elements in a constant set literal can't be equal.",
    correctionMessage: "Change or remove the duplicate element.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a key in a constant map is the
  // same as a previous key in the same map. If two keys are the same, then the
  // second value would overwrite the first value, which makes having both pairs
  // pointless.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the key `1` is used
  // twice:
  //
  // ```dart
  // const map = <int, String>{1: 'a', 2: 'b', [!1!]: 'c', 4: 'd'};
  // ```
  //
  // #### Common fixes
  //
  // If both entries should be included in the map, then change one of the keys
  // to be different:
  //
  // ```dart
  // const map = <int, String>{1: 'a', 2: 'b', 3: 'c', 4: 'd'};
  // ```
  //
  // If only one of the entries is needed, then remove the one that isn't
  // needed:
  //
  // ```dart
  // const map = <int, String>{1: 'a', 2: 'b', 4: 'd'};
  // ```
  //
  // Note that literal maps preserve the order of their entries, so the choice
  // of which entry to remove might affect the order in which keys and values
  // are returned by an iterator.
  static const CompileTimeErrorCode EQUAL_KEYS_IN_CONST_MAP =
      CompileTimeErrorCode(
    'EQUAL_KEYS_IN_CONST_MAP',
    "Two keys in a constant map literal can't be equal.",
    correctionMessage: "Change or remove the duplicate key.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the number of provided type arguments
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a list literal has more than one
  // type argument.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the list literal has
  // two type arguments when it can have at most one:
  //
  // ```dart
  // var l = [!<int, int>!][];
  // ```
  //
  // #### Common fixes
  //
  // Remove all except one of the type arguments:
  //
  // ```dart
  // var l = <int>[];
  // ```
  static const CompileTimeErrorCode EXPECTED_ONE_LIST_TYPE_ARGUMENTS =
      CompileTimeErrorCode(
    'EXPECTED_ONE_LIST_TYPE_ARGUMENTS',
    "List literals require one type argument or none, but {0} found.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the number of provided type arguments
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a set literal has more than one
  // type argument.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the set literal has
  // three type arguments when it can have at most one:
  //
  // ```dart
  // var s = [!<int, String, int>!]{0, 'a', 1};
  // ```
  //
  // #### Common fixes
  //
  // Remove all except one of the type arguments:
  //
  // ```dart
  // var s = <int>{0, 1};
  // ```
  static const CompileTimeErrorCode EXPECTED_ONE_SET_TYPE_ARGUMENTS =
      CompileTimeErrorCode(
    'EXPECTED_ONE_SET_TYPE_ARGUMENTS',
    "Set literals require one type argument or none, but {0} were found.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the number of provided type arguments
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a map literal has either one or
  // more than two type arguments.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the map literal has
  // three type arguments when it can have either two or zero:
  //
  // ```dart
  // var m = [!<int, String, int>!]{};
  // ```
  //
  // #### Common fixes
  //
  // Remove all except two of the type arguments:
  //
  // ```dart
  // var m = <int, String>{};
  // ```
  static const CompileTimeErrorCode EXPECTED_TWO_MAP_TYPE_ARGUMENTS =
      CompileTimeErrorCode(
    'EXPECTED_TWO_MAP_TYPE_ARGUMENTS',
    "Map literals require two type arguments or none, but {0} found.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the uri pointing to a library
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when it finds an export whose `dart:`
  // URI references an internal library.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `_interceptors` is an
  // internal library:
  //
  // ```dart
  // export [!'dart:_interceptors'!];
  // ```
  //
  // #### Common fixes
  //
  // Remove the export directive.
  static const CompileTimeErrorCode EXPORT_INTERNAL_LIBRARY =
      CompileTimeErrorCode(
    'EXPORT_INTERNAL_LIBRARY',
    "The library '{0}' is internal and can't be exported.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of a symbol defined in a legacy library
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a library that was opted in to
  // null safety exports another library, and the exported library is opted out
  // of null safety.
  //
  // #### Example
  //
  // Given a library that is opted out of null safety:
  //
  // ```dart
  // %uri="lib/optedOut.dart"
  // // @dart = 2.8
  // String s;
  // ```
  //
  // The following code produces this diagnostic because it's exporting symbols
  // from an opted-out library:
  //
  // ```dart
  // export [!'optedOut.dart'!];
  //
  // class C {}
  // ```
  //
  // #### Common fixes
  //
  // If you're able to do so, migrate the exported library so that it doesn't
  // need to opt out:
  //
  // ```dart
  // String? s;
  // ```
  //
  // If you can't migrate the library, then remove the export:
  //
  // ```dart
  // class C {}
  // ```
  //
  // If the exported library (the one that is opted out) itself exports an
  // opted-in library, then it's valid for your library to indirectly export the
  // symbols from the opted-in library. You can do so by adding a hide
  // combinator to the export directive in your library that hides all of the
  // names declared in the opted-out library.
  static const CompileTimeErrorCode EXPORT_LEGACY_SYMBOL = CompileTimeErrorCode(
    'EXPORT_LEGACY_SYMBOL',
    "The symbol '{0}' is defined in a legacy library, and can't be re-exported from a library with null safety enabled.",
    correctionMessage:
        "Try removing the export or migrating the legacy library.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the uri pointing to a non-library declaration
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an export directive references a
  // part rather than a library.
  //
  // #### Example
  //
  // Given a file named `part.dart` containing
  //
  // ```dart
  // %uri="lib/part.dart"
  // part of lib;
  // ```
  //
  // The following code produces this diagnostic because the file `part.dart` is
  // a part, and only libraries can be exported:
  //
  // ```dart
  // library lib;
  //
  // export [!'part.dart'!];
  // ```
  //
  // #### Common fixes
  //
  // Either remove the export directive, or change the URI to be the URI of the
  // library containing the part.
  static const CompileTimeErrorCode EXPORT_OF_NON_LIBRARY =
      CompileTimeErrorCode(
    'EXPORT_OF_NON_LIBRARY',
    "The exported library '{0}' can't have a part-of directive.",
    correctionMessage: "Try exporting the library that the part is a part of.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the analyzer finds an
  // expression, rather than a map entry, in what appears to be a map literal.
  //
  // #### Example
  //
  // The following code produces this diagnostic:
  //
  // ```dart
  // var map = <String, int>{'a': 0, 'b': 1, [!'c'!]};
  // ```
  //
  // #### Common fixes
  //
  // If the expression is intended to compute either a key or a value in an
  // entry, fix the issue by replacing the expression with the key or the value.
  // For example:
  //
  // ```dart
  // var map = <String, int>{'a': 0, 'b': 1, 'c': 2};
  // ```
  static const CompileTimeErrorCode EXPRESSION_IN_MAP = CompileTimeErrorCode(
    'EXPRESSION_IN_MAP',
    "Expressions can't be used in a map literal.",
    correctionMessage:
        "Try removing the expression or converting it to be a map entry.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a type (class or mixin) is a
  // subtype of a class from a library being imported using a deferred import.
  // The supertypes of a type must be compiled at the same time as the type, and
  // classes from deferred libraries aren't compiled until the library is
  // loaded.
  //
  // For more information, see the language tour's coverage of
  // [deferred loading](https://dart.dev/guides/language/language-tour#lazily-loading-a-library).
  //
  // #### Example
  //
  // Given a file (`a.dart`) that defines the class `A`:
  //
  // ```dart
  // %uri="lib/a.dart"
  // class A {}
  // ```
  //
  // The following code produces this diagnostic because the superclass of `B`
  // is declared in a deferred library:
  //
  // ```dart
  // import 'a.dart' deferred as a;
  //
  // class B extends [!a.A!] {}
  // ```
  //
  // #### Common fixes
  //
  // If you need to create a subtype of a type from the deferred library, then
  // remove the `deferred` keyword:
  //
  // ```dart
  // import 'a.dart' as a;
  //
  // class B extends a.A {}
  // ```
  static const CompileTimeErrorCode EXTENDS_DEFERRED_CLASS =
      CompileTimeErrorCode(
    'SUBTYPE_OF_DEFERRED_CLASS',
    "Classes can't extend deferred classes.",
    correctionMessage:
        "Try specifying a different superclass, or removing the extends clause.",
    hasPublishedDocs: true,
    uniqueName: 'EXTENDS_DEFERRED_CLASS',
  );

  /**
   * Parameters:
   * 0: the name of the disallowed type
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when one of the restricted classes is
  // used in either an `extends`, `implements`, `with`, or `on` clause. The
  // classes `bool`, `double`, `FutureOr`, `int`, `Null`, `num`, and `String`
  // are all restricted in this way, to allow for more efficient
  // implementations.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because `String` is used in an
  // `extends` clause:
  //
  // ```dart
  // class A extends [!String!] {}
  // ```
  //
  // The following code produces this diagnostic because `String` is used in an
  // `implements` clause:
  //
  // ```dart
  // class B implements [!String!] {}
  // ```
  //
  // The following code produces this diagnostic because `String` is used in a
  // `with` clause:
  //
  // ```dart
  // class C with [!String!] {}
  // ```
  //
  // The following code produces this diagnostic because `String` is used in an
  // `on` clause:
  //
  // ```dart
  // mixin M on [!String!] {}
  // ```
  //
  // #### Common fixes
  //
  // If a different type should be specified, then replace the type:
  //
  // ```dart
  // class A extends Object {}
  // ```
  //
  // If there isn't a different type that would be appropriate, then remove the
  // type, and possibly the whole clause:
  //
  // ```dart
  // class B {}
  // ```
  static const CompileTimeErrorCode EXTENDS_DISALLOWED_CLASS =
      CompileTimeErrorCode(
    'SUBTYPE_OF_DISALLOWED_TYPE',
    "Classes can't extend '{0}'.",
    correctionMessage:
        "Try specifying a different superclass, or removing the extends clause.",
    hasPublishedDocs: true,
    uniqueName: 'EXTENDS_DISALLOWED_CLASS',
  );

  /**
   * Parameters:
   * 0: the name in the extends clause
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an `extends` clause contains a
  // name that is declared to be something other than a class.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `f` is declared to be a
  // function:
  //
  // ```dart
  // void f() {}
  //
  // class C extends [!f!] {}
  // ```
  //
  // #### Common fixes
  //
  // If you want the class to extend a class other than `Object`, then replace
  // the name in the `extends` clause with the name of that class:
  //
  // ```dart
  // void f() {}
  //
  // class C extends B {}
  //
  // class B {}
  // ```
  //
  // If you want the class to extend `Object`, then remove the `extends` clause:
  //
  // ```dart
  // void f() {}
  //
  // class C {}
  // ```
  static const CompileTimeErrorCode EXTENDS_NON_CLASS = CompileTimeErrorCode(
    'EXTENDS_NON_CLASS',
    "Classes can only extend other classes.",
    correctionMessage:
        "Try specifying a different superclass, or removing the extends clause.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a type alias that expands to a
  // type parameter is used in an `extends`, `implements`, `with`, or `on`
  // clause.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the type alias `T`,
  // which expands to the type parameter `S`, is used in the `extends` clause of
  // the class `C`:
  //
  // ```dart
  // typedef T<S> = S;
  //
  // class C extends [!T!]<Object> {}
  // ```
  //
  // #### Common fixes
  //
  // Use the value of the type argument directly:
  //
  // ```dart
  // typedef T<S> = S;
  //
  // class C extends Object {}
  // ```
  static const CompileTimeErrorCode
      EXTENDS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER = CompileTimeErrorCode(
    'SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER',
    "A type alias that expands to a type parameter can't be used as a superclass.",
    correctionMessage:
        "Try specifying a different superclass, or removing the extends clause.",
    hasPublishedDocs: true,
    uniqueName: 'EXTENDS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
  );

  /**
   * Parameters:
   * 0: the name of the extension
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the name of an extension is used
  // in an expression other than in an extension override or to qualify an
  // access to a static member of the extension. Because classes define a type,
  // the name of a class can be used to refer to the instance of `Type`
  // representing the type of the class. Extensions, on the other hand, don't
  // define a type and can't be used as a type literal.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `E` is an extension:
  //
  // ```dart
  // extension E on int {
  //   static String m() => '';
  // }
  //
  // var x = [!E!];
  // ```
  //
  // #### Common fixes
  //
  // Replace the name of the extension with a name that can be referenced, such
  // as a static member defined on the extension:
  //
  // ```dart
  // extension E on int {
  //   static String m() => '';
  // }
  //
  // var x = E.m();
  // ```
  static const CompileTimeErrorCode EXTENSION_AS_EXPRESSION =
      CompileTimeErrorCode(
    'EXTENSION_AS_EXPRESSION',
    "Extension '{0}' can't be used as an expression.",
    correctionMessage: "Try replacing it with a valid expression.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the conflicting static member
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an extension declaration
  // contains both an instance member and a static member that have the same
  // name. The instance member and the static member can't have the same name
  // because it's unclear which member is being referenced by an unqualified use
  // of the name within the body of the extension.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the name `a` is being
  // used for two different members:
  //
  // ```dart
  // extension E on Object {
  //   int get a => 0;
  //   static int [!a!]() => 0;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Rename or remove one of the members:
  //
  // ```dart
  // extension E on Object {
  //   int get a => 0;
  //   static int b() => 0;
  // }
  // ```
  static const CompileTimeErrorCode EXTENSION_CONFLICTING_STATIC_AND_INSTANCE =
      CompileTimeErrorCode(
    'EXTENSION_CONFLICTING_STATIC_AND_INSTANCE',
    "An extension can't define static member '{0}' and an instance member with the same name.",
    correctionMessage:
        "Try renaming the member to a name that doesn't conflict.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an extension declaration
  // declares a member with the same name as a member declared in the class
  // `Object`. Such a member can never be used because the member in `Object` is
  // always found first.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `toString` is defined
  // by `Object`:
  //
  // ```dart
  // extension E on String {
  //   String [!toString!]() => this;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the member or rename it so that the name doesn't conflict with the
  // member in `Object`:
  //
  // ```dart
  // extension E on String {
  //   String displayString() => this;
  // }
  // ```
  static const CompileTimeErrorCode EXTENSION_DECLARES_MEMBER_OF_OBJECT =
      CompileTimeErrorCode(
    'EXTENSION_DECLARES_MEMBER_OF_OBJECT',
    "Extensions can't declare members with the same name as a member declared by 'Object'.",
    correctionMessage: "Try specifying a different name for the member.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an extension override is the
  // receiver of the invocation of a static member. Similar to static members in
  // classes, the static members of an extension should be accessed using the
  // name of the extension, not an extension override.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `m` is static:
  //
  // ```dart
  // extension E on String {
  //   static void m() {}
  // }
  //
  // void f() {
  //   E('').[!m!]();
  // }
  // ```
  //
  // #### Common fixes
  //
  // Replace the extension override with the name of the extension:
  //
  // ```dart
  // extension E on String {
  //   static void m() {}
  // }
  //
  // void f() {
  //   E.m();
  // }
  // ```
  static const CompileTimeErrorCode EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER =
      CompileTimeErrorCode(
    'EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER',
    "An extension override can't be used to access a static member from an extension.",
    correctionMessage: "Try using just the name of the extension.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the type of the argument
   * 1: the extended type
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the argument to an extension
  // override isn't assignable to the type being extended by the extension.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `3` isn't a `String`:
  //
  // ```dart
  // extension E on String {
  //   void method() {}
  // }
  //
  // void f() {
  //   E([!3!]).method();
  // }
  // ```
  //
  // #### Common fixes
  //
  // If you're using the correct extension, then update the argument to have the
  // correct type:
  //
  // ```dart
  // extension E on String {
  //   void method() {}
  // }
  //
  // void f() {
  //   E(3.toString()).method();
  // }
  // ```
  //
  // If there's a different extension that's valid for the type of the argument,
  // then either replace the name of the extension or unwrap the argument so
  // that the correct extension is found.
  static const CompileTimeErrorCode EXTENSION_OVERRIDE_ARGUMENT_NOT_ASSIGNABLE =
      CompileTimeErrorCode(
    'EXTENSION_OVERRIDE_ARGUMENT_NOT_ASSIGNABLE',
    "The type of the argument to the extension override '{0}' isn't assignable to the extended type '{1}'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an extension override is found
  // that isn't being used to access one of the members of the extension. The
  // extension override syntax doesn't have any runtime semantics; it only
  // controls which member is selected at compile time.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `E(i)` isn't an
  // expression:
  //
  // ```dart
  // extension E on int {
  //   int get a => 0;
  // }
  //
  // void f(int i) {
  //   print([!E(i)!]);
  // }
  // ```
  //
  // #### Common fixes
  //
  // If you want to invoke one of the members of the extension, then add the
  // invocation:
  //
  // ```dart
  // extension E on int {
  //   int get a => 0;
  // }
  //
  // void f(int i) {
  //   print(E(i).a);
  // }
  // ```
  //
  // If you don't want to invoke a member, then unwrap the argument:
  //
  // ```dart
  // extension E on int {
  //   int get a => 0;
  // }
  //
  // void f(int i) {
  //   print(i);
  // }
  // ```
  static const CompileTimeErrorCode EXTENSION_OVERRIDE_WITHOUT_ACCESS =
      CompileTimeErrorCode(
    'EXTENSION_OVERRIDE_WITHOUT_ACCESS',
    "An extension override can only be used to access instance members.",
    correctionMessage: "Consider adding an access to an instance member.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an extension override is used as
  // the receiver of a cascade expression. The value of a cascade expression
  // `e..m` is the value of the receiver `e`, but extension overrides aren't
  // expressions and don't have a value.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `E(3)` isn't an
  // expression:
  //
  // ```dart
  // extension E on int {
  //   void m() {}
  // }
  // f() {
  //   [!E!](3)..m();
  // }
  // ```
  //
  // #### Common fixes
  //
  // Use `.` rather than `..`:
  //
  // ```dart
  // extension E on int {
  //   void m() {}
  // }
  // f() {
  //   E(3).m();
  // }
  // ```
  //
  // If there are multiple cascaded accesses, you'll need to duplicate the
  // extension override for each one.
  static const CompileTimeErrorCode EXTENSION_OVERRIDE_WITH_CASCADE =
      CompileTimeErrorCode(
    'EXTENSION_OVERRIDE_WITH_CASCADE',
    "Extension overrides have no value so they can't be used as the receiver of a cascade expression.",
    correctionMessage: "Try using '.' instead of '..'.",
    hasPublishedDocs: true,
  );

  static const CompileTimeErrorCode EXTERNAL_FIELD_CONSTRUCTOR_INITIALIZER =
      CompileTimeErrorCode(
    'EXTERNAL_FIELD_CONSTRUCTOR_INITIALIZER',
    "External fields cannot have initializers.",
    correctionMessage:
        "Try removing the field initializer or the 'external' keyword from the field declaration.",
  );

  static const CompileTimeErrorCode EXTERNAL_FIELD_INITIALIZER =
      CompileTimeErrorCode(
    'EXTERNAL_FIELD_INITIALIZER',
    "External fields cannot have initializers.",
    correctionMessage:
        "Try removing the initializer or the 'external' keyword.",
  );

  static const CompileTimeErrorCode EXTERNAL_VARIABLE_INITIALIZER =
      CompileTimeErrorCode(
    'EXTERNAL_VARIABLE_INITIALIZER',
    "External variables cannot have initializers.",
    correctionMessage:
        "Try removing the initializer or the 'external' keyword.",
  );

  /**
   * Parameters:
   * 0: the maximum number of positional arguments
   * 1: the actual number of positional arguments given
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a method or function invocation
  // has more positional arguments than the method or function allows.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `f` defines 2
  // parameters but is invoked with 3 arguments:
  //
  // ```dart
  // void f(int a, int b) {}
  // void g() {
  //   f(1, 2, [!3!]);
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the arguments that don't correspond to parameters:
  //
  // ```dart
  // void f(int a, int b) {}
  // void g() {
  //   f(1, 2);
  // }
  // ```
  static const CompileTimeErrorCode EXTRA_POSITIONAL_ARGUMENTS =
      CompileTimeErrorCode(
    'EXTRA_POSITIONAL_ARGUMENTS',
    "Too many positional arguments: {0} expected, but {1} found.",
    correctionMessage: "Try removing the extra arguments.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the maximum number of positional arguments
   * 1: the actual number of positional arguments given
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a method or function invocation
  // has more positional arguments than the method or function allows, but the
  // method or function defines named parameters.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `f` defines 2
  // positional parameters but has a named parameter that could be used for the
  // third argument:
  //
  // ```dart
  // %language=2.9
  // void f(int a, int b, {int c}) {}
  // void g() {
  //   f(1, 2, [!3!]);
  // }
  // ```
  //
  // #### Common fixes
  //
  // If some of the arguments should be values for named parameters, then add
  // the names before the arguments:
  //
  // ```dart
  // %language=2.9
  // void f(int a, int b, {int c}) {}
  // void g() {
  //   f(1, 2, c: 3);
  // }
  // ```
  //
  // Otherwise, remove the arguments that don't correspond to positional
  // parameters:
  //
  // ```dart
  // %language=2.9
  // void f(int a, int b, {int c}) {}
  // void g() {
  //   f(1, 2);
  // }
  // ```
  static const CompileTimeErrorCode EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED =
      CompileTimeErrorCode(
    'EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED',
    "Too many positional arguments: {0} expected, but {1} found.",
    correctionMessage:
        "Try removing the extra positional arguments, or specifying the name for named arguments.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the field being initialized multiple times
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the initializer list of a
  // constructor initializes a field more than once. There is no value to allow
  // both initializers because only the last value is preserved.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the field `f` is being
  // initialized twice:
  //
  // ```dart
  // class C {
  //   int f;
  //
  //   C() : f = 0, [!f!] = 1;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove one of the initializers:
  //
  // ```dart
  // class C {
  //   int f;
  //
  //   C() : f = 0;
  // }
  // ```
  static const CompileTimeErrorCode FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS =
      CompileTimeErrorCode(
    'FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS',
    "The field '{0}' can't be initialized twice in the same constructor.",
    correctionMessage: "Try removing one of the initializations.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a final field is initialized in
  // both the declaration of the field and in an initializer in a constructor.
  // Final fields can only be assigned once, so it can't be initialized in both
  // places.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `f` is :
  //
  // ```dart
  // class C {
  //   final int f = 0;
  //   C() : [!f!] = 1;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the initialization doesn't depend on any values passed to the
  // constructor, and if all of the constructors need to initialize the field to
  // the same value, then remove the initializer from the constructor:
  //
  // ```dart
  // class C {
  //   final int f = 0;
  //   C();
  // }
  // ```
  //
  // If the initialization depends on a value passed to the constructor, or if
  // different constructors need to initialize the field differently, then
  // remove the initializer in the field's declaration:
  //
  // ```dart
  // class C {
  //   final int f;
  //   C() : f = 1;
  // }
  // ```
  static const CompileTimeErrorCode
      FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION = CompileTimeErrorCode(
    'FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION',
    "Fields can't be initialized in the constructor if they are final and were already initialized at their declaration.",
    correctionMessage: "Try removing one of the initializations.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a field is initialized in both
  // the parameter list and in the initializer list of a constructor.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the field `f` is
  // initialized both by a field formal parameter and in the initializer list:
  //
  // ```dart
  // class C {
  //   int f;
  //
  //   C(this.f) : [!f!] = 0;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the field should be initialized by the parameter, then remove the
  // initialization in the initializer list:
  //
  // ```dart
  // class C {
  //   int f;
  //
  //   C(this.f);
  // }
  // ```
  //
  // If the field should be initialized in the initializer list and the
  // parameter isn't needed, then remove the parameter:
  //
  // ```dart
  // class C {
  //   int f;
  //
  //   C() : f = 0;
  // }
  // ```
  //
  // If the field should be initialized in the initializer list and the
  // parameter is needed, then make it a normal parameter:
  //
  // ```dart
  // class C {
  //   int f;
  //
  //   C(int g) : f = g * 2;
  // }
  // ```
  static const CompileTimeErrorCode
      FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER = CompileTimeErrorCode(
    'FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER',
    "Fields can't be initialized in both the parameter list and the initializers.",
    correctionMessage: "Try removing one of the initializations.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a factory constructor has a
  // field formal parameter. Factory constructors can't assign values to fields
  // because no instance is created; hence, there is no field to assign.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the factory constructor
  // uses a field formal parameter:
  //
  // ```dart
  // class C {
  //   int? f;
  //
  //   factory C([!this.f!]) => throw 0;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Replace the field formal parameter with a normal parameter:
  //
  // ```dart
  // class C {
  //   int? f;
  //
  //   factory C(int f) => throw 0;
  // }
  // ```
  static const CompileTimeErrorCode FIELD_INITIALIZER_FACTORY_CONSTRUCTOR =
      CompileTimeErrorCode(
    'FIELD_INITIALIZER_FACTORY_CONSTRUCTOR',
    "Initializing formal parameters can't be used in factory constructors.",
    correctionMessage: "Try using a normal parameter.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the type of the initializer expression
   * 1: the name of the type of the field
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the initializer list of a
  // constructor initializes a field to a value that isn't assignable to the
  // field.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `0` has the type `int`,
  // and an `int` can't be assigned to a field of type `String`:
  //
  // ```dart
  // class C {
  //   String s;
  //
  //   C() : s = [!0!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the type of the field is correct, then change the value assigned to it
  // so that the value has a valid type:
  //
  // ```dart
  // class C {
  //   String s;
  //
  //   C() : s = '0';
  // }
  // ```
  //
  // If the type of the value is correct, then change the type of the field to
  // allow the assignment:
  //
  // ```dart
  // class C {
  //   int s;
  //
  //   C() : s = 0;
  // }
  // ```
  static const CompileTimeErrorCode FIELD_INITIALIZER_NOT_ASSIGNABLE =
      CompileTimeErrorCode(
    'FIELD_INITIALIZER_NOT_ASSIGNABLE',
    "The initializer type '{0}' can't be assigned to the field type '{1}'.",
    hasPublishedDocs: true,
  );

  /**
   * 7.6.1 Generative Constructors: It is a compile-time error if an
   * initializing formal is used by a function other than a non-redirecting
   * generative constructor.
   */
  static const CompileTimeErrorCode FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR =
      CompileTimeErrorCode(
    'FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR',
    "Initializing formal parameters can only be used in constructors.",
    correctionMessage: "Try using a normal parameter.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a redirecting constructor
  // initializes a field in the object. This isn't allowed because the instance
  // that has the field hasn't been created at the point at which it should be
  // initialized.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because the constructor
  // `C.zero`, which redirects to the constructor `C`, has a field formal
  // parameter that initializes the field `f`:
  //
  // ```dart
  // class C {
  //   int f;
  //
  //   C(this.f);
  //
  //   C.zero([!this.f!]) : this(f);
  // }
  // ```
  //
  // The following code produces this diagnostic because the constructor
  // `C.zero`, which redirects to the constructor `C`, has an initializer that
  // initializes the field `f`:
  //
  // ```dart
  // class C {
  //   int f;
  //
  //   C(this.f);
  //
  //   C.zero() : [!f = 0!], this(1);
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the initialization is done by a field formal parameter, then use a
  // normal parameter:
  //
  // ```dart
  // class C {
  //   int f;
  //
  //   C(this.f);
  //
  //   C.zero(int f) : this(f);
  // }
  // ```
  //
  // If the initialization is done in an initializer, then remove the
  // initializer:
  //
  // ```dart
  // class C {
  //   int f;
  //
  //   C(this.f);
  //
  //   C.zero() : this(0);
  // }
  // ```
  static const CompileTimeErrorCode FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR =
      CompileTimeErrorCode(
    'FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR',
    "The redirecting constructor can't have a field initializer.",
    correctionMessage:
        "Try initializing the field in the constructor being redirected to.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the type of the field formal parameter
   * 1: the name of the type of the field
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the type of a field formal
  // parameter isn't assignable to the type of the field being initialized.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the field formal
  // parameter has the type `String`, but the type of the field is `int`. The
  // parameter must have a type that is a subtype of the field's type.
  //
  // ```dart
  // class C {
  //   int f;
  //
  //   C([!String this.f!]);
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the type of the field is incorrect, then change the type of the field to
  // match the type of the parameter, and consider removing the type from the
  // parameter:
  //
  // ```dart
  // class C {
  //   String f;
  //
  //   C(this.f);
  // }
  // ```
  //
  // If the type of the parameter is incorrect, then remove the type of the
  // parameter:
  //
  // ```dart
  // class C {
  //   int f;
  //
  //   C(this.f);
  // }
  // ```
  //
  // If the types of both the field and the parameter are correct, then use an
  // initializer rather than a field formal parameter to convert the parameter
  // value into a value of the correct type:
  //
  // ```dart
  // class C {
  //   int f;
  //
  //   C(String s) : f = int.parse(s);
  // }
  // ```
  static const CompileTimeErrorCode FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE =
      CompileTimeErrorCode(
    'FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE',
    "The parameter type '{0}' is incompatible with the field type '{1}'.",
    correctionMessage:
        "Try changing or removing the parameter's type, or changing the field's type.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the field in question
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a final field is initialized
  // twice: once where it's declared and once by a constructor's parameter.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the field `f` is
  // initialized twice:
  //
  // ```dart
  // class C {
  //   final int f = 0;
  //
  //   C(this.[!f!]);
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the field should have the same value for all instances, then remove the
  // initialization in the parameter list:
  //
  // ```dart
  // class C {
  //   final int f = 0;
  //
  //   C();
  // }
  // ```
  //
  // If the field can have different values in different instances, then remove
  // the initialization in the declaration:
  //
  // ```dart
  // class C {
  //   final int f;
  //
  //   C(this.f);
  // }
  // ```
  static const CompileTimeErrorCode
      FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR = CompileTimeErrorCode(
    'FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR',
    "'{0}' is final and was given a value when it was declared, so it can't be set to a new value.",
    correctionMessage: "Try removing one of the initializations.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the uninitialized final variable
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a final field or variable isn't
  // initialized.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `x` doesn't have an
  // initializer:
  //
  // ```dart
  // final [!x!];
  // ```
  //
  // #### Common fixes
  //
  // For variables and static fields, you can add an initializer:
  //
  // ```dart
  // final x = 0;
  // ```
  //
  // For instance fields, you can add an initializer as shown in the previous
  // example, or you can initialize the field in every constructor. You can
  // initialize the field by using a field formal parameter:
  //
  // ```dart
  // class C {
  //   final int x;
  //   C(this.x);
  // }
  // ```
  //
  // You can also initialize the field by using an initializer in the
  // constructor:
  //
  // ```dart
  // class C {
  //   final int x;
  //   C(int y) : x = y * 2;
  // }
  // ```
  static const CompileTimeErrorCode FINAL_NOT_INITIALIZED =
      CompileTimeErrorCode(
    'FINAL_NOT_INITIALIZED',
    "The final variable '{0}' must be initialized.",
    correctionMessage: "Try initializing the variable.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the uninitialized final variable
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a class defines one or more
  // final instance fields without initializers and has at least one constructor
  // that doesn't initialize those fields. All final instance fields must be
  // initialized when the instance is created, either by the field's initializer
  // or by the constructor.
  //
  // #### Example
  //
  // The following code produces this diagnostic:
  //
  // ```dart
  // class C {
  //   final String value;
  //
  //   [!C!]();
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the value should be passed in to the constructor directly, then use a
  // field formal parameter to initialize the field `value`:
  //
  // ```dart
  // class C {
  //   final String value;
  //
  //   C(this.value);
  // }
  // ```
  //
  // If the value should be computed indirectly from a value provided by the
  // caller, then add a parameter and include an initializer:
  //
  // ```dart
  // class C {
  //   final String value;
  //
  //   C(Object o) : value = o.toString();
  // }
  // ```
  //
  // If the value of the field doesn't depend on values that can be passed to
  // the constructor, then add an initializer for the field as part of the field
  // declaration:
  //
  // ```dart
  // class C {
  //   final String value = '';
  //
  //   C();
  // }
  // ```
  //
  // If the value of the field doesn't depend on values that can be passed to
  // the constructor but different constructors need to initialize it to
  // different values, then add an initializer for the field in the initializer
  // list:
  //
  // ```dart
  // class C {
  //   final String value;
  //
  //   C() : value = '';
  //
  //   C.named() : value = 'c';
  // }
  // ```
  //
  // However, if the value is the same for all instances, then consider using a
  // static field instead of an instance field:
  //
  // ```dart
  // class C {
  //   static const String value = '';
  //
  //   C();
  // }
  // ```
  static const CompileTimeErrorCode FINAL_NOT_INITIALIZED_CONSTRUCTOR_1 =
      CompileTimeErrorCode(
    'FINAL_NOT_INITIALIZED_CONSTRUCTOR',
    "All final variables must be initialized, but '{0}' isn't.",
    correctionMessage: "Try adding an initializer for the field.",
    hasPublishedDocs: true,
    uniqueName: 'FINAL_NOT_INITIALIZED_CONSTRUCTOR_1',
  );

  /**
   * Parameters:
   * 0: the name of the uninitialized final variable
   * 1: the name of the uninitialized final variable
   */
  static const CompileTimeErrorCode FINAL_NOT_INITIALIZED_CONSTRUCTOR_2 =
      CompileTimeErrorCode(
    'FINAL_NOT_INITIALIZED_CONSTRUCTOR',
    "All final variables must be initialized, but '{0}' and '{1}' aren't.",
    correctionMessage: "Try adding initializers for the fields.",
    hasPublishedDocs: true,
    uniqueName: 'FINAL_NOT_INITIALIZED_CONSTRUCTOR_2',
  );

  /**
   * Parameters:
   * 0: the name of the uninitialized final variable
   * 1: the name of the uninitialized final variable
   * 2: the number of additional not initialized variables that aren't listed
   */
  static const CompileTimeErrorCode FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS =
      CompileTimeErrorCode(
    'FINAL_NOT_INITIALIZED_CONSTRUCTOR',
    "All final variables must be initialized, but '{0}', '{1}', and {2} others aren't.",
    correctionMessage: "Try adding initializers for the fields.",
    hasPublishedDocs: true,
    uniqueName: 'FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS',
  );

  /**
   * Parameters:
   * 0: the type of the iterable expression.
   * 1: the sequence type -- Iterable for `for` or Stream for `await for`.
   * 2: the loop variable type.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the `Iterable` or `Stream` in a
  // for-in loop has an element type that can't be assigned to the loop
  // variable.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `<String>[]` has an
  // element type of `String`, and `String` can't be assigned to the type of `e`
  // (`int`):
  //
  // ```dart
  // void f() {
  //   for (int e in [!<String>[]!]) {
  //     print(e);
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the type of the loop variable is correct, then update the type of the
  // iterable:
  //
  // ```dart
  // void f() {
  //   for (int e in <int>[]) {
  //     print(e);
  //   }
  // }
  // ```
  //
  // If the type of the iterable is correct, then update the type of the loop
  // variable:
  //
  // ```dart
  // void f() {
  //   for (String e in <String>[]) {
  //     print(e);
  //   }
  // }
  // ```
  static const CompileTimeErrorCode FOR_IN_OF_INVALID_ELEMENT_TYPE =
      CompileTimeErrorCode(
    'FOR_IN_OF_INVALID_ELEMENT_TYPE',
    "The type '{0}' used in the 'for' loop must implement '{1}' with a type argument that can be assigned to '{2}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the type of the iterable expression.
   * 1: the sequence type -- Iterable for `for` or Stream for `await for`.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the expression following `in` in
  // a for-in loop has a type that isn't a subclass of `Iterable`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `m` is a `Map`, and
  // `Map` isn't a subclass of `Iterable`:
  //
  // ```dart
  // void f(Map<String, String> m) {
  //   for (String s in [!m!]) {
  //     print(s);
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // Replace the expression with one that produces an iterable value:
  //
  // ```dart
  // void f(Map<String, String> m) {
  //   for (String s in m.values) {
  //     print(s);
  //   }
  // }
  // ```
  static const CompileTimeErrorCode FOR_IN_OF_INVALID_TYPE =
      CompileTimeErrorCode(
    'FOR_IN_OF_INVALID_TYPE',
    "The type '{0}' used in the 'for' loop must implement {1}.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the loop variable declared in a
  // for-in loop is declared to be a `const`. The variable can't be a `const`
  // because the value can't be computed at compile time.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the loop variable `x`
  // is declared to be a `const`:
  //
  // ```dart
  // void f() {
  //   for ([!const!] x in [0, 1, 2]) {
  //     print(x);
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If there's a type annotation, then remove the `const` modifier from the
  // declaration.
  //
  // If there's no type, then replace the `const` modifier with `final`, `var`,
  // or a type annotation:
  //
  // ```dart
  // void f() {
  //   for (final x in [0, 1, 2]) {
  //     print(x);
  //   }
  // }
  // ```
  static const CompileTimeErrorCode FOR_IN_WITH_CONST_VARIABLE =
      CompileTimeErrorCode(
    'FOR_IN_WITH_CONST_VARIABLE',
    "A for-in loop variable can't be a 'const'.",
    correctionMessage:
        "Try removing the 'const' modifier from the variable, or use a different variable.",
    hasPublishedDocs: true,
  );

  /**
   * It is a compile-time error if a generic function type is used as a bound
   * for a formal type parameter of a class or a function.
   */
  static const CompileTimeErrorCode GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND =
      CompileTimeErrorCode(
    'GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND',
    "Generic function types can't be used as type parameter bounds",
    correctionMessage:
        "Try making the free variable in the function type part of the larger declaration signature",
  );

  /**
   * It is a compile-time error if a generic function type is used as an actual
   * type argument.
   */
  static const CompileTimeErrorCode
      GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT = CompileTimeErrorCode(
    'GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT',
    "A generic function type can't be a type argument.",
    correctionMessage:
        "Try removing type parameters from the generic function type, or using 'dynamic' as the type argument here.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an instance method is being torn
  // off from a receiver whose type is `dynamic`, and the tear-off includes type
  // arguments. Because the analyzer can't know how many type parameters the
  // method has, or whether it has any type parameters, there's no way it can
  // validate that the type arguments are correct. As a result, the type
  // arguments aren't allowed.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the type of `p` is
  // `dynamic` and the tear-off of `m` has type arguments:
  //
  // ```dart
  // void f(dynamic list) {
  //   [!list.fold!]<int>;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If you can use a more specific type than `dynamic`, then change the type of
  // the receiver:
  //
  // ```dart
  // void f(List<Object> list) {
  //   list.fold<int>;
  // }
  // ```
  //
  // If you can't use a more specific type, then remove the type arguments:
  //
  // ```dart
  // void f(dynamic list) {
  //   list.cast;
  // }
  // ```
  static const CompileTimeErrorCode
      GENERIC_METHOD_TYPE_INSTANTIATION_ON_DYNAMIC = CompileTimeErrorCode(
    'GENERIC_METHOD_TYPE_INSTANTIATION_ON_DYNAMIC',
    "A method tear-off on a receiver whose type is 'dynamic' can't have type arguments.",
    correctionMessage:
        "Specify the type of the receiver, or remove the type arguments from the method tear-off.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the getter
   * 1: the type of the getter
   * 2: the type of the setter
   * 3: the name of the setter
   */
  static const CompileTimeErrorCode GETTER_NOT_ASSIGNABLE_SETTER_TYPES =
      CompileTimeErrorCode(
    'GETTER_NOT_ASSIGNABLE_SETTER_TYPES',
    "The return type of getter '{0}' is '{1}' which isn't assignable to the type '{2}' of its setter '{3}'.",
    correctionMessage: "Try changing the types so that they are compatible.",
  );

  /**
   * Parameters:
   * 0: the name of the getter
   * 1: the type of the getter
   * 2: the type of the setter
   * 3: the name of the setter
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the return type of a getter
  // isn't a subtype of the type of the parameter of a setter with the same
  // name.
  //
  // The subtype relationship is a requirement whether the getter and setter are
  // in the same class or whether one of them is in a superclass of the other.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the return type of the
  // getter `x` is `num`, the parameter type of the setter `x` is `int`, and
  // `num` isn't a subtype of `int`:
  //
  // ```dart
  // class C {
  //   num get [!x!] => 0;
  //
  //   set x(int y) {}
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the type of the getter is correct, then change the type of the setter:
  //
  // ```dart
  // class C {
  //   num get x => 0;
  //
  //   set x(num y) {}
  // }
  // ```
  //
  // If the type of the setter is correct, then change the type of the getter:
  //
  // ```dart
  // class C {
  //   int get x => 0;
  //
  //   set x(int y) {}
  // }
  // ```
  static const CompileTimeErrorCode GETTER_NOT_SUBTYPE_SETTER_TYPES =
      CompileTimeErrorCode(
    'GETTER_NOT_SUBTYPE_SETTER_TYPES',
    "The return type of getter '{0}' is '{1}' which isn't a subtype of the type '{2}' of its setter '{3}'.",
    correctionMessage: "Try changing the types so that they are compatible.",
    hasPublishedDocs: true,
  );

  static const CompileTimeErrorCode IF_ELEMENT_CONDITION_FROM_DEFERRED_LIBRARY =
      CompileTimeErrorCode(
    'IF_ELEMENT_CONDITION_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as values in an if condition inside a const collection literal.",
    correctionMessage: "Try making the deferred import non-deferred.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the body of a function has the
  // `async*` modifier even though the return type of the function isn't either
  // `Stream` or a supertype of `Stream`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the body of the
  // function `f` has the 'async*' modifier even though the return type `int`
  // isn't a supertype of `Stream`:
  //
  // ```dart
  // [!int!] f() async* {}
  // ```
  //
  // #### Common fixes
  //
  // If the function should be asynchronous, then change the return type to be
  // either `Stream` or a supertype of `Stream`:
  //
  // ```dart
  // Stream<int> f() async* {}
  // ```
  //
  // If the function should be synchronous, then remove the `async*` modifier:
  //
  // ```dart
  // int f() => 0;
  // ```
  static const CompileTimeErrorCode ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE =
      CompileTimeErrorCode(
    'ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE',
    "Functions marked 'async*' must have a return type that is a supertype of 'Stream<T>' for some type 'T'.",
    correctionMessage:
        "Try fixing the return type of the function, or removing the modifier 'async*' from the function body.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the body of a function has the
  // `async` modifier even though the return type of the function isn't
  // assignable to `Future`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the body of the
  // function `f` has the `async` modifier even though the return type isn't
  // assignable to `Future`:
  //
  // ```dart
  // [!int!] f() async {
  //   return 0;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the function should be asynchronous, then change the return type to be
  // assignable to `Future`:
  //
  // ```dart
  // Future<int> f() async {
  //   return 0;
  // }
  // ```
  //
  // If the function should be synchronous, then remove the `async` modifier:
  //
  // ```dart
  // int f() => 0;
  // ```
  static const CompileTimeErrorCode ILLEGAL_ASYNC_RETURN_TYPE =
      CompileTimeErrorCode(
    'ILLEGAL_ASYNC_RETURN_TYPE',
    "Functions marked 'async' must have a return type assignable to 'Future'.",
    correctionMessage:
        "Try fixing the return type of the function, or removing the modifier 'async' from the function body.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the body of a function has the
  // `sync*` modifier even though the return type of the function isn't either
  // `Iterable` or a supertype of `Iterable`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the body of the
  // function `f` has the 'sync*' modifier even though the return type `int`
  // isn't a supertype of `Iterable`:
  //
  // ```dart
  // [!int!] f() sync* {}
  // ```
  //
  // #### Common fixes
  //
  // If the function should return an iterable, then change the return type to
  // be either `Iterable` or a supertype of `Iterable`:
  //
  // ```dart
  // Iterable<int> f() sync* {}
  // ```
  //
  // If the function should return a single value, then remove the `sync*`
  // modifier:
  //
  // ```dart
  // int f() => 0;
  // ```
  static const CompileTimeErrorCode ILLEGAL_SYNC_GENERATOR_RETURN_TYPE =
      CompileTimeErrorCode(
    'ILLEGAL_SYNC_GENERATOR_RETURN_TYPE',
    "Functions marked 'sync*' must have a return type that is a supertype of 'Iterable<T>' for some type 'T'.",
    correctionMessage:
        "Try fixing the return type of the function, or removing the modifier 'sync*' from the function body.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  static const CompileTimeErrorCode IMPLEMENTS_DEFERRED_CLASS =
      CompileTimeErrorCode(
    'SUBTYPE_OF_DEFERRED_CLASS',
    "Classes and mixins can't implement deferred classes.",
    correctionMessage:
        "Try specifying a different interface, removing the class from the list, or changing the import to not be deferred.",
    hasPublishedDocs: true,
    uniqueName: 'IMPLEMENTS_DEFERRED_CLASS',
  );

  /**
   * Parameters:
   * 0: the name of the disallowed type
   */
  static const CompileTimeErrorCode IMPLEMENTS_DISALLOWED_CLASS =
      CompileTimeErrorCode(
    'SUBTYPE_OF_DISALLOWED_TYPE',
    "Classes and mixins can't implement '{0}'.",
    correctionMessage:
        "Try specifying a different interface, or remove the class from the list.",
    hasPublishedDocs: true,
    uniqueName: 'IMPLEMENTS_DISALLOWED_CLASS',
  );

  /**
   * Parameters:
   * 0: the name of the interface that was not found
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a name used in the `implements`
  // clause of a class or mixin declaration is defined to be something other
  // than a class or mixin.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `x` is a variable
  // rather than a class or mixin:
  //
  // ```dart
  // var x;
  // class C implements [!x!] {}
  // ```
  //
  // #### Common fixes
  //
  // If the name is the name of an existing class or mixin that's already being
  // imported, then add a prefix to the import so that the local definition of
  // the name doesn't shadow the imported name.
  //
  // If the name is the name of an existing class or mixin that isn't being
  // imported, then add an import, with a prefix, for the library in which it’s
  // declared.
  //
  // Otherwise, either replace the name in the `implements` clause with the name
  // of an existing class or mixin, or remove the name from the `implements`
  // clause.
  static const CompileTimeErrorCode IMPLEMENTS_NON_CLASS = CompileTimeErrorCode(
    'IMPLEMENTS_NON_CLASS',
    "Classes and mixins can only implement other classes and mixins.",
    correctionMessage:
        "Try specifying a class or mixin, or remove the name from the list.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the interface that is implemented more than once
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a single class is specified more
  // than once in an `implements` clause.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `A` is in the list
  // twice:
  //
  // ```dart
  // class A {}
  // class B implements A, [!A!] {}
  // ```
  //
  // #### Common fixes
  //
  // Remove all except one occurrence of the class name:
  //
  // ```dart
  // class A {}
  // class B implements A {}
  // ```
  static const CompileTimeErrorCode IMPLEMENTS_REPEATED = CompileTimeErrorCode(
    'IMPLEMENTS_REPEATED',
    "'{0}' can only be implemented once.",
    correctionMessage: "Try removing all but one occurrence of the class name.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the class that appears in both "extends" and "implements"
   *    clauses
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when one class is listed in both the
  // `extends` and `implements` clauses of another class.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the class `A` is used
  // in both the `extends` and `implements` clauses for the class `B`:
  //
  // ```dart
  // class A {}
  //
  // class B extends A implements [!A!] {}
  // ```
  //
  // #### Common fixes
  //
  // If you want to inherit the implementation from the class, then remove the
  // class from the `implements` clause:
  //
  // ```dart
  // class A {}
  //
  // class B extends A {}
  // ```
  //
  // If you don't want to inherit the implementation from the class, then remove
  // the `extends` clause:
  //
  // ```dart
  // class A {}
  //
  // class B implements A {}
  // ```
  static const CompileTimeErrorCode IMPLEMENTS_SUPER_CLASS =
      CompileTimeErrorCode(
    'IMPLEMENTS_SUPER_CLASS',
    "'{0}' can't be used in both the 'extends' and 'implements' clauses.",
    correctionMessage: "Try removing one of the occurrences.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  static const CompileTimeErrorCode
      IMPLEMENTS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER = CompileTimeErrorCode(
    'SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER',
    "A type alias that expands to a type parameter can't be implemented.",
    correctionMessage: "Try specifying a class or mixin, or removing the list.",
    hasPublishedDocs: true,
    uniqueName: 'IMPLEMENTS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
  );

  /**
   * Parameters:
   * 0: the name of the instance member
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when it finds a reference to an
  // instance member in a constructor's initializer list.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `defaultX` is an
  // instance member:
  //
  // ```dart
  // class C {
  //   int x;
  //
  //   C() : x = [!defaultX!];
  //
  //   int get defaultX => 0;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the member can be made static, then do so:
  //
  // ```dart
  // class C {
  //   int x;
  //
  //   C() : x = defaultX;
  //
  //   static int get defaultX => 0;
  // }
  // ```
  //
  // If not, then replace the reference in the initializer with a different
  // expression that doesn't use an instance member:
  //
  // ```dart
  // class C {
  //   int x;
  //
  //   C() : x = 0;
  //
  //   int get defaultX => 0;
  // }
  // ```
  static const CompileTimeErrorCode IMPLICIT_THIS_REFERENCE_IN_INITIALIZER =
      CompileTimeErrorCode(
    'IMPLICIT_THIS_REFERENCE_IN_INITIALIZER',
    "The instance member '{0}' can't be accessed in an initializer.",
    correctionMessage:
        "Try replacing the reference to the instance member with a different expression",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the uri pointing to a library
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when it finds an import whose `dart:`
  // URI references an internal library.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `_interceptors` is an
  // internal library:
  //
  // ```dart
  // import [!'dart:_interceptors'!];
  // ```
  //
  // #### Common fixes
  //
  // Remove the import directive.
  static const CompileTimeErrorCode IMPORT_INTERNAL_LIBRARY =
      CompileTimeErrorCode(
    'IMPORT_INTERNAL_LIBRARY',
    "The library '{0}' is internal and can't be imported.",
    hasPublishedDocs: true,
  );

  /**
   * 14.1 Imports: It is a compile-time error if the specified URI of an
   * immediate import does not refer to a library declaration.
   *
   * Parameters:
   * 0: the uri pointing to a non-library declaration
   */
  static const CompileTimeErrorCode IMPORT_OF_NON_LIBRARY =
      CompileTimeErrorCode(
    'IMPORT_OF_NON_LIBRARY',
    "The imported library '{0}' can't have a part-of directive.",
    correctionMessage: "Try importing the library that the part is a part of.",
  );

  /**
   * 13.9 Switch: It is a compile-time error if values of the expressions
   * <i>e<sub>k</sub></i> are not instances of the same class <i>C</i>, for all
   * <i>1 &lt;= k &lt;= n</i>.
   *
   * Parameters:
   * 0: the expression source code that is the unexpected type
   * 1: the name of the expected type
   */
  static const CompileTimeErrorCode INCONSISTENT_CASE_EXPRESSION_TYPES =
      CompileTimeErrorCode(
    'INCONSISTENT_CASE_EXPRESSION_TYPES',
    "Case expressions must have the same types, '{0}' isn't a '{1}'.",
  );

  /**
   * Parameters:
   * 0: the name of the instance member with inconsistent inheritance.
   * 1: the list of all inherited signatures for this member.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a class inherits two or more
  // conflicting signatures for a member and doesn't provide an implementation
  // that satisfies all the inherited signatures.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `C` is inheriting the
  // declaration of `m` from `A`, and that implementation isn't consistent with
  // the signature of `m` that's inherited from `B`:
  //
  // ```dart
  // %language=2.9
  // class A {
  //   void m({int a}) {}
  // }
  //
  // class B {
  //   void m({int b}) {}
  // }
  //
  // class [!C!] extends A implements B {
  // }
  // ```
  //
  // #### Common fixes
  //
  // Add an implementation of the method that satisfies all the inherited
  // signatures:
  //
  // ```dart
  // %language=2.9
  // class A {
  //   void m({int a}) {}
  // }
  //
  // class B {
  //   void m({int b}) {}
  // }
  //
  // class C extends A implements B {
  //   void m({int a, int b}) {}
  // }
  // ```
  static const CompileTimeErrorCode INCONSISTENT_INHERITANCE =
      CompileTimeErrorCode(
    'INCONSISTENT_INHERITANCE',
    "Superinterfaces don't have a valid override for '{0}': {1}.",
    correctionMessage:
        "Try adding an explicit override that is consistent with all of the inherited members.",
    hasPublishedDocs: true,
  );

  /**
   * 11.1.1 Inheritance and Overriding. Let `I` be the implicit interface of a
   * class `C` declared in library `L`. `I` inherits all members of
   * `inherited(I, L)` and `I` overrides `m'` if `m' ∈ overrides(I, L)`. It is
   * a compile-time error if `m` is a method and `m'` is a getter, or if `m`
   * is a getter and `m'` is a method.
   *
   * Parameters:
   * 0: the name of the instance member with inconsistent inheritance.
   * 1: the name of the superinterface that declares the name as a getter.
   * 2: the name of the superinterface that declares the name as a method.
   */
  static const CompileTimeErrorCode INCONSISTENT_INHERITANCE_GETTER_AND_METHOD =
      CompileTimeErrorCode(
    'INCONSISTENT_INHERITANCE_GETTER_AND_METHOD',
    "'{0}' is inherited as a getter (from '{1}') and also a method (from '{2}').",
    correctionMessage:
        "Try adjusting the supertypes of this class to remove the inconsistency.",
  );

  /**
   * It is a compile-time error if a part file has a different language version
   * override than its library.
   *
   * https://github.com/dart-lang/language/blob/master/accepted/
   * future-releases/language-versioning/feature-specification.md
   * #individual-library-language-version-override
   */
  static const CompileTimeErrorCode INCONSISTENT_LANGUAGE_VERSION_OVERRIDE =
      CompileTimeErrorCode(
    'INCONSISTENT_LANGUAGE_VERSION_OVERRIDE',
    "Parts must have exactly the same language version override as the library.",
  );

  /**
   * Parameters:
   * 0: the name of the initializing formal that is not an instance variable in
   *    the immediately enclosing class
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a constructor initializes a
  // field that isn't declared in the class containing the constructor.
  // Constructors can't initialize fields that aren't declared and fields that
  // are inherited from superclasses.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the initializer is
  // initializing `x`, but `x` isn't a field in the class:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   int y;
  //
  //   C() : [!x = 0!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // If a different field should be initialized, then change the name to the
  // name of the field:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   int y;
  //
  //   C() : y = 0;
  // }
  // ```
  //
  // If the field must be declared, then add a declaration:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   int x;
  //   int y;
  //
  //   C() : x = 0;
  // }
  // ```
  static const CompileTimeErrorCode INITIALIZER_FOR_NON_EXISTENT_FIELD =
      CompileTimeErrorCode(
    'INITIALIZER_FOR_NON_EXISTENT_FIELD',
    "'{0}' isn't a field in the enclosing class.",
    correctionMessage:
        "Try correcting the name to match an existing field, or defining a field named '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the initializing formal that is a static variable in the
   *    immediately enclosing class
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a static field is initialized in
  // a constructor using either a field formal parameter or an assignment in the
  // initializer list.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the static field `a` is
  // being initialized by the field formal parameter `this.a`:
  //
  // ```dart
  // class C {
  //   static int? a;
  //   C([!this.a!]);
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the field should be an instance field, then remove the keyword `static`:
  //
  // ```dart
  // class C {
  //   int? a;
  //   C(this.a);
  // }
  // ```
  //
  // If you intended to initialize an instance field and typed the wrong name,
  // then correct the name of the field being initialized:
  //
  // ```dart
  // class C {
  //   static int? a;
  //   int? b;
  //   C(this.b);
  // }
  // ```
  //
  // If you really want to initialize the static field, then move the
  // initialization into the constructor body:
  //
  // ```dart
  // class C {
  //   static int? a;
  //   C(int? c) {
  //     a = c;
  //   }
  // }
  // ```
  static const CompileTimeErrorCode INITIALIZER_FOR_STATIC_FIELD =
      CompileTimeErrorCode(
    'INITIALIZER_FOR_STATIC_FIELD',
    "'{0}' is a static field in the enclosing class. Fields initialized in a constructor can't be static.",
    correctionMessage: "Try removing the initialization.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the initializing formal that is not an instance variable in
   *    the immediately enclosing class
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a field formal parameter is
  // found in a constructor in a class that doesn't declare the field being
  // initialized. Constructors can't initialize fields that aren't declared and
  // fields that are inherited from superclasses.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the field `x` isn't
  // defined:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   int y;
  //
  //   C([!this.x!]);
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the field name was wrong, then change it to the name of an existing
  // field:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   int y;
  //
  //   C(this.y);
  // }
  // ```
  //
  // If the field name is correct but hasn't yet been defined, then declare the
  // field:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   int x;
  //   int y;
  //
  //   C(this.x);
  // }
  // ```
  //
  // If the parameter is needed but shouldn't initialize a field, then convert
  // it to a normal parameter and use it:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   int y;
  //
  //   C(int x) : y = x * 2;
  // }
  // ```
  //
  // If the parameter isn't needed, then remove it:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   int y;
  //
  //   C();
  // }
  // ```
  static const CompileTimeErrorCode INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD =
      CompileTimeErrorCode(
    'INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD',
    "'{0}' isn't a field in the enclosing class.",
    correctionMessage:
        "Try correcting the name to match an existing field, or defining a field named '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the static member
   * 1: the kind of the static member (field, getter, setter, or method)
   * 2: the name of the static member's enclosing element
   * 3: the kind of the static member's enclosing element (class, mixin, or extension)
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an access operator is used to
  // access a static member through an instance of the class.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `zero` is a static
  // field, but it’s being accessed as if it were an instance field:
  //
  // ```dart
  // void f(C c) {
  //   c.[!zero!];
  // }
  //
  // class C {
  //   static int zero = 0;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Use the class to access the static member:
  //
  // ```dart
  // void f(C c) {
  //   C.zero;
  // }
  //
  // class C {
  //   static int zero = 0;
  // }
  // ```
  static const CompileTimeErrorCode INSTANCE_ACCESS_TO_STATIC_MEMBER =
      CompileTimeErrorCode(
    'INSTANCE_ACCESS_TO_STATIC_MEMBER',
    "The static {1} '{0}' can't be accessed through an instance.",
    correctionMessage: "Try using the {3} '{2}' to access the {1}.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the static member
   * 1: the kind of the static member (field, getter, setter, or method)
   */
  static const CompileTimeErrorCode
      INSTANCE_ACCESS_TO_STATIC_MEMBER_OF_UNNAMED_EXTENSION =
      CompileTimeErrorCode(
    'INSTANCE_ACCESS_TO_STATIC_MEMBER',
    "The static {1} '{0}' can't be accessed through an instance.",
    hasPublishedDocs: true,
    uniqueName: 'INSTANCE_ACCESS_TO_STATIC_MEMBER_OF_UNNAMED_EXTENSION',
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a factory constructor contains
  // an unqualified reference to an instance member. In a generative
  // constructor, the instance of the class is created and initialized before
  // the body of the constructor is executed, so the instance can be bound to
  // `this` and accessed just like it would be in an instance method. But, in a
  // factory constructor, the instance isn't created before executing the body,
  // so `this` can't be used to reference it.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `x` isn't in scope in
  // the factory constructor:
  //
  // ```dart
  // class C {
  //   int x;
  //   factory C() {
  //     return C._([!x!]);
  //   }
  //   C._(this.x);
  // }
  // ```
  //
  // #### Common fixes
  //
  // Rewrite the code so that it doesn't reference the instance member:
  //
  // ```dart
  // class C {
  //   int x;
  //   factory C() {
  //     return C._(0);
  //   }
  //   C._(this.x);
  // }
  // ```
  static const CompileTimeErrorCode INSTANCE_MEMBER_ACCESS_FROM_FACTORY =
      CompileTimeErrorCode(
    'INSTANCE_MEMBER_ACCESS_FROM_FACTORY',
    "Instance members can't be accessed from a factory constructor.",
    correctionMessage: "Try removing the reference to the instance member.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a static method contains an
  // unqualified reference to an instance member.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the instance field `x`
  // is being referenced in a static method:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   int x;
  //
  //   static int m() {
  //     return [!x!];
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the method must reference the instance member, then it can't be static,
  // so remove the keyword:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   int x;
  //
  //   int m() {
  //     return x;
  //   }
  // }
  // ```
  //
  // If the method can't be made an instance method, then add a parameter so
  // that an instance of the class can be passed in:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   int x;
  //
  //   static int m(C c) {
  //     return c.x;
  //   }
  // }
  // ```
  static const CompileTimeErrorCode INSTANCE_MEMBER_ACCESS_FROM_STATIC =
      CompileTimeErrorCode(
    'INSTANCE_MEMBER_ACCESS_FROM_STATIC',
    "Instance members can't be accessed from a static method.",
    correctionMessage:
        "Try removing the reference to the instance member, or removing the keyword 'static' from the method.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when it finds a constructor
  // invocation and the constructor is declared in an abstract class. Even
  // though you can't create an instance of an abstract class, abstract classes
  // can declare constructors that can be invoked by subclasses.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `C` is an abstract
  // class:
  //
  // ```dart
  // abstract class C {}
  //
  // var c = new [!C!]();
  // ```
  //
  // #### Common fixes
  //
  // If there's a concrete subclass of the abstract class that can be used, then
  // create an instance of the concrete subclass.
  static const CompileTimeErrorCode INSTANTIATE_ABSTRACT_CLASS =
      CompileTimeErrorCode(
    'INSTANTIATE_ABSTRACT_CLASS',
    "Abstract classes can't be instantiated.",
    correctionMessage: "Try creating an instance of a concrete subtype.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an enum is instantiated. It's
  // invalid to create an instance of an enum by invoking a constructor; only
  // the instances named in the declaration of the enum can exist.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the enum `E` is being
  // instantiated:
  //
  // ```dart
  // enum E {a}
  //
  // var e = [!E!]();
  // ```
  //
  // #### Common fixes
  //
  // If you intend to use an instance of the enum, then reference one of the
  // constants defined in the enum:
  //
  // ```dart
  // enum E {a}
  //
  // var e = E.a;
  // ```
  //
  // If you intend to use an instance of a class, then use the name of that class in place of the name of the enum.
  static const CompileTimeErrorCode INSTANTIATE_ENUM = CompileTimeErrorCode(
    'INSTANTIATE_ENUM',
    "Enums can't be instantiated.",
    correctionMessage: "Try using one of the defined constants.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a constructor invocation is
  // found where the type being instantiated is a type alias for one of the type
  // parameters of the type alias. This isn’t allowed because the value of the
  // type parameter is a type rather than a class.
  //
  // #### Example
  //
  // The following code produces this diagnostic because it creates an instance
  // of `A`, even though `A` is a type alias that is defined to be equivalent to
  // a type parameter:
  //
  // ```dart
  // typedef A<T> = T;
  //
  // void f() {
  //   const [!A!]<int>();
  // }
  // ```
  //
  // #### Common fixes
  //
  // Use either a class name or a type alias defined to be a class, rather than
  // a type alias defined to be a type parameter:
  //
  // ```dart
  // typedef A<T> = C<T>;
  //
  // void f() {
  //   const A<int>();
  // }
  //
  // class C<T> {
  //   const C();
  // }
  // ```
  static const CompileTimeErrorCode
      INSTANTIATE_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER = CompileTimeErrorCode(
    'INSTANTIATE_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    "Type aliases that expand to a type parameter can't be instantiated.",
    correctionMessage: "Try replacing it with a class.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the lexeme of the integer
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an integer literal is being
  // implicitly converted to a double, but can't be represented as a 64-bit
  // double without overflow or loss of precision. Integer literals are
  // implicitly converted to a double if the context requires the type `double`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the integer value
  // `9223372036854775807` can't be represented exactly as a double:
  //
  // ```dart
  // double x = [!9223372036854775807!];
  // ```
  //
  // #### Common fixes
  //
  // If you need to use the exact value, then use the class `BigInt` to
  // represent the value:
  //
  // ```dart
  // var x = BigInt.parse('9223372036854775807');
  // ```
  //
  // If you need to use a double, then change the value to one that can be
  // represented exactly:
  //
  // ```dart
  // double x = 9223372036854775808;
  // ```
  static const CompileTimeErrorCode INTEGER_LITERAL_IMPRECISE_AS_DOUBLE =
      CompileTimeErrorCode(
    'INTEGER_LITERAL_IMPRECISE_AS_DOUBLE',
    "The integer literal is being used as a double, but can't be represented as a 64-bit double without overflow or loss of precision: '{0}'.",
    correctionMessage:
        "Try using the class 'BigInt', or switch to the closest valid double: '{1}'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an integer literal has a value
  // that is too large (positive) or too small (negative) to be represented in a
  // 64-bit word.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the value can't be
  // represented in 64 bits:
  //
  // ```dart
  // var x = [!9223372036854775810!];
  // ```
  //
  // #### Common fixes
  //
  // If you need to represent the current value, then wrap it in an instance of
  // the class `BigInt`:
  //
  // ```dart
  // var x = BigInt.parse('9223372036854775810');
  // ```
  static const CompileTimeErrorCode INTEGER_LITERAL_OUT_OF_RANGE =
      CompileTimeErrorCode(
    'INTEGER_LITERAL_OUT_OF_RANGE',
    "The integer literal {0} can't be represented in 64 bits.",
    correctionMessage:
        "Try using the 'BigInt' class if you need an integer larger than 9,223,372,036,854,775,807 or less than -9,223,372,036,854,775,808.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an annotation is found that is
  // using something that is neither a variable marked as `const` or the
  // invocation of a `const` constructor.
  //
  // Getters can't be used as annotations.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because the variable `v` isn't
  // a `const` variable:
  //
  // ```dart
  // var v = 0;
  //
  // [!@v!]
  // void f() {
  // }
  // ```
  //
  // The following code produces this diagnostic because `f` isn't a variable:
  //
  // ```dart
  // [!@f!]
  // void f() {
  // }
  // ```
  //
  // The following code produces this diagnostic because `f` isn't a
  // constructor:
  //
  // ```dart
  // [!@f()!]
  // void f() {
  // }
  // ```
  //
  // The following code produces this diagnostic because `g` is a getter:
  //
  // ```dart
  // [!@g!]
  // int get g => 0;
  // ```
  //
  // #### Common fixes
  //
  // If the annotation is referencing a variable that isn't a `const`
  // constructor, add the keyword `const` to the variable's declaration:
  //
  // ```dart
  // const v = 0;
  //
  // @v
  // void f() {
  // }
  // ```
  //
  // If the annotation isn't referencing a variable, then remove it:
  //
  // ```dart
  // int v = 0;
  //
  // void f() {
  // }
  // ```
  static const CompileTimeErrorCode INVALID_ANNOTATION = CompileTimeErrorCode(
    'INVALID_ANNOTATION',
    "Annotation must be either a const variable reference or const constructor invocation.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a constant defined in a library
  // that is imported as a deferred library is referenced in the argument list
  // of an annotation. Annotations are evaluated at compile time, and values
  // from deferred libraries aren't available at compile time.
  //
  // For more information, see the language tour's coverage of
  // [deferred loading](https://dart.dev/guides/language/language-tour#lazily-loading-a-library).
  //
  // #### Example
  //
  // The following code produces this diagnostic because the constant `pi` is
  // being referenced in the argument list of an annotation, even though the
  // library that defines it is being imported as a deferred library:
  //
  // ```dart
  // import 'dart:math' deferred as math;
  //
  // class C {
  //   const C(double d);
  // }
  //
  // @C([!math.pi!])
  // void f () {}
  // ```
  //
  // #### Common fixes
  //
  // If you need to reference the imported constant, then remove the `deferred`
  // keyword:
  //
  // ```dart
  // import 'dart:math' as math;
  //
  // class C {
  //   const C(double d);
  // }
  //
  // @C(math.pi)
  // void f () {}
  // ```
  //
  // If the import is required to be deferred and there's another constant that
  // is appropriate, then use that constant in place of the constant from the
  // deferred library.
  static const CompileTimeErrorCode
      INVALID_ANNOTATION_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY =
      CompileTimeErrorCode(
    'INVALID_ANNOTATION_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used in annotations.",
    correctionMessage:
        "Try moving the constant from the deferred library, or removing 'deferred' from the import.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a constant from a library that
  // is imported using a deferred import is used as an annotation. Annotations
  // are evaluated at compile time, and constants from deferred libraries aren't
  // available at compile time.
  //
  // For more information, see the language tour's coverage of
  // [deferred loading](https://dart.dev/guides/language/language-tour#lazily-loading-a-library).
  //
  // #### Example
  //
  // The following code produces this diagnostic because the constant `pi` is
  // being used as an annotation when the library `dart:math` is imported as
  // `deferred`:
  //
  // ```dart
  // import 'dart:math' deferred as math;
  //
  // @[!math.pi!]
  // void f() {}
  // ```
  //
  // #### Common fixes
  //
  // If you need to reference the constant as an annotation, then remove the
  // keyword `deferred` from the import:
  //
  // ```dart
  // import 'dart:math' as math;
  //
  // @math.pi
  // void f() {}
  // ```
  //
  // If you can use a different constant as an annotation, then replace the
  // annotation with a different constant:
  //
  // ```dart
  // @deprecated
  // void f() {}
  // ```
  static const CompileTimeErrorCode INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY =
      CompileTimeErrorCode(
    'INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as annotations.",
    correctionMessage:
        "Try removing the annotation, or changing the import to not be deferred.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the right hand side type
   * 1: the name of the left hand side type
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the static type of an expression
  // that is assigned to a variable isn't assignable to the type of the
  // variable.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the type of the
  // initializer (`int`) isn't assignable to the type of the variable
  // (`String`):
  //
  // ```dart
  // int i = 0;
  // String s = [!i!];
  // ```
  //
  // #### Common fixes
  //
  // If the value being assigned is always assignable at runtime, even though
  // the static types don't reflect that, then add an explicit cast.
  //
  // Otherwise, change the value being assigned so that it has the expected
  // type. In the previous example, this might look like:
  //
  // ```dart
  // int i = 0;
  // String s = i.toString();
  // ```
  //
  // If you can’t change the value, then change the type of the variable to be
  // compatible with the type of the value being assigned:
  //
  // ```dart
  // int i = 0;
  // int s = i;
  // ```
  static const CompileTimeErrorCode INVALID_ASSIGNMENT = CompileTimeErrorCode(
    'INVALID_ASSIGNMENT',
    "A value of type '{0}' can't be assigned to a variable of type '{1}'.",
    correctionMessage:
        "Try changing the type of the variable, or casting the right-hand type to '{1}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the type of the function
   * 1: the expected function type
   */
  static const CompileTimeErrorCode INVALID_CAST_FUNCTION =
      CompileTimeErrorCode(
    'INVALID_CAST_FUNCTION',
    "The function '{0}' has type '{1}' that isn't of expected type '{2}'. This means its parameter or return type doesn't match what is expected.",
  );

  /**
   * Parameters:
   * 0: the type of the torn-off function expression
   * 1: the expected function type
   */
  static const CompileTimeErrorCode INVALID_CAST_FUNCTION_EXPR =
      CompileTimeErrorCode(
    'INVALID_CAST_FUNCTION_EXPR',
    "The function expression type '{0}' isn't of type '{1}'. This means its parameter or return type doesn't match what is expected. Consider changing parameter type(s) or the returned type(s).",
  );

  /**
   * Parameters:
   * 0: the type of the literal
   * 1: the expected type
   */
  static const CompileTimeErrorCode INVALID_CAST_LITERAL = CompileTimeErrorCode(
    'INVALID_CAST_LITERAL',
    "The literal '{0}' with type '{1}' isn't of expected type '{2}'.",
  );

  /**
   * Parameters:
   * 0: the type of the list literal
   * 1: the expected type
   */
  static const CompileTimeErrorCode INVALID_CAST_LITERAL_LIST =
      CompileTimeErrorCode(
    'INVALID_CAST_LITERAL_LIST',
    "The list literal type '{0}' isn't of expected type '{1}'. The list's type can be changed with an explicit generic type argument or by changing the element types.",
  );

  /**
   * Parameters:
   * 0: the type of the map literal
   * 1: the expected type
   */
  static const CompileTimeErrorCode INVALID_CAST_LITERAL_MAP =
      CompileTimeErrorCode(
    'INVALID_CAST_LITERAL_MAP',
    "The map literal type '{0}' isn't of expected type '{1}'. The maps's type can be changed with an explicit generic type arguments or by changing the key and value types.",
  );

  /**
   * Parameters:
   * 0: the type of the set literal
   * 1: the expected type
   */
  static const CompileTimeErrorCode INVALID_CAST_LITERAL_SET =
      CompileTimeErrorCode(
    'INVALID_CAST_LITERAL_SET',
    "The set literal type '{0}' isn't of expected type '{1}'. The set's type can be changed with an explicit generic type argument or by changing the element types.",
  );

  /**
   * Parameters:
   * 0: the type of the torn-off method
   * 1: the expected function type
   */
  static const CompileTimeErrorCode INVALID_CAST_METHOD = CompileTimeErrorCode(
    'INVALID_CAST_METHOD',
    "The method tear-off '{0}' has type '{1}' that isn't of expected type '{2}'. This means its parameter or return type doesn't match what is expected.",
  );

  /**
   * Parameters:
   * 0: the type of the instantiated object
   * 1: the expected type
   */
  static const CompileTimeErrorCode INVALID_CAST_NEW_EXPR =
      CompileTimeErrorCode(
    'INVALID_CAST_NEW_EXPR',
    "The constructor returns type '{0}' that isn't of expected type '{1}'.",
  );

  /**
   * TODO(brianwilkerson) Remove this when we have decided on how to report
   * errors in compile-time constants. Until then, this acts as a placeholder
   * for more informative errors.
   *
   * See TODOs in ConstantVisitor
   */
  static const CompileTimeErrorCode INVALID_CONSTANT = CompileTimeErrorCode(
    'INVALID_CONSTANT',
    "Invalid constant value.",
  );

  /**
   * 7.6 Constructors: It is a compile-time error if the name of a constructor
   * is not a constructor name.
   */
  static const CompileTimeErrorCode INVALID_CONSTRUCTOR_NAME =
      CompileTimeErrorCode(
    'INVALID_CONSTRUCTOR_NAME',
    "Invalid constructor name.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an extension override doesn't
  // have exactly one argument. The argument is the expression used to compute
  // the value of `this` within the extension method, so there must be one
  // argument.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because there are no arguments:
  //
  // ```dart
  // extension E on String {
  //   String join(String other) => '$this $other';
  // }
  //
  // void f() {
  //   E[!()!].join('b');
  // }
  // ```
  //
  // And, the following code produces this diagnostic because there's more than
  // one argument:
  //
  // ```dart
  // extension E on String {
  //   String join(String other) => '$this $other';
  // }
  //
  // void f() {
  //   E[!('a', 'b')!].join('c');
  // }
  // ```
  //
  // #### Common fixes
  //
  // Provide one argument for the extension override:
  //
  // ```dart
  // extension E on String {
  //   String join(String other) => '$this $other';
  // }
  //
  // void f() {
  //   E('a').join('b');
  // }
  // ```
  static const CompileTimeErrorCode INVALID_EXTENSION_ARGUMENT_COUNT =
      CompileTimeErrorCode(
    'INVALID_EXTENSION_ARGUMENT_COUNT',
    "Extension overrides must have exactly one argument: the value of 'this' in the extension method.",
    correctionMessage: "Try specifying exactly one argument.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the name of a factory
  // constructor isn't the same as the name of the surrounding class.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the name of the factory
  // constructor (`A`) isn't the same as the surrounding class (`C`):
  //
  // ```dart
  // class A {}
  //
  // class C {
  //   factory [!A!]() => throw 0;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the factory returns an instance of the surrounding class, then rename
  // the factory:
  //
  // ```dart
  // class A {}
  //
  // class C {
  //   factory C() => throw 0;
  // }
  // ```
  //
  // If the factory returns an instance of a different class, then move the
  // factory to that class:
  //
  // ```dart
  // class A {
  //   factory A() => throw 0;
  // }
  //
  // class C {}
  // ```
  //
  // If the factory returns an instance of a different class, but you can't
  // modify that class or don't want to move the factory, then convert it to be
  // a static method:
  //
  // ```dart
  // class A {}
  //
  // class C {
  //   static A a() => throw 0;
  // }
  // ```
  static const CompileTimeErrorCode INVALID_FACTORY_NAME_NOT_A_CLASS =
      CompileTimeErrorCode(
    'INVALID_FACTORY_NAME_NOT_A_CLASS',
    "The name of a factory constructor must be the same as the name of the immediately enclosing class.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the declared member that is not a valid override.
   * 1: the name of the interface that declares the member.
   * 2: the type of the declared member in the interface.
   * 3. the name of the interface with the overridden member.
   * 4. the type of the overridden member.
   *
   * These parameters must be kept in sync with those of
   * [CompileTimeErrorCode.INVALID_OVERRIDE].
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when all of the following are true:
  //
  // - A class defines an abstract member.
  // - There is a concrete implementation of that member in a superclass.
  // - The concrete implementation isn't a valid implementation of the abstract
  //   method.
  //
  // The concrete implementation can be invalid because of incompatibilities in
  // either the return type, the types of parameters, or the type variables.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the method `A.add` has
  // a parameter of type `int`, and the overriding method `B.add` has a
  // corresponding parameter of type `num`:
  //
  // ```dart
  // class A {
  //   int add(int a) => a;
  // }
  // class [!B!] extends A {
  //   int add(num a);
  // }
  // ```
  //
  // This is a problem because in an invocation of `B.add` like the following:
  //
  // ```dart
  // void f(B b) {
  //   b.add(3.4);
  // }
  // ```
  //
  // `B.add` is expecting to be able to take, for example, a `double`, but when
  // the method `A.add` is executed (because it's the only concrete
  // implementation of `add`), a runtime exception will be thrown because a
  // `double` can't be assigned to a parameter of type `int`.
  //
  // #### Common fixes
  //
  // If the method in the subclass can conform to the implementation in the
  // superclass, then change the declaration in the subclass (or remove it if
  // it's the same):
  //
  // ```dart
  // class A {
  //   int add(int a) => a;
  // }
  // class B	extends A {
  //   int add(int a);
  // }
  // ```
  //
  // If the method in the superclass can be generalized to be a valid
  // implementation of the method in the subclass, then change the superclass
  // method:
  //
  // ```dart
  // class A {
  //   int add(num a) => a.floor();
  // }
  // class B	extends A {
  //   int add(num a);
  // }
  // ```
  //
  // If neither the method in the superclass nor the method in the subclass can
  // be changed, then provide a concrete implementation of the method in the
  // subclass:
  //
  // ```dart
  // class A {
  //   int add(int a) => a;
  // }
  // class B	extends A {
  //   int add(num a) => a.floor();
  // }
  // ```
  static const CompileTimeErrorCode INVALID_IMPLEMENTATION_OVERRIDE =
      CompileTimeErrorCode(
    'INVALID_IMPLEMENTATION_OVERRIDE',
    "'{1}.{0}' ('{2}') isn't a valid concrete implementation of '{3}.{0}' ('{4}').",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a generic function type has a
  // function-valued parameter that is written using the older inline function
  // type syntax.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the parameter `f`, in
  // the generic function type used to define `F`, uses the inline function
  // type syntax:
  //
  // ```dart
  // typedef F = int Function(int f[!(!]String s));
  // ```
  //
  // #### Common fixes
  //
  // Use the generic function syntax for the parameter's type:
  //
  // ```dart
  // typedef F = int Function(int Function(String));
  // ```
  static const CompileTimeErrorCode INVALID_INLINE_FUNCTION_TYPE =
      CompileTimeErrorCode(
    'INVALID_INLINE_FUNCTION_TYPE',
    "Inline function types can't be used for parameters in a generic function type.",
    correctionMessage:
        "Try using a generic function type (returnType 'Function(' parameters ')').",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the invalid modifier
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the body of a constructor is
  // prefixed by one of the following modifiers: `async`, `async*`, or `sync*`.
  // Constructor bodies must be synchronous.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the body of the
  // constructor for `C` is marked as being `async`:
  //
  // ```dart
  // class C {
  //   C() [!async!] {}
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the constructor can be synchronous, then remove the modifier:
  //
  // ```dart
  // class C {
  //   C();
  // }
  // ```
  //
  // If the constructor can't be synchronous, then use a static method to create
  // the instance instead:
  //
  // ```dart
  // class C {
  //   C();
  //   static Future<C> c() async {
  //     return C();
  //   }
  // }
  // ```
  static const CompileTimeErrorCode INVALID_MODIFIER_ON_CONSTRUCTOR =
      CompileTimeErrorCode(
    'INVALID_MODIFIER_ON_CONSTRUCTOR',
    "The modifier '{0}' can't be applied to the body of a constructor.",
    correctionMessage: "Try removing the modifier.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the invalid modifier
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the body of a setter is prefixed
  // by one of the following modifiers: `async`, `async*`, or `sync*`. Setter
  // bodies must be synchronous.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the body of the setter
  // `x` is marked as being `async`:
  //
  // ```dart
  // class C {
  //   set x(int i) [!async!] {}
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the setter can be synchronous, then remove the modifier:
  //
  // ```dart
  // class C {
  //   set x(int i) {}
  // }
  // ```
  //
  // If the setter can't be synchronous, then use a method to set the value
  // instead:
  //
  // ```dart
  // class C {
  //   void x(int i) async {}
  // }
  // ```
  static const CompileTimeErrorCode INVALID_MODIFIER_ON_SETTER =
      CompileTimeErrorCode(
    'INVALID_MODIFIER_ON_SETTER',
    "Setters can't use 'async', 'async*', or 'sync*'.",
    correctionMessage: "Try removing the modifier.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the declared member that is not a valid override.
   * 1: the name of the interface that declares the member.
   * 2: the type of the declared member in the interface.
   * 3. the name of the interface with the overridden member.
   * 4. the type of the overridden member.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a member of a class is found
  // that overrides a member from a supertype and the override isn't valid. An
  // override is valid if all of these are true:
  // * It allows all of the arguments allowed by the overridden member.
  // * It doesn't require any arguments that aren't required by the overridden
  //   member.
  // * The type of every parameter of the overridden member is assignable to the
  //   corresponding parameter of the override.
  // * The return type of the override is assignable to the return type of the
  //   overridden member.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the type of the
  // parameter `s` (`String`) isn't assignable to the type of the parameter `i`
  // (`int`):
  //
  // ```dart
  // class A {
  //   void m(int i) {}
  // }
  //
  // class B extends A {
  //   void [!m!](String s) {}
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the invalid method is intended to override the method from the
  // superclass, then change it to conform:
  //
  // ```dart
  // class A {
  //   void m(int i) {}
  // }
  //
  // class B extends A {
  //   void m(int i) {}
  // }
  // ```
  //
  // If it isn't intended to override the method from the superclass, then
  // rename it:
  //
  // ```dart
  // class A {
  //   void m(int i) {}
  // }
  //
  // class B extends A {
  //   void m2(String s) {}
  // }
  // ```
  static const CompileTimeErrorCode INVALID_OVERRIDE = CompileTimeErrorCode(
    'INVALID_OVERRIDE',
    "'{1}.{0}' ('{2}') isn't a valid override of '{3}.{0}' ('{4}').",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when `this` is used outside of an
  // instance method or a generative constructor. The reserved word `this` is
  // only defined in the context of an instance method or a generative
  // constructor.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `v` is a top-level
  // variable:
  //
  // ```dart
  // C f() => [!this!];
  //
  // class C {}
  // ```
  //
  // #### Common fixes
  //
  // Use a variable of the appropriate type in place of `this`, declaring it if
  // necessary:
  //
  // ```dart
  // C f(C c) => c;
  //
  // class C {}
  // ```
  static const CompileTimeErrorCode INVALID_REFERENCE_TO_THIS =
      CompileTimeErrorCode(
    'INVALID_REFERENCE_TO_THIS',
    "Invalid reference to 'this' expression.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the type parameter
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a type parameter is used as a
  // type argument in a list, map, or set literal that is prefixed by `const`.
  // This isn't allowed because the value of the type parameter (the actual type
  // that will be used at runtime) can't be known at compile time.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because the type parameter `T`
  // is being used as a type argument when creating a constant list:
  //
  // ```dart
  // List<T> newList<T>() => const <[!T!]>[];
  // ```
  //
  // The following code produces this diagnostic because the type parameter `T`
  // is being used as a type argument when creating a constant map:
  //
  // ```dart
  // Map<String, T> newSet<T>() => const <String, [!T!]>{};
  // ```
  //
  // The following code produces this diagnostic because the type parameter `T`
  // is being used as a type argument when creating a constant set:
  //
  // ```dart
  // Set<T> newSet<T>() => const <[!T!]>{};
  // ```
  //
  // #### Common fixes
  //
  // If the type that will be used for the type parameter can be known at
  // compile time, then remove the type parameter:
  //
  // ```dart
  // List<int> newList() => const <int>[];
  // ```
  //
  // If the type that will be used for the type parameter can't be known until
  // runtime, then remove the keyword `const`:
  //
  // ```dart
  // List<T> newList<T>() => <T>[];
  // ```
  static const CompileTimeErrorCode INVALID_TYPE_ARGUMENT_IN_CONST_LIST =
      CompileTimeErrorCode(
    'INVALID_TYPE_ARGUMENT_IN_CONST_LITERAL',
    "Constant list literals can't include a type parameter as a type argument, such as '{0}'.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_TYPE_ARGUMENT_IN_CONST_LIST',
  );

  /**
   * Parameters:
   * 0: the name of the type parameter
   */
  static const CompileTimeErrorCode INVALID_TYPE_ARGUMENT_IN_CONST_MAP =
      CompileTimeErrorCode(
    'INVALID_TYPE_ARGUMENT_IN_CONST_LITERAL',
    "Constant map literals can't include a type parameter as a type argument, such as '{0}'.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_TYPE_ARGUMENT_IN_CONST_MAP',
  );

  /**
   * Parameters:
   * 0: the name of the type parameter
   */
  static const CompileTimeErrorCode INVALID_TYPE_ARGUMENT_IN_CONST_SET =
      CompileTimeErrorCode(
    'INVALID_TYPE_ARGUMENT_IN_CONST_LITERAL',
    "Constant set literals can't include a type parameter as a type argument, such as '{0}'.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_TYPE_ARGUMENT_IN_CONST_SET',
  );

  /**
   * Parameters:
   * 0: the URI that is invalid
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a URI in a directive doesn't
  // conform to the syntax of a valid URI.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `'#'` isn't a valid
  // URI:
  //
  // ```dart
  // import [!'#'!];
  // ```
  //
  // #### Common fixes
  //
  // Replace the invalid URI with a valid URI.
  static const CompileTimeErrorCode INVALID_URI = CompileTimeErrorCode(
    'INVALID_URI',
    "Invalid URI syntax: '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * The 'covariant' keyword was found in an inappropriate location.
   */
  static const CompileTimeErrorCode INVALID_USE_OF_COVARIANT =
      CompileTimeErrorCode(
    'INVALID_USE_OF_COVARIANT',
    "The 'covariant' keyword can only be used for parameters in instance methods or before non-final instance fields.",
    correctionMessage: "Try removing the 'covariant' keyword.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an expression whose value will
  // always be `null` is dereferenced.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `x` will always be
  // `null`:
  //
  // ```dart
  // int f(Null x) {
  //   return [!x!].length;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the value is allowed to be something other than `null`, then change the
  // type of the expression:
  //
  // ```dart
  // int f(String? x) {
  //   return x!.length;
  // }
  // ```
  static const CompileTimeErrorCode INVALID_USE_OF_NULL_VALUE =
      CompileTimeErrorCode(
    'INVALID_USE_OF_NULL_VALUE',
    "An expression whose value is always 'null' can't be dereferenced.",
    correctionMessage: "Try changing the type of the expression.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the extension
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an extension override is used to
  // invoke a function but the extension doesn't declare a `call` method.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the extension `E`
  // doesn't define a `call` method:
  //
  // ```dart
  // extension E on String {}
  //
  // void f() {
  //   [!E('')!]();
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the extension is intended to define a `call` method, then declare it:
  //
  // ```dart
  // extension E on String {
  //   int call() => 0;
  // }
  //
  // void f() {
  //   E('')();
  // }
  // ```
  //
  // If the extended type defines a `call` method, then remove the extension
  // override.
  //
  // If the `call` method isn't defined, then rewrite the code so that it
  // doesn't invoke the `call` method.
  static const CompileTimeErrorCode INVOCATION_OF_EXTENSION_WITHOUT_CALL =
      CompileTimeErrorCode(
    'INVOCATION_OF_EXTENSION_WITHOUT_CALL',
    "The extension '{0}' doesn't define a 'call' method so the override can't be used in an invocation.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the identifier that is not a function type
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when it finds a function invocation,
  // but the name of the function being invoked is defined to be something other
  // than a function.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `Binary` is the name of
  // a function type, not a function:
  //
  // ```dart
  // typedef Binary = int Function(int, int);
  //
  // int f() {
  //   return [!Binary!](1, 2);
  // }
  // ```
  //
  // #### Common fixes
  //
  // Replace the name with the name of a function.
  static const CompileTimeErrorCode INVOCATION_OF_NON_FUNCTION =
      CompileTimeErrorCode(
    'INVOCATION_OF_NON_FUNCTION',
    "'{0}' isn't a function.",
    correctionMessage:
        "Try correcting the name to match an existing function, or define a method or function named '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a function invocation is found,
  // but the name being referenced isn't the name of a function, or when the
  // expression computing the function doesn't compute a function.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because `x` isn't a function:
  //
  // ```dart
  // int x = 0;
  //
  // int f() => x;
  //
  // var y = [!x!]();
  // ```
  //
  // The following code produces this diagnostic because `f()` doesn't return a
  // function:
  //
  // ```dart
  // int x = 0;
  //
  // int f() => x;
  //
  // var y = [!f()!]();
  // ```
  //
  // #### Common fixes
  //
  // If you need to invoke a function, then replace the code before the argument
  // list with the name of a function or with an expression that computes a
  // function:
  //
  // ```dart
  // int x = 0;
  //
  // int f() => x;
  //
  // var y = f();
  // ```
  static const CompileTimeErrorCode INVOCATION_OF_NON_FUNCTION_EXPRESSION =
      CompileTimeErrorCode(
    'INVOCATION_OF_NON_FUNCTION_EXPRESSION',
    "The expression doesn't evaluate to a function, so it can't be invoked.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the unresolvable label
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a `break` or `continue`
  // statement references a label that is declared in a method or function
  // containing the function in which the `break` or `continue` statement
  // appears. The `break` and `continue` statements can't be used to transfer
  // control outside the function that contains them.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the label `loop` is
  // declared outside the local function `g`:
  //
  // ```dart
  // void f() {
  //   loop:
  //   while (true) {
  //     void g() {
  //       break [!loop!];
  //     }
  //
  //     g();
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // Try rewriting the code so that it isn't necessary to transfer control
  // outside the local function, possibly by inlining the local function:
  //
  // ```dart
  // void f() {
  //   loop:
  //   while (true) {
  //     break loop;
  //   }
  // }
  // ```
  //
  // If that isn't possible, then try rewriting the local function so that a
  // value returned by the function can be used to determine whether control is
  // transferred:
  //
  // ```dart
  // void f() {
  //   loop:
  //   while (true) {
  //     bool g() {
  //       return true;
  //     }
  //
  //     if (g()) {
  //       break loop;
  //     }
  //   }
  // }
  // ```
  static const CompileTimeErrorCode LABEL_IN_OUTER_SCOPE = CompileTimeErrorCode(
    'LABEL_IN_OUTER_SCOPE',
    "Can't reference label '{0}' declared in an outer method.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the unresolvable label
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when it finds a reference to a label
  // that isn't defined in the scope of the `break` or `continue` statement that
  // is referencing it.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the label `loop` isn't
  // defined anywhere:
  //
  // ```dart
  // void f() {
  //   for (int i = 0; i < 10; i++) {
  //     for (int j = 0; j < 10; j++) {
  //       break [!loop!];
  //     }
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the label should be on the innermost enclosing `do`, `for`, `switch`, or
  // `while` statement, then remove the label:
  //
  // ```dart
  // void f() {
  //   for (int i = 0; i < 10; i++) {
  //     for (int j = 0; j < 10; j++) {
  //       break;
  //     }
  //   }
  // }
  // ```
  //
  // If the label should be on some other statement, then add the label:
  //
  // ```dart
  // void f() {
  //   loop: for (int i = 0; i < 10; i++) {
  //     for (int j = 0; j < 10; j++) {
  //       break loop;
  //     }
  //   }
  // }
  // ```
  static const CompileTimeErrorCode LABEL_UNDEFINED = CompileTimeErrorCode(
    'LABEL_UNDEFINED',
    "Can't reference an undefined label '{0}'.",
    correctionMessage:
        "Try defining the label, or correcting the name to match an existing label.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a class that has at least one
  // `const` constructor also has a field marked both `late` and `final`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the class `A` has a
  // `const` constructor and the `final` field `f` is marked as `late`:
  //
  // ```dart
  // class A {
  //   [!late!] final int f;
  //
  //   const A();
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the field doesn't need to be marked `late`, then remove the `late`
  // modifier from the field:
  //
  // ```dart
  // class A {
  //   final int f = 0;
  //
  //   const A();
  // }
  // ```
  //
  // If the field must be marked `late`, then remove the `const` modifier from
  // the constructors:
  //
  // ```dart
  // class A {
  //   late final int f;
  //
  //   A();
  // }
  // ```
  static const CompileTimeErrorCode LATE_FINAL_FIELD_WITH_CONST_CONSTRUCTOR =
      CompileTimeErrorCode(
    'LATE_FINAL_FIELD_WITH_CONST_CONSTRUCTOR',
    "Can't have a late final field in a class with a generative const constructor.",
    correctionMessage:
        "Try removing the 'late' modifier, or don't declare 'const' constructors.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the analyzer can prove that a
  // local variable marked as both `late` and `final` was already assigned a
  // value at the point where another assignment occurs.
  //
  // Because `final` variables can only be assigned once, subsequent assignments
  // are guaranteed to fail, so they're flagged.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the `final` variable
  // `v` is assigned a value in two places:
  //
  // ```dart
  // int f() {
  //   late final int v;
  //   v = 0;
  //   [!v!] += 1;
  //   return v;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If you need to be able to reassign the variable, then remove the `final`
  // keyword:
  //
  // ```dart
  // int f() {
  //   late int v;
  //   v = 0;
  //   v += 1;
  //   return v;
  // }
  // ```
  //
  // If you don't need to reassign the variable, then remove all except the
  // first of the assignments:
  //
  // ```dart
  // int f() {
  //   late final int v;
  //   v = 0;
  //   return v;
  // }
  // ```
  static const CompileTimeErrorCode LATE_FINAL_LOCAL_ALREADY_ASSIGNED =
      CompileTimeErrorCode(
    'LATE_FINAL_LOCAL_ALREADY_ASSIGNED',
    "The late final local variable is already assigned.",
    correctionMessage:
        "Try removing the 'final' modifier, or don't reassign the value.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the actual type of the list element
   * 1: the expected type of the list element
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the type of an element in a list
  // literal isn't assignable to the element type of the list.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `2.5` is a double, and
  // the list can hold only integers:
  //
  // ```dart
  // List<int> x = [1, [!2.5!], 3];
  // ```
  //
  // #### Common fixes
  //
  // If you intended to add a different object to the list, then replace the
  // element with an expression that computes the intended object:
  //
  // ```dart
  // List<int> x = [1, 2, 3];
  // ```
  //
  // If the object shouldn't be in the list, then remove the element:
  //
  // ```dart
  // List<int> x = [1, 3];
  // ```
  //
  // If the object being computed is correct, then widen the element type of the
  // list to allow all of the different types of objects it needs to contain:
  //
  // ```dart
  // List<num> x = [1, 2.5, 3];
  // ```
  static const CompileTimeErrorCode LIST_ELEMENT_TYPE_NOT_ASSIGNABLE =
      CompileTimeErrorCode(
    'LIST_ELEMENT_TYPE_NOT_ASSIGNABLE',
    "The element type '{0}' can't be assigned to the list type '{1}'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the first positional parameter
  // of a function named `main` isn't a supertype of `List<String>`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `List<int>` isn't a
  // supertype of `List<String>`:
  //
  // ```dart
  // void main([!List<int>!] args) {}
  // ```
  //
  // #### Common fixes
  //
  // If the function is an entry point, then change the type of the first
  // positional parameter to be a supertype of `List<String>`:
  //
  // ```dart
  // void main(List<String> args) {}
  // ```
  //
  // If the function isn't an entry point, then change the name of the function:
  //
  // ```dart
  // void f(List<int> args) {}
  // ```
  static const CompileTimeErrorCode MAIN_FIRST_POSITIONAL_PARAMETER_TYPE =
      CompileTimeErrorCode(
    'MAIN_FIRST_POSITIONAL_PARAMETER_TYPE',
    "The type of the first positional parameter of the 'main' function must be a supertype of 'List<String>'.",
    correctionMessage: "Try changing the type of the parameter.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a function named `main` has one
  // or more required named parameters.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the function named
  // `main` has a required named parameter (`x`):
  //
  // ```dart
  // void [!main!]({required int x}) {}
  // ```
  //
  // #### Common fixes
  //
  // If the function is an entry point, then remove the `required` keyword:
  //
  // ```dart
  // void main({int? x}) {}
  // ```
  //
  // If the function isn't an entry point, then change the name of the function:
  //
  // ```dart
  // void f({required int x}) {}
  // ```
  static const CompileTimeErrorCode MAIN_HAS_REQUIRED_NAMED_PARAMETERS =
      CompileTimeErrorCode(
    'MAIN_HAS_REQUIRED_NAMED_PARAMETERS',
    "The function 'main' can't have any required named parameters.",
    correctionMessage:
        "Try using a different name for the function, or removing the 'required' modifier.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a function named `main` has more
  // than two required positional parameters.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the function `main` has
  // three required positional parameters:
  //
  // ```dart
  // void [!main!](List<String> args, int x, int y) {}
  // ```
  //
  // #### Common fixes
  //
  // If the function is an entry point and the extra parameters aren't used,
  // then remove them:
  //
  // ```dart
  // void main(List<String> args, int x) {}
  // ```
  //
  // If the function is an entry point, but the extra parameters used are for
  // when the function isn't being used as an entry point, then make the extra
  // parameters optional:
  //
  // ```dart
  // void main(List<String> args, int x, [int y = 0]) {}
  // ```
  //
  // If the function isn't an entry point, then change the name of the function:
  //
  // ```dart
  // void f(List<String> args, int x, int y) {}
  // ```
  static const CompileTimeErrorCode
      MAIN_HAS_TOO_MANY_REQUIRED_POSITIONAL_PARAMETERS = CompileTimeErrorCode(
    'MAIN_HAS_TOO_MANY_REQUIRED_POSITIONAL_PARAMETERS',
    "The function 'main' can't have more than two required positional parameters.",
    correctionMessage:
        "Try using a different name for the function, or removing extra parameters.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a library contains a declaration
  // of the name `main` that isn't the declaration of a top-level function.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the name `main` is
  // being used to declare a top-level variable:
  //
  // ```dart
  // var [!main!] = 3;
  // ```
  //
  // #### Common fixes
  //
  // Use a different name for the declaration:
  //
  // ```dart
  // var mainIndex = 3;
  // ```
  static const CompileTimeErrorCode MAIN_IS_NOT_FUNCTION = CompileTimeErrorCode(
    'MAIN_IS_NOT_FUNCTION',
    "The declaration named 'main' must be a function.",
    correctionMessage: "Try using a different name for this declaration.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a map entry (a key/value pair)
  // is found in a set literal.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the literal has a map
  // entry even though it's a set literal:
  //
  // ```dart
  // const collection = <String>{[!'a' : 'b'!]};
  // ```
  //
  // #### Common fixes
  //
  // If you intended for the collection to be a map, then change the code so
  // that it is a map. In the previous example, you could do this by adding
  // another type argument:
  //
  // ```dart
  // const collection = <String, String>{'a' : 'b'};
  // ```
  //
  // In other cases, you might need to change the explicit type from `Set` to
  // `Map`.
  //
  // If you intended for the collection to be a set, then remove the map entry,
  // possibly by replacing the colon with a comma if both values should be
  // included in the set:
  //
  // ```dart
  // const collection = <String>{'a', 'b'};
  // ```
  static const CompileTimeErrorCode MAP_ENTRY_NOT_IN_MAP = CompileTimeErrorCode(
    'MAP_ENTRY_NOT_IN_MAP',
    "Map entries can only be used in a map literal.",
    correctionMessage:
        "Try converting the collection to a map or removing the map entry.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the type of the expression being used as a key
   * 1: the type of keys declared for the map
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a key of a key-value pair in a
  // map literal has a type that isn't assignable to the key type of the map.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `2` is an `int`, but
  // the keys of the map are required to be `String`s:
  //
  // ```dart
  // var m = <String, String>{[!2!] : 'a'};
  // ```
  //
  // #### Common fixes
  //
  // If the type of the map is correct, then change the key to have the correct
  // type:
  //
  // ```dart
  // var m = <String, String>{'2' : 'a'};
  // ```
  //
  // If the type of the key is correct, then change the key type of the map:
  //
  // ```dart
  // var m = <int, String>{2 : 'a'};
  // ```
  static const CompileTimeErrorCode MAP_KEY_TYPE_NOT_ASSIGNABLE =
      CompileTimeErrorCode(
    'MAP_KEY_TYPE_NOT_ASSIGNABLE',
    "The element type '{0}' can't be assigned to the map key type '{1}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the type of the expression being used as a value
   * 1: the type of values declared for the map
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a value of a key-value pair in a
  // map literal has a type that isn't assignable to the value type of the
  // map.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `2` is an `int`, but/
  // the values of the map are required to be `String`s:
  //
  // ```dart
  // var m = <String, String>{'a' : [!2!]};
  // ```
  //
  // #### Common fixes
  //
  // If the type of the map is correct, then change the value to have the
  // correct type:
  //
  // ```dart
  // var m = <String, String>{'a' : '2'};
  // ```
  //
  // If the type of the value is correct, then change the value type of the map:
  //
  // ```dart
  // var m = <String, int>{'a' : 2};
  // ```
  static const CompileTimeErrorCode MAP_VALUE_TYPE_NOT_ASSIGNABLE =
      CompileTimeErrorCode(
    'MAP_VALUE_TYPE_NOT_ASSIGNABLE',
    "The element type '{0}' can't be assigned to the map value type '{1}'.",
    hasPublishedDocs: true,
  );

  /**
   * 12.1 Constants: A constant expression is ... a constant list literal.
   */
  static const CompileTimeErrorCode MISSING_CONST_IN_LIST_LITERAL =
      CompileTimeErrorCode(
    'MISSING_CONST_IN_LIST_LITERAL',
    "List literals must be prefixed with 'const' when used as a constant expression.",
    correctionMessage: "Try adding the keyword 'const' before the literal.",
  );

  /**
   * 12.1 Constants: A constant expression is ... a constant map literal.
   */
  static const CompileTimeErrorCode MISSING_CONST_IN_MAP_LITERAL =
      CompileTimeErrorCode(
    'MISSING_CONST_IN_MAP_LITERAL',
    "Map literals must be prefixed with 'const' when used as a constant expression.",
    correctionMessage: "Try adding the keyword 'const' before the literal.",
  );

  /**
   * 12.1 Constants: A constant expression is ... a constant set literal.
   */
  static const CompileTimeErrorCode MISSING_CONST_IN_SET_LITERAL =
      CompileTimeErrorCode(
    'MISSING_CONST_IN_SET_LITERAL',
    "Set literals must be prefixed with 'const' when used as a constant expression.",
    correctionMessage: "Try adding the keyword 'const' before the literal.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when either the Dart or Flutter SDK
  // isn’t installed correctly, and, as a result, one of the `dart:` libraries
  // can't be found.
  //
  // #### Common fixes
  //
  // Reinstall the Dart or Flutter SDK.
  static const CompileTimeErrorCode MISSING_DART_LIBRARY = CompileTimeErrorCode(
    'MISSING_DART_LIBRARY',
    "Required library '{0}' is missing.",
    correctionMessage: "Re-install the Dart or Flutter SDK.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an optional parameter, whether
  // positional or named, has a [potentially non-nullable][] type and doesn't
  // specify a default value. Optional parameters that have no explicit default
  // value have an implicit default value of `null`. If the type of the
  // parameter doesn't allow the parameter to have a value of `null`, then the
  // implicit default value isn't valid.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because `x` can't be `null`,
  // and no non-`null` default value is specified:
  //
  // ```dart
  // void f([int [!x!]]) {}
  // ```
  //
  // As does this:
  //
  // ```dart
  // void g({int [!x!]}) {}
  // ```
  //
  // #### Common fixes
  //
  // If you want to use `null` to indicate that no value was provided, then you
  // need to make the type nullable:
  //
  // ```dart
  // void f([int? x]) {}
  // void g({int? x}) {}
  // ```
  //
  // If the parameter can't be null, then either provide a default value:
  //
  // ```dart
  // void f([int x = 1]) {}
  // void g({int x = 2}) {}
  // ```
  //
  // or make the parameter a required parameter:
  //
  // ```dart
  // void f(int x) {}
  // void g({required int x}) {}
  // ```
  static const CompileTimeErrorCode MISSING_DEFAULT_VALUE_FOR_PARAMETER =
      CompileTimeErrorCode(
    'MISSING_DEFAULT_VALUE_FOR_PARAMETER',
    "The parameter '{0}' can't have a value of 'null' because of its type, but the implicit default value is 'null'.",
    correctionMessage:
        "Try adding either an explicit non-'null' default value or the 'required' modifier.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the parameter
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an invocation of a function is
  // missing a required named parameter.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the invocation of `f`
  // doesn't include a value for the required named parameter `end`:
  //
  // ```dart
  // void f(int start, {required int end}) {}
  // void g() {
  //   [!f!](3);
  // }
  // ```
  //
  // #### Common fixes
  //
  // Add a named argument corresponding to the missing required parameter:
  //
  // ```dart
  // void f(int start, {required int end}) {}
  // void g() {
  //   f(3, end: 5);
  // }
  // ```
  static const CompileTimeErrorCode MISSING_REQUIRED_ARGUMENT =
      CompileTimeErrorCode(
    'MISSING_REQUIRED_ARGUMENT',
    "The named parameter '{0}' is required, but there's no corresponding argument.",
    correctionMessage: "Try adding the required argument.",
    hasPublishedDocs: true,
  );

  /**
   * Technically this is [IMPLEMENTS_SUPER_CLASS].
   * See https://github.com/dart-lang/sdk/issues/25765#issuecomment-307422593
   *
   * Parameters:
   * 0: the name of the class that appears in both "extends" and "with" clauses
   */
  static const CompileTimeErrorCode MIXINS_SUPER_CLASS = CompileTimeErrorCode(
    'MIXINS_SUPER_CLASS',
    "'{0}' can't be used in both 'extends' and 'with' clauses.",
    correctionMessage: "Try removing one of the occurrences.",
  );

  /**
   * Parameters:
   * 0: the name of the super-invoked member
   * 1: the display name of the type of the super-invoked member in the mixin
   * 2: the display name of the type of the concrete member in the class
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a mixin that invokes a method
  // using `super` is used in a class where the concrete implementation of that
  // method has a different signature than the signature defined for that method
  // by the mixin's `on` type. The reason this is an error is because the
  // invocation in the mixin might invoke the method in a way that's
  // incompatible with the method that will actually be executed.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the class `C` uses the
  // mixin `M`, the mixin `M` invokes `foo` using `super`, and the abstract
  // version of `foo` declared in `I` (the mixin's `on` type) doesn't have the
  // same signature as the concrete version of `foo` declared in `A`:
  //
  // ```dart
  // class I {
  //   void foo([int? p]) {}
  // }
  //
  // class A {
  //   void foo(int p) {}
  // }
  //
  // abstract class B extends A implements I {
  //   @override
  //   void foo([int? p]);
  // }
  //
  // mixin M on I {
  //   void bar() {
  //     super.foo(42);
  //   }
  // }
  //
  // abstract class C extends B with [!M!] {}
  // ```
  //
  // #### Common fixes
  //
  // If the class doesn't need to use the mixin, then remove it from the `with`
  // clause:
  //
  // ```dart
  // class I {
  //   void foo([int? p]) {}
  // }
  //
  // class A {
  //   void foo(int? p) {}
  // }
  //
  // abstract class B extends A implements I {
  //   @override
  //   void foo([int? p]);
  // }
  //
  // mixin M on I {
  //   void bar() {
  //     super.foo(42);
  //   }
  // }
  //
  // abstract class C extends B {}
  // ```
  //
  // If the class needs to use the mixin, then ensure that there's a concrete
  // implementation of the method that conforms to the signature expected by the
  // mixin:
  //
  // ```dart
  // class I {
  //   void foo([int? p]) {}
  // }
  //
  // class A {
  //   void foo(int? p) {}
  // }
  //
  // abstract class B extends A implements I {
  //   @override
  //   void foo([int? p]) {
  //     super.foo(p);
  //   }
  // }
  //
  // mixin M on I {
  //   void bar() {
  //     super.foo(42);
  //   }
  // }
  //
  // abstract class C extends B with M {}
  // ```
  static const CompileTimeErrorCode
      MIXIN_APPLICATION_CONCRETE_SUPER_INVOKED_MEMBER_TYPE =
      CompileTimeErrorCode(
    'MIXIN_APPLICATION_CONCRETE_SUPER_INVOKED_MEMBER_TYPE',
    "The super-invoked member '{0}' has the type '{1}', and the concrete member in the class has the type '{2}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the display name of the mixin
   * 1: the display name of the superclass
   * 2: the display name of the type that is not implemented
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a mixin that has a superclass
  // constraint is used in a [mixin application][] with a superclass that
  // doesn't implement the required constraint.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the mixin `M` requires
  // that the class to which it's applied be a subclass of `A`, but `Object`
  // isn't a subclass of `A`:
  //
  // ```dart
  // class A {}
  //
  // mixin M on A {}
  //
  // class X = Object with [!M!];
  // ```
  //
  // #### Common fixes
  //
  // If you need to use the mixin, then change the superclass to be either the
  // same as or a subclass of the superclass constraint:
  //
  // ```dart
  // class A {}
  //
  // mixin M on A {}
  //
  // class X = A with M;
  // ```
  static const CompileTimeErrorCode
      MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE = CompileTimeErrorCode(
    'MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE',
    "'{0}' can't be mixed onto '{1}' because '{1}' doesn't implement '{2}'.",
    correctionMessage: "Try extending the class '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the display name of the member without a concrete implementation
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a [mixin application][] contains
  // an invocation of a member from its superclass, and there's no concrete
  // member of that name in the mixin application's superclass.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the mixin `M` contains
  // the invocation `super.m()`, and the class `A`, which is the superclass of
  // the [mixin application][] `A+M`, doesn't define a concrete implementation
  // of `m`:
  //
  // ```dart
  // abstract class A {
  //   void m();
  // }
  //
  // mixin M on A {
  //   void bar() {
  //     super.m();
  //   }
  // }
  //
  // abstract class B extends A with [!M!] {}
  // ```
  //
  // #### Common fixes
  //
  // If you intended to apply the mixin `M` to a different class, one that has a
  // concrete implementation of `m`, then change the superclass of `B` to that
  // class:
  //
  // ```dart
  // abstract class A {
  //   void m();
  // }
  //
  // mixin M on A {
  //   void bar() {
  //     super.m();
  //   }
  // }
  //
  // class C implements A {
  //   void m() {}
  // }
  //
  // abstract class B extends C with M {}
  // ```
  //
  // If you need to make `B` a subclass of `A`, then add a concrete
  // implementation of `m` in `A`:
  //
  // ```dart
  // abstract class A {
  //   void m() {}
  // }
  //
  // mixin M on A {
  //   void bar() {
  //     super.m();
  //   }
  // }
  //
  // abstract class B extends A with M {}
  // ```
  static const CompileTimeErrorCode
      MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER = CompileTimeErrorCode(
    'MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER',
    "The class doesn't have a concrete implementation of the super-invoked member '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the mixin that is invalid
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a class is used as a mixin and
  // the mixed-in class defines a constructor.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the class `A`, which
  // defines a constructor, is being used as a mixin:
  //
  // ```dart
  // class A {
  //   A();
  // }
  //
  // class B with [!A!] {}
  // ```
  //
  // #### Common fixes
  //
  // If it's possible to convert the class to a mixin, then do so:
  //
  // ```dart
  // mixin A {
  // }
  //
  // class B with A {}
  // ```
  //
  // If the class can't be a mixin and it's possible to remove the constructor,
  // then do so:
  //
  // ```dart
  // class A {
  // }
  //
  // class B with A {}
  // ```
  //
  // If the class can't be a mixin and you can't remove the constructor, then
  // try extending or implementing the class rather than mixing it in:
  //
  // ```dart
  // class A {
  //   A();
  // }
  //
  // class B extends A {}
  // ```
  static const CompileTimeErrorCode MIXIN_CLASS_DECLARES_CONSTRUCTOR =
      CompileTimeErrorCode(
    'MIXIN_CLASS_DECLARES_CONSTRUCTOR',
    "The class '{0}' can't be used as a mixin because it declares a constructor.",
    hasPublishedDocs: true,
  );

  /**
   * The <i>mixinMember</i> production allows the same instance or static
   * members that a class would allow, but no constructors (for now).
   */
  static const CompileTimeErrorCode MIXIN_DECLARES_CONSTRUCTOR =
      CompileTimeErrorCode(
    'MIXIN_DECLARES_CONSTRUCTOR',
    "Mixins can't declare constructors.",
  );

  /**
   * No parameters.
   */
  static const CompileTimeErrorCode MIXIN_DEFERRED_CLASS = CompileTimeErrorCode(
    'SUBTYPE_OF_DEFERRED_CLASS',
    "Classes can't mixin deferred classes.",
    correctionMessage: "Try changing the import to not be deferred.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_DEFERRED_CLASS',
  );

  static const CompileTimeErrorCode
      MIXIN_INFERENCE_INCONSISTENT_MATCHING_CLASSES = CompileTimeErrorCode(
    'MIXIN_INFERENCE_INCONSISTENT_MATCHING_CLASSES',
    "Type parameters couldn't be inferred for the mixin '{0}' because the base class implements the mixin's supertype constraint '{1}' in multiple conflicting ways",
  );

  static const CompileTimeErrorCode MIXIN_INFERENCE_NO_MATCHING_CLASS =
      CompileTimeErrorCode(
    'MIXIN_INFERENCE_NO_MATCHING_CLASS',
    "Type parameters couldn't be inferred for the mixin '{0}' because the base class doesn't implement the mixin's supertype constraint '{1}'",
  );

  static const CompileTimeErrorCode MIXIN_INFERENCE_NO_POSSIBLE_SUBSTITUTION =
      CompileTimeErrorCode(
    'MIXIN_INFERENCE_NO_POSSIBLE_SUBSTITUTION',
    "Type parameters couldn't be inferred for the mixin '{0}' because no type parameter substitution could be found matching the mixin's supertype constraints",
  );

  /**
   * Parameters:
   * 0: the name of the mixin that is invalid
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a class that extends a class
  // other than `Object` is used as a mixin.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the class `B`, which
  // extends `A`, is being used as a mixin by `C`:
  //
  // ```dart
  // class A {}
  //
  // class B extends A {}
  //
  // class C with [!B!] {}
  // ```
  //
  // #### Common fixes
  //
  // If the class being used as a mixin can be changed to extend `Object`, then
  // change it:
  //
  // ```dart
  // class A {}
  //
  // class B {}
  //
  // class C with B {}
  // ```
  //
  // If the class being used as a mixin can't be changed and the class that's
  // using it extends `Object`, then extend the class being used as a mixin:
  //
  // ```dart
  // class A {}
  //
  // class B extends A {}
  //
  // class C extends B {}
  // ```
  //
  // If the class doesn't extend `Object` or if you want to be able to mix in
  // the behavior from `B` in other places, then create a real mixin:
  //
  // ```dart
  // class A {}
  //
  // mixin M on A {}
  //
  // class B extends A with M {}
  //
  // class C extends A with M {}
  // ```
  static const CompileTimeErrorCode MIXIN_INHERITS_FROM_NOT_OBJECT =
      CompileTimeErrorCode(
    'MIXIN_INHERITS_FROM_NOT_OBJECT',
    "The class '{0}' can't be used as a mixin because it extends a class other than 'Object'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a mixin is instantiated.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the mixin `M` is being
  // instantiated:
  //
  // ```dart
  // mixin M {}
  //
  // var m = [!M!]();
  // ```
  //
  // #### Common fixes
  //
  // If you intend to use an instance of a class, then use the name of that
  // class in place of the name of the mixin.
  static const CompileTimeErrorCode MIXIN_INSTANTIATE = CompileTimeErrorCode(
    'MIXIN_INSTANTIATE',
    "Mixins can't be instantiated.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the disallowed type
   */
  static const CompileTimeErrorCode MIXIN_OF_DISALLOWED_CLASS =
      CompileTimeErrorCode(
    'SUBTYPE_OF_DISALLOWED_TYPE',
    "Classes can't mixin '{0}'.",
    correctionMessage:
        "Try specifying a different class or mixin, or remove the class or mixin from the list.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_OF_DISALLOWED_CLASS',
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a name in a `with` clause is
  // defined to be something other than a mixin or a class.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `F` is defined to be a
  // function type:
  //
  // ```dart
  // typedef F = int Function(String);
  //
  // class C with [!F!] {}
  // ```
  //
  // #### Common fixes
  //
  // Remove the invalid name from the list, possibly replacing it with the name
  // of the intended mixin or class:
  //
  // ```dart
  // typedef F = int Function(String);
  //
  // class C {}
  // ```
  static const CompileTimeErrorCode MIXIN_OF_NON_CLASS = CompileTimeErrorCode(
    'MIXIN_OF_NON_CLASS',
    "Classes can only mix in mixins and classes.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  static const CompileTimeErrorCode
      MIXIN_OF_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER = CompileTimeErrorCode(
    'SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER',
    "A type alias that expands to a type parameter can't be mixed in.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_OF_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
  );

  /**
   * No parameters.
   */
  static const CompileTimeErrorCode
      MIXIN_ON_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER = CompileTimeErrorCode(
    'SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER',
    "A type alias that expands to a type parameter can't be used as a superclass constraint.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_ON_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
  );

  /**
   * No parameters.
   */
  static const CompileTimeErrorCode
      MIXIN_SUPER_CLASS_CONSTRAINT_DEFERRED_CLASS = CompileTimeErrorCode(
    'MIXIN_SUPER_CLASS_CONSTRAINT_DEFERRED_CLASS',
    "Deferred classes can't be used as super-class constraints.",
    correctionMessage: "Try changing the import to not be deferred.",
  );

  /**
   * Parameters:
   * 0: the name of the disallowed type
   */
  static const CompileTimeErrorCode
      MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS = CompileTimeErrorCode(
    'SUBTYPE_OF_DISALLOWED_TYPE',
    "''{0}' can't be used as a superclass constraint.",
    correctionMessage:
        "Try specifying a different super-class constraint, or remove the 'on' clause.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS',
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a type following the `on`
  // keyword in a mixin declaration is neither a class nor a mixin.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `F` is neither a class
  // nor a mixin:
  //
  // ```dart
  // typedef F = void Function();
  //
  // mixin M on [!F!] {}
  // ```
  //
  // #### Common fixes
  //
  // If the type was intended to be a class but was mistyped, then replace the
  // name.
  //
  // Otherwise, remove the type from the `on` clause.
  static const CompileTimeErrorCode MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE =
      CompileTimeErrorCode(
    'MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE',
    "Only classes and mixins can be used as superclass constraints.",
    hasPublishedDocs: true,
  );

  /**
   * 9.1 Mixin Application: It is a compile-time error if <i>S</i> does not
   * denote a class available in the immediately enclosing scope.
   */
  static const CompileTimeErrorCode MIXIN_WITH_NON_CLASS_SUPERCLASS =
      CompileTimeErrorCode(
    'MIXIN_WITH_NON_CLASS_SUPERCLASS',
    "Mixin can only be applied to class.",
  );

  /**
   * 7.6.1 Generative Constructors: A generative constructor may be redirecting,
   * in which case its only action is to invoke another generative constructor.
   */
  static const CompileTimeErrorCode
      MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS = CompileTimeErrorCode(
    'MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS',
    "Constructors can have at most one 'this' redirection.",
    correctionMessage: "Try removing all but one of the redirections.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the initializer list of a
  // constructor contains more than one invocation of a constructor from the
  // superclass. The initializer list is required to have exactly one such call,
  // which can either be explicit or implicit.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the initializer list
  // for `B`’s constructor invokes both the constructor `one` and the
  // constructor `two` from the superclass `A`:
  //
  // ```dart
  // class A {
  //   int? x;
  //   String? s;
  //   A.one(this.x);
  //   A.two(this.s);
  // }
  //
  // class B extends A {
  //   B() : super.one(0), [!super.two('')!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // If one of the super constructors will initialize the instance fully, then
  // remove the other:
  //
  // ```dart
  // class A {
  //   int? x;
  //   String? s;
  //   A.one(this.x);
  //   A.two(this.s);
  // }
  //
  // class B extends A {
  //   B() : super.one(0);
  // }
  // ```
  //
  // If the initialization achieved by one of the super constructors can be
  // performed in the body of the constructor, then remove its super invocation
  // and perform the initialization in the body:
  //
  // ```dart
  // class A {
  //   int? x;
  //   String? s;
  //   A.one(this.x);
  //   A.two(this.s);
  // }
  //
  // class B extends A {
  //   B() : super.one(0) {
  //     s = '';
  //   }
  // }
  // ```
  //
  // If the initialization can only be performed in a constructor in the
  // superclass, then either add a new constructor or modify one of the existing
  // constructors so there's a constructor that allows all the required
  // initialization to occur in a single call:
  //
  // ```dart
  // class A {
  //   int? x;
  //   String? s;
  //   A.one(this.x);
  //   A.two(this.s);
  //   A.three(this.x, this.s);
  // }
  //
  // class B extends A {
  //   B() : super.three(0, '');
  // }
  // ```
  static const CompileTimeErrorCode MULTIPLE_SUPER_INITIALIZERS =
      CompileTimeErrorCode(
    'MULTIPLE_SUPER_INITIALIZERS',
    "A constructor can have at most one 'super' initializer.",
    correctionMessage: "Try removing all but one of the 'super' initializers.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the non-type element
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an instance creation using
  // either `new` or `const` specifies a name that isn't defined as a class.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `f` is a function
  // rather than a class:
  //
  // ```dart
  // int f() => 0;
  //
  // void g() {
  //   new [!f!]();
  // }
  // ```
  //
  // #### Common fixes
  //
  // If a class should be created, then replace the invalid name with the name
  // of a valid class:
  //
  // ```dart
  // int f() => 0;
  //
  // void g() {
  //   new Object();
  // }
  // ```
  //
  // If the name is the name of a function and you want that function to be
  // invoked, then remove the `new` or `const` keyword:
  //
  // ```dart
  // int f() => 0;
  //
  // void g() {
  //   f();
  // }
  // ```
  static const CompileTimeErrorCode NEW_WITH_NON_TYPE = CompileTimeErrorCode(
    'CREATION_WITH_NON_TYPE',
    "The name '{0}' isn't a class.",
    correctionMessage: "Try correcting the name to match an existing class.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
    uniqueName: 'NEW_WITH_NON_TYPE',
  );

  /**
   * 12.11.1 New: If <i>T</i> is a class or parameterized type accessible in the
   * current scope then:
   * 1. If <i>e</i> is of the form <i>new T.id(a<sub>1</sub>, &hellip;,
   *    a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;,
   *    x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a static warning if
   *    <i>T.id</i> is not the name of a constructor declared by the type
   *    <i>T</i>.
   * If <i>e</i> of the form <i>new T(a<sub>1</sub>, &hellip;, a<sub>n</sub>,
   * x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>:
   * a<sub>n+kM/sub>)</i> it is a static warning if the type <i>T</i> does not
   * declare a constructor with the same name as the declaration of <i>T</i>.
   */
  static const CompileTimeErrorCode NEW_WITH_UNDEFINED_CONSTRUCTOR =
      CompileTimeErrorCode(
    'NEW_WITH_UNDEFINED_CONSTRUCTOR',
    "The class '{0}' doesn't have a constructor named '{1}'.",
    correctionMessage:
        "Try invoking a different constructor, or define a constructor named '{1}'.",
  );

  /**
   * Parameters:
   * 0: the name of the class being instantiated
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an unnamed constructor is
  // invoked on a class that defines named constructors but the class doesn’t
  // have an unnamed constructor.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `A` doesn't define an
  // unnamed constructor:
  //
  // ```dart
  // class A {
  //   A.a();
  // }
  //
  // A f() => [!A!]();
  // ```
  //
  // #### Common fixes
  //
  // If one of the named constructors does what you need, then use it:
  //
  // ```dart
  // class A {
  //   A.a();
  // }
  //
  // A f() => A.a();
  // ```
  //
  // If none of the named constructors does what you need, and you're able to
  // add an unnamed constructor, then add the constructor:
  //
  // ```dart
  // class A {
  //   A();
  //   A.a();
  // }
  //
  // A f() => A();
  // ```
  static const CompileTimeErrorCode NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT =
      CompileTimeErrorCode(
    'NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT',
    "The class '{0}' doesn't have an unnamed constructor.",
    correctionMessage:
        "Try using one of the named constructors defined in '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the first member
   * 1: the name of the second member
   * 2: the name of the third member
   * 3: the name of the fourth member
   * 4: the number of additional missing members that aren't listed
   */
  static const CompileTimeErrorCode
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS =
      CompileTimeErrorCode(
    'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
    "Missing concrete implementations of '{0}', '{1}', '{2}', '{3}', and {4} more.",
    correctionMessage:
        "Try implementing the missing methods, or make the class abstract.",
    hasPublishedDocs: true,
    uniqueName: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS',
  );

  /**
   * Parameters:
   * 0: the name of the first member
   * 1: the name of the second member
   * 2: the name of the third member
   * 3: the name of the fourth member
   */
  static const CompileTimeErrorCode
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR = CompileTimeErrorCode(
    'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
    "Missing concrete implementations of '{0}', '{1}', '{2}', and '{3}'.",
    correctionMessage:
        "Try implementing the missing methods, or make the class abstract.",
    hasPublishedDocs: true,
    uniqueName: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR',
  );

  /**
   * Parameters:
   * 0: the name of the member
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a concrete class inherits one or
  // more abstract members, and doesn't provide or inherit an implementation for
  // at least one of those abstract members.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the class `B` doesn't
  // have a concrete implementation of `m`:
  //
  // ```dart
  // abstract class A {
  //   void m();
  // }
  //
  // class [!B!] extends A {}
  // ```
  //
  // #### Common fixes
  //
  // If the subclass can provide a concrete implementation for some or all of
  // the abstract inherited members, then add the concrete implementations:
  //
  // ```dart
  // abstract class A {
  //   void m();
  // }
  //
  // class B extends A {
  //   void m() {}
  // }
  // ```
  //
  // If there is a mixin that provides an implementation of the inherited
  // methods, then apply the mixin to the subclass:
  //
  // ```dart
  // abstract class A {
  //   void m();
  // }
  //
  // class B extends A with M {}
  //
  // mixin M {
  //   void m() {}
  // }
  // ```
  //
  // If the subclass can't provide a concrete implementation for all of the
  // abstract inherited members, then mark the subclass as being abstract:
  //
  // ```dart
  // abstract class A {
  //   void m();
  // }
  //
  // abstract class B extends A {}
  // ```
  static const CompileTimeErrorCode
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE = CompileTimeErrorCode(
    'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
    "Missing concrete implementation of '{0}'.",
    correctionMessage:
        "Try implementing the missing method, or make the class abstract.",
    hasPublishedDocs: true,
    uniqueName: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE',
  );

  /**
   * Parameters:
   * 0: the name of the first member
   * 1: the name of the second member
   * 2: the name of the third member
   */
  static const CompileTimeErrorCode
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE = CompileTimeErrorCode(
    'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
    "Missing concrete implementations of '{0}', '{1}', and '{2}'.",
    correctionMessage:
        "Try implementing the missing methods, or make the class abstract.",
    hasPublishedDocs: true,
    uniqueName: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE',
  );

  /**
   * Parameters:
   * 0: the name of the first member
   * 1: the name of the second member
   */
  static const CompileTimeErrorCode
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO = CompileTimeErrorCode(
    'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
    "Missing concrete implementations of '{0}' and '{1}'.",
    correctionMessage:
        "Try implementing the missing methods, or make the class abstract.",
    hasPublishedDocs: true,
    uniqueName: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO',
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a condition, such as an `if` or
  // `while` loop, doesn't have the static type `bool`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `x` has the static type
  // `int`:
  //
  // ```dart
  // void f(int x) {
  //   if ([!x!]) {
  //     // ...
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // Change the condition so that it produces a Boolean value:
  //
  // ```dart
  // void f(int x) {
  //   if (x == 0) {
  //     // ...
  //   }
  // }
  // ```
  static const CompileTimeErrorCode NON_BOOL_CONDITION = CompileTimeErrorCode(
    'NON_BOOL_CONDITION',
    "Conditions must have a static type of 'bool'.",
    correctionMessage: "Try changing the condition.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the first expression in an
  // assert has a type other than `bool`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the type of `p` is
  // `int`, but a `bool` is required:
  //
  // ```dart
  // void f(int p) {
  //   assert([!p!]);
  // }
  // ```
  //
  // #### Common fixes
  //
  // Change the expression so that it has the type `bool`:
  //
  // ```dart
  // void f(int p) {
  //   assert(p > 0);
  // }
  // ```
  static const CompileTimeErrorCode NON_BOOL_EXPRESSION = CompileTimeErrorCode(
    'NON_BOOL_EXPRESSION',
    "The expression in an assert must be of type 'bool'.",
    correctionMessage: "Try changing the expression.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the operand of the unary
  // negation operator (`!`) doesn't have the type `bool`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `x` is an `int` when it
  // must be a `bool`:
  //
  // ```dart
  // int x = 0;
  // bool y = ![!x!];
  // ```
  //
  // #### Common fixes
  //
  // Replace the operand with an expression that has the type `bool`:
  //
  // ```dart
  // int x = 0;
  // bool y = !(x > 0);
  // ```
  static const CompileTimeErrorCode NON_BOOL_NEGATION_EXPRESSION =
      CompileTimeErrorCode(
    'NON_BOOL_NEGATION_EXPRESSION',
    "A negation operand must have a static type of 'bool'.",
    correctionMessage: "Try changing the operand to the '!' operator.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the lexeme of the logical operator
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when one of the operands of either
  // the `&&` or `||` operator doesn't have the type `bool`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `a` isn't a Boolean
  // value:
  //
  // ```dart
  // int a = 3;
  // bool b = [!a!] || a > 1;
  // ```
  //
  // #### Common fixes
  //
  // Change the operand to a Boolean value:
  //
  // ```dart
  // int a = 3;
  // bool b = a == 0 || a > 1;
  // ```
  static const CompileTimeErrorCode NON_BOOL_OPERAND = CompileTimeErrorCode(
    'NON_BOOL_OPERAND',
    "The operands of the operator '{0}' must be assignable to 'bool'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an annotation is the invocation
  // of an existing constructor even though the invoked constructor isn't a
  // const constructor.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the constructor for `C`
  // isn't a const constructor:
  //
  // ```dart
  // [!@C()!]
  // void f() {
  // }
  //
  // class C {
  //   C();
  // }
  // ```
  //
  // #### Common fixes
  //
  // If it's valid for the class to have a const constructor, then create a
  // const constructor that can be used for the annotation:
  //
  // ```dart
  // @C()
  // void f() {
  // }
  //
  // class C {
  //   const C();
  // }
  // ```
  //
  // If it isn't valid for the class to have a const constructor, then either
  // remove the annotation or use a different class for the annotation.
  static const CompileTimeErrorCode NON_CONSTANT_ANNOTATION_CONSTRUCTOR =
      CompileTimeErrorCode(
    'NON_CONSTANT_ANNOTATION_CONSTRUCTOR',
    "Annotation creation can only call a const constructor.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the expression in a `case`
  // clause isn't a constant expression.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `j` isn't a constant:
  //
  // ```dart
  // void f(int i, int j) {
  //   switch (i) {
  //     case [!j!]:
  //       // ...
  //       break;
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // Either make the expression a constant expression, or rewrite the `switch`
  // statement as a sequence of `if` statements:
  //
  // ```dart
  // void f(int i, int j) {
  //   if (i == j) {
  //     // ...
  //   }
  // }
  // ```
  static const CompileTimeErrorCode NON_CONSTANT_CASE_EXPRESSION =
      CompileTimeErrorCode(
    'NON_CONSTANT_CASE_EXPRESSION',
    "Case expressions must be constant.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the expression in a case clause
  // references a constant from a library that is imported using a deferred
  // import. In order for switch statements to be compiled efficiently, the
  // constants referenced in case clauses need to be available at compile time,
  // and constants from deferred libraries aren't available at compile time.
  //
  // For more information, see the language tour's coverage of
  // [deferred loading](https://dart.dev/guides/language/language-tour#lazily-loading-a-library).
  //
  // #### Example
  //
  // Given a file (`a.dart`) that defines the constant `zero`:
  //
  // ```dart
  // %uri="lib/a.dart"
  // const zero = 0;
  // ```
  //
  // The following code produces this diagnostic because the library `a.dart` is
  // imported using a `deferred` import, and the constant `a.zero`, declared in
  // the imported library, is used in a case clause:
  //
  // ```dart
  // import 'a.dart' deferred as a;
  //
  // void f(int x) {
  //   switch (x) {
  //     case [!a.zero!]:
  //       // ...
  //       break;
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If you need to reference the constant from the imported library, then
  // remove the `deferred` keyword:
  //
  // ```dart
  // import 'a.dart' as a;
  //
  // void f(int x) {
  //   switch (x) {
  //     case a.zero:
  //       // ...
  //       break;
  //   }
  // }
  // ```
  //
  // If you need to reference the constant from the imported library and also
  // need the imported library to be deferred, then rewrite the switch statement
  // as a sequence of `if` statements:
  //
  // ```dart
  // import 'a.dart' deferred as a;
  //
  // void f(int x) {
  //   if (x == a.zero) {
  //     // ...
  //   }
  // }
  // ```
  //
  // If you don't need to reference the constant, then replace the case
  // expression:
  //
  // ```dart
  // void f(int x) {
  //   switch (x) {
  //     case 0:
  //       // ...
  //       break;
  //   }
  // }
  // ```
  static const CompileTimeErrorCode
      NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY = CompileTimeErrorCode(
    'NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as a case expression.",
    correctionMessage:
        "Try re-writing the switch as a series of if statements, or changing the import to not be deferred.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an optional parameter, either
  // named or positional, has a default value that isn't a compile-time
  // constant.
  //
  // #### Example
  //
  // The following code produces this diagnostic:
  //
  // ```dart
  // %language=2.9
  // var defaultValue = 3;
  //
  // void f([int value = [!defaultValue!]]) {}
  // ```
  //
  // #### Common fixes
  //
  // If the default value can be converted to be a constant, then convert it:
  //
  // ```dart
  // %language=2.9
  // const defaultValue = 3;
  //
  // void f([int value = defaultValue]) {}
  // ```
  //
  // If the default value needs to change over time, then apply the default
  // value inside the function:
  //
  // ```dart
  // %language=2.9
  // var defaultValue = 3;
  //
  // void f([int value]) {
  //   value ??= defaultValue;
  // }
  // ```
  static const CompileTimeErrorCode NON_CONSTANT_DEFAULT_VALUE =
      CompileTimeErrorCode(
    'NON_CONSTANT_DEFAULT_VALUE',
    "The default value of an optional parameter must be constant.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the default value of an optional
  // parameter uses a constant from a library imported using a deferred import.
  // Default values need to be available at compile time, and constants from
  // deferred libraries aren't available at compile time.
  //
  // For more information, see the language tour's coverage of
  // [deferred loading](https://dart.dev/guides/language/language-tour#lazily-loading-a-library).
  //
  // #### Example
  //
  // Given a file (`a.dart`) that defines the constant `zero`:
  //
  // ```dart
  // %uri="lib/a.dart"
  // const zero = 0;
  // ```
  //
  // The following code produces this diagnostic because `zero` is declared in a
  // library imported using a deferred import:
  //
  // ```dart
  // import 'a.dart' deferred as a;
  //
  // void f({int x = [!a.zero!]}) {}
  // ```
  //
  // #### Common fixes
  //
  // If you need to reference the constant from the imported library, then
  // remove the `deferred` keyword:
  //
  // ```dart
  // import 'a.dart' as a;
  //
  // void f({int x = a.zero}) {}
  // ```
  //
  // If you don't need to reference the constant, then replace the default
  // value:
  //
  // ```dart
  // void f({int x = 0}) {}
  // ```
  static const CompileTimeErrorCode
      NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY = CompileTimeErrorCode(
    'NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as a default parameter value.",
    correctionMessage:
        "Try leaving the default as null and initializing the parameter inside the function body.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an element in a constant list
  // literal isn't a constant value. The list literal can be constant either
  // explicitly (because it's prefixed by the `const` keyword) or implicitly
  // (because it appears in a [constant context][]).
  //
  // #### Example
  //
  // The following code produces this diagnostic because `x` isn't a constant,
  // even though it appears in an implicitly constant list literal:
  //
  // ```dart
  // var x = 2;
  // var y = const <int>[0, 1, [!x!]];
  // ```
  //
  // #### Common fixes
  //
  // If the list needs to be a constant list, then convert the element to be a
  // constant. In the example above, you might add the `const` keyword to the
  // declaration of `x`:
  //
  // ```dart
  // const x = 2;
  // var y = const <int>[0, 1, x];
  // ```
  //
  // If the expression can't be made a constant, then the list can't be a
  // constant either, so you must change the code so that the list isn't a
  // constant. In the example above this means removing the `const` keyword
  // before the list literal:
  //
  // ```dart
  // var x = 2;
  // var y = <int>[0, 1, x];
  // ```
  static const CompileTimeErrorCode NON_CONSTANT_LIST_ELEMENT =
      CompileTimeErrorCode(
    'NON_CONSTANT_LIST_ELEMENT',
    "The values in a const list literal must be constants.",
    correctionMessage:
        "Try removing the keyword 'const' from the list literal.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a collection literal that is
  // either explicitly (because it's prefixed by the `const` keyword) or
  // implicitly (because it appears in a [constant context][]) a constant
  // contains a value that is declared in a library that is imported using a
  // deferred import. Constants are evaluated at compile time, and values from
  // deferred libraries aren't available at compile time.
  //
  // For more information, see the language tour's coverage of
  // [deferred loading](https://dart.dev/guides/language/language-tour#lazily-loading-a-library).
  //
  // #### Example
  //
  // Given a file (`a.dart`) that defines the constant `zero`:
  //
  // ```dart
  // %uri="lib/a.dart"
  // const zero = 0;
  // ```
  //
  // The following code produces this diagnostic because the constant list
  // literal contains `a.zero`, which is imported using a `deferred` import:
  //
  // ```dart
  // import 'a.dart' deferred as a;
  //
  // var l = const [[!a.zero!]];
  // ```
  //
  // #### Common fixes
  //
  // If the collection literal isn't required to be constant, then remove the
  // `const` keyword:
  //
  // ```dart
  // import 'a.dart' deferred as a;
  //
  // var l = [a.zero];
  // ```
  //
  // If the collection is required to be constant and the imported constant must
  // be referenced, then remove the keyword `deferred` from the import:
  //
  // ```dart
  // import 'a.dart' as a;
  //
  // var l = const [a.zero];
  // ```
  //
  // If you don't need to reference the constant, then replace it with a
  // suitable value:
  //
  // ```dart
  // var l = const [0];
  // ```
  static const CompileTimeErrorCode
      NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY = CompileTimeErrorCode(
    'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as values in a 'const' list literal.",
    correctionMessage:
        "Try removing the keyword 'const' from the list literal or removing the keyword 'deferred' from the import.",
    hasPublishedDocs: true,
    uniqueName: 'NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY',
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an `if` element or a spread
  // element in a constant map isn't a constant element.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because it's attempting to
  // spread a non-constant map:
  //
  // ```dart
  // var notConst = <int, int>{};
  // var map = const <int, int>{...[!notConst!]};
  // ```
  //
  // Similarly, the following code produces this diagnostic because the
  // condition in the `if` element isn't a constant expression:
  //
  // ```dart
  // bool notConst = true;
  // var map = const <int, int>{if ([!notConst!]) 1 : 2};
  // ```
  //
  // #### Common fixes
  //
  // If the map needs to be a constant map, then make the elements constants.
  // In the spread example, you might do that by making the collection being
  // spread a constant:
  //
  // ```dart
  // const notConst = <int, int>{};
  // var map = const <int, int>{...notConst};
  // ```
  //
  // If the map doesn't need to be a constant map, then remove the `const`
  // keyword:
  //
  // ```dart
  // bool notConst = true;
  // var map = <int, int>{if (notConst) 1 : 2};
  // ```
  static const CompileTimeErrorCode NON_CONSTANT_MAP_ELEMENT =
      CompileTimeErrorCode(
    'NON_CONSTANT_MAP_ELEMENT',
    "The elements in a const map literal must be constant.",
    correctionMessage: "Try removing the keyword 'const' from the map literal.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a key in a constant map literal
  // isn't a constant value.
  //
  // #### Example
  //
  // The following code produces this diagnostic beause `a` isn't a constant:
  //
  // ```dart
  // var a = 'a';
  // var m = const {[!a!]: 0};
  // ```
  //
  // #### Common fixes
  //
  // If the map needs to be a constant map, then make the key a constant:
  //
  // ```dart
  // const a = 'a';
  // var m = const {a: 0};
  // ```
  //
  // If the map doesn't need to be a constant map, then remove the `const`
  // keyword:
  //
  // ```dart
  // var a = 'a';
  // var m = {a: 0};
  // ```
  static const CompileTimeErrorCode NON_CONSTANT_MAP_KEY = CompileTimeErrorCode(
    'NON_CONSTANT_MAP_KEY',
    "The keys in a const map literal must be constant.",
    correctionMessage: "Try removing the keyword 'const' from the map literal.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  static const CompileTimeErrorCode NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY =
      CompileTimeErrorCode(
    'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as keys in a 'const' map literal.",
    correctionMessage:
        "Try removing the keyword 'const' from the map literal or removing the keyword 'deferred' from the import.",
    hasPublishedDocs: true,
    uniqueName: 'NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY',
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a value in a constant map
  // literal isn't a constant value.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `a` isn't a constant:
  //
  // ```dart
  // var a = 'a';
  // var m = const {0: [!a!]};
  // ```
  //
  // #### Common fixes
  //
  // If the map needs to be a constant map, then make the key a constant:
  //
  // ```dart
  // const a = 'a';
  // var m = const {0: a};
  // ```
  //
  // If the map doesn't need to be a constant map, then remove the `const`
  // keyword:
  //
  // ```dart
  // var a = 'a';
  // var m = {0: a};
  // ```
  static const CompileTimeErrorCode NON_CONSTANT_MAP_VALUE =
      CompileTimeErrorCode(
    'NON_CONSTANT_MAP_VALUE',
    "The values in a const map literal must be constant.",
    correctionMessage: "Try removing the keyword 'const' from the map literal.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  static const CompileTimeErrorCode
      NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY = CompileTimeErrorCode(
    'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as values in a 'const' map literal.",
    correctionMessage:
        "Try removing the keyword 'const' from the map literal or removing the keyword 'deferred' from the import.",
    hasPublishedDocs: true,
    uniqueName: 'NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY',
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a constant set literal contains
  // an element that isn't a compile-time constant.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `i` isn't a constant:
  //
  // ```dart
  // var i = 0;
  //
  // var s = const {[!i!]};
  // ```
  //
  // #### Common fixes
  //
  // If the element can be changed to be a constant, then change it:
  //
  // ```dart
  // const i = 0;
  //
  // var s = const {i};
  // ```
  //
  // If the element can't be a constant, then remove the keyword `const`:
  //
  // ```dart
  // var i = 0;
  //
  // var s = {i};
  // ```
  static const CompileTimeErrorCode NON_CONSTANT_SET_ELEMENT =
      CompileTimeErrorCode(
    'NON_CONSTANT_SET_ELEMENT',
    "The values in a const set literal must be constants.",
    correctionMessage: "Try removing the keyword 'const' from the set literal.",
    hasPublishedDocs: true,
  );

  /**
   * 13.2 Expression Statements: It is a compile-time error if a non-constant
   * map literal that has no explicit type arguments appears in a place where a
   * statement is expected.
   */
  static const CompileTimeErrorCode NON_CONST_MAP_AS_EXPRESSION_STATEMENT =
      CompileTimeErrorCode(
    'NON_CONST_MAP_AS_EXPRESSION_STATEMENT',
    "A non-constant map or set literal without type arguments can't be used as an expression statement.",
  );

  /**
   * Parameters:
   * 0: the non-generative constructor
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the initializer list of a
  // constructor invokes a constructor from the superclass, and the invoked
  // constructor is a factory constructor. Only a generative constructor can be
  // invoked in the initializer list.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the invocation of the
  // constructor `super.one()` is invoking a factory constructor:
  //
  // ```dart
  // class A {
  //   factory A.one() = B;
  //   A.two();
  // }
  //
  // class B extends A {
  //   B() : [!super.one()!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // Change the super invocation to invoke a generative constructor:
  //
  // ```dart
  // class A {
  //   factory A.one() = B;
  //   A.two();
  // }
  //
  // class B extends A {
  //   B() : super.two();
  // }
  // ```
  //
  // If the generative constructor is the unnamed constructor, and if there are
  // no arguments being passed to it, then you can remove the super invocation.
  static const CompileTimeErrorCode NON_GENERATIVE_CONSTRUCTOR =
      CompileTimeErrorCode(
    'NON_GENERATIVE_CONSTRUCTOR',
    "The generative constructor '{0}' is expected, but a factory was found.",
    correctionMessage:
        "Try calling a different constructor of the superclass, or making the called constructor not be a factory constructor.",
    hasPublishedDocs: true,
  );

  /**
   * An error code for when a class has no explicit constructor, and therefore
   * a constructor is implicitly defined which uses a factory as a
   * superinitializer. See [NON_GENERATIVE_CONSTRUCTOR].
   *
   * Parameters:
   * 0: the name of the superclass
   * 1: the name of the current class
   * 2: the implicitly called factory constructor of the superclass
   */
  static const CompileTimeErrorCode NON_GENERATIVE_IMPLICIT_CONSTRUCTOR =
      CompileTimeErrorCode(
    'NON_GENERATIVE_IMPLICIT_CONSTRUCTOR',
    "The unnamed constructor of superclass '{0}' (called by the default constructor of '{1}') must be a generative constructor, but factory found.",
    correctionMessage:
        "Try adding an explicit constructor that has a different superinitializer or changing the superclass constructor '{2}' to not be a factory constructor.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the body of a factory
  // constructor is marked with `async`, `async*`, or `sync*`. All constructors,
  // including factory constructors, are required to return an instance of the
  // class in which they're declared, not a `Future`, `Stream`, or `Iterator`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the body of the factory
  // constructor is marked with `async`:
  //
  // ```dart
  // class C {
  //   factory C() [!async!] {
  //     return C._();
  //   }
  //   C._();
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the member must be declared as a factory constructor, then remove the
  // keyword appearing before the body:
  //
  // ```dart
  // class C {
  //   factory C() {
  //     return C._();
  //   }
  //   C._();
  // }
  // ```
  //
  // If the member must return something other than an instance of the enclosing
  // class, then make the member a static method:
  //
  // ```dart
  // class C {
  //   static Future<C> m() async {
  //     return C._();
  //   }
  //   C._();
  // }
  // ```
  static const CompileTimeErrorCode NON_SYNC_FACTORY = CompileTimeErrorCode(
    'NON_SYNC_FACTORY',
    "Factory bodies can't use 'async', 'async*', or 'sync*'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name appearing where a type is expected
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an identifier that isn't a type
  // is used as a type argument.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `x` is a variable, not
  // a type:
  //
  // ```dart
  // var x = 0;
  // List<[!x!]> xList = [];
  // ```
  //
  // #### Common fixes
  //
  // Change the type argument to be a type:
  //
  // ```dart
  // var x = 0;
  // List<int> xList = [];
  // ```
  static const CompileTimeErrorCode NON_TYPE_AS_TYPE_ARGUMENT =
      CompileTimeErrorCode(
    'NON_TYPE_AS_TYPE_ARGUMENT',
    "The name '{0}' isn't a type so it can't be used as a type argument.",
    correctionMessage:
        "Try correcting the name to an existing type, or defining a type named '{0}'.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
  );

  /**
   * Parameters:
   * 0: the name of the non-type element
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the identifier following the
  // `on` in a `catch` clause is defined to be something other than a type.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `f` is a function, not
  // a type:
  //
  // ```dart
  // %language=2.9
  // void f() {
  //   try {
  //     // ...
  //   } on [!f!] {
  //     // ...
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // Change the name to the type of object that should be caught:
  //
  // ```dart
  // %language=2.9
  // void f() {
  //   try {
  //     // ...
  //   } on FormatException {
  //     // ...
  //   }
  // }
  // ```
  static const CompileTimeErrorCode NON_TYPE_IN_CATCH_CLAUSE =
      CompileTimeErrorCode(
    'NON_TYPE_IN_CATCH_CLAUSE',
    "The name '{0}' isn't a type and can't be used in an on-catch clause.",
    correctionMessage: "Try correcting the name to match an existing class.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a declaration of the operator
  // `[]=` has a return type other than `void`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the declaration of the
  // operator `[]=` has a return type of `int`:
  //
  // ```dart
  // class C {
  //   [!int!] operator []=(int index, int value) => 0;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Change the return type to `void`:
  //
  // ```dart
  // class C {
  //   void operator []=(int index, int value) => 0;
  // }
  // ```
  static const CompileTimeErrorCode NON_VOID_RETURN_FOR_OPERATOR =
      CompileTimeErrorCode(
    'NON_VOID_RETURN_FOR_OPERATOR',
    "The return type of the operator []= must be 'void'.",
    correctionMessage: "Try changing the return type to 'void'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a setter is defined with a
  // return type other than `void`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the setter `p` has a
  // return type of `int`:
  //
  // ```dart
  // class C {
  //   [!int!] set p(int i) => 0;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Change the return type to `void` or omit the return type:
  //
  // ```dart
  // class C {
  //   set p(int i) => 0;
  // }
  // ```
  static const CompileTimeErrorCode NON_VOID_RETURN_FOR_SETTER =
      CompileTimeErrorCode(
    'NON_VOID_RETURN_FOR_SETTER',
    "The return type of the setter must be 'void' or absent.",
    correctionMessage:
        "Try removing the return type, or define a method rather than a setter.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the variable that is invalid
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a local variable is referenced
  // and has all these characteristics:
  // - Has a type that's [potentially non-nullable][].
  // - Doesn't have an initializer.
  // - Isn't marked as `late`.
  // - The analyzer can't prove that the local variable will be assigned before
  //   the reference based on the specification of [definite assignment][].
  //
  // #### Examples
  //
  // The following code produces this diagnostic because `x` can't have a value
  // of `null`, but is referenced before a value was assigned to it:
  //
  // ```dart
  // String f() {
  //   int x;
  //   return [!x!].toString();
  // }
  // ```
  //
  // The following code produces this diagnostic because the assignment to `x`
  // might not be executed, so it might have a value of `null`:
  //
  // ```dart
  // int g(bool b) {
  //   int x;
  //   if (b) {
  //     x = 1;
  //   }
  //   return [!x!] * 2;
  // }
  // ```
  //
  // The following code produces this diagnostic because the analyzer can't
  // prove, based on definite assignment analysis, that `x` won't be referenced
  // without having a value assigned to it:
  //
  // ```dart
  // int h(bool b) {
  //   int x;
  //   if (b) {
  //     x = 1;
  //   }
  //   if (b) {
  //     return [!x!] * 2;
  //   }
  //   return 0;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If `null` is a valid value, then make the variable nullable:
  //
  // ```dart
  // String f() {
  //   int? x;
  //   return x!.toString();
  // }
  // ```
  //
  // If `null` isn’t a valid value, and there's a reasonable default value, then
  // add an initializer:
  //
  // ```dart
  // int g(bool b) {
  //   int x = 2;
  //   if (b) {
  //     x = 1;
  //   }
  //   return x * 2;
  // }
  // ```
  //
  // Otherwise, ensure that a value was assigned on every possible code path
  // before the value is accessed:
  //
  // ```dart
  // int g(bool b) {
  //   int x;
  //   if (b) {
  //     x = 1;
  //   } else {
  //     x = 2;
  //   }
  //   return x * 2;
  // }
  // ```
  //
  // You can also mark the variable as `late`, which removes the diagnostic, but
  // if the variable isn't assigned a value before it's accessed, then it
  // results in an exception being thrown at runtime. This approach should only
  // be used if you're sure that the variable will always be assigned, even
  // though the analyzer can't prove it based on definite assignment analysis.
  //
  // ```dart
  // int h(bool b) {
  //   late int x;
  //   if (b) {
  //     x = 1;
  //   }
  //   if (b) {
  //     return x * 2;
  //   }
  //   return 0;
  // }
  // ```
  static const CompileTimeErrorCode
      NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE =
      CompileTimeErrorCode(
    'NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE',
    "The non-nullable local variable '{0}' must be assigned before it can be used.",
    correctionMessage:
        "Try giving it an initializer expression, or ensure that it's assigned on every execution path.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name that is not a type
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a name is used as a type but
  // declared to be something other than a type.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `f` is a function:
  //
  // ```dart
  // f() {}
  // g([!f!] v) {}
  // ```
  //
  // #### Common fixes
  //
  // Replace the name with the name of a type.
  static const CompileTimeErrorCode NOT_A_TYPE = CompileTimeErrorCode(
    'NOT_A_TYPE',
    "{0} isn't a type.",
    correctionMessage: "Try correcting the name to match an existing type.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the operator that is not a binary operator.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an operator that can only be
  // used as a unary operator is used as a binary operator.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the operator `~` can
  // only be used as a unary operator:
  //
  // ```dart
  // var a = 5 [!~!] 3;
  // ```
  //
  // #### Common fixes
  //
  // Replace the operator with the correct binary operator:
  //
  // ```dart
  // var a = 5 - 3;
  // ```
  static const CompileTimeErrorCode NOT_BINARY_OPERATOR = CompileTimeErrorCode(
    'NOT_BINARY_OPERATOR',
    "'{0}' isn't a binary operator.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the expected number of required arguments
   * 1: the actual number of positional arguments given
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a method or function invocation
  // has fewer positional arguments than the number of required positional
  // parameters.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `f` declares two
  // required parameters, but only one argument is provided:
  //
  // ```dart
  // void f(int a, int b) {}
  // void g() {
  //   f[!(0)!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // Add arguments corresponding to the remaining parameters:
  //
  // ```dart
  // void f(int a, int b) {}
  // void g() {
  //   f(0, 1);
  // }
  // ```
  static const CompileTimeErrorCode NOT_ENOUGH_POSITIONAL_ARGUMENTS =
      CompileTimeErrorCode(
    'NOT_ENOUGH_POSITIONAL_ARGUMENTS',
    "{0} positional argument(s) expected, but {1} found.",
    correctionMessage: "Try adding the missing arguments.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the field that is not initialized
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a field is declared and has all
  // these characteristics:
  // - Has a type that's [potentially non-nullable][]
  // - Doesn't have an initializer
  // - Isn't marked as `late`
  //
  // #### Examples
  //
  // The following code produces this diagnostic because `x` is implicitly
  // initialized to `null` when it isn't allowed to be `null`:
  //
  // ```dart
  // class C {
  //   int [!x!];
  // }
  // ```
  //
  // Similarly, the following code produces this diagnostic because `x` is
  // implicitly initialized to `null`, when it isn't allowed to be `null`, by
  // one of the constructors, even though it's initialized by other
  // constructors:
  //
  // ```dart
  // class C {
  //   int x;
  //
  //   C(this.x);
  //
  //   [!C!].n();
  // }
  // ```
  //
  // #### Common fixes
  //
  // If there's a reasonable default value for the field that’s the same for all
  // instances, then add an initializer expression:
  //
  // ```dart
  // class C {
  //   int x = 0;
  // }
  // ```
  //
  // If the value of the field should be provided when an instance is created,
  // then add a constructor that sets the value of the field or update an
  // existing constructor:
  //
  // ```dart
  // class C {
  //   int x;
  //
  //   C(this.x);
  // }
  // ```
  //
  // You can also mark the field as `late`, which removes the diagnostic, but if
  // the field isn't assigned a value before it's accessed, then it results in
  // an exception being thrown at runtime. This approach should only be used if
  // you're sure that the field will always be assigned before it's referenced.
  //
  // ```dart
  // class C {
  //   late int x;
  // }
  // ```
  static const CompileTimeErrorCode
      NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD = CompileTimeErrorCode(
    'NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD',
    "Non-nullable instance field '{0}' must be initialized.",
    correctionMessage:
        "Try adding an initializer expression, or a generative constructor that initializes it, or mark it 'late'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the field that is not initialized
   */
  static const CompileTimeErrorCode
      NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD_CONSTRUCTOR =
      CompileTimeErrorCode(
    'NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD',
    "Non-nullable instance field '{0}' must be initialized.",
    correctionMessage:
        "Try adding an initializer expression, or add a field initializer in this constructor, or mark it 'late'.",
    hasPublishedDocs: true,
    uniqueName: 'NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD_CONSTRUCTOR',
  );

  /**
   * Parameters:
   * 0: the name of the variable that is invalid
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a static field or top-level
  // variable has a type that's non-nullable and doesn't have an initializer.
  // Fields and variables that don't have an initializer are normally
  // initialized to `null`, but the type of the field or variable doesn't allow
  // it to be set to `null`, so an explicit initializer must be provided.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because the field `f` can't be
  // initialized to `null`:
  //
  // ```dart
  // class C {
  //   static int [!f!];
  // }
  // ```
  //
  // Similarly, the following code produces this diagnostic because the
  // top-level variable `v` can't be initialized to `null`:
  //
  // ```dart
  // int [!v!];
  // ```
  //
  // #### Common fixes
  //
  // If the field or variable can't be initialized to `null`, then add an
  // initializer that sets it to a non-null value:
  //
  // ```dart
  // class C {
  //   static int f = 0;
  // }
  // ```
  //
  // If the field or variable should be initialized to `null`, then change the
  // type to be nullable:
  //
  // ```dart
  // int? v;
  // ```
  //
  // If the field or variable can't be initialized in the declaration but will
  // always be initialized before it's referenced, then mark it as being `late`:
  //
  // ```dart
  // class C {
  //   static late int f;
  // }
  // ```
  static const CompileTimeErrorCode NOT_INITIALIZED_NON_NULLABLE_VARIABLE =
      CompileTimeErrorCode(
    'NOT_INITIALIZED_NON_NULLABLE_VARIABLE',
    "The non-nullable variable '{0}' must be initialized.",
    correctionMessage: "Try adding an initializer expression.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  static const CompileTimeErrorCode NOT_INSTANTIATED_BOUND =
      CompileTimeErrorCode(
    'NOT_INSTANTIATED_BOUND',
    "Type parameter bound types must be instantiated.",
    correctionMessage: "Try adding type arguments to the type parameter bound.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the static type of the
  // expression of a spread element that appears in either a list literal or a
  // set literal doesn't implement the type `Iterable`.
  //
  // #### Example
  //
  // The following code produces this diagnostic:
  //
  // ```dart
  // var m = <String, int>{'a': 0, 'b': 1};
  // var s = <String>{...[!m!]};
  // ```
  //
  // #### Common fixes
  //
  // The most common fix is to replace the expression with one that produces an
  // iterable object:
  //
  // ```dart
  // var m = <String, int>{'a': 0, 'b': 1};
  // var s = <String>{...m.keys};
  // ```
  static const CompileTimeErrorCode NOT_ITERABLE_SPREAD = CompileTimeErrorCode(
    'NOT_ITERABLE_SPREAD',
    "Spread elements in list or set literals must implement 'Iterable'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the static type of the
  // expression of a spread element that appears in a map literal doesn't
  // implement the type `Map`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `l` isn't a `Map`:
  //
  // ```dart
  // var l =  <String>['a', 'b'];
  // var m = <int, String>{...[!l!]};
  // ```
  //
  // #### Common fixes
  //
  // The most common fix is to replace the expression with one that produces a
  // map:
  //
  // ```dart
  // var l =  <String>['a', 'b'];
  // var m = <int, String>{...l.asMap()};
  // ```
  static const CompileTimeErrorCode NOT_MAP_SPREAD = CompileTimeErrorCode(
    'NOT_MAP_SPREAD',
    "Spread elements in map literals must implement 'Map'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  static const CompileTimeErrorCode NOT_NULL_AWARE_NULL_SPREAD =
      CompileTimeErrorCode(
    'NOT_NULL_AWARE_NULL_SPREAD',
    "The Null typed expression can't be used with a non-null-aware spread.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an annotation consists of a
  // single identifier, but that identifier is the name of a class rather than a
  // variable. To create an instance of the class, the identifier must be
  // followed by an argument list.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `C` is a class, and a
  // class can't be used as an annotation without invoking a `const` constructor
  // from the class:
  //
  // ```dart
  // class C {
  //   const C();
  // }
  //
  // [!@C!]
  // var x;
  // ```
  //
  // #### Common fixes
  //
  // Add the missing argument list:
  //
  // ```dart
  // class C {
  //   const C();
  // }
  //
  // @C()
  // var x;
  // ```
  static const CompileTimeErrorCode NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS =
      CompileTimeErrorCode(
    'NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS',
    "Annotation creation must have arguments.",
    correctionMessage: "Try adding an empty argument list.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the class where override error was detected
   * 1: the list of candidate signatures which cannot be combined
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when there is a method declaration
  // for which one or more types needs to be inferred, and those types can't be
  // inferred because none of the overridden methods has a function type that is
  // a supertype of all the other overridden methods, as specified by
  // [override inference][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the method `m` declared
  // in the class `C` is missing both the return type and the type of the
  // parameter `a`, and neither of the missing types can be inferred for it:
  //
  // ```dart
  // abstract class A {
  //   A m(String a);
  // }
  //
  // abstract class B {
  //   B m(int a);
  // }
  //
  // abstract class C implements A, B {
  //   [!m!](a);
  // }
  // ```
  //
  // In this example, override inference can't be performed because the
  // overridden methods are incompatible in these ways:
  // - Neither parameter type (`String` and `int`) is a supertype of the other.
  // - Neither return type is a subtype of the other.
  //
  // #### Common fixes
  //
  // If possible, add types to the method in the subclass that are consistent
  // with the types from all the overridden methods:
  //
  // ```dart
  // abstract class A {
  //   A m(String a);
  // }
  //
  // abstract class B {
  //   B m(int a);
  // }
  //
  // abstract class C implements A, B {
  //   C m(Object a);
  // }
  // ```
  static const CompileTimeErrorCode NO_COMBINED_SUPER_SIGNATURE =
      CompileTimeErrorCode(
    'NO_COMBINED_SUPER_SIGNATURE',
    "Can't infer missing types in '{0}' from overridden methods: {1}.",
    correctionMessage:
        "Try providing explicit types for this method's parameters and return type.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the superclass that does not define an implicitly invoked
   *    constructor
   */
  static const CompileTimeErrorCode NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT =
      CompileTimeErrorCode(
    'NO_DEFAULT_SUPER_CONSTRUCTOR',
    "The superclass '{0}' doesn't have a zero argument constructor.",
    correctionMessage:
        "Try declaring a zero argument constructor in '{0}', or explicitly invoking a different constructor in '{0}'.",
    uniqueName: 'NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT',
  );

  /**
   * Parameters:
   * 0: the name of the superclass that does not define an implicitly invoked
   *    constructor
   * 1: the name of the subclass that does not contain any explicit constructors
   */
  static const CompileTimeErrorCode NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT =
      CompileTimeErrorCode(
    'NO_DEFAULT_SUPER_CONSTRUCTOR',
    "The superclass '{0}' doesn't have a zero argument constructor.",
    correctionMessage:
        "Try declaring a zero argument constructor in '{0}', or declaring a constructor in {1} that explicitly invokes a constructor in '{0}'.",
    uniqueName: 'NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT',
  );

  /**
   * User friendly specialized error for [NON_GENERATIVE_CONSTRUCTOR]. This
   * handles the case of `class E extends Exception` which will never work
   * because [Exception] has no generative constructors.
   *
   * Parameters:
   * 0: the name of the subclass
   * 1: the name of the superclass
   */
  static const CompileTimeErrorCode NO_GENERATIVE_CONSTRUCTORS_IN_SUPERCLASS =
      CompileTimeErrorCode(
    'NO_GENERATIVE_CONSTRUCTORS_IN_SUPERCLASS',
    "The class '{0}' cannot extend '{1}' because '{1}' only has factory constructors (no generative constructors), and '{0}' has at least one generative constructor.",
    correctionMessage:
        "Try implementing the class instead, adding a generative (not factory) constructor to the superclass {0}, or a factory constructor to the subclass.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a class declaration uses an
  // `extends` clause to specify a superclass, and the superclass is followed by
  // a `?`.
  //
  // It isn't valid to specify a nullable superclass because doing so would have
  // no meaning; it wouldn't change either the interface or implementation being
  // inherited by the class containing the `extends` clause.
  //
  // Note, however, that it _is_ valid to use a nullable type as a type argument
  // to the superclass, such as `class A extends B<C?> {}`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `A?` is a nullable
  // type, and nullable types can't be used in an `extends` clause:
  //
  // ```dart
  // class A {}
  // class B extends [!A?!] {}
  // ```
  //
  // #### Common fixes
  //
  // Remove the question mark from the type:
  //
  // ```dart
  // class A {}
  // class B extends A {}
  // ```
  static const CompileTimeErrorCode NULLABLE_TYPE_IN_EXTENDS_CLAUSE =
      CompileTimeErrorCode(
    'NULLABLE_TYPE_IN_EXTENDS_CLAUSE',
    "A class can't extend a nullable type.",
    correctionMessage: "Try removing the question mark.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a class or mixin declaration has
  // an `implements` clause, and an interface is followed by a `?`.
  //
  // It isn't valid to specify a nullable interface because doing so would have
  // no meaning; it wouldn't change the interface being inherited by the class
  // containing the `implements` clause.
  //
  // Note, however, that it _is_ valid to use a nullable type as a type argument
  // to the interface, such as `class A implements B<C?> {}`.
  //
  //
  // #### Example
  //
  // The following code produces this diagnostic because `A?` is a nullable
  // type, and nullable types can't be used in an `implements` clause:
  //
  // ```dart
  // class A {}
  // class B implements [!A?!] {}
  // ```
  //
  // #### Common fixes
  //
  // Remove the question mark from the type:
  //
  // ```dart
  // class A {}
  // class B implements A {}
  // ```
  static const CompileTimeErrorCode NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE =
      CompileTimeErrorCode(
    'NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE',
    "A class or mixin can't implement a nullable type.",
    correctionMessage: "Try removing the question mark.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a mixin declaration uses an `on`
  // clause to specify a superclass constraint, and the class that's specified
  // is followed by a `?`.
  //
  // It isn't valid to specify a nullable superclass constraint because doing so
  // would have no meaning; it wouldn't change the interface being depended on
  // by the mixin containing the `on` clause.
  //
  // Note, however, that it _is_ valid to use a nullable type as a type argument
  // to the superclass constraint, such as `mixin A on B<C?> {}`.
  //
  //
  // #### Example
  //
  // The following code produces this diagnostic because `A?` is a nullable type
  // and nullable types can't be used in an `on` clause:
  //
  // ```dart
  // class C {}
  // mixin M on [!C?!] {}
  // ```
  //
  // #### Common fixes
  //
  // Remove the question mark from the type:
  //
  // ```dart
  // class C {}
  // mixin M on C {}
  // ```
  static const CompileTimeErrorCode NULLABLE_TYPE_IN_ON_CLAUSE =
      CompileTimeErrorCode(
    'NULLABLE_TYPE_IN_ON_CLAUSE',
    "A mixin can't have a nullable type as a superclass constraint.",
    correctionMessage: "Try removing the question mark.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a class or mixin declaration has
  // a `with` clause, and a mixin is followed by a `?`.
  //
  // It isn't valid to specify a nullable mixin because doing so would have no
  // meaning; it wouldn't change either the interface or implementation being
  // inherited by the class containing the `with` clause.
  //
  // Note, however, that it _is_ valid to use a nullable type as a type argument
  // to the mixin, such as `class A with B<C?> {}`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `A?` is a nullable
  // type, and nullable types can't be used in a `with` clause:
  //
  // ```dart
  // mixin M {}
  // class C with [!M?!] {}
  // ```
  //
  // #### Common fixes
  //
  // Remove the question mark from the type:
  //
  // ```dart
  // mixin M {}
  // class C with M {}
  // ```
  static const CompileTimeErrorCode NULLABLE_TYPE_IN_WITH_CLAUSE =
      CompileTimeErrorCode(
    'NULLABLE_TYPE_IN_WITH_CLAUSE',
    "A class or mixin can't mix in a nullable type.",
    correctionMessage: "Try removing the question mark.",
    hasPublishedDocs: true,
  );

  /**
   * 7.9 Superclasses: It is a compile-time error to specify an extends clause
   * for class Object.
   */
  static const CompileTimeErrorCode OBJECT_CANNOT_EXTEND_ANOTHER_CLASS =
      CompileTimeErrorCode(
    'OBJECT_CANNOT_EXTEND_ANOTHER_CLASS',
    "The class 'Object' can't extend any other class.",
  );

  /**
   * Parameters:
   * 0: the name of the interface that is implemented more than once
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the same type is listed in the
  // superclass constraints of a mixin multiple times.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `A` is included twice
  // in the superclass constraints for `M`:
  //
  // ```dart
  // mixin M on A, [!A!] {
  // }
  //
  // class A {}
  // class B {}
  // ```
  //
  // #### Common fixes
  //
  // If a different type should be included in the superclass constraints, then
  // replace one of the occurrences with the other type:
  //
  // ```dart
  // mixin M on A, B {
  // }
  //
  // class A {}
  // class B {}
  // ```
  //
  // If no other type was intended, then remove the repeated type name:
  //
  // ```dart
  // mixin M on A {
  // }
  //
  // class A {}
  // class B {}
  // ```
  static const CompileTimeErrorCode ON_REPEATED = CompileTimeErrorCode(
    'ON_REPEATED',
    "The type '{0}' can be included in the superclass constraints only once.",
    correctionMessage:
        "Try removing all except one occurrence of the type name.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when one or more of the parameters in
  // an operator declaration are optional.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the parameter `other`
  // is an optional parameter:
  //
  // ```dart
  // class C {
  //   C operator +([[!C? other!]]) => this;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Make all of the parameters be required parameters:
  //
  // ```dart
  // class C {
  //   C operator +(C other) => this;
  // }
  // ```
  static const CompileTimeErrorCode OPTIONAL_PARAMETER_IN_OPERATOR =
      CompileTimeErrorCode(
    'OPTIONAL_PARAMETER_IN_OPERATOR',
    "Optional parameters aren't allowed when defining an operator.",
    correctionMessage: "Try removing the optional parameters.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of expected library name
   * 1: the non-matching actual library name from the "part of" declaration
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a library attempts to include a
  // file as a part of itself when the other file is a part of a different
  // library.
  //
  // #### Example
  //
  // Given a file named `part.dart` containing
  //
  // ```dart
  // %uri="package:a/part.dart"
  // part of 'library.dart';
  // ```
  //
  // The following code, in any file other than `library.dart`, produces this
  // diagnostic because it attempts to include `part.dart` as a part of itself
  // when `part.dart` is a part of a different library:
  //
  // ```dart
  // part [!'package:a/part.dart'!];
  // ```
  //
  // #### Common fixes
  //
  // If the library should be using a different file as a part, then change the
  // URI in the part directive to be the URI of the other file.
  //
  // If the part file should be a part of this library, then update the URI (or
  // library name) in the part-of directive to be the URI (or name) of the
  // correct library.
  static const CompileTimeErrorCode PART_OF_DIFFERENT_LIBRARY =
      CompileTimeErrorCode(
    'PART_OF_DIFFERENT_LIBRARY',
    "Expected this library to be part of '{0}', not '{1}'.",
    correctionMessage:
        "Try including a different part, or changing the name of the library in the part's part-of directive.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the uri pointing to a non-library declaration
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a part directive is found and
  // the referenced file doesn't have a part-of directive.
  //
  // #### Example
  //
  // Given a file (`a.dart`) containing:
  //
  // ```dart
  // %uri="lib/a.dart"
  // class A {}
  // ```
  //
  // The following code produces this diagnostic because `a.dart` doesn't
  // contain a part-of directive:
  //
  // ```dart
  // part [!'a.dart'!];
  // ```
  //
  // #### Common fixes
  //
  // If the referenced file is intended to be a part of another library, then
  // add a part-of directive to the file:
  //
  // ```dart
  // part of 'test.dart';
  //
  // class A {}
  // ```
  //
  // If the referenced file is intended to be a library, then replace the part
  // directive with an import directive:
  //
  // ```dart
  // import 'a.dart';
  // ```
  static const CompileTimeErrorCode PART_OF_NON_PART = CompileTimeErrorCode(
    'PART_OF_NON_PART',
    "The included part '{0}' must have a part-of directive.",
    correctionMessage: "Try adding a part-of directive to '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the URI of the expected library
   * 1: the non-matching actual library name from the "part of" declaration
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a library that doesn't have a
  // `library` directive (and hence has no name) contains a `part` directive and
  // the `part of` directive in the part file uses a name to specify the library
  // that it's a part of.
  //
  // #### Example
  //
  // Given a part file named `part_file.dart` containing the following code:
  //
  // ```dart
  // %uri="lib/part_file.dart"
  // part of lib;
  // ```
  //
  // The following code produces this diagnostic because the library including
  // the part file doesn't have a name even though the part file uses a name to
  // specify which library it's a part of:
  //
  // ```dart
  // part [!'part_file.dart'!];
  // ```
  //
  // #### Common fixes
  //
  // Change the `part of` directive in the part file to specify its library by
  // URI:
  //
  // ```dart
  // part of 'test.dart';
  // ```
  static const CompileTimeErrorCode PART_OF_UNNAMED_LIBRARY =
      CompileTimeErrorCode(
    'PART_OF_UNNAMED_LIBRARY',
    "The library is unnamed. A URI is expected, not a library name '{0}', in the part-of directive.",
    correctionMessage:
        "Try changing the part-of directive to a URI, or try including a different part.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the prefix
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a name is used as both an import
  // prefix and the name of a top-level declaration in the same library.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `f` is used as both an
  // import prefix and the name of a function:
  //
  // ```dart
  // import 'dart:math' as f;
  //
  // int [!f!]() => f.min(0, 1);
  // ```
  //
  // #### Common fixes
  //
  // If you want to use the name for the import prefix, then rename the
  // top-level declaration:
  //
  // ```dart
  // import 'dart:math' as f;
  //
  // int g() => f.min(0, 1);
  // ```
  //
  // If you want to use the name for the top-level declaration, then rename the
  // import prefix:
  //
  // ```dart
  // import 'dart:math' as math;
  //
  // int f() => math.min(0, 1);
  // ```
  static const CompileTimeErrorCode PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER =
      CompileTimeErrorCode(
    'PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER',
    "The name '{0}' is already used as an import prefix and can't be used to name a top-level element.",
    correctionMessage:
        "Try renaming either the top-level element or the prefix.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the prefix
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an import prefix is used by
  // itself, without accessing any of the names declared in the libraries
  // associated with the prefix. Prefixes aren't variables, and therefore can't
  // be used as a value.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the prefix `math` is
  // being used as if it were a variable:
  //
  // ```dart
  // import 'dart:math' as math;
  //
  // void f() {
  //   print([!math!]);
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the code is incomplete, then reference something in one of the libraries
  // associated with the prefix:
  //
  // ```dart
  // import 'dart:math' as math;
  //
  // void f() {
  //   print(math.pi);
  // }
  // ```
  //
  // If the name is wrong, then correct the name.
  static const CompileTimeErrorCode PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT =
      CompileTimeErrorCode(
    'PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT',
    "The name '{0}' refers to an import prefix, so it must be followed by '.'.",
    correctionMessage:
        "Try correcting the name to refer to something other than a prefix, or renaming the prefix.",
    hasPublishedDocs: true,
  );

  /**
   * From the `Static Types` section of the spec:
   *
   *     A type T is malformed if:
   *     - T has the form id or the form prefix.id, and in the enclosing lexical
   *       scope, the name id (respectively prefix.id) does not denote a type.
   *
   * In particular, this means that if an import prefix is shadowed by a local
   * declaration, it is an error to try to use it as a prefix for a type name.
   */
  static const CompileTimeErrorCode PREFIX_SHADOWED_BY_LOCAL_DECLARATION =
      CompileTimeErrorCode(
    'PREFIX_SHADOWED_BY_LOCAL_DECLARATION',
    "The prefix '{0}' can't be used here because it is shadowed by a local declaration.",
    correctionMessage:
        "Try renaming either the prefix or the local declaration.",
  );

  /**
   * Parameters:
   * 0: the private name that collides
   * 1: the name of the first mixin
   * 2: the name of the second mixin
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when two mixins that define the same
  // private member are used together in a single class in a library other than
  // the one that defines the mixins.
  //
  // #### Example
  //
  // Given a file named `a.dart` containing the following code:
  //
  // ```dart
  // %uri="lib/a.dart"
  // class A {
  //   void _foo() {}
  // }
  //
  // class B {
  //   void _foo() {}
  // }
  // ```
  //
  // The following code produces this diagnostic because the classes `A` and `B`
  // both define the method `_foo`:
  //
  // ```dart
  // import 'a.dart';
  //
  // class C extends Object with A, [!B!] {}
  // ```
  //
  // #### Common fixes
  //
  // If you don't need both of the mixins, then remove one of them from the
  // `with` clause:
  //
  // ```dart
  // import 'a.dart';
  //
  // class C extends Object with A, [!B!] {}
  // ```
  //
  // If you need both of the mixins, then rename the conflicting member in one
  // of the two mixins.
  static const CompileTimeErrorCode PRIVATE_COLLISION_IN_MIXIN_APPLICATION =
      CompileTimeErrorCode(
    'PRIVATE_COLLISION_IN_MIXIN_APPLICATION',
    "The private name '{0}', defined by '{1}', conflicts with the same name defined by '{2}'.",
    correctionMessage: "Try removing '{1}' from the 'with' clause.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the name of a named parameter
  // starts with an underscore.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the named parameter
  // `_x` starts with an underscore:
  //
  // ```dart
  // class C {
  //   void m({int [!_x!] = 0}) {}
  // }
  // ```
  //
  // #### Common fixes
  //
  // Rename the parameter so that it doesn't start with an underscore:
  //
  // ```dart
  // class C {
  //   void m({int x = 0}) {}
  // }
  // ```
  static const CompileTimeErrorCode PRIVATE_OPTIONAL_PARAMETER =
      CompileTimeErrorCode(
    'PRIVATE_OPTIONAL_PARAMETER',
    "Named parameters can't start with an underscore.",
    hasPublishedDocs: true,
  );

  static const CompileTimeErrorCode PRIVATE_SETTER = CompileTimeErrorCode(
    'PRIVATE_SETTER',
    "The setter '{0}' is private and can't be accessed outside of the library that declares it.",
    correctionMessage: "Try making it public.",
  );

  static const CompileTimeErrorCode READ_POTENTIALLY_UNASSIGNED_FINAL =
      CompileTimeErrorCode(
    'READ_POTENTIALLY_UNASSIGNED_FINAL',
    "The final variable '{0}' can't be read because it is potentially unassigned at this point.",
    correctionMessage:
        "Ensure that it is assigned on necessary execution paths.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the value of a compile-time
  // constant is defined in terms of itself, either directly or indirectly,
  // creating an infinite loop.
  //
  // #### Example
  //
  // The following code produces this diagnostic twice because both of the
  // constants are defined in terms of the other:
  //
  // ```dart
  // const [!secondsPerHour!] = minutesPerHour * 60;
  // const [!minutesPerHour!] = secondsPerHour / 60;
  // ```
  //
  // #### Common fixes
  //
  // Break the cycle by finding an alternative way of defining at least one of
  // the constants:
  //
  // ```dart
  // const secondsPerHour = minutesPerHour * 60;
  // const minutesPerHour = 60;
  // ```
  static const CompileTimeErrorCode RECURSIVE_COMPILE_TIME_CONSTANT =
      CompileTimeErrorCode(
    'RECURSIVE_COMPILE_TIME_CONSTANT',
    "The compile-time constant expression depends on itself.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   *
   * TODO(scheglov) review this later, there are no explicit "it is a
   * compile-time error" in specification. But it was added to the co19 and
   * there is same error for factories.
   *
   * https://code.google.com/p/dart/issues/detail?id=954
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a constructor redirects to
  // itself, either directly or indirectly, creating an infinite loop.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because the generative
  // constructors `C.a` and `C.b` each redirect to the other:
  //
  // ```dart
  // class C {
  //   C.a() : [!this.b()!];
  //   C.b() : [!this.a()!];
  // }
  // ```
  //
  // The following code produces this diagnostic because the factory
  // constructors `A` and `B` each redirect to the other:
  //
  // ```dart
  // abstract class A {
  //   factory A() = [!B!];
  // }
  // class B implements A {
  //   factory B() = [!A!];
  //   B.named();
  // }
  // ```
  //
  // #### Common fixes
  //
  // In the case of generative constructors, break the cycle by finding defining
  // at least one of the constructors to not redirect to another constructor:
  //
  // ```dart
  // class C {
  //   C.a() : this.b();
  //   C.b();
  // }
  // ```
  //
  // In the case of factory constructors, break the cycle by defining at least
  // one of the factory constructors to do one of the following:
  //
  // - Redirect to a generative constructor:
  //
  // ```dart
  // abstract class A {
  //   factory A() = B;
  // }
  // class B implements A {
  //   factory B() = B.named;
  //   B.named();
  // }
  // ```
  //
  // - Not redirect to another constructor:
  //
  // ```dart
  // abstract class A {
  //   factory A() = B;
  // }
  // class B implements A {
  //   factory B() {
  //     return B.named();
  //   }
  //
  //   B.named();
  // }
  // ```
  //
  // - Not be a factory constructor:
  //
  // ```dart
  // abstract class A {
  //   factory A() = B;
  // }
  // class B implements A {
  //   B();
  //   B.named();
  // }
  // ```
  static const CompileTimeErrorCode RECURSIVE_CONSTRUCTOR_REDIRECT =
      CompileTimeErrorCode(
    'RECURSIVE_CONSTRUCTOR_REDIRECT',
    "Constructors can't redirect to themselves either directly or indirectly.",
    correctionMessage:
        "Try changing one of the constructors in the loop to not redirect.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  static const CompileTimeErrorCode RECURSIVE_FACTORY_REDIRECT =
      CompileTimeErrorCode(
    'RECURSIVE_CONSTRUCTOR_REDIRECT',
    "Constructors can't redirect to themselves either directly or indirectly.",
    correctionMessage:
        "Try changing one of the constructors in the loop to not redirect.",
    hasPublishedDocs: true,
    uniqueName: 'RECURSIVE_FACTORY_REDIRECT',
  );

  /**
   * Parameters:
   * 0: the name of the class that implements itself recursively
   * 1: a string representation of the implements loop
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when there's a circularity in the
  // type hierarchy. This happens when a type, either directly or indirectly,
  // is declared to be a subtype of itself.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the class `A` is
  // declared to be a subtype of `B`, and `B` is a subtype of `A`:
  //
  // ```dart
  // class [!A!] extends B {}
  // class B implements A {}
  // ```
  //
  // #### Common fixes
  //
  // Change the type hierarchy so that there's no circularity.
  static const CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE =
      CompileTimeErrorCode(
    'RECURSIVE_INTERFACE_INHERITANCE',
    "'{0}' can't be a superinterface of itself: {1}.",
    hasPublishedDocs: true,
  );

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the interface of a
   * class <i>C</i> is a superinterface of itself.
   *
   * 8.1 Superinterfaces: It is a compile-time error if an interface is a
   * superinterface of itself.
   *
   * 7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a
   * superclass of itself.
   *
   * Parameters:
   * 0: the name of the class that implements itself recursively
   */
  static const CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE_EXTENDS =
      CompileTimeErrorCode(
    'RECURSIVE_INTERFACE_INHERITANCE',
    "'{0}' can't extend itself.",
    hasPublishedDocs: true,
    uniqueName: 'RECURSIVE_INTERFACE_INHERITANCE_EXTENDS',
  );

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the interface of a
   * class <i>C</i> is a superinterface of itself.
   *
   * 8.1 Superinterfaces: It is a compile-time error if an interface is a
   * superinterface of itself.
   *
   * 7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a
   * superclass of itself.
   *
   * Parameters:
   * 0: the name of the class that implements itself recursively
   */
  static const CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS =
      CompileTimeErrorCode(
    'RECURSIVE_INTERFACE_INHERITANCE',
    "'{0}' can't implement itself.",
    hasPublishedDocs: true,
    uniqueName: 'RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS',
  );

  /**
   * Parameters:
   * 0: the name of the mixin that constraints itself recursively
   */
  static const CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE_ON =
      CompileTimeErrorCode(
    'RECURSIVE_INTERFACE_INHERITANCE',
    "'{0}' can't use itself as a superclass constraint.",
    hasPublishedDocs: true,
    uniqueName: 'RECURSIVE_INTERFACE_INHERITANCE_ON',
  );

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the interface of a
   * class <i>C</i> is a superinterface of itself.
   *
   * 8.1 Superinterfaces: It is a compile-time error if an interface is a
   * superinterface of itself.
   *
   * 7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a
   * superclass of itself.
   *
   * Parameters:
   * 0: the name of the class that implements itself recursively
   */
  static const CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE_WITH =
      CompileTimeErrorCode(
    'RECURSIVE_INTERFACE_INHERITANCE',
    "'{0}' can't use itself as a mixin.",
    hasPublishedDocs: true,
    uniqueName: 'RECURSIVE_INTERFACE_INHERITANCE_WITH',
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a generative constructor
  // redirects to a constructor that isn't defined.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the constructor `C.a`
  // redirects to the constructor `C.b`, but `C.b` isn't defined:
  //
  // ```dart
  // class C {
  //   C.a() : [!this.b()!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the missing constructor must be called, then define it:
  //
  // ```dart
  // class C {
  //   C.a() : this.b();
  //   C.b();
  // }
  // ```
  //
  // If the missing constructor doesn't need to be called, then remove the
  // redirect:
  //
  // ```dart
  // class C {
  //   C.a();
  // }
  // ```
  static const CompileTimeErrorCode REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR =
      CompileTimeErrorCode(
    'REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR',
    "The constructor '{0}' couldn't be found in '{1}'.",
    correctionMessage:
        "Try redirecting to a different constructor, or defining the constructor named '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a generative constructor
  // redirects to a factory constructor.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the generative
  // constructor `C.a` redirects to the factory constructor `C.b`:
  //
  // ```dart
  // class C {
  //   C.a() : [!this.b()!];
  //   factory C.b() => C.a();
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the generative constructor doesn't need to redirect to another
  // constructor, then remove the redirect.
  //
  // ```dart
  // class C {
  //   C.a();
  //   factory C.b() => C.a();
  // }
  // ```
  //
  // If the generative constructor must redirect to another constructor, then
  // make the other constructor be a generative (non-factory) constructor:
  //
  // ```dart
  // class C {
  //   C.a() : this.b();
  //   C.b();
  // }
  // ```
  static const CompileTimeErrorCode
      REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR = CompileTimeErrorCode(
    'REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR',
    "Generative constructors can't redirect to a factory constructor.",
    correctionMessage: "Try redirecting to a different constructor.",
    hasPublishedDocs: true,
  );

  /**
   * A factory constructor can't redirect to a non-generative constructor of an
   * abstract class.
   */
  static const CompileTimeErrorCode REDIRECT_TO_ABSTRACT_CLASS_CONSTRUCTOR =
      CompileTimeErrorCode(
    'REDIRECT_TO_ABSTRACT_CLASS_CONSTRUCTOR',
    "The redirecting constructor '{0}' can't redirect to a constructor of the abstract class '{1}'.",
    correctionMessage: "Try redirecting to a constructor of a different class.",
  );

  /**
   * Parameters:
   * 0: the name of the redirected constructor
   * 1: the name of the redirecting constructor
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a factory constructor attempts
  // to redirect to another constructor, but the two have incompatible
  // parameters. The parameters are compatible if all of the parameters of the
  // redirecting constructor can be passed to the other constructor and if the
  // other constructor doesn't require any parameters that aren't declared by
  // the redirecting constructor.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because the constructor for `A`
  // doesn't declare a parameter that the constructor for `B` requires:
  //
  // ```dart
  // abstract class A {
  //   factory A() = [!B!];
  // }
  //
  // class B implements A {
  //   B(int x);
  //   B.zero();
  // }
  // ```
  //
  // The following code produces this diagnostic because the constructor for `A`
  // declares a named parameter (`y`) that the constructor for `B` doesn't
  // allow:
  //
  // ```dart
  // abstract class A {
  //   factory A(int x, {int y}) = [!B!];
  // }
  //
  // class B implements A {
  //   B(int x);
  // }
  // ```
  //
  // #### Common fixes
  //
  // If there's a different constructor that is compatible with the redirecting
  // constructor, then redirect to that constructor:
  //
  // ```dart
  // abstract class A {
  //   factory A() = B.zero;
  // }
  //
  // class B implements A {
  //   B(int x);
  //   B.zero();
  // }
  // ```
  //
  // Otherwise, update the redirecting constructor to be compatible:
  //
  // ```dart
  // abstract class A {
  //   factory A(int x) = B;
  // }
  //
  // class B implements A {
  //   B(int x);
  // }
  // ```
  static const CompileTimeErrorCode REDIRECT_TO_INVALID_FUNCTION_TYPE =
      CompileTimeErrorCode(
    'REDIRECT_TO_INVALID_FUNCTION_TYPE',
    "The redirected constructor '{0}' has incompatible parameters with '{1}'.",
    correctionMessage: "Try redirecting to a different constructor.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the redirected constructor's return type
   * 1: the name of the redirecting constructor's return type
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a factory constructor redirects
  // to a constructor whose return type isn't a subtype of the type that the
  // factory constructor is declared to produce.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `A` isn't a subclass
  // of `C`, which means that the value returned by the constructor `A()`
  // couldn't be returned from the constructor `C()`:
  //
  // ```dart
  // class A {}
  //
  // class B implements C {}
  //
  // class C {
  //   factory C() = [!A!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the factory constructor is redirecting to a constructor in the wrong
  // class, then update the factory constructor to redirect to the correct
  // constructor:
  //
  // ```dart
  // class A {}
  //
  // class B implements C {}
  //
  // class C {
  //   factory C() = B;
  // }
  // ```
  //
  // If the class defining the constructor being redirected to is the class that
  // should be returned, then make it a subtype of the factory's return type:
  //
  // ```dart
  // class A implements C {}
  //
  // class B implements C {}
  //
  // class C {
  //   factory C() = A;
  // }
  // ```
  static const CompileTimeErrorCode REDIRECT_TO_INVALID_RETURN_TYPE =
      CompileTimeErrorCode(
    'REDIRECT_TO_INVALID_RETURN_TYPE',
    "The return type '{0}' of the redirected constructor isn't a subtype of '{1}'.",
    correctionMessage: "Try redirecting to a different constructor.",
    hasPublishedDocs: true,
  );

  /**
   * 7.6.2 Factories: It is a compile-time error if <i>k</i> is prefixed with
   * the const modifier but <i>k'</i> is not a constant constructor.
   */
  static const CompileTimeErrorCode REDIRECT_TO_MISSING_CONSTRUCTOR =
      CompileTimeErrorCode(
    'REDIRECT_TO_MISSING_CONSTRUCTOR',
    "The constructor '{0}' couldn't be found in '{1}'.",
    correctionMessage:
        "Try redirecting to a different constructor, or define the constructor named '{0}'.",
  );

  /**
   * Parameters:
   * 0: the name of the non-type referenced in the redirect
   */
  // #### Description
  //
  // One way to implement a factory constructor is to redirect to another
  // constructor by referencing the name of the constructor. The analyzer
  // produces this diagnostic when the redirect is to something other than a
  // constructor.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `f` is a function:
  //
  // ```dart
  // C f() => throw 0;
  //
  // class C {
  //   factory C() = [!f!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the constructor isn't defined, then either define it or replace it with
  // a constructor that is defined.
  //
  // If the constructor is defined but the class that defines it isn't visible,
  // then you probably need to add an import.
  //
  // If you're trying to return the value returned by a function, then rewrite
  // the constructor to return the value from the constructor's body:
  //
  // ```dart
  // C f() => throw 0;
  //
  // class C {
  //   factory C() => f();
  // }
  // ```
  static const CompileTimeErrorCode REDIRECT_TO_NON_CLASS =
      CompileTimeErrorCode(
    'REDIRECT_TO_NON_CLASS',
    "The name '{0}' isn't a type and can't be used in a redirected constructor.",
    correctionMessage: "Try redirecting to a different constructor.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a constructor marked as `const`
  // redirects to a constructor that isn't marked as `const`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the constructor `C.a`
  // is marked as `const` but redirects to the constructor `C.b`, which isn't:
  //
  // ```dart
  // class C {
  //   const C.a() : this.[!b!]();
  //   C.b();
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the non-constant constructor can be marked as `const`, then mark it as
  // `const`:
  //
  // ```dart
  // class C {
  //   const C.a() : this.b();
  //   const C.b();
  // }
  // ```
  //
  // If the non-constant constructor can't be marked as `const`, then either
  // remove the redirect or remove `const` from the redirecting constructor:
  //
  // ```dart
  // class C {
  //   C.a() : this.b();
  //   C.b();
  // }
  // ```
  static const CompileTimeErrorCode REDIRECT_TO_NON_CONST_CONSTRUCTOR =
      CompileTimeErrorCode(
    'REDIRECT_TO_NON_CONST_CONSTRUCTOR',
    "A constant redirecting constructor can't redirect to a non-constant constructor.",
    correctionMessage: "Try redirecting to a different constructor.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a redirecting factory
  // constructor redirects to a type alias, and the type alias expands to one of
  // the type parameters of the type alias. This isn’t allowed because the value
  // of the type parameter is a type rather than a class.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the redirect to `B<A>`
  // is to a type alias whose value is `T`, even though it looks like the value
  // should be `A`:
  //
  // ```dart
  // class A implements C {}
  //
  // typedef B<T> = T;
  //
  // abstract class C {
  //   factory C() = [!B!]<A>;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Use either a class name or a type alias that is defined to be a class
  // rather than a type alias defined to be a type parameter:
  //
  // ```dart
  // class A implements C {}
  //
  // abstract class C {
  //   factory C() = A;
  // }
  // ```
  static const CompileTimeErrorCode
      REDIRECT_TO_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER = CompileTimeErrorCode(
    'REDIRECT_TO_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    "A redirecting constructor can't redirect to a type alias that expands to a type parameter.",
    correctionMessage: "Try replacing it with a class.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a variable is referenced before
  // it’s declared. In Dart, variables are visible everywhere in the block in
  // which they are declared, but can only be referenced after they are
  // declared.
  //
  // The analyzer also produces a context message that indicates where the
  // declaration is located.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `i` is used before it
  // is declared:
  //
  // ```dart
  // %language=2.9
  // void f() {
  //   print([!i!]);
  //   int i = 5;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If you intended to reference the local variable, move the declaration
  // before the first reference:
  //
  // ```dart
  // %language=2.9
  // void f() {
  //   int i = 5;
  //   print(i);
  // }
  // ```
  //
  // If you intended to reference a name from an outer scope, such as a
  // parameter, instance field or top-level variable, then rename the local
  // declaration so that it doesn't hide the outer variable.
  //
  // ```dart
  // %language=2.9
  // void f(int i) {
  //   print(i);
  //   int x = 5;
  //   print(x);
  // }
  // ```
  static const CompileTimeErrorCode REFERENCED_BEFORE_DECLARATION =
      CompileTimeErrorCode(
    'REFERENCED_BEFORE_DECLARATION',
    "Local variable '{0}' can't be referenced before it is declared.",
    correctionMessage:
        "Try moving the declaration to before the first use, or renaming the local variable so that it doesn't hide a name from an enclosing scope.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a `rethrow` statement is outside
  // a `catch` clause. The `rethrow` statement is used to throw a caught
  // exception again, but there's no caught exception outside of a `catch`
  // clause.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the`rethrow` statement
  // is outside of a `catch` clause:
  //
  // ```dart
  // void f() {
  //   [!rethrow!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // If you're trying to rethrow an exception, then wrap the `rethrow` statement
  // in a `catch` clause:
  //
  // ```dart
  // void f() {
  //   try {
  //     // ...
  //   } catch (exception) {
  //     rethrow;
  //   }
  // }
  // ```
  //
  // If you're trying to throw a new exception, then replace the `rethrow`
  // statement with a `throw` expression:
  //
  // ```dart
  // void f() {
  //   throw UnsupportedError('Not yet implemented');
  // }
  // ```
  static const CompileTimeErrorCode RETHROW_OUTSIDE_CATCH =
      CompileTimeErrorCode(
    'RETHROW_OUTSIDE_CATCH',
    "A rethrow must be inside of a catch clause.",
    correctionMessage:
        "Try moving the expression into a catch clause, or using a 'throw' expression.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a generative constructor
  // contains a `return` statement that specifies a value to be returned.
  // Generative constructors always return the object that was created, and
  // therefore can't return a different object.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the `return` statement
  // has an expression:
  //
  // ```dart
  // class C {
  //   C() {
  //     return [!this!];
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the constructor should create a new instance, then remove either the
  // `return` statement or the expression:
  //
  // ```dart
  // class C {
  //   C();
  // }
  // ```
  //
  // If the constructor shouldn't create a new instance, then convert it to be a
  // factory constructor:
  //
  // ```dart
  // class C {
  //   factory C() {
  //     return _instance;
  //   }
  //
  //   static C _instance = C._();
  //
  //   C._();
  // }
  // ```
  static const CompileTimeErrorCode RETURN_IN_GENERATIVE_CONSTRUCTOR =
      CompileTimeErrorCode(
    'RETURN_IN_GENERATIVE_CONSTRUCTOR',
    "Constructors can't return values.",
    correctionMessage:
        "Try removing the return statement or using a factory constructor.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a generator function (one whose
  // body is marked with either `async*` or `sync*`) uses either a `return`
  // statement to return a value or implicitly returns a value because of using
  // `=>`. In any of these cases, they should use `yield` instead of `return`.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because the method `f` is a
  // generator and is using `return` to return a value:
  //
  // ```dart
  // Iterable<int> f() sync* {
  //   [!return 3!];
  // }
  // ```
  //
  // The following code produces this diagnostic because the function `f` is a
  // generator and is implicitly returning a value:
  //
  // ```dart
  // Stream<int> f() async* [!=>!] 3;
  // ```
  //
  // #### Common fixes
  //
  // If the function is using `=>` for the body of the function, then convert it
  // to a block function body, and use `yield` to return a value:
  //
  // ```dart
  // Stream<int> f() async* {
  //   yield 3;
  // }
  // ```
  //
  // If the method is intended to be a generator, then use `yield` to return a
  // value:
  //
  // ```dart
  // Iterable<int> f() sync* {
  //   yield 3;
  // }
  // ```
  //
  // If the method isn't intended to be a generator, then remove the modifier
  // from the body (or use `async` if you're returning a future):
  //
  // ```dart
  // int f() {
  //   return 3;
  // }
  // ```
  static const CompileTimeErrorCode RETURN_IN_GENERATOR = CompileTimeErrorCode(
    'RETURN_IN_GENERATOR',
    "Can't return a value from a generator function that uses the 'async*' or 'sync*' modifier.",
    correctionMessage:
        "Try replacing 'return' with 'yield', using a block function body, or changing the method body modifier.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the return type as declared in the return statement
   * 1: the expected return type as defined by the method
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the static type of a returned
  // expression isn't assignable to the return type that the closure is required
  // to have.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `f` is defined to be a
  // function that returns a `String`, but the closure assigned to it returns an
  // `int`:
  //
  // ```dart
  // String Function(String) f = (s) => [!3!];
  // ```
  //
  // #### Common fixes
  //
  // If the return type is correct, then replace the returned value with a value
  // of the correct type, possibly by converting the existing value:
  //
  // ```dart
  // String Function(String) f = (s) => 3.toString();
  // ```
  static const CompileTimeErrorCode RETURN_OF_INVALID_TYPE_FROM_CLOSURE =
      CompileTimeErrorCode(
    'RETURN_OF_INVALID_TYPE_FROM_CLOSURE',
    "The return type '{0}' isn't a '{1}', as required by the closure's context.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the return type as declared in the return statement
   * 1: the expected return type as defined by the enclosing class
   * 2: the name of the constructor
   */
  static const CompileTimeErrorCode RETURN_OF_INVALID_TYPE_FROM_CONSTRUCTOR =
      CompileTimeErrorCode(
    'RETURN_OF_INVALID_TYPE',
    "A value of type '{0}' can't be returned from the constructor '{2}' because it has a return type of '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'RETURN_OF_INVALID_TYPE_FROM_CONSTRUCTOR',
  );

  /**
   * Parameters:
   * 0: the return type as declared in the return statement
   * 1: the expected return type as defined by the method
   * 2: the name of the method
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a method or function returns a
  // value whose type isn't assignable to the declared return type.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `f` has a return type
  // of `String` but is returning an `int`:
  //
  // ```dart
  // String f() => [!3!];
  // ```
  //
  // #### Common fixes
  //
  // If the return type is correct, then replace the value being returned with a
  // value of the correct type, possibly by converting the existing value:
  //
  // ```dart
  // String f() => 3.toString();
  // ```
  //
  // If the value is correct, then change the return type to match:
  //
  // ```dart
  // int f() => 3;
  // ```
  static const CompileTimeErrorCode RETURN_OF_INVALID_TYPE_FROM_FUNCTION =
      CompileTimeErrorCode(
    'RETURN_OF_INVALID_TYPE',
    "A value of type '{0}' can't be returned from the function '{2}' because it has a return type of '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'RETURN_OF_INVALID_TYPE_FROM_FUNCTION',
  );

  /**
   * Parameters:
   * 0: the return type as declared in the return statement
   * 1: the expected return type as defined by the method
   * 2: the name of the method
   */
  static const CompileTimeErrorCode RETURN_OF_INVALID_TYPE_FROM_METHOD =
      CompileTimeErrorCode(
    'RETURN_OF_INVALID_TYPE',
    "A value of type '{0}' can't be returned from the method '{2}' because it has a return type of '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'RETURN_OF_INVALID_TYPE_FROM_METHOD',
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when it finds a `return` statement
  // without an expression in a function that declares a return type.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the function `f` is
  // expected to return an `int`, but no value is being returned:
  //
  // ```dart
  // int f() {
  //   [!return!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // Add an expression that computes the value to be returned:
  //
  // ```dart
  // int f() {
  //   return 0;
  // }
  // ```
  static const CompileTimeErrorCode RETURN_WITHOUT_VALUE = CompileTimeErrorCode(
    'RETURN_WITHOUT_VALUE',
    "The return value is missing after 'return'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  static const CompileTimeErrorCode SET_ELEMENT_FROM_DEFERRED_LIBRARY =
      CompileTimeErrorCode(
    'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as values in a 'const' set literal.",
    correctionMessage:
        "Try removing the keyword 'const' from the set literal or removing the keyword 'deferred' from the import.",
    hasPublishedDocs: true,
    uniqueName: 'SET_ELEMENT_FROM_DEFERRED_LIBRARY',
  );

  /**
   * Parameters:
   * 0: the actual type of the set element
   * 1: the expected type of the set element
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an element in a set literal has
  // a type that isn't assignable to the element type of the set.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the type of the string
  // literal `'0'` is `String`, which isn't assignable to `int`, the element
  // type of the set:
  //
  // ```dart
  // var s = <int>{[!'0'!]};
  // ```
  //
  // #### Common fixes
  //
  // If the element type of the set literal is wrong, then change the element
  // type of the set:
  //
  // ```dart
  // var s = <String>{'0'};
  // ```
  //
  // If the type of the element is wrong, then change the element:
  //
  // ```dart
  // var s = <int>{'0'.length};
  // ```
  static const CompileTimeErrorCode SET_ELEMENT_TYPE_NOT_ASSIGNABLE =
      CompileTimeErrorCode(
    'SET_ELEMENT_TYPE_NOT_ASSIGNABLE',
    "The element type '{0}' can't be assigned to the set type '{1}'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a prefix in a deferred import is
  // also used as a prefix in other imports (whether deferred or not). The
  // prefix in a deferred import can't be shared with other imports because the
  // prefix is used to load the imported library.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the prefix `x` is used
  // as the prefix for a deferred import and is also used for one other import:
  //
  // ```dart
  // import 'dart:math' [!deferred!] as x;
  // import 'dart:convert' as x;
  //
  // var y = x.json.encode(x.min(0, 1));
  // ```
  //
  // #### Common fixes
  //
  // If you can use a different name for the deferred import, then do so:
  //
  // ```dart
  // import 'dart:math' deferred as math;
  // import 'dart:convert' as x;
  //
  // var y = x.json.encode(math.min(0, 1));
  // ```
  //
  // If you can use a different name for the other imports, then do so:
  //
  // ```dart
  // import 'dart:math' deferred as x;
  // import 'dart:convert' as convert;
  //
  // var y = convert.json.encode(x.min(0, 1));
  // ```
  static const CompileTimeErrorCode SHARED_DEFERRED_PREFIX =
      CompileTimeErrorCode(
    'SHARED_DEFERRED_PREFIX',
    "The prefix of a deferred import can't be used in other import directives.",
    correctionMessage: "Try renaming one of the prefixes.",
    hasPublishedDocs: true,
  );

  static const CompileTimeErrorCode SPREAD_EXPRESSION_FROM_DEFERRED_LIBRARY =
      CompileTimeErrorCode(
    'SPREAD_EXPRESSION_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be spread into a const literal.",
    correctionMessage: "Try making the deferred import non-deferred.",
  );

  /**
   * Parameters:
   * 0: the name of the instance member
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a class name is used to access
  // an instance field. Instance fields don't exist on a class; they exist only
  // on an instance of the class.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `x` is an instance
  // field:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   static int a;
  //
  //   int b;
  // }
  //
  // int f() => C.[!b!];
  // ```
  //
  // #### Common fixes
  //
  // If you intend to access a static field, then change the name of the field
  // to an existing static field:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   static int a;
  //
  //   int b;
  // }
  //
  // int f() => C.a;
  // ```
  //
  // If you intend to access the instance field, then use an instance of the
  // class to access the field:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   static int a;
  //
  //   int b;
  // }
  //
  // int f(C c) => c.b;
  // ```
  static const CompileTimeErrorCode STATIC_ACCESS_TO_INSTANCE_MEMBER =
      CompileTimeErrorCode(
    'STATIC_ACCESS_TO_INSTANCE_MEMBER',
    "Instance member '{0}' can't be accessed using static access.",
    hasPublishedDocs: true,
  );

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It
   * is a compile-time error if a generative constructor of class Object
   * includes a superinitializer.
   */
  static const CompileTimeErrorCode SUPER_INITIALIZER_IN_OBJECT =
      CompileTimeErrorCode(
    'SUPER_INITIALIZER_IN_OBJECT',
    "The class 'Object' can't invoke a constructor from a superclass.",
  );

  /**
   * Parameters:
   * 0: the superinitializer
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the initializer list of a
  // constructor contains an invocation of a constructor in the superclass, but
  // the invocation isn't the last item in the initializer list.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the invocation of the
  // superclass' constructor isn't the last item in the initializer list:
  //
  // ```dart
  // class A {
  //   A(int x);
  // }
  //
  // class B extends A {
  //   B(int x) : [!super!](x), assert(x >= 0);
  // }
  // ```
  //
  // #### Common fixes
  //
  // Move the invocation of the superclass' constructor to the end of the
  // initializer list:
  //
  // ```dart
  // class A {
  //   A(int x);
  // }
  //
  // class B extends A {
  //   B(int x) : assert(x >= 0), super(x);
  // }
  // ```
  static const CompileTimeErrorCode SUPER_INVOCATION_NOT_LAST =
      CompileTimeErrorCode(
    'SUPER_INVOCATION_NOT_LAST',
    "The superconstructor call must be last in an initializer list: '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a member declared inside an
  // extension uses the `super` keyword . Extensions aren't classes and don't
  // have superclasses, so the `super` keyword serves no purpose.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `super` can't be used
  // in an extension:
  //
  // ```dart
  // extension E on Object {
  //   String get displayString => [!super!].toString();
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the `super` keyword :
  //
  // ```dart
  // extension E on Object {
  //   String get displayString => toString();
  // }
  // ```
  static const CompileTimeErrorCode SUPER_IN_EXTENSION = CompileTimeErrorCode(
    'SUPER_IN_EXTENSION',
    "The 'super' keyword can't be used in an extension because an extension doesn't have a superclass.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the keyword `super` is used
  // outside of a instance method.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `super` is used in a
  // top-level function:
  //
  // ```dart
  // void f() {
  //   [!super!].f();
  // }
  // ```
  //
  // #### Common fixes
  //
  // Rewrite the code to not use `super`.
  static const CompileTimeErrorCode SUPER_IN_INVALID_CONTEXT =
      CompileTimeErrorCode(
    'SUPER_IN_INVALID_CONTEXT',
    "Invalid context for 'super' invocation.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a constructor that redirects to
  // another constructor also attempts to invoke a constructor from the
  // superclass. The superclass constructor will be invoked when the constructor
  // that the redirecting constructor is redirected to is invoked.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the constructor `C.a`
  // both redirects to `C.b` and invokes a constructor from the superclass:
  //
  // ```dart
  // class C {
  //   C.a() : this.b(), [!super()!];
  //   C.b();
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the invocation of the `super` constructor:
  //
  // ```dart
  // class C {
  //   C.a() : this.b();
  //   C.b();
  // }
  // ```
  static const CompileTimeErrorCode SUPER_IN_REDIRECTING_CONSTRUCTOR =
      CompileTimeErrorCode(
    'SUPER_IN_REDIRECTING_CONSTRUCTOR',
    "The redirecting constructor can't have a 'super' initializer.",
    hasPublishedDocs: true,
  );

  /**
   * It is an error if any case of a switch statement except the last case (the
   * default case if present) may complete normally. The previous syntactic
   * restriction requiring the last statement of each case to be one of an
   * enumerated list of statements (break, continue, return, throw, or rethrow)
   * is removed.
   */
  static const CompileTimeErrorCode SWITCH_CASE_COMPLETES_NORMALLY =
      CompileTimeErrorCode(
    'SWITCH_CASE_COMPLETES_NORMALLY',
    "The 'case' should not complete normally.",
    correctionMessage: "Try adding 'break', or 'return', etc.",
  );

  /**
   * Parameters:
   * 0: the static type of the switch expression
   * 1: the static type of the case expressions
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the type of the expression in a
  // `switch` statement isn't assignable to the type of the expressions in the
  // `case` clauses.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the type of `s`
  // (`String`) isn't assignable to the type of `0` (`int`):
  //
  // ```dart
  // %language=2.9
  // void f(String s) {
  //   switch ([!s!]) {
  //     case 0:
  //       break;
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the type of the `case` expressions is correct, then change the
  // expression in the `switch` statement to have the correct type:
  //
  // ```dart
  // %language=2.9
  // void f(String s) {
  //   switch (int.parse(s)) {
  //     case 0:
  //       break;
  //   }
  // }
  // ```
  //
  // If the type of the `switch` expression is correct, then change the `case`
  // expressions to have the correct type:
  //
  // ```dart
  // %language=2.9
  // void f(String s) {
  //   switch (s) {
  //     case '0':
  //       break;
  //   }
  // }
  // ```
  static const CompileTimeErrorCode SWITCH_EXPRESSION_NOT_ASSIGNABLE =
      CompileTimeErrorCode(
    'SWITCH_EXPRESSION_NOT_ASSIGNABLE',
    "Type '{0}' of the switch expression isn't assignable to the type '{1}' of case expressions.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a generative constructor from an
  // abstract class is being torn off. This isn't allowed because it isn't valid
  // to create an instance of an abstract class, which means that there isn't
  // any valid use for the torn off constructor.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the constructor `C.new`
  // is being torn off and the class `C` is an abstract class:
  //
  // ```dart
  // abstract class C {
  //   C();
  // }
  //
  // void f() {
  //   [!C.new!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // Tear off the constructor of a concrete class.
  static const CompileTimeErrorCode
      TEAROFF_OF_GENERATIVE_CONSTRUCTOR_OF_ABSTRACT_CLASS =
      CompileTimeErrorCode(
    'TEAROFF_OF_GENERATIVE_CONSTRUCTOR_OF_ABSTRACT_CLASS',
    "A generative constructor of an abstract class can't be torn off.",
    correctionMessage:
        "Try tearing off a constructor of a concrete class, or a non-generative constructor.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the type that can't be thrown
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the type of the expression in a
  // throw expression isn't assignable to `Object`. It isn't valid to throw
  // `null`, so it isn't valid to use an expression that might evaluate to
  // `null`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `s` might be `null`:
  //
  // ```dart
  // void f(String? s) {
  //   throw [!s!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // Add an explicit null check to the expression:
  //
  // ```dart
  // void f(String? s) {
  //   throw s!;
  // }
  // ```
  static const CompileTimeErrorCode THROW_OF_INVALID_TYPE =
      CompileTimeErrorCode(
    'THROW_OF_INVALID_TYPE',
    "The type '{0}' of the thrown expression must be assignable to 'Object'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the element whose type could not be inferred.
   * 1: The [TopLevelInferenceError]'s arguments that led to the cycle.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a top-level variable has no type
  // annotation and the variable's initializer refers to the variable, either
  // directly or indirectly.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the variables `x` and
  // `y` are defined in terms of each other, and neither has an explicit type,
  // so the type of the other can't be inferred:
  //
  // ```dart
  // var x = y;
  // var y = [!x!];
  // ```
  //
  // #### Common fixes
  //
  // If the two variables don't need to refer to each other, then break the
  // cycle:
  //
  // ```dart
  // var x = 0;
  // var y = x;
  // ```
  //
  // If the two variables need to refer to each other, then give at least one of
  // them an explicit type:
  //
  // ```dart
  // int x = y;
  // var y = x;
  // ```
  //
  // Note, however, that while this code doesn't produce any diagnostics, it
  // will produce a stack overflow at runtime unless at least one of the
  // variables is assigned a value that doesn't depend on the other variables
  // before any of the variables in the cycle are referenced.
  static const CompileTimeErrorCode TOP_LEVEL_CYCLE = CompileTimeErrorCode(
    'TOP_LEVEL_CYCLE',
    "The type of '{0}' can't be inferred because it depends on itself through the cycle: {1}.",
    correctionMessage:
        "Try adding an explicit type to one or more of the variables in the cycle in order to break the cycle.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a typedef refers to itself,
  // either directly or indirectly.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `F` depends on itself
  // indirectly through `G`:
  //
  // ```dart
  // typedef [!F!] = void Function(G);
  // typedef G = void Function(F);
  // ```
  //
  // #### Common fixes
  //
  // Change one or more of the typedefs in the cycle so that none of them refer
  // to themselves:
  //
  // ```dart
  // typedef F = void Function(G);
  // typedef G = void Function(int);
  // ```
  static const CompileTimeErrorCode TYPE_ALIAS_CANNOT_REFERENCE_ITSELF =
      CompileTimeErrorCode(
    'TYPE_ALIAS_CANNOT_REFERENCE_ITSELF',
    "Typedefs can't reference themselves directly or recursively via another typedef.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the type that is deferred and being used in a type
   *    annotation
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the type annotation is in a
  // variable declaration, or the type used in a cast (`as`) or type test (`is`)
  // is a type declared in a library that is imported using a deferred import.
  // These types are required to be available at compile time, but aren't.
  //
  // For more information, see the language tour's coverage of
  // [deferred loading](https://dart.dev/guides/language/language-tour#lazily-loading-a-library).
  //
  // #### Example
  //
  // The following code produces this diagnostic because the type of the
  // parameter `f` is imported from a deferred library:
  //
  // ```dart
  // import 'dart:io' deferred as io;
  //
  // void f([!io.File!] f) {}
  // ```
  //
  // #### Common fixes
  //
  // If you need to reference the imported type, then remove the `deferred`
  // keyword:
  //
  // ```dart
  // import 'dart:io' as io;
  //
  // void f(io.File f) {}
  // ```
  //
  // If the import is required to be deferred and there's another type that is
  // appropriate, then use that type in place of the type from the deferred
  // library.
  static const CompileTimeErrorCode TYPE_ANNOTATION_DEFERRED_CLASS =
      CompileTimeErrorCode(
    'TYPE_ANNOTATION_DEFERRED_CLASS',
    "The deferred type '{0}' can't be used in a declaration, cast, or type test.",
    correctionMessage:
        "Try using a different type, or changing the import to not be deferred.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the type used in the instance creation that should be
   *    limited by the bound as specified in the class declaration
   * 1: the name of the type parameter
   * 2: the substituted bound of the type parameter
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a type argument isn't the same
  // as or a subclass of the bounds of the corresponding type parameter.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `String` isn't a
  // subclass of `num`:
  //
  // ```dart
  // class A<E extends num> {}
  //
  // var a = A<[!String!]>();
  // ```
  //
  // #### Common fixes
  //
  // Change the type argument to be a subclass of the bounds:
  //
  // ```dart
  // class A<E extends num> {}
  //
  // var a = A<int>();
  // ```
  static const CompileTimeErrorCode TYPE_ARGUMENT_NOT_MATCHING_BOUNDS =
      CompileTimeErrorCode(
    'TYPE_ARGUMENT_NOT_MATCHING_BOUNDS',
    "'{0}' doesn't conform to the bound '{2}' of the type parameter '{1}'.",
    correctionMessage: "Try using a type that is or is a subclass of '{2}'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a static member references a
  // type parameter that is declared for the class. Type parameters only have
  // meaning for instances of the class.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the static method
  // `hasType` has a reference to the type parameter `T`:
  //
  // ```dart
  // class C<T> {
  //   static bool hasType(Object o) => o is [!T!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the member can be an instance member, then remove the keyword `static`:
  //
  // ```dart
  // class C<T> {
  //   bool hasType(Object o) => o is T;
  // }
  // ```
  //
  // If the member must be a static member, then make the member be generic:
  //
  // ```dart
  // class C<T> {
  //   static bool hasType<S>(Object o) => o is S;
  // }
  // ```
  //
  // Note, however, that there isn’t a relationship between `T` and `S`, so this
  // second option changes the semantics from what was likely to be intended.
  static const CompileTimeErrorCode TYPE_PARAMETER_REFERENCED_BY_STATIC =
      CompileTimeErrorCode(
    'TYPE_PARAMETER_REFERENCED_BY_STATIC',
    "Static members can't reference type parameters of the class.",
    correctionMessage:
        "Try removing the reference to the type parameter, or making the member an instance member.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the type parameter
   * 1: the name of the bounding type
   *
   * See [CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS].
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the bound of a type parameter
  // (the type following the `extends` keyword) is either directly or indirectly
  // the type parameter itself. Stating that the type parameter must be the same
  // as itself or a subtype of itself or a subtype of itself isn't helpful
  // because it will always be the same as itself.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because the bound of `T` is
  // `T`:
  //
  // ```dart
  // class C<[!T!] extends T> {}
  // ```
  //
  // The following code produces this diagnostic because the bound of `T1` is
  // `T2`, and the bound of `T2` is `T1`, effectively making the bound of `T1`
  // be `T1`:
  //
  // ```dart
  // class C<[!T1!] extends T2, T2 extends T1> {}
  // ```
  //
  // #### Common fixes
  //
  // If the type parameter needs to be a subclass of some type, then replace the
  // bound with the required type:
  //
  // ```dart
  // class C<T extends num> {}
  // ```
  //
  // If the type parameter can be any type, then remove the `extends` clause:
  //
  // ```dart
  // class C<T> {}
  // ```
  static const CompileTimeErrorCode TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND =
      CompileTimeErrorCode(
    'TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND',
    "'{0}' can't be a supertype of its upper bound.",
    correctionMessage:
        "Try using a type that is the same as or a subclass of '{1}'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the right-hand side of an `is`
  // or `is!` test isn't a type.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the right-hand side is
  // a parameter, not a type:
  //
  // ```dart
  // typedef B = int Function(int);
  //
  // void f(Object a, B b) {
  //   if (a is [!b!]) {
  //     return;
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If you intended to use a type test, then replace the right-hand side with a
  // type:
  //
  // ```dart
  // typedef B = int Function(int);
  //
  // void f(Object a, B b) {
  //   if (a is B) {
  //     return;
  //   }
  // }
  // ```
  //
  // If you intended to use a different kind of test, then change the test:
  //
  // ```dart
  // typedef B = int Function(int);
  //
  // void f(Object a, B b) {
  //   if (a == b) {
  //     return;
  //   }
  // }
  // ```
  static const CompileTimeErrorCode TYPE_TEST_WITH_NON_TYPE =
      CompileTimeErrorCode(
    'TYPE_TEST_WITH_NON_TYPE',
    "The name '{0}' isn't a type and can't be used in an 'is' expression.",
    correctionMessage: "Try correcting the name to match an existing type.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the name following the `is` in a
  // type test expression isn't defined.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the name `Srting` isn't
  // defined:
  //
  // ```dart
  // void f(Object o) {
  //   if (o is [!Srting!]) {
  //     // ...
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // Replace the name with the name of a type:
  //
  // ```dart
  // void f(Object o) {
  //   if (o is String) {
  //     // ...
  //   }
  // }
  // ```
  static const CompileTimeErrorCode TYPE_TEST_WITH_UNDEFINED_NAME =
      CompileTimeErrorCode(
    'TYPE_TEST_WITH_UNDEFINED_NAME',
    "The name '{0}' isn't defined, so it can't be used in an 'is' expression.",
    correctionMessage:
        "Try changing the name to the name of an existing type, or creating a type with the name '{0}'.",
    hasPublishedDocs: true,
  );

  static const CompileTimeErrorCode UNCHECKED_INVOCATION_OF_NULLABLE_VALUE =
      CompileTimeErrorCode(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "The function can't be unconditionally invoked because it can be 'null'.",
    correctionMessage: "Try adding a null check ('!').",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_INVOCATION_OF_NULLABLE_VALUE',
  );

  static const CompileTimeErrorCode
      UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE = CompileTimeErrorCode(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "The method '{0}' can't be unconditionally invoked because the receiver can be 'null'.",
    correctionMessage:
        "Try making the call conditional (using '?.') or adding a null check to the target ('!').",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE',
  );

  static const CompileTimeErrorCode
      UNCHECKED_OPERATOR_INVOCATION_OF_NULLABLE_VALUE = CompileTimeErrorCode(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "The operator '{0}' can't be unconditionally invoked because the receiver can be 'null'.",
    correctionMessage: "Try adding a null check to the target ('!').",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_OPERATOR_INVOCATION_OF_NULLABLE_VALUE',
  );

  static const CompileTimeErrorCode
      UNCHECKED_PROPERTY_ACCESS_OF_NULLABLE_VALUE = CompileTimeErrorCode(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "The property '{0}' can't be unconditionally accessed because the receiver can be 'null'.",
    correctionMessage:
        "Try making the access conditional (using '?.') or adding a null check to the target ('!').",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_PROPERTY_ACCESS_OF_NULLABLE_VALUE',
  );

  // #### Description
  //
  // The analyzer produces this diagnostic when an expression whose type is
  // [potentially non-nullable][] is dereferenced without first verifying that
  // the value isn't `null`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `s` can be `null` at
  // the point where it's referenced:
  //
  // ```dart
  // void f(String? s) {
  //   if (s.[!length!] > 3) {
  //     // ...
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the value really can be `null`, then add a test to ensure that members
  // are only accessed when the value isn't `null`:
  //
  // ```dart
  // void f(String? s) {
  //   if (s != null && s.length > 3) {
  //     // ...
  //   }
  // }
  // ```
  //
  // If the expression is a variable and the value should never be `null`, then
  // change the type of the variable to be non-nullable:
  //
  // ```dart
  // void f(String s) {
  //   if (s.length > 3) {
  //     // ...
  //   }
  // }
  // ```
  //
  // If you believe that the value of the expression should never be `null`, but
  // you can't change the type of the variable, and you're willing to risk
  // having an exception thrown at runtime if you're wrong, then you can assert
  // that the value isn't null:
  //
  // ```dart
  // void f(String? s) {
  //   if (s!.length > 3) {
  //     // ...
  //   }
  // }
  // ```
  static const CompileTimeErrorCode
      UNCHECKED_USE_OF_NULLABLE_VALUE_AS_CONDITION = CompileTimeErrorCode(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "A nullable expression can't be used as a condition.",
    correctionMessage:
        "Try checking that the value isn't 'null' before using it as a condition.",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_USE_OF_NULLABLE_VALUE_AS_CONDITION',
  );

  static const CompileTimeErrorCode
      UNCHECKED_USE_OF_NULLABLE_VALUE_AS_ITERATOR = CompileTimeErrorCode(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "A nullable expression can't be used as an iterator in a for-in loop.",
    correctionMessage:
        "Try checking that the value isn't 'null' before using it as an iterator.",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_USE_OF_NULLABLE_VALUE_AS_ITERATOR',
  );

  static const CompileTimeErrorCode UNCHECKED_USE_OF_NULLABLE_VALUE_IN_SPREAD =
      CompileTimeErrorCode(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "A nullable expression can't be used in a spread.",
    correctionMessage:
        "Try checking that the value isn't 'null' before using it in a spread, or use a null-aware spread.",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_USE_OF_NULLABLE_VALUE_IN_SPREAD',
  );

  static const CompileTimeErrorCode
      UNCHECKED_USE_OF_NULLABLE_VALUE_IN_YIELD_EACH = CompileTimeErrorCode(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "A nullable expression can't be used in a yield-each statement.",
    correctionMessage:
        "Try checking that the value isn't 'null' before using it in a yield-each statement.",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_USE_OF_NULLABLE_VALUE_IN_YIELD_EACH',
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a name that isn't defined is
  // used as an annotation.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the name `undefined`
  // isn't defined:
  //
  // ```dart
  // [!@undefined!]
  // void f() {}
  // ```
  //
  // #### Common fixes
  //
  // If the name is correct, but it isn’t declared yet, then declare the name as
  // a constant value:
  //
  // ```dart
  // const undefined = 'undefined';
  //
  // @undefined
  // void f() {}
  // ```
  //
  // If the name is wrong, replace the name with the name of a valid constant:
  //
  // ```dart
  // @deprecated
  // void f() {}
  // ```
  //
  // Otherwise, remove the annotation.
  static const CompileTimeErrorCode UNDEFINED_ANNOTATION = CompileTimeErrorCode(
    'UNDEFINED_ANNOTATION',
    "Undefined name '{0}' used as an annotation.",
    correctionMessage:
        "Try defining the name or importing it from another library.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
  );

  /**
   * Parameters:
   * 0: the name of the undefined class
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when it encounters an identifier that
  // appears to be the name of a class but either isn't defined or isn't visible
  // in the scope in which it's being referenced.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `Piont` isn't defined:
  //
  // ```dart
  // class Point {}
  //
  // void f([!Piont!] p) {}
  // ```
  //
  // #### Common fixes
  //
  // If the identifier isn't defined, then either define it or replace it with
  // the name of a class that is defined. The example above can be corrected by
  // fixing the spelling of the class:
  //
  // ```dart
  // class Point {}
  //
  // void f(Point p) {}
  // ```
  //
  // If the class is defined but isn't visible, then you probably need to add an
  // import.
  static const CompileTimeErrorCode UNDEFINED_CLASS = CompileTimeErrorCode(
    'UNDEFINED_CLASS',
    "Undefined class '{0}'.",
    correctionMessage:
        "Try changing the name to the name of an existing class, or creating a class with the name '{0}'.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
  );

  /**
   * Same as [CompileTimeErrorCode.UNDEFINED_CLASS], but to catch using
   * "boolean" instead of "bool" in order to improve the correction message.
   *
   * Parameters:
   * 0: the name of the undefined class
   */
  static const CompileTimeErrorCode UNDEFINED_CLASS_BOOLEAN =
      CompileTimeErrorCode(
    'UNDEFINED_CLASS',
    "Undefined class '{0}'.",
    correctionMessage: "Try using the type 'bool'.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
    uniqueName: 'UNDEFINED_CLASS_BOOLEAN',
  );

  /**
   * Parameters:
   * 0: the name of the superclass that does not define the invoked constructor
   * 1: the name of the constructor being invoked
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a superclass constructor is
  // invoked in the initializer list of a constructor, but the superclass
  // doesn't define the constructor being invoked.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because `A` doesn't have an
  // unnamed constructor:
  //
  // ```dart
  // class A {
  //   A.n();
  // }
  // class B extends A {
  //   B() : [!super()!];
  // }
  // ```
  //
  // The following code produces this diagnostic because `A` doesn't have a
  // constructor named `m`:
  //
  // ```dart
  // class A {
  //   A.n();
  // }
  // class B extends A {
  //   B() : [!super.m()!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the superclass defines a constructor that should be invoked, then change
  // the constructor being invoked:
  //
  // ```dart
  // class A {
  //   A.n();
  // }
  // class B extends A {
  //   B() : super.n();
  // }
  // ```
  //
  // If the superclass doesn't define an appropriate constructor, then define
  // the constructor being invoked:
  //
  // ```dart
  // class A {
  //   A.m();
  //   A.n();
  // }
  // class B extends A {
  //   B() : super.m();
  // }
  // ```
  static const CompileTimeErrorCode UNDEFINED_CONSTRUCTOR_IN_INITIALIZER =
      CompileTimeErrorCode(
    'UNDEFINED_CONSTRUCTOR_IN_INITIALIZER',
    "The class '{0}' doesn't have a constructor named '{1}'.",
    correctionMessage:
        "Try defining a constructor named '{1}' in '{0}', or invoking a different constructor.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the superclass that does not define the invoked constructor
   */
  static const CompileTimeErrorCode
      UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT = CompileTimeErrorCode(
    'UNDEFINED_CONSTRUCTOR_IN_INITIALIZER',
    "The class '{0}' doesn't have an unnamed constructor.",
    correctionMessage:
        "Try defining an unnamed constructor in '{0}', or invoking a different constructor.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT',
  );

  /**
   * Parameters:
   * 0: the name of the enumeration constant that is not defined
   * 1: the name of the enumeration used to access the constant
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when it encounters an identifier that
  // appears to be the name of an enum constant, and the name either isn't
  // defined or isn't visible in the scope in which it's being referenced.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `E` doesn't define a
  // constant named `c`:
  //
  // ```dart
  // enum E {a, b}
  //
  // var e = E.[!c!];
  // ```
  //
  // #### Common fixes
  //
  // If the constant should be defined, then add it to the declaration of the
  // enum:
  //
  // ```dart
  // enum E {a, b, c}
  //
  // var e = E.c;
  // ```
  //
  // If the constant shouldn't be defined, then change the name to the name of
  // an existing constant:
  //
  // ```dart
  // enum E {a, b}
  //
  // var e = E.b;
  // ```
  static const CompileTimeErrorCode UNDEFINED_ENUM_CONSTANT =
      CompileTimeErrorCode(
    'UNDEFINED_ENUM_CONSTANT',
    "There's no constant named '{0}' in '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing constant, or defining a constant named '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the getter that is undefined
   * 1: the name of the extension that was explicitly specified
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an extension override is used to
  // invoke a getter, but the getter isn't defined by the specified extension.
  // The analyzer also produces this diagnostic when a static getter is
  // referenced but isn't defined by the specified extension.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because the extension `E`
  // doesn't declare an instance getter named `b`:
  //
  // ```dart
  // extension E on String {
  //   String get a => 'a';
  // }
  //
  // extension F on String {
  //   String get b => 'b';
  // }
  //
  // void f() {
  //   E('c').[!b!];
  // }
  // ```
  //
  // The following code produces this diagnostic because the extension `E`
  // doesn't declare a static getter named `a`:
  //
  // ```dart
  // extension E on String {}
  //
  // var x = E.[!a!];
  // ```
  //
  // #### Common fixes
  //
  // If the name of the getter is incorrect, then change it to the name of an
  // existing getter:
  //
  // ```dart
  // extension E on String {
  //   String get a => 'a';
  // }
  //
  // extension F on String {
  //   String get b => 'b';
  // }
  //
  // void f() {
  //   E('c').a;
  // }
  // ```
  //
  // If the name of the getter is correct but the name of the extension is
  // wrong, then change the name of the extension to the correct name:
  //
  // ```dart
  // extension E on String {
  //   String get a => 'a';
  // }
  //
  // extension F on String {
  //   String get b => 'b';
  // }
  //
  // void f() {
  //   F('c').b;
  // }
  // ```
  //
  // If the name of the getter and extension are both correct, but the getter
  // isn't defined, then define the getter:
  //
  // ```dart
  // extension E on String {
  //   String get a => 'a';
  //   String get b => 'z';
  // }
  //
  // extension F on String {
  //   String get b => 'b';
  // }
  //
  // void f() {
  //   E('c').b;
  // }
  // ```
  static const CompileTimeErrorCode UNDEFINED_EXTENSION_GETTER =
      CompileTimeErrorCode(
    'UNDEFINED_EXTENSION_GETTER',
    "The getter '{0}' isn't defined for the extension '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing getter, or defining a getter named '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the method that is undefined
   * 1: the name of the extension that was explicitly specified
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an extension override is used to
  // invoke a method, but the method isn't defined by the specified extension.
  // The analyzer also produces this diagnostic when a static method is
  // referenced but isn't defined by the specified extension.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because the extension `E`
  // doesn't declare an instance method named `b`:
  //
  // ```dart
  // extension E on String {
  //   String a() => 'a';
  // }
  //
  // extension F on String {
  //   String b() => 'b';
  // }
  //
  // void f() {
  //   E('c').[!b!]();
  // }
  // ```
  //
  // The following code produces this diagnostic because the extension `E`
  // doesn't declare a static method named `a`:
  //
  // ```dart
  // extension E on String {}
  //
  // var x = E.[!a!]();
  // ```
  //
  // #### Common fixes
  //
  // If the name of the method is incorrect, then change it to the name of an
  // existing method:
  //
  // ```dart
  // extension E on String {
  //   String a() => 'a';
  // }
  //
  // extension F on String {
  //   String b() => 'b';
  // }
  //
  // void f() {
  //   E('c').a();
  // }
  // ```
  //
  // If the name of the method is correct, but the name of the extension is
  // wrong, then change the name of the extension to the correct name:
  //
  // ```dart
  // extension E on String {
  //   String a() => 'a';
  // }
  //
  // extension F on String {
  //   String b() => 'b';
  // }
  //
  // void f() {
  //   F('c').b();
  // }
  // ```
  //
  // If the name of the method and extension are both correct, but the method
  // isn't defined, then define the method:
  //
  // ```dart
  // extension E on String {
  //   String a() => 'a';
  //   String b() => 'z';
  // }
  //
  // extension F on String {
  //   String b() => 'b';
  // }
  //
  // void f() {
  //   E('c').b();
  // }
  // ```
  static const CompileTimeErrorCode UNDEFINED_EXTENSION_METHOD =
      CompileTimeErrorCode(
    'UNDEFINED_EXTENSION_METHOD',
    "The method '{0}' isn't defined for the extension '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing method, or defining a method named '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the operator that is undefined
   * 1: the name of the extension that was explicitly specified
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an operator is invoked on a
  // specific extension when that extension doesn't implement the operator.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the extension `E`
  // doesn't define the operator `*`:
  //
  // ```dart
  // var x = E('') [!*!] 4;
  //
  // extension E on String {}
  // ```
  //
  // #### Common fixes
  //
  // If the extension is expected to implement the operator, then add an
  // implementation of the operator to the extension:
  //
  // ```dart
  // var x = E('') * 4;
  //
  // extension E on String {
  //   int operator *(int multiplier) => length * multiplier;
  // }
  // ```
  //
  // If the operator is defined by a different extension, then change the name
  // of the extension to the name of the one that defines the operator.
  //
  // If the operator is defined on the argument of the extension override, then
  // remove the extension override:
  //
  // ```dart
  // var x = '' * 4;
  //
  // extension E on String {}
  // ```
  static const CompileTimeErrorCode UNDEFINED_EXTENSION_OPERATOR =
      CompileTimeErrorCode(
    'UNDEFINED_EXTENSION_OPERATOR',
    "The operator '{0}' isn't defined for the extension '{1}'.",
    correctionMessage: "Try defining the operator '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the setter that is undefined
   * 1: the name of the extension that was explicitly specified
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an extension override is used to
  // invoke a setter, but the setter isn't defined by the specified extension.
  // The analyzer also produces this diagnostic when a static setter is
  // referenced but isn't defined by the specified extension.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because the extension `E`
  // doesn't declare an instance setter named `b`:
  //
  // ```dart
  // extension E on String {
  //   set a(String v) {}
  // }
  //
  // extension F on String {
  //   set b(String v) {}
  // }
  //
  // void f() {
  //   E('c').[!b!] = 'd';
  // }
  // ```
  //
  // The following code produces this diagnostic because the extension `E`
  // doesn't declare a static setter named `a`:
  //
  // ```dart
  // extension E on String {}
  //
  // void f() {
  //   E.[!a!] = 3;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the name of the setter is incorrect, then change it to the name of an
  // existing setter:
  //
  // ```dart
  // extension E on String {
  //   set a(String v) {}
  // }
  //
  // extension F on String {
  //   set b(String v) {}
  // }
  //
  // void f() {
  //   E('c').a = 'd';
  // }
  // ```
  //
  // If the name of the setter is correct, but the name of the extension is
  // wrong, then change the name of the extension to the correct name:
  //
  // ```dart
  // extension E on String {
  //   set a(String v) {}
  // }
  //
  // extension F on String {
  //   set b(String v) {}
  // }
  //
  // void f() {
  //   F('c').b = 'd';
  // }
  // ```
  //
  // If the name of the setter and extension are both correct, but the setter
  // isn't defined, then define the setter:
  //
  // ```dart
  // extension E on String {
  //   set a(String v) {}
  //   set b(String v) {}
  // }
  //
  // extension F on String {
  //   set b(String v) {}
  // }
  //
  // void f() {
  //   E('c').b = 'd';
  // }
  // ```
  static const CompileTimeErrorCode UNDEFINED_EXTENSION_SETTER =
      CompileTimeErrorCode(
    'UNDEFINED_EXTENSION_SETTER',
    "The setter '{0}' isn't defined for the extension '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing setter, or defining a setter named '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the method that is undefined
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when it encounters an identifier that
  // appears to be the name of a function but either isn't defined or isn't
  // visible in the scope in which it's being referenced.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the name `emty` isn't
  // defined:
  //
  // ```dart
  // List<int> empty() => [];
  //
  // void main() {
  //   print([!emty!]());
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the identifier isn't defined, then either define it or replace it with
  // the name of a function that is defined. The example above can be corrected
  // by fixing the spelling of the function:
  //
  // ```dart
  // List<int> empty() => [];
  //
  // void main() {
  //   print(empty());
  // }
  // ```
  //
  // If the function is defined but isn't visible, then you probably need to add
  // an import or re-arrange your code to make the function visible.
  static const CompileTimeErrorCode UNDEFINED_FUNCTION = CompileTimeErrorCode(
    'UNDEFINED_FUNCTION',
    "The function '{0}' isn't defined.",
    correctionMessage:
        "Try importing the library that defines '{0}', correcting the name to the name of an existing function, or defining a function named '{0}'.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
  );

  /**
   * Parameters:
   * 0: the name of the getter
   * 1: the name of the enclosing type where the getter is being looked for
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when it encounters an identifier that
  // appears to be the name of a getter but either isn't defined or isn't
  // visible in the scope in which it's being referenced.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `String` has no member
  // named `len`:
  //
  // ```dart
  // int f(String s) => s.[!len!];
  // ```
  //
  // #### Common fixes
  //
  // If the identifier isn't defined, then either define it or replace it with
  // the name of a getter that is defined. The example above can be corrected by
  // fixing the spelling of the getter:
  //
  // ```dart
  // int f(String s) => s.length;
  // ```
  static const CompileTimeErrorCode UNDEFINED_GETTER = CompileTimeErrorCode(
    'UNDEFINED_GETTER',
    "The getter '{0}' isn't defined for the type '{1}'.",
    correctionMessage:
        "Try importing the library that defines '{0}', correcting the name to the name of an existing getter, or defining a getter or field named '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the getter
   * 1: the name of the function type alias
   */
  static const CompileTimeErrorCode UNDEFINED_GETTER_ON_FUNCTION_TYPE =
      CompileTimeErrorCode(
    'UNDEFINED_GETTER',
    "The getter '{0}' isn't defined for the '{1}' function type.",
    correctionMessage:
        "Try wrapping the function type alias in parentheses in order to access '{0}' as an extension getter on 'Type'.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_GETTER_ON_FUNCTION_TYPE',
  );

  /**
   * Parameters:
   * 0: the name of the identifier
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when it encounters an identifier that
  // either isn't defined or isn't visible in the scope in which it's being
  // referenced.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the name `rihgt` isn't
  // defined:
  //
  // ```dart
  // int min(int left, int right) => left <= [!rihgt!] ? left : right;
  // ```
  //
  // #### Common fixes
  //
  // If the identifier isn't defined, then either define it or replace it with
  // an identifier that is defined. The example above can be corrected by
  // fixing the spelling of the variable:
  //
  // ```dart
  // int min(int left, int right) => left <= right ? left : right;
  // ```
  //
  // If the identifier is defined but isn't visible, then you probably need to
  // add an import or re-arrange your code to make the identifier visible.
  static const CompileTimeErrorCode UNDEFINED_IDENTIFIER = CompileTimeErrorCode(
    'UNDEFINED_IDENTIFIER',
    "Undefined name '{0}'.",
    correctionMessage:
        "Try correcting the name to one that is defined, or defining the name.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the name `await` is used in a
  // method or function body without being declared, and the body isn't marked
  // with the `async` keyword. The name `await` only introduces an await
  // expression in an asynchronous function.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the name `await` is
  // used in the body of `f` even though the body of `f` isn't marked with the
  // `async` keyword:
  //
  // ```dart
  // void f(p) { [!await!] p; }
  // ```
  //
  // #### Common fixes
  //
  // Add the keyword `async` to the function body:
  //
  // ```dart
  // void f(p) async { await p; }
  // ```
  static const CompileTimeErrorCode UNDEFINED_IDENTIFIER_AWAIT =
      CompileTimeErrorCode(
    'UNDEFINED_IDENTIFIER_AWAIT',
    "Undefined name 'await' in function body not marked with 'async'.",
    correctionMessage:
        "Try correcting the name to one that is defined, defining the name, or adding 'async' to the enclosing function body.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the method that is undefined
   * 1: the resolved type name that the method lookup is happening on
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when it encounters an identifier that
  // appears to be the name of a method but either isn't defined or isn't
  // visible in the scope in which it's being referenced.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the identifier
  // `removeMiddle` isn't defined:
  //
  // ```dart
  // int f(List<int> l) => l.[!removeMiddle!]();
  // ```
  //
  // #### Common fixes
  //
  // If the identifier isn't defined, then either define it or replace it with
  // the name of a method that is defined. The example above can be corrected by
  // fixing the spelling of the method:
  //
  // ```dart
  // int f(List<int> l) => l.removeLast();
  // ```
  static const CompileTimeErrorCode UNDEFINED_METHOD = CompileTimeErrorCode(
    'UNDEFINED_METHOD',
    "The method '{0}' isn't defined for the type '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing method, or defining a method named '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the method
   * 1: the name of the function type alias
   */
  static const CompileTimeErrorCode UNDEFINED_METHOD_ON_FUNCTION_TYPE =
      CompileTimeErrorCode(
    'UNDEFINED_METHOD',
    "The method '{0}' isn't defined for the '{1}' function type.",
    correctionMessage:
        "Try wrapping the function type alias in parentheses in order to access '{0}' as an extension method on 'Type'.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_METHOD_ON_FUNCTION_TYPE',
  );

  /**
   * Parameters:
   * 0: the name of the requested named parameter
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a method or function invocation
  // has a named argument, but the method or function being invoked doesn't
  // define a parameter with the same name.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `m` doesn't declare a
  // named parameter named `a`:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   m({int b}) {}
  // }
  //
  // void f(C c) {
  //   c.m([!a!]: 1);
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the argument name is mistyped, then replace it with the correct name.
  // The example above can be fixed by changing `a` to `b`:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   m({int b}) {}
  // }
  //
  // void f(C c) {
  //   c.m(b: 1);
  // }
  // ```
  //
  // If a subclass adds a parameter with the name in question, then cast the
  // receiver to the subclass:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   m({int b}) {}
  // }
  //
  // class D extends C {
  //   m({int a, int b}) {}
  // }
  //
  // void f(C c) {
  //   (c as D).m(a: 1);
  // }
  // ```
  //
  // If the parameter should be added to the function, then add it:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   m({int a, int b}) {}
  // }
  //
  // void f(C c) {
  //   c.m(a: 1);
  // }
  // ```
  static const CompileTimeErrorCode UNDEFINED_NAMED_PARAMETER =
      CompileTimeErrorCode(
    'UNDEFINED_NAMED_PARAMETER',
    "The named parameter '{0}' isn't defined.",
    correctionMessage:
        "Try correcting the name to an existing named parameter's name, or defining a named parameter with the name '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the operator
   * 1: the name of the enclosing type where the operator is being looked for
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a user-definable operator is
  // invoked on an object for which the operator isn't defined.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the class `C` doesn't
  // define the operator `+`:
  //
  // ```dart
  // class C {}
  //
  // C f(C c) => c [!+!] 2;
  // ```
  //
  // #### Common fixes
  //
  // If the operator should be defined for the class, then define it:
  //
  // ```dart
  // class C {
  //   C operator +(int i) => this;
  // }
  //
  // C f(C c) => c + 2;
  // ```
  static const CompileTimeErrorCode UNDEFINED_OPERATOR = CompileTimeErrorCode(
    'UNDEFINED_OPERATOR',
    "The operator '{0}' isn't defined for the type '{1}'.",
    correctionMessage: "Try defining the operator '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a prefixed identifier is found
  // where the prefix is valid, but the identifier isn't declared in any of the
  // libraries imported using that prefix.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `dart:core` doesn't
  // define anything named `a`:
  //
  // ```dart
  // import 'dart:core' as p;
  //
  // void f() {
  //   p.[!a!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the library in which the name is declared isn't imported yet, add an
  // import for the library.
  //
  // If the name is wrong, then change it to one of the names that's declared in
  // the imported libraries.
  static const CompileTimeErrorCode UNDEFINED_PREFIXED_NAME =
      CompileTimeErrorCode(
    'UNDEFINED_PREFIXED_NAME',
    "The name '{0}' is being referenced through the prefix '{1}', but it isn't defined in any of the libraries imported using that prefix.",
    correctionMessage:
        "Try correcting the prefix or importing the library that defines '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the setter
   * 1: the name of the enclosing type where the setter is being looked for
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when it encounters an identifier that
  // appears to be the name of a setter but either isn't defined or isn't
  // visible in the scope in which the identifier is being referenced.
  //
  // #### Example
  //
  // The following code produces this diagnostic because there isn't a setter
  // named `z`:
  //
  // ```dart
  // class C {
  //   int x = 0;
  //   void m(int y) {
  //     this.[!z!] = y;
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the identifier isn't defined, then either define it or replace it with
  // the name of a setter that is defined. The example above can be corrected by
  // fixing the spelling of the setter:
  //
  // ```dart
  // class C {
  //   int x = 0;
  //   void m(int y) {
  //     this.x = y;
  //   }
  // }
  // ```
  static const CompileTimeErrorCode UNDEFINED_SETTER = CompileTimeErrorCode(
    'UNDEFINED_SETTER',
    "The setter '{0}' isn't defined for the type '{1}'.",
    correctionMessage:
        "Try importing the library that defines '{0}', correcting the name to the name of an existing setter, or defining a setter or field named '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the setter
   * 1: the name of the function type alias
   */
  static const CompileTimeErrorCode UNDEFINED_SETTER_ON_FUNCTION_TYPE =
      CompileTimeErrorCode(
    'UNDEFINED_SETTER',
    "The setter '{0}' isn't defined for the '{1}' function type.",
    correctionMessage:
        "Try wrapping the function type alias in parentheses in order to access '{0}' as an extension getter on 'Type'.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_SETTER_ON_FUNCTION_TYPE',
  );

  /**
   * Parameters:
   * 0: the name of the getter
   * 1: the name of the enclosing type where the getter is being looked for
   */
  static const CompileTimeErrorCode UNDEFINED_SUPER_GETTER =
      CompileTimeErrorCode(
    'UNDEFINED_SUPER_MEMBER',
    "The getter '{0}' isn't defined in a superclass of '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing getter, or defining a getter or field named '{0}' in a superclass.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_SUPER_GETTER',
  );

  /**
   * Parameters:
   * 0: the name of the method that is undefined
   * 1: the resolved type name that the method lookup is happening on
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an inherited member (method,
  // getter, setter, or operator) is referenced using `super`, but there’s no
  // member with that name in the superclass chain.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because `Object` doesn't define
  // a method named `n`:
  //
  // ```dart
  // class C {
  //   void m() {
  //     super.[!n!]();
  //   }
  // }
  // ```
  //
  // The following code produces this diagnostic because `Object` doesn't define
  // a getter named `g`:
  //
  // ```dart
  // class C {
  //   void m() {
  //     super.[!g!];
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the inherited member you intend to invoke has a different name, then
  // make the name of the invoked member match the inherited member.
  //
  // If the member you intend to invoke is defined in the same class, then
  // remove the `super.`.
  //
  // If the member isn’t defined, then either add the member to one of the
  // superclasses or remove the invocation.
  static const CompileTimeErrorCode UNDEFINED_SUPER_METHOD =
      CompileTimeErrorCode(
    'UNDEFINED_SUPER_MEMBER',
    "The method '{0}' isn't defined in a superclass of '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing method, or defining a method named '{0}' in a superclass.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_SUPER_METHOD',
  );

  /**
   * Parameters:
   * 0: the name of the operator
   * 1: the name of the enclosing type where the operator is being looked for
   */
  static const CompileTimeErrorCode UNDEFINED_SUPER_OPERATOR =
      CompileTimeErrorCode(
    'UNDEFINED_SUPER_MEMBER',
    "The operator '{0}' isn't defined in a superclass of '{1}'.",
    correctionMessage: "Try defining the operator '{0}' in a superclass.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_SUPER_OPERATOR',
  );

  /**
   * Parameters:
   * 0: the name of the setter
   * 1: the name of the enclosing type where the setter is being looked for
   */
  static const CompileTimeErrorCode UNDEFINED_SUPER_SETTER =
      CompileTimeErrorCode(
    'UNDEFINED_SUPER_MEMBER',
    "The setter '{0}' isn't defined in a superclass of '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing setter, or defining a setter or field named '{0}' in a superclass.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_SUPER_SETTER',
  );

  /**
   * This is a specialization of [INSTANCE_ACCESS_TO_STATIC_MEMBER] that is used
   * when we are able to find the name defined in a supertype. It exists to
   * provide a more informative error message.
   *
   * Parameters:
   * 0: the name of the defining type
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when code in one class references a
  // static member in a superclass without prefixing the member's name with the
  // name of the superclass. Static members can only be referenced without a
  // prefix in the class in which they're declared.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the static field `x` is
  // referenced in the getter `g` without prefixing it with the name of the
  // defining class:
  //
  // ```dart
  // class A {
  //   static int x = 3;
  // }
  //
  // class B extends A {
  //   int get g => [!x!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // Prefix the name of the static member with the name of the declaring class:
  //
  // ```dart
  // class A {
  //   static int x = 3;
  // }
  //
  // class B extends A {
  //   int get g => A.x;
  // }
  // ```
  static const CompileTimeErrorCode
      UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER = CompileTimeErrorCode(
    'UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER',
    "Static members from supertypes must be qualified by the name of the defining type.",
    correctionMessage: "Try adding '{0}.' before the name.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the defining type
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an undefined name is found, and
  // the name is the same as a static member of the extended type or one of its
  // superclasses.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `m` is a static member
  // of the extended type `C`:
  //
  // ```dart
  // class C {
  //   static void m() {}
  // }
  //
  // extension E on C {
  //   void f() {
  //     [!m!]();
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If you're trying to reference a static member that's declared outside the
  // extension, then add the name of the class or extension before the reference
  // to the member:
  //
  // ```dart
  // class C {
  //   static void m() {}
  // }
  //
  // extension E on C {
  //   void f() {
  //     C.m();
  //   }
  // }
  // ```
  //
  // If you're referencing a member that isn't declared yet, add a declaration:
  //
  // ```dart
  // class C {
  //   static void m() {}
  // }
  //
  // extension E on C {
  //   void f() {
  //     m();
  //   }
  //
  //   void m() {}
  // }
  // ```
  static const CompileTimeErrorCode
      UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE =
      CompileTimeErrorCode(
    'UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE',
    "Static members from the extended type or one of its superclasses must be qualified by the name of the defining type.",
    correctionMessage: "Try adding '{0}.' before the name.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the URI pointing to a non-existent file
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an import, export, or part
  // directive is found where the URI refers to a file that doesn't exist.
  //
  // #### Example
  //
  // If the file `lib.dart` doesn't exist, the following code produces this
  // diagnostic:
  //
  // ```dart
  // import [!'lib.dart'!];
  // ```
  //
  // #### Common fixes
  //
  // If the URI was mistyped or invalid, then correct the URI.
  //
  // If the URI is correct, then create the file.
  static const CompileTimeErrorCode URI_DOES_NOT_EXIST = CompileTimeErrorCode(
    'URI_DOES_NOT_EXIST',
    "Target of URI doesn't exist: '{0}'.",
    correctionMessage:
        "Try creating the file referenced by the URI, or Try using a URI for a file that does exist.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the URI pointing to a non-existent file
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an import, export, or part
  // directive is found where the URI refers to a file that doesn't exist and
  // the name of the file ends with a pattern that's commonly produced by code
  // generators, such as one of the following:
  // - `.g.dart`
  // - `.pb.dart`
  // - `.pbenum.dart`
  // - `.pbserver.dart`
  // - `.pbjson.dart`
  // - `.template.dart`
  //
  // #### Example
  //
  // If the file `lib.g.dart` doesn't exist, the following code produces this
  // diagnostic:
  //
  // ```dart
  // import [!'lib.g.dart'!];
  // ```
  //
  // #### Common fixes
  //
  // If the file is a generated file, then run the generator that generates the
  // file.
  //
  // If the file isn't a generated file, then check the spelling of the URI or
  // create the file.
  static const CompileTimeErrorCode URI_HAS_NOT_BEEN_GENERATED =
      CompileTimeErrorCode(
    'URI_HAS_NOT_BEEN_GENERATED',
    "Target of URI hasn't been generated: '{0}'.",
    correctionMessage:
        "Try running the generator that will generate the file referenced by the URI.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the string literal in an
  // `import`, `export`, or `part` directive contains an interpolation. The
  // resolution of the URIs in directives must happen before the declarations
  // are compiled, so expressions can’t be  evaluated  while determining the
  // values of the URIs.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the string in the
  // `import` directive contains an interpolation:
  //
  // ```dart
  // import [!'dart:$m'!];
  //
  // const m = 'math';
  // ```
  //
  // #### Common fixes
  //
  // Remove the interpolation from the URI:
  //
  // ```dart
  // import 'dart:math';
  //
  // var zero = min(0, 0);
  // ```
  static const CompileTimeErrorCode URI_WITH_INTERPOLATION =
      CompileTimeErrorCode(
    'URI_WITH_INTERPOLATION',
    "URIs can't use string interpolation.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a library is imported using the
  // `dart-ext` scheme.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the native library `x`
  // is being imported using a scheme of `dart-ext`:
  //
  // ```dart
  // import [!'dart-ext:x'!];
  // ```
  //
  // #### Common fixes
  //
  // Rewrite the code to use `dart:ffi` as a way of invoking the contents of the
  // native library.
  static const CompileTimeErrorCode USE_OF_NATIVE_EXTENSION =
      CompileTimeErrorCode(
    'USE_OF_NATIVE_EXTENSION',
    "Dart native extensions are deprecated and aren’t available in Dart 2.15.",
    correctionMessage: "Try using dart:ffi for C interop.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when it finds an expression whose
  // type is `void`, and the expression is used in a place where a value is
  // expected, such as before a member access or on the right-hand side of an
  // assignment.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `f` doesn't produce an
  // object on which `toString` can be invoked:
  //
  // ```dart
  // void f() {}
  //
  // void g() {
  //   [!f()!].toString();
  // }
  // ```
  //
  // #### Common fixes
  //
  // Either rewrite the code so that the expression has a value or rewrite the
  // code so that it doesn't depend on the value.
  static const CompileTimeErrorCode USE_OF_VOID_RESULT = CompileTimeErrorCode(
    'USE_OF_VOID_RESULT',
    "This expression has a type of 'void' so its value can't be used.",
    correctionMessage:
        "Try checking to see if you're using the correct API; there might be a function or call that returns void you didn't expect. Also check type parameters and variables which might also be void.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the type of the object being assigned.
   * 1: the type of the variable being assigned to
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the evaluation of a constant
  // expression would result in a `CastException`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the value of `x` is an
  // `int`, which can't be assigned to `y` because an `int` isn't a `String`:
  //
  // ```dart
  // %language=2.9
  // const Object x = 0;
  // const String y = [!x!];
  // ```
  //
  // #### Common fixes
  //
  // If the declaration of the constant is correct, then change the value being
  // assigned to be of the correct type:
  //
  // ```dart
  // %language=2.9
  // const Object x = 0;
  // const String y = '$x';
  // ```
  //
  // If the assigned value is correct, then change the declaration to have the
  // correct type:
  //
  // ```dart
  // %language=2.9
  // const Object x = 0;
  // const int y = x;
  // ```
  static const CompileTimeErrorCode VARIABLE_TYPE_MISMATCH =
      CompileTimeErrorCode(
    'VARIABLE_TYPE_MISMATCH',
    "A value of type '{0}' can't be assigned to a const variable of type '{1}'.",
    correctionMessage: "Try using a subtype, or removing the 'const' keyword",
    hasPublishedDocs: true,
  );

  /**
   * Let `C` be a generic class that declares a formal type parameter `X`, and
   * assume that `T` is a direct superinterface of `C`.
   *
   * It is a compile-time error if `X` is explicitly defined as a covariant or
   * 'in' type parameter and `X` occurs in a non-covariant position in `T`.
   * It is a compile-time error if `X` is explicitly defined as a contravariant
   * or 'out' type parameter and `X` occurs in a non-contravariant position in
   * `T`.
   *
   * Parameters:
   * 0: the name of the type parameter
   * 1: the variance modifier defined for {0}
   * 2: the variance position of the type parameter {0} in the
   *    superinterface {3}
   * 3: the name of the superinterface
   */
  static const CompileTimeErrorCode
      WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE =
      CompileTimeErrorCode(
    'WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE',
    "'{0}' is an '{1}' type parameter and can't be used in an '{2}' position in '{3}'.",
    correctionMessage:
        "Try using 'in' type parameters in 'in' positions and 'out' type parameters in 'out' positions in the superinterface.",
  );

  /**
   * Parameters:
   * 0: the name of the declared operator
   * 1: the number of parameters expected
   * 2: the number of parameters found in the operator declaration
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a declaration of an operator has
  // the wrong number of parameters.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the operator `+` must
  // have a single parameter corresponding to the right operand:
  //
  // ```dart
  // class C {
  //   int operator [!+!](a, b) => 0;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Add or remove parameters to match the required number:
  //
  // ```dart
  // class C {
  //   int operator +(a) => 0;
  // }
  // ```
  // TODO(brianwilkerson) It would be good to add a link to the spec or some
  //  other documentation that lists the number of parameters for each operator,
  //  but I don't know what to link to.
  static const CompileTimeErrorCode WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR =
      CompileTimeErrorCode(
    'WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR',
    "Operator '{0}' should declare exactly {1} parameters, but {2} found.",
    hasPublishedDocs: true,
  );

  /**
   * 7.1.1 Operators: It is a compile time error if the arity of the
   * user-declared operator - is not 0 or 1.
   *
   * Parameters:
   * 0: the number of parameters found in the operator declaration
   */
  static const CompileTimeErrorCode
      WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS = CompileTimeErrorCode(
    'WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR',
    "Operator '-' should declare 0 or 1 parameter, but {0} found.",
    hasPublishedDocs: true,
    uniqueName: 'WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS',
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a setter is found that doesn't
  // declare exactly one required positional parameter.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because the setter `s` declares
  // two required parameters:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   set [!s!](int x, int y) {}
  // }
  // ```
  //
  // The following code produces this diagnostic because the setter `s` declares
  // one optional parameter:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   set [!s!]([int x]) {}
  // }
  // ```
  //
  // #### Common fixes
  //
  // Change the declaration so that there's exactly one required positional
  // parameter:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   set s(int x) {}
  // }
  // ```
  static const CompileTimeErrorCode WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER =
      CompileTimeErrorCode(
    'WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER',
    "Setters must declare exactly one required positional parameter.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the type being referenced (<i>G</i>)
   * 1: the number of type parameters that were declared
   * 2: the number of type arguments provided
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a type that has type parameters
  // is used and type arguments are provided, but the number of type arguments
  // isn't the same as the number of type parameters.
  //
  // The analyzer also produces this diagnostic when a constructor is invoked
  // and the number of type arguments doesn't match the number of type
  // parameters declared for the class.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because `C` has one type
  // parameter but two type arguments are provided when it is used as a type
  // annotation:
  //
  // ```dart
  // class C<E> {}
  //
  // void f([!C<int, int>!] x) {}
  // ```
  //
  // The following code produces this diagnostic because `C` declares one type
  // parameter, but two type arguments are provided when creating an instance:
  //
  // ```dart
  // class C<E> {}
  //
  // var c = [!C<int, int>!]();
  // ```
  //
  // #### Common fixes
  //
  // Add or remove type arguments, as necessary, to match the number of type
  // parameters defined for the type:
  //
  // ```dart
  // class C<E> {}
  //
  // void f(C<int> x) {}
  // ```
  static const CompileTimeErrorCode WRONG_NUMBER_OF_TYPE_ARGUMENTS =
      CompileTimeErrorCode(
    'WRONG_NUMBER_OF_TYPE_ARGUMENTS',
    "The type '{0}' is declared with {1} type parameters, but {2} type arguments were given.",
    correctionMessage:
        "Try adjusting the number of type arguments to match the number of type parameters.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the number of type parameters that were declared
   * 1: the number of type arguments provided
   */
  static const CompileTimeErrorCode
      WRONG_NUMBER_OF_TYPE_ARGUMENTS_ANONYMOUS_FUNCTION = CompileTimeErrorCode(
    'WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION',
    "This function is declared with {0} type parameters, but {1} type arguments were given.",
    correctionMessage:
        "Try adjusting the number of type arguments to match the number of type parameters.",
    uniqueName: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS_ANONYMOUS_FUNCTION',
  );

  /**
   * Parameters:
   * 0: the name of the class being instantiated
   * 1: the name of the constructor being invoked
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when type arguments are provided
  // after the name of a named constructor. Constructors can't declare type
  // parameters, so invocations can only provide the type arguments associated
  // with the class, and those type arguments are required to follow the name of
  // the class rather than the name of the constructor.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the type parameters
  // (`<String>`) follow the name of the constructor rather than the name of the
  // class:
  //
  // ```dart
  // class C<T> {
  //   C.named();
  // }
  // C f() => C.named[!<String>!]();
  // ```
  //
  // #### Common fixes
  //
  // If the type arguments are for the class' type parameters, then move the
  // type arguments to follow the class name:
  //
  // ```dart
  // class C<T> {
  //   C.named();
  // }
  // C f() => C<String>.named();
  // ```
  //
  // If the type arguments aren't for the class' type parameters, then remove
  // them:
  //
  // ```dart
  // class C<T> {
  //   C.named();
  // }
  // C f() => C.named();
  // ```
  static const CompileTimeErrorCode WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR =
      CompileTimeErrorCode(
    'WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR',
    "The constructor '{0}.{1}' doesn't have type parameters.",
    correctionMessage: "Try moving type arguments to after the type name.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the extension being referenced
   * 1: the number of type parameters that were declared
   * 2: the number of type arguments provided
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an extension that has type
  // parameters is used and type arguments are provided, but the number of type
  // arguments isn't the same as the number of type parameters.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the extension `E` is
  // declared to have a single type parameter (`T`), but the extension override
  // has two type arguments:
  //
  // ```dart
  // extension E<T> on List<T> {
  //   int get len => length;
  // }
  //
  // void f(List<int> p) {
  //   E[!<int, String>!](p).len;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Change the type arguments so that there are the same number of type
  // arguments as there are type parameters:
  //
  // ```dart
  // extension E<T> on List<T> {
  //   int get len => length;
  // }
  //
  // void f(List<int> p) {
  //   E<int>(p).len;
  // }
  // ```
  static const CompileTimeErrorCode WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION =
      CompileTimeErrorCode(
    'WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION',
    "The extension '{0}' is declared with {1} type parameters, but {2} type arguments were given.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the function being referenced
   * 1: the number of type parameters that were declared
   * 2: the number of type arguments provided
   */
  static const CompileTimeErrorCode WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION =
      CompileTimeErrorCode(
    'WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION',
    "The function '{0}' is declared with {1} type parameters, but {2} type arguments were given.",
    correctionMessage:
        "Try adjusting the number of type arguments to match the number of type parameters.",
  );

  /**
   * Parameters:
   * 0: the name of the method being referenced (<i>G</i>)
   * 1: the number of type parameters that were declared
   * 2: the number of type arguments provided
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a method or function is invoked
  // with a different number of type arguments than the number of type
  // parameters specified in its declaration. There must either be no type
  // arguments or the number of arguments must match the number of parameters.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the invocation of the
  // method `m` has two type arguments, but the declaration of `m` only has one
  // type parameter:
  //
  // ```dart
  // class C {
  //   int m<A>(A a) => 0;
  // }
  //
  // int f(C c) => c.m[!<int, int>!](2);
  // ```
  //
  // #### Common fixes
  //
  // If the type arguments are necessary, then make them match the number of
  // type parameters by either adding or removing type arguments:
  //
  // ```dart
  // class C {
  //   int m<A>(A a) => 0;
  // }
  //
  // int f(C c) => c.m<int>(2);
  // ```
  //
  // If the type arguments aren't necessary, then remove them:
  //
  // ```dart
  // class C {
  //   int m<A>(A a) => 0;
  // }
  //
  // int f(C c) => c.m(2);
  // ```
  static const CompileTimeErrorCode WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD =
      CompileTimeErrorCode(
    'WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD',
    "The method '{0}' is declared with {1} type parameters, but {2} type arguments are given.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
  );

  /**
   * Let `C` be a generic class that declares a formal type parameter `X`, and
   * assume that `T` is a direct superinterface of `C`. It is a compile-time
   * error if `X` occurs contravariantly or invariantly in `T`.
   */
  static const CompileTimeErrorCode
      WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE = CompileTimeErrorCode(
    'WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE',
    "'{0}' can't be used contravariantly or invariantly in '{1}'.",
    correctionMessage:
        "Try not using class type parameters in types of formal parameters of function types, nor in explicitly contravariant or invariant superinterfaces.",
  );

  /**
   * Let `C` be a generic class that declares a formal type parameter `X`.
   *
   * If `X` is explicitly contravariant then it is a compile-time error for
   * `X` to occur in a non-contravariant position in a member signature in the
   * body of `C`, except when `X` is in a contravariant position in the type
   * annotation of a covariant formal parameter.
   *
   * If `X` is explicitly covariant then it is a compile-time error for
   * `X` to occur in a non-covariant position in a member signature in the
   * body of `C`, except when `X` is in a covariant position in the type
   * annotation of a covariant formal parameter.
   *
   * Parameters:
   * 0: the variance modifier defined for {0}
   * 1: the name of the type parameter
   * 2: the variance position that the type parameter {1} is in
   */
  static const CompileTimeErrorCode WRONG_TYPE_PARAMETER_VARIANCE_POSITION =
      CompileTimeErrorCode(
    'WRONG_TYPE_PARAMETER_VARIANCE_POSITION',
    "The '{0}' type parameter '{1}' can't be used in an '{2}' position.",
    correctionMessage:
        "Try removing the type parameter or change the explicit variance modifier declaration for the type parameter to another one of 'in', 'out', or 'inout'.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a `yield` or `yield*` statement
  // appears in a function whose body isn't marked with one of the `async*` or
  // `sync*` modifiers.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because `yield` is being used
  // in a function whose body doesn't have a modifier:
  //
  // ```dart
  // Iterable<int> get digits {
  //   yield* [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
  // }
  // ```
  //
  // The following code produces this diagnostic because `yield*` is being used
  // in a function whose body has the `async` modifier rather than the `async*`
  // modifier:
  //
  // ```dart
  // Stream<int> get digits async {
  //   yield* [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
  // }
  // ```
  //
  // #### Common fixes
  //
  // Add a modifier, or change the existing modifier to be either `async*` or
  // `sync*`:
  //
  // ```dart
  // Iterable<int> get digits sync* {
  //   yield* [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
  // }
  // ```
  static const CompileTimeErrorCode YIELD_EACH_IN_NON_GENERATOR =
      CompileTimeErrorCode(
    'YIELD_IN_NON_GENERATOR',
    "Yield-each statements must be in a generator function (one marked with either 'async*' or 'sync*').",
    correctionMessage:
        "Try adding 'async*' or 'sync*' to the enclosing function.",
    hasPublishedDocs: true,
    uniqueName: 'YIELD_EACH_IN_NON_GENERATOR',
  );

  /**
   * Parameters:
   * 0: the type of the expression after `yield*`
   * 1: the return type of the function containing the `yield*`
   */
  static const CompileTimeErrorCode YIELD_EACH_OF_INVALID_TYPE =
      CompileTimeErrorCode(
    'YIELD_OF_INVALID_TYPE',
    "The type '{0}' implied by the 'yield*' expression must be assignable to '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'YIELD_EACH_OF_INVALID_TYPE',
  );

  /**
   * ?? Yield: It is a compile-time error if a yield statement appears in a
   * function that is not a generator function.
   *
   * No parameters.
   */
  static const CompileTimeErrorCode YIELD_IN_NON_GENERATOR =
      CompileTimeErrorCode(
    'YIELD_IN_NON_GENERATOR',
    "Yield statements must be in a generator function (one marked with either 'async*' or 'sync*').",
    correctionMessage:
        "Try adding 'async*' or 'sync*' to the enclosing function.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the type of the expression after `yield`
   * 1: the return type of the function containing the `yield`
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the type of object produced by
  // a `yield` or `yield*` expression doesn't match the type of objects that
  // are to be returned from the `Iterable` or `Stream` types that are returned
  // from a generator (a function or method marked with either `sync*` or
  // `async*`).
  //
  // #### Example
  //
  // The following code produces this diagnostic because the getter `zero` is
  // declared to return an `Iterable` that returns integers, but the `yield` is
  // returning a string from the iterable:
  //
  // ```dart
  // Iterable<int> get zero sync* {
  //   yield [!'0'!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the return type of the function is correct, then fix the expression
  // following the keyword `yield` to return the correct type:
  //
  // ```dart
  // Iterable<int> get zero sync* {
  //   yield 0;
  // }
  // ```
  //
  // If the expression following the `yield` is correct, then change the return
  // type of the function to allow it:
  //
  // ```dart
  // Iterable<String> get zero sync* {
  //   yield '0';
  // }
  // ```
  static const CompileTimeErrorCode YIELD_OF_INVALID_TYPE =
      CompileTimeErrorCode(
    'YIELD_OF_INVALID_TYPE',
    "A yielded value of type '{0}' must be assignable to '{1}'.",
    hasPublishedDocs: true,
  );

  /// Initialize a newly created error code to have the given [name].
  const CompileTimeErrorCode(
    String name,
    String problemMessage, {
    String? correctionMessage,
    bool hasPublishedDocs = false,
    bool isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
          correctionMessage: correctionMessage,
          hasPublishedDocs: hasPublishedDocs,
          isUnresolvedIdentifier: isUnresolvedIdentifier,
          name: name,
          problemMessage: problemMessage,
          uniqueName: 'CompileTimeErrorCode.${uniqueName ?? name}',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorType.COMPILE_TIME_ERROR.severity;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;
}

class LanguageCode extends ErrorCode {
  static const LanguageCode IMPLICIT_DYNAMIC_FIELD = LanguageCode(
    'IMPLICIT_DYNAMIC_FIELD',
    "Missing field type for '{0}'.",
    correctionMessage:
        "Try adding an explicit type, or remove implicit-dynamic from your analysis options file.",
  );

  static const LanguageCode IMPLICIT_DYNAMIC_FUNCTION = LanguageCode(
    'IMPLICIT_DYNAMIC_FUNCTION',
    "Missing type arguments for generic function '{0}<{1}>'.",
    correctionMessage:
        "Try adding an explicit type, or remove implicit-dynamic from your analysis options file.",
  );

  static const LanguageCode IMPLICIT_DYNAMIC_INVOKE = LanguageCode(
    'IMPLICIT_DYNAMIC_INVOKE',
    "Missing type arguments for calling generic function type '{0}'.",
    correctionMessage:
        "Try adding an explicit type, or remove implicit-dynamic from your analysis options file.",
  );

  static const LanguageCode IMPLICIT_DYNAMIC_LIST_LITERAL = LanguageCode(
    'IMPLICIT_DYNAMIC_LIST_LITERAL',
    "Missing type argument for list literal.",
    correctionMessage:
        "Try adding an explicit type, or remove implicit-dynamic from your analysis options file.",
  );

  static const LanguageCode IMPLICIT_DYNAMIC_MAP_LITERAL = LanguageCode(
    'IMPLICIT_DYNAMIC_MAP_LITERAL',
    "Missing type arguments for map literal.",
    correctionMessage:
        "Try adding an explicit type, or remove implicit-dynamic from your analysis options file.",
  );

  static const LanguageCode IMPLICIT_DYNAMIC_METHOD = LanguageCode(
    'IMPLICIT_DYNAMIC_METHOD',
    "Missing type arguments for generic method '{0}<{1}>'.",
    correctionMessage:
        "Try adding an explicit type, or remove implicit-dynamic from your analysis options file.",
  );

  static const LanguageCode IMPLICIT_DYNAMIC_PARAMETER = LanguageCode(
    'IMPLICIT_DYNAMIC_PARAMETER',
    "Missing parameter type for '{0}'.",
    correctionMessage:
        "Try adding an explicit type, or remove implicit-dynamic from your analysis options file.",
  );

  static const LanguageCode IMPLICIT_DYNAMIC_RETURN = LanguageCode(
    'IMPLICIT_DYNAMIC_RETURN',
    "Missing return type for '{0}'.",
    correctionMessage:
        "Try adding an explicit type, or remove implicit-dynamic from your analysis options file.",
  );

  static const LanguageCode IMPLICIT_DYNAMIC_TYPE = LanguageCode(
    'IMPLICIT_DYNAMIC_TYPE',
    "Missing type arguments for generic type '{0}'.",
    correctionMessage:
        "Try adding an explicit type, or remove implicit-dynamic from your analysis options file.",
  );

  static const LanguageCode IMPLICIT_DYNAMIC_VARIABLE = LanguageCode(
    'IMPLICIT_DYNAMIC_VARIABLE',
    "Missing variable type for '{0}'.",
    correctionMessage:
        "Try adding an explicit type, or remove implicit-dynamic from your analysis options file.",
  );

  /// Initialize a newly created error code to have the given [name].
  const LanguageCode(
    String name,
    String problemMessage, {
    String? correctionMessage,
    bool hasPublishedDocs = false,
    bool isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
          correctionMessage: correctionMessage,
          hasPublishedDocs: hasPublishedDocs,
          isUnresolvedIdentifier: isUnresolvedIdentifier,
          name: name,
          problemMessage: problemMessage,
          uniqueName: 'LanguageCode.${uniqueName ?? name}',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorType.COMPILE_TIME_ERROR.severity;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;
}

class StaticWarningCode extends AnalyzerErrorCode {
  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic in two cases.
  //
  // The first is when the left operand of an `??` operator can't be `null`.
  // The right operand is only evaluated if the left operand has the value
  // `null`, and because the left operand can't be `null`, the right operand is
  // never evaluated.
  //
  // The second is when the left-hand side of an assignment using the `??=`
  // operator can't be `null`. The right-hand side is only evaluated if the
  // left-hand side has the value `null`, and because the left-hand side can't
  // be `null`, the right-hand side is never evaluated.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because `x` can't be `null`:
  //
  // ```dart
  // int f(int x) {
  //   return x ?? [!0!];
  // }
  // ```
  //
  // The following code produces this diagnostic because `f` can't be `null`:
  //
  // ```dart
  // class C {
  //   int f = -1;
  //
  //   void m(int x) {
  //     f ??= [!x!];
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the diagnostic is reported for an `??` operator, then remove the `??`
  // operator and the right operand:
  //
  // ```dart
  // int f(int x) {
  //   return x;
  // }
  // ```
  //
  // If the diagnostic is reported for an assignment, and the assignment isn't
  // needed, then remove the assignment:
  //
  // ```dart
  // class C {
  //   int f = -1;
  //
  //   void m(int x) {
  //   }
  // }
  // ```
  //
  // If the assignment is needed, but should be based on a different condition,
  // then rewrite the code to use `=` and the different condition:
  //
  // ```dart
  // class C {
  //   int f = -1;
  //
  //   void m(int x) {
  //     if (f < 0) {
  //       f = x;
  //     }
  //   }
  // }
  // ```
  static const StaticWarningCode DEAD_NULL_AWARE_EXPRESSION = StaticWarningCode(
    'DEAD_NULL_AWARE_EXPRESSION',
    "The left operand can't be null, so the right operand is never executed.",
    correctionMessage: "Try removing the operator and the right operand.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the null-aware operator that is invalid
   * 1: the non-null-aware operator that can replace the invalid operator
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a null-aware operator (`?.`,
  // `?..`, `?[`, `?..[`, or `...?`) is used on a receiver that's known to be
  // non-nullable.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because `s` can't be `null`:
  //
  // ```dart
  // int? getLength(String s) {
  //   return s[!?.!]length;
  // }
  // ```
  //
  // The following code produces this diagnostic because `a` can't be `null`:
  //
  // ```dart
  // var a = [];
  // var b = [[!...?!]a];
  // ```
  //
  // The following code produces this diagnostic because `s?.length` can't
  // return `null`:
  //
  // ```dart
  // void f(String? s) {
  //   s?.length[!?.!]isEven;
  // }
  // ```
  //
  // The reason `s?.length` can't return `null` is because the null-aware
  // operator following `s` short-circuits the evaluation of both `length` and
  // `isEven` if `s` is `null`. In other words, if `s` is `null`, then neither
  // `length` nor `isEven` will be invoked, and if `s` is non-`null`, then
  // `length` can't return a `null` value. Either way, `isEven` can't be invoked
  // on a `null` value, so the null-aware operator isn't necessary. See
  // [Understanding null safety](/null-safety/understanding-null-safety#smarter-null-aware-methods)
  // for more details.
  //
  // The following code produces this diagnostic because `s` can't be `null`.
  //
  // ```dart
  // void f(Object? o) {
  //   var s = o as String;
  //   s[!?.!]length;
  // }
  // ```
  //
  // The reason `s` can't be null, despite the fact that `o` can be `null`, is
  // because of the cast to `String`, which is a non-nullable type. If `o` ever
  // has the value `null`, the cast will fail and the invocation of `length`
  // will not happen.
  //
  // #### Common fixes
  //
  // Replace the null-aware operator with a non-null-aware equivalent; for
  // example, change `?.` to  `.`:
  //
  // ```dart
  // int getLength(String s) {
  //   return s.length;
  // }
  // ```
  //
  // (Note that the return type was also changed to be non-nullable, which might
  // not be appropriate in some cases.)
  static const StaticWarningCode INVALID_NULL_AWARE_OPERATOR =
      StaticWarningCode(
    'INVALID_NULL_AWARE_OPERATOR',
    "The receiver can't be null, so the null-aware operator '{0}' is unnecessary.",
    correctionMessage: "Try replacing the operator '{0}' with '{1}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the null-aware operator that is invalid
   * 1: the non-null-aware operator that can replace the invalid operator
   */
  static const StaticWarningCode
      INVALID_NULL_AWARE_OPERATOR_AFTER_SHORT_CIRCUIT = StaticWarningCode(
    'INVALID_NULL_AWARE_OPERATOR',
    "The receiver can't be null because of short-circuiting, so the null-aware operator '{0}' can't be used.",
    correctionMessage: "Try replacing the operator '{0}' with '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_NULL_AWARE_OPERATOR_AFTER_SHORT_CIRCUIT',
  );

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method
   * <i>m1</i> overrides an instance member <i>m2</i>, the signature of
   * <i>m2</i> explicitly specifies a default value for a formal parameter
   * <i>p</i> and the signature of <i>m1</i> specifies a different default value
   * for <i>p</i>.
   */
  static const StaticWarningCode
      INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED = StaticWarningCode(
    'INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED',
    "Parameters can't override default values, this method overrides '{0}.{1}' where '{2}' has a different value.",
    correctionMessage: "Try using the same default value in both methods.",
  );

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method
   * <i>m1</i> overrides an instance member <i>m2</i>, the signature of
   * <i>m2</i> explicitly specifies a default value for a formal parameter
   * <i>p</i> and the signature of <i>m1</i> specifies a different default value
   * for <i>p</i>.
   */
  static const StaticWarningCode
      INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL = StaticWarningCode(
    'INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL',
    "Parameters can't override default values, this method overrides '{0}.{1}' where this positional parameter has a different value.",
    correctionMessage: "Try using the same default value in both methods.",
  );

  /**
   * Parameters:
   * 0: the name of the constant that is missing
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a `switch` statement for an enum
  // doesn't include an option for one of the values in the enumeration.
  //
  // Note that `null` is always a possible value for an enum and therefore also
  // must be handled.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the enum constant `e2`
  // isn't handled:
  //
  // ```dart
  // enum E { e1, e2 }
  //
  // void f(E e) {
  //   [!switch (e)!] {
  //     case E.e1:
  //       break;
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If there's special handling for the missing values, then add a `case`
  // clause for each of the missing values:
  //
  // ```dart
  // enum E { e1, e2 }
  //
  // void f(E e) {
  //   switch (e) {
  //     case E.e1:
  //       break;
  //     case E.e2:
  //       break;
  //   }
  // }
  // ```
  //
  // If the missing values should be handled the same way, then add a `default`
  // clause:
  //
  // ```dart
  // enum E { e1, e2 }
  //
  // void f(E e) {
  //   switch (e) {
  //     case E.e1:
  //       break;
  //     default:
  //       break;
  //   }
  // }
  // ```
  // TODO(brianwilkerson) This documentation will need to be updated when NNBD
  //  ships.
  static const StaticWarningCode MISSING_ENUM_CONSTANT_IN_SWITCH =
      StaticWarningCode(
    'MISSING_ENUM_CONSTANT_IN_SWITCH',
    "Missing case clause for '{0}'.",
    correctionMessage:
        "Try adding a case clause for the missing constant, or adding a default clause.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the operand of the `!` operator
  // can't be `null`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `x` can't be `null`:
  //
  // ```dart
  // int f(int x) {
  //   return x[!!!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the null check operator (`!`):
  //
  // ```dart
  // int f(int x) {
  //   return x;
  // }
  // ```
  static const StaticWarningCode UNNECESSARY_NON_NULL_ASSERTION =
      StaticWarningCode(
    'UNNECESSARY_NON_NULL_ASSERTION',
    "The '!' will have no effect because the receiver can't be null.",
    correctionMessage: "Try removing the '!' operator.",
    hasPublishedDocs: true,
  );

  /// Initialize a newly created error code to have the given [name].
  const StaticWarningCode(
    String name,
    String problemMessage, {
    String? correctionMessage,
    bool hasPublishedDocs = false,
    bool isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
          correctionMessage: correctionMessage,
          hasPublishedDocs: hasPublishedDocs,
          isUnresolvedIdentifier: isUnresolvedIdentifier,
          name: name,
          problemMessage: problemMessage,
          uniqueName: 'StaticWarningCode.${uniqueName ?? name}',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.WARNING;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;
}
