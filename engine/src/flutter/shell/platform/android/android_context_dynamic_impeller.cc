// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_context_dynamic_impeller.h"

#include <android/api-level.h>
#include <sys/system_properties.h>
#include <memory>

#include "flutter/impeller/base/validation.h"
#include "shell/platform/android/android_rendering_selector.h"

namespace fs = std::filesystem;

namespace flutter {

namespace {

static const constexpr char* kAndroidHuawei = "android-huawei";

static constexpr const char* kBadSocs[] = {
    // Most Exynos Series SoC. These are SoCs that crash when using AHB imports.
    "exynos7870",  //
    "exynos7880",  //
    "exynos7872",  //
    "exynos7884",  //
    "exynos7885",  //
    "exynos7904",  //
    // Mongoose line.
    "exynos8890",  //
    "exynos8895",  //
    "exynos9609",  //
    "exynos9610",  //
    "exynos9611",  //
    "exynos9810",  //
    // `exynos9820` and `exynos9825` have graphical errors:
    // https://github.com/flutter/flutter/issues/171992.
    "exynos9820",  //
    "exynos9825"   //
};

static bool IsDeviceEmulator() {
  char property[PROP_VALUE_MAX];

  __system_property_get("ro.hardware", property);
  std::string_view hardware_prop(property);
  if (hardware_prop == "goldfish" || hardware_prop == "ranchu" ||
      hardware_prop == "qemu") {
    return true;
  }

  __system_property_get("ro.product.model", property);
  std::string_view model_prop(property);
  if (model_prop.find("gphone") != std::string::npos) {
    return true;
  }

  if (::access("/dev/qemu_pipe", F_OK) == 0) {
    return true;
  }

  return false;
}

static bool IsKnownBadSOC(std::string_view hardware) {
  // TODO(jonahwilliams): if the list gets too long (> 16), convert
  // to a hash map first.
  for (const auto& board : kBadSocs) {
    if (strcmp(board, hardware.data()) == 0) {
      return true;
    }
  }
  return false;
}

static std::shared_ptr<AndroidContextVKImpeller>
GetActualRenderingAPIForImpeller(
    int api_level,
    const AndroidContext::ContextSettings& settings) {
  constexpr int kMinimumAndroidApiLevelForMediaTekVulkan = 31;

  // have requisite features to support platform views.
  //
  // Even if this check returns true, Impeller may determine it cannot use
  // Vulkan for some other reason, such as a missing required extension or
  // feature. In these cases it will use OpenGLES.
  if (IsDeviceEmulator()) {
    // Avoid using Vulkan on known emulators.
    return nullptr;
  }

  char property[PROP_VALUE_MAX];
  __system_property_get("ro.com.google.clientidbase", property);
  if (strcmp(property, kAndroidHuawei) == 0) {
    // Avoid using Vulkan on Huawei as AHB imports do not
    // consistently work.
    return nullptr;
  }

  if (api_level < kMinimumAndroidApiLevelForMediaTekVulkan &&
      __system_property_find("ro.vendor.mediatek.platform") != nullptr) {
    // Probably MediaTek. Avoid Vulkan if older than 34 to work around
    // crashes when importing AHB.
    return nullptr;
  }

  __system_property_get("ro.product.board", property);
  if (IsKnownBadSOC(property)) {
    FML_LOG(INFO)
        << "Known bad Vulkan driver encountered, falling back to OpenGLES.";
    return nullptr;
  }

  // Determine if Vulkan is supported by creating a Vulkan context and
  // checking if it is valid.
  impeller::ScopedValidationDisable disable_validation;
  auto vulkan_backend = std::make_shared<AndroidContextVKImpeller>(
      AndroidContext::ContextSettings{
#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
          .enable_validation = settings.enable_validation,
#else
          .enable_validation = false,
#endif  // FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
          .enable_gpu_tracing = settings.enable_gpu_tracing,
          .enable_surface_control = settings.enable_surface_control,
          .impeller_flags =
              {
                  .lazy_shader_mode = settings.impeller_flags.lazy_shader_mode,
                  .antialiased_lines =
                      settings.impeller_flags.antialiased_lines,
              },
      });
  if (!vulkan_backend->IsValid()) {
    return nullptr;
  }
  return vulkan_backend;
}
}  // namespace

AndroidContextDynamicImpeller::AndroidContextDynamicImpeller(
    const AndroidContext::ContextSettings& settings)
    : AndroidContext(AndroidRenderingAPI::kImpellerVulkan),
      settings_(settings) {}

AndroidContextDynamicImpeller::~AndroidContextDynamicImpeller() = default;

AndroidRenderingAPI AndroidContextDynamicImpeller::RenderingApi() const {
  if (vk_context_) {
    return AndroidRenderingAPI::kImpellerVulkan;
  }
  if (gl_context_) {
    return AndroidRenderingAPI::kImpellerOpenGLES;
  }
  return AndroidRenderingAPI::kImpellerAutoselect;
}

std::shared_ptr<impeller::Context>
AndroidContextDynamicImpeller::GetImpellerContext() const {
  if (vk_context_) {
    return vk_context_->GetImpellerContext();
  }
  if (gl_context_) {
    return gl_context_->GetImpellerContext();
  }
  return nullptr;
}

std::shared_ptr<AndroidContextGLImpeller>
AndroidContextDynamicImpeller::GetGLContext() const {
  return gl_context_;
}

std::shared_ptr<AndroidContextVKImpeller>
AndroidContextDynamicImpeller::GetVKContext() const {
  return vk_context_;
}

void AndroidContextDynamicImpeller::SetupImpellerContext() {
  if (vk_context_ || gl_context_) {
    return;
  }
  vk_context_ = GetActualRenderingAPIForImpeller(android_get_device_api_level(),
                                                 settings_);
  if (!vk_context_) {
    gl_context_ = std::make_shared<AndroidContextGLImpeller>(
        std::make_unique<impeller::egl::Display>(),
        settings_.enable_gpu_tracing);
  }
}

}  // namespace flutter
