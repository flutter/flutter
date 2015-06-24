// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/tonic/dart_snapshot_loader.h"

#include "base/callback.h"
#include "base/trace_event/trace_event.h"
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

void DartSnapshotLoader::LoadSnapshot(mojo::ScopedDataPipeConsumerHandle pipe,
                                      const base::Closure& callback) {
  TRACE_EVENT_ASYNC_BEGIN0("sky", "DartSnapshotLoader::LoadSnapshot", this);

  callback_ = callback;
  drainer_ = adoptPtr(new DataPipeDrainer(this, pipe.Pass()));
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
