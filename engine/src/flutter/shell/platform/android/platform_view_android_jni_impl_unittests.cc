// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gmock/gmock.h"
#include "gtest/gtest.h"

#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/fml/platform/android/jni_weak_ref.h"
#include "flutter/fml/platform/android/scoped_java_ref.h"
#include "flutter/shell/platform/android/android_shell_holder.h"
#include "flutter/shell/platform/android/jni/jni_mock.h"
#include "flutter/shell/platform/android/jni/mock_jni_env.h"
#include "flutter/shell/platform/android/platform_view_android.h"
#include "flutter/shell/platform/android/platform_view_android_jni_impl.h"

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

// The load order is exercised with an injected loader rather than real dlopen():
// the property under test is purely the ordering (first-to-last, stop at the
// first that loads), and a fake loader makes that deterministic and free of any
// platform- or system-library-specific behavior. Whether a given path format is
// actually loadable is covered end-to-end by the deferred_components_test.
TEST(FindFirstLoadableLibraryTest, TriesInOrderAndStopsAtFirstSuccess) {
  std::vector<std::string> attempted;
  void* const kHandle = reinterpret_cast<void*>(0x1234);
  auto opener = [&](const std::string& path) -> void* {
    attempted.push_back(path);
    return path == "b" ? kHandle : nullptr;
  };
  EXPECT_EQ(FindFirstLoadableLibrary({"a", "b", "c"}, opener), kHandle);
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
