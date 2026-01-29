// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/make_copyable.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_persistent_value.h"
#include "third_party/tonic/logging/dart_invoke.h"

namespace flutter {

void CreateImageFromTextureId(int64_t texture_id, Dart_Handle callback_handle) {
  if (!Dart_IsClosure(callback_handle)) {
    Dart_ThrowException(tonic::ToDart("Callback must be a function"));
    return;
  }

  auto* dart_state = UIDartState::Current();
  if (!dart_state) {
    Dart_ThrowException(tonic::ToDart("No UI dart state available"));
    return;
  }

  auto snapshot_delegate = dart_state->GetSnapshotDelegate();
  if (!snapshot_delegate) {
    Dart_ThrowException(tonic::ToDart("No snapshot delegate available"));
    return;
  }

  const auto& task_runners = dart_state->GetTaskRunners();
  auto ui_runner = task_runners.GetUITaskRunner();
  auto raster_runner = task_runners.GetRasterTaskRunner();

  if (!ui_runner || !raster_runner) {
    Dart_ThrowException(tonic::ToDart("Task runners not available"));
    return;
  }

  // Store the callback so it persists across threads
  auto persistent_callback =
      std::make_unique<tonic::DartPersistentValue>(dart_state, callback_handle);

  // Capture what we need for the raster thread
  auto weak_dart_state = dart_state->GetWeakPtr();

  raster_runner->PostTask(fml::MakeCopyable([texture_id, snapshot_delegate,
                                             persistent_callback =
                                                 std::move(persistent_callback),
                                             ui_runner,
                                             weak_dart_state]() mutable {
    sk_sp<DlImage> dl_image = nullptr;

    // Access the snapshot delegate on the raster thread
    if (auto delegate = snapshot_delegate.get()) {
      dl_image = delegate->CreateImageFromTexture(texture_id);
    }

    // Post result back to UI thread
    ui_runner->PostTask(fml::MakeCopyable([dl_image = std::move(dl_image),
                                           persistent_callback =
                                               std::move(persistent_callback),
                                           weak_dart_state]() mutable {
      auto dart_state = weak_dart_state.lock();
      if (!dart_state) {
        // Isolate was terminated
        return;
      }

      tonic::DartState::Scope scope(dart_state.get());

      Dart_Handle callback = persistent_callback->Get();
      if (Dart_IsNull(callback)) {
        return;
      }

      if (dl_image && dl_image->isUIThreadSafe()) {
        auto canvas_image = fml::MakeRefCounted<CanvasImage>();
        canvas_image->set_image(std::move(dl_image));

        tonic::DartInvoke(callback, {tonic::ToDart(canvas_image), Dart_Null()});
      } else {
        tonic::DartInvoke(
            callback, {Dart_Null(),
                       tonic::ToDart("Failed to create image from texture")});
      }
    }));
  }));
}

}  // namespace flutter
