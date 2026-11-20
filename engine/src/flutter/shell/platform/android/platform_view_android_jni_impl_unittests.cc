// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cstring>

#include "gmock/gmock.h"
#include "gtest/gtest.h"

#include "flutter/display_list/geometry/dl_path_builder.h"
#include "flutter/flow/embedded_views.h"
#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/fml/platform/android/jni_weak_ref.h"
#include "flutter/fml/platform/android/scoped_java_ref.h"
#include "flutter/shell/platform/android/android_shell_holder.h"
#include "flutter/shell/platform/android/jni/jni_mock.h"
#include "flutter/shell/platform/android/jni/mock_jni_env.h"
#include "flutter/shell/platform/android/platform_view_android.h"
#include "flutter/shell/platform/android/platform_view_android_jni_impl.h"
#include "impeller/toolkit/android/proc_table.h"

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

TEST_F(PlatformViewAndroidJNIImplTest,
       CreateTransactionRetainsGlobalRefUntilPublished) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();

  const jobject kFlutterJniObj = reinterpret_cast<jobject>(0x1001);
  const jobject kJavaTxObj = reinterpret_cast<jobject>(0x2002);
  ASurfaceTransaction* const kNativeTx =
      reinterpret_cast<ASurfaceTransaction*>(0x3003);

  // Stub the NDK call so the fake Java object is never dereferenced.
  auto& from_java_proc =
      impeller::android::GetMutableProcTable().ASurfaceTransaction_fromJava;
  auto* real_from_java = from_java_proc.proc;
  from_java_proc.proc = [](JNIEnv*, jobject) -> ASurfaceTransaction* {
    return reinterpret_cast<ASurfaceTransaction*>(0x3003);
  };
  struct RestoreProc {
    decltype(from_java_proc.proc)* slot;
    decltype(from_java_proc.proc) prev;
    ~RestoreProc() { *slot = prev; }
  } restore{&from_java_proc.proc, real_from_java};

  EXPECT_CALL(mock_env, GetObjectRefType(_))
      .WillRepeatedly(Return(JNILocalRefType));
  EXPECT_CALL(mock_env, NewLocalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteLocalRef(_)).WillRepeatedly(Return());
  EXPECT_CALL(mock_env, NewWeakGlobalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteWeakGlobalRef(_)).WillRepeatedly(Return());
  EXPECT_CALL(mock_env, ExceptionCheck()).WillRepeatedly(Return(JNI_FALSE));
  EXPECT_CALL(mock_env, CallObjectMethodV(kFlutterJniObj, _, _))
      .WillOnce(Return(kJavaTxObj));

  bool global_ref_alive = false;
  EXPECT_CALL(mock_env, NewGlobalRef(kJavaTxObj))
      .WillOnce([&](jobject obj) -> jobject {
        global_ref_alive = true;
        return obj;
      });
  EXPECT_CALL(mock_env, DeleteGlobalRef(kJavaTxObj)).WillOnce([&](jobject) {
    global_ref_alive = false;
  });

  bool publish_called = false;
  EXPECT_CALL(mock_env, CallVoidMethodV(kFlutterJniObj, _, _))
      .WillOnce([&](jobject, jmethodID, va_list args) {
        // publishTransaction must receive the same transaction, while the
        // global ref is still keeping it alive.
        EXPECT_EQ(va_arg(args, jobject), kJavaTxObj);
        EXPECT_TRUE(global_ref_alive);
        publish_called = true;
      });

  fml::jni::JavaObjectWeakGlobalRef flutter_jni_ref(&mock_env, kFlutterJniObj);
  PlatformViewAndroidJNIImpl android_jni(flutter_jni_ref);

  std::function<void()> publish_cb;
  ASurfaceTransaction* tx = android_jni.createTransaction(publish_cb);
  EXPECT_EQ(tx, kNativeTx);
  ASSERT_NE(publish_cb, nullptr);
  EXPECT_TRUE(global_ref_alive);
  EXPECT_FALSE(publish_called);

  publish_cb();
  EXPECT_TRUE(publish_called);
  EXPECT_FALSE(global_ref_alive);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       PublishAppliesNativelyIfFlutterJNIWasCollected) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();

  const jobject kFlutterJniObj = reinterpret_cast<jobject>(0x1001);
  const jobject kJavaTxObj = reinterpret_cast<jobject>(0x2002);

  // Stub the NDK calls so the fake objects are never dereferenced.
  auto& proc_table = impeller::android::GetMutableProcTable();
  auto* real_from_java = proc_table.ASurfaceTransaction_fromJava.proc;
  auto* real_apply = proc_table.ASurfaceTransaction_apply.proc;
  proc_table.ASurfaceTransaction_fromJava.proc =
      [](JNIEnv*, jobject) -> ASurfaceTransaction* {
    return reinterpret_cast<ASurfaceTransaction*>(0x3003);
  };
  static ASurfaceTransaction* applied_tx;
  applied_tx = nullptr;
  proc_table.ASurfaceTransaction_apply.proc = [](ASurfaceTransaction* tx) {
    applied_tx = tx;
  };
  struct RestoreProcs {
    impeller::android::ProcTable& table;
    decltype(real_from_java) from_java;
    decltype(real_apply) apply;
    ~RestoreProcs() {
      table.ASurfaceTransaction_fromJava.proc = from_java;
      table.ASurfaceTransaction_apply.proc = apply;
    }
  } restore{proc_table, real_from_java, real_apply};

  // Resolving the weak FlutterJNI ref goes through NewLocalRef. Once
  // `flutter_jni_collected` is set, model the object having been collected.
  bool flutter_jni_collected = false;
  EXPECT_CALL(mock_env, GetObjectRefType(_))
      .WillRepeatedly(Return(JNILocalRefType));
  EXPECT_CALL(mock_env, NewLocalRef(_))
      .WillRepeatedly([&](jobject obj) -> jobject {
        return (obj == kFlutterJniObj && flutter_jni_collected) ? nullptr : obj;
      });
  EXPECT_CALL(mock_env, DeleteLocalRef(_)).WillRepeatedly(Return());
  EXPECT_CALL(mock_env, NewWeakGlobalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteWeakGlobalRef(_)).WillRepeatedly(Return());
  EXPECT_CALL(mock_env, ExceptionCheck()).WillRepeatedly(Return(JNI_FALSE));
  EXPECT_CALL(mock_env, CallObjectMethodV(kFlutterJniObj, _, _))
      .WillOnce(Return(kJavaTxObj));

  bool global_ref_alive = false;
  EXPECT_CALL(mock_env, NewGlobalRef(kJavaTxObj))
      .WillOnce([&](jobject obj) -> jobject {
        global_ref_alive = true;
        return obj;
      });
  EXPECT_CALL(mock_env, DeleteGlobalRef(kJavaTxObj)).WillOnce([&](jobject) {
    // The transaction must be applied before the global ref stops keeping the
    // Java object (and therefore the native handle) alive.
    EXPECT_NE(applied_tx, nullptr);
    global_ref_alive = false;
  });

  // There is no FlutterJNI to publish to.
  EXPECT_CALL(mock_env, CallVoidMethodV(_, _, _)).Times(0);

  fml::jni::JavaObjectWeakGlobalRef flutter_jni_ref(&mock_env, kFlutterJniObj);
  PlatformViewAndroidJNIImpl android_jni(flutter_jni_ref);

  std::function<void()> publish_cb;
  ASurfaceTransaction* tx = android_jni.createTransaction(publish_cb);
  ASSERT_NE(tx, nullptr);
  ASSERT_NE(publish_cb, nullptr);

  flutter_jni_collected = true;
  publish_cb();
  EXPECT_EQ(applied_tx, tx);
  EXPECT_FALSE(global_ref_alive);

  // A second invocation must not touch the transaction again.
  applied_tx = nullptr;
  publish_cb();
  EXPECT_EQ(applied_tx, nullptr);
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

