// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart pkg/analyzer/tool/messages/generate.dart' to update.

import "package:analyzer/error/error.dart";

// It is hard to visually separate each code's _doc comment_ from its published
// _documentation comment_ when each is written as an end-of-line comment.
// ignore_for_file: slash_for_doc_comments

final fastaAnalyzerErrorCodes = <ErrorCode?>[
  null,
  ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND,
  ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP,
  ParserErrorCode.EXTERNAL_CLASS,
  ParserErrorCode.STATIC_CONSTRUCTOR,
  ParserErrorCode.EXTERNAL_ENUM,
  ParserErrorCode.PREFIX_AFTER_COMBINATOR,
  ParserErrorCode.TYPEDEF_IN_CLASS,
  ParserErrorCode.EXPECTED_BODY,
  ParserErrorCode.INVALID_AWAIT_IN_FOR,
  ParserErrorCode.IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE,
  ParserErrorCode.WITH_BEFORE_EXTENDS,
  ParserErrorCode.VAR_RETURN_TYPE,
  ParserErrorCode.TYPE_ARGUMENTS_ON_TYPE_VARIABLE,
  ParserErrorCode.TOP_LEVEL_OPERATOR,
  ParserErrorCode.SWITCH_HAS_MULTIPLE_DEFAULT_CASES,
  ParserErrorCode.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE,
  ParserErrorCode.STATIC_OPERATOR,
  ParserErrorCode.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER,
  ParserErrorCode.STACK_OVERFLOW,
  ParserErrorCode.MISSING_CATCH_OR_FINALLY,
  ParserErrorCode.REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR,
  ParserErrorCode.REDIRECTING_CONSTRUCTOR_WITH_BODY,
  ParserErrorCode.NATIVE_CLAUSE_SHOULD_BE_ANNOTATION,
  ParserErrorCode.MULTIPLE_WITH_CLAUSES,
  ParserErrorCode.MULTIPLE_PART_OF_DIRECTIVES,
  ParserErrorCode.MULTIPLE_ON_CLAUSES,
  ParserErrorCode.MULTIPLE_LIBRARY_DIRECTIVES,
  ParserErrorCode.MULTIPLE_EXTENDS_CLAUSES,
  ParserErrorCode.MISSING_STATEMENT,
  ParserErrorCode.MISSING_PREFIX_IN_DEFERRED_IMPORT,
  ParserErrorCode.MISSING_KEYWORD_OPERATOR,
  ParserErrorCode.MISSING_EXPRESSION_IN_THROW,
  ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE,
  ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER,
  ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR,
  ParserErrorCode.MISSING_INITIALIZER,
  ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST,
  ParserErrorCode.INVALID_UNICODE_ESCAPE,
  ParserErrorCode.INVALID_OPERATOR,
  ParserErrorCode.INVALID_HEX_ESCAPE,
  ParserErrorCode.EXPECTED_INSTEAD,
  ParserErrorCode.IMPLEMENTS_BEFORE_WITH,
  ParserErrorCode.IMPLEMENTS_BEFORE_ON,
  ParserErrorCode.IMPLEMENTS_BEFORE_EXTENDS,
  ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE,
  ParserErrorCode.EXPECTED_ELSE_OR_COMMA,
  ParserErrorCode.INVALID_SUPER_IN_INITIALIZER,
  ParserErrorCode.EXPERIMENT_NOT_ENABLED,
  ParserErrorCode.EXTERNAL_METHOD_WITH_BODY,
  ParserErrorCode.EXTERNAL_FIELD,
  ParserErrorCode.ABSTRACT_CLASS_MEMBER,
  ParserErrorCode.BREAK_OUTSIDE_OF_LOOP,
  ParserErrorCode.CLASS_IN_CLASS,
  ParserErrorCode.COLON_IN_PLACE_OF_IN,
  ParserErrorCode.CONSTRUCTOR_WITH_RETURN_TYPE,
  ParserErrorCode.MODIFIER_OUT_OF_ORDER,
  ParserErrorCode.TYPE_BEFORE_FACTORY,
  ParserErrorCode.CONST_AND_FINAL,
  ParserErrorCode.CONFLICTING_MODIFIERS,
  ParserErrorCode.CONST_CLASS,
  ParserErrorCode.VAR_AS_TYPE_NAME,
  ParserErrorCode.CONST_FACTORY,
  ParserErrorCode.CONST_METHOD,
  ParserErrorCode.CONTINUE_WITHOUT_LABEL_IN_CASE,
  ParserErrorCode.INVALID_THIS_IN_INITIALIZER,
  ParserErrorCode.COVARIANT_AND_STATIC,
  ParserErrorCode.COVARIANT_MEMBER,
  ParserErrorCode.DEFERRED_AFTER_PREFIX,
  ParserErrorCode.DIRECTIVE_AFTER_DECLARATION,
  ParserErrorCode.DUPLICATED_MODIFIER,
  ParserErrorCode.DUPLICATE_DEFERRED,
  ParserErrorCode.DUPLICATE_LABEL_IN_SWITCH_STATEMENT,
  ParserErrorCode.DUPLICATE_PREFIX,
  ParserErrorCode.ENUM_IN_CLASS,
  ParserErrorCode.EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE,
  ParserErrorCode.EXTERNAL_TYPEDEF,
  ParserErrorCode.EXTRANEOUS_MODIFIER,
  ParserErrorCode.FACTORY_TOP_LEVEL_DECLARATION,
  ParserErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR,
  ParserErrorCode.FINAL_AND_COVARIANT,
  ParserErrorCode.FINAL_AND_VAR,
  ParserErrorCode.INITIALIZED_VARIABLE_IN_FOR_EACH,
  ParserErrorCode.CATCH_SYNTAX_EXTRA_PARAMETERS,
  ParserErrorCode.CATCH_SYNTAX,
  ParserErrorCode.EXTERNAL_FACTORY_REDIRECTION,
  ParserErrorCode.EXTERNAL_FACTORY_WITH_BODY,
  ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_BODY,
  ParserErrorCode.FIELD_INITIALIZED_OUTSIDE_DECLARING_CLASS,
  ParserErrorCode.VAR_AND_TYPE,
  ParserErrorCode.INVALID_INITIALIZER,
  ParserErrorCode.ANNOTATION_WITH_TYPE_ARGUMENTS,
  ParserErrorCode.EXTENSION_DECLARES_CONSTRUCTOR,
  ParserErrorCode.EXTENSION_DECLARES_INSTANCE_FIELD,
  ParserErrorCode.EXTENSION_DECLARES_ABSTRACT_MEMBER,
  ParserErrorCode.MIXIN_DECLARES_CONSTRUCTOR,
  ParserErrorCode.NULL_AWARE_CASCADE_OUT_OF_ORDER,
  ParserErrorCode.MULTIPLE_VARIANCE_MODIFIERS,
  ParserErrorCode.INVALID_USE_OF_COVARIANT_IN_EXTENSION,
  ParserErrorCode.TYPE_PARAMETER_ON_CONSTRUCTOR,
  ParserErrorCode.VOID_WITH_TYPE_ARGUMENTS,
  ParserErrorCode.FINAL_AND_COVARIANT_LATE_WITH_INITIALIZER,
  ParserErrorCode.INVALID_CONSTRUCTOR_NAME,
  ParserErrorCode.GETTER_CONSTRUCTOR,
  ParserErrorCode.SETTER_CONSTRUCTOR,
  ParserErrorCode.MEMBER_WITH_CLASS_NAME,
  ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_INITIALIZER,
  ParserErrorCode.ABSTRACT_STATIC_FIELD,
  ParserErrorCode.ABSTRACT_LATE_FIELD,
  ParserErrorCode.EXTERNAL_LATE_FIELD,
  ParserErrorCode.ABSTRACT_EXTERNAL_FIELD,
  ParserErrorCode.ANNOTATION_ON_TYPE_ARGUMENT,
  ParserErrorCode.BINARY_OPERATOR_WRITTEN_OUT,
  ParserErrorCode.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD,
  ParserErrorCode.ANNOTATION_WITH_TYPE_ARGUMENTS_UNINSTANTIATED,
  ParserErrorCode.LITERAL_WITH_CLASS_AND_NEW,
  ParserErrorCode.LITERAL_WITH_CLASS,
  ParserErrorCode.LITERAL_WITH_NEW,
  ParserErrorCode.CONSTRUCTOR_WITH_TYPE_ARGUMENTS,
  ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR,
  ParserErrorCode.TYPE_PARAMETER_ON_OPERATOR,
];

