// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_UI_DART_STATE_H_
#define FLUTTER_LIB_UI_UI_DART_STATE_H_

#include <memory>
#include <string>
#include <utility>

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/flow/skia_gpu_object.h"
#include "flutter/fml/build_config.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/lib/ui/io_manager.h"
#include "flutter/lib/ui/isolate_name_server/isolate_name_server.h"
#include "flutter/lib/ui/painting/image_decoder.h"
#include "flutter/lib/ui/snapshot_delegate.h"
#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/skia/include/gpu/GrContext.h"
#include "third_party/tonic/dart_microtask_queue.h"
#include "third_party/tonic/dart_persistent_value.h"
#include "third_party/tonic/dart_state.h"

namespace flutter {
class FontSelector;
class Window;

class UIDartState : public tonic::DartState {
 public:
  static UIDartState* Current();

  Dart_Port main_port() const { return main_port_; }

  void SetDebugName(const std::string name);

  const std::string& debug_name() const { return debug_name_; }

  const std::string& logger_prefix() const { return logger_prefix_; }

  Window* window() const { return window_.get(); }

  const TaskRunners& GetTaskRunners() const;

  void ScheduleMicrotask(Dart_Handle handle);

  void FlushMicrotasksNow();

  fml::WeakPtr<IOManager> GetIOManager() const;

  fml::RefPtr<flutter::SkiaUnrefQueue> GetSkiaUnrefQueue() const;

  fml::WeakPtr<SnapshotDelegate> GetSnapshotDelegate() const;

  fml::WeakPtr<GrContext> GetResourceContext() const;

  fml::WeakPtr<ImageDecoder> GetImageDecoder() const;

  std::shared_ptr<IsolateNameServer> GetIsolateNameServer() const;

  tonic::DartErrorHandleType GetLastError();

  void ReportUnhandledException(const std::string& error,
                                const std::string& stack_trace);

  template <class T>
  static flutter::SkiaGPUObject<T> CreateGPUObject(sk_sp<T> object) {
    if (!object) {
      return {};
    }
    auto* state = UIDartState::Current();
    FML_DCHECK(state);
    auto queue = state->GetSkiaUnrefQueue();
    return {std::move(object), std::move(queue)};
  };

 protected:
  UIDartState(TaskRunners task_runners,
              TaskObserverAdd add_callback,
              TaskObserverRemove remove_callback,
              fml::WeakPtr<SnapshotDelegate> snapshot_delegate,
              fml::WeakPtr<IOManager> io_manager,
              fml::RefPtr<SkiaUnrefQueue> skia_unref_queue,
              fml::WeakPtr<ImageDecoder> image_decoder,
              std::string advisory_script_uri,
              std::string advisory_script_entrypoint,
              std::string logger_prefix,
              UnhandledExceptionCallback unhandled_exception_callback,
              std::shared_ptr<IsolateNameServer> isolate_name_server);

  ~UIDartState() override;

  void SetWindow(std::unique_ptr<Window> window);

  const std::string& GetAdvisoryScriptURI() const;

  const std::string& GetAdvisoryScriptEntrypoint() const;

 private:
  void DidSetIsolate() override;

  const TaskRunners task_runners_;
  const TaskObserverAdd add_callback_;
  const TaskObserverRemove remove_callback_;
  fml::WeakPtr<SnapshotDelegate> snapshot_delegate_;
  fml::WeakPtr<IOManager> io_manager_;
  fml::RefPtr<SkiaUnrefQueue> skia_unref_queue_;
  fml::WeakPtr<ImageDecoder> image_decoder_;
  const std::string advisory_script_uri_;
  const std::string advisory_script_entrypoint_;
  const std::string logger_prefix_;
  Dart_Port main_port_ = ILLEGAL_PORT;
  std::string debug_name_;
  std::unique_ptr<Window> window_;
  tonic::DartMicrotaskQueue microtask_queue_;
  UnhandledExceptionCallback unhandled_exception_callback_;
  const std::shared_ptr<IsolateNameServer> isolate_name_server_;

  void AddOrRemoveTaskObserver(bool add);
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_UI_DART_STATE_H_
