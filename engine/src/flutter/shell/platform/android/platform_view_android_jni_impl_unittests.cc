// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gmock/gmock.h"
#include "gtest/gtest.h"

#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/fml/platform/android/jni_weak_ref.h"
#include "flutter/fml/platform/android/scoped_java_ref.h"
#include "flutter/lib/ui/window/platform_configuration.h"
#include "flutter/runtime/platform_data.h"
#include "flutter/runtime/runtime_controller.h"
#include "flutter/shell/common/engine.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/platform/android/android_shell_holder.h"
#include "flutter/shell/platform/android/jni/jni_mock.h"
#include "flutter/shell/platform/android/jni/mock_jni_env.h"
#include "flutter/shell/platform/android/platform_view_android.h"
#include "flutter/shell/platform/android/platform_view_android_jni_impl.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"

namespace flutter {
namespace testing {

using ::testing::_;
using ::testing::ElementsAre;
using ::testing::Return;
using ::testing::ReturnArg;

class PlatformViewAndroidJNIImplTest : public ::testing::Test {
 public:
  static void SetUpTestSuite() {
    static std::once_flag jvm_init_flag;
    std::call_once(jvm_init_flag, SetUpJVM);
  }

 private:
  friend class MockJNIEnvProvider;
  static MockJavaVM jvm_;
  static void SetUpJVM();
};

MockJavaVM PlatformViewAndroidJNIImplTest::jvm_;

class MockJNIEnvProvider {
 public:
  MockJNIEnvProvider() {
    PlatformViewAndroidJNIImplTest::jvm_.SetJNIEnv(&env_);
  }
  ~MockJNIEnvProvider() {
    PlatformViewAndroidJNIImplTest::jvm_.SetJNIEnv(nullptr);
  }
  MockJNIEnv& env() { return env_; }

 private:
  MockJNIEnv env_;
};

void PlatformViewAndroidJNIImplTest::SetUpJVM() {
  fml::jni::InitJavaVM(&jvm_);

  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();

  const jclass kPlaceholderClass = reinterpret_cast<jclass>(100);
  const jfieldID kPlaceholderFieldID = reinterpret_cast<jfieldID>(200);
  const jmethodID kPlaceholderMethodID = reinterpret_cast<jmethodID>(300);

  EXPECT_CALL(mock_env, GetObjectRefType(_))
      .WillRepeatedly(Return(JNILocalRefType));
  EXPECT_CALL(mock_env, NewLocalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteLocalRef(_)).WillRepeatedly(Return());
  EXPECT_CALL(mock_env, NewGlobalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteGlobalRef(_)).WillRepeatedly(Return());
  EXPECT_CALL(mock_env, FindClass(_)).WillRepeatedly(Return(kPlaceholderClass));
  EXPECT_CALL(mock_env, GetFieldID(_, _, _))
      .WillRepeatedly(Return(kPlaceholderFieldID));
  EXPECT_CALL(mock_env, GetMethodID(_, _, _))
      .WillRepeatedly(Return(kPlaceholderMethodID));
  EXPECT_CALL(mock_env, GetStaticFieldID(_, _, _))
      .WillRepeatedly(Return(kPlaceholderFieldID));
  EXPECT_CALL(mock_env, GetStaticMethodID(_, _, _))
      .WillRepeatedly(Return(kPlaceholderMethodID));
  EXPECT_CALL(mock_env, ExceptionCheck()).WillRepeatedly(Return(JNI_FALSE));
  EXPECT_CALL(mock_env, RegisterNatives(_, _, _)).WillRepeatedly(Return(0));

  PlatformViewAndroid::Register(&mock_env);
}

TEST_F(PlatformViewAndroidJNIImplTest, ImageGetHardwareBufferException) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();