TEST_F(PlatformViewAndroidJNIImplTest, HidePlatformView2ChecksExceptions) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();

  const jobject kFlutterJniObj = reinterpret_cast<jobject>(0x1001);

  EXPECT_CALL(mock_env, GetObjectRefType(_))
      .WillRepeatedly(Return(JNILocalRefType));
  EXPECT_CALL(mock_env, NewLocalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteLocalRef(_)).WillRepeatedly(Return());
  EXPECT_CALL(mock_env, NewWeakGlobalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteWeakGlobalRef(_)).WillRepeatedly(Return());
  EXPECT_CALL(mock_env, CallVoidMethodV(kFlutterJniObj, _, _)).Times(1);
  EXPECT_CALL(mock_env, ExceptionCheck()).Times(1).WillOnce(Return(JNI_FALSE));

  fml::jni::JavaObjectWeakGlobalRef flutter_jni_ref(&mock_env, kFlutterJniObj);
  PlatformViewAndroidJNIImpl android_jni(flutter_jni_ref);

  android_jni.hidePlatformView2(99);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       CreateOverlaySurfaceChecksIntermediateExceptionsAndNullSurface) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();

  const jobject kFlutterJniObj = reinterpret_cast<jobject>(0x1001);
  const jobject kOverlayObj = reinterpret_cast<jobject>(0x2001);
  const jobject kSurfaceObj = reinterpret_cast<jobject>(0x3001);

  static int from_surface_calls;
  from_surface_calls = 0;

  auto& from_surface_proc =
      impeller::android::GetMutableProcTable().ANativeWindow_fromSurface;
  auto* real_from_surface = from_surface_proc.proc;
  from_surface_proc.proc = [](JNIEnv*, jobject) -> ANativeWindow* {
    ++from_surface_calls;
    return nullptr;
  };
  struct RestoreProc {
    decltype(from_surface_proc.proc)* slot;
    decltype(from_surface_proc.proc) prev;
    ~RestoreProc() { *slot = prev; }
  } restore{&from_surface_proc.proc, real_from_surface};

  EXPECT_CALL(mock_env, GetObjectRefType(_))
      .WillRepeatedly(Return(JNILocalRefType));
  EXPECT_CALL(mock_env, NewLocalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteLocalRef(_)).WillRepeatedly(Return());
  EXPECT_CALL(mock_env, NewWeakGlobalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteWeakGlobalRef(_)).WillRepeatedly(Return());

  fml::jni::JavaObjectWeakGlobalRef flutter_jni_ref(&mock_env, kFlutterJniObj);
  PlatformViewAndroidJNIImpl android_jni(flutter_jni_ref);

  // Valid surface: checks exceptions after createOverlaySurface*, getId, and
  // getSurface (3 checks each).
  for (int variant = 0; variant < 2; ++variant) {
    from_surface_calls = 0;
    EXPECT_CALL(mock_env, CallObjectMethodV(_, _, _))
        .Times(2)
        .WillOnce(Return(kOverlayObj))
        .WillOnce(Return(kSurfaceObj));
    EXPECT_CALL(mock_env, CallIntMethodV(kOverlayObj, _, _))
        .WillOnce(Return(10 + variant));
    EXPECT_CALL(mock_env, ExceptionCheck())
        .Times(3)
        .WillRepeatedly(Return(JNI_FALSE));

    auto metadata = (variant == 0)
                        ? android_jni.FlutterViewCreateOverlaySurface()
                        : android_jni.createOverlaySurface2();
    ASSERT_NE(metadata, nullptr);
    EXPECT_EQ(metadata->id, 10 + variant);
    EXPECT_EQ(from_surface_calls, 1);
  }

  // Null Surface returned by getSurface(): still checks all 3 JNI calls and
  // does not pass nullptr into ANativeWindow_fromSurface.
  for (int variant = 0; variant < 2; ++variant) {
    from_surface_calls = 0;
    EXPECT_CALL(mock_env, CallObjectMethodV(_, _, _))
        .Times(2)
        .WillOnce(Return(kOverlayObj))
        .WillOnce(Return(nullptr));
    EXPECT_CALL(mock_env, CallIntMethodV(kOverlayObj, _, _))
        .WillOnce(Return(20 + variant));
    EXPECT_CALL(mock_env, ExceptionCheck())
        .Times(3)
        .WillRepeatedly(Return(JNI_FALSE));

    auto metadata = (variant == 0)
                        ? android_jni.FlutterViewCreateOverlaySurface()
                        : android_jni.createOverlaySurface2();
    ASSERT_NE(metadata, nullptr);
    EXPECT_EQ(metadata->id, 20 + variant);
    EXPECT_EQ(metadata->window.get(), nullptr);
    EXPECT_EQ(from_surface_calls, 0);
  }
}

