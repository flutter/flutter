// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

///
//  Generated code. Do not modify.
//  source: conductor_state.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use releasePhaseDescriptor instead')
const ReleasePhase$json = const {
  '1': 'ReleasePhase',
  '2': const [
    const {'1': 'APPLY_ENGINE_CHERRYPICKS', '2': 0},
    const {'1': 'CODESIGN_ENGINE_BINARIES', '2': 1},
    const {'1': 'APPLY_FRAMEWORK_CHERRYPICKS', '2': 2},
    const {'1': 'PUBLISH_VERSION', '2': 3},
    const {'1': 'PUBLISH_CHANNEL', '2': 4},
    const {'1': 'VERIFY_RELEASE', '2': 5},
    const {'1': 'RELEASE_COMPLETED', '2': 6},
  ],
};

/// Descriptor for `ReleasePhase`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List releasePhaseDescriptor = $convert.base64Decode(
    'CgxSZWxlYXNlUGhhc2USHAoYQVBQTFlfRU5HSU5FX0NIRVJSWVBJQ0tTEAASHAoYQ09ERVNJR05fRU5HSU5FX0JJTkFSSUVTEAESHwobQVBQTFlfRlJBTUVXT1JLX0NIRVJSWVBJQ0tTEAISEwoPUFVCTElTSF9WRVJTSU9OEAMSEwoPUFVCTElTSF9DSEFOTkVMEAQSEgoOVkVSSUZZX1JFTEVBU0UQBRIVChFSRUxFQVNFX0NPTVBMRVRFRBAG');
@$core.Deprecated('Use releaseTypeDescriptor instead')
const ReleaseType$json = const {
  '1': 'ReleaseType',
  '2': const [
    const {'1': 'STABLE_INITIAL', '2': 0},
    const {'1': 'STABLE_HOTFIX', '2': 1},
    const {'1': 'BETA_INITIAL', '2': 2},
    const {'1': 'BETA_HOTFIX', '2': 3},
  ],
};

/// Descriptor for `ReleaseType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List releaseTypeDescriptor = $convert.base64Decode(
    'CgtSZWxlYXNlVHlwZRISCg5TVEFCTEVfSU5JVElBTBAAEhEKDVNUQUJMRV9IT1RGSVgQARIQCgxCRVRBX0lOSVRJQUwQAhIPCgtCRVRBX0hPVEZJWBAD');
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
    const {'1': 'dartRevision', '3': 7, '4': 1, '5': 9, '10': 'dartRevision'},
    const {'1': 'workingBranch', '3': 8, '4': 1, '5': 9, '10': 'workingBranch'},
  ],
};

/// Descriptor for `Repository`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repositoryDescriptor = $convert.base64Decode(
    'CgpSZXBvc2l0b3J5EigKD2NhbmRpZGF0ZUJyYW5jaBgBIAEoCVIPY2FuZGlkYXRlQnJhbmNoEigKD3N0YXJ0aW5nR2l0SGVhZBgCIAEoCVIPc3RhcnRpbmdHaXRIZWFkEiYKDmN1cnJlbnRHaXRIZWFkGAMgASgJUg5jdXJyZW50R2l0SGVhZBIiCgxjaGVja291dFBhdGgYBCABKAlSDGNoZWNrb3V0UGF0aBIzCgh1cHN0cmVhbRgFIAEoCzIXLmNvbmR1Y3Rvcl9zdGF0ZS5SZW1vdGVSCHVwc3RyZWFtEi8KBm1pcnJvchgGIAEoCzIXLmNvbmR1Y3Rvcl9zdGF0ZS5SZW1vdGVSBm1pcnJvchIiCgxkYXJ0UmV2aXNpb24YByABKAlSDGRhcnRSZXZpc2lvbhIkCg13b3JraW5nQnJhbmNoGAggASgJUg13b3JraW5nQnJhbmNo');
@$core.Deprecated('Use conductorStateDescriptor instead')
const ConductorState$json = const {
  '1': 'ConductorState',
  '2': const [
    const {'1': 'releaseChannel', '3': 1, '4': 1, '5': 9, '10': 'releaseChannel'},
    const {'1': 'releaseVersion', '3': 2, '4': 1, '5': 9, '10': 'releaseVersion'},
    const {'1': 'engine', '3': 3, '4': 1, '5': 11, '6': '.conductor_state.Repository', '10': 'engine'},
    const {'1': 'framework', '3': 4, '4': 1, '5': 11, '6': '.conductor_state.Repository', '10': 'framework'},
    const {'1': 'createdDate', '3': 5, '4': 1, '5': 3, '10': 'createdDate'},
    const {'1': 'lastUpdatedDate', '3': 6, '4': 1, '5': 3, '10': 'lastUpdatedDate'},
    const {'1': 'logs', '3': 7, '4': 3, '5': 9, '10': 'logs'},
    const {'1': 'currentPhase', '3': 8, '4': 1, '5': 14, '6': '.conductor_state.ReleasePhase', '10': 'currentPhase'},
    const {'1': 'conductorVersion', '3': 10, '4': 1, '5': 9, '10': 'conductorVersion'},
    const {'1': 'releaseType', '3': 11, '4': 1, '5': 14, '6': '.conductor_state.ReleaseType', '10': 'releaseType'},
  ],
};

/// Descriptor for `ConductorState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List conductorStateDescriptor = $convert.base64Decode(
    'Cg5Db25kdWN0b3JTdGF0ZRImCg5yZWxlYXNlQ2hhbm5lbBgBIAEoCVIOcmVsZWFzZUNoYW5uZWwSJgoOcmVsZWFzZVZlcnNpb24YAiABKAlSDnJlbGVhc2VWZXJzaW9uEjMKBmVuZ2luZRgDIAEoCzIbLmNvbmR1Y3Rvcl9zdGF0ZS5SZXBvc2l0b3J5UgZlbmdpbmUSOQoJZnJhbWV3b3JrGAQgASgLMhsuY29uZHVjdG9yX3N0YXRlLlJlcG9zaXRvcnlSCWZyYW1ld29yaxIgCgtjcmVhdGVkRGF0ZRgFIAEoA1ILY3JlYXRlZERhdGUSKAoPbGFzdFVwZGF0ZWREYXRlGAYgASgDUg9sYXN0VXBkYXRlZERhdGUSEgoEbG9ncxgHIAMoCVIEbG9ncxJBCgxjdXJyZW50UGhhc2UYCCABKA4yHS5jb25kdWN0b3Jfc3RhdGUuUmVsZWFzZVBoYXNlUgxjdXJyZW50UGhhc2USKgoQY29uZHVjdG9yVmVyc2lvbhgKIAEoCVIQY29uZHVjdG9yVmVyc2lvbhI+CgtyZWxlYXNlVHlwZRgLIAEoDjIcLmNvbmR1Y3Rvcl9zdGF0ZS5SZWxlYXNlVHlwZVILcmVsZWFzZVR5cGU=');
