// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cstdint>
#include <unordered_map>
#include <vector>

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

namespace {

struct LocalRefTracker {
  std::vector<std::unordered_map<jobject, int>> frames{1};
  uintptr_t next_id = 0x5000;

  template <typename T>
  T TrackNew(T ref) {
    if (ref != nullptr) {
      ++frames.back()[reinterpret_cast<jobject>(ref)];
    }
    return ref;
  }

  template <typename T>
  T AllocateNew() {
    return TrackNew(reinterpret_cast<T>(next_id++));
  }

  void TrackDelete(jobject ref) {
    if (ref == nullptr) {
      return;
    }
    for (auto it = frames.rbegin(); it != frames.rend(); ++it) {
      auto found = it->find(ref);
      if (found != it->end()) {
        if (--found->second == 0) {
          it->erase(found);
        }
        return;
      }
    }
    ADD_FAILURE() << "DeleteLocalRef called on untracked or already-deleted "
                     "local reference: "
                  << ref;
  }

  jint PushFrame(jint capacity) {
    frames.emplace_back();
    return JNI_OK;
  }

  jobject PopFrame(jobject result) {
    EXPECT_GT(frames.size(), 1u);
    if (frames.size() > 1u) {
      frames.pop_back();
    }
    if (result != nullptr) {
      TrackNew(result);
    }
    return result;
  }

  size_t ActiveCount() const {
    size_t total = 0;
    for (const auto& frame : frames) {
      for (const auto& [ref, count] : frame) {
        total += static_cast<size_t>(count);
      }
    }
    return total;
  }

  void InstallDefaults(MockJNIEnv& mock_env) {
    EXPECT_CALL(mock_env, GetObjectRefType(_))
        .WillRepeatedly(Return(JNILocalRefType));
    EXPECT_CALL(mock_env, NewLocalRef(_))
        .WillRepeatedly(
            [this](jobject obj) -> jobject { return TrackNew(obj); });
    EXPECT_CALL(mock_env, DeleteLocalRef(_))
        .WillRepeatedly([this](jobject obj) { TrackDelete(obj); });
    EXPECT_CALL(mock_env, NewWeakGlobalRef(_)).WillRepeatedly(ReturnArg<0>());
    EXPECT_CALL(mock_env, DeleteWeakGlobalRef(_)).WillRepeatedly(Return());
    EXPECT_CALL(mock_env, PushLocalFrame(_))
        .WillRepeatedly(
            [this](jint capacity) -> jint { return PushFrame(capacity); });
    EXPECT_CALL(mock_env, PopLocalFrame(_))
        .WillRepeatedly(
            [this](jobject result) -> jobject { return PopFrame(result); });
  }
};

}  // namespace

