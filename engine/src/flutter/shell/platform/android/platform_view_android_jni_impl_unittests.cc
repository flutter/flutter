// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <android/looper.h>

#include "gmock/gmock.h"
#include "gtest/gtest.h"

#include "flutter/fml/file.h"
#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/fml/platform/android/jni_weak_ref.h"
#include "flutter/fml/platform/android/scoped_java_ref.h"
#include "flutter/lib/ui/window/platform_configuration.h"
#include "flutter/runtime/platform_data.h"
#include "flutter/runtime/runtime_controller.h"
#include "flutter/shell/common/engine.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/platform/android/android_image_generator.h"
#include "flutter/shell/platform/android/android_shell_holder.h"
#include "flutter/shell/platform/android/flutter_main.h"
#include "flutter/shell/platform/android/jni/jni_mock.h"
#include "flutter/shell/platform/android/jni/mock_jni_env.h"
#include "flutter/shell/platform/android/platform_view_android.h"
#include "flutter/shell/platform/android/platform_view_android_jni_impl.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/embedder_engine.h"
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
using DispatchPlatformMessageFn =
    void (*)(JNIEnv*, jobject, jlong, jstring, jobject, jint, jint);
using DispatchEmptyPlatformMessageFn =
    void (*)(JNIEnv*, jobject, jlong, jstring, jint);
using DispatchPointerDataPacketFn =
    void (*)(JNIEnv*, jobject, jlong, jobject, jint);
using RegisterTextureFn = void (*)(JNIEnv*, jobject, jlong, jlong, jobject);
using RegisterImageTextureFn =
    void (*)(JNIEnv*, jobject, jlong, jlong, jobject, jboolean);
using UnregisterTextureFn = void (*)(JNIEnv*, jobject, jlong, jlong);
using MarkTextureFrameAvailableFn = void (*)(JNIEnv*, jobject, jlong, jlong);
using SurfaceCreatedFn = void (*)(JNIEnv*, jobject, jlong, jobject);
using SurfaceWindowChangedFn = void (*)(JNIEnv*, jobject, jlong, jobject);
using SurfaceChangedFn = void (*)(JNIEnv*, jobject, jlong, jint, jint);
using SurfaceDestroyedFn = void (*)(JNIEnv*, jobject, jlong);
using UpdateDisplayMetricsFn = void (*)(JNIEnv*, jobject, jlong);
using NotifyLowMemoryWarningFn = void (*)(JNIEnv*, jobject, jlong);
using SetViewportMetricsFn = void (*)(JNIEnv*,
                                      jobject,
                                      jlong,
                                      jfloat,
                                      jint,
                                      jint,
                                      jint,
                                      jint,
                                      jint,
                                      jint,
                                      jint,
                                      jint,
                                      jint,
                                      jint,
                                      jint,
                                      jint,
                                      jint,
                                      jint,
                                      jint,
                                      jintArray,
                                      jintArray,
                                      jintArray,
                                      jint,
                                      jint,
                                      jint,
                                      jint,
                                      jint,
                                      jint,
                                      jint,
                                      jint);

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
  EXPECT_CALL(mock_env, PushLocalFrame(_)).WillRepeatedly(Return(0));
  EXPECT_CALL(mock_env, PopLocalFrame(_)).WillRepeatedly(Return(nullptr));
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

Shell* GetShellForTesting(const AndroidShellHolder& holder) {
  auto* engine =
      reinterpret_cast<EmbedderEngine*>(holder.GetEngineForTesting());
  return engine ? &engine->GetShell() : nullptr;
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
  return GetShellForTesting(holder)
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

TEST_F(PlatformViewAndroidJNIImplTest,
       SetViewportMetricsUpdatesRuntimePlatformData) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto set_viewport_metrics = reinterpret_cast<SetViewportMetricsFn>(
      RegisterNativesAndFind(mock_env, "nativeSetViewportMetrics"));
  ASSERT_NE(set_viewport_metrics, nullptr);

  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());
  const jlong shell_holder = reinterpret_cast<jlong>(holder.get());
  jobject jcaller = reinterpret_cast<jobject>(123);
  jintArray bounds = reinterpret_cast<jintArray>(456);
  jintArray type = reinterpret_cast<jintArray>(789);
  jintArray state = reinterpret_cast<jintArray>(1011);

  constexpr jint kFeatureBounds[4] = {10, 20, 30, 40};
  constexpr jint kFeatureTypes[1] = {kFlutterDisplayFeatureTypeHinge};
  constexpr jint kFeatureStates[1] = {
      kFlutterDisplayFeatureStatePostureHalfOpened};

  EXPECT_CALL(mock_env, GetArrayLength(bounds)).WillOnce(Return(4));
  EXPECT_CALL(mock_env, GetIntArrayRegion(bounds, 0, 4, _))
      .WillOnce([&](jintArray, jsize, jsize, jint* buf) {
        std::copy(std::begin(kFeatureBounds), std::end(kFeatureBounds), buf);
      });
  EXPECT_CALL(mock_env, GetArrayLength(type)).WillOnce(Return(1));
  EXPECT_CALL(mock_env, GetIntArrayRegion(type, 0, 1, _))
      .WillOnce([&](jintArray, jsize, jsize, jint* buf) {
        buf[0] = kFeatureTypes[0];
      });
  EXPECT_CALL(mock_env, GetArrayLength(state)).WillOnce(Return(1));
  EXPECT_CALL(mock_env, GetIntArrayRegion(state, 0, 1, _))
      .WillOnce([&](jintArray, jsize, jsize, jint* buf) {
        buf[0] = kFeatureStates[0];
      });

  set_viewport_metrics(&mock_env, jcaller, shell_holder,
                       /*devicePixelRatio=*/2.5f,
                       /*physicalWidth=*/1080,
                       /*physicalHeight=*/1920,
                       /*physicalPaddingTop=*/48,
                       /*physicalPaddingRight=*/12,
                       /*physicalPaddingBottom=*/36,
                       /*physicalPaddingLeft=*/8,
                       /*physicalViewInsetTop=*/0,
                       /*physicalViewInsetRight=*/0,
                       /*physicalViewInsetBottom=*/600,
                       /*physicalViewInsetLeft=*/0,
                       /*systemGestureInsetTop=*/48,
                       /*systemGestureInsetRight=*/24,
                       /*systemGestureInsetBottom=*/64,
                       /*systemGestureInsetLeft=*/24,
                       /*physicalTouchSlop=*/16,
                       /*javaDisplayFeaturesBounds=*/bounds,
                       /*javaDisplayFeaturesType=*/type,
                       /*javaDisplayFeaturesState=*/state,
                       /*physicalMinWidth=*/800,
                       /*physicalMaxWidth=*/1400,
                       /*physicalMinHeight=*/1600,
                       /*physicalMaxHeight=*/2400,
                       /*physicalDisplayCornerRadiusTopLeft=*/32,
                       /*physicalDisplayCornerRadiusTopRight=*/32,
                       /*physicalDisplayCornerRadiusBottomRight=*/16,
                       /*physicalDisplayCornerRadiusBottomLeft=*/16);

  const auto& views = RuntimePlatformData(*holder).viewport_metrics_for_views;
  auto it = views.find(0);
  ASSERT_NE(it, views.end());
  const ViewportMetrics& actual = it->second;
  EXPECT_DOUBLE_EQ(actual.device_pixel_ratio, 2.5);
  EXPECT_DOUBLE_EQ(actual.physical_width, 1080.0);
  EXPECT_DOUBLE_EQ(actual.physical_height, 1920.0);
  EXPECT_DOUBLE_EQ(actual.physical_min_width_constraint, 800.0);
  EXPECT_DOUBLE_EQ(actual.physical_max_width_constraint, 1400.0);
  EXPECT_DOUBLE_EQ(actual.physical_min_height_constraint, 1600.0);
  EXPECT_DOUBLE_EQ(actual.physical_max_height_constraint, 2400.0);
  EXPECT_DOUBLE_EQ(actual.physical_padding_top, 48.0);
  EXPECT_DOUBLE_EQ(actual.physical_padding_right, 12.0);
  EXPECT_DOUBLE_EQ(actual.physical_padding_bottom, 36.0);
  EXPECT_DOUBLE_EQ(actual.physical_padding_left, 8.0);
  EXPECT_DOUBLE_EQ(actual.physical_view_inset_top, 0.0);
  EXPECT_DOUBLE_EQ(actual.physical_view_inset_right, 0.0);
  EXPECT_DOUBLE_EQ(actual.physical_view_inset_bottom, 600.0);
  EXPECT_DOUBLE_EQ(actual.physical_view_inset_left, 0.0);
  EXPECT_DOUBLE_EQ(actual.physical_system_gesture_inset_top, 48.0);
  EXPECT_DOUBLE_EQ(actual.physical_system_gesture_inset_right, 24.0);
  EXPECT_DOUBLE_EQ(actual.physical_system_gesture_inset_bottom, 64.0);
  EXPECT_DOUBLE_EQ(actual.physical_system_gesture_inset_left, 24.0);
  EXPECT_DOUBLE_EQ(actual.physical_touch_slop, 16.0);
  EXPECT_THAT(actual.physical_display_features_bounds,
              ElementsAre(10.0, 20.0, 30.0, 40.0));
  EXPECT_THAT(actual.physical_display_features_type,
              ElementsAre(kFlutterDisplayFeatureTypeHinge));
  EXPECT_THAT(actual.physical_display_features_state,
              ElementsAre(kFlutterDisplayFeatureStatePostureHalfOpened));
  EXPECT_DOUBLE_EQ(actual.physical_display_corner_radius_top_left, 32.0);
  EXPECT_DOUBLE_EQ(actual.physical_display_corner_radius_top_right, 32.0);
  EXPECT_DOUBLE_EQ(actual.physical_display_corner_radius_bottom_right, 16.0);
  EXPECT_DOUBLE_EQ(actual.physical_display_corner_radius_bottom_left, 16.0);
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

