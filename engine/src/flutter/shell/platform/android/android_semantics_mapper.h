// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SEMANTICS_MAPPER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SEMANTICS_MAPPER_H_

#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter::android {

struct MappedSemanticsNodes {
  std::vector<uint8_t> buffer;
  std::vector<std::string> strings;
  std::vector<std::vector<uint8_t>> string_attribute_args;
};

struct MappedCustomActions {
  std::vector<uint8_t> buffer;
  std::vector<std::string> strings;
};

struct MappedSemanticsUpdate {
  MappedSemanticsNodes nodes;
  MappedCustomActions actions;
};

/// Serializes C-API `FlutterSemanticsUpdate2` payloads into the binary direct
/// `ByteBuffer` and string pool format expected by Android's
/// `AccessibilityBridge.java`, and dispatches accessibility actions via the
/// C-API `FlutterEngineProcTable`.
class AndroidSemanticsMapper {
 public:
  // 73 32-bit fields per serialized semantics node in AccessibilityBridge.java.
  static constexpr size_t kFixedFieldsPerNode = 73;
  static constexpr size_t kBytesPerNode = kFixedFieldsPerNode * sizeof(int32_t);
  static constexpr size_t kBytesPerChild = sizeof(int32_t);
  static constexpr size_t kBytesPerCustomAction = sizeof(int32_t);

  // 4 32-bit fields per custom accessibility action: id, overrideId, label,
  // hint.
  static constexpr size_t kFieldsPerAction = 4;
  static constexpr size_t kBytesPerAction = kFieldsPerAction * sizeof(int32_t);

  // 4 32-bit fields per string attribute: start, end, type, args_index.
  static constexpr size_t kFieldsPerStringAttribute = 4;
  static constexpr size_t kBytesPerStringAttribute =
      kFieldsPerStringAttribute * sizeof(int32_t);

  // Sentinel index indicating an absent or empty string / attribute payload.
  static constexpr int32_t kEmptyStringIndex = -1;

  // Number of float elements in a 4x4 column-major transformation matrix.
  static constexpr size_t kMatrixElementCount = 16;

  static MappedSemanticsUpdate MapUpdate(const FlutterSemanticsUpdate2* update);

  static MappedSemanticsNodes MapNodes(const FlutterSemanticsUpdate2* update);

  static MappedCustomActions MapCustomActions(
      const FlutterSemanticsUpdate2* update);

  static int64_t EncodeFlags(const FlutterSemanticsFlags* flags2,
                             FlutterSemanticsFlag deprecated_flags =
                                 static_cast<FlutterSemanticsFlag>(0));

  static void EncodeTransformation(const FlutterTransformation& transform,
                                   float* out_column_major_16);

  static FlutterSendSemanticsActionInfo BuildSendSemanticsActionInfo(
      int64_t view_id,
      uint64_t node_id,
      FlutterSemanticsAction action,
      const uint8_t* data,
      size_t data_length);

  static FlutterEngineResult DispatchSemanticsAction(
      const FlutterEngineProcTable& proc_table,
      FLUTTER_API_SYMBOL(FlutterEngine) engine,
      int64_t view_id,
      uint64_t node_id,
      FlutterSemanticsAction action,
      const uint8_t* data,
      size_t data_length);

  static FlutterEngineResult DispatchSemanticsAction(
      const FlutterEngineProcTable& proc_table,
      FLUTTER_API_SYMBOL(FlutterEngine) engine,
      uint64_t node_id,
      FlutterSemanticsAction action,
      const uint8_t* data,
      size_t data_length);

 private:
  FML_DISALLOW_IMPLICIT_CONSTRUCTORS(AndroidSemanticsMapper);
};

}  // namespace flutter::android

namespace flutter {

using MappedSemanticsNodes = android::MappedSemanticsNodes;
using MappedCustomActions = android::MappedCustomActions;
using MappedSemanticsUpdate = android::MappedSemanticsUpdate;
using AndroidSemanticsMapper = android::AndroidSemanticsMapper;

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SEMANTICS_MAPPER_H_
