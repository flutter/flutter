// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_JNI_MOCK_JNI_ENV_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_JNI_MOCK_JNI_ENV_H_

#include <jni.h>

namespace flutter {

class MockJavaVM : public JavaVM {
 public:
  MockJavaVM() {
    functions = &jni_invoke_;

    jni_invoke_.DestroyJavaVM = DoDestroyJavaVM;
    jni_invoke_.AttachCurrentThread = DoAttachCurrentThread;
    jni_invoke_.DetachCurrentThread = DoDetachCurrentThread;
    jni_invoke_.GetEnv = DoGetEnv;
    jni_invoke_.AttachCurrentThreadAsDaemon = DoAttachCurrentThreadAsDaemon;
  }

  void SetJNIEnv(JNIEnv* env) { env_ = env; }

 private:
  static jint DoDestroyJavaVM(JavaVM* vm) { return JNI_OK; }
  static jint DoAttachCurrentThread(JavaVM* vm,
                                    JNIEnv** p_env,
                                    void* thr_args) {
    return JNI_OK;
  }
  static jint DoDetachCurrentThread(JavaVM* vm) { return JNI_OK; }
  static jint DoGetEnv(JavaVM* vm, void** env, jint version) {
    *env = static_cast<MockJavaVM*>(vm)->env_;
    return JNI_OK;
  }
  static jint DoAttachCurrentThreadAsDaemon(JavaVM* vm,
                                            JNIEnv** p_env,
                                            void* thr_args) {
    return JNI_OK;
  }

  JNIEnv* env_ = nullptr;
  JNIInvokeInterface jni_invoke_;
};

class MockableJNIEnv : public JNIEnv {
 public:
  MockableJNIEnv() {
    // Replace the JNIEnv's function table with wrappers that invoke the
    // mockable virtual methods in this class.
    functions = &jni_;
    jni_.CallObjectMethod = WrapCallObjectMethod;
    jni_.CallObjectMethodV = WrapCallObjectMethodV;
    jni_.DeleteGlobalRef = WrapDeleteGlobalRef;
    jni_.DeleteLocalRef = WrapDeleteLocalRef;
    jni_.ExceptionCheck = WrapExceptionCheck;
    jni_.ExceptionClear = WrapExceptionClear;
    jni_.ExceptionDescribe = WrapExceptionDescribe;
    jni_.ExceptionOccurred = WrapExceptionOccurred;
    jni_.FindClass = WrapFindClass;
    jni_.GetFieldID = WrapGetFieldID;
    jni_.GetMethodID = WrapGetMethodID;
    jni_.GetObjectRefType = WrapGetObjectRefType;
    jni_.GetStaticFieldID = WrapGetStaticFieldID;
    jni_.GetStaticMethodID = WrapGetStaticMethodID;
    jni_.NewGlobalRef = WrapNewGlobalRef;
    jni_.NewLocalRef = WrapNewLocalRef;
    jni_.RegisterNatives = WrapRegisterNatives;
  }

  virtual jobject CallObjectMethodV(jobject, jmethodID, va_list) = 0;
  virtual void DeleteGlobalRef(jobject) = 0;
  virtual void DeleteLocalRef(jobject) = 0;
  virtual jboolean ExceptionCheck() = 0;
  virtual void ExceptionClear() = 0;
  virtual void ExceptionDescribe() = 0;
  virtual jthrowable ExceptionOccurred() = 0;
  virtual jclass FindClass(const char*) = 0;
  virtual jfieldID GetFieldID(jclass, const char*, const char*) = 0;
  virtual jmethodID GetMethodID(jclass, const char*, const char*) = 0;
  virtual jobjectRefType GetObjectRefType(jobject) = 0;
  virtual jfieldID GetStaticFieldID(jclass, const char*, const char*) = 0;
  virtual jmethodID GetStaticMethodID(jclass, const char*, const char*) = 0;
  virtual jobject NewGlobalRef(jobject) = 0;
  virtual jobject NewLocalRef(jobject) = 0;
  virtual jint RegisterNatives(jclass, const JNINativeMethod*, jint) = 0;