TEST_F(PlatformViewAndroidJNIImplTest, SetViewportMetricsCallsEmbedderApi) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto set_viewport_metrics = reinterpret_cast<SetViewportMetricsFn>(
      RegisterNativesAndFind(mock_env, "nativeSetViewportMetrics"));
  ASSERT_NE(set_viewport_metrics, nullptr);

  EXPECT_CALL(mock_env, GetArrayLength(_)).WillRepeatedly(Return(0));

  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());
  std::vector<FlutterWindowMetricsEvent> calls;
  holder->GetEmbedderApiForTesting().SendWindowMetricsEvent =
      MOCK_ENGINE_PROC(SendWindowMetricsEvent,
                       ([&calls](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                 const FlutterWindowMetricsEvent* event) {
                         EXPECT_NE(engine, nullptr);
                         EXPECT_NE(event, nullptr);
                         calls.push_back(*event);
                         return kSuccess;
                       }));

  set_viewport_metrics(&mock_env, reinterpret_cast<jobject>(123),
                       reinterpret_cast<jlong>(holder.get()),
                       /*devicePixelRatio=*/3.0f,
                       /*physicalWidth=*/1440,
                       /*physicalHeight=*/2560,
                       /*physicalPaddingTop=*/60,
                       /*physicalPaddingRight=*/0,
                       /*physicalPaddingBottom=*/40,
                       /*physicalPaddingLeft=*/0,
                       /*physicalViewInsetTop=*/0,
                       /*physicalViewInsetRight=*/0,
                       /*physicalViewInsetBottom=*/500,
                       /*physicalViewInsetLeft=*/0,
                       /*systemGestureInsetTop=*/60,
                       /*systemGestureInsetRight=*/30,
                       /*systemGestureInsetBottom=*/80,
                       /*systemGestureInsetLeft=*/30,
                       /*physicalTouchSlop=*/24,
                       /*javaDisplayFeaturesBounds=*/
                       reinterpret_cast<jintArray>(456),
                       /*javaDisplayFeaturesType=*/
                       reinterpret_cast<jintArray>(789),
                       /*javaDisplayFeaturesState=*/
                       reinterpret_cast<jintArray>(1011),
                       /*physicalMinWidth=*/0,
                       /*physicalMaxWidth=*/0,
                       /*physicalMinHeight=*/0,
                       /*physicalMaxHeight=*/0,
                       /*physicalDisplayCornerRadiusTopLeft=*/20,
                       /*physicalDisplayCornerRadiusTopRight=*/20,
                       /*physicalDisplayCornerRadiusBottomRight=*/20,
                       /*physicalDisplayCornerRadiusBottomLeft=*/20);

  ASSERT_EQ(calls.size(), 1u);
  EXPECT_EQ(calls[0].width, 1440u);
  EXPECT_EQ(calls[0].height, 2560u);
  EXPECT_DOUBLE_EQ(calls[0].pixel_ratio, 3.0);
  EXPECT_TRUE(calls[0].has_constraints);
  EXPECT_EQ(calls[0].min_width_constraint, 1440u);
  EXPECT_EQ(calls[0].max_width_constraint, 1440u);
  EXPECT_EQ(calls[0].min_height_constraint, 2560u);
  EXPECT_EQ(calls[0].max_height_constraint, 2560u);
  EXPECT_TRUE(calls[0].has_extended_metrics);
  EXPECT_DOUBLE_EQ(calls[0].physical_padding_top, 60.0);
  EXPECT_DOUBLE_EQ(calls[0].physical_padding_bottom, 40.0);
  EXPECT_DOUBLE_EQ(calls[0].physical_view_inset_bottom, 500.0);
  EXPECT_DOUBLE_EQ(calls[0].physical_system_gesture_inset_right, 30.0);
  EXPECT_DOUBLE_EQ(calls[0].physical_touch_slop, 24.0);
  EXPECT_DOUBLE_EQ(calls[0].physical_display_corner_radius_top_left, 20.0);
  EXPECT_DOUBLE_EQ(RuntimePlatformData(*holder)
                       .viewport_metrics_for_views.at(0)
                       .physical_width,
                   0.0);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       DispatchPlatformMessageCallsEmbedderApi) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto dispatch_platform_message = reinterpret_cast<DispatchPlatformMessageFn>(
      RegisterNativesAndFind(mock_env, "nativeDispatchPlatformMessage"));
  ASSERT_NE(dispatch_platform_message, nullptr);

  const std::u16string kChannelU16 = u"test/channel";
  jstring jchannel = reinterpret_cast<jstring>(2001);
  jobject jbuffer = reinterpret_cast<jobject>(2002);
  uint8_t payload[4] = {10, 20, 30, 40};

  EXPECT_CALL(mock_env, GetStringChars(jchannel, _))
      .WillRepeatedly(
          Return(reinterpret_cast<const jchar*>(kChannelU16.data())));
  EXPECT_CALL(mock_env, GetStringLength(jchannel))
      .WillRepeatedly(Return(static_cast<jsize>(kChannelU16.size())));
  EXPECT_CALL(mock_env, ReleaseStringChars(jchannel, _))
      .WillRepeatedly(Return());
  EXPECT_CALL(mock_env, GetDirectBufferAddress(jbuffer))
      .WillRepeatedly(Return(payload));

  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());

  struct CapturedMessage {
    std::string channel;
    bool data_non_null = false;
    std::vector<uint8_t> bytes;
    bool has_response_handle = false;
  };
  std::vector<CapturedMessage> calls;
  holder->GetEmbedderApiForTesting().SendPlatformMessage = MOCK_ENGINE_PROC(
      SendPlatformMessage, ([&calls](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                     const FlutterPlatformMessage* message) {
        EXPECT_NE(engine, nullptr);
        EXPECT_NE(message, nullptr);
        CapturedMessage captured;
        captured.channel = message->channel ? message->channel : "";
        captured.data_non_null = (message->message != nullptr);
        if (message->message != nullptr && message->message_size > 0) {
          captured.bytes.assign(message->message,
                                message->message + message->message_size);
        }
        captured.has_response_handle = (message->response_handle != nullptr);
        calls.push_back(std::move(captured));
        return kSuccess;
      }));

  // 1. Non-empty payload without response.
  dispatch_platform_message(&mock_env, reinterpret_cast<jobject>(123),
                            reinterpret_cast<jlong>(holder.get()), jchannel,
                            jbuffer, /*position=*/4, /*responseId=*/0);
  // 2. Zero-byte payload without response (must pass non-null message pointer
  // so Dart receives ByteData(0) rather than null).
  dispatch_platform_message(&mock_env, reinterpret_cast<jobject>(123),
                            reinterpret_cast<jlong>(holder.get()), jchannel,
                            jbuffer, /*position=*/0, /*responseId=*/0);

  ASSERT_EQ(calls.size(), 2u);
  EXPECT_EQ(calls[0].channel, "test/channel");
  EXPECT_TRUE(calls[0].data_non_null);
  EXPECT_THAT(calls[0].bytes, ElementsAre(10, 20, 30, 40));
  EXPECT_FALSE(calls[0].has_response_handle);

  EXPECT_EQ(calls[1].channel, "test/channel");
  EXPECT_TRUE(calls[1].data_non_null);
  EXPECT_TRUE(calls[1].bytes.empty());
  EXPECT_FALSE(calls[1].has_response_handle);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       DispatchEmptyPlatformMessageCallsEmbedderApi) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto dispatch_empty_message =
      reinterpret_cast<DispatchEmptyPlatformMessageFn>(RegisterNativesAndFind(
          mock_env, "nativeDispatchEmptyPlatformMessage"));
  ASSERT_NE(dispatch_empty_message, nullptr);

  const std::u16string kChannelU16 = u"test/empty";
  jstring jchannel = reinterpret_cast<jstring>(2003);
  EXPECT_CALL(mock_env, GetStringChars(jchannel, _))
      .WillRepeatedly(
          Return(reinterpret_cast<const jchar*>(kChannelU16.data())));
  EXPECT_CALL(mock_env, GetStringLength(jchannel))
      .WillRepeatedly(Return(static_cast<jsize>(kChannelU16.size())));
  EXPECT_CALL(mock_env, ReleaseStringChars(jchannel, _))
      .WillRepeatedly(Return());

  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());

  bool called = false;
  holder->GetEmbedderApiForTesting().SendPlatformMessage = MOCK_ENGINE_PROC(
      SendPlatformMessage, ([&called](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                      const FlutterPlatformMessage* message) {
        EXPECT_NE(engine, nullptr);
        EXPECT_NE(message, nullptr);
        EXPECT_STREQ(message->channel, "test/empty");
        EXPECT_EQ(message->message, nullptr);
        EXPECT_EQ(message->message_size, 0u);
        EXPECT_EQ(message->response_handle, nullptr);
        called = true;
        return kSuccess;
      }));

  dispatch_empty_message(&mock_env, reinterpret_cast<jobject>(123),
                         reinterpret_cast<jlong>(holder.get()), jchannel,
                         /*responseId=*/0);
  EXPECT_TRUE(called);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       DispatchPlatformMessageWithResponseForwardsReplyToJniFacade) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto dispatch_empty_message =
      reinterpret_cast<DispatchEmptyPlatformMessageFn>(RegisterNativesAndFind(
          mock_env, "nativeDispatchEmptyPlatformMessage"));
  ASSERT_NE(dispatch_empty_message, nullptr);

  const std::u16string kChannelU16 = u"test/reply";
  jstring jchannel = reinterpret_cast<jstring>(2004);
  EXPECT_CALL(mock_env, GetStringChars(jchannel, _))
      .WillRepeatedly(
          Return(reinterpret_cast<const jchar*>(kChannelU16.data())));
  EXPECT_CALL(mock_env, GetStringLength(jchannel))
      .WillRepeatedly(Return(static_cast<jsize>(kChannelU16.size())));
  EXPECT_CALL(mock_env, ReleaseStringChars(jchannel, _))
      .WillRepeatedly(Return());

  Settings settings;
  settings.enable_software_rendering = false;
  auto jni = std::make_shared<JNIMock>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kImpellerOpenGLES);
  ASSERT_TRUE(holder->IsValid());

  struct CapturedResponse {
    FlutterDataCallback callback = nullptr;
    void* user_data = nullptr;
    FlutterPlatformMessageResponseHandle* fake_handle = nullptr;
    bool released = false;
  };
  std::vector<CapturedResponse> responses;

  holder->GetEmbedderApiForTesting().PlatformMessageCreateResponseHandle =
      MOCK_ENGINE_PROC(
          PlatformMessageCreateResponseHandle,
          ([&responses](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                        FlutterDataCallback data_callback, void* user_data,
                        FlutterPlatformMessageResponseHandle** response_out) {
            EXPECT_NE(engine, nullptr);
            EXPECT_NE(data_callback, nullptr);
            EXPECT_NE(response_out, nullptr);
            auto* fake =
                reinterpret_cast<FlutterPlatformMessageResponseHandle*>(
                    static_cast<uintptr_t>(0x5000 + responses.size() + 1));
            *response_out = fake;
            responses.push_back({data_callback, user_data, fake, false});
            return kSuccess;
          }));

  holder->GetEmbedderApiForTesting().SendPlatformMessage = MOCK_ENGINE_PROC(
      SendPlatformMessage,
      ([&responses](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                    const FlutterPlatformMessage* message) {
        EXPECT_NE(engine, nullptr);
        EXPECT_NE(message, nullptr);
        EXPECT_FALSE(responses.empty());
        EXPECT_EQ(message->response_handle, responses.back().fake_handle);
        return kSuccess;
      }));

  holder->GetEmbedderApiForTesting().PlatformMessageReleaseResponseHandle =
      MOCK_ENGINE_PROC(
          PlatformMessageReleaseResponseHandle,
          ([&responses](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                        FlutterPlatformMessageResponseHandle* response) {
            EXPECT_NE(engine, nullptr);
            for (auto& entry : responses) {
              if (entry.fake_handle == response) {
                entry.released = true;
              }
            }
            return kSuccess;
          }));

  // Send 3 messages expecting responses: non-empty, 0-byte non-null, and null.
  dispatch_empty_message(&mock_env, reinterpret_cast<jobject>(123),
                         reinterpret_cast<jlong>(holder.get()), jchannel,
                         /*responseId=*/41);
  dispatch_empty_message(&mock_env, reinterpret_cast<jobject>(123),
                         reinterpret_cast<jlong>(holder.get()), jchannel,
                         /*responseId=*/42);
  dispatch_empty_message(&mock_env, reinterpret_cast<jobject>(123),
                         reinterpret_cast<jlong>(holder.get()), jchannel,
                         /*responseId=*/43);

  ASSERT_EQ(responses.size(), 3u);
  EXPECT_TRUE(responses[0].released);
  EXPECT_TRUE(responses[1].released);
  EXPECT_TRUE(responses[2].released);

  // 1. Non-empty response (responseId = 41).
  EXPECT_CALL(*jni, FlutterViewHandlePlatformMessageResponse(41, _))
      .WillOnce([](int, std::unique_ptr<fml::Mapping> data) {
        ASSERT_NE(data, nullptr);
        ASSERT_EQ(data->GetSize(), 3u);
        EXPECT_EQ(data->GetMapping()[0], 9);
        EXPECT_EQ(data->GetMapping()[1], 8);
        EXPECT_EQ(data->GetMapping()[2], 7);
      });
  const uint8_t kReplyBytes[3] = {9, 8, 7};
  responses[0].callback(kReplyBytes, sizeof(kReplyBytes),
                        responses[0].user_data);

  // 2. Zero-byte non-null response (responseId = 42).
  EXPECT_CALL(*jni, FlutterViewHandlePlatformMessageResponse(42, _))
      .WillOnce([](int, std::unique_ptr<fml::Mapping> data) {
        ASSERT_NE(data, nullptr);
        EXPECT_EQ(data->GetSize(), 0u);
      });
  static const uint8_t kEmptyByte = 0;
  responses[1].callback(&kEmptyByte, 0, responses[1].user_data);

  // 3. Null response (responseId = 43).
  EXPECT_CALL(*jni, FlutterViewHandlePlatformMessageResponse(43, _))
      .WillOnce([](int, std::unique_ptr<fml::Mapping> data) {
        EXPECT_EQ(data, nullptr);
      });
  responses[2].callback(nullptr, 0, responses[2].user_data);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       DispatchPlatformMessageRealProcsDoNotLeakUncompletedResponse) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto dispatch_platform_message = reinterpret_cast<DispatchPlatformMessageFn>(
      RegisterNativesAndFind(mock_env, "nativeDispatchPlatformMessage"));
  ASSERT_NE(dispatch_platform_message, nullptr);

  const std::u16string kChannelU16 = u"test/uncompleted";
  jstring jchannel = reinterpret_cast<jstring>(2005);
  jobject jbuffer = reinterpret_cast<jobject>(2006);
  uint8_t payload[2] = {1, 2};

  EXPECT_CALL(mock_env, GetStringChars(jchannel, _))
      .WillRepeatedly(
          Return(reinterpret_cast<const jchar*>(kChannelU16.data())));
  EXPECT_CALL(mock_env, GetStringLength(jchannel))
      .WillRepeatedly(Return(static_cast<jsize>(kChannelU16.size())));
  EXPECT_CALL(mock_env, ReleaseStringChars(jchannel, _))
      .WillRepeatedly(Return());
  EXPECT_CALL(mock_env, GetDirectBufferAddress(jbuffer))
      .WillRepeatedly(Return(payload));

  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());

  // The root isolate is not running, so the real response handle is created,
  // attached to the PlatformMessage, released, and dropped when the message is
  // not handled. Tearing down the holder must clean up its pending response
  // entry without leaking JNIMock.
  dispatch_platform_message(&mock_env, reinterpret_cast<jobject>(123),
                            reinterpret_cast<jlong>(holder.get()), jchannel,
                            jbuffer, /*position=*/2, /*responseId=*/99);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       DispatchPointerDataPacketUnpacksAndForwardsAllFieldsThroughEmbedderApi) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto dispatch_pointer_data_packet =
      reinterpret_cast<DispatchPointerDataPacketFn>(
          RegisterNativesAndFind(mock_env, "nativeDispatchPointerDataPacket"));
  ASSERT_NE(dispatch_pointer_data_packet, nullptr);

  PointerData records[2] = {};
  records[0].Clear();
  records[0].embedder_id = 77;
  records[0].time_stamp = 123456;
  records[0].change = PointerData::Change::kDown;
  records[0].kind = PointerData::DeviceKind::kStylus;
  records[0].signal_kind = PointerData::SignalKind::kNone;
  records[0].device = 3;
  records[0].physical_x = 12.5;
  records[0].physical_y = 34.5;
  records[0].buttons =
      kFlutterPointerButtonStylusContact | kFlutterPointerButtonStylusPrimary;
  records[0].pressure = 0.75;
  records[0].pressure_min = 0.1;
  records[0].pressure_max = 1.0;
  records[0].distance = 1.5;
  records[0].distance_max = 8.0;
  records[0].size = 0.4;
  records[0].radius_major = 6.0;
  records[0].radius_minor = 3.0;
  records[0].radius_min = 1.0;
  records[0].radius_max = 10.0;
  records[0].orientation = 0.25;
  records[0].tilt = 0.5;
  records[0].platformData = 101;
  records[0].scale = 1.0;
  records[0].view_id = 0;

  records[1].Clear();
  records[1].embedder_id = 78;
  records[1].time_stamp = 123789;
  records[1].change = PointerData::Change::kPanZoomUpdate;
  records[1].kind = PointerData::DeviceKind::kTrackpad;
  records[1].signal_kind = PointerData::SignalKind::kScroll;
  records[1].device = 4;
  records[1].physical_x = 50.0;
  records[1].physical_y = 60.0;
  records[1].scroll_delta_x = -4.0;
  records[1].scroll_delta_y = 8.0;
  records[1].pan_x = 15.0;
  records[1].pan_y = -25.0;
  records[1].scale = 1.25;
  records[1].rotation = 0.125;
  records[1].view_id = 2;

  jobject jbuffer = reinterpret_cast<jobject>(3001);
  EXPECT_CALL(mock_env, GetDirectBufferAddress(jbuffer))
      .WillRepeatedly(Return(records));

  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());

  std::vector<FlutterPointerEvent> captured;
  holder->GetEmbedderApiForTesting().SendPointerEvent = MOCK_ENGINE_PROC(
      SendPointerEvent,
      ([&captured](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                   const FlutterPointerEvent* events, size_t events_count) {
        EXPECT_NE(engine, nullptr);
        EXPECT_NE(events, nullptr);
        captured.assign(events, events + events_count);
        return kSuccess;
      }));

  dispatch_pointer_data_packet(&mock_env, reinterpret_cast<jobject>(123),
                               reinterpret_cast<jlong>(holder.get()), jbuffer,
                               static_cast<jint>(sizeof(records)));

  ASSERT_EQ(captured.size(), 2u);
  EXPECT_EQ(captured[0].struct_size, sizeof(FlutterPointerEvent));
  EXPECT_EQ(captured[0].embedder_id, 77);
  EXPECT_EQ(captured[0].timestamp, 123456u);
  EXPECT_EQ(captured[0].phase, FlutterPointerPhase::kDown);
  EXPECT_EQ(captured[0].device_kind, kFlutterPointerDeviceKindStylus);
  EXPECT_EQ(captured[0].signal_kind, kFlutterPointerSignalKindNone);
  EXPECT_EQ(captured[0].device, 3);
  EXPECT_DOUBLE_EQ(captured[0].x, 12.5);
  EXPECT_DOUBLE_EQ(captured[0].y, 34.5);
  EXPECT_EQ(captured[0].buttons, kFlutterPointerButtonStylusContact |
                                     kFlutterPointerButtonStylusPrimary);
  EXPECT_DOUBLE_EQ(captured[0].pressure, 0.75);
  EXPECT_DOUBLE_EQ(captured[0].pressure_min, 0.1);
  EXPECT_DOUBLE_EQ(captured[0].pressure_max, 1.0);
  EXPECT_DOUBLE_EQ(captured[0].distance, 1.5);
  EXPECT_DOUBLE_EQ(captured[0].distance_max, 8.0);
  EXPECT_DOUBLE_EQ(captured[0].size, 0.4);
  EXPECT_DOUBLE_EQ(captured[0].radius_major, 6.0);
  EXPECT_DOUBLE_EQ(captured[0].radius_minor, 3.0);
  EXPECT_DOUBLE_EQ(captured[0].radius_min, 1.0);
  EXPECT_DOUBLE_EQ(captured[0].radius_max, 10.0);
  EXPECT_DOUBLE_EQ(captured[0].orientation, 0.25);
  EXPECT_DOUBLE_EQ(captured[0].tilt, 0.5);
  EXPECT_EQ(captured[0].platform_data, 101);
  EXPECT_EQ(captured[0].view_id, 0);

  EXPECT_EQ(captured[1].struct_size, sizeof(FlutterPointerEvent));
  EXPECT_EQ(captured[1].embedder_id, 78);
  EXPECT_EQ(captured[1].timestamp, 123789u);
  EXPECT_EQ(captured[1].phase, FlutterPointerPhase::kPanZoomUpdate);
  EXPECT_EQ(captured[1].device_kind, kFlutterPointerDeviceKindTrackpad);
  EXPECT_EQ(captured[1].signal_kind, kFlutterPointerSignalKindScroll);
  EXPECT_EQ(captured[1].device, 4);
  EXPECT_DOUBLE_EQ(captured[1].x, 50.0);
  EXPECT_DOUBLE_EQ(captured[1].y, 60.0);
  EXPECT_DOUBLE_EQ(captured[1].scroll_delta_x, -4.0);
  EXPECT_DOUBLE_EQ(captured[1].scroll_delta_y, 8.0);
  EXPECT_DOUBLE_EQ(captured[1].pan_x, 15.0);
  EXPECT_DOUBLE_EQ(captured[1].pan_y, -25.0);
  EXPECT_DOUBLE_EQ(captured[1].scale, 1.25);
  EXPECT_DOUBLE_EQ(captured[1].rotation, 0.125);
  EXPECT_EQ(captured[1].view_id, 2);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       DispatchPointerDataPacketIgnoresNullEmptyOrTruncatedBuffers) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto dispatch_pointer_data_packet =
      reinterpret_cast<DispatchPointerDataPacketFn>(
          RegisterNativesAndFind(mock_env, "nativeDispatchPointerDataPacket"));
  ASSERT_NE(dispatch_pointer_data_packet, nullptr);

  PointerData record = {};
  record.Clear();
  jobject jbuffer = reinterpret_cast<jobject>(3002);
  jobject jnull_buffer = reinterpret_cast<jobject>(3003);
  EXPECT_CALL(mock_env, GetDirectBufferAddress(jbuffer))
      .WillRepeatedly(Return(&record));
  EXPECT_CALL(mock_env, GetDirectBufferAddress(jnull_buffer))
      .WillRepeatedly(Return(nullptr));

  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());

  bool called = false;
  holder->GetEmbedderApiForTesting().SendPointerEvent =
      MOCK_ENGINE_PROC(SendPointerEvent, ([&called](auto, auto, auto) {
                         called = true;
                         return kSuccess;
                       }));

  const jlong shell_holder = reinterpret_cast<jlong>(holder.get());
  jobject jcaller = reinterpret_cast<jobject>(123);

  dispatch_pointer_data_packet(&mock_env, jcaller, shell_holder, jbuffer, 0);
  dispatch_pointer_data_packet(&mock_env, jcaller, shell_holder, jbuffer, -1);
  dispatch_pointer_data_packet(&mock_env, jcaller, shell_holder, jbuffer,
                               static_cast<jint>(sizeof(PointerData) - 1));
  dispatch_pointer_data_packet(&mock_env, jcaller, shell_holder, jnull_buffer,
                               static_cast<jint>(sizeof(PointerData)));
  EXPECT_FALSE(called);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       DispatchPointerDataPacketRealProcForwardsToEngine) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto dispatch_pointer_data_packet =
      reinterpret_cast<DispatchPointerDataPacketFn>(
          RegisterNativesAndFind(mock_env, "nativeDispatchPointerDataPacket"));
  ASSERT_NE(dispatch_pointer_data_packet, nullptr);

  PointerData record = {};
  record.Clear();
  record.embedder_id = 55;
  record.time_stamp = 1000;
  record.change = PointerData::Change::kAdd;
  record.kind = PointerData::DeviceKind::kTouch;
  record.physical_x = 10.0;
  record.physical_y = 20.0;

  jobject jbuffer = reinterpret_cast<jobject>(3004);
  EXPECT_CALL(mock_env, GetDirectBufferAddress(jbuffer))
      .WillRepeatedly(Return(&record));

  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());

  dispatch_pointer_data_packet(&mock_env, reinterpret_cast<jobject>(123),
                               reinterpret_cast<jlong>(holder.get()), jbuffer,
                               static_cast<jint>(sizeof(record)));
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

