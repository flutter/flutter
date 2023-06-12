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

class HintCode extends AnalyzerErrorCode {
  /**
   * Parameters:
   * 0: the name of the actual argument type
   * 1: the name of the expected function return type
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an invocation of
  // `Future.catchError` has an argument that is a function whose parameters
  // aren't compatible with the arguments that will be passed to the function
  // when it's invoked. The static type of the first argument to `catchError`
  // is just `Function`, even though the function that is passed in is expected
  // to have either a single parameter of type `Object` or two parameters of
  // type `Object` and `StackTrace`.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because the closure being
  // passed to `catchError` doesn't take any parameters, but the function is
  // required to take at least one parameter:
  //
  // ```dart
  // void f(Future<int> f) {
  //   f.catchError([!() => 0!]);
  // }
  // ```
  //
  // The following code produces this diagnostic because the closure being
  // passed to `catchError` takes three parameters, but it can't have more than
  // two required parameters:
  //
  // ```dart
  // void f(Future<int> f) {
  //   f.catchError([!(one, two, three) => 0!]);
  // }
  // ```
  //
  // The following code produces this diagnostic because even though the closure
  // being passed to `catchError` takes one parameter, the closure doesn't have
  // a type that is compatible with `Object`:
  //
  // ```dart
  // void f(Future<int> f) {
  //   f.catchError([!(String error) => 0!]);
  // }
  // ```
  //
  // #### Common fixes
  //
  // Change the function being passed to `catchError` so that it has either one
  // or two required parameters, and the parameters have the required types:
  //
  // ```dart
  // void f(Future<int> f) {
  //   f.catchError((Object error) => 0);
  // }
  // ```
  static const HintCode ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER =
      HintCode(
    'ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER',
    "The argument type '{0}' can't be assigned to the parameter type '{1} Function(Object)' or '{1} Function(Object, StackTrace)'.",
    hasPublishedDocs: true,
  );

  /**
   * Users should not assign values marked `@doNotStore`.
   */
  static const HintCode ASSIGNMENT_OF_DO_NOT_STORE = HintCode(
    'ASSIGNMENT_OF_DO_NOT_STORE',
    "'{0}' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.",
    correctionMessage: "Try removing the assignment.",
  );

  /**
   * When the target expression uses '?.' operator, it can be `null`, so all the
   * subsequent invocations should also use '?.' operator.
   */
  static const HintCode CAN_BE_NULL_AFTER_NULL_AWARE = HintCode(
    'CAN_BE_NULL_AFTER_NULL_AWARE',
    "The receiver uses '?.', so its value can be null.",
    correctionMessage: "Replace the '.' with a '?.' in the invocation.",
  );

  /**
   * Dead code is code that is never reached, this can happen for instance if a
   * statement follows a return statement.
   *
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when code is found that won't be
  // executed because execution will never reach the code.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the invocation of
  // `print` occurs after the function has returned:
  //
  // ```dart
  // void f() {
  //   return;
  //   [!print('here');!]
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the code isn't needed, then remove it:
  //
  // ```dart
  // void f() {
  //   return;
  // }
  // ```
  //
  // If the code needs to be executed, then either move the code to a place
  // where it will be executed:
  //
  // ```dart
  // void f() {
  //   print('here');
  //   return;
  // }
  // ```
  //
  // Or, rewrite the code before it, so that it can be reached:
  //
  // ```dart
  // void f({bool skipPrinting = true}) {
  //   if (skipPrinting) {
  //     return;
  //   }
  //   print('here');
  // }
  // ```
  static const HintCode DEAD_CODE = HintCode(
    'DEAD_CODE',
    "Dead code.",
    correctionMessage:
        "Try removing the code, or fixing the code before it so that it can be reached.",
    hasPublishedDocs: true,
  );

  /**
   * Dead code is code that is never reached. This case covers cases where the
   * user has catch clauses after `catch (e)` or `on Object catch (e)`.
   *
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a `catch` clause is found that
  // can't be executed because it’s after a `catch` clause of the form
  // `catch (e)` or `on Object catch (e)`. The first `catch` clause that matches
  // the thrown object is selected, and both of those forms will match any
  // object, so no `catch` clauses that follow them will be selected.
  //
  // #### Example
  //
  // The following code produces this diagnostic:
  //
  // ```dart
  // void f() {
  //   try {
  //   } catch (e) {
  //   } [!on String {
  //   }!]
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the clause should be selectable, then move the clause before the general
  // clause:
  //
  // ```dart
  // void f() {
  //   try {
  //   } on String {
  //   } catch (e) {
  //   }
  // }
  // ```
  //
  // If the clause doesn't need to be selectable, then remove it:
  //
  // ```dart
  // void f() {
  //   try {
  //   } catch (e) {
  //   }
  // }
  // ```
  static const HintCode DEAD_CODE_CATCH_FOLLOWING_CATCH = HintCode(
    'DEAD_CODE_CATCH_FOLLOWING_CATCH',
    "Dead code: Catch clauses after a 'catch (e)' or an 'on Object catch (e)' are never reached.",
    correctionMessage:
        "Try reordering the catch clauses so that they can be reached, or removing the unreachable catch clauses.",
    hasPublishedDocs: true,
  );

  /**
   * Dead code is code that is never reached. This case covers cases where the
   * user has an on-catch clause such as `on A catch (e)`, where a supertype of
   * `A` was already caught.
   *
   * Parameters:
   * 0: name of the subtype
   * 1: name of the supertype
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a `catch` clause is found that
  // can't be executed because it is after a `catch` clause that catches either
  // the same type or a supertype of the clause's type. The first `catch` clause
  // that matches the thrown object is selected, and the earlier clause always
  // matches anything matchable by the highlighted clause, so the highlighted
  // clause will never be selected.
  //
  // #### Example
  //
  // The following code produces this diagnostic:
  //
  // ```dart
  // void f() {
  //   try {
  //   } on num {
  //   } [!on int {
  //   }!]
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the clause should be selectable, then move the clause before the general
  // clause:
  //
  // ```dart
  // void f() {
  //   try {
  //   } on int {
  //   } on num {
  //   }
  // }
  // ```
  //
  // If the clause doesn't need to be selectable, then remove it:
  //
  // ```dart
  // void f() {
  //   try {
  //   } on num {
  //   }
  // }
  // ```
  static const HintCode DEAD_CODE_ON_CATCH_SUBTYPE = HintCode(
    'DEAD_CODE_ON_CATCH_SUBTYPE',
    "Dead code: This on-catch block won’t be executed because '{0}' is a subtype of '{1}' and hence will have been caught already.",
    correctionMessage:
        "Try reordering the catch clauses so that this block can be reached, or removing the unreachable catch clause.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the class `Function` is used in
  // either the `extends`, `implements`, or `with` clause of a class or mixin.
  // Using the class `Function` in this way has no semantic value, so it's
  // effectively dead code.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `Function` is used as
  // the superclass of `F`:
  //
  // ```dart
  // class F extends [!Function!] {}
  // ```
  //
  // #### Common fixes
  //
  // Remove the class `Function` from whichever clause it's in, and remove the
  // whole clause if `Function` is the only type in the clause:
  //
  // ```dart
  // class F {}
  // ```
  static const HintCode DEPRECATED_EXTENDS_FUNCTION = HintCode(
    'DEPRECATED_SUBTYPE_OF_FUNCTION',
    "Extending 'Function' is deprecated.",
    correctionMessage: "Try removing 'Function' from the 'extends' clause.",
    hasPublishedDocs: true,
    uniqueName: 'DEPRECATED_EXTENDS_FUNCTION',
  );

  /**
   * Users should not create a class named `Function` anymore.
   */
  static const HintCode DEPRECATED_FUNCTION_CLASS_DECLARATION = HintCode(
    'DEPRECATED_FUNCTION_CLASS_DECLARATION',
    "Declaring a class named 'Function' is deprecated.",
    correctionMessage: "Try renaming the class.",
  );

  /**
   * No parameters.
   */
  static const HintCode DEPRECATED_IMPLEMENTS_FUNCTION = HintCode(
    'DEPRECATED_SUBTYPE_OF_FUNCTION',
    "Implementing 'Function' has no effect.",
    correctionMessage: "Try removing 'Function' from the 'implements' clause.",
    hasPublishedDocs: true,
    uniqueName: 'DEPRECATED_IMPLEMENTS_FUNCTION',
  );

  /**
   * Parameters:
   * 0: the name of the member
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a deprecated library or class
  // member is used in a different package.
  //
  // #### Example
  //
  // If the method `m` in the class `C` is annotated with `@deprecated`, then
  // the following code produces this diagnostic:
  //
  // ```dart
  // void f(C c) {
  //   c.[!m!]();
  // }
  // ```
  //
  // #### Common fixes
  //
  // The documentation for declarations that are annotated with `@deprecated`
  // should indicate what code to use in place of the deprecated code.
  static const HintCode DEPRECATED_MEMBER_USE = HintCode(
    'DEPRECATED_MEMBER_USE',
    "'{0}' is deprecated and shouldn't be used.",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the member
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a deprecated library member or
  // class member is used in the same package in which it's declared.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `x` is deprecated:
  //
  // ```dart
  // @deprecated
  // var x = 0;
  // var y = [!x!];
  // ```
  //
  // #### Common fixes
  //
  // The fix depends on what's been deprecated and what the replacement is. The
  // documentation for deprecated declarations should indicate what code to use
  // in place of the deprecated code.
  static const HintCode DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE = HintCode(
    'DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE',
    "'{0}' is deprecated and shouldn't be used.",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the member
   * 1: message details
   */
  static const HintCode DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE =
      HintCode(
    'DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE',
    "'{0}' is deprecated and shouldn't be used. {1}.",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
    uniqueName: 'DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE',
  );

  /**
   * Parameters:
   * 0: the name of the member
   * 1: message details
   */
  static const HintCode DEPRECATED_MEMBER_USE_WITH_MESSAGE = HintCode(
    'DEPRECATED_MEMBER_USE',
    "'{0}' is deprecated and shouldn't be used. {1}.",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
    uniqueName: 'DEPRECATED_MEMBER_USE_WITH_MESSAGE',
  );

  /**
   * No parameters.
   */
  static const HintCode DEPRECATED_MIXIN_FUNCTION = HintCode(
    'DEPRECATED_SUBTYPE_OF_FUNCTION',
    "Mixing in 'Function' is deprecated.",
    correctionMessage: "Try removing 'Function' from the 'with' clause.",
    hasPublishedDocs: true,
    uniqueName: 'DEPRECATED_MIXIN_FUNCTION',
  );

  /**
   * No parameters.
   */
  static const HintCode DEPRECATED_NEW_IN_COMMENT_REFERENCE = HintCode(
    'DEPRECATED_NEW_IN_COMMENT_REFERENCE',
    "Using the 'new' keyword in a comment reference is deprecated.",
    correctionMessage: "Try referring to a constructor by its name.",
  );

