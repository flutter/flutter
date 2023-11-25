// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/core/shader_types.h"

struct FlutterGPUUnlitVertexShader {
  struct PerVertexData {
    impeller::Point position;  // (offset 0, size 8)
  };                           // struct PerVertexData (size 8)

  static constexpr auto kInputPosition = impeller::ShaderStageIOSlot{
      // position
      "position",                    // name
      0u,                            // attribute location
      0u,                            // attribute set
      0u,                            // attribute binding
      impeller::ShaderType::kFloat,  // type
      32u,                           // bit width of type
      2u,                            // vec size
      1u,                            // number of columns
      0u,                            // offset for interleaved layout
  };

  static constexpr std::array<const impeller::ShaderStageIOSlot*, 1>
      kAllShaderStageInputs = {
          &kInputPosition,  // position
  };

  static constexpr auto kInterleavedLayout = impeller::ShaderStageBufferLayout{
      sizeof(PerVertexData),  // stride for interleaved layout
      0u,                     // attribute binding
  };
  static constexpr std::array<const impeller::ShaderStageBufferLayout*, 1>
      kInterleavedBufferLayout = {&kInterleavedLayout};
};

constexpr unsigned int kFlutterGPUUnlitVertIPLRLength = 856;
extern unsigned char kFlutterGPUUnlitVertIPLR[];

constexpr unsigned int kFlutterGPUUnlitFragIPLRLength = 556;
extern unsigned char kFlutterGPUUnlitFragIPLR[];
