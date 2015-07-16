// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/async_pixel_transfer_manager_share_group.h"

#include <list>

#include "base/bind.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/memory/weak_ptr.h"
#include "base/synchronization/cancellation_flag.h"
#include "base/synchronization/lock.h"
#include "base/synchronization/waitable_event.h"
#include "base/threading/thread.h"
#include "base/threading/thread_checker.h"
#include "base/trace_event/trace_event.h"
#include "base/trace_event/trace_event_synthetic_delay.h"
#include "gpu/command_buffer/service/async_pixel_transfer_delegate.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_surface.h"
#include "ui/gl/gpu_preference.h"
#include "ui/gl/scoped_binders.h"

namespace gpu {

namespace {

const char kAsyncTransferThreadName[] = "AsyncTransferThread";

void PerformNotifyCompletion(
    AsyncMemoryParams mem_params,
    scoped_refptr<AsyncPixelTransferCompletionObserver> observer) {
  TRACE_EVENT0("gpu", "PerformNotifyCompletion");
  observer->DidComplete(mem_params);
}

// TODO(backer): Factor out common thread scheduling logic from the EGL and
// ShareGroup implementations. http://crbug.com/239889
class TransferThread : public base::Thread {
 public:
  TransferThread()
      : base::Thread(kAsyncTransferThreadName),
        initialized_(false) {
    Start();
#if defined(OS_ANDROID) || defined(OS_LINUX)
    SetPriority(base::ThreadPriority::BACKGROUND);
#endif
  }

  ~TransferThread() override {
    // The only instance of this class was declared leaky.
    NOTREACHED();
  }

  void InitializeOnMainThread(gfx::GLContext* parent_context) {
    TRACE_EVENT0("gpu", "TransferThread::InitializeOnMainThread");
    if (initialized_)
      return;

    base::WaitableEvent wait_for_init(true, false);
    message_loop_proxy()->PostTask(
      FROM_HERE,
      base::Bind(&TransferThread::InitializeOnTransferThread,
                 base::Unretained(this),
                 base::Unretained(parent_context),
                 &wait_for_init));
    wait_for_init.Wait();
  }

  void CleanUp() override {
    surface_ = NULL;
    context_ = NULL;
  }

 private:
  bool initialized_;

  scoped_refptr<gfx::GLSurface> surface_;
  scoped_refptr<gfx::GLContext> context_;

  void InitializeOnTransferThread(gfx::GLContext* parent_context,
                                   base::WaitableEvent* caller_wait) {
    TRACE_EVENT0("gpu", "InitializeOnTransferThread");

    if (!parent_context) {
      LOG(ERROR) << "No parent context provided.";
      caller_wait->Signal();
      return;
    }

    surface_ = gfx::GLSurface::CreateOffscreenGLSurface(
        gfx::Size(1, 1), gfx::SurfaceConfiguration());
    if (!surface_.get()) {
      LOG(ERROR) << "Unable to create GLSurface";
      caller_wait->Signal();
      return;
    }

    // TODO(backer): This is coded for integrated GPUs. For discrete GPUs
    // we would probably want to use a PBO texture upload for a true async
    // upload (that would hopefully be optimized as a DMA transfer by the
    // driver).
    context_ = gfx::GLContext::CreateGLContext(parent_context->share_group(),
                                               surface_.get(),
                                               gfx::PreferIntegratedGpu);
    if (!context_.get()) {
      LOG(ERROR) << "Unable to create GLContext.";
      caller_wait->Signal();
      return;
    }

    context_->MakeCurrent(surface_.get());
    initialized_ = true;
    caller_wait->Signal();
  }

  DISALLOW_COPY_AND_ASSIGN(TransferThread);
};

base::LazyInstance<TransferThread>::Leaky
    g_transfer_thread = LAZY_INSTANCE_INITIALIZER;

base::MessageLoopProxy* transfer_message_loop_proxy() {
  return g_transfer_thread.Pointer()->message_loop_proxy().get();
}

class PendingTask : public base::RefCountedThreadSafe<PendingTask> {
 public:
  explicit PendingTask(const base::Closure& task)
      : task_(task), task_pending_(true, false) {}

  bool TryRun() {
    // This is meant to be called on the main thread where the texture
    // is already bound.
    DCHECK(checker_.CalledOnValidThread());
    if (task_lock_.Try()) {
      // Only run once.
      if (!task_.is_null())
        task_.Run();
      task_.Reset();

      task_lock_.Release();
      task_pending_.Signal();
      return true;
    }
    return false;
  }