class ParserErrorCode extends ErrorCode {
  static const ParserErrorCode ABSTRACT_CLASS_MEMBER = ParserErrorCode(
    'ABSTRACT_CLASS_MEMBER',
    "Members of classes can't be declared to be 'abstract'.",
    correctionMessage:
        "Try removing the 'abstract' keyword. You can add the 'abstract' keyword before the class declaration.",
  );

  static const ParserErrorCode ABSTRACT_ENUM = ParserErrorCode(
    'ABSTRACT_ENUM',
    "Enums can't be declared to be 'abstract'.",
    correctionMessage: "Try removing the keyword 'abstract'.",
  );

  static const ParserErrorCode ABSTRACT_EXTERNAL_FIELD = ParserErrorCode(
    'ABSTRACT_EXTERNAL_FIELD',
    "Fields can't be declared both 'abstract' and 'external'.",
    correctionMessage: "Try removing the 'abstract' or 'external' keyword.",
  );

  static const ParserErrorCode ABSTRACT_LATE_FIELD = ParserErrorCode(
    'ABSTRACT_LATE_FIELD',
    "Abstract fields cannot be late.",
    correctionMessage: "Try removing the 'abstract' or 'late' keyword.",
  );

  static const ParserErrorCode ABSTRACT_STATIC_FIELD = ParserErrorCode(
    'ABSTRACT_STATIC_FIELD',
    "Static fields can't be declared 'abstract'.",
    correctionMessage: "Try removing the 'abstract' or 'static' keyword.",
  );

  static const ParserErrorCode ABSTRACT_STATIC_METHOD = ParserErrorCode(
    'ABSTRACT_STATIC_METHOD',
    "Static methods can't be declared to be 'abstract'.",
    correctionMessage: "Try removing the keyword 'abstract'.",
  );

  static const ParserErrorCode ABSTRACT_TOP_LEVEL_FUNCTION = ParserErrorCode(
    'ABSTRACT_TOP_LEVEL_FUNCTION',
    "Top-level functions can't be declared to be 'abstract'.",
    correctionMessage: "Try removing the keyword 'abstract'.",
  );

  static const ParserErrorCode ABSTRACT_TOP_LEVEL_VARIABLE = ParserErrorCode(
    'ABSTRACT_TOP_LEVEL_VARIABLE',
    "Top-level variables can't be declared to be 'abstract'.",
    correctionMessage: "Try removing the keyword 'abstract'.",
  );

  static const ParserErrorCode ABSTRACT_TYPEDEF = ParserErrorCode(
    'ABSTRACT_TYPEDEF',
    "Typedefs can't be declared to be 'abstract'.",
    correctionMessage: "Try removing the keyword 'abstract'.",
  );

  static const ParserErrorCode ANNOTATION_ON_TYPE_ARGUMENT = ParserErrorCode(
    'ANNOTATION_ON_TYPE_ARGUMENT',
    "Type arguments can't have annotations because they aren't declarations.",
  );

  static const ParserErrorCode ANNOTATION_WITH_TYPE_ARGUMENTS = ParserErrorCode(
    'ANNOTATION_WITH_TYPE_ARGUMENTS',
    "An annotation can't use type arguments.",
  );

  static const ParserErrorCode ANNOTATION_WITH_TYPE_ARGUMENTS_UNINSTANTIATED =
      ParserErrorCode(
    'ANNOTATION_WITH_TYPE_ARGUMENTS_UNINSTANTIATED',
    "An annotation with type arguments must be followed by an argument list.",
  );

  /**
   * 16.32 Identifier Reference: It is a compile-time error if any of the
   * identifiers async, await, or yield is used as an identifier in a function
   * body marked with either async, async, or sync.
   */
  static const ParserErrorCode ASYNC_KEYWORD_USED_AS_IDENTIFIER =
      ParserErrorCode(
    'ASYNC_KEYWORD_USED_AS_IDENTIFIER',
    "The keywords 'await' and 'yield' can't be used as identifiers in an asynchronous or generator function.",
  );

  static const ParserErrorCode BINARY_OPERATOR_WRITTEN_OUT = ParserErrorCode(
    'BINARY_OPERATOR_WRITTEN_OUT',
    "Binary operator '{0}' is written as '{1}' instead of the written out word.",
    correctionMessage: "Try replacing '{0}' with '{1}'.",
  );

  static const ParserErrorCode BREAK_OUTSIDE_OF_LOOP = ParserErrorCode(
    'BREAK_OUTSIDE_OF_LOOP',
    "A break statement can't be used outside of a loop or switch statement.",
    correctionMessage: "Try removing the break statement.",
  );

  static const ParserErrorCode CATCH_SYNTAX = ParserErrorCode(
    'CATCH_SYNTAX',
    "'catch' must be followed by '(identifier)' or '(identifier, identifier)'.",
    correctionMessage:
        "No types are needed, the first is given by 'on', the second is always 'StackTrace'.",
  );

  static const ParserErrorCode CATCH_SYNTAX_EXTRA_PARAMETERS = ParserErrorCode(
    'CATCH_SYNTAX_EXTRA_PARAMETERS',
    "'catch' must be followed by '(identifier)' or '(identifier, identifier)'.",
    correctionMessage:
        "No types are needed, the first is given by 'on', the second is always 'StackTrace'.",
  );

  static const ParserErrorCode CLASS_IN_CLASS = ParserErrorCode(
    'CLASS_IN_CLASS',
    "Classes can't be declared inside other classes.",
    correctionMessage: "Try moving the class to the top-level.",
  );

  static const ParserErrorCode COLON_IN_PLACE_OF_IN = ParserErrorCode(
    'COLON_IN_PLACE_OF_IN',
    "For-in loops use 'in' rather than a colon.",
    correctionMessage: "Try replacing the colon with the keyword 'in'.",
  );

  static const ParserErrorCode CONFLICTING_MODIFIERS = ParserErrorCode(
    'CONFLICTING_MODIFIERS',
    "Members can't be declared to be both '{0}' and '{1}'.",
    correctionMessage: "Try removing one of the keywords.",
  );

  static const ParserErrorCode CONSTRUCTOR_WITH_RETURN_TYPE = ParserErrorCode(
    'CONSTRUCTOR_WITH_RETURN_TYPE',
    "Constructors can't have a return type.",
    correctionMessage: "Try removing the return type.",
  );

  static const ParserErrorCode CONSTRUCTOR_WITH_TYPE_ARGUMENTS =
      ParserErrorCode(
    'CONSTRUCTOR_WITH_TYPE_ARGUMENTS',
    "A constructor invocation can't have type arguments after the constructor name.",
    correctionMessage:
        "Try removing the type arguments or placing them after the class name.",
  );

  static const ParserErrorCode CONST_AND_FINAL = ParserErrorCode(
    'CONST_AND_FINAL',
    "Members can't be declared to be both 'const' and 'final'.",
    correctionMessage: "Try removing either the 'const' or 'final' keyword.",
  );

  static const ParserErrorCode CONST_CLASS = ParserErrorCode(
    'CONST_CLASS',
    "Classes can't be declared to be 'const'.",
    correctionMessage:
        "Try removing the 'const' keyword. If you're trying to indicate that instances of the class can be constants, place the 'const' keyword on  the class' constructor(s).",
  );

  static const ParserErrorCode CONST_CONSTRUCTOR_WITH_BODY = ParserErrorCode(
    'CONST_CONSTRUCTOR_WITH_BODY',
    "Const constructors can't have a body.",
    correctionMessage: "Try removing either the 'const' keyword or the body.",
  );

  static const ParserErrorCode CONST_ENUM = ParserErrorCode(
    'CONST_ENUM',
    "Enums can't be declared to be 'const'.",
    correctionMessage: "Try removing the 'const' keyword.",
  );

  static const ParserErrorCode CONST_FACTORY = ParserErrorCode(
    'CONST_FACTORY',
    "Only redirecting factory constructors can be declared to be 'const'.",
    correctionMessage:
        "Try removing the 'const' keyword, or replacing the body with '=' followed by a valid target.",
  );

  static const ParserErrorCode CONST_METHOD = ParserErrorCode(
    'CONST_METHOD',
    "Getters, setters and methods can't be declared to be 'const'.",
    correctionMessage: "Try removing the 'const' keyword.",
  );

  static const ParserErrorCode CONST_TYPEDEF = ParserErrorCode(
    'CONST_TYPEDEF',
    "Type aliases can't be declared to be 'const'.",
    correctionMessage: "Try removing the 'const' keyword.",
  );

