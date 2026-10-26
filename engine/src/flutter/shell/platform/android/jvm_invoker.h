// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_JVM_INVOKER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_JVM_INVOKER_H_

#include <jni.h>
#include <atomic>
#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

#include "flutter/fml/build_config.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"

#if FML_OS_ANDROID
#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/fml/platform/android/jni_weak_ref.h"
#include "flutter/fml/platform/android/scoped_java_ref.h"
#else
namespace fml {
namespace jni {

template <typename T>
class ScopedJavaLocalRef {
 public:
  ScopedJavaLocalRef() = default;
  ScopedJavaLocalRef(JNIEnv* env, T obj) : env_(env), obj_(obj) {}
  explicit ScopedJavaLocalRef(T obj) : obj_(obj) {}
  ~ScopedJavaLocalRef() { Reset(); }

  ScopedJavaLocalRef(const ScopedJavaLocalRef& other)
      : env_(other.env_), obj_(other.obj_) {
    if (env_ && obj_) {
      obj_ = static_cast<T>(env_->NewLocalRef(obj_));
    }
  }

  ScopedJavaLocalRef& operator=(const ScopedJavaLocalRef& other) {
    if (this != &other) {
      Reset();
      env_ = other.env_;
      obj_ = other.obj_;
      if (env_ && obj_) {
        obj_ = static_cast<T>(env_->NewLocalRef(obj_));
      }
    }
    return *this;
  }

  ScopedJavaLocalRef(ScopedJavaLocalRef&& other) noexcept
      : env_(other.env_), obj_(other.obj_) {
    other.env_ = nullptr;
    other.obj_ = nullptr;
  }

  ScopedJavaLocalRef& operator=(ScopedJavaLocalRef&& other) noexcept {
    if (this != &other) {
      Reset();
      env_ = other.env_;
      obj_ = other.obj_;
      other.env_ = nullptr;
      other.obj_ = nullptr;
    }
    return *this;
  }

  T obj() const { return obj_; }
  bool is_null() const { return obj_ == nullptr; }

  void Reset() {
    if (env_ && obj_) {
      env_->DeleteLocalRef(obj_);
    }
    obj_ = nullptr;
  }

  void Reset(JNIEnv* env, T obj) {
    Reset();
    env_ = env;
    obj_ = obj;
  }

 private:
  JNIEnv* env_ = nullptr;
  T obj_ = nullptr;
};

template <typename T>
class ScopedJavaGlobalRef {
 public:
  ScopedJavaGlobalRef() = default;
  ScopedJavaGlobalRef(JNIEnv* env, T obj) : env_(env) {
    if (env_ && obj) {
      obj_ = static_cast<T>(env_->NewGlobalRef(obj));
    } else {
      obj_ = obj;
    }
  }
  explicit ScopedJavaGlobalRef(const ScopedJavaLocalRef<T>& local)
      : obj_(local.obj()) {}
  ~ScopedJavaGlobalRef() { Reset(); }

  ScopedJavaGlobalRef(const ScopedJavaGlobalRef& other)
      : env_(other.env_), obj_(other.obj_) {
    if (env_ && obj_) {
      obj_ = static_cast<T>(env_->NewGlobalRef(obj_));
    }
  }

  ScopedJavaGlobalRef& operator=(const ScopedJavaGlobalRef& other) {
    if (this != &other) {
      Reset();
      env_ = other.env_;
      obj_ = other.obj_;
      if (env_ && obj_) {
        obj_ = static_cast<T>(env_->NewGlobalRef(obj_));
      }
    }
    return *this;
  }

  ScopedJavaGlobalRef(ScopedJavaGlobalRef&& other) noexcept
      : env_(other.env_), obj_(other.obj_) {
    other.env_ = nullptr;
    other.obj_ = nullptr;
  }

  ScopedJavaGlobalRef& operator=(ScopedJavaGlobalRef&& other) noexcept {
    if (this != &other) {
      Reset();
      env_ = other.env_;
      obj_ = other.obj_;
      other.env_ = nullptr;
      other.obj_ = nullptr;
    }
    return *this;
  }