namespace {

class TestAPKAssetProviderImpl : public APKAssetProviderInternal {
 public:
  explicit TestAPKAssetProviderImpl(std::string payload)
      : payload_(std::move(payload)) {}

  std::unique_ptr<fml::Mapping> GetAsMapping(
      const std::string& asset_name) const override {
    if (asset_name == "test_asset.txt") {
      return std::make_unique<fml::DataMapping>(payload_);
    }
    return nullptr;
  }

 private:
  std::string payload_;
};

}  // namespace

TEST_F(PlatformViewAndroidJNIImplTest,
       LoadDartDeferredLibraryCallsEmbedderApiAndCleansUp) {
  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());

  constexpr intptr_t kTestLoadingUnitId = 42;
  const std::string kDataBytes = "deferred_data";
  const std::string kInstrBytes = "deferred_instructions";

  bool called = false;
  holder->GetEmbedderApiForTesting().LoadDartDeferredLibrary = MOCK_ENGINE_PROC(
      LoadDartDeferredLibrary,
      ([&](FLUTTER_API_SYMBOL(FlutterEngine) engine,
           const FlutterDartDeferredLibrary* deferred_library) {
        EXPECT_NE(engine, nullptr);
        EXPECT_NE(deferred_library, nullptr);
        EXPECT_EQ(deferred_library->struct_size,
                  sizeof(FlutterDartDeferredLibrary));
        EXPECT_EQ(deferred_library->loading_unit_id, kTestLoadingUnitId);
        EXPECT_EQ(
            std::string(reinterpret_cast<const char*>(deferred_library->data),
                        deferred_library->data_size),
            kDataBytes);
        EXPECT_EQ(std::string(reinterpret_cast<const char*>(
                                  deferred_library->instructions),
                              deferred_library->instructions_size),
                  kInstrBytes);
        EXPECT_NE(deferred_library->destruction_callback, nullptr);
        deferred_library->destruction_callback(deferred_library->user_data);
        called = true;
        return kSuccess;
      }));

  holder->LoadDartDeferredLibrary(
      kTestLoadingUnitId, std::make_unique<fml::DataMapping>(kDataBytes),
      std::make_unique<fml::DataMapping>(kInstrBytes));
  EXPECT_TRUE(called);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       LoadDartDeferredLibraryErrorCallsEmbedderApi) {
  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());

  constexpr intptr_t kTestLoadingUnitId = 17;
  bool called = false;
  holder->GetEmbedderApiForTesting().NotifyDartDeferredLibraryLoadError =
      MOCK_ENGINE_PROC(NotifyDartDeferredLibraryLoadError,
                       ([&](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                            const FlutterDartDeferredLibraryLoadError* error) {
                         EXPECT_NE(engine, nullptr);
                         EXPECT_NE(error, nullptr);
                         EXPECT_EQ(error->struct_size,
                                   sizeof(FlutterDartDeferredLibraryLoadError));
                         EXPECT_EQ(error->loading_unit_id, kTestLoadingUnitId);
                         EXPECT_STREQ(error->error_message,
                                      "missing split APK");
                         EXPECT_TRUE(error->transient);
                         called = true;
                         return kSuccess;
                       }));

  holder->LoadDartDeferredLibraryError(kTestLoadingUnitId, "missing split APK",
                                       /*transient=*/true);
  EXPECT_TRUE(called);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       UpdateJavaAssetManagerCallsEmbedderApiAndResolvesAssets) {
  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());

  bool called = false;
  holder->GetEmbedderApiForTesting().UpdateAssetResolver = MOCK_ENGINE_PROC(
      UpdateAssetResolver,
      ([&](FLUTTER_API_SYMBOL(FlutterEngine) engine,
           const FlutterAssetResolverRegistrationInfo* info) {
        EXPECT_NE(engine, nullptr);
        EXPECT_NE(info, nullptr);
        EXPECT_EQ(info->struct_size,
                  sizeof(FlutterAssetResolverRegistrationInfo));
        EXPECT_NE(info->resolver, nullptr);
        FlutterAsset asset = {};
        EXPECT_TRUE(info->resolver->find_asset_callback(
            info->resolver->user_data, "test_asset.txt", &asset));
        EXPECT_EQ(
            std::string(reinterpret_cast<const char*>(asset.data), asset.size),
            "updated_asset_content");
        if (asset.asset_free_callback) {
          asset.asset_free_callback(asset.user_data);
        }
        if (info->resolver->destruction_callback) {
          info->resolver->destruction_callback(info->resolver->user_data);
        }
        called = true;
        return kSuccess;
      }));

  auto provider = std::make_unique<APKAssetProvider>(
      std::make_shared<TestAPKAssetProviderImpl>("updated_asset_content"));
  holder->UpdateJavaAssetManager(std::move(provider));
  EXPECT_TRUE(called);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       UpdateJavaAssetManagerRealProcForwardsToEngine) {
  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());

  auto asset_manager = std::make_shared<AssetManager>();
  asset_manager->PushBack(std::make_unique<APKAssetProvider>(
      std::make_shared<TestAPKAssetProviderImpl>("initial_asset")));
  GetShellForTesting(*holder)->GetEngine()->UpdateAssetManager(asset_manager);

  auto initial_mapping = asset_manager->GetAsMapping("test_asset.txt");
  ASSERT_NE(initial_mapping, nullptr);
  EXPECT_EQ(
      std::string(reinterpret_cast<const char*>(initial_mapping->GetMapping()),
                  initial_mapping->GetSize()),
      "initial_asset");

  auto provider = std::make_unique<APKAssetProvider>(
      std::make_shared<TestAPKAssetProviderImpl>("real_proc_asset"));
  holder->UpdateJavaAssetManager(std::move(provider));

  auto updated_mapping = asset_manager->GetAsMapping("test_asset.txt");
  ASSERT_NE(updated_mapping, nullptr);
  EXPECT_EQ(
      std::string(reinterpret_cast<const char*>(updated_mapping->GetMapping()),
                  updated_mapping->GetSize()),
      "real_proc_asset");
}

