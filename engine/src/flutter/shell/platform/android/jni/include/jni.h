// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_JNI_INCLUDE_JNI_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_JNI_INCLUDE_JNI_H_

#include <stdarg.h>
#include <stdint.h>

// NOLINTBEGIN(readability-identifier-naming)

/* Primitive types that match up with Java equivalents. */
typedef uint8_t jboolean; /* unsigned 8 bits */
typedef int8_t jbyte;     /* signed 8 bits */
typedef uint16_t jchar;   /* unsigned 16 bits */
typedef int16_t jshort;   /* signed 16 bits */
typedef int32_t jint;     /* signed 32 bits */
typedef int64_t jlong;    /* signed 64 bits */
typedef float jfloat;     /* 32-bit IEEE 754 */
typedef double jdouble;   /* 64-bit IEEE 754 */

/* "cardinal indices and sizes" */
typedef jint jsize;

#ifdef __cplusplus
/*
 * Reference types, in C++
 */
class _jobject {};
class _jclass : public _jobject {};
class _jstring : public _jobject {};
class _jarray : public _jobject {};
class _jobjectArray : public _jarray {};
class _jbooleanArray : public _jarray {};
class _jbyteArray : public _jarray {};
class _jcharArray : public _jarray {};
class _jshortArray : public _jarray {};
class _jintArray : public _jarray {};
class _jlongArray : public _jarray {};
class _jfloatArray : public _jarray {};
class _jdoubleArray : public _jarray {};
class _jthrowable : public _jobject {};

typedef _jobject* jobject;
typedef _jclass* jclass;
typedef _jstring* jstring;
typedef _jarray* jarray;
typedef _jobjectArray* jobjectArray;
typedef _jbooleanArray* jbooleanArray;
typedef _jbyteArray* jbyteArray;
typedef _jcharArray* jcharArray;
typedef _jshortArray* jshortArray;
typedef _jintArray* jintArray;
typedef _jlongArray* jlongArray;
typedef _jfloatArray* jfloatArray;
typedef _jdoubleArray* jdoubleArray;
typedef _jthrowable* jthrowable;
typedef _jobject* jweak;

#else /* not __cplusplus */

/*
 * Reference types, in C.
 */
typedef void* jobject;
typedef jobject jclass;
typedef jobject jstring;
typedef jobject jarray;
typedef jarray jobjectArray;
typedef jarray jbooleanArray;
typedef jarray jbyteArray;
typedef jarray jcharArray;
typedef jarray jshortArray;
typedef jarray jintArray;
typedef jarray jlongArray;
typedef jarray jfloatArray;
typedef jarray jdoubleArray;
typedef jobject jthrowable;
typedef jobject jweak;

#endif /* not __cplusplus */

struct _jfieldID;                   /* opaque structure */
typedef struct _jfieldID* jfieldID; /* field IDs */

struct _jmethodID;                    /* opaque structure */
typedef struct _jmethodID* jmethodID; /* method IDs */

struct JNIInvokeInterface;

typedef union jvalue {
  jboolean z;
  jbyte b;
  jchar c;
  jshort s;
  jint i;
  jlong j;
  jfloat f;
  jdouble d;
  jobject l;
} jvalue;

typedef enum jobjectRefType {
  JNIInvalidRefType = 0,
  JNILocalRefType = 1,
  JNIGlobalRefType = 2,
  JNIWeakGlobalRefType = 3
} jobjectRefType;

typedef struct {
  const char* name;
  const char* signature;
  void* fnPtr;
} JNINativeMethod;

struct _JNIEnv;
struct _JavaVM;
typedef const struct JNINativeInterface* C_JNIEnv;

#if defined(__cplusplus)
typedef _JNIEnv JNIEnv;
typedef _JavaVM JavaVM;
#else
typedef const struct JNINativeInterface* JNIEnv;
typedef const struct JNIInvokeInterface* JavaVM;
#endif

/*
 * Table of interface function pointers.
 */
struct JNINativeInterface {
  void* reserved0;
  void* reserved1;
  void* reserved2;
  void* reserved3;

  jint (*GetVersion)(JNIEnv* env);

  jclass (*DefineClass)(JNIEnv* env,
                        const char* name,
                        jobject loader,
                        const jbyte* buf,
                        jsize buf_len);
  jclass (*FindClass)(JNIEnv* env, const char* name);

  jmethodID (*FromReflectedMethod)(JNIEnv* env, jobject method);
  jfieldID (*FromReflectedField)(JNIEnv* env, jobject field);
  /* spec doesn't show jboolean parameter */
  jobject (*ToReflectedMethod)(JNIEnv* env,
                               jclass clazz,
                               jmethodID method_id,
                               jboolean is_static);

  jclass (*GetSuperclass)(JNIEnv* env, jclass clazz);
  jboolean (*IsAssignableFrom)(JNIEnv* env, jclass clazz1, jclass clazz2);

  /* spec doesn't show jboolean parameter */
  jobject (*ToReflectedField)(JNIEnv* env,
                              jclass clazz,
                              jfieldID field_id,
                              jboolean is_static);

  jint (*Throw)(JNIEnv* env, jthrowable obj);
  jint (*ThrowNew)(JNIEnv* env, jclass clazz, const char* message);
  jthrowable (*ExceptionOccurred)(JNIEnv* env);
  void (*ExceptionDescribe)(JNIEnv* env);
  void (*ExceptionClear)(JNIEnv* env);
  void (*FatalError)(JNIEnv* env, const char* msg);

  jint (*PushLocalFrame)(JNIEnv* env, jint capacity);
  jobject (*PopLocalFrame)(JNIEnv* env, jobject result);

  jobject (*NewGlobalRef)(JNIEnv* env, jobject obj);
  void (*DeleteGlobalRef)(JNIEnv* env, jobject global_ref);
  void (*DeleteLocalRef)(JNIEnv* env, jobject local_ref);
  jboolean (*IsSameObject)(JNIEnv* env, jobject ref1, jobject ref2);

  jobject (*NewLocalRef)(JNIEnv* env, jobject obj);
  jint (*EnsureLocalCapacity)(JNIEnv* env, jint capacity);

  jobject (*AllocObject)(JNIEnv* env, jclass clazz);
  jobject (*NewObject)(JNIEnv* env, jclass clazz, jmethodID method_id, ...);
  jobject (*NewObjectV)(JNIEnv* env,
                        jclass clazz,
                        jmethodID method_id,
                        va_list args);
  jobject (*NewObjectA)(JNIEnv* env,
                        jclass clazz,
                        jmethodID method_id,
                        const jvalue* args);

  jclass (*GetObjectClass)(JNIEnv* env, jobject obj);
  jboolean (*IsInstanceOf)(JNIEnv* env, jobject obj, jclass clazz);
  jmethodID (*GetMethodID)(JNIEnv* env,
                           jclass clazz,
                           const char* name,
                           const char* sig);