  T obj() const { return obj_; }
  bool is_null() const { return obj_ == nullptr; }
  explicit operator bool() const { return obj_ != nullptr; }

  void Reset() {
    if (env_ && obj_) {
      env_->DeleteGlobalRef(obj_);
    }
    obj_ = nullptr;
  }

  void Reset(JNIEnv* env, T obj) {
    Reset();
    env_ = env;
    if (env_ && obj) {
      obj_ = static_cast<T>(env_->NewGlobalRef(obj));
    } else {
      obj_ = obj;
    }
  }

 private:
  JNIEnv* env_ = nullptr;
  T obj_ = nullptr;
};

class JavaObjectWeakGlobalRef {
 public:
  JavaObjectWeakGlobalRef() = default;
  JavaObjectWeakGlobalRef(JNIEnv* env, jobject obj) : env_(env) {
    if (env_ && obj) {
      obj_ = env_->NewWeakGlobalRef(obj);
    } else {
      obj_ = obj;
    }
  }
  ~JavaObjectWeakGlobalRef() { reset(); }

  JavaObjectWeakGlobalRef(const JavaObjectWeakGlobalRef& other)
      : env_(other.env_), obj_(other.obj_) {
    if (env_ && obj_) {
      obj_ = env_->NewWeakGlobalRef(obj_);
    }
  }

  JavaObjectWeakGlobalRef& operator=(const JavaObjectWeakGlobalRef& other) {
    if (this != &other) {
      reset();
      env_ = other.env_;
      obj_ = other.obj_;
      if (env_ && obj_) {
        obj_ = env_->NewWeakGlobalRef(obj_);
      }
    }
    return *this;
  }

  ScopedJavaLocalRef<jobject> get(JNIEnv* env) const {
    if (!env || !obj_) {
      return ScopedJavaLocalRef<jobject>();
    }
    return ScopedJavaLocalRef<jobject>(env, env->NewLocalRef(obj_));
  }

  bool is_empty() const { return obj_ == nullptr; }

  void reset() {
    if (env_ && obj_) {
      env_->DeleteWeakGlobalRef(obj_);
    }
    obj_ = nullptr;
  }

 private:
  JNIEnv* env_ = nullptr;
  jweak obj_ = nullptr;
};

inline bool CheckException(JNIEnv* env) {
  if (!env) {
    return true;
  }
  if (env->ExceptionCheck() == JNI_FALSE) {
    return true;
  }
  env->ExceptionDescribe();
  env->ExceptionClear();
  return false;
}

inline std::string JavaStringToString(JNIEnv* env, jstring str) {
  if (!env || !str) {
    return "";
  }
  const char* chars = env->GetStringUTFChars(str, nullptr);
  if (!chars) {
    return "";
  }
  std::string result(chars);
  env->ReleaseStringUTFChars(str, chars);
  return result;
}

inline ScopedJavaLocalRef<jstring> StringToJavaString(JNIEnv* env,
                                                      const std::string& str) {
  if (!env) {
    return ScopedJavaLocalRef<jstring>();
  }
  return ScopedJavaLocalRef<jstring>(env, env->NewStringUTF(str.c_str()));
}

inline std::vector<std::string> StringArrayToVector(JNIEnv* env,
                                                    jobjectArray array) {
  std::vector<std::string> out;
  if (!env || !array) {
    return out;
  }
  jsize length = env->GetArrayLength(array);
  out.reserve(length);
  for (jsize i = 0; i < length; ++i) {
    jstring jstr = static_cast<jstring>(env->GetObjectArrayElement(array, i));
    if (jstr) {
      out.push_back(JavaStringToString(env, jstr));
      env->DeleteLocalRef(jstr);
    } else {
      out.emplace_back("");
    }
  }
  return out;
}

inline ScopedJavaLocalRef<jobjectArray> VectorToStringArray(
    JNIEnv* env,
    const std::vector<std::string>& vector) {
  if (!env) {
    return ScopedJavaLocalRef<jobjectArray>();
  }
  jclass string_clazz = env->FindClass("java/lang/String");
  jobjectArray joa = env->NewObjectArray(vector.size(), string_clazz, nullptr);
  for (size_t i = 0; i < vector.size(); ++i) {
    jstring item = env->NewStringUTF(vector[i].c_str());
    env->SetObjectArrayElement(joa, i, item);
    if (item) {
      env->DeleteLocalRef(item);
    }
  }
  if (string_clazz) {
    env->DeleteLocalRef(string_clazz);
  }
  return ScopedJavaLocalRef<jobjectArray>(env, joa);
}

inline std::vector<float> FloatArrayToVector(JNIEnv* env, jfloatArray array) {
  std::vector<float> out;
  if (!env || !array) {
    return out;
  }
  jsize length = env->GetArrayLength(array);
  out.resize(length);
  env->GetFloatArrayRegion(array, 0, length, out.data());
  return out;
}

}  // namespace jni
}  // namespace fml
#endif  // FML_OS_ANDROID

