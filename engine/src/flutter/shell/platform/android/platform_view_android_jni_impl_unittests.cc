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
