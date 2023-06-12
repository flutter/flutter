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

class FfiCode extends AnalyzerErrorCode {
  /**
   * No parameters.
   */
  static const FfiCode ANNOTATION_ON_POINTER_FIELD = FfiCode(
    'ANNOTATION_ON_POINTER_FIELD',
    "Fields in a struct class whose type is 'Pointer' should not have any annotations.",
    correctionMessage: "Try removing the annotation.",
  );

  /**
   * Parameters:
   * 0: the name of the argument
   */
  static const FfiCode ARGUMENT_MUST_BE_A_CONSTANT = FfiCode(
    'ARGUMENT_MUST_BE_A_CONSTANT',
    "Argument '{0}' must be a constant.",
    correctionMessage: "Try replacing the value with a literal or const.",
  );

  /**
   * No parameters.
   */
  static const FfiCode CREATION_OF_STRUCT_OR_UNION = FfiCode(
    'CREATION_OF_STRUCT_OR_UNION',
    "Subclasses of 'Struct' and 'Union' are backed by native memory, and can't be instantiated by a generative constructor.",
    correctionMessage:
        "Try allocating it via allocation, or load from a 'Pointer'.",
  );

  /**
   * Parameters:
   * 0: the name of the subclass
   * 1: the name of the superclass
   */
  static const FfiCode EMPTY_STRUCT = FfiCode(
    'EMPTY_STRUCT',
    "The class '{0}' can’t be empty because it's a subclass of '{1}'.",
    correctionMessage:
        "Try adding a field to '{0}' or use a different superclass.",
  );

  /**
   * No parameters.
   */
  static const FfiCode EXTRA_ANNOTATION_ON_STRUCT_FIELD = FfiCode(
    'EXTRA_ANNOTATION_ON_STRUCT_FIELD',
    "Fields in a struct class must have exactly one annotation indicating the native type.",
    correctionMessage: "Try removing the extra annotation.",
  );

  /**
   * No parameters.
   */
  static const FfiCode EXTRA_SIZE_ANNOTATION_CARRAY = FfiCode(
    'EXTRA_SIZE_ANNOTATION_CARRAY',
    "'Array's must have exactly one 'Array' annotation.",
    correctionMessage: "Try removing the extra annotation.",
  );

  /**
   * No parameters.
   */
  static const FfiCode FFI_NATIVE_MUST_BE_EXTERNAL = FfiCode(
    'FFI_NATIVE_MUST_BE_EXTERNAL',
    "FfiNative functions must be declared external.",
    correctionMessage: "Add the `external` keyword to the function.",
  );

  /**
   * No parameters.
   */
  static const FfiCode
      FFI_NATIVE_ONLY_CLASSES_EXTENDING_NATIVEFIELDWRAPPERCLASS1_CAN_BE_POINTER =
      FfiCode(
    'FFI_NATIVE_ONLY_CLASSES_EXTENDING_NATIVEFIELDWRAPPERCLASS1_CAN_BE_POINTER',
    "Only classes extending NativeFieldWrapperClass1 can be passed as Pointer.",
    correctionMessage: "Pass as Handle instead.",
  );

  /**
   * Parameters:
   * 0: the expected number of parameters
   * 1: the actual number of parameters
   */
  static const FfiCode FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS = FfiCode(
    'FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS',
    "Unexpected number of FfiNative annotation parameters. Expected {0} but has {1}.",
    correctionMessage: "Make sure parameters match the function annotated.",
  );

  /**
   * Parameters:
   * 0: the expected number of parameters
   * 1: the actual number of parameters
   */
  static const FfiCode
      FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS_WITH_RECEIVER = FfiCode(
    'FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS_WITH_RECEIVER',
    "Unexpected number of FfiNative annotation parameters. Expected {0} but has {1}. FfiNative instance method annotation must have receiver as first argument.",
    correctionMessage:
        "Make sure parameters match the function annotated, including an extra first parameter for the receiver.",
  );