namespace flutter {

class JvmInvoker {
 public:
  explicit JvmInvoker(JNIEnv* env = nullptr, jobject flutter_jni = nullptr);
  ~JvmInvoker();

  void AttachToJava(JNIEnv* env, jobject flutter_jni);
  void DetachFromJava();

  bool Attach(JNIEnv* env, jobject flutter_jni) {
    AttachToJava(env, flutter_jni);
    return true;
  }
  void Detach() { DetachFromJava(); }

  bool IsAttached() const;

  void AsyncWaitForVsync(int64_t baton);

  void HandlePlatformMessage(const std::string& channel,
                             const uint8_t* data,
                             size_t data_size,
                             int32_t response_id,
                             int64_t message_data = 0);

  void HandlePlatformMessageResponse(int32_t response_id,
                                     const uint8_t* data,
                                     size_t data_size);

  void InvokePlatformMessageEmptyResponseCallback(int32_t response_id) {
    HandlePlatformMessageResponse(response_id, nullptr, 0);
  }

  void InvokePlatformMessageResponseCallback(int32_t response_id,
                                             const uint8_t* data,
                                             size_t data_size) {
    HandlePlatformMessageResponse(response_id, data, data_size);
  }

  void UpdateSemantics(JNIEnv* env,
                       jobject buffer,
                       jobjectArray strings,
                       jobjectArray string_Attribute_args);
  void UpdateSemantics(
      const std::vector<uint8_t>& buffer,
      const std::vector<std::string>& strings,
      const std::vector<std::vector<uint8_t>>& string_attribute_args);
  void UpdateCustomAccessibilityActions(
      const std::vector<uint8_t>& buffer,
      const std::vector<std::string>& strings);
  void SetApplicationLocale(const std::string& locale);
  void SetSemanticsTreeEnabled(bool enabled);

  std::unique_ptr<std::vector<std::string>> ComputePlatformResolvedLocale(
      const std::vector<std::string>& supported_locales_data);

  void OnFirstFrame();
  void OnEngineRestart();
  void OnPreEngineRestart() { OnEngineRestart(); }

  void CreatePlatformView(int32_t view_id,
                          const std::string& view_type,
                          double width,
                          double height,
                          int32_t direction,
                          const std::vector<uint8_t>& params);

  void DisposePlatformView(int32_t view_id);
  void OffsetPlatformView(int32_t view_id, double top, double left);
  void ResizePlatformView(int32_t view_id, double width, double height);
  void OnPlatformViewDisplay(int32_t view_id,
                             int32_t x,
                             int32_t y,
                             int32_t width,
                             int32_t height,
                             int32_t original_width,
                             int32_t original_height,
                             int32_t mutators_count,
                             const std::vector<int32_t>& mutators_types,
                             const std::vector<float>& mutators_matrices,
                             const std::vector<int32_t>& mutators_rects,
                             const std::vector<float>& mutators_rrects,
                             const std::vector<float>& mutators_opacities);
  void OnDisplayPlatformView2(int32_t view_id,
                              int32_t x,
                              int32_t y,
                              int32_t width,
                              int32_t height,
                              int32_t original_width,
                              int32_t original_height,
                              int32_t mutators_count,
                              const std::vector<int32_t>& mutators_types,
                              const std::vector<float>& mutators_matrices,
                              const std::vector<int32_t>& mutators_rects,
                              const std::vector<float>& mutators_rrects,
                              const std::vector<float>& mutators_opacities);