TEST_F(PlatformViewAndroidJNIImplTest,
       FlutterViewOnDisplayPlatformViewDeletesLocalRefs) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  LocalRefTracker tracker;
  tracker.InstallDefaults(mock_env);

  const jobject kFlutterJniObj = reinterpret_cast<jobject>(0x1001);

  EXPECT_CALL(mock_env, ExceptionCheck()).WillRepeatedly(Return(JNI_FALSE));
  EXPECT_CALL(mock_env, NewObjectV(_, _, _))
      .WillOnce([&](jclass, jmethodID, va_list) -> jobject {
        return tracker.AllocateNew<jobject>();
      });
  EXPECT_CALL(mock_env, NewFloatArray(_))
      .WillRepeatedly([&](jsize) -> jfloatArray {
        return tracker.AllocateNew<jfloatArray>();
      });
  EXPECT_CALL(mock_env, SetFloatArrayRegion(_, _, _, _))
      .WillRepeatedly(Return());

  int void_calls = 0;
  EXPECT_CALL(mock_env, CallVoidMethodV(_, _, _))
      .WillRepeatedly([&](jobject, jmethodID, va_list) { ++void_calls; });

  fml::jni::JavaObjectWeakGlobalRef flutter_jni_ref(&mock_env, kFlutterJniObj);
  PlatformViewAndroidJNIImpl android_jni(flutter_jni_ref);

  MutatorsStack stack;
  stack.PushTransform(DlMatrix::MakeTranslation({4.0f, 8.0f}));
  stack.PushClipRect(DlRect::MakeLTRB(0.0f, 0.0f, 50.0f, 50.0f));
  stack.PushClipRRect(
      DlRoundRect::MakeRectRadius(DlRect::MakeLTRB(0, 0, 20, 20), 3.0f));
  stack.PushClipRSE(DlRoundSuperellipse::MakeRectRadius(
      DlRect::MakeLTRB(0, 0, 20, 20), 3.0f));

  android_jni.FlutterViewOnDisplayPlatformView(1, 0, 0, 100, 100, 100, 100,
                                               stack);

  // 4 mutator pushes + 1 final onDisplayPlatformView call.
  EXPECT_EQ(void_calls, 5);
  EXPECT_EQ(tracker.frames.size(), 1u);
  EXPECT_EQ(tracker.ActiveCount(), 0u);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       OnDisplayPlatformView2DeletesMutatorsStackAndPathLocalRefs) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  LocalRefTracker tracker;
  tracker.InstallDefaults(mock_env);

  const jobject kFlutterJniObj = reinterpret_cast<jobject>(0x1001);

  EXPECT_CALL(mock_env, ExceptionCheck()).WillRepeatedly(Return(JNI_FALSE));
  // 1st NewObjectV: FlutterMutatorsStack; 2nd NewObjectV: android.graphics.Path
  EXPECT_CALL(mock_env, NewObjectV(_, _, _))
      .Times(2)
      .WillRepeatedly([&](jclass, jmethodID, va_list) -> jobject {
        return tracker.AllocateNew<jobject>();
      });
  EXPECT_CALL(mock_env, GetStaticObjectField(_, _))
      .WillOnce([&](jclass, jfieldID) -> jobject {
        return tracker.AllocateNew<jobject>();
      });
  EXPECT_CALL(mock_env, NewFloatArray(_))
      .WillRepeatedly([&](jsize) -> jfloatArray {
        return tracker.AllocateNew<jfloatArray>();
      });
  EXPECT_CALL(mock_env, SetFloatArrayRegion(_, _, _, _))
      .WillRepeatedly(Return());
  EXPECT_CALL(mock_env, CallVoidMethodV(_, _, _)).WillRepeatedly(Return());

  fml::jni::JavaObjectWeakGlobalRef flutter_jni_ref(&mock_env, kFlutterJniObj);
  PlatformViewAndroidJNIImpl android_jni(flutter_jni_ref);

  DlPathBuilder path_builder;
  path_builder.SetFillType(DlPathFillType::kOdd)
      .MoveTo({0.0f, 0.0f})
      .LineTo({10.0f, 5.0f})
      .QuadraticCurveTo({15.0f, 0.0f}, {20.0f, 10.0f})
      .ConicCurveTo({25.0f, 15.0f}, {30.0f, 10.0f}, 0.707f)
      .CubicCurveTo({35.0f, 0.0f}, {40.0f, 20.0f}, {50.0f, 10.0f})
      .Close();

  MutatorsStack stack;
  stack.PushTransform(DlMatrix::MakeTranslation({2.0f, 3.0f}));
  stack.PushClipRect(DlRect::MakeLTRB(0.0f, 0.0f, 40.0f, 40.0f));
  stack.PushClipRRect(
      DlRoundRect::MakeRectRadius(DlRect::MakeLTRB(0, 0, 20, 20), 4.0f));
  stack.PushClipRSE(DlRoundSuperellipse::MakeRectRadius(
      DlRect::MakeLTRB(0, 0, 20, 20), 4.0f));
  stack.PushOpacity(180);
  stack.PushClipPath(path_builder.TakePath());

  android_jni.onDisplayPlatformView2(7, 0, 0, 100, 100, 100, 100, stack);

  EXPECT_EQ(tracker.frames.size(), 1u);
  EXPECT_EQ(tracker.ActiveCount(), 0u);
}