  static const ParserErrorCode CONTINUE_OUTSIDE_OF_LOOP = ParserErrorCode(
    'CONTINUE_OUTSIDE_OF_LOOP',
    "A continue statement can't be used outside of a loop or switch statement.",
    correctionMessage: "Try removing the continue statement.",
  );

  static const ParserErrorCode CONTINUE_WITHOUT_LABEL_IN_CASE = ParserErrorCode(
    'CONTINUE_WITHOUT_LABEL_IN_CASE',
    "A continue statement in a switch statement must have a label as a target.",
    correctionMessage:
        "Try adding a label associated with one of the case clauses to the continue statement.",
  );

  static const ParserErrorCode COVARIANT_AND_STATIC = ParserErrorCode(
    'COVARIANT_AND_STATIC',
    "Members can't be declared to be both 'covariant' and 'static'.",
    correctionMessage:
        "Try removing either the 'covariant' or 'static' keyword.",
  );

  static const ParserErrorCode COVARIANT_CONSTRUCTOR = ParserErrorCode(
    'COVARIANT_CONSTRUCTOR',
    "A constructor can't be declared to be 'covariant'.",
    correctionMessage: "Try removing the keyword 'covariant'.",
  );

  static const ParserErrorCode COVARIANT_MEMBER = ParserErrorCode(
    'COVARIANT_MEMBER',
    "Getters, setters and methods can't be declared to be 'covariant'.",
    correctionMessage: "Try removing the 'covariant' keyword.",
  );

