// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_JNI_MOCK_JNI_ENV_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_JNI_MOCK_JNI_ENV_H_

#include <jni.h>

#include "gmock/gmock.h"

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
    if (p_env) {
      *p_env = static_cast<MockJavaVM*>(vm)->env_;
    }
    return JNI_OK;
  }
  static jint DoDetachCurrentThread(JavaVM* vm) { return JNI_OK; }
  static jint DoGetEnv(JavaVM* vm, void** env, jint version) {
    if (env) {
      *env = static_cast<MockJavaVM*>(vm)->env_;
    }
    return JNI_OK;
  }
  static jint DoAttachCurrentThreadAsDaemon(JavaVM* vm,
                                            JNIEnv** p_env,
                                            void* thr_args) {
    if (p_env) {
      *p_env = static_cast<MockJavaVM*>(vm)->env_;
    }
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
    jni_.CallVoidMethod = WrapCallVoidMethod;
    jni_.CallVoidMethodV = WrapCallVoidMethodV;
    jni_.CallIntMethod = WrapCallIntMethod;
    jni_.CallIntMethodV = WrapCallIntMethodV;
    jni_.CallFloatMethod = WrapCallFloatMethod;
    jni_.CallFloatMethodV = WrapCallFloatMethodV;
    jni_.CallBooleanMethod = WrapCallBooleanMethod;
    jni_.CallBooleanMethodV = WrapCallBooleanMethodV;
    jni_.DeleteGlobalRef = WrapDeleteGlobalRef;
    jni_.DeleteLocalRef = WrapDeleteLocalRef;
    jni_.ExceptionCheck = WrapExceptionCheck;
    jni_.ExceptionClear = WrapExceptionClear;
    jni_.ExceptionDescribe = WrapExceptionDescribe;
    jni_.ExceptionOccurred = WrapExceptionOccurred;
    jni_.FindClass = WrapFindClass;
    jni_.GetFieldID = WrapGetFieldID;
    jni_.GetMethodID = WrapGetMethodID;
    jni_.GetObjectClass = WrapGetObjectClass;
    jni_.GetObjectRefType = WrapGetObjectRefType;
    jni_.GetStaticFieldID = WrapGetStaticFieldID;
    jni_.GetStaticMethodID = WrapGetStaticMethodID;
    jni_.NewGlobalRef = WrapNewGlobalRef;
    jni_.NewLocalRef = WrapNewLocalRef;
    jni_.NewObject = WrapNewObject;
    jni_.NewObjectV = WrapNewObjectV;
    jni_.RegisterNatives = WrapRegisterNatives;
    jni_.GetArrayLength = WrapGetArrayLength;
    jni_.GetIntArrayRegion = WrapGetIntArrayRegion;
    jni_.GetObjectArrayElement = WrapGetObjectArrayElement;
    jni_.GetStringLength = WrapGetStringLength;
    jni_.GetStringChars = WrapGetStringChars;
    jni_.ReleaseStringChars = WrapReleaseStringChars;
    jni_.NewFloatArray = WrapNewFloatArray;
    jni_.SetFloatArrayRegion = WrapSetFloatArrayRegion;
    jni_.PushLocalFrame = WrapPushLocalFrame;
    jni_.PopLocalFrame = WrapPopLocalFrame;
    jni_.NewDirectByteBuffer = WrapNewDirectByteBuffer;
    jni_.NewStringUTF = WrapNewStringUTF;
  }

  virtual jobject CallObjectMethodV(jobject, jmethodID, va_list) = 0;
  virtual void CallVoidMethodV(jobject, jmethodID, va_list) = 0;
  virtual jint CallIntMethodV(jobject, jmethodID, va_list) = 0;
  virtual jfloat CallFloatMethodV(jobject, jmethodID, va_list) = 0;
  virtual jboolean CallBooleanMethodV(jobject, jmethodID, va_list) = 0;
  virtual void DeleteGlobalRef(jobject) = 0;
  virtual void DeleteLocalRef(jobject) = 0;
  virtual jboolean ExceptionCheck() = 0;
  virtual void ExceptionClear() = 0;
  virtual void ExceptionDescribe() = 0;
  virtual jthrowable ExceptionOccurred() = 0;
  virtual jclass FindClass(const char*) = 0;
  virtual jfieldID GetFieldID(jclass, const char*, const char*) = 0;
  virtual jmethodID GetMethodID(jclass, const char*, const char*) = 0;
  virtual jclass GetObjectClass(jobject) = 0;
  virtual jobjectRefType GetObjectRefType(jobject) = 0;
  virtual jfieldID GetStaticFieldID(jclass, const char*, const char*) = 0;
  virtual jmethodID GetStaticMethodID(jclass, const char*, const char*) = 0;
  virtual jobject NewGlobalRef(jobject) = 0;
  virtual jobject NewLocalRef(jobject) = 0;
  virtual jobject NewObjectV(jclass, jmethodID, va_list) = 0;
  virtual jint RegisterNatives(jclass, const JNINativeMethod*, jint) = 0;
  virtual jsize GetArrayLength(jarray) = 0;
  virtual void GetIntArrayRegion(jintArray, jsize, jsize, jint*) = 0;
  virtual jobject GetObjectArrayElement(jobjectArray, jsize) = 0;
  virtual jsize GetStringLength(jstring) = 0;
  virtual const jchar* GetStringChars(jstring, jboolean*) = 0;
  virtual void ReleaseStringChars(jstring, const jchar*) = 0;
  virtual jfloatArray NewFloatArray(jsize) = 0;
  virtual void SetFloatArrayRegion(jfloatArray,
                                   jsize,
                                   jsize,
                                   const jfloat*) = 0;
  virtual jint PushLocalFrame(jint) = 0;
  virtual jobject PopLocalFrame(jobject) = 0;
  virtual jobject NewDirectByteBuffer(void*, jlong) = 0;
  virtual jstring NewStringUTF(const char*) = 0;

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
  static void WrapCallVoidMethod(JNIEnv* env,
                                 jobject obj,
                                 jmethodID methodID,
                                 ...) {
    va_list args;
    va_start(args, methodID);
    WrapCallVoidMethodV(env, obj, methodID, args);
    va_end(args);
  }
  static void WrapCallVoidMethodV(JNIEnv* env,
                                  jobject obj,
                                  jmethodID methodID,
                                  va_list args) {
    static_cast<MockableJNIEnv*>(env)->CallVoidMethodV(obj, methodID, args);
  }
  static jint WrapCallIntMethod(JNIEnv* env,
                                jobject obj,
                                jmethodID methodID,
                                ...) {
    va_list args;
    va_start(args, methodID);
    jint result = WrapCallIntMethodV(env, obj, methodID, args);
    va_end(args);
    return result;
  }
  static jint WrapCallIntMethodV(JNIEnv* env,
                                 jobject obj,
                                 jmethodID methodID,
                                 va_list args) {
    return static_cast<MockableJNIEnv*>(env)->CallIntMethodV(obj, methodID,
                                                             args);
  }
  static jfloat WrapCallFloatMethod(JNIEnv* env,
                                    jobject obj,
                                    jmethodID methodID,
                                    ...) {
    va_list args;
    va_start(args, methodID);
    jfloat result = WrapCallFloatMethodV(env, obj, methodID, args);
    va_end(args);
    return result;
  }
  static jfloat WrapCallFloatMethodV(JNIEnv* env,
                                     jobject obj,
                                     jmethodID methodID,
                                     va_list args) {
    return static_cast<MockableJNIEnv*>(env)->CallFloatMethodV(obj, methodID,
                                                               args);
  }
  static jboolean WrapCallBooleanMethod(JNIEnv* env,
                                        jobject obj,
                                        jmethodID methodID,
                                        ...) {
    va_list args;
    va_start(args, methodID);
    jboolean result = WrapCallBooleanMethodV(env, obj, methodID, args);
    va_end(args);
    return result;
  }
  static jboolean WrapCallBooleanMethodV(JNIEnv* env,
                                         jobject obj,
                                         jmethodID methodID,
                                         va_list args) {
    return static_cast<MockableJNIEnv*>(env)->CallBooleanMethodV(obj, methodID,
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
  static jclass WrapGetObjectClass(JNIEnv* env, jobject obj) {
    return static_cast<MockableJNIEnv*>(env)->GetObjectClass(obj);
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
  static jobject WrapNewObject(JNIEnv* env,
                               jclass clazz,
                               jmethodID methodID,
                               ...) {
    va_list args;
    va_start(args, methodID);
    jobject result = WrapNewObjectV(env, clazz, methodID, args);
    va_end(args);
    return result;
  }
  static jobject WrapNewObjectV(JNIEnv* env,
                                jclass clazz,
                                jmethodID methodID,
                                va_list args) {
    return static_cast<MockableJNIEnv*>(env)->NewObjectV(clazz, methodID, args);
  }
  static jint WrapRegisterNatives(JNIEnv* env,
                                  jclass clazz,
                                  const JNINativeMethod* methods,
                                  jint nMethods) {
    return static_cast<MockableJNIEnv*>(env)->RegisterNatives(clazz, methods,
                                                              nMethods);
  }
  static jsize WrapGetArrayLength(JNIEnv* env, jarray array) {
    return static_cast<MockableJNIEnv*>(env)->GetArrayLength(array);
  }
  static void WrapGetIntArrayRegion(JNIEnv* env,
                                    jintArray array,
                                    jsize start,
                                    jsize len,
                                    jint* buf) {
    static_cast<MockableJNIEnv*>(env)->GetIntArrayRegion(array, start, len,
                                                         buf);
  }
  static jobject WrapGetObjectArrayElement(JNIEnv* env,
                                           jobjectArray array,
                                           jsize index) {
    return static_cast<MockableJNIEnv*>(env)->GetObjectArrayElement(array,
                                                                    index);
  }
  static jsize WrapGetStringLength(JNIEnv* env, jstring string) {
    return static_cast<MockableJNIEnv*>(env)->GetStringLength(string);
  }
  static const jchar* WrapGetStringChars(JNIEnv* env,
                                         jstring string,
                                         jboolean* is_copy) {
    return static_cast<MockableJNIEnv*>(env)->GetStringChars(string, is_copy);
  }
  static void WrapReleaseStringChars(JNIEnv* env,
                                     jstring string,
                                     const jchar* chars) {
    static_cast<MockableJNIEnv*>(env)->ReleaseStringChars(string, chars);
  }
  static jfloatArray WrapNewFloatArray(JNIEnv* env, jsize length) {
    return static_cast<MockableJNIEnv*>(env)->NewFloatArray(length);
  }
  static void WrapSetFloatArrayRegion(JNIEnv* env,
                                      jfloatArray array,
                                      jsize start,
                                      jsize len,
                                      const jfloat* buf) {
    static_cast<MockableJNIEnv*>(env)->SetFloatArrayRegion(array, start, len,
                                                           buf);
  }
  static jint WrapPushLocalFrame(JNIEnv* env, jint capacity) {
    return static_cast<MockableJNIEnv*>(env)->PushLocalFrame(capacity);
  }
  static jobject WrapPopLocalFrame(JNIEnv* env, jobject result) {
    return static_cast<MockableJNIEnv*>(env)->PopLocalFrame(result);
  }
  static jobject WrapNewDirectByteBuffer(JNIEnv* env,
                                         void* address,
                                         jlong capacity) {
    return static_cast<MockableJNIEnv*>(env)->NewDirectByteBuffer(address,
                                                                  capacity);
  }
  static jstring WrapNewStringUTF(JNIEnv* env, const char* bytes) {
    return static_cast<MockableJNIEnv*>(env)->NewStringUTF(bytes);
  }

  JNINativeInterface jni_ = {};
};

class MockJNIEnv : public MockableJNIEnv {
 public:
  MockJNIEnv() {
    ON_CALL(*this, PushLocalFrame(::testing::_))
        .WillByDefault(::testing::Return(0));
    ON_CALL(*this, PopLocalFrame(::testing::_))
        .WillByDefault(::testing::ReturnArg<0>());
    ON_CALL(*this, ExceptionCheck())
        .WillByDefault(::testing::Return(JNI_FALSE));
  }

  MOCK_METHOD(jobject,
              CallObjectMethodV,
              (jobject, jmethodID, va_list),
              (override));
  MOCK_METHOD(void, CallVoidMethodV, (jobject, jmethodID, va_list), (override));
  MOCK_METHOD(jint, CallIntMethodV, (jobject, jmethodID, va_list), (override));
  MOCK_METHOD(jfloat,
              CallFloatMethodV,
              (jobject, jmethodID, va_list),
              (override));
  MOCK_METHOD(jboolean,
              CallBooleanMethodV,
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
  MOCK_METHOD(jclass, GetObjectClass, (jobject), (override));
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
  MOCK_METHOD(jobject, NewObjectV, (jclass, jmethodID, va_list), (override));
  MOCK_METHOD(jint,
              RegisterNatives,
              (jclass, const JNINativeMethod*, jint),
              (override));
  MOCK_METHOD(jsize, GetArrayLength, (jarray), (override));
  MOCK_METHOD(void,
              GetIntArrayRegion,
              (jintArray, jsize, jsize, jint*),
              (override));
  MOCK_METHOD(jobject,
              GetObjectArrayElement,
              (jobjectArray, jsize),
              (override));
  MOCK_METHOD(jsize, GetStringLength, (jstring), (override));
  MOCK_METHOD(const jchar*, GetStringChars, (jstring, jboolean*), (override));
  MOCK_METHOD(void, ReleaseStringChars, (jstring, const jchar*), (override));
  MOCK_METHOD(jfloatArray, NewFloatArray, (jsize), (override));
  MOCK_METHOD(void,
              SetFloatArrayRegion,
              (jfloatArray, jsize, jsize, const jfloat*),
              (override));
  MOCK_METHOD(jint, PushLocalFrame, (jint), (override));
  MOCK_METHOD(jobject, PopLocalFrame, (jobject), (override));
  MOCK_METHOD(jobject, NewDirectByteBuffer, (void*, jlong), (override));
  MOCK_METHOD(jstring, NewStringUTF, (const char*), (override));
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_JNI_MOCK_JNI_ENV_H_
