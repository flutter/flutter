///
//  Generated code. Do not modify.
//  source: test.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'package1.pb.dart' as $1;
import 'package2.pb.dart' as $2;

class M extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'M', createEmptyInstance: create)
    ..aOM<M>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'm', subBuilder: M.create)
    ..aOM<$1.M>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'm1', subBuilder: $1.M.create)
    ..aOM<$2.M>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'm2', subBuilder: $2.M.create)
    ..hasRequiredFields = false
  ;

  M._() : super();
  factory M({
    M? m,
    $1.M? m1,
    $2.M? m2,
  }) {
    final _result = create();
    if (m != null) {
      _result.m = m;
    }
    if (m1 != null) {
      _result.m1 = m1;
    }
    if (m2 != null) {
      _result.m2 = m2;
    }
    return _result;
  }
  factory M.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory M.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  M clone() => M()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  M copyWith(void Function(M) updates) => super.copyWith((message) => updates(message as M)) as M; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static M create() => M._();
  M createEmptyInstance() => create();
  static $pb.PbList<M> createRepeated() => $pb.PbList<M>();
  @$core.pragma('dart2js:noInline')
  static M getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<M>(create);
  static M? _defaultInstance;

  @$pb.TagNumber(1)
  M get m => $_getN(0);
  @$pb.TagNumber(1)
  set m(M v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasM() => $_has(0);
  @$pb.TagNumber(1)
  void clearM() => clearField(1);
  @$pb.TagNumber(1)
  M ensureM() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.M get m1 => $_getN(1);
  @$pb.TagNumber(2)
  set m1($1.M v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasM1() => $_has(1);
  @$pb.TagNumber(2)
  void clearM1() => clearField(2);
  @$pb.TagNumber(2)
  $1.M ensureM1() => $_ensure(1);

  @$pb.TagNumber(3)
  $2.M get m2 => $_getN(2);
  @$pb.TagNumber(3)
  set m2($2.M v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasM2() => $_has(2);
  @$pb.TagNumber(3)
  void clearM2() => clearField(3);
  @$pb.TagNumber(3)
  $2.M ensureM2() => $_ensure(2);
}