  // Call ImageGetHardwareBuffer and simulate throwing an exception.
  // Verify that it clears the exception and does not abort the process.
  EXPECT_CALL(mock_env, GetObjectRefType(_))
      .WillRepeatedly(Return(JNILocalRefType));
  EXPECT_CALL(mock_env, NewLocalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteLocalRef(_)).WillRepeatedly(Return());
  EXPECT_CALL(mock_env, CallObjectMethodV(_, _, _))
      .WillRepeatedly(Return(nullptr));
  EXPECT_CALL(mock_env, ExceptionCheck()).WillOnce(Return(JNI_TRUE));
  EXPECT_CALL(mock_env, ExceptionDescribe()).WillOnce(Return());
  EXPECT_CALL(mock_env, ExceptionClear()).Times(1).WillOnce(Return());

  fml::jni::JavaObjectWeakGlobalRef flutter_jni_object;
  PlatformViewAndroidJNIImpl android_jni(flutter_jni_object);

  fml::jni::ScopedJavaLocalRef<jobject> image(&mock_env,
                                              reinterpret_cast<jobject>(123));
  android_jni.ImageGetHardwareBuffer(image);
}

TEST_F(PlatformViewAndroidJNIImplTest, SetViewportMetricsEmptyArrays) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();

  typedef void (*SetViewportMetricsFn)(
      JNIEnv*, jobject, jlong, jfloat, jint, jint, jint, jint, jint, jint, jint,
      jint, jint, jint, jint, jint, jint, jint, jint, jintArray, jintArray,
      jintArray, jint, jint, jint, jint, jint, jint, jint, jint);

  SetViewportMetricsFn set_viewport_metrics = nullptr;

  const jclass kPlaceholderClass = reinterpret_cast<jclass>(100);
  const jfieldID kPlaceholderFieldID = reinterpret_cast<jfieldID>(200);
  const jmethodID kPlaceholderMethodID = reinterpret_cast<jmethodID>(300);

  EXPECT_CALL(mock_env, GetObjectRefType(_))
      .WillRepeatedly(Return(JNILocalRefType));
  EXPECT_CALL(mock_env, NewLocalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteLocalRef(_)).WillRepeatedly(Return());
  EXPECT_CALL(mock_env, NewGlobalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteGlobalRef(_)).WillRepeatedly(Return());
  EXPECT_CALL(mock_env, FindClass(_)).WillRepeatedly(Return(kPlaceholderClass));
  EXPECT_CALL(mock_env, GetFieldID(_, _, _))
      .WillRepeatedly(Return(kPlaceholderFieldID));
  EXPECT_CALL(mock_env, GetMethodID(_, _, _))
      .WillRepeatedly(Return(kPlaceholderMethodID));
  EXPECT_CALL(mock_env, GetStaticFieldID(_, _, _))
      .WillRepeatedly(Return(kPlaceholderFieldID));
  EXPECT_CALL(mock_env, GetStaticMethodID(_, _, _))
      .WillRepeatedly(Return(kPlaceholderMethodID));
  EXPECT_CALL(mock_env, ExceptionCheck()).WillRepeatedly(Return(JNI_FALSE));

  EXPECT_CALL(mock_env, RegisterNatives(_, _, _))
      .WillRepeatedly(
          [&](jclass clazz, const JNINativeMethod* methods, jint nMethods) {
            for (jint i = 0; i < nMethods; ++i) {
              if (strcmp(methods[i].name, "nativeSetViewportMetrics") == 0) {
                set_viewport_metrics =
                    reinterpret_cast<SetViewportMetricsFn>(methods[i].fnPtr);
              }
            }
            return 0;
          });

  PlatformViewAndroid::Register(&mock_env);

  ASSERT_NE(set_viewport_metrics, nullptr);

  EXPECT_CALL(mock_env, GetArrayLength(_)).WillRepeatedly(Return(0));
  EXPECT_CALL(mock_env, GetIntArrayRegion(_, _, _, _)).Times(0);

