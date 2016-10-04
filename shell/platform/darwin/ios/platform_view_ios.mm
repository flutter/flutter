// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/platform_view_ios.h"

#include "base/mac/scoped_nsautorelease_pool.h"
#include "base/trace_event/trace_event.h"
#include "flutter/shell/platform/darwin/common/view_service_provider.h"
#include "flutter/shell/platform/darwin/common/platform_service_provider.h"
#include "flutter/sky/engine/wtf/MakeUnique.h"
#include "lib/ftl/synchronization/waitable_event.h"
#include "mojo/public/cpp/application/connect.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/EAGL.h>
#import <QuartzCore/CAEAGLLayer.h>

namespace shell {

struct GLintSize {
  GLint width;
  GLint height;

  GLintSize() : width(0), height(0) {}

  GLintSize(GLint w, GLint h) : width(w), height(h) {}

  GLintSize(CGSize size)
      : width(static_cast<GLint>(size.width)),
        height(static_cast<GLint>(size.height)) {}

  bool operator==(const GLintSize& other) const {
    return width == other.width && height == other.height;
  }
};

class IOSGLContext {
 public:
  IOSGLContext(PlatformView::SurfaceConfig config, CAEAGLLayer* layer)
      : layer_([layer retain]),
        context_([[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]),
        resource_context_([[EAGLContext alloc]
            initWithAPI:kEAGLRenderingAPIOpenGLES2
             sharegroup:context_.get().sharegroup]),
        framebuffer_(GL_NONE),
        colorbuffer_(GL_NONE),
        depthbuffer_(GL_NONE),
        stencilbuffer_(GL_NONE),
        depth_stencil_packed_buffer_(GL_NONE) {
    base::mac::ScopedNSAutoreleasePool pool;

    CHECK(layer_ != nullptr);
    CHECK(context_ != nullptr);
    CHECK(resource_context_ != nullptr);

    bool context_current = [EAGLContext setCurrentContext:context_];

    DCHECK(context_current);
    DCHECK(glGetError() == GL_NO_ERROR);

    // Generate the framebuffer

    glGenFramebuffers(1, &framebuffer_);
    DCHECK(glGetError() == GL_NO_ERROR);
    DCHECK(framebuffer_ != GL_NONE);

    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer_);
    DCHECK(glGetError() == GL_NO_ERROR);

    // Setup color attachment

    glGenRenderbuffers(1, &colorbuffer_);
    DCHECK(colorbuffer_ != GL_NONE);

    glBindRenderbuffer(GL_RENDERBUFFER, colorbuffer_);
    DCHECK(glGetError() == GL_NO_ERROR);

    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, colorbuffer_);
    DCHECK(glGetError() == GL_NO_ERROR);

    // On iOS, if both depth and stencil attachments are requested, we are
    // required to create a single renderbuffer that acts as both.

    auto requires_packed =
        (config.depth_bits != 0) && (config.stencil_bits != 0);

