// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Smoke test for the wrapped GN build of the GPU test backends: ANGLE on
// SwiftShader through EGL, as //flutter/testing:opengl sets it up, and
// SwiftShader's Vulkan driver opened directly, as //flutter/testing:vulkan
// does. Both need the driver, its ICD manifest and the loader next to this
// binary (flutter_gpu_test_backends in the BUILD file).

#include <dlfcn.h>

#include <cstring>
#include <string>

#include "gtest/gtest.h"

// After gtest: the Vulkan headers come with the engine's platform defines
// (VK_USE_PLATFORM_XLIB_KHR), and Xlib's macros (None, Bool) break gtest's
// declarations when they come first.
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES2/gl2.h>
#include <vulkan/vulkan.h>

namespace {

bool HasExtension(const char* extensions, const char* name) {
  const char* found = strstr(extensions, name);
  const size_t length = strlen(name);
  return found != nullptr && (found[length] == ' ' || found[length] == '\0');
}

TEST(GlBackendsSmokeTest, AngleRendersWithSwiftShader) {
  const char* extensions = eglQueryString(EGL_NO_DISPLAY, EGL_EXTENSIONS);
  ASSERT_NE(extensions, nullptr);
  ASSERT_TRUE(HasExtension(extensions, "EGL_ANGLE_platform_angle_vulkan"))
      << extensions;
  ASSERT_TRUE(HasExtension(extensions,
                           "EGL_ANGLE_platform_angle_device_type_swiftshader"))
      << extensions;

  auto get_platform_display = reinterpret_cast<PFNEGLGETPLATFORMDISPLAYEXTPROC>(
      eglGetProcAddress("eglGetPlatformDisplayEXT"));
  ASSERT_NE(get_platform_display, nullptr);
  const EGLint display_attributes[] = {
      EGL_PLATFORM_ANGLE_TYPE_ANGLE,
      EGL_PLATFORM_ANGLE_TYPE_VULKAN_ANGLE,
      EGL_PLATFORM_ANGLE_DEVICE_TYPE_ANGLE,
      EGL_PLATFORM_ANGLE_DEVICE_TYPE_SWIFTSHADER_ANGLE,
      EGL_PLATFORM_ANGLE_NATIVE_PLATFORM_TYPE_ANGLE,
      EGL_PLATFORM_VULKAN_DISPLAY_MODE_HEADLESS_ANGLE,
      EGL_NONE,
  };
  EGLDisplay display = get_platform_display(
      EGL_PLATFORM_ANGLE_ANGLE,
      reinterpret_cast<EGLNativeDisplayType*>(EGL_DEFAULT_DISPLAY),
      display_attributes);
  ASSERT_NE(display, EGL_NO_DISPLAY);
  // Initialization is where ANGLE opens the Vulkan loader and the loader
  // the SwiftShader ICD, both from this binary's directory.
  ASSERT_TRUE(eglInitialize(display, nullptr, nullptr))
      << "eglInitialize failed: 0x" << std::hex << eglGetError();

  const EGLint config_attributes[] = {
      EGL_SURFACE_TYPE,
      EGL_PBUFFER_BIT,
      EGL_RENDERABLE_TYPE,
      EGL_OPENGL_ES2_BIT,
      EGL_RED_SIZE,
      8,
      EGL_GREEN_SIZE,
      8,
      EGL_BLUE_SIZE,
      8,
      EGL_ALPHA_SIZE,
      8,
      EGL_NONE,
  };
  EGLConfig config = nullptr;
  EGLint config_count = 0;
  ASSERT_TRUE(
      eglChooseConfig(display, config_attributes, &config, 1, &config_count));
  ASSERT_EQ(config_count, 1);
  const EGLint context_attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE};
  EGLContext context =
      eglCreateContext(display, config, EGL_NO_CONTEXT, context_attributes);
  ASSERT_NE(context, EGL_NO_CONTEXT);
  const EGLint surface_attributes[] = {EGL_WIDTH, 4, EGL_HEIGHT, 4, EGL_NONE};
  EGLSurface surface =
      eglCreatePbufferSurface(display, config, surface_attributes);
  ASSERT_NE(surface, EGL_NO_SURFACE);
  ASSERT_TRUE(eglMakeCurrent(display, surface, surface, context));

