///
//  Generated code. Do not modify.
//  source: descriptor.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class FieldDescriptorProto_Type extends $pb.ProtobufEnum {
  static const FieldDescriptorProto_Type TYPE_DOUBLE =
      FieldDescriptorProto_Type._(
          1,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TYPE_DOUBLE');
  static const FieldDescriptorProto_Type TYPE_FLOAT =
      FieldDescriptorProto_Type._(
          2,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TYPE_FLOAT');
  static const FieldDescriptorProto_Type TYPE_INT64 =
      FieldDescriptorProto_Type._(
          3,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TYPE_INT64');
  static const FieldDescriptorProto_Type TYPE_UINT64 =
      FieldDescriptorProto_Type._(
          4,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TYPE_UINT64');
  static const FieldDescriptorProto_Type TYPE_INT32 =
      FieldDescriptorProto_Type._(
          5,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TYPE_INT32');
  static const FieldDescriptorProto_Type TYPE_FIXED64 =
      FieldDescriptorProto_Type._(
          6,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TYPE_FIXED64');
  static const FieldDescriptorProto_Type TYPE_FIXED32 =
      FieldDescriptorProto_Type._(
          7,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TYPE_FIXED32');
  static const FieldDescriptorProto_Type TYPE_BOOL =
      FieldDescriptorProto_Type._(
          8,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TYPE_BOOL');
  static const FieldDescriptorProto_Type TYPE_STRING =
      FieldDescriptorProto_Type._(
          9,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TYPE_STRING');
  static const FieldDescriptorProto_Type TYPE_GROUP =
      FieldDescriptorProto_Type._(
          10,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TYPE_GROUP');
  static const FieldDescriptorProto_Type TYPE_MESSAGE =
      FieldDescriptorProto_Type._(
          11,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TYPE_MESSAGE');
  static const FieldDescriptorProto_Type TYPE_BYTES =
      FieldDescriptorProto_Type._(
          12,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TYPE_BYTES');
  static const FieldDescriptorProto_Type TYPE_UINT32 =
      FieldDescriptorProto_Type._(
          13,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TYPE_UINT32');
  static const FieldDescriptorProto_Type TYPE_ENUM =
      FieldDescriptorProto_Type._(
          14,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TYPE_ENUM');
  static const FieldDescriptorProto_Type TYPE_SFIXED32 =
      FieldDescriptorProto_Type._(
          15,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TYPE_SFIXED32');
  static const FieldDescriptorProto_Type TYPE_SFIXED64 =
      FieldDescriptorProto_Type._(
          16,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TYPE_SFIXED64');
  static const FieldDescriptorProto_Type TYPE_SINT32 =
      FieldDescriptorProto_Type._(
          17,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TYPE_SINT32');
  static const FieldDescriptorProto_Type TYPE_SINT64 =
      FieldDescriptorProto_Type._(
          18,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TYPE_SINT64');

  static const $core.List<FieldDescriptorProto_Type> values =
      <FieldDescriptorProto_Type>[
    TYPE_DOUBLE,
    TYPE_FLOAT,
    TYPE_INT64,
    TYPE_UINT64,
    TYPE_INT32,
    TYPE_FIXED64,
    TYPE_FIXED32,
    TYPE_BOOL,
    TYPE_STRING,
    TYPE_GROUP,
    TYPE_MESSAGE,
    TYPE_BYTES,
    TYPE_UINT32,
    TYPE_ENUM,
    TYPE_SFIXED32,
    TYPE_SFIXED64,
    TYPE_SINT32,
    TYPE_SINT64,
  ];

  static final $core.Map<$core.int, FieldDescriptorProto_Type> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static FieldDescriptorProto_Type? valueOf($core.int value) => _byValue[value];

  const FieldDescriptorProto_Type._($core.int v, $core.String n) : super(v, n);
}

class FieldDescriptorProto_Label extends $pb.ProtobufEnum {
  static const FieldDescriptorProto_Label LABEL_OPTIONAL =
      FieldDescriptorProto_Label._(
          1,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'LABEL_OPTIONAL');
  static const FieldDescriptorProto_Label LABEL_REQUIRED =
      FieldDescriptorProto_Label._(
          2,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'LABEL_REQUIRED');
  static const FieldDescriptorProto_Label LABEL_REPEATED =
      FieldDescriptorProto_Label._(
          3,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'LABEL_REPEATED');

  static const $core.List<FieldDescriptorProto_Label> values =
      <FieldDescriptorProto_Label>[
    LABEL_OPTIONAL,
    LABEL_REQUIRED,
    LABEL_REPEATED,
  ];

  static final $core.Map<$core.int, FieldDescriptorProto_Label> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static FieldDescriptorProto_Label? valueOf($core.int value) =>
      _byValue[value];

  const FieldDescriptorProto_Label._($core.int v, $core.String n) : super(v, n);
}

class FileOptions_OptimizeMode extends $pb.ProtobufEnum {
  static const FileOptions_OptimizeMode SPEED = FileOptions_OptimizeMode._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'SPEED');
  static const FileOptions_OptimizeMode CODE_SIZE = FileOptions_OptimizeMode._(
      2,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'CODE_SIZE');
  static const FileOptions_OptimizeMode LITE_RUNTIME =
      FileOptions_OptimizeMode._(
          3,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'LITE_RUNTIME');

  static const $core.List<FileOptions_OptimizeMode> values =
      <FileOptions_OptimizeMode>[
    SPEED,
    CODE_SIZE,
    LITE_RUNTIME,
  ];

  static final $core.Map<$core.int, FileOptions_OptimizeMode> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static FileOptions_OptimizeMode? valueOf($core.int value) => _byValue[value];

  const FileOptions_OptimizeMode._($core.int v, $core.String n) : super(v, n);
}

class FieldOptions_CType extends $pb.ProtobufEnum {
  static const FieldOptions_CType STRING = FieldOptions_CType._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'STRING');
  static const FieldOptions_CType CORD = FieldOptions_CType._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'CORD');
  static const FieldOptions_CType STRING_PIECE = FieldOptions_CType._(
      2,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'STRING_PIECE');

  static const $core.List<FieldOptions_CType> values = <FieldOptions_CType>[
    STRING,
    CORD,
    STRING_PIECE,
  ];

  static final $core.Map<$core.int, FieldOptions_CType> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static FieldOptions_CType? valueOf($core.int value) => _byValue[value];

  const FieldOptions_CType._($core.int v, $core.String n) : super(v, n);
}

class FieldOptions_JSType extends $pb.ProtobufEnum {
  static const FieldOptions_JSType JS_NORMAL = FieldOptions_JSType._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'JS_NORMAL');
  static const FieldOptions_JSType JS_STRING = FieldOptions_JSType._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'JS_STRING');
  static const FieldOptions_JSType JS_NUMBER = FieldOptions_JSType._(
      2,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'JS_NUMBER');

  static const $core.List<FieldOptions_JSType> values = <FieldOptions_JSType>[
    JS_NORMAL,
    JS_STRING,
    JS_NUMBER,
  ];

  static final $core.Map<$core.int, FieldOptions_JSType> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static FieldOptions_JSType? valueOf($core.int value) => _byValue[value];

  const FieldOptions_JSType._($core.int v, $core.String n) : super(v, n);
}

class MethodOptions_IdempotencyLevel extends $pb.ProtobufEnum {
  static const MethodOptions_IdempotencyLevel IDEMPOTENCY_UNKNOWN =
      MethodOptions_IdempotencyLevel._(
          0,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'IDEMPOTENCY_UNKNOWN');
  static const MethodOptions_IdempotencyLevel NO_SIDE_EFFECTS =
      MethodOptions_IdempotencyLevel._(
          1,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'NO_SIDE_EFFECTS');
  static const MethodOptions_IdempotencyLevel IDEMPOTENT =
      MethodOptions_IdempotencyLevel._(
          2,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'IDEMPOTENT');

  static const $core.List<MethodOptions_IdempotencyLevel> values =
      <MethodOptions_IdempotencyLevel>[
    IDEMPOTENCY_UNKNOWN,
    NO_SIDE_EFFECTS,
    IDEMPOTENT,
  ];

  static final $core.Map<$core.int, MethodOptions_IdempotencyLevel> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static MethodOptions_IdempotencyLevel? valueOf($core.int value) =>
      _byValue[value];

  const MethodOptions_IdempotencyLevel._($core.int v, $core.String n)
      : super(v, n);
}
