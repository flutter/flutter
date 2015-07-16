// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_IN_PROCESS_COMMAND_BUFFER_H_
#define GPU_COMMAND_BUFFER_SERVICE_IN_PROCESS_COMMAND_BUFFER_H_

#include <map>
#include <vector>

#include "base/atomic_sequence_num.h"
#include "base/callback.h"
#include "base/compiler_specific.h"
#include "base/containers/scoped_ptr_hash_map.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/weak_ptr.h"
#include "base/synchronization/lock.h"
#include "base/synchronization/waitable_event.h"
#include "gpu/command_buffer/client/gpu_control.h"
#include "gpu/command_buffer/common/command_buffer.h"
#include "gpu/gpu_export.h"
#include "ui/gfx/gpu_memory_buffer.h"
#include "ui/gfx/native_widget_types.h"
#include "ui/gl/gl_surface.h"
#include "ui/gl/gpu_preference.h"

namespace base {
class SequenceChecker;
}

namespace gfx {
class GLContext;
class GLShareGroup;
class GLSurface;
class Size;
}

#if defined(OS_ANDROID)
namespace gfx {
class SurfaceTexture;
}
namespace gpu {
class StreamTextureManagerInProcess;
}
#endif

namespace gpu {
class ValueStateMap;

namespace gles2 {
class GLES2Decoder;
class MailboxManager;
class ShaderTranslatorCache;
class SubscriptionRefSet;
}

class CommandBufferServiceBase;
class GpuMemoryBufferManager;
class GpuScheduler;
class ImageFactory;
class TransferBufferManagerInterface;

// This class provides a thread-safe interface to the global GPU service (for
// example GPU thread) when being run in single process mode.
// However, the behavior for accessing one context (i.e. one instance of this
// class) from different client threads is undefined.
class GPU_EXPORT InProcessCommandBuffer : public CommandBuffer,
                                          public GpuControl {
 public:
  class Service;
  explicit InProcessCommandBuffer(const scoped_refptr<Service>& service);
  ~InProcessCommandBuffer() override;

  // If |surface| is not NULL, use it directly; in this case, the command
  // buffer gpu thread must be the same as the client thread. Otherwise create
  // a new GLSurface.
  bool Initialize(scoped_refptr<gfx::GLSurface> surface,
                  bool is_offscreen,
                  gfx::AcceleratedWidget window,
                  const gfx::Size& size,
                  const std::vector<int32>& attribs,
                  gfx::GpuPreference gpu_preference,
                  const base::Closure& context_lost_callback,
                  InProcessCommandBuffer* share_group,
                  GpuMemoryBufferManager* gpu_memory_buffer_manager,
                  ImageFactory* image_factory,
                  const gfx::SurfaceConfiguration& requested_configuration);
  void Destroy();

  // CommandBuffer implementation:
  bool Initialize() override;
  State GetLastState() override;
  int32 GetLastToken() override;
  void Flush(int32 put_offset) override;
  void OrderingBarrier(int32 put_offset) override;
  void WaitForTokenInRange(int32 start, int32 end) override;
  void WaitForGetOffsetInRange(int32 start, int32 end) override;
  void SetGetBuffer(int32 shm_id) override;
  scoped_refptr<gpu::Buffer> CreateTransferBuffer(size_t size,
                                                  int32* id) override;
  void DestroyTransferBuffer(int32 id) override;
  gpu::error::Error GetLastError() override;

  // GpuControl implementation:
  gpu::Capabilities GetCapabilities() override;
  int32 CreateImage(ClientBuffer buffer,
                    size_t width,
                    size_t height,
                    unsigned internalformat) override;
  void DestroyImage(int32 id) override;
  int32 CreateGpuMemoryBufferImage(size_t width,
                                   size_t height,
                                   unsigned internalformat,
                                   unsigned usage) override;
  uint32 InsertSyncPoint() override;
  uint32 InsertFutureSyncPoint() override;
  void RetireSyncPoint(uint32 sync_point) override;
  void SignalSyncPoint(uint32 sync_point,
                       const base::Closure& callback) override;
  void SignalQuery(uint32 query_id, const base::Closure& callback) override;
  void SetSurfaceVisible(bool visible) override;
  uint32 CreateStreamTexture(uint32 texture_id) override;
  void SetLock(base::Lock*) override;

  // The serializer interface to the GPU service (i.e. thread).
  class Service {
   public:
    Service();
    virtual ~Service();

    virtual void AddRef() const = 0;
    virtual void Release() const = 0;

    // Queues a task to run as soon as possible.
    virtual void ScheduleTask(const base::Closure& task) = 0;

    // Schedules |callback| to run at an appropriate time for performing idle
    // work.
    virtual void ScheduleIdleWork(const base::Closure& task) = 0;

    virtual bool UseVirtualizedGLContexts() = 0;
    virtual scoped_refptr<gles2::ShaderTranslatorCache>
        shader_translator_cache() = 0;
    scoped_refptr<gfx::GLShareGroup> share_group();
    scoped_refptr<gles2::MailboxManager> mailbox_manager();
    scoped_refptr<gles2::SubscriptionRefSet> subscription_ref_set();
    scoped_refptr<gpu::ValueStateMap> pending_valuebuffer_state();

   private:
    scoped_refptr<gfx::GLShareGroup> share_group_;
    scoped_refptr<gles2::MailboxManager> mailbox_manager_;
    scoped_refptr<gles2::SubscriptionRefSet> subscription_ref_set_;
    scoped_refptr<gpu::ValueStateMap> pending_valuebuffer_state_;
  };

#if defined(OS_ANDROID)
  scoped_refptr<gfx::SurfaceTexture> GetSurfaceTexture(
      uint32 stream_id);
#endif

 private:
  struct InitializeOnGpuThreadParams {
    bool is_offscreen;
    gfx::AcceleratedWidget window;
    const gfx::Size& size;
    const std::vector<int32>& attribs;
    gfx::GpuPreference gpu_preference;
    gpu::Capabilities* capabilities;  // Ouptut.
    InProcessCommandBuffer* context_group;
    ImageFactory* image_factory;
    gfx::SurfaceConfiguration requested_configuration;

    InitializeOnGpuThreadParams(
      bool is_offscreen,
      gfx::AcceleratedWidget window,
      const gfx::Size& size,
      const std::vector<int32>& attribs,
      gfx::GpuPreference gpu_preference,
      gpu::Capabilities* capabilities,
      InProcessCommandBuffer* share_group,
      ImageFactory* image_factory,
      const gfx::SurfaceConfiguration& requested_configuration);
  };

  bool InitializeOnGpuThread(const InitializeOnGpuThreadParams& params);
  bool DestroyOnGpuThread();
  void FlushOnGpuThread(int32 put_offset);
  void ScheduleIdleWorkOnGpuThread();
  uint32 CreateStreamTextureOnGpuThread(uint32 client_texture_id);
  bool MakeCurrent();
  base::Closure WrapCallback(const base::Closure& callback);
  State GetStateFast();
  void QueueTask(const base::Closure& task) { service_->ScheduleTask(task); }
  void CheckSequencedThread();
  void RetireSyncPointOnGpuThread(uint32 sync_point);
  void SignalSyncPointOnGpuThread(uint32 sync_point,
                                  const base::Closure& callback);
  bool WaitSyncPointOnGpuThread(uint32 sync_point);
  void SignalQueryOnGpuThread(unsigned query_id, const base::Closure& callback);
  void DestroyTransferBufferOnGpuThread(int32 id);
  void CreateImageOnGpuThread(int32 id,
                              const gfx::GpuMemoryBufferHandle& handle,
                              const gfx::Size& size,
                              gfx::GpuMemoryBuffer::Format format,
                              uint32 internalformat);
  void DestroyImageOnGpuThread(int32 id);

  // Callbacks:
  void OnContextLost();
  void OnResizeView(gfx::Size size, float scale_factor);
  bool GetBufferChanged(int32 transfer_buffer_id);
  void PumpCommands();
  void PerformIdleWork();

  // Members accessed on the gpu thread (possibly with the exception of
  // creation):
  bool context_lost_;
  scoped_ptr<TransferBufferManagerInterface> transfer_buffer_manager_;
  scoped_ptr<GpuScheduler> gpu_scheduler_;
  scoped_ptr<gles2::GLES2Decoder> decoder_;
  scoped_refptr<gfx::GLContext> context_;
  scoped_refptr<gfx::GLSurface> surface_;
  base::Closure context_lost_callback_;
  bool idle_work_pending_;  // Used to throttle PerformIdleWork.
  ImageFactory* image_factory_;

  // Members accessed on the client thread:
  State last_state_;
  int32 last_put_offset_;
  gpu::Capabilities capabilities_;
  GpuMemoryBufferManager* gpu_memory_buffer_manager_;
  base::AtomicSequenceNumber next_image_id_;

  // Accessed on both threads:
  scoped_ptr<CommandBufferServiceBase> command_buffer_;
  base::Lock command_buffer_lock_;
  base::WaitableEvent flush_event_;
  scoped_refptr<Service> service_;
  State state_after_last_flush_;
  base::Lock state_after_last_flush_lock_;
  scoped_refptr<gfx::GLShareGroup> gl_share_group_;

#if defined(OS_ANDROID)
  scoped_ptr<StreamTextureManagerInProcess> stream_texture_manager_;
#endif

  // Only used with explicit scheduling and the gpu thread is the same as
  // the client thread.
  scoped_ptr<base::SequenceChecker> sequence_checker_;

  base::WeakPtr<InProcessCommandBuffer> gpu_thread_weak_ptr_;
  base::WeakPtrFactory<InProcessCommandBuffer> gpu_thread_weak_ptr_factory_;

  DISALLOW_COPY_AND_ASSIGN(InProcessCommandBuffer);
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_IN_PROCESS_COMMAND_BUFFER_H_
