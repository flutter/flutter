// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/bindings/jni/dart_jni.h"

#include <vector>

#include "base/logging.h"
#include "base/android/jni_android.h"
#include "base/android/jni_string.h"
#include "base/strings/string_util.h"
#include "sky/engine/tonic/dart_args.h"
#include "sky/engine/tonic/dart_binding_macros.h"
#include "sky/engine/tonic/dart_converter.h"

namespace blink {

using base::android::ScopedJavaLocalRef;
using base::android::ScopedJavaGlobalRef;

#define ENTER_JNI()                                                            \
  JNIEnv* env = base::android::AttachCurrentThread();                          \
  base::android::ScopedJavaLocalFrame java_frame(env);

namespace {

DartLibraryNatives* g_natives = nullptr;

Dart_NativeFunction GetNativeFunction(Dart_Handle name,
                                      int argument_count,
                                      bool* auto_setup_scope) {
  return g_natives->GetNativeFunction(name, argument_count, auto_setup_scope);
}

const uint8_t* GetSymbol(Dart_NativeFunction native_function) {
  return g_natives->GetSymbol(native_function);
}

// Check if a JNI API has thrown an exception.  If so, convert it to a
// Dart exception.
bool CheckJniException(JNIEnv* env, Dart_Handle *exception) {
  if (env->ExceptionCheck() == JNI_FALSE)
    return false;

  jthrowable java_throwable = env->ExceptionOccurred();
  env->ExceptionClear();
  std::string info = base::android::GetJavaExceptionInfo(
      env, java_throwable);

  *exception = StdStringToDart(info);
  return true;
}

// Check if a Dart API returned an error handle.
bool CheckDartException(Dart_Handle result, Dart_Handle* exception) {
  if (!Dart_IsError(result))
    return false;

  *exception = result;
  return true;
}

} // anonymous namespace

DART_NATIVE_CALLBACK_STATIC(JniClass, FromName);

#define FOR_EACH_BINDING(V) \
  V(JniArray, GetLength) \
  V(JniClass, CallStaticLongMethod) \
  V(JniClass, NewObject) \
  V(JniClass, GetFieldId) \
  V(JniClass, GetMethodId) \
  V(JniClass, GetStaticFieldId) \
  V(JniClass, GetStaticIntField) \
  V(JniClass, GetStaticMethodId) \
  V(JniClass, GetStaticObjectField) \
  V(JniObject, CallBooleanMethod) \
  V(JniObject, CallIntMethod) \
  V(JniObject, CallObjectMethod) \
  V(JniObject, GetIntField) \
  V(JniObjectArray, GetArrayElement) \
  V(JniObjectArray, SetArrayElement) \
  V(JniString, GetText)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void DartJni::InitForGlobal() {
  if (!g_natives) {
    g_natives = new DartLibraryNatives();

    g_natives->Register({
      DART_REGISTER_NATIVE_STATIC(JniClass, FromName)
      FOR_EACH_BINDING(DART_REGISTER_NATIVE)
    });
  }
}

void DartJni::InitForIsolate() {
  DCHECK(g_natives);
  DART_CHECK_VALID(Dart_SetNativeResolver(
      Dart_LookupLibrary(ToDart("dart:jni")), GetNativeFunction, GetSymbol));
}

ScopedJavaGlobalRef<jobject> DartJni::class_loader_;
jmethodID DartJni::class_loader_load_class_method_id_;
jmethodID DartJni::class_get_name_method_id_;

bool DartJni::InitJni() {
  JNIEnv* env = base::android::AttachCurrentThread();

  class_loader_.Reset(base::android::GetClassLoader(env));

  ScopedJavaLocalRef<jclass> class_loader_clazz(
      env, env->FindClass("java/lang/ClassLoader"));
  CHECK(!base::android::ClearException(env));

  class_loader_load_class_method_id_ = env->GetMethodID(
      class_loader_clazz.obj(),
      "loadClass",
      "(Ljava/lang/String;)Ljava/lang/Class;");
  CHECK(!base::android::ClearException(env));

  ScopedJavaLocalRef<jclass> class_clazz(
      env, env->FindClass("java/lang/Class"));
  CHECK(!base::android::ClearException(env));

  class_get_name_method_id_ = env->GetMethodID(
      class_clazz.obj(),
      "getName",
      "()Ljava/lang/String;");
  CHECK(!base::android::ClearException(env));

  return true;
}

ScopedJavaLocalRef<jclass> DartJni::GetClass(JNIEnv* env, const char* name) {
  jobject clazz = env->CallObjectMethod(
      class_loader_.obj(),
      class_loader_load_class_method_id_,
      base::android::ConvertUTF8ToJavaString(env, name).obj());

  return ScopedJavaLocalRef<jclass>(env, static_cast<jclass>(clazz));
}

std::string DartJni::GetObjectClassName(JNIEnv* env, jobject obj) {
  jclass clazz = env->GetObjectClass(obj);
  DCHECK(clazz);
  jstring name = static_cast<jstring>(
      env->CallObjectMethod(clazz, class_get_name_method_id_));
  DCHECK(name);

  return base::android::ConvertJavaStringToUTF8(env, name);
}

class JniMethodArgs {
 public:
  void Convert(JNIEnv* env,
               const Vector<Dart_Handle>& dart_args,
               Dart_Handle* exception);
  jvalue* jvalues() { return jvalues_.data(); }

