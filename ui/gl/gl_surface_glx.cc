// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

extern "C" {
#include <X11/Xlib.h>
}

#include "ui/gl/gl_surface_glx.h"

#include "base/basictypes.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/weak_ptr.h"
#include "base/message_loop/message_loop.h"
#include "base/single_thread_task_runner.h"
#include "base/synchronization/cancellation_flag.h"
#include "base/synchronization/lock.h"
#include "base/thread_task_runner_handle.h"
#include "base/threading/non_thread_safe.h"
#include "base/threading/thread.h"
#include "base/time/time.h"
#include "base/trace_event/trace_event.h"
#include "ui/events/platform/platform_event_source.h"
#include "ui/gfx/x/x11_connection.h"
#include "ui/gfx/x/x11_types.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/sync_control_vsync_provider.h"

namespace gfx {

namespace {

Display* g_display = NULL;
const char* g_glx_extensions = NULL;
bool g_glx_context_create = false;
bool g_glx_create_context_robustness_supported = false;
bool g_glx_texture_from_pixmap_supported = false;
bool g_glx_oml_sync_control_supported = false;

// Track support of glXGetMscRateOML separately from GLX_OML_sync_control as a
// whole since on some platforms (e.g. crosbug.com/34585), glXGetMscRateOML
// always fails even though GLX_OML_sync_control is reported as being supported.
bool g_glx_get_msc_rate_oml_supported = false;

bool g_glx_sgi_video_sync_supported = false;

static const base::TimeDelta kGetVSyncParametersMinPeriod =
#if defined(OS_LINUX)
    // See crbug.com/373489
    // On Linux, querying the vsync parameters might burn CPU for up to an
    // entire vsync, so we only query periodically to reduce CPU usage.
    // 5 seconds is chosen somewhat abitrarily as a balance between:
    //  a) Drift in the phase of our signal.
    //  b) Potential janks from periodically pegging the CPU.
    base::TimeDelta::FromSeconds(5);
#else
    base::TimeDelta::FromSeconds(0);
#endif

class OMLSyncControlVSyncProvider
    : public gfx::SyncControlVSyncProvider {
 public:
  explicit OMLSyncControlVSyncProvider(gfx::AcceleratedWidget window)
      : SyncControlVSyncProvider(),
        window_(window) {
  }

  ~OMLSyncControlVSyncProvider() override {}

 protected:
  bool GetSyncValues(int64* system_time,
                     int64* media_stream_counter,
                     int64* swap_buffer_counter) override {
    return glXGetSyncValuesOML(g_display, window_, system_time,
                               media_stream_counter, swap_buffer_counter);
  }

  bool GetMscRate(int32* numerator, int32* denominator) override {
    if (!g_glx_get_msc_rate_oml_supported)
      return false;

    if (!glXGetMscRateOML(g_display, window_, numerator, denominator)) {
      // Once glXGetMscRateOML has been found to fail, don't try again,
      // since each failing call may spew an error message.
      g_glx_get_msc_rate_oml_supported = false;
      return false;
    }

    return true;
  }

 private:
  XID window_;

  DISALLOW_COPY_AND_ASSIGN(OMLSyncControlVSyncProvider);
};

class SGIVideoSyncThread
     : public base::Thread,
       public base::NonThreadSafe,
       public base::RefCounted<SGIVideoSyncThread> {
 public:
  static scoped_refptr<SGIVideoSyncThread> Create() {
    if (!g_video_sync_thread) {
      g_video_sync_thread = new SGIVideoSyncThread();
      g_video_sync_thread->Start();
    }
    return g_video_sync_thread;
  }

 private:
  friend class base::RefCounted<SGIVideoSyncThread>;

  SGIVideoSyncThread() : base::Thread("SGI_video_sync") {
    DCHECK(CalledOnValidThread());
  }

  ~SGIVideoSyncThread() override {
    DCHECK(CalledOnValidThread());
    g_video_sync_thread = NULL;
    Stop();
  }

  static SGIVideoSyncThread* g_video_sync_thread;

  DISALLOW_COPY_AND_ASSIGN(SGIVideoSyncThread);
};

class SGIVideoSyncProviderThreadShim {
 public:
  explicit SGIVideoSyncProviderThreadShim(XID window)
      : window_(window),
        context_(NULL),
        task_runner_(base::ThreadTaskRunnerHandle::Get()),
        cancel_vsync_flag_(),
        vsync_lock_() {
    // This ensures that creation of |window_| has occured when this shim
    // is executing in the same process as the call to create |window_|.
    XSync(g_display, False);
  }

