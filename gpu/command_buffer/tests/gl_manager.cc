// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/tests/gl_manager.h"

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <GLES2/gl2extchromium.h>

#include <vector>

#include "base/at_exit.h"
#include "base/bind.h"
#include "base/memory/ref_counted_memory.h"
#include "gpu/command_buffer/client/gles2_implementation.h"
#include "gpu/command_buffer/client/gles2_lib.h"
#include "gpu/command_buffer/client/transfer_buffer.h"
#include "gpu/command_buffer/common/constants.h"
#include "gpu/command_buffer/common/gles2_cmd_utils.h"
#include "gpu/command_buffer/common/value_state.h"
#include "gpu/command_buffer/service/command_buffer_service.h"
#include "gpu/command_buffer/service/context_group.h"
#include "gpu/command_buffer/service/gl_context_virtual.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder.h"
#include "gpu/command_buffer/service/gpu_scheduler.h"
#include "gpu/command_buffer/service/image_manager.h"
#include "gpu/command_buffer/service/mailbox_manager_impl.h"
#include "gpu/command_buffer/service/memory_tracking.h"
#include "gpu/command_buffer/service/valuebuffer_manager.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gfx/gpu_memory_buffer.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_image_ref_counted_memory.h"
#include "ui/gl/gl_share_group.h"
#include "ui/gl/gl_surface.h"

namespace gpu {
namespace {

size_t StrideInBytes(size_t width, gfx::GpuMemoryBuffer::Format format) {
  switch (format) {
    case gfx::GpuMemoryBuffer::ATCIA:
    case gfx::GpuMemoryBuffer::DXT5:
      return width;
    case gfx::GpuMemoryBuffer::ATC:
    case gfx::GpuMemoryBuffer::DXT1:
    case gfx::GpuMemoryBuffer::ETC1:
      DCHECK_EQ(width % 2, 0U);
      return width / 2;
    case gfx::GpuMemoryBuffer::RGBA_8888:
    case gfx::GpuMemoryBuffer::BGRA_8888:
      return width * 4;
    case gfx::GpuMemoryBuffer::RGBX_8888:
      NOTREACHED();
      return 0;
  }

  NOTREACHED();
  return 0;
}

class GpuMemoryBufferImpl : public gfx::GpuMemoryBuffer {
 public:
  GpuMemoryBufferImpl(base::RefCountedBytes* bytes,
                      const gfx::Size& size,
                      gfx::GpuMemoryBuffer::Format format)
      : bytes_(bytes), size_(size), format_(format), mapped_(false) {}

  static GpuMemoryBufferImpl* FromClientBuffer(ClientBuffer buffer) {
    return reinterpret_cast<GpuMemoryBufferImpl*>(buffer);
  }

  // Overridden from gfx::GpuMemoryBuffer:
  bool Map(void** data) override {
    mapped_ = true;
    *data = &bytes_->data().front();
    return true;
  }
  void Unmap() override { mapped_ = false; }
  bool IsMapped() const override { return mapped_; }
  Format GetFormat() const override { return format_; }
  void GetStride(uint32* stride) const override {
    *stride = StrideInBytes(size_.width(), format_);
  }
  gfx::GpuMemoryBufferHandle GetHandle() const override {
    NOTREACHED();
    return gfx::GpuMemoryBufferHandle();
  }
  ClientBuffer AsClientBuffer() override {
    return reinterpret_cast<ClientBuffer>(this);
  }

  base::RefCountedBytes* bytes() { return bytes_.get(); }