 private:
  jvalue DartToJavaValue(JNIEnv* env,
                         Dart_Handle handle,
                         Dart_Handle* exception);

  std::vector<jvalue> jvalues_;
};

void JniMethodArgs::Convert(JNIEnv* env,
                            const Vector<Dart_Handle>& dart_args,
                            Dart_Handle* exception) {
  jvalues_.reserve(dart_args.size());

  for (Dart_Handle dart_arg : dart_args) {
    jvalue value = DartToJavaValue(env, dart_arg, exception);
    if (*exception) return;
    jvalues_.push_back(value);
  }
}

jvalue JniMethodArgs::DartToJavaValue(JNIEnv* env,
                                      Dart_Handle dart_value,
                                      Dart_Handle* exception) {
  jvalue java_value = jvalue();

  if (Dart_IsBoolean(dart_value)) {
    java_value.z = DartConverter<bool>::FromDart(dart_value);
  } else if (Dart_IsInteger(dart_value)) {
    java_value.j = DartConverter<jlong>::FromDart(dart_value);
  } else if (Dart_IsDouble(dart_value)) {
    java_value.d = DartConverter<jdouble>::FromDart(dart_value);
  } else if (Dart_IsString(dart_value)) {
    intptr_t length;
    Dart_Handle result = Dart_StringLength(dart_value, &length);
    if (CheckDartException(result, exception)) return java_value;

    std::vector<uint16_t> string_data(length);
    result = Dart_StringToUTF16(dart_value, string_data.data(), &length);
    if (CheckDartException(result, exception)) return java_value;

    java_value.l = env->NewString(string_data.data(), length);
    CheckJniException(env, exception);
  } else {
    *exception = ToDart("Argument has unsupported data type");
  }

  return java_value;
}

IMPLEMENT_WRAPPERTYPEINFO(jni, JniClass);

JniClass::JniClass(JNIEnv* env, jclass clazz)
    : clazz_(env, clazz) {
}

JniClass::~JniClass() {
}

PassRefPtr<JniClass> JniClass::FromName(const char* name) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    ScopedJavaLocalRef<jclass> clazz = DartJni::GetClass(env, name);
    if (CheckJniException(env, &exception)) goto fail;

    return adoptRef(new JniClass(env, clazz.obj()));
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return nullptr;
}

intptr_t JniClass::GetFieldId(const char* name, const char* sig) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jfieldID id = env->GetFieldID(clazz_.obj(), name, sig);
    if (CheckJniException(env, &exception)) goto fail;

    return reinterpret_cast<intptr_t>(id);
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

intptr_t JniClass::GetStaticFieldId(const char* name, const char* sig) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jfieldID id = env->GetStaticFieldID(clazz_.obj(), name, sig);
    if (CheckJniException(env, &exception)) goto fail;

    return reinterpret_cast<intptr_t>(id);
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

intptr_t JniClass::GetMethodId(const char* name, const char* sig) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jmethodID id = env->GetMethodID(clazz_.obj(), name, sig);
    if (CheckJniException(env, &exception)) goto fail;

    return reinterpret_cast<intptr_t>(id);
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

intptr_t JniClass::GetStaticMethodId(const char* name, const char* sig) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jmethodID id = env->GetStaticMethodID(clazz_.obj(), name, sig);
    if (CheckJniException(env, &exception)) goto fail;

    return reinterpret_cast<intptr_t>(id);
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

jint JniClass::GetStaticIntField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jint result = env->GetStaticIntField(clazz_.obj(), fieldId);
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