    if (requires_packed) {
      glGenRenderbuffers(1, &depth_stencil_packed_buffer_);
      glBindRenderbuffer(GL_RENDERBUFFER, depth_stencil_packed_buffer_);
      DCHECK(depth_stencil_packed_buffer_ != GL_NONE);

      glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                                GL_RENDERBUFFER, depth_stencil_packed_buffer_);
      glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT,
                                GL_RENDERBUFFER, depth_stencil_packed_buffer_);
      DCHECK(depth_stencil_packed_buffer_ != GL_NONE);
    } else {
      // Setup the depth attachment if necessary
      if (config.depth_bits != 0) {
        glGenRenderbuffers(1, &depthbuffer_);
        DCHECK(depthbuffer_ != GL_NONE);

        glBindRenderbuffer(GL_RENDERBUFFER, depthbuffer_);
        DCHECK(glGetError() == GL_NO_ERROR);

        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                                  GL_RENDERBUFFER, depthbuffer_);
        DCHECK(glGetError() == GL_NO_ERROR);
      }

      // Setup the stencil attachment if necessary
      if (config.stencil_bits != 0) {
        glGenRenderbuffers(1, &stencilbuffer_);
        DCHECK(stencilbuffer_ != GL_NONE);

        glBindRenderbuffer(GL_RENDERBUFFER, stencilbuffer_);
        DCHECK(glGetError() == GL_NO_ERROR);

        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT,
                                  GL_RENDERBUFFER, stencilbuffer_);
        DCHECK(glGetError() == GL_NO_ERROR);
      }
    }

    // The default is RGBA
    NSString* drawableColorFormat = kEAGLColorFormatRGBA8;

    if (config.red_bits <= 5 && config.green_bits <= 6 &&
        config.blue_bits <= 5 && config.alpha_bits == 0) {
      drawableColorFormat = kEAGLColorFormatRGB565;
    }

    layer_.get().drawableProperties = @{
      kEAGLDrawablePropertyColorFormat : drawableColorFormat,
      kEAGLDrawablePropertyRetainedBacking : @(NO),
    };
  }

  ~IOSGLContext() {
    DCHECK(glGetError() == GL_NO_ERROR);

    // Deletes on GL_NONEs are ignored
    glDeleteFramebuffers(1, &framebuffer_);

    glDeleteRenderbuffers(1, &colorbuffer_);
    glDeleteRenderbuffers(1, &depthbuffer_);
    glDeleteRenderbuffers(1, &stencilbuffer_);
    glDeleteRenderbuffers(1, &depth_stencil_packed_buffer_);

    DCHECK(glGetError() == GL_NO_ERROR);
  }

  bool PresentRenderBuffer() const {
    base::mac::ScopedNSAutoreleasePool pool;

    const GLenum discards[] = {
        GL_DEPTH_ATTACHMENT, GL_STENCIL_ATTACHMENT,
    };

    glDiscardFramebufferEXT(GL_FRAMEBUFFER, sizeof(discards) / sizeof(GLenum),
                            discards);

    glBindRenderbuffer(GL_RENDERBUFFER, colorbuffer_);
    return [[EAGLContext currentContext] presentRenderbuffer:GL_RENDERBUFFER];
  }

  GLuint framebuffer() const { return framebuffer_; }

  bool MakeCurrent() {
    base::mac::ScopedNSAutoreleasePool pool;

    return UpdateStorageSizeIfNecessary() &&
           [EAGLContext setCurrentContext:context_.get()];
  }

  bool ResourceMakeCurrent() {
    base::mac::ScopedNSAutoreleasePool pool;

    return [EAGLContext setCurrentContext:resource_context_.get()];
  }

 private:
  base::scoped_nsobject<CAEAGLLayer> layer_;
  base::scoped_nsobject<EAGLContext> context_;
  base::scoped_nsobject<EAGLContext> resource_context_;

  GLuint framebuffer_;
  GLuint colorbuffer_;
  GLuint depthbuffer_;
  GLuint stencilbuffer_;
  GLuint depth_stencil_packed_buffer_;

  GLintSize storage_size_;

  bool UpdateStorageSizeIfNecessary() {
    GLintSize size([layer_.get() bounds].size);

    if (size == storage_size_) {
      // Nothing to since the stoage size is already consistent with the layer.
      return true;
    }

    if (![EAGLContext setCurrentContext:context_]) {
      return false;
    }

    DCHECK(glGetError() == GL_NO_ERROR);

    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer_);

    glBindRenderbuffer(GL_RENDERBUFFER, colorbuffer_);
    DCHECK(glGetError() == GL_NO_ERROR);

    if (![context_.get() renderbufferStorage:GL_RENDERBUFFER
                                fromDrawable:layer_.get()]) {
      return false;
    }

    GLint width = 0;
    GLint height = 0;
    bool rebind_color_buffer = false;

    if (depthbuffer_ != GL_NONE || stencilbuffer_ != GL_NONE ||
        depth_stencil_packed_buffer_ != GL_NONE) {
      // Fetch the dimensions of the color buffer whose backing was just updated
      // so that backing of the attachments can be updated
      glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH,
                                   &width);
      DCHECK(glGetError() == GL_NO_ERROR);

      glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT,
                                   &height);
      DCHECK(glGetError() == GL_NO_ERROR);

      rebind_color_buffer = true;
    }

    if (depth_stencil_packed_buffer_ != GL_NONE) {
      glBindRenderbuffer(GL_RENDERBUFFER, depth_stencil_packed_buffer_);
      glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8_OES, width,
                            height);
      DCHECK(glGetError() == GL_NO_ERROR);
    }

    if (depthbuffer_ != GL_NONE) {
      glBindRenderbuffer(GL_RENDERBUFFER, depthbuffer_);
      glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width,
                            height);
      DCHECK(glGetError() == GL_NO_ERROR);
    }

    if (stencilbuffer_ != GL_NONE) {
      glBindRenderbuffer(GL_RENDERBUFFER, stencilbuffer_);
      glRenderbufferStorage(GL_RENDERBUFFER, GL_STENCIL_INDEX8, width, height);
      DCHECK(glGetError() == GL_NO_ERROR);
    }

    if (rebind_color_buffer) {
      glBindRenderbuffer(GL_RENDERBUFFER, colorbuffer_);
      DCHECK(glGetError() == GL_NO_ERROR);
    }

    storage_size_ = GLintSize(width, height);
    DCHECK(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);

    return true;
  }

  FTL_DISALLOW_COPY_AND_ASSIGN(IOSGLContext);
};