TEST_F(PlatformViewAndroidJNIImplTest,
       CreateOverlaySurfaceDeletesLocalRefsAndPopsLocalFrame) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  LocalRefTracker tracker;
  tracker.InstallDefaults(mock_env);

  const jobject kFlutterJniObj = reinterpret_cast<jobject>(0x1001);

  static int from_surface_calls;
  static jobject last_surface_arg;
  from_surface_calls = 0;
  last_surface_arg = nullptr;

  auto& from_surface_proc =
      impeller::android::GetMutableProcTable().ANativeWindow_fromSurface;
  auto* real_from_surface = from_surface_proc.proc;
  from_surface_proc.proc = [](JNIEnv* env, jobject surface) -> ANativeWindow* {
    ++from_surface_calls;
    last_surface_arg = surface;
    // Simulate ANativeWindow_fromSurface leaving an internal local ref in the
    // active frame (https://code.google.com/p/android/issues/detail?id=68174).
    env->NewLocalRef(reinterpret_cast<jobject>(0x9999));
    return nullptr;
  };
  struct RestoreProc {
    decltype(from_surface_proc.proc)* slot;
    decltype(from_surface_proc.proc) prev;
    ~RestoreProc() { *slot = prev; }
  } restore{&from_surface_proc.proc, real_from_surface};

  EXPECT_CALL(mock_env, ExceptionCheck()).WillRepeatedly(Return(JNI_FALSE));

  fml::jni::JavaObjectWeakGlobalRef flutter_jni_ref(&mock_env, kFlutterJniObj);
  PlatformViewAndroidJNIImpl android_jni(flutter_jni_ref);

  for (int variant = 0; variant < 2; ++variant) {
    from_surface_calls = 0;
    last_surface_arg = nullptr;
    jobject overlay_obj = nullptr;
    jobject surface_obj = nullptr;

    EXPECT_CALL(mock_env, CallObjectMethodV(_, _, _))
        .Times(2)
        .WillOnce([&](jobject obj, jmethodID, va_list) -> jobject {
          EXPECT_EQ(obj, kFlutterJniObj);
          overlay_obj = tracker.AllocateNew<jobject>();
          return overlay_obj;
        })
        .WillOnce([&](jobject obj, jmethodID, va_list) -> jobject {
          EXPECT_EQ(obj, overlay_obj);
          surface_obj = tracker.AllocateNew<jobject>();
          return surface_obj;
        });
    EXPECT_CALL(mock_env, CallIntMethodV(_, _, _))
        .WillOnce([&](jobject obj, jmethodID, va_list) -> jint {
          EXPECT_EQ(obj, overlay_obj);
          return 42 + variant;
        });

    auto metadata = (variant == 0)
                        ? android_jni.FlutterViewCreateOverlaySurface()
                        : android_jni.createOverlaySurface2();
    ASSERT_NE(metadata, nullptr);
    EXPECT_EQ(metadata->id, 42 + variant);
    EXPECT_EQ(from_surface_calls, 1);
    EXPECT_EQ(last_surface_arg, surface_obj);
    EXPECT_EQ(tracker.frames.size(), 1u);
    EXPECT_EQ(tracker.ActiveCount(), 0u);
  }
}

