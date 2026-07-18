// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_CODE_PUSH_CONFIG_H_
#define FLUTTER_SHELL_COMMON_CODE_PUSH_CONFIG_H_

namespace flutter {

// OTA Dart code push stores only the application isolate AOT snapshot blobs.
// The VM snapshot and engine native code continue to come from the store build.
struct CodePushConfig {
  static constexpr const char* kRootDirectoryName = "code_push";
  static constexpr const char* kActiveDirectoryName = "active";
  static constexpr const char* kStagingDirectoryName = "staging";
  static constexpr const char* kManifestFileName = "patch_manifest.json";
  static constexpr const char* kIsolateSnapshotDataFileName =
      "isolate_snapshot_data";
  static constexpr const char* kIsolateSnapshotInstructionsFileName =
      "isolate_snapshot_instr";
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_CODE_PUSH_CONFIG_H_
