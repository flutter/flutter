// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/async_pixel_transfer_manager_egl.h"

#include <list>
#include <string>

#include "base/bind.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/synchronization/waitable_event.h"
#include "base/threading/thread.h"
#include "base/trace_event/trace_event.h"
#include "base/trace_event/trace_event_synthetic_delay.h"
#include "gpu/command_buffer/service/async_pixel_transfer_delegate.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_surface_egl.h"
#include "ui/gl/scoped_binders.h"

namespace gpu {

namespace {

bool CheckErrors(const char* file, int line) {
  EGLint eglerror;
  GLenum glerror;
  bool success = true;
  while ((eglerror = eglGetError()) != EGL_SUCCESS) {
     LOG(ERROR) << "Async transfer EGL error at "
                << file << ":" << line << " " << eglerror;
     success = false;
  }
  while ((glerror = glGetError()) != GL_NO_ERROR) {
     LOG(ERROR) << "Async transfer OpenGL error at "
                << file << ":" << line << " " << glerror;
     success = false;
  }
  return success;
}
#define CHECK_GL() CheckErrors(__FILE__, __LINE__)

const char kAsyncTransferThreadName[] = "AsyncTransferThread";

// Regular glTexImage2D call.
void DoTexImage2D(const AsyncTexImage2DParams& tex_params, void* data) {
  glTexImage2D(
      GL_TEXTURE_2D, tex_params.level, tex_params.internal_format,
      tex_params.width, tex_params.height,
      tex_params.border, tex_params.format, tex_params.type, data);
}

// Regular glTexSubImage2D call.
void DoTexSubImage2D(const AsyncTexSubImage2DParams& tex_params, void* data) {
  glTexSubImage2D(
      GL_TEXTURE_2D, tex_params.level,
      tex_params.xoffset, tex_params.yoffset,
      tex_params.width, tex_params.height,
      tex_params.format, tex_params.type, data);
}

// Full glTexSubImage2D call, from glTexImage2D params.
void DoFullTexSubImage2D(const AsyncTexImage2DParams& tex_params, void* data) {
  glTexSubImage2D(
      GL_TEXTURE_2D, tex_params.level,
      0, 0, tex_params.width, tex_params.height,
      tex_params.format, tex_params.type, data);
}

void SetGlParametersForEglImageTexture() {
  // These params are needed for EGLImage creation to succeed on several
  // Android devices. I couldn't find this requirement in the EGLImage
  // extension spec, but several devices fail without it.
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}

void PerformNotifyCompletion(
    AsyncMemoryParams mem_params,
    scoped_refptr<AsyncPixelTransferCompletionObserver> observer) {
  TRACE_EVENT0("gpu", "PerformNotifyCompletion");
  observer->DidComplete(mem_params);
}

class TransferThread : public base::Thread {
 public:
  TransferThread() : base::Thread(kAsyncTransferThreadName) {
    Start();
#if defined(OS_ANDROID) || defined(OS_LINUX)
    SetPriority(base::ThreadPriority::BACKGROUND);
#endif
  }
  ~TransferThread() override { Stop(); }

  void Init() override {
    gfx::GLShareGroup* share_group = NULL;
    surface_ = new gfx::PbufferGLSurfaceEGL(gfx::Size(1, 1),
                                            gfx::SurfaceConfiguration());
    surface_->Initialize();
    context_ = gfx::GLContext::CreateGLContext(
        share_group, surface_.get(), gfx::PreferDiscreteGpu);
    bool is_current = context_->MakeCurrent(surface_.get());
    DCHECK(is_current);
  }

  void CleanUp() override {
    surface_ = NULL;
    context_->ReleaseCurrent(surface_.get());
    context_ = NULL;
  }

 private:
  scoped_refptr<gfx::GLContext> context_;
  scoped_refptr<gfx::GLSurface> surface_;

