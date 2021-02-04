///
//  Generated code. Do not modify.
//  source: conductor_state.proto
//
// @dart = 2.7
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Repository extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Repository', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'conductor_state'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'candidateBranch', protoName: 'candidateBranch')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'previousGitHead', protoName: 'previousGitHead')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'checkoutPath', protoName: 'checkoutPath')
    ..hasRequiredFields = false
  ;

  Repository._() : super();
  factory Repository({
    $core.String candidateBranch,
    $core.String previousGitHead,
    $core.String checkoutPath,
  }) {
    final _result = create();
    if (candidateBranch != null) {
      _result.candidateBranch = candidateBranch;
    }
    if (previousGitHead != null) {
      _result.previousGitHead = previousGitHead;
    }
    if (checkoutPath != null) {
      _result.checkoutPath = checkoutPath;
    }
    return _result;
  }
  factory Repository.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Repository.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Repository clone() => Repository()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Repository copyWith(void Function(Repository) updates) => super.copyWith((message) => updates(message as Repository)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Repository create() => Repository._();
  Repository createEmptyInstance() => create();
  static $pb.PbList<Repository> createRepeated() => $pb.PbList<Repository>();
  @$core.pragma('dart2js:noInline')
  static Repository getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Repository>(create);
  static Repository _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get candidateBranch => $_getSZ(0);
  @$pb.TagNumber(1)
  set candidateBranch($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCandidateBranch() => $_has(0);
  @$pb.TagNumber(1)
  void clearCandidateBranch() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get previousGitHead => $_getSZ(1);
  @$pb.TagNumber(2)
  set previousGitHead($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPreviousGitHead() => $_has(1);
  @$pb.TagNumber(2)
  void clearPreviousGitHead() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get checkoutPath => $_getSZ(2);
  @$pb.TagNumber(3)
  set checkoutPath($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasCheckoutPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearCheckoutPath() => clearField(3);
}

class ConductorState extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ConductorState', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'conductor_state'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'releaseChannel', protoName: 'releaseChannel')
    ..aOM<Repository>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'engine', subBuilder: Repository.create)
    ..aOM<Repository>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'framework', subBuilder: Repository.create)
    ..hasRequiredFields = false
  ;

  ConductorState._() : super();
  factory ConductorState({
    $core.String releaseChannel,
    Repository engine,
    Repository framework,
  }) {
    final _result = create();
    if (releaseChannel != null) {
      _result.releaseChannel = releaseChannel;
    }
    if (engine != null) {
      _result.engine = engine;
    }
    if (framework != null) {
      _result.framework = framework;
    }
    return _result;
  }
  factory ConductorState.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ConductorState.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ConductorState clone() => ConductorState()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ConductorState copyWith(void Function(ConductorState) updates) => super.copyWith((message) => updates(message as ConductorState)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ConductorState create() => ConductorState._();
  ConductorState createEmptyInstance() => create();
  static $pb.PbList<ConductorState> createRepeated() => $pb.PbList<ConductorState>();
  @$core.pragma('dart2js:noInline')
  static ConductorState getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConductorState>(create);
  static ConductorState _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get releaseChannel => $_getSZ(0);
  @$pb.TagNumber(1)
  set releaseChannel($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasReleaseChannel() => $_has(0);
  @$pb.TagNumber(1)
  void clearReleaseChannel() => clearField(1);

  @$pb.TagNumber(2)
  Repository get engine => $_getN(1);
  @$pb.TagNumber(2)
  set engine(Repository v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasEngine() => $_has(1);
  @$pb.TagNumber(2)
  void clearEngine() => clearField(2);
  @$pb.TagNumber(2)
  Repository ensureEngine() => $_ensure(1);

  @$pb.TagNumber(3)
  Repository get framework => $_getN(2);
  @$pb.TagNumber(3)
  set framework(Repository v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasFramework() => $_has(2);
  @$pb.TagNumber(3)
  void clearFramework() => clearField(3);
  @$pb.TagNumber(3)
  Repository ensureFramework() => $_ensure(2);
}