  static const ParserErrorCode COVARIANT_TOP_LEVEL_DECLARATION =
      ParserErrorCode(
    'COVARIANT_TOP_LEVEL_DECLARATION',
    "Top-level declarations can't be declared to be covariant.",
    correctionMessage: "Try removing the keyword 'covariant'.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a function type associated with
  // a parameter includes optional parameters that have a default value. This
  // isn't allowed because the default values of parameters aren't part of the
  // function's type, and therefore including them doesn't provide any value.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the parameter `p` has a
  // default value even though it's part of the type of the parameter `g`:
  //
  // ```dart
  // void f(void Function([int p [!=!] 0]) g) {
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the default value from the function-type's parameter:
  //
  // ```dart
  // void f(void Function([int p]) g) {
  // }
  // ```
  static const ParserErrorCode DEFAULT_VALUE_IN_FUNCTION_TYPE = ParserErrorCode(
    'DEFAULT_VALUE_IN_FUNCTION_TYPE',
    "Parameters in a function type can't have default values.",
    correctionMessage: "Try removing the default value.",
    hasPublishedDocs: true,
  );

  static const ParserErrorCode DEFERRED_AFTER_PREFIX = ParserErrorCode(
    'DEFERRED_AFTER_PREFIX',
    "The deferred keyword should come immediately before the prefix ('as' clause).",
    correctionMessage: "Try moving the deferred keyword before the prefix.",
  );

  static const ParserErrorCode DIRECTIVE_AFTER_DECLARATION = ParserErrorCode(
    'DIRECTIVE_AFTER_DECLARATION',
    "Directives must appear before any declarations.",
    correctionMessage: "Try moving the directive before any declarations.",
  );

  /**
   * Parameters:
   * 0: the modifier that was duplicated
   */
  static const ParserErrorCode DUPLICATED_MODIFIER = ParserErrorCode(
    'DUPLICATED_MODIFIER',
    "The modifier '{0}' was already specified.",
    correctionMessage: "Try removing all but one occurrence of the modifier.",
  );

  static const ParserErrorCode DUPLICATE_DEFERRED = ParserErrorCode(
    'DUPLICATE_DEFERRED',
    "An import directive can only have one 'deferred' keyword.",
    correctionMessage: "Try removing all but one 'deferred' keyword.",
  );

  /**
   * Parameters:
   * 0: the label that was duplicated
   */
  static const ParserErrorCode DUPLICATE_LABEL_IN_SWITCH_STATEMENT =
      ParserErrorCode(
    'DUPLICATE_LABEL_IN_SWITCH_STATEMENT',
    "The label '{0}' was already used in this switch statement.",
    correctionMessage: "Try choosing a different name for this label.",
  );

  static const ParserErrorCode DUPLICATE_PREFIX = ParserErrorCode(
    'DUPLICATE_PREFIX',
    "An import directive can only have one prefix ('as' clause).",
    correctionMessage: "Try removing all but one prefix.",
  );

  static const ParserErrorCode EMPTY_ENUM_BODY = ParserErrorCode(
    'EMPTY_ENUM_BODY',
    "An enum must declare at least one constant name.",
    correctionMessage: "Try declaring a constant.",
  );

  static const ParserErrorCode ENUM_IN_CLASS = ParserErrorCode(
    'ENUM_IN_CLASS',
    "Enums can't be declared inside classes.",
    correctionMessage: "Try moving the enum to the top-level.",
  );

  static const ParserErrorCode EQUALITY_CANNOT_BE_EQUALITY_OPERAND =
      ParserErrorCode(
    'EQUALITY_CANNOT_BE_EQUALITY_OPERAND',
    "A comparison expression can't be an operand of another comparison expression.",
    correctionMessage: "Try putting parentheses around one of the comparisons.",
  );

  static const ParserErrorCode EXPECTED_BODY = ParserErrorCode(
    'EXPECTED_BODY',
    "A {0} must have a body, even if it is empty.",
    correctionMessage: "Try adding an empty body.",
  );

  static const ParserErrorCode EXPECTED_CASE_OR_DEFAULT = ParserErrorCode(
    'EXPECTED_CASE_OR_DEFAULT',
    "Expected 'case' or 'default'.",
    correctionMessage: "Try placing this code inside a case clause.",
  );

  static const ParserErrorCode EXPECTED_CLASS_MEMBER = ParserErrorCode(
    'EXPECTED_CLASS_MEMBER',
    "Expected a class member.",
    correctionMessage: "Try placing this code inside a class member.",
  );

  static const ParserErrorCode EXPECTED_ELSE_OR_COMMA = ParserErrorCode(
    'EXPECTED_ELSE_OR_COMMA',
    "Expected 'else' or comma.",
  );

  static const ParserErrorCode EXPECTED_EXECUTABLE = ParserErrorCode(
    'EXPECTED_EXECUTABLE',
    "Expected a method, getter, setter or operator declaration.",
    correctionMessage:
        "This appears to be incomplete code. Try removing it or completing it.",
  );

  static const ParserErrorCode EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD =
      ParserErrorCode(
    'EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD',
    "'{0}' can't be used as an identifier because it's a keyword.",
    correctionMessage:
        "Try renaming this to be an identifier that isn't a keyword.",
  );

  static const ParserErrorCode EXPECTED_INSTEAD = ParserErrorCode(
    'EXPECTED_INSTEAD',
    "Expected '{0}' instead of this.",
  );

  static const ParserErrorCode EXPECTED_LIST_OR_MAP_LITERAL = ParserErrorCode(
    'EXPECTED_LIST_OR_MAP_LITERAL',
    "Expected a list or map literal.",
    correctionMessage:
        "Try inserting a list or map literal, or remove the type arguments.",
  );

  static const ParserErrorCode EXPECTED_STRING_LITERAL = ParserErrorCode(
    'EXPECTED_STRING_LITERAL',
    "Expected a string literal.",
  );

  /**
   * Parameters:
   * 0: the token that was expected but not found
   */
  static const ParserErrorCode EXPECTED_TOKEN = ParserErrorCode(
    'EXPECTED_TOKEN',
    "Expected to find '{0}'.",
  );

  static const ParserErrorCode EXPECTED_TYPE_NAME = ParserErrorCode(
    'EXPECTED_TYPE_NAME',
    "Expected a type name.",
  );

  static const ParserErrorCode EXPERIMENT_NOT_ENABLED = ParserErrorCode(
    'EXPERIMENT_NOT_ENABLED',
    "This requires the '{0}' language feature to be enabled.",
    correctionMessage:
        "Try updating your pubspec.yaml to set the minimum SDK constraint to {1} or higher, and running 'pub get'.",
  );

  static const ParserErrorCode EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE =
      ParserErrorCode(
    'EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE',
    "Export directives must precede part directives.",
    correctionMessage:
        "Try moving the export directives before the part directives.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an abstract declaration is
  // declared in an extension. Extensions can declare only concrete members.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the method `a` doesn't
  // have a body:
  //
  // ```dart
  // extension E on String {
  //   int [!a!]();
  // }
  // ```
  //
  // #### Common fixes
  //
  // Either provide an implementation for the member or remove it.
  static const ParserErrorCode EXTENSION_DECLARES_ABSTRACT_MEMBER =
      ParserErrorCode(
    'EXTENSION_DECLARES_ABSTRACT_MEMBER',
    "Extensions can't declare abstract members.",
    correctionMessage: "Try providing an implementation for the member.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a constructor declaration is
  // found in an extension. It isn't valid to define a constructor because
  // extensions aren't classes, and it isn't possible to create an instance of
  // an extension.
  //
  // #### Example
  //
  // The following code produces this diagnostic because there is a constructor
  // declaration in `E`:
  //
  // ```dart
  // extension E on String {
  //   [!E!]() : super();
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the constructor or replace it with a static method.
  static const ParserErrorCode EXTENSION_DECLARES_CONSTRUCTOR = ParserErrorCode(
    'EXTENSION_DECLARES_CONSTRUCTOR',
    "Extensions can't declare constructors.",
    correctionMessage: "Try removing the constructor declaration.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an instance field declaration is
  // found in an extension. It isn't valid to define an instance field because
  // extensions can only add behavior, not state.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `s` is an instance
  // field:
  //
  // ```dart
  // %language=2.9
  // extension E on String {
  //   String [!s!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the field, make it a static field, or convert it to be a getter,
  // setter, or method.
  static const ParserErrorCode EXTENSION_DECLARES_INSTANCE_FIELD =
      ParserErrorCode(
    'EXTENSION_DECLARES_INSTANCE_FIELD',
    "Extensions can't declare instance fields",
    correctionMessage:
        "Try removing the field declaration or making it a static field",
    hasPublishedDocs: true,
  );

  static const ParserErrorCode EXTERNAL_CLASS = ParserErrorCode(
    'EXTERNAL_CLASS',
    "Classes can't be declared to be 'external'.",
    correctionMessage: "Try removing the keyword 'external'.",
  );

  static const ParserErrorCode EXTERNAL_CONSTRUCTOR_WITH_BODY = ParserErrorCode(
    'EXTERNAL_CONSTRUCTOR_WITH_BODY',
    "External constructors can't have a body.",
    correctionMessage:
        "Try removing the body of the constructor, or removing the keyword 'external'.",
  );

  static const ParserErrorCode EXTERNAL_CONSTRUCTOR_WITH_INITIALIZER =
      ParserErrorCode(
    'EXTERNAL_CONSTRUCTOR_WITH_INITIALIZER',
    "An external constructor can't have any initializers.",
  );

  static const ParserErrorCode EXTERNAL_ENUM = ParserErrorCode(
    'EXTERNAL_ENUM',
    "Enums can't be declared to be 'external'.",
    correctionMessage: "Try removing the keyword 'external'.",
  );

  static const ParserErrorCode EXTERNAL_FACTORY_REDIRECTION = ParserErrorCode(
    'EXTERNAL_FACTORY_REDIRECTION',
    "A redirecting factory can't be external.",
    correctionMessage: "Try removing the 'external' modifier.",
  );

  static const ParserErrorCode EXTERNAL_FACTORY_WITH_BODY = ParserErrorCode(
    'EXTERNAL_FACTORY_WITH_BODY',
    "External factories can't have a body.",
    correctionMessage:
        "Try removing the body of the factory, or removing the keyword 'external'.",
  );

  static const ParserErrorCode EXTERNAL_FIELD = ParserErrorCode(
    'EXTERNAL_FIELD',
    "Fields can't be declared to be 'external'.",
    correctionMessage:
        "Try removing the keyword 'external', or replacing the field by an external getter and/or setter.",
  );

  static const ParserErrorCode EXTERNAL_GETTER_WITH_BODY = ParserErrorCode(
    'EXTERNAL_GETTER_WITH_BODY',
    "External getters can't have a body.",
    correctionMessage:
        "Try removing the body of the getter, or removing the keyword 'external'.",
  );

  static const ParserErrorCode EXTERNAL_LATE_FIELD = ParserErrorCode(
    'EXTERNAL_LATE_FIELD',
    "External fields cannot be late.",
    correctionMessage: "Try removing the 'external' or 'late' keyword.",
  );

  static const ParserErrorCode EXTERNAL_METHOD_WITH_BODY = ParserErrorCode(
    'EXTERNAL_METHOD_WITH_BODY',
    "An external or native method can't have a body.",
  );

  static const ParserErrorCode EXTERNAL_OPERATOR_WITH_BODY = ParserErrorCode(
    'EXTERNAL_OPERATOR_WITH_BODY',
    "External operators can't have a body.",
    correctionMessage:
        "Try removing the body of the operator, or removing the keyword 'external'.",
  );

  static const ParserErrorCode EXTERNAL_SETTER_WITH_BODY = ParserErrorCode(
    'EXTERNAL_SETTER_WITH_BODY',
    "External setters can't have a body.",
    correctionMessage:
        "Try removing the body of the setter, or removing the keyword 'external'.",
  );

  static const ParserErrorCode EXTERNAL_TYPEDEF = ParserErrorCode(
    'EXTERNAL_TYPEDEF',
    "Typedefs can't be declared to be 'external'.",
    correctionMessage: "Try removing the keyword 'external'.",
  );

  static const ParserErrorCode EXTRANEOUS_MODIFIER = ParserErrorCode(
    'EXTRANEOUS_MODIFIER',
    "Can't have modifier '{0}' here.",
    correctionMessage: "Try removing '{0}'.",
  );

  static const ParserErrorCode FACTORY_TOP_LEVEL_DECLARATION = ParserErrorCode(
    'FACTORY_TOP_LEVEL_DECLARATION',
    "Top-level declarations can't be declared to be 'factory'.",
    correctionMessage: "Try removing the keyword 'factory'.",
  );

  static const ParserErrorCode FACTORY_WITHOUT_BODY = ParserErrorCode(
    'FACTORY_WITHOUT_BODY',
    "A non-redirecting 'factory' constructor must have a body.",
    correctionMessage: "Try adding a body to the constructor.",
  );

  static const ParserErrorCode FACTORY_WITH_INITIALIZERS = ParserErrorCode(
    'FACTORY_WITH_INITIALIZERS',
    "A 'factory' constructor can't have initializers.",
    correctionMessage:
        "Try removing the 'factory' keyword to make this a generative constructor, or removing the initializers.",
  );

  static const ParserErrorCode FIELD_INITIALIZED_OUTSIDE_DECLARING_CLASS =
      ParserErrorCode(
    'FIELD_INITIALIZED_OUTSIDE_DECLARING_CLASS',
    "A field can only be initialized in its declaring class",
    correctionMessage:
        "Try passing a value into the superclass constructor, or moving the initialization into the constructor body.",
  );

  static const ParserErrorCode FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR =
      ParserErrorCode(
    'FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR',
    "Field formal parameters can only be used in a constructor.",
    correctionMessage: "Try removing 'this.'.",
  );

  static const ParserErrorCode FINAL_AND_COVARIANT = ParserErrorCode(
    'FINAL_AND_COVARIANT',
    "Members can't be declared to be both 'final' and 'covariant'.",
    correctionMessage:
        "Try removing either the 'final' or 'covariant' keyword.",
  );

  static const ParserErrorCode FINAL_AND_COVARIANT_LATE_WITH_INITIALIZER =
      ParserErrorCode(
    'FINAL_AND_COVARIANT_LATE_WITH_INITIALIZER',
    "Members marked 'late' with an initializer can't be declared to be both 'final' and 'covariant'.",
    correctionMessage:
        "Try removing either the 'final' or 'covariant' keyword, or removing the initializer.",
  );

  static const ParserErrorCode FINAL_AND_VAR = ParserErrorCode(
    'FINAL_AND_VAR',
    "Members can't be declared to be both 'final' and 'var'.",
    correctionMessage: "Try removing the keyword 'var'.",
  );

  static const ParserErrorCode FINAL_CLASS = ParserErrorCode(
    'FINAL_CLASS',
    "Classes can't be declared to be 'final'.",
    correctionMessage: "Try removing the keyword 'final'.",
  );

  static const ParserErrorCode FINAL_CONSTRUCTOR = ParserErrorCode(
    'FINAL_CONSTRUCTOR',
    "A constructor can't be declared to be 'final'.",
    correctionMessage: "Try removing the keyword 'final'.",
  );

  static const ParserErrorCode FINAL_ENUM = ParserErrorCode(
    'FINAL_ENUM',
    "Enums can't be declared to be 'final'.",
    correctionMessage: "Try removing the keyword 'final'.",
  );

  static const ParserErrorCode FINAL_METHOD = ParserErrorCode(
    'FINAL_METHOD',
    "Getters, setters and methods can't be declared to be 'final'.",
    correctionMessage: "Try removing the keyword 'final'.",
  );

  static const ParserErrorCode FINAL_TYPEDEF = ParserErrorCode(
    'FINAL_TYPEDEF',
    "Typedefs can't be declared to be 'final'.",
    correctionMessage: "Try removing the keyword 'final'.",
  );

  static const ParserErrorCode FUNCTION_TYPED_PARAMETER_VAR = ParserErrorCode(
    'FUNCTION_TYPED_PARAMETER_VAR',
    "Function-typed parameters can't specify 'const', 'final' or 'var' in place of a return type.",
    correctionMessage: "Try replacing the keyword with a return type.",
  );

  static const ParserErrorCode GETTER_CONSTRUCTOR = ParserErrorCode(
    'GETTER_CONSTRUCTOR',
    "Constructors can't be a getter.",
    correctionMessage: "Try removing 'get'.",
  );

  static const ParserErrorCode GETTER_IN_FUNCTION = ParserErrorCode(
    'GETTER_IN_FUNCTION',
    "Getters can't be defined within methods or functions.",
    correctionMessage:
        "Try moving the getter outside the method or function, or converting the getter to a function.",
  );

  static const ParserErrorCode GETTER_WITH_PARAMETERS = ParserErrorCode(
    'GETTER_WITH_PARAMETERS',
    "Getters must be declared without a parameter list.",
    correctionMessage:
        "Try removing the parameter list, or removing the keyword 'get' to define a method rather than a getter.",
  );

  static const ParserErrorCode ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE =
      ParserErrorCode(
    'ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE',
    "Illegal assignment to non-assignable expression.",
  );

  static const ParserErrorCode IMPLEMENTS_BEFORE_EXTENDS = ParserErrorCode(
    'IMPLEMENTS_BEFORE_EXTENDS',
    "The extends clause must be before the implements clause.",
    correctionMessage:
        "Try moving the extends clause before the implements clause.",
  );

  static const ParserErrorCode IMPLEMENTS_BEFORE_ON = ParserErrorCode(
    'IMPLEMENTS_BEFORE_ON',
    "The on clause must be before the implements clause.",
    correctionMessage: "Try moving the on clause before the implements clause.",
  );

  static const ParserErrorCode IMPLEMENTS_BEFORE_WITH = ParserErrorCode(
    'IMPLEMENTS_BEFORE_WITH',
    "The with clause must be before the implements clause.",
    correctionMessage:
        "Try moving the with clause before the implements clause.",
  );

  static const ParserErrorCode IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE =
      ParserErrorCode(
    'IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE',
    "Import directives must precede part directives.",
    correctionMessage:
        "Try moving the import directives before the part directives.",
  );

  static const ParserErrorCode INITIALIZED_VARIABLE_IN_FOR_EACH =
      ParserErrorCode(
    'INITIALIZED_VARIABLE_IN_FOR_EACH',
    "The loop variable in a for-each loop can't be initialized.",
    correctionMessage:
        "Try removing the initializer, or using a different kind of loop.",
  );

  static const ParserErrorCode INVALID_AWAIT_IN_FOR = ParserErrorCode(
    'INVALID_AWAIT_IN_FOR',
    "The keyword 'await' isn't allowed for a normal 'for' statement.",
    correctionMessage: "Try removing the keyword, or use a for-each statement.",
  );

  /**
   * Parameters:
   * 0: the invalid escape sequence
   */
  static const ParserErrorCode INVALID_CODE_POINT = ParserErrorCode(
    'INVALID_CODE_POINT',
    "The escape sequence '{0}' isn't a valid code point.",
  );

  static const ParserErrorCode INVALID_COMMENT_REFERENCE = ParserErrorCode(
    'INVALID_COMMENT_REFERENCE',
    "Comment references should contain a possibly prefixed identifier and can start with 'new', but shouldn't contain anything else.",
  );

  static const ParserErrorCode INVALID_CONSTRUCTOR_NAME = ParserErrorCode(
    'INVALID_CONSTRUCTOR_NAME',
    "The name of a constructor must match the name of the enclosing class.",
  );

  static const ParserErrorCode INVALID_GENERIC_FUNCTION_TYPE = ParserErrorCode(
    'INVALID_GENERIC_FUNCTION_TYPE',
    "Invalid generic function type.",
    correctionMessage:
        "Try using a generic function type (returnType 'Function(' parameters ')').",
  );

  static const ParserErrorCode INVALID_HEX_ESCAPE = ParserErrorCode(
    'INVALID_HEX_ESCAPE',
    "An escape sequence starting with '\\x' must be followed by 2 hexadecimal digits.",
  );

  static const ParserErrorCode INVALID_INITIALIZER = ParserErrorCode(
    'INVALID_INITIALIZER',
    "Not a valid initializer.",
    correctionMessage: "To initialize a field, use the syntax 'name = value'.",
  );

  static const ParserErrorCode INVALID_LITERAL_IN_CONFIGURATION =
      ParserErrorCode(
    'INVALID_LITERAL_IN_CONFIGURATION',
    "The literal in a configuration can't contain interpolation.",
    correctionMessage: "Try removing the interpolation expressions.",
  );

  /**
   * Parameters:
   * 0: the operator that is invalid
   */
  static const ParserErrorCode INVALID_OPERATOR = ParserErrorCode(
    'INVALID_OPERATOR',
    "The string '{0}' isn't a user-definable operator.",
  );

  /**
   * Parameters:
   * 0: the operator being applied to 'super'
   *
   * Only generated by the old parser.
   * Replaced by INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER.
   */
  static const ParserErrorCode INVALID_OPERATOR_FOR_SUPER = ParserErrorCode(
    'INVALID_OPERATOR_FOR_SUPER',
    "The operator '{0}' can't be used with 'super'.",
  );

  static const ParserErrorCode INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER =
      ParserErrorCode(
    'INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER',
    "The operator '?.' cannot be used with 'super' because 'super' cannot be null.",
    correctionMessage: "Try replacing '?.' with '.'",
  );

  static const ParserErrorCode INVALID_STAR_AFTER_ASYNC = ParserErrorCode(
    'INVALID_STAR_AFTER_ASYNC',
    "The modifier 'async*' isn't allowed for an expression function body.",
    correctionMessage: "Try converting the body to a block.",
  );

  static const ParserErrorCode INVALID_SUPER_IN_INITIALIZER = ParserErrorCode(
    'INVALID_SUPER_IN_INITIALIZER',
    "Can only use 'super' in an initializer for calling the superclass constructor (e.g. 'super()' or 'super.namedConstructor()')",
  );

  static const ParserErrorCode INVALID_SYNC = ParserErrorCode(
    'INVALID_SYNC',
    "The modifier 'sync' isn't allowed for an expression function body.",
    correctionMessage: "Try converting the body to a block.",
  );

  static const ParserErrorCode INVALID_THIS_IN_INITIALIZER = ParserErrorCode(
    'INVALID_THIS_IN_INITIALIZER',
    "Can only use 'this' in an initializer for field initialization (e.g. 'this.x = something') and constructor redirection (e.g. 'this()' or 'this.namedConstructor())",
  );

  static const ParserErrorCode INVALID_UNICODE_ESCAPE = ParserErrorCode(
    'INVALID_UNICODE_ESCAPE',
    "An escape sequence starting with '\\u' must be followed by 4 hexadecimal digits or from 1 to 6 digits between '{' and '}'.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a member declared inside an
  // extension uses the keyword `covariant` in the declaration of a parameter.
  // Extensions aren't classes and don't have subclasses, so the keyword serves
  // no purpose.
  //
  // #### Example
  //
  // The following code produces this diagnostic because `i` is marked as being
  // covariant:
  //
  // ```dart
  // extension E on String {
  //   void a([!covariant!] int i) {}
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the `covariant` keyword:
  //
  // ```dart
  // extension E on String {
  //   void a(int i) {}
  // }
  // ```
  static const ParserErrorCode INVALID_USE_OF_COVARIANT_IN_EXTENSION =
      ParserErrorCode(
    'INVALID_USE_OF_COVARIANT_IN_EXTENSION',
    "Can't have modifier '{0}' in an extension.",
    correctionMessage: "Try removing '{0}'.",
    hasPublishedDocs: true,
  );

  static const ParserErrorCode LIBRARY_DIRECTIVE_NOT_FIRST = ParserErrorCode(
    'LIBRARY_DIRECTIVE_NOT_FIRST',
    "The library directive must appear before all other directives.",
    correctionMessage:
        "Try moving the library directive before any other directives.",
  );

  static const ParserErrorCode LITERAL_WITH_CLASS = ParserErrorCode(
    'LITERAL_WITH_CLASS',
    "A {0} literal can't be prefixed by '{1}'.",
    correctionMessage: "Try removing '{1}'",
  );

  static const ParserErrorCode LITERAL_WITH_CLASS_AND_NEW = ParserErrorCode(
    'LITERAL_WITH_CLASS_AND_NEW',
    "A {0} literal can't be prefixed by 'new {1}'.",
    correctionMessage: "Try removing 'new' and '{1}'",
  );

  static const ParserErrorCode LITERAL_WITH_NEW = ParserErrorCode(
    'LITERAL_WITH_NEW',
    "A literal can't be prefixed by 'new'.",
    correctionMessage: "Try removing 'new'",
  );

  static const ParserErrorCode LOCAL_FUNCTION_DECLARATION_MODIFIER =
      ParserErrorCode(
    'LOCAL_FUNCTION_DECLARATION_MODIFIER',
    "Local function declarations can't specify any modifiers.",
    correctionMessage: "Try removing the modifier.",
  );

  static const ParserErrorCode MEMBER_WITH_CLASS_NAME = ParserErrorCode(
    'MEMBER_WITH_CLASS_NAME',
    "A class member can't have the same name as the enclosing class.",
    correctionMessage: "Try renaming the member.",
  );

  static const ParserErrorCode MISSING_ASSIGNABLE_SELECTOR = ParserErrorCode(
    'MISSING_ASSIGNABLE_SELECTOR',
    "Missing selector such as '.identifier' or '[0]'.",
    correctionMessage: "Try adding a selector.",
  );

  static const ParserErrorCode MISSING_ASSIGNMENT_IN_INITIALIZER =
      ParserErrorCode(
    'MISSING_ASSIGNMENT_IN_INITIALIZER',
    "Expected an assignment after the field name.",
    correctionMessage: "To initialize a field, use the syntax 'name = value'.",
  );

  static const ParserErrorCode MISSING_CATCH_OR_FINALLY = ParserErrorCode(
    'MISSING_CATCH_OR_FINALLY',
    "A try block must be followed by an 'on', 'catch', or 'finally' clause.",
    correctionMessage:
        "Try adding either a catch or finally clause, or remove the try statement.",
  );

  static const ParserErrorCode MISSING_CLOSING_PARENTHESIS = ParserErrorCode(
    'MISSING_CLOSING_PARENTHESIS',
    "The closing parenthesis is missing.",
    correctionMessage: "Try adding the closing parenthesis.",
  );

  static const ParserErrorCode MISSING_CONST_FINAL_VAR_OR_TYPE =
      ParserErrorCode(
    'MISSING_CONST_FINAL_VAR_OR_TYPE',
    "Variables must be declared using the keywords 'const', 'final', 'var' or a type name.",
    correctionMessage:
        "Try adding the name of the type of the variable or the keyword 'var'.",
  );

  static const ParserErrorCode MISSING_ENUM_BODY = ParserErrorCode(
    'MISSING_ENUM_BODY',
    "An enum definition must have a body with at least one constant name.",
    correctionMessage: "Try adding a body and defining at least one constant.",
  );

  static const ParserErrorCode MISSING_EXPRESSION_IN_INITIALIZER =
      ParserErrorCode(
    'MISSING_EXPRESSION_IN_INITIALIZER',
    "Expected an expression after the assignment operator.",
    correctionMessage:
        "Try adding the value to be assigned, or remove the assignment operator.",
  );

  static const ParserErrorCode MISSING_EXPRESSION_IN_THROW = ParserErrorCode(
    'MISSING_EXPRESSION_IN_THROW',
    "Missing expression after 'throw'.",
    correctionMessage:
        "Add an expression after 'throw' or use 'rethrow' to throw a caught exception",
  );

  static const ParserErrorCode MISSING_FUNCTION_BODY = ParserErrorCode(
    'MISSING_FUNCTION_BODY',
    "A function body must be provided.",
    correctionMessage: "Try adding a function body.",
  );

  static const ParserErrorCode MISSING_FUNCTION_KEYWORD = ParserErrorCode(
    'MISSING_FUNCTION_KEYWORD',
    "Function types must have the keyword 'Function' before the parameter list.",
    correctionMessage: "Try adding the keyword 'Function'.",
  );

  static const ParserErrorCode MISSING_FUNCTION_PARAMETERS = ParserErrorCode(
    'MISSING_FUNCTION_PARAMETERS',
    "Functions must have an explicit list of parameters.",
    correctionMessage: "Try adding a parameter list.",
  );

  static const ParserErrorCode MISSING_GET = ParserErrorCode(
    'MISSING_GET',
    "Getters must have the keyword 'get' before the getter name.",
    correctionMessage: "Try adding the keyword 'get'.",
  );

  static const ParserErrorCode MISSING_IDENTIFIER = ParserErrorCode(
    'MISSING_IDENTIFIER',
    "Expected an identifier.",
  );

  static const ParserErrorCode MISSING_INITIALIZER = ParserErrorCode(
    'MISSING_INITIALIZER',
    "Expected an initializer.",
  );

  static const ParserErrorCode MISSING_KEYWORD_OPERATOR = ParserErrorCode(
    'MISSING_KEYWORD_OPERATOR',
    "Operator declarations must be preceded by the keyword 'operator'.",
    correctionMessage: "Try adding the keyword 'operator'.",
  );

  static const ParserErrorCode MISSING_METHOD_PARAMETERS = ParserErrorCode(
    'MISSING_METHOD_PARAMETERS',
    "Methods must have an explicit list of parameters.",
    correctionMessage: "Try adding a parameter list.",
  );

  static const ParserErrorCode MISSING_NAME_FOR_NAMED_PARAMETER =
      ParserErrorCode(
    'MISSING_NAME_FOR_NAMED_PARAMETER',
    "Named parameters in a function type must have a name",
    correctionMessage:
        "Try providing a name for the parameter or removing the curly braces.",
  );

  static const ParserErrorCode MISSING_NAME_IN_LIBRARY_DIRECTIVE =
      ParserErrorCode(
    'MISSING_NAME_IN_LIBRARY_DIRECTIVE',
    "Library directives must include a library name.",
    correctionMessage:
        "Try adding a library name after the keyword 'library', or remove the library directive if the library doesn't have any parts.",
  );

  static const ParserErrorCode MISSING_NAME_IN_PART_OF_DIRECTIVE =
      ParserErrorCode(
    'MISSING_NAME_IN_PART_OF_DIRECTIVE',
    "Part-of directives must include a library name.",
    correctionMessage: "Try adding a library name after the 'of'.",
  );

  static const ParserErrorCode MISSING_PREFIX_IN_DEFERRED_IMPORT =
      ParserErrorCode(
    'MISSING_PREFIX_IN_DEFERRED_IMPORT',
    "Deferred imports should have a prefix.",
    correctionMessage:
        "Try adding a prefix to the import by adding an 'as' clause.",
  );

  static const ParserErrorCode MISSING_STAR_AFTER_SYNC = ParserErrorCode(
    'MISSING_STAR_AFTER_SYNC',
    "The modifier 'sync' must be followed by a star ('*').",
    correctionMessage: "Try removing the modifier, or add a star.",
  );

  static const ParserErrorCode MISSING_STATEMENT = ParserErrorCode(
    'MISSING_STATEMENT',
    "Expected a statement.",
  );

  /**
   * Parameters:
   * 0: the terminator that is missing
   */
  static const ParserErrorCode MISSING_TERMINATOR_FOR_PARAMETER_GROUP =
      ParserErrorCode(
    'MISSING_TERMINATOR_FOR_PARAMETER_GROUP',
    "There is no '{0}' to close the parameter group.",
    correctionMessage: "Try inserting a '{0}' at the end of the group.",
  );

  static const ParserErrorCode MISSING_TYPEDEF_PARAMETERS = ParserErrorCode(
    'MISSING_TYPEDEF_PARAMETERS',
    "Typedefs must have an explicit list of parameters.",
    correctionMessage: "Try adding a parameter list.",
  );

  static const ParserErrorCode MISSING_VARIABLE_IN_FOR_EACH = ParserErrorCode(
    'MISSING_VARIABLE_IN_FOR_EACH',
    "A loop variable must be declared in a for-each loop before the 'in', but none was found.",
    correctionMessage: "Try declaring a loop variable.",
  );

  static const ParserErrorCode MIXED_PARAMETER_GROUPS = ParserErrorCode(
    'MIXED_PARAMETER_GROUPS',
    "Can't have both positional and named parameters in a single parameter list.",
    correctionMessage: "Try choosing a single style of optional parameters.",
  );

  static const ParserErrorCode MIXIN_DECLARES_CONSTRUCTOR = ParserErrorCode(
    'MIXIN_DECLARES_CONSTRUCTOR',
    "Mixins can't declare constructors.",
  );

  static const ParserErrorCode MODIFIER_OUT_OF_ORDER = ParserErrorCode(
    'MODIFIER_OUT_OF_ORDER',
    "The modifier '{0}' should be before the modifier '{1}'.",
    correctionMessage: "Try re-ordering the modifiers.",
  );

  static const ParserErrorCode MULTIPLE_EXTENDS_CLAUSES = ParserErrorCode(
    'MULTIPLE_EXTENDS_CLAUSES',
    "Each class definition can have at most one extends clause.",
    correctionMessage:
        "Try choosing one superclass and define your class to implement (or mix in) the others.",
  );

  static const ParserErrorCode MULTIPLE_IMPLEMENTS_CLAUSES = ParserErrorCode(
    'MULTIPLE_IMPLEMENTS_CLAUSES',
    "Each class or mixin definition can have at most one implements clause.",
    correctionMessage:
        "Try combining all of the implements clauses into a single clause.",
  );

  static const ParserErrorCode MULTIPLE_LIBRARY_DIRECTIVES = ParserErrorCode(
    'MULTIPLE_LIBRARY_DIRECTIVES',
    "Only one library directive may be declared in a file.",
    correctionMessage: "Try removing all but one of the library directives.",
  );

  static const ParserErrorCode MULTIPLE_NAMED_PARAMETER_GROUPS =
      ParserErrorCode(
    'MULTIPLE_NAMED_PARAMETER_GROUPS',
    "Can't have multiple groups of named parameters in a single parameter list.",
    correctionMessage: "Try combining all of the groups into a single group.",
  );

  static const ParserErrorCode MULTIPLE_ON_CLAUSES = ParserErrorCode(
    'MULTIPLE_ON_CLAUSES',
    "Each mixin definition can have at most one on clause.",
    correctionMessage:
        "Try combining all of the on clauses into a single clause.",
  );

  static const ParserErrorCode MULTIPLE_PART_OF_DIRECTIVES = ParserErrorCode(
    'MULTIPLE_PART_OF_DIRECTIVES',
    "Only one part-of directive may be declared in a file.",
    correctionMessage: "Try removing all but one of the part-of directives.",
  );

  static const ParserErrorCode MULTIPLE_POSITIONAL_PARAMETER_GROUPS =
      ParserErrorCode(
    'MULTIPLE_POSITIONAL_PARAMETER_GROUPS',
    "Can't have multiple groups of positional parameters in a single parameter list.",
    correctionMessage: "Try combining all of the groups into a single group.",
  );

  /**
   * Parameters:
   * 0: the number of variables being declared
   */
  static const ParserErrorCode MULTIPLE_VARIABLES_IN_FOR_EACH = ParserErrorCode(
    'MULTIPLE_VARIABLES_IN_FOR_EACH',
    "A single loop variable must be declared in a for-each loop before the 'in', but {0} were found.",
    correctionMessage:
        "Try moving all but one of the declarations inside the loop body.",
  );

  static const ParserErrorCode MULTIPLE_VARIANCE_MODIFIERS = ParserErrorCode(
    'MULTIPLE_VARIANCE_MODIFIERS',
    "Each type parameter can have at most one variance modifier.",
    correctionMessage:
        "Use at most one of the 'in', 'out', or 'inout' modifiers.",
  );

  static const ParserErrorCode MULTIPLE_WITH_CLAUSES = ParserErrorCode(
    'MULTIPLE_WITH_CLAUSES',
    "Each class definition can have at most one with clause.",
    correctionMessage:
        "Try combining all of the with clauses into a single clause.",
  );

  static const ParserErrorCode NAMED_FUNCTION_EXPRESSION = ParserErrorCode(
    'NAMED_FUNCTION_EXPRESSION',
    "Function expressions can't be named.",
    correctionMessage:
        "Try removing the name, or moving the function expression to a function declaration statement.",
  );

  static const ParserErrorCode NAMED_FUNCTION_TYPE = ParserErrorCode(
    'NAMED_FUNCTION_TYPE',
    "Function types can't be named.",
    correctionMessage: "Try replacing the name with the keyword 'Function'.",
  );

  static const ParserErrorCode NAMED_PARAMETER_OUTSIDE_GROUP = ParserErrorCode(
    'NAMED_PARAMETER_OUTSIDE_GROUP',
    "Named parameters must be enclosed in curly braces ('{' and '}').",
    correctionMessage: "Try surrounding the named parameters in curly braces.",
  );

  static const ParserErrorCode NATIVE_CLAUSE_IN_NON_SDK_CODE = ParserErrorCode(
    'NATIVE_CLAUSE_IN_NON_SDK_CODE',
    "Native clause can only be used in the SDK and code that is loaded through native extensions.",
    correctionMessage: "Try removing the native clause.",
  );

  static const ParserErrorCode NATIVE_CLAUSE_SHOULD_BE_ANNOTATION =
      ParserErrorCode(
    'NATIVE_CLAUSE_SHOULD_BE_ANNOTATION',
    "Native clause in this form is deprecated.",
    correctionMessage:
        "Try removing this native clause and adding @native() or @native('native-name') before the declaration.",
  );

  static const ParserErrorCode NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE =
      ParserErrorCode(
    'NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE',
    "Native functions can only be declared in the SDK and code that is loaded through native extensions.",
    correctionMessage: "Try removing the word 'native'.",
  );

  static const ParserErrorCode NON_CONSTRUCTOR_FACTORY = ParserErrorCode(
    'NON_CONSTRUCTOR_FACTORY',
    "Only a constructor can be declared to be a factory.",
    correctionMessage: "Try removing the keyword 'factory'.",
  );

  static const ParserErrorCode NON_IDENTIFIER_LIBRARY_NAME = ParserErrorCode(
    'NON_IDENTIFIER_LIBRARY_NAME',
    "The name of a library must be an identifier.",
    correctionMessage: "Try using an identifier as the name of the library.",
  );

  static const ParserErrorCode NON_PART_OF_DIRECTIVE_IN_PART = ParserErrorCode(
    'NON_PART_OF_DIRECTIVE_IN_PART',
    "The part-of directive must be the only directive in a part.",
    correctionMessage:
        "Try removing the other directives, or moving them to the library for which this is a part.",
  );

  static const ParserErrorCode NON_STRING_LITERAL_AS_URI = ParserErrorCode(
    'NON_STRING_LITERAL_AS_URI',
    "The URI must be a string literal.",
    correctionMessage:
        "Try enclosing the URI in either single or double quotes.",
  );

  /**
   * Parameters:
   * 0: the operator that the user is trying to define
   */
  static const ParserErrorCode NON_USER_DEFINABLE_OPERATOR = ParserErrorCode(
    'NON_USER_DEFINABLE_OPERATOR',
    "The operator '{0}' isn't user definable.",
  );

  static const ParserErrorCode NORMAL_BEFORE_OPTIONAL_PARAMETERS =
      ParserErrorCode(
    'NORMAL_BEFORE_OPTIONAL_PARAMETERS',
    "Normal parameters must occur before optional parameters.",
    correctionMessage:
        "Try moving all of the normal parameters before the optional parameters.",
  );

  static const ParserErrorCode NULL_AWARE_CASCADE_OUT_OF_ORDER =
      ParserErrorCode(
    'NULL_AWARE_CASCADE_OUT_OF_ORDER',
    "The '?..' cascade operator must be first in the cascade sequence.",
    correctionMessage:
        "Try moving the '?..' operator to be the first cascade operator in the sequence.",
  );

  static const ParserErrorCode POSITIONAL_AFTER_NAMED_ARGUMENT =
      ParserErrorCode(
    'POSITIONAL_AFTER_NAMED_ARGUMENT',
    "Positional arguments must occur before named arguments.",
    correctionMessage:
        "Try moving all of the positional arguments before the named arguments.",
  );

  static const ParserErrorCode POSITIONAL_PARAMETER_OUTSIDE_GROUP =
      ParserErrorCode(
    'POSITIONAL_PARAMETER_OUTSIDE_GROUP',
    "Positional parameters must be enclosed in square brackets ('[' and ']').",
    correctionMessage:
        "Try surrounding the positional parameters in square brackets.",
  );

  static const ParserErrorCode PREFIX_AFTER_COMBINATOR = ParserErrorCode(
    'PREFIX_AFTER_COMBINATOR',
    "The prefix ('as' clause) should come before any show/hide combinators.",
    correctionMessage: "Try moving the prefix before the combinators.",
  );

  static const ParserErrorCode REDIRECTING_CONSTRUCTOR_WITH_BODY =
      ParserErrorCode(
    'REDIRECTING_CONSTRUCTOR_WITH_BODY',
    "Redirecting constructors can't have a body.",
    correctionMessage:
        "Try removing the body, or not making this a redirecting constructor.",
  );

  static const ParserErrorCode REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR =
      ParserErrorCode(
    'REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR',
    "Only factory constructor can specify '=' redirection.",
    correctionMessage:
        "Try making this a factory constructor, or remove the redirection.",
  );

  static const ParserErrorCode SETTER_CONSTRUCTOR = ParserErrorCode(
    'SETTER_CONSTRUCTOR',
    "Constructors can't be a setter.",
    correctionMessage: "Try removing 'set'.",
  );

  static const ParserErrorCode SETTER_IN_FUNCTION = ParserErrorCode(
    'SETTER_IN_FUNCTION',
    "Setters can't be defined within methods or functions.",
    correctionMessage: "Try moving the setter outside the method or function.",
  );

  static const ParserErrorCode STACK_OVERFLOW = ParserErrorCode(
    'STACK_OVERFLOW',
    "The file has too many nested expressions or statements.",
    correctionMessage: "Try simplifying the code.",
  );

  static const ParserErrorCode STATIC_CONSTRUCTOR = ParserErrorCode(
    'STATIC_CONSTRUCTOR',
    "Constructors can't be static.",
    correctionMessage: "Try removing the keyword 'static'.",
  );

  static const ParserErrorCode STATIC_GETTER_WITHOUT_BODY = ParserErrorCode(
    'STATIC_GETTER_WITHOUT_BODY',
    "A 'static' getter must have a body.",
    correctionMessage:
        "Try adding a body to the getter, or removing the keyword 'static'.",
  );

  static const ParserErrorCode STATIC_OPERATOR = ParserErrorCode(
    'STATIC_OPERATOR',
    "Operators can't be static.",
    correctionMessage: "Try removing the keyword 'static'.",
  );

  static const ParserErrorCode STATIC_SETTER_WITHOUT_BODY = ParserErrorCode(
    'STATIC_SETTER_WITHOUT_BODY',
    "A 'static' setter must have a body.",
    correctionMessage:
        "Try adding a body to the setter, or removing the keyword 'static'.",
  );

  static const ParserErrorCode STATIC_TOP_LEVEL_DECLARATION = ParserErrorCode(
    'STATIC_TOP_LEVEL_DECLARATION',
    "Top-level declarations can't be declared to be static.",
    correctionMessage: "Try removing the keyword 'static'.",
  );

  static const ParserErrorCode SWITCH_HAS_CASE_AFTER_DEFAULT_CASE =
      ParserErrorCode(
    'SWITCH_HAS_CASE_AFTER_DEFAULT_CASE',
    "The default case should be the last case in a switch statement.",
    correctionMessage:
        "Try moving the default case after the other case clauses.",
  );

  static const ParserErrorCode SWITCH_HAS_MULTIPLE_DEFAULT_CASES =
      ParserErrorCode(
    'SWITCH_HAS_MULTIPLE_DEFAULT_CASES',
    "The 'default' case can only be declared once.",
    correctionMessage: "Try removing all but one default case.",
  );

  static const ParserErrorCode TOP_LEVEL_OPERATOR = ParserErrorCode(
    'TOP_LEVEL_OPERATOR',
    "Operators must be declared within a class.",
    correctionMessage:
        "Try removing the operator, moving it to a class, or converting it to be a function.",
  );

  static const ParserErrorCode TYPEDEF_IN_CLASS = ParserErrorCode(
    'TYPEDEF_IN_CLASS',
    "Typedefs can't be declared inside classes.",
    correctionMessage: "Try moving the typedef to the top-level.",
  );

  static const ParserErrorCode TYPE_ARGUMENTS_ON_TYPE_VARIABLE =
      ParserErrorCode(
    'TYPE_ARGUMENTS_ON_TYPE_VARIABLE',
    "Can't use type arguments with type variable '{0}'.",
    correctionMessage: "Try removing the type arguments.",
  );

  static const ParserErrorCode TYPE_BEFORE_FACTORY = ParserErrorCode(
    'TYPE_BEFORE_FACTORY',
    "Factory constructors cannot have a return type.",
    correctionMessage: "Try removing the type appearing before 'factory'.",
  );

  static const ParserErrorCode TYPE_PARAMETER_ON_CONSTRUCTOR = ParserErrorCode(
    'TYPE_PARAMETER_ON_CONSTRUCTOR',
    "Constructors can't have type parameters.",
    correctionMessage: "Try removing the type parameters.",
  );

  /**
   * 7.1.1 Operators: Type parameters are not syntactically supported on an
   * operator.
   */
  static const ParserErrorCode TYPE_PARAMETER_ON_OPERATOR = ParserErrorCode(
    'TYPE_PARAMETER_ON_OPERATOR',
    "Types parameters aren't allowed when defining an operator.",
    correctionMessage: "Try removing the type parameters.",
  );

  /**
   * Parameters:
   * 0: the starting character that was missing
   */
  static const ParserErrorCode UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP =
      ParserErrorCode(
    'UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP',
    "There is no '{0}' to open a parameter group.",
    correctionMessage: "Try inserting the '{0}' at the appropriate location.",
  );

  /**
   * Parameters:
   * 0: the unexpected text that was found
   */
  static const ParserErrorCode UNEXPECTED_TOKEN = ParserErrorCode(
    'UNEXPECTED_TOKEN',
    "Unexpected text '{0}'.",
    correctionMessage: "Try removing the text.",
  );

  static const ParserErrorCode VAR_AND_TYPE = ParserErrorCode(
    'VAR_AND_TYPE',
    "Variables can't be declared using both 'var' and a type name.",
    correctionMessage: "Try removing 'var.'",
  );

  static const ParserErrorCode VAR_AS_TYPE_NAME = ParserErrorCode(
    'VAR_AS_TYPE_NAME',
    "The keyword 'var' can't be used as a type name.",
  );

  static const ParserErrorCode VAR_CLASS = ParserErrorCode(
    'VAR_CLASS',
    "Classes can't be declared to be 'var'.",
    correctionMessage: "Try removing the keyword 'var'.",
  );

  static const ParserErrorCode VAR_ENUM = ParserErrorCode(
    'VAR_ENUM',
    "Enums can't be declared to be 'var'.",
    correctionMessage: "Try removing the keyword 'var'.",
  );

  static const ParserErrorCode VAR_RETURN_TYPE = ParserErrorCode(
    'VAR_RETURN_TYPE',
    "The return type can't be 'var'.",
    correctionMessage:
        "Try removing the keyword 'var', or replacing it with the name of the return type.",
  );

  static const ParserErrorCode VAR_TYPEDEF = ParserErrorCode(
    'VAR_TYPEDEF',
    "Typedefs can't be declared to be 'var'.",
    correctionMessage:
        "Try removing the keyword 'var', or replacing it with the name of the return type.",
  );

  static const ParserErrorCode VOID_WITH_TYPE_ARGUMENTS = ParserErrorCode(
    'VOID_WITH_TYPE_ARGUMENTS',
    "Type 'void' can't have type arguments.",
    correctionMessage: "Try removing the type arguments.",
  );

  static const ParserErrorCode WITH_BEFORE_EXTENDS = ParserErrorCode(
    'WITH_BEFORE_EXTENDS',
    "The extends clause must be before the with clause.",
    correctionMessage: "Try moving the extends clause before the with clause.",
  );

  static const ParserErrorCode WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER =
      ParserErrorCode(
    'WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER',
    "The default value of a positional parameter should be preceded by '='.",
    correctionMessage: "Try replacing the ':' with '='.",
  );

  /**
   * Parameters:
   * 0: the terminator that was expected
   * 1: the terminator that was found
   */
  static const ParserErrorCode WRONG_TERMINATOR_FOR_PARAMETER_GROUP =
      ParserErrorCode(
    'WRONG_TERMINATOR_FOR_PARAMETER_GROUP',
    "Expected '{0}' to close parameter group.",
    correctionMessage: "Try replacing '{0}' with '{1}'.",
  );

  /// Initialize a newly created error code to have the given [name].
  const ParserErrorCode(
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
          uniqueName: 'ParserErrorCode.${uniqueName ?? name}',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.SYNTACTIC_ERROR;
}
