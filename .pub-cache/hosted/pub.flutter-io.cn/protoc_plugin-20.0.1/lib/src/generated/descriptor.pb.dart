///
//  Generated code. Do not modify.
//  source: descriptor.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'descriptor.pbenum.dart';

export 'descriptor.pbenum.dart';

class FileDescriptorSet extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'FileDescriptorSet',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..pc<FileDescriptorProto>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'file',
        $pb.PbFieldType.PM,
        subBuilder: FileDescriptorProto.create);

  FileDescriptorSet._() : super();
  factory FileDescriptorSet({
    $core.Iterable<FileDescriptorProto>? file,
  }) {
    final _result = create();
    if (file != null) {
      _result.file.addAll(file);
    }
    return _result;
  }
  factory FileDescriptorSet.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FileDescriptorSet.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FileDescriptorSet clone() => FileDescriptorSet()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FileDescriptorSet copyWith(void Function(FileDescriptorSet) updates) =>
      super.copyWith((message) => updates(message as FileDescriptorSet))
          as FileDescriptorSet; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FileDescriptorSet create() => FileDescriptorSet._();
  FileDescriptorSet createEmptyInstance() => create();
  static $pb.PbList<FileDescriptorSet> createRepeated() =>
      $pb.PbList<FileDescriptorSet>();
  @$core.pragma('dart2js:noInline')
  static FileDescriptorSet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FileDescriptorSet>(create);
  static FileDescriptorSet? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<FileDescriptorProto> get file => $_getList(0);
}