  DISALLOW_COPY_AND_ASSIGN(TransferThread);
};

base::LazyInstance<TransferThread>
    g_transfer_thread = LAZY_INSTANCE_INITIALIZER;

base::MessageLoopProxy* transfer_message_loop_proxy() {
  return g_transfer_thread.Pointer()->message_loop_proxy().get();
}

// Class which holds async pixel transfers state (EGLImage).
// The EGLImage is accessed by either thread, but everything
// else accessed only on the main thread.
class TransferStateInternal
    : public base::RefCountedThreadSafe<TransferStateInternal> {
 public:
  TransferStateInternal(GLuint texture_id,
                        const AsyncTexImage2DParams& define_params,
                        bool wait_for_uploads,
                        bool wait_for_creation,
                        bool use_image_preserved)
      : texture_id_(texture_id),
        thread_texture_id_(0),
        transfer_completion_(true, true),
        egl_image_(EGL_NO_IMAGE_KHR),
        wait_for_uploads_(wait_for_uploads),
        wait_for_creation_(wait_for_creation),
        use_image_preserved_(use_image_preserved) {
    define_params_ = define_params;
  }

  bool TransferIsInProgress() {
    return !transfer_completion_.IsSignaled();
  }

  void BindTransfer() {
    TRACE_EVENT2("gpu", "BindAsyncTransfer glEGLImageTargetTexture2DOES",
                 "width", define_params_.width,
                 "height", define_params_.height);
    DCHECK(texture_id_);
    if (EGL_NO_IMAGE_KHR == egl_image_)
      return;

    glBindTexture(GL_TEXTURE_2D, texture_id_);
    glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, egl_image_);
    bind_callback_.Run();

    DCHECK(CHECK_GL());
  }

  void CreateEglImage(GLuint texture_id) {
    TRACE_EVENT0("gpu", "eglCreateImageKHR");
    DCHECK(texture_id);
    DCHECK_EQ(egl_image_, EGL_NO_IMAGE_KHR);

    EGLDisplay egl_display = eglGetCurrentDisplay();
    EGLContext egl_context = eglGetCurrentContext();
    EGLenum egl_target = EGL_GL_TEXTURE_2D_KHR;
    EGLClientBuffer egl_buffer =
        reinterpret_cast<EGLClientBuffer>(texture_id);

    EGLint image_preserved = use_image_preserved_ ? EGL_TRUE : EGL_FALSE;
    EGLint egl_attrib_list[] = {
        EGL_GL_TEXTURE_LEVEL_KHR, 0, // mip-level.
        EGL_IMAGE_PRESERVED_KHR, image_preserved,
        EGL_NONE
    };
    egl_image_ = eglCreateImageKHR(
        egl_display,
        egl_context,
        egl_target,
        egl_buffer,
        egl_attrib_list);

    DLOG_IF(ERROR, EGL_NO_IMAGE_KHR == egl_image_)
        << "eglCreateImageKHR failed";
  }

  void CreateEglImageOnUploadThread() {
    CreateEglImage(thread_texture_id_);
  }

  void CreateEglImageOnMainThreadIfNeeded() {
    if (egl_image_ == EGL_NO_IMAGE_KHR) {
      CreateEglImage(texture_id_);
      if (wait_for_creation_) {
        TRACE_EVENT0("gpu", "glFinish creation");
        glFinish();
      }
    }
  }

  void WaitForLastUpload() {
    // This glFinish is just a safe-guard for if uploads have some
    // GPU action that needs to occur. We could use fences and try
    // to do this less often. However, on older drivers fences are
    // not always reliable (eg. Mali-400 just blocks forever).
    if (wait_for_uploads_) {
      TRACE_EVENT0("gpu", "glFinish");
      glFinish();
    }
  }

  void MarkAsTransferIsInProgress() {
    TRACE_EVENT_SYNTHETIC_DELAY_BEGIN("gpu.AsyncTexImage");
    transfer_completion_.Reset();
  }

  void MarkAsCompleted() {
    TRACE_EVENT_SYNTHETIC_DELAY_END("gpu.AsyncTexImage");
    transfer_completion_.Signal();
  }