  jobject (*CallObjectMethod)(JNIEnv* env,
                              jobject obj,
                              jmethodID method_id,
                              ...);
  jobject (*CallObjectMethodV)(JNIEnv* env,
                               jobject obj,
                               jmethodID method_id,
                               va_list args);
  jobject (*CallObjectMethodA)(JNIEnv* env,
                               jobject obj,
                               jmethodID method_id,
                               const jvalue* args);
  jboolean (*CallBooleanMethod)(JNIEnv* env,
                                jobject obj,
                                jmethodID method_id,
                                ...);
  jboolean (*CallBooleanMethodV)(JNIEnv* env,
                                 jobject obj,
                                 jmethodID method_id,
                                 va_list args);
  jboolean (*CallBooleanMethodA)(JNIEnv* env,
                                 jobject obj,
                                 jmethodID method_id,
                                 const jvalue* args);
  jbyte (*CallByteMethod)(JNIEnv* env, jobject obj, jmethodID method_id, ...);
  jbyte (*CallByteMethodV)(JNIEnv* env,
                           jobject obj,
                           jmethodID method_id,
                           va_list args);
  jbyte (*CallByteMethodA)(JNIEnv* env,
                           jobject obj,
                           jmethodID method_id,
                           const jvalue* args);
  jchar (*CallCharMethod)(JNIEnv* env, jobject obj, jmethodID method_id, ...);
  jchar (*CallCharMethodV)(JNIEnv* env,
                           jobject obj,
                           jmethodID method_id,
                           va_list args);
  jchar (*CallCharMethodA)(JNIEnv* env,
                           jobject obj,
                           jmethodID method_id,
                           const jvalue* args);
  jshort (*CallShortMethod)(JNIEnv* env, jobject obj, jmethodID method_id, ...);
  jshort (*CallShortMethodV)(JNIEnv* env,
                             jobject obj,
                             jmethodID method_id,
                             va_list args);
  jshort (*CallShortMethodA)(JNIEnv* env,
                             jobject obj,
                             jmethodID method_id,
                             const jvalue* args);
  jint (*CallIntMethod)(JNIEnv* env, jobject obj, jmethodID method_id, ...);
  jint (*CallIntMethodV)(JNIEnv* env,
                         jobject obj,
                         jmethodID method_id,
                         va_list args);
  jint (*CallIntMethodA)(JNIEnv* env,
                         jobject obj,
                         jmethodID method_id,
                         const jvalue* args);
  jlong (*CallLongMethod)(JNIEnv* env, jobject obj, jmethodID method_id, ...);
  jlong (*CallLongMethodV)(JNIEnv* env,
                           jobject obj,
                           jmethodID method_id,
                           va_list args);
  jlong (*CallLongMethodA)(JNIEnv* env,
                           jobject obj,
                           jmethodID method_id,
                           const jvalue* args);
  jfloat (*CallFloatMethod)(JNIEnv* env, jobject obj, jmethodID method_id, ...);
  jfloat (*CallFloatMethodV)(JNIEnv* env,
                             jobject obj,
                             jmethodID method_id,
                             va_list args);
  jfloat (*CallFloatMethodA)(JNIEnv* env,
                             jobject obj,
                             jmethodID method_id,
                             const jvalue* args);
  jdouble (*CallDoubleMethod)(JNIEnv* env,
                              jobject obj,
                              jmethodID method_id,
                              ...);
  jdouble (*CallDoubleMethodV)(JNIEnv* env,
                               jobject obj,
                               jmethodID method_id,
                               va_list args);
  jdouble (*CallDoubleMethodA)(JNIEnv* env,
                               jobject obj,
                               jmethodID method_id,
                               const jvalue* args);
  void (*CallVoidMethod)(JNIEnv* env, jobject obj, jmethodID method_id, ...);
  void (*CallVoidMethodV)(JNIEnv* env,
                          jobject obj,
                          jmethodID method_id,
                          va_list args);
  void (*CallVoidMethodA)(JNIEnv* env,
                          jobject obj,
                          jmethodID method_id,
                          const jvalue* args);

  jobject (*CallNonvirtualObjectMethod)(JNIEnv* env,
                                        jobject obj,
                                        jclass clazz,
                                        jmethodID method_id,
                                        ...);
  jobject (*CallNonvirtualObjectMethodV)(JNIEnv* env,
                                         jobject obj,
                                         jclass clazz,
                                         jmethodID method_id,
                                         va_list args);
  jobject (*CallNonvirtualObjectMethodA)(JNIEnv* env,
                                         jobject obj,
                                         jclass clazz,
                                         jmethodID method_id,
                                         const jvalue* args);
  jboolean (*CallNonvirtualBooleanMethod)(JNIEnv* env,
                                          jobject obj,
                                          jclass clazz,
                                          jmethodID method_id,
                                          ...);
  jboolean (*CallNonvirtualBooleanMethodV)(JNIEnv* env,
                                           jobject obj,
                                           jclass clazz,
                                           jmethodID method_id,
                                           va_list args);
  jboolean (*CallNonvirtualBooleanMethodA)(JNIEnv* env,
                                           jobject obj,
                                           jclass clazz,
                                           jmethodID method_id,
                                           const jvalue* args);
  jbyte (*CallNonvirtualByteMethod)(JNIEnv* env,
                                    jobject obj,
                                    jclass clazz,
                                    jmethodID method_id,
                                    ...);
  jbyte (*CallNonvirtualByteMethodV)(JNIEnv* env,
                                     jobject obj,
                                     jclass clazz,
                                     jmethodID method_id,
                                     va_list args);
  jbyte (*CallNonvirtualByteMethodA)(JNIEnv* env,
                                     jobject obj,
                                     jclass clazz,
                                     jmethodID method_id,
                                     const jvalue* args);
  jchar (*CallNonvirtualCharMethod)(JNIEnv* env,
                                    jobject obj,
                                    jclass clazz,
                                    jmethodID method_id,
                                    ...);
  jchar (*CallNonvirtualCharMethodV)(JNIEnv* env,
                                     jobject obj,
                                     jclass clazz,
                                     jmethodID method_id,
                                     va_list args);
  jchar (*CallNonvirtualCharMethodA)(JNIEnv* env,
                                     jobject obj,
                                     jclass clazz,
                                     jmethodID method_id,
                                     const jvalue* args);
  jshort (*CallNonvirtualShortMethod)(JNIEnv* env,
                                      jobject obj,
                                      jclass clazz,
                                      jmethodID method_id,
                                      ...);
  jshort (*CallNonvirtualShortMethodV)(JNIEnv* env,
                                       jobject obj,
                                       jclass clazz,
                                       jmethodID method_id,
                                       va_list args);
  jshort (*CallNonvirtualShortMethodA)(JNIEnv* env,
                                       jobject obj,
                                       jclass clazz,
                                       jmethodID method_id,
                                       const jvalue* args);
  jint (*CallNonvirtualIntMethod)(JNIEnv* env,
                                  jobject obj,
                                  jclass clazz,
                                  jmethodID method_id,
                                  ...);
  jint (*CallNonvirtualIntMethodV)(JNIEnv* env,
                                   jobject obj,
                                   jclass clazz,
                                   jmethodID method_id,
                                   va_list args);
  jint (*CallNonvirtualIntMethodA)(JNIEnv* env,
                                   jobject obj,
                                   jclass clazz,
                                   jmethodID method_id,
                                   const jvalue* args);
  jlong (*CallNonvirtualLongMethod)(JNIEnv* env,
                                    jobject obj,
                                    jclass clazz,
                                    jmethodID method_id,
                                    ...);
  jlong (*CallNonvirtualLongMethodV)(JNIEnv* env,
                                     jobject obj,
                                     jclass clazz,
                                     jmethodID method_id,
                                     va_list args);
  jlong (*CallNonvirtualLongMethodA)(JNIEnv* env,
                                     jobject obj,
                                     jclass clazz,
                                     jmethodID method_id,
                                     const jvalue* args);
  jfloat (*CallNonvirtualFloatMethod)(JNIEnv* env,
                                      jobject obj,
                                      jclass clazz,
                                      jmethodID method_id,
                                      ...);
  jfloat (*CallNonvirtualFloatMethodV)(JNIEnv* env,
                                       jobject obj,
                                       jclass clazz,
                                       jmethodID method_id,
                                       va_list args);
  jfloat (*CallNonvirtualFloatMethodA)(JNIEnv* env,
                                       jobject obj,
                                       jclass clazz,
                                       jmethodID method_id,
                                       const jvalue* args);
  jdouble (*CallNonvirtualDoubleMethod)(JNIEnv* env,
                                        jobject obj,
                                        jclass clazz,
                                        jmethodID method_id,
                                        ...);
  jdouble (*CallNonvirtualDoubleMethodV)(JNIEnv* env,
                                         jobject obj,
                                         jclass clazz,
                                         jmethodID method_id,
                                         va_list args);
  jdouble (*CallNonvirtualDoubleMethodA)(JNIEnv* env,
                                         jobject obj,
                                         jclass clazz,
                                         jmethodID method_id,
                                         const jvalue* args);
  void (*CallNonvirtualVoidMethod)(JNIEnv* env,
                                   jobject obj,
                                   jclass clazz,
                                   jmethodID method_id,
                                   ...);
  void (*CallNonvirtualVoidMethodV)(JNIEnv* env,
                                    jobject obj,
                                    jclass clazz,
                                    jmethodID method_id,
                                    va_list args);
  void (*CallNonvirtualVoidMethodA)(JNIEnv* env,
                                    jobject obj,
                                    jclass clazz,
                                    jmethodID method_id,
                                    const jvalue* args);

  jfieldID (*GetFieldID)(JNIEnv* env,
                         jclass clazz,
                         const char* name,
                         const char* sig);