TEST_F(PlatformViewAndroidJNIImplTest,
       RegisterTextureCallsEmbedderApiIncludingZeroId) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto register_texture = reinterpret_cast<RegisterTextureFn>(
      RegisterNativesAndFind(mock_env, "nativeRegisterTexture"));
  ASSERT_NE(register_texture, nullptr);

  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());

  std::vector<int64_t> registered_ids;
  holder->GetEmbedderApiForTesting().RegisterExternalTexture = MOCK_ENGINE_PROC(
      RegisterExternalTexture,
      ([&registered_ids](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                         int64_t texture_identifier) {
        EXPECT_NE(engine, nullptr);
        registered_ids.push_back(texture_identifier);
        return kSuccess;
      }));

  const jlong shell_holder = reinterpret_cast<jlong>(holder.get());
  jobject jcaller = reinterpret_cast<jobject>(123);
  jobject jsurface_texture = reinterpret_cast<jobject>(4001);

  constexpr jlong kFirstTextureId = 0;
  constexpr jlong kSecondTextureId = 5;
  register_texture(&mock_env, jcaller, shell_holder, kFirstTextureId,
                   jsurface_texture);
  register_texture(&mock_env, jcaller, shell_holder, kSecondTextureId,
                   jsurface_texture);

  EXPECT_THAT(registered_ids, ElementsAre(kFirstTextureId, kSecondTextureId));
}