  void WaitForTransferCompletion() {
    TRACE_EVENT0("gpu", "WaitForTransferCompletion");
    // TODO(backer): Deschedule the channel rather than blocking the main GPU
    // thread (crbug.com/240265).
    transfer_completion_.Wait();
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
    DCHECK(!thread_texture_id_);
    DCHECK_EQ(0, tex_params.level);
    if (EGL_NO_IMAGE_KHR != egl_image_) {
      MarkAsCompleted();
      return;
    }

    void* data = mem_params.GetDataAddress();

    base::TimeTicks begin_time;
    if (texture_upload_stats.get())
      begin_time = base::TimeTicks::Now();

    {
      TRACE_EVENT0("gpu", "glTexImage2D no data");
      glGenTextures(1, &thread_texture_id_);
      glActiveTexture(GL_TEXTURE0);
      glBindTexture(GL_TEXTURE_2D, thread_texture_id_);

      SetGlParametersForEglImageTexture();

      // If we need to use image_preserved, we pass the data with
      // the allocation. Otherwise we use a NULL allocation to
      // try to avoid any costs associated with creating the EGLImage.
      if (use_image_preserved_)
        DoTexImage2D(tex_params, data);
      else
        DoTexImage2D(tex_params, NULL);
    }

    CreateEglImageOnUploadThread();

    {
      TRACE_EVENT0("gpu", "glTexSubImage2D with data");

      // If we didn't use image_preserved, we haven't uploaded
      // the data yet, so we do this with a full texSubImage.
      if (!use_image_preserved_)
        DoFullTexSubImage2D(tex_params, data);
    }

    WaitForLastUpload();
    MarkAsCompleted();

    DCHECK(CHECK_GL());
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

    DCHECK_NE(EGL_NO_IMAGE_KHR, egl_image_);
    DCHECK_EQ(0, tex_params.level);

    void* data = mem_params.GetDataAddress();

    base::TimeTicks begin_time;
    if (texture_upload_stats.get())
      begin_time = base::TimeTicks::Now();

    if (!thread_texture_id_) {
      TRACE_EVENT0("gpu", "glEGLImageTargetTexture2DOES");
      glGenTextures(1, &thread_texture_id_);
      glActiveTexture(GL_TEXTURE0);
      glBindTexture(GL_TEXTURE_2D, thread_texture_id_);
      glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, egl_image_);
    } else {
      glActiveTexture(GL_TEXTURE0);
      glBindTexture(GL_TEXTURE_2D, thread_texture_id_);
    }
    {
      TRACE_EVENT0("gpu", "glTexSubImage2D");
      DoTexSubImage2D(tex_params, data);
    }
    WaitForLastUpload();
    MarkAsCompleted();

    DCHECK(CHECK_GL());
    if (texture_upload_stats.get()) {
      texture_upload_stats->AddUpload(base::TimeTicks::Now() - begin_time);
    }
  }

 protected:
  friend class base::RefCountedThreadSafe<TransferStateInternal>;
  friend class gpu::AsyncPixelTransferDelegateEGL;

  static void DeleteTexture(GLuint id) {
    glDeleteTextures(1, &id);
  }

  virtual ~TransferStateInternal() {
    if (egl_image_ != EGL_NO_IMAGE_KHR) {
      EGLDisplay display = eglGetCurrentDisplay();
      eglDestroyImageKHR(display, egl_image_);
    }
    if (thread_texture_id_) {
      transfer_message_loop_proxy()->PostTask(FROM_HERE,
          base::Bind(&DeleteTexture, thread_texture_id_));
    }
  }

  // The 'real' texture.
  GLuint texture_id_;

  // The EGLImage sibling on the upload thread.
  GLuint thread_texture_id_;

  // Definition params for texture that needs binding.
  AsyncTexImage2DParams define_params_;

  // Indicates that an async transfer is in progress.
  base::WaitableEvent transfer_completion_;

  // It would be nice if we could just create a new EGLImage for
  // every upload, but I found that didn't work, so this stores
  // one for the lifetime of the texture.
  EGLImageKHR egl_image_;

  // Callback to invoke when AsyncTexImage2D is complete
  // and the client can safely use the texture. This occurs
  // during BindCompletedAsyncTransfers().
  base::Closure bind_callback_;

  // Customize when we block on fences (these are work-arounds).
  bool wait_for_uploads_;
  bool wait_for_creation_;
  bool use_image_preserved_;
};

}  // namespace

// Class which handles async pixel transfers using EGLImageKHR and another
// upload thread
class AsyncPixelTransferDelegateEGL
    : public AsyncPixelTransferDelegate,
      public base::SupportsWeakPtr<AsyncPixelTransferDelegateEGL> {
 public:
  AsyncPixelTransferDelegateEGL(
      AsyncPixelTransferManagerEGL::SharedState* shared_state,
      GLuint texture_id,
      const AsyncTexImage2DParams& define_params);
  ~AsyncPixelTransferDelegateEGL() override;

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
  // Returns true if a work-around was used.
  bool WorkAroundAsyncTexImage2D(
      const AsyncTexImage2DParams& tex_params,
      const AsyncMemoryParams& mem_params,
      const base::Closure& bind_callback);
  bool WorkAroundAsyncTexSubImage2D(
      const AsyncTexSubImage2DParams& tex_params,
      const AsyncMemoryParams& mem_params);

  // A raw pointer is safe because the SharedState is owned by the Manager,
  // which owns this Delegate.
  AsyncPixelTransferManagerEGL::SharedState* shared_state_;
  scoped_refptr<TransferStateInternal> state_;

  DISALLOW_COPY_AND_ASSIGN(AsyncPixelTransferDelegateEGL);
};

