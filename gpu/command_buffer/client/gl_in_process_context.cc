// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/client/gl_in_process_context.h"

#include <set>
#include <utility>
#include <vector>

#include <GLES2/gl2.h>
#ifndef GL_GLEXT_PROTOTYPES
#define GL_GLEXT_PROTOTYPES 1
#endif
#include <GLES2/gl2ext.h>
#include <GLES2/gl2extchromium.h>

#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/weak_ptr.h"
#include "base/message_loop/message_loop.h"
#include "gpu/command_buffer/client/gles2_implementation.h"
#include "gpu/command_buffer/client/transfer_buffer.h"
#include "gpu/command_buffer/common/command_buffer.h"
#include "gpu/command_buffer/common/constants.h"
#include "ui/gfx/geometry/size.h"
#include "ui/gl/gl_image.h"

#if defined(OS_ANDROID)
#include "ui/gl/android/surface_texture.h"
#endif

namespace gpu {

namespace {

const int32 kDefaultCommandBufferSize = 1024 * 1024;
const unsigned int kDefaultStartTransferBufferSize = 4 * 1024 * 1024;
const unsigned int kDefaultMinTransferBufferSize = 1 * 256 * 1024;
const unsigned int kDefaultMaxTransferBufferSize = 16 * 1024 * 1024;

class GLInProcessContextImpl
    : public GLInProcessContext,
      public base::SupportsWeakPtr<GLInProcessContextImpl> {
 public:
  explicit GLInProcessContextImpl(
      const GLInProcessContextSharedMemoryLimits& mem_limits);
  ~GLInProcessContextImpl() override;

  bool Initialize(scoped_refptr<gfx::GLSurface> surface,
                  bool is_offscreen,
                  bool use_global_share_group,
                  GLInProcessContext* share_context,
                  gfx::AcceleratedWidget window,
                  const gfx::Size& size,
                  const gpu::gles2::ContextCreationAttribHelper& attribs,
                  gfx::GpuPreference gpu_preference,
                  const scoped_refptr<InProcessCommandBuffer::Service>& service,
                  GpuMemoryBufferManager* gpu_memory_buffer_manager,
                  ImageFactory* image_factory);

  // GLInProcessContext implementation:
  void SetContextLostCallback(const base::Closure& callback) override;
  gles2::GLES2Implementation* GetImplementation() override;
  size_t GetMappedMemoryLimit() override;
  void SetLock(base::Lock* lock) override;

#if defined(OS_ANDROID)
  scoped_refptr<gfx::SurfaceTexture> GetSurfaceTexture(
      uint32 stream_id) override;
#endif

 private:
  void Destroy();
  void OnContextLost();
  void OnSignalSyncPoint(const base::Closure& callback);

  scoped_ptr<gles2::GLES2CmdHelper> gles2_helper_;
  scoped_ptr<TransferBuffer> transfer_buffer_;
  scoped_ptr<gles2::GLES2Implementation> gles2_implementation_;
  scoped_ptr<InProcessCommandBuffer> command_buffer_;

  const GLInProcessContextSharedMemoryLimits mem_limits_;
  bool context_lost_;
  base::Closure context_lost_callback_;
  base::Lock* lock_;

  DISALLOW_COPY_AND_ASSIGN(GLInProcessContextImpl);
};

base::LazyInstance<base::Lock> g_all_shared_contexts_lock =
    LAZY_INSTANCE_INITIALIZER;
base::LazyInstance<std::set<GLInProcessContextImpl*> > g_all_shared_contexts =
    LAZY_INSTANCE_INITIALIZER;

GLInProcessContextImpl::GLInProcessContextImpl(
    const GLInProcessContextSharedMemoryLimits& mem_limits)
    : mem_limits_(mem_limits), context_lost_(false), lock_(nullptr) {
}

GLInProcessContextImpl::~GLInProcessContextImpl() {
  {
    base::AutoLock lock(g_all_shared_contexts_lock.Get());
    g_all_shared_contexts.Get().erase(this);
  }
  Destroy();
}

gles2::GLES2Implementation* GLInProcessContextImpl::GetImplementation() {
  return gles2_implementation_.get();
}

size_t GLInProcessContextImpl::GetMappedMemoryLimit() {
  return mem_limits_.mapped_memory_reclaim_limit;
}

void GLInProcessContextImpl::SetLock(base::Lock* lock) {
  command_buffer_->SetLock(lock);
  lock_ = lock;
}

void GLInProcessContextImpl::SetContextLostCallback(
    const base::Closure& callback) {
  context_lost_callback_ = callback;
}

void GLInProcessContextImpl::OnContextLost() {
  scoped_ptr<base::AutoLock> lock;
  if (lock_)
    lock.reset(new base::AutoLock(*lock_));
  context_lost_ = true;
  if (!context_lost_callback_.is_null()) {
    context_lost_callback_.Run();
  }
}

bool GLInProcessContextImpl::Initialize(
    scoped_refptr<gfx::GLSurface> surface,
    bool is_offscreen,
    bool use_global_share_group,
    GLInProcessContext* share_context,
    gfx::AcceleratedWidget window,
    const gfx::Size& size,
    const gles2::ContextCreationAttribHelper& attribs,
    gfx::GpuPreference gpu_preference,
    const scoped_refptr<InProcessCommandBuffer::Service>& service,
    GpuMemoryBufferManager* gpu_memory_buffer_manager,
    ImageFactory* image_factory) {
  DCHECK(!use_global_share_group || !share_context);
  DCHECK(size.width() >= 0 && size.height() >= 0);

  std::vector<int32> attrib_vector;
  attribs.Serialize(&attrib_vector);

  base::Closure wrapped_callback =
      base::Bind(&GLInProcessContextImpl::OnContextLost, AsWeakPtr());
  command_buffer_.reset(new InProcessCommandBuffer(service));

  scoped_ptr<base::AutoLock> scoped_shared_context_lock;
  scoped_refptr<gles2::ShareGroup> share_group;
  InProcessCommandBuffer* share_command_buffer = NULL;
  if (use_global_share_group) {
    scoped_shared_context_lock.reset(
        new base::AutoLock(g_all_shared_contexts_lock.Get()));
    for (std::set<GLInProcessContextImpl*>::const_iterator it =
             g_all_shared_contexts.Get().begin();
         it != g_all_shared_contexts.Get().end();
         it++) {
      const GLInProcessContextImpl* context = *it;
      if (!context->context_lost_) {
        share_group = context->gles2_implementation_->share_group();
        share_command_buffer = context->command_buffer_.get();
        DCHECK(share_group.get());
        DCHECK(share_command_buffer);
        break;
      }
    }
  } else if (share_context) {
    GLInProcessContextImpl* impl =
        static_cast<GLInProcessContextImpl*>(share_context);
    share_group = impl->gles2_implementation_->share_group();
    share_command_buffer = impl->command_buffer_.get();
    DCHECK(share_group.get());
    DCHECK(share_command_buffer);
  }

  if (!command_buffer_->Initialize(surface,
                                   is_offscreen,
                                   window,
                                   size,
                                   attrib_vector,
                                   gpu_preference,
                                   wrapped_callback,
                                   share_command_buffer,
                                   gpu_memory_buffer_manager,
                                   image_factory)) {
    LOG(ERROR) << "Failed to initialize InProcessCommmandBuffer";
    return false;
  }

  // Create the GLES2 helper, which writes the command buffer protocol.
  gles2_helper_.reset(new gles2::GLES2CmdHelper(command_buffer_.get()));
  if (!gles2_helper_->Initialize(mem_limits_.command_buffer_size)) {
    LOG(ERROR) << "Failed to initialize GLES2CmdHelper";
    Destroy();
    return false;
  }

  // Create a transfer buffer.
  transfer_buffer_.reset(new TransferBuffer(gles2_helper_.get()));

  // Check for consistency.
  DCHECK(!attribs.bind_generates_resource);
  const bool bind_generates_resource = false;
  const bool support_client_side_arrays = false;

  // Create the object exposing the OpenGL API.
  gles2_implementation_.reset(
      new gles2::GLES2Implementation(gles2_helper_.get(),
                                     share_group.get(),
                                     transfer_buffer_.get(),
                                     bind_generates_resource,
                                     attribs.lose_context_when_out_of_memory,
                                     support_client_side_arrays,
                                     command_buffer_.get()));

  if (use_global_share_group) {
    g_all_shared_contexts.Get().insert(this);
    scoped_shared_context_lock.reset();
  }

  if (!gles2_implementation_->Initialize(
          mem_limits_.start_transfer_buffer_size,
          mem_limits_.min_transfer_buffer_size,
          mem_limits_.max_transfer_buffer_size,
          mem_limits_.mapped_memory_reclaim_limit)) {
    return false;
  }

  return true;
}

void GLInProcessContextImpl::Destroy() {
  if (gles2_implementation_) {
    // First flush the context to ensure that any pending frees of resources
    // are completed. Otherwise, if this context is part of a share group,
    // those resources might leak. Also, any remaining side effects of commands
    // issued on this context might not be visible to other contexts in the
    // share group.
    gles2_implementation_->Flush();

    gles2_implementation_.reset();
  }

  transfer_buffer_.reset();
  gles2_helper_.reset();
  command_buffer_.reset();
}

#if defined(OS_ANDROID)
scoped_refptr<gfx::SurfaceTexture>
GLInProcessContextImpl::GetSurfaceTexture(uint32 stream_id) {
  return command_buffer_->GetSurfaceTexture(stream_id);
}
#endif

}  // anonymous namespace

GLInProcessContextSharedMemoryLimits::GLInProcessContextSharedMemoryLimits()
    : command_buffer_size(kDefaultCommandBufferSize),
      start_transfer_buffer_size(kDefaultStartTransferBufferSize),
      min_transfer_buffer_size(kDefaultMinTransferBufferSize),
      max_transfer_buffer_size(kDefaultMaxTransferBufferSize),
      mapped_memory_reclaim_limit(gles2::GLES2Implementation::kNoLimit) {
}

// static
GLInProcessContext* GLInProcessContext::Create(
    scoped_refptr<gpu::InProcessCommandBuffer::Service> service,
    scoped_refptr<gfx::GLSurface> surface,
    bool is_offscreen,
    gfx::AcceleratedWidget window,
    const gfx::Size& size,
    GLInProcessContext* share_context,
    bool use_global_share_group,
    const ::gpu::gles2::ContextCreationAttribHelper& attribs,
    gfx::GpuPreference gpu_preference,
    const GLInProcessContextSharedMemoryLimits& memory_limits,
    GpuMemoryBufferManager* gpu_memory_buffer_manager,
    ImageFactory* image_factory) {
  DCHECK(!use_global_share_group || !share_context);
  if (surface.get()) {
    DCHECK_EQ(surface->IsOffscreen(), is_offscreen);
    DCHECK(surface->GetSize() == size);
    DCHECK_EQ(gfx::kNullAcceleratedWidget, window);
  }

  scoped_ptr<GLInProcessContextImpl> context(
      new GLInProcessContextImpl(memory_limits));
  if (!context->Initialize(surface,
                           is_offscreen,
                           use_global_share_group,
                           share_context,
                           window,
                           size,
                           attribs,
                           gpu_preference,
                           service,
                           gpu_memory_buffer_manager,
                           image_factory))
    return NULL;

  return context.release();
}

}  // namespace gpu