  void HidePlatformView2(int32_t view_id);

  jobject CreateOverlaySurface();
  jobject CreateOverlaySurface2();
  void DestroyOverlaySurfaces();
  void DestroyOverlaySurface2();
  void ShowOverlaySurface2();
  void HideOverlaySurface2();

  void OnBeginFrame();
  void OnEndFrame();
  void EndFrame2();

  double GetScaledFontSize(double unscaled_font_size, int32_t configuration_id);

  bool RequestDartDeferredLibrary(int32_t loading_unit_id);

  bool SurfaceTextureShouldUpdate(jobject surface_texture_wrapper);
  void SurfaceTextureAttachToGLContext(jobject surface_texture_wrapper,
                                       int32_t texture_id);
  void SurfaceTextureUpdateTexImage(jobject surface_texture_wrapper);
  void SurfaceTextureGetTransformMatrix(jobject surface_texture_wrapper,
                                        float transform_matrix[16]);
  void SurfaceTextureDetachFromGLContext(jobject surface_texture_wrapper);

  jobject ImageTextureEntryAcquireLatestImage(jobject image_texture_entry);
  jobject ImageGetHardwareBuffer(jobject image);
  void ImageClose(jobject image);
  void HardwareBufferClose(jobject hardware_buffer);

  static bool RegisterMethodIds(JNIEnv* env);

  JNIEnv* GetEnv() const;
  fml::jni::ScopedJavaLocalRef<jobject> GetFlutterJni(JNIEnv* env) const;

 private:
  JNIEnv* test_env_ = nullptr;
  fml::jni::JavaObjectWeakGlobalRef java_object_;

  FML_DISALLOW_COPY_AND_ASSIGN(JvmInvoker);
};

// Dynamic library loader abstraction for Android NDK symbols and unit testing.
class OSLibrary {
 public:
  virtual ~OSLibrary() = default;
  virtual void* ResolveSymbol(const char* symbol_name) = 0;
};

class OSLibraryLoader {
 public:
  virtual ~OSLibraryLoader() = default;
  virtual std::unique_ptr<OSLibrary> Load(const std::string& library_name) = 0;
};

class DefaultOSLibrary : public OSLibrary {
 public:
  explicit DefaultOSLibrary(void* handle);
  ~DefaultOSLibrary() override;

  void* ResolveSymbol(const char* symbol_name) override;

 private:
  void* handle_ = nullptr;
};

class DefaultOSLibraryLoader : public OSLibraryLoader {
 public:
  DefaultOSLibraryLoader() = default;
  ~DefaultOSLibraryLoader() override = default;

  std::unique_ptr<OSLibrary> Load(const std::string& library_name) override;
};

class MockOSLibrary : public OSLibrary {
 public:
  MockOSLibrary() = default;
  ~MockOSLibrary() override = default;

  void RegisterSymbol(const std::string& symbol_name, void* address);
  void* ResolveSymbol(const char* symbol_name) override;

 private:
  std::unordered_map<std::string, void*> symbols_;
};

class MockOSLibraryLoader : public OSLibraryLoader {
 public:
  MockOSLibraryLoader() = default;
  ~MockOSLibraryLoader() override = default;

  void RegisterLibrary(const std::string& library_name,
                       std::shared_ptr<MockOSLibrary> library);
  std::unique_ptr<OSLibrary> Load(const std::string& library_name) override;