PassRefPtr<JniObject> JniClass::GetStaticObjectField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jobject obj = env->GetStaticObjectField(clazz_.obj(), fieldId);
    if (CheckJniException(env, &exception)) goto fail;

    return JniObject::Create(env, obj);
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return nullptr;
}

PassRefPtr<JniObject> JniClass::NewObject(jmethodID methodId,
                                          const Vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception) goto fail;

    jobject obj = env->NewObjectA(clazz_.obj(), methodId, java_args.jvalues());
    if (CheckJniException(env, &exception)) goto fail;

    return JniObject::Create(env, obj);
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return nullptr;
}

jlong JniClass::CallStaticLongMethod(jmethodID methodId,
                                     const Vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception) goto fail;

    jlong result = env->CallStaticLongMethodA(clazz_.obj(), methodId,
                                              java_args.jvalues());
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

IMPLEMENT_WRAPPERTYPEINFO(jni, JniObject);

JniObject::JniObject(JNIEnv* env, jobject object)
    : object_(env, object) {
}

JniObject::~JniObject() {
}

PassRefPtr<JniObject> JniObject::Create(JNIEnv* env, jobject object) {
  std::string class_name = DartJni::GetObjectClassName(env, object);

  JniObject* result;

  if (class_name == "java.lang.String") {
    result = new JniString(env, static_cast<jstring>(object));
  } else if (base::StartsWith(class_name, "[L", base::CompareCase::SENSITIVE)) {
    result = new JniObjectArray(env, static_cast<jobjectArray>(object));
  } else {
    result = new JniObject(env, object);
  }

  return adoptRef(result);
}

jint JniObject::GetIntField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jint result = env->GetIntField(java_object(), fieldId);
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

PassRefPtr<JniObject> JniObject::CallObjectMethod(
    jmethodID methodId,
    const Vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception) goto fail;

    jobject result = env->CallObjectMethodA(java_object(), methodId,
                                            java_args.jvalues());
    if (CheckJniException(env, &exception)) goto fail;

    return JniObject::Create(env, result);
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return nullptr;
}

bool JniObject::CallBooleanMethod(jmethodID methodId,
                                  const Vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception) goto fail;

    jboolean result = env->CallBooleanMethodA(java_object(), methodId,
                                              java_args.jvalues());
    if (CheckJniException(env, &exception)) goto fail;

    return result == JNI_TRUE;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return false;
}

jint JniObject::CallIntMethod(jmethodID methodId,
                              const Vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception) goto fail;

    jint result = env->CallIntMethodA(java_object(), methodId,
                                      java_args.jvalues());
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

IMPLEMENT_WRAPPERTYPEINFO(jni, JniString);

JniString::JniString(JNIEnv* env, jstring object)
    : JniObject(env, object) {}

JniString::~JniString() {
}

jstring JniString::java_string() {
  return static_cast<jstring>(java_object());
}

String JniString::GetText() {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jsize length = env->GetStringLength(java_string());
    if (CheckJniException(env, &exception)) goto fail;

    const jchar* chars = env->GetStringChars(java_string(), NULL);
    if (CheckJniException(env, &exception)) goto fail;

    String result(chars, length);
    env->ReleaseStringChars(java_string(), chars);

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return String();
}

IMPLEMENT_WRAPPERTYPEINFO(jni, JniArray);

JniArray::JniArray(JNIEnv* env, jarray array)
    : JniObject(env, array) {}

JniArray::~JniArray() {
}

jsize JniArray::GetLength() {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jsize result = env->GetArrayLength(java_array<jarray>());
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

template<typename JArrayType>
JArrayType JniArray::java_array() const {
  return static_cast<JArrayType>(java_object());
}

IMPLEMENT_WRAPPERTYPEINFO(jni, JniObjectArray);

JniObjectArray::JniObjectArray(JNIEnv* env, jobjectArray array)
    : JniArray(env, array) {}

JniObjectArray::~JniObjectArray() {
}

PassRefPtr<JniObject> JniObjectArray::GetArrayElement(jsize index) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jobject obj = env->GetObjectArrayElement(java_array<jobjectArray>(),
                                             index);
    if (CheckJniException(env, &exception)) goto fail;

    return JniObject::Create(env, obj);
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return nullptr;
}

void JniObjectArray::SetArrayElement(jsize index, const JniObject* value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetObjectArrayElement(java_array<jobjectArray>(), index,
                               value->java_object());
    if (CheckJniException(env, &exception)) goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
}

} // namespace blink
