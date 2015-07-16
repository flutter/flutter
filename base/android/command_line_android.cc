// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/command_line_android.h"

#include "base/android/jni_array.h"
#include "base/android/jni_string.h"
#include "base/command_line.h"
#include "base/logging.h"
#include "jni/CommandLine_jni.h"

using base::android::ConvertUTF8ToJavaString;
using base::android::ConvertJavaStringToUTF8;
using base::CommandLine;

namespace {

void AppendJavaStringArrayToCommandLine(JNIEnv* env,
                                        jobjectArray array,
                                        bool includes_program) {
  std::vector<std::string> vec;
  if (array)
    base::android::AppendJavaStringArrayToStringVector(env, array, &vec);
  if (!includes_program)
    vec.insert(vec.begin(), "");
  CommandLine extra_command_line(vec);
  CommandLine::ForCurrentProcess()->AppendArguments(extra_command_line,
                                                    includes_program);
}

}  // namespace

static void Reset(JNIEnv* env, jclass clazz) {
  CommandLine::Reset();
}

static jboolean HasSwitch(JNIEnv* env, jclass clazz, jstring jswitch) {
  std::string switch_string(ConvertJavaStringToUTF8(env, jswitch));
  return CommandLine::ForCurrentProcess()->HasSwitch(switch_string);
}

static jstring GetSwitchValue(JNIEnv* env, jclass clazz, jstring jswitch) {
  std::string switch_string(ConvertJavaStringToUTF8(env, jswitch));
  std::string value(CommandLine::ForCurrentProcess()->GetSwitchValueNative(
      switch_string));
  if (value.empty())
    return 0;
  // OK to release, JNI binding.
  return ConvertUTF8ToJavaString(env, value).Release();
}

static void AppendSwitch(JNIEnv* env, jclass clazz, jstring jswitch) {
  std::string switch_string(ConvertJavaStringToUTF8(env, jswitch));
  CommandLine::ForCurrentProcess()->AppendSwitch(switch_string);
}

static void AppendSwitchWithValue(JNIEnv* env, jclass clazz,
                                  jstring jswitch, jstring jvalue) {
  std::string switch_string(ConvertJavaStringToUTF8(env, jswitch));
  std::string value_string (ConvertJavaStringToUTF8(env, jvalue));
  CommandLine::ForCurrentProcess()->AppendSwitchASCII(switch_string,
                                                      value_string);
}

static void AppendSwitchesAndArguments(JNIEnv* env, jclass clazz,
                                       jobjectArray array) {
  AppendJavaStringArrayToCommandLine(env, array, false);
}

namespace base {
namespace android {

void InitNativeCommandLineFromJavaArray(JNIEnv* env, jobjectArray array) {
  // TODO(port): Make an overload of Init() that takes StringVector rather than
  // have to round-trip via AppendArguments.
  CommandLine::Init(0, NULL);
  AppendJavaStringArrayToCommandLine(env, array, true);
}

bool RegisterCommandLine(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

}  // namespace android
}  // namespace base
