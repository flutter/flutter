///
//  Generated code. Do not modify.
//  source: conductor_state.proto
//
// @dart = 2.7
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

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

const Remote$json = const {
  '1': 'Remote',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'url', '3': 2, '4': 1, '5': 9, '10': 'url'},
  ],
};

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
    const {'1': 'currentPhase', '3': 9, '4': 1, '5': 14, '6': '.conductor_state.ReleasePhase', '10': 'currentPhase'},
  ],
};
