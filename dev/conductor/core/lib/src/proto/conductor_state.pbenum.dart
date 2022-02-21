// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

///
//  Generated code. Do not modify.
//  source: conductor_state.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class ReleasePhase extends $pb.ProtobufEnum {
  static const ReleasePhase APPLY_ENGINE_CHERRYPICKS =
      ReleasePhase._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'APPLY_ENGINE_CHERRYPICKS');
  static const ReleasePhase CODESIGN_ENGINE_BINARIES =
      ReleasePhase._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CODESIGN_ENGINE_BINARIES');
  static const ReleasePhase APPLY_FRAMEWORK_CHERRYPICKS = ReleasePhase._(
      2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'APPLY_FRAMEWORK_CHERRYPICKS');
  static const ReleasePhase PUBLISH_VERSION =
      ReleasePhase._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PUBLISH_VERSION');
  static const ReleasePhase PUBLISH_CHANNEL =
      ReleasePhase._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PUBLISH_CHANNEL');
  static const ReleasePhase VERIFY_RELEASE =
      ReleasePhase._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'VERIFY_RELEASE');
  static const ReleasePhase RELEASE_COMPLETED =
      ReleasePhase._(6, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'RELEASE_COMPLETED');

  static const $core.List<ReleasePhase> values = <ReleasePhase>[
    APPLY_ENGINE_CHERRYPICKS,
    CODESIGN_ENGINE_BINARIES,
    APPLY_FRAMEWORK_CHERRYPICKS,
    PUBLISH_VERSION,
    PUBLISH_CHANNEL,
    VERIFY_RELEASE,
    RELEASE_COMPLETED,
  ];

  static final $core.Map<$core.int, ReleasePhase> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ReleasePhase? valueOf($core.int value) => _byValue[value];

  const ReleasePhase._($core.int v, $core.String n) : super(v, n);
}

class CherrypickState extends $pb.ProtobufEnum {
  static const CherrypickState PENDING =
      CherrypickState._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PENDING');
  static const CherrypickState PENDING_WITH_CONFLICT =
      CherrypickState._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PENDING_WITH_CONFLICT');
  static const CherrypickState COMPLETED =
      CherrypickState._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'COMPLETED');
  static const CherrypickState ABANDONED =
      CherrypickState._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ABANDONED');

  static const $core.List<CherrypickState> values = <CherrypickState>[
    PENDING,
    PENDING_WITH_CONFLICT,
    COMPLETED,
    ABANDONED,
  ];

  static final $core.Map<$core.int, CherrypickState> _byValue = $pb.ProtobufEnum.initByValue(values);
  static CherrypickState? valueOf($core.int value) => _byValue[value];

  const CherrypickState._($core.int v, $core.String n) : super(v, n);
}