TEST_F(PlatformViewAndroidJNIImplTest, RegisterImageTextureCallsEmbedderApi) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto register_image_texture = reinterpret_cast<RegisterImageTextureFn>(
      RegisterNativesAndFind(mock_env, "nativeRegisterImageTexture"));
  ASSERT_NE(register_image_texture, nullptr);

  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());

  std::vector<int64_t> registered_ids;
  holder->GetEmbedderApiForTesting().RegisterExternalTexture = MOCK_ENGINE_PROC(
      RegisterExternalTexture,
      ([&registered_ids](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                         int64_t texture_identifier) {
        EXPECT_NE(engine, nullptr);
        registered_ids.push_back(texture_identifier);
        return kSuccess;
      }));

  const jlong shell_holder = reinterpret_cast<jlong>(holder.get());
  jobject jcaller = reinterpret_cast<jobject>(123);
  jobject jimage_entry = reinterpret_cast<jobject>(4002);

  constexpr jlong kKeepAliveTextureId = 0;
  constexpr jlong kResetTextureId = 1;
  register_image_texture(&mock_env, jcaller, shell_holder, kKeepAliveTextureId,
                         jimage_entry, JNI_FALSE);
  register_image_texture(&mock_env, jcaller, shell_holder, kResetTextureId,
                         jimage_entry, JNI_TRUE);

  EXPECT_THAT(registered_ids,
              ElementsAre(kKeepAliveTextureId, kResetTextureId));
}

TEST_F(PlatformViewAndroidJNIImplTest,
       UnregisterAndMarkTextureFrameAvailableCallEmbedderApi) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto mark_frame_available = reinterpret_cast<MarkTextureFrameAvailableFn>(
      RegisterNativesAndFind(mock_env, "nativeMarkTextureFrameAvailable"));
  auto unregister_texture = reinterpret_cast<UnregisterTextureFn>(
      RegisterNativesAndFind(mock_env, "nativeUnregisterTexture"));
  ASSERT_NE(mark_frame_available, nullptr);
  ASSERT_NE(unregister_texture, nullptr);

  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());

  std::vector<int64_t> marked_ids;
  std::vector<int64_t> unregistered_ids;
  holder->GetEmbedderApiForTesting().MarkExternalTextureFrameAvailable =
      MOCK_ENGINE_PROC(MarkExternalTextureFrameAvailable,
                       ([&marked_ids](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                      int64_t texture_identifier) {
                         EXPECT_NE(engine, nullptr);
                         marked_ids.push_back(texture_identifier);
                         return kSuccess;
                       }));
  holder->GetEmbedderApiForTesting().UnregisterExternalTexture =
      MOCK_ENGINE_PROC(
          UnregisterExternalTexture,
          ([&unregistered_ids](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                               int64_t texture_identifier) {
            EXPECT_NE(engine, nullptr);
            unregistered_ids.push_back(texture_identifier);
            return kSuccess;
          }));

  const jlong shell_holder = reinterpret_cast<jlong>(holder.get());
  jobject jcaller = reinterpret_cast<jobject>(123);

  constexpr jlong kZeroTextureId = 0;
  constexpr jlong kNonZeroTextureId = 9;
  mark_frame_available(&mock_env, jcaller, shell_holder, kZeroTextureId);
  mark_frame_available(&mock_env, jcaller, shell_holder, kNonZeroTextureId);
  unregister_texture(&mock_env, jcaller, shell_holder, kZeroTextureId);
  unregister_texture(&mock_env, jcaller, shell_holder, kNonZeroTextureId);

  EXPECT_THAT(marked_ids, ElementsAre(kZeroTextureId, kNonZeroTextureId));
  EXPECT_THAT(unregistered_ids, ElementsAre(kZeroTextureId, kNonZeroTextureId));
}