  /**
   * No parameters.
   */
  static const FfiCode FIELD_INITIALIZER_IN_STRUCT = FfiCode(
    'FIELD_INITIALIZER_IN_STRUCT',
    "Constructors in subclasses of 'Struct' and 'Union' can't have field initializers.",
    correctionMessage:
        "Try removing the field initializer and marking the field as external.",
  );

  /**
   * No parameters.
   */
  static const FfiCode FIELD_IN_STRUCT_WITH_INITIALIZER = FfiCode(
    'FIELD_IN_STRUCT_WITH_INITIALIZER',
    "Fields in subclasses of 'Struct' and 'Union' can't have initializers.",
    correctionMessage:
        "Try removing the initializer and marking the field as external.",
  );

  /**
   * No parameters.
   */
  static const FfiCode FIELD_MUST_BE_EXTERNAL_IN_STRUCT = FfiCode(
    'FIELD_MUST_BE_EXTERNAL_IN_STRUCT',
    "Fields of 'Struct' and 'Union' subclasses must be marked external.",
    correctionMessage: "Try adding the 'external' modifier.",
  );

  /**
   * Parameters:
   * 0: the name of the struct class
   */
  static const FfiCode GENERIC_STRUCT_SUBCLASS = FfiCode(
    'GENERIC_STRUCT_SUBCLASS',
    "The class '{0}' can't extend 'Struct' or 'Union' because it is generic.",
    correctionMessage: "Try removing the type parameters from '{0}'.",
  );

  /**
   * No parameters.
   */
  static const FfiCode INVALID_EXCEPTION_VALUE = FfiCode(
    'INVALID_EXCEPTION_VALUE',
    "The method 'Pointer.fromFunction' must not have an exceptional return value (the second argument) when the return type of the function is either 'void', 'Handle' or 'Pointer'.",
    correctionMessage: "Try removing the exceptional return value.",
  );

  /**
   * Parameters:
   * 0: the type of the field
   */
  static const FfiCode INVALID_FIELD_TYPE_IN_STRUCT = FfiCode(
    'INVALID_FIELD_TYPE_IN_STRUCT',
    "Fields in struct classes can't have the type '{0}'. They can only be declared as 'int', 'double', 'Array', 'Pointer', or subtype of 'Struct' or 'Union'.",
    correctionMessage:
        "Try using 'int', 'double', 'Array', 'Pointer', or subtype of 'Struct' or 'Union'.",
  );

  /**
   * No parameters.
   */
  static const FfiCode LEAF_CALL_MUST_NOT_RETURN_HANDLE = FfiCode(
    'LEAF_CALL_MUST_NOT_RETURN_HANDLE',
    "FFI leaf call must not return a Handle.",
    correctionMessage: "Try changing the return type to primitive or struct.",
  );

  /**
   * No parameters.
   */
  static const FfiCode LEAF_CALL_MUST_NOT_TAKE_HANDLE = FfiCode(
    'LEAF_CALL_MUST_NOT_TAKE_HANDLE',
    "FFI leaf call must not take arguments of type Handle.",
    correctionMessage: "Try changing the argument type to primitive or struct.",
  );

  /**
   * No parameters.
   */
  static const FfiCode MISMATCHED_ANNOTATION_ON_STRUCT_FIELD = FfiCode(
    'MISMATCHED_ANNOTATION_ON_STRUCT_FIELD',
    "The annotation does not match the declared type of the field.",
    correctionMessage:
        "Try using a different annotation or changing the declared type to match.",
  );

  /**
   * No parameters.
   */
  static const FfiCode MISSING_ANNOTATION_ON_STRUCT_FIELD = FfiCode(
    'MISSING_ANNOTATION_ON_STRUCT_FIELD',
    "Fields in a struct class must either have the type 'Pointer' or an annotation indicating the native type.",
    correctionMessage: "Try adding an annotation.",
  );

  /**
   * No parameters.
   */
  static const FfiCode MISSING_EXCEPTION_VALUE = FfiCode(
    'MISSING_EXCEPTION_VALUE',
    "The method 'Pointer.fromFunction' must have an exceptional return value (the second argument) when the return type of the function is neither 'void', 'Handle' or 'Pointer'.",
    correctionMessage: "Try adding an exceptional return value.",
  );

