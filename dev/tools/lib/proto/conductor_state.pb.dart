///
//  Generated code. Do not modify.
//  source: conductor_state.proto
//
// @dart = 2.7
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class Repository extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Repository',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'conductor_state'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'candidateBranch',
        protoName: 'candidateBranch')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'startingGitHead',
        protoName: 'startingGitHead')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'currentGitHead',
        protoName: 'currentGitHead')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'checkoutPath',
        protoName: 'checkoutPath')
    ..hasRequiredFields = false;

  Repository._() : super();
  factory Repository({
    $core.String candidateBranch,
    $core.String startingGitHead,
    $core.String currentGitHead,
    $core.String checkoutPath,
  }) {
    final _result = create();
    if (candidateBranch != null) {
      _result.candidateBranch = candidateBranch;
    }
    if (startingGitHead != null) {
      _result.startingGitHead = startingGitHead;
    }
    if (currentGitHead != null) {
      _result.currentGitHead = currentGitHead;
    }
    if (checkoutPath != null) {
      _result.checkoutPath = checkoutPath;
    }
    return _result;
  }
  factory Repository.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Repository.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Repository clone() => Repository()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Repository copyWith(void Function(Repository) updates) =>
      super.copyWith((message) => updates(message as Repository)); // ignore: deprecated_member_use
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
  set candidateBranch($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCandidateBranch() => $_has(0);
  @$pb.TagNumber(1)
  void clearCandidateBranch() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get startingGitHead => $_getSZ(1);
  @$pb.TagNumber(2)
  set startingGitHead($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasStartingGitHead() => $_has(1);
  @$pb.TagNumber(2)
  void clearStartingGitHead() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get currentGitHead => $_getSZ(2);
  @$pb.TagNumber(3)
  set currentGitHead($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasCurrentGitHead() => $_has(2);
  @$pb.TagNumber(3)
  void clearCurrentGitHead() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get checkoutPath => $_getSZ(3);
  @$pb.TagNumber(4)
  set checkoutPath($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasCheckoutPath() => $_has(3);
  @$pb.TagNumber(4)
  void clearCheckoutPath() => clearField(4);
}

class ConductorState extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ConductorState',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'conductor_state'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'releaseChannel',
        protoName: 'releaseChannel')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'releaseVersion',
        protoName: 'releaseVersion')
    ..aOM<Repository>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'engine',
        subBuilder: Repository.create)
    ..aOM<Repository>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'framework',
        subBuilder: Repository.create)
    ..aInt64(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createdDate',
        protoName: 'createdDate')
    ..aInt64(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'lastUpdatedDate',
        protoName: 'lastUpdatedDate')
    ..pPS(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'logs')
    ..hasRequiredFields = false;

  ConductorState._() : super();
  factory ConductorState({
    $core.String releaseChannel,
    $core.String releaseVersion,
    Repository engine,
    Repository framework,
    $fixnum.Int64 createdDate,
    $fixnum.Int64 lastUpdatedDate,
    $core.Iterable<$core.String> logs,
  }) {
    final _result = create();
    if (releaseChannel != null) {
      _result.releaseChannel = releaseChannel;
    }
    if (releaseVersion != null) {
      _result.releaseVersion = releaseVersion;
    }
    if (engine != null) {
      _result.engine = engine;
    }
    if (framework != null) {
      _result.framework = framework;
    }
    if (createdDate != null) {
      _result.createdDate = createdDate;
    }
    if (lastUpdatedDate != null) {
      _result.lastUpdatedDate = lastUpdatedDate;
    }
    if (logs != null) {
      _result.logs.addAll(logs);
    }
    return _result;
  }
  factory ConductorState.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ConductorState.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ConductorState clone() => ConductorState()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ConductorState copyWith(void Function(ConductorState) updates) =>
      super.copyWith((message) => updates(message as ConductorState)); // ignore: deprecated_member_use
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
  set releaseChannel($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasReleaseChannel() => $_has(0);
  @$pb.TagNumber(1)
  void clearReleaseChannel() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get releaseVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set releaseVersion($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasReleaseVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearReleaseVersion() => clearField(2);

  @$pb.TagNumber(4)
  Repository get engine => $_getN(2);
  @$pb.TagNumber(4)
  set engine(Repository v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasEngine() => $_has(2);
  @$pb.TagNumber(4)
  void clearEngine() => clearField(4);
  @$pb.TagNumber(4)
  Repository ensureEngine() => $_ensure(2);

  @$pb.TagNumber(5)
  Repository get framework => $_getN(3);
  @$pb.TagNumber(5)
  set framework(Repository v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasFramework() => $_has(3);
  @$pb.TagNumber(5)
  void clearFramework() => clearField(5);
  @$pb.TagNumber(5)
  Repository ensureFramework() => $_ensure(3);

  @$pb.TagNumber(6)
  $fixnum.Int64 get createdDate => $_getI64(4);
  @$pb.TagNumber(6)
  set createdDate($fixnum.Int64 v) {
    $_setInt64(4, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasCreatedDate() => $_has(4);
  @$pb.TagNumber(6)
  void clearCreatedDate() => clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get lastUpdatedDate => $_getI64(5);
  @$pb.TagNumber(7)
  set lastUpdatedDate($fixnum.Int64 v) {
    $_setInt64(5, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasLastUpdatedDate() => $_has(5);
  @$pb.TagNumber(7)
  void clearLastUpdatedDate() => clearField(7);

  @$pb.TagNumber(8)
  $core.List<$core.String> get logs => $_getList(6);
}
