// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

import "package:analyzer/error/error.dart";
import "package:analyzer/src/error/analyzer_error_code.dart";

class HintCode extends AnalyzerErrorCode {
  ///  Parameters:
  ///  0: the name of the actual argument type
  ///  1: the name of the expected function return type
  static const HintCode ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER =
      HintCode(
    'ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER',
    "The argument type '{0}' can't be assigned to the parameter type '{1} "
        "Function(Object)' or '{1} Function(Object, StackTrace)'.",
    hasPublishedDocs: true,
  );

  ///  Users should not assign values marked `@doNotStore`.
  static const HintCode ASSIGNMENT_OF_DO_NOT_STORE = HintCode(
    'ASSIGNMENT_OF_DO_NOT_STORE',
    "'{0}' is marked 'doNotStore' and shouldn't be assigned to a field or "
        "top-level variable.",
    correctionMessage: "Try removing the assignment.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the declared return type
  static const HintCode BODY_MIGHT_COMPLETE_NORMALLY_NULLABLE = HintCode(
    'BODY_MIGHT_COMPLETE_NORMALLY_NULLABLE',
    "This function has a nullable return type of '{0}', but ends without "
        "returning a value.",
    correctionMessage:
        "Try adding a return statement, or if no value is ever returned, try "
        "changing the return type to 'void'.",
  );

  ///  When the target expression uses '?.' operator, it can be `null`, so all the
  ///  subsequent invocations should also use '?.' operator.
  static const HintCode CAN_BE_NULL_AFTER_NULL_AWARE = HintCode(
    'CAN_BE_NULL_AFTER_NULL_AWARE',
    "The receiver uses '?.', so its value can be null.",
    correctionMessage: "Replace the '.' with a '?.' in the invocation.",
  );

  ///  Dead code is code that is never reached, this can happen for instance if a
  ///  statement follows a return statement.
  ///
  ///  No parameters.
  static const HintCode DEAD_CODE = HintCode(
    'DEAD_CODE',
    "Dead code.",
    correctionMessage:
        "Try removing the code, or fixing the code before it so that it can be "
        "reached.",
    hasPublishedDocs: true,
  );

  ///  Dead code is code that is never reached. This case covers cases where the
  ///  user has catch clauses after `catch (e)` or `on Object catch (e)`.
  ///
  ///  No parameters.
  static const HintCode DEAD_CODE_CATCH_FOLLOWING_CATCH = HintCode(
    'DEAD_CODE_CATCH_FOLLOWING_CATCH',
    "Dead code: Catch clauses after a 'catch (e)' or an 'on Object catch (e)' "
        "are never reached.",
    correctionMessage:
        "Try reordering the catch clauses so that they can be reached, or "
        "removing the unreachable catch clauses.",
    hasPublishedDocs: true,
  );

  ///  Dead code is code that is never reached. This case covers cases where the
  ///  user has an on-catch clause such as `on A catch (e)`, where a supertype of
  ///  `A` was already caught.
  ///
  ///  Parameters:
  ///  0: name of the subtype
  ///  1: name of the supertype
  static const HintCode DEAD_CODE_ON_CATCH_SUBTYPE = HintCode(
    'DEAD_CODE_ON_CATCH_SUBTYPE',
    "Dead code: This on-catch block won’t be executed because '{0}' is a "
        "subtype of '{1}' and hence will have been caught already.",
    correctionMessage:
        "Try reordering the catch clauses so that this block can be reached, "
        "or removing the unreachable catch clause.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the element
  static const HintCode DEPRECATED_EXPORT_USE = HintCode(
    'DEPRECATED_EXPORT_USE',
    "The ability to import '{0}' indirectly has been deprecated.",
    correctionMessage: "Try importing '{0}' directly.",
  );

  ///  No parameters.
  static const HintCode DEPRECATED_EXTENDS_FUNCTION = HintCode(
    'DEPRECATED_SUBTYPE_OF_FUNCTION',
    "Extending 'Function' is deprecated.",
    correctionMessage: "Try removing 'Function' from the 'extends' clause.",
    hasPublishedDocs: true,
    uniqueName: 'DEPRECATED_EXTENDS_FUNCTION',
  );

  ///  No parameters.
  static const HintCode DEPRECATED_IMPLEMENTS_FUNCTION = HintCode(
    'DEPRECATED_SUBTYPE_OF_FUNCTION',
    "Implementing 'Function' has no effect.",
    correctionMessage: "Try removing 'Function' from the 'implements' clause.",
    hasPublishedDocs: true,
    uniqueName: 'DEPRECATED_IMPLEMENTS_FUNCTION',
  );

  ///  Parameters:
  ///  0: the name of the member
  static const HintCode DEPRECATED_MEMBER_USE = HintCode(
    'DEPRECATED_MEMBER_USE',
    "'{0}' is deprecated and shouldn't be used.",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the member
  static const HintCode DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE = HintCode(
    'DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE',
    "'{0}' is deprecated and shouldn't be used.",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the member
  ///  1: message details
  static const HintCode DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE =
      HintCode(
    'DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE',
    "'{0}' is deprecated and shouldn't be used. {1}.",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
    uniqueName: 'DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE',
  );

  ///  Parameters:
  ///  0: the name of the member
  ///  1: message details
  static const HintCode DEPRECATED_MEMBER_USE_WITH_MESSAGE = HintCode(
    'DEPRECATED_MEMBER_USE',
    "'{0}' is deprecated and shouldn't be used. {1}.",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
    uniqueName: 'DEPRECATED_MEMBER_USE_WITH_MESSAGE',
  );

  ///  No parameters.
  static const HintCode DEPRECATED_MIXIN_FUNCTION = HintCode(
    'DEPRECATED_SUBTYPE_OF_FUNCTION',
    "Mixing in 'Function' is deprecated.",
    correctionMessage: "Try removing 'Function' from the 'with' clause.",
    hasPublishedDocs: true,
    uniqueName: 'DEPRECATED_MIXIN_FUNCTION',
  );

  ///  No parameters.
  static const HintCode DEPRECATED_NEW_IN_COMMENT_REFERENCE = HintCode(
    'DEPRECATED_NEW_IN_COMMENT_REFERENCE',
    "Using the 'new' keyword in a comment reference is deprecated.",
    correctionMessage: "Try referring to a constructor by its name.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode DIVISION_OPTIMIZATION = HintCode(
    'DIVISION_OPTIMIZATION',
    "The operator x ~/ y is more efficient than (x / y).toInt().",
    correctionMessage:
        "Try re-writing the expression to use the '~/' operator.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode DUPLICATE_HIDDEN_NAME = HintCode(
    'DUPLICATE_HIDDEN_NAME',
    "Duplicate hidden name.",
    correctionMessage:
        "Try removing the repeated name from the list of hidden members.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the diagnostic being ignored
  static const HintCode DUPLICATE_IGNORE = HintCode(
    'DUPLICATE_IGNORE',
    "The diagnostic '{0}' doesn't need to be ignored here because it's already "
        "being ignored.",
    correctionMessage:
        "Try removing the name from the list, or removing the whole comment if "
        "this is the only name in the list.",
    hasPublishedDocs: true,
  );

  ///  Duplicate imports.
  ///
  ///  No parameters.
  static const HintCode DUPLICATE_IMPORT = HintCode(
    'DUPLICATE_IMPORT',
    "Duplicate import.",
    correctionMessage: "Try removing all but one import of the library.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode DUPLICATE_SHOWN_NAME = HintCode(
    'DUPLICATE_SHOWN_NAME',
    "Duplicate shown name.",
    correctionMessage:
        "Try removing the repeated name from the list of shown members.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode EQUAL_ELEMENTS_IN_SET = HintCode(
    'EQUAL_ELEMENTS_IN_SET',
    "Two elements in a set literal shouldn't be equal.",
    correctionMessage: "Change or remove the duplicate element.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode EQUAL_KEYS_IN_MAP = HintCode(
    'EQUAL_KEYS_IN_MAP',
    "Two keys in a map literal shouldn't be equal.",
    correctionMessage: "Change or remove the duplicate key.",
    hasPublishedDocs: true,
  );

  ///  It is a bad practice for a source file in a package "lib" directory
  ///  hierarchy to traverse outside that directory hierarchy. For example, a
  ///  source file in the "lib" directory should not contain a directive such as
  ///  `import '../web/some.dart'` which references a file outside the lib
  ///  directory.
  static const HintCode FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE =
      HintCode(
    'FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE',
    "A file in the 'lib' directory shouldn't import a file outside the 'lib' "
        "directory.",
    correctionMessage:
        "Try removing the import, or moving the imported file inside the 'lib' "
        "directory.",
  );

  ///  It is a bad practice for a source file ouside a package "lib" directory
  ///  hierarchy to traverse into that directory hierarchy. For example, a source
  ///  file in the "web" directory should not contain a directive such as
  ///  `import '../lib/some.dart'` which references a file inside the lib
  ///  directory.
  static const HintCode FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE =
      HintCode(
    'FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE',
    "A file outside the 'lib' directory shouldn't reference a file inside the "
        "'lib' directory using a relative path.",
    correctionMessage: "Try using a 'package:' URI instead.",
  );

  ///  No parameters.
  static const HintCode IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION = HintCode(
    'IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION',
    "The imported library defines a top-level function named 'loadLibrary' "
        "that is hidden by deferring this library.",
    correctionMessage:
        "Try changing the import to not be deferred, or rename the function in "
        "the imported library.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  ///
  ///  https://github.com/dart-lang/sdk/issues/44063
  static const HintCode IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE = HintCode(
    'IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE',
    "The library '{0}' is legacy, and shouldn't be imported into a null safe "
        "library.",
    correctionMessage: "Try migrating the imported library.",
    hasPublishedDocs: true,
  );

  ///  When "strict-inference" is enabled, collection literal types must be
  ///  inferred via the context type, or have type arguments.
  static const HintCode INFERENCE_FAILURE_ON_COLLECTION_LITERAL = HintCode(
    'INFERENCE_FAILURE_ON_COLLECTION_LITERAL',
    "The type argument(s) of '{0}' can't be inferred.",
    correctionMessage: "Use explicit type argument(s) for '{0}'.",
  );

  ///  When "strict-inference" is enabled, types in function invocations must be
  ///  inferred via the context type, or have type arguments.
  static const HintCode INFERENCE_FAILURE_ON_FUNCTION_INVOCATION = HintCode(
    'INFERENCE_FAILURE_ON_FUNCTION_INVOCATION',
    "The type argument(s) of the function '{0}' can't be inferred.",
    correctionMessage: "Use explicit type argument(s) for '{0}'.",
  );

  ///  When "strict-inference" is enabled, recursive local functions, top-level
  ///  functions, methods, and function-typed function parameters must all
  ///  specify a return type. See the strict-inference resource:
  ///
  ///  https://github.com/dart-lang/language/blob/master/resources/type-system/strict-inference.md
  static const HintCode INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE = HintCode(
    'INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE',
    "The return type of '{0}' cannot be inferred.",
    correctionMessage: "Declare the return type of '{0}'.",
  );

  ///  When "strict-inference" is enabled, types in function invocations must be
  ///  inferred via the context type, or have type arguments.
  static const HintCode INFERENCE_FAILURE_ON_GENERIC_INVOCATION = HintCode(
    'INFERENCE_FAILURE_ON_GENERIC_INVOCATION',
    "The type argument(s) of the generic function type '{0}' can't be "
        "inferred.",
    correctionMessage: "Use explicit type argument(s) for '{0}'.",
  );

  ///  When "strict-inference" is enabled, types in instance creation
  ///  (constructor calls) must be inferred via the context type, or have type
  ///  arguments.
  static const HintCode INFERENCE_FAILURE_ON_INSTANCE_CREATION = HintCode(
    'INFERENCE_FAILURE_ON_INSTANCE_CREATION',
    "The type argument(s) of the constructor '{0}' can't be inferred.",
    correctionMessage: "Use explicit type argument(s) for '{0}'.",
  );

  ///  When "strict-inference" in enabled, uninitialized variables must be
  ///  declared with a specific type.
  static const HintCode INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE = HintCode(
    'INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE',
    "The type of {0} can't be inferred without either a type or initializer.",
    correctionMessage: "Try specifying the type of the variable.",
  );

  ///  When "strict-inference" in enabled, function parameters must be
  ///  declared with a specific type, or inherit a type.
  static const HintCode INFERENCE_FAILURE_ON_UNTYPED_PARAMETER = HintCode(
    'INFERENCE_FAILURE_ON_UNTYPED_PARAMETER',
    "The type of {0} can't be inferred; a type must be explicitly provided.",
    correctionMessage: "Try specifying the type of the parameter.",
  );

  ///  Parameters:
  ///  0: the name of the annotation
  ///  1: the list of valid targets
  static const HintCode INVALID_ANNOTATION_TARGET = HintCode(
    'INVALID_ANNOTATION_TARGET',
    "The annotation '{0}' can only be used on {1}.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the element
  static const HintCode INVALID_EXPORT_OF_INTERNAL_ELEMENT = HintCode(
    'INVALID_EXPORT_OF_INTERNAL_ELEMENT',
    "The member '{0}' can't be exported as a part of a package's public API.",
    correctionMessage: "Try using a hide clause to hide '{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the element
  static const HintCode INVALID_EXPORT_OF_INTERNAL_ELEMENT_INDIRECTLY =
      HintCode(
    'INVALID_EXPORT_OF_INTERNAL_ELEMENT_INDIRECTLY',
    "The member '{0}' can't be exported as a part of a package's public API, "
        "but is indirectly exported as part of the signature of '{1}'.",
    correctionMessage: "Try using a hide clause to hide '{0}'.",
    hasPublishedDocs: true,
  );

  ///  This hint is generated anywhere a @factory annotation is associated with
  ///  anything other than a method.
  static const HintCode INVALID_FACTORY_ANNOTATION = HintCode(
    'INVALID_FACTORY_ANNOTATION',
    "Only methods can be annotated as factories.",
  );

  ///  Parameters:
  ///  0: The name of the method
  static const HintCode INVALID_FACTORY_METHOD_DECL = HintCode(
    'INVALID_FACTORY_METHOD_DECL',
    "Factory method '{0}' must have a return type.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the method
  static const HintCode INVALID_FACTORY_METHOD_IMPL = HintCode(
    'INVALID_FACTORY_METHOD_IMPL',
    "Factory method '{0}' doesn't return a newly allocated object.",
    hasPublishedDocs: true,
  );

  ///  This hint is generated anywhere an @immutable annotation is associated with
  ///  anything other than a class.
  static const HintCode INVALID_IMMUTABLE_ANNOTATION = HintCode(
    'INVALID_IMMUTABLE_ANNOTATION',
    "Only classes can be annotated as being immutable.",
  );

  ///  No parameters.
  static const HintCode INVALID_INTERNAL_ANNOTATION = HintCode(
    'INVALID_INTERNAL_ANNOTATION',
    "Only public elements in a package's private API can be annotated as being "
        "internal.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode INVALID_LANGUAGE_VERSION_OVERRIDE_AT_SIGN = HintCode(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The Dart language version override number must begin with '@dart'.",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// "
        "@dart = 2.0'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_AT_SIGN',
  );

  ///  No parameters.
  static const HintCode INVALID_LANGUAGE_VERSION_OVERRIDE_EQUALS = HintCode(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The Dart language version override comment must be specified with an '=' "
        "character.",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// "
        "@dart = 2.0'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_EQUALS',
  );

  static const HintCode INVALID_LANGUAGE_VERSION_OVERRIDE_GREATER = HintCode(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The language version override can't specify a version greater than the "
        "latest known language version: {0}.{1}.",
    correctionMessage: "Try removing the language version override.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_GREATER',
  );

  static const HintCode INVALID_LANGUAGE_VERSION_OVERRIDE_LOCATION = HintCode(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The language version override must be specified before any declaration or "
        "directive.",
    correctionMessage:
        "Try moving the language version override to the top of the file.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_LOCATION',
  );

  ///  No parameters.
  static const HintCode INVALID_LANGUAGE_VERSION_OVERRIDE_LOWER_CASE = HintCode(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The Dart language version override comment must be specified with the "
        "word 'dart' in all lower case.",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// "
        "@dart = 2.0'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_LOWER_CASE',
  );

  ///  No parameters.
  static const HintCode INVALID_LANGUAGE_VERSION_OVERRIDE_NUMBER = HintCode(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The Dart language version override comment must be specified with a "
        "version number, like '2.0', after the '=' character.",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// "
        "@dart = 2.0'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_NUMBER',
  );

  ///  No parameters.
  static const HintCode INVALID_LANGUAGE_VERSION_OVERRIDE_PREFIX = HintCode(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The Dart language version override number can't be prefixed with a "
        "letter.",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// "
        "@dart = 2.0'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_PREFIX',
  );

  ///  No parameters.
  static const HintCode INVALID_LANGUAGE_VERSION_OVERRIDE_TRAILING_CHARACTERS =
      HintCode(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The Dart language version override comment can't be followed by any "
        "non-whitespace characters.",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// "
        "@dart = 2.0'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_TRAILING_CHARACTERS',
  );

  ///  No parameters.
  static const HintCode INVALID_LANGUAGE_VERSION_OVERRIDE_TWO_SLASHES =
      HintCode(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The Dart language version override comment must be specified with exactly "
        "two slashes.",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// "
        "@dart = 2.0'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_TWO_SLASHES',
  );

  ///  No parameters.
  static const HintCode INVALID_LITERAL_ANNOTATION = HintCode(
    'INVALID_LITERAL_ANNOTATION',
    "Only const constructors can have the `@literal` annotation.",
    hasPublishedDocs: true,
  );

  ///  This hint is generated anywhere where `@nonVirtual` annotates something
  ///  other than a non-abstract instance member in a class or mixin.
  ///
  ///  No Parameters.
  static const HintCode INVALID_NON_VIRTUAL_ANNOTATION = HintCode(
    'INVALID_NON_VIRTUAL_ANNOTATION',
    "The annotation '@nonVirtual' can only be applied to a concrete instance "
        "member.",
    correctionMessage: "Try removing '@nonVirtual'.",
    hasPublishedDocs: true,
  );

  ///  This hint is generated anywhere where an instance member annotated with
  ///  `@nonVirtual` is overridden in a subclass.
  ///
  ///  Parameters:
  ///  0: the name of the member
  ///  1: the name of the defining class
  static const HintCode INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER = HintCode(
    'INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER',
    "The member '{0}' is declared non-virtual in '{1}' and can't be overridden "
        "in subclasses.",
    hasPublishedDocs: true,
  );

  ///  This hint is generated anywhere where `@required` annotates a named
  ///  parameter with a default value.
  ///
  ///  Parameters:
  ///  0: the name of the member
  static const HintCode INVALID_REQUIRED_NAMED_PARAM = HintCode(
    'INVALID_REQUIRED_NAMED_PARAM',
    "The type parameter '{0}' is annotated with @required but only named "
        "parameters without a default value can be annotated with it.",
    correctionMessage: "Remove @required.",
  );

  ///  This hint is generated anywhere where `@required` annotates an optional
  ///  positional parameter.
  ///
  ///  Parameters:
  ///  0: the name of the member
  static const HintCode INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM = HintCode(
    'INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM',
    "Incorrect use of the annotation @required on the optional positional "
        "parameter '{0}'. Optional positional parameters cannot be required.",
    correctionMessage: "Remove @required.",
  );

  ///  This hint is generated anywhere where `@required` annotates a non optional
  ///  positional parameter.
  ///
  ///  Parameters:
  ///  0: the name of the member
  static const HintCode INVALID_REQUIRED_POSITIONAL_PARAM = HintCode(
    'INVALID_REQUIRED_POSITIONAL_PARAM',
    "Redundant use of the annotation @required on the required positional "
        "parameter '{0}'.",
    correctionMessage: "Remove @required.",
  );

  ///  This hint is generated anywhere where `@sealed` annotates something other
  ///  than a class.
  ///
  ///  No parameters.
  static const HintCode INVALID_SEALED_ANNOTATION = HintCode(
    'INVALID_SEALED_ANNOTATION',
    "The annotation '@sealed' can only be applied to classes.",
    correctionMessage: "Try removing the '@sealed' annotation.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the member
  static const HintCode INVALID_USE_OF_INTERNAL_MEMBER = HintCode(
    'INVALID_USE_OF_INTERNAL_MEMBER',
    "The member '{0}' can only be used within its package.",
    hasPublishedDocs: true,
  );

  ///  This hint is generated anywhere where a member annotated with `@protected`
  ///  is used outside of an instance member of a subclass.
  ///
  ///  Parameters:
  ///  0: the name of the member
  ///  1: the name of the defining class
  static const HintCode INVALID_USE_OF_PROTECTED_MEMBER = HintCode(
    'INVALID_USE_OF_PROTECTED_MEMBER',
    "The member '{0}' can only be used within instance members of subclasses "
        "of '{1}'.",
  );

  ///  Parameters:
  ///  0: the name of the member
  static const HintCode INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER = HintCode(
    'INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER',
    "The member '{0}' can only be used for overriding.",
    hasPublishedDocs: true,
  );

  ///  This hint is generated anywhere where a member annotated with
  ///  `@visibleForTemplate` is used outside of a "template" Dart file.
  ///
  ///  Parameters:
  ///  0: the name of the member
  ///  1: the name of the defining class
  static const HintCode INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER = HintCode(
    'INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER',
    "The member '{0}' can only be used within '{1}' or a template library.",
  );

  ///  This hint is generated anywhere where a member annotated with
  ///  `@visibleForTesting` is used outside the defining library, or a test.
  ///
  ///  Parameters:
  ///  0: the name of the member
  ///  1: the name of the defining class
  static const HintCode INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER = HintCode(
    'INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER',
    "The member '{0}' can only be used within '{1}' or a test.",
    hasPublishedDocs: true,
  );

  ///  This hint is generated anywhere where a private declaration is annotated
  ///  with `@visibleForTemplate` or `@visibleForTesting`.
  ///
  ///  Parameters:
  ///  0: the name of the member
  ///  1: the name of the annotation
  static const HintCode INVALID_VISIBILITY_ANNOTATION = HintCode(
    'INVALID_VISIBILITY_ANNOTATION',
    "The member '{0}' is annotated with '{1}', but this annotation is only "
        "meaningful on declarations of public members.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode INVALID_VISIBLE_FOR_OVERRIDING_ANNOTATION = HintCode(
    'INVALID_VISIBLE_FOR_OVERRIDING_ANNOTATION',
    "The annotation 'visibleForOverriding' can only be applied to a public "
        "instance member that can be overridden.",
    hasPublishedDocs: true,
  );

  ///  Generate a hint for a constructor, function or method invocation where a
  ///  required parameter is missing.
  ///
  ///  Parameters:
  ///  0: the name of the parameter
  static const HintCode MISSING_REQUIRED_PARAM = HintCode(
    'MISSING_REQUIRED_PARAM',
    "The parameter '{0}' is required.",
    hasPublishedDocs: true,
  );

  ///  Generate a hint for a constructor, function or method invocation where a
  ///  required parameter is missing.
  ///
  ///  Parameters:
  ///  0: the name of the parameter
  ///  1: message details
  static const HintCode MISSING_REQUIRED_PARAM_WITH_DETAILS = HintCode(
    'MISSING_REQUIRED_PARAM',
    "The parameter '{0}' is required. {1}.",
    hasPublishedDocs: true,
    uniqueName: 'MISSING_REQUIRED_PARAM_WITH_DETAILS',
  );

  ///  Parameters:
  ///  0: the name of the declared return type
  static const HintCode MISSING_RETURN = HintCode(
    'MISSING_RETURN',
    "This function has a return type of '{0}', but doesn't end with a return "
        "statement.",
    correctionMessage:
        "Try adding a return statement, or changing the return type to 'void'.",
    hasPublishedDocs: true,
  );

  ///  This hint is generated anywhere where a `@sealed` class is used as a
  ///  a superclass constraint of a mixin.
  ///
  ///  Parameters:
  ///  0: the name of the sealed class
  static const HintCode MIXIN_ON_SEALED_CLASS = HintCode(
    'MIXIN_ON_SEALED_CLASS',
    "The class '{0}' shouldn't be used as a mixin constraint because it is "
        "sealed, and any class mixing in this mixin must have '{0}' as a "
        "superclass.",
    correctionMessage:
        "Try composing with this class, or refer to its documentation for more "
        "information.",
    hasPublishedDocs: true,
  );

  ///  Generate a hint for classes that inherit from classes annotated with
  ///  `@immutable` but that are not immutable.
  static const HintCode MUST_BE_IMMUTABLE = HintCode(
    'MUST_BE_IMMUTABLE',
    "This class (or a class that this class inherits from) is marked as "
        "'@immutable', but one or more of its instance fields aren't final: "
        "{0}",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the class declaring the overridden method
  static const HintCode MUST_CALL_SUPER = HintCode(
    'MUST_CALL_SUPER',
    "This method overrides a method annotated as '@mustCallSuper' in '{0}', "
        "but doesn't invoke the overridden method.",
    hasPublishedDocs: true,
  );

  ///  Generate a hint for non-const instance creation using a constructor
  ///  annotated with `@literal`.
  ///
  ///  Parameters:
  ///  0: the name of the class defining the annotated constructor
  static const HintCode NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR = HintCode(
    'NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR',
    "This instance creation must be 'const', because the {0} constructor is "
        "marked as '@literal'.",
    correctionMessage: "Try adding a 'const' keyword.",
    hasPublishedDocs: true,
  );

  ///  Generate a hint for non-const instance creation (with the `new` keyword)
  ///  using a constructor annotated with `@literal`.
  ///
  ///  Parameters:
  ///  0: the name of the class defining the annotated constructor
  static const HintCode NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR_USING_NEW =
      HintCode(
    'NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR',
    "This instance creation must be 'const', because the {0} constructor is "
        "marked as '@literal'.",
    correctionMessage: "Try replacing the 'new' keyword with 'const'.",
    hasPublishedDocs: true,
    uniqueName: 'NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR_USING_NEW',
  );

  ///  No parameters.
  static const HintCode NULLABLE_TYPE_IN_CATCH_CLAUSE = HintCode(
    'NULLABLE_TYPE_IN_CATCH_CLAUSE',
    "A potentially nullable type can't be used in an 'on' clause because it "
        "isn't valid to throw a nullable expression.",
    correctionMessage: "Try using a non-nullable type.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the method being invoked
  ///  1: the type argument associated with the method
  static const HintCode NULL_ARGUMENT_TO_NON_NULL_TYPE = HintCode(
    'NULL_ARGUMENT_TO_NON_NULL_TYPE',
    "'{0}' shouldn't be called with a null argument for the non-nullable type "
        "argument '{1}'.",
    correctionMessage: "Try adding a non-null argument.",
    hasPublishedDocs: true,
  );

  ///  When the left operand of a binary expression uses '?.' operator, it can be
  ///  `null`.
  static const HintCode NULL_AWARE_BEFORE_OPERATOR = HintCode(
    'NULL_AWARE_BEFORE_OPERATOR',
    "The left operand uses '?.', so its value can be null.",
  );

  ///  A condition in a control flow statement could evaluate to `null` because it
  ///  uses the null-aware '?.' operator.
  static const HintCode NULL_AWARE_IN_CONDITION = HintCode(
    'NULL_AWARE_IN_CONDITION',
    "The value of the '?.' operator can be 'null', which isn't appropriate in "
        "a condition.",
    correctionMessage:
        "Try replacing the '?.' with a '.', testing the left-hand side for "
        "null if necessary.",
  );

  ///  A condition in operands of a logical operator could evaluate to `null`
  ///  because it uses the null-aware '?.' operator.
  static const HintCode NULL_AWARE_IN_LOGICAL_OPERATOR = HintCode(
    'NULL_AWARE_IN_LOGICAL_OPERATOR',
    "The value of the '?.' operator can be 'null', which isn't appropriate as "
        "an operand of a logical operator.",
  );

  ///  No parameters.
  static const HintCode NULL_CHECK_ALWAYS_FAILS = HintCode(
    'NULL_CHECK_ALWAYS_FAILS',
    "This null-check will always throw an exception because the expression "
        "will always evaluate to 'null'.",
    hasPublishedDocs: true,
  );

  ///  A field with the override annotation does not override a getter or setter.
  ///
  ///  No parameters.
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_FIELD = HintCode(
    'OVERRIDE_ON_NON_OVERRIDING_MEMBER',
    "The field doesn't override an inherited getter or setter.",
    correctionMessage:
        "Try updating this class to match the superclass, or removing the "
        "override annotation.",
    hasPublishedDocs: true,
    uniqueName: 'OVERRIDE_ON_NON_OVERRIDING_FIELD',
  );

  ///  A getter with the override annotation does not override an existing getter.
  ///
  ///  No parameters.
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_GETTER = HintCode(
    'OVERRIDE_ON_NON_OVERRIDING_MEMBER',
    "The getter doesn't override an inherited getter.",
    correctionMessage:
        "Try updating this class to match the superclass, or removing the "
        "override annotation.",
    hasPublishedDocs: true,
    uniqueName: 'OVERRIDE_ON_NON_OVERRIDING_GETTER',
  );

  ///  A method with the override annotation does not override an existing method.
  ///
  ///  No parameters.
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_METHOD = HintCode(
    'OVERRIDE_ON_NON_OVERRIDING_MEMBER',
    "The method doesn't override an inherited method.",
    correctionMessage:
        "Try updating this class to match the superclass, or removing the "
        "override annotation.",
    hasPublishedDocs: true,
    uniqueName: 'OVERRIDE_ON_NON_OVERRIDING_METHOD',
  );

  ///  A setter with the override annotation does not override an existing setter.
  ///
  ///  No parameters.
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_SETTER = HintCode(
    'OVERRIDE_ON_NON_OVERRIDING_MEMBER',
    "The setter doesn't override an inherited setter.",
    correctionMessage:
        "Try updating this class to match the superclass, or removing the "
        "override annotation.",
    hasPublishedDocs: true,
    uniqueName: 'OVERRIDE_ON_NON_OVERRIDING_SETTER',
  );

  ///  It is a bad practice for a package import to reference anything outside the
  ///  given package, or more generally, it is bad practice for a package import
  ///  to contain a "..". For example, a source file should not contain a
  ///  directive such as `import 'package:foo/../some.dart'`.
  static const HintCode PACKAGE_IMPORT_CONTAINS_DOT_DOT = HintCode(
    'PACKAGE_IMPORT_CONTAINS_DOT_DOT',
    "A package import shouldn't contain '..'.",
  );

  ///  It is not an error to call or tear-off a method, setter, or getter, or to
  ///  read or write a field, on a receiver of static type `Never`.
  ///  Implementations that provide feedback about dead or unreachable code are
  ///  encouraged to indicate that any arguments to the invocation are
  ///  unreachable.
  ///
  ///  It is not an error to apply an expression of type `Never` in the function
  ///  position of a function call. Implementations that provide feedback about
  ///  dead or unreachable code are encouraged to indicate that any arguments to
  ///  the call are unreachable.
  ///
  ///  Parameters: none
  static const HintCode RECEIVER_OF_TYPE_NEVER = HintCode(
    'RECEIVER_OF_TYPE_NEVER',
    "The receiver is of type 'Never', and will never complete with a value.",
    correctionMessage:
        "Try checking for throw expressions or type errors in the receiver",
  );

  ///  Parameters:
  ///  0: the name of the annotated function being invoked
  ///  1: the name of the function containing the return
  static const HintCode RETURN_OF_DO_NOT_STORE = HintCode(
    'RETURN_OF_DO_NOT_STORE',
    "'{0}' is annotated with 'doNotStore' and shouldn't be returned unless "
        "'{1}' is also annotated.",
    correctionMessage: "Annotate '{1}' with 'doNotStore'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the return type as declared in the return statement
  ///  1: the expected return type as defined by the type of the Future
  static const HintCode RETURN_OF_INVALID_TYPE_FROM_CATCH_ERROR = HintCode(
    'INVALID_RETURN_TYPE_FOR_CATCH_ERROR',
    "A value of type '{0}' can't be returned by the 'onError' handler because "
        "it must be assignable to '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'RETURN_OF_INVALID_TYPE_FROM_CATCH_ERROR',
  );

  ///  Parameters:
  ///  0: the return type of the function
  ///  1: the expected return type as defined by the type of the Future
  static const HintCode RETURN_TYPE_INVALID_FOR_CATCH_ERROR = HintCode(
    'INVALID_RETURN_TYPE_FOR_CATCH_ERROR',
    "The return type '{0}' isn't assignable to '{1}', as required by "
        "'Future.catchError'.",
    hasPublishedDocs: true,
    uniqueName: 'RETURN_TYPE_INVALID_FOR_CATCH_ERROR',
  );

  ///  No parameters.
  static const HintCode SDK_VERSION_ASYNC_EXPORTED_FROM_CORE = HintCode(
    'SDK_VERSION_ASYNC_EXPORTED_FROM_CORE',
    "The class '{0}' wasn't exported from 'dart:core' until version 2.1, but "
        "this code is required to be able to run on earlier versions.",
    correctionMessage:
        "Try either importing 'dart:async' or updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode SDK_VERSION_AS_EXPRESSION_IN_CONST_CONTEXT = HintCode(
    'SDK_VERSION_AS_EXPRESSION_IN_CONST_CONTEXT',
    "The use of an as expression in a constant expression wasn't supported "
        "until version 2.3.2, but this code is required to be able to run on "
        "earlier versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode SDK_VERSION_BOOL_OPERATOR_IN_CONST_CONTEXT = HintCode(
    'SDK_VERSION_BOOL_OPERATOR_IN_CONST_CONTEXT',
    "The use of the operator '{0}' for 'bool' operands in a constant context "
        "wasn't supported until version 2.3.2, but this code is required to be "
        "able to run on earlier versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  ///
  ///  There is also a [ParserError.EXPERIMENT_NOT_ENABLED] code which catches
  ///  some cases of constructor tearoff features (like `List<int>.filled;`).
  ///  Other constructor tearoff cases are not realized until resolution
  ///  (like `List.filled;`).
  static const HintCode SDK_VERSION_CONSTRUCTOR_TEAROFFS = HintCode(
    'SDK_VERSION_CONSTRUCTOR_TEAROFFS',
    "Tearing off a constructor requires the 'constructor-tearoffs' language "
        "feature.",
    correctionMessage:
        "Try updating your pubspec.yaml to set the minimum SDK constraint to "
        "2.15 or higher, and running 'pub get'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode SDK_VERSION_EQ_EQ_OPERATOR_IN_CONST_CONTEXT = HintCode(
    'SDK_VERSION_EQ_EQ_OPERATOR_IN_CONST_CONTEXT',
    "Using the operator '==' for non-primitive types wasn't supported until "
        "version 2.3.2, but this code is required to be able to run on earlier "
        "versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode SDK_VERSION_EXTENSION_METHODS = HintCode(
    'SDK_VERSION_EXTENSION_METHODS',
    "Extension methods weren't supported until version 2.6.0, but this code is "
        "required to be able to run on earlier versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode SDK_VERSION_GT_GT_GT_OPERATOR = HintCode(
    'SDK_VERSION_GT_GT_GT_OPERATOR',
    "The operator '>>>' wasn't supported until version 2.14.0, but this code "
        "is required to be able to run on earlier versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode SDK_VERSION_IS_EXPRESSION_IN_CONST_CONTEXT = HintCode(
    'SDK_VERSION_IS_EXPRESSION_IN_CONST_CONTEXT',
    "The use of an is expression in a constant context wasn't supported until "
        "version 2.3.2, but this code is required to be able to run on earlier "
        "versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode SDK_VERSION_NEVER = HintCode(
    'SDK_VERSION_NEVER',
    "The type 'Never' wasn't supported until version 2.12.0, but this code is "
        "required to be able to run on earlier versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode SDK_VERSION_SET_LITERAL = HintCode(
    'SDK_VERSION_SET_LITERAL',
    "Set literals weren't supported until version 2.2, but this code is "
        "required to be able to run on earlier versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode SDK_VERSION_UI_AS_CODE = HintCode(
    'SDK_VERSION_UI_AS_CODE',
    "The for, if, and spread elements weren't supported until version 2.3.0, "
        "but this code is required to be able to run on earlier versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode SDK_VERSION_UI_AS_CODE_IN_CONST_CONTEXT = HintCode(
    'SDK_VERSION_UI_AS_CODE_IN_CONST_CONTEXT',
    "The if and spread elements weren't supported in constant expressions "
        "until version 2.5.0, but this code is required to be able to run on "
        "earlier versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
  );

  ///  When "strict-raw-types" is enabled, "raw types" must have type arguments.
  ///
  ///  A "raw type" is a type name that does not use inference to fill in missing
  ///  type arguments; instead, each type argument is instantiated to its bound.
  static const HintCode STRICT_RAW_TYPE = HintCode(
    'STRICT_RAW_TYPE',
    "The generic type '{0}' should have explicit type arguments but doesn't.",
    correctionMessage: "Use explicit type arguments for '{0}'.",
  );

  ///  Parameters:
  ///  0: the name of the sealed class
  static const HintCode SUBTYPE_OF_SEALED_CLASS = HintCode(
    'SUBTYPE_OF_SEALED_CLASS',
    "The class '{0}' shouldn't be extended, mixed in, or implemented because "
        "it's sealed.",
    correctionMessage:
        "Try composing instead of inheriting, or refer to the documentation of "
        "'{0}' for more information.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the unicode sequence of the code point.
  static const HintCode TEXT_DIRECTION_CODE_POINT_IN_COMMENT = HintCode(
    'TEXT_DIRECTION_CODE_POINT_IN_COMMENT',
    "The Unicode code point 'U+{0}' changes the appearance of text from how "
        "it's interpreted by the compiler.",
    correctionMessage:
        "Try removing the code point or using the Unicode escape sequence "
        "'\\u{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the unicode sequence of the code point.
  static const HintCode TEXT_DIRECTION_CODE_POINT_IN_LITERAL = HintCode(
    'TEXT_DIRECTION_CODE_POINT_IN_LITERAL',
    "The Unicode code point 'U+{0}' changes the appearance of text from how "
        "it's interpreted by the compiler.",
    correctionMessage:
        "Try removing the code point or using the Unicode escape sequence "
        "'\\u{0}'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode TYPE_CHECK_IS_NOT_NULL = HintCode(
    'TYPE_CHECK_WITH_NULL',
    "Tests for non-null should be done with '!= null'.",
    correctionMessage: "Try replacing the 'is! Null' check with '!= null'.",
    hasPublishedDocs: true,
    uniqueName: 'TYPE_CHECK_IS_NOT_NULL',
  );

  ///  No parameters.
  static const HintCode TYPE_CHECK_IS_NULL = HintCode(
    'TYPE_CHECK_WITH_NULL',
    "Tests for null should be done with '== null'.",
    correctionMessage: "Try replacing the 'is Null' check with '== null'.",
    hasPublishedDocs: true,
    uniqueName: 'TYPE_CHECK_IS_NULL',
  );

  ///  Parameters:
  ///  0: the name of the library being imported
  ///  1: the name in the hide clause that isn't defined in the library
  static const HintCode UNDEFINED_HIDDEN_NAME = HintCode(
    'UNDEFINED_HIDDEN_NAME',
    "The library '{0}' doesn't export a member with the hidden name '{1}'.",
    correctionMessage: "Try removing the name from the list of hidden members.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the undefined parameter
  ///  1: the name of the targeted member
  static const HintCode UNDEFINED_REFERENCED_PARAMETER = HintCode(
    'UNDEFINED_REFERENCED_PARAMETER',
    "The parameter '{0}' isn't defined by '{1}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the library being imported
  ///  1: the name in the show clause that isn't defined in the library
  static const HintCode UNDEFINED_SHOWN_NAME = HintCode(
    'UNDEFINED_SHOWN_NAME',
    "The library '{0}' doesn't export a member with the shown name '{1}'.",
    correctionMessage: "Try removing the name from the list of shown members.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the non-diagnostic being ignored
  static const HintCode UNIGNORABLE_IGNORE = HintCode(
    'UNIGNORABLE_IGNORE',
    "The diagnostic '{0}' can't be ignored.",
    correctionMessage:
        "Try removing the name from the list, or removing the whole comment if "
        "this is the only name in the list.",
  );

  ///  No parameters.
  static const HintCode UNNECESSARY_CAST = HintCode(
    'UNNECESSARY_CAST',
    "Unnecessary cast.",
    correctionMessage: "Try removing the cast.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode UNNECESSARY_FINAL = HintCode(
    'UNNECESSARY_FINAL',
    "The keyword 'final' isn't necessary because the parameter is implicitly "
        "'final'.",
    correctionMessage: "Try removing the 'final'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the diagnostic being ignored
  static const HintCode UNNECESSARY_IGNORE = HintCode(
    'UNNECESSARY_IGNORE',
    "The diagnostic '{0}' isn't produced at this location so it doesn't need "
        "to be ignored.",
    correctionMessage:
        "Try removing the name from the list, or removing the whole comment if "
        "this is the only name in the list.",
  );

  ///  Parameters:
  ///  0: the uri that is not necessary
  ///  1: the uri that makes it unnecessary
  static const HintCode UNNECESSARY_IMPORT = HintCode(
    'UNNECESSARY_IMPORT',
    "The import of '{0}' is unnecessary because all of the used elements are "
        "also provided by the import of '{1}'.",
    correctionMessage: "Try removing the import directive.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode UNNECESSARY_NO_SUCH_METHOD = HintCode(
    'UNNECESSARY_NO_SUCH_METHOD',
    "Unnecessary 'noSuchMethod' declaration.",
    correctionMessage: "Try removing the declaration of 'noSuchMethod'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode UNNECESSARY_NULL_COMPARISON_FALSE = HintCode(
    'UNNECESSARY_NULL_COMPARISON',
    "The operand can't be null, so the condition is always false.",
    correctionMessage:
        "Try removing the condition, an enclosing condition, or the whole "
        "conditional statement.",
    hasPublishedDocs: true,
    uniqueName: 'UNNECESSARY_NULL_COMPARISON_FALSE',
  );

  ///  No parameters.
  static const HintCode UNNECESSARY_NULL_COMPARISON_TRUE = HintCode(
    'UNNECESSARY_NULL_COMPARISON',
    "The operand can't be null, so the condition is always true.",
    correctionMessage: "Remove the condition.",
    hasPublishedDocs: true,
    uniqueName: 'UNNECESSARY_NULL_COMPARISON_TRUE',
  );

  ///  Parameters:
  ///  0: the name of the type
  static const HintCode UNNECESSARY_QUESTION_MARK = HintCode(
    'UNNECESSARY_QUESTION_MARK',
    "The '?' is unnecessary because '{0}' is nullable without it.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode UNNECESSARY_TYPE_CHECK_FALSE = HintCode(
    'UNNECESSARY_TYPE_CHECK',
    "Unnecessary type check; the result is always 'false'.",
    correctionMessage:
        "Try correcting the type check, or removing the type check.",
    hasPublishedDocs: true,
    uniqueName: 'UNNECESSARY_TYPE_CHECK_FALSE',
  );

  ///  No parameters.
  static const HintCode UNNECESSARY_TYPE_CHECK_TRUE = HintCode(
    'UNNECESSARY_TYPE_CHECK',
    "Unnecessary type check; the result is always 'true'.",
    correctionMessage:
        "Try correcting the type check, or removing the type check.",
    hasPublishedDocs: true,
    uniqueName: 'UNNECESSARY_TYPE_CHECK_TRUE',
  );

  ///  Parameters:
  ///  0: the name of the exception variable
  static const HintCode UNUSED_CATCH_CLAUSE = HintCode(
    'UNUSED_CATCH_CLAUSE',
    "The exception variable '{0}' isn't used, so the 'catch' clause can be "
        "removed.",
    correctionMessage: "Try removing the catch clause.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the stack trace variable
  static const HintCode UNUSED_CATCH_STACK = HintCode(
    'UNUSED_CATCH_STACK',
    "The stack trace variable '{0}' isn't used and can be removed.",
    correctionMessage: "Try removing the stack trace variable, or using it.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name that is declared but not referenced
  static const HintCode UNUSED_ELEMENT = HintCode(
    'UNUSED_ELEMENT',
    "The declaration '{0}' isn't referenced.",
    correctionMessage: "Try removing the declaration of '{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the parameter that is declared but not used
  static const HintCode UNUSED_ELEMENT_PARAMETER = HintCode(
    'UNUSED_ELEMENT',
    "A value for optional parameter '{0}' isn't ever given.",
    correctionMessage: "Try removing the unused parameter.",
    hasPublishedDocs: true,
    uniqueName: 'UNUSED_ELEMENT_PARAMETER',
  );

  ///  Parameters:
  ///  0: the name of the unused field
  static const HintCode UNUSED_FIELD = HintCode(
    'UNUSED_FIELD',
    "The value of the field '{0}' isn't used.",
    correctionMessage: "Try removing the field, or using it.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the content of the unused import's uri
  static const HintCode UNUSED_IMPORT = HintCode(
    'UNUSED_IMPORT',
    "Unused import: '{0}'.",
    correctionMessage: "Try removing the import directive.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the label that isn't used
  static const HintCode UNUSED_LABEL = HintCode(
    'UNUSED_LABEL',
    "The label '{0}' isn't used.",
    correctionMessage:
        "Try removing the label, or using it in either a 'break' or 'continue' "
        "statement.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the unused variable
  static const HintCode UNUSED_LOCAL_VARIABLE = HintCode(
    'UNUSED_LOCAL_VARIABLE',
    "The value of the local variable '{0}' isn't used.",
    correctionMessage: "Try removing the variable or using it.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the annotated method, property or function
  static const HintCode UNUSED_RESULT = HintCode(
    'UNUSED_RESULT',
    "The value of '{0}' should be used.",
    correctionMessage:
        "Try using the result by invoking a member, passing it to a function, "
        "or returning it from this function.",
    hasPublishedDocs: true,
  );

  ///  The result of invoking a method, property, or function annotated with
  ///  `@useResult` must be used (assigned, passed to a function as an argument,
  ///  or returned by a function).
  ///
  ///  Parameters:
  ///  0: the name of the annotated method, property or function
  ///  1: message details
  static const HintCode UNUSED_RESULT_WITH_MESSAGE = HintCode(
    'UNUSED_RESULT',
    "'{0}' should be used. {1}.",
    correctionMessage:
        "Try using the result by invoking a member, passing it to a function, "
        "or returning it from this function.",
    hasPublishedDocs: true,
    uniqueName: 'UNUSED_RESULT_WITH_MESSAGE',
  );

  ///  Parameters:
  ///  0: the name that is shown but not used
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
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
          name: name,
          problemMessage: problemMessage,
          uniqueName: 'HintCode.${uniqueName ?? name}',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorType.HINT.severity;

  @override
  ErrorType get type => ErrorType.HINT;
}