PlatformViewIOS::PlatformViewIOS(CAEAGLLayer* layer)
    : context_(WTF::MakeUnique<IOSGLContext>(surface_config_, layer)),
      weak_factory_(this) {
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  shell::Shell::Shared().tracing_controller().set_traces_base_path(
      [paths.firstObject UTF8String]);
}

PlatformViewIOS::~PlatformViewIOS() = default;

sky::SkyEnginePtr& PlatformViewIOS::engineProxy() {
  return engine_;
}

flutter::platform::ApplicationMessagesPtr& PlatformViewIOS::AppMessageSender() {
  return app_message_sender_;
}

shell::ApplicationMessagesImpl& PlatformViewIOS::AppMessageReceiver() {
  return app_message_receiver_;
}

void PlatformViewIOS::ToggleAccessibility(UIView* view, bool enable) {
  if (enable) {
    if (!accessibility_bridge_ && dart_services_.get() != nullptr) {
      accessibility_bridge_.reset(
          new shell::AccessibilityBridge(view, dart_services_.get()));
    }
  } else {
    accessibility_bridge_ = nullptr;
  }
}

void PlatformViewIOS::ConnectToEngineAndSetupServices() {
  ConnectToEngine(mojo::GetProxy(&engine_));

  mojo::ServiceProviderPtr service_provider;

  auto service_provider_proxy = mojo::GetProxy(&service_provider);

  new PlatformServiceProvider(service_provider_proxy.Pass());

  ftl::WeakPtr<ApplicationMessagesImpl> appplication_messages_impl =
      app_message_receiver_.GetWeakPtr();

  mojo::ServiceProviderPtr viewServiceProvider;

  new ViewServiceProvider(
      [appplication_messages_impl](
          mojo::InterfaceRequest<flutter::platform::ApplicationMessages>
              request) {
        if (appplication_messages_impl)
          appplication_messages_impl->AddBinding(std::move(request));
      },
      mojo::GetProxy(&viewServiceProvider));

  sky::ServicesDataPtr services = sky::ServicesData::New();
  services->incoming_services = service_provider.Pass();
  services->outgoing_services = mojo::GetProxy(&dart_services_);
  services->view_services = viewServiceProvider.Pass();
  engine_->SetServices(services.Pass());

  mojo::ConnectToService(dart_services_.get(),
                         mojo::GetProxy(&app_message_sender_));
}

void PlatformViewIOS::SetupAndLoadFromSource(
    const std::string& main,
    const std::string& packages,
    const std::string& assets_directory) {
  ConnectToEngineAndSetupServices();
  engine_->RunFromFile(main, packages, assets_directory);
}

ftl::WeakPtr<PlatformView> PlatformViewIOS::GetWeakViewPtr() {
  return weak_factory_.GetWeakPtr();
}

uint64_t PlatformViewIOS::DefaultFramebuffer() const {
  return context_ != nullptr ? context_->framebuffer() : GL_NONE;
}

bool PlatformViewIOS::ContextMakeCurrent() {
  return context_ != nullptr ? context_->MakeCurrent() : false;
}

bool PlatformViewIOS::ResourceContextMakeCurrent() {
  return context_ != nullptr ? context_->ResourceMakeCurrent() : false;
}

bool PlatformViewIOS::SwapBuffers() {
  TRACE_EVENT0("flutter", "PlatformViewIOS::SwapBuffers");
  return context_ != nullptr ? context_->PresentRenderBuffer() : false;
}

void PlatformViewIOS::RunFromSource(const std::string& main,
                                    const std::string& packages,
                                    const std::string& assets_directory) {
  auto latch = new ftl::ManualResetWaitableEvent();

  dispatch_async(dispatch_get_main_queue(), ^{
    SetupAndLoadFromSource(main, packages, assets_directory);
    latch->Signal();
  });

  latch->Wait();
  delete latch;
}

}  // namespace shell