 private:
  scoped_refptr<base::RefCountedBytes> bytes_;
  const gfx::Size size_;
  gfx::GpuMemoryBuffer::Format format_;
  bool mapped_;
};

}  // namespace

int GLManager::use_count_;
scoped_refptr<gfx::GLShareGroup>* GLManager::base_share_group_;
scoped_refptr<gfx::GLSurface>* GLManager::base_surface_;
scoped_refptr<gfx::GLContext>* GLManager::base_context_;

GLManager::Options::Options()
    : size(4, 4),
      share_group_manager(NULL),
      share_mailbox_manager(NULL),
      virtual_manager(NULL),
      bind_generates_resource(false),
      lose_context_when_out_of_memory(false),
      context_lost_allowed(false) {
}

GLManager::GLManager() : context_lost_allowed_(false) {
  SetupBaseContext();
}

GLManager::~GLManager() {
  --use_count_;
  if (!use_count_) {
    if (base_share_group_) {
      delete base_context_;
      base_context_ = NULL;
    }
    if (base_surface_) {
      delete base_surface_;
      base_surface_ = NULL;
    }
    if (base_context_) {
      delete base_context_;
      base_context_ = NULL;
    }
  }
}

// static
scoped_ptr<gfx::GpuMemoryBuffer> GLManager::CreateGpuMemoryBuffer(
    const gfx::Size& size,
    gfx::GpuMemoryBuffer::Format format) {
  std::vector<unsigned char> data(
      StrideInBytes(size.width(), format) * size.height(), 0);
  scoped_refptr<base::RefCountedBytes> bytes(new base::RefCountedBytes(data));
  return make_scoped_ptr<gfx::GpuMemoryBuffer>(
      new GpuMemoryBufferImpl(bytes.get(), size, format));
}

void GLManager::Initialize(const GLManager::Options& options) {
  InitializeWithCommandLine(options, nullptr);
}
void GLManager::InitializeWithCommandLine(const GLManager::Options& options,
                                          base::CommandLine* command_line) {
  const int32 kCommandBufferSize = 1024 * 1024;
  const size_t kStartTransferBufferSize = 4 * 1024 * 1024;
  const size_t kMinTransferBufferSize = 1 * 256 * 1024;
  const size_t kMaxTransferBufferSize = 16 * 1024 * 1024;

  context_lost_allowed_ = options.context_lost_allowed;

  gles2::MailboxManager* mailbox_manager = NULL;
  if (options.share_mailbox_manager) {
    mailbox_manager = options.share_mailbox_manager->mailbox_manager();
  } else if (options.share_group_manager) {
    mailbox_manager = options.share_group_manager->mailbox_manager();
  }

  gfx::GLShareGroup* share_group = NULL;
  if (options.share_group_manager) {
    share_group = options.share_group_manager->share_group();
  } else if (options.share_mailbox_manager) {
    share_group = options.share_mailbox_manager->share_group();
  }

  gles2::ContextGroup* context_group = NULL;
  gles2::ShareGroup* client_share_group = NULL;
  if (options.share_group_manager) {
    context_group = options.share_group_manager->decoder_->GetContextGroup();
    client_share_group =
      options.share_group_manager->gles2_implementation()->share_group();
  }

  gfx::GLContext* real_gl_context = NULL;
  if (options.virtual_manager) {
    real_gl_context = options.virtual_manager->context();
  }

  mailbox_manager_ =
      mailbox_manager ? mailbox_manager : new gles2::MailboxManagerImpl;
  share_group_ =
      share_group ? share_group : new gfx::GLShareGroup;

  gfx::GpuPreference gpu_preference(gfx::PreferDiscreteGpu);
  std::vector<int32> attribs;
  gles2::ContextCreationAttribHelper attrib_helper;
  attrib_helper.red_size = 8;
  attrib_helper.green_size = 8;
  attrib_helper.blue_size = 8;
  attrib_helper.alpha_size = 8;
  attrib_helper.depth_size = 16;
  attrib_helper.stencil_size = 8;
  attrib_helper.Serialize(&attribs);

  DCHECK(!command_line || !context_group);
  if (!context_group) {
    scoped_refptr<gles2::FeatureInfo> feature_info;
    if (command_line)
      feature_info = new gles2::FeatureInfo(*command_line);
    context_group =
        new gles2::ContextGroup(mailbox_manager_.get(),
                                NULL,
                                new gpu::gles2::ShaderTranslatorCache,
                                feature_info,
                                NULL,
                                NULL,
                                options.bind_generates_resource);
  }

  decoder_.reset(::gpu::gles2::GLES2Decoder::Create(context_group));

  command_buffer_.reset(new CommandBufferService(
      decoder_->GetContextGroup()->transfer_buffer_manager()));
  ASSERT_TRUE(command_buffer_->Initialize())
      << "could not create command buffer service";

  gpu_scheduler_.reset(new GpuScheduler(command_buffer_.get(),
                                        decoder_.get(),
                                        decoder_.get()));

  decoder_->set_engine(gpu_scheduler_.get());

  surface_ = gfx::GLSurface::CreateOffscreenGLSurface(options.size);
  ASSERT_TRUE(surface_.get() != NULL) << "could not create offscreen surface";

  if (base_context_) {
    context_ = scoped_refptr<gfx::GLContext>(new gpu::GLContextVirtual(
        share_group_.get(), base_context_->get(), decoder_->AsWeakPtr()));
    ASSERT_TRUE(context_->Initialize(
        surface_.get(), gfx::PreferIntegratedGpu));
  } else {
    if (real_gl_context) {
      context_ = scoped_refptr<gfx::GLContext>(new gpu::GLContextVirtual(
          share_group_.get(), real_gl_context, decoder_->AsWeakPtr()));
      ASSERT_TRUE(context_->Initialize(
          surface_.get(), gfx::PreferIntegratedGpu));
    } else {
      context_ = gfx::GLContext::CreateGLContext(share_group_.get(),
                                                 surface_.get(),
                                                 gpu_preference);
    }
  }
  ASSERT_TRUE(context_.get() != NULL) << "could not create GL context";

  ASSERT_TRUE(context_->MakeCurrent(surface_.get()));

  ASSERT_TRUE(decoder_->Initialize(
      surface_.get(),
      context_.get(),
      true,
      options.size,
      ::gpu::gles2::DisallowedFeatures(),
      attribs)) << "could not initialize decoder";

  command_buffer_->SetPutOffsetChangeCallback(
      base::Bind(&GLManager::PumpCommands, base::Unretained(this)));
  command_buffer_->SetGetBufferChangeCallback(
      base::Bind(&GLManager::GetBufferChanged, base::Unretained(this)));

  // Create the GLES2 helper, which writes the command buffer protocol.
  gles2_helper_.reset(new gles2::GLES2CmdHelper(command_buffer_.get()));
  ASSERT_TRUE(gles2_helper_->Initialize(kCommandBufferSize));

  // Create a transfer buffer.
  transfer_buffer_.reset(new TransferBuffer(gles2_helper_.get()));

  // Create the object exposing the OpenGL API.
  const bool support_client_side_arrays = true;
  gles2_implementation_.reset(
      new gles2::GLES2Implementation(gles2_helper_.get(),
                                     client_share_group,
                                     transfer_buffer_.get(),
                                     options.bind_generates_resource,
                                     options.lose_context_when_out_of_memory,
                                     support_client_side_arrays,
                                     this));

  ASSERT_TRUE(gles2_implementation_->Initialize(
      kStartTransferBufferSize,
      kMinTransferBufferSize,
      kMaxTransferBufferSize,
      gpu::gles2::GLES2Implementation::kNoLimit))
          << "Could not init GLES2Implementation";

  MakeCurrent();
}

void GLManager::SetupBaseContext() {
  if (use_count_) {
    #if defined(OS_ANDROID)
      base_share_group_ = new scoped_refptr<gfx::GLShareGroup>(
          new gfx::GLShareGroup);
      gfx::Size size(4, 4);
      base_surface_ = new scoped_refptr<gfx::GLSurface>(
          gfx::GLSurface::CreateOffscreenGLSurface(size));
      gfx::GpuPreference gpu_preference(gfx::PreferDiscreteGpu);
      base_context_ = new scoped_refptr<gfx::GLContext>(
          gfx::GLContext::CreateGLContext(base_share_group_->get(),
                                          base_surface_->get(),
                                          gpu_preference));
    #endif
  }
  ++use_count_;
}

void GLManager::MakeCurrent() {
  ::gles2::SetGLContext(gles2_implementation_.get());
}

void GLManager::SetSurface(gfx::GLSurface* surface) {
  decoder_->SetSurface(surface);
}

void GLManager::Destroy() {
  if (gles2_implementation_.get()) {
    MakeCurrent();
    EXPECT_TRUE(glGetError() == GL_NONE);
    gles2_implementation_->Flush();
    gles2_implementation_.reset();
  }
  transfer_buffer_.reset();
  gles2_helper_.reset();
  command_buffer_.reset();
  if (decoder_.get()) {
    bool have_context = decoder_->GetGLContext()->MakeCurrent(surface_.get());
    decoder_->Destroy(have_context);
    decoder_.reset();
  }
}

const gpu::gles2::FeatureInfo::Workarounds& GLManager::workarounds() const {
  return decoder_->GetContextGroup()->feature_info()->workarounds();
}

void GLManager::PumpCommands() {
  if (!decoder_->MakeCurrent()) {
    command_buffer_->SetContextLostReason(decoder_->GetContextLostReason());
    command_buffer_->SetParseError(::gpu::error::kLostContext);
    return;
  }
  gpu_scheduler_->PutChanged();
  ::gpu::CommandBuffer::State state = command_buffer_->GetLastState();
  if (!context_lost_allowed_) {
    ASSERT_EQ(::gpu::error::kNoError, state.error);
  }
}

bool GLManager::GetBufferChanged(int32 transfer_buffer_id) {
  return gpu_scheduler_->SetGetBuffer(transfer_buffer_id);
}

Capabilities GLManager::GetCapabilities() {
  return decoder_->GetCapabilities();
}

int32 GLManager::CreateImage(ClientBuffer buffer,
                             size_t width,
                             size_t height,
                             unsigned internalformat) {
  GpuMemoryBufferImpl* gpu_memory_buffer =
      GpuMemoryBufferImpl::FromClientBuffer(buffer);

  scoped_refptr<gfx::GLImageRefCountedMemory> image(
      new gfx::GLImageRefCountedMemory(gfx::Size(width, height),
                                       internalformat));
  if (!image->Initialize(gpu_memory_buffer->bytes(),
                         gpu_memory_buffer->GetFormat())) {
    return -1;
  }

  static int32 next_id = 1;
  int32 new_id = next_id++;

  gpu::gles2::ImageManager* image_manager = decoder_->GetImageManager();
  DCHECK(image_manager);
  image_manager->AddImage(image.get(), new_id);
  return new_id;
}

int32 GLManager::CreateGpuMemoryBufferImage(size_t width,
                                            size_t height,
                                            unsigned internalformat,
                                            unsigned usage) {
  DCHECK_EQ(usage, static_cast<unsigned>(GL_MAP_CHROMIUM));
  scoped_ptr<gfx::GpuMemoryBuffer> buffer = GLManager::CreateGpuMemoryBuffer(
      gfx::Size(width, height), gfx::GpuMemoryBuffer::RGBA_8888);
  return CreateImage(buffer->AsClientBuffer(), width, height, internalformat);
}

void GLManager::DestroyImage(int32 id) {
  gpu::gles2::ImageManager* image_manager = decoder_->GetImageManager();
  DCHECK(image_manager);
  image_manager->RemoveImage(id);
}

uint32 GLManager::InsertSyncPoint() {
  NOTIMPLEMENTED();
  return 0u;
}

uint32 GLManager::InsertFutureSyncPoint() {
  NOTIMPLEMENTED();
  return 0u;
}

void GLManager::RetireSyncPoint(uint32 sync_point) {
  NOTIMPLEMENTED();
}

void GLManager::SignalSyncPoint(uint32 sync_point,
                                const base::Closure& callback) {
  NOTIMPLEMENTED();
}

void GLManager::SignalQuery(uint32 query, const base::Closure& callback) {
  NOTIMPLEMENTED();
}

void GLManager::SetSurfaceVisible(bool visible) {
  NOTIMPLEMENTED();
}

uint32 GLManager::CreateStreamTexture(uint32 texture_id) {
  NOTIMPLEMENTED();
  return 0;
}

void GLManager::SetLock(base::Lock*) {
  NOTIMPLEMENTED();
}

}  // namespace gpu