  Settings settings;
  settings.enable_software_rendering = false;
  auto jni = std::make_shared<JNIMock>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kImpellerOpenGLES);

  jobject jcaller = reinterpret_cast<jobject>(123);
  jintArray bounds = reinterpret_cast<jintArray>(456);
  jintArray type = reinterpret_cast<jintArray>(789);
  jintArray state = reinterpret_cast<jintArray>(1011);

  set_viewport_metrics(&mock_env, jcaller,
                       reinterpret_cast<jlong>(holder.get()), 1.0f, 100, 100, 0,
                       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, bounds, type, state,
                       0, 0, 0, 0, 0, 0, 0, 0);
}

namespace {

// Signatures of FlutterJNI natives registered by PlatformViewAndroid::Register.
using SetSemanticsEnabledFn = void (*)(JNIEnv*, jobject, jlong, jboolean);
using SetAccessibilityFeaturesFn = void (*)(JNIEnv*, jobject, jlong, jint);
using ScheduleFrameFn = void (*)(JNIEnv*, jobject, jlong);

// Runs PlatformViewAndroid::Register against |mock_env| and returns the
// function registered for the FlutterJNI native called |name|, or nullptr.
void* RegisterNativesAndFind(MockJNIEnv& mock_env, const char* name) {
  // Arbitrary non-null handles. The mock env never dereferences them.
  const jclass kPlaceholderClass = reinterpret_cast<jclass>(100);
  const jfieldID kPlaceholderFieldID = reinterpret_cast<jfieldID>(200);
  const jmethodID kPlaceholderMethodID = reinterpret_cast<jmethodID>(300);

  EXPECT_CALL(mock_env, GetObjectRefType(_))
      .WillRepeatedly(Return(JNILocalRefType));
  EXPECT_CALL(mock_env, NewLocalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteLocalRef(_)).WillRepeatedly(Return());
  EXPECT_CALL(mock_env, NewGlobalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteGlobalRef(_)).WillRepeatedly(Return());
  EXPECT_CALL(mock_env, FindClass(_)).WillRepeatedly(Return(kPlaceholderClass));
  EXPECT_CALL(mock_env, GetFieldID(_, _, _))
      .WillRepeatedly(Return(kPlaceholderFieldID));
  EXPECT_CALL(mock_env, GetMethodID(_, _, _))
      .WillRepeatedly(Return(kPlaceholderMethodID));
  EXPECT_CALL(mock_env, GetStaticFieldID(_, _, _))
      .WillRepeatedly(Return(kPlaceholderFieldID));
  EXPECT_CALL(mock_env, GetStaticMethodID(_, _, _))
      .WillRepeatedly(Return(kPlaceholderMethodID));
  EXPECT_CALL(mock_env, ExceptionCheck()).WillRepeatedly(Return(JNI_FALSE));

  void* found = nullptr;
  EXPECT_CALL(mock_env, RegisterNatives(_, _, _))
      .WillRepeatedly(
          [&](jclass clazz, const JNINativeMethod* methods, jint nMethods) {
            for (jint i = 0; i < nMethods; ++i) {
              if (strcmp(methods[i].name, name) == 0) {
                found = methods[i].fnPtr;
              }
            }
            return 0;
          });

  PlatformViewAndroid::Register(&mock_env);
  return found;
}

// The PlatformData held by the holder's runtime controller.
//
// Only valid on the UI thread. AndroidShellHolder merges the platform and UI
// threads by default (Settings::merged_platform_ui_thread), and the platform
// thread is the thread that created the holder, so in these tests the UI
// thread is the test thread. Shell applies semantics and accessibility updates
// with RunNowAndFlushMessages, so they are visible as soon as the native
// returns.
const PlatformData& RuntimePlatformData(const AndroidShellHolder& holder) {
  return holder.GetShellForTesting()
      ->GetEngine()
      ->GetRuntimeController()
      ->GetPlatformData();
}

std::unique_ptr<AndroidShellHolder> CreateHolderWithMergedThreads() {
  Settings settings;
  settings.enable_software_rendering = false;
  EXPECT_EQ(settings.merged_platform_ui_thread,
            Settings::MergedPlatformUIThread::kEnabled);
  return std::make_unique<AndroidShellHolder>(
      settings, std::make_shared<JNIMock>(),
      AndroidRenderingAPI::kImpellerOpenGLES);
}

}  // namespace

