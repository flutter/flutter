// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/playground/backend/gles/playground_impl_gles.h"

#define IMPELLER_PLAYGROUND_SUPPORTS_ANGLE FML_OS_MACOSX

#if IMPELLER_PLAYGROUND_SUPPORTS_ANGLE
#include <dlfcn.h>
#endif

#define GLFW_INCLUDE_NONE
#include "third_party/glfw/include/GLFW/glfw3.h"

#include "flutter/fml/build_config.h"
#include "impeller/entity/gles/entity_shaders_gles.h"
#include "impeller/entity/gles/framebuffer_blend_shaders_gles.h"
#include "impeller/entity/gles/modern_shaders_gles.h"
#include "impeller/entity/gles3/entity_shaders_gles.h"
#include "impeller/entity/gles3/framebuffer_blend_shaders_gles.h"
#include "impeller/entity/gles3/modern_shaders_gles.h"
#include "impeller/fixtures/gles/fixtures_shaders_gles.h"
#include "impeller/fixtures/gles/modern_fixtures_shaders_gles.h"
#include "impeller/fixtures/gles3/fixtures_shaders_gles.h"
#include "impeller/fixtures/gles3/modern_fixtures_shaders_gles.h"
#include "impeller/playground/imgui/gles/imgui_shaders_gles.h"
#include "impeller/playground/imgui/gles3/imgui_shaders_gles.h"
#include "impeller/renderer/backend/gles/context_gles.h"
#include "impeller/renderer/backend/gles/surface_gles.h"

namespace impeller {

class PlaygroundImplGLES::ReactorWorker final : public ReactorGLES::Worker {
 public:
  ReactorWorker() = default;

  // |ReactorGLES::Worker|
  bool CanReactorReactOnCurrentThreadNow(
      const ReactorGLES& reactor) const override {
    ReaderLock lock(mutex_);
    auto found = reactions_allowed_.find(std::this_thread::get_id());
    if (found == reactions_allowed_.end()) {
      return false;
    }
    return found->second;
  }

  void SetReactionsAllowedOnCurrentThread(bool allowed) {
    WriterLock lock(mutex_);
    reactions_allowed_[std::this_thread::get_id()] = allowed;
  }

 private:
  mutable RWMutex mutex_;
  std::map<std::thread::id, bool> reactions_allowed_ IPLR_GUARDED_BY(mutex_);

  ReactorWorker(const ReactorWorker&) = delete;

  ReactorWorker& operator=(const ReactorWorker&) = delete;
};

struct PlaygroundImplGLES::ShareableContext final {
 public:
  ShareableContext(UniqueHandle window,
                   std::shared_ptr<ReactorWorker> worker,
                   std::shared_ptr<ContextGLES> context)
      : window(std::move(window)),
        worker(std::move(worker)),
        context(std::move(context)) {}

  ~ShareableContext() {
    if (window) {
      ::glfwMakeContextCurrent(window.get());
    }
    context.reset();
    worker.reset();
    window.reset();
  }

  // This is a placeholder/dummy window. It is not rendered to by playground
  // tests. Instead, it is created so different playground tests can create
  // windows that share the same context.
  // See https://www.glfw.org/docs/latest/context_guide.html#context_sharing for
  // details.
  UniqueHandle window = {nullptr, &DestroyWindowHandle};

