// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/gles2_cmd_decoder.h"

#include "base/command_line.h"
#include "base/strings/string_number_conversions.h"
#include "gpu/command_buffer/common/gles2_cmd_format.h"
#include "gpu/command_buffer/common/gles2_cmd_utils.h"
#include "gpu/command_buffer/common/id_allocator.h"
#include "gpu/command_buffer/service/async_pixel_transfer_delegate_mock.h"
#include "gpu/command_buffer/service/async_pixel_transfer_manager.h"
#include "gpu/command_buffer/service/async_pixel_transfer_manager_mock.h"
#include "gpu/command_buffer/service/cmd_buffer_engine.h"
#include "gpu/command_buffer/service/context_group.h"
#include "gpu/command_buffer/service/context_state.h"
#include "gpu/command_buffer/service/gl_surface_mock.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder_unittest.h"

#include "gpu/command_buffer/service/gpu_switches.h"
#include "gpu/command_buffer/service/image_manager.h"
#include "gpu/command_buffer/service/mailbox_manager.h"
#include "gpu/command_buffer/service/mocks.h"
#include "gpu/command_buffer/service/program_manager.h"
#include "gpu/command_buffer/service/test_helper.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_mock.h"
#include "ui/gl/gl_surface_stub.h"

#if !defined(GL_DEPTH24_STENCIL8)
#define GL_DEPTH24_STENCIL8 0x88F0
#endif

using ::gfx::MockGLInterface;
using ::testing::_;
using ::testing::DoAll;
using ::testing::InSequence;
using ::testing::Invoke;
using ::testing::MatcherCast;
using ::testing::Mock;
using ::testing::Pointee;
using ::testing::Return;
using ::testing::SaveArg;
using ::testing::SetArrayArgument;
using ::testing::SetArgumentPointee;
using ::testing::SetArgPointee;
using ::testing::StrEq;
using ::testing::StrictMock;

