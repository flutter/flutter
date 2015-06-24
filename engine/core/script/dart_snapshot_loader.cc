// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/script/dart_snapshot_loader.h"

#include "base/callback.h"
#include "base/trace_event/trace_event.h"
#include "sky/engine/platform/weborigin/KURL.h"
#include "sky/engine/tonic/dart_api_scope.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_error.h"
#include "sky/engine/tonic/dart_isolate_scope.h"
#include "sky/engine/wtf/MainThread.h"

using mojo::common::DataPipeDrainer;

namespace blink {

DartSnapshotLoader::DartSnapshotLoader(DartState* dart_state)
    : dart_state_(dart_state->GetWeakPtr()) {
}

DartSnapshotLoader::~DartSnapshotLoader() {
}

void DartSnapshotLoader::LoadSnapshot(const KURL& url,
                                      mojo::URLResponsePtr response,
                                      const base::Closure& callback) {
  TRACE_EVENT_ASYNC_BEGIN0("sky", "DartSnapshotLoader::LoadSnapshot", this);
  callback_ = callback;

  if (!response) {
    fetcher_ = adoptPtr(new MojoFetcher(this, url));
  } else {
    OnReceivedResponse(response.Pass());
  }
}

void DartSnapshotLoader::OnReceivedResponse(mojo::URLResponsePtr response) {
  if (response->status_code != 200) {
    callback_.Run();
    return;
  }
  drainer_ = adoptPtr(new DataPipeDrainer(this, response->body.Pass()));
}

void DartSnapshotLoader::OnDataAvailable(const void* data, size_t num_bytes) {
  buffer_.append(static_cast<const uint8_t*>(data), num_bytes);
}

void DartSnapshotLoader::OnDataComplete() {
  TRACE_EVENT_ASYNC_END0("sky", "DartSnapshotLoader::LoadSnapshot", this);

  {
    DartIsolateScope scope(dart_state_->isolate());
    DartApiScope api_scope;

    LogIfError(Dart_LoadScriptFromSnapshot(buffer_.data(), buffer_.size()));
  }

  callback_.Run();
}

}  // namespace blink
