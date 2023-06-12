///
//  Generated code. Do not modify.
//  source: generator/fonts.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class FileSpec extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'FileSpec',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'fonts'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'filename')
    ..aInt64(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'fileSize')
    ..a<$core.List<$core.int>>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'hash',
        $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  FileSpec._() : super();
  factory FileSpec({
    $core.String? filename,
    $fixnum.Int64? fileSize,
    $core.List<$core.int>? hash,
  }) {
    final _result = create();
    if (filename != null) {
      _result.filename = filename;
    }
    if (fileSize != null) {
      _result.fileSize = fileSize;
    }
    if (hash != null) {
      _result.hash = hash;
    }
    return _result;
  }
  factory FileSpec.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FileSpec.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FileSpec clone() => FileSpec()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FileSpec copyWith(void Function(FileSpec) updates) =>
      super.copyWith((message) => updates(message as FileSpec))
          as FileSpec; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FileSpec create() => FileSpec._();
  FileSpec createEmptyInstance() => create();
  static $pb.PbList<FileSpec> createRepeated() => $pb.PbList<FileSpec>();
  @$core.pragma('dart2js:noInline')
  static FileSpec getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FileSpec>(create);
  static FileSpec? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get filename => $_getSZ(0);
  @$pb.TagNumber(1)
  set filename($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasFilename() => $_has(0);
  @$pb.TagNumber(1)
  void clearFilename() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get fileSize => $_getI64(1);
  @$pb.TagNumber(2)
  set fileSize($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasFileSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearFileSize() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get hash => $_getN(2);
  @$pb.TagNumber(3)
  set hash($core.List<$core.int> v) {
    $_setBytes(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasHash() => $_has(2);
  @$pb.TagNumber(3)
  void clearHash() => clearField(3);
}

class IntRange extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'IntRange',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'fonts'),
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

  IntRange._() : super();
  factory IntRange({
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
  factory IntRange.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory IntRange.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  IntRange clone() => IntRange()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  IntRange copyWith(void Function(IntRange) updates) =>
      super.copyWith((message) => updates(message as IntRange))
          as IntRange; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static IntRange create() => IntRange._();
  IntRange createEmptyInstance() => create();
  static $pb.PbList<IntRange> createRepeated() => $pb.PbList<IntRange>();
  @$core.pragma('dart2js:noInline')
  static IntRange getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IntRange>(create);
  static IntRange? _defaultInstance;

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

class FloatRange extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'FloatRange',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'fonts'),
      createEmptyInstance: create)
    ..a<$core.double>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'start',
        $pb.PbFieldType.OF)
    ..a<$core.double>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'end',
        $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  FloatRange._() : super();
  factory FloatRange({
    $core.double? start,
    $core.double? end,
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
  factory FloatRange.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FloatRange.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FloatRange clone() => FloatRange()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FloatRange copyWith(void Function(FloatRange) updates) =>
      super.copyWith((message) => updates(message as FloatRange))
          as FloatRange; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FloatRange create() => FloatRange._();
  FloatRange createEmptyInstance() => create();
  static $pb.PbList<FloatRange> createRepeated() => $pb.PbList<FloatRange>();
  @$core.pragma('dart2js:noInline')
  static FloatRange getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FloatRange>(create);
  static FloatRange? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get start => $_getN(0);
  @$pb.TagNumber(1)
  set start($core.double v) {
    $_setFloat(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasStart() => $_has(0);
  @$pb.TagNumber(1)
  void clearStart() => clearField(1);

  @$pb.TagNumber(2)
  $core.double get end => $_getN(1);
  @$pb.TagNumber(2)
  set end($core.double v) {
    $_setFloat(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasEnd() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnd() => clearField(2);
}

class Font extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'Font',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'fonts'),
      createEmptyInstance: create)
    ..aOM<FileSpec>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'file',
        subBuilder: FileSpec.create)
    ..aOM<IntRange>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'weight',
        subBuilder: IntRange.create)
    ..aOM<FloatRange>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'width',
        subBuilder: FloatRange.create)
    ..aOM<FloatRange>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'italic',
        subBuilder: FloatRange.create)
    ..a<$core.int>(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'ttcIndex',
        $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  Font._() : super();
  factory Font({
    FileSpec? file,
    IntRange? weight,
    FloatRange? width,
    FloatRange? italic,
    $core.int? ttcIndex,
  }) {
    final _result = create();
    if (file != null) {
      _result.file = file;
    }
    if (weight != null) {
      _result.weight = weight;
    }
    if (width != null) {
      _result.width = width;
    }
    if (italic != null) {
      _result.italic = italic;
    }
    if (ttcIndex != null) {
      _result.ttcIndex = ttcIndex;
    }
    return _result;
  }
  factory Font.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Font.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Font clone() => Font()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Font copyWith(void Function(Font) updates) =>
      super.copyWith((message) => updates(message as Font))
          as Font; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Font create() => Font._();
  Font createEmptyInstance() => create();
  static $pb.PbList<Font> createRepeated() => $pb.PbList<Font>();
  @$core.pragma('dart2js:noInline')
  static Font getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Font>(create);
  static Font? _defaultInstance;

  @$pb.TagNumber(1)
  FileSpec get file => $_getN(0);
  @$pb.TagNumber(1)
  set file(FileSpec v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasFile() => $_has(0);
  @$pb.TagNumber(1)
  void clearFile() => clearField(1);
  @$pb.TagNumber(1)
  FileSpec ensureFile() => $_ensure(0);

  @$pb.TagNumber(2)
  IntRange get weight => $_getN(1);
  @$pb.TagNumber(2)
  set weight(IntRange v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasWeight() => $_has(1);
  @$pb.TagNumber(2)
  void clearWeight() => clearField(2);
  @$pb.TagNumber(2)
  IntRange ensureWeight() => $_ensure(1);

  @$pb.TagNumber(3)
  FloatRange get width => $_getN(2);
  @$pb.TagNumber(3)
  set width(FloatRange v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasWidth() => $_has(2);
  @$pb.TagNumber(3)
  void clearWidth() => clearField(3);
  @$pb.TagNumber(3)
  FloatRange ensureWidth() => $_ensure(2);

  @$pb.TagNumber(4)
  FloatRange get italic => $_getN(3);
  @$pb.TagNumber(4)
  set italic(FloatRange v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasItalic() => $_has(3);
  @$pb.TagNumber(4)
  void clearItalic() => clearField(4);
  @$pb.TagNumber(4)
  FloatRange ensureItalic() => $_ensure(3);

  @$pb.TagNumber(7)
  $core.int get ttcIndex => $_getIZ(4);
  @$pb.TagNumber(7)
  set ttcIndex($core.int v) {
    $_setSignedInt32(4, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasTtcIndex() => $_has(4);
  @$pb.TagNumber(7)
  void clearTtcIndex() => clearField(7);
}

class FontFamily extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'FontFamily',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'fonts'),
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
            : 'version',
        $pb.PbFieldType.O3)
    ..pc<Font>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'fonts',
        $pb.PbFieldType.PM,
        subBuilder: Font.create)
    ..hasRequiredFields = false;

  FontFamily._() : super();
  factory FontFamily({
    $core.String? name,
    $core.int? version,
    $core.Iterable<Font>? fonts,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (version != null) {
      _result.version = version;
    }
    if (fonts != null) {
      _result.fonts.addAll(fonts);
    }
    return _result;
  }
  factory FontFamily.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FontFamily.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FontFamily clone() => FontFamily()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FontFamily copyWith(void Function(FontFamily) updates) =>
      super.copyWith((message) => updates(message as FontFamily))
          as FontFamily; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FontFamily create() => FontFamily._();
  FontFamily createEmptyInstance() => create();
  static $pb.PbList<FontFamily> createRepeated() => $pb.PbList<FontFamily>();
  @$core.pragma('dart2js:noInline')
  static FontFamily getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FontFamily>(create);
  static FontFamily? _defaultInstance;

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
  $core.int get version => $_getIZ(1);
  @$pb.TagNumber(2)
  set version($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => clearField(2);

  @$pb.TagNumber(4)
  $core.List<Font> get fonts => $_getList(2);
}

class Directory extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'Directory',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'fonts'),
      createEmptyInstance: create)
    ..pc<FontFamily>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'family',
        $pb.PbFieldType.PM,
        subBuilder: FontFamily.create)
    ..p<$core.int>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'nameLookup',
        $pb.PbFieldType.P3)
    ..pPS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'strings')
    ..p<$core.int>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'prefetch',
        $pb.PbFieldType.P3)
    ..a<$core.int>(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'version',
        $pb.PbFieldType.O3)
    ..aOS(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'description')
    ..hasRequiredFields = false;

  Directory._() : super();
  factory Directory({
    $core.Iterable<FontFamily>? family,
    $core.Iterable<$core.int>? nameLookup,
    $core.Iterable<$core.String>? strings,
    $core.Iterable<$core.int>? prefetch,
    $core.int? version,
    $core.String? description,
  }) {
    final _result = create();
    if (family != null) {
      _result.family.addAll(family);
    }
    if (nameLookup != null) {
      _result.nameLookup.addAll(nameLookup);
    }
    if (strings != null) {
      _result.strings.addAll(strings);
    }
    if (prefetch != null) {
      _result.prefetch.addAll(prefetch);
    }
    if (version != null) {
      _result.version = version;
    }
    if (description != null) {
      _result.description = description;
    }
    return _result;
  }
  factory Directory.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Directory.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Directory clone() => Directory()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Directory copyWith(void Function(Directory) updates) =>
      super.copyWith((message) => updates(message as Directory))
          as Directory; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Directory create() => Directory._();
  Directory createEmptyInstance() => create();
  static $pb.PbList<Directory> createRepeated() => $pb.PbList<Directory>();
  @$core.pragma('dart2js:noInline')
  static Directory getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Directory>(create);
  static Directory? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<FontFamily> get family => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get nameLookup => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<$core.String> get strings => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<$core.int> get prefetch => $_getList(3);

  @$pb.TagNumber(5)
  $core.int get version => $_getIZ(4);
  @$pb.TagNumber(5)
  set version($core.int v) {
    $_setSignedInt32(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasVersion() => $_has(4);
  @$pb.TagNumber(5)
  void clearVersion() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get description => $_getSZ(5);
  @$pb.TagNumber(6)
  set description($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasDescription() => $_has(5);
  @$pb.TagNumber(6)
  void clearDescription() => clearField(6);
}