  std::shared_ptr<ReactorWorker> worker;
  std::shared_ptr<ContextGLES> context;
};

void PlaygroundImplGLES::DestroyWindowHandle(WindowHandle handle) {
  if (!handle) {
    return;
  }
  ::glfwDestroyWindow(reinterpret_cast<GLFWwindow*>(handle));
}

static std::vector<std::shared_ptr<fml::Mapping>>
ShaderLibraryMappingsForPlayground(bool is_gles3);

PlaygroundImplGLES::PlaygroundImplGLES(
    PlaygroundSwitches switches,
    std::shared_ptr<ShareableContext>& shared_context)
    : PlaygroundImpl(switches),
      handle_(nullptr, &DestroyWindowHandle),
      use_angle_(switches.use_angle) {
  if (use_angle_) {
#if IMPELLER_PLAYGROUND_SUPPORTS_ANGLE
    angle_glesv2_ = dlopen("libGLESv2.dylib", RTLD_LAZY);
#endif
    FML_CHECK(angle_glesv2_ != nullptr);
  }

  if (!shared_context) {
    shared_context = MakeShareableContext(switches_);
    if (!shared_context) {
      FML_LOG(ERROR) << "Could not create GLES context.";
      return;
    }
  }

  context_ = shared_context->context;

  auto window = CreateGLWindow(switches_, shared_context->window.get());
  handle_.reset(window);

  shared_context->context->GetGPUTracer()->Reset();
}

GLFWwindow* PlaygroundImplGLES::CreateGLWindow(
    const PlaygroundSwitches& switches,
    GLFWwindow* share_window) {
  ::glfwDefaultWindowHints();

#if FML_OS_MACOSX
  FML_CHECK(switches.use_angle) << "Must use Angle on macOS for OpenGL ES.";
  ::glfwWindowHint(GLFW_CONTEXT_CREATION_API, GLFW_EGL_CONTEXT_API);
#endif  // FML_OS_MACOSX
#if FML_OS_LINUX
  // Use EGL even on X11 then the client can select the GLES implementation
  // by defining __EGL_VENDOR_LIBRARY_FILENAMES
  ::glfwWindowHint(GLFW_CONTEXT_CREATION_API, GLFW_EGL_CONTEXT_API);
#endif
  ::glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_ES_API);
  ::glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
  ::glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
  ::glfwWindowHint(GLFW_RED_BITS, 8);
  ::glfwWindowHint(GLFW_GREEN_BITS, 8);
  ::glfwWindowHint(GLFW_BLUE_BITS, 8);
  ::glfwWindowHint(GLFW_ALPHA_BITS, 8);
  ::glfwWindowHint(GLFW_DEPTH_BITS, 32);   // 32 bit depth buffer
  ::glfwWindowHint(GLFW_STENCIL_BITS, 8);  // 8 bit stencil buffer
  ::glfwWindowHint(GLFW_SAMPLES, 4);       // 4xMSAA

  ::glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE);
#ifndef NDEBUG
  ::glfwWindowHint(GLFW_CONTEXT_DEBUG, GLFW_TRUE);
#endif

  auto window = ::glfwCreateWindow(1, 1, "Test", nullptr, share_window);
  ::glfwMakeContextCurrent(window);
  return window;
}

std::shared_ptr<PlaygroundImplGLES::ShareableContext>
PlaygroundImplGLES::MakeShareableContext(const PlaygroundSwitches& switches) {
  auto window =
      UniqueHandle(CreateGLWindow(switches, nullptr), &DestroyWindowHandle);
  if (!window) {
    FML_LOG(ERROR) << "Could not create GLES window.";
    return nullptr;
  }

  auto gl =
      std::make_unique<ProcTableGLES>(CreateGLProcAddressResolver(switches));
  if (!gl->IsValid()) {
    FML_LOG(ERROR) << "Proc table when creating a playground was invalid.";
    return nullptr;
  }

  if (gl->GetDescription()->HasDebugExtension()) {
    gl->DebugMessageCallbackKHR(
        +[](GLenum /* source */, GLenum message_type, GLuint /* message_id */,
            GLenum /* severity */, GLsizei /* length */, const GLchar* message,
            const void* /* user_param */) {
          switch (message_type) {
            case GL_DEBUG_TYPE_ERROR_KHR:
              FML_LOG(ERROR) << "GL Error: " << message;
              return;
            default:
              return;
          }
        },
        nullptr);

#ifndef NDEBUG
    gl->Enable(GL_DEBUG_OUTPUT_SYNCHRONOUS_KHR);
#endif
  }
  bool is_gles3 = gl->GetDescription()->GetGlVersion().IsAtLeast(Version(3));
  auto context_gles =
      ContextGLES::Create(switches.flags, std::move(gl),
                          ShaderLibraryMappingsForPlayground(is_gles3), true);
  if (!context_gles) {
    FML_LOG(ERROR) << "Could not create context.";
    return nullptr;
  }

  auto worker = std::make_shared<ReactorWorker>();
  worker->SetReactionsAllowedOnCurrentThread(true);

  // REMIND: context stores only a weak pointer.
  auto worker_id = context_gles->AddReactorWorker(worker);
  if (!worker_id.has_value()) {
    FML_LOG(ERROR) << "Could not add reactor worker.";
    return nullptr;
  }

  return std::make_shared<ShareableContext>(std::move(window), worker,
                                            context_gles);
}

PlaygroundImplGLES::~PlaygroundImplGLES() {
  if (context_) {
    ::glfwMakeContextCurrent(handle_.get());
    (void)context_->FlushCommandBuffers();
  }
}

