// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/android/tracing_controller.h"

#include "base/android/jni_android.h"
#include "base/android/jni_string.h"
#include "base/files/file_util.h"
#include "base/macros.h"
#include "base/trace_event/trace_event.h"
#include "jni/TracingController_jni.h"

namespace sky {
namespace shell {
namespace {

const char kStart[] = "{\"traceEvents\":[";
const char kEnd[] = "]}";

static FILE* g_file = NULL;

void Write(const std::string& data) {
  ignore_result(fwrite(data.data(), data.length(), 1, g_file));
}

void HandleChunk(const scoped_refptr<base::RefCountedString>& chunk,
                 bool has_more_events) {
  Write(chunk->data());
  if (has_more_events)
    Write(",");

  if (!has_more_events) {
    Write(kEnd);
    base::CloseFile(g_file);
    g_file = NULL;

    LOG(INFO) << "Trace complete";
  }
}

}  // namespace

static void StartTracing(JNIEnv* env, jclass clazz) {
  LOG(INFO) << "Starting trace";

  base::trace_event::TraceLog::GetInstance()->SetEnabled(
      base::trace_event::CategoryFilter("*"),
      base::trace_event::TraceLog::RECORDING_MODE,
      base::trace_event::TraceOptions(base::trace_event::RECORD_UNTIL_FULL));
}

static void StopTracing(JNIEnv* env, jclass clazz, jstring path) {
  base::trace_event::TraceLog::GetInstance()->SetDisabled();

  base::FilePath file_path(base::android::ConvertJavaStringToUTF8(env, path));
  g_file = base::OpenFile(file_path, "w");
  CHECK(g_file) << "Failed to open file " << file_path.LossyDisplayName();

  LOG(INFO) << "Saving trace to " << file_path.LossyDisplayName();
  Write(kStart);
  base::trace_event::TraceLog::GetInstance()->Flush(base::Bind(&HandleChunk));
}

bool RegisterTracingController(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

}  // namespace shell
}  // namespace sky
