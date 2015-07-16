// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains the mock GLES2Decoder class.

#ifndef GPU_COMMAND_BUFFER_SERVICE_GLES2_CMD_DECODER_MOCK_H_
#define GPU_COMMAND_BUFFER_SERVICE_GLES2_CMD_DECODER_MOCK_H_

#include <vector>

#include "base/callback_forward.h"
#include "gpu/command_buffer/common/mailbox.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "ui/gfx/geometry/size.h"

namespace gfx {
class GLContext;
class GLSurface;
}

namespace gpu {
namespace gles2 {

class ContextGroup;
class ErrorState;
class QueryManager;
struct ContextState;

class MockGLES2Decoder : public GLES2Decoder {
 public:
  MockGLES2Decoder();
  virtual ~MockGLES2Decoder();

  error::Error FakeDoCommands(unsigned int num_commands,
                              const void* buffer,
                              int num_entries,
                              int* entries_processed);

  MOCK_METHOD6(Initialize,
               bool(const scoped_refptr<gfx::GLSurface>& surface,
                    const scoped_refptr<gfx::GLContext>& context,
                    bool offscreen,
                    const gfx::Size& size,
                    const DisallowedFeatures& disallowed_features,
                    const std::vector<int32>& attribs));
  MOCK_METHOD1(Destroy, void(bool have_context));
  MOCK_METHOD1(SetSurface, void(const scoped_refptr<gfx::GLSurface>& surface));
  MOCK_METHOD1(ProduceFrontBuffer, void(const Mailbox& mailbox));
  MOCK_METHOD1(ResizeOffscreenFrameBuffer, bool(const gfx::Size& size));
  MOCK_METHOD0(MakeCurrent, bool());
  MOCK_METHOD1(GetServiceIdForTesting, uint32(uint32 client_id));
  MOCK_METHOD0(GetGLES2Util, GLES2Util*());
  MOCK_METHOD0(GetGLSurface, gfx::GLSurface*());
  MOCK_METHOD0(GetGLContext, gfx::GLContext*());
  MOCK_METHOD0(GetContextGroup, ContextGroup*());
  MOCK_METHOD0(GetContextState, const ContextState*());
  MOCK_METHOD0(GetCapabilities, Capabilities());
  MOCK_METHOD1(ProcessPendingQueries, bool(bool));
  MOCK_METHOD0(HasMoreIdleWork, bool());
  MOCK_METHOD0(PerformIdleWork, void());
  MOCK_METHOD1(RestoreState, void(const ContextState* prev_state));
  MOCK_CONST_METHOD0(RestoreActiveTexture, void());
  MOCK_CONST_METHOD1(
      RestoreAllTextureUnitBindings, void(const ContextState* state));
  MOCK_CONST_METHOD1(
      RestoreActiveTextureUnitBinding, void(unsigned int target));
  MOCK_CONST_METHOD0(RestoreBufferBindings, void());
  MOCK_CONST_METHOD0(RestoreFramebufferBindings, void());
  MOCK_CONST_METHOD0(RestoreGlobalState, void());
  MOCK_CONST_METHOD0(RestoreProgramBindings, void());
  MOCK_METHOD0(RestoreRenderbufferBindings, void());
  MOCK_CONST_METHOD1(RestoreTextureState, void(unsigned service_id));
  MOCK_CONST_METHOD1(RestoreTextureUnitBindings, void(unsigned unit));
  MOCK_CONST_METHOD0(ClearAllAttributes, void());
  MOCK_CONST_METHOD0(RestoreAllAttributes, void());
  MOCK_METHOD0(GetQueryManager, gpu::gles2::QueryManager*());
  MOCK_METHOD0(GetVertexArrayManager, gpu::gles2::VertexArrayManager*());
  MOCK_METHOD0(GetImageManager, gpu::gles2::ImageManager*());
  MOCK_METHOD0(GetValuebufferManager, gpu::gles2::ValuebufferManager*());
  MOCK_METHOD1(
      SetResizeCallback, void(const base::Callback<void(gfx::Size, float)>&));
  MOCK_METHOD0(GetAsyncPixelTransferDelegate,
      AsyncPixelTransferDelegate*());
  MOCK_METHOD0(GetAsyncPixelTransferManager,
      AsyncPixelTransferManager*());
  MOCK_METHOD0(ResetAsyncPixelTransferManagerForTest, void());
  MOCK_METHOD1(SetAsyncPixelTransferManagerForTest,
      void(AsyncPixelTransferManager*));
  MOCK_METHOD1(SetIgnoreCachedStateForTest, void(bool ignore));
  MOCK_METHOD3(DoCommand, error::Error(unsigned int command,
                                       unsigned int arg_count,
                                       const void* cmd_data));
  MOCK_METHOD4(DoCommands,
               error::Error(unsigned int num_commands,
                            const void* buffer,
                            int num_entries,
                            int* entries_processed));
  MOCK_METHOD2(GetServiceTextureId, bool(uint32 client_texture_id,
                                         uint32* service_texture_id));
  MOCK_METHOD0(GetContextLostReason, error::ContextLostReason());
  MOCK_CONST_METHOD1(GetCommandName, const char*(unsigned int command_id));
  MOCK_METHOD9(ClearLevel, bool(
      Texture* texture,
      unsigned target,
      int level,
      unsigned internal_format,
      unsigned format,
      unsigned type,
      int width,
      int height,
      bool is_texture_immutable));
  MOCK_METHOD0(GetErrorState, ErrorState *());

  MOCK_METHOD0(GetLogger, Logger*());
  MOCK_METHOD1(SetShaderCacheCallback,
               void(const ShaderCacheCallback& callback));
  MOCK_METHOD1(SetWaitSyncPointCallback,
               void(const WaitSyncPointCallback& callback));
  MOCK_METHOD1(WaitForReadPixels,
               void(base::Closure callback));
  MOCK_METHOD0(GetTextureUploadCount, uint32());
  MOCK_METHOD0(GetTotalTextureUploadTime, base::TimeDelta());
  MOCK_METHOD0(GetTotalProcessingCommandsTime, base::TimeDelta());
  MOCK_METHOD1(AddProcessingCommandsTime, void(base::TimeDelta));
  MOCK_CONST_METHOD0(WasContextLost, bool());
  MOCK_CONST_METHOD0(WasContextLostByRobustnessExtension, bool());
  MOCK_METHOD1(MarkContextLost, void(gpu::error::ContextLostReason reason));

  DISALLOW_COPY_AND_ASSIGN(MockGLES2Decoder);
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_GLES2_CMD_DECODER_MOCK_H_
