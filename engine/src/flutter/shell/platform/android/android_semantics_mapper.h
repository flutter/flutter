// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SEMANTICS_MAPPER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SEMANTICS_MAPPER_H_

#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
namespace android {

/// @brief Encoded representation of a batch of semantics node updates.
struct EncodedSemanticsUpdate {
  std::vector<uint8_t> buffer;
  std::vector<std::string> strings;
  std::vector<std::vector<uint8_t>> string_attribute_args;

  bool empty() const { return buffer.empty(); }
};

/// @brief Encoded representation of custom accessibility action updates.
struct EncodedCustomAccessibilityActions {
  std::vector<uint8_t> buffer;
  std::vector<std::string> strings;

  bool empty() const { return buffer.empty(); }
};

/// @brief Aggregated batch of encoded semantics updates and custom actions.
struct EncodedSemanticsBatch {
  EncodedSemanticsUpdate nodes;
  EncodedCustomAccessibilityActions custom_actions;
  FlutterViewId view_id = 0;

  bool empty() const { return nodes.empty() && custom_actions.empty(); }
};

/// @brief Decoupled, C-ABI quarantined mapper that converts Embedder C-API
/// semantics tree structures into Android accessibility binary buffers.
///
/// Converts FlutterSemanticsUpdate2, FlutterSemanticsNode2, and
/// FlutterSemanticsCustomAction2 into the direct byte buffers and string
/// tables required by Android's AccessibilityBridge.
class AndroidSemanticsMapper {
 public:
  static constexpr size_t kBytesPerNode =
      73 * sizeof(int32_t);  // 73 fields in SemanticsNode
  static constexpr size_t kBytesPerChild = sizeof(int32_t);
  static constexpr size_t kBytesPerCustomAction = sizeof(int32_t);
  static constexpr size_t kBytesPerAction = 4 * sizeof(int32_t);
  static constexpr size_t kBytesPerStringAttribute = 4 * sizeof(int32_t);
  static constexpr int32_t kEmptyStringIndex = -1;

  /// @brief Maps a complete FlutterSemanticsUpdate2 batch into encoded buffers.
  static EncodedSemanticsBatch MapSemanticsUpdate(
      const FlutterSemanticsUpdate2& update);

  /// @brief Maps an array of FlutterSemanticsNode2 pointers into node buffers.
  static EncodedSemanticsUpdate MapNodes(const FlutterSemanticsNode2** nodes,
                                         size_t count);

  /// @brief Maps an array of FlutterSemanticsCustomAction2 pointers into action
  /// buffers.
  static EncodedCustomAccessibilityActions MapCustomActions(
      const FlutterSemanticsCustomAction2** actions,
      size_t count);

  /// @brief Encodes FlutterSemanticsFlags into the 64-bit flag bitmask expected
  /// by AccessibilityBridge.java.
  static int64_t EncodeFlags(const FlutterSemanticsFlags* flags2,
                             FlutterSemanticsFlag deprecated_flags =
                                 static_cast<FlutterSemanticsFlag>(0));

  /// @brief Encodes a FlutterTransformation into 16 column-major float values
  /// suitable for Android OpenGL Matrix multiplication.
  static void EncodeTransformation(const FlutterTransformation& transform,
                                   float* out_col_major_16);

  /// @brief Packs a string into strings table and writes its index to buffer.
  static void PutStringIntoBuffer(const char* str,
                                  int32_t* buffer,
                                  size_t* position,
                                  std::vector<std::string>& strings);

  /// @brief Packs string attributes into string_attribute_args table and writes
  /// indices/types to buffer.
  static void PutStringAttributesIntoBuffer(
      const FlutterStringAttribute** attributes,
      size_t count,
      int32_t* buffer,
      size_t* position,
      std::vector<std::vector<uint8_t>>& string_attribute_args);

 private:
  FML_DISALLOW_IMPLICIT_CONSTRUCTORS(AndroidSemanticsMapper);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SEMANTICS_MAPPER_H_
