///
//  Generated code. Do not modify.
//  source: conductor_state.proto
//
// @dart = 2.7
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use releasePhaseDescriptor instead')
const ReleasePhase$json = const {
  '1': 'ReleasePhase',
  '2': const [
    const {'1': 'INITIALIZED', '2': 0},
    const {'1': 'ENGINE_CHERRYPICKS_APPLIED', '2': 1},
    const {'1': 'ENGINE_BINARIES_CODESIGNED', '2': 2},
    const {'1': 'FRAMEWORK_CHERRYPICKS_APPLIED', '2': 3},
    const {'1': 'VERSION_PUBLISHED', '2': 4},
    const {'1': 'CHANNEL_PUBLISHED', '2': 5},
    const {'1': 'RELEASE_VERIFIED', '2': 6},
  ],
};

/// Descriptor for `ReleasePhase`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List releasePhaseDescriptor = $convert.base64Decode(
    'CgxSZWxlYXNlUGhhc2USDwoLSU5JVElBTElaRUQQABIeChpFTkdJTkVfQ0hFUlJZUElDS1NfQVBQTElFRBABEh4KGkVOR0lORV9CSU5BUklFU19DT0RFU0lHTkVEEAISIQodRlJBTUVXT1JLX0NIRVJSWVBJQ0tTX0FQUExJRUQQAxIVChFWRVJTSU9OX1BVQkxJU0hFRBAEEhUKEUNIQU5ORUxfUFVCTElTSEVEEAUSFAoQUkVMRUFTRV9WRVJJRklFRBAG');
@$core.Deprecated('Use remoteDescriptor instead')
const Remote$json = const {
  '1': 'Remote',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'url', '3': 2, '4': 1, '5': 9, '10': 'url'},
  ],
};

/// Descriptor for `Remote`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List remoteDescriptor =
    $convert.base64Decode('CgZSZW1vdGUSEgoEbmFtZRgBIAEoCVIEbmFtZRIQCgN1cmwYAiABKAlSA3VybA==');
@$core.Deprecated('Use repositoryDescriptor instead')
const Repository$json = const {
  '1': 'Repository',
  '2': const [
    const {'1': 'candidateBranch', '3': 1, '4': 1, '5': 9, '10': 'candidateBranch'},
    const {'1': 'startingGitHead', '3': 2, '4': 1, '5': 9, '10': 'startingGitHead'},
    const {'1': 'currentGitHead', '3': 3, '4': 1, '5': 9, '10': 'currentGitHead'},
    const {'1': 'checkoutPath', '3': 4, '4': 1, '5': 9, '10': 'checkoutPath'},
    const {'1': 'upstream', '3': 5, '4': 1, '5': 11, '6': '.conductor_state.Remote', '10': 'upstream'},
    const {'1': 'mirror', '3': 6, '4': 1, '5': 11, '6': '.conductor_state.Remote', '10': 'mirror'},
    const {'1': 'cherrypicks', '3': 7, '4': 3, '5': 9, '10': 'cherrypicks'},
  ],
};

/// Descriptor for `Repository`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repositoryDescriptor = $convert.base64Decode(
    'CgpSZXBvc2l0b3J5EigKD2NhbmRpZGF0ZUJyYW5jaBgBIAEoCVIPY2FuZGlkYXRlQnJhbmNoEigKD3N0YXJ0aW5nR2l0SGVhZBgCIAEoCVIPc3RhcnRpbmdHaXRIZWFkEiYKDmN1cnJlbnRHaXRIZWFkGAMgASgJUg5jdXJyZW50R2l0SGVhZBIiCgxjaGVja291dFBhdGgYBCABKAlSDGNoZWNrb3V0UGF0aBIzCgh1cHN0cmVhbRgFIAEoCzIXLmNvbmR1Y3Rvcl9zdGF0ZS5SZW1vdGVSCHVwc3RyZWFtEi8KBm1pcnJvchgGIAEoCzIXLmNvbmR1Y3Rvcl9zdGF0ZS5SZW1vdGVSBm1pcnJvchIgCgtjaGVycnlwaWNrcxgHIAMoCVILY2hlcnJ5cGlja3M=');
@$core.Deprecated('Use conductorStateDescriptor instead')
const ConductorState$json = const {
  '1': 'ConductorState',
  '2': const [
    const {'1': 'releaseChannel', '3': 1, '4': 1, '5': 9, '10': 'releaseChannel'},
    const {'1': 'releaseVersion', '3': 2, '4': 1, '5': 9, '10': 'releaseVersion'},
    const {'1': 'engine', '3': 4, '4': 1, '5': 11, '6': '.conductor_state.Repository', '10': 'engine'},
    const {'1': 'framework', '3': 5, '4': 1, '5': 11, '6': '.conductor_state.Repository', '10': 'framework'},
    const {'1': 'createdDate', '3': 6, '4': 1, '5': 3, '10': 'createdDate'},
    const {'1': 'lastUpdatedDate', '3': 7, '4': 1, '5': 3, '10': 'lastUpdatedDate'},
    const {'1': 'logs', '3': 8, '4': 3, '5': 9, '10': 'logs'},
    const {'1': 'lastPhase', '3': 9, '4': 1, '5': 14, '6': '.conductor_state.ReleasePhase', '10': 'lastPhase'},
    const {'1': 'conductor_version', '3': 10, '4': 1, '5': 9, '10': 'conductorVersion'},
  ],
};

/// Descriptor for `ConductorState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List conductorStateDescriptor = $convert.base64Decode(
    'Cg5Db25kdWN0b3JTdGF0ZRImCg5yZWxlYXNlQ2hhbm5lbBgBIAEoCVIOcmVsZWFzZUNoYW5uZWwSJgoOcmVsZWFzZVZlcnNpb24YAiABKAlSDnJlbGVhc2VWZXJzaW9uEjMKBmVuZ2luZRgEIAEoCzIbLmNvbmR1Y3Rvcl9zdGF0ZS5SZXBvc2l0b3J5UgZlbmdpbmUSOQoJZnJhbWV3b3JrGAUgASgLMhsuY29uZHVjdG9yX3N0YXRlLlJlcG9zaXRvcnlSCWZyYW1ld29yaxIgCgtjcmVhdGVkRGF0ZRgGIAEoA1ILY3JlYXRlZERhdGUSKAoPbGFzdFVwZGF0ZWREYXRlGAcgASgDUg9sYXN0VXBkYXRlZERhdGUSEgoEbG9ncxgIIAMoCVIEbG9ncxI7CglsYXN0UGhhc2UYCSABKA4yHS5jb25kdWN0b3Jfc3RhdGUuUmVsZWFzZVBoYXNlUglsYXN0UGhhc2USKwoRY29uZHVjdG9yX3ZlcnNpb24YCiABKAlSEGNvbmR1Y3RvclZlcnNpb24=');