TEST_F(PlatformViewAndroidJNIImplTest,
       SetSemanticsEnabledUpdatesRuntimePlatformData) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto set_semantics_enabled = reinterpret_cast<SetSemanticsEnabledFn>(
      RegisterNativesAndFind(mock_env, "nativeSetSemanticsEnabled"));
  ASSERT_NE(set_semantics_enabled, nullptr);

  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());
  const jlong shell_holder = reinterpret_cast<jlong>(holder.get());
  jobject jcaller = reinterpret_cast<jobject>(123);

  EXPECT_FALSE(RuntimePlatformData(*holder).semantics_enabled);

  set_semantics_enabled(&mock_env, jcaller, shell_holder, JNI_TRUE);
  EXPECT_TRUE(RuntimePlatformData(*holder).semantics_enabled);

  set_semantics_enabled(&mock_env, jcaller, shell_holder, JNI_FALSE);
  EXPECT_FALSE(RuntimePlatformData(*holder).semantics_enabled);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       SetAccessibilityFeaturesUpdatesRuntimePlatformData) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto set_accessibility_features =
      reinterpret_cast<SetAccessibilityFeaturesFn>(
          RegisterNativesAndFind(mock_env, "nativeSetAccessibilityFeatures"));
  ASSERT_NE(set_accessibility_features, nullptr);

  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());
  const jlong shell_holder = reinterpret_cast<jlong>(holder.get());
  jobject jcaller = reinterpret_cast<jobject>(123);

  EXPECT_EQ(RuntimePlatformData(*holder).accessibility_feature_flags_, 0);

  // The flags AccessibilityBridge sends with animations off, bold text and
  // high contrast, the same values Java packs in
  // AccessibilityBridge.AccessibilityFeature.
  const int32_t flags =
      static_cast<int32_t>(AccessibilityFeatureFlag::kDisableAnimations) |
      static_cast<int32_t>(AccessibilityFeatureFlag::kBoldText) |
      static_cast<int32_t>(AccessibilityFeatureFlag::kHighContrast);
  set_accessibility_features(&mock_env, jcaller, shell_holder, flags);
  EXPECT_EQ(RuntimePlatformData(*holder).accessibility_feature_flags_, flags);

  set_accessibility_features(&mock_env, jcaller, shell_holder, 0);
  EXPECT_EQ(RuntimePlatformData(*holder).accessibility_feature_flags_, 0);
}

// The natives below must reach the engine only through the holder's embedder
// API proc table. Each test replaces the proc with a mock that does not
// forward, so the runtime state must stay unchanged while the mock records
// the call. The tests above cover the same natives with the real procs.