TEST_F(PlatformViewAndroidJNIImplTest,
       RegisterMarkAndUnregisterTextureRealProcsForwardToEngine) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto register_texture = reinterpret_cast<RegisterTextureFn>(
      RegisterNativesAndFind(mock_env, "nativeRegisterTexture"));
  auto register_image_texture = reinterpret_cast<RegisterImageTextureFn>(
      RegisterNativesAndFind(mock_env, "nativeRegisterImageTexture"));
  auto mark_frame_available = reinterpret_cast<MarkTextureFrameAvailableFn>(
      RegisterNativesAndFind(mock_env, "nativeMarkTextureFrameAvailable"));
  auto unregister_texture = reinterpret_cast<UnregisterTextureFn>(
      RegisterNativesAndFind(mock_env, "nativeUnregisterTexture"));
  ASSERT_NE(register_texture, nullptr);
  ASSERT_NE(register_image_texture, nullptr);
  ASSERT_NE(mark_frame_available, nullptr);
  ASSERT_NE(unregister_texture, nullptr);

  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());

  const jlong shell_holder = reinterpret_cast<jlong>(holder.get());
  jobject jcaller = reinterpret_cast<jobject>(123);
  jobject jsurface_texture = reinterpret_cast<jobject>(4003);
  jobject jimage_entry = reinterpret_cast<jobject>(4004);

  // Android's FlutterRenderer starts assigning texture IDs at 0.
  constexpr jlong kSurfaceTextureId = 0;
  constexpr jlong kImageTextureId = 1;
  register_texture(&mock_env, jcaller, shell_holder, kSurfaceTextureId,
                   jsurface_texture);
  register_image_texture(&mock_env, jcaller, shell_holder, kImageTextureId,
                         jimage_entry, JNI_FALSE);
  mark_frame_available(&mock_env, jcaller, shell_holder, kSurfaceTextureId);
  mark_frame_available(&mock_env, jcaller, shell_holder, kImageTextureId);
  unregister_texture(&mock_env, jcaller, shell_holder, kSurfaceTextureId);
  unregister_texture(&mock_env, jcaller, shell_holder, kImageTextureId);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       SurfaceCreatedCallsEmbedderApiAndFirstFrameCallback) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto surface_created = reinterpret_cast<SurfaceCreatedFn>(
      RegisterNativesAndFind(mock_env, "nativeSurfaceCreated"));
  ASSERT_NE(surface_created, nullptr);

  Settings settings;
  settings.enable_software_rendering = false;
  auto jni = std::make_shared<JNIMock>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kImpellerOpenGLES);
  ASSERT_TRUE(holder->IsValid());

  VoidCallback captured_first_frame_callback = nullptr;
  void* captured_first_frame_user_data = nullptr;
  int notify_created_calls = 0;

  holder->GetEmbedderApiForTesting().SetNextFrameCallback = MOCK_ENGINE_PROC(
      SetNextFrameCallback, ([&](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                 VoidCallback callback, void* user_data) {
        EXPECT_NE(engine, nullptr);
        EXPECT_NE(callback, nullptr);
        captured_first_frame_callback = callback;
        captured_first_frame_user_data = user_data;
        return kSuccess;
      }));
  holder->GetEmbedderApiForTesting().NotifyCreated = MOCK_ENGINE_PROC(
      NotifyCreated, ([&](FLUTTER_API_SYMBOL(FlutterEngine) engine) {
        EXPECT_NE(engine, nullptr);
        notify_created_calls++;
        return kSuccess;
      }));

  surface_created(&mock_env, reinterpret_cast<jobject>(123),
                  reinterpret_cast<jlong>(holder.get()),
                  /*jsurface=*/nullptr);

  EXPECT_EQ(notify_created_calls, 1);
  ASSERT_NE(captured_first_frame_callback, nullptr);

  EXPECT_CALL(*jni, FlutterViewOnFirstFrame()).Times(1);
  captured_first_frame_callback(captured_first_frame_user_data);
  // Poll the current thread's ALooper with a zero-millisecond timeout to drain
  // the posted platform task without blocking.
  constexpr int kImmediatePollTimeoutMs = 0;
  ALooper_pollOnce(kImmediatePollTimeoutMs, nullptr, nullptr, nullptr);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       FirstFrameCallbackDroppedIfHolderDestroyedBeforePlatformTaskRuns) {
  Settings settings;
  settings.enable_software_rendering = false;
  auto jni = std::make_shared<JNIMock>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kImpellerOpenGLES);
  ASSERT_TRUE(holder->IsValid());

  VoidCallback captured_first_frame_callback = nullptr;
  void* captured_first_frame_user_data = nullptr;

  holder->GetEmbedderApiForTesting().SetNextFrameCallback = MOCK_ENGINE_PROC(
      SetNextFrameCallback, ([&](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                 VoidCallback callback, void* user_data) {
        captured_first_frame_callback = callback;
        captured_first_frame_user_data = user_data;
        return kSuccess;
      }));
  holder->GetEmbedderApiForTesting().NotifyCreated = MOCK_ENGINE_PROC(
      NotifyCreated,
      ([](FLUTTER_API_SYMBOL(FlutterEngine) engine) { return kSuccess; }));

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  holder->NotifySurfaceCreated(window);
  ASSERT_NE(captured_first_frame_callback, nullptr);

  // Fire the render-thread callback (which posts to the platform task runner),
  // then destroy the holder before the platform task runs.
  EXPECT_CALL(*jni, FlutterViewOnFirstFrame()).Times(0);
  captured_first_frame_callback(captured_first_frame_user_data);
  holder.reset();
  // Poll the current thread's ALooper with a zero-millisecond timeout to drain
  // the posted platform task and verify the WeakPtr guard drops it safely.
  constexpr int kImmediatePollTimeoutMs = 0;
  ALooper_pollOnce(kImmediatePollTimeoutMs, nullptr, nullptr, nullptr);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       SurfaceWindowChangedChangedAndDestroyedCallEmbedderApi) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto surface_window_changed = reinterpret_cast<SurfaceWindowChangedFn>(
      RegisterNativesAndFind(mock_env, "nativeSurfaceWindowChanged"));
  auto surface_changed = reinterpret_cast<SurfaceChangedFn>(
      RegisterNativesAndFind(mock_env, "nativeSurfaceChanged"));
  auto surface_destroyed = reinterpret_cast<SurfaceDestroyedFn>(
      RegisterNativesAndFind(mock_env, "nativeSurfaceDestroyed"));
  ASSERT_NE(surface_window_changed, nullptr);
  ASSERT_NE(surface_changed, nullptr);
  ASSERT_NE(surface_destroyed, nullptr);

  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithMergedThreads();
  ASSERT_TRUE(holder->IsValid());

  int schedule_frame_calls = 0;
  int notify_destroyed_calls = 0;
  holder->GetEmbedderApiForTesting().ScheduleFrame = MOCK_ENGINE_PROC(
      ScheduleFrame, ([&](FLUTTER_API_SYMBOL(FlutterEngine) engine) {
        EXPECT_NE(engine, nullptr);
        schedule_frame_calls++;
        return kSuccess;
      }));
  holder->GetEmbedderApiForTesting().NotifyDestroyed = MOCK_ENGINE_PROC(
      NotifyDestroyed, ([&](FLUTTER_API_SYMBOL(FlutterEngine) engine) {
        EXPECT_NE(engine, nullptr);
        notify_destroyed_calls++;
        return kSuccess;
      }));

  const jlong shell_holder = reinterpret_cast<jlong>(holder.get());
  jobject jcaller = reinterpret_cast<jobject>(123);

  surface_window_changed(&mock_env, jcaller, shell_holder,
                         /*jsurface=*/nullptr);
  EXPECT_EQ(schedule_frame_calls, 1);

  constexpr jint kSurfaceWidth = 720;
  constexpr jint kSurfaceHeight = 1280;
  surface_changed(&mock_env, jcaller, shell_holder, kSurfaceWidth,
                  kSurfaceHeight);

  surface_destroyed(&mock_env, jcaller, shell_holder);
  EXPECT_EQ(notify_destroyed_calls, 1);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       SurfaceLifecycleRealProcsForwardToEngine) {
  // Use the software rendering backend so that the real NotifyCreated proc can
  // construct a valid rendering surface on the raster thread without requiring
  // a live ANativeWindow backed by an EGL surface on physical devices.
  Settings settings;
  settings.enable_software_rendering = true;
  settings.enable_impeller = false;
  auto jni = std::make_shared<JNIMock>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kSoftware);
  ASSERT_TRUE(holder->IsValid());

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/false);
  holder->NotifySurfaceCreated(window);
  constexpr int kSurfaceWidth = 480;
  constexpr int kSurfaceHeight = 800;
  holder->NotifySurfaceChanged(kSurfaceWidth, kSurfaceHeight);
  holder->NotifySurfaceWindowChanged(window);
  holder->NotifySurfaceDestroyed();
}