  virtual ~SGIVideoSyncProviderThreadShim() {
    if (context_) {
      glXDestroyContext(display_, context_);
      context_ = NULL;
    }
  }

  base::CancellationFlag* cancel_vsync_flag() {
    return &cancel_vsync_flag_;
  }

  base::Lock* vsync_lock() {
    return &vsync_lock_;
  }

  void Initialize() {
    DCHECK(display_);

    XWindowAttributes attributes;
    if (!XGetWindowAttributes(display_, window_, &attributes)) {
      LOG(ERROR) << "XGetWindowAttributes failed for window " <<
        window_ << ".";
      return;
    }

    XVisualInfo visual_info_template;
    visual_info_template.visualid = XVisualIDFromVisual(attributes.visual);

    int visual_info_count = 0;
    gfx::XScopedPtr<XVisualInfo> visual_info_list(XGetVisualInfo(
        display_, VisualIDMask, &visual_info_template, &visual_info_count));

    DCHECK(visual_info_list.get());
    if (visual_info_count == 0) {
      LOG(ERROR) << "No visual info for visual ID.";
      return;
    }

    context_ = glXCreateContext(display_, visual_info_list.get(), NULL, True);

    DCHECK(NULL != context_);
  }

  void GetVSyncParameters(const VSyncProvider::UpdateVSyncCallback& callback) {
    base::TimeTicks now;
    {
      // Don't allow |window_| destruction while we're probing vsync.
      base::AutoLock locked(vsync_lock_);

      if (!context_ || cancel_vsync_flag_.IsSet())
        return;

      glXMakeCurrent(display_, window_, context_);

      unsigned int retrace_count = 0;
      if (glXWaitVideoSyncSGI(1, 0, &retrace_count) != 0)
        return;

      TRACE_EVENT_INSTANT0("gpu", "vblank", TRACE_EVENT_SCOPE_THREAD);
      now = base::TimeTicks::Now();

      glXMakeCurrent(display_, 0, 0);
    }

    const base::TimeDelta kDefaultInterval =
        base::TimeDelta::FromSeconds(1) / 60;

    task_runner_->PostTask(
        FROM_HERE, base::Bind(callback, now, kDefaultInterval));
  }

 private:
  // For initialization of display_ in GLSurface::InitializeOneOff before
  // the sandbox goes up.
  friend class gfx::GLSurfaceGLX;

  static Display* display_;

  XID window_;
  GLXContext context_;

  scoped_refptr<base::SingleThreadTaskRunner> task_runner_;

  base::CancellationFlag cancel_vsync_flag_;
  base::Lock vsync_lock_;