static std::vector<std::shared_ptr<fml::Mapping>>
ShaderLibraryMappingsForPlayground(bool is_gles3) {
  if (is_gles3) {
    return {
        std::make_shared<fml::NonOwnedMapping>(
            impeller_entity_shaders_gles3_data,
            impeller_entity_shaders_gles3_length),
        std::make_shared<fml::NonOwnedMapping>(
            impeller_modern_shaders_gles3_data,
            impeller_modern_shaders_gles3_length),
        std::make_shared<fml::NonOwnedMapping>(
            impeller_framebuffer_blend_shaders_gles3_data,
            impeller_framebuffer_blend_shaders_gles3_length),
        std::make_shared<fml::NonOwnedMapping>(
            impeller_fixtures_shaders_gles3_data,
            impeller_fixtures_shaders_gles3_length),
        std::make_shared<fml::NonOwnedMapping>(
            impeller_modern_fixtures_shaders_gles3_data,
            impeller_modern_fixtures_shaders_gles3_length),
        std::make_shared<fml::NonOwnedMapping>(
            impeller_imgui_shaders_gles3_data,
            impeller_imgui_shaders_gles3_length),
    };
  }
  return {
      std::make_shared<fml::NonOwnedMapping>(
          impeller_entity_shaders_gles_data,
          impeller_entity_shaders_gles_length),
      std::make_shared<fml::NonOwnedMapping>(
          impeller_modern_shaders_gles_data,
          impeller_modern_shaders_gles_length),
      std::make_shared<fml::NonOwnedMapping>(
          impeller_framebuffer_blend_shaders_gles_data,
          impeller_framebuffer_blend_shaders_gles_length),
      std::make_shared<fml::NonOwnedMapping>(
          impeller_fixtures_shaders_gles_data,
          impeller_fixtures_shaders_gles_length),
      std::make_shared<fml::NonOwnedMapping>(
          impeller_modern_fixtures_shaders_gles_data,
          impeller_modern_fixtures_shaders_gles_length),
      std::make_shared<fml::NonOwnedMapping>(
          impeller_imgui_shaders_gles_data, impeller_imgui_shaders_gles_length),
  };
}

// |PlaygroundImpl|
std::shared_ptr<Context> PlaygroundImplGLES::GetContext() const {
  return context_;
}

// |PlaygroundImpl|
Playground::GLProcAddressResolver
PlaygroundImplGLES::CreateGLProcAddressResolver() const {
  return CreateGLProcAddressResolver(switches_);
}

Playground::GLProcAddressResolver
PlaygroundImplGLES::CreateGLProcAddressResolver(
    const PlaygroundSwitches& switches) {
  return switches.use_angle ? [](const char* name) -> void* {
    void* symbol = nullptr;
#if IMPELLER_PLAYGROUND_SUPPORTS_ANGLE
    void* angle_glesv2 = dlopen("libGLESv2.dylib", RTLD_LAZY);
    symbol = dlsym(angle_glesv2, name);
#endif
    FML_CHECK(symbol);
    return symbol;
  }
  : [](const char* name) -> void* {
      return reinterpret_cast<void*>(::glfwGetProcAddress(name));
    };
}

// |PlaygroundImpl|
PlaygroundImpl::WindowHandle PlaygroundImplGLES::GetWindowHandle() const {
  return handle_.get();
}

// |PlaygroundImpl|
std::unique_ptr<Surface> PlaygroundImplGLES::AcquireSurfaceFrame(
    std::shared_ptr<Context> context) {
  auto window = reinterpret_cast<GLFWwindow*>(GetWindowHandle());
  int width = 0;
  int height = 0;
  ::glfwGetFramebufferSize(window, &width, &height);
  if (width <= 0 || height <= 0) {
    return nullptr;
  }
  SurfaceGLES::SwapCallback swap_callback = [window]() -> bool {
    ::glfwSwapBuffers(window);
    return true;
  };
  return SurfaceGLES::WrapFBO(context,                         //
                              swap_callback,                   //
                              0u,                              //
                              PixelFormat::kR8G8B8A8UNormInt,  //
                              ISize::MakeWH(width, height)     //
  );
}

fml::Status PlaygroundImplGLES::SetCapabilities(
    const std::shared_ptr<Capabilities>& capabilities) {
  return fml::Status(
      fml::StatusCode::kUnimplemented,
      "PlaygroundImplGLES doesn't support setting the capabilities.");
}

RuntimeStageBackend PlaygroundImplGLES::GetRuntimeStageBackend() const {
  const auto gl =
      std::make_unique<ProcTableGLES>(CreateGLProcAddressResolver());
  if (!gl->IsValid()) {
    FML_LOG(ERROR) << "Proc table was invalid. Assuming baseline OpenGL ES";
    return RuntimeStageBackend::kOpenGLES;
  }
  bool is_gles3 = gl->GetDescription()->GetGlVersion().IsAtLeast(Version(3));
  return is_gles3 ? RuntimeStageBackend::kOpenGLES3
                  : RuntimeStageBackend::kOpenGLES;
}

}  // namespace impeller