  void BindAndRun(GLuint texture_id) {
    // This is meant to be called on the upload thread where we don't have to
    // restore the previous texture binding.
    DCHECK(!checker_.CalledOnValidThread());
    base::AutoLock locked(task_lock_);
    if (!task_.is_null()) {
      glBindTexture(GL_TEXTURE_2D, texture_id);
      task_.Run();
      task_.Reset();
      glBindTexture(GL_TEXTURE_2D, 0);
      // Flush for synchronization between threads.
      glFlush();
      task_pending_.Signal();
    }
  }

  void Cancel() {
    base::AutoLock locked(task_lock_);
    task_.Reset();
    task_pending_.Signal();
  }

  bool TaskIsInProgress() {
    return !task_pending_.IsSignaled();
  }

  void WaitForTask() {
    task_pending_.Wait();
  }

 private:
  friend class base::RefCountedThreadSafe<PendingTask>;

  virtual ~PendingTask() {}

  base::ThreadChecker checker_;

  base::Lock task_lock_;
  base::Closure task_;
  base::WaitableEvent task_pending_;

  DISALLOW_COPY_AND_ASSIGN(PendingTask);
};

// Class which holds async pixel transfers state.
// The texture_id is accessed by either thread, but everything
// else accessed only on the main thread.
class TransferStateInternal
    : public base::RefCountedThreadSafe<TransferStateInternal> {
 public:
  TransferStateInternal(GLuint texture_id,
                        const AsyncTexImage2DParams& define_params)
      : texture_id_(texture_id), define_params_(define_params) {}

  bool TransferIsInProgress() {
    return pending_upload_task_.get() &&
           pending_upload_task_->TaskIsInProgress();
  }

  void BindTransfer() {
    TRACE_EVENT2("gpu", "BindAsyncTransfer",
                 "width", define_params_.width,
                 "height", define_params_.height);
    DCHECK(texture_id_);

    glBindTexture(GL_TEXTURE_2D, texture_id_);
    bind_callback_.Run();
  }

  void WaitForTransferCompletion() {
    TRACE_EVENT0("gpu", "WaitForTransferCompletion");
    DCHECK(pending_upload_task_.get());
    if (!pending_upload_task_->TryRun()) {
      pending_upload_task_->WaitForTask();
    }
    pending_upload_task_ = NULL;
  }

  void CancelUpload() {
    TRACE_EVENT0("gpu", "CancelUpload");
    if (pending_upload_task_.get())
      pending_upload_task_->Cancel();
    pending_upload_task_ = NULL;
  }

  void ScheduleAsyncTexImage2D(
      const AsyncTexImage2DParams tex_params,
      const AsyncMemoryParams mem_params,
      scoped_refptr<AsyncPixelTransferUploadStats> texture_upload_stats,
      const base::Closure& bind_callback) {
    TRACE_EVENT_SYNTHETIC_DELAY_BEGIN("gpu.AsyncTexImage");
    pending_upload_task_ = new PendingTask(base::Bind(
        &TransferStateInternal::PerformAsyncTexImage2D,
        this,
        tex_params,
        mem_params,
        texture_upload_stats));
    transfer_message_loop_proxy()->PostTask(
        FROM_HERE,
        base::Bind(
            &PendingTask::BindAndRun, pending_upload_task_, texture_id_));

    // Save the late bind callback, so we can notify the client when it is
    // bound.
    bind_callback_ = bind_callback;
  }

  void ScheduleAsyncTexSubImage2D(
      AsyncTexSubImage2DParams tex_params,
      AsyncMemoryParams mem_params,
      scoped_refptr<AsyncPixelTransferUploadStats> texture_upload_stats) {
    TRACE_EVENT_SYNTHETIC_DELAY_BEGIN("gpu.AsyncTexImage");
    pending_upload_task_ = new PendingTask(base::Bind(
        &TransferStateInternal::PerformAsyncTexSubImage2D,
        this,
        tex_params,
        mem_params,
        texture_upload_stats));
    transfer_message_loop_proxy()->PostTask(
        FROM_HERE,
        base::Bind(
            &PendingTask::BindAndRun, pending_upload_task_, texture_id_));
  }

 private:
  friend class base::RefCountedThreadSafe<TransferStateInternal>;

  virtual ~TransferStateInternal() {
  }

  void PerformAsyncTexImage2D(
      AsyncTexImage2DParams tex_params,
      AsyncMemoryParams mem_params,
      scoped_refptr<AsyncPixelTransferUploadStats> texture_upload_stats) {
    TRACE_EVENT2("gpu",
                 "PerformAsyncTexImage",
                 "width",
                 tex_params.width,
                 "height",
                 tex_params.height);
    DCHECK_EQ(0, tex_params.level);

    base::TimeTicks begin_time;
    if (texture_upload_stats.get())
      begin_time = base::TimeTicks::Now();

    void* data = mem_params.GetDataAddress();

    {
      TRACE_EVENT0("gpu", "glTexImage2D");
      glTexImage2D(GL_TEXTURE_2D,
                   tex_params.level,
                   tex_params.internal_format,
                   tex_params.width,
                   tex_params.height,
                   tex_params.border,
                   tex_params.format,
                   tex_params.type,
                   data);
      TRACE_EVENT_SYNTHETIC_DELAY_END("gpu.AsyncTexImage");
    }

    if (texture_upload_stats.get()) {
      texture_upload_stats->AddUpload(base::TimeTicks::Now() - begin_time);
    }
  }

  void PerformAsyncTexSubImage2D(
      AsyncTexSubImage2DParams tex_params,
      AsyncMemoryParams mem_params,
      scoped_refptr<AsyncPixelTransferUploadStats> texture_upload_stats) {
    TRACE_EVENT2("gpu",
                 "PerformAsyncTexSubImage2D",
                 "width",
                 tex_params.width,
                 "height",
                 tex_params.height);
    DCHECK_EQ(0, tex_params.level);

    base::TimeTicks begin_time;
    if (texture_upload_stats.get())
      begin_time = base::TimeTicks::Now();

    void* data = mem_params.GetDataAddress();
    {
      TRACE_EVENT0("gpu", "glTexSubImage2D");
      glTexSubImage2D(GL_TEXTURE_2D,
                      tex_params.level,
                      tex_params.xoffset,
                      tex_params.yoffset,
                      tex_params.width,
                      tex_params.height,
                      tex_params.format,
                      tex_params.type,
                      data);
      TRACE_EVENT_SYNTHETIC_DELAY_END("gpu.AsyncTexImage");
    }

    if (texture_upload_stats.get()) {
      texture_upload_stats->AddUpload(base::TimeTicks::Now() - begin_time);
    }
  }

  scoped_refptr<PendingTask> pending_upload_task_;

  GLuint texture_id_;

  // Definition params for texture that needs binding.
  AsyncTexImage2DParams define_params_;

  // Callback to invoke when AsyncTexImage2D is complete
  // and the client can safely use the texture. This occurs
  // during BindCompletedAsyncTransfers().
  base::Closure bind_callback_;
};

}  // namespace

class AsyncPixelTransferDelegateShareGroup
    : public AsyncPixelTransferDelegate,
      public base::SupportsWeakPtr<AsyncPixelTransferDelegateShareGroup> {
 public:
  AsyncPixelTransferDelegateShareGroup(
      AsyncPixelTransferManagerShareGroup::SharedState* shared_state,
      GLuint texture_id,
      const AsyncTexImage2DParams& define_params);
  ~AsyncPixelTransferDelegateShareGroup() override;

  void BindTransfer() { state_->BindTransfer(); }

  // Implement AsyncPixelTransferDelegate:
  void AsyncTexImage2D(const AsyncTexImage2DParams& tex_params,
                       const AsyncMemoryParams& mem_params,
                       const base::Closure& bind_callback) override;
  void AsyncTexSubImage2D(const AsyncTexSubImage2DParams& tex_params,
                          const AsyncMemoryParams& mem_params) override;
  bool TransferIsInProgress() override;
  void WaitForTransferCompletion() override;

 private:
  // A raw pointer is safe because the SharedState is owned by the Manager,
  // which owns this Delegate.
  AsyncPixelTransferManagerShareGroup::SharedState* shared_state_;
  scoped_refptr<TransferStateInternal> state_;

  DISALLOW_COPY_AND_ASSIGN(AsyncPixelTransferDelegateShareGroup);
};

AsyncPixelTransferDelegateShareGroup::AsyncPixelTransferDelegateShareGroup(
    AsyncPixelTransferManagerShareGroup::SharedState* shared_state,
    GLuint texture_id,
    const AsyncTexImage2DParams& define_params)
    : shared_state_(shared_state),
      state_(new TransferStateInternal(texture_id, define_params)) {}

AsyncPixelTransferDelegateShareGroup::~AsyncPixelTransferDelegateShareGroup() {
  TRACE_EVENT0("gpu", " ~AsyncPixelTransferDelegateShareGroup");
  state_->CancelUpload();
}

bool AsyncPixelTransferDelegateShareGroup::TransferIsInProgress() {
  return state_->TransferIsInProgress();
}

void AsyncPixelTransferDelegateShareGroup::WaitForTransferCompletion() {
  if (state_->TransferIsInProgress()) {
    state_->WaitForTransferCompletion();
    DCHECK(!state_->TransferIsInProgress());
  }

  // Fast track the BindTransfer, if applicable.
  for (AsyncPixelTransferManagerShareGroup::SharedState::TransferQueue::iterator
           iter = shared_state_->pending_allocations.begin();
       iter != shared_state_->pending_allocations.end();
       ++iter) {
    if (iter->get() != this)
      continue;

    shared_state_->pending_allocations.erase(iter);
    BindTransfer();
    break;
  }
}

void AsyncPixelTransferDelegateShareGroup::AsyncTexImage2D(
    const AsyncTexImage2DParams& tex_params,
    const AsyncMemoryParams& mem_params,
    const base::Closure& bind_callback) {
  DCHECK(!state_->TransferIsInProgress());
  DCHECK_EQ(static_cast<GLenum>(GL_TEXTURE_2D), tex_params.target);
  DCHECK_EQ(tex_params.level, 0);

  shared_state_->pending_allocations.push_back(AsWeakPtr());
  state_->ScheduleAsyncTexImage2D(tex_params,
                                  mem_params,
                                  shared_state_->texture_upload_stats,
                                  bind_callback);
}

void AsyncPixelTransferDelegateShareGroup::AsyncTexSubImage2D(
    const AsyncTexSubImage2DParams& tex_params,
    const AsyncMemoryParams& mem_params) {
  TRACE_EVENT2("gpu", "AsyncTexSubImage2D",
               "width", tex_params.width,
               "height", tex_params.height);
  DCHECK(!state_->TransferIsInProgress());
  DCHECK_EQ(static_cast<GLenum>(GL_TEXTURE_2D), tex_params.target);
  DCHECK_EQ(tex_params.level, 0);

  state_->ScheduleAsyncTexSubImage2D(
      tex_params, mem_params, shared_state_->texture_upload_stats);
}

AsyncPixelTransferManagerShareGroup::SharedState::SharedState()
    // TODO(reveman): Skip this if --enable-gpu-benchmarking is not present.
    : texture_upload_stats(new AsyncPixelTransferUploadStats) {}

AsyncPixelTransferManagerShareGroup::SharedState::~SharedState() {}

AsyncPixelTransferManagerShareGroup::AsyncPixelTransferManagerShareGroup(
    gfx::GLContext* context) {
  g_transfer_thread.Pointer()->InitializeOnMainThread(context);
}

AsyncPixelTransferManagerShareGroup::~AsyncPixelTransferManagerShareGroup() {}

void AsyncPixelTransferManagerShareGroup::BindCompletedAsyncTransfers() {
  scoped_ptr<gfx::ScopedTextureBinder> texture_binder;

  while (!shared_state_.pending_allocations.empty()) {
    if (!shared_state_.pending_allocations.front().get()) {
      shared_state_.pending_allocations.pop_front();
      continue;
    }
    AsyncPixelTransferDelegateShareGroup* delegate =
        shared_state_.pending_allocations.front().get();
    // Terminate early, as all transfers finish in order, currently.
    if (delegate->TransferIsInProgress())
      break;

    if (!texture_binder)
      texture_binder.reset(new gfx::ScopedTextureBinder(GL_TEXTURE_2D, 0));

    // Used to set tex info from the gles2 cmd decoder once upload has
    // finished (it'll bind the texture and call a callback).
    delegate->BindTransfer();

    shared_state_.pending_allocations.pop_front();
  }
}

void AsyncPixelTransferManagerShareGroup::AsyncNotifyCompletion(
    const AsyncMemoryParams& mem_params,
    AsyncPixelTransferCompletionObserver* observer) {
  // Post a PerformNotifyCompletion task to the upload thread. This task
  // will run after all async transfers are complete.
  transfer_message_loop_proxy()->PostTask(
      FROM_HERE,
      base::Bind(&PerformNotifyCompletion,
                 mem_params,
                 make_scoped_refptr(observer)));
}

uint32 AsyncPixelTransferManagerShareGroup::GetTextureUploadCount() {
  return shared_state_.texture_upload_stats->GetStats(NULL);
}

base::TimeDelta
AsyncPixelTransferManagerShareGroup::GetTotalTextureUploadTime() {
  base::TimeDelta total_texture_upload_time;
  shared_state_.texture_upload_stats->GetStats(&total_texture_upload_time);
  return total_texture_upload_time;
}

void AsyncPixelTransferManagerShareGroup::ProcessMorePendingTransfers() {
}

bool AsyncPixelTransferManagerShareGroup::NeedsProcessMorePendingTransfers() {
  return false;
}

void AsyncPixelTransferManagerShareGroup::WaitAllAsyncTexImage2D() {
  if (shared_state_.pending_allocations.empty())
    return;

  AsyncPixelTransferDelegateShareGroup* delegate =
      shared_state_.pending_allocations.back().get();
  if (delegate)
    delegate->WaitForTransferCompletion();
}

AsyncPixelTransferDelegate*
AsyncPixelTransferManagerShareGroup::CreatePixelTransferDelegateImpl(
    gles2::TextureRef* ref,
    const AsyncTexImage2DParams& define_params) {
  return new AsyncPixelTransferDelegateShareGroup(
      &shared_state_, ref->service_id(), define_params);
}

}  // namespace gpu