  jobject (*GetObjectField)(JNIEnv* env, jobject obj, jfieldID field_id);
  jboolean (*GetBooleanField)(JNIEnv* env, jobject obj, jfieldID field_id);
  jbyte (*GetByteField)(JNIEnv* env, jobject obj, jfieldID field_id);
  jchar (*GetCharField)(JNIEnv* env, jobject obj, jfieldID field_id);
  jshort (*GetShortField)(JNIEnv* env, jobject obj, jfieldID field_id);
  jint (*GetIntField)(JNIEnv* env, jobject obj, jfieldID field_id);
  jlong (*GetLongField)(JNIEnv* env, jobject obj, jfieldID field_id);
  jfloat (*GetFloatField)(JNIEnv* env, jobject obj, jfieldID field_id);
  jdouble (*GetDoubleField)(JNIEnv* env, jobject obj, jfieldID field_id);

  void (*SetObjectField)(JNIEnv* env,
                         jobject obj,
                         jfieldID field_id,
                         jobject val);
  void (*SetBooleanField)(JNIEnv* env,
                          jobject obj,
                          jfieldID field_id,
                          jboolean val);
  void (*SetByteField)(JNIEnv* env, jobject obj, jfieldID field_id, jbyte val);
  void (*SetCharField)(JNIEnv* env, jobject obj, jfieldID field_id, jchar val);
  void (*SetShortField)(JNIEnv* env,
                        jobject obj,
                        jfieldID field_id,
                        jshort val);
  void (*SetIntField)(JNIEnv* env, jobject obj, jfieldID field_id, jint val);
  void (*SetLongField)(JNIEnv* env, jobject obj, jfieldID field_id, jlong val);
  void (*SetFloatField)(JNIEnv* env,
                        jobject obj,
                        jfieldID field_id,
                        jfloat val);
  void (*SetDoubleField)(JNIEnv* env,
                         jobject obj,
                         jfieldID field_id,
                         jdouble val);

  jmethodID (*GetStaticMethodID)(JNIEnv* env,
                                 jclass clazz,
                                 const char* name,
                                 const char* sig);

  jobject (*CallStaticObjectMethod)(JNIEnv* env,
                                    jclass clazz,
                                    jmethodID method_id,
                                    ...);
  jobject (*CallStaticObjectMethodV)(JNIEnv* env,
                                     jclass clazz,
                                     jmethodID method_id,
                                     va_list args);
  jobject (*CallStaticObjectMethodA)(JNIEnv* env,
                                     jclass clazz,
                                     jmethodID method_id,
                                     const jvalue* args);
  jboolean (*CallStaticBooleanMethod)(JNIEnv* env,
                                      jclass clazz,
                                      jmethodID method_id,
                                      ...);
  jboolean (*CallStaticBooleanMethodV)(JNIEnv* env,
                                       jclass clazz,
                                       jmethodID method_id,
                                       va_list args);
  jboolean (*CallStaticBooleanMethodA)(JNIEnv* env,
                                       jclass clazz,
                                       jmethodID method_id,
                                       const jvalue* args);
  jbyte (*CallStaticByteMethod)(JNIEnv* env,
                                jclass clazz,
                                jmethodID method_id,
                                ...);
  jbyte (*CallStaticByteMethodV)(JNIEnv* env,
                                 jclass clazz,
                                 jmethodID method_id,
                                 va_list args);
  jbyte (*CallStaticByteMethodA)(JNIEnv* env,
                                 jclass clazz,
                                 jmethodID method_id,
                                 const jvalue* args);
  jchar (*CallStaticCharMethod)(JNIEnv* env,
                                jclass clazz,
                                jmethodID method_id,
                                ...);
  jchar (*CallStaticCharMethodV)(JNIEnv* env,
                                 jclass clazz,
                                 jmethodID method_id,
                                 va_list args);
  jchar (*CallStaticCharMethodA)(JNIEnv* env,
                                 jclass clazz,
                                 jmethodID method_id,
                                 const jvalue* args);
  jshort (*CallStaticShortMethod)(JNIEnv* env,
                                  jclass clazz,
                                  jmethodID method_id,
                                  ...);
  jshort (*CallStaticShortMethodV)(JNIEnv* env,
                                   jclass clazz,
                                   jmethodID method_id,
                                   va_list args);
  jshort (*CallStaticShortMethodA)(JNIEnv* env,
                                   jclass clazz,
                                   jmethodID method_id,
                                   const jvalue* args);
  jint (*CallStaticIntMethod)(JNIEnv* env,
                              jclass clazz,
                              jmethodID method_id,
                              ...);
  jint (*CallStaticIntMethodV)(JNIEnv* env,
                               jclass clazz,
                               jmethodID method_id,
                               va_list args);
  jint (*CallStaticIntMethodA)(JNIEnv* env,
                               jclass clazz,
                               jmethodID method_id,
                               const jvalue* args);
  jlong (*CallStaticLongMethod)(JNIEnv* env,
                                jclass clazz,
                                jmethodID method_id,
                                ...);
  jlong (*CallStaticLongMethodV)(JNIEnv* env,
                                 jclass clazz,
                                 jmethodID method_id,
                                 va_list args);
  jlong (*CallStaticLongMethodA)(JNIEnv* env,
                                 jclass clazz,
                                 jmethodID method_id,
                                 const jvalue* args);
  jfloat (*CallStaticFloatMethod)(JNIEnv* env,
                                  jclass clazz,
                                  jmethodID method_id,
                                  ...);
  jfloat (*CallStaticFloatMethodV)(JNIEnv* env,
                                   jclass clazz,
                                   jmethodID method_id,
                                   va_list args);
  jfloat (*CallStaticFloatMethodA)(JNIEnv* env,
                                   jclass clazz,
                                   jmethodID method_id,
                                   const jvalue* args);
  jdouble (*CallStaticDoubleMethod)(JNIEnv* env,
                                    jclass clazz,
                                    jmethodID method_id,
                                    ...);
  jdouble (*CallStaticDoubleMethodV)(JNIEnv* env,
                                     jclass clazz,
                                     jmethodID method_id,
                                     va_list args);
  jdouble (*CallStaticDoubleMethodA)(JNIEnv* env,
                                     jclass clazz,
                                     jmethodID method_id,
                                     const jvalue* args);
  void (*CallStaticVoidMethod)(JNIEnv* env,
                               jclass clazz,
                               jmethodID method_id,
                               ...);
  void (*CallStaticVoidMethodV)(JNIEnv* env,
                                jclass clazz,
                                jmethodID method_id,
                                va_list args);
  void (*CallStaticVoidMethodA)(JNIEnv* env,
                                jclass clazz,
                                jmethodID method_id,
                                const jvalue* args);

  jfieldID (*GetStaticFieldID)(JNIEnv* env,
                               jclass clazz,
                               const char* name,
                               const char* sig);

  jobject (*GetStaticObjectField)(JNIEnv* env, jclass clazz, jfieldID field_id);
  jboolean (*GetStaticBooleanField)(JNIEnv* env,
                                    jclass clazz,
                                    jfieldID field_id);
  jbyte (*GetStaticByteField)(JNIEnv* env, jclass clazz, jfieldID field_id);
  jchar (*GetStaticCharField)(JNIEnv* env, jclass clazz, jfieldID field_id);
  jshort (*GetStaticShortField)(JNIEnv* env, jclass clazz, jfieldID field_id);
  jint (*GetStaticIntField)(JNIEnv* env, jclass clazz, jfieldID field_id);
  jlong (*GetStaticLongField)(JNIEnv* env, jclass clazz, jfieldID field_id);
  jfloat (*GetStaticFloatField)(JNIEnv* env, jclass clazz, jfieldID field_id);
  jdouble (*GetStaticDoubleField)(JNIEnv* env, jclass clazz, jfieldID field_id);

  void (*SetStaticObjectField)(JNIEnv* env,
                               jclass clazz,
                               jfieldID field_id,
                               jobject val);
  void (*SetStaticBooleanField)(JNIEnv* env,
                                jclass clazz,
                                jfieldID field_id,
                                jboolean val);
  void (*SetStaticByteField)(JNIEnv* env,
                             jclass clazz,
                             jfieldID field_id,
                             jbyte val);
  void (*SetStaticCharField)(JNIEnv* env,
                             jclass clazz,
                             jfieldID field_id,
                             jchar val);
  void (*SetStaticShortField)(JNIEnv* env,
                              jclass clazz,
                              jfieldID field_id,
                              jshort val);
  void (*SetStaticIntField)(JNIEnv* env,
                            jclass clazz,
                            jfieldID field_id,
                            jint val);
  void (*SetStaticLongField)(JNIEnv* env,
                             jclass clazz,
                             jfieldID field_id,
                             jlong val);
  void (*SetStaticFloatField)(JNIEnv* env,
                              jclass clazz,
                              jfieldID field_id,
                              jfloat val);
  void (*SetStaticDoubleField)(JNIEnv* env,
                               jclass clazz,
                               jfieldID field_id,
                               jdouble val);

