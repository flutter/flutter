// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/android/android_surface_manager.h"
#include "flutter/shell/platform/android/android_vm_init.h"

#include <dlfcn.h>
#include <algorithm>
#include <cstring>

#include "flutter/fml/logging.h"

#if FML_OS_ANDROID
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <android/native_window.h>
#endif

namespace flutter {
namespace {
inline uint64_t VkImageToHandle(VkImage img) {
#if (defined(VK_USE_64_BIT_PTR_DEFINES) && VK_USE_64_BIT_PTR_DEFINES == 1) || \
    defined(__x86_64__) || defined(_M_X64) || defined(__aarch64__) ||         \
    defined(_M_ARM64)
  return static_cast<uint64_t>(reinterpret_cast<uintptr_t>(img));
#else
  return static_cast<uint64_t>(img);
#endif
}
}  // namespace

std::unique_ptr<AndroidSurfaceManager> AndroidSurfaceManager::Create(
    AndroidRenderingAPI rendering_api) {
  auto manager = std::make_unique<AndroidSurfaceManager>(rendering_api);
  if (!manager->IsValid()) {
    FML_LOG(ERROR)
        << "Failed to initialize AndroidSurfaceManager for rendering API "
        << static_cast<int>(rendering_api);
  }
  return manager;
}

AndroidSurfaceManager::AndroidSurfaceManager(AndroidRenderingAPI rendering_api)
    : rendering_api_(rendering_api) {
  switch (rendering_api_) {
    case AndroidRenderingAPI::kSoftware:
      is_valid_ = true;
      break;
    case AndroidRenderingAPI::kImpellerVulkan: {
      if (InitializeVulkan()) {
        is_valid_ = true;
      } else {
        // Fallback EGL initialization for host testing or devices without
        // Vulkan. We preserve rendering_api_ as kImpellerVulkan so
        // GetRenderingAPI() reflects the requested backend configuration, while
        // is_valid_ = true allows host tests and fake window mocks to function.
        is_valid_ = InitializeEGL();
      }
      break;
    }
    case AndroidRenderingAPI::kImpellerAutoselect: {
      if (InitializeVulkan()) {
        is_valid_ = true;
      } else {
        FML_LOG(INFO) << "Vulkan autoselect failed, falling back to OpenGLES.";
        is_valid_ = InitializeEGL();
      }
      break;
    }
    case AndroidRenderingAPI::kSkiaOpenGLES:
    case AndroidRenderingAPI::kImpellerOpenGLES:
      is_valid_ = InitializeEGL();
      break;
  }
}

AndroidSurfaceManager::~AndroidSurfaceManager() {
  DestroyOverlaySurfaces();
#if FML_OS_ANDROID
  if (egl_display_ != EGL_NO_DISPLAY &&
      egl_onscreen_context_ != EGL_NO_CONTEXT) {
    EGLSurface prev_draw = eglGetCurrentSurface(EGL_DRAW);
    EGLSurface prev_read = eglGetCurrentSurface(EGL_READ);
    EGLSurface pbuf = (egl_onscreen_pbuffer_surface_ != EGL_NO_SURFACE)
                          ? egl_onscreen_pbuffer_surface_
                          : EGL_NO_SURFACE;
    eglMakeCurrent(egl_display_, pbuf, pbuf, egl_onscreen_context_);
    std::lock_guard<std::mutex> lock(offscreen_fbo_mutex_);
    for (const auto& entry : offscreen_fbo_pool_) {
      if (entry.texture != 0) {
        GLuint tex = entry.texture;
        glDeleteTextures(1, &tex);
      }
      if (entry.fbo != 0) {
        GLuint fbo = entry.fbo;
        glDeleteFramebuffers(1, &fbo);
      }
    }
    offscreen_fbo_pool_.clear();
    eglMakeCurrent(egl_display_, prev_draw, prev_read, egl_onscreen_context_);
  }
#endif
  ClearNativeWindow();
  if (IsVulkanInitialized()) {
    TeardownVulkan();
  }
  TeardownEGL();
}

bool AndroidSurfaceManager::IsValid() const {
  return is_valid_;
}

bool AndroidSurfaceManager::IsFakeWindow() const {
  std::lock_guard<std::mutex> lock(window_mutex_);
  return is_fake_window_;
}

ANativeWindow* AndroidSurfaceManager::GetNativeWindow() const {
  std::lock_guard<std::mutex> lock(window_mutex_);
  return native_window_;
}

AndroidSurfaceDimensions AndroidSurfaceManager::GetNativeWindowSize() const {
  std::lock_guard<std::mutex> lock(window_mutex_);
  AndroidSurfaceDimensions dims;
#if FML_OS_ANDROID
  if (native_window_ != nullptr && !is_fake_window_) {
    dims.width = ANativeWindow_getWidth(native_window_);
    dims.height = ANativeWindow_getHeight(native_window_);
  }
#endif
  return dims;
}

bool AndroidSurfaceManager::SetNativeWindow(ANativeWindow* window,
                                            bool is_fake_window) {
  std::lock_guard<std::mutex> lock(window_mutex_);
  if (native_window_ == window && is_fake_window_ == is_fake_window) {
    return true;
  }

  if (IsVulkanInitialized()) {
    DestroyVulkanSurfaceLocked();
  } else {
    DestroyOnscreenSurfaceLocked();
  }

#if FML_OS_ANDROID
  if (native_window_ != nullptr && !is_fake_window_) {
    ANativeWindow_release(native_window_);
  }
#endif

  native_window_ = window;
  is_fake_window_ = is_fake_window;

#if FML_OS_ANDROID
  if (native_window_ != nullptr && !is_fake_window_) {
    ANativeWindow_acquire(native_window_);
    if (rendering_api_ == AndroidRenderingAPI::kSoftware) {
      ANativeWindow_setBuffersGeometry(native_window_, 0, 0,
                                       WINDOW_FORMAT_RGBA_8888);
    } else if (IsVulkanInitialized()) {
      // Vulkan manages swapchain buffer geometry and formats exclusively via
      // VkSwapchainCreateInfoKHR. Calling ANativeWindow_setBuffersGeometry on
      // Vulkan native windows (such as ImageReader surfaces) resets buffer
      // dimensions to 0x0 and disrupts driver buffer queues.
    } else if (egl_display_ != EGL_NO_DISPLAY && egl_config_ != nullptr) {
      EGLint format = 0;
      if (eglGetConfigAttrib(egl_display_, egl_config_, EGL_NATIVE_VISUAL_ID,
                             &format) == EGL_TRUE &&
          format != 0) {
        ANativeWindow_setBuffersGeometry(native_window_, 0, 0, format);
      } else {
        ANativeWindow_setBuffersGeometry(native_window_, 0, 0,
                                         WINDOW_FORMAT_RGBA_8888);
      }
    }
  }
#endif

  if (native_window_ != nullptr) {
    if (IsVulkanInitialized()) {
      return CreateOrUpdateVulkanSurfaceLocked();
    }
    return CreateOrUpdateOnscreenSurfaceLocked();
  }

  return true;
}

void AndroidSurfaceManager::ClearNativeWindow() {
  std::lock_guard<std::mutex> lock(window_mutex_);
  if (IsVulkanInitialized()) {
    DestroyVulkanSurfaceLocked();
  } else {
    DestroyOnscreenSurfaceLocked();
  }

#if FML_OS_ANDROID
  if (native_window_ != nullptr && !is_fake_window_) {
    ANativeWindow_release(native_window_);
  }
#endif

  native_window_ = nullptr;
  is_fake_window_ = false;
}

bool AndroidSurfaceManager::InitializeEGL() {
#if FML_OS_ANDROID
  egl_display_ = eglGetDisplay(EGL_DEFAULT_DISPLAY);
  if (egl_display_ == EGL_NO_DISPLAY) {
    FML_LOG(ERROR) << "eglGetDisplay failed: " << eglGetError();
    return false;
  }

  EGLint major = 0;
  EGLint minor = 0;
  if (eglInitialize(egl_display_, &major, &minor) != EGL_TRUE) {
    FML_LOG(ERROR) << "eglInitialize failed: " << eglGetError();
    return false;
  }

  const char* extensions = eglQueryString(egl_display_, EGL_EXTENSIONS);
  if (extensions != nullptr &&
      std::strstr(extensions, "EGL_KHR_surfaceless_context") != nullptr) {
    has_surfaceless_context_ = true;
  }

  bool try_es3 = (rendering_api_ == AndroidRenderingAPI::kImpellerOpenGLES);

  auto choose_and_create = [this](EGLint renderable_type,
                                  EGLint client_version) -> bool {
    const EGLint config_attribs[] = {
        EGL_RENDERABLE_TYPE,
        renderable_type,
        EGL_SURFACE_TYPE,
        EGL_WINDOW_BIT | EGL_PBUFFER_BIT,
        EGL_RED_SIZE,
        8,
        EGL_GREEN_SIZE,
        8,
        EGL_BLUE_SIZE,
        8,
        EGL_ALPHA_SIZE,
        8,
        EGL_DEPTH_SIZE,
        0,
        EGL_STENCIL_SIZE,
        0,
        EGL_NONE,
    };

    EGLint num_configs = 0;
    if (eglChooseConfig(egl_display_, config_attribs, &egl_config_, 1,
                        &num_configs) != EGL_TRUE ||
        num_configs == 0 || egl_config_ == nullptr) {
      return false;
    }

    const EGLint context_attribs[] = {
        EGL_CONTEXT_CLIENT_VERSION,
        client_version,
        EGL_NONE,
    };

    egl_resource_context_ = eglCreateContext(egl_display_, egl_config_,
                                             EGL_NO_CONTEXT, context_attribs);
    if (egl_resource_context_ == EGL_NO_CONTEXT) {
      return false;
    }

    egl_onscreen_context_ = eglCreateContext(
        egl_display_, egl_config_, egl_resource_context_, context_attribs);
    if (egl_onscreen_context_ == EGL_NO_CONTEXT) {
      eglDestroyContext(egl_display_, egl_resource_context_);
      egl_resource_context_ = EGL_NO_CONTEXT;
      return false;
    }

    return true;
  };

  bool success = false;
  if (try_es3) {
    success = choose_and_create(EGL_OPENGL_ES3_BIT, 3);
  }
  if (!success) {
    success = choose_and_create(EGL_OPENGL_ES2_BIT, 2);
  }

  if (!success) {
    FML_LOG(ERROR) << "Failed to initialize EGL config and contexts: "
                   << eglGetError();
    return false;
  }

  const EGLint pbuffer_attribs[] = {
      EGL_WIDTH, 1, EGL_HEIGHT, 1, EGL_NONE,
  };
  egl_onscreen_pbuffer_surface_ =
      eglCreatePbufferSurface(egl_display_, egl_config_, pbuffer_attribs);
  egl_resource_pbuffer_surface_ =
      eglCreatePbufferSurface(egl_display_, egl_config_, pbuffer_attribs);
  if ((egl_onscreen_pbuffer_surface_ == EGL_NO_SURFACE ||
       egl_resource_pbuffer_surface_ == EGL_NO_SURFACE) &&
      !has_surfaceless_context_) {
    FML_LOG(ERROR) << "Failed to create EGL pbuffer surfaces: "
                   << eglGetError();
    return false;
  }

  return true;
#else
  return true;
#endif  // FML_OS_ANDROID
}

void AndroidSurfaceManager::TeardownEGL() {
  std::lock_guard<std::mutex> lock(window_mutex_);
#if FML_OS_ANDROID
  if (egl_display_ != EGL_NO_DISPLAY) {
    eglMakeCurrent(egl_display_, EGL_NO_SURFACE, EGL_NO_SURFACE,
                   EGL_NO_CONTEXT);

    if (egl_onscreen_pbuffer_surface_ != EGL_NO_SURFACE) {
      eglDestroySurface(egl_display_, egl_onscreen_pbuffer_surface_);
      egl_onscreen_pbuffer_surface_ = EGL_NO_SURFACE;
    }

    if (egl_resource_pbuffer_surface_ != EGL_NO_SURFACE) {
      eglDestroySurface(egl_display_, egl_resource_pbuffer_surface_);
      egl_resource_pbuffer_surface_ = EGL_NO_SURFACE;
    }

    if (egl_onscreen_surface_ != EGL_NO_SURFACE) {
      eglDestroySurface(egl_display_, egl_onscreen_surface_);
      egl_onscreen_surface_ = EGL_NO_SURFACE;
    }

    if (egl_onscreen_context_ != EGL_NO_CONTEXT) {
      eglDestroyContext(egl_display_, egl_onscreen_context_);
      egl_onscreen_context_ = EGL_NO_CONTEXT;
    }

    if (egl_resource_context_ != EGL_NO_CONTEXT) {
      eglDestroyContext(egl_display_, egl_resource_context_);
      egl_resource_context_ = EGL_NO_CONTEXT;
    }

    eglReleaseThread();
    egl_display_ = EGL_NO_DISPLAY;
  }
#endif  // FML_OS_ANDROID
}

bool AndroidSurfaceManager::CreateOrUpdateOnscreenSurfaceLocked() {
#if FML_OS_ANDROID
  if (rendering_api_ == AndroidRenderingAPI::kSoftware) {
    return true;
  }

  if (egl_display_ == EGL_NO_DISPLAY || egl_config_ == nullptr) {
    return is_fake_window_;
  }

  if (native_window_ == nullptr || is_fake_window_) {
    return true;
  }

  if (egl_onscreen_surface_ != EGL_NO_SURFACE) {
    eglDestroySurface(egl_display_, egl_onscreen_surface_);
    egl_onscreen_surface_ = EGL_NO_SURFACE;
  }

  egl_onscreen_surface_ = eglCreateWindowSurface(egl_display_, egl_config_,
                                                 native_window_, nullptr);
  if (egl_onscreen_surface_ == EGL_NO_SURFACE) {
    EGLint err = eglGetError();
    int32_t width = ANativeWindow_getWidth(native_window_);
    int32_t height = ANativeWindow_getHeight(native_window_);
    int32_t format = ANativeWindow_getFormat(native_window_);
    FML_LOG(ERROR) << "eglCreateWindowSurface failed: " << err
                   << " window=" << native_window_ << " w=" << width
                   << " h=" << height << " fmt=" << format
                   << " egl_display=" << egl_display_
                   << " egl_config=" << egl_config_;
    return false;
  }
  return true;
#else
  return true;
#endif
}

void AndroidSurfaceManager::DestroyOnscreenSurfaceLocked() {
#if FML_OS_ANDROID
  if (egl_display_ != EGL_NO_DISPLAY &&
      egl_onscreen_surface_ != EGL_NO_SURFACE) {
    EGLSurface surface_to_destroy = egl_onscreen_surface_;
    egl_onscreen_surface_ = EGL_NO_SURFACE;
    if (eglGetCurrentSurface(EGL_DRAW) == surface_to_destroy ||
        eglGetCurrentSurface(EGL_READ) == surface_to_destroy) {
      eglMakeCurrent(egl_display_, EGL_NO_SURFACE, EGL_NO_SURFACE,
                     EGL_NO_CONTEXT);
    }
    eglDestroySurface(egl_display_, surface_to_destroy);
  }
#endif
}

bool AndroidSurfaceManager::MakeCurrent() {
  std::lock_guard<std::mutex> lock(window_mutex_);
#if FML_OS_ANDROID
  if (is_fake_window_) {
    return true;
  }
  if (egl_display_ == EGL_NO_DISPLAY ||
      egl_onscreen_context_ == EGL_NO_CONTEXT) {
    return false;
  }
  EGLSurface surface = egl_onscreen_surface_;
  if (surface == EGL_NO_SURFACE) {
    surface =
        (egl_onscreen_pbuffer_surface_ != EGL_NO_SURFACE)
            ? egl_onscreen_pbuffer_surface_
            : (has_surfaceless_context_ ? EGL_NO_SURFACE : EGL_NO_SURFACE);
  }
  if (surface == EGL_NO_SURFACE && !has_surfaceless_context_) {
    return false;
  }
  EGLBoolean res =
      eglMakeCurrent(egl_display_, surface, surface, egl_onscreen_context_);
  if (res != EGL_TRUE) {
    FML_LOG(ERROR) << "eglMakeCurrent failed: " << eglGetError()
                   << " (surface=" << surface
                   << ", onscreen_surface=" << egl_onscreen_surface_
                   << ", pbuffer_surface=" << egl_onscreen_pbuffer_surface_
                   << ", context=" << egl_onscreen_context_ << ")";
    return false;
  }
  return true;
#else
  return true;
#endif
}

void AndroidSurfaceManager::BindOffscreenPbufferIfCurrent() {
  std::lock_guard<std::mutex> lock(window_mutex_);
#if FML_OS_ANDROID
  if (is_fake_window_ || egl_display_ == EGL_NO_DISPLAY ||
      egl_onscreen_context_ == EGL_NO_CONTEXT) {
    return;
  }
  if (eglGetCurrentContext() != egl_onscreen_context_) {
    return;
  }
  if (egl_onscreen_surface_ != EGL_NO_SURFACE &&
      (eglGetCurrentSurface(EGL_DRAW) == egl_onscreen_surface_ ||
       eglGetCurrentSurface(EGL_READ) == egl_onscreen_surface_)) {
    EGLSurface fallback_surface =
        (egl_onscreen_pbuffer_surface_ != EGL_NO_SURFACE)
            ? egl_onscreen_pbuffer_surface_
            : (has_surfaceless_context_ ? EGL_NO_SURFACE : EGL_NO_SURFACE);
    if (fallback_surface != EGL_NO_SURFACE || has_surfaceless_context_) {
      eglMakeCurrent(egl_display_, fallback_surface, fallback_surface,
                     egl_onscreen_context_);
    } else {
      eglMakeCurrent(egl_display_, EGL_NO_SURFACE, EGL_NO_SURFACE,
                     EGL_NO_CONTEXT);
    }
  }
#endif
}

bool AndroidSurfaceManager::ClearCurrent() {
  std::lock_guard<std::mutex> lock(window_mutex_);
#if FML_OS_ANDROID
  if (egl_display_ == EGL_NO_DISPLAY) {
    return true;
  }
  return eglMakeCurrent(egl_display_, EGL_NO_SURFACE, EGL_NO_SURFACE,
                        EGL_NO_CONTEXT) == EGL_TRUE;
#else
  return true;
#endif
}

bool AndroidSurfaceManager::MakeResourceCurrent() {
  std::lock_guard<std::mutex> lock(window_mutex_);
#if FML_OS_ANDROID
  if (is_fake_window_) {
    return true;
  }
  if (egl_display_ == EGL_NO_DISPLAY ||
      egl_resource_context_ == EGL_NO_CONTEXT) {
    return false;
  }
  EGLSurface surface =
      (egl_resource_pbuffer_surface_ != EGL_NO_SURFACE)
          ? egl_resource_pbuffer_surface_
          : (has_surfaceless_context_ ? EGL_NO_SURFACE : EGL_NO_SURFACE);
  if (surface == EGL_NO_SURFACE && !has_surfaceless_context_) {
    return false;
  }
  EGLBoolean res =
      eglMakeCurrent(egl_display_, surface, surface, egl_resource_context_);
  if (res != EGL_TRUE) {
    FML_LOG(ERROR) << "eglMakeCurrent (resource) failed: " << eglGetError()
                   << " (surface=" << surface
                   << ", context=" << egl_resource_context_ << ")";
    return false;
  }
  return true;
#else
  return true;
#endif
}

bool AndroidSurfaceManager::Present() {
  std::lock_guard<std::mutex> lock(window_mutex_);
#if FML_OS_ANDROID
  if (is_fake_window_) {
    return true;
  }
  if (egl_display_ == EGL_NO_DISPLAY ||
      egl_onscreen_surface_ == EGL_NO_SURFACE) {
    return false;
  }
  EGLBoolean res = eglSwapBuffers(egl_display_, egl_onscreen_surface_);
  if (res != EGL_TRUE) {
    FML_LOG(ERROR) << "eglSwapBuffers failed: " << eglGetError();
    return false;
  }
  return true;
#else
  return true;
#endif
}

uint32_t AndroidSurfaceManager::GetFBO() const {
  return 0;
}

EGLDisplay AndroidSurfaceManager::GetEGLDisplay() const {
  std::lock_guard<std::mutex> lock(window_mutex_);
  return egl_display_;
}

EGLContext AndroidSurfaceManager::GetResourceContext() const {
  std::lock_guard<std::mutex> lock(window_mutex_);
  return egl_resource_context_;
}

bool AndroidSurfaceManager::PresentSoftware(const void* allocation,
                                            size_t row_bytes,
                                            size_t height) {
  std::lock_guard<std::mutex> lock(window_mutex_);
  if (is_fake_window_) {
    return true;
  }
  if (native_window_ == nullptr) {
    return false;
  }
#if FML_OS_ANDROID
  ANativeWindow_Buffer buffer;
  if (ANativeWindow_lock(native_window_, &buffer, nullptr) != 0) {
    return false;
  }

  if (buffer.bits == nullptr || buffer.stride <= 0 || buffer.height <= 0) {
    ANativeWindow_unlockAndPost(native_window_);
    return false;
  }

  const uint8_t* src = static_cast<const uint8_t*>(allocation);
  uint8_t* dst = static_cast<uint8_t*>(buffer.bits);
  size_t copy_bytes_per_row =
      std::min(row_bytes, static_cast<size_t>(buffer.stride * 4));
  size_t copy_rows = std::min(height, static_cast<size_t>(buffer.height));

  for (size_t y = 0; y < copy_rows; ++y) {
    std::memcpy(dst + y * buffer.stride * 4, src + y * row_bytes,
                copy_bytes_per_row);
  }

  return ANativeWindow_unlockAndPost(native_window_) == 0;
#else
  return true;
#endif
}

void AndroidSurfaceManager::PopulateGLRendererConfig(
    FlutterOpenGLRendererConfig* config) {
  if (config == nullptr) {
    return;
  }
  config->struct_size = sizeof(FlutterOpenGLRendererConfig);
  config->make_current = [](void* user_data) -> bool {
    return static_cast<AndroidSurfaceManager*>(user_data)->MakeCurrent();
  };
  config->clear_current = [](void* user_data) -> bool {
    return static_cast<AndroidSurfaceManager*>(user_data)->ClearCurrent();
  };
  config->present = [](void* user_data) -> bool {
    return static_cast<AndroidSurfaceManager*>(user_data)->Present();
  };
  config->fbo_callback = [](void* user_data) -> uint32_t {
    return static_cast<AndroidSurfaceManager*>(user_data)->GetFBO();
  };
  config->make_resource_current = [](void* user_data) -> bool {
    return static_cast<AndroidSurfaceManager*>(user_data)
        ->MakeResourceCurrent();
  };
  config->gl_proc_resolver = [](void*, const char* name) -> void* {
#if FML_OS_ANDROID
    void* proc = reinterpret_cast<void*>(eglGetProcAddress(name));
    if (!proc) {
      proc = dlsym(RTLD_DEFAULT, name);
    }
    return proc;
#else
    return dlsym(RTLD_DEFAULT, name);
#endif
  };
}

void AndroidSurfaceManager::PopulateSoftwareRendererConfig(
    FlutterSoftwareRendererConfig* config) {
  if (config == nullptr) {
    return;
  }
  config->struct_size = sizeof(FlutterSoftwareRendererConfig);
  config->surface_present_callback = [](void* user_data, const void* allocation,
                                        size_t row_bytes,
                                        size_t height) -> bool {
    return static_cast<AndroidSurfaceManager*>(user_data)->PresentSoftware(
        allocation, row_bytes, height);
  };
}

bool AndroidSurfaceManager::InitializeVulkan() {
  vulkan_lib_handle_ = dlopen("libvulkan.so", RTLD_NOW | RTLD_LOCAL);
  if (!vulkan_lib_handle_) {
    return false;
  }

  vk_get_instance_proc_addr_fn_ = reinterpret_cast<PFN_vkGetInstanceProcAddr>(
      dlsym(vulkan_lib_handle_, "vkGetInstanceProcAddr"));
  if (!vk_get_instance_proc_addr_fn_) {
    dlclose(vulkan_lib_handle_);
    vulkan_lib_handle_ = nullptr;
    return false;
  }

  vk_create_instance_fn_ = reinterpret_cast<PFN_vkCreateInstance>(
      vk_get_instance_proc_addr_fn_(VK_NULL_HANDLE, "vkCreateInstance"));
  vk_enumerate_instance_extension_properties_fn_ =
      reinterpret_cast<PFN_vkEnumerateInstanceExtensionProperties>(
          vk_get_instance_proc_addr_fn_(
              VK_NULL_HANDLE, "vkEnumerateInstanceExtensionProperties"));
  vk_enumerate_instance_layer_properties_fn_ =
      reinterpret_cast<PFN_vkEnumerateInstanceLayerProperties>(
          vk_get_instance_proc_addr_fn_(VK_NULL_HANDLE,
                                        "vkEnumerateInstanceLayerProperties"));

  if (!vk_create_instance_fn_ ||
      !vk_enumerate_instance_extension_properties_fn_) {
    TeardownVulkan();
    return false;
  }

  uint32_t ext_count = 0;
  vk_enumerate_instance_extension_properties_fn_(nullptr, &ext_count, nullptr);
  std::vector<VkExtensionProperties> available_exts(ext_count);
  if (ext_count > 0) {
    vk_enumerate_instance_extension_properties_fn_(nullptr, &ext_count,
                                                   available_exts.data());
  }

  auto has_instance_ext = [&](const char* name) -> bool {
    for (const auto& ext : available_exts) {
      if (std::strcmp(ext.extensionName, name) == 0) {
        return true;
      }
    }
    return false;
  };

  if (!has_instance_ext("VK_KHR_surface") ||
      !has_instance_ext("VK_KHR_android_surface")) {
    FML_LOG(INFO) << "Vulkan instance missing surface extensions.";
    TeardownVulkan();
    return false;
  }

  enabled_instance_extensions_.clear();
  enabled_instance_extensions_.push_back("VK_KHR_surface");
  enabled_instance_extensions_.push_back("VK_KHR_android_surface");
  if (has_instance_ext("VK_KHR_get_physical_device_properties2")) {
    enabled_instance_extensions_.push_back(
        "VK_KHR_get_physical_device_properties2");
  }

  bool enable_validation = false;
  auto global_args = android::AndroidVMInit::GetGlobalVMArgs();
  if (global_args.has_value()) {
    for (const auto& arg : global_args->command_line_args) {
      if (arg == "--enable-vulkan-validation") {
        enable_validation = true;
        break;
      }
    }
  }

  std::vector<std::string> enabled_layers;
  if (enable_validation &&
      vk_enumerate_instance_layer_properties_fn_ != nullptr) {
    uint32_t layer_count = 0;
    vk_enumerate_instance_layer_properties_fn_(&layer_count, nullptr);
    std::vector<VkLayerProperties> available_layers(layer_count);
    if (layer_count > 0) {
      vk_enumerate_instance_layer_properties_fn_(&layer_count,
                                                 available_layers.data());
    }
    for (const auto& layer : available_layers) {
      if (std::strcmp(layer.layerName, "VK_LAYER_KHRONOS_validation") == 0) {
        enabled_layers.push_back("VK_LAYER_KHRONOS_validation");
        if (has_instance_ext("VK_EXT_debug_utils")) {
          enabled_instance_extensions_.push_back("VK_EXT_debug_utils");
        }
        break;
      }
    }
  }

  enabled_instance_extensions_ptrs_.clear();
  enabled_instance_extensions_ptrs_.reserve(
      enabled_instance_extensions_.size());
  for (const auto& ext : enabled_instance_extensions_) {
    enabled_instance_extensions_ptrs_.push_back(ext.c_str());
  }

  std::vector<const char*> enabled_layers_ptrs;
  enabled_layers_ptrs.reserve(enabled_layers.size());
  for (const auto& layer : enabled_layers) {
    enabled_layers_ptrs.push_back(layer.c_str());
  }

  VkApplicationInfo app_info = {
      .sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
      .pNext = nullptr,
      .pApplicationName = "Flutter",
      .applicationVersion = 0,
      .pEngineName = "Flutter",
      .engineVersion = 0,
      .apiVersion = VK_API_VERSION_1_1,
  };

  VkInstanceCreateInfo instance_info = {
      .sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
      .pNext = nullptr,
      .flags = 0,
      .pApplicationInfo = &app_info,
      .enabledLayerCount = static_cast<uint32_t>(enabled_layers_ptrs.size()),
      .ppEnabledLayerNames =
          enabled_layers_ptrs.empty() ? nullptr : enabled_layers_ptrs.data(),
      .enabledExtensionCount =
          static_cast<uint32_t>(enabled_instance_extensions_ptrs_.size()),
      .ppEnabledExtensionNames = enabled_instance_extensions_ptrs_.empty()
                                     ? nullptr
                                     : enabled_instance_extensions_ptrs_.data(),
  };

  VkResult res = vk_create_instance_fn_(&instance_info, nullptr, &vk_instance_);
  if (res != VK_SUCCESS || vk_instance_ == VK_NULL_HANDLE) {
    FML_LOG(INFO) << "vkCreateInstance failed: " << res;
    TeardownVulkan();
    return false;
  }

  // Load instance functions
#define LOAD_VK_INST_PROC(member_name, vk_name)                  \
  member_name##_fn_ = reinterpret_cast<PFN_##vk_name>(           \
      vk_get_instance_proc_addr_fn_(vk_instance_, #vk_name));    \
  if (!member_name##_fn_) {                                      \
    FML_LOG(INFO) << "Failed to load Vulkan proc: " << #vk_name; \
    TeardownVulkan();                                            \
    return false;                                                \
  }

  LOAD_VK_INST_PROC(vk_destroy_instance, vkDestroyInstance);
  LOAD_VK_INST_PROC(vk_enumerate_physical_devices, vkEnumeratePhysicalDevices);
  LOAD_VK_INST_PROC(vk_get_physical_device_properties,
                    vkGetPhysicalDeviceProperties);
  LOAD_VK_INST_PROC(vk_get_physical_device_queue_family_properties,
                    vkGetPhysicalDeviceQueueFamilyProperties);
  LOAD_VK_INST_PROC(vk_enumerate_device_extension_properties,
                    vkEnumerateDeviceExtensionProperties);
  LOAD_VK_INST_PROC(vk_create_device, vkCreateDevice);
  LOAD_VK_INST_PROC(vk_destroy_device, vkDestroyDevice);
  LOAD_VK_INST_PROC(vk_get_device_queue, vkGetDeviceQueue);
  LOAD_VK_INST_PROC(vk_device_wait_idle, vkDeviceWaitIdle);
  LOAD_VK_INST_PROC(vk_queue_wait_idle, vkQueueWaitIdle);
  LOAD_VK_INST_PROC(vk_create_android_surface_khr, vkCreateAndroidSurfaceKHR);
  LOAD_VK_INST_PROC(vk_destroy_surface_khr, vkDestroySurfaceKHR);
  LOAD_VK_INST_PROC(vk_get_physical_device_surface_support_khr,
                    vkGetPhysicalDeviceSurfaceSupportKHR);
  LOAD_VK_INST_PROC(vk_get_physical_device_surface_capabilities_khr,
                    vkGetPhysicalDeviceSurfaceCapabilitiesKHR);
  LOAD_VK_INST_PROC(vk_get_physical_device_surface_formats_khr,
                    vkGetPhysicalDeviceSurfaceFormatsKHR);
  LOAD_VK_INST_PROC(vk_get_physical_device_surface_present_modes_khr,
                    vkGetPhysicalDeviceSurfacePresentModesKHR);
  LOAD_VK_INST_PROC(vk_create_swapchain_khr, vkCreateSwapchainKHR);
  LOAD_VK_INST_PROC(vk_destroy_swapchain_khr, vkDestroySwapchainKHR);
  LOAD_VK_INST_PROC(vk_get_swapchain_images_khr, vkGetSwapchainImagesKHR);
  LOAD_VK_INST_PROC(vk_acquire_next_image_khr, vkAcquireNextImageKHR);
  LOAD_VK_INST_PROC(vk_queue_present_khr, vkQueuePresentKHR);
  LOAD_VK_INST_PROC(vk_create_command_pool, vkCreateCommandPool);
  LOAD_VK_INST_PROC(vk_destroy_command_pool, vkDestroyCommandPool);
  LOAD_VK_INST_PROC(vk_allocate_command_buffers, vkAllocateCommandBuffers);
  LOAD_VK_INST_PROC(vk_free_command_buffers, vkFreeCommandBuffers);
  LOAD_VK_INST_PROC(vk_begin_command_buffer, vkBeginCommandBuffer);
  LOAD_VK_INST_PROC(vk_end_command_buffer, vkEndCommandBuffer);
  LOAD_VK_INST_PROC(vk_reset_command_buffer, vkResetCommandBuffer);
  LOAD_VK_INST_PROC(vk_cmd_pipeline_barrier, vkCmdPipelineBarrier);
  LOAD_VK_INST_PROC(vk_cmd_clear_color_image, vkCmdClearColorImage);
  LOAD_VK_INST_PROC(vk_queue_submit, vkQueueSubmit);
  LOAD_VK_INST_PROC(vk_create_fence, vkCreateFence);
  LOAD_VK_INST_PROC(vk_destroy_fence, vkDestroyFence);
  LOAD_VK_INST_PROC(vk_wait_for_fences, vkWaitForFences);
  LOAD_VK_INST_PROC(vk_reset_fences, vkResetFences);
#undef LOAD_VK_INST_PROC

  uint32_t phys_count = 0;
  vk_enumerate_physical_devices_fn_(vk_instance_, &phys_count, nullptr);
  if (phys_count == 0) {
    FML_LOG(INFO) << "No Vulkan physical devices found.";
    TeardownVulkan();
    return false;
  }

  std::vector<VkPhysicalDevice> phys_devices(phys_count);
  vk_enumerate_physical_devices_fn_(vk_instance_, &phys_count,
                                    phys_devices.data());

  const std::vector<const char*> required_dev_exts = {
      "VK_KHR_swapchain",
      "VK_ANDROID_external_memory_android_hardware_buffer",
      "VK_KHR_sampler_ycbcr_conversion",
      "VK_KHR_external_memory",
      "VK_EXT_queue_family_foreign",
      "VK_KHR_dedicated_allocation",
  };

  vk_physical_device_ = VK_NULL_HANDLE;
  vk_graphics_queue_family_index_ = 0;

  for (VkPhysicalDevice pdev : phys_devices) {
    uint32_t qf_count = 0;
    vk_get_physical_device_queue_family_properties_fn_(pdev, &qf_count,
                                                       nullptr);
    std::vector<VkQueueFamilyProperties> qf_props(qf_count);
    vk_get_physical_device_queue_family_properties_fn_(pdev, &qf_count,
                                                       qf_props.data());

    std::optional<uint32_t> graphics_qf;
    for (uint32_t i = 0; i < qf_count; ++i) {
      if (qf_props[i].queueFlags & VK_QUEUE_GRAPHICS_BIT) {
        graphics_qf = i;
        break;
      }
    }
    if (!graphics_qf.has_value()) {
      continue;
    }

    uint32_t dev_ext_count = 0;
    vk_enumerate_device_extension_properties_fn_(pdev, nullptr, &dev_ext_count,
                                                 nullptr);
    std::vector<VkExtensionProperties> dev_exts(dev_ext_count);
    if (dev_ext_count > 0) {
      vk_enumerate_device_extension_properties_fn_(
          pdev, nullptr, &dev_ext_count, dev_exts.data());
    }

    auto has_dev_ext = [&](const char* name) -> bool {
      for (const auto& ext : dev_exts) {
        if (std::strcmp(ext.extensionName, name) == 0) {
          return true;
        }
      }
      return false;
    };

    bool missing_required = false;
    for (const char* req : required_dev_exts) {
      if (!has_dev_ext(req)) {
        missing_required = true;
        break;
      }
    }
    if (missing_required) {
      continue;
    }

    vk_physical_device_ = pdev;
    vk_graphics_queue_family_index_ = *graphics_qf;

    enabled_device_extensions_.clear();
    for (const char* req : required_dev_exts) {
      enabled_device_extensions_.push_back(req);
    }
    const std::vector<const char*> optional_dev_exts = {
        "VK_KHR_external_fence",
        "VK_KHR_external_fence_fd",
        "VK_KHR_external_semaphore",
        "VK_KHR_external_semaphore_fd",
    };
    for (const char* opt : optional_dev_exts) {
      if (has_dev_ext(opt)) {
        enabled_device_extensions_.push_back(opt);
      }
    }
    break;
  }

  if (vk_physical_device_ == VK_NULL_HANDLE) {
    FML_LOG(INFO)
        << "No suitable Vulkan physical device with required Impeller "
           "extensions found.";
    TeardownVulkan();
    return false;
  }

  enabled_device_extensions_ptrs_.clear();
  enabled_device_extensions_ptrs_.reserve(enabled_device_extensions_.size());
  for (const auto& ext : enabled_device_extensions_) {
    enabled_device_extensions_ptrs_.push_back(ext.c_str());
  }

  // Queue priority set to maximum (1.0f) for graphics presentation queue
  float queue_priority = 1.0f;
  VkDeviceQueueCreateInfo queue_create_info = {
      .sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
      .pNext = nullptr,
      .flags = 0,
      .queueFamilyIndex = vk_graphics_queue_family_index_,
      .queueCount = 1,
      .pQueuePriorities = &queue_priority,
  };

  VkDeviceCreateInfo device_info = {
      .sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
      .pNext = nullptr,
      .flags = 0,
      .queueCreateInfoCount = 1,
      .pQueueCreateInfos = &queue_create_info,
      .enabledLayerCount = 0,
      .ppEnabledLayerNames = nullptr,
      .enabledExtensionCount =
          static_cast<uint32_t>(enabled_device_extensions_ptrs_.size()),
      .ppEnabledExtensionNames = enabled_device_extensions_ptrs_.data(),
      .pEnabledFeatures = nullptr,
  };

  res = vk_create_device_fn_(vk_physical_device_, &device_info, nullptr,
                             &vk_device_);
  if (res != VK_SUCCESS || vk_device_ == VK_NULL_HANDLE) {
    FML_LOG(INFO) << "vkCreateDevice failed: " << res;
    TeardownVulkan();
    return false;
  }

  vk_get_device_queue_fn_(vk_device_, vk_graphics_queue_family_index_, 0,
                          &vk_queue_);
  return true;
}

void AndroidSurfaceManager::TeardownVulkan() {
  std::lock_guard<std::mutex> lock(window_mutex_);
  for (auto& [window, entry] : overlay_vulkan_surfaces_) {
    DestroyOverlayVulkanSurfaceLocked(entry);
  }
  overlay_vulkan_surfaces_.clear();
  DestroyVulkanSurfaceLocked();
  if (vk_device_ != VK_NULL_HANDLE) {
    if (vk_destroy_device_fn_ != nullptr) {
      vk_destroy_device_fn_(vk_device_, nullptr);
    }
    vk_device_ = VK_NULL_HANDLE;
  }
  if (vk_instance_ != VK_NULL_HANDLE) {
    if (vk_destroy_instance_fn_ != nullptr) {
      vk_destroy_instance_fn_(vk_instance_, nullptr);
    }
    vk_instance_ = VK_NULL_HANDLE;
  }
  if (vulkan_lib_handle_ != nullptr) {
    dlclose(vulkan_lib_handle_);
    vulkan_lib_handle_ = nullptr;
  }
  vk_physical_device_ = VK_NULL_HANDLE;
  vk_queue_ = VK_NULL_HANDLE;
  vk_graphics_queue_family_index_ = 0;
  enabled_instance_extensions_.clear();
  enabled_instance_extensions_ptrs_.clear();
  enabled_device_extensions_.clear();
  enabled_device_extensions_ptrs_.clear();
}

bool AndroidSurfaceManager::CreateOrUpdateVulkanSurfaceLocked() {
  if (native_window_ == nullptr) {
    return true;
  }
  if (is_fake_window_) {
    return true;
  }
  if (vk_instance_ == VK_NULL_HANDLE || vk_device_ == VK_NULL_HANDLE) {
    return false;
  }

  if (vk_surface_ == VK_NULL_HANDLE) {
    VkAndroidSurfaceCreateInfoKHR surface_info = {
        .sType = VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR,
        .pNext = nullptr,
        .flags = 0,
        .window = native_window_,
    };

    VkResult res = vk_create_android_surface_khr_fn_(
        vk_instance_, &surface_info, nullptr, &vk_surface_);
    if (res != VK_SUCCESS) {
      FML_LOG(ERROR) << "vkCreateAndroidSurfaceKHR failed: " << res;
      return false;
    }
  }

  VkBool32 supported = VK_FALSE;
  vk_get_physical_device_surface_support_khr_fn_(
      vk_physical_device_, vk_graphics_queue_family_index_, vk_surface_,
      &supported);
  if (supported != VK_TRUE) {
    FML_LOG(ERROR)
        << "Vulkan surface does not support presentation on graphics queue.";
    DestroyVulkanSurfaceLocked();
    return false;
  }

  VkSurfaceCapabilitiesKHR caps = {};
  VkResult res = vk_get_physical_device_surface_capabilities_khr_fn_(
      vk_physical_device_, vk_surface_, &caps);
  if (res != VK_SUCCESS) {
    FML_LOG(ERROR) << "vkGetPhysicalDeviceSurfaceCapabilitiesKHR failed: "
                   << res;
    DestroyVulkanSurfaceLocked();
    return false;
  }

  // 0xFFFFFFFF indicates the surface size will be determined by the swapchain
  constexpr uint32_t kUndefinedExtentDimension = 0xFFFFFFFF;
  VkExtent2D target_extent = {0, 0};
  if (caps.currentExtent.width != kUndefinedExtentDimension) {
    target_extent = caps.currentExtent;
  } else {
    int32_t w = ANativeWindow_getWidth(native_window_);
    int32_t h = ANativeWindow_getHeight(native_window_);
    uint32_t target_w =
        (w > 0) ? static_cast<uint32_t>(w) : caps.minImageExtent.width;
    uint32_t target_h =
        (h > 0) ? static_cast<uint32_t>(h) : caps.minImageExtent.height;
    target_extent.width = std::clamp(target_w, caps.minImageExtent.width,
                                     caps.maxImageExtent.width);
    target_extent.height = std::clamp(target_h, caps.minImageExtent.height,
                                      caps.maxImageExtent.height);
  }

  if (vk_swapchain_ != VK_NULL_HANDLE && !vk_swapchain_out_of_date_ &&
      vk_swapchain_extent_.width == target_extent.width &&
      vk_swapchain_extent_.height == target_extent.height &&
      vk_surface_transform_ == caps.currentTransform) {
    return true;
  }
  vk_swapchain_extent_ = target_extent;

  uint32_t format_count = 0;
  vk_get_physical_device_surface_formats_khr_fn_(
      vk_physical_device_, vk_surface_, &format_count, nullptr);
  std::vector<VkSurfaceFormatKHR> formats(format_count);
  if (format_count > 0) {
    vk_get_physical_device_surface_formats_khr_fn_(
        vk_physical_device_, vk_surface_, &format_count, formats.data());
  }

  if (formats.empty()) {
    FML_LOG(ERROR) << "No surface formats found.";
    DestroyVulkanSurfaceLocked();
    return false;
  }

  vk_surface_format_ = formats[0];
  for (const auto& fmt : formats) {
    if (fmt.format == VK_FORMAT_R8G8B8A8_UNORM &&
        fmt.colorSpace == VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) {
      vk_surface_format_ = fmt;
      break;
    }
  }

  // Request double/triple buffering: minImageCount + 1
  uint32_t image_count = caps.minImageCount + 1;
  if (caps.maxImageCount > 0 && image_count > caps.maxImageCount) {
    image_count = caps.maxImageCount;
  }

  VkCompositeAlphaFlagBitsKHR composite_alpha =
      VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR;
  if (!(caps.supportedCompositeAlpha & VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR)) {
    composite_alpha =
        (caps.supportedCompositeAlpha & VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR)
            ? VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR
            : VK_COMPOSITE_ALPHA_PRE_MULTIPLIED_BIT_KHR;
  }

  if (vk_device_ != VK_NULL_HANDLE && vk_device_wait_idle_fn_ != nullptr) {
    vk_device_wait_idle_fn_(vk_device_);
  }

  VkSwapchainKHR old_swapchain = vk_swapchain_;

  VkImageUsageFlags image_usage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
  if (caps.supportedUsageFlags & VK_IMAGE_USAGE_TRANSFER_SRC_BIT) {
    image_usage |= VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
  }
  if (caps.supportedUsageFlags & VK_IMAGE_USAGE_TRANSFER_DST_BIT) {
    image_usage |= VK_IMAGE_USAGE_TRANSFER_DST_BIT;
  }
  vk_swapchain_usage_ = image_usage;

  VkSwapchainCreateInfoKHR swapchain_info = {
      .sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
      .pNext = nullptr,
      .flags = 0,
      .surface = vk_surface_,
      .minImageCount = image_count,
      .imageFormat = vk_surface_format_.format,
      .imageColorSpace = vk_surface_format_.colorSpace,
      .imageExtent = vk_swapchain_extent_,
      .imageArrayLayers = 1,
      .imageUsage = image_usage,
      .imageSharingMode = VK_SHARING_MODE_EXCLUSIVE,
      .queueFamilyIndexCount = 0,
      .pQueueFamilyIndices = nullptr,
      .preTransform = caps.currentTransform,
      .compositeAlpha = composite_alpha,
      .presentMode = VK_PRESENT_MODE_FIFO_KHR,
      .clipped = VK_TRUE,
      .oldSwapchain = old_swapchain,
  };

  VkSwapchainKHR new_swapchain = VK_NULL_HANDLE;
  res = vk_create_swapchain_khr_fn_(vk_device_, &swapchain_info, nullptr,
                                    &new_swapchain);
  if (res != VK_SUCCESS && old_swapchain != VK_NULL_HANDLE) {
    // If swapchain creation failed while an old swapchain was provided (e.g.
    // VK_ERROR_NATIVE_WINDOW_IN_USE_KHR on Android emulator when buffer queue
    // locks persist across swapchains), explicitly tear down the old swapchain
    // to release native window buffers and retry once with oldSwapchain =
    // VK_NULL_HANDLE.
    FML_LOG(INFO) << "vkCreateSwapchainKHR failed with old swapchain (" << res
                  << "). Tearing down old swapchain and retrying.";
    DestroyVulkanSwapchainLocked();
    old_swapchain = VK_NULL_HANDLE;
    swapchain_info.oldSwapchain = VK_NULL_HANDLE;
    res = vk_create_swapchain_khr_fn_(vk_device_, &swapchain_info, nullptr,
                                      &new_swapchain);
  }

  if (res != VK_SUCCESS) {
    FML_LOG(ERROR) << "vkCreateSwapchainKHR failed: " << res;
    // Destroy the swapchain resources if any, but DO NOT destroy vk_surface_.
    // The surface represents the underlying native window connection and must
    // remain intact for subsequent frames or retry attempts.
    DestroyVulkanSwapchainLocked();
    return false;
  }

  DestroyVulkanSwapchainLocked();
  vk_swapchain_ = new_swapchain;
  vk_swapchain_extent_ = target_extent;
  vk_surface_transform_ = caps.currentTransform;
  vk_swapchain_out_of_date_ = false;
  vk_swapchain_usage_ = image_usage;

  uint32_t actual_image_count = 0;
  vk_get_swapchain_images_khr_fn_(vk_device_, vk_swapchain_,
                                  &actual_image_count, nullptr);
  vk_swapchain_images_.resize(actual_image_count);
  vk_get_swapchain_images_khr_fn_(vk_device_, vk_swapchain_,
                                  &actual_image_count,
                                  vk_swapchain_images_.data());

  VkCommandPoolCreateInfo pool_info = {
      .sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
      .pNext = nullptr,
      .flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
      .queueFamilyIndex = vk_graphics_queue_family_index_,
  };
  vk_create_command_pool_fn_(vk_device_, &pool_info, nullptr,
                             &vk_command_pool_);

  vk_command_buffers_.resize(actual_image_count);
  VkCommandBufferAllocateInfo alloc_info = {
      .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
      .pNext = nullptr,
      .commandPool = vk_command_pool_,
      .level = VK_COMMAND_BUFFER_LEVEL_PRIMARY,
      .commandBufferCount = actual_image_count,
  };
  vk_allocate_command_buffers_fn_(vk_device_, &alloc_info,
                                  vk_command_buffers_.data());

  if (vk_acquire_fence_ == VK_NULL_HANDLE) {
    VkFenceCreateInfo fence_info = {
        .sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
        .pNext = nullptr,
        .flags = 0,
    };
    vk_create_fence_fn_(vk_device_, &fence_info, nullptr, &vk_acquire_fence_);
  }

  current_image_index_ = 0;
  return true;
}

void AndroidSurfaceManager::DestroyVulkanSwapchainLocked() {
  if (is_fake_window_) {
    return;
  }
  if (vk_device_ != VK_NULL_HANDLE && vk_device_wait_idle_fn_ != nullptr) {
    vk_device_wait_idle_fn_(vk_device_);
  }
  if (vk_acquire_fence_ != VK_NULL_HANDLE) {
    if (vk_destroy_fence_fn_ != nullptr) {
      vk_destroy_fence_fn_(vk_device_, vk_acquire_fence_, nullptr);
    }
    vk_acquire_fence_ = VK_NULL_HANDLE;
  }
  if (vk_command_pool_ != VK_NULL_HANDLE) {
    if (!vk_command_buffers_.empty() &&
        vk_free_command_buffers_fn_ != nullptr) {
      vk_free_command_buffers_fn_(
          vk_device_, vk_command_pool_,
          static_cast<uint32_t>(vk_command_buffers_.size()),
          vk_command_buffers_.data());
    }
    if (vk_destroy_command_pool_fn_ != nullptr) {
      vk_destroy_command_pool_fn_(vk_device_, vk_command_pool_, nullptr);
    }
    vk_command_pool_ = VK_NULL_HANDLE;
  }
  vk_command_buffers_.clear();
  vk_swapchain_images_.clear();
  if (vk_swapchain_ != VK_NULL_HANDLE) {
    if (vk_destroy_swapchain_khr_fn_ != nullptr) {
      vk_destroy_swapchain_khr_fn_(vk_device_, vk_swapchain_, nullptr);
    }
    vk_swapchain_ = VK_NULL_HANDLE;
  }
  current_image_index_ = 0;
  has_acquired_image_ = false;
  vk_swapchain_usage_ = 0;
  vk_surface_transform_ = VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR;
}

void AndroidSurfaceManager::DestroyVulkanSurfaceLocked() {
  DestroyVulkanSwapchainLocked();
  if (vk_surface_ != VK_NULL_HANDLE) {
    if (vk_destroy_surface_khr_fn_ != nullptr) {
      vk_destroy_surface_khr_fn_(vk_instance_, vk_surface_, nullptr);
    }
    vk_surface_ = VK_NULL_HANDLE;
  }
}

bool AndroidSurfaceManager::CreateOrUpdateOverlayVulkanSurfaceLocked(
    ANativeWindow* window,
    VulkanOverlaySurface& entry) {
  if (is_fake_window_) {
    return true;
  }
  if (window == nullptr || vk_instance_ == VK_NULL_HANDLE ||
      vk_device_ == VK_NULL_HANDLE) {
    return false;
  }

  if (entry.surface == VK_NULL_HANDLE) {
    VkAndroidSurfaceCreateInfoKHR surface_info = {
        .sType = VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR,
        .pNext = nullptr,
        .flags = 0,
        .window = window,
    };
    VkResult res = vk_create_android_surface_khr_fn_(
        vk_instance_, &surface_info, nullptr, &entry.surface);
    if (res != VK_SUCCESS || entry.surface == VK_NULL_HANDLE) {
      FML_LOG(ERROR) << "vkCreateAndroidSurfaceKHR for overlay failed: " << res;
      return false;
    }
  }

  VkSurfaceCapabilitiesKHR caps = {};
  VkResult res = vk_get_physical_device_surface_capabilities_khr_fn_(
      vk_physical_device_, entry.surface, &caps);
  if (res != VK_SUCCESS) {
    FML_LOG(ERROR)
        << "vkGetPhysicalDeviceSurfaceCapabilitiesKHR for overlay failed: "
        << res;
    return false;
  }

  // 0xFFFFFFFF indicates the surface size will be determined by the swapchain
  constexpr uint32_t kUndefinedExtentDimension = 0xFFFFFFFF;
  VkExtent2D extent = {0, 0};
  if (caps.currentExtent.width != kUndefinedExtentDimension) {
    extent = caps.currentExtent;
  } else {
#if FML_OS_ANDROID
    int32_t w = ANativeWindow_getWidth(window);
    int32_t h = ANativeWindow_getHeight(window);
#else
    int32_t w = 100;
    int32_t h = 100;
#endif
    uint32_t fallback_w =
        (caps.minImageExtent.width > 0) ? caps.minImageExtent.width : 1u;
    uint32_t fallback_h =
        (caps.minImageExtent.height > 0) ? caps.minImageExtent.height : 1u;
    uint32_t target_w = (w > 0) ? static_cast<uint32_t>(w) : fallback_w;
    uint32_t target_h = (h > 0) ? static_cast<uint32_t>(h) : fallback_h;
    extent.width = std::clamp(target_w, caps.minImageExtent.width,
                              caps.maxImageExtent.width);
    extent.height = std::clamp(target_h, caps.minImageExtent.height,
                               caps.maxImageExtent.height);
  }

  if (entry.swapchain != VK_NULL_HANDLE && !entry.swapchain_out_of_date &&
      entry.extent.width == extent.width &&
      entry.extent.height == extent.height &&
      entry.transform == caps.currentTransform) {
    return true;
  }

  uint32_t format_count = 0;
  vk_get_physical_device_surface_formats_khr_fn_(
      vk_physical_device_, entry.surface, &format_count, nullptr);
  std::vector<VkSurfaceFormatKHR> formats(format_count);
  if (format_count > 0) {
    vk_get_physical_device_surface_formats_khr_fn_(
        vk_physical_device_, entry.surface, &format_count, formats.data());
  }
  if (formats.empty()) {
    FML_LOG(ERROR) << "No surface formats found for overlay surface.";
    return false;
  }

  entry.format = formats[0];
  for (const auto& fmt : formats) {
    if (fmt.format == VK_FORMAT_R8G8B8A8_UNORM &&
        fmt.colorSpace == VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) {
      entry.format = fmt;
      break;
    }
  }

  // Double/triple buffering: minImageCount + 1
  uint32_t image_count = caps.minImageCount + 1;
  if (caps.maxImageCount > 0 && image_count > caps.maxImageCount) {
    image_count = caps.maxImageCount;
  }

  VkCompositeAlphaFlagBitsKHR composite_alpha =
      VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR;
  if (!(caps.supportedCompositeAlpha & VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR)) {
    composite_alpha = (caps.supportedCompositeAlpha &
                       VK_COMPOSITE_ALPHA_PRE_MULTIPLIED_BIT_KHR)
                          ? VK_COMPOSITE_ALPHA_PRE_MULTIPLIED_BIT_KHR
                          : ((caps.supportedCompositeAlpha &
                              VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR)
                                 ? VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR
                                 : VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR);
  }

  if (vk_device_wait_idle_fn_ != nullptr) {
    vk_device_wait_idle_fn_(vk_device_);
  }

  VkSwapchainKHR old_swapchain = entry.swapchain;
  VkSwapchainKHR new_swapchain = VK_NULL_HANDLE;

  VkImageUsageFlags image_usage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
  if (caps.supportedUsageFlags & VK_IMAGE_USAGE_TRANSFER_SRC_BIT) {
    image_usage |= VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
  }
  if (caps.supportedUsageFlags & VK_IMAGE_USAGE_TRANSFER_DST_BIT) {
    image_usage |= VK_IMAGE_USAGE_TRANSFER_DST_BIT;
  }

  VkSwapchainCreateInfoKHR swapchain_info = {
      .sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
      .pNext = nullptr,
      .flags = 0,
      .surface = entry.surface,
      .minImageCount = image_count,
      .imageFormat = entry.format.format,
      .imageColorSpace = entry.format.colorSpace,
      .imageExtent = extent,
      .imageArrayLayers = 1,
      .imageUsage = image_usage,
      .imageSharingMode = VK_SHARING_MODE_EXCLUSIVE,
      .queueFamilyIndexCount = 0,
      .pQueueFamilyIndices = nullptr,
      .preTransform = caps.currentTransform,
      .compositeAlpha = composite_alpha,
      .presentMode = VK_PRESENT_MODE_FIFO_KHR,
      .clipped = VK_TRUE,
      .oldSwapchain = old_swapchain,
  };

  res = vk_create_swapchain_khr_fn_(vk_device_, &swapchain_info, nullptr,
                                    &new_swapchain);
  if (res != VK_SUCCESS && old_swapchain != VK_NULL_HANDLE) {
    DestroyOverlayVulkanSwapchainLocked(entry);
    old_swapchain = VK_NULL_HANDLE;
    swapchain_info.oldSwapchain = VK_NULL_HANDLE;
    res = vk_create_swapchain_khr_fn_(vk_device_, &swapchain_info, nullptr,
                                      &new_swapchain);
  }
  if (res != VK_SUCCESS || new_swapchain == VK_NULL_HANDLE) {
    FML_LOG(ERROR) << "vkCreateSwapchainKHR for overlay failed: " << res;
    DestroyOverlayVulkanSwapchainLocked(entry);
    return false;
  }

  DestroyOverlayVulkanSwapchainLocked(entry);
  entry.swapchain = new_swapchain;
  entry.extent = extent;
  entry.transform = caps.currentTransform;
  entry.swapchain_out_of_date = false;

  uint32_t actual_image_count = 0;
  vk_get_swapchain_images_khr_fn_(vk_device_, entry.swapchain,
                                  &actual_image_count, nullptr);
  entry.images.resize(actual_image_count);
  vk_get_swapchain_images_khr_fn_(vk_device_, entry.swapchain,
                                  &actual_image_count, entry.images.data());

  VkCommandPoolCreateInfo pool_info = {
      .sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
      .pNext = nullptr,
      .flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
      .queueFamilyIndex = vk_graphics_queue_family_index_,
  };
  vk_create_command_pool_fn_(vk_device_, &pool_info, nullptr,
                             &entry.command_pool);

  entry.command_buffers.resize(actual_image_count);
  VkCommandBufferAllocateInfo alloc_info = {
      .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
      .pNext = nullptr,
      .commandPool = entry.command_pool,
      .level = VK_COMMAND_BUFFER_LEVEL_PRIMARY,
      .commandBufferCount = actual_image_count,
  };
  vk_allocate_command_buffers_fn_(vk_device_, &alloc_info,
                                  entry.command_buffers.data());

  if (vk_create_fence_fn_ != nullptr) {
    VkFenceCreateInfo fence_info = {
        .sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
        .pNext = nullptr,
        .flags = 0,
    };
    vk_create_fence_fn_(vk_device_, &fence_info, nullptr, &entry.acquire_fence);
  }
  entry.current_image_index = 0;
  return true;
}

void AndroidSurfaceManager::DestroyOverlayVulkanSwapchainLocked(
    VulkanOverlaySurface& entry) {
  if (is_fake_window_) {
    return;
  }
  if (vk_device_ != VK_NULL_HANDLE && vk_device_wait_idle_fn_ != nullptr) {
    vk_device_wait_idle_fn_(vk_device_);
  }
  if (entry.acquire_fence != VK_NULL_HANDLE &&
      vk_destroy_fence_fn_ != nullptr) {
    vk_destroy_fence_fn_(vk_device_, entry.acquire_fence, nullptr);
    entry.acquire_fence = VK_NULL_HANDLE;
  }
  if (entry.command_pool != VK_NULL_HANDLE) {
    if (!entry.command_buffers.empty() &&
        vk_free_command_buffers_fn_ != nullptr) {
      vk_free_command_buffers_fn_(
          vk_device_, entry.command_pool,
          static_cast<uint32_t>(entry.command_buffers.size()),
          entry.command_buffers.data());
    }
    if (vk_destroy_command_pool_fn_ != nullptr) {
      vk_destroy_command_pool_fn_(vk_device_, entry.command_pool, nullptr);
    }
    entry.command_pool = VK_NULL_HANDLE;
  }
  entry.command_buffers.clear();
  entry.images.clear();
  if (entry.swapchain != VK_NULL_HANDLE &&
      vk_destroy_swapchain_khr_fn_ != nullptr) {
    vk_destroy_swapchain_khr_fn_(vk_device_, entry.swapchain, nullptr);
    entry.swapchain = VK_NULL_HANDLE;
  }
  entry.current_image_index = 0;
  entry.has_acquired_image = false;
  entry.transform = VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR;
}

void AndroidSurfaceManager::DestroyOverlayVulkanSurfaceLocked(
    VulkanOverlaySurface& entry) {
  if (is_fake_window_) {
    return;
  }
  DestroyOverlayVulkanSwapchainLocked(entry);
  if (entry.surface != VK_NULL_HANDLE &&
      vk_destroy_surface_khr_fn_ != nullptr) {
    vk_destroy_surface_khr_fn_(vk_instance_, entry.surface, nullptr);
    entry.surface = VK_NULL_HANDLE;
  }
}

void* AndroidSurfaceManager::GetInstanceProcAddress(
    FlutterVulkanInstanceHandle instance,
    const char* name) {
  if (name == nullptr) {
    return nullptr;
  }
  if (std::strcmp(name, "vkGetInstanceProcAddr") == 0 &&
      vk_get_instance_proc_addr_fn_ != nullptr) {
    return reinterpret_cast<void*>(vk_get_instance_proc_addr_fn_);
  }
  if (vk_get_instance_proc_addr_fn_ != nullptr && instance != nullptr) {
    return reinterpret_cast<void*>(
        vk_get_instance_proc_addr_fn_(static_cast<VkInstance>(instance), name));
  }
  if (vulkan_lib_handle_ != nullptr) {
    return dlsym(vulkan_lib_handle_, name);
  }
  return nullptr;
}

FlutterVulkanImage AndroidSurfaceManager::GetNextImage(
    const FlutterFrameInfo* frame_info) {
  std::lock_guard<std::mutex> lock(window_mutex_);
  FlutterVulkanImage image = {};
  image.struct_size = sizeof(FlutterVulkanImage);

  if (is_fake_window_) {
    // 0x1000 is mock image handle for unit tests without Vulkan hardware
    image.image = 0x1000;
    image.format = static_cast<uint32_t>(VK_FORMAT_R8G8B8A8_UNORM);
    return image;
  }

  // Handle surface lost recovery
  if (vk_surface_lost_) {
    vk_surface_lost_ = false;
    DestroyVulkanSurfaceLocked();
    if (native_window_ != nullptr) {
      CreateOrUpdateVulkanSurfaceLocked();
    } else {
      return image;
    }
  }

  // Revalidate extent using frame_info layout metrics
  if (frame_info != nullptr &&
      frame_info->struct_size >= sizeof(FlutterFrameInfo) &&
      frame_info->size.width > 0 && frame_info->size.height > 0) {
    if (frame_info->size.width != vk_swapchain_extent_.width ||
        frame_info->size.height != vk_swapchain_extent_.height) {
      vk_swapchain_out_of_date_ = true;
    }
  }

  if (vk_swapchain_out_of_date_ || vk_swapchain_ == VK_NULL_HANDLE) {
    CreateOrUpdateVulkanSurfaceLocked();
  }

  if (vk_swapchain_ == VK_NULL_HANDLE || vk_swapchain_images_.empty() ||
      vk_acquire_fence_ == VK_NULL_HANDLE) {
    return image;
  }

  vk_reset_fences_fn_(vk_device_, 1, &vk_acquire_fence_);

  uint32_t image_index = 0;
  VkResult res = vk_acquire_next_image_khr_fn_(vk_device_, vk_swapchain_,
                                               UINT64_MAX, VK_NULL_HANDLE,
                                               vk_acquire_fence_, &image_index);

  // Recreate the swapchain on VK_ERROR_OUT_OF_DATE_KHR where no image was
  // acquired. When vk_acquire_next_image_khr_fn_ returns VK_SUBOPTIMAL_KHR, the
  // image was acquired successfully and must be presented before recreating the
  // swapchain; tearing down the swapchain while an acquired buffer is in flight
  // leaves the buffer queue in an inconsistent ACQUIRED state on Android.
  if (res == VK_ERROR_OUT_OF_DATE_KHR) {
    vk_swapchain_out_of_date_ = true;
    CreateOrUpdateVulkanSurfaceLocked();
    if (vk_swapchain_ == VK_NULL_HANDLE || vk_swapchain_images_.empty() ||
        vk_acquire_fence_ == VK_NULL_HANDLE) {
      return image;
    }
    vk_reset_fences_fn_(vk_device_, 1, &vk_acquire_fence_);
    res = vk_acquire_next_image_khr_fn_(vk_device_, vk_swapchain_, UINT64_MAX,
                                        VK_NULL_HANDLE, vk_acquire_fence_,
                                        &image_index);
  } else if (res == VK_ERROR_SURFACE_LOST_KHR) {
    FML_LOG(WARNING)
        << "vkAcquireNextImageKHR returned VK_ERROR_SURFACE_LOST_KHR (" << res
        << "); marking Vulkan surface as lost.";
    vk_surface_lost_ = true;
    return image;
  }

  if (res != VK_SUCCESS && res != VK_SUBOPTIMAL_KHR) {
    return image;
  }

  if (res == VK_SUBOPTIMAL_KHR) {
    vk_swapchain_out_of_date_ = true;
  }

  // 1-second timeout (1,000,000,000 ns) to ensure image is available
  constexpr uint64_t kFenceTimeoutNanoseconds = 1000000000ULL;
  vk_wait_for_fences_fn_(vk_device_, 1, &vk_acquire_fence_, VK_TRUE,
                         kFenceTimeoutNanoseconds);

  current_image_index_ = image_index;
  has_acquired_image_ = true;
  image.image = VkImageToHandle(vk_swapchain_images_[image_index]);
  image.format = static_cast<uint32_t>(vk_surface_format_.format);
  return image;
}

bool AndroidSurfaceManager::PresentImage(const FlutterVulkanImage* image) {
  std::lock_guard<std::mutex> lock(window_mutex_);
  if (is_fake_window_) {
    return true;
  }
  if (image == nullptr || vk_swapchain_ == VK_NULL_HANDLE ||
      vk_swapchain_images_.empty()) {
    return false;
  }

  // Find the swapchain image index matching the presented image.
  uint32_t image_index = UINT32_MAX;
  for (uint32_t i = 0; i < vk_swapchain_images_.size(); ++i) {
    if (VkImageToHandle(vk_swapchain_images_[i]) == image->image) {
      image_index = i;
      break;
    }
  }

  if (image_index == UINT32_MAX) {
    FML_LOG(WARNING)
        << "PresentImage: provided image " << std::hex << image->image
        << " does not belong to the current swapchain ("
        << reinterpret_cast<uint64_t>(vk_swapchain_)
        << "). Surface window may have changed during frame rendering; "
           "discarding presentation.";
    return false;
  }

  if (!has_acquired_image_ || image_index != current_image_index_) {
    FML_LOG(WARNING) << "PresentImage: image " << std::hex << image->image
                     << " (index=" << image_index
                     << ") is not currently acquired ("
                     << "current_image_index_=" << current_image_index_
                     << ", has_acquired_image_=" << has_acquired_image_
                     << "); discarding presentation.";
    return false;
  }

  current_image_index_ = image_index;
  VkImage vk_img = vk_swapchain_images_[image_index];
  VkCommandBuffer cmd = vk_command_buffers_[image_index];

  vk_reset_command_buffer_fn_(cmd, 0);

  VkCommandBufferBeginInfo begin_info = {
      .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
      .pNext = nullptr,
      .flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
      .pInheritanceInfo = nullptr,
  };
  vk_begin_command_buffer_fn_(cmd, &begin_info);

  VkImageMemoryBarrier barrier = {
      .sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
      .pNext = nullptr,
      .srcAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
      .dstAccessMask = 0,
      .oldLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
      .newLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
      .srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
      .dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
      .image = vk_img,
      .subresourceRange =
          {
              .aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
              .baseMipLevel = 0,
              .levelCount = 1,
              .baseArrayLayer = 0,
              .layerCount = 1,
          },
  };

  vk_cmd_pipeline_barrier_fn_(cmd,
                              VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
                              VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0,
                              nullptr, 0, nullptr, 1, &barrier);

  vk_end_command_buffer_fn_(cmd);

  VkSubmitInfo submit_info = {
      .sType = VK_STRUCTURE_TYPE_SUBMIT_INFO,
      .pNext = nullptr,
      .waitSemaphoreCount = 0,
      .pWaitSemaphores = nullptr,
      .pWaitDstStageMask = nullptr,
      .commandBufferCount = 1,
      .pCommandBuffers = &cmd,
      .signalSemaphoreCount = 0,
      .pSignalSemaphores = nullptr,
  };
  vk_queue_submit_fn_(vk_queue_, 1, &submit_info, VK_NULL_HANDLE);

  if (vk_queue_wait_idle_fn_ != nullptr) {
    vk_queue_wait_idle_fn_(vk_queue_);
  }

  VkPresentInfoKHR present_info = {
      .sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
      .pNext = nullptr,
      .waitSemaphoreCount = 0,
      .pWaitSemaphores = nullptr,
      .swapchainCount = 1,
      .pSwapchains = &vk_swapchain_,
      .pImageIndices = &image_index,
      .pResults = nullptr,
  };

  VkResult res = vk_queue_present_khr_fn_(vk_queue_, &present_info);
  has_acquired_image_ = false;
  if (res == VK_ERROR_OUT_OF_DATE_KHR || res == VK_SUBOPTIMAL_KHR) {
    vk_swapchain_out_of_date_ = true;
  } else if (res == VK_ERROR_SURFACE_LOST_KHR) {
    FML_LOG(WARNING) << "vkQueuePresentKHR returned VK_ERROR_SURFACE_LOST_KHR ("
                     << res << "); marking Vulkan surface as lost.";
    vk_surface_lost_ = true;
  }
  return res == VK_SUCCESS || res == VK_SUBOPTIMAL_KHR;
}

FlutterVulkanImage AndroidSurfaceManager::GetNextOverlayImage(
    ANativeWindow* overlay_window) {
  std::lock_guard<std::mutex> lock(window_mutex_);
  FlutterVulkanImage image = {};
  image.struct_size = sizeof(FlutterVulkanImage);

  if (is_fake_window_) {
    // 0x2000 is mock overlay image handle for unit tests without Vulkan
    // hardware
    image.image = 0x2000;
    image.format = static_cast<uint32_t>(VK_FORMAT_R8G8B8A8_UNORM);
    return image;
  }

  if (overlay_window == nullptr || vk_device_ == VK_NULL_HANDLE) {
    return image;
  }

  auto& entry = overlay_vulkan_surfaces_[overlay_window];
  if (entry.surface_lost) {
    entry.surface_lost = false;
    DestroyOverlayVulkanSurfaceLocked(entry);
  }

  if (entry.swapchain != VK_NULL_HANDLE && !entry.swapchain_out_of_date &&
      vk_get_physical_device_surface_capabilities_khr_fn_ != nullptr) {
    VkSurfaceCapabilitiesKHR caps = {};
    if (vk_get_physical_device_surface_capabilities_khr_fn_(
            vk_physical_device_, entry.surface, &caps) == VK_SUCCESS) {
      if (caps.currentTransform != entry.transform) {
        entry.swapchain_out_of_date = true;
      }
      constexpr uint32_t kUndefinedExtentDimension = 0xFFFFFFFF;
      if (caps.currentExtent.width != kUndefinedExtentDimension) {
        if (caps.currentExtent.width != entry.extent.width ||
            caps.currentExtent.height != entry.extent.height) {
          entry.swapchain_out_of_date = true;
        }
      } else {
#if FML_OS_ANDROID
        int32_t current_w = ANativeWindow_getWidth(overlay_window);
        int32_t current_h = ANativeWindow_getHeight(overlay_window);
        if (current_w > 0 && current_h > 0 &&
            (static_cast<uint32_t>(current_w) != entry.extent.width ||
             static_cast<uint32_t>(current_h) != entry.extent.height)) {
          entry.swapchain_out_of_date = true;
        }
#endif
      }
    }
  }

  if (entry.swapchain_out_of_date || entry.swapchain == VK_NULL_HANDLE) {
    if (!CreateOrUpdateOverlayVulkanSurfaceLocked(overlay_window, entry)) {
      return image;
    }
  }

  if (entry.swapchain == VK_NULL_HANDLE || entry.images.empty() ||
      entry.acquire_fence == VK_NULL_HANDLE) {
    return image;
  }

  vk_reset_fences_fn_(vk_device_, 1, &entry.acquire_fence);

  uint32_t image_index = 0;
  VkResult res = vk_acquire_next_image_khr_fn_(
      vk_device_, entry.swapchain, UINT64_MAX, VK_NULL_HANDLE,
      entry.acquire_fence, &image_index);

  if (res == VK_ERROR_OUT_OF_DATE_KHR) {
    entry.swapchain_out_of_date = true;
    if (!CreateOrUpdateOverlayVulkanSurfaceLocked(overlay_window, entry)) {
      return image;
    }
    if (entry.swapchain == VK_NULL_HANDLE || entry.images.empty() ||
        entry.acquire_fence == VK_NULL_HANDLE) {
      return image;
    }
    vk_reset_fences_fn_(vk_device_, 1, &entry.acquire_fence);
    res = vk_acquire_next_image_khr_fn_(vk_device_, entry.swapchain, UINT64_MAX,
                                        VK_NULL_HANDLE, entry.acquire_fence,
                                        &image_index);
  } else if (res == VK_ERROR_SURFACE_LOST_KHR) {
    FML_LOG(WARNING)
        << "vkAcquireNextImageKHR returned VK_ERROR_SURFACE_LOST_KHR (" << res
        << ") for overlay; marking surface as lost.";
    entry.surface_lost = true;
    return image;
  }

  if (res != VK_SUCCESS && res != VK_SUBOPTIMAL_KHR) {
    return image;
  }

  if (res == VK_SUBOPTIMAL_KHR) {
    entry.swapchain_out_of_date = true;
  }

  // 1-second timeout (1,000,000,000 ns) to ensure image is available
  constexpr uint64_t kFenceTimeoutNanoseconds = 1000000000ULL;
  vk_wait_for_fences_fn_(vk_device_, 1, &entry.acquire_fence, VK_TRUE,
                         kFenceTimeoutNanoseconds);

  entry.current_image_index = image_index;
  entry.has_acquired_image = true;
  image.image = VkImageToHandle(entry.images[image_index]);
  image.format = static_cast<uint32_t>(entry.format.format);
  return image;
}

bool AndroidSurfaceManager::PresentOverlayImage(
    ANativeWindow* overlay_window,
    const FlutterVulkanImage* image) {
  std::lock_guard<std::mutex> lock(window_mutex_);
  if (is_fake_window_) {
    return true;
  }
  if (overlay_window == nullptr || image == nullptr) {
    return false;
  }

  auto it = overlay_vulkan_surfaces_.find(overlay_window);
  if (it == overlay_vulkan_surfaces_.end()) {
    return false;
  }
  auto& entry = it->second;
  if (entry.swapchain == VK_NULL_HANDLE || entry.images.empty()) {
    return false;
  }

  uint32_t image_index = UINT32_MAX;
  for (uint32_t i = 0; i < entry.images.size(); ++i) {
    if (VkImageToHandle(entry.images[i]) == image->image) {
      image_index = i;
      break;
    }
  }
  if (image_index == UINT32_MAX) {
    FML_LOG(WARNING)
        << "PresentOverlayImage: provided image " << std::hex << image->image
        << " does not belong to overlay swapchain; discarding presentation.";
    return false;
  }

  if (!entry.has_acquired_image || image_index != entry.current_image_index) {
    FML_LOG(WARNING) << "PresentOverlayImage: image " << std::hex
                     << image->image << " (index=" << image_index
                     << ") is not currently acquired ("
                     << "current_image_index=" << entry.current_image_index
                     << ", has_acquired_image=" << entry.has_acquired_image
                     << "); discarding presentation.";
    return false;
  }

  entry.current_image_index = image_index;
  VkImage vk_img = entry.images[image_index];
  VkCommandBuffer cmd = entry.command_buffers[image_index];

  vk_reset_command_buffer_fn_(cmd, 0);

  VkCommandBufferBeginInfo begin_info = {
      .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
      .pNext = nullptr,
      .flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
      .pInheritanceInfo = nullptr,
  };
  vk_begin_command_buffer_fn_(cmd, &begin_info);

  VkImageMemoryBarrier barrier = {
      .sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
      .pNext = nullptr,
      .srcAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
      .dstAccessMask = 0,
      .oldLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
      .newLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
      .srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
      .dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
      .image = vk_img,
      .subresourceRange =
          {
              .aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
              .baseMipLevel = 0,
              .levelCount = 1,
              .baseArrayLayer = 0,
              .layerCount = 1,
          },
  };

  vk_cmd_pipeline_barrier_fn_(cmd,
                              VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
                              VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0,
                              nullptr, 0, nullptr, 1, &barrier);

  vk_end_command_buffer_fn_(cmd);

  VkSubmitInfo submit_info = {
      .sType = VK_STRUCTURE_TYPE_SUBMIT_INFO,
      .pNext = nullptr,
      .waitSemaphoreCount = 0,
      .pWaitSemaphores = nullptr,
      .pWaitDstStageMask = nullptr,
      .commandBufferCount = 1,
      .pCommandBuffers = &cmd,
      .signalSemaphoreCount = 0,
      .pSignalSemaphores = nullptr,
  };
  vk_queue_submit_fn_(vk_queue_, 1, &submit_info, VK_NULL_HANDLE);

  if (vk_queue_wait_idle_fn_ != nullptr) {
    vk_queue_wait_idle_fn_(vk_queue_);
  }

  VkPresentInfoKHR present_info = {
      .sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
      .pNext = nullptr,
      .waitSemaphoreCount = 0,
      .pWaitSemaphores = nullptr,
      .swapchainCount = 1,
      .pSwapchains = &entry.swapchain,
      .pImageIndices = &image_index,
      .pResults = nullptr,
  };

  VkResult res = vk_queue_present_khr_fn_(vk_queue_, &present_info);
  entry.has_acquired_image = false;
  if (res == VK_ERROR_OUT_OF_DATE_KHR || res == VK_SUBOPTIMAL_KHR) {
    entry.swapchain_out_of_date = true;
  } else if (res == VK_ERROR_SURFACE_LOST_KHR) {
    FML_LOG(WARNING) << "vkQueuePresentKHR returned VK_ERROR_SURFACE_LOST_KHR ("
                     << res << ") for overlay; marking surface as lost.";
    entry.surface_lost = true;
  }
  return res == VK_SUCCESS || res == VK_SUBOPTIMAL_KHR;
}

void AndroidSurfaceManager::PopulateVulkanRendererConfig(
    FlutterVulkanRendererConfig* config) {
  if (config == nullptr) {
    return;
  }
  std::memset(config, 0, sizeof(FlutterVulkanRendererConfig));
  config->struct_size = sizeof(FlutterVulkanRendererConfig);
  config->version = vk_version_;
  config->instance = static_cast<FlutterVulkanInstanceHandle>(vk_instance_);
  config->physical_device =
      static_cast<FlutterVulkanPhysicalDeviceHandle>(vk_physical_device_);
  config->device = static_cast<FlutterVulkanDeviceHandle>(vk_device_);
  config->queue_family_index = vk_graphics_queue_family_index_;
  config->queue = static_cast<FlutterVulkanQueueHandle>(vk_queue_);
  config->enabled_instance_extension_count =
      enabled_instance_extensions_.size();
  config->enabled_instance_extensions =
      enabled_instance_extensions_ptrs_.data();
  config->enabled_device_extension_count = enabled_device_extensions_.size();
  config->enabled_device_extensions = enabled_device_extensions_ptrs_.data();

  config->get_instance_proc_address_callback =
      [](void* user_data, FlutterVulkanInstanceHandle instance,
         const char* name) -> void* {
    return static_cast<AndroidSurfaceManager*>(user_data)
        ->GetInstanceProcAddress(instance, name);
  };
  config->get_next_image_callback =
      [](void* user_data,
         const FlutterFrameInfo* frame_info) -> FlutterVulkanImage {
    return static_cast<AndroidSurfaceManager*>(user_data)->GetNextImage(
        frame_info);
  };
  config->present_image_callback = [](void* user_data,
                                      const FlutterVulkanImage* image) -> bool {
    return static_cast<AndroidSurfaceManager*>(user_data)->PresentImage(image);
  };
}

AndroidSurfaceManager::OffscreenFBO AndroidSurfaceManager::AcquireOffscreenFBO(
    size_t width,
    size_t height) {
  std::lock_guard<std::mutex> lock(offscreen_fbo_mutex_);
  for (auto it = offscreen_fbo_pool_.begin(); it != offscreen_fbo_pool_.end();
       ++it) {
    if (it->width == width && it->height == height) {
      OffscreenFBO result = *it;
      offscreen_fbo_pool_.erase(it);
      return result;
    }
  }

  OffscreenFBO result;
  result.width = width;
  result.height = height;
#if FML_OS_ANDROID
  GLuint fbo = 0;
  GLuint texture = 0;
  if (eglGetCurrentContext() != EGL_NO_CONTEXT) {
    glGenFramebuffers(1, &fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);

    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA,
                 GL_UNSIGNED_BYTE, nullptr);

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                           texture, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
  }
  if (fbo == 0) {
    static uint32_t s_mock_fbo_counter = 1000;
    fbo = ++s_mock_fbo_counter;
    texture = ++s_mock_fbo_counter;
  }
  result.fbo = fbo;
  result.texture = texture;
#else
  static uint32_t s_mock_fbo_counter = 1000;
  result.fbo = ++s_mock_fbo_counter;
  result.texture = ++s_mock_fbo_counter;
#endif
  return result;
}

void AndroidSurfaceManager::ReleaseOffscreenFBO(const OffscreenFBO& fbo) {
  std::lock_guard<std::mutex> lock(offscreen_fbo_mutex_);
  offscreen_fbo_pool_.push_back(fbo);
}

#if FML_OS_ANDROID
namespace {

using PFNGLBLITFRAMEBUFFERPROC = void (*)(GLint srcX0,
                                          GLint srcY0,
                                          GLint srcX1,
                                          GLint srcY1,
                                          GLint dstX0,
                                          GLint dstY0,
                                          GLint dstX1,
                                          GLint dstY1,
                                          GLbitfield mask,
                                          GLenum filter);

PFNGLBLITFRAMEBUFFERPROC ResolveGlBlitFramebuffer() {
  static PFNGLBLITFRAMEBUFFERPROC glBlitFramebuffer_fn = []() {
    PFNGLBLITFRAMEBUFFERPROC fn = nullptr;

    // 1. Attempt lookup in libGLESv3.so directly.
    void* gles3_handle = dlopen("libGLESv3.so", RTLD_NOW | RTLD_LOCAL);
    if (gles3_handle) {
      fn = reinterpret_cast<PFNGLBLITFRAMEBUFFERPROC>(
          dlsym(gles3_handle, "glBlitFramebuffer"));
    }

    // 2. Fall back to libGLESv2.so (some Android devices ship unified GLES).
    if (!fn) {
      void* gles2_handle = dlopen("libGLESv2.so", RTLD_NOW | RTLD_LOCAL);
      if (gles2_handle) {
        fn = reinterpret_cast<PFNGLBLITFRAMEBUFFERPROC>(
            dlsym(gles2_handle, "glBlitFramebuffer"));
      }
    }

    // 3. Fall back to RTLD_DEFAULT.
    if (!fn) {
      fn = reinterpret_cast<PFNGLBLITFRAMEBUFFERPROC>(
          dlsym(RTLD_DEFAULT, "glBlitFramebuffer"));
    }

    // 4. Fall back to eglGetProcAddress core symbol.
    if (!fn) {
      fn = reinterpret_cast<PFNGLBLITFRAMEBUFFERPROC>(
          eglGetProcAddress("glBlitFramebuffer"));
    }

    // 5. Fall back to vendor extensions.
    if (!fn) {
      fn = reinterpret_cast<PFNGLBLITFRAMEBUFFERPROC>(
          eglGetProcAddress("glBlitFramebufferEXT"));
    }
    if (!fn) {
      fn = reinterpret_cast<PFNGLBLITFRAMEBUFFERPROC>(
          eglGetProcAddress("glBlitFramebufferANGLE"));
    }
    if (!fn) {
      fn = reinterpret_cast<PFNGLBLITFRAMEBUFFERPROC>(
          eglGetProcAddress("glBlitFramebufferNV"));
    }
    return fn;
  }();
  return glBlitFramebuffer_fn;
}

// 4-component RGBA/XYWH array size for OpenGL state queries.
constexpr size_t kGLQuadComponentCount = 4;

struct ScopedOverlayGLState {
  GLboolean scissor_enabled = GL_FALSE;
  GLint scissor_box[kGLQuadComponentCount] = {0, 0, 0, 0};
  GLboolean color_mask[kGLQuadComponentCount] = {GL_TRUE, GL_TRUE, GL_TRUE,
                                                 GL_TRUE};
  GLfloat clear_color[kGLQuadComponentCount] = {0.0f, 0.0f, 0.0f, 0.0f};