TEST_F(PlatformViewAndroidJNIImplTest,
       OnDisplayPlatformViewChecksExceptionsAfterEveryJNICall) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();

  const jobject kFlutterJniObj = reinterpret_cast<jobject>(0x1001);
  const jobject kMutatorsStackObj = reinterpret_cast<jobject>(0x2001);
  const jobject kPathObj = reinterpret_cast<jobject>(0x2002);
  const jobject kFillTypeObj = reinterpret_cast<jobject>(0x2003);
  const jfloatArray kFloatArrayObj = reinterpret_cast<jfloatArray>(0x2004);

  EXPECT_CALL(mock_env, GetObjectRefType(_))
      .WillRepeatedly(Return(JNILocalRefType));
  EXPECT_CALL(mock_env, NewLocalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteLocalRef(_)).WillRepeatedly(Return());
  EXPECT_CALL(mock_env, NewWeakGlobalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteWeakGlobalRef(_)).WillRepeatedly(Return());
  EXPECT_CALL(mock_env, NewFloatArray(_))
      .WillRepeatedly(Return(kFloatArrayObj));
  EXPECT_CALL(mock_env, SetFloatArrayRegion(_, _, _, _))
      .WillRepeatedly(Return());
  EXPECT_CALL(mock_env, CallVoidMethodV(_, _, _)).WillRepeatedly(Return());

  fml::jni::JavaObjectWeakGlobalRef flutter_jni_ref(&mock_env, kFlutterJniObj);
  PlatformViewAndroidJNIImpl android_jni(flutter_jni_ref);

  // 1) FlutterViewOnDisplayPlatformView:
  //    1 (NewObject) + 3 (kTransform) + 1 (kClipRect) + 3 (kClipRRect) +
  //    3 (kClipRSE) + 1 (onDisplayPlatformView) = 12 ExceptionCheck calls.
  EXPECT_CALL(mock_env, NewObjectV(_, _, _))
      .WillOnce(Return(kMutatorsStackObj));
  EXPECT_CALL(mock_env, ExceptionCheck())
      .Times(12)
      .WillRepeatedly(Return(JNI_FALSE));

  MutatorsStack hc_stack;
  hc_stack.PushTransform(DlMatrix::MakeTranslation({4.0f, 8.0f}));
  hc_stack.PushClipRect(DlRect::MakeLTRB(0.0f, 0.0f, 50.0f, 50.0f));
  hc_stack.PushClipRRect(
      DlRoundRect::MakeRectRadius(DlRect::MakeLTRB(0, 0, 20, 20), 3.0f));
  hc_stack.PushClipRSE(DlRoundSuperellipse::MakeRectRadius(
      DlRect::MakeLTRB(0, 0, 20, 20), 3.0f));

  android_jni.FlutterViewOnDisplayPlatformView(1, 0, 0, 100, 100, 100, 100,
                                               hc_stack);

  // 2) onDisplayPlatformView2 with kOpacity + closed kClipPath:
  //    1 (NewObject MutatorsStack) + 1 (pushOpacity) + 1 (NewObject Path) +
  //    2 (SetFillType) + 7 (MoveTo, LineTo, QuadTo, ConicTo, CubicTo, implicit
  //    closing LineTo, Close) + 1 (pushClipPath) + 1 (onDisplayPlatformView2) =
  //    14 ExceptionCheck calls.
  EXPECT_CALL(mock_env, NewObjectV(_, _, _))
      .Times(2)
      .WillOnce(Return(kMutatorsStackObj))
      .WillOnce(Return(kPathObj));
  EXPECT_CALL(mock_env, GetStaticObjectField(_, _))
      .WillOnce(Return(kFillTypeObj));
  EXPECT_CALL(mock_env, ExceptionCheck())
      .Times(14)
      .WillRepeatedly(Return(JNI_FALSE));

  DlPathBuilder path_builder;
  path_builder.SetFillType(DlPathFillType::kOdd)
      .MoveTo({0.0f, 0.0f})
      .LineTo({10.0f, 5.0f})
      .QuadraticCurveTo({15.0f, 0.0f}, {20.0f, 10.0f})
      .ConicCurveTo({25.0f, 15.0f}, {30.0f, 10.0f}, 0.707f)
      .CubicCurveTo({35.0f, 0.0f}, {40.0f, 20.0f}, {50.0f, 10.0f})
      .Close();

  MutatorsStack hcpp_stack;
  hcpp_stack.PushOpacity(200);
  hcpp_stack.PushClipPath(path_builder.TakePath());

  android_jni.onDisplayPlatformView2(2, 0, 0, 100, 100, 100, 100, hcpp_stack);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       SurfaceTextureGetTransformMatrixSkipsCallWhenAllocationReturnsNull) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();

  const jobject kWeakRefObj = reinterpret_cast<jobject>(0x4001);
  const jobject kWrapperObj = reinterpret_cast<jobject>(0x4002);

  EXPECT_CALL(mock_env, GetObjectRefType(_))
      .WillRepeatedly(Return(JNILocalRefType));
  EXPECT_CALL(mock_env, NewLocalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteLocalRef(_)).WillRepeatedly(Return());
  EXPECT_CALL(mock_env, CallObjectMethodV(kWeakRefObj, _, _))
      .WillOnce(Return(kWrapperObj));
  EXPECT_CALL(mock_env, NewFloatArray(16)).WillOnce(Return(nullptr));
  EXPECT_CALL(mock_env, ExceptionCheck())
      .Times(2)
      .WillRepeatedly(Return(JNI_FALSE));
  EXPECT_CALL(mock_env, CallVoidMethodV(_, _, _)).Times(0);

  fml::jni::JavaObjectWeakGlobalRef flutter_jni_object;
  PlatformViewAndroidJNIImpl android_jni(flutter_jni_object);

  fml::jni::ScopedJavaLocalRef<jobject> surface_texture(&mock_env, kWeakRefObj);
  EXPECT_EQ(android_jni.SurfaceTextureGetTransformMatrix(surface_texture),
            SkM44());
}