  jstring (*NewString)(JNIEnv* env, const jchar* unicode_chars, jsize len);
  jsize (*GetStringLength)(JNIEnv* env, jstring string);
  const jchar* (*GetStringChars)(JNIEnv* env,
                                 jstring string,
                                 jboolean* is_copy);
  void (*ReleaseStringChars)(JNIEnv* env, jstring string, const jchar* chars);
  jstring (*NewStringUTF)(JNIEnv* env, const char* bytes);
  jsize (*GetStringUTFLength)(JNIEnv* env, jstring string);
  const char* (*GetStringUTFChars)(JNIEnv* env,
                                   jstring string,
                                   jboolean* is_copy);
  void (*ReleaseStringUTFChars)(JNIEnv* env, jstring string, const char* utf);
  jsize (*GetArrayLength)(JNIEnv* env, jarray array);
  jobjectArray (*NewObjectArray)(JNIEnv* env,
                                 jsize length,
                                 jclass element_class,
                                 jobject initial_element);
  jobject (*GetObjectArrayElement)(JNIEnv* env,
                                   jobjectArray array,
                                   jsize index);
  void (*SetObjectArrayElement)(JNIEnv* env,
                                jobjectArray array,
                                jsize index,
                                jobject val);

  jbooleanArray (*NewBooleanArray)(JNIEnv* env, jsize length);
  jbyteArray (*NewByteArray)(JNIEnv* env, jsize length);
  jcharArray (*NewCharArray)(JNIEnv* env, jsize length);
  jshortArray (*NewShortArray)(JNIEnv* env, jsize length);
  jintArray (*NewIntArray)(JNIEnv* env, jsize length);
  jlongArray (*NewLongArray)(JNIEnv* env, jsize length);
  jfloatArray (*NewFloatArray)(JNIEnv* env, jsize length);
  jdoubleArray (*NewDoubleArray)(JNIEnv* env, jsize length);

  jboolean* (*GetBooleanArrayElements)(JNIEnv* env,
                                       jbooleanArray array,
                                       jboolean* is_copy);
  jbyte* (*GetByteArrayElements)(JNIEnv* env,
                                 jbyteArray array,
                                 jboolean* is_copy);
  jchar* (*GetCharArrayElements)(JNIEnv* env,
                                 jcharArray array,
                                 jboolean* is_copy);
  jshort* (*GetShortArrayElements)(JNIEnv* env,
                                   jshortArray array,
                                   jboolean* is_copy);
  jint* (*GetIntArrayElements)(JNIEnv* env, jintArray array, jboolean* is_copy);
  jlong* (*GetLongArrayElements)(JNIEnv* env,
                                 jlongArray array,
                                 jboolean* is_copy);
  jfloat* (*GetFloatArrayElements)(JNIEnv* env,
                                   jfloatArray array,
                                   jboolean* is_copy);
  jdouble* (*GetDoubleArrayElements)(JNIEnv* env,
                                     jdoubleArray array,
                                     jboolean* is_copy);

  void (*ReleaseBooleanArrayElements)(JNIEnv* env,
                                      jbooleanArray array,
                                      jboolean* elems,
                                      jint mode);
  void (*ReleaseByteArrayElements)(JNIEnv* env,
                                   jbyteArray array,
                                   jbyte* elems,
                                   jint mode);
  void (*ReleaseCharArrayElements)(JNIEnv* env,
                                   jcharArray array,
                                   jchar* elems,
                                   jint mode);
  void (*ReleaseShortArrayElements)(JNIEnv* env,
                                    jshortArray array,
                                    jshort* elems,
                                    jint mode);
  void (*ReleaseIntArrayElements)(JNIEnv* env,
                                  jintArray array,
                                  jint* elems,
                                  jint mode);
  void (*ReleaseLongArrayElements)(JNIEnv* env,
                                   jlongArray array,
                                   jlong* elems,
                                   jint mode);
  void (*ReleaseFloatArrayElements)(JNIEnv* env,
                                    jfloatArray array,
                                    jfloat* elems,
                                    jint mode);
  void (*ReleaseDoubleArrayElements)(JNIEnv* env,
                                     jdoubleArray array,
                                     jdouble* elems,
                                     jint mode);

  void (*GetBooleanArrayRegion)(JNIEnv* env,
                                jbooleanArray array,
                                jsize start,
                                jsize len,
                                jboolean* buf);
  void (*GetByteArrayRegion)(JNIEnv* env,
                             jbyteArray array,
                             jsize start,
                             jsize len,
                             jbyte* buf);
  void (*GetCharArrayRegion)(JNIEnv* env,
                             jcharArray array,
                             jsize start,
                             jsize len,
                             jchar* buf);
  void (*GetShortArrayRegion)(JNIEnv* env,
                              jshortArray array,
                              jsize start,
                              jsize len,
                              jshort* buf);
  void (*GetIntArrayRegion)(JNIEnv* env,
                            jintArray array,
                            jsize start,
                            jsize len,
                            jint* buf);
  void (*GetLongArrayRegion)(JNIEnv* env,
                             jlongArray array,
                             jsize start,
                             jsize len,
                             jlong* buf);
  void (*GetFloatArrayRegion)(JNIEnv* env,
                              jfloatArray array,
                              jsize start,
                              jsize len,
                              jfloat* buf);
  void (*GetDoubleArrayRegion)(JNIEnv* env,
                               jdoubleArray array,
                               jsize start,
                               jsize len,
                               jdouble* buf);

  void (*SetBooleanArrayRegion)(JNIEnv* env,
                                jbooleanArray array,
                                jsize start,
                                jsize len,
                                const jboolean* buf);
  void (*SetByteArrayRegion)(JNIEnv* env,
                             jbyteArray array,
                             jsize start,
                             jsize len,
                             const jbyte* buf);
  void (*SetCharArrayRegion)(JNIEnv* env,
                             jcharArray array,
                             jsize start,
                             jsize len,
                             const jchar* buf);
  void (*SetShortArrayRegion)(JNIEnv* env,
                              jshortArray array,
                              jsize start,
                              jsize len,
                              const jshort* buf);
  void (*SetIntArrayRegion)(JNIEnv* env,
                            jintArray array,
                            jsize start,
                            jsize len,
                            const jint* buf);
  void (*SetLongArrayRegion)(JNIEnv* env,
                             jlongArray array,
                             jsize start,
                             jsize len,
                             const jlong* buf);
  void (*SetFloatArrayRegion)(JNIEnv* env,
                              jfloatArray array,
                              jsize start,
                              jsize len,
                              const jfloat* buf);
  void (*SetDoubleArrayRegion)(JNIEnv* env,
                               jdoubleArray array,
                               jsize start,
                               jsize len,
                               const jdouble* buf);

  jint (*RegisterNatives)(JNIEnv* env,
                          jclass clazz,
                          const JNINativeMethod* methods,
                          jint n_methods);
  jint (*UnregisterNatives)(JNIEnv* env, jclass clazz);
  jint (*MonitorEnter)(JNIEnv* env, jobject obj);
  jint (*MonitorExit)(JNIEnv* env, jobject obj);
  jint (*GetJavaVM)(JNIEnv* env, JavaVM** vm);

  void (*GetStringRegion)(JNIEnv* env,
                          jstring str,
                          jsize start,
                          jsize len,
                          jchar* buf);
  void (*GetStringUTFRegion)(JNIEnv* env,
                             jstring str,
                             jsize start,
                             jsize len,
                             char* buf);

  void* (*GetPrimitiveArrayCritical)(JNIEnv* env,
                                     jarray array,
                                     jboolean* is_copy);
  void (*ReleasePrimitiveArrayCritical)(JNIEnv* env,
                                        jarray array,
                                        void* carray,
                                        jint mode);

  const jchar* (*GetStringCritical)(JNIEnv* env,
                                    jstring str,
                                    jboolean* is_copy);
  void (*ReleaseStringCritical)(JNIEnv* env, jstring str, const jchar* carray);

  jweak (*NewWeakGlobalRef)(JNIEnv* env, jobject obj);
  void (*DeleteWeakGlobalRef)(JNIEnv* env, jweak obj);

  jboolean (*ExceptionCheck)(JNIEnv* env);

