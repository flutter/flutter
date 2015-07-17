// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/library_loader/library_loader_hooks.h"

#include "base/android/command_line_android.h"
#include "base/android/jni_string.h"
#include "base/android/library_loader/library_load_from_apk_status_codes.h"
#include "base/android/library_loader/library_prefetcher.h"
#include "base/at_exit.h"
#include "base/metrics/histogram.h"
#include "jni/LibraryLoader_jni.h"

namespace base {
namespace android {

namespace {

base::AtExitManager* g_at_exit_manager = NULL;
const char* g_library_version_number = "";
LibraryLoadedHook* g_registration_callback = NULL;

enum RendererHistogramCode {
  // Renderer load at fixed address success, fail, or not attempted.
  // Renderers do not attempt to load at at fixed address if on a
  // low-memory device on which browser load at fixed address has already
  // failed.
  LFA_SUCCESS = 0,
  LFA_BACKOFF_USED = 1,
  LFA_NOT_ATTEMPTED = 2,

  // End sentinel, also used as nothing-pending indicator.
  MAX_RENDERER_HISTOGRAM_CODE = 3,
  NO_PENDING_HISTOGRAM_CODE = MAX_RENDERER_HISTOGRAM_CODE
};

enum BrowserHistogramCode {
  // Non-low-memory random address browser loads.
  NORMAL_LRA_SUCCESS = 0,

  // Low-memory browser loads at fixed address, success or fail.
  LOW_MEMORY_LFA_SUCCESS = 1,
  LOW_MEMORY_LFA_BACKOFF_USED = 2,

  MAX_BROWSER_HISTOGRAM_CODE = 3,
};

RendererHistogramCode g_renderer_histogram_code = NO_PENDING_HISTOGRAM_CODE;

// The amount of time, in milliseconds, that it took to load the shared
// libraries in the renderer. Set in
// RegisterChromiumAndroidLinkerRendererHistogram.
long g_renderer_library_load_time_ms = 0;

} // namespace

static void RegisterChromiumAndroidLinkerRendererHistogram(
    JNIEnv* env,
    jobject jcaller,
    jboolean requested_shared_relro,
    jboolean load_at_fixed_address_failed,
    jlong library_load_time_ms) {
  // Note a pending histogram value for later recording.
  if (requested_shared_relro) {
    g_renderer_histogram_code = load_at_fixed_address_failed
                                ? LFA_BACKOFF_USED : LFA_SUCCESS;
  } else {
    g_renderer_histogram_code = LFA_NOT_ATTEMPTED;
  }

  g_renderer_library_load_time_ms = library_load_time_ms;
}

void RecordChromiumAndroidLinkerRendererHistogram() {
  if (g_renderer_histogram_code == NO_PENDING_HISTOGRAM_CODE)
    return;
  // Record and release the pending histogram value.
  UMA_HISTOGRAM_ENUMERATION("ChromiumAndroidLinker.RendererStates",
                            g_renderer_histogram_code,
                            MAX_RENDERER_HISTOGRAM_CODE);
  g_renderer_histogram_code = NO_PENDING_HISTOGRAM_CODE;

  // Record how long it took to load the shared libraries.
  UMA_HISTOGRAM_TIMES("ChromiumAndroidLinker.RendererLoadTime",
      base::TimeDelta::FromMilliseconds(g_renderer_library_load_time_ms));
}

static void RecordChromiumAndroidLinkerBrowserHistogram(
    JNIEnv* env,
    jobject jcaller,
    jboolean is_using_browser_shared_relros,
    jboolean load_at_fixed_address_failed,
    jint library_load_from_apk_status,
    jlong library_load_time_ms) {
  // For low-memory devices, record whether or not we successfully loaded the
  // browser at a fixed address. Otherwise just record a normal invocation.
  BrowserHistogramCode histogram_code;
  if (is_using_browser_shared_relros) {
    histogram_code = load_at_fixed_address_failed
                     ? LOW_MEMORY_LFA_BACKOFF_USED : LOW_MEMORY_LFA_SUCCESS;
  } else {
    histogram_code = NORMAL_LRA_SUCCESS;
  }
  UMA_HISTOGRAM_ENUMERATION("ChromiumAndroidLinker.BrowserStates",
                            histogram_code,
                            MAX_BROWSER_HISTOGRAM_CODE);

  // Record the device support for loading a library directly from the APK file.
  UMA_HISTOGRAM_ENUMERATION("ChromiumAndroidLinker.LibraryLoadFromApkStatus",
                            library_load_from_apk_status,
                            LIBRARY_LOAD_FROM_APK_STATUS_CODES_MAX);

  // Record how long it took to load the shared libraries.
  UMA_HISTOGRAM_TIMES("ChromiumAndroidLinker.BrowserLoadTime",
                      base::TimeDelta::FromMilliseconds(library_load_time_ms));
}

void SetLibraryLoadedHook(LibraryLoadedHook* func) {
  g_registration_callback = func;
}

static void InitCommandLine(JNIEnv* env,
                            jobject jcaller,
                            jobjectArray init_command_line) {
  InitNativeCommandLineFromJavaArray(env, init_command_line);
}

static jboolean LibraryLoaded(JNIEnv* env, jobject jcaller) {
  if (g_registration_callback == NULL) {
    return true;
  }
  return g_registration_callback(env, NULL);
}

void LibraryLoaderExitHook() {
  if (g_at_exit_manager) {
    delete g_at_exit_manager;
    g_at_exit_manager = NULL;
  }
}

static jboolean ForkAndPrefetchNativeLibrary(JNIEnv* env, jclass clazz) {
  return NativeLibraryPrefetcher::ForkAndPrefetchNativeLibrary();
}

bool RegisterLibraryLoaderEntryHook(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

void SetVersionNumber(const char* version_number) {
  g_library_version_number = strdup(version_number);
}

jstring GetVersionNumber(JNIEnv* env, jobject jcaller) {
  return ConvertUTF8ToJavaString(env, g_library_version_number).Release();
}

LibraryProcessType GetLibraryProcessType(JNIEnv* env) {
  return static_cast<LibraryProcessType>(
      Java_LibraryLoader_getLibraryProcessType(env));
}

void InitAtExitManager() {
  g_at_exit_manager = new base::AtExitManager();
}

}  // namespace android
}  // namespace base