  DISALLOW_COPY_AND_ASSIGN(SGIVideoSyncProviderThreadShim);
};

class SGIVideoSyncVSyncProvider
    : public gfx::VSyncProvider,
      public base::SupportsWeakPtr<SGIVideoSyncVSyncProvider> {
 public:
  explicit SGIVideoSyncVSyncProvider(gfx::AcceleratedWidget window)
      : vsync_thread_(SGIVideoSyncThread::Create()),
        shim_(new SGIVideoSyncProviderThreadShim(window)),
        cancel_vsync_flag_(shim_->cancel_vsync_flag()),
        vsync_lock_(shim_->vsync_lock()) {
    vsync_thread_->message_loop()->PostTask(
        FROM_HERE,
        base::Bind(&SGIVideoSyncProviderThreadShim::Initialize,
                   base::Unretained(shim_.get())));
  }

  ~SGIVideoSyncVSyncProvider() override {
    {
      base::AutoLock locked(*vsync_lock_);
      cancel_vsync_flag_->Set();
    }

    // Hand-off |shim_| to be deleted on the |vsync_thread_|.
    vsync_thread_->message_loop()->DeleteSoon(
        FROM_HERE,
        shim_.release());
  }

  void GetVSyncParameters(
      const VSyncProvider::UpdateVSyncCallback& callback) override {
    if (kGetVSyncParametersMinPeriod > base::TimeDelta()) {
      base::TimeTicks now = base::TimeTicks::Now();
      base::TimeDelta delta = now - last_get_vsync_parameters_time_;
      if (delta < kGetVSyncParametersMinPeriod)
        return;
      last_get_vsync_parameters_time_ = now;
    }

    // Only one outstanding request per surface.
    if (!pending_callback_) {
      pending_callback_.reset(
          new VSyncProvider::UpdateVSyncCallback(callback));
      vsync_thread_->message_loop()->PostTask(
          FROM_HERE,
          base::Bind(&SGIVideoSyncProviderThreadShim::GetVSyncParameters,
                     base::Unretained(shim_.get()),
                     base::Bind(
                         &SGIVideoSyncVSyncProvider::PendingCallbackRunner,
                         AsWeakPtr())));
    }
  }

 private:
  void PendingCallbackRunner(const base::TimeTicks timebase,
                             const base::TimeDelta interval) {
    DCHECK(pending_callback_);
    pending_callback_->Run(timebase, interval);
    pending_callback_.reset();
  }

  scoped_refptr<SGIVideoSyncThread> vsync_thread_;

  // Thread shim through which the sync provider is accessed on |vsync_thread_|.
  scoped_ptr<SGIVideoSyncProviderThreadShim> shim_;

  scoped_ptr<VSyncProvider::UpdateVSyncCallback> pending_callback_;

  // Raw pointers to sync primitives owned by the shim_.
  // These will only be referenced before we post a task to destroy
  // the shim_, so they are safe to access.
  base::CancellationFlag* cancel_vsync_flag_;
  base::Lock* vsync_lock_;

  base::TimeTicks last_get_vsync_parameters_time_;

  DISALLOW_COPY_AND_ASSIGN(SGIVideoSyncVSyncProvider);
};

SGIVideoSyncThread* SGIVideoSyncThread::g_video_sync_thread = NULL;

// In order to take advantage of GLX_SGI_video_sync, we need a display
// for use on a separate thread. We must allocate this before the sandbox
// goes up (rather than on-demand when we start the thread).
Display* SGIVideoSyncProviderThreadShim::display_ = NULL;

}  // namespace

GLSurfaceGLX::GLSurfaceGLX(
  const gfx::SurfaceConfiguration& requested_configuration)
    : GLSurface(requested_configuration) {
}

bool GLSurfaceGLX::InitializeOneOff() {
  static bool initialized = false;
  if (initialized)
    return true;

  // http://crbug.com/245466
  setenv("force_s3tc_enable", "true", 1);

  // SGIVideoSyncProviderShim (if instantiated) will issue X commands on
  // it's own thread.
  gfx::InitializeThreadedX11();
  g_display = gfx::GetXDisplay();

  if (!g_display) {
    LOG(ERROR) << "XOpenDisplay failed.";
    return false;
  }

  int major, minor;
  if (!glXQueryVersion(g_display, &major, &minor)) {
    LOG(ERROR) << "glxQueryVersion failed";
    return false;
  }

  if (major == 1 && minor < 3) {
    LOG(ERROR) << "GLX 1.3 or later is required.";
    return false;
  }

  g_glx_extensions = glXQueryExtensionsString(g_display, 0);
  g_glx_context_create =
      HasGLXExtension("GLX_ARB_create_context");
  g_glx_create_context_robustness_supported =
      HasGLXExtension("GLX_ARB_create_context_robustness");
  g_glx_texture_from_pixmap_supported =
      HasGLXExtension("GLX_EXT_texture_from_pixmap");
  g_glx_oml_sync_control_supported =
      HasGLXExtension("GLX_OML_sync_control");
  g_glx_get_msc_rate_oml_supported = g_glx_oml_sync_control_supported;
  g_glx_sgi_video_sync_supported =
      HasGLXExtension("GLX_SGI_video_sync");

  if (!g_glx_get_msc_rate_oml_supported && g_glx_sgi_video_sync_supported)
    SGIVideoSyncProviderThreadShim::display_ = gfx::OpenNewXDisplay();

  initialized = true;
  return true;
}

// static
const char* GLSurfaceGLX::GetGLXExtensions() {
  return g_glx_extensions;
}

// static
bool GLSurfaceGLX::HasGLXExtension(const char* name) {
  return ExtensionsContain(GetGLXExtensions(), name);
}

// static
bool GLSurfaceGLX::IsCreateContextSupported() {
  return g_glx_context_create;
}

// static
bool GLSurfaceGLX::IsCreateContextRobustnessSupported() {
  return g_glx_create_context_robustness_supported;
}

// static
bool GLSurfaceGLX::IsTextureFromPixmapSupported() {
  return g_glx_texture_from_pixmap_supported;
}

// static
bool GLSurfaceGLX::IsOMLSyncControlSupported() {
  return g_glx_oml_sync_control_supported;
}

void* GLSurfaceGLX::GetDisplay() {
  return g_display;
}

GLSurfaceGLX::~GLSurfaceGLX() {}

NativeViewGLSurfaceGLX::NativeViewGLSurfaceGLX(
  gfx::AcceleratedWidget window,
  const gfx::SurfaceConfiguration& requested_configuration)
  : GLSurfaceGLX(requested_configuration),
    parent_window_(window),
    window_(0),
    config_(NULL) {
}

gfx::AcceleratedWidget NativeViewGLSurfaceGLX::GetDrawableHandle() const {
  return window_;
}

bool NativeViewGLSurfaceGLX::Initialize() {
  XWindowAttributes attributes;
  if (!XGetWindowAttributes(g_display, parent_window_, &attributes)) {
    LOG(ERROR) << "XGetWindowAttributes failed for window " << parent_window_
        << ".";
    return false;
  }
  size_ = gfx::Size(attributes.width, attributes.height);
  // Create a child window, with a CopyFromParent visual (to avoid inducing
  // extra blits in the driver), that we can resize exactly in Resize(),
  // correctly ordered with GL, so that we don't have invalid transient states.
  // See https://crbug.com/326995.
  window_ = XCreateWindow(g_display,
                          parent_window_,
                          0,
                          0,
                          size_.width(),
                          size_.height(),
                          0,
                          CopyFromParent,
                          InputOutput,
                          CopyFromParent,
                          0,
                          NULL);
  XMapWindow(g_display, window_);

  ui::PlatformEventSource* event_source =
      ui::PlatformEventSource::GetInstance();
  // Can be NULL in tests, when we don't care about Exposes.
  if (event_source) {
    XSelectInput(g_display, window_, ExposureMask);
    ui::PlatformEventSource::GetInstance()->AddPlatformEventDispatcher(this);
  }
  XFlush(g_display);

  gfx::AcceleratedWidget window_for_vsync = window_;

  if (g_glx_oml_sync_control_supported)
    vsync_provider_.reset(new OMLSyncControlVSyncProvider(window_for_vsync));
  else if (g_glx_sgi_video_sync_supported)
    vsync_provider_.reset(new SGIVideoSyncVSyncProvider(window_for_vsync));

  return true;
}

void NativeViewGLSurfaceGLX::Destroy() {
  if (window_) {
    ui::PlatformEventSource* event_source =
        ui::PlatformEventSource::GetInstance();
    if (event_source)
      event_source->RemovePlatformEventDispatcher(this);
    XDestroyWindow(g_display, window_);
    XFlush(g_display);
  }
}

bool NativeViewGLSurfaceGLX::CanDispatchEvent(const ui::PlatformEvent& event) {
  return event->type == Expose && event->xexpose.window == window_;
}

uint32_t NativeViewGLSurfaceGLX::DispatchEvent(const ui::PlatformEvent& event) {
  XEvent forwarded_event = *event;
  forwarded_event.xexpose.window = parent_window_;
  XSendEvent(g_display, parent_window_, False, ExposureMask,
             &forwarded_event);
  XFlush(g_display);
  return ui::POST_DISPATCH_STOP_PROPAGATION;
}

bool NativeViewGLSurfaceGLX::Resize(const gfx::Size& size) {
  size_ = size;
  glXWaitGL();
  XResizeWindow(g_display, window_, size.width(), size.height());
  glXWaitX();
  return true;
}

bool NativeViewGLSurfaceGLX::IsOffscreen() {
  return false;
}

bool NativeViewGLSurfaceGLX::SwapBuffers() {
  TRACE_EVENT2("gpu", "NativeViewGLSurfaceGLX:RealSwapBuffers",
      "width", GetSize().width(),
      "height", GetSize().height());

  glXSwapBuffers(g_display, GetDrawableHandle());
  return true;
}

gfx::Size NativeViewGLSurfaceGLX::GetSize() {
  return size_;
}

void* NativeViewGLSurfaceGLX::GetHandle() {
  return reinterpret_cast<void*>(GetDrawableHandle());
}

bool NativeViewGLSurfaceGLX::SupportsPostSubBuffer() {
  return gfx::g_driver_glx.ext.b_GLX_MESA_copy_sub_buffer;
}

void* NativeViewGLSurfaceGLX::GetConfig() {
  if (!config_) {
    // This code path is expensive, but we only take it when
    // attempting to use GLX_ARB_create_context_robustness, in which
    // case we need a GLXFBConfig for the window in order to create a
    // context for it.
    //
    // TODO(kbr): this is not a reliable code path. On platforms which
    // support it, we should use glXChooseFBConfig in the browser
    // process to choose the FBConfig and from there the X Visual to
    // use when creating the window in the first place. Then we can
    // pass that FBConfig down rather than attempting to reconstitute
    // it.
    //
    // TODO(iansf): Perhaps instead of kbr's suggestion above, we can
    // now use GLSurface::GetSurfaceConfiguration to use the returned
    // gfx::SurfaceConfiguration with glXChooseFBConfig in a manner
    // similar to that used in NativeViewGLSurfaceEGL::GetConfig.

    XWindowAttributes attributes;
    if (!XGetWindowAttributes(
        g_display,
        window_,
        &attributes)) {
      LOG(ERROR) << "XGetWindowAttributes failed for window " <<
          window_ << ".";
      return NULL;
    }

    int visual_id = XVisualIDFromVisual(attributes.visual);

    int num_elements = 0;
    gfx::XScopedPtr<GLXFBConfig> configs(
        glXGetFBConfigs(g_display, DefaultScreen(g_display), &num_elements));
    if (!configs.get()) {
      LOG(ERROR) << "glXGetFBConfigs failed.";
      return NULL;
    }
    if (!num_elements) {
      LOG(ERROR) << "glXGetFBConfigs returned 0 elements.";
      return NULL;
    }
    bool found = false;
    int i;
    for (i = 0; i < num_elements; ++i) {
      int value;
      if (glXGetFBConfigAttrib(
              g_display, configs.get()[i], GLX_VISUAL_ID, &value)) {
        LOG(ERROR) << "glXGetFBConfigAttrib failed.";
        return NULL;
      }
      if (value == visual_id) {
        found = true;
        break;
      }
    }
    if (found) {
      config_ = configs.get()[i];
    }
  }

  return config_;
}

bool NativeViewGLSurfaceGLX::PostSubBuffer(
    int x, int y, int width, int height) {
  DCHECK(gfx::g_driver_glx.ext.b_GLX_MESA_copy_sub_buffer);
  glXCopySubBufferMESA(g_display, GetDrawableHandle(), x, y, width, height);
  return true;
}

VSyncProvider* NativeViewGLSurfaceGLX::GetVSyncProvider() {
  return vsync_provider_.get();
}

NativeViewGLSurfaceGLX::~NativeViewGLSurfaceGLX() {
  Destroy();
}

PbufferGLSurfaceGLX::PbufferGLSurfaceGLX(
  const gfx::Size& size,
  const gfx::SurfaceConfiguration& requested_configuration)
  : GLSurfaceGLX(requested_configuration),
    size_(size),
    config_(NULL),
    pbuffer_(0) {
  // Some implementations of Pbuffer do not support having a 0 size. For such
  // cases use a (1, 1) surface.
  if (size_.GetArea() == 0)
    size_.SetSize(1, 1);
}

bool PbufferGLSurfaceGLX::Initialize() {
  DCHECK(!pbuffer_);

  static const int config_attributes[] = {
    GLX_BUFFER_SIZE, 32,
    GLX_ALPHA_SIZE, 8,
    GLX_BLUE_SIZE, 8,
    GLX_GREEN_SIZE, 8,
    GLX_RED_SIZE, 8,
    GLX_RENDER_TYPE, GLX_RGBA_BIT,
    GLX_DRAWABLE_TYPE, GLX_PBUFFER_BIT,
    GLX_DOUBLEBUFFER, False,
    0
  };

  int num_elements = 0;
  gfx::XScopedPtr<GLXFBConfig> configs(glXChooseFBConfig(
      g_display, DefaultScreen(g_display), config_attributes, &num_elements));
  if (!configs.get()) {
    LOG(ERROR) << "glXChooseFBConfig failed.";
    return false;
  }
  if (!num_elements) {
    LOG(ERROR) << "glXChooseFBConfig returned 0 elements.";
    return false;
  }

  config_ = configs.get()[0];

  const int pbuffer_attributes[] = {
    GLX_PBUFFER_WIDTH, size_.width(),
    GLX_PBUFFER_HEIGHT, size_.height(),
    0
  };
  pbuffer_ = glXCreatePbuffer(g_display,
                              static_cast<GLXFBConfig>(config_),
                              pbuffer_attributes);
  if (!pbuffer_) {
    Destroy();
    LOG(ERROR) << "glXCreatePbuffer failed.";
    return false;
  }

  return true;
}

void PbufferGLSurfaceGLX::Destroy() {
  if (pbuffer_) {
    glXDestroyPbuffer(g_display, pbuffer_);
    pbuffer_ = 0;
  }

  config_ = NULL;
}

bool PbufferGLSurfaceGLX::IsOffscreen() {
  return true;
}

bool PbufferGLSurfaceGLX::SwapBuffers() {
  NOTREACHED() << "Attempted to call SwapBuffers on a pbuffer.";
  return false;
}

gfx::Size PbufferGLSurfaceGLX::GetSize() {
  return size_;
}

void* PbufferGLSurfaceGLX::GetHandle() {
  return reinterpret_cast<void*>(pbuffer_);
}

void* PbufferGLSurfaceGLX::GetConfig() {
  return config_;
}

PbufferGLSurfaceGLX::~PbufferGLSurfaceGLX() {
  Destroy();
}

}  // namespace gfx