  jobject (*NewDirectByteBuffer)(JNIEnv* env, void* address, jlong capacity);
  void* (*GetDirectBufferAddress)(JNIEnv* env, jobject buf);
  jlong (*GetDirectBufferCapacity)(JNIEnv* env, jobject buf);

  /* added in JNI 1.6 */
  jobjectRefType (*GetObjectRefType)(JNIEnv* env, jobject obj);
};

/*
 * C++ object wrapper.
 *
 * This is usually overlaid on a C struct whose first element is a
 * JNINativeInterface*.  We rely somewhat on compiler behavior.
 */
struct _JNIEnv {
  /* do not rename this; it does not seem to be entirely opaque */
  const struct JNINativeInterface* functions;

#if defined(__cplusplus)

  jint GetVersion() { return functions->GetVersion(this); }

  jclass DefineClass(const char* name,
                     jobject loader,
                     const jbyte* buf,
                     jsize buf_len) {
    return functions->DefineClass(this, name, loader, buf, buf_len);
  }

  jclass FindClass(const char* name) {
    return functions->FindClass(this, name);
  }

  jmethodID FromReflectedMethod(jobject method) {
    return functions->FromReflectedMethod(this, method);
  }

  jfieldID FromReflectedField(jobject field) {
    return functions->FromReflectedField(this, field);
  }

  jobject ToReflectedMethod(jclass clazz,
                            jmethodID method_id,
                            jboolean is_static) {
    return functions->ToReflectedMethod(this, clazz, method_id, is_static);
  }

  jclass GetSuperclass(jclass clazz) {
    return functions->GetSuperclass(this, clazz);
  }

  jboolean IsAssignableFrom(jclass clazz1, jclass clazz2) {
    return functions->IsAssignableFrom(this, clazz1, clazz2);
  }

  jobject ToReflectedField(jclass clazz,
                           jfieldID field_id,
                           jboolean is_static) {
    return functions->ToReflectedField(this, clazz, field_id, is_static);
  }

  jint Throw(jthrowable obj) { return functions->Throw(this, obj); }

  jint ThrowNew(jclass clazz, const char* message) {
    return functions->ThrowNew(this, clazz, message);
  }

  jthrowable ExceptionOccurred() { return functions->ExceptionOccurred(this); }

  void ExceptionDescribe() { functions->ExceptionDescribe(this); }

  void ExceptionClear() { functions->ExceptionClear(this); }

  void FatalError(const char* msg) { functions->FatalError(this, msg); }

  jint PushLocalFrame(jint capacity) {
    return functions->PushLocalFrame(this, capacity);
  }

  jobject PopLocalFrame(jobject result) {
    return functions->PopLocalFrame(this, result);
  }

  jobject NewGlobalRef(jobject obj) {
    return functions->NewGlobalRef(this, obj);
  }

  void DeleteGlobalRef(jobject obj) { functions->DeleteGlobalRef(this, obj); }

  void DeleteLocalRef(jobject obj) { functions->DeleteLocalRef(this, obj); }

  jboolean IsSameObject(jobject ref1, jobject ref2) {
    return functions->IsSameObject(this, ref1, ref2);
  }

  jobject NewLocalRef(jobject obj) { return functions->NewLocalRef(this, obj); }

  jint EnsureLocalCapacity(jint capacity) {
    return functions->EnsureLocalCapacity(this, capacity);
  }

  jobject AllocObject(jclass clazz) {
    return functions->AllocObject(this, clazz);
  }

  jobject NewObject(jclass clazz, jmethodID method_id, ...) {
    va_list args;
    va_start(args, method_id);
    jobject result = functions->NewObjectV(this, clazz, method_id, args);
    va_end(args);
    return result;
  }

  jobject NewObjectV(jclass clazz, jmethodID method_id, va_list args) {
    return functions->NewObjectV(this, clazz, method_id, args);
  }

  jobject NewObjectA(jclass clazz, jmethodID method_id, const jvalue* args) {
    return functions->NewObjectA(this, clazz, method_id, args);
  }

  jclass GetObjectClass(jobject obj) {
    return functions->GetObjectClass(this, obj);
  }

  jboolean IsInstanceOf(jobject obj, jclass clazz) {
    return functions->IsInstanceOf(this, obj, clazz);
  }

  jmethodID GetMethodID(jclass clazz, const char* name, const char* sig) {
    return functions->GetMethodID(this, clazz, name, sig);
  }

#define _JNI_CALL_TYPE_METHOD(_jtype, _jname)                              \
  _jtype Call##_jname##Method(jobject obj, jmethodID method_id, ...) {     \
    _jtype result;                                                         \
    va_list args;                                                          \
    va_start(args, method_id);                                             \
    result = functions->Call##_jname##MethodV(this, obj, method_id, args); \
    va_end(args);                                                          \
    return result;                                                         \
  }
#define _JNI_CALL_TYPE_METHODV(_jtype, _jname)                           \
  _jtype Call##_jname##MethodV(jobject obj, jmethodID method_id,         \
                               va_list args) {                           \
    return functions->Call##_jname##MethodV(this, obj, method_id, args); \
  }
#define _JNI_CALL_TYPE_METHODA(_jtype, _jname)                           \
  _jtype Call##_jname##MethodA(jobject obj, jmethodID method_id,         \
                               const jvalue* args) {                     \
    return functions->Call##_jname##MethodA(this, obj, method_id, args); \
  }

#define _JNI_CALL_TYPE(_jtype, _jname)   \
  _JNI_CALL_TYPE_METHOD(_jtype, _jname)  \
  _JNI_CALL_TYPE_METHODV(_jtype, _jname) \
  _JNI_CALL_TYPE_METHODA(_jtype, _jname)

  _JNI_CALL_TYPE(jobject, Object)
  _JNI_CALL_TYPE(jboolean, Boolean)
  _JNI_CALL_TYPE(jbyte, Byte)
  _JNI_CALL_TYPE(jchar, Char)
  _JNI_CALL_TYPE(jshort, Short)
  _JNI_CALL_TYPE(jint, Int)
  _JNI_CALL_TYPE(jlong, Long)
  _JNI_CALL_TYPE(jfloat, Float)
  _JNI_CALL_TYPE(jdouble, Double)

  void CallVoidMethod(jobject obj, jmethodID method_id, ...) {
    va_list args;
    va_start(args, method_id);
    functions->CallVoidMethodV(this, obj, method_id, args);
    va_end(args);
  }
  void CallVoidMethodV(jobject obj, jmethodID method_id, va_list args) {
    functions->CallVoidMethodV(this, obj, method_id, args);
  }
  void CallVoidMethodA(jobject obj, jmethodID method_id, const jvalue* args) {
    functions->CallVoidMethodA(this, obj, method_id, args);
  }

#define _JNI_CALL_NONVIRT_TYPE_METHOD(_jtype, _jname)                     \
  _jtype CallNonvirtual##_jname##Method(jobject obj, jclass clazz,        \
                                        jmethodID method_id, ...) {       \
    _jtype result;                                                        \
    va_list args;                                                         \
    va_start(args, method_id);                                            \
    result = functions->CallNonvirtual##_jname##MethodV(this, obj, clazz, \
                                                        method_id, args); \
    va_end(args);                                                         \
    return result;                                                        \
  }
#define _JNI_CALL_NONVIRT_TYPE_METHODV(_jtype, _jname)                        \
  _jtype CallNonvirtual##_jname##MethodV(jobject obj, jclass clazz,           \
                                         jmethodID method_id, va_list args) { \
    return functions->CallNonvirtual##_jname##MethodV(this, obj, clazz,       \
                                                      method_id, args);       \
  }
#define _JNI_CALL_NONVIRT_TYPE_METHODA(_jtype, _jname)                      \
  _jtype CallNonvirtual##_jname##MethodA(                                   \
      jobject obj, jclass clazz, jmethodID method_id, const jvalue* args) { \
    return functions->CallNonvirtual##_jname##MethodA(this, obj, clazz,     \
                                                      method_id, args);     \
  }