  /**
   * Parameters:
   * 0: the type of the field
   */
  static const FfiCode MISSING_FIELD_TYPE_IN_STRUCT = FfiCode(
    'MISSING_FIELD_TYPE_IN_STRUCT',
    "Fields in struct classes must have an explicitly declared type of 'int', 'double' or 'Pointer'.",
    correctionMessage: "Try using 'int', 'double' or 'Pointer'.",
  );

  /**
   * No parameters.
   */
  static const FfiCode MISSING_SIZE_ANNOTATION_CARRAY = FfiCode(
    'MISSING_SIZE_ANNOTATION_CARRAY',
    "'Array's must have exactly one 'Array' annotation.",
    correctionMessage: "Try adding a 'Array' annotation.",
  );

  /**
   * Parameters:
   * 0: the type that should be a valid dart:ffi native type.
   * 1: the name of the function whose invocation depends on this relationship
   */
  static const FfiCode MUST_BE_A_NATIVE_FUNCTION_TYPE = FfiCode(
    'MUST_BE_A_NATIVE_FUNCTION_TYPE',
    "The type '{0}' given to '{1}' must be a valid 'dart:ffi' native function type.",
    correctionMessage:
        "Try changing the type to only use members for 'dart:ffi'.",
  );

  /**
   * Parameters:
   * 0: the type that should be a subtype
   * 1: the supertype that the subtype is compared to
   * 2: the name of the function whose invocation depends on this relationship
   */
  static const FfiCode MUST_BE_A_SUBTYPE = FfiCode(
    'MUST_BE_A_SUBTYPE',
    "The type '{0}' must be a subtype of '{1}' for '{2}'.",
    correctionMessage: "Try changing one or both of the type arguments.",
  );

  /**
   * Parameters:
   * 0: the name of the function, method, or constructor having type arguments
   */
  static const FfiCode NON_CONSTANT_TYPE_ARGUMENT = FfiCode(
    'NON_CONSTANT_TYPE_ARGUMENT',
    "The type arguments to '{0}' must be compile time constants but type parameters are not constants.",
    correctionMessage: "Try changing the type argument to be a constant type.",
  );

  /**
   * Parameters:
   * 0: the type that should be a valid dart:ffi native type.
   */
  static const FfiCode NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER = FfiCode(
    'NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER',
    "The type argument for the pointer '{0}' must be a valid 'NativeFunction' in order to use 'asFunction'.",
    correctionMessage:
        "Try changing the function argument in 'NativeFunction' to only use NativeTypes.",
  );

  /**
   * No parameters.
   */
  static const FfiCode NON_POSITIVE_ARRAY_DIMENSION = FfiCode(
    'NON_POSITIVE_ARRAY_DIMENSION',
    "Array dimensions must be positive numbers.",
    correctionMessage: "Try changing the input to a positive number.",
  );

  /**
   * Parameters:
   * 0: the type of the field
   */
  static const FfiCode NON_SIZED_TYPE_ARGUMENT = FfiCode(
    'NON_SIZED_TYPE_ARGUMENT',
    "Type arguments to '{0}' can't have the type '{1}'. They can only be declared as native integer, 'Float', 'Double', 'Pointer', or subtype of 'Struct' or 'Union'.",
    correctionMessage:
        "Try using a native integer, 'Float', 'Double', 'Pointer', or subtype of 'Struct' or 'Union'.",
  );

  /**
   * No parameters.
   */
  static const FfiCode PACKED_ANNOTATION = FfiCode(
    'PACKED_ANNOTATION',
    "Structs must have at most one 'Packed' annotation.",
    correctionMessage: "Try removing extra 'Packed' annotations.",
  );

  /**
   * No parameters.
   */
  static const FfiCode PACKED_ANNOTATION_ALIGNMENT = FfiCode(
    'PACKED_ANNOTATION_ALIGNMENT',
    "Only packing to 1, 2, 4, 8, and 16 bytes is supported.",
    correctionMessage:
        "Try changing the 'Packed' annotation alignment to 1, 2, 4, 8, or 16.",
  );

