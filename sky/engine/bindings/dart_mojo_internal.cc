// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/bindings/dart_mojo_internal.h"

#include "dart/runtime/include/dart_api.h"
#include "flutter/tonic/dart_converter.h"
#include "flutter/tonic/dart_error.h"
#include "mojo/public/platform/dart/mojo_natives.h"

namespace blink {
namespace {

MojoHandle g_handle_watcher_producer_handle = MOJO_HANDLE_INVALID;

void SetHandleWatcherControlHandle(Dart_Handle mojo_internal) {
  CHECK(g_handle_watcher_producer_handle != MOJO_HANDLE_INVALID);
  Dart_Handle handle_watcher_type = Dart_GetType(
      mojo_internal, ToDart("MojoHandleWatcher"), 0, nullptr);
  Dart_Handle field_name = ToDart("mojoControlHandle");
  Dart_Handle control_port_value = ToDart(g_handle_watcher_producer_handle);
  Dart_Handle result =
      Dart_SetField(handle_watcher_type, field_name, control_port_value);
  CHECK(!LogIfError(result));
}

}  // namespace

void DartMojoInternal::SetHandleWatcherProducerHandle(MojoHandle handle) {
  CHECK_EQ(g_handle_watcher_producer_handle, MOJO_HANDLE_INVALID);
  g_handle_watcher_producer_handle = handle;
}

void DartMojoInternal::InitForIsolate() {
  Dart_Handle mojo_internal = Dart_LookupLibrary(ToDart("dart:mojo.internal"));
  DART_CHECK_VALID(Dart_SetNativeResolver(
      mojo_internal,
      mojo::dart::MojoNativeLookup,
      mojo::dart::MojoNativeSymbol));
  SetHandleWatcherControlHandle(mojo_internal);
}

}  // namespace blink