TEST_F(PlatformViewAndroidJNIImplTest,
       UpdateDisplayMetricsCallsEmbedderNotifyDisplayUpdate) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto update_display_metrics = reinterpret_cast<UpdateDisplayMetricsFn>(
      RegisterNativesAndFind(mock_env, "nativeUpdateDisplayMetrics"));
  ASSERT_NE(update_display_metrics, nullptr);

  Settings settings;
  settings.enable_software_rendering = false;
  auto jni = std::make_shared<JNIMock>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kImpellerOpenGLES);
  ASSERT_TRUE(holder->IsValid());

  constexpr double kRefreshRateHz = 120.0;
  constexpr double kDisplayWidthPx = 1080.0;
  constexpr double kDisplayHeightPx = 2400.0;
  constexpr double kDisplayDensity = 2.75;
  EXPECT_CALL(*jni, GetDisplayRefreshRate()).WillOnce(Return(kRefreshRateHz));
  EXPECT_CALL(*jni, GetDisplayWidth()).WillOnce(Return(kDisplayWidthPx));
  EXPECT_CALL(*jni, GetDisplayHeight()).WillOnce(Return(kDisplayHeightPx));
  EXPECT_CALL(*jni, GetDisplayDensity()).WillOnce(Return(kDisplayDensity));

  FlutterEngineDisplaysUpdateType captured_update_type =
      static_cast<FlutterEngineDisplaysUpdateType>(-1);
  std::vector<FlutterEngineDisplay> captured_displays;

  holder->GetEmbedderApiForTesting().NotifyDisplayUpdate = MOCK_ENGINE_PROC(
      NotifyDisplayUpdate,
      ([&](FLUTTER_API_SYMBOL(FlutterEngine) engine,
           FlutterEngineDisplaysUpdateType update_type,
           const FlutterEngineDisplay* displays, size_t display_count) {
        EXPECT_NE(engine, nullptr);
        captured_update_type = update_type;
        if (displays != nullptr) {
          captured_displays.assign(displays, displays + display_count);
        }
        return kSuccess;
      }));

  update_display_metrics(&mock_env, reinterpret_cast<jobject>(123),
                         reinterpret_cast<jlong>(holder.get()));

  EXPECT_EQ(captured_update_type, kFlutterEngineDisplaysUpdateTypeStartup);
  ASSERT_EQ(captured_displays.size(), 1u);
  EXPECT_EQ(captured_displays[0].struct_size, sizeof(FlutterEngineDisplay));
  EXPECT_EQ(captured_displays[0].display_id, 0u);
  EXPECT_TRUE(captured_displays[0].single_display);
  EXPECT_DOUBLE_EQ(captured_displays[0].refresh_rate, kRefreshRateHz);
  EXPECT_EQ(captured_displays[0].width, static_cast<size_t>(kDisplayWidthPx));
  EXPECT_EQ(captured_displays[0].height, static_cast<size_t>(kDisplayHeightPx));
  EXPECT_DOUBLE_EQ(captured_displays[0].device_pixel_ratio, kDisplayDensity);

  // Verify negative sentinel values (-1.0 when Java object is absent) are
  // clamped to 0.0 before conversion.
  constexpr double kMissingJavaObjectSentinel = -1.0;
  EXPECT_CALL(*jni, GetDisplayRefreshRate())
      .WillOnce(Return(kUnknownDisplayRefreshRate));
  EXPECT_CALL(*jni, GetDisplayWidth())
      .WillOnce(Return(kMissingJavaObjectSentinel));
  EXPECT_CALL(*jni, GetDisplayHeight())
      .WillOnce(Return(kMissingJavaObjectSentinel));
  EXPECT_CALL(*jni, GetDisplayDensity())
      .WillOnce(Return(kMissingJavaObjectSentinel));

  captured_displays.clear();
  holder->UpdateDisplayMetrics();
  ASSERT_EQ(captured_displays.size(), 1u);
  EXPECT_EQ(captured_displays[0].width, 0u);
  EXPECT_EQ(captured_displays[0].height, 0u);
  EXPECT_DOUBLE_EQ(captured_displays[0].device_pixel_ratio, 0.0);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       UpdateDisplayMetricsRealProcForwardsToEngine) {
  Settings settings;
  settings.enable_software_rendering = false;
  auto jni = std::make_shared<JNIMock>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kImpellerOpenGLES);
  ASSERT_TRUE(holder->IsValid());

  constexpr double kRefreshRateHz = 90.0;
  constexpr double kDisplayWidthPx = 1440.0;
  constexpr double kDisplayHeightPx = 3120.0;
  constexpr double kDisplayDensity = 3.5;
  EXPECT_CALL(*jni, GetDisplayRefreshRate()).WillOnce(Return(kRefreshRateHz));
  EXPECT_CALL(*jni, GetDisplayWidth()).WillOnce(Return(kDisplayWidthPx));
  EXPECT_CALL(*jni, GetDisplayHeight()).WillOnce(Return(kDisplayHeightPx));
  EXPECT_CALL(*jni, GetDisplayDensity()).WillOnce(Return(kDisplayDensity));

  holder->UpdateDisplayMetrics();
  EXPECT_DOUBLE_EQ(GetShellForTesting(*holder)->GetMainDisplayRefreshRate(),
                   kRefreshRateHz);
  ASSERT_EQ(RuntimePlatformData(*holder).displays.size(), 1u);
  EXPECT_DOUBLE_EQ(RuntimePlatformData(*holder).displays[0].refresh_rate,
                   kRefreshRateHz);
  EXPECT_DOUBLE_EQ(RuntimePlatformData(*holder).displays[0].width,
                   kDisplayWidthPx);
  EXPECT_DOUBLE_EQ(RuntimePlatformData(*holder).displays[0].height,
                   kDisplayHeightPx);
  EXPECT_DOUBLE_EQ(RuntimePlatformData(*holder).displays[0].pixel_ratio,
                   kDisplayDensity);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       PlatformViewEmbedderHandlePlatformMessageForwardsToAndroidHandler) {
  Settings settings;
  settings.enable_software_rendering = false;
  auto jni = std::make_shared<JNIMock>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kImpellerOpenGLES);
  ASSERT_TRUE(holder->IsValid());
  ASSERT_NE(holder->GetPlatformMessageHandler(), nullptr);
  EXPECT_EQ(holder->GetPlatformMessageHandler(),
            holder->GetPlatformView()->GetPlatformMessageHandler());

  std::string captured_channel;
  EXPECT_CALL(*jni, FlutterViewHandlePlatformMessage(_, _))
      .WillOnce([&](std::unique_ptr<flutter::PlatformMessage> message,
                    int response_id) {
        ASSERT_NE(message, nullptr);
        captured_channel = message->channel();
        EXPECT_GT(response_id, 0);
      });

  PlatformView* platform_view = holder->GetPlatformView().get();
  ASSERT_NE(platform_view, nullptr);
  platform_view->HandlePlatformMessage(
      std::make_unique<flutter::PlatformMessage>(
          "flutter/test_embedder_forward", nullptr));
  EXPECT_EQ(captured_channel, "flutter/test_embedder_forward");
}

TEST_F(PlatformViewAndroidJNIImplTest, NotifyLowMemoryWarningCallsEmbedderApi) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto notify_low_memory = reinterpret_cast<NotifyLowMemoryWarningFn>(
      RegisterNativesAndFind(mock_env, "nativeNotifyLowMemoryWarning"));
  ASSERT_NE(notify_low_memory, nullptr);

  Settings settings;
  settings.enable_software_rendering = false;
  auto jni = std::make_shared<JNIMock>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kImpellerOpenGLES);
  ASSERT_TRUE(holder->IsValid());

  bool called = false;
  holder->GetEmbedderApiForTesting().NotifyLowMemoryWarning = MOCK_ENGINE_PROC(
      NotifyLowMemoryWarning, ([&](FLUTTER_API_SYMBOL(FlutterEngine) engine) {
        EXPECT_NE(engine, nullptr);
        called = true;
        return kSuccess;
      }));

  // Placeholder JNI caller object for JNI invocation.
  constexpr intptr_t kFakeJCaller = 123;
  notify_low_memory(&mock_env, reinterpret_cast<jobject>(kFakeJCaller),
                    reinterpret_cast<jlong>(holder.get()));
  EXPECT_TRUE(called);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       ScreenshotCallsEmbedderApiAndFreesScreenshot) {
  Settings settings;
  settings.enable_software_rendering = false;
  auto jni = std::make_shared<JNIMock>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kImpellerOpenGLES);
  ASSERT_TRUE(holder->IsValid());

  // Fake RGBA pixel buffer (4 bytes = 1 pixel) returned by the mocked C-API.
  constexpr uint8_t kFakePixelBytes[] = {0xAA, 0xBB, 0xCC, 0xDD};
  constexpr size_t kFakeScreenshotWidth = 640;
  constexpr size_t kFakeScreenshotHeight = 480;
  bool screenshot_called = false;
  bool free_screenshot_called = false;
  FlutterScreenshotType captured_type = kFlutterScreenshotTypeSkiaPicture;
  bool captured_base64_encode = false;

  holder->GetEmbedderApiForTesting().Screenshot = MOCK_ENGINE_PROC(
      Screenshot, ([&](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                       const FlutterScreenshotRequest* request,
                       FlutterScreenshot* screenshot_out) {
        EXPECT_NE(engine, nullptr);
        EXPECT_NE(request, nullptr);
        EXPECT_EQ(request->struct_size, sizeof(FlutterScreenshotRequest));
        captured_type = request->type;
        captured_base64_encode = request->base64_encode;
        EXPECT_NE(screenshot_out, nullptr);
        EXPECT_EQ(screenshot_out->struct_size, sizeof(FlutterScreenshot));
        screenshot_out->data = kFakePixelBytes;
        screenshot_out->data_length = sizeof(kFakePixelBytes);
        screenshot_out->width = kFakeScreenshotWidth;
        screenshot_out->height = kFakeScreenshotHeight;
        screenshot_out->format = kFlutterScreenshotFormatR8G8B8A8UNormInt;
        screenshot_out->format_description =
            "ScreenshotType::UncompressedImage";
        screenshot_called = true;
        return kSuccess;
      }));

  holder->GetEmbedderApiForTesting().FreeScreenshot =
      MOCK_ENGINE_PROC(FreeScreenshot, ([&](FlutterScreenshot* screenshot) {
                         EXPECT_NE(screenshot, nullptr);
                         EXPECT_EQ(screenshot->data, kFakePixelBytes);
                         free_screenshot_called = true;
                         return kSuccess;
                       }));

  AndroidShellHolder::ScreenshotData result = holder->Screenshot(
      kFlutterScreenshotTypeUncompressedImage, /*base64_encode=*/true);

  EXPECT_TRUE(screenshot_called);
  EXPECT_TRUE(free_screenshot_called);
  EXPECT_EQ(captured_type, kFlutterScreenshotTypeUncompressedImage);
  EXPECT_TRUE(captured_base64_encode);
  ASSERT_NE(result.data.GetMapping(), nullptr);
  ASSERT_EQ(result.data.GetSize(), sizeof(kFakePixelBytes));
  EXPECT_EQ(std::memcmp(result.data.GetMapping(), kFakePixelBytes,
                        sizeof(kFakePixelBytes)),
            0);
  EXPECT_EQ(result.width, static_cast<int32_t>(kFakeScreenshotWidth));
  EXPECT_EQ(result.height, static_cast<int32_t>(kFakeScreenshotHeight));
  EXPECT_EQ(result.format, "ScreenshotType::UncompressedImage");
  EXPECT_EQ(result.pixel_format, kFlutterScreenshotFormatR8G8B8A8UNormInt);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       AndroidImageGeneratorRegistrationInfoValidatesCallbacksAndDestruction) {
  Settings settings;
  settings.enable_software_rendering = false;
  auto jni = std::make_shared<JNIMock>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kImpellerOpenGLES);
  ASSERT_TRUE(holder->IsValid());
  EXPECT_NE(holder->GetEmbedderApiForTesting().RegisterImageGenerator, nullptr);

  // Priority -1 matches AndroidShellHolder SDK image decoder registration.
  constexpr int32_t kAndroidSdkDecoderPriority = -1;
  FlutterImageGeneratorRegistrationInfo info =
      AndroidImageGenerator::MakeFlutterImageGeneratorRegistrationInfo(
          GetShellForTesting(*holder)->GetTaskRunners().GetIOTaskRunner(),
          kAndroidSdkDecoderPriority);

  EXPECT_EQ(info.struct_size, sizeof(FlutterImageGeneratorRegistrationInfo));
  EXPECT_EQ(info.priority, kAndroidSdkDecoderPriority);
  ASSERT_NE(info.create_generator, nullptr);
  ASSERT_NE(info.user_data, nullptr);
  ASSERT_NE(info.destruction_callback, nullptr);

  // Null/empty arguments to create_generator must return false without leaking.
  FlutterImageGenerator out_gen = {};
  constexpr uint8_t kDummyEncodedBytes[] = {0x89, 0x50, 0x4E, 0x47};
  EXPECT_FALSE(info.create_generator(nullptr, sizeof(kDummyEncodedBytes),
                                     info.user_data, &out_gen));
  EXPECT_FALSE(
      info.create_generator(kDummyEncodedBytes, 0, info.user_data, &out_gen));
  EXPECT_FALSE(info.create_generator(
      kDummyEncodedBytes, sizeof(kDummyEncodedBytes), nullptr, &out_gen));
  EXPECT_FALSE(info.create_generator(
      kDummyEncodedBytes, sizeof(kDummyEncodedBytes), info.user_data, nullptr));

  // Release the heap-allocated task runner ref in user_data.
  info.destruction_callback(info.user_data);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       LaunchQueriesRunsAOTCompiledDartCodeViaEmbedderApi) {
  Settings settings;
  settings.enable_software_rendering = false;
  auto jni = std::make_shared<JNIMock>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kImpellerOpenGLES);
  ASSERT_TRUE(holder->IsValid());

  bool runs_aot_queried = false;
  holder->GetEmbedderApiForTesting().RunsAOTCompiledDartCode =
      MOCK_ENGINE_PROC(RunsAOTCompiledDartCode, ([&]() {
                         runs_aot_queried = true;
                         return false;
                       }));

  // With RunsAOTCompiledDartCode returning false and no kernel asset configured
  // on settings, Launch queries RunsAOTCompiledDartCode and returns early when
  // BuildRunConfiguration returns std::nullopt.
  constexpr int64_t kTestEngineId = 1;
  holder->Launch(/*apk_asset_provider=*/nullptr, "main", "", {}, kTestEngineId);
  EXPECT_TRUE(runs_aot_queried);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       LookupCallbackInformationRoutesThroughEmbedderApi) {
  fml::ScopedTemporaryDirectory temp_dir;
  ASSERT_TRUE(temp_dir.fd().is_valid());

  FlutterEngineProcTable embedder_api = {};
  embedder_api.struct_size = sizeof(FlutterEngineProcTable);
  ASSERT_EQ(FlutterEngineGetProcAddresses(&embedder_api), kSuccess);

  ASSERT_EQ(embedder_api.SetCallbackCachePath(temp_dir.path().c_str()),
            kSuccess);
  ASSERT_EQ(embedder_api.LoadCallbackCache(), kSuccess);

  FlutterCallbackInformation cb_in = {};
  cb_in.struct_size = sizeof(FlutterCallbackInformation);
  cb_in.name = "myTopLevelCallback";
  cb_in.class_name = nullptr;
  cb_in.library_path = "package:my_app/callbacks.dart";

  int64_t handle = 0;
  ASSERT_EQ(embedder_api.GetCallbackHandle(&cb_in, &handle), kSuccess);
  EXPECT_NE(handle, 0);

  using LookupCallbackInformationFn =
      jobject (*)(JNIEnv*, jobject, jlong handle);
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  auto lookup_fn = reinterpret_cast<LookupCallbackInformationFn>(
      RegisterNativesAndFind(mock_env, "nativeLookupCallbackInformation"));
  ASSERT_NE(lookup_fn, nullptr);

  std::vector<std::string> utf_strings;
  EXPECT_CALL(mock_env, NewStringUTF(_))
      .WillRepeatedly([&utf_strings](const char* str) {
        EXPECT_NE(str, nullptr);
        utf_strings.emplace_back(str);
        return reinterpret_cast<jstring>(utf_strings.size());
      });
  const jobject kFakeCallbackInfoObj = reinterpret_cast<jobject>(777);
  EXPECT_CALL(mock_env, NewObjectV(_, _, _))
      .WillOnce(Return(kFakeCallbackInfoObj));

  jobject jcaller = reinterpret_cast<jobject>(123);
  jobject result = lookup_fn(&mock_env, jcaller, handle);
  EXPECT_EQ(result, kFakeCallbackInfoObj);
  EXPECT_THAT(utf_strings, ElementsAre("myTopLevelCallback", "",
                                       "package:my_app/callbacks.dart"));

  // Unknown handle returns nullptr without constructing a Java object.
  constexpr jlong kUnknownHandle = -999999;
  EXPECT_EQ(lookup_fn(&mock_env, jcaller, kUnknownHandle), nullptr);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       FlutterMainPrefetchDefaultFontManagerCallsEmbedderApi) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();

  const jclass kPlaceholderClass = reinterpret_cast<jclass>(100);
  EXPECT_CALL(mock_env, FindClass(_)).WillRepeatedly(Return(kPlaceholderClass));

  using PrefetchDefaultFontManagerFn = void (*)(JNIEnv*, jclass);
  PrefetchDefaultFontManagerFn prefetch_fn = nullptr;
  EXPECT_CALL(mock_env, RegisterNatives(_, _, _))
      .WillOnce(
          [&](jclass clazz, const JNINativeMethod* methods, jint nMethods) {
            for (jint i = 0; i < nMethods; ++i) {
              if (std::strcmp(methods[i].name,
                              "nativePrefetchDefaultFontManager") == 0) {
                prefetch_fn = reinterpret_cast<PrefetchDefaultFontManagerFn>(
                    methods[i].fnPtr);
              }
            }
            return 0;
          });

  ASSERT_TRUE(FlutterMain::Register(&mock_env));
  ASSERT_NE(prefetch_fn, nullptr);

  prefetch_fn(&mock_env, kPlaceholderClass);
}