  /**
   * Parameters:
   * 0: the name of the outer struct
   * 1: the name of the struct being nested
   */
  static const FfiCode PACKED_NESTING_NON_PACKED = FfiCode(
    'PACKED_NESTING_NON_PACKED',
    "Nesting the non-packed or less tightly packed struct '{0}' in a packed struct '{1}' is not supported.",
    correctionMessage:
        "Try packing the nested struct or packing the nested struct more tightly.",
  );

  /**
   * No parameters.
   */
  static const FfiCode SIZE_ANNOTATION_DIMENSIONS = FfiCode(
    'SIZE_ANNOTATION_DIMENSIONS',
    "'Array's must have an 'Array' annotation that matches the dimensions.",
    correctionMessage: "Try adjusting the arguments in the 'Array' annotation.",
  );

  /**
   * Parameters:
   * 0: the name of the subclass
   * 1: the name of the class being extended, implemented, or mixed in
   */
  static const FfiCode SUBTYPE_OF_FFI_CLASS_IN_EXTENDS = FfiCode(
    'SUBTYPE_OF_FFI_CLASS',
    "The class '{0}' can't extend '{1}'.",
    correctionMessage: "Try extending 'Struct' or 'Union'.",
    uniqueName: 'SUBTYPE_OF_FFI_CLASS_IN_EXTENDS',
  );

  /**
   * Parameters:
   * 0: the name of the subclass
   * 1: the name of the class being extended, implemented, or mixed in
   */
  static const FfiCode SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS = FfiCode(
    'SUBTYPE_OF_FFI_CLASS',
    "The class '{0}' can't implement '{1}'.",
    correctionMessage: "Try extending 'Struct' or 'Union'.",
    uniqueName: 'SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS',
  );

  /**
   * Parameters:
   * 0: the name of the subclass
   * 1: the name of the class being extended, implemented, or mixed in
   */
  static const FfiCode SUBTYPE_OF_FFI_CLASS_IN_WITH = FfiCode(
    'SUBTYPE_OF_FFI_CLASS',
    "The class '{0}' can't mix in '{1}'.",
    correctionMessage: "Try extending 'Struct' or 'Union'.",
    uniqueName: 'SUBTYPE_OF_FFI_CLASS_IN_WITH',
  );

  /**
   * Parameters:
   * 0: the name of the subclass
   * 1: the name of the class being extended, implemented, or mixed in
   */
  static const FfiCode SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS = FfiCode(
    'SUBTYPE_OF_STRUCT_CLASS',
    "The class '{0}' can't extend '{1}' because '{1}' is a subtype of 'Struct' or 'Union'.",
    correctionMessage: "Try extending 'Struct' or 'Union' directly.",
    uniqueName: 'SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS',
  );

  /**
   * Parameters:
   * 0: the name of the subclass
   * 1: the name of the class being extended, implemented, or mixed in
   */
  static const FfiCode SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS = FfiCode(
    'SUBTYPE_OF_STRUCT_CLASS',
    "The class '{0}' can't implement '{1}' because '{1}' is a subtype of 'Struct' or 'Union'.",
    correctionMessage: "Try extending 'Struct' or 'Union' directly.",
    uniqueName: 'SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS',
  );

  /**
   * Parameters:
   * 0: the name of the subclass
   * 1: the name of the class being extended, implemented, or mixed in
   */
  static const FfiCode SUBTYPE_OF_STRUCT_CLASS_IN_WITH = FfiCode(
    'SUBTYPE_OF_STRUCT_CLASS',
    "The class '{0}' can't mix in '{1}' because '{1}' is a subtype of 'Struct' or 'Union'.",
    correctionMessage: "Try extending 'Struct' or 'Union' directly.",
    uniqueName: 'SUBTYPE_OF_STRUCT_CLASS_IN_WITH',
  );

  /// Initialize a newly created error code to have the given [name].
  const FfiCode(
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
          uniqueName: 'FfiCode.${uniqueName ?? name}',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorType.COMPILE_TIME_ERROR.severity;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;
}