  /**
   * Hint to use the ~/ operator.
   */
  static const HintCode DIVISION_OPTIMIZATION = HintCode(
    'DIVISION_OPTIMIZATION',
    "The operator x ~/ y is more efficient than (x / y).toInt().",
    correctionMessage:
        "Try re-writing the expression to use the '~/' operator.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a name occurs multiple times in
  // a `hide` clause. Repeating the name is unnecessary.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the name `min` is
  // hidden more than once:
  //
  // ```dart
  // import 'dart:math' hide min, [!min!];
  //
  // var x = pi;
  // ```
  //
  // #### Common fixes
  //
  // If the name was mistyped in one or more places, then correct the mistyped
  // names:
  //
  // ```dart
  // import 'dart:math' hide max, min;
  //
  // var x = pi;
  // ```
  //
  // If the name wasn't mistyped, then remove the unnecessary name from the
  // list:
  //
  // ```dart
  // import 'dart:math' hide min;
  //
  // var x = pi;
  // ```
  static const HintCode DUPLICATE_HIDDEN_NAME = HintCode(
    'DUPLICATE_HIDDEN_NAME',
    "Duplicate hidden name.",
    correctionMessage:
        "Try removing the repeated name from the list of hidden members.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the diagnostic being ignored
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a diagnostic name appears in an
  // `ignore` comment, but the diagnostic is already being ignored, either
  // because it's already included in the same `ignore` comment or because it
  // appears in an `ignore-in-file` comment.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because the diagnostic named
  // `unused_local_variable` is already being ignored for the whole file so it
  // doesn't need to be ignored on a specific line:
  //
  // ```dart
  // // ignore_for_file: unused_local_variable
  // void f() {
  //   // ignore: [!unused_local_variable!]
  //   var x = 0;
  // }
  // ```
  //
  // The following code produces this diagnostic because the diagnostic named
  // `unused_local_variable` is being ignored twice on the same line:
  //
  // ```dart
  // void f() {
  //   // ignore: unused_local_variable, [!unused_local_variable!]
  //   var x = 0;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the ignore comment, or remove the unnecessary diagnostic name if the
  // ignore comment is ignoring more than one diagnostic:
  //
  // ```dart
  // // ignore_for_file: unused_local_variable
  // void f() {
  //   var x = 0;
  // }
  // ```
  static const HintCode DUPLICATE_IGNORE = HintCode(
    'DUPLICATE_IGNORE',
    "The diagnostic '{0}' doesn't need to be ignored here because it's already being ignored.",
    correctionMessage:
        "Try removing the name from the list, or removing the whole comment if this is the only name in the list.",
    hasPublishedDocs: true,
  );

  /**
   * Duplicate imports.
   *
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an import directive is found
  // that is the same as an import before it in the file. The second import
  // doesn’t add value and should be removed.
  //
  // #### Example
  //
  // The following code produces this diagnostic:
  //
  // ```dart
  // import 'package:meta/meta.dart';
  // import [!'package:meta/meta.dart'!];
  //
  // @sealed class C {}
  // ```
  //
  // #### Common fixes
  //
  // Remove the unnecessary import:
  //
  // ```dart
  // import 'package:meta/meta.dart';
  //
  // @sealed class C {}
  // ```
  static const HintCode DUPLICATE_IMPORT = HintCode(
    'DUPLICATE_IMPORT',
    "Duplicate import.",
    correctionMessage: "Try removing all but one import of the library.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a name occurs multiple times in
  // a `show` clause. Repeating the name is unnecessary.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the name `min` is shown
  // more than once:
  //
  // ```dart
  // import 'dart:math' show min, [!min!];
  //
  // var x = min(2, min(0, 1));
  // ```
  //
  // #### Common fixes
  //
  // If the name was mistyped in one or more places, then correct the mistyped
  // names:
  //
  // ```dart
  // import 'dart:math' show max, min;
  //
  // var x = max(2, min(0, 1));
  // ```
  //
  // If the name wasn't mistyped, then remove the unnecessary name from the
  // list:
  //
  // ```dart
  // import 'dart:math' show min;
  //
  // var x = min(2, min(0, 1));
  // ```
  static const HintCode DUPLICATE_SHOWN_NAME = HintCode(
    'DUPLICATE_SHOWN_NAME',
    "Duplicate shown name.",
    correctionMessage:
        "Try removing the repeated name from the list of shown members.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an element in a non-constant set
  // is the same as a previous element in the same set. If two elements are the
  // same, then the second value is ignored, which makes having both elements
  // pointless and likely signals a bug.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the element `1` appears
  // twice:
  //
  // ```dart
  // const a = 1;
  // const b = 1;
  // var s = <int>{a, [!b!]};
  // ```
  //
  // #### Common fixes
  //
  // If both elements should be included in the set, then change one of the
  // elements:
  //
  // ```dart
  // const a = 1;
  // const b = 2;
  // var s = <int>{a, b};
  // ```
  //
  // If only one of the elements is needed, then remove the one that isn't
  // needed:
  //
  // ```dart
  // const a = 1;
  // var s = <int>{a};
  // ```
  //
  // Note that literal sets preserve the order of their elements, so the choice
  // of which element to remove might affect the order in which elements are
  // returned by an iterator.
  static const HintCode EQUAL_ELEMENTS_IN_SET = HintCode(
    'EQUAL_ELEMENTS_IN_SET',
    "Two elements in a set literal shouldn't be equal.",
    correctionMessage: "Change or remove the duplicate element.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a key in a non-constant map is
  // the same as a previous key in the same map. If two keys are the same, then
  // the second value overwrites the first value, which makes having both pairs
  // pointless and likely signals a bug.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the keys `a` and `b`
  // have the same value:
  //
  // ```dart
  // const a = 1;
  // const b = 1;
  // var m = <int, String>{a: 'a', [!b!]: 'b'};
  // ```
  //
  // #### Common fixes
  //
  // If both entries should be included in the map, then change one of the keys:
  //
  // ```dart
  // const a = 1;
  // const b = 2;
  // var m = <int, String>{a: 'a', b: 'b'};
  // ```
  //
  // If only one of the entries is needed, then remove the one that isn't
  // needed:
  //
  // ```dart
  // const a = 1;
  // var m = <int, String>{a: 'a'};
  // ```
  //
  // Note that literal maps preserve the order of their entries, so the choice
  // of which entry to remove might affect the order in which the keys and
  // values are returned by an iterator.
  static const HintCode EQUAL_KEYS_IN_MAP = HintCode(
    'EQUAL_KEYS_IN_MAP',
    "Two keys in a map literal shouldn't be equal.",
    correctionMessage: "Change or remove the duplicate key.",
    hasPublishedDocs: true,
  );

  /**
   * It is a bad practice for a source file in a package "lib" directory
   * hierarchy to traverse outside that directory hierarchy. For example, a
   * source file in the "lib" directory should not contain a directive such as
   * `import '../web/some.dart'` which references a file outside the lib
   * directory.
   */
  static const HintCode FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE =
      HintCode(
    'FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE',
    "A file in the 'lib' directory shouldn't import a file outside the 'lib' directory.",
    correctionMessage:
        "Try removing the import, or moving the imported file inside the 'lib' directory.",
  );

  /**
   * It is a bad practice for a source file ouside a package "lib" directory
   * hierarchy to traverse into that directory hierarchy. For example, a source
   * file in the "web" directory should not contain a directive such as
   * `import '../lib/some.dart'` which references a file inside the lib
   * directory.
   */
  static const HintCode FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE =
      HintCode(
    'FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE',
    "A file outside the 'lib' directory shouldn't reference a file inside the 'lib' directory using a relative path.",
    correctionMessage: "Try using a package: URI instead.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a library that declares a
  // function named `loadLibrary` is imported using a deferred import. A
  // deferred import introduces an implicit function named `loadLibrary`. This
  // function is used to load the contents of the deferred library, and the
  // implicit function hides the explicit declaration in the deferred library.
  //
  // For more information, see the language tour's coverage of
  // [deferred loading](https://dart.dev/guides/language/language-tour#lazily-loading-a-library).
  //
  // #### Example
  //
  // Given a file (`a.dart`) that defines a function named `loadLibrary`:
  //
  // ```dart
  // %uri="lib/a.dart"
  // void loadLibrary(Library library) {}
  //
  // class Library {}
  // ```
  //
  // The following code produces this diagnostic because the implicit
  // declaration of `a.loadLibrary` is hiding the explicit declaration of
  // `loadLibrary` in `a.dart`:
  //
  // ```dart
  // [!import 'a.dart' deferred as a;!]
  //
  // void f() {
  //   a.Library();
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the imported library isn't required to be deferred, then remove the
  // keyword `deferred`:
  //
  // ```dart
  // import 'a.dart' as a;
  //
  // void f() {
  //   a.Library();
  // }
  // ```
  //
  // If the imported library is required to be deferred and you need to
  // reference the imported function, then rename the function in the imported
  // library:
  //
  // ```dart
  // void populateLibrary(Library library) {}
  //
  // class Library {}
  // ```
  //
  // If the imported library is required to be deferred and you don't need to
  // reference the imported function, then add a `hide` clause:
  //
  // ```dart
  // import 'a.dart' deferred as a hide loadLibrary;
  //
  // void f() {
  //   a.Library();
  // }
  // ```
  //
  // If type arguments shouldn't be required for the class, then mark the class
  // with the `@optionalTypeArgs` annotation (from `package:meta`):
  static const HintCode IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION = HintCode(
    'IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION',
    "The imported library defines a top-level function named 'loadLibrary' that is hidden by deferring this library.",
    correctionMessage:
        "Try changing the import to not be deferred, or rename the function in the imported library.",
    hasPublishedDocs: true,
  );

  /**
   * https://github.com/dart-lang/sdk/issues/44063
   */
  static const HintCode IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE = HintCode(
    'IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE',
    "The library '{0}' is legacy, and should not be imported into a null safe library.",
    correctionMessage: "Try migrating the imported library.",
  );

  /**
   * When "strict-inference" is enabled, collection literal types must be
   * inferred via the context type, or have type arguments.
   */
  static const HintCode INFERENCE_FAILURE_ON_COLLECTION_LITERAL = HintCode(
    'INFERENCE_FAILURE_ON_COLLECTION_LITERAL',
    "The type argument(s) of '{0}' can't be inferred.",
    correctionMessage: "Use explicit type argument(s) for '{0}'.",
  );

  /**
   * When "strict-inference" is enabled, types in function invocations must be
   * inferred via the context type, or have type arguments.
   */
  static const HintCode INFERENCE_FAILURE_ON_FUNCTION_INVOCATION = HintCode(
    'INFERENCE_FAILURE_ON_FUNCTION_INVOCATION',
    "The type argument(s) of the function '{0}' can't be inferred.",
    correctionMessage: "Use explicit type argument(s) for '{0}'.",
  );

  /**
   * When "strict-inference" is enabled, recursive local functions, top-level
   * functions, methods, and function-typed function parameters must all
   * specify a return type. See the strict-inference resource:
   *
   * https://github.com/dart-lang/language/blob/master/resources/type-system/strict-inference.md
   */
  static const HintCode INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE = HintCode(
    'INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE',
    "The return type of '{0}' cannot be inferred.",
    correctionMessage: "Declare the return type of '{0}'.",
  );

  /**
   * When "strict-inference" is enabled, types in function invocations must be
   * inferred via the context type, or have type arguments.
   */
  static const HintCode INFERENCE_FAILURE_ON_GENERIC_INVOCATION = HintCode(
    'INFERENCE_FAILURE_ON_GENERIC_INVOCATION',
    "The type argument(s) of the generic function type '{0}' can't be inferred.",
    correctionMessage: "Use explicit type argument(s) for '{0}'.",
  );

  /**
   * When "strict-inference" is enabled, types in instance creation
   * (constructor calls) must be inferred via the context type, or have type
   * arguments.
   */
  static const HintCode INFERENCE_FAILURE_ON_INSTANCE_CREATION = HintCode(
    'INFERENCE_FAILURE_ON_INSTANCE_CREATION',
    "The type argument(s) of the constructor '{0}' can't be inferred.",
    correctionMessage: "Use explicit type argument(s) for '{0}'.",
  );

  /**
   * When "strict-inference" in enabled, uninitialized variables must be
   * declared with a specific type.
   */
  static const HintCode INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE = HintCode(
    'INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE',
    "The type of {0} can't be inferred without either a type or initializer.",
    correctionMessage: "Try specifying the type of the variable.",
  );

  /**
   * When "strict-inference" in enabled, function parameters must be
   * declared with a specific type, or inherit a type.
   */
  static const HintCode INFERENCE_FAILURE_ON_UNTYPED_PARAMETER = HintCode(
    'INFERENCE_FAILURE_ON_UNTYPED_PARAMETER',
    "The type of {0} can't be inferred; a type must be explicitly provided.",
    correctionMessage: "Try specifying the type of the parameter.",
  );

  /**
   * Parameters:
   * 0: the name of the annotation
   * 1: the list of valid targets
   */
  static const HintCode INVALID_ANNOTATION_TARGET = HintCode(
    'INVALID_ANNOTATION_TARGET',
    "The annotation '{0}' can only be used on {1}",
  );

  /**
   * This hint is generated anywhere where an element annotated with `@internal`
   * is exported as a part of a package's public API.
   *
   * Parameters:
   * 0: the name of the element
   */
  static const HintCode INVALID_EXPORT_OF_INTERNAL_ELEMENT = HintCode(
    'INVALID_EXPORT_OF_INTERNAL_ELEMENT',
    "The member '{0}' can't be exported as a part of a package's public API.",
    correctionMessage: "Try using a hide clause to hide '{0}'.",
  );

  /**
   * This hint is generated anywhere where an element annotated with `@internal`
   * is exported indirectly as a part of a package's public API.
   *
   * Parameters:
   * 0: the name of the element
   */
  static const HintCode INVALID_EXPORT_OF_INTERNAL_ELEMENT_INDIRECTLY =
      HintCode(
    'INVALID_EXPORT_OF_INTERNAL_ELEMENT_INDIRECTLY',
    "The member '{0}' can't be exported as a part of a package's public API, but is indirectly exported as part of the signature of '{1}'.",
    correctionMessage: "Try using a hide clause to hide '{0}'.",
  );

  /**
   * This hint is generated anywhere a @factory annotation is associated with
   * anything other than a method.
   */
  static const HintCode INVALID_FACTORY_ANNOTATION = HintCode(
    'INVALID_FACTORY_ANNOTATION',
    "Only methods can be annotated as factories.",
  );

  /**
   * This hint is generated anywhere a @factory annotation is associated with
   * a method that does not declare a return type.
   */
  static const HintCode INVALID_FACTORY_METHOD_DECL = HintCode(
    'INVALID_FACTORY_METHOD_DECL',
    "Factory method '{0}' must have a return type.",
  );

  /**
   * This hint is generated anywhere a @factory annotation is associated with
   * a non-abstract method that can return anything other than a newly allocated
   * object.
   *
   * Parameters:
   * 0: the name of the method
   */
  static const HintCode INVALID_FACTORY_METHOD_IMPL = HintCode(
    'INVALID_FACTORY_METHOD_IMPL',
    "Factory method '{0}' doesn't return a newly allocated object.",
  );

  /**
   * This hint is generated anywhere an @immutable annotation is associated with
   * anything other than a class.
   */
  static const HintCode INVALID_IMMUTABLE_ANNOTATION = HintCode(
    'INVALID_IMMUTABLE_ANNOTATION',
    "Only classes can be annotated as being immutable.",
  );

  /**
   * This hint is generated anywhere a @internal annotation is associated with
   * an element found in a package's public API.
   */
  static const HintCode INVALID_INTERNAL_ANNOTATION = HintCode(
    'INVALID_INTERNAL_ANNOTATION',
    "Only public elements in a package's private API can be annotated as being internal.",
  );

  /**
   * Invalid Dart language version comments don't follow the specification [1].
   * If a comment begins with "@dart" or "dart" (letters in any case),
   * followed by optional whitespace, followed by optional non-alphanumeric,
   * non-whitespace characters, followed by optional whitespace, followed by
   * an optional alphabetical character, followed by a digit, then the
   * comment is considered to be an attempt at a language version override
   * comment. If this attempted language version override comment is not a
   * valid language version override comment, it is reported.
   *
   * [1] https://github.com/dart-lang/language/blob/master/accepted/future-releases/language-versioning/feature-specification.md#individual-library-language-version-override
   */
  static const HintCode INVALID_LANGUAGE_VERSION_OVERRIDE_AT_SIGN = HintCode(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The Dart language version override number must begin with '@dart'",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// @dart = 2.0'.",
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_AT_SIGN',
  );

  /**
   * Invalid Dart language version comments don't follow the specification [1].
   * If a comment begins with "@dart" or "dart" (letters in any case),
   * followed by optional whitespace, followed by optional non-alphanumeric,
   * non-whitespace characters, followed by optional whitespace, followed by
   * an optional alphabetical character, followed by a digit, then the
   * comment is considered to be an attempt at a language version override
   * comment. If this attempted language version override comment is not a
   * valid language version override comment, it is reported.
   *
   * [1] https://github.com/dart-lang/language/blob/master/accepted/future-releases/language-versioning/feature-specification.md#individual-library-language-version-override
   */
  static const HintCode INVALID_LANGUAGE_VERSION_OVERRIDE_EQUALS = HintCode(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The Dart language version override comment must be specified with an '=' character",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// @dart = 2.0'.",
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_EQUALS',
  );

  static const HintCode INVALID_LANGUAGE_VERSION_OVERRIDE_GREATER = HintCode(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The language version override can't specify a version greater than the latest known language version: {0}.{1}",
    correctionMessage: "Try removing the language version override.",
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_GREATER',
  );

  static const HintCode INVALID_LANGUAGE_VERSION_OVERRIDE_LOCATION = HintCode(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The language version override must be before any declaration or directive.",
    correctionMessage:
        "Try moving the language version override to the top of the file.",
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_LOCATION',
  );

  /**
   * Invalid Dart language version comments don't follow the specification [1].
   * If a comment begins with "@dart" or "dart" (letters in any case),
   * followed by optional whitespace, followed by optional non-alphanumeric,
   * non-whitespace characters, followed by optional whitespace, followed by
   * an optional alphabetical character, followed by a digit, then the
   * comment is considered to be an attempt at a language version override
   * comment. If this attempted language version override comment is not a
   * valid language version override comment, it is reported.
   *
   * [1] https://github.com/dart-lang/language/blob/master/accepted/future-releases/language-versioning/feature-specification.md#individual-library-language-version-override
   */
  static const HintCode INVALID_LANGUAGE_VERSION_OVERRIDE_LOWER_CASE = HintCode(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The Dart language version override comment must be specified with the word 'dart' in all lower case",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// @dart = 2.0'.",
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_LOWER_CASE',
  );

  /**
   * Invalid Dart language version comments don't follow the specification [1].
   * If a comment begins with "@dart" or "dart" (letters in any case),
   * followed by optional whitespace, followed by optional non-alphanumeric,
   * non-whitespace characters, followed by optional whitespace, followed by
   * an optional alphabetical character, followed by a digit, then the
   * comment is considered to be an attempt at a language version override
   * comment. If this attempted language version override comment is not a
   * valid language version override comment, it is reported.
   *
   * [1] https://github.com/dart-lang/language/blob/master/accepted/future-releases/language-versioning/feature-specification.md#individual-library-language-version-override
   */
  static const HintCode INVALID_LANGUAGE_VERSION_OVERRIDE_NUMBER = HintCode(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The Dart language version override comment must be specified with a version number, like '2.0', after the '=' character.",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// @dart = 2.0'.",
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_NUMBER',
  );

  /**
   * Invalid Dart language version comments don't follow the specification [1].
   * If a comment begins with "@dart" or "dart" (letters in any case),
   * followed by optional whitespace, followed by optional non-alphanumeric,
   * non-whitespace characters, followed by optional whitespace, followed by
   * an optional alphabetical character, followed by a digit, then the
   * comment is considered to be an attempt at a language version override
   * comment. If this attempted language version override comment is not a
   * valid language version override comment, it is reported.
   *
   * [1] https://github.com/dart-lang/language/blob/master/accepted/future-releases/language-versioning/feature-specification.md#individual-library-language-version-override
   */
  static const HintCode INVALID_LANGUAGE_VERSION_OVERRIDE_PREFIX = HintCode(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The Dart language version override number can't be prefixed with a letter",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// @dart = 2.0'.",
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_PREFIX',
  );

  /**
   * Invalid Dart language version comments don't follow the specification [1].
   * If a comment begins with "@dart" or "dart" (letters in any case),
   * followed by optional whitespace, followed by optional non-alphanumeric,
   * non-whitespace characters, followed by optional whitespace, followed by
   * an optional alphabetical character, followed by a digit, then the
   * comment is considered to be an attempt at a language version override
   * comment. If this attempted language version override comment is not a
   * valid language version override comment, it is reported.
   *
   * [1] https://github.com/dart-lang/language/blob/master/accepted/future-releases/language-versioning/feature-specification.md#individual-library-language-version-override
   */
  static const HintCode INVALID_LANGUAGE_VERSION_OVERRIDE_TRAILING_CHARACTERS =
      HintCode(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The Dart language version override comment can't be followed by any non-whitespace characters",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// @dart = 2.0'.",
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_TRAILING_CHARACTERS',
  );

  /**
   * Invalid Dart language version comments don't follow the specification [1].
   * If a comment begins with "@dart" or "dart" (letters in any case),
   * followed by optional whitespace, followed by optional non-alphanumeric,
   * non-whitespace characters, followed by optional whitespace, followed by
   * an optional alphabetical character, followed by a digit, then the
   * comment is considered to be an attempt at a language version override
   * comment. If this attempted language version override comment is not a
   * valid language version override comment, it is reported.
   *
   * [1] https://github.com/dart-lang/language/blob/master/accepted/future-releases/language-versioning/feature-specification.md#individual-library-language-version-override
   */
  static const HintCode INVALID_LANGUAGE_VERSION_OVERRIDE_TWO_SLASHES =
      HintCode(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The Dart language version override comment must be specified with exactly two slashes.",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// @dart = 2.0'.",
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_TWO_SLASHES',
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the `@literal` annotation is
  // applied to anything other than a const constructor.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because the constructor isn't
  // a `const` constructor:
  //
  // ```dart
  // import 'package:meta/meta.dart';
  //
  // class C {
  //   [!@literal!]
  //   C();
  // }
  // ```
  //
  // The following code produces this diagnostic because `x` isn't a
  // constructor:
  //
  // ```dart
  // import 'package:meta/meta.dart';
  //
  // [!@literal!]
  // var x;
  // ```
  //
  // #### Common fixes
  //
  // If the annotation is on a constructor and the constructor should always be
  // invoked with `const`, when possible, then mark the constructor with the
  // `const` keyword:
  //
  // ```dart
  // import 'package:meta/meta.dart';
  //
  // class C {
  //   @literal
  //   const C();
  // }
  // ```
  //
  // If the constructor can't be marked as `const`, then remove the annotation.
  //
  // If the annotation is on anything other than a constructor, then remove the
  // annotation:
  //
  // ```dart
  // var x;
  // ```
  static const HintCode INVALID_LITERAL_ANNOTATION = HintCode(
    'INVALID_LITERAL_ANNOTATION',
    "Only const constructors can have the `@literal` annotation.",
    hasPublishedDocs: true,
  );

  /**
   * This hint is generated anywhere where `@nonVirtual` annotates something
   * other than a non-abstract instance member in a class or mixin.
   *
   * No Parameters.
   */
  static const HintCode INVALID_NON_VIRTUAL_ANNOTATION = HintCode(
    'INVALID_NON_VIRTUAL_ANNOTATION',
    "The annotation '@nonVirtual' can only be applied to a concrete instance member.",
    correctionMessage: "Try removing @nonVirtual.",
  );

  /**
   * This hint is generated anywhere where an instance member annotated with
   * `@nonVirtual` is overridden in a subclass.
   *
   * Parameters:
   * 0: the name of the member
   * 1: the name of the defining class
   */
  static const HintCode INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER = HintCode(
    'INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER',
    "The member '{0}' is declared non-virtual in '{1}' and can't be overridden in subclasses.",
  );

  /**
   * This hint is generated anywhere where `@required` annotates a named
   * parameter with a default value.
   *
   * Parameters:
   * 0: the name of the member
   */
  static const HintCode INVALID_REQUIRED_NAMED_PARAM = HintCode(
    'INVALID_REQUIRED_NAMED_PARAM',
    "The type parameter '{0}' is annotated with @required but only named parameters without a default value can be annotated with it.",
    correctionMessage: "Remove @required.",
  );

  /**
   * This hint is generated anywhere where `@required` annotates an optional
   * positional parameter.
   *
   * Parameters:
   * 0: the name of the member
   */
  static const HintCode INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM = HintCode(
    'INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM',
    "Incorrect use of the annotation @required on the optional positional parameter '{0}'. Optional positional parameters cannot be required.",
    correctionMessage: "Remove @required.",
  );

  /**
   * This hint is generated anywhere where `@required` annotates a non optional
   * positional parameter.
   *
   * Parameters:
   * 0: the name of the member
   */
  static const HintCode INVALID_REQUIRED_POSITIONAL_PARAM = HintCode(
    'INVALID_REQUIRED_POSITIONAL_PARAM',
    "Redundant use of the annotation @required on the required positional parameter '{0}'.",
    correctionMessage: "Remove @required.",
  );

  /**
   * This hint is generated anywhere where `@sealed` annotates something other
   * than a class.
   *
   * No parameters.
   */
  static const HintCode INVALID_SEALED_ANNOTATION = HintCode(
    'INVALID_SEALED_ANNOTATION',
    "The annotation '@sealed' can only be applied to classes.",
    correctionMessage: "Remove @sealed.",
  );

  /**
   * This hint is generated anywhere where a member annotated with `@internal`
   * is used outside of the package in which it is declared.
   *
   * Parameters:
   * 0: the name of the member
   */
  static const HintCode INVALID_USE_OF_INTERNAL_MEMBER = HintCode(
    'INVALID_USE_OF_INTERNAL_MEMBER',
    "The member '{0}' can only be used within its package.",
  );

  /**
   * This hint is generated anywhere where a member annotated with `@protected`
   * is used outside of an instance member of a subclass.
   *
   * Parameters:
   * 0: the name of the member
   * 1: the name of the defining class
   */
  static const HintCode INVALID_USE_OF_PROTECTED_MEMBER = HintCode(
    'INVALID_USE_OF_PROTECTED_MEMBER',
    "The member '{0}' can only be used within instance members of subclasses of '{1}'.",
  );

  /**
   * Parameters:
   * 0: the name of the member
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an instance member that is
  // annotated with `visibleForOverriding` is referenced outside the library in
  // which it's declared for any reason other than to override it.
  //
  // #### Example
  //
  // Given a file named `a.dart` containing the following declaration:
  //
  // ```dart
  // %uri="lib/a.dart"
  // import 'package:meta/meta.dart';
  //
  // class A {
  //   @visibleForOverriding
  //   void a() {}
  // }
  // ```
  //
  // The following code produces this diagnostic because the method `m` is being
  // invoked even though the only reason it's public is to allow it to be
  // overridden:
  //
  // ```dart
  // import 'a.dart';
  //
  // class B extends A {
  //   void b() {
  //     [!a!]();
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the invalid use of the member.
  static const HintCode INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER = HintCode(
    'INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER',
    "The member '{0}' can only be used for overriding.",
    hasPublishedDocs: true,
  );

  /**
   * This hint is generated anywhere where a member annotated with
   * `@visibleForTemplate` is used outside of a "template" Dart file.
   *
   * Parameters:
   * 0: the name of the member
   * 1: the name of the defining class
   */
  static const HintCode INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER = HintCode(
    'INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER',
    "The member '{0}' can only be used within '{1}' or a template library.",
  );

  /**
   * This hint is generated anywhere where a member annotated with
   * `@visibleForTesting` is used outside the defining library, or a test.
   *
   * Parameters:
   * 0: the name of the member
   * 1: the name of the defining class
   */
  static const HintCode INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER = HintCode(
    'INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER',
    "The member '{0}' can only be used within '{1}' or a test.",
  );

  /**
   * This hint is generated anywhere where a private declaration is annotated
   * with `@visibleForTemplate` or `@visibleForTesting`.
   *
   * Parameters:
   * 0: the name of the member
   * 1: the name of the annotation
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when either the `@visibleForTemplate`
  // or `@visibleForTesting` annotation is applied to a non-public declaration.
  //
  // #### Example
  //
  // The following code produces this diagnostic:
  //
  // ```dart
  // import 'package:meta/meta.dart';
  //
  // [!@visibleForTesting!]
  // void _someFunction() {}
  //
  // void f() => _someFunction();
  // ```
  //
  // #### Common fixes
  //
  // If the declaration doesn't need to be used by test code, then remove the
  // annotation:
  //
  // ```dart
  // void _someFunction() {}
  //
  // void f() => _someFunction();
  // ```
  //
  // If it does, then make it public:
  //
  // ```dart
  // import 'package:meta/meta.dart';
  //
  // @visibleForTesting
  // void someFunction() {}
  //
  // void f() => someFunction();
  // ```
  static const HintCode INVALID_VISIBILITY_ANNOTATION = HintCode(
    'INVALID_VISIBILITY_ANNOTATION',
    "The member '{0}' is annotated with '{1}', but this annotation is only meaningful on declarations of public members.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when anything other than a public
  // instance member of a class is annotated with `visibleForOverriding`.
  // Because only public instance members can be overridden outside the defining
  // library, there's no value to annotating any other declarations.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the annotation is on a
  // class, and classes can't be overridden:
  //
  // ```dart
  // import 'package:meta/meta.dart';
  //
  // [!@visibleForOverriding!]
  // class C {}
  // ```
  //
  // #### Common fixes
  //
  // Remove the annotation:
  //
  // ```dart
  // class C {}
  // ```
  static const HintCode INVALID_VISIBLE_FOR_OVERRIDING_ANNOTATION = HintCode(
    'INVALID_VISIBLE_FOR_OVERRIDING_ANNOTATION',
    "The annotation 'visibleForOverriding' can only be applied to a public instance member that can be overridden.",
    hasPublishedDocs: true,
  );

  /**
   * Generate a hint for a constructor, function or method invocation where a
   * required parameter is missing.
   *
   * Parameters:
   * 0: the name of the parameter
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a method or function with a
  // named parameter that is annotated as being required is invoked without
  // providing a value for the parameter.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the named parameter `x`
  // is required:
  //
  // ```dart
  // %language=2.9
  // import 'package:meta/meta.dart';
  //
  // void f({@required int x}) {}
  //
  // void g() {
  //   [!f!]();
  // }
  // ```
  //
  // #### Common fixes
  //
  // Provide the required value:
  //
  // ```dart
  // %language=2.9
  // import 'package:meta/meta.dart';
  //
  // void f({@required int x}) {}
  //
  // void g() {
  //   f(x: 2);
  // }
  // ```
  static const HintCode MISSING_REQUIRED_PARAM = HintCode(
    'MISSING_REQUIRED_PARAM',
    "The parameter '{0}' is required.",
    hasPublishedDocs: true,
  );

  /**
   * Generate a hint for a constructor, function or method invocation where a
   * required parameter is missing.
   *
   * Parameters:
   * 0: the name of the parameter
   * 1: message details
   */
  static const HintCode MISSING_REQUIRED_PARAM_WITH_DETAILS = HintCode(
    'MISSING_REQUIRED_PARAM',
    "The parameter '{0}' is required. {1}.",
    hasPublishedDocs: true,
    uniqueName: 'MISSING_REQUIRED_PARAM_WITH_DETAILS',
  );

  /**
   * Parameters:
   * 0: the name of the declared return type
   */
  // #### Description
  //
  // Any function or method that doesn't end with either an explicit return or a
  // throw implicitly returns `null`. This is rarely the desired behavior. The
  // analyzer produces this diagnostic when it finds an implicit return.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `f` doesn't end with a
  // return:
  //
  // ```dart
  // %language=2.9
  // int [!f!](int x) {
  //   if (x < 0) {
  //     return 0;
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // Add a `return` statement that makes the return value explicit, even if
  // `null` is the appropriate value.
  static const HintCode MISSING_RETURN = HintCode(
    'MISSING_RETURN',
    "This function has a return type of '{0}', but doesn't end with a return statement.",
    correctionMessage:
        "Try adding a return statement, or changing the return type to 'void'.",
    hasPublishedDocs: true,
  );

  /**
   * This hint is generated anywhere where a `@sealed` class is used as a
   * a superclass constraint of a mixin.
   *
   * Parameters:
   * 0: the name of the sealed class
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the superclass constraint of a
  // mixin is a class from a different package that was marked as `@sealed`.
  // Classes that are sealed can't be extended, implemented, mixed in, or used
  // as a superclass constraint.
  //
  // #### Example
  //
  // If the package `p` defines a sealed class:
  //
  // ```dart
  // %uri="package:p/p.dart"
  // import 'package:meta/meta.dart';
  //
  // @sealed
  // class C {}
  // ```
  //
  // Then, the following code, when in a package other than `p`, produces this
  // diagnostic:
  //
  // ```dart
  // import 'package:p/p.dart';
  //
  // [!mixin M on C {}!]
  // ```
  //
  // #### Common fixes
  //
  // If the classes that use the mixin don't need to be subclasses of the sealed
  // class, then consider adding a field and delegating to the wrapped instance
  // of the sealed class.
  static const HintCode MIXIN_ON_SEALED_CLASS = HintCode(
    'MIXIN_ON_SEALED_CLASS',
    "The class '{0}' shouldn't be used as a mixin constraint because it is sealed, and any class mixing in this mixin must have '{0}' as a superclass.",
    correctionMessage:
        "Try composing with this class, or refer to its documentation for more information.",
    hasPublishedDocs: true,
  );

  /**
   * Generate a hint for classes that inherit from classes annotated with
   * `@immutable` but that are not immutable.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an immutable class defines one
  // or more instance fields that aren't final. A class is immutable if it's
  // marked as being immutable using the annotation `@immutable` or if it's a
  // subclass of an immutable class.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the field `x` isn't
  // final:
  //
  // ```dart
  // import 'package:meta/meta.dart';
  //
  // @immutable
  // class [!C!] {
  //   int x;
  //
  //   C(this.x);
  // }
  // ```
  //
  // #### Common fixes
  //
  // If instances of the class should be immutable, then add the keyword `final`
  // to all non-final field declarations:
  //
  // ```dart
  // import 'package:meta/meta.dart';
  //
  // @immutable
  // class C {
  //   final int x;
  //
  //   C(this.x);
  // }
  // ```
  //
  // If the instances of the class should be mutable, then remove the
  // annotation, or choose a different superclass if the annotation is
  // inherited:
  //
  // ```dart
  // class C {
  //   int x;
  //
  //   C(this.x);
  // }
  // ```
  static const HintCode MUST_BE_IMMUTABLE = HintCode(
    'MUST_BE_IMMUTABLE',
    "This class (or a class that this class inherits from) is marked as '@immutable', but one or more of its instance fields aren't final: {0}",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the class declaring the overridden method
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a method that overrides a method
  // that is annotated as `@mustCallSuper` doesn't invoke the overridden method
  // as required.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the method `m` in `B`
  // doesn't invoke the overridden method `m` in `A`:
  //
  // ```dart
  // import 'package:meta/meta.dart';
  //
  // class A {
  //   @mustCallSuper
  //   m() {}
  // }
  //
  // class B extends A {
  //   @override
  //   [!m!]() {}
  // }
  // ```
  //
  // #### Common fixes
  //
  // Add an invocation of the overridden method in the overriding method:
  //
  // ```dart
  // import 'package:meta/meta.dart';
  //
  // class A {
  //   @mustCallSuper
  //   m() {}
  // }
  //
  // class B extends A {
  //   @override
  //   m() {
  //     super.m();
  //   }
  // }
  // ```
  static const HintCode MUST_CALL_SUPER = HintCode(
    'MUST_CALL_SUPER',
    "This method overrides a method annotated as '@mustCallSuper' in '{0}', but doesn't invoke the overridden method.",
    hasPublishedDocs: true,
  );

  /**
   * Generate a hint for non-const instance creation using a constructor
   * annotated with `@literal`.
   *
   * Parameters:
   * 0: the name of the class defining the annotated constructor
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a constructor that has the
  // `@literal` annotation is invoked without using the `const` keyword, but all
  // of the arguments to the constructor are constants. The annotation indicates
  // that the constructor should be used to create a constant value whenever
  // possible.
  //
  // #### Example
  //
  // The following code produces this diagnostic:
  //
  // ```dart
  // import 'package:meta/meta.dart';
  //
  // class C {
  //   @literal
  //   const C();
  // }
  //
  // C f() => [!C()!];
  // ```
  //
  // #### Common fixes
  //
  // Add the keyword `const` before the constructor invocation:
  //
  // ```dart
  // import 'package:meta/meta.dart';
  //
  // class C {
  //   @literal
  //   const C();
  // }
  //
  // void f() => const C();
  // ```
  static const HintCode NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR = HintCode(
    'NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR',
    "This instance creation must be 'const', because the {0} constructor is marked as '@literal'.",
    correctionMessage: "Try adding a 'const' keyword.",
    hasPublishedDocs: true,
  );

  /**
   * Generate a hint for non-const instance creation (with the `new` keyword)
   * using a constructor annotated with `@literal`.
   *
   * Parameters:
   * 0: the name of the class defining the annotated constructor
   */
  static const HintCode NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR_USING_NEW =
      HintCode(
    'NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR',
    "This instance creation must be 'const', because the {0} constructor is marked as '@literal'.",
    correctionMessage: "Try replacing the 'new' keyword with 'const'.",
    hasPublishedDocs: true,
    uniqueName: 'NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR_USING_NEW',
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the type following `on` in a
  // `catch` clause is a nullable type. It isn't valid to specify a nullable
  // type because it isn't possible to catch `null` (because it's a runtime
  // error to throw `null`).
  //
  // #### Example
  //
  // The following code produces this diagnostic because the exception type is
  // specified to allow `null` when `null` can't be thrown:
  //
  // ```dart
  // void f() {
  //   try {
  //     // ...
  //   } on [!FormatException?!] {
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the question mark from the type:
  //
  // ```dart
  // void f() {
  //   try {
  //     // ...
  //   } on FormatException {
  //   }
  // }
  // ```
  static const HintCode NULLABLE_TYPE_IN_CATCH_CLAUSE = HintCode(
    'NULLABLE_TYPE_IN_CATCH_CLAUSE',
    "A potentially nullable type can't be used in an 'on' clause because it isn't valid to throw a nullable expression.",
    correctionMessage: "Try using a non-nullable type.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the method being invoked
   * 1: the type argument associated with the method
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when `null` is passed to either the
  // constructor `Future.value` or the method `Completer.complete` when the type
  // argument used to create the instance was non-nullable. Even though the type
  // system can't express this restriction, passing in a `null` results in a
  // runtime exception.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `null` is being passed
  // to the constructor `Future.value` even though the type argument is the
  // non-nullable type `String`:
  //
  // ```dart
  // Future<String> f() {
  //   return Future.value([!null!]);
  // }
  // ```
  //
  // #### Common fixes
  //
  // Pass in a non-null value:
  //
  // ```dart
  // Future<String> f() {
  //   return Future.value('');
  // }
  // ```
  static const HintCode NULL_ARGUMENT_TO_NON_NULL_TYPE = HintCode(
    'NULL_ARGUMENT_TO_NON_NULL_TYPE',
    "'{0}' shouldn't be called with a null argument for the non-nullable type argument '{1}'.",
    correctionMessage: "Try adding a non-null argument.",
    hasPublishedDocs: true,
  );

  /**
   * When the left operand of a binary expression uses '?.' operator, it can be
   * `null`.
   */
  static const HintCode NULL_AWARE_BEFORE_OPERATOR = HintCode(
    'NULL_AWARE_BEFORE_OPERATOR',
    "The left operand uses '?.', so its value can be null.",
  );

  /**
   * A condition in a control flow statement could evaluate to `null` because it
   * uses the null-aware '?.' operator.
   */
  static const HintCode NULL_AWARE_IN_CONDITION = HintCode(
    'NULL_AWARE_IN_CONDITION',
    "The value of the '?.' operator can be 'null', which isn't appropriate in a condition.",
    correctionMessage:
        "Try replacing the '?.' with a '.', testing the left-hand side for null if necessary.",
  );

  /**
   * A condition in operands of a logical operator could evaluate to `null`
   * because it uses the null-aware '?.' operator.
   */
  static const HintCode NULL_AWARE_IN_LOGICAL_OPERATOR = HintCode(
    'NULL_AWARE_IN_LOGICAL_OPERATOR',
    "The value of the '?.' operator can be 'null', which isn't appropriate as an operand of a logical operator.",
  );

  /**
   * This hint indicates that a null literal is null-checked with `!`, but null
   * is never not null.
   */
  static const HintCode NULL_CHECK_ALWAYS_FAILS = HintCode(
    'NULL_CHECK_ALWAYS_FAILS',
    "This null-check will always throw an exception because the expression will always evaluate to 'null'.",
  );

  /**
   * A field with the override annotation does not override a getter or setter.
   *
   * No parameters.
   */
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_FIELD = HintCode(
    'OVERRIDE_ON_NON_OVERRIDING_MEMBER',
    "The field doesn't override an inherited getter or setter.",
    correctionMessage:
        "Try updating this class to match the superclass, or removing the override annotation.",
    hasPublishedDocs: true,
    uniqueName: 'OVERRIDE_ON_NON_OVERRIDING_FIELD',
  );

  /**
   * A getter with the override annotation does not override an existing getter.
   *
   * No parameters.
   */
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_GETTER = HintCode(
    'OVERRIDE_ON_NON_OVERRIDING_MEMBER',
    "The getter doesn't override an inherited getter.",
    correctionMessage:
        "Try updating this class to match the superclass, or removing the override annotation.",
    hasPublishedDocs: true,
    uniqueName: 'OVERRIDE_ON_NON_OVERRIDING_GETTER',
  );

  /**
   * A method with the override annotation does not override an existing method.
   *
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a class member is annotated with
  // the `@override` annotation, but the member isn’t declared in any of the
  // supertypes of the class.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `m` isn't declared in
  // any of the supertypes of `C`:
  //
  // ```dart
  // class C {
  //   @override
  //   String [!m!]() => '';
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the member is intended to override a member with a different name, then
  // update the member to have the same name:
  //
  // ```dart
  // class C {
  //   @override
  //   String toString() => '';
  // }
  // ```
  //
  // If the member is intended to override a member that was removed from the
  // superclass, then consider removing the member from the subclass.
  //
  // If the member can't be removed, then remove the annotation.
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_METHOD = HintCode(
    'OVERRIDE_ON_NON_OVERRIDING_MEMBER',
    "The method doesn't override an inherited method.",
    correctionMessage:
        "Try updating this class to match the superclass, or removing the override annotation.",
    hasPublishedDocs: true,
    uniqueName: 'OVERRIDE_ON_NON_OVERRIDING_METHOD',
  );

  /**
   * A setter with the override annotation does not override an existing setter.
   *
   * No parameters.
   */
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_SETTER = HintCode(
    'OVERRIDE_ON_NON_OVERRIDING_MEMBER',
    "The setter doesn't override an inherited setter.",
    correctionMessage:
        "Try updating this class to match the superclass, or removing the override annotation.",
    hasPublishedDocs: true,
    uniqueName: 'OVERRIDE_ON_NON_OVERRIDING_SETTER',
  );

  /**
   * It is a bad practice for a package import to reference anything outside the
   * given package, or more generally, it is bad practice for a package import
   * to contain a "..". For example, a source file should not contain a
   * directive such as `import 'package:foo/../some.dart'`.
   */
  static const HintCode PACKAGE_IMPORT_CONTAINS_DOT_DOT = HintCode(
    'PACKAGE_IMPORT_CONTAINS_DOT_DOT',
    "A package import shouldn't contain '..'.",
  );

  /**
   * It is not an error to call or tear-off a method, setter, or getter, or to
   * read or write a field, on a receiver of static type `Never`.
   * Implementations that provide feedback about dead or unreachable code are
   * encouraged to indicate that any arguments to the invocation are
   * unreachable.
   *
   * It is not an error to apply an expression of type `Never` in the function
   * position of a function call. Implementations that provide feedback about
   * dead or unreachable code are encouraged to indicate that any arguments to
   * the call are unreachable.
   *
   * Parameters: none
   */
  static const HintCode RECEIVER_OF_TYPE_NEVER = HintCode(
    'RECEIVER_OF_TYPE_NEVER',
    "The receiver is of type 'Never', and will never complete with a value.",
    correctionMessage:
        "Try checking for throw expressions or type errors in the receiver",
  );

  /**
   * Users should not return values marked `@doNotStore` from functions,
   * methods or getters not marked `@doNotStore`.
   */
  static const HintCode RETURN_OF_DO_NOT_STORE = HintCode(
    'RETURN_OF_DO_NOT_STORE',
    "'{0}' is annotated with 'doNotStore' and shouldn't be returned unless '{1}' is also annotated.",
    correctionMessage: "Annotate '{1}' with 'doNotStore'.",
  );

  /**
   * Parameters:
   * 0: the return type as declared in the return statement
   * 1: the expected return type as defined by the type of the Future
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an invocation of
  // `Future.catchError` has an argument whose return type isn't compatible with
  // the type returned by the instance of `Future`. At runtime, the method
  // `catchError` attempts to return the value from the callback as the result
  // of the future, which results in another exception being thrown.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because `future` is declared to
  // return an `int` while `callback` is declared to return a `String`, and
  // `String` isn't a subtype of `int`:
  //
  // ```dart
  // void f(Future<int> future, String Function(dynamic, StackTrace) callback) {
  //   future.catchError([!callback!]);
  // }
  // ```
  //
  // The following code produces this diagnostic because the closure being
  // passed to `catchError` returns an `int` while `future` is declared to
  // return a `String`:
  //
  // ```dart
  // void f(Future<String> future) {
  //   future.catchError((error, stackTrace) => [!3!]);
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the instance of `Future` is declared correctly, then change the callback
  // to match:
  //
  // ```dart
  // void f(Future<int> future, int Function(dynamic, StackTrace) callback) {
  //   future.catchError(callback);
  // }
  // ```
  //
  // If the declaration of the instance of `Future` is wrong, then change it to
  // match the callback:
  //
  // ```dart
  // void f(Future<String> future, String Function(dynamic, StackTrace) callback) {
  //   future.catchError(callback);
  // }
  // ```
  static const HintCode RETURN_OF_INVALID_TYPE_FROM_CATCH_ERROR = HintCode(
    'INVALID_RETURN_TYPE_FOR_CATCH_ERROR',
    "A value of type '{0}' can't be returned by the 'onError' handler because it must be assignable to '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'RETURN_OF_INVALID_TYPE_FROM_CATCH_ERROR',
  );

  /**
   * Parameters:
   * 0: the return type of the function
   * 1: the expected return type as defined by the type of the Future
   */
  static const HintCode RETURN_TYPE_INVALID_FOR_CATCH_ERROR = HintCode(
    'INVALID_RETURN_TYPE_FOR_CATCH_ERROR',
    "The return type '{0}' isn't assignable to '{1}', as required by 'Future.catchError'.",
    hasPublishedDocs: true,
    uniqueName: 'RETURN_TYPE_INVALID_FOR_CATCH_ERROR',
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when either the class `Future` or
  // `Stream` is referenced in a library that doesn't import `dart:async` in
  // code that has an SDK constraint whose lower bound is less than 2.1.0. In
  // earlier versions, these classes weren't defined in `dart:core`, so the
  // import was necessary.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.1.0:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //   sdk: '>=2.0.0 <2.4.0'
  // ```
  //
  // In the package that has that pubspec, code like the following produces this
  // diagnostic:
  //
  // ```dart
  // void f([!Future!] f) {}
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the classes to be referenced:
  //
  // ```yaml
  // environment:
  //   sdk: '>=2.1.0 <2.4.0'
  // ```
  //
  // If you need to support older versions of the SDK, then import the
  // `dart:async` library.
  //
  // ```dart
  // import 'dart:async';
  //
  // void f(Future f) {}
  // ```
  static const HintCode SDK_VERSION_ASYNC_EXPORTED_FROM_CORE = HintCode(
    'SDK_VERSION_ASYNC_EXPORTED_FROM_CORE',
    "The class '{0}' wasn't exported from 'dart:core' until version 2.1, but this code is required to be able to run on earlier versions.",
    correctionMessage:
        "Try either importing 'dart:async' or updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an `as` expression inside a
  // [constant context][] is found in code that has an SDK constraint whose
  // lower bound is less than 2.3.2. Using an `as` expression in a
  // [constant context][] wasn't supported in earlier versions, so this code
  // won't be able to run against earlier versions of the SDK.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.3.2:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //   sdk: '>=2.1.0 <2.4.0'
  // ```
  //
  // In the package that has that pubspec, code like the following produces
  // this diagnostic:
  //
  // ```dart
  // const num n = 3;
  // const int i = [!n as int!];
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the expression to be used:
  //
  // ```yaml
  // environment:
  //   sdk: '>=2.3.2 <2.4.0'
  // ```
  //
  // If you need to support older versions of the SDK, then either rewrite the
  // code to not use an `as` expression, or change the code so that the `as`
  // expression isn't in a [constant context][]:
  //
  // ```dart
  // num x = 3;
  // int y = x as int;
  // ```
  static const HintCode SDK_VERSION_AS_EXPRESSION_IN_CONST_CONTEXT = HintCode(
    'SDK_VERSION_AS_EXPRESSION_IN_CONST_CONTEXT',
    "The use of an as expression in a constant expression wasn't supported until version 2.3.2, but this code is required to be able to run on earlier versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when any use of the `&`, `|`, or `^`
  // operators on the class `bool` inside a [constant context][] is found in
  // code that has an SDK constraint whose lower bound is less than 2.3.2. Using
  // these operators in a [constant context][] wasn't supported in earlier
  // versions, so this code won't be able to run against earlier versions of the
  // SDK.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.3.2:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //   sdk: '>=2.1.0 <2.4.0'
  // ```
  //
  // In the package that has that pubspec, code like the following produces this
  // diagnostic:
  //
  // ```dart
  // const bool a = true;
  // const bool b = false;
  // const bool c = a [!&!] b;
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the operators to be used:
  //
  // ```yaml
  // environment:
  //  sdk: '>=2.3.2 <2.4.0'
  // ```
  //
  // If you need to support older versions of the SDK, then either rewrite the
  // code to not use these operators, or change the code so that the expression
  // isn't in a [constant context][]:
  //
  // ```dart
  // const bool a = true;
  // const bool b = false;
  // bool c = a & b;
  // ```
  static const HintCode SDK_VERSION_BOOL_OPERATOR_IN_CONST_CONTEXT = HintCode(
    'SDK_VERSION_BOOL_OPERATOR_IN_CONST_CONTEXT',
    "The use of the operator '{0}' for 'bool' operands in a constant context wasn't supported until version 2.3.2, but this code is required to be able to run on earlier versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   *
   * There is also a [ParserError.EXPERIMENT_NOT_ENABLED] code which catches
   * some cases of constructor tearoff features (like `List<int>.filled;`).
   * Other constructor tearoff cases are not realized until resolution
   * (like `List.filled;`).
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a constructor tear-off is found
  // in code that has an SDK constraint whose lower bound is less than 2.15.
  // Constructor tear-offs weren't supported in earlier versions, so this code
  // won't be able to run against earlier versions of the SDK.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.15:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //   sdk: '>=2.9.0 <2.15.0'
  // ```
  //
  // In the package that has that pubspec, code like the following produces this
  // diagnostic:
  //
  // ```dart
  // %language=2.14
  // var setConstructor = [!Set.identity!];
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the operator to be used:
  //
  // ```yaml
  // environment:
  //   sdk: '>=2.15.0 <2.16.0'
  // ```
  //
  // If you need to support older versions of the SDK, then rewrite the code to
  // not use constructor tear-offs:
  //
  // ```dart
  // %language=2.14
  // var setConstructor = () => Set.identity();
  // ```
  static const HintCode SDK_VERSION_CONSTRUCTOR_TEAROFFS = HintCode(
    'SDK_VERSION_CONSTRUCTOR_TEAROFFS',
    "Tearing off a constructor requires the 'constructor-tearoffs' language feature.",
    correctionMessage:
        "Try updating your pubspec.yaml to set the minimum SDK constraint to 2.15 or higher, and running 'pub get'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the operator `==` is used on a
  // non-primitive type inside a [constant context][] is found in code that has
  // an SDK constraint whose lower bound is less than 2.3.2. Using this operator
  // in a [constant context][] wasn't supported in earlier versions, so this
  // code won't be able to run against earlier versions of the SDK.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.3.2:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //   sdk: '>=2.1.0 <2.4.0'
  // ```
  //
  // In the package that has that pubspec, code like the following produces this
  // diagnostic:
  //
  // ```dart
  // %language=2.9
  // class C {}
  // const C a = null;
  // const C b = null;
  // const bool same = a [!==!] b;
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the operator to be used:
  //
  // ```yaml
  // environment:
  //   sdk: '>=2.3.2 <2.4.0'
  // ```
  //
  // If you need to support older versions of the SDK, then either rewrite the
  // code to not use the `==` operator, or change the code so that the
  // expression isn't in a [constant context][]:
  //
  // ```dart
  // %language=2.9
  // class C {}
  // const C a = null;
  // const C b = null;
  // bool same = a == b;
  // ```
  static const HintCode SDK_VERSION_EQ_EQ_OPERATOR_IN_CONST_CONTEXT = HintCode(
    'SDK_VERSION_EQ_EQ_OPERATOR_IN_CONST_CONTEXT',
    "Using the operator '==' for non-primitive types wasn't supported until version 2.3.2, but this code is required to be able to run on earlier versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an extension declaration or an
  // extension override is found in code that has an SDK constraint whose lower
  // bound is less than 2.6.0. Using extensions wasn't supported in earlier
  // versions, so this code won't be able to run against earlier versions of the
  // SDK.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.6.0:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //  sdk: '>=2.4.0 <2.7.0'
  // ```
  //
  // In the package that has that pubspec, code like the following produces
  // this diagnostic:
  //
  // ```dart
  // [!extension!] E on String {
  //   void sayHello() {
  //     print('Hello $this');
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the syntax to be used:
  //
  // ```yaml
  // environment:
  //   sdk: '>=2.6.0 <2.7.0'
  // ```
  //
  // If you need to support older versions of the SDK, then rewrite the code to
  // not make use of extensions. The most common way to do this is to rewrite
  // the members of the extension as top-level functions (or methods) that take
  // the value that would have been bound to `this` as a parameter:
  //
  // ```dart
  // void sayHello(String s) {
  //   print('Hello $s');
  // }
  // ```
  static const HintCode SDK_VERSION_EXTENSION_METHODS = HintCode(
    'SDK_VERSION_EXTENSION_METHODS',
    "Extension methods weren't supported until version 2.6.0, but this code is required to be able to run on earlier versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the operator `>>>` is used in
  // code that has an SDK constraint whose lower bound is less than 2.14.0. This
  // operator wasn't supported in earlier versions, so this code won't be able
  // to run against earlier versions of the SDK.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.14.0:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //  sdk: '>=2.0.0 <2.15.0'
  // ```
  //
  // In the package that has that pubspec, code like the following produces this
  // diagnostic:
  //
  // ```dart
  // int x = 3 [!>>>!] 4;
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the operator to be used:
  //
  // ```yaml
  // environment:
  //   sdk: '>=2.14.0 <2.15.0'
  // ```
  //
  // If you need to support older versions of the SDK, then rewrite the code to
  // not use the `>>>` operator:
  //
  // ```dart
  // int x = logicalShiftRight(3, 4);
  //
  // int logicalShiftRight(int leftOperand, int rightOperand) {
  //   int divisor = 1 << rightOperand;
  //   if (divisor == 0) {
  //     return 0;
  //   }
  //   return leftOperand ~/ divisor;
  // }
  // ```
  static const HintCode SDK_VERSION_GT_GT_GT_OPERATOR = HintCode(
    'SDK_VERSION_GT_GT_GT_OPERATOR',
    "The operator '>>>' wasn't supported until version 2.14.0, but this code is required to be able to run on earlier versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an `is` expression inside a
  // [constant context][] is found in code that has an SDK constraint whose
  // lower bound is less than 2.3.2. Using an `is` expression in a
  // [constant context][] wasn't supported in earlier versions, so this code
  // won't be able to run against earlier versions of the SDK.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.3.2:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //   sdk: '>=2.1.0 <2.4.0'
  // ```
  //
  // In the package that has that pubspec, code like the following produces
  // this diagnostic:
  //
  // ```dart
  // const Object x = 4;
  // const y = [!x is int!] ? 0 : 1;
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the expression to be used:
  //
  // ```yaml
  // environment:
  //   sdk: '>=2.3.2 <2.4.0'
  // ```
  //
  // If you need to support older versions of the SDK, then either rewrite the
  // code to not use the `is` operator, or, if that isn't possible, change the
  // code so that the `is` expression isn't in a
  // [constant context][]:
  //
  // ```dart
  // const Object x = 4;
  // var y = x is int ? 0 : 1;
  // ```
  static const HintCode SDK_VERSION_IS_EXPRESSION_IN_CONST_CONTEXT = HintCode(
    'SDK_VERSION_IS_EXPRESSION_IN_CONST_CONTEXT',
    "The use of an is expression in a constant context wasn't supported until version 2.3.2, but this code is required to be able to run on earlier versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a reference to the class `Never`
  // is found in code that has an SDK constraint whose lower bound is less than
  // 2.12.0. This class wasn't defined in earlier versions, so this code won't
  // be able to run against earlier versions of the SDK.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.12.0:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //   sdk: '>=2.5.0 <2.6.0'
  // ```
  //
  // In the package that has that pubspec, code like the following produces this
  // diagnostic:
  //
  // ```dart
  // %language=2.9
  // [!Never!] n;
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the type to be used:
  //
  // ```yaml
  // environment:
  //   sdk: '>=2.12.0 <2.13.0'
  // ```
  //
  // If you need to support older versions of the SDK, then rewrite the code to
  // not reference this class:
  //
  // ```dart
  // dynamic x;
  // ```
  static const HintCode SDK_VERSION_NEVER = HintCode(
    'SDK_VERSION_NEVER',
    "The type 'Never' wasn't supported until version 2.12.0, but this code is required to be able to run on earlier versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a set literal is found in code
  // that has an SDK constraint whose lower bound is less than 2.2.0. Set
  // literals weren't supported in earlier versions, so this code won't be able
  // to run against earlier versions of the SDK.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.2.0:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //   sdk: '>=2.1.0 <2.4.0'
  // ```
  //
  // In the package that has that pubspec, code like the following produces this
  // diagnostic:
  //
  // ```dart
  // var s = [!<int>{}!];
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the syntax to be used:
  //
  // ```yaml
  // environment:
  //   sdk: '>=2.2.0 <2.4.0'
  // ```
  //
  // If you do need to support older versions of the SDK, then replace the set
  // literal with code that creates the set without the use of a literal:
  //
  // ```dart
  // var s = new Set<int>();
  // ```
  static const HintCode SDK_VERSION_SET_LITERAL = HintCode(
    'SDK_VERSION_SET_LITERAL',
    "Set literals weren't supported until version 2.2, but this code is required to be able to run on earlier versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a for, if, or spread element is
  // found in code that has an SDK constraint whose lower bound is less than
  // 2.3.0. Using a for, if, or spread element wasn't supported in earlier
  // versions, so this code won't be able to run against earlier versions of the
  // SDK.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.3.0:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //   sdk: '>=2.2.0 <2.4.0'
  // ```
  //
  // In the package that has that pubspec, code like the following produces
  // this diagnostic:
  //
  // ```dart
  // var digits = [[!for (int i = 0; i < 10; i++) i!]];
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the syntax to be used:
  //
  // ```yaml
  // environment:
  //   sdk: '>=2.3.0 <2.4.0'
  // ```
  //
  // If you need to support older versions of the SDK, then rewrite the code to
  // not make use of those elements:
  //
  // ```dart
  // var digits = _initializeDigits();
  //
  // List<int> _initializeDigits() {
  //   var digits = <int>[];
  //   for (int i = 0; i < 10; i++) {
  //     digits.add(i);
  //   }
  //   return digits;
  // }
  // ```
  static const HintCode SDK_VERSION_UI_AS_CODE = HintCode(
    'SDK_VERSION_UI_AS_CODE',
    "The for, if, and spread elements weren't supported until version 2.3.0, but this code is required to be able to run on earlier versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an if or spread element inside
  // a [constant context][] is found in code that has an SDK constraint whose
  // lower bound is less than 2.5.0. Using an if or spread element inside a
  // [constant context][] wasn't supported in earlier versions, so this code
  // won't be able to run against earlier versions of the SDK.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.5.0:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //   sdk: '>=2.4.0 <2.6.0'
  // ```
  //
  // In the package that has that pubspec, code like the following produces
  // this diagnostic:
  //
  // ```dart
  // const a = [1, 2];
  // const b = [[!...a!]];
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the syntax to be used:
  //
  // ```yaml
  // environment:
  //   sdk: '>=2.5.0 <2.6.0'
  // ```
  //
  // If you need to support older versions of the SDK, then rewrite the code to
  // not make use of those elements:
  //
  // ```dart
  // const a = [1, 2];
  // const b = [1, 2];
  // ```
  //
  // If that isn't possible, change the code so that the element isn't in a
  // [constant context][]:
  //
  // ```dart
  // const a = [1, 2];
  // var b = [...a];
  // ```
  static const HintCode SDK_VERSION_UI_AS_CODE_IN_CONST_CONTEXT = HintCode(
    'SDK_VERSION_UI_AS_CODE_IN_CONST_CONTEXT',
    "The if and spread elements weren't supported in constant expressions until version 2.5.0, but this code is required to be able to run on earlier versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  /**
   * When "strict-raw-types" is enabled, "raw types" must have type arguments.
   *
   * A "raw type" is a type name that does not use inference to fill in missing
   * type arguments; instead, each type argument is instantiated to its bound.
   */
  static const HintCode STRICT_RAW_TYPE = HintCode(
    'STRICT_RAW_TYPE',
    "The generic type '{0}' should have explicit type arguments but doesn't.",
    correctionMessage: "Use explicit type arguments for '{0}'.",
  );

  /**
   * Parameters:
   * 0: the name of the sealed class
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a sealed class (one that either
  // has the `@sealed` annotation or inherits or mixes in a sealed class) is
  // referenced in either the `extends`, `implements`, or `with` clause of a
  // class or mixin declaration if the declaration isn't in the same package as
  // the sealed class.
  //
  // #### Example
  //
  // Given a library in a package other than the package being analyzed that
  // contains the following:
  //
  // ```dart
  // %uri="package:a/a.dart"
  // import 'package:meta/meta.dart';
  //
  // class A {}
  //
  // @sealed
  // class B {}
  // ```
  //
  // The following code produces this diagnostic because `C`, which isn't in the
  // same package as `B`, is extending the sealed class `B`:
  //
  // ```dart
  // import 'package:a/a.dart';
  //
  // [!class C extends B {}!]
  // ```
  //
  // #### Common fixes
  //
  // If the class doesn't need to be a subtype of the sealed class, then change
  // the declaration so that it isn't:
  //
  // ```dart
  // import 'package:a/a.dart';
  //
  // class B extends A {}
  // ```
  //
  // If the class needs to be a subtype of the sealed class, then either change
  // the sealed class so that it's no longer sealed or move the subclass into
  // the same package as the sealed class.
  static const HintCode SUBTYPE_OF_SEALED_CLASS = HintCode(
    'SUBTYPE_OF_SEALED_CLASS',
    "The class '{0}' shouldn't be extended, mixed in, or implemented because it's sealed.",
    correctionMessage:
        "Try composing instead of inheriting, or refer to the documentation of '{0}' for more information.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the unicode sequence of the code point.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when it encounters source that
  // contains text direction Unicode code points. These code points cause
  // source code in either a string literal or a comment to be interpreted
  // and compiled differently than how it appears in editors, leading to
  // possible security vulnerabilities.
  //
  // #### Example
  //
  // The following code produces this diagnostic twice because there are
  // hidden characters at the start and end of the label string:
  //
  // ```dart
  // var label = '[!I!]nteractive text[!'!];
  // ```
  //
  // #### Common fixes
  //
  // If the code points are intended to be included in the string literal,
  // then escape them:
  //
  // ```dart
  // var label = '\u202AInteractive text\u202C';
  // ```
  //
  // If the code points aren't intended to be included in the string literal,
  // then remove them:
  //
  // ```dart
  // var label = 'Interactive text';
  // ```
  static const HintCode TEXT_DIRECTION_CODE_POINT_IN_COMMENT = HintCode(
    'TEXT_DIRECTION_CODE_POINT_IN_COMMENT',
    "The Unicode code point 'U+{0}' changes the appearance of text from how it's interpreted by the compiler.",
    correctionMessage:
        "Try removing the code point or using the Unicode escape sequence '\\u{0}'.",
  );

  /**
   * Parameters:
   * 0: the unicode sequence of the code point.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when it encounters source that
  // contains text direction Unicode code points. These code points cause
  // source code in either a string literal or a comment to be interpreted
  // and compiled differently than how it appears in editors, leading to
  // possible security vulnerabilities.
  //
  // #### Example
  //
  // The following code produces this diagnostic twice because there are
  // hidden characters at the start and end of the label string:
  //
  // ```dart
  // var label = '[!I!]nteractive text[!'!];
  // ```
  //
  // #### Common fixes
  //
  // If the code points are intended to be included in the string literal,
  // then escape them:
  //
  // ```dart
  // var label = '\u202AInteractive text\u202C';
  // ```
  //
  // If the code points aren't intended to be included in the string literal,
  // then remove them:
  //
  // ```dart
  // var label = 'Interactive text';
  // ```
  static const HintCode TEXT_DIRECTION_CODE_POINT_IN_LITERAL = HintCode(
    'TEXT_DIRECTION_CODE_POINT_IN_LITERAL',
    "The Unicode code point 'U+{0}' changes the appearance of text from how it's interpreted by the compiler.",
    correctionMessage:
        "Try removing the code point or using the Unicode escape sequence '\\u{0}'.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when there's a type check (using the
  // `as` operator) where the type is `Null`. There's only one value whose type
  // is `Null`, so the code is both more readable and more performant when it
  // tests for `null` explicitly.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because the code is testing to
  // see whether the value of `s` is `null` by using a type check:
  //
  // ```dart
  // void f(String? s) {
  //   if ([!s is Null!]) {
  //     return;
  //   }
  //   print(s);
  // }
  // ```
  //
  // The following code produces this diagnostic because the code is testing to
  // see whether the value of `s` is something other than `null` by using a type
  // check:
  //
  // ```dart
  // void f(String? s) {
  //   if ([!s is! Null!]) {
  //     print(s);
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // Replace the type check with the equivalent comparison with `null`:
  //
  // ```dart
  // void f(String? s) {
  //   if (s == null) {
  //     return;
  //   }
  //   print(s);
  // }
  // ```
  static const HintCode TYPE_CHECK_IS_NOT_NULL = HintCode(
    'TYPE_CHECK_WITH_NULL',
    "Tests for non-null should be done with '!= null'.",
    correctionMessage: "Try replacing the 'is! Null' check with '!= null'.",
    hasPublishedDocs: true,
    uniqueName: 'TYPE_CHECK_IS_NOT_NULL',
  );

  /**
   * No parameters.
   */
  static const HintCode TYPE_CHECK_IS_NULL = HintCode(
    'TYPE_CHECK_WITH_NULL',
    "Tests for null should be done with '== null'.",
    correctionMessage: "Try replacing the 'is Null' check with '== null'.",
    hasPublishedDocs: true,
    uniqueName: 'TYPE_CHECK_IS_NULL',
  );

  /**
   * Parameters:
   * 0: the name of the library being imported
   * 1: the name in the hide clause that isn't defined in the library
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a hide combinator includes a
  // name that isn't defined by the library being imported.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `dart:math` doesn't
  // define the name `String`:
  //
  // ```dart
  // import 'dart:math' hide [!String!], max;
  //
  // var x = min(0, 1);
  // ```
  //
  // #### Common fixes
  //
  // If a different name should be hidden, then correct the name. Otherwise,
  // remove the name from the list:
  //
  // ```dart
  // import 'dart:math' hide max;
  //
  // var x = min(0, 1);
  // ```
  static const HintCode UNDEFINED_HIDDEN_NAME = HintCode(
    'UNDEFINED_HIDDEN_NAME',
    "The library '{0}' doesn't export a member with the hidden name '{1}'.",
    correctionMessage: "Try removing the name from the list of hidden members.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the undefined parameter
   * 1: the name of the targeted member
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an annotation of the form
  // `@UnusedResult.unless(parameterDefined: parameterName)` specifies a
  // parameter name that isn't defined by the annotated function.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the function `f`
  // doesn't have a parameter named `b`:
  //
  // ```dart
  // import 'package:meta/meta.dart';
  //
  // @UseResult.unless(parameterDefined: [!'b'!])
  // int f([int? a]) => a ?? 0;
  // ```
  //
  // #### Common fixes
  //
  // Change the argument named `parameterDefined` to match the name of one of
  // the parameters to the function:
  //
  // ```dart
  // import 'package:meta/meta.dart';
  //
  // @UseResult.unless(parameterDefined: 'a')
  // int f([int? a]) => a ?? 0;
  // ```
  static const HintCode UNDEFINED_REFERENCED_PARAMETER = HintCode(
    'UNDEFINED_REFERENCED_PARAMETER',
    "The parameter '{0}' isn't defined by '{1}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the library being imported
   * 1: the name in the show clause that isn't defined in the library
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a show combinator includes a
  // name that isn't defined by the library being imported.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `dart:math` doesn't
  // define the name `String`:
  //
  // ```dart
  // import 'dart:math' show min, [!String!];
  //
  // var x = min(0, 1);
  // ```
  //
  // #### Common fixes
  //
  // If a different name should be shown, then correct the name. Otherwise,
  // remove the name from the list:
  //
  // ```dart
  // import 'dart:math' show min;
  //
  // var x = min(0, 1);
  // ```
  static const HintCode UNDEFINED_SHOWN_NAME = HintCode(
    'UNDEFINED_SHOWN_NAME',
    "The library '{0}' doesn't export a member with the shown name '{1}'.",
    correctionMessage: "Try removing the name from the list of shown members.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the non-diagnostic being ignored
   */
  static const HintCode UNIGNORABLE_IGNORE = HintCode(
    'UNIGNORABLE_IGNORE',
    "The diagnostic '{0}' can't be ignored.",
    correctionMessage:
        "Try removing the name from the list, or removing the whole comment if this is the only name in the list.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the value being cast is already
  // known to be of the type that it's being cast to.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `n` is already known to
  // be an `int` as a result of the `is` test:
  //
  // ```dart
  // void f(num n) {
  //   if (n is int) {
  //     ([!n as int!]).isEven;
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the unnecessary cast:
  //
  // ```dart
  // void f(num n) {
  //   if (n is int) {
  //     n.isEven;
  //   }
  // }
  // ```
  static const HintCode UNNECESSARY_CAST = HintCode(
    'UNNECESSARY_CAST',
    "Unnecessary cast.",
    correctionMessage: "Try removing the cast.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the diagnostic being ignored
   */
  static const HintCode UNNECESSARY_IGNORE = HintCode(
    'UNNECESSARY_IGNORE',
    "The diagnostic '{0}' isn't produced at this location so it doesn't need to be ignored.",
    correctionMessage:
        "Try removing the name from the list, or removing the whole comment if this is the only name in the list.",
  );

  /**
   * Parameters:
   * 0: the uri that is not necessary
   * 1: the uri that makes it unnecessary
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an import isn't needed because
  // all of the names that are imported and referenced within the importing
  // library are also visible through another import.
  //
  // #### Example
  //
  // Given a file named `a.dart` that contains the following:
  //
  // ```dart
  // %uri="lib/a.dart"
  // class A {}
  // ```
  //
  // And, given a file named `b.dart` that contains the following:
  //
  // ```dart
  // %uri="lib/b.dart"
  // export 'a.dart';
  //
  // class B {}
  // ```
  //
  // The following code produces this diagnostic because the class `A`, which is
  // imported from `a.dart`, is also imported from `b.dart`. Removing the import
  // of `a.dart` leaves the semantics unchanged:
  //
  // ```dart
  // import [!'a.dart'!];
  // import 'b.dart';
  //
  // void f(A a, B b) {}
  // ```
  //
  // #### Common fixes
  //
  // If the import isn't needed, then remove it.
  //
  // If some of the names imported by this import are intended to be used but
  // aren't yet, and if those names aren't imported by other imports, then add
  // the missing references to those names.
  static const HintCode UNNECESSARY_IMPORT = HintCode(
    'UNNECESSARY_IMPORT',
    "The import of '{0}' is unnecessary because all of the used elements are also provided by the import of '{1}'.",
    correctionMessage: "Try removing the import directive.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when there's a declaration of
  // `noSuchMethod`, the only thing the declaration does is invoke the
  // overridden declaration, and the overridden declaration isn't the
  // declaration in `Object`.
  //
  // Overriding the implementation of `Object`'s `noSuchMethod` (no matter what
  // the implementation does) signals to the analyzer that it shouldn't flag any
  // inherited abstract methods that aren't implemented in that class. This
  // works even if the overriding implementation is inherited from a superclass,
  // so there's no value to declare it again in a subclass.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the declaration of
  // `noSuchMethod` in `A` makes the declaration of `noSuchMethod` in `B`
  // unnecessary:
  //
  // ```dart
  // class A {
  //   @override
  //   dynamic noSuchMethod(x) => super.noSuchMethod(x);
  // }
  // class B extends A {
  //   @override
  //   dynamic [!noSuchMethod!](y) {
  //     return super.noSuchMethod(y);
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the unnecessary declaration:
  //
  // ```dart
  // class A {
  //   @override
  //   dynamic noSuchMethod(x) => super.noSuchMethod(x);
  // }
  // class B extends A {}
  // ```
  static const HintCode UNNECESSARY_NO_SUCH_METHOD = HintCode(
    'UNNECESSARY_NO_SUCH_METHOD',
    "Unnecessary 'noSuchMethod' declaration.",
    correctionMessage: "Try removing the declaration of 'noSuchMethod'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when it finds an equality comparison
  // (either `==` or `!=`) with one operand of `null` and the other operand
  // can't be `null`. Such comparisons are always either `true` or `false`, so
  // they serve no purpose.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because `x` can never be
  // `null`, so the comparison always evaluates to `true`:
  //
  // ```dart
  // void f(int x) {
  //   if (x [!!= null!]) {
  //     print(x);
  //   }
  // }
  // ```
  //
  // The following code produces this diagnostic because `x` can never be
  // `null`, so the comparison always evaluates to `false`:
  //
  // ```dart
  // void f(int x) {
  //   if (x [!== null!]) {
  //     throw ArgumentError("x can't be null");
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the other operand should be able to be `null`, then change the type of
  // the operand:
  //
  // ```dart
  // void f(int? x) {
  //   if (x != null) {
  //     print(x);
  //   }
  // }
  // ```
  //
  // If the other operand really can't be `null`, then remove the condition:
  //
  // ```dart
  // void f(int x) {
  //   print(x);
  // }
  // ```
  static const HintCode UNNECESSARY_NULL_COMPARISON_FALSE = HintCode(
    'UNNECESSARY_NULL_COMPARISON',
    "The operand can't be null, so the condition is always false.",
    correctionMessage:
        "Try removing the condition, an enclosing condition, or the whole conditional statement.",
    hasPublishedDocs: true,
    uniqueName: 'UNNECESSARY_NULL_COMPARISON_FALSE',
  );

  /**
   * No parameters.
   */
  static const HintCode UNNECESSARY_NULL_COMPARISON_TRUE = HintCode(
    'UNNECESSARY_NULL_COMPARISON',
    "The operand can't be null, so the condition is always true.",
    correctionMessage: "Remove the condition.",
    hasPublishedDocs: true,
    uniqueName: 'UNNECESSARY_NULL_COMPARISON_TRUE',
  );

  /**
   * Parameters:
   * 0: the name of the type
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when either the type `dynamic` or the
  // type `Null` is followed by a question mark. Both of these types are
  // inherently nullable so the question mark doesn't change the semantics.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the question mark
  // following `dynamic` isn't necessary:
  //
  // ```dart
  // dynamic[!?!] x;
  // ```
  //
  // #### Common fixes
  //
  // Remove the unneeded question mark:
  //
  // ```dart
  // dynamic x;
  // ```
  static const HintCode UNNECESSARY_QUESTION_MARK = HintCode(
    'UNNECESSARY_QUESTION_MARK',
    "The '?' is unnecessary because '{0}' is nullable without it.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the value of a type check (using
  // either `is` or `is!`) is known at compile time.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the test `a is Object?`
  // is always `true`:
  //
  // ```dart
  // bool f<T>(T a) => [!a is Object?!];
  // ```
  //
  // #### Common fixes
  //
  // If the type check doesn't check what you intended to check, then change the
  // test:
  //
  // ```dart
  // bool f<T>(T a) => a is Object;
  // ```
  //
  // If the type check does check what you intended to check, then replace the
  // type check with its known value or completely remove it:
  //
  // ```dart
  // bool f<T>(T a) => true;
  // ```
  static const HintCode UNNECESSARY_TYPE_CHECK_FALSE = HintCode(
    'UNNECESSARY_TYPE_CHECK',
    "Unnecessary type check; the result is always 'false'.",
    correctionMessage:
        "Try correcting the type check, or removing the type check.",
    hasPublishedDocs: true,
    uniqueName: 'UNNECESSARY_TYPE_CHECK_FALSE',
  );

  /**
   * No parameters.
   */
  static const HintCode UNNECESSARY_TYPE_CHECK_TRUE = HintCode(
    'UNNECESSARY_TYPE_CHECK',
    "Unnecessary type check; the result is always 'true'.",
    correctionMessage:
        "Try correcting the type check, or removing the type check.",
    hasPublishedDocs: true,
    uniqueName: 'UNNECESSARY_TYPE_CHECK_TRUE',
  );

  /**
   * Parameters:
   * 0: the name of the exception variable
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a `catch` clause is found, and
  // neither the exception parameter nor the optional stack trace parameter are
  // used in the `catch` block.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `e` isn't referenced:
  //
  // ```dart
  // void f() {
  //   try {
  //     int.parse(';');
  //   } on FormatException catch ([!e!]) {
  //     // ignored
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the unused `catch` clause:
  //
  // ```dart
  // void f() {
  //   try {
  //     int.parse(';');
  //   } on FormatException {
  //     // ignored
  //   }
  // }
  // ```
  static const HintCode UNUSED_CATCH_CLAUSE = HintCode(
    'UNUSED_CATCH_CLAUSE',
    "The exception variable '{0}' isn't used, so the 'catch' clause can be removed.",
    correctionMessage: "Try removing the catch clause.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the stack trace variable
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the stack trace parameter in a
  // `catch` clause isn't referenced within the body of the `catch` block.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `stackTrace` isn't
  // referenced:
  //
  // ```dart
  // void f() {
  //   try {
  //     // ...
  //   } catch (exception, [!stackTrace!]) {
  //     // ...
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If you need to reference the stack trace parameter, then add a reference to
  // it. Otherwise, remove it:
  //
  // ```dart
  // void f() {
  //   try {
  //     // ...
  //   } catch (exception) {
  //     // ...
  //   }
  // }
  // ```
  static const HintCode UNUSED_CATCH_STACK = HintCode(
    'UNUSED_CATCH_STACK',
    "The stack trace variable '{0}' isn't used and can be removed.",
    correctionMessage: "Try removing the stack trace variable, or using it.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name that is declared but not referenced
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a private declaration isn't
  // referenced in the library that contains the declaration. The following
  // kinds of declarations are analyzed:
  // - Private top-level declarations, such as classes, enums, mixins, typedefs,
  //   top-level variables, and top-level functions
  // - Private static and instance methods
  // - Optional parameters of private functions for which a value is never
  //   passed, even when the parameter doesn't have a private name
  //
  // #### Example
  //
  // Assuming that no code in the library references `_C`, the following code
  // produces this diagnostic:
  //
  // ```dart
  // class [!_C!] {}
  // ```
  //
  // Assuming that no code in the library passes a value for `y` in any
  // invocation of `_m`, the following code produces this diagnostic:
  //
  // ```dart
  // %language=2.9
  // class C {
  //   void _m(int x, [int [!y!]]) {}
  //
  //   void n() => _m(0);
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the declaration isn't needed, then remove it:
  //
  // ```dart
  // class C {
  //   void _m(int x) {}
  //
  //   void n() => _m(0);
  // }
  // ```
  //
  // If the declaration is intended to be used, then add the code to use it.
  static const HintCode UNUSED_ELEMENT = HintCode(
    'UNUSED_ELEMENT',
    "The declaration '{0}' isn't referenced.",
    correctionMessage: "Try removing the declaration of '{0}'.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the parameter that is declared but not used
   */
  static const HintCode UNUSED_ELEMENT_PARAMETER = HintCode(
    'UNUSED_ELEMENT',
    "A value for optional parameter '{0}' isn't ever given.",
    correctionMessage: "Try removing the unused parameter.",
    hasPublishedDocs: true,
    uniqueName: 'UNUSED_ELEMENT_PARAMETER',
  );

  /**
   * Parameters:
   * 0: the name of the unused field
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a private field is declared but
  // never read, even if it's written in one or more places.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the field
  // `_originalValue` isn't read anywhere in the library:
  //
  // ```dart
  // class C {
  //   final String [!_originalValue!];
  //   final String _currentValue;
  //
  //   C(this._originalValue) : _currentValue = _originalValue;
  //
  //   String get value => _currentValue;
  // }
  // ```
  //
  // It might appear that the field `_originalValue` is being read in the
  // initializer (`_currentValue = _originalValue`), but that is actually a
  // reference to the parameter of the same name, not a reference to the field.
  //
  // #### Common fixes
  //
  // If the field isn't needed, then remove it.
  //
  // If the field was intended to be used, then add the missing code.
  static const HintCode UNUSED_FIELD = HintCode(
    'UNUSED_FIELD',
    "The value of the field '{0}' isn't used.",
    correctionMessage: "Try removing the field, or using it.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the content of the unused import's uri
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an import isn't needed because
  // none of the names that are imported are referenced within the importing
  // library.
  //
  // #### Example
  //
  // The following code produces this diagnostic because nothing defined in
  // `dart:async` is referenced in the library:
  //
  // ```dart
  // import [!'dart:async'!];
  //
  // void main() {}
  // ```
  //
  // #### Common fixes
  //
  // If the import isn't needed, then remove it.
  //
  // If some of the imported names are intended to be used, then add the missing
  // code.
  static const HintCode UNUSED_IMPORT = HintCode(
    'UNUSED_IMPORT',
    "Unused import: '{0}'.",
    correctionMessage: "Try removing the import directive.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the label that isn't used
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a label that isn't used is
  // found.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the label `loop` isn't
  // referenced anywhere in the method:
  //
  // ```dart
  // void f(int limit) {
  //   [!loop:!] for (int i = 0; i < limit; i++) {
  //     print(i);
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the label isn't needed, then remove it:
  //
  // ```dart
  // void f(int limit) {
  //   for (int i = 0; i < limit; i++) {
  //     print(i);
  //   }
  // }
  // ```
  //
  // If the label is needed, then use it:
  //
  // ```dart
  // void f(int limit) {
  //   loop: for (int i = 0; i < limit; i++) {
  //     print(i);
  //     break loop;
  //   }
  // }
  // ```
  // TODO(brianwilkerson) Highlight the identifier without the colon.
  static const HintCode UNUSED_LABEL = HintCode(
    'UNUSED_LABEL',
    "The label '{0}' isn't used.",
    correctionMessage:
        "Try removing the label, or using it in either a 'break' or 'continue' statement.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the unused variable
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a local variable is declared but
  // never read, even if it's written in one or more places.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the value of `count` is
  // never read:
  //
  // ```dart
  // void main() {
  //   int [!count!] = 0;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the variable isn't needed, then remove it.
  //
  // If the variable was intended to be used, then add the missing code.
  static const HintCode UNUSED_LOCAL_VARIABLE = HintCode(
    'UNUSED_LOCAL_VARIABLE',
    "The value of the local variable '{0}' isn't used.",
    correctionMessage: "Try removing the variable or using it.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the annotated method, property or function
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a function annotated with
  // `useResult` is invoked, and the value returned by that function isn't used.
  // The value is considered to be used if a member of the value is invoked, if
  // the value is passed to another function, or if the value is assigned to a
  // variable or field.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the invocation of
  // `c.a()` isn't used, even though the method `a` is annotated with
  // `useResult`:
  //
  // ```dart
  // import 'package:meta/meta.dart';
  //
  // class C {
  //   @useResult
  //   int a() => 0;
  //
  //   int b() => 0;
  // }
  //
  // void f(C c) {
  //   c.[!a!]();
  // }
  // ```
  //
  // #### Common fixes
  //
  // If you intended to invoke the annotated function, then use the value that
  // was returned:
  //
  // ```dart
  // import 'package:meta/meta.dart';
  //
  // class C {
  //   @useResult
  //   int a() => 0;
  //
  //   int b() => 0;
  // }
  //
  // void f(C c) {
  //   print(c.a());
  // }
  // ```
  //
  // If you intended to invoke a different function, then correct the name of
  // the function being invoked:
  //
  // ```dart
  // import 'package:meta/meta.dart';
  //
  // class C {
  //   @useResult
  //   int a() => 0;
  //
  //   int b() => 0;
  // }
  //
  // void f(C c) {
  //   c.b();
  // }
  // ```
  static const HintCode UNUSED_RESULT = HintCode(
    'UNUSED_RESULT',
    "The value of '{0}' should be used.",
    correctionMessage:
        "Try using the result by invoking a member, passing it to a function, or returning it from this function.",
    hasPublishedDocs: true,
  );

  /**
   * The result of invoking a method, property, or function annotated with
   * `@useResult` must be used (assigned, passed to a function as an argument,
   * or returned by a function).
   *
   * Parameters:
   * 0: the name of the annotated method, property or function
   * 1: message details
   */
  static const HintCode UNUSED_RESULT_WITH_MESSAGE = HintCode(
    'UNUSED_RESULT',
    "'{0}' should be used. {1}.",
    correctionMessage:
        "Try using the result by invoking a member, passing it to a function, or returning it from this function.",
    hasPublishedDocs: true,
    uniqueName: 'UNUSED_RESULT_WITH_MESSAGE',
  );

  /**
   * Parameters:
   * 0: the name that is shown but not used
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a show combinator includes a
  // name that isn't used within the library. Because it isn't referenced, the
  // name can be removed.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the function `max`
  // isn't used:
  //
  // ```dart
  // import 'dart:math' show min, [!max!];
  //
  // var x = min(0, 1);
  // ```
  //
  // #### Common fixes
  //
  // Either use the name or remove it:
  //
  // ```dart
  // import 'dart:math' show min;
  //
  // var x = min(0, 1);
  // ```
  static const HintCode UNUSED_SHOWN_NAME = HintCode(
    'UNUSED_SHOWN_NAME',
    "The name {0} is shown, but isn’t used.",
    correctionMessage: "Try removing the name from the list of shown members.",
    hasPublishedDocs: true,
  );

  /// Initialize a newly created error code to have the given [name].
  const HintCode(
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
          uniqueName: 'HintCode.${uniqueName ?? name}',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorType.HINT.severity;

  @override
  ErrorType get type => ErrorType.HINT;
}
