// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/in_process_command_buffer.h"

#include <queue>
#include <set>
#include <utility>

#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/command_line.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/memory/weak_ptr.h"
#include "base/message_loop/message_loop_proxy.h"
#include "base/sequence_checker.h"
#include "base/synchronization/condition_variable.h"
#include "base/threading/thread.h"
#include "gpu/command_buffer/client/gpu_memory_buffer_manager.h"
#include "gpu/command_buffer/common/value_state.h"
#include "gpu/command_buffer/service/command_buffer_service.h"
#include "gpu/command_buffer/service/context_group.h"
#include "gpu/command_buffer/service/gl_context_virtual.h"
#include "gpu/command_buffer/service/gpu_scheduler.h"
#include "gpu/command_buffer/service/gpu_switches.h"
#include "gpu/command_buffer/service/image_factory.h"
#include "gpu/command_buffer/service/image_manager.h"
#include "gpu/command_buffer/service/mailbox_manager_impl.h"
#include "gpu/command_buffer/service/mailbox_manager_sync.h"
#include "gpu/command_buffer/service/memory_tracking.h"
#include "gpu/command_buffer/service/query_manager.h"
#include "gpu/command_buffer/service/sync_point_manager.h"
#include "gpu/command_buffer/service/transfer_buffer_manager.h"
#include "gpu/command_buffer/service/valuebuffer_manager.h"
#include "ui/gfx/geometry/size.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_image.h"
#include "ui/gl/gl_share_group.h"

#if defined(OS_ANDROID)
#include "gpu/command_buffer/service/stream_texture_manager_in_process_android.h"
#include "ui/gl/android/surface_texture.h"
#endif

#if defined(OS_WIN)
#include <windows.h>
#include "base/process/process_handle.h"
#endif

namespace gpu {

namespace {

template <typename T>
static void RunTaskWithResult(base::Callback<T(void)> task,
                              T* result,
                              base::WaitableEvent* completion) {
  *result = task.Run();
  completion->Signal();
}

class GpuInProcessThread
    : public base::Thread,
      public InProcessCommandBuffer::Service,
      public base::RefCountedThreadSafe<GpuInProcessThread> {
 public:
  GpuInProcessThread();

  void AddRef() const override {
    base::RefCountedThreadSafe<GpuInProcessThread>::AddRef();
  }
  void Release() const override {
    base::RefCountedThreadSafe<GpuInProcessThread>::Release();
  }

  void ScheduleTask(const base::Closure& task) override;
  void ScheduleIdleWork(const base::Closure& callback) override;
  bool UseVirtualizedGLContexts() override { return false; }
  scoped_refptr<gles2::ShaderTranslatorCache> shader_translator_cache()
      override;

 private:
  ~GpuInProcessThread() override;
  friend class base::RefCountedThreadSafe<GpuInProcessThread>;

  scoped_refptr<gpu::gles2::ShaderTranslatorCache> shader_translator_cache_;
  DISALLOW_COPY_AND_ASSIGN(GpuInProcessThread);
};

GpuInProcessThread::GpuInProcessThread() : base::Thread("GpuThread") {
  Start();
}

GpuInProcessThread::~GpuInProcessThread() {
  Stop();
}

void GpuInProcessThread::ScheduleTask(const base::Closure& task) {
  message_loop()->PostTask(FROM_HERE, task);
}

void GpuInProcessThread::ScheduleIdleWork(const base::Closure& callback) {
  // Match delay with GpuCommandBufferStub.
  message_loop()->PostDelayedTask(
      FROM_HERE, callback, base::TimeDelta::FromMilliseconds(2));
}

scoped_refptr<gles2::ShaderTranslatorCache>
GpuInProcessThread::shader_translator_cache() {
  if (!shader_translator_cache_.get())
    shader_translator_cache_ = new gpu::gles2::ShaderTranslatorCache;
  return shader_translator_cache_;
}

struct GpuInProcessThreadHolder {
  GpuInProcessThreadHolder() : gpu_thread(new GpuInProcessThread) {}
  scoped_refptr<InProcessCommandBuffer::Service> gpu_thread;
};

base::LazyInstance<GpuInProcessThreadHolder> g_default_service =
    LAZY_INSTANCE_INITIALIZER;

class ScopedEvent {
 public:
  explicit ScopedEvent(base::WaitableEvent* event) : event_(event) {}
  ~ScopedEvent() { event_->Signal(); }

