// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/platform/android/android_image_generator.h"
#include "flutter/shell/platform/android/flutter_embedder_native.h"
#include "flutter/shell/platform/android/flutter_main.h"

// This is called by the VM when the shared library is first loaded.
JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void* reserved) {
  TRACE_EVENT0("flutter", "JNI_OnLoad");
  // Initialize the Java VM.
  fml::jni::InitJavaVM(vm);

  JNIEnv* env = fml::jni::AttachCurrentThread();
  bool result = false;

  // Register FlutterEmbedderNative.
  result = flutter::android::FlutterEmbedderNative::RegisterJni(env);
  FML_CHECK(result);

  // Register FlutterMain.
  result = flutter::FlutterMain::Register(env);
  FML_CHECK(result);

  // Register AndroidImageDecoder.
  result = flutter::AndroidImageGenerator::Register(env);
  FML_CHECK(result);

  return JNI_VERSION_1_4;
}