AsyncPixelTransferDelegateEGL::AsyncPixelTransferDelegateEGL(
    AsyncPixelTransferManagerEGL::SharedState* shared_state,
    GLuint texture_id,
    const AsyncTexImage2DParams& define_params)
    : shared_state_(shared_state) {
  // We can't wait on uploads on imagination (it can take 200ms+).
  // In practice, they are complete when the CPU glTexSubImage2D completes.
  bool wait_for_uploads = !shared_state_->is_imagination;

  // Qualcomm runs into texture corruption problems if the same texture is
  // uploaded to with both async and normal uploads. Synchronize after EGLImage
  // creation on the main thread as a work-around.
  bool wait_for_creation = shared_state_->is_qualcomm;

  // Qualcomm has a race when using image_preserved=FALSE,
  // which can result in black textures even after the first upload.
  // Since using FALSE is mainly for performance (to avoid layout changes),
  // but Qualcomm itself doesn't seem to get any performance benefit,
  // we just using image_preservedd=TRUE on Qualcomm as a work-around.
  bool use_image_preserved =
      shared_state_->is_qualcomm || shared_state_->is_imagination;

  state_ = new TransferStateInternal(texture_id,
                                   define_params,
                                   wait_for_uploads,
                                   wait_for_creation,
                                   use_image_preserved);
}

AsyncPixelTransferDelegateEGL::~AsyncPixelTransferDelegateEGL() {}

bool AsyncPixelTransferDelegateEGL::TransferIsInProgress() {
  return state_->TransferIsInProgress();
}

void AsyncPixelTransferDelegateEGL::WaitForTransferCompletion() {
  if (state_->TransferIsInProgress()) {
#if defined(OS_ANDROID) || defined(OS_LINUX)
    g_transfer_thread.Pointer()->SetPriority(base::ThreadPriority::BACKGROUND);
#endif

    state_->WaitForTransferCompletion();
    DCHECK(!state_->TransferIsInProgress());

#if defined(OS_ANDROID) || defined(OS_LINUX)
    g_transfer_thread.Pointer()->SetPriority(base::ThreadPriority::BACKGROUND);
#endif
  }
}

void AsyncPixelTransferDelegateEGL::AsyncTexImage2D(
    const AsyncTexImage2DParams& tex_params,
    const AsyncMemoryParams& mem_params,
    const base::Closure& bind_callback) {
  if (WorkAroundAsyncTexImage2D(tex_params, mem_params, bind_callback))
    return;

  DCHECK(!state_->TransferIsInProgress());
  DCHECK_EQ(state_->egl_image_, EGL_NO_IMAGE_KHR);
  DCHECK_EQ(static_cast<GLenum>(GL_TEXTURE_2D), tex_params.target);
  DCHECK_EQ(tex_params.level, 0);

  // Mark the transfer in progress and save the late bind
  // callback, so we can notify the client when it is bound.
  shared_state_->pending_allocations.push_back(AsWeakPtr());
  state_->bind_callback_ = bind_callback;

  // Mark the transfer in progress.
  state_->MarkAsTransferIsInProgress();

  // Duplicate the shared memory so there is no way we can get
  // a use-after-free of the raw pixels.
  transfer_message_loop_proxy()->PostTask(FROM_HERE,
      base::Bind(
          &TransferStateInternal::PerformAsyncTexImage2D,
          state_,
          tex_params,
          mem_params,
          shared_state_->texture_upload_stats));

  DCHECK(CHECK_GL());
}