 private:
  base::WaitableEvent* event_;
};

// This wrapper adds the WaitSyncPoint which allows waiting on a sync point
// on the service thread, implemented using a condition variable.
class SyncPointManagerWrapper {
 public:
  SyncPointManagerWrapper();

  uint32 GenerateSyncPoint();
  void RetireSyncPoint(uint32 sync_point);
  void AddSyncPointCallback(uint32 sync_point, const base::Closure& callback);

  void WaitSyncPoint(uint32 sync_point);

 private:
  void OnSyncPointRetired();

  const scoped_refptr<SyncPointManager> manager_;
  base::Lock retire_lock_;
  base::ConditionVariable retire_cond_var_;

  DISALLOW_COPY_AND_ASSIGN(SyncPointManagerWrapper);
};

SyncPointManagerWrapper::SyncPointManagerWrapper()
    : manager_(SyncPointManager::Create(true)),
      retire_cond_var_(&retire_lock_) {
}

uint32 SyncPointManagerWrapper::GenerateSyncPoint() {
  uint32 sync_point = manager_->GenerateSyncPoint();
  manager_->AddSyncPointCallback(
      sync_point, base::Bind(&SyncPointManagerWrapper::OnSyncPointRetired,
                             base::Unretained(this)));
  return sync_point;
}

void SyncPointManagerWrapper::RetireSyncPoint(uint32 sync_point) {
  manager_->RetireSyncPoint(sync_point);
}

void SyncPointManagerWrapper::AddSyncPointCallback(
    uint32 sync_point,
    const base::Closure& callback) {
  manager_->AddSyncPointCallback(sync_point, callback);
}

void SyncPointManagerWrapper::WaitSyncPoint(uint32 sync_point) {
  base::AutoLock lock(retire_lock_);
  while (!manager_->IsSyncPointRetired(sync_point)) {
    retire_cond_var_.Wait();
  }
}

void SyncPointManagerWrapper::OnSyncPointRetired() {
  base::AutoLock lock(retire_lock_);
  retire_cond_var_.Broadcast();
}

base::LazyInstance<SyncPointManagerWrapper> g_sync_point_manager =
    LAZY_INSTANCE_INITIALIZER;

base::SharedMemoryHandle ShareToGpuThread(
    base::SharedMemoryHandle source_handle) {
#if defined(OS_WIN)
  // Windows needs to explicitly duplicate the handle to current process.
  base::SharedMemoryHandle target_handle;
  if (!DuplicateHandle(GetCurrentProcess(),
                       source_handle,
                       GetCurrentProcess(),
                       &target_handle,
                       FILE_GENERIC_READ | FILE_GENERIC_WRITE,
                       FALSE,
                       0)) {
    return base::SharedMemory::NULLHandle();
  }

  return target_handle;
#else
  int duped_handle = HANDLE_EINTR(dup(source_handle.fd));
  if (duped_handle < 0)
    return base::SharedMemory::NULLHandle();

  return base::FileDescriptor(duped_handle, true);
#endif
}

gfx::GpuMemoryBufferHandle ShareGpuMemoryBufferToGpuThread(
    const gfx::GpuMemoryBufferHandle& source_handle,
    bool* requires_sync_point) {
  switch (source_handle.type) {
    case gfx::SHARED_MEMORY_BUFFER: {
      gfx::GpuMemoryBufferHandle handle;
      handle.type = gfx::SHARED_MEMORY_BUFFER;
      handle.handle = ShareToGpuThread(source_handle.handle);
      *requires_sync_point = false;
      return handle;
    }
    case gfx::IO_SURFACE_BUFFER:
    case gfx::SURFACE_TEXTURE_BUFFER:
    case gfx::OZONE_NATIVE_BUFFER:
      *requires_sync_point = true;
      return source_handle;
    default:
      NOTREACHED();
      return gfx::GpuMemoryBufferHandle();
  }
}

}  // anonyous namespace


InProcessCommandBuffer::
  InitializeOnGpuThreadParams::InitializeOnGpuThreadParams(
      bool is_offscreen,
      gfx::AcceleratedWidget window,
      const gfx::Size& size,
      const std::vector<int32>& attribs,
      gfx::GpuPreference gpu_preference,
      gpu::Capabilities* capabilities,
      InProcessCommandBuffer* share_group,
      ImageFactory* image_factory,
      const gfx::SurfaceConfiguration& requested_configuration)
        : is_offscreen(is_offscreen),
          window(window),
          size(size),
          attribs(attribs),
          gpu_preference(gpu_preference),
          capabilities(capabilities),
          context_group(share_group),
          image_factory(image_factory),
          requested_configuration(requested_configuration) {
}


InProcessCommandBuffer::Service::Service() {}

InProcessCommandBuffer::Service::~Service() {}

scoped_refptr<gfx::GLShareGroup>
InProcessCommandBuffer::Service::share_group() {
  if (!share_group_.get())
    share_group_ = new gfx::GLShareGroup;
  return share_group_;
}

scoped_refptr<gles2::MailboxManager>
InProcessCommandBuffer::Service::mailbox_manager() {
  if (!mailbox_manager_.get()) {
    if (base::CommandLine::ForCurrentProcess()->HasSwitch(
            switches::kEnableThreadedTextureMailboxes)) {
      mailbox_manager_ = new gles2::MailboxManagerSync();
    } else {
      mailbox_manager_ = new gles2::MailboxManagerImpl();
    }
  }
  return mailbox_manager_;
}

scoped_refptr<gles2::SubscriptionRefSet>
InProcessCommandBuffer::Service::subscription_ref_set() {
  if (!subscription_ref_set_.get()) {
    subscription_ref_set_ = new gles2::SubscriptionRefSet();
  }
  return subscription_ref_set_;
}

scoped_refptr<ValueStateMap>
InProcessCommandBuffer::Service::pending_valuebuffer_state() {
  if (!pending_valuebuffer_state_.get()) {
    pending_valuebuffer_state_ = new ValueStateMap();
  }
  return pending_valuebuffer_state_;
}

InProcessCommandBuffer::InProcessCommandBuffer(
    const scoped_refptr<Service>& service)
    : context_lost_(false),
      idle_work_pending_(false),
      image_factory_(nullptr),
      last_put_offset_(-1),
      gpu_memory_buffer_manager_(nullptr),
      flush_event_(false, false),
      service_(service.get() ? service : g_default_service.Get().gpu_thread),
      gpu_thread_weak_ptr_factory_(this) {
  DCHECK(service_.get());
  next_image_id_.GetNext();
}

InProcessCommandBuffer::~InProcessCommandBuffer() {
  Destroy();
}

void InProcessCommandBuffer::OnResizeView(gfx::Size size, float scale_factor) {
  CheckSequencedThread();
  DCHECK(!surface_->IsOffscreen());
  surface_->Resize(size);
}

bool InProcessCommandBuffer::MakeCurrent() {
  CheckSequencedThread();
  command_buffer_lock_.AssertAcquired();

  if (!context_lost_ && decoder_->MakeCurrent())
    return true;
  DLOG(ERROR) << "Context lost because MakeCurrent failed.";
  command_buffer_->SetContextLostReason(decoder_->GetContextLostReason());
  command_buffer_->SetParseError(gpu::error::kLostContext);
  return false;
}

void InProcessCommandBuffer::PumpCommands() {
  CheckSequencedThread();
  command_buffer_lock_.AssertAcquired();

  if (!MakeCurrent())
    return;

  gpu_scheduler_->PutChanged();
}

bool InProcessCommandBuffer::GetBufferChanged(int32 transfer_buffer_id) {
  CheckSequencedThread();
  command_buffer_lock_.AssertAcquired();
  command_buffer_->SetGetBuffer(transfer_buffer_id);
  return true;
}

bool InProcessCommandBuffer::Initialize(
    scoped_refptr<gfx::GLSurface> surface,
    bool is_offscreen,
    gfx::AcceleratedWidget window,
    const gfx::Size& size,
    const std::vector<int32>& attribs,
    gfx::GpuPreference gpu_preference,
    const base::Closure& context_lost_callback,
    InProcessCommandBuffer* share_group,
    GpuMemoryBufferManager* gpu_memory_buffer_manager,
    ImageFactory* image_factory,
    const gfx::SurfaceConfiguration& requested_configuration) {
  DCHECK(!share_group || service_.get() == share_group->service_.get());
  context_lost_callback_ = WrapCallback(context_lost_callback);

  if (surface.get()) {
    // GPU thread must be the same as client thread due to GLSurface not being
    // thread safe.
    sequence_checker_.reset(new base::SequenceChecker);
    surface_ = surface;
  }

  gpu::Capabilities capabilities;
  InitializeOnGpuThreadParams params(is_offscreen,
                                     window,
                                     size,
                                     attribs,
                                     gpu_preference,
                                     &capabilities,
                                     share_group,
                                     image_factory,
                                     requested_configuration);

  base::Callback<bool(void)> init_task =
      base::Bind(&InProcessCommandBuffer::InitializeOnGpuThread,
                 base::Unretained(this),
                 params);

  base::WaitableEvent completion(true, false);
  bool result = false;
  QueueTask(
      base::Bind(&RunTaskWithResult<bool>, init_task, &result, &completion));
  completion.Wait();

  gpu_memory_buffer_manager_ = gpu_memory_buffer_manager;

  if (result) {
    capabilities_ = capabilities;
    capabilities_.image = capabilities_.image && gpu_memory_buffer_manager_;
  }

  return result;
}

bool InProcessCommandBuffer::InitializeOnGpuThread(
    const InitializeOnGpuThreadParams& params) {
  CheckSequencedThread();
  gpu_thread_weak_ptr_ = gpu_thread_weak_ptr_factory_.GetWeakPtr();

  DCHECK(params.size.width() >= 0 && params.size.height() >= 0);

  TransferBufferManager* manager = new TransferBufferManager();
  transfer_buffer_manager_.reset(manager);
  manager->Initialize();

  scoped_ptr<CommandBufferService> command_buffer(
      new CommandBufferService(transfer_buffer_manager_.get()));
  command_buffer->SetPutOffsetChangeCallback(base::Bind(
      &InProcessCommandBuffer::PumpCommands, gpu_thread_weak_ptr_));
  command_buffer->SetParseErrorCallback(base::Bind(
      &InProcessCommandBuffer::OnContextLost, gpu_thread_weak_ptr_));

  if (!command_buffer->Initialize()) {
    LOG(ERROR) << "Could not initialize command buffer.";
    DestroyOnGpuThread();
    return false;
  }

  gl_share_group_ = params.context_group
                        ? params.context_group->gl_share_group_
                        : service_->share_group();

#if defined(OS_ANDROID)
  stream_texture_manager_.reset(new StreamTextureManagerInProcess);
#endif

  bool bind_generates_resource = false;
  decoder_.reset(gles2::GLES2Decoder::Create(
      params.context_group
          ? params.context_group->decoder_->GetContextGroup()
          : new gles2::ContextGroup(service_->mailbox_manager(),
                                    NULL,
                                    service_->shader_translator_cache(),
                                    NULL,
                                    service_->subscription_ref_set(),
                                    service_->pending_valuebuffer_state(),
                                    bind_generates_resource)));

  gpu_scheduler_.reset(
      new GpuScheduler(command_buffer.get(), decoder_.get(), decoder_.get()));
  command_buffer->SetGetBufferChangeCallback(base::Bind(
      &GpuScheduler::SetGetBuffer, base::Unretained(gpu_scheduler_.get())));
  command_buffer_ = command_buffer.Pass();

  decoder_->set_engine(gpu_scheduler_.get());

  if (!surface_.get()) {
    if (params.is_offscreen)
      surface_ = gfx::GLSurface::CreateOffscreenGLSurface(
          params.size, params.requested_configuration);
    else
      surface_ = gfx::GLSurface::CreateViewGLSurface(
          params.window, params.requested_configuration);
  }

  if (!surface_.get()) {
    LOG(ERROR) << "Could not create GLSurface.";
    DestroyOnGpuThread();
    return false;
  }

  if (service_->UseVirtualizedGLContexts() ||
      decoder_->GetContextGroup()
          ->feature_info()
          ->workarounds()
          .use_virtualized_gl_contexts) {
    context_ = gl_share_group_->GetSharedContext();
    if (!context_.get()) {
      context_ = gfx::GLContext::CreateGLContext(
          gl_share_group_.get(), surface_.get(), params.gpu_preference);
      gl_share_group_->SetSharedContext(context_.get());
    }

    context_ = new GLContextVirtual(
        gl_share_group_.get(), context_.get(), decoder_->AsWeakPtr());
    if (context_->Initialize(surface_.get(), params.gpu_preference)) {
      VLOG(1) << "Created virtual GL context.";
    } else {
      context_ = NULL;
    }
  } else {
    context_ = gfx::GLContext::CreateGLContext(
        gl_share_group_.get(), surface_.get(), params.gpu_preference);
  }

  if (!context_.get()) {
    LOG(ERROR) << "Could not create GLContext.";
    DestroyOnGpuThread();
    return false;
  }

  if (!context_->MakeCurrent(surface_.get())) {
    LOG(ERROR) << "Could not make context current.";
    DestroyOnGpuThread();
    return false;
  }

  gles2::DisallowedFeatures disallowed_features;
  disallowed_features.gpu_memory_manager = true;
  if (!decoder_->Initialize(surface_,
                            context_,
                            params.is_offscreen,
                            params.size,
                            disallowed_features,
                            params.attribs)) {
    LOG(ERROR) << "Could not initialize decoder.";
    DestroyOnGpuThread();
    return false;
  }
  *params.capabilities = decoder_->GetCapabilities();

  if (!params.is_offscreen) {
    decoder_->SetResizeCallback(base::Bind(
        &InProcessCommandBuffer::OnResizeView, gpu_thread_weak_ptr_));
  }
  decoder_->SetWaitSyncPointCallback(
      base::Bind(&InProcessCommandBuffer::WaitSyncPointOnGpuThread,
                 base::Unretained(this)));

  image_factory_ = params.image_factory;
  params.capabilities->image = params.capabilities->image && image_factory_;

  return true;
}

void InProcessCommandBuffer::Destroy() {
  CheckSequencedThread();

  base::WaitableEvent completion(true, false);
  bool result = false;
  base::Callback<bool(void)> destroy_task = base::Bind(
      &InProcessCommandBuffer::DestroyOnGpuThread, base::Unretained(this));
  QueueTask(
      base::Bind(&RunTaskWithResult<bool>, destroy_task, &result, &completion));
  completion.Wait();
}

bool InProcessCommandBuffer::DestroyOnGpuThread() {
  CheckSequencedThread();
  gpu_thread_weak_ptr_factory_.InvalidateWeakPtrs();
  command_buffer_.reset();
  // Clean up GL resources if possible.
  bool have_context = context_.get() && context_->MakeCurrent(surface_.get());
  if (decoder_) {
    decoder_->Destroy(have_context);
    decoder_.reset();
  }
  context_ = NULL;
  surface_ = NULL;
  gl_share_group_ = NULL;
#if defined(OS_ANDROID)
  stream_texture_manager_.reset();
#endif

  return true;
}

void InProcessCommandBuffer::CheckSequencedThread() {
  DCHECK(!sequence_checker_ ||
         sequence_checker_->CalledOnValidSequencedThread());
}

void InProcessCommandBuffer::OnContextLost() {
  CheckSequencedThread();
  if (!context_lost_callback_.is_null()) {
    context_lost_callback_.Run();
    context_lost_callback_.Reset();
  }

  context_lost_ = true;
}

CommandBuffer::State InProcessCommandBuffer::GetStateFast() {
  CheckSequencedThread();
  base::AutoLock lock(state_after_last_flush_lock_);
  if (state_after_last_flush_.generation - last_state_.generation < 0x80000000U)
    last_state_ = state_after_last_flush_;
  return last_state_;
}

CommandBuffer::State InProcessCommandBuffer::GetLastState() {
  CheckSequencedThread();
  return last_state_;
}

int32 InProcessCommandBuffer::GetLastToken() {
  CheckSequencedThread();
  GetStateFast();
  return last_state_.token;
}

void InProcessCommandBuffer::FlushOnGpuThread(int32 put_offset) {
  CheckSequencedThread();
  ScopedEvent handle_flush(&flush_event_);
  base::AutoLock lock(command_buffer_lock_);
  command_buffer_->Flush(put_offset);
  {
    // Update state before signaling the flush event.
    base::AutoLock lock(state_after_last_flush_lock_);
    state_after_last_flush_ = command_buffer_->GetLastState();
  }
  DCHECK((!error::IsError(state_after_last_flush_.error) && !context_lost_) ||
         (error::IsError(state_after_last_flush_.error) && context_lost_));

  // If we've processed all pending commands but still have pending queries,
  // pump idle work until the query is passed.
  if (put_offset == state_after_last_flush_.get_offset &&
      gpu_scheduler_->HasMoreWork()) {
    ScheduleIdleWorkOnGpuThread();
  }
}

void InProcessCommandBuffer::PerformIdleWork() {
  CheckSequencedThread();
  idle_work_pending_ = false;
  base::AutoLock lock(command_buffer_lock_);
  if (MakeCurrent() && gpu_scheduler_->HasMoreWork()) {
    gpu_scheduler_->PerformIdleWork();
    ScheduleIdleWorkOnGpuThread();
  }
}

void InProcessCommandBuffer::ScheduleIdleWorkOnGpuThread() {
  CheckSequencedThread();
  if (idle_work_pending_)
    return;
  idle_work_pending_ = true;
  service_->ScheduleIdleWork(
      base::Bind(&InProcessCommandBuffer::PerformIdleWork,
                 gpu_thread_weak_ptr_));
}

void InProcessCommandBuffer::Flush(int32 put_offset) {
  CheckSequencedThread();
  if (last_state_.error != gpu::error::kNoError)
    return;

  if (last_put_offset_ == put_offset)
    return;

  last_put_offset_ = put_offset;
  base::Closure task = base::Bind(&InProcessCommandBuffer::FlushOnGpuThread,
                                  gpu_thread_weak_ptr_,
                                  put_offset);
  QueueTask(task);
}

void InProcessCommandBuffer::OrderingBarrier(int32 put_offset) {
  Flush(put_offset);
}

void InProcessCommandBuffer::WaitForTokenInRange(int32 start, int32 end) {
  CheckSequencedThread();
  while (!InRange(start, end, GetLastToken()) &&
         last_state_.error == gpu::error::kNoError)
    flush_event_.Wait();
}

void InProcessCommandBuffer::WaitForGetOffsetInRange(int32 start, int32 end) {
  CheckSequencedThread();

  GetStateFast();
  while (!InRange(start, end, last_state_.get_offset) &&
         last_state_.error == gpu::error::kNoError) {
    flush_event_.Wait();
    GetStateFast();
  }
}

void InProcessCommandBuffer::SetGetBuffer(int32 shm_id) {
  CheckSequencedThread();
  if (last_state_.error != gpu::error::kNoError)
    return;

  {
    base::AutoLock lock(command_buffer_lock_);
    command_buffer_->SetGetBuffer(shm_id);
    last_put_offset_ = 0;
  }
  {
    base::AutoLock lock(state_after_last_flush_lock_);
    state_after_last_flush_ = command_buffer_->GetLastState();
  }
}

scoped_refptr<Buffer> InProcessCommandBuffer::CreateTransferBuffer(size_t size,
                                                                   int32* id) {
  CheckSequencedThread();
  base::AutoLock lock(command_buffer_lock_);
  return command_buffer_->CreateTransferBuffer(size, id);
}

void InProcessCommandBuffer::DestroyTransferBuffer(int32 id) {
  CheckSequencedThread();
  base::Closure task =
      base::Bind(&InProcessCommandBuffer::DestroyTransferBufferOnGpuThread,
                 base::Unretained(this),
                 id);

  QueueTask(task);
}

void InProcessCommandBuffer::DestroyTransferBufferOnGpuThread(int32 id) {
  base::AutoLock lock(command_buffer_lock_);
  command_buffer_->DestroyTransferBuffer(id);
}

gpu::Capabilities InProcessCommandBuffer::GetCapabilities() {
  return capabilities_;
}

int32 InProcessCommandBuffer::CreateImage(ClientBuffer buffer,
                                          size_t width,
                                          size_t height,
                                          unsigned internalformat) {
  CheckSequencedThread();

  DCHECK(gpu_memory_buffer_manager_);
  gfx::GpuMemoryBuffer* gpu_memory_buffer =
      gpu_memory_buffer_manager_->GpuMemoryBufferFromClientBuffer(buffer);
  DCHECK(gpu_memory_buffer);

  int32 new_id = next_image_id_.GetNext();

  DCHECK(gpu::ImageFactory::IsImageFormatCompatibleWithGpuMemoryBufferFormat(
      internalformat, gpu_memory_buffer->GetFormat()));

  // This handle is owned by the GPU thread and must be passed to it or it
  // will leak. In otherwords, do not early out on error between here and the
  // queuing of the CreateImage task below.
  bool requires_sync_point = false;
  gfx::GpuMemoryBufferHandle handle =
      ShareGpuMemoryBufferToGpuThread(gpu_memory_buffer->GetHandle(),
                                      &requires_sync_point);

  QueueTask(base::Bind(&InProcessCommandBuffer::CreateImageOnGpuThread,
                       base::Unretained(this),
                       new_id,
                       handle,
                       gfx::Size(width, height),
                       gpu_memory_buffer->GetFormat(),
                       internalformat));

  if (requires_sync_point) {
    gpu_memory_buffer_manager_->SetDestructionSyncPoint(gpu_memory_buffer,
                                                        InsertSyncPoint());
  }

  return new_id;
}

void InProcessCommandBuffer::CreateImageOnGpuThread(
    int32 id,
    const gfx::GpuMemoryBufferHandle& handle,
    const gfx::Size& size,
    gfx::GpuMemoryBuffer::Format format,
    uint32 internalformat) {
  if (!decoder_)
    return;

  gpu::gles2::ImageManager* image_manager = decoder_->GetImageManager();
  DCHECK(image_manager);
  if (image_manager->LookupImage(id)) {
    LOG(ERROR) << "Image already exists with same ID.";
    return;
  }

  // Note: this assumes that client ID is always 0.
  const int kClientId = 0;

  DCHECK(image_factory_);
  scoped_refptr<gfx::GLImage> image =
      image_factory_->CreateImageForGpuMemoryBuffer(
          handle, size, format, internalformat, kClientId);
  if (!image.get())
    return;

  image_manager->AddImage(image.get(), id);
}

void InProcessCommandBuffer::DestroyImage(int32 id) {
  CheckSequencedThread();

  QueueTask(base::Bind(&InProcessCommandBuffer::DestroyImageOnGpuThread,
                       base::Unretained(this),
                       id));
}

void InProcessCommandBuffer::DestroyImageOnGpuThread(int32 id) {
  if (!decoder_)
    return;

  gpu::gles2::ImageManager* image_manager = decoder_->GetImageManager();
  DCHECK(image_manager);
  if (!image_manager->LookupImage(id)) {
    LOG(ERROR) << "Image with ID doesn't exist.";
    return;
  }

  image_manager->RemoveImage(id);
}

int32 InProcessCommandBuffer::CreateGpuMemoryBufferImage(
    size_t width,
    size_t height,
    unsigned internalformat,
    unsigned usage) {
  CheckSequencedThread();

  DCHECK(gpu_memory_buffer_manager_);
  scoped_ptr<gfx::GpuMemoryBuffer> buffer(
      gpu_memory_buffer_manager_->AllocateGpuMemoryBuffer(
          gfx::Size(width, height),
          gpu::ImageFactory::ImageFormatToGpuMemoryBufferFormat(internalformat),
          gpu::ImageFactory::ImageUsageToGpuMemoryBufferUsage(usage)));
  if (!buffer)
    return -1;

  return CreateImage(buffer->AsClientBuffer(), width, height, internalformat);
}

uint32 InProcessCommandBuffer::InsertSyncPoint() {
  uint32 sync_point = g_sync_point_manager.Get().GenerateSyncPoint();
  QueueTask(base::Bind(&InProcessCommandBuffer::RetireSyncPointOnGpuThread,
                       base::Unretained(this),
                       sync_point));
  return sync_point;
}

uint32 InProcessCommandBuffer::InsertFutureSyncPoint() {
  return g_sync_point_manager.Get().GenerateSyncPoint();
}

void InProcessCommandBuffer::RetireSyncPoint(uint32 sync_point) {
  QueueTask(base::Bind(&InProcessCommandBuffer::RetireSyncPointOnGpuThread,
                       base::Unretained(this),
                       sync_point));
}

void InProcessCommandBuffer::RetireSyncPointOnGpuThread(uint32 sync_point) {
  gles2::MailboxManager* mailbox_manager =
      decoder_->GetContextGroup()->mailbox_manager();
  if (mailbox_manager->UsesSync()) {
    bool make_current_success = false;
    {
      base::AutoLock lock(command_buffer_lock_);
      make_current_success = MakeCurrent();
    }
    if (make_current_success)
      mailbox_manager->PushTextureUpdates(sync_point);
  }
  g_sync_point_manager.Get().RetireSyncPoint(sync_point);
}

void InProcessCommandBuffer::SignalSyncPoint(unsigned sync_point,
                                             const base::Closure& callback) {
  CheckSequencedThread();
  QueueTask(base::Bind(&InProcessCommandBuffer::SignalSyncPointOnGpuThread,
                       base::Unretained(this),
                       sync_point,
                       WrapCallback(callback)));
}

bool InProcessCommandBuffer::WaitSyncPointOnGpuThread(unsigned sync_point) {
  g_sync_point_manager.Get().WaitSyncPoint(sync_point);
  gles2::MailboxManager* mailbox_manager =
      decoder_->GetContextGroup()->mailbox_manager();
  mailbox_manager->PullTextureUpdates(sync_point);
  return true;
}

void InProcessCommandBuffer::SignalSyncPointOnGpuThread(
    unsigned sync_point,
    const base::Closure& callback) {
  g_sync_point_manager.Get().AddSyncPointCallback(sync_point, callback);
}

void InProcessCommandBuffer::SignalQuery(unsigned query_id,
                                         const base::Closure& callback) {
  CheckSequencedThread();
  QueueTask(base::Bind(&InProcessCommandBuffer::SignalQueryOnGpuThread,
                       base::Unretained(this),
                       query_id,
                       WrapCallback(callback)));
}

void InProcessCommandBuffer::SignalQueryOnGpuThread(
    unsigned query_id,
    const base::Closure& callback) {
  gles2::QueryManager* query_manager_ = decoder_->GetQueryManager();
  DCHECK(query_manager_);

  gles2::QueryManager::Query* query = query_manager_->GetQuery(query_id);
  if (!query)
    callback.Run();
  else
    query->AddCallback(callback);
}

void InProcessCommandBuffer::SetSurfaceVisible(bool visible) {}

uint32 InProcessCommandBuffer::CreateStreamTexture(uint32 texture_id) {
  base::WaitableEvent completion(true, false);
  uint32 stream_id = 0;
  base::Callback<uint32(void)> task =
      base::Bind(&InProcessCommandBuffer::CreateStreamTextureOnGpuThread,
                 base::Unretained(this),
                 texture_id);
  QueueTask(
      base::Bind(&RunTaskWithResult<uint32>, task, &stream_id, &completion));
  completion.Wait();
  return stream_id;
}

void InProcessCommandBuffer::SetLock(base::Lock*) {
}

uint32 InProcessCommandBuffer::CreateStreamTextureOnGpuThread(
    uint32 client_texture_id) {
#if defined(OS_ANDROID)
  return stream_texture_manager_->CreateStreamTexture(
      client_texture_id, decoder_->GetContextGroup()->texture_manager());
#else
  return 0;
#endif
}

gpu::error::Error InProcessCommandBuffer::GetLastError() {
  CheckSequencedThread();
  return last_state_.error;
}

bool InProcessCommandBuffer::Initialize() {
  NOTREACHED();
  return false;
}

namespace {

void PostCallback(const scoped_refptr<base::MessageLoopProxy>& loop,
                         const base::Closure& callback) {
  // The loop.get() check is to support using InProcessCommandBuffer on a thread
  // without a message loop.
  if (loop.get() && !loop->BelongsToCurrentThread()) {
    loop->PostTask(FROM_HERE, callback);
  } else {
    callback.Run();
  }
}

void RunOnTargetThread(scoped_ptr<base::Closure> callback) {
  DCHECK(callback.get());
  callback->Run();
}

}  // anonymous namespace

base::Closure InProcessCommandBuffer::WrapCallback(
    const base::Closure& callback) {
  // Make sure the callback gets deleted on the target thread by passing
  // ownership.
  scoped_ptr<base::Closure> scoped_callback(new base::Closure(callback));
  base::Closure callback_on_client_thread =
      base::Bind(&RunOnTargetThread, base::Passed(&scoped_callback));
  base::Closure wrapped_callback =
      base::Bind(&PostCallback, base::MessageLoopProxy::current(),
                 callback_on_client_thread);
  return wrapped_callback;
}

#if defined(OS_ANDROID)
scoped_refptr<gfx::SurfaceTexture>
InProcessCommandBuffer::GetSurfaceTexture(uint32 stream_id) {
  DCHECK(stream_texture_manager_);
  return stream_texture_manager_->GetSurfaceTexture(stream_id);
}
#endif

}  // namespace gpu