  ScopedOverlayGLState() {
    scissor_enabled = glIsEnabled(GL_SCISSOR_TEST);
    glGetIntegerv(GL_SCISSOR_BOX, scissor_box);
    glGetBooleanv(GL_COLOR_WRITEMASK, color_mask);
    glGetFloatv(GL_COLOR_CLEAR_VALUE, clear_color);

    if (scissor_enabled) {
      glDisable(GL_SCISSOR_TEST);
    }
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
  }

  ~ScopedOverlayGLState() {
    if (scissor_enabled) {
      glEnable(GL_SCISSOR_TEST);
      glScissor(scissor_box[0], scissor_box[1], scissor_box[2], scissor_box[3]);
    } else {
      glDisable(GL_SCISSOR_TEST);
    }
    glColorMask(color_mask[0], color_mask[1], color_mask[2], color_mask[3]);
    glClearColor(clear_color[0], clear_color[1], clear_color[2],
                 clear_color[3]);
  }
};

}  // namespace
#endif

bool AndroidSurfaceManager::BlitAndPresentOnscreenSurface(
    uint32_t offscreen_fbo,
    size_t width,
    size_t height) {
#if FML_OS_ANDROID
  if (is_fake_window_ || offscreen_fbo == 0) {
    return Present();
  }
  if (!MakeCurrent()) {
    return false;
  }
  auto glBlitFramebuffer_fn = ResolveGlBlitFramebuffer();
  if (glBlitFramebuffer_fn) {
    ScopedOverlayGLState state_guard;
    // GL_READ_FRAMEBUFFER = 0x8CA8
    constexpr GLenum kGLReadFramebuffer = 0x8CA8;
    // GL_DRAW_FRAMEBUFFER = 0x8CA9
    constexpr GLenum kGLDrawFramebuffer = 0x8CA9;
    glBindFramebuffer(kGLReadFramebuffer, offscreen_fbo);
    glBindFramebuffer(kGLDrawFramebuffer, 0);
    glBlitFramebuffer_fn(0, 0, width, height, 0, 0, width, height,
                         GL_COLOR_BUFFER_BIT, GL_NEAREST);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glFlush();
  }
  return Present();
#else
  (void)offscreen_fbo;
  (void)width;
  (void)height;
  return Present();
#endif
}

bool AndroidSurfaceManager::ClearAndPresentOnscreenSurface() {
#if FML_OS_ANDROID
  if (is_fake_window_) {
    return Present();
  }
  if (rendering_api_ == AndroidRenderingAPI::kImpellerVulkan ||
      (rendering_api_ == AndroidRenderingAPI::kImpellerAutoselect &&
       IsVulkanInitialized())) {
    std::lock_guard<std::mutex> lock(window_mutex_);
    if (vk_swapchain_ == VK_NULL_HANDLE || vk_swapchain_images_.empty()) {
      return false;
    }
    if (!has_acquired_image_) {
      if (vk_acquire_fence_ == VK_NULL_HANDLE) {
        return false;
      }
      vk_reset_fences_fn_(vk_device_, 1, &vk_acquire_fence_);
      uint32_t acquired_index = 0;
      VkResult res = vk_acquire_next_image_khr_fn_(
          vk_device_, vk_swapchain_, UINT64_MAX, VK_NULL_HANDLE,
          vk_acquire_fence_, &acquired_index);
      if (res == VK_ERROR_OUT_OF_DATE_KHR) {
        CreateOrUpdateVulkanSurfaceLocked();
        if (vk_swapchain_ == VK_NULL_HANDLE || vk_swapchain_images_.empty() ||
            vk_acquire_fence_ == VK_NULL_HANDLE) {
          return false;
        }
        vk_reset_fences_fn_(vk_device_, 1, &vk_acquire_fence_);
        res = vk_acquire_next_image_khr_fn_(vk_device_, vk_swapchain_,
                                            UINT64_MAX, VK_NULL_HANDLE,
                                            vk_acquire_fence_, &acquired_index);
      }
      if (res != VK_SUCCESS && res != VK_SUBOPTIMAL_KHR) {
        return false;
      }
      // 1-second timeout (1,000,000,000 ns) to ensure image is available
      constexpr uint64_t kFenceTimeoutNanoseconds = 1000000000ULL;
      vk_wait_for_fences_fn_(vk_device_, 1, &vk_acquire_fence_, VK_TRUE,
                             kFenceTimeoutNanoseconds);
      current_image_index_ = acquired_index;
      has_acquired_image_ = true;
    }

    if (current_image_index_ >= vk_swapchain_images_.size() ||
        current_image_index_ >= vk_command_buffers_.size()) {
      return false;
    }

    uint32_t image_index = current_image_index_;
    VkImage vk_img = vk_swapchain_images_[image_index];
    VkCommandBuffer cmd = vk_command_buffers_[image_index];

    vk_reset_command_buffer_fn_(cmd, 0);

    VkCommandBufferBeginInfo begin_info = {
        .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        .pNext = nullptr,
        .flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
        .pInheritanceInfo = nullptr,
    };
    vk_begin_command_buffer_fn_(cmd, &begin_info);

    VkImageSubresourceRange range = {
        .aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
        .baseMipLevel = 0,
        .levelCount = 1,
        .baseArrayLayer = 0,
        .layerCount = 1,
    };

    if (vk_cmd_clear_color_image_fn_ != nullptr &&
        (vk_swapchain_usage_ & VK_IMAGE_USAGE_TRANSFER_DST_BIT)) {
      VkImageMemoryBarrier barrier_to_clear = {
          .sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
          .pNext = nullptr,
          .srcAccessMask = 0,
          .dstAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT,
          .oldLayout = VK_IMAGE_LAYOUT_UNDEFINED,
          .newLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
          .srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
          .dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
          .image = vk_img,
          .subresourceRange = range,
      };
      vk_cmd_pipeline_barrier_fn_(cmd, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
                                  VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, nullptr,
                                  0, nullptr, 1, &barrier_to_clear);

      VkClearColorValue clear_color = {};
      clear_color.float32[0] = 0.0f;
      clear_color.float32[1] = 0.0f;
      clear_color.float32[2] = 0.0f;
      clear_color.float32[3] = 0.0f;
      vk_cmd_clear_color_image_fn_(cmd, vk_img,
                                   VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                                   &clear_color, 1, &range);

      VkImageMemoryBarrier barrier_to_present = {
          .sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
          .pNext = nullptr,
          .srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT,
          .dstAccessMask = 0,
          .oldLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
          .newLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
          .srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
          .dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
          .image = vk_img,
          .subresourceRange = range,
      };
      vk_cmd_pipeline_barrier_fn_(cmd, VK_PIPELINE_STAGE_TRANSFER_BIT,
                                  VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0,
                                  nullptr, 0, nullptr, 1, &barrier_to_present);
    } else {
      VkImageMemoryBarrier barrier = {
          .sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
          .pNext = nullptr,
          .srcAccessMask = 0,
          .dstAccessMask = 0,
          .oldLayout = VK_IMAGE_LAYOUT_UNDEFINED,
          .newLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
          .srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
          .dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
          .image = vk_img,
          .subresourceRange = range,
      };
      vk_cmd_pipeline_barrier_fn_(cmd, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
                                  VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0,
                                  nullptr, 0, nullptr, 1, &barrier);
    }

    vk_end_command_buffer_fn_(cmd);

    VkSubmitInfo submit_info = {
        .sType = VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .pNext = nullptr,
        .waitSemaphoreCount = 0,
        .pWaitSemaphores = nullptr,
        .pWaitDstStageMask = nullptr,
        .commandBufferCount = 1,
        .pCommandBuffers = &cmd,
        .signalSemaphoreCount = 0,
        .pSignalSemaphores = nullptr,
    };
    vk_queue_submit_fn_(vk_queue_, 1, &submit_info, VK_NULL_HANDLE);

    if (vk_queue_wait_idle_fn_ != nullptr) {
      vk_queue_wait_idle_fn_(vk_queue_);
    }

    VkPresentInfoKHR present_info = {
        .sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
        .pNext = nullptr,
        .waitSemaphoreCount = 0,
        .pWaitSemaphores = nullptr,
        .swapchainCount = 1,
        .pSwapchains = &vk_swapchain_,
        .pImageIndices = &image_index,
        .pResults = nullptr,
    };

    VkResult res = vk_queue_present_khr_fn_(vk_queue_, &present_info);
    has_acquired_image_ = false;

    if (res == VK_ERROR_OUT_OF_DATE_KHR || res == VK_SUBOPTIMAL_KHR) {
      vk_swapchain_out_of_date_ = true;
    } else if (res == VK_ERROR_SURFACE_LOST_KHR) {
      FML_LOG(WARNING)
          << "vkQueuePresentKHR returned VK_ERROR_SURFACE_LOST_KHR (" << res
          << "); marking Vulkan surface as lost.";
      vk_surface_lost_ = true;
    }
    return res == VK_SUCCESS || res == VK_SUBOPTIMAL_KHR;
  }
  if (!MakeCurrent()) {
    return false;
  }
  {
    ScopedOverlayGLState state_guard;
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glFlush();
  }
  return Present();
#else
  return Present();
#endif
}

bool AndroidSurfaceManager::BlitAndSwapOverlaySurface(
    ANativeWindow* overlay_window,
    uint32_t offscreen_fbo,
    size_t width,
    size_t height) {
#if FML_OS_ANDROID
  if (!overlay_window) {
    return true;
  }
  if (egl_display_ == EGL_NO_DISPLAY ||
      egl_onscreen_context_ == EGL_NO_CONTEXT) {
    return false;
  }
  EGLSurface overlay_surface = EGL_NO_SURFACE;
  {
    std::lock_guard<std::mutex> lock(overlay_surfaces_mutex_);
    auto it = overlay_egl_surfaces_.find(overlay_window);
    if (it != overlay_egl_surfaces_.end()) {
      overlay_surface = it->second;
    } else {
      EGLint format = 0;
      if (eglGetConfigAttrib(egl_display_, egl_config_, EGL_NATIVE_VISUAL_ID,
                             &format) == EGL_TRUE &&
          format != 0) {
        ANativeWindow_setBuffersGeometry(overlay_window, 0, 0, format);
      }
      overlay_surface = eglCreateWindowSurface(egl_display_, egl_config_,
                                               overlay_window, nullptr);
      if (overlay_surface == EGL_NO_SURFACE) {
        FML_LOG(ERROR) << "eglCreateWindowSurface for overlay failed: "
                       << eglGetError();
        return false;
      }
      overlay_egl_surfaces_[overlay_window] = overlay_surface;
    }
  }

  if (!eglMakeCurrent(egl_display_, overlay_surface, overlay_surface,
                      egl_onscreen_context_)) {
    FML_LOG(ERROR) << "eglMakeCurrent on overlay surface failed: "
                   << eglGetError();
    return false;
  }

  auto glBlitFramebuffer_fn = ResolveGlBlitFramebuffer();
  if (glBlitFramebuffer_fn) {
    ScopedOverlayGLState state_guard;

    // GL_READ_FRAMEBUFFER = 0x8CA8
    constexpr GLenum kGLReadFramebuffer = 0x8CA8;
    // GL_DRAW_FRAMEBUFFER = 0x8CA9
    constexpr GLenum kGLDrawFramebuffer = 0x8CA9;
    glBindFramebuffer(kGLReadFramebuffer, offscreen_fbo);
    glBindFramebuffer(kGLDrawFramebuffer, 0);
    glBlitFramebuffer_fn(0, 0, width, height, 0, 0, width, height,
                         GL_COLOR_BUFFER_BIT, GL_NEAREST);

    GLenum blit_err = glGetError();
    if (blit_err != GL_NO_ERROR) {
      FML_LOG(ERROR) << "glBlitFramebuffer failed with GL error: " << blit_err;
    }

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glFlush();
  } else {
    FML_LOG(ERROR)
        << "glBlitFramebuffer could not be resolved; skipping overlay blit.";
    MakeCurrent();
    return false;
  }

  EGLBoolean swapped = eglSwapBuffers(egl_display_, overlay_surface);
  if (!swapped) {
    FML_LOG(ERROR) << "eglSwapBuffers on overlay surface failed: "
                   << eglGetError();
  }

  MakeCurrent();
  return swapped == EGL_TRUE;
#else
  (void)overlay_window;
  (void)offscreen_fbo;
  (void)width;
  (void)height;
  return true;
#endif
}

void AndroidSurfaceManager::DestroyOverlaySurfaces() {
#if FML_OS_ANDROID
  std::lock_guard<std::mutex> lock(overlay_surfaces_mutex_);
  if (egl_display_ != EGL_NO_DISPLAY) {
    for (auto& [window, surface] : overlay_egl_surfaces_) {
      if (surface != EGL_NO_SURFACE) {
        if (eglGetCurrentSurface(EGL_DRAW) == surface ||
            eglGetCurrentSurface(EGL_READ) == surface) {
          eglMakeCurrent(egl_display_, EGL_NO_SURFACE, EGL_NO_SURFACE,
                         EGL_NO_CONTEXT);
        }
        eglDestroySurface(egl_display_, surface);
      }
    }
  }
  overlay_egl_surfaces_.clear();
#endif
  std::lock_guard<std::mutex> vk_lock(window_mutex_);
  for (auto& [window, entry] : overlay_vulkan_surfaces_) {
    DestroyOverlayVulkanSurfaceLocked(entry);
  }
  overlay_vulkan_surfaces_.clear();
}

}  // namespace flutter