void AsyncPixelTransferDelegateEGL::AsyncTexSubImage2D(
    const AsyncTexSubImage2DParams& tex_params,
    const AsyncMemoryParams& mem_params) {
  TRACE_EVENT2("gpu", "AsyncTexSubImage2D",
               "width", tex_params.width,
               "height", tex_params.height);
  if (WorkAroundAsyncTexSubImage2D(tex_params, mem_params))
    return;
  DCHECK(!state_->TransferIsInProgress());
  DCHECK_EQ(static_cast<GLenum>(GL_TEXTURE_2D), tex_params.target);
  DCHECK_EQ(tex_params.level, 0);

  // Mark the transfer in progress.
  state_->MarkAsTransferIsInProgress();

  // If this wasn't async allocated, we don't have an EGLImage yet.
  // Create the EGLImage if it hasn't already been created.
  state_->CreateEglImageOnMainThreadIfNeeded();

  // Duplicate the shared memory so there are no way we can get
  // a use-after-free of the raw pixels.
  transfer_message_loop_proxy()->PostTask(FROM_HERE,
      base::Bind(
          &TransferStateInternal::PerformAsyncTexSubImage2D,
          state_,
          tex_params,
          mem_params,
          shared_state_->texture_upload_stats));

  DCHECK(CHECK_GL());
}

namespace {
bool IsPowerOfTwo (unsigned int x) {
  return ((x != 0) && !(x & (x - 1)));
}

bool IsMultipleOfEight(unsigned int x) {
  return (x & 7) == 0;
}

bool DimensionsSupportImgFastPath(int width, int height) {
  // Multiple of eight, but not a power of two.
  return IsMultipleOfEight(width) &&
         IsMultipleOfEight(height) &&
         !(IsPowerOfTwo(width) &&
           IsPowerOfTwo(height));
}
}  // namespace

// It is very difficult to stream uploads on Imagination GPUs:
// - glTexImage2D defers a swizzle/stall until draw-time
// - glTexSubImage2D will sleep for 16ms on a good day, and 100ms
//   or longer if OpenGL is in heavy use by another thread.
// The one combination that avoids these problems requires:
// a.) Allocations/Uploads must occur on different threads/contexts.
// b.) Texture size must be non-power-of-two.
// When using a+b, uploads will be incorrect/corrupt unless:
// c.) Texture size must be a multiple-of-eight.
//
// To achieve a.) we allocate synchronously on the main thread followed
// by uploading on the upload thread. When b/c are not true we fall back
// on purely synchronous allocation/upload on the main thread.

bool AsyncPixelTransferDelegateEGL::WorkAroundAsyncTexImage2D(
    const AsyncTexImage2DParams& tex_params,
    const AsyncMemoryParams& mem_params,
    const base::Closure& bind_callback) {
  if (!shared_state_->is_imagination)
    return false;

  // On imagination we allocate synchronously all the time, even
  // if the dimensions support fast uploads. This is for part a.)
  // above, so allocations occur on a different thread/context as uploads.
  void* data = mem_params.GetDataAddress();
  SetGlParametersForEglImageTexture();

  {
    TRACE_EVENT0("gpu", "glTexImage2D with data");
    DoTexImage2D(tex_params, data);
  }

  // The allocation has already occured, so mark it as finished
  // and ready for binding.
  CHECK(!state_->TransferIsInProgress());

  // If the dimensions support fast async uploads, create the
  // EGLImage for future uploads. The late bind should not
  // be needed since the EGLImage was created from the main thread
  // texture, but this is required to prevent an imagination driver crash.
  if (DimensionsSupportImgFastPath(tex_params.width, tex_params.height)) {
    state_->CreateEglImageOnMainThreadIfNeeded();
    shared_state_->pending_allocations.push_back(AsWeakPtr());
    state_->bind_callback_ = bind_callback;
  }

  DCHECK(CHECK_GL());
  return true;
}