  const auto* renderer =
      reinterpret_cast<const char*>(glGetString(GL_RENDERER));
  ASSERT_NE(renderer, nullptr);
  EXPECT_NE(std::string(renderer).find("SwiftShader"), std::string::npos)
      << renderer;

  glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  unsigned char pixel[4] = {0, 0, 0, 0};
  glReadPixels(0, 0, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, pixel);
  EXPECT_EQ(glGetError(), static_cast<GLenum>(GL_NO_ERROR));
  EXPECT_EQ(pixel[0], 255);
  EXPECT_EQ(pixel[1], 0);
  EXPECT_EQ(pixel[2], 0);
  EXPECT_EQ(pixel[3], 255);

  eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
  eglDestroySurface(display, surface);
  eglDestroyContext(display, context);
  eglTerminate(display);
}

TEST(GlBackendsSmokeTest, SwiftShaderOpensAsVulkanDriver) {
  // A bare name: found through the executable's $ORIGIN rpath, as
  // //flutter/vulkan/procs opens it.
  void* library = dlopen("libvk_swiftshader.so", RTLD_NOW | RTLD_LOCAL);
  ASSERT_NE(library, nullptr) << dlerror();
  // vkGetInstanceProcAddr, as //flutter/vulkan/procs resolves it (through
  // the ICD entry point, vk_icdGetInstanceProcAddr, the driver would take
  // the caller for a loader of interface version 4 and refuse Vulkan 1.1).
  auto get_instance_proc_addr = reinterpret_cast<PFN_vkGetInstanceProcAddr>(
      dlsym(library, "vkGetInstanceProcAddr"));
  ASSERT_NE(get_instance_proc_addr, nullptr) << dlerror();

  auto create_instance = reinterpret_cast<PFN_vkCreateInstance>(
      get_instance_proc_addr(nullptr, "vkCreateInstance"));
  ASSERT_NE(create_instance, nullptr);
  VkApplicationInfo application_info = {};
  application_info.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
  application_info.pApplicationName = "gl_backends_smoke_test";
  application_info.apiVersion = VK_API_VERSION_1_1;
  VkInstanceCreateInfo create_info = {};
  create_info.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
  create_info.pApplicationInfo = &application_info;
  VkInstance instance = VK_NULL_HANDLE;
  ASSERT_EQ(create_instance(&create_info, nullptr, &instance), VK_SUCCESS);

  auto enumerate_physical_devices =
      reinterpret_cast<PFN_vkEnumeratePhysicalDevices>(
          get_instance_proc_addr(instance, "vkEnumeratePhysicalDevices"));
  auto get_physical_device_properties =
      reinterpret_cast<PFN_vkGetPhysicalDeviceProperties>(
          get_instance_proc_addr(instance, "vkGetPhysicalDeviceProperties"));
  auto destroy_instance = reinterpret_cast<PFN_vkDestroyInstance>(
      get_instance_proc_addr(instance, "vkDestroyInstance"));
  ASSERT_NE(enumerate_physical_devices, nullptr);
  ASSERT_NE(get_physical_device_properties, nullptr);
  ASSERT_NE(destroy_instance, nullptr);

  uint32_t device_count = 0;
  ASSERT_EQ(enumerate_physical_devices(instance, &device_count, nullptr),
            VK_SUCCESS);
  ASSERT_EQ(device_count, 1u);
  VkPhysicalDevice device = VK_NULL_HANDLE;
  ASSERT_EQ(enumerate_physical_devices(instance, &device_count, &device),
            VK_SUCCESS);
  VkPhysicalDeviceProperties properties = {};
  get_physical_device_properties(device, &properties);
  EXPECT_NE(std::string(properties.deviceName).find("SwiftShader"),
            std::string::npos)
      << properties.deviceName;

  destroy_instance(instance, nullptr);
  dlclose(library);
}

}  // namespace