namespace gpu {
namespace gles2 {

using namespace cmds;

TEST_P(GLES2DecoderManualInitTest, AsyncPixelTransfers) {
  InitState init;
  init.extensions = "GL_CHROMIUM_async_pixel_transfers";
  init.bind_generates_resource = true;
  InitDecoder(init);

  // Set up the texture.
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  TextureRef* texture_ref = GetTexture(client_texture_id_);
  Texture* texture = texture_ref->texture();

  // Set a mock Async delegate
  StrictMock<gpu::MockAsyncPixelTransferManager>* manager =
      new StrictMock<gpu::MockAsyncPixelTransferManager>;
  manager->Initialize(group().texture_manager());
  decoder_->SetAsyncPixelTransferManagerForTest(manager);
  StrictMock<gpu::MockAsyncPixelTransferDelegate>* delegate = NULL;

  // Tex(Sub)Image2D upload commands.
  AsyncTexImage2DCHROMIUM teximage_cmd;
  teximage_cmd.Init(GL_TEXTURE_2D,
                    0,
                    GL_RGBA,
                    8,
                    8,
                    GL_RGBA,
                    GL_UNSIGNED_BYTE,
                    kSharedMemoryId,
                    kSharedMemoryOffset,
                    0,
                    0,
                    0);
  AsyncTexSubImage2DCHROMIUM texsubimage_cmd;
  texsubimage_cmd.Init(GL_TEXTURE_2D,
                       0,
                       0,
                       0,
                       8,
                       8,
                       GL_RGBA,
                       GL_UNSIGNED_BYTE,
                       kSharedMemoryId,
                       kSharedMemoryOffset,
                       0,
                       0,
                       0);
  WaitAsyncTexImage2DCHROMIUM wait_cmd;
  wait_cmd.Init(GL_TEXTURE_2D);
  WaitAllAsyncTexImage2DCHROMIUM wait_all_cmd;
  wait_all_cmd.Init();

  // No transfer state exists initially.
  EXPECT_FALSE(
      decoder_->GetAsyncPixelTransferManager()->GetPixelTransferDelegate(
          texture_ref));

  base::Closure bind_callback;

  // AsyncTexImage2D
  {
    // Create transfer state since it doesn't exist.
    EXPECT_EQ(texture_ref->num_observers(), 0);
    EXPECT_CALL(*manager, CreatePixelTransferDelegateImpl(texture_ref, _))
        .WillOnce(Return(
            delegate = new StrictMock<gpu::MockAsyncPixelTransferDelegate>))
        .RetiresOnSaturation();
    EXPECT_CALL(*delegate, AsyncTexImage2D(_, _, _))
        .WillOnce(SaveArg<2>(&bind_callback))
        .RetiresOnSaturation();
    // Command succeeds.
    EXPECT_EQ(error::kNoError, ExecuteCmd(teximage_cmd));
    EXPECT_EQ(GL_NO_ERROR, GetGLError());
    EXPECT_EQ(
        delegate,
        decoder_->GetAsyncPixelTransferManager()->GetPixelTransferDelegate(
            texture_ref));
    EXPECT_TRUE(texture->IsImmutable());
    // The texture is safe but the level has not been defined yet.
    EXPECT_TRUE(texture->SafeToRenderFrom());
    GLsizei width, height;
    EXPECT_FALSE(texture->GetLevelSize(GL_TEXTURE_2D, 0, &width, &height));
    EXPECT_EQ(texture_ref->num_observers(), 1);
  }
  {
    // Async redefinitions are not allowed!
    // Command fails.
    EXPECT_EQ(error::kNoError, ExecuteCmd(teximage_cmd));
    EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
    EXPECT_EQ(
        delegate,
        decoder_->GetAsyncPixelTransferManager()->GetPixelTransferDelegate(
            texture_ref));
    EXPECT_TRUE(texture->IsImmutable());
    EXPECT_TRUE(texture->SafeToRenderFrom());
  }

  // Binding/defining of the async transfer
  {
    // TODO(epenner): We should check that the manager gets the
    // BindCompletedAsyncTransfers() call, which is required to
    // guarantee the delegate calls the bind callback.

    // Simulate the bind callback from the delegate.
    bind_callback.Run();

    // After the bind callback is run, the texture is safe,
    // and has the right size etc.
    EXPECT_TRUE(texture->SafeToRenderFrom());
    GLsizei width, height;
    EXPECT_TRUE(texture->GetLevelSize(GL_TEXTURE_2D, 0, &width, &height));
    EXPECT_EQ(width, 8);
    EXPECT_EQ(height, 8);
  }

  // AsyncTexSubImage2D
  EXPECT_CALL(*delegate, Destroy()).RetiresOnSaturation();
  decoder_->GetAsyncPixelTransferManager()->ClearPixelTransferDelegateForTest(
      texture_ref);
  EXPECT_EQ(texture_ref->num_observers(), 0);
  texture->SetImmutable(false);
  {
    // Create transfer state since it doesn't exist.
    EXPECT_CALL(*manager, CreatePixelTransferDelegateImpl(texture_ref, _))
        .WillOnce(Return(
            delegate = new StrictMock<gpu::MockAsyncPixelTransferDelegate>))
        .RetiresOnSaturation();
    EXPECT_CALL(*delegate, AsyncTexSubImage2D(_, _)).RetiresOnSaturation();
    // Command succeeds.
    EXPECT_EQ(error::kNoError, ExecuteCmd(texsubimage_cmd));
    EXPECT_EQ(GL_NO_ERROR, GetGLError());
    EXPECT_EQ(
        delegate,
        decoder_->GetAsyncPixelTransferManager()->GetPixelTransferDelegate(
            texture_ref));
    EXPECT_TRUE(texture->IsImmutable());
    EXPECT_TRUE(texture->SafeToRenderFrom());
  }
  {
    // No transfer is in progress.
    EXPECT_CALL(*delegate, TransferIsInProgress())
        .WillOnce(Return(false))  // texSubImage validation
        .WillOnce(Return(false))  // async validation
        .RetiresOnSaturation();
    EXPECT_CALL(*delegate, AsyncTexSubImage2D(_, _)).RetiresOnSaturation();
    // Command succeeds.
    EXPECT_EQ(error::kNoError, ExecuteCmd(texsubimage_cmd));
    EXPECT_EQ(GL_NO_ERROR, GetGLError());
    EXPECT_EQ(
        delegate,
        decoder_->GetAsyncPixelTransferManager()->GetPixelTransferDelegate(
            texture_ref));
    EXPECT_TRUE(texture->IsImmutable());
    EXPECT_TRUE(texture->SafeToRenderFrom());
  }
  {
    // A transfer is still in progress!
    EXPECT_CALL(*delegate, TransferIsInProgress())
        .WillOnce(Return(true))
        .RetiresOnSaturation();
    // No async call, command fails.
    EXPECT_EQ(error::kNoError, ExecuteCmd(texsubimage_cmd));
    EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
    EXPECT_EQ(
        delegate,
        decoder_->GetAsyncPixelTransferManager()->GetPixelTransferDelegate(
            texture_ref));
    EXPECT_TRUE(texture->IsImmutable());
    EXPECT_TRUE(texture->SafeToRenderFrom());
  }

  // Delete delegate on DeleteTexture.
  {
    EXPECT_EQ(texture_ref->num_observers(), 1);
    EXPECT_CALL(*delegate, Destroy()).RetiresOnSaturation();
    DoDeleteTexture(client_texture_id_, kServiceTextureId);
    EXPECT_FALSE(
        decoder_->GetAsyncPixelTransferManager()->GetPixelTransferDelegate(
            texture_ref));
    texture = NULL;
    texture_ref = NULL;
    delegate = NULL;
  }

  // WaitAsyncTexImage2D
  {
    // Get a fresh texture since the existing texture cannot be respecified
    // asynchronously and AsyncTexSubImage2D does not involve binding.
    EXPECT_CALL(*gl_, GenTextures(1, _))
        .WillOnce(SetArgumentPointee<1>(kServiceTextureId));
    DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
    texture_ref = GetTexture(client_texture_id_);
    texture = texture_ref->texture();
    texture->SetImmutable(false);
    // Create transfer state since it doesn't exist.
    EXPECT_CALL(*manager, CreatePixelTransferDelegateImpl(texture_ref, _))
        .WillOnce(Return(
            delegate = new StrictMock<gpu::MockAsyncPixelTransferDelegate>))
        .RetiresOnSaturation();
    EXPECT_CALL(*delegate, AsyncTexImage2D(_, _, _)).RetiresOnSaturation();
    // Start async transfer.
    EXPECT_EQ(error::kNoError, ExecuteCmd(teximage_cmd));
    EXPECT_EQ(GL_NO_ERROR, GetGLError());
    EXPECT_EQ(
        delegate,
        decoder_->GetAsyncPixelTransferManager()->GetPixelTransferDelegate(
            texture_ref));

    EXPECT_TRUE(texture->IsImmutable());
    // Wait for completion.
    EXPECT_CALL(*delegate, WaitForTransferCompletion());
    EXPECT_CALL(*manager, BindCompletedAsyncTransfers());
    EXPECT_EQ(error::kNoError, ExecuteCmd(wait_cmd));
    EXPECT_EQ(GL_NO_ERROR, GetGLError());
  }

  // WaitAllAsyncTexImage2D
  EXPECT_CALL(*delegate, Destroy()).RetiresOnSaturation();
  DoDeleteTexture(client_texture_id_, kServiceTextureId);
  EXPECT_FALSE(
      decoder_->GetAsyncPixelTransferManager()->GetPixelTransferDelegate(
          texture_ref));
  texture = NULL;
  texture_ref = NULL;
  delegate = NULL;
  {
    // Get a fresh texture since the existing texture cannot be respecified
    // asynchronously and AsyncTexSubImage2D does not involve binding.
    EXPECT_CALL(*gl_, GenTextures(1, _))
        .WillOnce(SetArgumentPointee<1>(kServiceTextureId));
    DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
    texture_ref = GetTexture(client_texture_id_);
    texture = texture_ref->texture();
    texture->SetImmutable(false);
    // Create transfer state since it doesn't exist.
    EXPECT_CALL(*manager, CreatePixelTransferDelegateImpl(texture_ref, _))
        .WillOnce(Return(
            delegate = new StrictMock<gpu::MockAsyncPixelTransferDelegate>))
        .RetiresOnSaturation();
    EXPECT_CALL(*delegate, AsyncTexImage2D(_, _, _)).RetiresOnSaturation();
    // Start async transfer.
    EXPECT_EQ(error::kNoError, ExecuteCmd(teximage_cmd));
    EXPECT_EQ(GL_NO_ERROR, GetGLError());
    EXPECT_EQ(
        delegate,
        decoder_->GetAsyncPixelTransferManager()->GetPixelTransferDelegate(
            texture_ref));

    EXPECT_TRUE(texture->IsImmutable());
    // Wait for completion of all uploads.
    EXPECT_CALL(*manager, WaitAllAsyncTexImage2D()).RetiresOnSaturation();
    EXPECT_CALL(*manager, BindCompletedAsyncTransfers());
    EXPECT_EQ(error::kNoError, ExecuteCmd(wait_all_cmd));
    EXPECT_EQ(GL_NO_ERROR, GetGLError());
  }

  // Remove PixelTransferManager before the decoder destroys.
  EXPECT_CALL(*delegate, Destroy()).RetiresOnSaturation();
  decoder_->ResetAsyncPixelTransferManagerForTest();
  manager = NULL;
}

TEST_P(GLES2DecoderManualInitTest, AsyncPixelTransferManager) {
  InitState init;
  init.extensions = "GL_CHROMIUM_async_pixel_transfers";
  init.bind_generates_resource = true;
  InitDecoder(init);

  // Set up the texture.
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  TextureRef* texture_ref = GetTexture(client_texture_id_);

  // Set a mock Async delegate.
  StrictMock<gpu::MockAsyncPixelTransferManager>* manager =
      new StrictMock<gpu::MockAsyncPixelTransferManager>;
  manager->Initialize(group().texture_manager());
  decoder_->SetAsyncPixelTransferManagerForTest(manager);
  StrictMock<gpu::MockAsyncPixelTransferDelegate>* delegate = NULL;

  AsyncTexImage2DCHROMIUM teximage_cmd;
  teximage_cmd.Init(GL_TEXTURE_2D,
                    0,
                    GL_RGBA,
                    8,
                    8,
                    GL_RGBA,
                    GL_UNSIGNED_BYTE,
                    kSharedMemoryId,
                    kSharedMemoryOffset,
                    0,
                    0,
                    0);

  // No transfer delegate exists initially.
  EXPECT_FALSE(
      decoder_->GetAsyncPixelTransferManager()->GetPixelTransferDelegate(
          texture_ref));

  // Create delegate on AsyncTexImage2D.
  {
    EXPECT_CALL(*manager, CreatePixelTransferDelegateImpl(texture_ref, _))
        .WillOnce(Return(
            delegate = new StrictMock<gpu::MockAsyncPixelTransferDelegate>))
        .RetiresOnSaturation();
    EXPECT_CALL(*delegate, AsyncTexImage2D(_, _, _)).RetiresOnSaturation();

    // Command succeeds.
    EXPECT_EQ(error::kNoError, ExecuteCmd(teximage_cmd));
    EXPECT_EQ(GL_NO_ERROR, GetGLError());
  }

  // Delegate is cached.
  EXPECT_EQ(delegate,
            decoder_->GetAsyncPixelTransferManager()->GetPixelTransferDelegate(
                texture_ref));

  // Delete delegate on manager teardown.
  {
    EXPECT_EQ(texture_ref->num_observers(), 1);
    EXPECT_CALL(*delegate, Destroy()).RetiresOnSaturation();
    decoder_->ResetAsyncPixelTransferManagerForTest();
    manager = NULL;

    // Texture ref still valid.
    EXPECT_EQ(texture_ref, GetTexture(client_texture_id_));
    EXPECT_EQ(texture_ref->num_observers(), 0);
  }
}

}  // namespace gles2
}  // namespace gpu