bool AsyncPixelTransferDelegateEGL::WorkAroundAsyncTexSubImage2D(
    const AsyncTexSubImage2DParams& tex_params,
    const AsyncMemoryParams& mem_params) {
  if (!shared_state_->is_imagination)
    return false;

  // If the dimensions support fast async uploads, we can use the
  // normal async upload path for uploads.
  if (DimensionsSupportImgFastPath(tex_params.width, tex_params.height))
    return false;

  // Fall back on a synchronous stub as we don't have a known fast path.
  // Also, older ICS drivers crash when we do any glTexSubImage2D on the
  // same thread. To work around this we do glTexImage2D instead. Since
  // we didn't create an EGLImage for this texture (see above), this is
  // okay, but it limits this API to full updates for now.
  DCHECK(!state_->egl_image_);
  DCHECK_EQ(tex_params.xoffset, 0);
  DCHECK_EQ(tex_params.yoffset, 0);
  DCHECK_EQ(state_->define_params_.width, tex_params.width);
  DCHECK_EQ(state_->define_params_.height, tex_params.height);
  DCHECK_EQ(state_->define_params_.level, tex_params.level);
  DCHECK_EQ(state_->define_params_.format, tex_params.format);
  DCHECK_EQ(state_->define_params_.type, tex_params.type);

  void* data = mem_params.GetDataAddress();
  base::TimeTicks begin_time;
  if (shared_state_->texture_upload_stats.get())
    begin_time = base::TimeTicks::Now();
  {
    TRACE_EVENT0("gpu", "glTexSubImage2D");
    // Note we use define_params_ instead of tex_params.
    // The DCHECKs above verify this is always the same.
    DoTexImage2D(state_->define_params_, data);
  }
  if (shared_state_->texture_upload_stats.get()) {
    shared_state_->texture_upload_stats
        ->AddUpload(base::TimeTicks::Now() - begin_time);
  }

  DCHECK(CHECK_GL());
  return true;
}

AsyncPixelTransferManagerEGL::SharedState::SharedState()
    // TODO(reveman): Skip this if --enable-gpu-benchmarking is not present.
    : texture_upload_stats(new AsyncPixelTransferUploadStats) {
  const char* vendor = reinterpret_cast<const char*>(glGetString(GL_VENDOR));
  if (vendor) {
    is_imagination =
        std::string(vendor).find("Imagination") != std::string::npos;
    is_qualcomm = std::string(vendor).find("Qualcomm") != std::string::npos;
  }
}

AsyncPixelTransferManagerEGL::SharedState::~SharedState() {}

AsyncPixelTransferManagerEGL::AsyncPixelTransferManagerEGL() {}

AsyncPixelTransferManagerEGL::~AsyncPixelTransferManagerEGL() {}

void AsyncPixelTransferManagerEGL::BindCompletedAsyncTransfers() {
  scoped_ptr<gfx::ScopedTextureBinder> texture_binder;

  while(!shared_state_.pending_allocations.empty()) {
    if (!shared_state_.pending_allocations.front().get()) {
      shared_state_.pending_allocations.pop_front();
      continue;
    }
    AsyncPixelTransferDelegateEGL* delegate =
        shared_state_.pending_allocations.front().get();
    // Terminate early, as all transfers finish in order, currently.
    if (delegate->TransferIsInProgress())
      break;

    if (!texture_binder)
      texture_binder.reset(new gfx::ScopedTextureBinder(GL_TEXTURE_2D, 0));

    // If the transfer is finished, bind it to the texture
    // and remove it from pending list.
    delegate->BindTransfer();
    shared_state_.pending_allocations.pop_front();
  }
}

void AsyncPixelTransferManagerEGL::AsyncNotifyCompletion(
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

uint32 AsyncPixelTransferManagerEGL::GetTextureUploadCount() {
  return shared_state_.texture_upload_stats->GetStats(NULL);
}

base::TimeDelta AsyncPixelTransferManagerEGL::GetTotalTextureUploadTime() {
  base::TimeDelta total_texture_upload_time;
  shared_state_.texture_upload_stats->GetStats(&total_texture_upload_time);
  return total_texture_upload_time;
}

void AsyncPixelTransferManagerEGL::ProcessMorePendingTransfers() {
}

bool AsyncPixelTransferManagerEGL::NeedsProcessMorePendingTransfers() {
  return false;
}

void AsyncPixelTransferManagerEGL::WaitAllAsyncTexImage2D() {
  if (shared_state_.pending_allocations.empty())
    return;

  AsyncPixelTransferDelegateEGL* delegate =
      shared_state_.pending_allocations.back().get();
  if (delegate)
    delegate->WaitForTransferCompletion();
}

AsyncPixelTransferDelegate*
AsyncPixelTransferManagerEGL::CreatePixelTransferDelegateImpl(
    gles2::TextureRef* ref,
    const AsyncTexImage2DParams& define_params) {
  return new AsyncPixelTransferDelegateEGL(
      &shared_state_, ref->service_id(), define_params);
}

}  // namespace gpu