TEST_F(PlatformViewAndroidJNIImplTest, LaunchCallsLaunchEngineEmbedderApi) {
  Settings settings;
  settings.enable_software_rendering = false;
  auto jni = std::make_shared<JNIMock>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kImpellerOpenGLES);
  ASSERT_TRUE(holder->IsValid());

  // Simulate AOT mode so Launch proceeds without needing a kernel file on disk.
  holder->GetEmbedderApiForTesting().RunsAOTCompiledDartCode =
      MOCK_ENGINE_PROC(RunsAOTCompiledDartCode, ([]() { return true; }));

  // Expect display metrics query during Launch.
  constexpr double kRefreshRateHz = 60.0;
  constexpr double kDisplayWidthPx = 1080.0;
  constexpr double kDisplayHeightPx = 1920.0;
  constexpr double kDisplayDensity = 2.0;
  EXPECT_CALL(*jni, GetDisplayRefreshRate()).WillOnce(Return(kRefreshRateHz));
  EXPECT_CALL(*jni, GetDisplayWidth()).WillOnce(Return(kDisplayWidthPx));
  EXPECT_CALL(*jni, GetDisplayHeight()).WillOnce(Return(kDisplayHeightPx));
  EXPECT_CALL(*jni, GetDisplayDensity()).WillOnce(Return(kDisplayDensity));

  bool launch_engine_called = false;
  std::string captured_entrypoint;
  std::string captured_library;
  std::vector<std::string> captured_args;
  int64_t captured_engine_id = 0;

  holder->GetEmbedderApiForTesting().LaunchEngine = MOCK_ENGINE_PROC(
      LaunchEngine, ([&](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                         const FlutterEngineRunConfiguration* config) {
        EXPECT_NE(engine, nullptr);
        EXPECT_NE(config, nullptr);
        if (config != nullptr) {
          EXPECT_EQ(config->struct_size, sizeof(FlutterEngineRunConfiguration));
          if (config->custom_dart_entrypoint != nullptr) {
            captured_entrypoint = config->custom_dart_entrypoint;
          }
          if (config->custom_dart_entrypoint_library != nullptr) {
            captured_library = config->custom_dart_entrypoint_library;
          }
          for (int i = 0; i < config->dart_entrypoint_argc; ++i) {
            captured_args.emplace_back(config->dart_entrypoint_argv[i]);
          }
          captured_engine_id = config->engine_id;
        }
        launch_engine_called = true;
        return kSuccess;
      }));

  constexpr int64_t kTestEngineId = 77;
  holder->Launch(/*apk_asset_provider=*/nullptr, "customMain",
                 "package:my_app/main.dart", {"--foo", "--bar"}, kTestEngineId);

  EXPECT_TRUE(launch_engine_called);
  EXPECT_EQ(captured_entrypoint, "customMain");
  EXPECT_EQ(captured_library, "package:my_app/main.dart");
  EXPECT_THAT(captured_args, ElementsAre("--foo", "--bar"));
  EXPECT_EQ(captured_engine_id, kTestEngineId);
}

TEST_F(PlatformViewAndroidJNIImplTest, DestroyCallsShutdownEmbedderApi) {
  Settings settings;
  settings.enable_software_rendering = false;
  auto jni = std::make_shared<JNIMock>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kImpellerOpenGLES);
  ASSERT_TRUE(holder->IsValid());

  FLUTTER_API_SYMBOL(FlutterEngine)
  expected_engine = holder->GetEngineForTesting();
  ASSERT_NE(expected_engine, nullptr);

  bool shutdown_called = false;
  FlutterEngineShutdownFnPtr real_shutdown =
      holder->GetEmbedderApiForTesting().Shutdown;
  ASSERT_NE(real_shutdown, nullptr);

  holder->GetEmbedderApiForTesting().Shutdown = MOCK_ENGINE_PROC(
      Shutdown, ([&](FLUTTER_API_SYMBOL(FlutterEngine) engine) {
        EXPECT_EQ(engine, expected_engine);
        shutdown_called = true;
        return real_shutdown(engine);
      }));

  holder.reset();
  EXPECT_TRUE(shutdown_called);
}

}  // namespace testing
}  // namespace flutter