 private:
  static jobject WrapCallObjectMethod(JNIEnv* env,
                                      jobject obj,
                                      jmethodID methodID,
                                      ...) {
    va_list args;
    va_start(args, methodID);
    jobject result = WrapCallObjectMethodV(env, obj, methodID, args);
    va_end(args);
    return result;
  }
  static jobject WrapCallObjectMethodV(JNIEnv* env,
                                       jobject obj,
                                       jmethodID methodID,
                                       va_list args) {
    return static_cast<MockableJNIEnv*>(env)->CallObjectMethodV(obj, methodID,
                                                                args);
  }
  static void WrapDeleteGlobalRef(JNIEnv* env, jobject globalRef) {
    static_cast<MockableJNIEnv*>(env)->DeleteGlobalRef(globalRef);
  }
  static void WrapDeleteLocalRef(JNIEnv* env, jobject localRef) {
    static_cast<MockableJNIEnv*>(env)->DeleteLocalRef(localRef);
  }
  static jboolean WrapExceptionCheck(JNIEnv* env) {
    return static_cast<MockableJNIEnv*>(env)->ExceptionCheck();
  }
  static void WrapExceptionClear(JNIEnv* env) {
    static_cast<MockableJNIEnv*>(env)->ExceptionClear();
  }
  static void WrapExceptionDescribe(JNIEnv* env) {
    static_cast<MockableJNIEnv*>(env)->ExceptionDescribe();
  }
  static jthrowable WrapExceptionOccurred(JNIEnv* env) {
    return static_cast<MockableJNIEnv*>(env)->ExceptionOccurred();
  }
  static jclass WrapFindClass(JNIEnv* env, const char* name) {
    return static_cast<MockableJNIEnv*>(env)->FindClass(name);
  }
  static jfieldID WrapGetFieldID(JNIEnv* env,
                                 jclass clazz,
                                 const char* name,
                                 const char* sig) {
    return static_cast<MockableJNIEnv*>(env)->GetFieldID(clazz, name, sig);
  }
  static jmethodID WrapGetMethodID(JNIEnv* env,
                                   jclass clazz,
                                   const char* name,
                                   const char* sig) {
    return static_cast<MockableJNIEnv*>(env)->GetMethodID(clazz, name, sig);
  }
  static jobjectRefType WrapGetObjectRefType(JNIEnv* env, jobject obj) {
    return static_cast<MockableJNIEnv*>(env)->GetObjectRefType(obj);
  }
  static jfieldID WrapGetStaticFieldID(JNIEnv* env,
                                       jclass clazz,
                                       const char* name,
                                       const char* sig) {
    return static_cast<MockableJNIEnv*>(env)->GetStaticFieldID(clazz, name,
                                                               sig);
  }
  static jmethodID WrapGetStaticMethodID(JNIEnv* env,
                                         jclass clazz,
                                         const char* name,
                                         const char* sig) {
    return static_cast<MockableJNIEnv*>(env)->GetStaticMethodID(clazz, name,
                                                                sig);
  }
  static jobject WrapNewGlobalRef(JNIEnv* env, jobject ref) {
    return static_cast<MockableJNIEnv*>(env)->NewGlobalRef(ref);
  }
  static jobject WrapNewLocalRef(JNIEnv* env, jobject ref) {
    return static_cast<MockableJNIEnv*>(env)->NewLocalRef(ref);
  }
  static jint WrapRegisterNatives(JNIEnv* env,
                                  jclass clazz,
                                  const JNINativeMethod* methods,
                                  jint nMethods) {
    return static_cast<MockableJNIEnv*>(env)->RegisterNatives(clazz, methods,
                                                              nMethods);
  }

  JNINativeInterface jni_ = {};
};

class MockJNIEnv : public MockableJNIEnv {
 public:
  MOCK_METHOD(jobject,
              CallObjectMethodV,
              (jobject, jmethodID, va_list),
              (override));
  MOCK_METHOD(void, DeleteGlobalRef, (jobject), (override));
  MOCK_METHOD(void, DeleteLocalRef, (jobject), (override));
  MOCK_METHOD(jboolean, ExceptionCheck, (), (override));
  MOCK_METHOD(void, ExceptionClear, (), (override));
  MOCK_METHOD(void, ExceptionDescribe, (), (override));
  MOCK_METHOD(jthrowable, ExceptionOccurred, (), (override));
  MOCK_METHOD(jclass, FindClass, (const char*), (override));
  MOCK_METHOD(jfieldID,
              GetFieldID,
              (jclass, const char*, const char*),
              (override));
  MOCK_METHOD(jmethodID,
              GetMethodID,
              (jclass, const char*, const char*),
              (override));
  MOCK_METHOD(jobjectRefType, GetObjectRefType, (jobject), (override));
  MOCK_METHOD(jfieldID,
              GetStaticFieldID,
              (jclass, const char*, const char*),
              (override));
  MOCK_METHOD(jmethodID,
              GetStaticMethodID,
              (jclass, const char*, const char*),
              (override));
  MOCK_METHOD(jobject, NewGlobalRef, (jobject), (override));
  MOCK_METHOD(jobject, NewLocalRef, (jobject), (override));
  MOCK_METHOD(jint,
              RegisterNatives,
              (jclass, const JNINativeMethod*, jint),
              (override));
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_JNI_MOCK_JNI_ENV_H_
