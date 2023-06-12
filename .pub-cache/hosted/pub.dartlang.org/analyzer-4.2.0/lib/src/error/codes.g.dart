// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

import "package:analyzer/error/error.dart";
import "package:analyzer/src/error/analyzer_error_code.dart";

class CompileTimeErrorCode extends AnalyzerErrorCode {
  ///  No parameters.
  static const CompileTimeErrorCode ABSTRACT_FIELD_CONSTRUCTOR_INITIALIZER =
      CompileTimeErrorCode(
    'ABSTRACT_FIELD_INITIALIZER',
    "Abstract fields can't have initializers.",
    correctionMessage:
        "Try removing the field initializer or the 'abstract' keyword from the "
        "field declaration.",
    hasPublishedDocs: true,
    uniqueName: 'ABSTRACT_FIELD_CONSTRUCTOR_INITIALIZER',
  );

  ///  No parameters.
  static const CompileTimeErrorCode ABSTRACT_FIELD_INITIALIZER =
      CompileTimeErrorCode(
    'ABSTRACT_FIELD_INITIALIZER',
    "Abstract fields can't have initializers.",
    correctionMessage:
        "Try removing the initializer or the 'abstract' keyword.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the display name for the kind of the found abstract member
  ///  1: the name of the member
  static const CompileTimeErrorCode ABSTRACT_SUPER_MEMBER_REFERENCE =
      CompileTimeErrorCode(
    'ABSTRACT_SUPER_MEMBER_REFERENCE',
    "The {0} '{1}' is always abstract in the supertype.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the ambiguous element
  ///  1: the name of the first library in which the type is found
  ///  2: the name of the second library in which the type is found
  static const CompileTimeErrorCode AMBIGUOUS_EXPORT = CompileTimeErrorCode(
    'AMBIGUOUS_EXPORT',
    "The name '{0}' is defined in the libraries '{1}' and '{2}'.",
    correctionMessage:
        "Try removing the export of one of the libraries, or explicitly hiding "
        "the name in one of the export directives.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the member
  ///  1: the names of the declaring extensions
  static const CompileTimeErrorCode AMBIGUOUS_EXTENSION_MEMBER_ACCESS =
      CompileTimeErrorCode(
    'AMBIGUOUS_EXTENSION_MEMBER_ACCESS',
    "A member named '{0}' is defined in {1}, and none are more specific.",
    correctionMessage:
        "Try using an extension override to specify the extension you want to "
        "be chosen.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the ambiguous type
  ///  1: the name of the first library that the type is found
  ///  2: the name of the second library that the type is found
  static const CompileTimeErrorCode AMBIGUOUS_IMPORT = CompileTimeErrorCode(
    'AMBIGUOUS_IMPORT',
    "The name '{0}' is defined in the libraries {1}.",
    correctionMessage:
        "Try using 'as prefix' for one of the import directives, or hiding the "
        "name from all but one of the imports.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH =
      CompileTimeErrorCode(
    'AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH',
    "The literal can't be either a map or a set because it contains at least "
        "one literal map entry or a spread operator spreading a 'Map', and at "
        "least one element which is neither of these.",
    correctionMessage:
        "Try removing or changing some of the elements so that all of the "
        "elements are consistent.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER =
      CompileTimeErrorCode(
    'AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER',
    "This literal must be either a map or a set, but the elements don't have "
        "enough information for type inference to work.",
    correctionMessage:
        "Try adding type arguments to the literal (one for sets, two for "
        "maps).",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the actual argument type
  ///  1: the name of the expected type
  static const CompileTimeErrorCode ARGUMENT_TYPE_NOT_ASSIGNABLE =
      CompileTimeErrorCode(
    'ARGUMENT_TYPE_NOT_ASSIGNABLE',
    "The argument type '{0}' can't be assigned to the parameter type '{1}'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode ASSERT_IN_REDIRECTING_CONSTRUCTOR =
      CompileTimeErrorCode(
    'ASSERT_IN_REDIRECTING_CONSTRUCTOR',
    "A redirecting constructor can't have an 'assert' initializer.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode ASSIGNMENT_TO_CONST = CompileTimeErrorCode(
    'ASSIGNMENT_TO_CONST',
    "Constant variables can't be assigned a value.",
    correctionMessage:
        "Try removing the assignment, or remove the modifier 'const' from the "
        "variable.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the final variable
  static const CompileTimeErrorCode ASSIGNMENT_TO_FINAL = CompileTimeErrorCode(
    'ASSIGNMENT_TO_FINAL',
    "'{0}' can't be used as a setter because it's final.",
    correctionMessage:
        "Try finding a different setter, or making '{0}' non-final.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode ASSIGNMENT_TO_FINAL_LOCAL =
      CompileTimeErrorCode(
    'ASSIGNMENT_TO_FINAL_LOCAL',
    "The final variable '{0}' can only be set once.",
    correctionMessage: "Try making '{0}' non-final.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode ASSIGNMENT_TO_FINAL_NO_SETTER =
      CompileTimeErrorCode(
    'ASSIGNMENT_TO_FINAL_NO_SETTER',
    "There isn’t a setter named '{0}' in class '{1}'.",
    correctionMessage:
        "Try correcting the name to reference an existing setter, or declare "
        "the setter.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode ASSIGNMENT_TO_FUNCTION =
      CompileTimeErrorCode(
    'ASSIGNMENT_TO_FUNCTION',
    "Functions can't be assigned a value.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode ASSIGNMENT_TO_METHOD = CompileTimeErrorCode(
    'ASSIGNMENT_TO_METHOD',
    "Methods can't be assigned a value.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode ASSIGNMENT_TO_TYPE = CompileTimeErrorCode(
    'ASSIGNMENT_TO_TYPE',
    "Types can't be assigned a value.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode ASYNC_FOR_IN_WRONG_CONTEXT =
      CompileTimeErrorCode(
    'ASYNC_FOR_IN_WRONG_CONTEXT',
    "The async for-in loop can only be used in an async function.",
    correctionMessage:
        "Try marking the function body with either 'async' or 'async*', or "
        "removing the 'await' before the for-in loop.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode AWAIT_IN_LATE_LOCAL_VARIABLE_INITIALIZER =
      CompileTimeErrorCode(
    'AWAIT_IN_LATE_LOCAL_VARIABLE_INITIALIZER',
    "The 'await' expression can't be used in a 'late' local variable's "
        "initializer.",
    correctionMessage:
        "Try removing the 'late' modifier, or rewriting the initializer "
        "without using the 'await' expression.",
    hasPublishedDocs: true,
  );

  ///  16.30 Await Expressions: It is a compile-time error if the function
  ///  immediately enclosing _a_ is not declared asynchronous. (Where _a_ is the
  ///  await expression.)
  static const CompileTimeErrorCode AWAIT_IN_WRONG_CONTEXT =
      CompileTimeErrorCode(
    'AWAIT_IN_WRONG_CONTEXT',
    "The await expression can only be used in an async function.",
    correctionMessage:
        "Try marking the function body with either 'async' or 'async*'.",
  );

  ///  No parameters.
  static const CompileTimeErrorCode BODY_MIGHT_COMPLETE_NORMALLY =
      CompileTimeErrorCode(
    'BODY_MIGHT_COMPLETE_NORMALLY',
    "The body might complete normally, causing 'null' to be returned, but the "
        "return type, '{0}', is a potentially non-nullable type.",
    correctionMessage:
        "Try adding either a return or a throw statement at the end.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode BREAK_LABEL_ON_SWITCH_MEMBER =
      CompileTimeErrorCode(
    'BREAK_LABEL_ON_SWITCH_MEMBER',
    "A break label resolves to the 'case' or 'default' statement.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the built-in identifier that is being used
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_EXTENSION_NAME =
      CompileTimeErrorCode(
    'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    "The built-in identifier '{0}' can't be used as an extension name.",
    correctionMessage: "Try choosing a different name for the extension.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_EXTENSION_NAME',
  );

  ///  Parameters:
  ///  0: the built-in identifier that is being used
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_PREFIX_NAME =
      CompileTimeErrorCode(
    'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    "The built-in identifier '{0}' can't be used as a prefix name.",
    correctionMessage: "Try choosing a different name for the prefix.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_PREFIX_NAME',
  );

  ///  Parameters:
  ///  0: the built-in identifier that is being used
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPE =
      CompileTimeErrorCode(
    'BUILT_IN_IDENTIFIER_AS_TYPE',
    "The built-in identifier '{0}' can't be used as a type.",
    correctionMessage: "Try correcting the name to match an existing type.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the built-in identifier that is being used
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME =
      CompileTimeErrorCode(
    'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    "The built-in identifier '{0}' can't be used as a typedef name.",
    correctionMessage: "Try choosing a different name for the typedef.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME',
  );

  ///  Parameters:
  ///  0: the built-in identifier that is being used
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPE_NAME =
      CompileTimeErrorCode(
    'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    "The built-in identifier '{0}' can't be used as a type name.",
    correctionMessage: "Try choosing a different name for the type.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_TYPE_NAME',
  );

  ///  Parameters:
  ///  0: the built-in identifier that is being used
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME =
      CompileTimeErrorCode(
    'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    "The built-in identifier '{0}' can't be used as a type parameter name.",
    correctionMessage: "Try choosing a different name for the type parameter.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME',
  );

  ///  No parameters.
  static const CompileTimeErrorCode CASE_BLOCK_NOT_TERMINATED =
      CompileTimeErrorCode(
    'CASE_BLOCK_NOT_TERMINATED',
    "The last statement of the 'case' should be 'break', 'continue', "
        "'rethrow', 'return', or 'throw'.",
    correctionMessage: "Try adding one of the required statements.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the this of the switch case expression
  static const CompileTimeErrorCode CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS =
      CompileTimeErrorCode(
    'CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS',
    "The switch case expression type '{0}' can't override the '==' operator.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the type of the case expression
  ///  1: the type of the switch expression
  static const CompileTimeErrorCode
      CASE_EXPRESSION_TYPE_IS_NOT_SWITCH_EXPRESSION_SUBTYPE =
      CompileTimeErrorCode(
    'CASE_EXPRESSION_TYPE_IS_NOT_SWITCH_EXPRESSION_SUBTYPE',
    "The switch case expression type '{0}' must be a subtype of the switch "
        "expression type '{1}'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode CAST_TO_NON_TYPE = CompileTimeErrorCode(
    'CAST_TO_NON_TYPE',
    "The name '{0}' isn't a type, so it can't be used in an 'as' expression.",
    correctionMessage:
        "Try changing the name to the name of an existing type, or creating a "
        "type with the name '{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the member
  static const CompileTimeErrorCode
      CLASS_INSTANTIATION_ACCESS_TO_INSTANCE_MEMBER = CompileTimeErrorCode(
    'CLASS_INSTANTIATION_ACCESS_TO_MEMBER',
    "The instance member '{0}' can't be accessed on a class instantiation.",
    correctionMessage:
        "Try changing the member name to the name of a constructor.",
    uniqueName: 'CLASS_INSTANTIATION_ACCESS_TO_INSTANCE_MEMBER',
  );

  ///  Parameters:
  ///  0: the name of the member
  static const CompileTimeErrorCode
      CLASS_INSTANTIATION_ACCESS_TO_STATIC_MEMBER = CompileTimeErrorCode(
    'CLASS_INSTANTIATION_ACCESS_TO_MEMBER',
    "The static member '{0}' can't be accessed on a class instantiation.",
    correctionMessage:
        "Try removing the type arguments from the class name, or changing the "
        "member name to the name of a constructor.",
    uniqueName: 'CLASS_INSTANTIATION_ACCESS_TO_STATIC_MEMBER',
  );

  ///  Parameters:
  ///  0: the name of the member
  static const CompileTimeErrorCode
      CLASS_INSTANTIATION_ACCESS_TO_UNKNOWN_MEMBER = CompileTimeErrorCode(
    'CLASS_INSTANTIATION_ACCESS_TO_MEMBER',
    "The class '{0} doesn't have a constructor named '{1}.",
    correctionMessage:
        "Try invoking a different constructor, or defining a constructor named "
        "'{1}'.",
    uniqueName: 'CLASS_INSTANTIATION_ACCESS_TO_UNKNOWN_MEMBER',
  );

  static const CompileTimeErrorCode CONCRETE_CLASS_HAS_ENUM_SUPERINTERFACE =
      CompileTimeErrorCode(
    'CONCRETE_CLASS_HAS_ENUM_SUPERINTERFACE',
    "Concrete classes can't have 'Enum' as a superinterface.",
    correctionMessage:
        "Try specifying a different interface, or remove it from the list.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the abstract method
  ///  1: the name of the enclosing class
  static const CompileTimeErrorCode CONCRETE_CLASS_WITH_ABSTRACT_MEMBER =
      CompileTimeErrorCode(
    'CONCRETE_CLASS_WITH_ABSTRACT_MEMBER',
    "'{0}' must have a method body because '{1}' isn't abstract.",
    correctionMessage: "Try making '{1}' abstract, or adding a body to '{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the constructor and field
  static const CompileTimeErrorCode CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD =
      CompileTimeErrorCode(
    'CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER',
    "'{0}' can't be used to name both a constructor and a static field in this "
        "class.",
    correctionMessage: "Try renaming either the constructor or the field.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD',
  );

  ///  Parameters:
  ///  0: the name of the constructor and getter
  static const CompileTimeErrorCode CONFLICTING_CONSTRUCTOR_AND_STATIC_GETTER =
      CompileTimeErrorCode(
    'CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER',
    "'{0}' can't be used to name both a constructor and a static getter in "
        "this class.",
    correctionMessage: "Try renaming either the constructor or the getter.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_GETTER',
  );

  ///  Parameters:
  ///  0: the name of the constructor
  static const CompileTimeErrorCode CONFLICTING_CONSTRUCTOR_AND_STATIC_METHOD =
      CompileTimeErrorCode(
    'CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER',
    "'{0}' can't be used to name both a constructor and a static method in "
        "this class.",
    correctionMessage: "Try renaming either the constructor or the method.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_METHOD',
  );

  ///  Parameters:
  ///  0: the name of the constructor and setter
  static const CompileTimeErrorCode CONFLICTING_CONSTRUCTOR_AND_STATIC_SETTER =
      CompileTimeErrorCode(
    'CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER',
    "'{0}' can't be used to name both a constructor and a static setter in "
        "this class.",
    correctionMessage: "Try renaming either the constructor or the setter.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_SETTER',
  );

  ///  10.11 Class Member Conflicts: Let `C` be a class. It is a compile-time
  ///  error if `C` declares a getter or a setter with basename `n`, and has a
  ///  method named `n`.
  ///
  ///  Parameters:
  ///  0: the name of the class defining the conflicting field
  ///  1: the name of the conflicting field
  ///  2: the name of the class defining the method with which the field conflicts
  static const CompileTimeErrorCode CONFLICTING_FIELD_AND_METHOD =
      CompileTimeErrorCode(
    'CONFLICTING_FIELD_AND_METHOD',
    "Class '{0}' can't define field '{1}' and have method '{2}.{1}' with the "
        "same name.",
    correctionMessage:
        "Try converting the getter to a method, or renaming the field to a "
        "name that doesn't conflict.",
  );

  ///  Parameters:
  ///  0: the name of the class implementing the conflicting interface
  ///  1: the first conflicting type
  ///  2: the second conflicting type
  static const CompileTimeErrorCode CONFLICTING_GENERIC_INTERFACES =
      CompileTimeErrorCode(
    'CONFLICTING_GENERIC_INTERFACES',
    "The class '{0}' can't implement both '{1}' and '{2}' because the type "
        "arguments are different.",
    hasPublishedDocs: true,
  );

  ///  10.11 Class Member Conflicts: Let `C` be a class. It is a compile-time
  ///  error if `C` declares a method named `n`, and has a getter or a setter
  ///  with basename `n`.
  ///
  ///  Parameters:
  ///  0: the name of the class defining the conflicting method
  ///  1: the name of the conflicting method
  ///  2: the name of the class defining the field with which the method conflicts
  static const CompileTimeErrorCode CONFLICTING_METHOD_AND_FIELD =
      CompileTimeErrorCode(
    'CONFLICTING_METHOD_AND_FIELD',
    "Class '{0}' can't define method '{1}' and have field '{2}.{1}' with the "
        "same name.",
    correctionMessage:
        "Try converting the method to a getter, or renaming the method to a "
        "name that doesn't conflict.",
  );

  ///  10.11 Class Member Conflicts: Let `C` be a class. It is a compile-time
  ///  error if `C` declares a static member with basename `n`, and has an
  ///  instance member with basename `n`.
  ///
  ///  Parameters:
  ///  0: the name of the class defining the conflicting member
  ///  1: the name of the conflicting static member
  ///  2: the name of the class defining the field with which the method conflicts
  static const CompileTimeErrorCode CONFLICTING_STATIC_AND_INSTANCE =
      CompileTimeErrorCode(
    'CONFLICTING_STATIC_AND_INSTANCE',
    "Class '{0}' can't define static member '{1}' and have instance member "
        "'{2}.{1}' with the same name.",
    correctionMessage:
        "Try renaming the member to a name that doesn't conflict.",
  );

  ///  Parameters:
  ///  0: the name of the type variable
  static const CompileTimeErrorCode CONFLICTING_TYPE_VARIABLE_AND_CLASS =
      CompileTimeErrorCode(
    'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
    "'{0}' can't be used to name both a type variable and the class in which "
        "the type variable is defined.",
    correctionMessage: "Try renaming either the type variable or the class.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_CLASS',
  );

  ///  Parameters:
  ///  0: the name of the type variable
  static const CompileTimeErrorCode CONFLICTING_TYPE_VARIABLE_AND_ENUM =
      CompileTimeErrorCode(
    'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
    "'{0}' can't be used to name both a type variable and the enum in which "
        "the type variable is defined.",
    correctionMessage: "Try renaming either the type variable or the enum.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_ENUM',
  );

  ///  Parameters:
  ///  0: the name of the type variable
  static const CompileTimeErrorCode CONFLICTING_TYPE_VARIABLE_AND_EXTENSION =
      CompileTimeErrorCode(
    'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
    "'{0}' can't be used to name both a type variable and the extension in "
        "which the type variable is defined.",
    correctionMessage:
        "Try renaming either the type variable or the extension.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_EXTENSION',
  );

  ///  Parameters:
  ///  0: the name of the type variable
  static const CompileTimeErrorCode CONFLICTING_TYPE_VARIABLE_AND_MEMBER_CLASS =
      CompileTimeErrorCode(
    'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
    "'{0}' can't be used to name both a type variable and a member in this "
        "class.",
    correctionMessage: "Try renaming either the type variable or the member.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER_CLASS',
  );

  ///  Parameters:
  ///  0: the name of the type variable
  static const CompileTimeErrorCode CONFLICTING_TYPE_VARIABLE_AND_MEMBER_ENUM =
      CompileTimeErrorCode(
    'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
    "'{0}' can't be used to name both a type variable and a member in this "
        "enum.",
    correctionMessage: "Try renaming either the type variable or the member.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER_ENUM',
  );

  ///  Parameters:
  ///  0: the name of the type variable
  static const CompileTimeErrorCode
      CONFLICTING_TYPE_VARIABLE_AND_MEMBER_EXTENSION = CompileTimeErrorCode(
    'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
    "'{0}' can't be used to name both a type variable and a member in this "
        "extension.",
    correctionMessage: "Try renaming either the type variable or the member.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER_EXTENSION',
  );

  ///  Parameters:
  ///  0: the name of the type variable
  static const CompileTimeErrorCode CONFLICTING_TYPE_VARIABLE_AND_MEMBER_MIXIN =
      CompileTimeErrorCode(
    'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
    "'{0}' can't be used to name both a type variable and a member in this "
        "mixin.",
    correctionMessage: "Try renaming either the type variable or the member.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER_MIXIN',
  );

  ///  Parameters:
  ///  0: the name of the type variable
  static const CompileTimeErrorCode CONFLICTING_TYPE_VARIABLE_AND_MIXIN =
      CompileTimeErrorCode(
    'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
    "'{0}' can't be used to name both a type variable and the mixin in which "
        "the type variable is defined.",
    correctionMessage: "Try renaming either the type variable or the mixin.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_MIXIN',
  );

  ///  16.12.2 Const: It is a compile-time error if evaluation of a constant
  ///  object results in an uncaught exception being thrown.
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH =
      CompileTimeErrorCode(
    'CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH',
    "In a const constructor, a value of type '{0}' can't be assigned to the "
        "field '{1}', which has type '{2}'.",
    correctionMessage: "Try using a subtype, or removing the keyword 'const'.",
  );

  ///  Parameters:
  ///  0: the type of the runtime value of the argument
  ///  1: the static type of the parameter
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH =
      CompileTimeErrorCode(
    'CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH',
    "A value of type '{0}' can't be assigned to a parameter of type '{1}' in a "
        "const constructor.",
    correctionMessage: "Try using a subtype, or removing the keyword 'const'.",
    hasPublishedDocs: true,
  );

  ///  16.12.2 Const: It is a compile-time error if evaluation of a constant
  ///  object results in an uncaught exception being thrown.
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_THROWS_EXCEPTION =
      CompileTimeErrorCode(
    'CONST_CONSTRUCTOR_THROWS_EXCEPTION',
    "Const constructors can't throw exceptions.",
    correctionMessage:
        "Try removing the throw statement, or removing the keyword 'const'.",
  );

  ///  Parameters:
  ///  0: the name of the field
  static const CompileTimeErrorCode
      CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST =
      CompileTimeErrorCode(
    'CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST',
    "Can't define the 'const' constructor because the field '{0}' is "
        "initialized with a non-constant value.",
    correctionMessage:
        "Try initializing the field to a constant value, or removing the "
        "keyword 'const' from the constructor.",
    hasPublishedDocs: true,
  );

  ///  7.6.3 Constant Constructors: The superinitializer that appears, explicitly
  ///  or implicitly, in the initializer list of a constant constructor must
  ///  specify a constant constructor of the superclass of the immediately
  ///  enclosing class or a compile-time error occurs.
  ///
  ///  12.1 Mixin Application: For each generative constructor named ... an
  ///  implicitly declared constructor named ... is declared. If Sq is a
  ///  generative const constructor, and M does not declare any fields, Cq is
  ///  also a const constructor.
  ///
  ///  Parameters:
  ///  0: the name of the instance field.
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD =
      CompileTimeErrorCode(
    'CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD',
    "This constructor can't be declared 'const' because a mixin adds the "
        "instance field: {0}.",
    correctionMessage:
        "Try removing the 'const' keyword or removing the 'with' clause from "
        "the class declaration, or removing the field from the mixin class.",
  );

  ///  7.6.3 Constant Constructors: The superinitializer that appears, explicitly
  ///  or implicitly, in the initializer list of a constant constructor must
  ///  specify a constant constructor of the superclass of the immediately
  ///  enclosing class or a compile-time error occurs.
  ///
  ///  12.1 Mixin Application: For each generative constructor named ... an
  ///  implicitly declared constructor named ... is declared. If Sq is a
  ///  generative const constructor, and M does not declare any fields, Cq is
  ///  also a const constructor.
  ///
  ///  Parameters:
  ///  0: the names of the instance fields.
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELDS =
      CompileTimeErrorCode(
    'CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD',
    "This constructor can't be declared 'const' because the mixins add the "
        "instance fields: {0}.",
    correctionMessage:
        "Try removing the 'const' keyword or removing the 'with' clause from "
        "the class declaration, or removing the fields from the mixin classes.",
    uniqueName: 'CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELDS',
  );

  ///  Parameters:
  ///  0: the name of the superclass
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER =
      CompileTimeErrorCode(
    'CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER',
    "A constant constructor can't call a non-constant super constructor of "
        "'{0}'.",
    correctionMessage:
        "Try calling a constant constructor in the superclass, or removing the "
        "keyword 'const' from the constructor.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD =
      CompileTimeErrorCode(
    'CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD',
    "Can't define a const constructor for a class with non-final fields.",
    correctionMessage:
        "Try making all of the fields final, or removing the keyword 'const' "
        "from the constructor.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode CONST_DEFERRED_CLASS = CompileTimeErrorCode(
    'CONST_DEFERRED_CLASS',
    "Deferred classes can't be created with 'const'.",
    correctionMessage:
        "Try using 'new' to create the instance, or changing the import to not "
        "be deferred.",
    hasPublishedDocs: true,
  );

  ///  16.12.2 Const: It is a compile-time error if evaluation of a constant
  ///  object results in an uncaught exception being thrown.
  static const CompileTimeErrorCode CONST_EVAL_THROWS_EXCEPTION =
      CompileTimeErrorCode(
    'CONST_EVAL_THROWS_EXCEPTION',
    "Evaluation of this constant expression throws an exception.",
  );

  ///  16.12.2 Const: It is a compile-time error if evaluation of a constant
  ///  object results in an uncaught exception being thrown.
  static const CompileTimeErrorCode CONST_EVAL_THROWS_IDBZE =
      CompileTimeErrorCode(
    'CONST_EVAL_THROWS_IDBZE',
    "Evaluation of this constant expression throws an "
        "IntegerDivisionByZeroException.",
  );

  ///  16.12.2 Const: An expression of one of the forms !e, e1 && e2 or e1 || e2,
  ///  where e, e1 and e2 are constant expressions that evaluate to a boolean
  ///  value.
  static const CompileTimeErrorCode CONST_EVAL_TYPE_BOOL = CompileTimeErrorCode(
    'CONST_EVAL_TYPE_BOOL',
    "In constant expressions, operands of this operator must be of type "
        "'bool'.",
  );

  ///  16.12.2 Const: An expression of one of the forms !e, e1 && e2 or e1 || e2,
  ///  where e, e1 and e2 are constant expressions that evaluate to a boolean
  ///  value.
  static const CompileTimeErrorCode CONST_EVAL_TYPE_BOOL_INT =
      CompileTimeErrorCode(
    'CONST_EVAL_TYPE_BOOL_INT',
    "In constant expressions, operands of this operator must be of type 'bool' "
        "or 'int'.",
  );

  ///  16.12.2 Const: An expression of one of the forms e1 == e2 or e1 != e2 where
  ///  e1 and e2 are constant expressions that evaluate to a numeric, string or
  ///  boolean value or to null.
  static const CompileTimeErrorCode CONST_EVAL_TYPE_BOOL_NUM_STRING =
      CompileTimeErrorCode(
    'CONST_EVAL_TYPE_BOOL_NUM_STRING',
    "In constant expressions, operands of this operator must be of type "
        "'bool', 'num', 'String' or 'null'.",
  );

  ///  16.12.2 Const: An expression of one of the forms ~e, e1 ^ e2, e1 & e2,
  ///  e1 | e2, e1 >> e2 or e1 << e2, where e, e1 and e2 are constant expressions
  ///  that evaluate to an integer value or to null.
  static const CompileTimeErrorCode CONST_EVAL_TYPE_INT = CompileTimeErrorCode(
    'CONST_EVAL_TYPE_INT',
    "In constant expressions, operands of this operator must be of type 'int'.",
  );

  ///  16.12.2 Const: An expression of one of the forms e, e1 + e2, e1 - e2, e1
  ///  e2, e1 / e2, e1 ~/ e2, e1 > e2, e1 < e2, e1 >= e2, e1 <= e2 or e1 % e2,
  ///  where e, e1 and e2 are constant expressions that evaluate to a numeric
  ///  value or to null.
  static const CompileTimeErrorCode CONST_EVAL_TYPE_NUM = CompileTimeErrorCode(
    'CONST_EVAL_TYPE_NUM',
    "In constant expressions, operands of this operator must be of type 'num'.",
  );

  static const CompileTimeErrorCode CONST_EVAL_TYPE_TYPE = CompileTimeErrorCode(
    'CONST_EVAL_TYPE_TYPE',
    "In constant expressions, operands of this operator must be of type "
        "'Type'.",
  );

  ///  Parameters:
  ///  0: the name of the type of the initializer expression
  ///  1: the name of the type of the field
  static const CompileTimeErrorCode CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE =
      CompileTimeErrorCode(
    'FIELD_INITIALIZER_NOT_ASSIGNABLE',
    "The initializer type '{0}' can't be assigned to the field type '{1}' in a "
        "const constructor.",
    correctionMessage: "Try using a subtype, or removing the 'const' keyword",
    hasPublishedDocs: true,
    uniqueName: 'CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE',
  );

  ///  No parameters.
  static const CompileTimeErrorCode CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE =
      CompileTimeErrorCode(
    'CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE',
    "Const variables must be initialized with a constant value.",
    correctionMessage:
        "Try changing the initializer to be a constant expression.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY =
      CompileTimeErrorCode(
    'CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used to initialize a "
        "'const' variable.",
    correctionMessage:
        "Try initializing the variable without referencing members of the "
        "deferred library, or changing the import to not be deferred.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode CONST_INSTANCE_FIELD = CompileTimeErrorCode(
    'CONST_INSTANCE_FIELD',
    "Only static fields can be declared as const.",
    correctionMessage:
        "Try declaring the field as final, or adding the keyword 'static'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the type of the entry's key
  static const CompileTimeErrorCode
      CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS = CompileTimeErrorCode(
    'CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS',
    "The type of a key in a constant map can't override the '==' operator, but "
        "the class '{0}' does.",
    correctionMessage:
        "Try using a different value for the key, or removing the keyword "
        "'const' from the map.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the uninitialized final variable
  static const CompileTimeErrorCode CONST_NOT_INITIALIZED =
      CompileTimeErrorCode(
    'CONST_NOT_INITIALIZED',
    "The constant '{0}' must be initialized.",
    correctionMessage: "Try adding an initialization to the declaration.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the type of the element
  static const CompileTimeErrorCode CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS =
      CompileTimeErrorCode(
    'CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS',
    "The type of an element in a constant set can't override the '==' "
        "operator, but the type '{0}' does.",
    correctionMessage:
        "Try using a different value for the element, or removing the keyword "
        "'const' from the set.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode CONST_SPREAD_EXPECTED_LIST_OR_SET =
      CompileTimeErrorCode(
    'CONST_SPREAD_EXPECTED_LIST_OR_SET',
    "A list or a set is expected in this spread.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode CONST_SPREAD_EXPECTED_MAP =
      CompileTimeErrorCode(
    'CONST_SPREAD_EXPECTED_MAP',
    "A map is expected in this spread.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode CONST_WITH_NON_CONST = CompileTimeErrorCode(
    'CONST_WITH_NON_CONST',
    "The constructor being called isn't a const constructor.",
    correctionMessage: "Try removing 'const' from the constructor invocation.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode CONST_WITH_NON_CONSTANT_ARGUMENT =
      CompileTimeErrorCode(
    'CONST_WITH_NON_CONSTANT_ARGUMENT',
    "Arguments of a constant creation must be constant expressions.",
    correctionMessage:
        "Try making the argument a valid constant, or use 'new' to call the "
        "constructor.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the non-type element
  static const CompileTimeErrorCode CONST_WITH_NON_TYPE = CompileTimeErrorCode(
    'CREATION_WITH_NON_TYPE',
    "The name '{0}' isn't a class.",
    correctionMessage: "Try correcting the name to match an existing class.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
    uniqueName: 'CONST_WITH_NON_TYPE',
  );

  ///  No parameters.
  static const CompileTimeErrorCode CONST_WITH_TYPE_PARAMETERS =
      CompileTimeErrorCode(
    'CONST_WITH_TYPE_PARAMETERS',
    "A constant creation can't use a type parameter as a type argument.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      CONST_WITH_TYPE_PARAMETERS_CONSTRUCTOR_TEAROFF = CompileTimeErrorCode(
    'CONST_WITH_TYPE_PARAMETERS',
    "A constant constructor tearoff can't use a type parameter as a type "
        "argument.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
    uniqueName: 'CONST_WITH_TYPE_PARAMETERS_CONSTRUCTOR_TEAROFF',
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      CONST_WITH_TYPE_PARAMETERS_FUNCTION_TEAROFF = CompileTimeErrorCode(
    'CONST_WITH_TYPE_PARAMETERS',
    "A constant function tearoff can't use a type parameter as a type "
        "argument.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
    uniqueName: 'CONST_WITH_TYPE_PARAMETERS_FUNCTION_TEAROFF',
  );

  ///  16.12.2 Const: It is a compile-time error if <i>T.id</i> is not the name of
  ///  a constant constructor declared by the type <i>T</i>.
  ///
  ///  Parameters:
  ///  0: the name of the type
  ///  1: the name of the requested constant constructor
  static const CompileTimeErrorCode CONST_WITH_UNDEFINED_CONSTRUCTOR =
      CompileTimeErrorCode(
    'CONST_WITH_UNDEFINED_CONSTRUCTOR',
    "The class '{0}' doesn't have a constant constructor '{1}'.",
    correctionMessage: "Try calling a different constructor.",
  );

  ///  16.12.2 Const: It is a compile-time error if <i>T.id</i> is not the name of
  ///  a constant constructor declared by the type <i>T</i>.
  ///
  ///  Parameters:
  ///  0: the name of the type
  static const CompileTimeErrorCode CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT =
      CompileTimeErrorCode(
    'CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT',
    "The class '{0}' doesn't have an unnamed constant constructor.",
    correctionMessage: "Try calling a different constructor.",
  );

  static const CompileTimeErrorCode CONTINUE_LABEL_ON_SWITCH =
      CompileTimeErrorCode(
    'CONTINUE_LABEL_ON_SWITCH',
    "A `continue` label resolves to a `switch` statement, but the label must "
        "be on a loop or a switch member.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the type parameter
  ///  1: detail text explaining why the type could not be inferred
  static const CompileTimeErrorCode COULD_NOT_INFER = CompileTimeErrorCode(
    'COULD_NOT_INFER',
    "Couldn't infer type parameter '{0}'.{1}",
  );

  ///  No parameters.
  static const CompileTimeErrorCode DEFAULT_LIST_CONSTRUCTOR =
      CompileTimeErrorCode(
    'DEFAULT_LIST_CONSTRUCTOR',
    "The default 'List' constructor isn't available when null safety is "
        "enabled.",
    correctionMessage:
        "Try using a list literal, 'List.filled' or 'List.generate'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR = CompileTimeErrorCode(
    'DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR',
    "Default values aren't allowed in factory constructors that redirect to "
        "another constructor.",
    correctionMessage: "Try removing the default value.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode DEFAULT_VALUE_ON_REQUIRED_PARAMETER =
      CompileTimeErrorCode(
    'DEFAULT_VALUE_ON_REQUIRED_PARAMETER',
    "Required named parameters can't have a default value.",
    correctionMessage:
        "Try removing either the default value or the 'required' modifier.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode DEFERRED_IMPORT_OF_EXTENSION =
      CompileTimeErrorCode(
    'DEFERRED_IMPORT_OF_EXTENSION',
    "Imports of deferred libraries must hide all extensions.",
    correctionMessage:
        "Try adding either a show combinator listing the names you need to "
        "reference or a hide combinator listing all of the extensions.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the variable that is invalid
  static const CompileTimeErrorCode DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE =
      CompileTimeErrorCode(
    'DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE',
    "The late local variable '{0}' is definitely unassigned at this point.",
    correctionMessage:
        "Ensure that it is assigned on necessary execution paths.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode DISALLOWED_TYPE_INSTANTIATION_EXPRESSION =
      CompileTimeErrorCode(
    'DISALLOWED_TYPE_INSTANTIATION_EXPRESSION',
    "Only a generic type, generic function, generic instance method, or "
        "generic constructor can have type arguments.",
    correctionMessage:
        "Try removing the type arguments, or instantiating the type(s) of a "
        "generic type, generic function, generic instance method, or generic "
        "constructor.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode DUPLICATE_CONSTRUCTOR_DEFAULT =
      CompileTimeErrorCode(
    'DUPLICATE_CONSTRUCTOR',
    "The unnamed constructor is already defined.",
    correctionMessage: "Try giving one of the constructors a name.",
    hasPublishedDocs: true,
    uniqueName: 'DUPLICATE_CONSTRUCTOR_DEFAULT',
  );

  ///  Parameters:
  ///  0: the name of the duplicate entity
  static const CompileTimeErrorCode DUPLICATE_CONSTRUCTOR_NAME =
      CompileTimeErrorCode(
    'DUPLICATE_CONSTRUCTOR',
    "The constructor with name '{0}' is already defined.",
    correctionMessage: "Try renaming one of the constructors.",
    hasPublishedDocs: true,
    uniqueName: 'DUPLICATE_CONSTRUCTOR_NAME',
  );

  ///  Parameters:
  ///  0: the name of the duplicate entity
  static const CompileTimeErrorCode DUPLICATE_DEFINITION = CompileTimeErrorCode(
    'DUPLICATE_DEFINITION',
    "The name '{0}' is already defined.",
    correctionMessage: "Try renaming one of the declarations.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the field
  static const CompileTimeErrorCode DUPLICATE_FIELD_FORMAL_PARAMETER =
      CompileTimeErrorCode(
    'DUPLICATE_FIELD_FORMAL_PARAMETER',
    "The field '{0}' can't be initialized by multiple parameters in the same "
        "constructor.",
    correctionMessage:
        "Try removing one of the parameters, or using different fields.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the parameter that was duplicated
  static const CompileTimeErrorCode DUPLICATE_NAMED_ARGUMENT =
      CompileTimeErrorCode(
    'DUPLICATE_NAMED_ARGUMENT',
    "The argument for the named parameter '{0}' was already specified.",
    correctionMessage:
        "Try removing one of the named arguments, or correcting one of the "
        "names to reference a different named parameter.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the URI of the duplicate part
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
    hasPublishedDocs: true,
  );

  static const CompileTimeErrorCode ENUM_CONSTANT_WITH_NON_CONST_CONSTRUCTOR =
      CompileTimeErrorCode(
    'ENUM_CONSTANT_WITH_NON_CONST_CONSTRUCTOR',
    "The invoked constructor isn't a 'const' constructor.",
    correctionMessage: "Try invoking a 'const' generative constructor.",
    hasPublishedDocs: true,
  );

  static const CompileTimeErrorCode
      ENUM_INSTANTIATED_TO_BOUNDS_IS_NOT_WELL_BOUNDED = CompileTimeErrorCode(
    'ENUM_INSTANTIATED_TO_BOUNDS_IS_NOT_WELL_BOUNDED',
    "The result of instantiating the enum to bounds is not well-bounded.",
    correctionMessage: "Try using different bounds for type parameters.",
  );

  static const CompileTimeErrorCode ENUM_MIXIN_WITH_INSTANCE_VARIABLE =
      CompileTimeErrorCode(
    'ENUM_MIXIN_WITH_INSTANCE_VARIABLE',
    "Mixins applied to enums can't have instance variables.",
    correctionMessage: "Try replacing the instance variables with getters.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the abstract method
  ///  1: the name of the enclosing enum
  static const CompileTimeErrorCode ENUM_WITH_ABSTRACT_MEMBER =
      CompileTimeErrorCode(
    'ENUM_WITH_ABSTRACT_MEMBER',
    "'{0}' must have a method body because '{1}' is an enum.",
    correctionMessage: "Try adding a body to '{0}'.",
    hasPublishedDocs: true,
  );

  static const CompileTimeErrorCode ENUM_WITH_NAME_VALUES =
      CompileTimeErrorCode(
    'ENUM_WITH_NAME_VALUES',
    "The name 'values' is not a valid name for an enum.",
    correctionMessage: "Try using a different name.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode EQUAL_ELEMENTS_IN_CONST_SET =
      CompileTimeErrorCode(
    'EQUAL_ELEMENTS_IN_CONST_SET',
    "Two elements in a constant set literal can't be equal.",
    correctionMessage: "Change or remove the duplicate element.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode EQUAL_KEYS_IN_CONST_MAP =
      CompileTimeErrorCode(
    'EQUAL_KEYS_IN_CONST_MAP',
    "Two keys in a constant map literal can't be equal.",
    correctionMessage: "Change or remove the duplicate key.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the number of provided type arguments
  static const CompileTimeErrorCode EXPECTED_ONE_LIST_TYPE_ARGUMENTS =
      CompileTimeErrorCode(
    'EXPECTED_ONE_LIST_TYPE_ARGUMENTS',
    "List literals require one type argument or none, but {0} found.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the number of provided type arguments
  static const CompileTimeErrorCode EXPECTED_ONE_SET_TYPE_ARGUMENTS =
      CompileTimeErrorCode(
    'EXPECTED_ONE_SET_TYPE_ARGUMENTS',
    "Set literals require one type argument or none, but {0} were found.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the number of provided type arguments
  static const CompileTimeErrorCode EXPECTED_TWO_MAP_TYPE_ARGUMENTS =
      CompileTimeErrorCode(
    'EXPECTED_TWO_MAP_TYPE_ARGUMENTS',
    "Map literals require two type arguments or none, but {0} found.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the uri pointing to a library
  static const CompileTimeErrorCode EXPORT_INTERNAL_LIBRARY =
      CompileTimeErrorCode(
    'EXPORT_INTERNAL_LIBRARY',
    "The library '{0}' is internal and can't be exported.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of a symbol defined in a legacy library
  static const CompileTimeErrorCode EXPORT_LEGACY_SYMBOL = CompileTimeErrorCode(
    'EXPORT_LEGACY_SYMBOL',
    "The symbol '{0}' is defined in a legacy library, and can't be re-exported "
        "from a library with null safety enabled.",
    correctionMessage:
        "Try removing the export or migrating the legacy library.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the uri pointing to a non-library declaration
  static const CompileTimeErrorCode EXPORT_OF_NON_LIBRARY =
      CompileTimeErrorCode(
    'EXPORT_OF_NON_LIBRARY',
    "The exported library '{0}' can't have a part-of directive.",
    correctionMessage: "Try exporting the library that the part is a part of.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode EXPRESSION_IN_MAP = CompileTimeErrorCode(
    'EXPRESSION_IN_MAP',
    "Expressions can't be used in a map literal.",
    correctionMessage:
        "Try removing the expression or converting it to be a map entry.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode EXTENDS_DEFERRED_CLASS =
      CompileTimeErrorCode(
    'SUBTYPE_OF_DEFERRED_CLASS',
    "Classes can't extend deferred classes.",
    correctionMessage:
        "Try specifying a different superclass, or removing the extends "
        "clause.",
    hasPublishedDocs: true,
    uniqueName: 'EXTENDS_DEFERRED_CLASS',
  );

  ///  Parameters:
  ///  0: the name of the disallowed type
  static const CompileTimeErrorCode EXTENDS_DISALLOWED_CLASS =
      CompileTimeErrorCode(
    'SUBTYPE_OF_DISALLOWED_TYPE',
    "Classes can't extend '{0}'.",
    correctionMessage:
        "Try specifying a different superclass, or removing the extends "
        "clause.",
    hasPublishedDocs: true,
    uniqueName: 'EXTENDS_DISALLOWED_CLASS',
  );

  ///  Parameters:
  ///  0: the name in the extends clause
  static const CompileTimeErrorCode EXTENDS_NON_CLASS = CompileTimeErrorCode(
    'EXTENDS_NON_CLASS',
    "Classes can only extend other classes.",
    correctionMessage:
        "Try specifying a different superclass, or removing the extends "
        "clause.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      EXTENDS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER = CompileTimeErrorCode(
    'SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER',
    "A type alias that expands to a type parameter can't be used as a "
        "superclass.",
    correctionMessage:
        "Try specifying a different superclass, or removing the extends "
        "clause.",
    hasPublishedDocs: true,
    uniqueName: 'EXTENDS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
  );

  ///  Parameters:
  ///  0: the name of the extension
  static const CompileTimeErrorCode EXTENSION_AS_EXPRESSION =
      CompileTimeErrorCode(
    'EXTENSION_AS_EXPRESSION',
    "Extension '{0}' can't be used as an expression.",
    correctionMessage: "Try replacing it with a valid expression.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the conflicting static member
  static const CompileTimeErrorCode EXTENSION_CONFLICTING_STATIC_AND_INSTANCE =
      CompileTimeErrorCode(
    'EXTENSION_CONFLICTING_STATIC_AND_INSTANCE',
    "An extension can't define static member '{0}' and an instance member with "
        "the same name.",
    correctionMessage:
        "Try renaming the member to a name that doesn't conflict.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode EXTENSION_DECLARES_MEMBER_OF_OBJECT =
      CompileTimeErrorCode(
    'EXTENSION_DECLARES_MEMBER_OF_OBJECT',
    "Extensions can't declare members with the same name as a member declared "
        "by 'Object'.",
    correctionMessage: "Try specifying a different name for the member.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER =
      CompileTimeErrorCode(
    'EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER',
    "An extension override can't be used to access a static member from an "
        "extension.",
    correctionMessage: "Try using just the name of the extension.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the type of the argument
  ///  1: the extended type
  static const CompileTimeErrorCode EXTENSION_OVERRIDE_ARGUMENT_NOT_ASSIGNABLE =
      CompileTimeErrorCode(
    'EXTENSION_OVERRIDE_ARGUMENT_NOT_ASSIGNABLE',
    "The type of the argument to the extension override '{0}' isn't assignable "
        "to the extended type '{1}'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode EXTENSION_OVERRIDE_WITHOUT_ACCESS =
      CompileTimeErrorCode(
    'EXTENSION_OVERRIDE_WITHOUT_ACCESS',
    "An extension override can only be used to access instance members.",
    correctionMessage: "Consider adding an access to an instance member.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode EXTENSION_OVERRIDE_WITH_CASCADE =
      CompileTimeErrorCode(
    'EXTENSION_OVERRIDE_WITH_CASCADE',
    "Extension overrides have no value so they can't be used as the receiver "
        "of a cascade expression.",
    correctionMessage: "Try using '.' instead of '..'.",
    hasPublishedDocs: true,
  );

  static const CompileTimeErrorCode EXTERNAL_FIELD_CONSTRUCTOR_INITIALIZER =
      CompileTimeErrorCode(
    'EXTERNAL_WITH_INITIALIZER',
    "External fields can't have initializers.",
    correctionMessage:
        "Try removing the field initializer or the 'external' keyword from the "
        "field declaration.",
    hasPublishedDocs: true,
    uniqueName: 'EXTERNAL_FIELD_CONSTRUCTOR_INITIALIZER',
  );

  static const CompileTimeErrorCode EXTERNAL_FIELD_INITIALIZER =
      CompileTimeErrorCode(
    'EXTERNAL_WITH_INITIALIZER',
    "External fields can't have initializers.",
    correctionMessage:
        "Try removing the initializer or the 'external' keyword.",
    hasPublishedDocs: true,
    uniqueName: 'EXTERNAL_FIELD_INITIALIZER',
  );

  static const CompileTimeErrorCode EXTERNAL_VARIABLE_INITIALIZER =
      CompileTimeErrorCode(
    'EXTERNAL_WITH_INITIALIZER',
    "External variables can't have initializers.",
    correctionMessage:
        "Try removing the initializer or the 'external' keyword.",
    hasPublishedDocs: true,
    uniqueName: 'EXTERNAL_VARIABLE_INITIALIZER',
  );

  ///  Parameters:
  ///  0: the maximum number of positional arguments
  ///  1: the actual number of positional arguments given
  static const CompileTimeErrorCode EXTRA_POSITIONAL_ARGUMENTS =
      CompileTimeErrorCode(
    'EXTRA_POSITIONAL_ARGUMENTS',
    "Too many positional arguments: {0} expected, but {1} found.",
    correctionMessage: "Try removing the extra arguments.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the maximum number of positional arguments
  ///  1: the actual number of positional arguments given
  static const CompileTimeErrorCode EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED =
      CompileTimeErrorCode(
    'EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED',
    "Too many positional arguments: {0} expected, but {1} found.",
    correctionMessage:
        "Try removing the extra positional arguments, or specifying the name "
        "for named arguments.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the field being initialized multiple times
  static const CompileTimeErrorCode FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS =
      CompileTimeErrorCode(
    'FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS',
    "The field '{0}' can't be initialized twice in the same constructor.",
    correctionMessage: "Try removing one of the initializations.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION = CompileTimeErrorCode(
    'FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION',
    "Fields can't be initialized in the constructor if they are final and were "
        "already initialized at their declaration.",
    correctionMessage: "Try removing one of the initializations.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER = CompileTimeErrorCode(
    'FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER',
    "Fields can't be initialized in both the parameter list and the "
        "initializers.",
    correctionMessage: "Try removing one of the initializations.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode FIELD_INITIALIZER_FACTORY_CONSTRUCTOR =
      CompileTimeErrorCode(
    'FIELD_INITIALIZER_FACTORY_CONSTRUCTOR',
    "Initializing formal parameters can't be used in factory constructors.",
    correctionMessage: "Try using a normal parameter.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the type of the initializer expression
  ///  1: the name of the type of the field
  static const CompileTimeErrorCode FIELD_INITIALIZER_NOT_ASSIGNABLE =
      CompileTimeErrorCode(
    'FIELD_INITIALIZER_NOT_ASSIGNABLE',
    "The initializer type '{0}' can't be assigned to the field type '{1}'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR =
      CompileTimeErrorCode(
    'FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR',
    "Initializing formal parameters can only be used in constructors.",
    correctionMessage: "Try using a normal parameter.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR =
      CompileTimeErrorCode(
    'FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR',
    "The redirecting constructor can't have a field initializer.",
    correctionMessage:
        "Try initializing the field in the constructor being redirected to.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the type of the field formal parameter
  ///  1: the name of the type of the field
  static const CompileTimeErrorCode FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE =
      CompileTimeErrorCode(
    'FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE',
    "The parameter type '{0}' is incompatible with the field type '{1}'.",
    correctionMessage:
        "Try changing or removing the parameter's type, or changing the "
        "field's type.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the field in question
  static const CompileTimeErrorCode
      FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR = CompileTimeErrorCode(
    'FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR',
    "'{0}' is final and was given a value when it was declared, so it can't be "
        "set to a new value.",
    correctionMessage: "Try removing one of the initializations.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the uninitialized final variable
  static const CompileTimeErrorCode FINAL_NOT_INITIALIZED =
      CompileTimeErrorCode(
    'FINAL_NOT_INITIALIZED',
    "The final variable '{0}' must be initialized.",
    correctionMessage: "Try initializing the variable.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the uninitialized final variable
  static const CompileTimeErrorCode FINAL_NOT_INITIALIZED_CONSTRUCTOR_1 =
      CompileTimeErrorCode(
    'FINAL_NOT_INITIALIZED_CONSTRUCTOR',
    "All final variables must be initialized, but '{0}' isn't.",
    correctionMessage: "Try adding an initializer for the field.",
    hasPublishedDocs: true,
    uniqueName: 'FINAL_NOT_INITIALIZED_CONSTRUCTOR_1',
  );

  ///  Parameters:
  ///  0: the name of the uninitialized final variable
  ///  1: the name of the uninitialized final variable
  static const CompileTimeErrorCode FINAL_NOT_INITIALIZED_CONSTRUCTOR_2 =
      CompileTimeErrorCode(
    'FINAL_NOT_INITIALIZED_CONSTRUCTOR',
    "All final variables must be initialized, but '{0}' and '{1}' aren't.",
    correctionMessage: "Try adding initializers for the fields.",
    hasPublishedDocs: true,
    uniqueName: 'FINAL_NOT_INITIALIZED_CONSTRUCTOR_2',
  );

  ///  Parameters:
  ///  0: the name of the uninitialized final variable
  ///  1: the name of the uninitialized final variable
  ///  2: the number of additional not initialized variables that aren't listed
  static const CompileTimeErrorCode FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS =
      CompileTimeErrorCode(
    'FINAL_NOT_INITIALIZED_CONSTRUCTOR',
    "All final variables must be initialized, but '{0}', '{1}', and {2} others "
        "aren't.",
    correctionMessage: "Try adding initializers for the fields.",
    hasPublishedDocs: true,
    uniqueName: 'FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS',
  );

  ///  Parameters:
  ///  0: the type of the iterable expression.
  ///  1: the sequence type -- Iterable for `for` or Stream for `await for`.
  ///  2: the loop variable type.
  static const CompileTimeErrorCode FOR_IN_OF_INVALID_ELEMENT_TYPE =
      CompileTimeErrorCode(
    'FOR_IN_OF_INVALID_ELEMENT_TYPE',
    "The type '{0}' used in the 'for' loop must implement '{1}' with a type "
        "argument that can be assigned to '{2}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the type of the iterable expression.
  ///  1: the sequence type -- Iterable for `for` or Stream for `await for`.
  static const CompileTimeErrorCode FOR_IN_OF_INVALID_TYPE =
      CompileTimeErrorCode(
    'FOR_IN_OF_INVALID_TYPE',
    "The type '{0}' used in the 'for' loop must implement {1}.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode FOR_IN_WITH_CONST_VARIABLE =
      CompileTimeErrorCode(
    'FOR_IN_WITH_CONST_VARIABLE',
    "A for-in loop variable can't be a 'const'.",
    correctionMessage:
        "Try removing the 'const' modifier from the variable, or use a "
        "different variable.",
    hasPublishedDocs: true,
  );

  ///  It is a compile-time error if a generic function type is used as a bound
  ///  for a formal type parameter of a class or a function.
  static const CompileTimeErrorCode GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND =
      CompileTimeErrorCode(
    'GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND',
    "Generic function types can't be used as type parameter bounds",
    correctionMessage:
        "Try making the free variable in the function type part of the larger "
        "declaration signature",
  );

  ///  It is a compile-time error if a generic function type is used as an actual
  ///  type argument.
  static const CompileTimeErrorCode
      GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT = CompileTimeErrorCode(
    'GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT',
    "A generic function type can't be a type argument.",
    correctionMessage:
        "Try removing type parameters from the generic function type, or using "
        "'dynamic' as the type argument here.",
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      GENERIC_METHOD_TYPE_INSTANTIATION_ON_DYNAMIC = CompileTimeErrorCode(
    'GENERIC_METHOD_TYPE_INSTANTIATION_ON_DYNAMIC',
    "A method tear-off on a receiver whose type is 'dynamic' can't have type "
        "arguments.",
    correctionMessage:
        "Specify the type of the receiver, or remove the type arguments from "
        "the method tear-off.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the getter
  ///  1: the type of the getter
  ///  2: the type of the setter
  ///  3: the name of the setter
  static const CompileTimeErrorCode GETTER_NOT_ASSIGNABLE_SETTER_TYPES =
      CompileTimeErrorCode(
    'GETTER_NOT_ASSIGNABLE_SETTER_TYPES',
    "The return type of getter '{0}' is '{1}' which isn't assignable to the "
        "type '{2}' of its setter '{3}'.",
    correctionMessage: "Try changing the types so that they are compatible.",
  );

  ///  Parameters:
  ///  0: the name of the getter
  ///  1: the type of the getter
  ///  2: the type of the setter
  ///  3: the name of the setter
  static const CompileTimeErrorCode GETTER_NOT_SUBTYPE_SETTER_TYPES =
      CompileTimeErrorCode(
    'GETTER_NOT_SUBTYPE_SETTER_TYPES',
    "The return type of getter '{0}' is '{1}' which isn't a subtype of the "
        "type '{2}' of its setter '{3}'.",
    correctionMessage: "Try changing the types so that they are compatible.",
    hasPublishedDocs: true,
  );

  static const CompileTimeErrorCode IF_ELEMENT_CONDITION_FROM_DEFERRED_LIBRARY =
      CompileTimeErrorCode(
    'IF_ELEMENT_CONDITION_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as values in an if "
        "condition inside a const collection literal.",
    correctionMessage: "Try making the deferred import non-deferred.",
  );

  ///  No parameters.
  static const CompileTimeErrorCode ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE =
      CompileTimeErrorCode(
    'ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE',
    "Functions marked 'async*' must have a return type that is a supertype of "
        "'Stream<T>' for some type 'T'.",
    correctionMessage:
        "Try fixing the return type of the function, or removing the modifier "
        "'async*' from the function body.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode ILLEGAL_ASYNC_RETURN_TYPE =
      CompileTimeErrorCode(
    'ILLEGAL_ASYNC_RETURN_TYPE',
    "Functions marked 'async' must have a return type assignable to 'Future'.",
    correctionMessage:
        "Try fixing the return type of the function, or removing the modifier "
        "'async' from the function body.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of member that cannot be declared
  static const CompileTimeErrorCode ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION =
      CompileTimeErrorCode(
    'ILLEGAL_CONCRETE_ENUM_MEMBER',
    "A concrete instance member named '{0}' can't be declared in a class that "
        "implements 'Enum'.",
    correctionMessage: "Try using a different name.",
    hasPublishedDocs: true,
    uniqueName: 'ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION',
  );

  ///  Parameters:
  ///  0: the name of member that cannot be inherited
  ///  1: the name of the class that declares the member
  static const CompileTimeErrorCode ILLEGAL_CONCRETE_ENUM_MEMBER_INHERITANCE =
      CompileTimeErrorCode(
    'ILLEGAL_CONCRETE_ENUM_MEMBER',
    "A concrete instance member named '{0}' can't be inherited from '{1}' in a "
        "class that implements 'Enum'.",
    correctionMessage: "Try using a different name.",
    hasPublishedDocs: true,
    uniqueName: 'ILLEGAL_CONCRETE_ENUM_MEMBER_INHERITANCE',
  );

  static const CompileTimeErrorCode ILLEGAL_ENUM_VALUES_DECLARATION =
      CompileTimeErrorCode(
    'ILLEGAL_ENUM_VALUES',
    "An instance member named 'values' can't be declared in a class that "
        "implements 'Enum'.",
    correctionMessage: "Try using a different name.",
    hasPublishedDocs: true,
    uniqueName: 'ILLEGAL_ENUM_VALUES_DECLARATION',
  );

  ///  Parameters:
  ///  0: the name of the class that declares 'values'
  static const CompileTimeErrorCode ILLEGAL_ENUM_VALUES_INHERITANCE =
      CompileTimeErrorCode(
    'ILLEGAL_ENUM_VALUES',
    "An instance member named 'values' can't be inherited from '{0}' in a "
        "class that implements 'Enum'.",
    correctionMessage: "Try using a different name.",
    hasPublishedDocs: true,
    uniqueName: 'ILLEGAL_ENUM_VALUES_INHERITANCE',
  );

  static const CompileTimeErrorCode ILLEGAL_LANGUAGE_VERSION_OVERRIDE =
      CompileTimeErrorCode(
    'ILLEGAL_LANGUAGE_VERSION_OVERRIDE',
    "The language version must be {0}.",
    correctionMessage:
        "Try removing the language version override and migrating the code.",
  );

  ///  No parameters.
  static const CompileTimeErrorCode ILLEGAL_SYNC_GENERATOR_RETURN_TYPE =
      CompileTimeErrorCode(
    'ILLEGAL_SYNC_GENERATOR_RETURN_TYPE',
    "Functions marked 'sync*' must have a return type that is a supertype of "
        "'Iterable<T>' for some type 'T'.",
    correctionMessage:
        "Try fixing the return type of the function, or removing the modifier "
        "'sync*' from the function body.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode IMPLEMENTS_DEFERRED_CLASS =
      CompileTimeErrorCode(
    'SUBTYPE_OF_DEFERRED_CLASS',
    "Classes and mixins can't implement deferred classes.",
    correctionMessage:
        "Try specifying a different interface, removing the class from the "
        "list, or changing the import to not be deferred.",
    hasPublishedDocs: true,
    uniqueName: 'IMPLEMENTS_DEFERRED_CLASS',
  );

  ///  Parameters:
  ///  0: the name of the disallowed type
  static const CompileTimeErrorCode IMPLEMENTS_DISALLOWED_CLASS =
      CompileTimeErrorCode(
    'SUBTYPE_OF_DISALLOWED_TYPE',
    "Classes and mixins can't implement '{0}'.",
    correctionMessage:
        "Try specifying a different interface, or remove the class from the "
        "list.",
    hasPublishedDocs: true,
    uniqueName: 'IMPLEMENTS_DISALLOWED_CLASS',
  );

  ///  Parameters:
  ///  0: the name of the interface that was not found
  static const CompileTimeErrorCode IMPLEMENTS_NON_CLASS = CompileTimeErrorCode(
    'IMPLEMENTS_NON_CLASS',
    "Classes and mixins can only implement other classes and mixins.",
    correctionMessage:
        "Try specifying a class or mixin, or remove the name from the list.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the interface that is implemented more than once
  static const CompileTimeErrorCode IMPLEMENTS_REPEATED = CompileTimeErrorCode(
    'IMPLEMENTS_REPEATED',
    "'{0}' can only be implemented once.",
    correctionMessage: "Try removing all but one occurrence of the class name.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the class that appears in both "extends" and "implements"
  ///     clauses
  static const CompileTimeErrorCode IMPLEMENTS_SUPER_CLASS =
      CompileTimeErrorCode(
    'IMPLEMENTS_SUPER_CLASS',
    "'{0}' can't be used in both the 'extends' and 'implements' clauses.",
    correctionMessage: "Try removing one of the occurrences.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      IMPLEMENTS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER = CompileTimeErrorCode(
    'SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER',
    "A type alias that expands to a type parameter can't be implemented.",
    correctionMessage: "Try specifying a class or mixin, or removing the list.",
    hasPublishedDocs: true,
    uniqueName: 'IMPLEMENTS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
  );

  ///  Parameters:
  ///  0: the name of the superclass
  static const CompileTimeErrorCode
      IMPLICIT_SUPER_INITIALIZER_MISSING_ARGUMENTS = CompileTimeErrorCode(
    'IMPLICIT_SUPER_INITIALIZER_MISSING_ARGUMENTS',
    "The implicitly invoked unnamed constructor from '{0}' has required "
        "parameters.",
    correctionMessage:
        "Try adding an explicit super parameter with the required arguments.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the instance member
  static const CompileTimeErrorCode IMPLICIT_THIS_REFERENCE_IN_INITIALIZER =
      CompileTimeErrorCode(
    'IMPLICIT_THIS_REFERENCE_IN_INITIALIZER',
    "The instance member '{0}' can't be accessed in an initializer.",
    correctionMessage:
        "Try replacing the reference to the instance member with a different "
        "expression",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the uri pointing to a library
  static const CompileTimeErrorCode IMPORT_INTERNAL_LIBRARY =
      CompileTimeErrorCode(
    'IMPORT_INTERNAL_LIBRARY',
    "The library '{0}' is internal and can't be imported.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the uri pointing to a non-library declaration
  static const CompileTimeErrorCode IMPORT_OF_NON_LIBRARY =
      CompileTimeErrorCode(
    'IMPORT_OF_NON_LIBRARY',
    "The imported library '{0}' can't have a part-of directive.",
    correctionMessage: "Try importing the library that the part is a part of.",
    hasPublishedDocs: true,
  );

  ///  13.9 Switch: It is a compile-time error if values of the expressions
  ///  <i>e<sub>k</sub></i> are not instances of the same class <i>C</i>, for all
  ///  <i>1 &lt;= k &lt;= n</i>.
  ///
  ///  Parameters:
  ///  0: the expression source code that is the unexpected type
  ///  1: the name of the expected type
  static const CompileTimeErrorCode INCONSISTENT_CASE_EXPRESSION_TYPES =
      CompileTimeErrorCode(
    'INCONSISTENT_CASE_EXPRESSION_TYPES',
    "Case expressions must have the same types, '{0}' isn't a '{1}'.",
  );

  ///  Parameters:
  ///  0: the name of the instance member with inconsistent inheritance.
  ///  1: the list of all inherited signatures for this member.
  static const CompileTimeErrorCode INCONSISTENT_INHERITANCE =
      CompileTimeErrorCode(
    'INCONSISTENT_INHERITANCE',
    "Superinterfaces don't have a valid override for '{0}': {1}.",
    correctionMessage:
        "Try adding an explicit override that is consistent with all of the "
        "inherited members.",
    hasPublishedDocs: true,
  );

  ///  11.1.1 Inheritance and Overriding. Let `I` be the implicit interface of a
  ///  class `C` declared in library `L`. `I` inherits all members of
  ///  `inherited(I, L)` and `I` overrides `m'` if `m' ∈ overrides(I, L)`. It is
  ///  a compile-time error if `m` is a method and `m'` is a getter, or if `m`
  ///  is a getter and `m'` is a method.
  ///
  ///  Parameters:
  ///  0: the name of the instance member with inconsistent inheritance.
  ///  1: the name of the superinterface that declares the name as a getter.
  ///  2: the name of the superinterface that declares the name as a method.
  static const CompileTimeErrorCode INCONSISTENT_INHERITANCE_GETTER_AND_METHOD =
      CompileTimeErrorCode(
    'INCONSISTENT_INHERITANCE_GETTER_AND_METHOD',
    "'{0}' is inherited as a getter (from '{1}') and also a method (from "
        "'{2}').",
    correctionMessage:
        "Try adjusting the supertypes of this class to remove the "
        "inconsistency.",
  );

  ///  No parameters.
  static const CompileTimeErrorCode INCONSISTENT_LANGUAGE_VERSION_OVERRIDE =
      CompileTimeErrorCode(
    'INCONSISTENT_LANGUAGE_VERSION_OVERRIDE',
    "Parts must have exactly the same language version override as the "
        "library.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the initializing formal that is not an instance variable in
  ///     the immediately enclosing class
  static const CompileTimeErrorCode INITIALIZER_FOR_NON_EXISTENT_FIELD =
      CompileTimeErrorCode(
    'INITIALIZER_FOR_NON_EXISTENT_FIELD',
    "'{0}' isn't a field in the enclosing class.",
    correctionMessage:
        "Try correcting the name to match an existing field, or defining a "
        "field named '{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the initializing formal that is a static variable in the
  ///     immediately enclosing class
  static const CompileTimeErrorCode INITIALIZER_FOR_STATIC_FIELD =
      CompileTimeErrorCode(
    'INITIALIZER_FOR_STATIC_FIELD',
    "'{0}' is a static field in the enclosing class. Fields initialized in a "
        "constructor can't be static.",
    correctionMessage: "Try removing the initialization.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the initializing formal that is not an instance variable in
  ///     the immediately enclosing class
  static const CompileTimeErrorCode INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD =
      CompileTimeErrorCode(
    'INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD',
    "'{0}' isn't a field in the enclosing class.",
    correctionMessage:
        "Try correcting the name to match an existing field, or defining a "
        "field named '{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the static member
  ///  1: the kind of the static member (field, getter, setter, or method)
  ///  2: the name of the static member's enclosing element
  ///  3: the kind of the static member's enclosing element (class, mixin, or extension)
  static const CompileTimeErrorCode INSTANCE_ACCESS_TO_STATIC_MEMBER =
      CompileTimeErrorCode(
    'INSTANCE_ACCESS_TO_STATIC_MEMBER',
    "The static {1} '{0}' can't be accessed through an instance.",
    correctionMessage: "Try using the {3} '{2}' to access the {1}.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the static member
  ///  1: the kind of the static member (field, getter, setter, or method)
  static const CompileTimeErrorCode
      INSTANCE_ACCESS_TO_STATIC_MEMBER_OF_UNNAMED_EXTENSION =
      CompileTimeErrorCode(
    'INSTANCE_ACCESS_TO_STATIC_MEMBER',
    "The static {1} '{0}' can't be accessed through an instance.",
    hasPublishedDocs: true,
    uniqueName: 'INSTANCE_ACCESS_TO_STATIC_MEMBER_OF_UNNAMED_EXTENSION',
  );

  ///  No parameters.
  static const CompileTimeErrorCode INSTANCE_MEMBER_ACCESS_FROM_FACTORY =
      CompileTimeErrorCode(
    'INSTANCE_MEMBER_ACCESS_FROM_FACTORY',
    "Instance members can't be accessed from a factory constructor.",
    correctionMessage: "Try removing the reference to the instance member.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode INSTANCE_MEMBER_ACCESS_FROM_STATIC =
      CompileTimeErrorCode(
    'INSTANCE_MEMBER_ACCESS_FROM_STATIC',
    "Instance members can't be accessed from a static method.",
    correctionMessage:
        "Try removing the reference to the instance member, or removing the "
        "keyword 'static' from the method.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode INSTANTIATE_ABSTRACT_CLASS =
      CompileTimeErrorCode(
    'INSTANTIATE_ABSTRACT_CLASS',
    "Abstract classes can't be instantiated.",
    correctionMessage: "Try creating an instance of a concrete subtype.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode INSTANTIATE_ENUM = CompileTimeErrorCode(
    'INSTANTIATE_ENUM',
    "Enums can't be instantiated.",
    correctionMessage: "Try using one of the defined constants.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      INSTANTIATE_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER = CompileTimeErrorCode(
    'INSTANTIATE_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    "Type aliases that expand to a type parameter can't be instantiated.",
    correctionMessage: "Try replacing it with a class.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the lexeme of the integer
  static const CompileTimeErrorCode INTEGER_LITERAL_IMPRECISE_AS_DOUBLE =
      CompileTimeErrorCode(
    'INTEGER_LITERAL_IMPRECISE_AS_DOUBLE',
    "The integer literal is being used as a double, but can't be represented "
        "as a 64-bit double without overflow or loss of precision: '{0}'.",
    correctionMessage:
        "Try using the class 'BigInt', or switch to the closest valid double: "
        "'{1}'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode INTEGER_LITERAL_OUT_OF_RANGE =
      CompileTimeErrorCode(
    'INTEGER_LITERAL_OUT_OF_RANGE',
    "The integer literal {0} can't be represented in 64 bits.",
    correctionMessage:
        "Try using the 'BigInt' class if you need an integer larger than "
        "9,223,372,036,854,775,807 or less than -9,223,372,036,854,775,808.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode INVALID_ANNOTATION = CompileTimeErrorCode(
    'INVALID_ANNOTATION',
    "Annotation must be either a const variable reference or const constructor "
        "invocation.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      INVALID_ANNOTATION_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY =
      CompileTimeErrorCode(
    'INVALID_ANNOTATION_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used in annotations.",
    correctionMessage:
        "Try moving the constant from the deferred library, or removing "
        "'deferred' from the import.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY =
      CompileTimeErrorCode(
    'INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as annotations.",
    correctionMessage:
        "Try removing the annotation, or changing the import to not be "
        "deferred.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the right hand side type
  ///  1: the name of the left hand side type
  static const CompileTimeErrorCode INVALID_ASSIGNMENT = CompileTimeErrorCode(
    'INVALID_ASSIGNMENT',
    "A value of type '{0}' can't be assigned to a variable of type '{1}'.",
    correctionMessage:
        "Try changing the type of the variable, or casting the right-hand type "
        "to '{1}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the type of the function
  ///  1: the expected function type
  ///
  ///  This error is only reported in libraries which are not null safe.
  static const CompileTimeErrorCode INVALID_CAST_FUNCTION =
      CompileTimeErrorCode(
    'INVALID_CAST_FUNCTION',
    "The function '{0}' has type '{1}' that isn't of expected type '{2}'. This "
        "means its parameter or return type doesn't match what is expected.",
  );

  ///  Parameters:
  ///  0: the type of the torn-off function expression
  ///  1: the expected function type
  ///
  ///  This error is only reported in libraries which are not null safe.
  static const CompileTimeErrorCode INVALID_CAST_FUNCTION_EXPR =
      CompileTimeErrorCode(
    'INVALID_CAST_FUNCTION_EXPR',
    "The function expression type '{0}' isn't of type '{1}'. This means its "
        "parameter or return type doesn't match what is expected. Consider "
        "changing parameter type(s) or the returned type(s).",
  );

  ///  Parameters:
  ///  0: the type of the literal
  ///  1: the expected type
  ///
  ///  This error is only reported in libraries which are not null safe.
  static const CompileTimeErrorCode INVALID_CAST_LITERAL = CompileTimeErrorCode(
    'INVALID_CAST_LITERAL',
    "The literal '{0}' with type '{1}' isn't of expected type '{2}'.",
  );

  ///  Parameters:
  ///  0: the type of the list literal
  ///  1: the expected type
  ///
  ///  This error is only reported in libraries which are not null safe.
  static const CompileTimeErrorCode INVALID_CAST_LITERAL_LIST =
      CompileTimeErrorCode(
    'INVALID_CAST_LITERAL_LIST',
    "The list literal type '{0}' isn't of expected type '{1}'. The list's type "
        "can be changed with an explicit generic type argument or by changing "
        "the element types.",
  );

  ///  Parameters:
  ///  0: the type of the map literal
  ///  1: the expected type
  ///
  ///  This error is only reported in libraries which are not null safe.
  static const CompileTimeErrorCode INVALID_CAST_LITERAL_MAP =
      CompileTimeErrorCode(
    'INVALID_CAST_LITERAL_MAP',
    "The map literal type '{0}' isn't of expected type '{1}'. The map's type "
        "can be changed with an explicit generic type arguments or by changing "
        "the key and value types.",
  );

  ///  Parameters:
  ///  0: the type of the set literal
  ///  1: the expected type
  ///
  ///  This error is only reported in libraries which are not null safe.
  static const CompileTimeErrorCode INVALID_CAST_LITERAL_SET =
      CompileTimeErrorCode(
    'INVALID_CAST_LITERAL_SET',
    "The set literal type '{0}' isn't of expected type '{1}'. The set's type "
        "can be changed with an explicit generic type argument or by changing "
        "the element types.",
  );

  ///  Parameters:
  ///  0: the type of the torn-off method
  ///  1: the expected function type
  ///
  ///  This error is only reported in libraries which are not null safe.
  static const CompileTimeErrorCode INVALID_CAST_METHOD = CompileTimeErrorCode(
    'INVALID_CAST_METHOD',
    "The method tear-off '{0}' has type '{1}' that isn't of expected type "
        "'{2}'. This means its parameter or return type doesn't match what is "
        "expected.",
  );

  ///  Parameters:
  ///  0: the type of the instantiated object
  ///  1: the expected type
  ///
  ///  This error is only reported in libraries which are not null safe.
  static const CompileTimeErrorCode INVALID_CAST_NEW_EXPR =
      CompileTimeErrorCode(
    'INVALID_CAST_NEW_EXPR',
    "The constructor returns type '{0}' that isn't of expected type '{1}'.",
  );

  ///  TODO(brianwilkerson) Remove this when we have decided on how to report
  ///  errors in compile-time constants. Until then, this acts as a placeholder
  ///  for more informative errors.
  ///
  ///  See TODOs in ConstantVisitor
  static const CompileTimeErrorCode INVALID_CONSTANT = CompileTimeErrorCode(
    'INVALID_CONSTANT',
    "Invalid constant value.",
  );

  ///  No parameters.
  static const CompileTimeErrorCode INVALID_EXTENSION_ARGUMENT_COUNT =
      CompileTimeErrorCode(
    'INVALID_EXTENSION_ARGUMENT_COUNT',
    "Extension overrides must have exactly one argument: the value of 'this' "
        "in the extension method.",
    correctionMessage: "Try specifying exactly one argument.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode INVALID_FACTORY_NAME_NOT_A_CLASS =
      CompileTimeErrorCode(
    'INVALID_FACTORY_NAME_NOT_A_CLASS',
    "The name of a factory constructor must be the same as the name of the "
        "immediately enclosing class.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the declared member that is not a valid override.
  ///  1: the name of the interface that declares the member.
  ///  2: the type of the declared member in the interface.
  ///  3. the name of the interface with the overridden member.
  ///  4. the type of the overridden member.
  ///
  ///  These parameters must be kept in sync with those of
  ///  [CompileTimeErrorCode.INVALID_OVERRIDE].
  static const CompileTimeErrorCode INVALID_IMPLEMENTATION_OVERRIDE =
      CompileTimeErrorCode(
    'INVALID_IMPLEMENTATION_OVERRIDE',
    "'{1}.{0}' ('{2}') isn't a valid concrete implementation of '{3}.{0}' "
        "('{4}').",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode INVALID_INLINE_FUNCTION_TYPE =
      CompileTimeErrorCode(
    'INVALID_INLINE_FUNCTION_TYPE',
    "Inline function types can't be used for parameters in a generic function "
        "type.",
    correctionMessage:
        "Try using a generic function type (returnType 'Function(' parameters "
        "')').",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the invalid modifier
  static const CompileTimeErrorCode INVALID_MODIFIER_ON_CONSTRUCTOR =
      CompileTimeErrorCode(
    'INVALID_MODIFIER_ON_CONSTRUCTOR',
    "The modifier '{0}' can't be applied to the body of a constructor.",
    correctionMessage: "Try removing the modifier.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the invalid modifier
  static const CompileTimeErrorCode INVALID_MODIFIER_ON_SETTER =
      CompileTimeErrorCode(
    'INVALID_MODIFIER_ON_SETTER',
    "Setters can't use 'async', 'async*', or 'sync*'.",
    correctionMessage: "Try removing the modifier.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the declared member that is not a valid override.
  ///  1: the name of the interface that declares the member.
  ///  2: the type of the declared member in the interface.
  ///  3. the name of the interface with the overridden member.
  ///  4. the type of the overridden member.
  static const CompileTimeErrorCode INVALID_OVERRIDE = CompileTimeErrorCode(
    'INVALID_OVERRIDE',
    "'{1}.{0}' ('{2}') isn't a valid override of '{3}.{0}' ('{4}').",
    hasPublishedDocs: true,
  );

  static const CompileTimeErrorCode
      INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR = CompileTimeErrorCode(
    'INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR',
    "Generative enum constructors can only be used as targets of redirection.",
    correctionMessage: "Try using an enum constant, or a factory constructor.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode INVALID_REFERENCE_TO_THIS =
      CompileTimeErrorCode(
    'INVALID_REFERENCE_TO_THIS',
    "Invalid reference to 'this' expression.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the super modifier
  static const CompileTimeErrorCode INVALID_SUPER_FORMAL_PARAMETER_LOCATION =
      CompileTimeErrorCode(
    'INVALID_SUPER_FORMAL_PARAMETER_LOCATION',
    "Super parameters can only be used in non-redirecting generative "
        "constructors.",
    correctionMessage:
        "Try removing the 'super' modifier, or changing the constructor to be "
        "non-redirecting and generative.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the type parameter
  static const CompileTimeErrorCode INVALID_TYPE_ARGUMENT_IN_CONST_LIST =
      CompileTimeErrorCode(
    'INVALID_TYPE_ARGUMENT_IN_CONST_LITERAL',
    "Constant list literals can't include a type parameter as a type argument, "
        "such as '{0}'.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_TYPE_ARGUMENT_IN_CONST_LIST',
  );

  ///  Parameters:
  ///  0: the name of the type parameter
  static const CompileTimeErrorCode INVALID_TYPE_ARGUMENT_IN_CONST_MAP =
      CompileTimeErrorCode(
    'INVALID_TYPE_ARGUMENT_IN_CONST_LITERAL',
    "Constant map literals can't include a type parameter as a type argument, "
        "such as '{0}'.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_TYPE_ARGUMENT_IN_CONST_MAP',
  );

  ///  Parameters:
  ///  0: the name of the type parameter
  static const CompileTimeErrorCode INVALID_TYPE_ARGUMENT_IN_CONST_SET =
      CompileTimeErrorCode(
    'INVALID_TYPE_ARGUMENT_IN_CONST_LITERAL',
    "Constant set literals can't include a type parameter as a type argument, "
        "such as '{0}'.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_TYPE_ARGUMENT_IN_CONST_SET',
  );

  ///  Parameters:
  ///  0: the URI that is invalid
  static const CompileTimeErrorCode INVALID_URI = CompileTimeErrorCode(
    'INVALID_URI',
    "Invalid URI syntax: '{0}'.",
    hasPublishedDocs: true,
  );

  ///  The 'covariant' keyword was found in an inappropriate location.
  static const CompileTimeErrorCode INVALID_USE_OF_COVARIANT =
      CompileTimeErrorCode(
    'INVALID_USE_OF_COVARIANT',
    "The 'covariant' keyword can only be used for parameters in instance "
        "methods or before non-final instance fields.",
    correctionMessage: "Try removing the 'covariant' keyword.",
  );

  ///  No parameters.
  static const CompileTimeErrorCode INVALID_USE_OF_NULL_VALUE =
      CompileTimeErrorCode(
    'INVALID_USE_OF_NULL_VALUE',
    "An expression whose value is always 'null' can't be dereferenced.",
    correctionMessage: "Try changing the type of the expression.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the extension
  static const CompileTimeErrorCode INVOCATION_OF_EXTENSION_WITHOUT_CALL =
      CompileTimeErrorCode(
    'INVOCATION_OF_EXTENSION_WITHOUT_CALL',
    "The extension '{0}' doesn't define a 'call' method so the override can't "
        "be used in an invocation.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the identifier that is not a function type
  static const CompileTimeErrorCode INVOCATION_OF_NON_FUNCTION =
      CompileTimeErrorCode(
    'INVOCATION_OF_NON_FUNCTION',
    "'{0}' isn't a function.",
    correctionMessage:
        "Try correcting the name to match an existing function, or define a "
        "method or function named '{0}'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode INVOCATION_OF_NON_FUNCTION_EXPRESSION =
      CompileTimeErrorCode(
    'INVOCATION_OF_NON_FUNCTION_EXPRESSION',
    "The expression doesn't evaluate to a function, so it can't be invoked.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the unresolvable label
  static const CompileTimeErrorCode LABEL_IN_OUTER_SCOPE = CompileTimeErrorCode(
    'LABEL_IN_OUTER_SCOPE',
    "Can't reference label '{0}' declared in an outer method.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the unresolvable label
  static const CompileTimeErrorCode LABEL_UNDEFINED = CompileTimeErrorCode(
    'LABEL_UNDEFINED',
    "Can't reference an undefined label '{0}'.",
    correctionMessage:
        "Try defining the label, or correcting the name to match an existing "
        "label.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode LATE_FINAL_FIELD_WITH_CONST_CONSTRUCTOR =
      CompileTimeErrorCode(
    'LATE_FINAL_FIELD_WITH_CONST_CONSTRUCTOR',
    "Can't have a late final field in a class with a generative const "
        "constructor.",
    correctionMessage:
        "Try removing the 'late' modifier, or don't declare 'const' "
        "constructors.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode LATE_FINAL_LOCAL_ALREADY_ASSIGNED =
      CompileTimeErrorCode(
    'LATE_FINAL_LOCAL_ALREADY_ASSIGNED',
    "The late final local variable is already assigned.",
    correctionMessage:
        "Try removing the 'final' modifier, or don't reassign the value.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the actual type of the list element
  ///  1: the expected type of the list element
  static const CompileTimeErrorCode LIST_ELEMENT_TYPE_NOT_ASSIGNABLE =
      CompileTimeErrorCode(
    'LIST_ELEMENT_TYPE_NOT_ASSIGNABLE',
    "The element type '{0}' can't be assigned to the list type '{1}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the message of the exception
  ///  1: the stack trace
  static const CompileTimeErrorCode MACRO_EXECUTION_EXCEPTION =
      CompileTimeErrorCode(
    'MACRO_EXECUTION_EXCEPTION',
    "Exception during macro execution: {0}\n{1}",
    correctionMessage: "Re-install the Dart or Flutter SDK.",
  );

  ///  No parameters.
  static const CompileTimeErrorCode MAIN_FIRST_POSITIONAL_PARAMETER_TYPE =
      CompileTimeErrorCode(
    'MAIN_FIRST_POSITIONAL_PARAMETER_TYPE',
    "The type of the first positional parameter of the 'main' function must be "
        "a supertype of 'List<String>'.",
    correctionMessage: "Try changing the type of the parameter.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode MAIN_HAS_REQUIRED_NAMED_PARAMETERS =
      CompileTimeErrorCode(
    'MAIN_HAS_REQUIRED_NAMED_PARAMETERS',
    "The function 'main' can't have any required named parameters.",
    correctionMessage:
        "Try using a different name for the function, or removing the "
        "'required' modifier.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      MAIN_HAS_TOO_MANY_REQUIRED_POSITIONAL_PARAMETERS = CompileTimeErrorCode(
    'MAIN_HAS_TOO_MANY_REQUIRED_POSITIONAL_PARAMETERS',
    "The function 'main' can't have more than two required positional "
        "parameters.",
    correctionMessage:
        "Try using a different name for the function, or removing extra "
        "parameters.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode MAIN_IS_NOT_FUNCTION = CompileTimeErrorCode(
    'MAIN_IS_NOT_FUNCTION',
    "The declaration named 'main' must be a function.",
    correctionMessage: "Try using a different name for this declaration.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode MAP_ENTRY_NOT_IN_MAP = CompileTimeErrorCode(
    'MAP_ENTRY_NOT_IN_MAP',
    "Map entries can only be used in a map literal.",
    correctionMessage:
        "Try converting the collection to a map or removing the map entry.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the type of the expression being used as a key
  ///  1: the type of keys declared for the map
  static const CompileTimeErrorCode MAP_KEY_TYPE_NOT_ASSIGNABLE =
      CompileTimeErrorCode(
    'MAP_KEY_TYPE_NOT_ASSIGNABLE',
    "The element type '{0}' can't be assigned to the map key type '{1}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the type of the expression being used as a value
  ///  1: the type of values declared for the map
  static const CompileTimeErrorCode MAP_VALUE_TYPE_NOT_ASSIGNABLE =
      CompileTimeErrorCode(
    'MAP_VALUE_TYPE_NOT_ASSIGNABLE',
    "The element type '{0}' can't be assigned to the map value type '{1}'.",
    hasPublishedDocs: true,
  );

  ///  12.1 Constants: A constant expression is ... a constant list literal.
  ///
  ///  Note: This diagnostic is never displayed to the user, so it doesn't need
  ///  to be documented.
  static const CompileTimeErrorCode MISSING_CONST_IN_LIST_LITERAL =
      CompileTimeErrorCode(
    'MISSING_CONST_IN_LIST_LITERAL',
    "Seeing this message constitutes a bug. Please report it.",
  );

  ///  12.1 Constants: A constant expression is ... a constant map literal.
  ///
  ///  Note: This diagnostic is never displayed to the user, so it doesn't need
  ///  to be documented.
  static const CompileTimeErrorCode MISSING_CONST_IN_MAP_LITERAL =
      CompileTimeErrorCode(
    'MISSING_CONST_IN_MAP_LITERAL',
    "Seeing this message constitutes a bug. Please report it.",
  );

  ///  12.1 Constants: A constant expression is ... a constant set literal.
  ///
  ///  Note: This diagnostic is never displayed to the user, so it doesn't need
  ///  to be documented.
  static const CompileTimeErrorCode MISSING_CONST_IN_SET_LITERAL =
      CompileTimeErrorCode(
    'MISSING_CONST_IN_SET_LITERAL',
    "Seeing this message constitutes a bug. Please report it.",
  );

  ///  No parameters.
  static const CompileTimeErrorCode MISSING_DART_LIBRARY = CompileTimeErrorCode(
    'MISSING_DART_LIBRARY',
    "Required library '{0}' is missing.",
    correctionMessage: "Re-install the Dart or Flutter SDK.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode MISSING_DEFAULT_VALUE_FOR_PARAMETER =
      CompileTimeErrorCode(
    'MISSING_DEFAULT_VALUE_FOR_PARAMETER',
    "The parameter '{0}' can't have a value of 'null' because of its type, but "
        "the implicit default value is 'null'.",
    correctionMessage:
        "Try adding either an explicit non-'null' default value or the "
        "'required' modifier.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      MISSING_DEFAULT_VALUE_FOR_PARAMETER_WITH_ANNOTATION =
      CompileTimeErrorCode(
    'MISSING_DEFAULT_VALUE_FOR_PARAMETER',
    "With null safety, use the 'required' keyword, not the '@required' "
        "annotation.",
    correctionMessage: "Try removing the '@'.",
    hasPublishedDocs: true,
    uniqueName: 'MISSING_DEFAULT_VALUE_FOR_PARAMETER_WITH_ANNOTATION',
  );

  ///  Parameters:
  ///  0: the name of the parameter
  static const CompileTimeErrorCode MISSING_REQUIRED_ARGUMENT =
      CompileTimeErrorCode(
    'MISSING_REQUIRED_ARGUMENT',
    "The named parameter '{0}' is required, but there's no corresponding "
        "argument.",
    correctionMessage: "Try adding the required argument.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the class that appears in both "extends" and "with" clauses
  static const CompileTimeErrorCode MIXINS_SUPER_CLASS = CompileTimeErrorCode(
    'IMPLEMENTS_SUPER_CLASS',
    "'{0}' can't be used in both the 'extends' and 'with' clauses.",
    correctionMessage: "Try removing one of the occurrences.",
    hasPublishedDocs: true,
    uniqueName: 'MIXINS_SUPER_CLASS',
  );

  ///  Parameters:
  ///  0: the name of the super-invoked member
  ///  1: the display name of the type of the super-invoked member in the mixin
  ///  2: the display name of the type of the concrete member in the class
  static const CompileTimeErrorCode
      MIXIN_APPLICATION_CONCRETE_SUPER_INVOKED_MEMBER_TYPE =
      CompileTimeErrorCode(
    'MIXIN_APPLICATION_CONCRETE_SUPER_INVOKED_MEMBER_TYPE',
    "The super-invoked member '{0}' has the type '{1}', and the concrete "
        "member in the class has the type '{2}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the display name of the mixin
  ///  1: the display name of the superclass
  ///  2: the display name of the type that is not implemented
  static const CompileTimeErrorCode
      MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE = CompileTimeErrorCode(
    'MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE',
    "'{0}' can't be mixed onto '{1}' because '{1}' doesn't implement '{2}'.",
    correctionMessage: "Try extending the class '{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the display name of the member without a concrete implementation
  static const CompileTimeErrorCode
      MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER = CompileTimeErrorCode(
    'MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER',
    "The class doesn't have a concrete implementation of the super-invoked "
        "member '{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the mixin that is invalid
  static const CompileTimeErrorCode MIXIN_CLASS_DECLARES_CONSTRUCTOR =
      CompileTimeErrorCode(
    'MIXIN_CLASS_DECLARES_CONSTRUCTOR',
    "The class '{0}' can't be used as a mixin because it declares a "
        "constructor.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode MIXIN_DEFERRED_CLASS = CompileTimeErrorCode(
    'SUBTYPE_OF_DEFERRED_CLASS',
    "Classes can't mixin deferred classes.",
    correctionMessage: "Try changing the import to not be deferred.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_DEFERRED_CLASS',
  );

  ///  Parameters:
  ///  0: the name of the mixin that is invalid
  static const CompileTimeErrorCode MIXIN_INHERITS_FROM_NOT_OBJECT =
      CompileTimeErrorCode(
    'MIXIN_INHERITS_FROM_NOT_OBJECT',
    "The class '{0}' can't be used as a mixin because it extends a class other "
        "than 'Object'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode MIXIN_INSTANTIATE = CompileTimeErrorCode(
    'MIXIN_INSTANTIATE',
    "Mixins can't be instantiated.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the disallowed type
  static const CompileTimeErrorCode MIXIN_OF_DISALLOWED_CLASS =
      CompileTimeErrorCode(
    'SUBTYPE_OF_DISALLOWED_TYPE',
    "Classes can't mixin '{0}'.",
    correctionMessage:
        "Try specifying a different class or mixin, or remove the class or "
        "mixin from the list.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_OF_DISALLOWED_CLASS',
  );

  ///  No parameters.
  static const CompileTimeErrorCode MIXIN_OF_NON_CLASS = CompileTimeErrorCode(
    'MIXIN_OF_NON_CLASS',
    "Classes can only mix in mixins and classes.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      MIXIN_OF_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER = CompileTimeErrorCode(
    'SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER',
    "A type alias that expands to a type parameter can't be mixed in.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_OF_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      MIXIN_ON_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER = CompileTimeErrorCode(
    'SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER',
    "A type alias that expands to a type parameter can't be used as a "
        "superclass constraint.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_ON_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      MIXIN_SUPER_CLASS_CONSTRAINT_DEFERRED_CLASS = CompileTimeErrorCode(
    'MIXIN_SUPER_CLASS_CONSTRAINT_DEFERRED_CLASS',
    "Deferred classes can't be used as superclass constraints.",
    correctionMessage: "Try changing the import to not be deferred.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the disallowed type
  static const CompileTimeErrorCode
      MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS = CompileTimeErrorCode(
    'SUBTYPE_OF_DISALLOWED_TYPE',
    "''{0}' can't be used as a superclass constraint.",
    correctionMessage:
        "Try specifying a different super-class constraint, or remove the 'on' "
        "clause.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS',
  );

  ///  No parameters.
  static const CompileTimeErrorCode MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE =
      CompileTimeErrorCode(
    'MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE',
    "Only classes and mixins can be used as superclass constraints.",
    hasPublishedDocs: true,
  );

  ///  9.1 Mixin Application: It is a compile-time error if <i>S</i> does not
  ///  denote a class available in the immediately enclosing scope.
  static const CompileTimeErrorCode MIXIN_WITH_NON_CLASS_SUPERCLASS =
      CompileTimeErrorCode(
    'MIXIN_WITH_NON_CLASS_SUPERCLASS',
    "Mixin can only be applied to class.",
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS = CompileTimeErrorCode(
    'MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS',
    "Constructors can have only one 'this' redirection, at most.",
    correctionMessage: "Try removing all but one of the redirections.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode MULTIPLE_SUPER_INITIALIZERS =
      CompileTimeErrorCode(
    'MULTIPLE_SUPER_INITIALIZERS',
    "A constructor can have at most one 'super' initializer.",
    correctionMessage: "Try removing all but one of the 'super' initializers.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the non-type element
  static const CompileTimeErrorCode NEW_WITH_NON_TYPE = CompileTimeErrorCode(
    'CREATION_WITH_NON_TYPE',
    "The name '{0}' isn't a class.",
    correctionMessage: "Try correcting the name to match an existing class.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
    uniqueName: 'NEW_WITH_NON_TYPE',
  );

  ///  12.11.1 New: If <i>T</i> is a class or parameterized type accessible in the
  ///  current scope then:
  ///  1. If <i>e</i> is of the form <i>new T.id(a<sub>1</sub>, &hellip;,
  ///     a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;,
  ///     x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a static warning if
  ///     <i>T.id</i> is not the name of a constructor declared by the type
  ///     <i>T</i>.
  ///  If <i>e</i> of the form <i>new T(a<sub>1</sub>, &hellip;, a<sub>n</sub>,
  ///  x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>:
  ///  a<sub>n+kM/sub>)</i> it is a static warning if the type <i>T</i> does not
  ///  declare a constructor with the same name as the declaration of <i>T</i>.
  static const CompileTimeErrorCode NEW_WITH_UNDEFINED_CONSTRUCTOR =
      CompileTimeErrorCode(
    'NEW_WITH_UNDEFINED_CONSTRUCTOR',
    "The class '{0}' doesn't have a constructor named '{1}'.",
    correctionMessage:
        "Try invoking a different constructor, or define a constructor named "
        "'{1}'.",
  );

  ///  Parameters:
  ///  0: the name of the class being instantiated
  static const CompileTimeErrorCode NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT =
      CompileTimeErrorCode(
    'NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT',
    "The class '{0}' doesn't have an unnamed constructor.",
    correctionMessage:
        "Try using one of the named constructors defined in '{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the first member
  ///  1: the name of the second member
  ///  2: the name of the third member
  ///  3: the name of the fourth member
  ///  4: the number of additional missing members that aren't listed
  static const CompileTimeErrorCode
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS =
      CompileTimeErrorCode(
    'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
    "Missing concrete implementations of '{0}', '{1}', '{2}', '{3}', and {4} "
        "more.",
    correctionMessage:
        "Try implementing the missing methods, or make the class abstract.",
    hasPublishedDocs: true,
    uniqueName: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS',
  );

  ///  Parameters:
  ///  0: the name of the first member
  ///  1: the name of the second member
  ///  2: the name of the third member
  ///  3: the name of the fourth member
  static const CompileTimeErrorCode
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR = CompileTimeErrorCode(
    'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
    "Missing concrete implementations of '{0}', '{1}', '{2}', and '{3}'.",
    correctionMessage:
        "Try implementing the missing methods, or make the class abstract.",
    hasPublishedDocs: true,
    uniqueName: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR',
  );

  ///  Parameters:
  ///  0: the name of the member
  static const CompileTimeErrorCode
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE = CompileTimeErrorCode(
    'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
    "Missing concrete implementation of '{0}'.",
    correctionMessage:
        "Try implementing the missing method, or make the class abstract.",
    hasPublishedDocs: true,
    uniqueName: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE',
  );

  ///  Parameters:
  ///  0: the name of the first member
  ///  1: the name of the second member
  ///  2: the name of the third member
  static const CompileTimeErrorCode
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE = CompileTimeErrorCode(
    'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
    "Missing concrete implementations of '{0}', '{1}', and '{2}'.",
    correctionMessage:
        "Try implementing the missing methods, or make the class abstract.",
    hasPublishedDocs: true,
    uniqueName: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE',
  );

  ///  Parameters:
  ///  0: the name of the first member
  ///  1: the name of the second member
  static const CompileTimeErrorCode
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO = CompileTimeErrorCode(
    'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
    "Missing concrete implementations of '{0}' and '{1}'.",
    correctionMessage:
        "Try implementing the missing methods, or make the class abstract.",
    hasPublishedDocs: true,
    uniqueName: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO',
  );

  ///  No parameters.
  static const CompileTimeErrorCode NON_BOOL_CONDITION = CompileTimeErrorCode(
    'NON_BOOL_CONDITION',
    "Conditions must have a static type of 'bool'.",
    correctionMessage: "Try changing the condition.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode NON_BOOL_EXPRESSION = CompileTimeErrorCode(
    'NON_BOOL_EXPRESSION',
    "The expression in an assert must be of type 'bool'.",
    correctionMessage: "Try changing the expression.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode NON_BOOL_NEGATION_EXPRESSION =
      CompileTimeErrorCode(
    'NON_BOOL_NEGATION_EXPRESSION',
    "A negation operand must have a static type of 'bool'.",
    correctionMessage: "Try changing the operand to the '!' operator.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the lexeme of the logical operator
  static const CompileTimeErrorCode NON_BOOL_OPERAND = CompileTimeErrorCode(
    'NON_BOOL_OPERAND',
    "The operands of the operator '{0}' must be assignable to 'bool'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode NON_CONSTANT_ANNOTATION_CONSTRUCTOR =
      CompileTimeErrorCode(
    'NON_CONSTANT_ANNOTATION_CONSTRUCTOR',
    "Annotation creation can only call a const constructor.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode NON_CONSTANT_CASE_EXPRESSION =
      CompileTimeErrorCode(
    'NON_CONSTANT_CASE_EXPRESSION',
    "Case expressions must be constant.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY = CompileTimeErrorCode(
    'NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as a case "
        "expression.",
    correctionMessage:
        "Try re-writing the switch as a series of if statements, or changing "
        "the import to not be deferred.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode NON_CONSTANT_DEFAULT_VALUE =
      CompileTimeErrorCode(
    'NON_CONSTANT_DEFAULT_VALUE',
    "The default value of an optional parameter must be constant.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY = CompileTimeErrorCode(
    'NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as a default "
        "parameter value.",
    correctionMessage:
        "Try leaving the default as null and initializing the parameter inside "
        "the function body.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode NON_CONSTANT_LIST_ELEMENT =
      CompileTimeErrorCode(
    'NON_CONSTANT_LIST_ELEMENT',
    "The values in a const list literal must be constants.",
    correctionMessage:
        "Try removing the keyword 'const' from the list literal.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY = CompileTimeErrorCode(
    'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as values in a "
        "'const' list literal.",
    correctionMessage:
        "Try removing the keyword 'const' from the list literal or removing "
        "the keyword 'deferred' from the import.",
    hasPublishedDocs: true,
    uniqueName: 'NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY',
  );

  ///  No parameters.
  static const CompileTimeErrorCode NON_CONSTANT_MAP_ELEMENT =
      CompileTimeErrorCode(
    'NON_CONSTANT_MAP_ELEMENT',
    "The elements in a const map literal must be constant.",
    correctionMessage: "Try removing the keyword 'const' from the map literal.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode NON_CONSTANT_MAP_KEY = CompileTimeErrorCode(
    'NON_CONSTANT_MAP_KEY',
    "The keys in a const map literal must be constant.",
    correctionMessage: "Try removing the keyword 'const' from the map literal.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY =
      CompileTimeErrorCode(
    'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as keys in a "
        "'const' map literal.",
    correctionMessage:
        "Try removing the keyword 'const' from the map literal or removing the "
        "keyword 'deferred' from the import.",
    hasPublishedDocs: true,
    uniqueName: 'NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY',
  );

  ///  No parameters.
  static const CompileTimeErrorCode NON_CONSTANT_MAP_VALUE =
      CompileTimeErrorCode(
    'NON_CONSTANT_MAP_VALUE',
    "The values in a const map literal must be constant.",
    correctionMessage: "Try removing the keyword 'const' from the map literal.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY = CompileTimeErrorCode(
    'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as values in a "
        "'const' map literal.",
    correctionMessage:
        "Try removing the keyword 'const' from the map literal or removing the "
        "keyword 'deferred' from the import.",
    hasPublishedDocs: true,
    uniqueName: 'NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY',
  );

  ///  No parameters.
  static const CompileTimeErrorCode NON_CONSTANT_SET_ELEMENT =
      CompileTimeErrorCode(
    'NON_CONSTANT_SET_ELEMENT',
    "The values in a const set literal must be constants.",
    correctionMessage: "Try removing the keyword 'const' from the set literal.",
    hasPublishedDocs: true,
  );

  static const CompileTimeErrorCode NON_CONST_GENERATIVE_ENUM_CONSTRUCTOR =
      CompileTimeErrorCode(
    'NON_CONST_GENERATIVE_ENUM_CONSTRUCTOR',
    "Generative enum constructors must be 'const'.",
    correctionMessage: "Try adding the keyword 'const'.",
    hasPublishedDocs: true,
  );

  ///  13.2 Expression Statements: It is a compile-time error if a non-constant
  ///  map literal that has no explicit type arguments appears in a place where a
  ///  statement is expected.
  static const CompileTimeErrorCode NON_CONST_MAP_AS_EXPRESSION_STATEMENT =
      CompileTimeErrorCode(
    'NON_CONST_MAP_AS_EXPRESSION_STATEMENT',
    "A non-constant map or set literal without type arguments can't be used as "
        "an expression statement.",
  );

  ///  No parameters.
  static const CompileTimeErrorCode NON_FINAL_FIELD_IN_ENUM =
      CompileTimeErrorCode(
    'NON_FINAL_FIELD_IN_ENUM',
    "Enums can only declare final fields.",
    correctionMessage: "Try making the field final.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the non-generative constructor
  static const CompileTimeErrorCode NON_GENERATIVE_CONSTRUCTOR =
      CompileTimeErrorCode(
    'NON_GENERATIVE_CONSTRUCTOR',
    "The generative constructor '{0}' is expected, but a factory was found.",
    correctionMessage:
        "Try calling a different constructor of the superclass, or making the "
        "called constructor not be a factory constructor.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the superclass
  ///  1: the name of the current class
  ///  2: the implicitly called factory constructor of the superclass
  static const CompileTimeErrorCode NON_GENERATIVE_IMPLICIT_CONSTRUCTOR =
      CompileTimeErrorCode(
    'NON_GENERATIVE_IMPLICIT_CONSTRUCTOR',
    "The unnamed constructor of superclass '{0}' (called by the default "
        "constructor of '{1}') must be a generative constructor, but factory "
        "found.",
    correctionMessage:
        "Try adding an explicit constructor that has a different "
        "superinitializer or changing the superclass constructor '{2}' to not "
        "be a factory constructor.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode NON_SYNC_FACTORY = CompileTimeErrorCode(
    'NON_SYNC_FACTORY',
    "Factory bodies can't use 'async', 'async*', or 'sync*'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name appearing where a type is expected
  static const CompileTimeErrorCode NON_TYPE_AS_TYPE_ARGUMENT =
      CompileTimeErrorCode(
    'NON_TYPE_AS_TYPE_ARGUMENT',
    "The name '{0}' isn't a type so it can't be used as a type argument.",
    correctionMessage:
        "Try correcting the name to an existing type, or defining a type named "
        "'{0}'.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
  );

  ///  Parameters:
  ///  0: the name of the non-type element
  static const CompileTimeErrorCode NON_TYPE_IN_CATCH_CLAUSE =
      CompileTimeErrorCode(
    'NON_TYPE_IN_CATCH_CLAUSE',
    "The name '{0}' isn't a type and can't be used in an on-catch clause.",
    correctionMessage: "Try correcting the name to match an existing class.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode NON_VOID_RETURN_FOR_OPERATOR =
      CompileTimeErrorCode(
    'NON_VOID_RETURN_FOR_OPERATOR',
    "The return type of the operator []= must be 'void'.",
    correctionMessage: "Try changing the return type to 'void'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode NON_VOID_RETURN_FOR_SETTER =
      CompileTimeErrorCode(
    'NON_VOID_RETURN_FOR_SETTER',
    "The return type of the setter must be 'void' or absent.",
    correctionMessage:
        "Try removing the return type, or define a method rather than a "
        "setter.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the variable that is invalid
  static const CompileTimeErrorCode
      NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE =
      CompileTimeErrorCode(
    'NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE',
    "The non-nullable local variable '{0}' must be assigned before it can be "
        "used.",
    correctionMessage:
        "Try giving it an initializer expression, or ensure that it's assigned "
        "on every execution path.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name that is not a type
  static const CompileTimeErrorCode NOT_A_TYPE = CompileTimeErrorCode(
    'NOT_A_TYPE',
    "{0} isn't a type.",
    correctionMessage: "Try correcting the name to match an existing type.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the operator that is not a binary operator.
  static const CompileTimeErrorCode NOT_BINARY_OPERATOR = CompileTimeErrorCode(
    'NOT_BINARY_OPERATOR',
    "'{0}' isn't a binary operator.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the expected number of required arguments
  ///  1: the actual number of positional arguments given
  static const CompileTimeErrorCode NOT_ENOUGH_POSITIONAL_ARGUMENTS =
      CompileTimeErrorCode(
    'NOT_ENOUGH_POSITIONAL_ARGUMENTS',
    "{0} positional argument(s) expected, but {1} found.",
    correctionMessage: "Try adding the missing arguments.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the field that is not initialized
  static const CompileTimeErrorCode
      NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD = CompileTimeErrorCode(
    'NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD',
    "Non-nullable instance field '{0}' must be initialized.",
    correctionMessage:
        "Try adding an initializer expression, or a generative constructor "
        "that initializes it, or mark it 'late'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the field that is not initialized
  static const CompileTimeErrorCode
      NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD_CONSTRUCTOR =
      CompileTimeErrorCode(
    'NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD',
    "Non-nullable instance field '{0}' must be initialized.",
    correctionMessage:
        "Try adding an initializer expression, or add a field initializer in "
        "this constructor, or mark it 'late'.",
    hasPublishedDocs: true,
    uniqueName: 'NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD_CONSTRUCTOR',
  );

  ///  Parameters:
  ///  0: the name of the variable that is invalid
  static const CompileTimeErrorCode NOT_INITIALIZED_NON_NULLABLE_VARIABLE =
      CompileTimeErrorCode(
    'NOT_INITIALIZED_NON_NULLABLE_VARIABLE',
    "The non-nullable variable '{0}' must be initialized.",
    correctionMessage: "Try adding an initializer expression.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode NOT_INSTANTIATED_BOUND =
      CompileTimeErrorCode(
    'NOT_INSTANTIATED_BOUND',
    "Type parameter bound types must be instantiated.",
    correctionMessage: "Try adding type arguments to the type parameter bound.",
  );

  ///  No parameters.
  static const CompileTimeErrorCode NOT_ITERABLE_SPREAD = CompileTimeErrorCode(
    'NOT_ITERABLE_SPREAD',
    "Spread elements in list or set literals must implement 'Iterable'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode NOT_MAP_SPREAD = CompileTimeErrorCode(
    'NOT_MAP_SPREAD',
    "Spread elements in map literals must implement 'Map'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode NOT_NULL_AWARE_NULL_SPREAD =
      CompileTimeErrorCode(
    'NOT_NULL_AWARE_NULL_SPREAD',
    "The Null typed expression can't be used with a non-null-aware spread.",
  );

  ///  No parameters.
  static const CompileTimeErrorCode NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS =
      CompileTimeErrorCode(
    'NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS',
    "Annotation creation must have arguments.",
    correctionMessage: "Try adding an empty argument list.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the class where override error was detected
  ///  1: the list of candidate signatures which cannot be combined
  static const CompileTimeErrorCode NO_COMBINED_SUPER_SIGNATURE =
      CompileTimeErrorCode(
    'NO_COMBINED_SUPER_SIGNATURE',
    "Can't infer missing types in '{0}' from overridden methods: {1}.",
    correctionMessage:
        "Try providing explicit types for this method's parameters and return "
        "type.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the superclass that does not define an implicitly invoked
  ///     constructor
  static const CompileTimeErrorCode NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT =
      CompileTimeErrorCode(
    'NO_DEFAULT_SUPER_CONSTRUCTOR',
    "The superclass '{0}' doesn't have a zero argument constructor.",
    correctionMessage:
        "Try declaring a zero argument constructor in '{0}', or explicitly "
        "invoking a different constructor in '{0}'.",
    uniqueName: 'NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT',
  );

  ///  Parameters:
  ///  0: the name of the superclass that does not define an implicitly invoked
  ///     constructor
  ///  1: the name of the subclass that does not contain any explicit constructors
  static const CompileTimeErrorCode NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT =
      CompileTimeErrorCode(
    'NO_DEFAULT_SUPER_CONSTRUCTOR',
    "The superclass '{0}' doesn't have a zero argument constructor.",
    correctionMessage:
        "Try declaring a zero argument constructor in '{0}', or declaring a "
        "constructor in {1} that explicitly invokes a constructor in '{0}'.",
    uniqueName: 'NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT',
  );

  ///  Parameters:
  ///  0: the name of the subclass
  ///  1: the name of the superclass
  static const CompileTimeErrorCode NO_GENERATIVE_CONSTRUCTORS_IN_SUPERCLASS =
      CompileTimeErrorCode(
    'NO_GENERATIVE_CONSTRUCTORS_IN_SUPERCLASS',
    "The class '{0}' can't extend '{1}' because '{1}' only has factory "
        "constructors (no generative constructors), and '{0}' has at least one "
        "generative constructor.",
    correctionMessage:
        "Try implementing the class instead, adding a generative (not factory) "
        "constructor to the superclass '{1}', or a factory constructor to the "
        "subclass.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode NULLABLE_TYPE_IN_EXTENDS_CLAUSE =
      CompileTimeErrorCode(
    'NULLABLE_TYPE_IN_EXTENDS_CLAUSE',
    "A class can't extend a nullable type.",
    correctionMessage: "Try removing the question mark.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE =
      CompileTimeErrorCode(
    'NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE',
    "A class or mixin can't implement a nullable type.",
    correctionMessage: "Try removing the question mark.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode NULLABLE_TYPE_IN_ON_CLAUSE =
      CompileTimeErrorCode(
    'NULLABLE_TYPE_IN_ON_CLAUSE',
    "A mixin can't have a nullable type as a superclass constraint.",
    correctionMessage: "Try removing the question mark.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode NULLABLE_TYPE_IN_WITH_CLAUSE =
      CompileTimeErrorCode(
    'NULLABLE_TYPE_IN_WITH_CLAUSE',
    "A class or mixin can't mix in a nullable type.",
    correctionMessage: "Try removing the question mark.",
    hasPublishedDocs: true,
  );

  ///  7.9 Superclasses: It is a compile-time error to specify an extends clause
  ///  for class Object.
  static const CompileTimeErrorCode OBJECT_CANNOT_EXTEND_ANOTHER_CLASS =
      CompileTimeErrorCode(
    'OBJECT_CANNOT_EXTEND_ANOTHER_CLASS',
    "The class 'Object' can't extend any other class.",
  );

  ///  Parameters:
  ///  0: the name of the interface that is implemented more than once
  static const CompileTimeErrorCode ON_REPEATED = CompileTimeErrorCode(
    'ON_REPEATED',
    "The type '{0}' can be included in the superclass constraints only once.",
    correctionMessage:
        "Try removing all except one occurrence of the type name.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode OPTIONAL_PARAMETER_IN_OPERATOR =
      CompileTimeErrorCode(
    'OPTIONAL_PARAMETER_IN_OPERATOR',
    "Optional parameters aren't allowed when defining an operator.",
    correctionMessage: "Try removing the optional parameters.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of expected library name
  ///  1: the non-matching actual library name from the "part of" declaration
  static const CompileTimeErrorCode PART_OF_DIFFERENT_LIBRARY =
      CompileTimeErrorCode(
    'PART_OF_DIFFERENT_LIBRARY',
    "Expected this library to be part of '{0}', not '{1}'.",
    correctionMessage:
        "Try including a different part, or changing the name of the library "
        "in the part's part-of directive.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the uri pointing to a non-library declaration
  static const CompileTimeErrorCode PART_OF_NON_PART = CompileTimeErrorCode(
    'PART_OF_NON_PART',
    "The included part '{0}' must have a part-of directive.",
    correctionMessage: "Try adding a part-of directive to '{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the URI of the expected library
  ///  1: the non-matching actual library name from the "part of" declaration
  static const CompileTimeErrorCode PART_OF_UNNAMED_LIBRARY =
      CompileTimeErrorCode(
    'PART_OF_UNNAMED_LIBRARY',
    "The library is unnamed. A URI is expected, not a library name '{0}', in "
        "the part-of directive.",
    correctionMessage:
        "Try changing the part-of directive to a URI, or try including a "
        "different part.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      POSITIONAL_SUPER_FORMAL_PARAMETER_WITH_POSITIONAL_ARGUMENT =
      CompileTimeErrorCode(
    'POSITIONAL_SUPER_FORMAL_PARAMETER_WITH_POSITIONAL_ARGUMENT',
    "Positional super parameters can't be used when the super constructor "
        "invocation has a positional argument.",
    correctionMessage:
        "Try making all the positional parameters passed to the super "
        "constructor be either all super parameters or all normal parameters.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the prefix
  static const CompileTimeErrorCode PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER =
      CompileTimeErrorCode(
    'PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER',
    "The name '{0}' is already used as an import prefix and can't be used to "
        "name a top-level element.",
    correctionMessage:
        "Try renaming either the top-level element or the prefix.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the prefix
  static const CompileTimeErrorCode PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT =
      CompileTimeErrorCode(
    'PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT',
    "The name '{0}' refers to an import prefix, so it must be followed by '.'.",
    correctionMessage:
        "Try correcting the name to refer to something other than a prefix, or "
        "renaming the prefix.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the prefix being shadowed
  static const CompileTimeErrorCode PREFIX_SHADOWED_BY_LOCAL_DECLARATION =
      CompileTimeErrorCode(
    'PREFIX_SHADOWED_BY_LOCAL_DECLARATION',
    "The prefix '{0}' can't be used here because it's shadowed by a local "
        "declaration.",
    correctionMessage:
        "Try renaming either the prefix or the local declaration.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the private name that collides
  ///  1: the name of the first mixin
  ///  2: the name of the second mixin
  static const CompileTimeErrorCode PRIVATE_COLLISION_IN_MIXIN_APPLICATION =
      CompileTimeErrorCode(
    'PRIVATE_COLLISION_IN_MIXIN_APPLICATION',
    "The private name '{0}', defined by '{1}', conflicts with the same name "
        "defined by '{2}'.",
    correctionMessage: "Try removing '{1}' from the 'with' clause.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode PRIVATE_OPTIONAL_PARAMETER =
      CompileTimeErrorCode(
    'PRIVATE_OPTIONAL_PARAMETER',
    "Named parameters can't start with an underscore.",
    hasPublishedDocs: true,
  );

  static const CompileTimeErrorCode PRIVATE_SETTER = CompileTimeErrorCode(
    'PRIVATE_SETTER',
    "The setter '{0}' is private and can't be accessed outside the library "
        "that declares it.",
    correctionMessage: "Try making it public.",
    hasPublishedDocs: true,
  );

  static const CompileTimeErrorCode READ_POTENTIALLY_UNASSIGNED_FINAL =
      CompileTimeErrorCode(
    'READ_POTENTIALLY_UNASSIGNED_FINAL',
    "The final variable '{0}' can't be read because it's potentially "
        "unassigned at this point.",
    correctionMessage:
        "Ensure that it is assigned on necessary execution paths.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode RECURSIVE_COMPILE_TIME_CONSTANT =
      CompileTimeErrorCode(
    'RECURSIVE_COMPILE_TIME_CONSTANT',
    "The compile-time constant expression depends on itself.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  ///
  ///  TODO(scheglov) review this later, there are no explicit "it is a
  ///  compile-time error" in specification. But it was added to the co19 and
  ///  there is same error for factories.
  ///
  ///  https://code.google.com/p/dart/issues/detail?id=954
  static const CompileTimeErrorCode RECURSIVE_CONSTRUCTOR_REDIRECT =
      CompileTimeErrorCode(
    'RECURSIVE_CONSTRUCTOR_REDIRECT',
    "Constructors can't redirect to themselves either directly or indirectly.",
    correctionMessage:
        "Try changing one of the constructors in the loop to not redirect.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode RECURSIVE_FACTORY_REDIRECT =
      CompileTimeErrorCode(
    'RECURSIVE_CONSTRUCTOR_REDIRECT',
    "Constructors can't redirect to themselves either directly or indirectly.",
    correctionMessage:
        "Try changing one of the constructors in the loop to not redirect.",
    hasPublishedDocs: true,
    uniqueName: 'RECURSIVE_FACTORY_REDIRECT',
  );

  ///  Parameters:
  ///  0: the name of the class that implements itself recursively
  ///  1: a string representation of the implements loop
  static const CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE =
      CompileTimeErrorCode(
    'RECURSIVE_INTERFACE_INHERITANCE',
    "'{0}' can't be a superinterface of itself: {1}.",
    hasPublishedDocs: true,
  );

  ///  7.10 Superinterfaces: It is a compile-time error if the interface of a
  ///  class <i>C</i> is a superinterface of itself.
  ///
  ///  8.1 Superinterfaces: It is a compile-time error if an interface is a
  ///  superinterface of itself.
  ///
  ///  7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a
  ///  superclass of itself.
  ///
  ///  Parameters:
  ///  0: the name of the class that implements itself recursively
  static const CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE_EXTENDS =
      CompileTimeErrorCode(
    'RECURSIVE_INTERFACE_INHERITANCE',
    "'{0}' can't extend itself.",
    hasPublishedDocs: true,
    uniqueName: 'RECURSIVE_INTERFACE_INHERITANCE_EXTENDS',
  );

  ///  7.10 Superinterfaces: It is a compile-time error if the interface of a
  ///  class <i>C</i> is a superinterface of itself.
  ///
  ///  8.1 Superinterfaces: It is a compile-time error if an interface is a
  ///  superinterface of itself.
  ///
  ///  7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a
  ///  superclass of itself.
  ///
  ///  Parameters:
  ///  0: the name of the class that implements itself recursively
  static const CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS =
      CompileTimeErrorCode(
    'RECURSIVE_INTERFACE_INHERITANCE',
    "'{0}' can't implement itself.",
    hasPublishedDocs: true,
    uniqueName: 'RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS',
  );

  ///  Parameters:
  ///  0: the name of the mixin that constraints itself recursively
  static const CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE_ON =
      CompileTimeErrorCode(
    'RECURSIVE_INTERFACE_INHERITANCE',
    "'{0}' can't use itself as a superclass constraint.",
    hasPublishedDocs: true,
    uniqueName: 'RECURSIVE_INTERFACE_INHERITANCE_ON',
  );

  ///  7.10 Superinterfaces: It is a compile-time error if the interface of a
  ///  class <i>C</i> is a superinterface of itself.
  ///
  ///  8.1 Superinterfaces: It is a compile-time error if an interface is a
  ///  superinterface of itself.
  ///
  ///  7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a
  ///  superclass of itself.
  ///
  ///  Parameters:
  ///  0: the name of the class that implements itself recursively
  static const CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE_WITH =
      CompileTimeErrorCode(
    'RECURSIVE_INTERFACE_INHERITANCE',
    "'{0}' can't use itself as a mixin.",
    hasPublishedDocs: true,
    uniqueName: 'RECURSIVE_INTERFACE_INHERITANCE_WITH',
  );

  ///  No parameters.
  static const CompileTimeErrorCode REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR =
      CompileTimeErrorCode(
    'REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR',
    "The constructor '{0}' couldn't be found in '{1}'.",
    correctionMessage:
        "Try redirecting to a different constructor, or defining the "
        "constructor named '{0}'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR = CompileTimeErrorCode(
    'REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR',
    "Generative constructors can't redirect to a factory constructor.",
    correctionMessage: "Try redirecting to a different constructor.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the redirecting constructor
  ///  1: the name of the abstract class defining the constructor being redirected to
  static const CompileTimeErrorCode REDIRECT_TO_ABSTRACT_CLASS_CONSTRUCTOR =
      CompileTimeErrorCode(
    'REDIRECT_TO_ABSTRACT_CLASS_CONSTRUCTOR',
    "The redirecting constructor '{0}' can't redirect to a constructor of the "
        "abstract class '{1}'.",
    correctionMessage: "Try redirecting to a constructor of a different class.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the redirected constructor
  ///  1: the name of the redirecting constructor
  static const CompileTimeErrorCode REDIRECT_TO_INVALID_FUNCTION_TYPE =
      CompileTimeErrorCode(
    'REDIRECT_TO_INVALID_FUNCTION_TYPE',
    "The redirected constructor '{0}' has incompatible parameters with '{1}'.",
    correctionMessage: "Try redirecting to a different constructor.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the redirected constructor's return type
  ///  1: the name of the redirecting constructor's return type
  static const CompileTimeErrorCode REDIRECT_TO_INVALID_RETURN_TYPE =
      CompileTimeErrorCode(
    'REDIRECT_TO_INVALID_RETURN_TYPE',
    "The return type '{0}' of the redirected constructor isn't a subtype of "
        "'{1}'.",
    correctionMessage: "Try redirecting to a different constructor.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the constructor
  ///  1: the name of the class containing the constructor
  static const CompileTimeErrorCode REDIRECT_TO_MISSING_CONSTRUCTOR =
      CompileTimeErrorCode(
    'REDIRECT_TO_MISSING_CONSTRUCTOR',
    "The constructor '{0}' couldn't be found in '{1}'.",
    correctionMessage:
        "Try redirecting to a different constructor, or define the constructor "
        "named '{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the non-type referenced in the redirect
  static const CompileTimeErrorCode REDIRECT_TO_NON_CLASS =
      CompileTimeErrorCode(
    'REDIRECT_TO_NON_CLASS',
    "The name '{0}' isn't a type and can't be used in a redirected "
        "constructor.",
    correctionMessage: "Try redirecting to a different constructor.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode REDIRECT_TO_NON_CONST_CONSTRUCTOR =
      CompileTimeErrorCode(
    'REDIRECT_TO_NON_CONST_CONSTRUCTOR',
    "A constant redirecting constructor can't redirect to a non-constant "
        "constructor.",
    correctionMessage: "Try redirecting to a different constructor.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      REDIRECT_TO_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER = CompileTimeErrorCode(
    'REDIRECT_TO_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    "A redirecting constructor can't redirect to a type alias that expands to "
        "a type parameter.",
    correctionMessage: "Try replacing it with a class.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode REFERENCED_BEFORE_DECLARATION =
      CompileTimeErrorCode(
    'REFERENCED_BEFORE_DECLARATION',
    "Local variable '{0}' can't be referenced before it is declared.",
    correctionMessage:
        "Try moving the declaration to before the first use, or renaming the "
        "local variable so that it doesn't hide a name from an enclosing "
        "scope.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode RETHROW_OUTSIDE_CATCH =
      CompileTimeErrorCode(
    'RETHROW_OUTSIDE_CATCH',
    "A rethrow must be inside of a catch clause.",
    correctionMessage:
        "Try moving the expression into a catch clause, or using a 'throw' "
        "expression.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode RETURN_IN_GENERATIVE_CONSTRUCTOR =
      CompileTimeErrorCode(
    'RETURN_IN_GENERATIVE_CONSTRUCTOR',
    "Constructors can't return values.",
    correctionMessage:
        "Try removing the return statement or using a factory constructor.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode RETURN_IN_GENERATOR = CompileTimeErrorCode(
    'RETURN_IN_GENERATOR',
    "Can't return a value from a generator function that uses the 'async*' or "
        "'sync*' modifier.",
    correctionMessage:
        "Try replacing 'return' with 'yield', using a block function body, or "
        "changing the method body modifier.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the return type as declared in the return statement
  ///  1: the expected return type as defined by the method
  static const CompileTimeErrorCode RETURN_OF_INVALID_TYPE_FROM_CLOSURE =
      CompileTimeErrorCode(
    'RETURN_OF_INVALID_TYPE_FROM_CLOSURE',
    "The return type '{0}' isn't a '{1}', as required by the closure's "
        "context.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the return type as declared in the return statement
  ///  1: the expected return type as defined by the enclosing class
  ///  2: the name of the constructor
  static const CompileTimeErrorCode RETURN_OF_INVALID_TYPE_FROM_CONSTRUCTOR =
      CompileTimeErrorCode(
    'RETURN_OF_INVALID_TYPE',
    "A value of type '{0}' can't be returned from the constructor '{2}' "
        "because it has a return type of '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'RETURN_OF_INVALID_TYPE_FROM_CONSTRUCTOR',
  );

  ///  Parameters:
  ///  0: the return type as declared in the return statement
  ///  1: the expected return type as defined by the method
  ///  2: the name of the method
  static const CompileTimeErrorCode RETURN_OF_INVALID_TYPE_FROM_FUNCTION =
      CompileTimeErrorCode(
    'RETURN_OF_INVALID_TYPE',
    "A value of type '{0}' can't be returned from the function '{2}' because "
        "it has a return type of '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'RETURN_OF_INVALID_TYPE_FROM_FUNCTION',
  );

  ///  Parameters:
  ///  0: the return type as declared in the return statement
  ///  1: the expected return type as defined by the method
  ///  2: the name of the method
  static const CompileTimeErrorCode RETURN_OF_INVALID_TYPE_FROM_METHOD =
      CompileTimeErrorCode(
    'RETURN_OF_INVALID_TYPE',
    "A value of type '{0}' can't be returned from the method '{2}' because it "
        "has a return type of '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'RETURN_OF_INVALID_TYPE_FROM_METHOD',
  );

  ///  No parameters.
  static const CompileTimeErrorCode RETURN_WITHOUT_VALUE = CompileTimeErrorCode(
    'RETURN_WITHOUT_VALUE',
    "The return value is missing after 'return'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode SET_ELEMENT_FROM_DEFERRED_LIBRARY =
      CompileTimeErrorCode(
    'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as values in a "
        "'const' set literal.",
    correctionMessage:
        "Try removing the keyword 'const' from the set literal or removing the "
        "keyword 'deferred' from the import.",
    hasPublishedDocs: true,
    uniqueName: 'SET_ELEMENT_FROM_DEFERRED_LIBRARY',
  );

  ///  Parameters:
  ///  0: the actual type of the set element
  ///  1: the expected type of the set element
  static const CompileTimeErrorCode SET_ELEMENT_TYPE_NOT_ASSIGNABLE =
      CompileTimeErrorCode(
    'SET_ELEMENT_TYPE_NOT_ASSIGNABLE',
    "The element type '{0}' can't be assigned to the set type '{1}'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
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
    "Constant values from a deferred library can't be spread into a const "
        "literal.",
    correctionMessage: "Try making the deferred import non-deferred.",
  );

  ///  Parameters:
  ///  0: the name of the instance member
  static const CompileTimeErrorCode STATIC_ACCESS_TO_INSTANCE_MEMBER =
      CompileTimeErrorCode(
    'STATIC_ACCESS_TO_INSTANCE_MEMBER',
    "Instance member '{0}' can't be accessed using static access.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the type of super-parameter
  ///  1: the type of associated super-constructor parameter
  static const CompileTimeErrorCode
      SUPER_FORMAL_PARAMETER_TYPE_IS_NOT_SUBTYPE_OF_ASSOCIATED =
      CompileTimeErrorCode(
    'SUPER_FORMAL_PARAMETER_TYPE_IS_NOT_SUBTYPE_OF_ASSOCIATED',
    "The type '{0}' of this parameter isn't a subtype of the type '{1}' of the "
        "associated super constructor parameter.",
    correctionMessage:
        "Try removing the explicit type annotation from the parameter.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_NAMED = CompileTimeErrorCode(
    'SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_NAMED',
    "No associated named super constructor parameter.",
    correctionMessage:
        "Try changing the name to the name of an existing named super "
        "constructor parameter, or creating such named parameter.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_POSITIONAL =
      CompileTimeErrorCode(
    'SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_POSITIONAL',
    "No associated positional super constructor parameter.",
    correctionMessage:
        "Try using a normal parameter, or adding more positional parameters to "
        "the super constructor.",
    hasPublishedDocs: true,
  );

  ///  7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It
  ///  is a compile-time error if a generative constructor of class Object
  ///  includes a superinitializer.
  static const CompileTimeErrorCode SUPER_INITIALIZER_IN_OBJECT =
      CompileTimeErrorCode(
    'SUPER_INITIALIZER_IN_OBJECT',
    "The class 'Object' can't invoke a constructor from a superclass.",
  );

  ///  Parameters:
  ///  0: the superinitializer
  static const CompileTimeErrorCode SUPER_INVOCATION_NOT_LAST =
      CompileTimeErrorCode(
    'SUPER_INVOCATION_NOT_LAST',
    "The superconstructor call must be last in an initializer list: '{0}'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode SUPER_IN_ENUM_CONSTRUCTOR =
      CompileTimeErrorCode(
    'SUPER_IN_ENUM_CONSTRUCTOR',
    "The enum constructor can't have a 'super' initializer.",
    correctionMessage: "Try removing the 'super' invocation.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode SUPER_IN_EXTENSION = CompileTimeErrorCode(
    'SUPER_IN_EXTENSION',
    "The 'super' keyword can't be used in an extension because an extension "
        "doesn't have a superclass.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode SUPER_IN_INVALID_CONTEXT =
      CompileTimeErrorCode(
    'SUPER_IN_INVALID_CONTEXT',
    "Invalid context for 'super' invocation.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode SUPER_IN_REDIRECTING_CONSTRUCTOR =
      CompileTimeErrorCode(
    'SUPER_IN_REDIRECTING_CONSTRUCTOR',
    "The redirecting constructor can't have a 'super' initializer.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode SWITCH_CASE_COMPLETES_NORMALLY =
      CompileTimeErrorCode(
    'SWITCH_CASE_COMPLETES_NORMALLY',
    "The 'case' shouldn't complete normally.",
    correctionMessage: "Try adding 'break', 'return', or 'throw'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the static type of the switch expression
  ///  1: the static type of the case expressions
  static const CompileTimeErrorCode SWITCH_EXPRESSION_NOT_ASSIGNABLE =
      CompileTimeErrorCode(
    'SWITCH_EXPRESSION_NOT_ASSIGNABLE',
    "Type '{0}' of the switch expression isn't assignable to the type '{1}' of "
        "case expressions.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode
      TEAROFF_OF_GENERATIVE_CONSTRUCTOR_OF_ABSTRACT_CLASS =
      CompileTimeErrorCode(
    'TEAROFF_OF_GENERATIVE_CONSTRUCTOR_OF_ABSTRACT_CLASS',
    "A generative constructor of an abstract class can't be torn off.",
    correctionMessage:
        "Try tearing off a constructor of a concrete class, or a "
        "non-generative constructor.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the type that can't be thrown
  static const CompileTimeErrorCode THROW_OF_INVALID_TYPE =
      CompileTimeErrorCode(
    'THROW_OF_INVALID_TYPE',
    "The type '{0}' of the thrown expression must be assignable to 'Object'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the element whose type could not be inferred.
  ///  1: The [TopLevelInferenceError]'s arguments that led to the cycle.
  static const CompileTimeErrorCode TOP_LEVEL_CYCLE = CompileTimeErrorCode(
    'TOP_LEVEL_CYCLE',
    "The type of '{0}' can't be inferred because it depends on itself through "
        "the cycle: {1}.",
    correctionMessage:
        "Try adding an explicit type to one or more of the variables in the "
        "cycle in order to break the cycle.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode TYPE_ALIAS_CANNOT_REFERENCE_ITSELF =
      CompileTimeErrorCode(
    'TYPE_ALIAS_CANNOT_REFERENCE_ITSELF',
    "Typedefs can't reference themselves directly or recursively via another "
        "typedef.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the type that is deferred and being used in a type
  ///     annotation
  static const CompileTimeErrorCode TYPE_ANNOTATION_DEFERRED_CLASS =
      CompileTimeErrorCode(
    'TYPE_ANNOTATION_DEFERRED_CLASS',
    "The deferred type '{0}' can't be used in a declaration, cast, or type "
        "test.",
    correctionMessage:
        "Try using a different type, or changing the import to not be "
        "deferred.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the type used in the instance creation that should be
  ///     limited by the bound as specified in the class declaration
  ///  1: the name of the type parameter
  ///  2: the substituted bound of the type parameter
  static const CompileTimeErrorCode TYPE_ARGUMENT_NOT_MATCHING_BOUNDS =
      CompileTimeErrorCode(
    'TYPE_ARGUMENT_NOT_MATCHING_BOUNDS',
    "'{0}' doesn't conform to the bound '{2}' of the type parameter '{1}'.",
    correctionMessage: "Try using a type that is or is a subclass of '{2}'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode TYPE_PARAMETER_REFERENCED_BY_STATIC =
      CompileTimeErrorCode(
    'TYPE_PARAMETER_REFERENCED_BY_STATIC',
    "Static members can't reference type parameters of the class.",
    correctionMessage:
        "Try removing the reference to the type parameter, or making the "
        "member an instance member.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the type parameter
  ///  1: the name of the bounding type
  ///
  ///  See [CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS].
  static const CompileTimeErrorCode TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND =
      CompileTimeErrorCode(
    'TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND',
    "'{0}' can't be a supertype of its upper bound.",
    correctionMessage:
        "Try using a type that is the same as or a subclass of '{1}'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode TYPE_TEST_WITH_NON_TYPE =
      CompileTimeErrorCode(
    'TYPE_TEST_WITH_NON_TYPE',
    "The name '{0}' isn't a type and can't be used in an 'is' expression.",
    correctionMessage: "Try correcting the name to match an existing type.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode TYPE_TEST_WITH_UNDEFINED_NAME =
      CompileTimeErrorCode(
    'TYPE_TEST_WITH_UNDEFINED_NAME',
    "The name '{0}' isn't defined, so it can't be used in an 'is' expression.",
    correctionMessage:
        "Try changing the name to the name of an existing type, or creating a "
        "type with the name '{0}'.",
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
    "The method '{0}' can't be unconditionally invoked because the receiver "
        "can be 'null'.",
    correctionMessage:
        "Try making the call conditional (using '?.') or adding a null check "
        "to the target ('!').",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE',
  );

  static const CompileTimeErrorCode
      UNCHECKED_OPERATOR_INVOCATION_OF_NULLABLE_VALUE = CompileTimeErrorCode(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "The operator '{0}' can't be unconditionally invoked because the receiver "
        "can be 'null'.",
    correctionMessage: "Try adding a null check to the target ('!').",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_OPERATOR_INVOCATION_OF_NULLABLE_VALUE',
  );

  static const CompileTimeErrorCode
      UNCHECKED_PROPERTY_ACCESS_OF_NULLABLE_VALUE = CompileTimeErrorCode(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "The property '{0}' can't be unconditionally accessed because the receiver "
        "can be 'null'.",
    correctionMessage:
        "Try making the access conditional (using '?.') or adding a null check "
        "to the target ('!').",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_PROPERTY_ACCESS_OF_NULLABLE_VALUE',
  );

  static const CompileTimeErrorCode
      UNCHECKED_USE_OF_NULLABLE_VALUE_AS_CONDITION = CompileTimeErrorCode(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "A nullable expression can't be used as a condition.",
    correctionMessage:
        "Try checking that the value isn't 'null' before using it as a "
        "condition.",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_USE_OF_NULLABLE_VALUE_AS_CONDITION',
  );

  static const CompileTimeErrorCode
      UNCHECKED_USE_OF_NULLABLE_VALUE_AS_ITERATOR = CompileTimeErrorCode(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "A nullable expression can't be used as an iterator in a for-in loop.",
    correctionMessage:
        "Try checking that the value isn't 'null' before using it as an "
        "iterator.",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_USE_OF_NULLABLE_VALUE_AS_ITERATOR',
  );

  static const CompileTimeErrorCode UNCHECKED_USE_OF_NULLABLE_VALUE_IN_SPREAD =
      CompileTimeErrorCode(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "A nullable expression can't be used in a spread.",
    correctionMessage:
        "Try checking that the value isn't 'null' before using it in a spread, "
        "or use a null-aware spread.",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_USE_OF_NULLABLE_VALUE_IN_SPREAD',
  );

  static const CompileTimeErrorCode
      UNCHECKED_USE_OF_NULLABLE_VALUE_IN_YIELD_EACH = CompileTimeErrorCode(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "A nullable expression can't be used in a yield-each statement.",
    correctionMessage:
        "Try checking that the value isn't 'null' before using it in a "
        "yield-each statement.",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_USE_OF_NULLABLE_VALUE_IN_YIELD_EACH',
  );

  ///  No parameters.
  static const CompileTimeErrorCode UNDEFINED_ANNOTATION = CompileTimeErrorCode(
    'UNDEFINED_ANNOTATION',
    "Undefined name '{0}' used as an annotation.",
    correctionMessage:
        "Try defining the name or importing it from another library.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
  );

  ///  Parameters:
  ///  0: the name of the undefined class
  static const CompileTimeErrorCode UNDEFINED_CLASS = CompileTimeErrorCode(
    'UNDEFINED_CLASS',
    "Undefined class '{0}'.",
    correctionMessage:
        "Try changing the name to the name of an existing class, or creating a "
        "class with the name '{0}'.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
  );

  ///  Same as [CompileTimeErrorCode.UNDEFINED_CLASS], but to catch using
  ///  "boolean" instead of "bool" in order to improve the correction message.
  ///
  ///  Parameters:
  ///  0: the name of the undefined class
  static const CompileTimeErrorCode UNDEFINED_CLASS_BOOLEAN =
      CompileTimeErrorCode(
    'UNDEFINED_CLASS',
    "Undefined class '{0}'.",
    correctionMessage: "Try using the type 'bool'.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
    uniqueName: 'UNDEFINED_CLASS_BOOLEAN',
  );

  ///  Parameters:
  ///  0: the name of the superclass that does not define the invoked constructor
  ///  1: the name of the constructor being invoked
  static const CompileTimeErrorCode UNDEFINED_CONSTRUCTOR_IN_INITIALIZER =
      CompileTimeErrorCode(
    'UNDEFINED_CONSTRUCTOR_IN_INITIALIZER',
    "The class '{0}' doesn't have a constructor named '{1}'.",
    correctionMessage:
        "Try defining a constructor named '{1}' in '{0}', or invoking a "
        "different constructor.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the superclass that does not define the invoked constructor
  static const CompileTimeErrorCode
      UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT = CompileTimeErrorCode(
    'UNDEFINED_CONSTRUCTOR_IN_INITIALIZER',
    "The class '{0}' doesn't have an unnamed constructor.",
    correctionMessage:
        "Try defining an unnamed constructor in '{0}', or invoking a different "
        "constructor.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT',
  );

  ///  Parameters:
  ///  0: the name of the enum constant that is not defined
  ///  1: the name of the enum used to access the constant
  static const CompileTimeErrorCode UNDEFINED_ENUM_CONSTANT =
      CompileTimeErrorCode(
    'UNDEFINED_ENUM_CONSTANT',
    "There's no constant named '{0}' in '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing constant, or "
        "defining a constant named '{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the constructor that is undefined
  static const CompileTimeErrorCode UNDEFINED_ENUM_CONSTRUCTOR_NAMED =
      CompileTimeErrorCode(
    'UNDEFINED_ENUM_CONSTRUCTOR',
    "The enum doesn't have a constructor named '{0}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing constructor, or "
        "defining constructor with the name '{0}'.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_ENUM_CONSTRUCTOR_NAMED',
  );

  static const CompileTimeErrorCode UNDEFINED_ENUM_CONSTRUCTOR_UNNAMED =
      CompileTimeErrorCode(
    'UNDEFINED_ENUM_CONSTRUCTOR',
    "The enum doesn't have an unnamed constructor.",
    correctionMessage:
        "Try adding the name of an existing constructor, or defining an "
        "unnamed constructor.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_ENUM_CONSTRUCTOR_UNNAMED',
  );

  ///  Parameters:
  ///  0: the name of the getter that is undefined
  ///  1: the name of the extension that was explicitly specified
  static const CompileTimeErrorCode UNDEFINED_EXTENSION_GETTER =
      CompileTimeErrorCode(
    'UNDEFINED_EXTENSION_GETTER',
    "The getter '{0}' isn't defined for the extension '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing getter, or "
        "defining a getter named '{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the method that is undefined
  ///  1: the name of the extension that was explicitly specified
  static const CompileTimeErrorCode UNDEFINED_EXTENSION_METHOD =
      CompileTimeErrorCode(
    'UNDEFINED_EXTENSION_METHOD',
    "The method '{0}' isn't defined for the extension '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing method, or "
        "defining a method named '{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the operator that is undefined
  ///  1: the name of the extension that was explicitly specified
  static const CompileTimeErrorCode UNDEFINED_EXTENSION_OPERATOR =
      CompileTimeErrorCode(
    'UNDEFINED_EXTENSION_OPERATOR',
    "The operator '{0}' isn't defined for the extension '{1}'.",
    correctionMessage: "Try defining the operator '{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the setter that is undefined
  ///  1: the name of the extension that was explicitly specified
  static const CompileTimeErrorCode UNDEFINED_EXTENSION_SETTER =
      CompileTimeErrorCode(
    'UNDEFINED_EXTENSION_SETTER',
    "The setter '{0}' isn't defined for the extension '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing setter, or "
        "defining a setter named '{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the method that is undefined
  static const CompileTimeErrorCode UNDEFINED_FUNCTION = CompileTimeErrorCode(
    'UNDEFINED_FUNCTION',
    "The function '{0}' isn't defined.",
    correctionMessage:
        "Try importing the library that defines '{0}', correcting the name to "
        "the name of an existing function, or defining a function named '{0}'.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
  );

  ///  Parameters:
  ///  0: the name of the getter
  ///  1: the name of the enclosing type where the getter is being looked for
  static const CompileTimeErrorCode UNDEFINED_GETTER = CompileTimeErrorCode(
    'UNDEFINED_GETTER',
    "The getter '{0}' isn't defined for the type '{1}'.",
    correctionMessage:
        "Try importing the library that defines '{0}', correcting the name to "
        "the name of an existing getter, or defining a getter or field named "
        "'{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the getter
  ///  1: the name of the function type alias
  static const CompileTimeErrorCode UNDEFINED_GETTER_ON_FUNCTION_TYPE =
      CompileTimeErrorCode(
    'UNDEFINED_GETTER',
    "The getter '{0}' isn't defined for the '{1}' function type.",
    correctionMessage:
        "Try wrapping the function type alias in parentheses in order to "
        "access '{0}' as an extension getter on 'Type'.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_GETTER_ON_FUNCTION_TYPE',
  );

  ///  Parameters:
  ///  0: the name of the identifier
  static const CompileTimeErrorCode UNDEFINED_IDENTIFIER = CompileTimeErrorCode(
    'UNDEFINED_IDENTIFIER',
    "Undefined name '{0}'.",
    correctionMessage:
        "Try correcting the name to one that is defined, or defining the name.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode UNDEFINED_IDENTIFIER_AWAIT =
      CompileTimeErrorCode(
    'UNDEFINED_IDENTIFIER_AWAIT',
    "Undefined name 'await' in function body not marked with 'async'.",
    correctionMessage:
        "Try correcting the name to one that is defined, defining the name, or "
        "adding 'async' to the enclosing function body.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the method that is undefined
  ///  1: the resolved type name that the method lookup is happening on
  static const CompileTimeErrorCode UNDEFINED_METHOD = CompileTimeErrorCode(
    'UNDEFINED_METHOD',
    "The method '{0}' isn't defined for the type '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing method, or "
        "defining a method named '{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the method
  ///  1: the name of the function type alias
  static const CompileTimeErrorCode UNDEFINED_METHOD_ON_FUNCTION_TYPE =
      CompileTimeErrorCode(
    'UNDEFINED_METHOD',
    "The method '{0}' isn't defined for the '{1}' function type.",
    correctionMessage:
        "Try wrapping the function type alias in parentheses in order to "
        "access '{0}' as an extension method on 'Type'.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_METHOD_ON_FUNCTION_TYPE',
  );

  ///  Parameters:
  ///  0: the name of the requested named parameter
  static const CompileTimeErrorCode UNDEFINED_NAMED_PARAMETER =
      CompileTimeErrorCode(
    'UNDEFINED_NAMED_PARAMETER',
    "The named parameter '{0}' isn't defined.",
    correctionMessage:
        "Try correcting the name to an existing named parameter's name, or "
        "defining a named parameter with the name '{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the operator
  ///  1: the name of the enclosing type where the operator is being looked for
  static const CompileTimeErrorCode UNDEFINED_OPERATOR = CompileTimeErrorCode(
    'UNDEFINED_OPERATOR',
    "The operator '{0}' isn't defined for the type '{1}'.",
    correctionMessage: "Try defining the operator '{0}'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode UNDEFINED_PREFIXED_NAME =
      CompileTimeErrorCode(
    'UNDEFINED_PREFIXED_NAME',
    "The name '{0}' is being referenced through the prefix '{1}', but it isn't "
        "defined in any of the libraries imported using that prefix.",
    correctionMessage:
        "Try correcting the prefix or importing the library that defines "
        "'{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the setter
  ///  1: the name of the enclosing type where the setter is being looked for
  static const CompileTimeErrorCode UNDEFINED_SETTER = CompileTimeErrorCode(
    'UNDEFINED_SETTER',
    "The setter '{0}' isn't defined for the type '{1}'.",
    correctionMessage:
        "Try importing the library that defines '{0}', correcting the name to "
        "the name of an existing setter, or defining a setter or field named "
        "'{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the setter
  ///  1: the name of the function type alias
  static const CompileTimeErrorCode UNDEFINED_SETTER_ON_FUNCTION_TYPE =
      CompileTimeErrorCode(
    'UNDEFINED_SETTER',
    "The setter '{0}' isn't defined for the '{1}' function type.",
    correctionMessage:
        "Try wrapping the function type alias in parentheses in order to "
        "access '{0}' as an extension getter on 'Type'.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_SETTER_ON_FUNCTION_TYPE',
  );

  ///  Parameters:
  ///  0: the name of the getter
  ///  1: the name of the enclosing type where the getter is being looked for
  static const CompileTimeErrorCode UNDEFINED_SUPER_GETTER =
      CompileTimeErrorCode(
    'UNDEFINED_SUPER_MEMBER',
    "The getter '{0}' isn't defined in a superclass of '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing getter, or "
        "defining a getter or field named '{0}' in a superclass.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_SUPER_GETTER',
  );

  ///  Parameters:
  ///  0: the name of the method that is undefined
  ///  1: the resolved type name that the method lookup is happening on
  static const CompileTimeErrorCode UNDEFINED_SUPER_METHOD =
      CompileTimeErrorCode(
    'UNDEFINED_SUPER_MEMBER',
    "The method '{0}' isn't defined in a superclass of '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing method, or "
        "defining a method named '{0}' in a superclass.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_SUPER_METHOD',
  );

  ///  Parameters:
  ///  0: the name of the operator
  ///  1: the name of the enclosing type where the operator is being looked for
  static const CompileTimeErrorCode UNDEFINED_SUPER_OPERATOR =
      CompileTimeErrorCode(
    'UNDEFINED_SUPER_MEMBER',
    "The operator '{0}' isn't defined in a superclass of '{1}'.",
    correctionMessage: "Try defining the operator '{0}' in a superclass.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_SUPER_OPERATOR',
  );

  ///  Parameters:
  ///  0: the name of the setter
  ///  1: the name of the enclosing type where the setter is being looked for
  static const CompileTimeErrorCode UNDEFINED_SUPER_SETTER =
      CompileTimeErrorCode(
    'UNDEFINED_SUPER_MEMBER',
    "The setter '{0}' isn't defined in a superclass of '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing setter, or "
        "defining a setter or field named '{0}' in a superclass.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_SUPER_SETTER',
  );

  ///  This is a specialization of [INSTANCE_ACCESS_TO_STATIC_MEMBER] that is used
  ///  when we are able to find the name defined in a supertype. It exists to
  ///  provide a more informative error message.
  ///
  ///  Parameters:
  ///  0: the name of the defining type
  static const CompileTimeErrorCode
      UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER = CompileTimeErrorCode(
    'UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER',
    "Static members from supertypes must be qualified by the name of the "
        "defining type.",
    correctionMessage: "Try adding '{0}.' before the name.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the defining type
  static const CompileTimeErrorCode
      UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE =
      CompileTimeErrorCode(
    'UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE',
    "Static members from the extended type or one of its superclasses must be "
        "qualified by the name of the defining type.",
    correctionMessage: "Try adding '{0}.' before the name.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the URI pointing to a non-existent file
  static const CompileTimeErrorCode URI_DOES_NOT_EXIST = CompileTimeErrorCode(
    'URI_DOES_NOT_EXIST',
    "Target of URI doesn't exist: '{0}'.",
    correctionMessage:
        "Try creating the file referenced by the URI, or Try using a URI for a "
        "file that does exist.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the URI pointing to a non-existent file
  static const CompileTimeErrorCode URI_HAS_NOT_BEEN_GENERATED =
      CompileTimeErrorCode(
    'URI_HAS_NOT_BEEN_GENERATED',
    "Target of URI hasn't been generated: '{0}'.",
    correctionMessage:
        "Try running the generator that will generate the file referenced by "
        "the URI.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode URI_WITH_INTERPOLATION =
      CompileTimeErrorCode(
    'URI_WITH_INTERPOLATION',
    "URIs can't use string interpolation.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode USE_OF_NATIVE_EXTENSION =
      CompileTimeErrorCode(
    'USE_OF_NATIVE_EXTENSION',
    "Dart native extensions are deprecated and aren’t available in Dart 2.15.",
    correctionMessage: "Try using dart:ffi for C interop.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const CompileTimeErrorCode USE_OF_VOID_RESULT = CompileTimeErrorCode(
    'USE_OF_VOID_RESULT',
    "This expression has a type of 'void' so its value can't be used.",
    correctionMessage:
        "Try checking to see if you're using the correct API; there might be a "
        "function or call that returns void you didn't expect. Also check type "
        "parameters and variables which might also be void.",
    hasPublishedDocs: true,
  );

  static const CompileTimeErrorCode VALUES_DECLARATION_IN_ENUM =
      CompileTimeErrorCode(
    'VALUES_DECLARATION_IN_ENUM',
    "A member named 'values' can't be declared in an enum.",
    correctionMessage: "Try using a different name.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the type of the object being assigned.
  ///  1: the type of the variable being assigned to
  static const CompileTimeErrorCode VARIABLE_TYPE_MISMATCH =
      CompileTimeErrorCode(
    'VARIABLE_TYPE_MISMATCH',
    "A value of type '{0}' can't be assigned to a const variable of type "
        "'{1}'.",
    correctionMessage: "Try using a subtype, or removing the 'const' keyword",
    hasPublishedDocs: true,
  );

  ///  Let `C` be a generic class that declares a formal type parameter `X`, and
  ///  assume that `T` is a direct superinterface of `C`.
  ///
  ///  It is a compile-time error if `X` is explicitly defined as a covariant or
  ///  'in' type parameter and `X` occurs in a non-covariant position in `T`.
  ///  It is a compile-time error if `X` is explicitly defined as a contravariant
  ///  or 'out' type parameter and `X` occurs in a non-contravariant position in
  ///  `T`.
  ///
  ///  Parameters:
  ///  0: the name of the type parameter
  ///  1: the variance modifier defined for {0}
  ///  2: the variance position of the type parameter {0} in the
  ///     superinterface {3}
  ///  3: the name of the superinterface
  static const CompileTimeErrorCode
      WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE =
      CompileTimeErrorCode(
    'WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE',
    "'{0}' is an '{1}' type parameter and can't be used in an '{2}' position "
        "in '{3}'.",
    correctionMessage:
        "Try using 'in' type parameters in 'in' positions and 'out' type "
        "parameters in 'out' positions in the superinterface.",
  );

  ///  Parameters:
  ///  0: the name of the declared operator
  ///  1: the number of parameters expected
  ///  2: the number of parameters found in the operator declaration
  static const CompileTimeErrorCode WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR =
      CompileTimeErrorCode(
    'WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR',
    "Operator '{0}' should declare exactly {1} parameters, but {2} found.",
    hasPublishedDocs: true,
  );

  ///  7.1.1 Operators: It is a compile time error if the arity of the
  ///  user-declared operator - is not 0 or 1.
  ///
  ///  Parameters:
  ///  0: the number of parameters found in the operator declaration
  static const CompileTimeErrorCode
      WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS = CompileTimeErrorCode(
    'WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR',
    "Operator '-' should declare 0 or 1 parameter, but {0} found.",
    hasPublishedDocs: true,
    uniqueName: 'WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS',
  );

  ///  No parameters.
  static const CompileTimeErrorCode WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER =
      CompileTimeErrorCode(
    'WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER',
    "Setters must declare exactly one required positional parameter.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the type being referenced (<i>G</i>)
  ///  1: the number of type parameters that were declared
  ///  2: the number of type arguments provided
  static const CompileTimeErrorCode WRONG_NUMBER_OF_TYPE_ARGUMENTS =
      CompileTimeErrorCode(
    'WRONG_NUMBER_OF_TYPE_ARGUMENTS',
    "The type '{0}' is declared with {1} type parameters, but {2} type "
        "arguments were given.",
    correctionMessage:
        "Try adjusting the number of type arguments to match the number of "
        "type parameters.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the number of type parameters that were declared
  ///  1: the number of type arguments provided
  static const CompileTimeErrorCode
      WRONG_NUMBER_OF_TYPE_ARGUMENTS_ANONYMOUS_FUNCTION = CompileTimeErrorCode(
    'WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION',
    "This function is declared with {0} type parameters, but {1} type "
        "arguments were given.",
    correctionMessage:
        "Try adjusting the number of type arguments to match the number of "
        "type parameters.",
    uniqueName: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS_ANONYMOUS_FUNCTION',
  );

  ///  Parameters:
  ///  0: the name of the class being instantiated
  ///  1: the name of the constructor being invoked
  static const CompileTimeErrorCode WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR =
      CompileTimeErrorCode(
    'WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR',
    "The constructor '{0}.{1}' doesn't have type parameters.",
    correctionMessage: "Try moving type arguments to after the type name.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the number of type parameters that were declared
  ///  1: the number of type arguments provided
  static const CompileTimeErrorCode WRONG_NUMBER_OF_TYPE_ARGUMENTS_ENUM =
      CompileTimeErrorCode(
    'WRONG_NUMBER_OF_TYPE_ARGUMENTS_ENUM',
    "The enum is declared with {0} type parameters, but {1} type arguments "
        "were given.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the extension being referenced
  ///  1: the number of type parameters that were declared
  ///  2: the number of type arguments provided
  static const CompileTimeErrorCode WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION =
      CompileTimeErrorCode(
    'WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION',
    "The extension '{0}' is declared with {1} type parameters, but {2} type "
        "arguments were given.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the function being referenced
  ///  1: the number of type parameters that were declared
  ///  2: the number of type arguments provided
  static const CompileTimeErrorCode WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION =
      CompileTimeErrorCode(
    'WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION',
    "The function '{0}' is declared with {1} type parameters, but {2} type "
        "arguments were given.",
    correctionMessage:
        "Try adjusting the number of type arguments to match the number of "
        "type parameters.",
  );

  ///  Parameters:
  ///  0: the name of the method being referenced (<i>G</i>)
  ///  1: the number of type parameters that were declared
  ///  2: the number of type arguments provided
  static const CompileTimeErrorCode WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD =
      CompileTimeErrorCode(
    'WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD',
    "The method '{0}' is declared with {1} type parameters, but {2} type "
        "arguments are given.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
  );

  ///  Let `C` be a generic class that declares a formal type parameter `X`, and
  ///  assume that `T` is a direct superinterface of `C`. It is a compile-time
  ///  error if `X` occurs contravariantly or invariantly in `T`.
  static const CompileTimeErrorCode
      WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE = CompileTimeErrorCode(
    'WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE',
    "'{0}' can't be used contravariantly or invariantly in '{1}'.",
    correctionMessage:
        "Try not using class type parameters in types of formal parameters of "
        "function types, nor in explicitly contravariant or invariant "
        "superinterfaces.",
  );

  ///  Let `C` be a generic class that declares a formal type parameter `X`.
  ///
  ///  If `X` is explicitly contravariant then it is a compile-time error for
  ///  `X` to occur in a non-contravariant position in a member signature in the
  ///  body of `C`, except when `X` is in a contravariant position in the type
  ///  annotation of a covariant formal parameter.
  ///
  ///  If `X` is explicitly covariant then it is a compile-time error for
  ///  `X` to occur in a non-covariant position in a member signature in the
  ///  body of `C`, except when `X` is in a covariant position in the type
  ///  annotation of a covariant formal parameter.
  ///
  ///  Parameters:
  ///  0: the variance modifier defined for {0}
  ///  1: the name of the type parameter
  ///  2: the variance position that the type parameter {1} is in
  static const CompileTimeErrorCode WRONG_TYPE_PARAMETER_VARIANCE_POSITION =
      CompileTimeErrorCode(
    'WRONG_TYPE_PARAMETER_VARIANCE_POSITION',
    "The '{0}' type parameter '{1}' can't be used in an '{2}' position.",
    correctionMessage:
        "Try removing the type parameter or change the explicit variance "
        "modifier declaration for the type parameter to another one of 'in', "
        "'out', or 'inout'.",
  );

  ///  No parameters.
  static const CompileTimeErrorCode YIELD_EACH_IN_NON_GENERATOR =
      CompileTimeErrorCode(
    'YIELD_IN_NON_GENERATOR',
    "Yield-each statements must be in a generator function (one marked with "
        "either 'async*' or 'sync*').",
    correctionMessage:
        "Try adding 'async*' or 'sync*' to the enclosing function.",
    hasPublishedDocs: true,
    uniqueName: 'YIELD_EACH_IN_NON_GENERATOR',
  );

  ///  Parameters:
  ///  0: the type of the expression after `yield*`
  ///  1: the return type of the function containing the `yield*`
  static const CompileTimeErrorCode YIELD_EACH_OF_INVALID_TYPE =
      CompileTimeErrorCode(
    'YIELD_OF_INVALID_TYPE',
    "The type '{0}' implied by the 'yield*' expression must be assignable to "
        "'{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'YIELD_EACH_OF_INVALID_TYPE',
  );

  ///  ?? Yield: It is a compile-time error if a yield statement appears in a
  ///  function that is not a generator function.
  ///
  ///  No parameters.
  static const CompileTimeErrorCode YIELD_IN_NON_GENERATOR =
      CompileTimeErrorCode(
    'YIELD_IN_NON_GENERATOR',
    "Yield statements must be in a generator function (one marked with either "
        "'async*' or 'sync*').",
    correctionMessage:
        "Try adding 'async*' or 'sync*' to the enclosing function.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the type of the expression after `yield`
  ///  1: the return type of the function containing the `yield`
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
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
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
        "Try adding an explicit type, or remove implicit-dynamic from your "
        "analysis options file.",
  );

  static const LanguageCode IMPLICIT_DYNAMIC_FUNCTION = LanguageCode(
    'IMPLICIT_DYNAMIC_FUNCTION',
    "Missing type arguments for generic function '{0}<{1}>'.",
    correctionMessage:
        "Try adding an explicit type, or remove implicit-dynamic from your "
        "analysis options file.",
  );

  static const LanguageCode IMPLICIT_DYNAMIC_INVOKE = LanguageCode(
    'IMPLICIT_DYNAMIC_INVOKE',
    "Missing type arguments for calling generic function type '{0}'.",
    correctionMessage:
        "Try adding an explicit type, or remove implicit-dynamic from your "
        "analysis options file.",
  );

  static const LanguageCode IMPLICIT_DYNAMIC_LIST_LITERAL = LanguageCode(
    'IMPLICIT_DYNAMIC_LIST_LITERAL',
    "Missing type argument for list literal.",
    correctionMessage:
        "Try adding an explicit type, or remove implicit-dynamic from your "
        "analysis options file.",
  );

  static const LanguageCode IMPLICIT_DYNAMIC_MAP_LITERAL = LanguageCode(
    'IMPLICIT_DYNAMIC_MAP_LITERAL',
    "Missing type arguments for map literal.",
    correctionMessage:
        "Try adding an explicit type, or remove implicit-dynamic from your "
        "analysis options file.",
  );

  static const LanguageCode IMPLICIT_DYNAMIC_METHOD = LanguageCode(
    'IMPLICIT_DYNAMIC_METHOD',
    "Missing type arguments for generic method '{0}<{1}>'.",
    correctionMessage:
        "Try adding an explicit type, or remove implicit-dynamic from your "
        "analysis options file.",
  );

  static const LanguageCode IMPLICIT_DYNAMIC_PARAMETER = LanguageCode(
    'IMPLICIT_DYNAMIC_PARAMETER',
    "Missing parameter type for '{0}'.",
    correctionMessage:
        "Try adding an explicit type, or remove implicit-dynamic from your "
        "analysis options file.",
  );

  static const LanguageCode IMPLICIT_DYNAMIC_RETURN = LanguageCode(
    'IMPLICIT_DYNAMIC_RETURN',
    "Missing return type for '{0}'.",
    correctionMessage:
        "Try adding an explicit type, or remove implicit-dynamic from your "
        "analysis options file.",
  );

  static const LanguageCode IMPLICIT_DYNAMIC_TYPE = LanguageCode(
    'IMPLICIT_DYNAMIC_TYPE',
    "Missing type arguments for generic type '{0}'.",
    correctionMessage:
        "Try adding an explicit type, or remove implicit-dynamic from your "
        "analysis options file.",
  );

  static const LanguageCode IMPLICIT_DYNAMIC_VARIABLE = LanguageCode(
    'IMPLICIT_DYNAMIC_VARIABLE',
    "Missing variable type for '{0}'.",
    correctionMessage:
        "Try adding an explicit type, or remove implicit-dynamic from your "
        "analysis options file.",
  );

  /// Initialize a newly created error code to have the given [name].
  const LanguageCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
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
  ///  No parameters.
  static const StaticWarningCode DEAD_NULL_AWARE_EXPRESSION = StaticWarningCode(
    'DEAD_NULL_AWARE_EXPRESSION',
    "The left operand can't be null, so the right operand is never executed.",
    correctionMessage: "Try removing the operator and the right operand.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the null-aware operator that is invalid
  ///  1: the non-null-aware operator that can replace the invalid operator
  static const StaticWarningCode INVALID_NULL_AWARE_OPERATOR =
      StaticWarningCode(
    'INVALID_NULL_AWARE_OPERATOR',
    "The receiver can't be null, so the null-aware operator '{0}' is "
        "unnecessary.",
    correctionMessage: "Try replacing the operator '{0}' with '{1}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the null-aware operator that is invalid
  ///  1: the non-null-aware operator that can replace the invalid operator
  static const StaticWarningCode
      INVALID_NULL_AWARE_OPERATOR_AFTER_SHORT_CIRCUIT = StaticWarningCode(
    'INVALID_NULL_AWARE_OPERATOR',
    "The receiver can't be null because of short-circuiting, so the null-aware "
        "operator '{0}' can't be used.",
    correctionMessage: "Try replacing the operator '{0}' with '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_NULL_AWARE_OPERATOR_AFTER_SHORT_CIRCUIT',
  );

  ///  7.1 Instance Methods: It is a static warning if an instance method
  ///  <i>m1</i> overrides an instance member <i>m2</i>, the signature of
  ///  <i>m2</i> explicitly specifies a default value for a formal parameter
  ///  <i>p</i> and the signature of <i>m1</i> specifies a different default value
  ///  for <i>p</i>.
  static const StaticWarningCode
      INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED = StaticWarningCode(
    'INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED',
    "Parameters can't override default values, this method overrides '{0}.{1}' "
        "where '{2}' has a different value.",
    correctionMessage: "Try using the same default value in both methods.",
  );

  ///  7.1 Instance Methods: It is a static warning if an instance method
  ///  <i>m1</i> overrides an instance member <i>m2</i>, the signature of
  ///  <i>m2</i> explicitly specifies a default value for a formal parameter
  ///  <i>p</i> and the signature of <i>m1</i> specifies a different default value
  ///  for <i>p</i>.
  static const StaticWarningCode
      INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL = StaticWarningCode(
    'INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL',
    "Parameters can't override default values, this method overrides '{0}.{1}' "
        "where this positional parameter has a different value.",
    correctionMessage: "Try using the same default value in both methods.",
  );

  ///  Parameters:
  ///  0: the name of the constant that is missing
  static const StaticWarningCode MISSING_ENUM_CONSTANT_IN_SWITCH =
      StaticWarningCode(
    'MISSING_ENUM_CONSTANT_IN_SWITCH',
    "Missing case clause for '{0}'.",
    correctionMessage:
        "Try adding a case clause for the missing constant, or adding a "
        "default clause.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
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
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
          name: name,
          problemMessage: problemMessage,
          uniqueName: 'StaticWarningCode.${uniqueName ?? name}',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.WARNING;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;
}