#define _JNI_CALL_NONVIRT_TYPE(_jtype, _jname)   \
  _JNI_CALL_NONVIRT_TYPE_METHOD(_jtype, _jname)  \
  _JNI_CALL_NONVIRT_TYPE_METHODV(_jtype, _jname) \
  _JNI_CALL_NONVIRT_TYPE_METHODA(_jtype, _jname)

  _JNI_CALL_NONVIRT_TYPE(jobject, Object)
  _JNI_CALL_NONVIRT_TYPE(jboolean, Boolean)
  _JNI_CALL_NONVIRT_TYPE(jbyte, Byte)
  _JNI_CALL_NONVIRT_TYPE(jchar, Char)
  _JNI_CALL_NONVIRT_TYPE(jshort, Short)
  _JNI_CALL_NONVIRT_TYPE(jint, Int)
  _JNI_CALL_NONVIRT_TYPE(jlong, Long)
  _JNI_CALL_NONVIRT_TYPE(jfloat, Float)
  _JNI_CALL_NONVIRT_TYPE(jdouble, Double)

  void CallNonvirtualVoidMethod(jobject obj,
                                jclass clazz,
                                jmethodID method_id,
                                ...) {
    va_list args;
    va_start(args, method_id);
    functions->CallNonvirtualVoidMethodV(this, obj, clazz, method_id, args);
    va_end(args);
  }
  void CallNonvirtualVoidMethodV(jobject obj,
                                 jclass clazz,
                                 jmethodID method_id,
                                 va_list args) {
    functions->CallNonvirtualVoidMethodV(this, obj, clazz, method_id, args);
  }
  void CallNonvirtualVoidMethodA(jobject obj,
                                 jclass clazz,
                                 jmethodID method_id,
                                 const jvalue* args) {
    functions->CallNonvirtualVoidMethodA(this, obj, clazz, method_id, args);
  }

  jfieldID GetFieldID(jclass clazz, const char* name, const char* sig) {
    return functions->GetFieldID(this, clazz, name, sig);
  }

  jobject GetObjectField(jobject obj, jfieldID field_id) {
    return functions->GetObjectField(this, obj, field_id);
  }
  jboolean GetBooleanField(jobject obj, jfieldID field_id) {
    return functions->GetBooleanField(this, obj, field_id);
  }
  jbyte GetByteField(jobject obj, jfieldID field_id) {
    return functions->GetByteField(this, obj, field_id);
  }
  jchar GetCharField(jobject obj, jfieldID field_id) {
    return functions->GetCharField(this, obj, field_id);
  }
  jshort GetShortField(jobject obj, jfieldID field_id) {
    return functions->GetShortField(this, obj, field_id);
  }
  jint GetIntField(jobject obj, jfieldID field_id) {
    return functions->GetIntField(this, obj, field_id);
  }
  jlong GetLongField(jobject obj, jfieldID field_id) {
    return functions->GetLongField(this, obj, field_id);
  }
  jfloat GetFloatField(jobject obj, jfieldID field_id) {
    return functions->GetFloatField(this, obj, field_id);
  }
  jdouble GetDoubleField(jobject obj, jfieldID field_id) {
    return functions->GetDoubleField(this, obj, field_id);
  }

  void SetObjectField(jobject obj, jfieldID field_id, jobject val) {
    functions->SetObjectField(this, obj, field_id, val);
  }
  void SetBooleanField(jobject obj, jfieldID field_id, jboolean val) {
    functions->SetBooleanField(this, obj, field_id, val);
  }
  void SetByteField(jobject obj, jfieldID field_id, jbyte val) {
    functions->SetByteField(this, obj, field_id, val);
  }
  void SetCharField(jobject obj, jfieldID field_id, jchar val) {
    functions->SetCharField(this, obj, field_id, val);
  }
  void SetShortField(jobject obj, jfieldID field_id, jshort val) {
    functions->SetShortField(this, obj, field_id, val);
  }
  void SetIntField(jobject obj, jfieldID field_id, jint val) {
    functions->SetIntField(this, obj, field_id, val);
  }
  void SetLongField(jobject obj, jfieldID field_id, jlong val) {
    functions->SetLongField(this, obj, field_id, val);
  }
  void SetFloatField(jobject obj, jfieldID field_id, jfloat val) {
    functions->SetFloatField(this, obj, field_id, val);
  }
  void SetDoubleField(jobject obj, jfieldID field_id, jdouble val) {
    functions->SetDoubleField(this, obj, field_id, val);
  }

  jmethodID GetStaticMethodID(jclass clazz, const char* name, const char* sig) {
    return functions->GetStaticMethodID(this, clazz, name, sig);
  }

#define _JNI_CALL_STATIC_TYPE_METHOD(_jtype, _jname)                          \
  _jtype CallStatic##_jname##Method(jclass clazz, jmethodID method_id, ...) { \
    _jtype result;                                                            \
    va_list args;                                                             \
    va_start(args, method_id);                                                \
    result =                                                                  \
        functions->CallStatic##_jname##MethodV(this, clazz, method_id, args); \
    va_end(args);                                                             \
    return result;                                                            \
  }
#define _JNI_CALL_STATIC_TYPE_METHODV(_jtype, _jname)                     \
  _jtype CallStatic##_jname##MethodV(jclass clazz, jmethodID method_id,   \
                                     va_list args) {                      \
    return functions->CallStatic##_jname##MethodV(this, clazz, method_id, \
                                                  args);                  \
  }
#define _JNI_CALL_STATIC_TYPE_METHODA(_jtype, _jname)                     \
  _jtype CallStatic##_jname##MethodA(jclass clazz, jmethodID method_id,   \
                                     const jvalue* args) {                \
    return functions->CallStatic##_jname##MethodA(this, clazz, method_id, \
                                                  args);                  \
  }

