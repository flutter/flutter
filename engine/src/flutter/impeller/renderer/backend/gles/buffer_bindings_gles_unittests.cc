// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/renderer/backend/gles/buffer_bindings_gles.h"
#include "impeller/renderer/backend/gles/device_buffer_gles.h"
#include "impeller/renderer/backend/gles/test/mock_gles.h"
#include "impeller/renderer/testing/mocks.h"

namespace impeller {
namespace testing {

TEST(BufferBindingsGLESTest, BindUniformData) {
  BufferBindingsGLES bindings;
  absl::flat_hash_map<std::string, GLint> uniform_bindings;
  uniform_bindings["SHADERMETADATA.FOOBAR"] = 1;
  bindings.SetUniformBindings(std::move(uniform_bindings));
  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init();
  Bindings vertex_bindings;

  ShaderMetadata shader_metadata = {
      .name = "shader_metadata",
      .members = {ShaderStructMemberMetadata{.type = ShaderType::kFloat,
                                             .name = "foobar",
                                             .offset = 0,
                                             .size = sizeof(float),
                                             .byte_length = sizeof(float)}}};
  std::shared_ptr<ReactorGLES> reactor;
  std::shared_ptr<Allocation> backing_store = std::make_shared<Allocation>();
  ASSERT_TRUE(backing_store->Truncate(Bytes{sizeof(float)}));
  DeviceBufferGLES device_buffer(DeviceBufferDescriptor{.size = sizeof(float)},
                                 reactor, backing_store);
  BufferView buffer_view(&device_buffer, Range(0, sizeof(float)));
  vertex_bindings.buffers.push_back(BufferAndUniformSlot{
      .slot =
          ShaderUniformSlot{
              .name = "foobar", .ext_res_0 = 0, .set = 0, .binding = 0},
      .view = BufferResource(&shader_metadata, buffer_view)});
  Bindings fragment_bindings;
  EXPECT_TRUE(bindings.BindUniformData(mock_gl->GetProcTable(), vertex_bindings,
                                       fragment_bindings));
  std::vector<std::string> captured_calls = mock_gl->GetCapturedCalls();
  EXPECT_TRUE(std::find(captured_calls.begin(), captured_calls.end(),
                        "glUniform1fv") != captured_calls.end());
}

}  // namespace testing
}  // namespace impeller
