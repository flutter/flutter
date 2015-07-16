// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/jni_android.h"

#include <map>

#include "base/android/build_info.h"
#include "base/android/jni_string.h"
#include "base/android/jni_utils.h"
#include "base/lazy_instance.h"
#include "base/logging.h"

namespace {
using base::android::GetClass;
using base::android::MethodID;
using base::android::ScopedJavaLocalRef;

bool g_disable_manual_jni_registration = false;

JavaVM* g_jvm = NULL;
// Leak the global app context, as it is used from a non-joinable worker thread
// that may still be running at shutdown. There is no harm in doing this.
base::LazyInstance<base::android::ScopedJavaGlobalRef<jobject> >::Leaky
    g_application_context = LAZY_INSTANCE_INITIALIZER;
base::LazyInstance<base::android::ScopedJavaGlobalRef<jobject> >::Leaky
    g_class_loader = LAZY_INSTANCE_INITIALIZER;
jmethodID g_class_loader_load_class_method_id = 0;

}  // namespace

namespace base {
namespace android {

bool IsManualJniRegistrationDisabled() {
  return g_disable_manual_jni_registration;
}

void DisableManualJniRegistration() {
  DCHECK(!g_disable_manual_jni_registration);
  g_disable_manual_jni_registration = true;
}

JNIEnv* AttachCurrentThread() {
  DCHECK(g_jvm);
  JNIEnv* env = NULL;
  jint ret = g_jvm->AttachCurrentThread(&env, NULL);
  DCHECK_EQ(JNI_OK, ret);
  return env;
}

JNIEnv* AttachCurrentThreadWithName(const std::string& thread_name) {
  DCHECK(g_jvm);
  JavaVMAttachArgs args;
  args.version = JNI_VERSION_1_2;
  args.name = thread_name.c_str();
  args.group = NULL;
  JNIEnv* env = NULL;
  jint ret = g_jvm->AttachCurrentThread(&env, &args);
  DCHECK_EQ(JNI_OK, ret);
  return env;
}

void DetachFromVM() {
  // Ignore the return value, if the thread is not attached, DetachCurrentThread
  // will fail. But it is ok as the native thread may never be attached.
  if (g_jvm)
    g_jvm->DetachCurrentThread();
}

void InitVM(JavaVM* vm) {
  DCHECK(!g_jvm);
  g_jvm = vm;
}

bool IsVMInitialized() {
  return g_jvm != NULL;
}

void InitApplicationContext(JNIEnv* env, const JavaRef<jobject>& context) {
  if (env->IsSameObject(g_application_context.Get().obj(), context.obj())) {
    // It's safe to set the context more than once if it's the same context.
    return;
  }
  DCHECK(g_application_context.Get().is_null());
  g_application_context.Get().Reset(context);
}

void InitReplacementClassLoader(JNIEnv* env,
                                const JavaRef<jobject>& class_loader) {
  DCHECK(g_class_loader.Get().is_null());
  DCHECK(!class_loader.is_null());

  ScopedJavaLocalRef<jclass> class_loader_clazz =
      GetClass(env, "java/lang/ClassLoader");
  CHECK(!ClearException(env));
  g_class_loader_load_class_method_id =
      env->GetMethodID(class_loader_clazz.obj(),
                       "loadClass",
                       "(Ljava/lang/String;)Ljava/lang/Class;");
  CHECK(!ClearException(env));

  DCHECK(env->IsInstanceOf(class_loader.obj(), class_loader_clazz.obj()));
  g_class_loader.Get().Reset(class_loader);
}

const jobject GetApplicationContext() {
  DCHECK(!g_application_context.Get().is_null());
  return g_application_context.Get().obj();
}

ScopedJavaLocalRef<jclass> GetClass(JNIEnv* env, const char* class_name) {
  jclass clazz;
  if (!g_class_loader.Get().is_null()) {
    // ClassLoader.loadClass expects a classname with components separated by
    // dots instead of the slashes that JNIEnv::FindClass expects. The JNI
    // generator generates names with slashes, so we have to replace them here.
    // TODO(torne): move to an approach where we always use ClassLoader except
    // for the special case of base::android::GetClassLoader(), and change the
    // JNI generator to generate dot-separated names. http://crbug.com/461773
    size_t bufsize = strlen(class_name) + 1;
    char dotted_name[bufsize];
    memmove(dotted_name, class_name, bufsize);
    for (size_t i = 0; i < bufsize; ++i) {
      if (dotted_name[i] == '/') {
        dotted_name[i] = '.';
      }
    }

    clazz = static_cast<jclass>(
        env->CallObjectMethod(g_class_loader.Get().obj(),
                              g_class_loader_load_class_method_id,
                              ConvertUTF8ToJavaString(env, dotted_name).obj()));
  } else {
    clazz = env->FindClass(class_name);
  }
  CHECK(!ClearException(env) && clazz) << "Failed to find class " << class_name;
  return ScopedJavaLocalRef<jclass>(env, clazz);
}

jclass LazyGetClass(
    JNIEnv* env,
    const char* class_name,
    base::subtle::AtomicWord* atomic_class_id) {
  COMPILE_ASSERT(sizeof(subtle::AtomicWord) >= sizeof(jclass),
                 AtomicWord_SmallerThan_jMethodID);
  subtle::AtomicWord value = base::subtle::Acquire_Load(atomic_class_id);
  if (value)
    return reinterpret_cast<jclass>(value);
  ScopedJavaGlobalRef<jclass> clazz;
  clazz.Reset(GetClass(env, class_name));
  subtle::AtomicWord null_aw = reinterpret_cast<subtle::AtomicWord>(NULL);
  subtle::AtomicWord cas_result = base::subtle::Release_CompareAndSwap(
      atomic_class_id,
      null_aw,
      reinterpret_cast<subtle::AtomicWord>(clazz.obj()));
  if (cas_result == null_aw) {
    // We intentionally leak the global ref since we now storing it as a raw
    // pointer in |atomic_class_id|.
    return clazz.Release();
  } else {
    return reinterpret_cast<jclass>(cas_result);
  }
}

template<MethodID::Type type>
jmethodID MethodID::Get(JNIEnv* env,
                        jclass clazz,
                        const char* method_name,
                        const char* jni_signature) {
  jmethodID id = type == TYPE_STATIC ?
      env->GetStaticMethodID(clazz, method_name, jni_signature) :
      env->GetMethodID(clazz, method_name, jni_signature);
  CHECK(base::android::ClearException(env) || id) <<
      "Failed to find " <<
      (type == TYPE_STATIC ? "static " : "") <<
      "method " << method_name << " " << jni_signature;
  return id;
}

// If |atomic_method_id| set, it'll return immediately. Otherwise, it'll call
// into ::Get() above. If there's a race, it's ok since the values are the same
// (and the duplicated effort will happen only once).
template<MethodID::Type type>
jmethodID MethodID::LazyGet(JNIEnv* env,
                            jclass clazz,
                            const char* method_name,
                            const char* jni_signature,
                            base::subtle::AtomicWord* atomic_method_id) {
  COMPILE_ASSERT(sizeof(subtle::AtomicWord) >= sizeof(jmethodID),
                 AtomicWord_SmallerThan_jMethodID);
  subtle::AtomicWord value = base::subtle::Acquire_Load(atomic_method_id);
  if (value)
    return reinterpret_cast<jmethodID>(value);
  jmethodID id = MethodID::Get<type>(env, clazz, method_name, jni_signature);
  base::subtle::Release_Store(
      atomic_method_id, reinterpret_cast<subtle::AtomicWord>(id));
  return id;
}

// Various template instantiations.
template jmethodID MethodID::Get<MethodID::TYPE_STATIC>(
    JNIEnv* env, jclass clazz, const char* method_name,
    const char* jni_signature);

template jmethodID MethodID::Get<MethodID::TYPE_INSTANCE>(
    JNIEnv* env, jclass clazz, const char* method_name,
    const char* jni_signature);

template jmethodID MethodID::LazyGet<MethodID::TYPE_STATIC>(
    JNIEnv* env, jclass clazz, const char* method_name,
    const char* jni_signature, base::subtle::AtomicWord* atomic_method_id);

template jmethodID MethodID::LazyGet<MethodID::TYPE_INSTANCE>(
    JNIEnv* env, jclass clazz, const char* method_name,
    const char* jni_signature, base::subtle::AtomicWord* atomic_method_id);

bool HasException(JNIEnv* env) {
  return env->ExceptionCheck() != JNI_FALSE;
}

bool ClearException(JNIEnv* env) {
  if (!HasException(env))
    return false;
  env->ExceptionDescribe();
  env->ExceptionClear();
  return true;
}

void CheckException(JNIEnv* env) {
  if (!HasException(env))
    return;

  // Exception has been found, might as well tell breakpad about it.
  jthrowable java_throwable = env->ExceptionOccurred();
  if (java_throwable) {
    // Clear the pending exception, since a local reference is now held.
    env->ExceptionDescribe();
    env->ExceptionClear();

    // Set the exception_string in BuildInfo so that breakpad can read it.
    // RVO should avoid any extra copies of the exception string.
    base::android::BuildInfo::GetInstance()->SetJavaExceptionInfo(
        GetJavaExceptionInfo(env, java_throwable));
  }

  // Now, feel good about it and die.
  CHECK(false) << "Please include Java exception stack in crash report";
}

std::string GetJavaExceptionInfo(JNIEnv* env, jthrowable java_throwable) {
  ScopedJavaLocalRef<jclass> throwable_clazz =
      GetClass(env, "java/lang/Throwable");
  jmethodID throwable_printstacktrace =
      MethodID::Get<MethodID::TYPE_INSTANCE>(
          env, throwable_clazz.obj(), "printStackTrace",
          "(Ljava/io/PrintStream;)V");

  // Create an instance of ByteArrayOutputStream.
  ScopedJavaLocalRef<jclass> bytearray_output_stream_clazz =
      GetClass(env, "java/io/ByteArrayOutputStream");
  jmethodID bytearray_output_stream_constructor =
      MethodID::Get<MethodID::TYPE_INSTANCE>(
          env, bytearray_output_stream_clazz.obj(), "<init>", "()V");
  jmethodID bytearray_output_stream_tostring =
      MethodID::Get<MethodID::TYPE_INSTANCE>(
          env, bytearray_output_stream_clazz.obj(), "toString",
          "()Ljava/lang/String;");
  ScopedJavaLocalRef<jobject> bytearray_output_stream(env,
      env->NewObject(bytearray_output_stream_clazz.obj(),
                     bytearray_output_stream_constructor));

  // Create an instance of PrintStream.
  ScopedJavaLocalRef<jclass> printstream_clazz =
      GetClass(env, "java/io/PrintStream");
  jmethodID printstream_constructor =
      MethodID::Get<MethodID::TYPE_INSTANCE>(
          env, printstream_clazz.obj(), "<init>",
          "(Ljava/io/OutputStream;)V");
  ScopedJavaLocalRef<jobject> printstream(env,
      env->NewObject(printstream_clazz.obj(), printstream_constructor,
                     bytearray_output_stream.obj()));

  // Call Throwable.printStackTrace(PrintStream)
  env->CallVoidMethod(java_throwable, throwable_printstacktrace,
      printstream.obj());

  // Call ByteArrayOutputStream.toString()
  ScopedJavaLocalRef<jstring> exception_string(
      env, static_cast<jstring>(
          env->CallObjectMethod(bytearray_output_stream.obj(),
                                bytearray_output_stream_tostring)));

  return ConvertJavaStringToUTF8(exception_string);
}


}  // namespace android
}  // namespace base