 private:
  std::unordered_map<std::string, std::shared_ptr<MockOSLibrary>> libraries_;
};

// Vulkan eligibility and device owner abstractions for Android C-API embedder.
enum class VulkanIneligibleReason {
  kEligible = 0,
  kApiLevelTooLow,
  kNoVulkanHardware,
  kKnownBadGpuDriver,
  kExtensionMissing,
  kImpellerDisabled,
  kForceOpenGLES,
};

struct DeviceProperties {
  int api_level = 0;
  std::string hardware;
  std::string manufacturer;
  std::string model;
  std::string gpu_vendor;
  std::string gpu_renderer;
  std::string gpu_driver_version;
  uint32_t vulkan_api_version = 0;
  bool has_external_memory_android_hardware_buffer = false;
  bool has_semaphore_fd = false;
  bool impeller_enabled = true;
  bool force_opengles = false;
};

using PropertyReader = std::function<std::string(const char* key)>;
DeviceProperties ReadDeviceProperties(PropertyReader reader = nullptr);
VulkanIneligibleReason CheckVulkanEligibility(const DeviceProperties& props);
const char* VulkanIneligibleReasonToString(VulkanIneligibleReason reason);

using VkInstanceHandle = void*;
using VkPhysicalDeviceHandle = void*;
using VkDeviceHandle = void*;
using VkQueueHandle = void*;

class VulkanQueueGuard {
 public:
  explicit VulkanQueueGuard(std::mutex& mutex) : lock_(mutex) {}
  ~VulkanQueueGuard() = default;

  VulkanQueueGuard(const VulkanQueueGuard&) = delete;
  VulkanQueueGuard& operator=(const VulkanQueueGuard&) = delete;

 private:
  std::unique_lock<std::mutex> lock_;
};

class VulkanDeviceOwner {
 public:
  struct Config {
    uint32_t api_version = 0;
    bool enable_validation = false;
    std::vector<std::string> instance_extensions;
    std::vector<std::string> device_extensions;
  };

  struct MockDriverCallbacks {
    std::function<bool(const Config&,
                       VkInstanceHandle*,
                       VkPhysicalDeviceHandle*,
                       VkDeviceHandle*,
                       VkQueueHandle*,
                       uint32_t*)>
        initialize_fn;
    std::function<void(VkInstanceHandle, VkDeviceHandle)> destroy_fn;
    std::function<void*(VkInstanceHandle, const char*)> get_instance_proc_addr;
    std::function<void*(VkDeviceHandle, const char*)> get_device_proc_addr;
  };

  static std::unique_ptr<VulkanDeviceOwner> Create(
      const Config& config,
      std::optional<MockDriverCallbacks> mock_callbacks = std::nullopt);

  ~VulkanDeviceOwner();

  bool IsValid() const { return is_valid_; }

  VkInstanceHandle GetInstance() const { return instance_; }
  VkPhysicalDeviceHandle GetPhysicalDevice() const { return physical_device_; }
  VkDeviceHandle GetDevice() const { return device_; }
  VkQueueHandle GetQueue() const { return queue_; }
  uint32_t GetQueueFamilyIndex() const { return queue_family_index_; }

  VulkanQueueGuard AcquireQueueLock() { return VulkanQueueGuard(queue_mutex_); }

  void* GetInstanceProcAddr(const char* name) const;
  void* GetDeviceProcAddr(const char* name) const;

 private:
  VulkanDeviceOwner(const Config& config,
                    std::optional<MockDriverCallbacks> mock_callbacks);

  bool Initialize(const Config& config);

  bool is_valid_ = false;
  VkInstanceHandle instance_ = nullptr;
  VkPhysicalDeviceHandle physical_device_ = nullptr;
  VkDeviceHandle device_ = nullptr;
  VkQueueHandle queue_ = nullptr;
  uint32_t queue_family_index_ = 0;

  mutable std::mutex queue_mutex_;
  std::optional<MockDriverCallbacks> mock_callbacks_;

  FML_DISALLOW_COPY_AND_ASSIGN(VulkanDeviceOwner);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_JVM_INVOKER_H_