TEST_F(PlatformViewAndroidJNIImplTest, SetSemanticsEnabledCallsEmbedderApi) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto set_semantics_enabled = reinterpret_cast<SetSemanticsEnabledFn>(
      RegisterNativesAndFind(mock_env, "nativeSetSemanticsEnabled"));
  ASSERT_NE(set_semantics_enabled, nullptr);

  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());
  std::vector<bool> calls;
  holder->GetEmbedderApiForTesting().UpdateSemanticsEnabled = MOCK_ENGINE_PROC(
      UpdateSemanticsEnabled,
      ([&calls](FLUTTER_API_SYMBOL(FlutterEngine) engine, bool enabled) {
        EXPECT_NE(engine, nullptr);
        calls.push_back(enabled);
        return kSuccess;
      }));

  set_semantics_enabled(&mock_env, reinterpret_cast<jobject>(123),
                        reinterpret_cast<jlong>(holder.get()), JNI_TRUE);

  EXPECT_THAT(calls, ElementsAre(true));
  EXPECT_FALSE(RuntimePlatformData(*holder).semantics_enabled);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       SetAccessibilityFeaturesCallsEmbedderApi) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto set_accessibility_features =
      reinterpret_cast<SetAccessibilityFeaturesFn>(
          RegisterNativesAndFind(mock_env, "nativeSetAccessibilityFeatures"));
  ASSERT_NE(set_accessibility_features, nullptr);

  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());
  std::vector<int32_t> calls;
  holder->GetEmbedderApiForTesting().UpdateAccessibilityFeatures =
      MOCK_ENGINE_PROC(UpdateAccessibilityFeatures,
                       ([&calls](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                 FlutterAccessibilityFeature features) {
                         EXPECT_NE(engine, nullptr);
                         calls.push_back(static_cast<int32_t>(features));
                         return kSuccess;
                       }));

  const int32_t flags =
      static_cast<int32_t>(AccessibilityFeatureFlag::kDisableAnimations) |
      static_cast<int32_t>(AccessibilityFeatureFlag::kBoldText);
  set_accessibility_features(&mock_env, reinterpret_cast<jobject>(123),
                             reinterpret_cast<jlong>(holder.get()), flags);

  EXPECT_THAT(calls, ElementsAre(flags));
  EXPECT_EQ(RuntimePlatformData(*holder).accessibility_feature_flags_, 0);
}

TEST_F(PlatformViewAndroidJNIImplTest, ScheduleFrameCallsEmbedderApi) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto schedule_frame = reinterpret_cast<ScheduleFrameFn>(
      RegisterNativesAndFind(mock_env, "nativeScheduleFrame"));
  ASSERT_NE(schedule_frame, nullptr);

  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());
  int calls = 0;
  holder->GetEmbedderApiForTesting().ScheduleFrame = MOCK_ENGINE_PROC(
      ScheduleFrame, ([&calls](FLUTTER_API_SYMBOL(FlutterEngine) engine) {
        EXPECT_NE(engine, nullptr);
        calls++;
        return kSuccess;
      }));

  schedule_frame(&mock_env, reinterpret_cast<jobject>(123),
                 reinterpret_cast<jlong>(holder.get()));

  EXPECT_EQ(calls, 1);
}

// The load order is exercised with an injected loader rather than real
// dlopen(): the property under test is purely the ordering (first-to-last,
// stop at the first that loads), and a fake loader makes that deterministic
// and free of any platform- or system-library-specific behavior. Whether a
// given path format is actually loadable is covered end-to-end by
// dev/integration_tests/deferred_components_test.
TEST(FindFirstLoadableLibraryTest, TriesInOrderAndStopsAtFirstSuccess) {
  std::vector<std::string> attempted;
  void* const handle = reinterpret_cast<void*>(0x1234);
  auto opener = [&](const std::string& path) -> void* {
    attempted.push_back(path);
    return path == "b" ? handle : nullptr;
  };
  EXPECT_EQ(FindFirstLoadableLibrary({"a", "b", "c"}, opener), handle);
  // "c" is never attempted because "b" already loaded.
  EXPECT_THAT(attempted, ElementsAre("a", "b"));
}

TEST(FindFirstLoadableLibraryTest, TriesAllAndReturnsNullWhenNoneLoad) {
  std::vector<std::string> attempted;
  auto opener = [&](const std::string& path) -> void* {
    attempted.push_back(path);
    return nullptr;
  };
  EXPECT_EQ(FindFirstLoadableLibrary({"a", "b"}, opener), nullptr);
  EXPECT_THAT(attempted, ElementsAre("a", "b"));
}

TEST(FindFirstLoadableLibraryTest, EmptyReturnsNull) {
  EXPECT_EQ(FindFirstLoadableLibrary(
                {}, [](const std::string&) -> void* { return nullptr; }),
            nullptr);
}

}  // namespace testing
}  // namespace flutter