TEST_F(PlatformViewAndroidJNIImplTest,
       RegisterFailsWithoutCallingGetMethodIDWhenMutatorsStackClassMissing) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();

  const jclass kFlutterCallbackInfoClass = reinterpret_cast<jclass>(101);
  const jclass kFlutterJniClass = reinterpret_cast<jclass>(102);
  const jclass kPlaceholderClass = reinterpret_cast<jclass>(100);
  const jfieldID kPlaceholderFieldID = reinterpret_cast<jfieldID>(200);
  const jmethodID kPlaceholderMethodID = reinterpret_cast<jmethodID>(300);

  EXPECT_CALL(mock_env, GetObjectRefType(_))
      .WillRepeatedly(Return(JNILocalRefType));
  EXPECT_CALL(mock_env, NewLocalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteLocalRef(_)).WillRepeatedly(Return());
  EXPECT_CALL(mock_env, NewGlobalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteGlobalRef(_)).WillRepeatedly(Return());
  EXPECT_CALL(mock_env, ExceptionCheck()).WillRepeatedly(Return(JNI_FALSE));

  EXPECT_CALL(mock_env, FindClass(_))
      .WillRepeatedly([&](const char* name) -> jclass {
        if (std::strcmp(name,
                        "io/flutter/embedding/engine/mutatorsstack/"
                        "FlutterMutatorsStack") == 0) {
          return nullptr;
        }
        if (std::strcmp(name, "io/flutter/view/FlutterCallbackInformation") ==
            0) {
          return kFlutterCallbackInfoClass;
        }
        return kFlutterJniClass;
      });
  // Only FlutterCallbackInformation.<init> may be looked up before
  // FlutterMutatorsStack fails; GetMethodID must never be called with nullptr.
  EXPECT_CALL(mock_env, GetMethodID(_, _, _))
      .Times(1)
      .WillOnce([&](jclass clazz, const char*, const char*) -> jmethodID {
        EXPECT_EQ(clazz, kFlutterCallbackInfoClass);
        return kPlaceholderMethodID;
      });

  EXPECT_FALSE(PlatformViewAndroid::Register(&mock_env));

  // Restore valid class registration for any subsequent tests.
  EXPECT_CALL(mock_env, FindClass(_)).WillRepeatedly(Return(kPlaceholderClass));
  EXPECT_CALL(mock_env, GetFieldID(_, _, _))
      .WillRepeatedly(Return(kPlaceholderFieldID));
  EXPECT_CALL(mock_env, GetMethodID(_, _, _))
      .WillRepeatedly(Return(kPlaceholderMethodID));
  EXPECT_CALL(mock_env, GetStaticFieldID(_, _, _))
      .WillRepeatedly(Return(kPlaceholderFieldID));
  EXPECT_CALL(mock_env, GetStaticMethodID(_, _, _))
      .WillRepeatedly(Return(kPlaceholderMethodID));
  EXPECT_CALL(mock_env, RegisterNatives(_, _, _)).WillRepeatedly(Return(0));
  EXPECT_TRUE(PlatformViewAndroid::Register(&mock_env));
}

}  // namespace testing
}  // namespace flutter
