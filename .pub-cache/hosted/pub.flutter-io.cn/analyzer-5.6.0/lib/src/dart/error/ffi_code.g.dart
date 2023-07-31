// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

// We allow some snake_case and SCREAMING_SNAKE_CASE identifiers in generated
// code, as they match names declared in the source configuration files.
// ignore_for_file: constant_identifier_names

import "package:analyzer/error/error.dart";
import "package:analyzer/src/error/analyzer_error_code.dart";

class FfiCode extends AnalyzerErrorCode {
  ///  No parameters.
  static const FfiCode ABI_SPECIFIC_INTEGER_INVALID = FfiCode(
    'ABI_SPECIFIC_INTEGER_INVALID',
    "Classes extending 'AbiSpecificInteger' must have exactly one const "
        "constructor, no other members, and no type parameters.",
    correctionMessage:
        "Try removing all type parameters, removing all members, and adding "
        "one const constructor.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const FfiCode ABI_SPECIFIC_INTEGER_MAPPING_EXTRA = FfiCode(
    'ABI_SPECIFIC_INTEGER_MAPPING_EXTRA',
    "Classes extending 'AbiSpecificInteger' must have exactly one "
        "'AbiSpecificIntegerMapping' annotation specifying the mapping from "
        "ABI to a 'NativeType' integer with a fixed size.",
    correctionMessage: "Try removing the extra annotation.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const FfiCode ABI_SPECIFIC_INTEGER_MAPPING_MISSING = FfiCode(
    'ABI_SPECIFIC_INTEGER_MAPPING_MISSING',
    "Classes extending 'AbiSpecificInteger' must have exactly one "
        "'AbiSpecificIntegerMapping' annotation specifying the mapping from "
        "ABI to a 'NativeType' integer with a fixed size.",
    correctionMessage: "Try adding an annotation.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the value of the invalid mapping
  static const FfiCode ABI_SPECIFIC_INTEGER_MAPPING_UNSUPPORTED = FfiCode(
    'ABI_SPECIFIC_INTEGER_MAPPING_UNSUPPORTED',
    "Invalid mapping to '{0}'; only mappings to 'Int8', 'Int16', 'Int32', "
        "'Int64', 'Uint8', 'Uint16', 'UInt32', and 'Uint64' are supported.",
    correctionMessage:
        "Try changing the value to 'Int8', 'Int16', 'Int32', 'Int64', 'Uint8', "
        "'Uint16', 'UInt32', or 'Uint64'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const FfiCode ANNOTATION_ON_POINTER_FIELD = FfiCode(
    'ANNOTATION_ON_POINTER_FIELD',
    "Fields in a struct class whose type is 'Pointer' shouldn't have any "
        "annotations.",
    correctionMessage: "Try removing the annotation.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the argument
  static const FfiCode ARGUMENT_MUST_BE_A_CONSTANT = FfiCode(
    'ARGUMENT_MUST_BE_A_CONSTANT',
    "Argument '{0}' must be a constant.",
    correctionMessage: "Try replacing the value with a literal or const.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the struct or union class
  static const FfiCode COMPOUND_IMPLEMENTS_FINALIZABLE = FfiCode(
    'COMPOUND_IMPLEMENTS_FINALIZABLE',
    "The class '{0}' can't implement Finalizable.",
    correctionMessage: "Try removing the implements clause from '{0}'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const FfiCode CREATION_OF_STRUCT_OR_UNION = FfiCode(
    'CREATION_OF_STRUCT_OR_UNION',
    "Subclasses of 'Struct' and 'Union' are backed by native memory, and can't "
        "be instantiated by a generative constructor.",
    correctionMessage:
        "Try allocating it via allocation, or load from a 'Pointer'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the subclass
  ///  1: the name of the superclass
  static const FfiCode EMPTY_STRUCT = FfiCode(
    'EMPTY_STRUCT',
    "The class '{0}' can't be empty because it's a subclass of '{1}'.",
    correctionMessage:
        "Try adding a field to '{0}' or use a different superclass.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const FfiCode EXTRA_ANNOTATION_ON_STRUCT_FIELD = FfiCode(
    'EXTRA_ANNOTATION_ON_STRUCT_FIELD',
    "Fields in a struct class must have exactly one annotation indicating the "
        "native type.",
    correctionMessage: "Try removing the extra annotation.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const FfiCode EXTRA_SIZE_ANNOTATION_CARRAY = FfiCode(
    'EXTRA_SIZE_ANNOTATION_CARRAY',
    "'Array's must have exactly one 'Array' annotation.",
    correctionMessage: "Try removing the extra annotation.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const FfiCode FFI_NATIVE_MUST_BE_EXTERNAL = FfiCode(
    'FFI_NATIVE_MUST_BE_EXTERNAL',
    "FfiNative functions must be declared external.",
    correctionMessage: "Add the `external` keyword to the function.",
  );

  ///  No parameters.
  static const FfiCode
      FFI_NATIVE_ONLY_CLASSES_EXTENDING_NATIVEFIELDWRAPPERCLASS1_CAN_BE_POINTER =
      FfiCode(
    'FFI_NATIVE_ONLY_CLASSES_EXTENDING_NATIVEFIELDWRAPPERCLASS1_CAN_BE_POINTER',
    "Only classes extending NativeFieldWrapperClass1 can be passed as Pointer.",
    correctionMessage: "Pass as Handle instead.",
  );

  ///  Parameters:
  ///  0: the expected number of parameters
  ///  1: the actual number of parameters
  static const FfiCode FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS = FfiCode(
    'FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS',
    "Unexpected number of FfiNative annotation parameters. Expected {0} but "
        "has {1}.",
    correctionMessage: "Make sure parameters match the function annotated.",
  );

  ///  Parameters:
  ///  0: the expected number of parameters
  ///  1: the actual number of parameters
  static const FfiCode
      FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS_WITH_RECEIVER = FfiCode(
    'FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS_WITH_RECEIVER',
    "Unexpected number of FfiNative annotation parameters. Expected {0} but "
        "has {1}. FfiNative instance method annotation must have receiver as "
        "first argument.",
    correctionMessage:
        "Make sure parameters match the function annotated, including an extra "
        "first parameter for the receiver.",
  );

  ///  No parameters.
  static const FfiCode FIELD_INITIALIZER_IN_STRUCT = FfiCode(
    'FIELD_INITIALIZER_IN_STRUCT',
    "Constructors in subclasses of 'Struct' and 'Union' can't have field "
        "initializers.",
    correctionMessage:
        "Try removing the field initializer and marking the field as external.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const FfiCode FIELD_IN_STRUCT_WITH_INITIALIZER = FfiCode(
    'FIELD_IN_STRUCT_WITH_INITIALIZER',
    "Fields in subclasses of 'Struct' and 'Union' can't have initializers.",
    correctionMessage:
        "Try removing the initializer and marking the field as external.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const FfiCode FIELD_MUST_BE_EXTERNAL_IN_STRUCT = FfiCode(
    'FIELD_MUST_BE_EXTERNAL_IN_STRUCT',
    "Fields of 'Struct' and 'Union' subclasses must be marked external.",
    correctionMessage: "Try adding the 'external' modifier.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the struct class
  static const FfiCode GENERIC_STRUCT_SUBCLASS = FfiCode(
    'GENERIC_STRUCT_SUBCLASS',
    "The class '{0}' can't extend 'Struct' or 'Union' because '{0}' is "
        "generic.",
    correctionMessage: "Try removing the type parameters from '{0}'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const FfiCode INVALID_EXCEPTION_VALUE = FfiCode(
    'INVALID_EXCEPTION_VALUE',
    "The method 'Pointer.fromFunction' can't have an exceptional return value "
        "(the second argument) when the return type of the function is either "
        "'void', 'Handle' or 'Pointer'.",
    correctionMessage: "Try removing the exceptional return value.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the type of the field
  static const FfiCode INVALID_FIELD_TYPE_IN_STRUCT = FfiCode(
    'INVALID_FIELD_TYPE_IN_STRUCT',
    "Fields in struct classes can't have the type '{0}'. They can only be "
        "declared as 'int', 'double', 'Array', 'Pointer', or subtype of "
        "'Struct' or 'Union'.",
    correctionMessage:
        "Try using 'int', 'double', 'Array', 'Pointer', or subtype of 'Struct' "
        "or 'Union'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const FfiCode LEAF_CALL_MUST_NOT_RETURN_HANDLE = FfiCode(
    'LEAF_CALL_MUST_NOT_RETURN_HANDLE',
    "FFI leaf call can't return a 'Handle'.",
    correctionMessage: "Try changing the return type to primitive or struct.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const FfiCode LEAF_CALL_MUST_NOT_TAKE_HANDLE = FfiCode(
    'LEAF_CALL_MUST_NOT_TAKE_HANDLE',
    "FFI leaf call can't take arguments of type 'Handle'.",
    correctionMessage: "Try changing the argument type to primitive or struct.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const FfiCode MISMATCHED_ANNOTATION_ON_STRUCT_FIELD = FfiCode(
    'MISMATCHED_ANNOTATION_ON_STRUCT_FIELD',
    "The annotation doesn't match the declared type of the field.",
    correctionMessage:
        "Try using a different annotation or changing the declared type to "
        "match.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the type that is missing a native type annotation
  ///  1: the superclass which is extended by this field's class
  static const FfiCode MISSING_ANNOTATION_ON_STRUCT_FIELD = FfiCode(
    'MISSING_ANNOTATION_ON_STRUCT_FIELD',
    "Fields of type '{0}' in a subclass of '{1}' must have an annotation "
        "indicating the native type.",
    correctionMessage: "Try adding an annotation.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const FfiCode MISSING_EXCEPTION_VALUE = FfiCode(
    'MISSING_EXCEPTION_VALUE',
    "The method 'Pointer.fromFunction' must have an exceptional return value "
        "(the second argument) when the return type of the function is neither "
        "'void', 'Handle', nor 'Pointer'.",
    correctionMessage: "Try adding an exceptional return value.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const FfiCode MISSING_FIELD_TYPE_IN_STRUCT = FfiCode(
    'MISSING_FIELD_TYPE_IN_STRUCT',
    "Fields in struct classes must have an explicitly declared type of 'int', "
        "'double' or 'Pointer'.",
    correctionMessage: "Try using 'int', 'double' or 'Pointer'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const FfiCode MISSING_SIZE_ANNOTATION_CARRAY = FfiCode(
    'MISSING_SIZE_ANNOTATION_CARRAY',
    "Fields of type 'Array' must have exactly one 'Array' annotation.",
    correctionMessage:
        "Try adding an 'Array' annotation, or removing all but one of the "
        "annotations.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the type that should be a valid dart:ffi native type.
  ///  1: the name of the function whose invocation depends on this relationship
  static const FfiCode MUST_BE_A_NATIVE_FUNCTION_TYPE = FfiCode(
    'MUST_BE_A_NATIVE_FUNCTION_TYPE',
    "The type '{0}' given to '{1}' must be a valid 'dart:ffi' native function "
        "type.",
    correctionMessage:
        "Try changing the type to only use members for 'dart:ffi'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the type that should be a subtype
  ///  1: the supertype that the subtype is compared to
  ///  2: the name of the function whose invocation depends on this relationship
  static const FfiCode MUST_BE_A_SUBTYPE = FfiCode(
    'MUST_BE_A_SUBTYPE',
    "The type '{0}' must be a subtype of '{1}' for '{2}'.",
    correctionMessage: "Try changing one or both of the type arguments.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the function, method, or constructor having type arguments
  static const FfiCode NON_CONSTANT_TYPE_ARGUMENT = FfiCode(
    'NON_CONSTANT_TYPE_ARGUMENT',
    "The type arguments to '{0}' must be known at compile time, so they can't "
        "be type parameters.",
    correctionMessage: "Try changing the type argument to be a constant type.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the type that should be a valid dart:ffi native type.
  static const FfiCode NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER = FfiCode(
    'NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER',
    "Can't invoke 'asFunction' because the function signature '{0}' for the "
        "pointer isn't a valid C function signature.",
    correctionMessage:
        "Try changing the function argument in 'NativeFunction' to only use "
        "NativeTypes.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const FfiCode NON_POSITIVE_ARRAY_DIMENSION = FfiCode(
    'NON_POSITIVE_ARRAY_DIMENSION',
    "Array dimensions must be positive numbers.",
    correctionMessage: "Try changing the input to a positive number.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the field
  ///  1: the type of the field
  static const FfiCode NON_SIZED_TYPE_ARGUMENT = FfiCode(
    'NON_SIZED_TYPE_ARGUMENT',
    "The type '{1}' isn't a valid type argument for '{0}'. The type argument "
        "must be a native integer, 'Float', 'Double', 'Pointer', or subtype of "
        "'Struct', 'Union', or 'AbiSpecificInteger'.",
    correctionMessage:
        "Try using a native integer, 'Float', 'Double', 'Pointer', or subtype "
        "of 'Struct', 'Union', or 'AbiSpecificInteger'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const FfiCode PACKED_ANNOTATION = FfiCode(
    'PACKED_ANNOTATION',
    "Structs must have at most one 'Packed' annotation.",
    correctionMessage: "Try removing extra 'Packed' annotations.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const FfiCode PACKED_ANNOTATION_ALIGNMENT = FfiCode(
    'PACKED_ANNOTATION_ALIGNMENT',
    "Only packing to 1, 2, 4, 8, and 16 bytes is supported.",
    correctionMessage:
        "Try changing the 'Packed' annotation alignment to 1, 2, 4, 8, or 16.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const FfiCode SIZE_ANNOTATION_DIMENSIONS = FfiCode(
    'SIZE_ANNOTATION_DIMENSIONS',
    "'Array's must have an 'Array' annotation that matches the dimensions.",
    correctionMessage: "Try adjusting the arguments in the 'Array' annotation.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the subclass
  ///  1: the name of the class being extended, implemented, or mixed in
  static const FfiCode SUBTYPE_OF_FFI_CLASS_IN_EXTENDS = FfiCode(
    'SUBTYPE_OF_FFI_CLASS',
    "The class '{0}' can't extend '{1}'.",
    correctionMessage: "Try extending 'Struct' or 'Union'.",
    hasPublishedDocs: true,
    uniqueName: 'SUBTYPE_OF_FFI_CLASS_IN_EXTENDS',
  );

  ///  Parameters:
  ///  0: the name of the subclass
  ///  1: the name of the class being extended, implemented, or mixed in
  static const FfiCode SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS = FfiCode(
    'SUBTYPE_OF_FFI_CLASS',
    "The class '{0}' can't implement '{1}'.",
    correctionMessage: "Try implementing 'Allocator' or 'Finalizable'.",
    hasPublishedDocs: true,
    uniqueName: 'SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS',
  );

  ///  Parameters:
  ///  0: the name of the subclass
  ///  1: the name of the class being extended, implemented, or mixed in
  static const FfiCode SUBTYPE_OF_FFI_CLASS_IN_WITH = FfiCode(
    'SUBTYPE_OF_FFI_CLASS',
    "The class '{0}' can't mix in '{1}'.",
    correctionMessage: "Try extending 'Struct' or 'Union'.",
    hasPublishedDocs: true,
    uniqueName: 'SUBTYPE_OF_FFI_CLASS_IN_WITH',
  );

  ///  Parameters:
  ///  0: the name of the subclass
  ///  1: the name of the class being extended, implemented, or mixed in
  static const FfiCode SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS = FfiCode(
    'SUBTYPE_OF_STRUCT_CLASS',
    "The class '{0}' can't extend '{1}' because '{1}' is a subtype of "
        "'Struct', 'Union', or 'AbiSpecificInteger'.",
    correctionMessage:
        "Try extending 'Struct', 'Union', or 'AbiSpecificInteger' directly.",
    hasPublishedDocs: true,
    uniqueName: 'SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS',
  );

  ///  Parameters:
  ///  0: the name of the subclass
  ///  1: the name of the class being extended, implemented, or mixed in
  static const FfiCode SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS = FfiCode(
    'SUBTYPE_OF_STRUCT_CLASS',
    "The class '{0}' can't implement '{1}' because '{1}' is a subtype of "
        "'Struct', 'Union', or 'AbiSpecificInteger'.",
    correctionMessage:
        "Try extending 'Struct', 'Union', or 'AbiSpecificInteger' directly.",
    hasPublishedDocs: true,
    uniqueName: 'SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS',
  );

  ///  Parameters:
  ///  0: the name of the subclass
  ///  1: the name of the class being extended, implemented, or mixed in
  static const FfiCode SUBTYPE_OF_STRUCT_CLASS_IN_WITH = FfiCode(
    'SUBTYPE_OF_STRUCT_CLASS',
    "The class '{0}' can't mix in '{1}' because '{1}' is a subtype of "
        "'Struct', 'Union', or 'AbiSpecificInteger'.",
    correctionMessage:
        "Try extending 'Struct', 'Union', or 'AbiSpecificInteger' directly.",
    hasPublishedDocs: true,
    uniqueName: 'SUBTYPE_OF_STRUCT_CLASS_IN_WITH',
  );

  /// Initialize a newly created error code to have the given [name].
  const FfiCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
          name: name,
          problemMessage: problemMessage,
          uniqueName: 'FfiCode.${uniqueName ?? name}',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorType.COMPILE_TIME_ERROR.severity;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;
}
