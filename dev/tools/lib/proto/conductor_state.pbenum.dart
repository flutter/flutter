///
//  Generated code. Do not modify.
//  source: conductor_state.proto
//
// @dart = 2.7
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class ReleasePhase extends $pb.ProtobufEnum {
  static const ReleasePhase INITIALIZED =
      ReleasePhase._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'INITIALIZED');
  static const ReleasePhase ENGINE_CHERRYPICKS_APPLIED = ReleasePhase._(
      1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ENGINE_CHERRYPICKS_APPLIED');
  static const ReleasePhase ENGINE_BINARIES_CODESIGNED = ReleasePhase._(
      2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ENGINE_BINARIES_CODESIGNED');
  static const ReleasePhase FRAMEWORK_CHERRYPICKS_APPLIED = ReleasePhase._(
      3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'FRAMEWORK_CHERRYPICKS_APPLIED');
  static const ReleasePhase VERSION_PUBLISHED =
      ReleasePhase._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'VERSION_PUBLISHED');
  static const ReleasePhase CHANNEL_PUBLISHED =
      ReleasePhase._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CHANNEL_PUBLISHED');
  static const ReleasePhase RELEASE_VERIFIED =
      ReleasePhase._(6, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'RELEASE_VERIFIED');

  static const $core.List<ReleasePhase> values = <ReleasePhase>[
    INITIALIZED,
    ENGINE_CHERRYPICKS_APPLIED,
    ENGINE_BINARIES_CODESIGNED,
    FRAMEWORK_CHERRYPICKS_APPLIED,
    VERSION_PUBLISHED,
    CHANNEL_PUBLISHED,
    RELEASE_VERIFIED,
  ];

  static final $core.Map<$core.int, ReleasePhase> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ReleasePhase valueOf($core.int value) => _byValue[value];

  const ReleasePhase._($core.int v, $core.String n) : super(v, n);
}