class FileDescriptorProto extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'FileDescriptorProto',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'name')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'package')
    ..pPS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'dependency')
    ..pc<DescriptorProto>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'messageType',
        $pb.PbFieldType.PM,
        subBuilder: DescriptorProto.create)
    ..pc<EnumDescriptorProto>(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'enumType',
        $pb.PbFieldType.PM,
        subBuilder: EnumDescriptorProto.create)
    ..pc<ServiceDescriptorProto>(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'service',
        $pb.PbFieldType.PM,
        subBuilder: ServiceDescriptorProto.create)
    ..pc<FieldDescriptorProto>(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'extension',
        $pb.PbFieldType.PM,
        subBuilder: FieldDescriptorProto.create)
    ..aOM<FileOptions>(
        8,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'options',
        subBuilder: FileOptions.create)
    ..aOM<SourceCodeInfo>(
        9,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'sourceCodeInfo',
        subBuilder: SourceCodeInfo.create)
    ..p<$core.int>(
        10,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'publicDependency',
        $pb.PbFieldType.P3)
    ..p<$core.int>(
        11,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'weakDependency',
        $pb.PbFieldType.P3)
    ..aOS(
        12,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'syntax');

  FileDescriptorProto._() : super();
  factory FileDescriptorProto({
    $core.String? name,
    $core.String? package,
    $core.Iterable<$core.String>? dependency,
    $core.Iterable<DescriptorProto>? messageType,
    $core.Iterable<EnumDescriptorProto>? enumType,
    $core.Iterable<ServiceDescriptorProto>? service,
    $core.Iterable<FieldDescriptorProto>? extension,
    FileOptions? options,
    SourceCodeInfo? sourceCodeInfo,
    $core.Iterable<$core.int>? publicDependency,
    $core.Iterable<$core.int>? weakDependency,
    $core.String? syntax,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (package != null) {
      _result.package = package;
    }
    if (dependency != null) {
      _result.dependency.addAll(dependency);
    }
    if (messageType != null) {
      _result.messageType.addAll(messageType);
    }
    if (enumType != null) {
      _result.enumType.addAll(enumType);
    }
    if (service != null) {
      _result.service.addAll(service);
    }
    if (extension != null) {
      _result.extension.addAll(extension);
    }
    if (options != null) {
      _result.options = options;
    }
    if (sourceCodeInfo != null) {
      _result.sourceCodeInfo = sourceCodeInfo;
    }
    if (publicDependency != null) {
      _result.publicDependency.addAll(publicDependency);
    }
    if (weakDependency != null) {
      _result.weakDependency.addAll(weakDependency);
    }
    if (syntax != null) {
      _result.syntax = syntax;
    }
    return _result;
  }
  factory FileDescriptorProto.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FileDescriptorProto.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FileDescriptorProto clone() => FileDescriptorProto()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FileDescriptorProto copyWith(void Function(FileDescriptorProto) updates) =>
      super.copyWith((message) => updates(message as FileDescriptorProto))
          as FileDescriptorProto; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FileDescriptorProto create() => FileDescriptorProto._();
  FileDescriptorProto createEmptyInstance() => create();
  static $pb.PbList<FileDescriptorProto> createRepeated() =>
      $pb.PbList<FileDescriptorProto>();
  @$core.pragma('dart2js:noInline')
  static FileDescriptorProto getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FileDescriptorProto>(create);
  static FileDescriptorProto? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get package => $_getSZ(1);
  @$pb.TagNumber(2)
  set package($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPackage() => $_has(1);
  @$pb.TagNumber(2)
  void clearPackage() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.String> get dependency => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<DescriptorProto> get messageType => $_getList(3);

  @$pb.TagNumber(5)
  $core.List<EnumDescriptorProto> get enumType => $_getList(4);

  @$pb.TagNumber(6)
  $core.List<ServiceDescriptorProto> get service => $_getList(5);

  @$pb.TagNumber(7)
  $core.List<FieldDescriptorProto> get extension => $_getList(6);

  @$pb.TagNumber(8)
  FileOptions get options => $_getN(7);
  @$pb.TagNumber(8)
  set options(FileOptions v) {
    setField(8, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasOptions() => $_has(7);
  @$pb.TagNumber(8)
  void clearOptions() => clearField(8);
  @$pb.TagNumber(8)
  FileOptions ensureOptions() => $_ensure(7);

  @$pb.TagNumber(9)
  SourceCodeInfo get sourceCodeInfo => $_getN(8);
  @$pb.TagNumber(9)
  set sourceCodeInfo(SourceCodeInfo v) {
    setField(9, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasSourceCodeInfo() => $_has(8);
  @$pb.TagNumber(9)
  void clearSourceCodeInfo() => clearField(9);
  @$pb.TagNumber(9)
  SourceCodeInfo ensureSourceCodeInfo() => $_ensure(8);

  @$pb.TagNumber(10)
  $core.List<$core.int> get publicDependency => $_getList(9);

  @$pb.TagNumber(11)
  $core.List<$core.int> get weakDependency => $_getList(10);

  @$pb.TagNumber(12)
  $core.String get syntax => $_getSZ(11);
  @$pb.TagNumber(12)
  set syntax($core.String v) {
    $_setString(11, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasSyntax() => $_has(11);
  @$pb.TagNumber(12)
  void clearSyntax() => clearField(12);
}

class DescriptorProto_ExtensionRange extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'DescriptorProto.ExtensionRange',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'start',
        $pb.PbFieldType.O3)
    ..a<$core.int>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'end',
        $pb.PbFieldType.O3)
    ..aOM<ExtensionRangeOptions>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'options',
        subBuilder: ExtensionRangeOptions.create);

  DescriptorProto_ExtensionRange._() : super();
  factory DescriptorProto_ExtensionRange({
    $core.int? start,
    $core.int? end,
    ExtensionRangeOptions? options,
  }) {
    final _result = create();
    if (start != null) {
      _result.start = start;
    }
    if (end != null) {
      _result.end = end;
    }
    if (options != null) {
      _result.options = options;
    }
    return _result;
  }
  factory DescriptorProto_ExtensionRange.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DescriptorProto_ExtensionRange.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DescriptorProto_ExtensionRange clone() =>
      DescriptorProto_ExtensionRange()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DescriptorProto_ExtensionRange copyWith(
          void Function(DescriptorProto_ExtensionRange) updates) =>
      super.copyWith(
              (message) => updates(message as DescriptorProto_ExtensionRange))
          as DescriptorProto_ExtensionRange; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DescriptorProto_ExtensionRange create() =>
      DescriptorProto_ExtensionRange._();
  DescriptorProto_ExtensionRange createEmptyInstance() => create();
  static $pb.PbList<DescriptorProto_ExtensionRange> createRepeated() =>
      $pb.PbList<DescriptorProto_ExtensionRange>();
  @$core.pragma('dart2js:noInline')
  static DescriptorProto_ExtensionRange getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DescriptorProto_ExtensionRange>(create);
  static DescriptorProto_ExtensionRange? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get start => $_getIZ(0);
  @$pb.TagNumber(1)
  set start($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasStart() => $_has(0);
  @$pb.TagNumber(1)
  void clearStart() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get end => $_getIZ(1);
  @$pb.TagNumber(2)
  set end($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasEnd() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnd() => clearField(2);

  @$pb.TagNumber(3)
  ExtensionRangeOptions get options => $_getN(2);
  @$pb.TagNumber(3)
  set options(ExtensionRangeOptions v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasOptions() => $_has(2);
  @$pb.TagNumber(3)
  void clearOptions() => clearField(3);
  @$pb.TagNumber(3)
  ExtensionRangeOptions ensureOptions() => $_ensure(2);
}

class DescriptorProto_ReservedRange extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'DescriptorProto.ReservedRange',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'start',
        $pb.PbFieldType.O3)
    ..a<$core.int>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'end',
        $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  DescriptorProto_ReservedRange._() : super();
  factory DescriptorProto_ReservedRange({
    $core.int? start,
    $core.int? end,
  }) {
    final _result = create();
    if (start != null) {
      _result.start = start;
    }
    if (end != null) {
      _result.end = end;
    }
    return _result;
  }
  factory DescriptorProto_ReservedRange.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DescriptorProto_ReservedRange.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DescriptorProto_ReservedRange clone() =>
      DescriptorProto_ReservedRange()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DescriptorProto_ReservedRange copyWith(
          void Function(DescriptorProto_ReservedRange) updates) =>
      super.copyWith(
              (message) => updates(message as DescriptorProto_ReservedRange))
          as DescriptorProto_ReservedRange; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DescriptorProto_ReservedRange create() =>
      DescriptorProto_ReservedRange._();
  DescriptorProto_ReservedRange createEmptyInstance() => create();
  static $pb.PbList<DescriptorProto_ReservedRange> createRepeated() =>
      $pb.PbList<DescriptorProto_ReservedRange>();
  @$core.pragma('dart2js:noInline')
  static DescriptorProto_ReservedRange getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DescriptorProto_ReservedRange>(create);
  static DescriptorProto_ReservedRange? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get start => $_getIZ(0);
  @$pb.TagNumber(1)
  set start($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasStart() => $_has(0);
  @$pb.TagNumber(1)
  void clearStart() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get end => $_getIZ(1);
  @$pb.TagNumber(2)
  set end($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasEnd() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnd() => clearField(2);
}

class DescriptorProto extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'DescriptorProto',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'name')
    ..pc<FieldDescriptorProto>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'field',
        $pb.PbFieldType.PM,
        subBuilder: FieldDescriptorProto.create)
    ..pc<DescriptorProto>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'nestedType',
        $pb.PbFieldType.PM,
        subBuilder: DescriptorProto.create)
    ..pc<EnumDescriptorProto>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'enumType',
        $pb.PbFieldType.PM,
        subBuilder: EnumDescriptorProto.create)
    ..pc<DescriptorProto_ExtensionRange>(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'extensionRange',
        $pb.PbFieldType.PM,
        subBuilder: DescriptorProto_ExtensionRange.create)
    ..pc<FieldDescriptorProto>(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'extension',
        $pb.PbFieldType.PM,
        subBuilder: FieldDescriptorProto.create)
    ..aOM<MessageOptions>(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'options',
        subBuilder: MessageOptions.create)
    ..pc<OneofDescriptorProto>(
        8,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'oneofDecl',
        $pb.PbFieldType.PM,
        subBuilder: OneofDescriptorProto.create)
    ..pc<DescriptorProto_ReservedRange>(
        9,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'reservedRange',
        $pb.PbFieldType.PM,
        subBuilder: DescriptorProto_ReservedRange.create)
    ..pPS(
        10,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'reservedName');

  DescriptorProto._() : super();
  factory DescriptorProto({
    $core.String? name,
    $core.Iterable<FieldDescriptorProto>? field,
    $core.Iterable<DescriptorProto>? nestedType,
    $core.Iterable<EnumDescriptorProto>? enumType,
    $core.Iterable<DescriptorProto_ExtensionRange>? extensionRange,
    $core.Iterable<FieldDescriptorProto>? extension,
    MessageOptions? options,
    $core.Iterable<OneofDescriptorProto>? oneofDecl,
    $core.Iterable<DescriptorProto_ReservedRange>? reservedRange,
    $core.Iterable<$core.String>? reservedName,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (field != null) {
      _result.field.addAll(field);
    }
    if (nestedType != null) {
      _result.nestedType.addAll(nestedType);
    }
    if (enumType != null) {
      _result.enumType.addAll(enumType);
    }
    if (extensionRange != null) {
      _result.extensionRange.addAll(extensionRange);
    }
    if (extension != null) {
      _result.extension.addAll(extension);
    }
    if (options != null) {
      _result.options = options;
    }
    if (oneofDecl != null) {
      _result.oneofDecl.addAll(oneofDecl);
    }
    if (reservedRange != null) {
      _result.reservedRange.addAll(reservedRange);
    }
    if (reservedName != null) {
      _result.reservedName.addAll(reservedName);
    }
    return _result;
  }
  factory DescriptorProto.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DescriptorProto.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DescriptorProto clone() => DescriptorProto()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DescriptorProto copyWith(void Function(DescriptorProto) updates) =>
      super.copyWith((message) => updates(message as DescriptorProto))
          as DescriptorProto; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DescriptorProto create() => DescriptorProto._();
  DescriptorProto createEmptyInstance() => create();
  static $pb.PbList<DescriptorProto> createRepeated() =>
      $pb.PbList<DescriptorProto>();
  @$core.pragma('dart2js:noInline')
  static DescriptorProto getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DescriptorProto>(create);
  static DescriptorProto? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<FieldDescriptorProto> get field => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<DescriptorProto> get nestedType => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<EnumDescriptorProto> get enumType => $_getList(3);

  @$pb.TagNumber(5)
  $core.List<DescriptorProto_ExtensionRange> get extensionRange => $_getList(4);

  @$pb.TagNumber(6)
  $core.List<FieldDescriptorProto> get extension => $_getList(5);

  @$pb.TagNumber(7)
  MessageOptions get options => $_getN(6);
  @$pb.TagNumber(7)
  set options(MessageOptions v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasOptions() => $_has(6);
  @$pb.TagNumber(7)
  void clearOptions() => clearField(7);
  @$pb.TagNumber(7)
  MessageOptions ensureOptions() => $_ensure(6);

  @$pb.TagNumber(8)
  $core.List<OneofDescriptorProto> get oneofDecl => $_getList(7);

  @$pb.TagNumber(9)
  $core.List<DescriptorProto_ReservedRange> get reservedRange => $_getList(8);

  @$pb.TagNumber(10)
  $core.List<$core.String> get reservedName => $_getList(9);
}

class ExtensionRangeOptions extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ExtensionRangeOptions',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..pc<UninterpretedOption>(
        999,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'uninterpretedOption',
        $pb.PbFieldType.PM,
        subBuilder: UninterpretedOption.create)
    ..hasExtensions = true;

  ExtensionRangeOptions._() : super();
  factory ExtensionRangeOptions({
    $core.Iterable<UninterpretedOption>? uninterpretedOption,
  }) {
    final _result = create();
    if (uninterpretedOption != null) {
      _result.uninterpretedOption.addAll(uninterpretedOption);
    }
    return _result;
  }
  factory ExtensionRangeOptions.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ExtensionRangeOptions.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ExtensionRangeOptions clone() =>
      ExtensionRangeOptions()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ExtensionRangeOptions copyWith(
          void Function(ExtensionRangeOptions) updates) =>
      super.copyWith((message) => updates(message as ExtensionRangeOptions))
          as ExtensionRangeOptions; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ExtensionRangeOptions create() => ExtensionRangeOptions._();
  ExtensionRangeOptions createEmptyInstance() => create();
  static $pb.PbList<ExtensionRangeOptions> createRepeated() =>
      $pb.PbList<ExtensionRangeOptions>();
  @$core.pragma('dart2js:noInline')
  static ExtensionRangeOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExtensionRangeOptions>(create);
  static ExtensionRangeOptions? _defaultInstance;

  @$pb.TagNumber(999)
  $core.List<UninterpretedOption> get uninterpretedOption => $_getList(0);
}

class FieldDescriptorProto extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'FieldDescriptorProto',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'name')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'extendee')
    ..a<$core.int>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'number',
        $pb.PbFieldType.O3)
    ..e<FieldDescriptorProto_Label>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'label',
        $pb.PbFieldType.OE,
        defaultOrMaker: FieldDescriptorProto_Label.LABEL_OPTIONAL,
        valueOf: FieldDescriptorProto_Label.valueOf,
        enumValues: FieldDescriptorProto_Label.values)
    ..e<FieldDescriptorProto_Type>(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'type',
        $pb.PbFieldType.OE,
        defaultOrMaker: FieldDescriptorProto_Type.TYPE_DOUBLE,
        valueOf: FieldDescriptorProto_Type.valueOf,
        enumValues: FieldDescriptorProto_Type.values)
    ..aOS(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'typeName')
    ..aOS(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'defaultValue')
    ..aOM<FieldOptions>(
        8,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'options',
        subBuilder: FieldOptions.create)
    ..a<$core.int>(
        9,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'oneofIndex',
        $pb.PbFieldType.O3)
    ..aOS(
        10,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'jsonName')
    ..aOB(
        17,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'proto3Optional');

  FieldDescriptorProto._() : super();
  factory FieldDescriptorProto({
    $core.String? name,
    $core.String? extendee,
    $core.int? number,
    FieldDescriptorProto_Label? label,
    FieldDescriptorProto_Type? type,
    $core.String? typeName,
    $core.String? defaultValue,
    FieldOptions? options,
    $core.int? oneofIndex,
    $core.String? jsonName,
    $core.bool? proto3Optional,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (extendee != null) {
      _result.extendee = extendee;
    }
    if (number != null) {
      _result.number = number;
    }
    if (label != null) {
      _result.label = label;
    }
    if (type != null) {
      _result.type = type;
    }
    if (typeName != null) {
      _result.typeName = typeName;
    }
    if (defaultValue != null) {
      _result.defaultValue = defaultValue;
    }
    if (options != null) {
      _result.options = options;
    }
    if (oneofIndex != null) {
      _result.oneofIndex = oneofIndex;
    }
    if (jsonName != null) {
      _result.jsonName = jsonName;
    }
    if (proto3Optional != null) {
      _result.proto3Optional = proto3Optional;
    }
    return _result;
  }
  factory FieldDescriptorProto.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FieldDescriptorProto.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FieldDescriptorProto clone() =>
      FieldDescriptorProto()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FieldDescriptorProto copyWith(void Function(FieldDescriptorProto) updates) =>
      super.copyWith((message) => updates(message as FieldDescriptorProto))
          as FieldDescriptorProto; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FieldDescriptorProto create() => FieldDescriptorProto._();
  FieldDescriptorProto createEmptyInstance() => create();
  static $pb.PbList<FieldDescriptorProto> createRepeated() =>
      $pb.PbList<FieldDescriptorProto>();
  @$core.pragma('dart2js:noInline')
  static FieldDescriptorProto getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FieldDescriptorProto>(create);
  static FieldDescriptorProto? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get extendee => $_getSZ(1);
  @$pb.TagNumber(2)
  set extendee($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasExtendee() => $_has(1);
  @$pb.TagNumber(2)
  void clearExtendee() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get number => $_getIZ(2);
  @$pb.TagNumber(3)
  set number($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasNumber() => $_has(2);
  @$pb.TagNumber(3)
  void clearNumber() => clearField(3);

  @$pb.TagNumber(4)
  FieldDescriptorProto_Label get label => $_getN(3);
  @$pb.TagNumber(4)
  set label(FieldDescriptorProto_Label v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasLabel() => $_has(3);
  @$pb.TagNumber(4)
  void clearLabel() => clearField(4);

  @$pb.TagNumber(5)
  FieldDescriptorProto_Type get type => $_getN(4);
  @$pb.TagNumber(5)
  set type(FieldDescriptorProto_Type v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasType() => $_has(4);
  @$pb.TagNumber(5)
  void clearType() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get typeName => $_getSZ(5);
  @$pb.TagNumber(6)
  set typeName($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasTypeName() => $_has(5);
  @$pb.TagNumber(6)
  void clearTypeName() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get defaultValue => $_getSZ(6);
  @$pb.TagNumber(7)
  set defaultValue($core.String v) {
    $_setString(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasDefaultValue() => $_has(6);
  @$pb.TagNumber(7)
  void clearDefaultValue() => clearField(7);

  @$pb.TagNumber(8)
  FieldOptions get options => $_getN(7);
  @$pb.TagNumber(8)
  set options(FieldOptions v) {
    setField(8, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasOptions() => $_has(7);
  @$pb.TagNumber(8)
  void clearOptions() => clearField(8);
  @$pb.TagNumber(8)
  FieldOptions ensureOptions() => $_ensure(7);

  @$pb.TagNumber(9)
  $core.int get oneofIndex => $_getIZ(8);
  @$pb.TagNumber(9)
  set oneofIndex($core.int v) {
    $_setSignedInt32(8, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasOneofIndex() => $_has(8);
  @$pb.TagNumber(9)
  void clearOneofIndex() => clearField(9);

  @$pb.TagNumber(10)
  $core.String get jsonName => $_getSZ(9);
  @$pb.TagNumber(10)
  set jsonName($core.String v) {
    $_setString(9, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasJsonName() => $_has(9);
  @$pb.TagNumber(10)
  void clearJsonName() => clearField(10);

  @$pb.TagNumber(17)
  $core.bool get proto3Optional => $_getBF(10);
  @$pb.TagNumber(17)
  set proto3Optional($core.bool v) {
    $_setBool(10, v);
  }

  @$pb.TagNumber(17)
  $core.bool hasProto3Optional() => $_has(10);
  @$pb.TagNumber(17)
  void clearProto3Optional() => clearField(17);
}

class OneofDescriptorProto extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'OneofDescriptorProto',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'name')
    ..aOM<OneofOptions>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'options',
        subBuilder: OneofOptions.create);

  OneofDescriptorProto._() : super();
  factory OneofDescriptorProto({
    $core.String? name,
    OneofOptions? options,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (options != null) {
      _result.options = options;
    }
    return _result;
  }
  factory OneofDescriptorProto.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory OneofDescriptorProto.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  OneofDescriptorProto clone() =>
      OneofDescriptorProto()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  OneofDescriptorProto copyWith(void Function(OneofDescriptorProto) updates) =>
      super.copyWith((message) => updates(message as OneofDescriptorProto))
          as OneofDescriptorProto; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static OneofDescriptorProto create() => OneofDescriptorProto._();
  OneofDescriptorProto createEmptyInstance() => create();
  static $pb.PbList<OneofDescriptorProto> createRepeated() =>
      $pb.PbList<OneofDescriptorProto>();
  @$core.pragma('dart2js:noInline')
  static OneofDescriptorProto getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OneofDescriptorProto>(create);
  static OneofDescriptorProto? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  OneofOptions get options => $_getN(1);
  @$pb.TagNumber(2)
  set options(OneofOptions v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasOptions() => $_has(1);
  @$pb.TagNumber(2)
  void clearOptions() => clearField(2);
  @$pb.TagNumber(2)
  OneofOptions ensureOptions() => $_ensure(1);
}

class EnumDescriptorProto_EnumReservedRange extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'EnumDescriptorProto.EnumReservedRange',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'start',
        $pb.PbFieldType.O3)
    ..a<$core.int>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'end',
        $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  EnumDescriptorProto_EnumReservedRange._() : super();
  factory EnumDescriptorProto_EnumReservedRange({
    $core.int? start,
    $core.int? end,
  }) {
    final _result = create();
    if (start != null) {
      _result.start = start;
    }
    if (end != null) {
      _result.end = end;
    }
    return _result;
  }
  factory EnumDescriptorProto_EnumReservedRange.fromBuffer(
          $core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory EnumDescriptorProto_EnumReservedRange.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  EnumDescriptorProto_EnumReservedRange clone() =>
      EnumDescriptorProto_EnumReservedRange()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  EnumDescriptorProto_EnumReservedRange copyWith(
          void Function(EnumDescriptorProto_EnumReservedRange) updates) =>
      super.copyWith((message) =>
              updates(message as EnumDescriptorProto_EnumReservedRange))
          as EnumDescriptorProto_EnumReservedRange; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EnumDescriptorProto_EnumReservedRange create() =>
      EnumDescriptorProto_EnumReservedRange._();
  EnumDescriptorProto_EnumReservedRange createEmptyInstance() => create();
  static $pb.PbList<EnumDescriptorProto_EnumReservedRange> createRepeated() =>
      $pb.PbList<EnumDescriptorProto_EnumReservedRange>();
  @$core.pragma('dart2js:noInline')
  static EnumDescriptorProto_EnumReservedRange getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          EnumDescriptorProto_EnumReservedRange>(create);
  static EnumDescriptorProto_EnumReservedRange? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get start => $_getIZ(0);
  @$pb.TagNumber(1)
  set start($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasStart() => $_has(0);
  @$pb.TagNumber(1)
  void clearStart() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get end => $_getIZ(1);
  @$pb.TagNumber(2)
  set end($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasEnd() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnd() => clearField(2);
}

class EnumDescriptorProto extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'EnumDescriptorProto',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'name')
    ..pc<EnumValueDescriptorProto>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'value',
        $pb.PbFieldType.PM,
        subBuilder: EnumValueDescriptorProto.create)
    ..aOM<EnumOptions>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'options',
        subBuilder: EnumOptions.create)
    ..pc<EnumDescriptorProto_EnumReservedRange>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'reservedRange',
        $pb.PbFieldType.PM,
        subBuilder: EnumDescriptorProto_EnumReservedRange.create)
    ..pPS(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'reservedName');

  EnumDescriptorProto._() : super();
  factory EnumDescriptorProto({
    $core.String? name,
    $core.Iterable<EnumValueDescriptorProto>? value,
    EnumOptions? options,
    $core.Iterable<EnumDescriptorProto_EnumReservedRange>? reservedRange,
    $core.Iterable<$core.String>? reservedName,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (value != null) {
      _result.value.addAll(value);
    }
    if (options != null) {
      _result.options = options;
    }
    if (reservedRange != null) {
      _result.reservedRange.addAll(reservedRange);
    }
    if (reservedName != null) {
      _result.reservedName.addAll(reservedName);
    }
    return _result;
  }
  factory EnumDescriptorProto.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory EnumDescriptorProto.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  EnumDescriptorProto clone() => EnumDescriptorProto()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  EnumDescriptorProto copyWith(void Function(EnumDescriptorProto) updates) =>
      super.copyWith((message) => updates(message as EnumDescriptorProto))
          as EnumDescriptorProto; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EnumDescriptorProto create() => EnumDescriptorProto._();
  EnumDescriptorProto createEmptyInstance() => create();
  static $pb.PbList<EnumDescriptorProto> createRepeated() =>
      $pb.PbList<EnumDescriptorProto>();
  @$core.pragma('dart2js:noInline')
  static EnumDescriptorProto getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnumDescriptorProto>(create);
  static EnumDescriptorProto? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<EnumValueDescriptorProto> get value => $_getList(1);

  @$pb.TagNumber(3)
  EnumOptions get options => $_getN(2);
  @$pb.TagNumber(3)
  set options(EnumOptions v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasOptions() => $_has(2);
  @$pb.TagNumber(3)
  void clearOptions() => clearField(3);
  @$pb.TagNumber(3)
  EnumOptions ensureOptions() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.List<EnumDescriptorProto_EnumReservedRange> get reservedRange =>
      $_getList(3);

  @$pb.TagNumber(5)
  $core.List<$core.String> get reservedName => $_getList(4);
}

class EnumValueDescriptorProto extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'EnumValueDescriptorProto',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'name')
    ..a<$core.int>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'number',
        $pb.PbFieldType.O3)
    ..aOM<EnumValueOptions>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'options',
        subBuilder: EnumValueOptions.create);

  EnumValueDescriptorProto._() : super();
  factory EnumValueDescriptorProto({
    $core.String? name,
    $core.int? number,
    EnumValueOptions? options,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (number != null) {
      _result.number = number;
    }
    if (options != null) {
      _result.options = options;
    }
    return _result;
  }
  factory EnumValueDescriptorProto.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory EnumValueDescriptorProto.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  EnumValueDescriptorProto clone() =>
      EnumValueDescriptorProto()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  EnumValueDescriptorProto copyWith(
          void Function(EnumValueDescriptorProto) updates) =>
      super.copyWith((message) => updates(message as EnumValueDescriptorProto))
          as EnumValueDescriptorProto; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EnumValueDescriptorProto create() => EnumValueDescriptorProto._();
  EnumValueDescriptorProto createEmptyInstance() => create();
  static $pb.PbList<EnumValueDescriptorProto> createRepeated() =>
      $pb.PbList<EnumValueDescriptorProto>();
  @$core.pragma('dart2js:noInline')
  static EnumValueDescriptorProto getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnumValueDescriptorProto>(create);
  static EnumValueDescriptorProto? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get number => $_getIZ(1);
  @$pb.TagNumber(2)
  set number($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasNumber() => $_has(1);
  @$pb.TagNumber(2)
  void clearNumber() => clearField(2);

  @$pb.TagNumber(3)
  EnumValueOptions get options => $_getN(2);
  @$pb.TagNumber(3)
  set options(EnumValueOptions v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasOptions() => $_has(2);
  @$pb.TagNumber(3)
  void clearOptions() => clearField(3);
  @$pb.TagNumber(3)
  EnumValueOptions ensureOptions() => $_ensure(2);
}

class ServiceDescriptorProto extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ServiceDescriptorProto',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'name')
    ..pc<MethodDescriptorProto>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'method',
        $pb.PbFieldType.PM,
        subBuilder: MethodDescriptorProto.create)
    ..aOM<ServiceOptions>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'options',
        subBuilder: ServiceOptions.create);

  ServiceDescriptorProto._() : super();
  factory ServiceDescriptorProto({
    $core.String? name,
    $core.Iterable<MethodDescriptorProto>? method,
    ServiceOptions? options,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (method != null) {
      _result.method.addAll(method);
    }
    if (options != null) {
      _result.options = options;
    }
    return _result;
  }
  factory ServiceDescriptorProto.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ServiceDescriptorProto.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ServiceDescriptorProto clone() =>
      ServiceDescriptorProto()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ServiceDescriptorProto copyWith(
          void Function(ServiceDescriptorProto) updates) =>
      super.copyWith((message) => updates(message as ServiceDescriptorProto))
          as ServiceDescriptorProto; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ServiceDescriptorProto create() => ServiceDescriptorProto._();
  ServiceDescriptorProto createEmptyInstance() => create();
  static $pb.PbList<ServiceDescriptorProto> createRepeated() =>
      $pb.PbList<ServiceDescriptorProto>();
  @$core.pragma('dart2js:noInline')
  static ServiceDescriptorProto getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServiceDescriptorProto>(create);
  static ServiceDescriptorProto? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<MethodDescriptorProto> get method => $_getList(1);

  @$pb.TagNumber(3)
  ServiceOptions get options => $_getN(2);
  @$pb.TagNumber(3)
  set options(ServiceOptions v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasOptions() => $_has(2);
  @$pb.TagNumber(3)
  void clearOptions() => clearField(3);
  @$pb.TagNumber(3)
  ServiceOptions ensureOptions() => $_ensure(2);
}

class MethodDescriptorProto extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'MethodDescriptorProto',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'name')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'inputType')
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'outputType')
    ..aOM<MethodOptions>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'options',
        subBuilder: MethodOptions.create)
    ..aOB(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'clientStreaming')
    ..aOB(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'serverStreaming');

  MethodDescriptorProto._() : super();
  factory MethodDescriptorProto({
    $core.String? name,
    $core.String? inputType,
    $core.String? outputType,
    MethodOptions? options,
    $core.bool? clientStreaming,
    $core.bool? serverStreaming,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (inputType != null) {
      _result.inputType = inputType;
    }
    if (outputType != null) {
      _result.outputType = outputType;
    }
    if (options != null) {
      _result.options = options;
    }
    if (clientStreaming != null) {
      _result.clientStreaming = clientStreaming;
    }
    if (serverStreaming != null) {
      _result.serverStreaming = serverStreaming;
    }
    return _result;
  }
  factory MethodDescriptorProto.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory MethodDescriptorProto.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  MethodDescriptorProto clone() =>
      MethodDescriptorProto()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  MethodDescriptorProto copyWith(
          void Function(MethodDescriptorProto) updates) =>
      super.copyWith((message) => updates(message as MethodDescriptorProto))
          as MethodDescriptorProto; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MethodDescriptorProto create() => MethodDescriptorProto._();
  MethodDescriptorProto createEmptyInstance() => create();
  static $pb.PbList<MethodDescriptorProto> createRepeated() =>
      $pb.PbList<MethodDescriptorProto>();
  @$core.pragma('dart2js:noInline')
  static MethodDescriptorProto getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MethodDescriptorProto>(create);
  static MethodDescriptorProto? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get inputType => $_getSZ(1);
  @$pb.TagNumber(2)
  set inputType($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasInputType() => $_has(1);
  @$pb.TagNumber(2)
  void clearInputType() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get outputType => $_getSZ(2);
  @$pb.TagNumber(3)
  set outputType($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasOutputType() => $_has(2);
  @$pb.TagNumber(3)
  void clearOutputType() => clearField(3);

  @$pb.TagNumber(4)
  MethodOptions get options => $_getN(3);
  @$pb.TagNumber(4)
  set options(MethodOptions v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasOptions() => $_has(3);
  @$pb.TagNumber(4)
  void clearOptions() => clearField(4);
  @$pb.TagNumber(4)
  MethodOptions ensureOptions() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.bool get clientStreaming => $_getBF(4);
  @$pb.TagNumber(5)
  set clientStreaming($core.bool v) {
    $_setBool(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasClientStreaming() => $_has(4);
  @$pb.TagNumber(5)
  void clearClientStreaming() => clearField(5);

  @$pb.TagNumber(6)
  $core.bool get serverStreaming => $_getBF(5);
  @$pb.TagNumber(6)
  set serverStreaming($core.bool v) {
    $_setBool(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasServerStreaming() => $_has(5);
  @$pb.TagNumber(6)
  void clearServerStreaming() => clearField(6);
}

class FileOptions extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'FileOptions',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'javaPackage')
    ..aOS(
        8,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'javaOuterClassname')
    ..e<FileOptions_OptimizeMode>(
        9,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'optimizeFor',
        $pb.PbFieldType.OE,
        defaultOrMaker: FileOptions_OptimizeMode.SPEED,
        valueOf: FileOptions_OptimizeMode.valueOf,
        enumValues: FileOptions_OptimizeMode.values)
    ..aOB(
        10,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'javaMultipleFiles')
    ..aOS(
        11,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'goPackage')
    ..aOB(
        16,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'ccGenericServices')
    ..aOB(
        17,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'javaGenericServices')
    ..aOB(
        18,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'pyGenericServices')
    ..aOB(
        20,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'javaGenerateEqualsAndHash')
    ..aOB(
        23,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'deprecated')
    ..aOB(
        27,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'javaStringCheckUtf8')
    ..a<$core.bool>(
        31,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'ccEnableArenas',
        $pb.PbFieldType.OB,
        defaultOrMaker: true)
    ..aOS(
        36,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'objcClassPrefix')
    ..aOS(
        37,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'csharpNamespace')
    ..aOS(
        39,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'swiftPrefix')
    ..aOS(
        40,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'phpClassPrefix')
    ..aOS(
        41,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'phpNamespace')
    ..aOB(
        42,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'phpGenericServices')
    ..aOS(
        44,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'phpMetadataNamespace')
    ..aOS(
        45,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'rubyPackage')
    ..pc<UninterpretedOption>(
        999,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'uninterpretedOption',
        $pb.PbFieldType.PM,
        subBuilder: UninterpretedOption.create)
    ..hasExtensions = true;

  FileOptions._() : super();
  factory FileOptions({
    $core.String? javaPackage,
    $core.String? javaOuterClassname,
    FileOptions_OptimizeMode? optimizeFor,
    $core.bool? javaMultipleFiles,
    $core.String? goPackage,
    $core.bool? ccGenericServices,
    $core.bool? javaGenericServices,
    $core.bool? pyGenericServices,
    @$core.Deprecated('This field is deprecated.')
        $core.bool? javaGenerateEqualsAndHash,
    $core.bool? deprecated,
    $core.bool? javaStringCheckUtf8,
    $core.bool? ccEnableArenas,
    $core.String? objcClassPrefix,
    $core.String? csharpNamespace,
    $core.String? swiftPrefix,
    $core.String? phpClassPrefix,
    $core.String? phpNamespace,
    $core.bool? phpGenericServices,
    $core.String? phpMetadataNamespace,
    $core.String? rubyPackage,
    $core.Iterable<UninterpretedOption>? uninterpretedOption,
  }) {
    final _result = create();
    if (javaPackage != null) {
      _result.javaPackage = javaPackage;
    }
    if (javaOuterClassname != null) {
      _result.javaOuterClassname = javaOuterClassname;
    }
    if (optimizeFor != null) {
      _result.optimizeFor = optimizeFor;
    }
    if (javaMultipleFiles != null) {
      _result.javaMultipleFiles = javaMultipleFiles;
    }
    if (goPackage != null) {
      _result.goPackage = goPackage;
    }
    if (ccGenericServices != null) {
      _result.ccGenericServices = ccGenericServices;
    }
    if (javaGenericServices != null) {
      _result.javaGenericServices = javaGenericServices;
    }
    if (pyGenericServices != null) {
      _result.pyGenericServices = pyGenericServices;
    }
    if (javaGenerateEqualsAndHash != null) {
      // ignore: deprecated_member_use_from_same_package
      _result.javaGenerateEqualsAndHash = javaGenerateEqualsAndHash;
    }
    if (deprecated != null) {
      _result.deprecated = deprecated;
    }
    if (javaStringCheckUtf8 != null) {
      _result.javaStringCheckUtf8 = javaStringCheckUtf8;
    }
    if (ccEnableArenas != null) {
      _result.ccEnableArenas = ccEnableArenas;
    }
    if (objcClassPrefix != null) {
      _result.objcClassPrefix = objcClassPrefix;
    }
    if (csharpNamespace != null) {
      _result.csharpNamespace = csharpNamespace;
    }
    if (swiftPrefix != null) {
      _result.swiftPrefix = swiftPrefix;
    }
    if (phpClassPrefix != null) {
      _result.phpClassPrefix = phpClassPrefix;
    }
    if (phpNamespace != null) {
      _result.phpNamespace = phpNamespace;
    }
    if (phpGenericServices != null) {
      _result.phpGenericServices = phpGenericServices;
    }
    if (phpMetadataNamespace != null) {
      _result.phpMetadataNamespace = phpMetadataNamespace;
    }
    if (rubyPackage != null) {
      _result.rubyPackage = rubyPackage;
    }
    if (uninterpretedOption != null) {
      _result.uninterpretedOption.addAll(uninterpretedOption);
    }
    return _result;
  }
  factory FileOptions.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FileOptions.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FileOptions clone() => FileOptions()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FileOptions copyWith(void Function(FileOptions) updates) =>
      super.copyWith((message) => updates(message as FileOptions))
          as FileOptions; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FileOptions create() => FileOptions._();
  FileOptions createEmptyInstance() => create();
  static $pb.PbList<FileOptions> createRepeated() => $pb.PbList<FileOptions>();
  @$core.pragma('dart2js:noInline')
  static FileOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FileOptions>(create);
  static FileOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get javaPackage => $_getSZ(0);
  @$pb.TagNumber(1)
  set javaPackage($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasJavaPackage() => $_has(0);
  @$pb.TagNumber(1)
  void clearJavaPackage() => clearField(1);

  @$pb.TagNumber(8)
  $core.String get javaOuterClassname => $_getSZ(1);
  @$pb.TagNumber(8)
  set javaOuterClassname($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasJavaOuterClassname() => $_has(1);
  @$pb.TagNumber(8)
  void clearJavaOuterClassname() => clearField(8);

  @$pb.TagNumber(9)
  FileOptions_OptimizeMode get optimizeFor => $_getN(2);
  @$pb.TagNumber(9)
  set optimizeFor(FileOptions_OptimizeMode v) {
    setField(9, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasOptimizeFor() => $_has(2);
  @$pb.TagNumber(9)
  void clearOptimizeFor() => clearField(9);

  @$pb.TagNumber(10)
  $core.bool get javaMultipleFiles => $_getBF(3);
  @$pb.TagNumber(10)
  set javaMultipleFiles($core.bool v) {
    $_setBool(3, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasJavaMultipleFiles() => $_has(3);
  @$pb.TagNumber(10)
  void clearJavaMultipleFiles() => clearField(10);

  @$pb.TagNumber(11)
  $core.String get goPackage => $_getSZ(4);
  @$pb.TagNumber(11)
  set goPackage($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasGoPackage() => $_has(4);
  @$pb.TagNumber(11)
  void clearGoPackage() => clearField(11);

  @$pb.TagNumber(16)
  $core.bool get ccGenericServices => $_getBF(5);
  @$pb.TagNumber(16)
  set ccGenericServices($core.bool v) {
    $_setBool(5, v);
  }

  @$pb.TagNumber(16)
  $core.bool hasCcGenericServices() => $_has(5);
  @$pb.TagNumber(16)
  void clearCcGenericServices() => clearField(16);

  @$pb.TagNumber(17)
  $core.bool get javaGenericServices => $_getBF(6);
  @$pb.TagNumber(17)
  set javaGenericServices($core.bool v) {
    $_setBool(6, v);
  }

  @$pb.TagNumber(17)
  $core.bool hasJavaGenericServices() => $_has(6);
  @$pb.TagNumber(17)
  void clearJavaGenericServices() => clearField(17);

  @$pb.TagNumber(18)
  $core.bool get pyGenericServices => $_getBF(7);
  @$pb.TagNumber(18)
  set pyGenericServices($core.bool v) {
    $_setBool(7, v);
  }

  @$pb.TagNumber(18)
  $core.bool hasPyGenericServices() => $_has(7);
  @$pb.TagNumber(18)
  void clearPyGenericServices() => clearField(18);

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(20)
  $core.bool get javaGenerateEqualsAndHash => $_getBF(8);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(20)
  set javaGenerateEqualsAndHash($core.bool v) {
    $_setBool(8, v);
  }

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(20)
  $core.bool hasJavaGenerateEqualsAndHash() => $_has(8);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(20)
  void clearJavaGenerateEqualsAndHash() => clearField(20);

  @$pb.TagNumber(23)
  $core.bool get deprecated => $_getBF(9);
  @$pb.TagNumber(23)
  set deprecated($core.bool v) {
    $_setBool(9, v);
  }

  @$pb.TagNumber(23)
  $core.bool hasDeprecated() => $_has(9);
  @$pb.TagNumber(23)
  void clearDeprecated() => clearField(23);

  @$pb.TagNumber(27)
  $core.bool get javaStringCheckUtf8 => $_getBF(10);
  @$pb.TagNumber(27)
  set javaStringCheckUtf8($core.bool v) {
    $_setBool(10, v);
  }

  @$pb.TagNumber(27)
  $core.bool hasJavaStringCheckUtf8() => $_has(10);
  @$pb.TagNumber(27)
  void clearJavaStringCheckUtf8() => clearField(27);

  @$pb.TagNumber(31)
  $core.bool get ccEnableArenas => $_getB(11, true);
  @$pb.TagNumber(31)
  set ccEnableArenas($core.bool v) {
    $_setBool(11, v);
  }

  @$pb.TagNumber(31)
  $core.bool hasCcEnableArenas() => $_has(11);
  @$pb.TagNumber(31)
  void clearCcEnableArenas() => clearField(31);

  @$pb.TagNumber(36)
  $core.String get objcClassPrefix => $_getSZ(12);
  @$pb.TagNumber(36)
  set objcClassPrefix($core.String v) {
    $_setString(12, v);
  }

  @$pb.TagNumber(36)
  $core.bool hasObjcClassPrefix() => $_has(12);
  @$pb.TagNumber(36)
  void clearObjcClassPrefix() => clearField(36);

  @$pb.TagNumber(37)
  $core.String get csharpNamespace => $_getSZ(13);
  @$pb.TagNumber(37)
  set csharpNamespace($core.String v) {
    $_setString(13, v);
  }

  @$pb.TagNumber(37)
  $core.bool hasCsharpNamespace() => $_has(13);
  @$pb.TagNumber(37)
  void clearCsharpNamespace() => clearField(37);

  @$pb.TagNumber(39)
  $core.String get swiftPrefix => $_getSZ(14);
  @$pb.TagNumber(39)
  set swiftPrefix($core.String v) {
    $_setString(14, v);
  }

  @$pb.TagNumber(39)
  $core.bool hasSwiftPrefix() => $_has(14);
  @$pb.TagNumber(39)
  void clearSwiftPrefix() => clearField(39);

  @$pb.TagNumber(40)
  $core.String get phpClassPrefix => $_getSZ(15);
  @$pb.TagNumber(40)
  set phpClassPrefix($core.String v) {
    $_setString(15, v);
  }

  @$pb.TagNumber(40)
  $core.bool hasPhpClassPrefix() => $_has(15);
  @$pb.TagNumber(40)
  void clearPhpClassPrefix() => clearField(40);

  @$pb.TagNumber(41)
  $core.String get phpNamespace => $_getSZ(16);
  @$pb.TagNumber(41)
  set phpNamespace($core.String v) {
    $_setString(16, v);
  }

  @$pb.TagNumber(41)
  $core.bool hasPhpNamespace() => $_has(16);
  @$pb.TagNumber(41)
  void clearPhpNamespace() => clearField(41);

  @$pb.TagNumber(42)
  $core.bool get phpGenericServices => $_getBF(17);
  @$pb.TagNumber(42)
  set phpGenericServices($core.bool v) {
    $_setBool(17, v);
  }

  @$pb.TagNumber(42)
  $core.bool hasPhpGenericServices() => $_has(17);
  @$pb.TagNumber(42)
  void clearPhpGenericServices() => clearField(42);

  @$pb.TagNumber(44)
  $core.String get phpMetadataNamespace => $_getSZ(18);
  @$pb.TagNumber(44)
  set phpMetadataNamespace($core.String v) {
    $_setString(18, v);
  }

  @$pb.TagNumber(44)
  $core.bool hasPhpMetadataNamespace() => $_has(18);
  @$pb.TagNumber(44)
  void clearPhpMetadataNamespace() => clearField(44);

  @$pb.TagNumber(45)
  $core.String get rubyPackage => $_getSZ(19);
  @$pb.TagNumber(45)
  set rubyPackage($core.String v) {
    $_setString(19, v);
  }

  @$pb.TagNumber(45)
  $core.bool hasRubyPackage() => $_has(19);
  @$pb.TagNumber(45)
  void clearRubyPackage() => clearField(45);

  @$pb.TagNumber(999)
  $core.List<UninterpretedOption> get uninterpretedOption => $_getList(20);
}

class MessageOptions extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'MessageOptions',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..aOB(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'messageSetWireFormat')
    ..aOB(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'noStandardDescriptorAccessor')
    ..aOB(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'deprecated')
    ..aOB(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'mapEntry')
    ..pc<UninterpretedOption>(
        999,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'uninterpretedOption',
        $pb.PbFieldType.PM,
        subBuilder: UninterpretedOption.create)
    ..hasExtensions = true;

  MessageOptions._() : super();
  factory MessageOptions({
    $core.bool? messageSetWireFormat,
    $core.bool? noStandardDescriptorAccessor,
    $core.bool? deprecated,
    $core.bool? mapEntry,
    $core.Iterable<UninterpretedOption>? uninterpretedOption,
  }) {
    final _result = create();
    if (messageSetWireFormat != null) {
      _result.messageSetWireFormat = messageSetWireFormat;
    }
    if (noStandardDescriptorAccessor != null) {
      _result.noStandardDescriptorAccessor = noStandardDescriptorAccessor;
    }
    if (deprecated != null) {
      _result.deprecated = deprecated;
    }
    if (mapEntry != null) {
      _result.mapEntry = mapEntry;
    }
    if (uninterpretedOption != null) {
      _result.uninterpretedOption.addAll(uninterpretedOption);
    }
    return _result;
  }
  factory MessageOptions.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory MessageOptions.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  MessageOptions clone() => MessageOptions()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  MessageOptions copyWith(void Function(MessageOptions) updates) =>
      super.copyWith((message) => updates(message as MessageOptions))
          as MessageOptions; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MessageOptions create() => MessageOptions._();
  MessageOptions createEmptyInstance() => create();
  static $pb.PbList<MessageOptions> createRepeated() =>
      $pb.PbList<MessageOptions>();
  @$core.pragma('dart2js:noInline')
  static MessageOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MessageOptions>(create);
  static MessageOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get messageSetWireFormat => $_getBF(0);
  @$pb.TagNumber(1)
  set messageSetWireFormat($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasMessageSetWireFormat() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageSetWireFormat() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get noStandardDescriptorAccessor => $_getBF(1);
  @$pb.TagNumber(2)
  set noStandardDescriptorAccessor($core.bool v) {
    $_setBool(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasNoStandardDescriptorAccessor() => $_has(1);
  @$pb.TagNumber(2)
  void clearNoStandardDescriptorAccessor() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get deprecated => $_getBF(2);
  @$pb.TagNumber(3)
  set deprecated($core.bool v) {
    $_setBool(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasDeprecated() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeprecated() => clearField(3);

  @$pb.TagNumber(7)
  $core.bool get mapEntry => $_getBF(3);
  @$pb.TagNumber(7)
  set mapEntry($core.bool v) {
    $_setBool(3, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasMapEntry() => $_has(3);
  @$pb.TagNumber(7)
  void clearMapEntry() => clearField(7);

  @$pb.TagNumber(999)
  $core.List<UninterpretedOption> get uninterpretedOption => $_getList(4);
}

class FieldOptions extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'FieldOptions',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..e<FieldOptions_CType>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'ctype',
        $pb.PbFieldType.OE,
        defaultOrMaker: FieldOptions_CType.STRING,
        valueOf: FieldOptions_CType.valueOf,
        enumValues: FieldOptions_CType.values)
    ..aOB(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'packed')
    ..aOB(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'deprecated')
    ..aOB(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'lazy')
    ..e<FieldOptions_JSType>(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'jstype',
        $pb.PbFieldType.OE,
        defaultOrMaker: FieldOptions_JSType.JS_NORMAL,
        valueOf: FieldOptions_JSType.valueOf,
        enumValues: FieldOptions_JSType.values)
    ..aOB(
        10,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'weak')
    ..pc<UninterpretedOption>(
        999,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'uninterpretedOption',
        $pb.PbFieldType.PM,
        subBuilder: UninterpretedOption.create)
    ..hasExtensions = true;

  FieldOptions._() : super();
  factory FieldOptions({
    FieldOptions_CType? ctype,
    $core.bool? packed,
    $core.bool? deprecated,
    $core.bool? lazy,
    FieldOptions_JSType? jstype,
    $core.bool? weak,
    $core.Iterable<UninterpretedOption>? uninterpretedOption,
  }) {
    final _result = create();
    if (ctype != null) {
      _result.ctype = ctype;
    }
    if (packed != null) {
      _result.packed = packed;
    }
    if (deprecated != null) {
      _result.deprecated = deprecated;
    }
    if (lazy != null) {
      _result.lazy = lazy;
    }
    if (jstype != null) {
      _result.jstype = jstype;
    }
    if (weak != null) {
      _result.weak = weak;
    }
    if (uninterpretedOption != null) {
      _result.uninterpretedOption.addAll(uninterpretedOption);
    }
    return _result;
  }
  factory FieldOptions.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FieldOptions.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FieldOptions clone() => FieldOptions()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FieldOptions copyWith(void Function(FieldOptions) updates) =>
      super.copyWith((message) => updates(message as FieldOptions))
          as FieldOptions; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FieldOptions create() => FieldOptions._();
  FieldOptions createEmptyInstance() => create();
  static $pb.PbList<FieldOptions> createRepeated() =>
      $pb.PbList<FieldOptions>();
  @$core.pragma('dart2js:noInline')
  static FieldOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FieldOptions>(create);
  static FieldOptions? _defaultInstance;

  @$pb.TagNumber(1)
  FieldOptions_CType get ctype => $_getN(0);
  @$pb.TagNumber(1)
  set ctype(FieldOptions_CType v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCtype() => $_has(0);
  @$pb.TagNumber(1)
  void clearCtype() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get packed => $_getBF(1);
  @$pb.TagNumber(2)
  set packed($core.bool v) {
    $_setBool(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPacked() => $_has(1);
  @$pb.TagNumber(2)
  void clearPacked() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get deprecated => $_getBF(2);
  @$pb.TagNumber(3)
  set deprecated($core.bool v) {
    $_setBool(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasDeprecated() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeprecated() => clearField(3);

  @$pb.TagNumber(5)
  $core.bool get lazy => $_getBF(3);
  @$pb.TagNumber(5)
  set lazy($core.bool v) {
    $_setBool(3, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasLazy() => $_has(3);
  @$pb.TagNumber(5)
  void clearLazy() => clearField(5);

  @$pb.TagNumber(6)
  FieldOptions_JSType get jstype => $_getN(4);
  @$pb.TagNumber(6)
  set jstype(FieldOptions_JSType v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasJstype() => $_has(4);
  @$pb.TagNumber(6)
  void clearJstype() => clearField(6);

  @$pb.TagNumber(10)
  $core.bool get weak => $_getBF(5);
  @$pb.TagNumber(10)
  set weak($core.bool v) {
    $_setBool(5, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasWeak() => $_has(5);
  @$pb.TagNumber(10)
  void clearWeak() => clearField(10);

  @$pb.TagNumber(999)
  $core.List<UninterpretedOption> get uninterpretedOption => $_getList(6);
}

class OneofOptions extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'OneofOptions',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..pc<UninterpretedOption>(
        999,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'uninterpretedOption',
        $pb.PbFieldType.PM,
        subBuilder: UninterpretedOption.create)
    ..hasExtensions = true;

  OneofOptions._() : super();
  factory OneofOptions({
    $core.Iterable<UninterpretedOption>? uninterpretedOption,
  }) {
    final _result = create();
    if (uninterpretedOption != null) {
      _result.uninterpretedOption.addAll(uninterpretedOption);
    }
    return _result;
  }
  factory OneofOptions.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory OneofOptions.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  OneofOptions clone() => OneofOptions()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  OneofOptions copyWith(void Function(OneofOptions) updates) =>
      super.copyWith((message) => updates(message as OneofOptions))
          as OneofOptions; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static OneofOptions create() => OneofOptions._();
  OneofOptions createEmptyInstance() => create();
  static $pb.PbList<OneofOptions> createRepeated() =>
      $pb.PbList<OneofOptions>();
  @$core.pragma('dart2js:noInline')
  static OneofOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OneofOptions>(create);
  static OneofOptions? _defaultInstance;

  @$pb.TagNumber(999)
  $core.List<UninterpretedOption> get uninterpretedOption => $_getList(0);
}

class EnumOptions extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'EnumOptions',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..aOB(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'allowAlias')
    ..aOB(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'deprecated')
    ..pc<UninterpretedOption>(
        999,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'uninterpretedOption',
        $pb.PbFieldType.PM,
        subBuilder: UninterpretedOption.create)
    ..hasExtensions = true;

  EnumOptions._() : super();
  factory EnumOptions({
    $core.bool? allowAlias,
    $core.bool? deprecated,
    $core.Iterable<UninterpretedOption>? uninterpretedOption,
  }) {
    final _result = create();
    if (allowAlias != null) {
      _result.allowAlias = allowAlias;
    }
    if (deprecated != null) {
      _result.deprecated = deprecated;
    }
    if (uninterpretedOption != null) {
      _result.uninterpretedOption.addAll(uninterpretedOption);
    }
    return _result;
  }
  factory EnumOptions.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory EnumOptions.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  EnumOptions clone() => EnumOptions()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  EnumOptions copyWith(void Function(EnumOptions) updates) =>
      super.copyWith((message) => updates(message as EnumOptions))
          as EnumOptions; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EnumOptions create() => EnumOptions._();
  EnumOptions createEmptyInstance() => create();
  static $pb.PbList<EnumOptions> createRepeated() => $pb.PbList<EnumOptions>();
  @$core.pragma('dart2js:noInline')
  static EnumOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnumOptions>(create);
  static EnumOptions? _defaultInstance;

  @$pb.TagNumber(2)
  $core.bool get allowAlias => $_getBF(0);
  @$pb.TagNumber(2)
  set allowAlias($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasAllowAlias() => $_has(0);
  @$pb.TagNumber(2)
  void clearAllowAlias() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get deprecated => $_getBF(1);
  @$pb.TagNumber(3)
  set deprecated($core.bool v) {
    $_setBool(1, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasDeprecated() => $_has(1);
  @$pb.TagNumber(3)
  void clearDeprecated() => clearField(3);

  @$pb.TagNumber(999)
  $core.List<UninterpretedOption> get uninterpretedOption => $_getList(2);
}

class EnumValueOptions extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'EnumValueOptions',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..aOB(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'deprecated')
    ..pc<UninterpretedOption>(
        999,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'uninterpretedOption',
        $pb.PbFieldType.PM,
        subBuilder: UninterpretedOption.create)
    ..hasExtensions = true;

  EnumValueOptions._() : super();
  factory EnumValueOptions({
    $core.bool? deprecated,
    $core.Iterable<UninterpretedOption>? uninterpretedOption,
  }) {
    final _result = create();
    if (deprecated != null) {
      _result.deprecated = deprecated;
    }
    if (uninterpretedOption != null) {
      _result.uninterpretedOption.addAll(uninterpretedOption);
    }
    return _result;
  }
  factory EnumValueOptions.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory EnumValueOptions.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  EnumValueOptions clone() => EnumValueOptions()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  EnumValueOptions copyWith(void Function(EnumValueOptions) updates) =>
      super.copyWith((message) => updates(message as EnumValueOptions))
          as EnumValueOptions; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EnumValueOptions create() => EnumValueOptions._();
  EnumValueOptions createEmptyInstance() => create();
  static $pb.PbList<EnumValueOptions> createRepeated() =>
      $pb.PbList<EnumValueOptions>();
  @$core.pragma('dart2js:noInline')
  static EnumValueOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnumValueOptions>(create);
  static EnumValueOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get deprecated => $_getBF(0);
  @$pb.TagNumber(1)
  set deprecated($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasDeprecated() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeprecated() => clearField(1);

  @$pb.TagNumber(999)
  $core.List<UninterpretedOption> get uninterpretedOption => $_getList(1);
}

class ServiceOptions extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ServiceOptions',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..aOB(
        33,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'deprecated')
    ..pc<UninterpretedOption>(
        999,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'uninterpretedOption',
        $pb.PbFieldType.PM,
        subBuilder: UninterpretedOption.create)
    ..hasExtensions = true;

  ServiceOptions._() : super();
  factory ServiceOptions({
    $core.bool? deprecated,
    $core.Iterable<UninterpretedOption>? uninterpretedOption,
  }) {
    final _result = create();
    if (deprecated != null) {
      _result.deprecated = deprecated;
    }
    if (uninterpretedOption != null) {
      _result.uninterpretedOption.addAll(uninterpretedOption);
    }
    return _result;
  }
  factory ServiceOptions.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ServiceOptions.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ServiceOptions clone() => ServiceOptions()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ServiceOptions copyWith(void Function(ServiceOptions) updates) =>
      super.copyWith((message) => updates(message as ServiceOptions))
          as ServiceOptions; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ServiceOptions create() => ServiceOptions._();
  ServiceOptions createEmptyInstance() => create();
  static $pb.PbList<ServiceOptions> createRepeated() =>
      $pb.PbList<ServiceOptions>();
  @$core.pragma('dart2js:noInline')
  static ServiceOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServiceOptions>(create);
  static ServiceOptions? _defaultInstance;

  @$pb.TagNumber(33)
  $core.bool get deprecated => $_getBF(0);
  @$pb.TagNumber(33)
  set deprecated($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(33)
  $core.bool hasDeprecated() => $_has(0);
  @$pb.TagNumber(33)
  void clearDeprecated() => clearField(33);

  @$pb.TagNumber(999)
  $core.List<UninterpretedOption> get uninterpretedOption => $_getList(1);
}

class MethodOptions extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'MethodOptions',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..aOB(
        33,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'deprecated')
    ..e<MethodOptions_IdempotencyLevel>(
        34,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'idempotencyLevel',
        $pb.PbFieldType.OE,
        defaultOrMaker: MethodOptions_IdempotencyLevel.IDEMPOTENCY_UNKNOWN,
        valueOf: MethodOptions_IdempotencyLevel.valueOf,
        enumValues: MethodOptions_IdempotencyLevel.values)
    ..pc<UninterpretedOption>(
        999,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'uninterpretedOption',
        $pb.PbFieldType.PM,
        subBuilder: UninterpretedOption.create)
    ..hasExtensions = true;

  MethodOptions._() : super();
  factory MethodOptions({
    $core.bool? deprecated,
    MethodOptions_IdempotencyLevel? idempotencyLevel,
    $core.Iterable<UninterpretedOption>? uninterpretedOption,
  }) {
    final _result = create();
    if (deprecated != null) {
      _result.deprecated = deprecated;
    }
    if (idempotencyLevel != null) {
      _result.idempotencyLevel = idempotencyLevel;
    }
    if (uninterpretedOption != null) {
      _result.uninterpretedOption.addAll(uninterpretedOption);
    }
    return _result;
  }
  factory MethodOptions.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory MethodOptions.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  MethodOptions clone() => MethodOptions()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  MethodOptions copyWith(void Function(MethodOptions) updates) =>
      super.copyWith((message) => updates(message as MethodOptions))
          as MethodOptions; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MethodOptions create() => MethodOptions._();
  MethodOptions createEmptyInstance() => create();
  static $pb.PbList<MethodOptions> createRepeated() =>
      $pb.PbList<MethodOptions>();
  @$core.pragma('dart2js:noInline')
  static MethodOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MethodOptions>(create);
  static MethodOptions? _defaultInstance;

  @$pb.TagNumber(33)
  $core.bool get deprecated => $_getBF(0);
  @$pb.TagNumber(33)
  set deprecated($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(33)
  $core.bool hasDeprecated() => $_has(0);
  @$pb.TagNumber(33)
  void clearDeprecated() => clearField(33);

  @$pb.TagNumber(34)
  MethodOptions_IdempotencyLevel get idempotencyLevel => $_getN(1);
  @$pb.TagNumber(34)
  set idempotencyLevel(MethodOptions_IdempotencyLevel v) {
    setField(34, v);
  }

  @$pb.TagNumber(34)
  $core.bool hasIdempotencyLevel() => $_has(1);
  @$pb.TagNumber(34)
  void clearIdempotencyLevel() => clearField(34);

  @$pb.TagNumber(999)
  $core.List<UninterpretedOption> get uninterpretedOption => $_getList(2);
}

class UninterpretedOption_NamePart extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'UninterpretedOption.NamePart',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..aQS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'namePart')
    ..a<$core.bool>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'isExtension',
        $pb.PbFieldType.QB);

  UninterpretedOption_NamePart._() : super();
  factory UninterpretedOption_NamePart({
    $core.String? namePart,
    $core.bool? isExtension,
  }) {
    final _result = create();
    if (namePart != null) {
      _result.namePart = namePart;
    }
    if (isExtension != null) {
      _result.isExtension = isExtension;
    }
    return _result;
  }
  factory UninterpretedOption_NamePart.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory UninterpretedOption_NamePart.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  UninterpretedOption_NamePart clone() =>
      UninterpretedOption_NamePart()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  UninterpretedOption_NamePart copyWith(
          void Function(UninterpretedOption_NamePart) updates) =>
      super.copyWith(
              (message) => updates(message as UninterpretedOption_NamePart))
          as UninterpretedOption_NamePart; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UninterpretedOption_NamePart create() =>
      UninterpretedOption_NamePart._();
  UninterpretedOption_NamePart createEmptyInstance() => create();
  static $pb.PbList<UninterpretedOption_NamePart> createRepeated() =>
      $pb.PbList<UninterpretedOption_NamePart>();
  @$core.pragma('dart2js:noInline')
  static UninterpretedOption_NamePart getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UninterpretedOption_NamePart>(create);
  static UninterpretedOption_NamePart? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get namePart => $_getSZ(0);
  @$pb.TagNumber(1)
  set namePart($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasNamePart() => $_has(0);
  @$pb.TagNumber(1)
  void clearNamePart() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get isExtension => $_getBF(1);
  @$pb.TagNumber(2)
  set isExtension($core.bool v) {
    $_setBool(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasIsExtension() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsExtension() => clearField(2);
}

class UninterpretedOption extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'UninterpretedOption',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..pc<UninterpretedOption_NamePart>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'name',
        $pb.PbFieldType.PM,
        subBuilder: UninterpretedOption_NamePart.create)
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'identifierValue')
    ..a<$fixnum.Int64>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'positiveIntValue',
        $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aInt64(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'negativeIntValue')
    ..a<$core.double>(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'doubleValue',
        $pb.PbFieldType.OD)
    ..a<$core.List<$core.int>>(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'stringValue',
        $pb.PbFieldType.OY)
    ..aOS(
        8,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'aggregateValue');

  UninterpretedOption._() : super();
  factory UninterpretedOption({
    $core.Iterable<UninterpretedOption_NamePart>? name,
    $core.String? identifierValue,
    $fixnum.Int64? positiveIntValue,
    $fixnum.Int64? negativeIntValue,
    $core.double? doubleValue,
    $core.List<$core.int>? stringValue,
    $core.String? aggregateValue,
  }) {
    final _result = create();
    if (name != null) {
      _result.name.addAll(name);
    }
    if (identifierValue != null) {
      _result.identifierValue = identifierValue;
    }
    if (positiveIntValue != null) {
      _result.positiveIntValue = positiveIntValue;
    }
    if (negativeIntValue != null) {
      _result.negativeIntValue = negativeIntValue;
    }
    if (doubleValue != null) {
      _result.doubleValue = doubleValue;
    }
    if (stringValue != null) {
      _result.stringValue = stringValue;
    }
    if (aggregateValue != null) {
      _result.aggregateValue = aggregateValue;
    }
    return _result;
  }
  factory UninterpretedOption.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory UninterpretedOption.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  UninterpretedOption clone() => UninterpretedOption()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  UninterpretedOption copyWith(void Function(UninterpretedOption) updates) =>
      super.copyWith((message) => updates(message as UninterpretedOption))
          as UninterpretedOption; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UninterpretedOption create() => UninterpretedOption._();
  UninterpretedOption createEmptyInstance() => create();
  static $pb.PbList<UninterpretedOption> createRepeated() =>
      $pb.PbList<UninterpretedOption>();
  @$core.pragma('dart2js:noInline')
  static UninterpretedOption getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UninterpretedOption>(create);
  static UninterpretedOption? _defaultInstance;

  @$pb.TagNumber(2)
  $core.List<UninterpretedOption_NamePart> get name => $_getList(0);

  @$pb.TagNumber(3)
  $core.String get identifierValue => $_getSZ(1);
  @$pb.TagNumber(3)
  set identifierValue($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasIdentifierValue() => $_has(1);
  @$pb.TagNumber(3)
  void clearIdentifierValue() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get positiveIntValue => $_getI64(2);
  @$pb.TagNumber(4)
  set positiveIntValue($fixnum.Int64 v) {
    $_setInt64(2, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasPositiveIntValue() => $_has(2);
  @$pb.TagNumber(4)
  void clearPositiveIntValue() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get negativeIntValue => $_getI64(3);
  @$pb.TagNumber(5)
  set negativeIntValue($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasNegativeIntValue() => $_has(3);
  @$pb.TagNumber(5)
  void clearNegativeIntValue() => clearField(5);

  @$pb.TagNumber(6)
  $core.double get doubleValue => $_getN(4);
  @$pb.TagNumber(6)
  set doubleValue($core.double v) {
    $_setDouble(4, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasDoubleValue() => $_has(4);
  @$pb.TagNumber(6)
  void clearDoubleValue() => clearField(6);

  @$pb.TagNumber(7)
  $core.List<$core.int> get stringValue => $_getN(5);
  @$pb.TagNumber(7)
  set stringValue($core.List<$core.int> v) {
    $_setBytes(5, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasStringValue() => $_has(5);
  @$pb.TagNumber(7)
  void clearStringValue() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get aggregateValue => $_getSZ(6);
  @$pb.TagNumber(8)
  set aggregateValue($core.String v) {
    $_setString(6, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasAggregateValue() => $_has(6);
  @$pb.TagNumber(8)
  void clearAggregateValue() => clearField(8);
}

class SourceCodeInfo_Location extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SourceCodeInfo.Location',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..p<$core.int>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'path',
        $pb.PbFieldType.K3)
    ..p<$core.int>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'span',
        $pb.PbFieldType.K3)
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'leadingComments')
    ..aOS(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'trailingComments')
    ..pPS(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'leadingDetachedComments')
    ..hasRequiredFields = false;

  SourceCodeInfo_Location._() : super();
  factory SourceCodeInfo_Location({
    $core.Iterable<$core.int>? path,
    $core.Iterable<$core.int>? span,
    $core.String? leadingComments,
    $core.String? trailingComments,
    $core.Iterable<$core.String>? leadingDetachedComments,
  }) {
    final _result = create();
    if (path != null) {
      _result.path.addAll(path);
    }
    if (span != null) {
      _result.span.addAll(span);
    }
    if (leadingComments != null) {
      _result.leadingComments = leadingComments;
    }
    if (trailingComments != null) {
      _result.trailingComments = trailingComments;
    }
    if (leadingDetachedComments != null) {
      _result.leadingDetachedComments.addAll(leadingDetachedComments);
    }
    return _result;
  }
  factory SourceCodeInfo_Location.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SourceCodeInfo_Location.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SourceCodeInfo_Location clone() =>
      SourceCodeInfo_Location()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SourceCodeInfo_Location copyWith(
          void Function(SourceCodeInfo_Location) updates) =>
      super.copyWith((message) => updates(message as SourceCodeInfo_Location))
          as SourceCodeInfo_Location; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SourceCodeInfo_Location create() => SourceCodeInfo_Location._();
  SourceCodeInfo_Location createEmptyInstance() => create();
  static $pb.PbList<SourceCodeInfo_Location> createRepeated() =>
      $pb.PbList<SourceCodeInfo_Location>();
  @$core.pragma('dart2js:noInline')
  static SourceCodeInfo_Location getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SourceCodeInfo_Location>(create);
  static SourceCodeInfo_Location? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get path => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get span => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get leadingComments => $_getSZ(2);
  @$pb.TagNumber(3)
  set leadingComments($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasLeadingComments() => $_has(2);
  @$pb.TagNumber(3)
  void clearLeadingComments() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get trailingComments => $_getSZ(3);
  @$pb.TagNumber(4)
  set trailingComments($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasTrailingComments() => $_has(3);
  @$pb.TagNumber(4)
  void clearTrailingComments() => clearField(4);

  @$pb.TagNumber(6)
  $core.List<$core.String> get leadingDetachedComments => $_getList(4);
}

class SourceCodeInfo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SourceCodeInfo',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..pc<SourceCodeInfo_Location>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'location',
        $pb.PbFieldType.PM,
        subBuilder: SourceCodeInfo_Location.create)
    ..hasRequiredFields = false;

  SourceCodeInfo._() : super();
  factory SourceCodeInfo({
    $core.Iterable<SourceCodeInfo_Location>? location,
  }) {
    final _result = create();
    if (location != null) {
      _result.location.addAll(location);
    }
    return _result;
  }
  factory SourceCodeInfo.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SourceCodeInfo.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SourceCodeInfo clone() => SourceCodeInfo()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SourceCodeInfo copyWith(void Function(SourceCodeInfo) updates) =>
      super.copyWith((message) => updates(message as SourceCodeInfo))
          as SourceCodeInfo; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SourceCodeInfo create() => SourceCodeInfo._();
  SourceCodeInfo createEmptyInstance() => create();
  static $pb.PbList<SourceCodeInfo> createRepeated() =>
      $pb.PbList<SourceCodeInfo>();
  @$core.pragma('dart2js:noInline')
  static SourceCodeInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SourceCodeInfo>(create);
  static SourceCodeInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SourceCodeInfo_Location> get location => $_getList(0);
}

class GeneratedCodeInfo_Annotation extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'GeneratedCodeInfo.Annotation',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..p<$core.int>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'path',
        $pb.PbFieldType.K3)
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'sourceFile')
    ..a<$core.int>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'begin',
        $pb.PbFieldType.O3)
    ..a<$core.int>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'end',
        $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  GeneratedCodeInfo_Annotation._() : super();
  factory GeneratedCodeInfo_Annotation({
    $core.Iterable<$core.int>? path,
    $core.String? sourceFile,
    $core.int? begin,
    $core.int? end,
  }) {
    final _result = create();
    if (path != null) {
      _result.path.addAll(path);
    }
    if (sourceFile != null) {
      _result.sourceFile = sourceFile;
    }
    if (begin != null) {
      _result.begin = begin;
    }
    if (end != null) {
      _result.end = end;
    }
    return _result;
  }
  factory GeneratedCodeInfo_Annotation.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GeneratedCodeInfo_Annotation.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GeneratedCodeInfo_Annotation clone() =>
      GeneratedCodeInfo_Annotation()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GeneratedCodeInfo_Annotation copyWith(
          void Function(GeneratedCodeInfo_Annotation) updates) =>
      super.copyWith(
              (message) => updates(message as GeneratedCodeInfo_Annotation))
          as GeneratedCodeInfo_Annotation; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GeneratedCodeInfo_Annotation create() =>
      GeneratedCodeInfo_Annotation._();
  GeneratedCodeInfo_Annotation createEmptyInstance() => create();
  static $pb.PbList<GeneratedCodeInfo_Annotation> createRepeated() =>
      $pb.PbList<GeneratedCodeInfo_Annotation>();
  @$core.pragma('dart2js:noInline')
  static GeneratedCodeInfo_Annotation getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GeneratedCodeInfo_Annotation>(create);
  static GeneratedCodeInfo_Annotation? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get path => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get sourceFile => $_getSZ(1);
  @$pb.TagNumber(2)
  set sourceFile($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasSourceFile() => $_has(1);
  @$pb.TagNumber(2)
  void clearSourceFile() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get begin => $_getIZ(2);
  @$pb.TagNumber(3)
  set begin($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasBegin() => $_has(2);
  @$pb.TagNumber(3)
  void clearBegin() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get end => $_getIZ(3);
  @$pb.TagNumber(4)
  set end($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasEnd() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnd() => clearField(4);
}

class GeneratedCodeInfo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'GeneratedCodeInfo',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'google.protobuf'),
      createEmptyInstance: create)
    ..pc<GeneratedCodeInfo_Annotation>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'annotation',
        $pb.PbFieldType.PM,
        subBuilder: GeneratedCodeInfo_Annotation.create)
    ..hasRequiredFields = false;

  GeneratedCodeInfo._() : super();
  factory GeneratedCodeInfo({
    $core.Iterable<GeneratedCodeInfo_Annotation>? annotation,
  }) {
    final _result = create();
    if (annotation != null) {
      _result.annotation.addAll(annotation);
    }
    return _result;
  }
  factory GeneratedCodeInfo.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GeneratedCodeInfo.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GeneratedCodeInfo clone() => GeneratedCodeInfo()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GeneratedCodeInfo copyWith(void Function(GeneratedCodeInfo) updates) =>
      super.copyWith((message) => updates(message as GeneratedCodeInfo))
          as GeneratedCodeInfo; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GeneratedCodeInfo create() => GeneratedCodeInfo._();
  GeneratedCodeInfo createEmptyInstance() => create();
  static $pb.PbList<GeneratedCodeInfo> createRepeated() =>
      $pb.PbList<GeneratedCodeInfo>();
  @$core.pragma('dart2js:noInline')
  static GeneratedCodeInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GeneratedCodeInfo>(create);
  static GeneratedCodeInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<GeneratedCodeInfo_Annotation> get annotation => $_getList(0);
}
