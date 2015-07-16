// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "services/android/java_handler.h"

#include "base/android/base_jni_onload.h"
#include "base/android/base_jni_registrar.h"
#include "base/android/jni_android.h"
#include "base/android/jni_string.h"
#include "base/android/library_loader/library_loader_hooks.h"
#include "base/bind.h"
#include "base/files/file_path.h"
#include "base/logging.h"
#include "base/run_loop.h"
#include "base/scoped_native_library.h"
#include "base/trace_event/trace_event.h"
#include "jni/JavaHandler_jni.h"
#include "mojo/android/system/base_run_loop.h"
#include "mojo/android/system/core_impl.h"
#include "mojo/application/application_runner_chromium.h"
#include "mojo/application/content_handler_factory.h"
#include "mojo/public/c/system/main.h"
#include "mojo/public/cpp/application/application_impl.h"

using base::android::AttachCurrentThread;
using base::android::ScopedJavaLocalRef;
using base::android::ConvertJavaStringToUTF8;
using base::android::ConvertUTF8ToJavaString;
using base::android::GetApplicationContext;

namespace {

bool RegisterJNI(JNIEnv* env) {
  if (!base::android::RegisterJni(env))
    return false;

  if (!services::android::RegisterNativesImpl(env))
    return false;

  if (!mojo::android::RegisterCoreImpl(env))
    return false;

  if (!mojo::android::RegisterBaseRunLoop(env))
    return false;

  return true;
}

}  // namespace

namespace services {
namespace android {

JavaHandler::JavaHandler() : content_handler_factory_(this) {
}

JavaHandler::~JavaHandler() {
}

void JavaHandler::RunApplication(
    mojo::InterfaceRequest<mojo::Application> application_request,
    mojo::URLResponsePtr response) {
  TRACE_EVENT_BEGIN1("java_handler", "JavaHandler::RunApplication", "url",
                     std::string(response->url));
  JNIEnv* env = base::android::AttachCurrentThread();
  base::FilePath archive_path;
  base::FilePath cache_dir;
  {
    base::MessageLoop loop;
    handler_task_runner_->PostTask(
        FROM_HERE,
        base::Bind(&JavaHandler::GetApplication, base::Unretained(this),
                   base::Unretained(&archive_path),
                   base::Unretained(&cache_dir), base::Passed(response.Pass()),
                   base::Bind(base::IgnoreResult(
                                  &base::SingleThreadTaskRunner::PostTask),
                              loop.task_runner(), FROM_HERE,
                              base::MessageLoop::QuitWhenIdleClosure())));
    base::RunLoop().Run();
  }


  jobject context = base::android::GetApplicationContext();
  ScopedJavaLocalRef<jstring> j_archive_path =
      ConvertUTF8ToJavaString(env, archive_path.value());
  ScopedJavaLocalRef<jstring> j_cache_dir =
      ConvertUTF8ToJavaString(env, cache_dir.value());
  Java_JavaHandler_bootstrap(
      env, context, j_archive_path.obj(), j_cache_dir.obj(),
      application_request.PassMessagePipe().release().value());
}

void JavaHandler::Initialize(mojo::ApplicationImpl* app) {
  tracing_.Initialize(app);
  handler_task_runner_ = base::MessageLoop::current()->task_runner();
  app->ConnectToService("mojo:url_response_disk_cache",
                        &url_response_disk_cache_);
}

void JavaHandler::GetApplication(base::FilePath* archive_path,
                                 base::FilePath* cache_dir,
                                 mojo::URLResponsePtr response,
                                 const base::Closure& callback) {
  url_response_disk_cache_->GetFile(
      response.Pass(),
      [archive_path, cache_dir, callback](mojo::Array<uint8_t> extracted_path,
                                          mojo::Array<uint8_t> cache_path) {
        if (extracted_path.is_null()) {
          *archive_path = base::FilePath();
          *cache_dir = base::FilePath();
        } else {
          *archive_path = base::FilePath(
              std::string(reinterpret_cast<char*>(&extracted_path.front()),
                          extracted_path.size()));
          *cache_dir = base::FilePath(std::string(
              reinterpret_cast<char*>(&cache_path.front()), cache_path.size()));
        }
        callback.Run();
      });
}

bool JavaHandler::ConfigureIncomingConnection(
    mojo::ApplicationConnection* connection) {
  connection->AddService(&content_handler_factory_);
  return true;
}

void PreInvokeEvent(JNIEnv* env, jclass jcaller) {
  TRACE_EVENT_END0("java_handler", "JavaHandler::RunApplication");
}

}  // namespace android
}  // namespace services

MojoResult MojoMain(MojoHandle application_request) {
  mojo::ApplicationRunnerChromium runner(new services::android::JavaHandler());
  return runner.Run(application_request);
}

JNI_EXPORT jint JNI_OnLoad(JavaVM* vm, void* reserved) {
  std::vector<base::android::RegisterCallback> register_callbacks;
  register_callbacks.push_back(base::Bind(&RegisterJNI));
  if (!base::android::OnJNIOnLoadRegisterJNI(vm, register_callbacks) ||
      !base::android::OnJNIOnLoadInit(
          std::vector<base::android::InitCallback>())) {
    return -1;
  }

  // There cannot be two AtExit objects triggering at the same time. Remove the
  // one from LibraryLoader as ApplicationRunnerChromium also uses one.
  base::android::LibraryLoaderExitHook();

  return JNI_VERSION_1_4;
}

// This is needed because the application needs to access the application
// context.
extern "C" JNI_EXPORT void InitApplicationContext(
    const base::android::JavaRef<jobject>& context) {
  JNIEnv* env = base::android::AttachCurrentThread();
  base::android::InitApplicationContext(env, context);
}