#define _JNI_CALL_STATIC_TYPE(_jtype, _jname)   \
  _JNI_CALL_STATIC_TYPE_METHOD(_jtype, _jname)  \
  _JNI_CALL_STATIC_TYPE_METHODV(_jtype, _jname) \
  _JNI_CALL_STATIC_TYPE_METHODA(_jtype, _jname)

  _JNI_CALL_STATIC_TYPE(jobject, Object)
  _JNI_CALL_STATIC_TYPE(jboolean, Boolean)
  _JNI_CALL_STATIC_TYPE(jbyte, Byte)
  _JNI_CALL_STATIC_TYPE(jchar, Char)
  _JNI_CALL_STATIC_TYPE(jshort, Short)
  _JNI_CALL_STATIC_TYPE(jint, Int)
  _JNI_CALL_STATIC_TYPE(jlong, Long)
  _JNI_CALL_STATIC_TYPE(jfloat, Float)
  _JNI_CALL_STATIC_TYPE(jdouble, Double)

  void CallStaticVoidMethod(jclass clazz, jmethodID method_id, ...) {
    va_list args;
    va_start(args, method_id);
    functions->CallStaticVoidMethodV(this, clazz, method_id, args);
    va_end(args);
  }
  void CallStaticVoidMethodV(jclass clazz, jmethodID method_id, va_list args) {
    functions->CallStaticVoidMethodV(this, clazz, method_id, args);
  }
  void CallStaticVoidMethodA(jclass clazz,
                             jmethodID method_id,
                             const jvalue* args) {
    functions->CallStaticVoidMethodA(this, clazz, method_id, args);
  }

  jfieldID GetStaticFieldID(jclass clazz, const char* name, const char* sig) {
    return functions->GetStaticFieldID(this, clazz, name, sig);
  }

  jobject GetStaticObjectField(jclass clazz, jfieldID field_id) {
    return functions->GetStaticObjectField(this, clazz, field_id);
  }
  jboolean GetStaticBooleanField(jclass clazz, jfieldID field_id) {
    return functions->GetStaticBooleanField(this, clazz, field_id);
  }
  jbyte GetStaticByteField(jclass clazz, jfieldID field_id) {
    return functions->GetStaticByteField(this, clazz, field_id);
  }
  jchar GetStaticCharField(jclass clazz, jfieldID field_id) {
    return functions->GetStaticCharField(this, clazz, field_id);
  }
  jshort GetStaticShortField(jclass clazz, jfieldID field_id) {
    return functions->GetStaticShortField(this, clazz, field_id);
  }
  jint GetStaticIntField(jclass clazz, jfieldID field_id) {
    return functions->GetStaticIntField(this, clazz, field_id);
  }
  jlong GetStaticLongField(jclass clazz, jfieldID field_id) {
    return functions->GetStaticLongField(this, clazz, field_id);
  }
  jfloat GetStaticFloatField(jclass clazz, jfieldID field_id) {
    return functions->GetStaticFloatField(this, clazz, field_id);
  }
  jdouble GetStaticDoubleField(jclass clazz, jfieldID field_id) {
    return functions->GetStaticDoubleField(this, clazz, field_id);
  }

  void SetStaticObjectField(jclass clazz, jfieldID field_id, jobject val) {
    functions->SetStaticObjectField(this, clazz, field_id, val);
  }
  void SetStaticBooleanField(jclass clazz, jfieldID field_id, jboolean val) {
    functions->SetStaticBooleanField(this, clazz, field_id, val);
  }
  void SetStaticByteField(jclass clazz, jfieldID field_id, jbyte val) {
    functions->SetStaticByteField(this, clazz, field_id, val);
  }
  void SetStaticCharField(jclass clazz, jfieldID field_id, jchar val) {
    functions->SetStaticCharField(this, clazz, field_id, val);
  }
  void SetStaticShortField(jclass clazz, jfieldID field_id, jshort val) {
    functions->SetStaticShortField(this, clazz, field_id, val);
  }
  void SetStaticIntField(jclass clazz, jfieldID field_id, jint val) {
    functions->SetStaticIntField(this, clazz, field_id, val);
  }
  void SetStaticLongField(jclass clazz, jfieldID field_id, jlong val) {
    functions->SetStaticLongField(this, clazz, field_id, val);
  }
  void SetStaticFloatField(jclass clazz, jfieldID field_id, jfloat val) {
    functions->SetStaticFloatField(this, clazz, field_id, val);
  }
  void SetStaticDoubleField(jclass clazz, jfieldID field_id, jdouble val) {
    functions->SetStaticDoubleField(this, clazz, field_id, val);
  }

  jstring NewString(const jchar* unicode_chars, jsize len) {
    return functions->NewString(this, unicode_chars, len);
  }

  jsize GetStringLength(jstring string) {
    return functions->GetStringLength(this, string);
  }

  const jchar* GetStringChars(jstring string, jboolean* is_copy) {
    return functions->GetStringChars(this, string, is_copy);
  }

  void ReleaseStringChars(jstring string, const jchar* chars) {
    functions->ReleaseStringChars(this, string, chars);
  }

  jstring NewStringUTF(const char* bytes) {
    return functions->NewStringUTF(this, bytes);
  }

  jsize GetStringUTFLength(jstring string) {
    return functions->GetStringUTFLength(this, string);
  }

  const char* GetStringUTFChars(jstring string, jboolean* is_copy) {
    return functions->GetStringUTFChars(this, string, is_copy);
  }

  void ReleaseStringUTFChars(jstring string, const char* utf) {
    functions->ReleaseStringUTFChars(this, string, utf);
  }

  jsize GetArrayLength(jarray array) {
    return functions->GetArrayLength(this, array);
  }

  jobjectArray NewObjectArray(jsize length,
                              jclass element_class,
                              jobject initial_element) {
    return functions->NewObjectArray(this, length, element_class,
                                     initial_element);
  }

  jobject GetObjectArrayElement(jobjectArray array, jsize index) {
    return functions->GetObjectArrayElement(this, array, index);
  }

  void SetObjectArrayElement(jobjectArray array, jsize index, jobject val) {
    functions->SetObjectArrayElement(this, array, index, val);
  }

  jbooleanArray NewBooleanArray(jsize length) {
    return functions->NewBooleanArray(this, length);
  }
  jbyteArray NewByteArray(jsize length) {
    return functions->NewByteArray(this, length);
  }
  jcharArray NewCharArray(jsize length) {
    return functions->NewCharArray(this, length);
  }
  jshortArray NewShortArray(jsize length) {
    return functions->NewShortArray(this, length);
  }
  jintArray NewIntArray(jsize length) {
    return functions->NewIntArray(this, length);
  }
  jlongArray NewLongArray(jsize length) {
    return functions->NewLongArray(this, length);
  }
  jfloatArray NewFloatArray(jsize length) {
    return functions->NewFloatArray(this, length);
  }
  jdoubleArray NewDoubleArray(jsize length) {
    return functions->NewDoubleArray(this, length);
  }

  jboolean* GetBooleanArrayElements(jbooleanArray array, jboolean* is_copy) {
    return functions->GetBooleanArrayElements(this, array, is_copy);
  }
  jbyte* GetByteArrayElements(jbyteArray array, jboolean* is_copy) {
    return functions->GetByteArrayElements(this, array, is_copy);
  }
  jchar* GetCharArrayElements(jcharArray array, jboolean* is_copy) {
    return functions->GetCharArrayElements(this, array, is_copy);
  }
  jshort* GetShortArrayElements(jshortArray array, jboolean* is_copy) {
    return functions->GetShortArrayElements(this, array, is_copy);
  }
  jint* GetIntArrayElements(jintArray array, jboolean* is_copy) {
    return functions->GetIntArrayElements(this, array, is_copy);
  }
  jlong* GetLongArrayElements(jlongArray array, jboolean* is_copy) {
    return functions->GetLongArrayElements(this, array, is_copy);
  }
  jfloat* GetFloatArrayElements(jfloatArray array, jboolean* is_copy) {
    return functions->GetFloatArrayElements(this, array, is_copy);
  }
  jdouble* GetDoubleArrayElements(jdoubleArray array, jboolean* is_copy) {
    return functions->GetDoubleArrayElements(this, array, is_copy);
  }

  void ReleaseBooleanArrayElements(jbooleanArray array,
                                   jboolean* elems,
                                   jint mode) {
    functions->ReleaseBooleanArrayElements(this, array, elems, mode);
  }
  void ReleaseByteArrayElements(jbyteArray array, jbyte* elems, jint mode) {
    functions->ReleaseByteArrayElements(this, array, elems, mode);
  }
  void ReleaseCharArrayElements(jcharArray array, jchar* elems, jint mode) {
    functions->ReleaseCharArrayElements(this, array, elems, mode);
  }
  void ReleaseShortArrayElements(jshortArray array, jshort* elems, jint mode) {
    functions->ReleaseShortArrayElements(this, array, elems, mode);
  }
  void ReleaseIntArrayElements(jintArray array, jint* elems, jint mode) {
    functions->ReleaseIntArrayElements(this, array, elems, mode);
  }
  void ReleaseLongArrayElements(jlongArray array, jlong* elems, jint mode) {
    functions->ReleaseLongArrayElements(this, array, elems, mode);
  }
  void ReleaseFloatArrayElements(jfloatArray array, jfloat* elems, jint mode) {
    functions->ReleaseFloatArrayElements(this, array, elems, mode);
  }
  void ReleaseDoubleArrayElements(jdoubleArray array,
                                  jdouble* elems,
                                  jint mode) {
    functions->ReleaseDoubleArrayElements(this, array, elems, mode);
  }

  void GetBooleanArrayRegion(jbooleanArray array,
                             jsize start,
                             jsize len,
                             jboolean* buf) {
    functions->GetBooleanArrayRegion(this, array, start, len, buf);
  }
  void GetByteArrayRegion(jbyteArray array,
                          jsize start,
                          jsize len,
                          jbyte* buf) {
    functions->GetByteArrayRegion(this, array, start, len, buf);
  }
  void GetCharArrayRegion(jcharArray array,
                          jsize start,
                          jsize len,
                          jchar* buf) {
    functions->GetCharArrayRegion(this, array, start, len, buf);
  }
  void GetShortArrayRegion(jshortArray array,
                           jsize start,
                           jsize len,
                           jshort* buf) {
    functions->GetShortArrayRegion(this, array, start, len, buf);
  }
  void GetIntArrayRegion(jintArray array, jsize start, jsize len, jint* buf) {
    functions->GetIntArrayRegion(this, array, start, len, buf);
  }
  void GetLongArrayRegion(jlongArray array,
                          jsize start,
                          jsize len,
                          jlong* buf) {
    functions->GetLongArrayRegion(this, array, start, len, buf);
  }
  void GetFloatArrayRegion(jfloatArray array,
                           jsize start,
                           jsize len,
                           jfloat* buf) {
    functions->GetFloatArrayRegion(this, array, start, len, buf);
  }
  void GetDoubleArrayRegion(jdoubleArray array,
                            jsize start,
                            jsize len,
                            jdouble* buf) {
    functions->GetDoubleArrayRegion(this, array, start, len, buf);
  }

  void SetBooleanArrayRegion(jbooleanArray array,
                             jsize start,
                             jsize len,
                             const jboolean* buf) {
    functions->SetBooleanArrayRegion(this, array, start, len, buf);
  }
  void SetByteArrayRegion(jbyteArray array,
                          jsize start,
                          jsize len,
                          const jbyte* buf) {
    functions->SetByteArrayRegion(this, array, start, len, buf);
  }
  void SetCharArrayRegion(jcharArray array,
                          jsize start,
                          jsize len,
                          const jchar* buf) {
    functions->SetCharArrayRegion(this, array, start, len, buf);
  }
  void SetShortArrayRegion(jshortArray array,
                           jsize start,
                           jsize len,
                           const jshort* buf) {
    functions->SetShortArrayRegion(this, array, start, len, buf);
  }
  void SetIntArrayRegion(jintArray array,
                         jsize start,
                         jsize len,
                         const jint* buf) {
    functions->SetIntArrayRegion(this, array, start, len, buf);
  }
  void SetLongArrayRegion(jlongArray array,
                          jsize start,
                          jsize len,
                          const jlong* buf) {
    functions->SetLongArrayRegion(this, array, start, len, buf);
  }
  void SetFloatArrayRegion(jfloatArray array,
                           jsize start,
                           jsize len,
                           const jfloat* buf) {
    functions->SetFloatArrayRegion(this, array, start, len, buf);
  }
  void SetDoubleArrayRegion(jdoubleArray array,
                            jsize start,
                            jsize len,
                            const jdouble* buf) {
    functions->SetDoubleArrayRegion(this, array, start, len, buf);
  }

  jint RegisterNatives(jclass clazz,
                       const JNINativeMethod* methods,
                       jint n_methods) {
    return functions->RegisterNatives(this, clazz, methods, n_methods);
  }

  jint UnregisterNatives(jclass clazz) {
    return functions->UnregisterNatives(this, clazz);
  }

  jint MonitorEnter(jobject obj) { return functions->MonitorEnter(this, obj); }

  jint MonitorExit(jobject obj) { return functions->MonitorExit(this, obj); }

  jint GetJavaVM(JavaVM** vm) { return functions->GetJavaVM(this, vm); }

  void GetStringRegion(jstring str, jsize start, jsize len, jchar* buf) {
    functions->GetStringRegion(this, str, start, len, buf);
  }

  void GetStringUTFRegion(jstring str, jsize start, jsize len, char* buf) {
    functions->GetStringUTFRegion(this, str, start, len, buf);
  }

  void* GetPrimitiveArrayCritical(jarray array, jboolean* is_copy) {
    return functions->GetPrimitiveArrayCritical(this, array, is_copy);
  }

  void ReleasePrimitiveArrayCritical(jarray array, void* carray, jint mode) {
    functions->ReleasePrimitiveArrayCritical(this, array, carray, mode);
  }

  const jchar* GetStringCritical(jstring str, jboolean* is_copy) {
    return functions->GetStringCritical(this, str, is_copy);
  }

  void ReleaseStringCritical(jstring str, const jchar* carray) {
    functions->ReleaseStringCritical(this, str, carray);
  }

  jweak NewWeakGlobalRef(jobject obj) {
    return functions->NewWeakGlobalRef(this, obj);
  }

  void DeleteWeakGlobalRef(jweak obj) {
    functions->DeleteWeakGlobalRef(this, obj);
  }

  jboolean ExceptionCheck() { return functions->ExceptionCheck(this); }

  jobject NewDirectByteBuffer(void* address, jlong capacity) {
    return functions->NewDirectByteBuffer(this, address, capacity);
  }

  void* GetDirectBufferAddress(jobject buf) {
    return functions->GetDirectBufferAddress(this, buf);
  }

  jlong GetDirectBufferCapacity(jobject buf) {
    return functions->GetDirectBufferCapacity(this, buf);
  }

  /* added in JNI 1.6 */
  jobjectRefType GetObjectRefType(jobject obj) {
    return functions->GetObjectRefType(this, obj);
  }

