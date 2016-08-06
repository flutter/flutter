// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tonic/dart_snapshot_loader.h"

#include <utility>

#include "flutter/tonic/dart_state.h"
#include "glue/trace_event.h"
#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/logging/dart_error.h"
#include "lib/tonic/scopes/dart_api_scope.h"
#include "lib/tonic/scopes/dart_isolate_scope.h"

using tonic::LogIfError;

namespace blink {

DartSnapshotLoader::DartSnapshotLoader(tonic::DartState* dart_state)
    : dart_state_(dart_state->GetWeakPtr()) {}

DartSnapshotLoader::~DartSnapshotLoader() {}

void DartSnapshotLoader::LoadSnapshot(mojo::ScopedDataPipeConsumerHandle pipe,
                                      const ftl::Closure& callback) {
  TRACE_EVENT_ASYNC_BEGIN0("flutter", "DartSnapshotLoader::LoadSnapshot", this);

  drain_job_.reset(new glue::DrainDataPipeJob(
      std::move(pipe), [this, callback](std::vector<char> buffer) {
        TRACE_EVENT_ASYNC_END0("flutter", "DartSnapshotLoader::LoadSnapshot",
                               this);
        // TODO(abarth): Should we check dart_state_ for null?
        {
          tonic::DartIsolateScope scope(dart_state_->isolate());
          tonic::DartApiScope api_scope;

          LogIfError(Dart_LoadScriptFromSnapshot(
              reinterpret_cast<uint8_t*>(buffer.data()), buffer.size()));
        }

        callback();
      }));
}

}  // namespace blink