TEST_F(PlatformViewAndroidJNIImplTest,
       ComputePlatformResolvedLocaleDeletesLocalRefsAndHandlesNullResult) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();
  LocalRefTracker tracker;
  tracker.InstallDefaults(mock_env);

  const jobject kFlutterJniObj = reinterpret_cast<jobject>(0x1001);
  std::unordered_map<jstring, std::u16string> string_table;

  EXPECT_CALL(mock_env, ExceptionCheck()).WillRepeatedly(Return(JNI_FALSE));
  EXPECT_CALL(mock_env, FindClass(_))
      .WillRepeatedly(
          [&](const char*) -> jclass { return tracker.AllocateNew<jclass>(); });
  EXPECT_CALL(mock_env, NewObjectArray(_, _, _))
      .WillRepeatedly([&](jsize, jclass, jobject) -> jobjectArray {
        return tracker.AllocateNew<jobjectArray>();
      });
  EXPECT_CALL(mock_env, NewString(_, _))
      .WillRepeatedly([&](const jchar* chars, jsize len) -> jstring {
        jstring s = tracker.AllocateNew<jstring>();
        string_table[s] =
            std::u16string(reinterpret_cast<const char16_t*>(chars), len);
        return s;
      });
  EXPECT_CALL(mock_env, SetObjectArrayElement(_, _, _))
      .WillRepeatedly(Return());
  EXPECT_CALL(mock_env, GetStringChars(_, _))
      .WillRepeatedly([&](jstring s, jboolean*) -> const jchar* {
        return reinterpret_cast<const char*>(string_table.at(s).data()) !=
                       nullptr
                   ? reinterpret_cast<const jchar*>(string_table.at(s).data())
                   : nullptr;
      });
  EXPECT_CALL(mock_env, GetStringLength(_))
      .WillRepeatedly([&](jstring s) -> jsize {
        return static_cast<jsize>(string_table.at(s).size());
      });
  EXPECT_CALL(mock_env, ReleaseStringChars(_, _)).WillRepeatedly(Return());

  fml::jni::JavaObjectWeakGlobalRef flutter_jni_ref(&mock_env, kFlutterJniObj);
  PlatformViewAndroidJNIImpl android_jni(flutter_jni_ref);

  // Case 1: Non-null 3-element result array deletes both the array ref and
  // each element jstring local ref.
  jobjectArray result_array = nullptr;
  const std::vector<std::u16string> kResolved = {u"en", u"US", u""};
  EXPECT_CALL(mock_env, CallObjectMethodV(kFlutterJniObj, _, _))
      .WillOnce([&](jobject, jmethodID, va_list) -> jobject {
        result_array = tracker.AllocateNew<jobjectArray>();
        return result_array;
      });
  EXPECT_CALL(mock_env, GetArrayLength(_)).WillOnce([&](jarray arr) -> jsize {
    EXPECT_EQ(arr, result_array);
    return static_cast<jsize>(kResolved.size());
  });
  EXPECT_CALL(mock_env, GetObjectArrayElement(_, _))
      .Times(3)
      .WillRepeatedly([&](jobjectArray arr, jsize idx) -> jobject {
        EXPECT_EQ(arr, result_array);
        jstring elem = tracker.AllocateNew<jstring>();
        string_table[elem] = kResolved.at(static_cast<size_t>(idx));
        return elem;
      });

  auto resolved = android_jni.FlutterViewComputePlatformResolvedLocale(
      {"en", "US", "Latn"});
  ASSERT_NE(resolved, nullptr);
  EXPECT_THAT(*resolved, ElementsAre("en", "US", ""));
  EXPECT_EQ(tracker.ActiveCount(), 0u);

  // Case 2: Null result array does not call GetArrayLength(nullptr) and leaves
  // zero leaked local refs.
  EXPECT_CALL(mock_env, CallObjectMethodV(kFlutterJniObj, _, _))
      .WillOnce(Return(nullptr));
  EXPECT_CALL(mock_env, GetArrayLength(_)).Times(0);

  auto empty_resolved =
      android_jni.FlutterViewComputePlatformResolvedLocale({"en", "US", ""});
  ASSERT_NE(empty_resolved, nullptr);
  EXPECT_TRUE(empty_resolved->empty());
  EXPECT_EQ(tracker.ActiveCount(), 0u);
}

}  // namespace testing
}  // namespace flutter