#undef _JNI_CALL_TYPE_METHOD
#undef _JNI_CALL_TYPE_METHODV
#undef _JNI_CALL_TYPE_METHODA
#undef _JNI_CALL_TYPE
#undef _JNI_CALL_NONVIRT_TYPE_METHOD
#undef _JNI_CALL_NONVIRT_TYPE_METHODV
#undef _JNI_CALL_NONVIRT_TYPE_METHODA
#undef _JNI_CALL_NONVIRT_TYPE
#undef _JNI_CALL_STATIC_TYPE_METHOD
#undef _JNI_CALL_STATIC_TYPE_METHODV
#undef _JNI_CALL_STATIC_TYPE_METHODA
#undef _JNI_CALL_STATIC_TYPE

#endif /* __cplusplus */
};

/*
 * JNI invocation interface.
 */
struct JNIInvokeInterface {
  void* reserved0;
  void* reserved1;
  void* reserved2;

  jint (*DestroyJavaVM)(JavaVM* vm);
  jint (*AttachCurrentThread)(JavaVM* vm, JNIEnv** p_env, void* thr_args);
  jint (*DetachCurrentThread)(JavaVM* vm);
  jint (*GetEnv)(JavaVM* vm, void** p_env, jint version);
  jint (*AttachCurrentThreadAsDaemon)(JavaVM* vm,
                                      JNIEnv** p_env,
                                      void* thr_args);
};

/*
 * C++ version.
 */
struct _JavaVM {
  const struct JNIInvokeInterface* functions;

#if defined(__cplusplus)
  jint DestroyJavaVM() { return functions->DestroyJavaVM(this); }
  jint AttachCurrentThread(JNIEnv** p_env, void* thr_args) {
    return functions->AttachCurrentThread(this, p_env, thr_args);
  }
  jint DetachCurrentThread() { return functions->DetachCurrentThread(this); }
  jint GetEnv(void** p_env, jint version) {
    return functions->GetEnv(this, p_env, version);
  }
  jint AttachCurrentThreadAsDaemon(JNIEnv** p_env, void* thr_args) {
    return functions->AttachCurrentThreadAsDaemon(this, p_env, thr_args);
  }
#endif /* __cplusplus */
};

struct JavaVMAttachArgs {
  jint version;     /* must be >= JNI_VERSION_1_2 */
  const char* name; /* NULL or name of thread as modified UTF-8 str */
  jobject group;    /* global ref of a ThreadGroup object, or NULL */
};
typedef struct JavaVMAttachArgs JavaVMAttachArgs;

/*
 * JNI 1.2+ initialization.  (As of 1.6, the pre-1.2 structures are no
 * longer supported.)
 */
typedef struct JavaVMOption {
  const char* optionString;
  void* extraInfo;
} JavaVMOption;

typedef struct JavaVMInitArgs {
  jint version; /* use JNI_VERSION_1_2 or later */

  jint nOptions;
  JavaVMOption* options;
  jboolean ignoreUnrecognized;
} JavaVMInitArgs;

#ifdef __cplusplus
extern "C" {
#endif

/*
 * VM initialization functions.
 *
 * Note these are the only symbols exported for JNI by the VM.
 */
jint JNI_GetDefaultJavaVMInitArgs(void*);
jint JNI_CreateJavaVM(JavaVM**, JNIEnv**, void*);
jint JNI_GetCreatedJavaVMs(JavaVM**, jsize, jsize*);

#if defined(_WIN32) || defined(__WIN32__) || defined(WIN32)
#define JNIIMPORT __declspec(dllimport)
#define JNIEXPORT __declspec(dllexport)
#define JNICALL __stdcall
#else
#define JNIIMPORT
#define JNIEXPORT __attribute__((visibility("default")))
#define JNICALL
#endif

/*
 * Prototypes for functions exported by loadable shared libs.  These are
 * called by JNI, not provided by JNI.
 */
JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void* reserved);
JNIEXPORT void JNI_OnUnload(JavaVM* vm, void* reserved);

#ifdef __cplusplus
}
#endif

/*
 * Manifest constants.
 */
#define JNI_FALSE 0
#define JNI_TRUE 1

#define JNI_VERSION_1_1 0x00010001
#define JNI_VERSION_1_2 0x00010002
#define JNI_VERSION_1_4 0x00010004
#define JNI_VERSION_1_6 0x00010006

#define JNI_OK (0)         /* no error */
#define JNI_ERR (-1)       /* generic error */
#define JNI_EDETACHED (-2) /* thread detached from the VM */
#define JNI_EVERSION (-3)  /* JNI version error */
#define JNI_ENOMEM (-4)    /* Out of memory */
#define JNI_EEXIST (-5)    /* VM already created */
#define JNI_EINVAL (-6)    /* Invalid argument */

#define JNI_COMMIT 1 /* copy content, do not free buffer */
#define JNI_ABORT 2  /* free buffer w/o copying back */

// NOLINTEND(readability-identifier-naming)

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_JNI_INCLUDE_JNI_H_
